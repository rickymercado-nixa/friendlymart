import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all products stream
  static Stream<QuerySnapshot> getAllProductsStream() {
    return _firestore.collection('products').snapshots();
  }

  // Get products by category stream
  static Stream<QuerySnapshot> getProductsByCategoryStream(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots();
  }

  // Get product by ID
  static Future<DocumentSnapshot?> getProduct(String productId) async {
    try {
      return await _firestore.collection('products').doc(productId).get();
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Check if product has sufficient stock
  static Future<bool> checkStock(String productId, int requestedQuantity) async {
    try {
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) return false;

      final stock = productDoc.data()?['stock'] as int? ?? 0;
      return stock >= requestedQuantity;
    } catch (e) {
      print('Error checking stock: $e');
      return false;
    }
  }

  // Get available categories
  static Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      final categories = <String>{};

      for (var doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Search products by name
  static Stream<QuerySnapshot> searchProductsStream(String searchTerm) {
    return _firestore
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThanOrEqualTo: searchTerm + '\uf8ff')
        .snapshots();
  }
}