import 'dart:io';
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:friendlymart/screens/dashboards/admin_dashboard.dart';

class CreateProductPage extends StatefulWidget {
  @override
  _CreateProductPageState createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  // ✅ Category dropdown
  String? _selectedCategory;
  final List<String> _categories = [
    "Fruits",
    "Vegetables",
    "Beverages",
    "Snacks",
    "Meat",
  ];

  File? _imageFile;
  final picker = ImagePicker();
  bool _isLoading = false;

  // 👉 Pick image
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 👉 Upload to Cloudinary
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    try {
      final cloudName = "defiwrcn3"; // from Cloudinary dashboard
      final uploadPreset = "unsigned_preset"; // unsigned preset

      final url =
      Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final resData = json.decode(resStr);

        return resData["secure_url"]; // ✅ Cloudinary image URL
      } else {
        print("Cloudinary upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Cloudinary upload error: $e");
      return null;
    }
  }

  // 👉 Add product to Firestore
  Future<void> addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_imageFile != null) {
        print("Uploading image: ${_imageFile!.path}");
        imageUrl = await uploadImageToCloudinary(_imageFile!);
        print("Uploaded image URL: $imageUrl");
      } else {
        print("⚠️ No image selected!");
      }

      await FirebaseFirestore.instance.collection('products').add({
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'category': _selectedCategory ?? "Uncategorized",
        'price': double.tryParse(priceController.text) ?? 0,
        'stock': int.tryParse(stockController.text) ?? 0,
        'createdAt': Timestamp.now(),
        'image': imageUrl ?? "",
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.bottomSlide,
        title: 'Success!',
        desc: 'Product has been added successfully.',
        btnOkOnPress: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
          );
        },
      ).show();
    } catch (e) {
      print("❌ Error adding product: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 👉 Form decoration
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Product"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.yellow[700]!,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image preview
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt,
                          size: 40, color: Colors.grey.shade600),
                      SizedBox(height: 8),
                      Text("Tap to upload image",
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Product Name
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration("Product Name"),
                validator: (val) =>
                val!.isEmpty ? "Enter product name" : null,
              ),
              SizedBox(height: 12),

              // Description
              TextFormField(
                controller: descController,
                decoration: _inputDecoration("Description"),
                maxLines: 2,
              ),
              SizedBox(height: 12),

              // ✅ Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDecoration("Category"),
                items: _categories
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
                validator: (val) =>
                val == null ? "Please select a category" : null,
              ),
              SizedBox(height: 12),

              // Price
              TextFormField(
                controller: priceController,
                decoration: _inputDecoration("Price"),
                keyboardType: TextInputType.number,
                validator: (val) =>
                val!.isEmpty ? "Enter product price" : null,
              ),
              SizedBox(height: 12),

              // Stock
              TextFormField(
                controller: stockController,
                decoration: _inputDecoration("Stock"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700]!,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Add Product",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.yellow[700]!)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
