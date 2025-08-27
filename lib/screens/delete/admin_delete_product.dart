import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendlymart/screens/dashboards/admin_dashboard.dart';

class DeleteProductPage extends StatelessWidget {
  final String productId;

  DeleteProductPage({required this.productId});

  Future<void> deleteProduct(BuildContext context) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminDashboard()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Delete Product"),
      content: Text("Are you sure you want to delete this product?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => deleteProduct(context),
          child: Text("Delete"),
        )
      ],
    );
  }
}
