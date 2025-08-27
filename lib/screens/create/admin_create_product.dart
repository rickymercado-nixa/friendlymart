import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendlymart/screens/dashboards/admin_dashboard.dart';
import 'package:friendlymart/screens/dashboards/admin_dashboard.dart';

class CreateProductPage extends StatefulWidget {
  @override
  _CreateProductPageState createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  Future<void> addProduct() async {
    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'category': categoryController.text.trim(),
        'price': double.tryParse(priceController.text) ?? 0,
        'stock': int.tryParse(stockController.text) ?? 0,
        'createdAt': Timestamp.now(),
        'image': ''
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.bottomSlide,
        title: 'Add Success!',
        desc: 'You add product successfully!.',
        btnOkOnPress: () {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => AdminDashboard()),
          );
        },
      ).show();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Product")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: nameController, decoration: InputDecoration(labelText: "Product Name")),
              TextFormField(controller: descController, decoration: InputDecoration(labelText: "Description")),
              TextFormField(controller: categoryController, decoration: InputDecoration(labelText: "Category")),
              TextFormField(controller: priceController, decoration: InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
              TextFormField(controller: stockController, decoration: InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addProduct,
                child: Text("Add"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
