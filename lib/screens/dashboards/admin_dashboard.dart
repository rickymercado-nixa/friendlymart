import 'package:flutter/material.dart';
import 'package:friendlymart/models/riderapproval_page.dart';
import 'package:friendlymart/screens/create/admin_create_product.dart';
import 'package:friendlymart/screens/order_review_screen.dart';
import 'package:friendlymart/screens/read/admin_read_product.dart';
import 'package:friendlymart/screens/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardAnalyticsPage(),
      ReadProductsPage(),
      CreateProductPage(),
      RiderApprovalPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = Colors.blue[800];
    final accentYellow = Colors.yellow[700];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friendly Mart Admin"),
        centerTitle: true,
        backgroundColor: primaryBlue,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Create"),
          BottomNavigationBarItem(icon: Icon(Icons.motorcycle), label: "Riders"),
        ],
      ),
      /*
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentYellow,
        onPressed: () {},
        child: Icon(Icons.add, color: primaryBlue),
      ),
       */
    );
  }
}

class DashboardAnalyticsPage extends StatelessWidget {
  const DashboardAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryBlue = Colors.blue[800]!;
    final accentYellow = Colors.yellow[700]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Business Analytics",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              )),
          const SizedBox(height: 20),

          // Cards using Wrap to avoid overflow
          Wrap(
            runSpacing: 20,
            children: [
              _buildStatCard("Total Orders", "1,240", Icons.shopping_cart, primaryBlue, accentYellow),
              _buildStatCard("Active Deliveries", "58", Icons.local_shipping, Colors.green, accentYellow),
              _buildStatCard("Completed Orders", "1,180", Icons.check_circle, Colors.blue, accentYellow),
              _buildStatCard("Revenue", "₱520,000", Icons.monetization_on, Colors.purple, accentYellow),
            ],
          ),
          const SizedBox(height: 30),

          Text("Other Features",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              )),
          const SizedBox(height: 10),

          ListTile(
            leading: Icon(Icons.receipt, color: primaryBlue),
            title: const Text("Order Review"),
            subtitle: const Text("Review Orders"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const OrderReviewScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.chat, color: Colors.green[700]),
            title: const Text("Customer Chat Support"),
            subtitle: const Text("Real-time messaging with customers"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return SizedBox(
      width: 160,
      child: Card(
        color: bgColor.withValues(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(title, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }
}
