import 'package:flutter/material.dart';

class CustomerDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Customer Dashboard")),
      body: Center(child: Text("Welcome Customer!", style: TextStyle(fontSize: 24))),
    );
  }
}
