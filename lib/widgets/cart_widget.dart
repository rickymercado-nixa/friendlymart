import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';

class CartDialog extends StatelessWidget {
  const CartDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.blue[600]),
          SizedBox(width: 8),
          Text(
            "Your Cart",
            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: StreamBuilder<DocumentSnapshot>(
          stream: CartService.getCartStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildEmptyCart();
            }

            final cartData = snapshot.data!.data() as Map<String, dynamic>;
            final items = cartData['items'] as Map<String, dynamic>? ?? {};

            if (items.isEmpty) {
              return _buildEmptyCart();
            }

            double total = 0;
            items.forEach((key, value) {
              total += value['subtotal'];
            });

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    children: items.entries.map((entry) {
                      final item = entry.value;
                      return CartItemTile(
                        item: item,
                        productId: entry.key,
                        onRemove: () => _removeItem(entry.key),
                      );
                    }).toList(),
                  ),
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₱${total.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close", style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () => _checkout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text("Checkout"),
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text("Your cart is empty", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _removeItem(String productId) async {
    await CartService.removeItemFromCart(productId);
  }

  Future<void> _checkout(BuildContext context) async {
    final cartData = await CartService.getCartForCheckout();

    if (cartData == null) {
      _showSnackBar(context, "Cart is empty!", Colors.orange);
      return;
    }

    // Use the CartService.checkout() instead of OrderService
    final success = await CartService.checkout(paymentMethod: "Cash on Delivery");

    if (success) {
      Navigator.pop(context);
      _showSnackBar(context, "Order placed successfully!", Colors.green);
    } else {
      _showSnackBar(context, "Failed to place order. Please try again.", Colors.red);
    }
  }


  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String productId;
  final VoidCallback onRemove;

  const CartItemTile({
    Key? key,
    required this.item,
    required this.productId,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  "₱${item['price']} × ${item['qty']} = ₱${item['subtotal']}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class CartBadge extends StatelessWidget {
  final int itemCount;
  final VoidCallback onTap;

  const CartBadge({
    Key? key,
    required this.itemCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(right: 16, left: 8),
          child: IconButton(
            icon: Icon(Icons.shopping_cart_rounded, size: 26),
            onPressed: onTap,
          ),
        ),
        if (itemCount > 0)
          Positioned(
            right: 12,
            top: 8,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.amber[400],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                itemCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}