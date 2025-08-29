import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendlymart/screens/login.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../widgets/cart_widget.dart';
import '../../widgets/product_widgets.dart';
import 'package:friendlymart/screens/orders_screen.dart';

class CustomerDashboardPage extends StatefulWidget {
  @override
  _CustomerDashboardPageState createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  String selectedCategory = "All";
  final List<String> categories = ["All", "Beverages", "Snacks", "Fruits", "Vegetables"];
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }


  void _onCategoryChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedCategory = value;
      });
    }
  }

  void _openCartDialog() {
    showDialog(
      context: context,
      builder: (_) => CartDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildProductsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      title: Text(
        "FriendlyMart",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        CategoryDropdown(
          selectedCategory: selectedCategory,
          categories: categories,
          onChanged: _onCategoryChanged,
        ),
        IconButton(
          icon: Icon(Icons.receipt_long),
          tooltip: "My Orders",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomerOrdersPage()),
            );
          },
        ),
        // Real-time cart badge using StreamBuilder
        StreamBuilder<DocumentSnapshot>(
          stream: CartService.getCartStream(),
          builder: (context, snapshot) {
            int cartCount = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              final cartData = snapshot.data!.data() as Map<String, dynamic>?;
              final items = cartData?['items'] as Map<String, dynamic>? ?? {};
              cartCount = items.length;
            }

            return CartBadge(
              itemCount: cartCount,
              onTap: _openCartDialog,
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: selectedCategory == "All"
          ? ProductService.getAllProductsStream()
          : ProductService.getProductsByCategoryStream(selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final products = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              // No callback needed - cart updates are now real-time
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            "No products found",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}