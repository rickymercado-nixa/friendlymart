import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendlymart/screens/update/admin_update_product.dart';
import 'package:friendlymart/screens/delete/admin_delete_product.dart';

class ReadProductsPage extends StatefulWidget {
  @override
  _ReadProductsPageState createState() => _ReadProductsPageState();
}

class _ReadProductsPageState extends State<ReadProductsPage> {
  String selectedCategory = "All";
  final List<String> categories = [
    "All",
    "Beverages",
    "Snacks",
    "Fruits",
    "Vegetables"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Products",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: selectedCategory,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.black54),
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(
                      cat,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedCategory = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: (selectedCategory == "All")
            ? FirebaseFirestore.instance
            .collection('products')
//            .orderBy('name')
            .snapshots()
            : FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: selectedCategory)
//            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No products found.",
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index];
              String? imageUrl = product['image'];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported,
                          size: 30, color: Colors.grey),
                    ),
                  ),
                  title: Text(
                    product['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "₱${product['price']}  •  Stock: ${product['stock']}\n${product['category']}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UpdateProductPage(
                                productId: product.id,
                                productData: product,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DeleteProductPage(productId: product.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
