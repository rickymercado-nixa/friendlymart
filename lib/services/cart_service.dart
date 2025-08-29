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

  // Remove item from cart
  static Future<bool> removeItemFromCart(String productId) async {
    final cartRef = _userCartRef;
    if (cartRef == null) return false;

    try {
      await cartRef.update({
        'items.$productId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
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
      };
    } catch (e) {
      print('Error getting cart for checkout: $e');
      return null;
    }
  }

  // Checkout: move cart items into orders
  static Future<bool> checkout({
    required String paymentMethod,
    String? deliveryLocation,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final cartData = await getCartForCheckout();
    if (cartData == null) return false;

    try {
      final orderData = {
        'customerId': user.uid,
        'items': cartData['items'],
        'totalAmount': cartData['totalAmount'],
        'paymentMethod': paymentMethod,
        'paymentStatus': 'Pending',
        'orderStatus': 'Pending',
        'deliveryLocation': deliveryLocation ?? "Not provided",
        'deliveryFee': 0,
        'acceptedBy': "Waiting for rider",
        'assignBy': "System",
        'riderId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to orders
      await _firestore.collection('orders').add(orderData);

      // Clear the cart after placing order
      await clearCart();

      return true;
    } catch (e) {
      print("Error during checkout: $e");
      return false;
    }
  }
}
