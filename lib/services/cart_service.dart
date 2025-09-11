import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's cart document reference
  static DocumentReference? get _userCartRef {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('carts').doc(user.uid);
  }

  // Delivery location from map picker
  static Future<void> setDeliveryLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final cartRef = _userCartRef;
    if (cartRef == null) return;

    try {
      await cartRef.set({
        'deliveryLocation': {
          'address': address,
          'lat': latitude,
          'lng': longitude,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Delivery location updated in cart (lat/lng + Address)");
    } catch (e) {
      print("❌ Error setting delivery location: $e");
    }
  }

  // Get delivery location from cart
  static Future<Map<String, dynamic>?> getDeliveryLocation() async {
    final cartRef = _userCartRef;
    if (cartRef == null) return null;

    try {
      final cartDoc = await cartRef.get();
      if (!cartDoc.exists) return null;

      final data = cartDoc.data() as Map<String, dynamic>;
      return data['deliveryLocation'] as Map<String, dynamic>?;
    } catch (e) {
      print("❌ Error getting delivery location: $e");
      return null;
    }
  }

  // Get cart items count
  static Future<int> getCartItemsCount() async {
    final cartRef = _userCartRef;
    if (cartRef == null) return 0;

    try {
      final cartDoc = await cartRef.get();
      if (!cartDoc.exists) return 0;

      final items = cartDoc.data() as Map<String, dynamic>?;
      final itemsMap = items?['items'] as Map<String, dynamic>? ?? {};
      return itemsMap.length;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }

  // Add item to cart
  static Future<bool> addItemToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
  }) async {
    final cartRef = _userCartRef;
    if (cartRef == null) return false;

    try {
      final subtotal = price * quantity;
      final itemData = {
        'name': productName,
        'price': price,
        'productId': productId,
        'qty': quantity,
        'subtotal': subtotal,
      };

      await cartRef.set({
        'updatedAt': FieldValue.serverTimestamp(),
        'items': {
          productId: itemData,
        }
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error adding item to cart: $e');
      return false;
    }
  }

// Remove item from cart and restore stock
  static Future<bool> removeItemFromCart(String productId) async {
    final cartRef = _userCartRef;
    if (cartRef == null) return false;

    try {
      final cartDoc = await cartRef.get();
      if (!cartDoc.exists) return false;

      final cartData = cartDoc.data() as Map<String, dynamic>?;
      final items = cartData?['items'] as Map<String, dynamic>? ?? {};
      if (!items.containsKey(productId)) return false;

      final removedItem = items[productId];
      final removedQty = removedItem['qty'] as int;

      final productRef = FirebaseFirestore.instance.collection('products').doc(productId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final productSnap = await transaction.get(productRef);
        if (!productSnap.exists) throw Exception("Product not found");

        final currentStock = productSnap['stock'] as int;
        final newStock = currentStock + removedQty;

        transaction.update(productRef, {'stock': newStock});

        transaction.update(cartRef, {
          'items.$productId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      print('Error removing item from cart: $e');
      return false;
    }
  }


  // Get cart stream for real-time updates
  static Stream<DocumentSnapshot>? getCartStream() {
    final cartRef = _userCartRef;
    if (cartRef == null) return null;
    return cartRef.snapshots();
  }

  // Clear entire cart
  static Future<bool> clearCart() async {
    final cartRef = _userCartRef;
    if (cartRef == null) return false;

    try {
      await cartRef.delete();
      return true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  // Get cart data for checkout
  static Future<Map<String, dynamic>?> getCartForCheckout() async {
    final cartRef = _userCartRef;
    if (cartRef == null) return null;

    try {
      final cartDoc = await cartRef.get();
      if (!cartDoc.exists) return null;

      final cartData = cartDoc.data() as Map<String, dynamic>?;
      final items = cartData?['items'] as Map<String, dynamic>? ?? {};

      if (items.isEmpty) return null;

      double totalAmount = 0;
      List<Map<String, dynamic>> orderItems = [];

      items.forEach((productId, itemData) {
        totalAmount += itemData['subtotal'];
        orderItems.add({
          'productId': productId,
          'name': itemData['name'],
          'price': itemData['price'],
          'quantity': itemData['qty'],
          'subtotal': itemData['subtotal'],
        });
      });

      return {
        'items': orderItems,
        'totalAmount': totalAmount,
        'deliveryLocation': cartData?['deliveryLocation'],
      };
    } catch (e) {
      print('Error getting cart for checkout: $e');
      return null;
    }
  }

  static Future<bool> checkout({
    required String paymentMethod,
    required Map<String, dynamic> deliveryLocation, // 👈 added this
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("❌ No user logged in at checkout");
      return false;
    }

    final cartData = await getCartForCheckout();
    if (cartData == null) {
      print("❌ No cart data found");
      return false;
    }

    try {
      final orderData = {
        'customerId': _firestore.collection('users').doc(user.uid),
        'items': cartData['items'],
        'totalAmount': cartData['totalAmount'],
        'paymentMethod': paymentMethod,
        'paymentStatus': 'Pending',
        'orderStatus': 'Pending',
        'deliveryLocation': {
          "lat": deliveryLocation["lat"],
          "lng": deliveryLocation["lng"],
          "address": deliveryLocation["address"],
        },
        'deliveryFee': 0,
        'acceptedBy': "",
        'assignedBy': "System",
        'riderId': "",
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('orders').add(orderData);

      await clearCart();

      print("✅ Order placed successfully!");
      return true;
    } catch (e) {
      print("❌ Error during checkout: $e");
      return false;
    }
  }
}
