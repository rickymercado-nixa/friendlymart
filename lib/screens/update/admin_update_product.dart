import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';

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

  File? _imageFile; // picked image
  String? imageUrl; // stored image URL

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.productData['name']);
    descController = TextEditingController(text: widget.productData['description']);
    categoryController = TextEditingController(text: widget.productData['category']);
    priceController = TextEditingController(text: widget.productData['price'].toString());
    stockController = TextEditingController(text: widget.productData['stock'].toString());
    imageUrl = widget.productData['image']; // current product image
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    const cloudName = "defiwrcn3"; // replace
    const uploadPreset = "unsigned_preset"; // replace

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    final request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final resData = await response.stream.bytesToString();
      return json.decode(resData)["secure_url"];
    }
    return null;
  }

  Future<void> updateProduct() async {
    String? finalImageUrl = imageUrl;

    if (_imageFile != null) {
      final uploadedUrl = await uploadImageToCloudinary(_imageFile!);
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      }
    }

    await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
      'name': nameController.text,
      'description': descController.text,
      'category': categoryController.text,
      'price': double.tryParse(priceController.text) ?? 0,
      'stock': int.tryParse(stockController.text) ?? 0,
      'image': finalImageUrl,
    });

    // Show AwesomeDialog after successful update
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.bottomSlide,
      title: 'Update Successful!',
      desc: 'The product has been updated successfully.',
      btnOkOnPress: () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => AdminDashboard()));
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Update Product")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: _imageFile != null
                  ? Image.file(_imageFile!, height: 150, fit: BoxFit.cover)
                  : (imageUrl != null
                  ? Image.network(imageUrl!, height: 150, fit: BoxFit.cover)
                  : Container(
                height: 150,
                color: Colors.grey[300],
                child: Icon(Icons.camera_alt, size: 50),
              )),
            ),
            SizedBox(height: 20),
            TextFormField(controller: nameController, decoration: InputDecoration(labelText: "Product Name")),
            TextFormField(controller: descController, decoration: InputDecoration(labelText: "Description")),
            TextFormField(controller: categoryController, decoration: InputDecoration(labelText: "Category")),
            TextFormField(controller: priceController, decoration: InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextFormField(controller: stockController, decoration: InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProduct,
              child: Text("Update Product"),
            )
          ],
        ),
      ),
    );
  }
}
