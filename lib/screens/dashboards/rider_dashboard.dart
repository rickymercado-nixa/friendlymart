import 'package:flutter/material.dart';

class RiderDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rider Dashboard")),
      body: Center(child: Text("Welcome Rider!", style: TextStyle(fontSize: 24))),
    );
  }
}
