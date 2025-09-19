import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendlymart/screens/login.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../widgets/cart_widget.dart';
import '../../widgets/product_widgets.dart';
import 'package:friendlymart/screens/orders_screen.dart';
import 'package:friendlymart/screens/customer_notification_screen.dart';
import 'package:friendlymart/chats/customer_chats.dart';

class CustomerDashboardPage extends StatefulWidget {
  @override
  _CustomerDashboardPageState createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  String selectedCategory = "All";
  final List<String> categories = ["All", "Beverages", "Snacks", "Fruits", "Vegetables"];
  int _selectedIndex = 0;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
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

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0: // Orders
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CustomerOrdersPage()),
        );
        break;
      case 1: // Chat
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerChatsScreen()),
        );
        break;
      case 2: // Cart
        _openCartDialog();
        break;
      case 3: // Logout
        _logout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildProductsList(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final String? customerId = FirebaseAuth.instance.currentUser?.uid;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      title: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: 'Friendly',
              style: TextStyle(color: Colors.yellow[700]!),
            ),
            TextSpan(
              text: 'Mart',
              style: TextStyle(color: Colors.blue[900]!),
            ),
          ],
        ),
      ),
      actions: [
        CategoryDropdown(
          selectedCategory: selectedCategory,
          categories: categories,
          onChanged: _onCategoryChanged,
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('notifications')
              .where('customerId', isEqualTo: _firestore.doc('users/$customerId'))
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int notifCount = 0;
            if (snapshot.hasData) {
              notifCount = snapshot.data!.docs.length;
            }
            return Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (notifCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$notifCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
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

  Widget _buildBottomNavigationBar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: CartService.getCartStream(),
      builder: (context, snapshot) {
        int cartCount = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final cartData = snapshot.data!.data() as Map<String, dynamic>?;
          final items = cartData?['items'] as Map<String, dynamic>? ?? {};
          cartCount = items.length;
        }

        return BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[600],
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: "Orders",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.shopping_cart),
                  if (cartCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          "$cartCount",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: "Cart",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout),
              label: "Logout",
            ),
          ],
        );
      },
    );
  }
}
