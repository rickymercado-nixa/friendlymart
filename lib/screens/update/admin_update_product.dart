import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendlymart/screens/dashboards/admin_dashboard.dart';

class UpdateProductPage extends StatefulWidget {
  final String productId;
  final dynamic productData;

  UpdateProductPage({required this.productId, required this.productData});

  @override
  _UpdateProductPageState createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController categoryController;
  late TextEditingController priceController;
  late TextEditingController stockController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.productData['name']);
    descController = TextEditingController(text: widget.productData['description']);
    categoryController = TextEditingController(text: widget.productData['category']);
    priceController = TextEditingController(text: widget.productData['price'].toString());
    stockController = TextEditingController(text: widget.productData['stock'].toString());
  }

  Future<void> updateProduct() async {
    await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
      'name': nameController.text,
      'description': descController.text,
      'category': categoryController.text,
      'price': double.tryParse(priceController.text) ?? 0,
      'stock': int.tryParse(stockController.text) ?? 0,
    });
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminDashboard()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Update Product")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(controller: nameController, decoration: InputDecoration(labelText: "Product Name")),
            TextFormField(controller: descController, decoration: InputDecoration(labelText: "Description")),
            TextFormField(controller: categoryController, decoration: InputDecoration(labelText: "Category")),
            TextFormField(controller: priceController, decoration: InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextFormField(controller: stockController, decoration: InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProduct,
              child: Text("Update"),
            )
          ],
        ),
      ),
    );
  }
}
