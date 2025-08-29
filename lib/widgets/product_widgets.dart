import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cart_service.dart';

class ProductCard extends StatefulWidget {
  final DocumentSnapshot product;

  const ProductCard({
    Key? key,
    required this.product,
  }) : super(key: key);


  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int quantity = 1;

  void updateQuantity(bool increase) {
    setState(() {
      if (increase) {
        final stock = widget.product['stock'] as int;
        if (quantity < stock) {
          quantity++;
        }
      } else {
        if (quantity > 1) {
          quantity--;
        }
      }
    });
    // Removed callback - no need to notify parent
  }

  Future<void> addToCart() async {
    final success = await CartService.addItemToCart(
      productId: widget.product.id,
      productName: widget.product['name'],
      price: widget.product['price'].toDouble(),
      quantity: quantity,
    );

    if (success) {
      // Reset quantity after adding to cart
      setState(() {
        quantity = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${widget.product['name']} added to cart"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add item to cart"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.product['stock'] as int;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(imageUrl: widget.product['image']),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductDetails(
                    name: widget.product['name'],
                    price: widget.product['price'].toDouble(),
                    stock: stock,
                  ),
                  SizedBox(height: 12),
                  ProductControls(
                    quantity: quantity,
                    stock: stock,
                    onQuantityChanged: updateQuantity,
                    onAddToCart: addToCart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  final String? imageUrl;

  const ProductImage({Key? key, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
          ),
        )
            : Container(
          color: Colors.grey[200],
          child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
        ),
      ),
    );
  }
}

class ProductDetails extends StatelessWidget {
  final String name;
  final double price;
  final int stock;

  const ProductDetails({
    Key? key,
    required this.name,
    required this.price,
    required this.stock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 4),
        Text(
          "₱${price.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Stock: $stock",
          style: TextStyle(
            fontSize: 12,
            color: stock > 5 ? Colors.green[600] : Colors.orange[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ProductControls extends StatelessWidget {
  final int quantity;
  final int stock;
  final Function(bool) onQuantityChanged;
  final VoidCallback onAddToCart;

  const ProductControls({
    Key? key,
    required this.quantity,
    required this.stock,
    required this.onQuantityChanged,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Qty: ",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            QuantitySelector(
              quantity: quantity,
              stock: stock,
              onQuantityChanged: onQuantityChanged,
            ),
          ],
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: stock > 0 ? onAddToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[400],
              foregroundColor: Colors.blue[800],
              elevation: 2,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_shopping_cart, size: 18),
                SizedBox(width: 6),
                Text(
                  "Add to Cart",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int stock;
  final Function(bool) onQuantityChanged;

  const QuantitySelector({
    Key? key,
    required this.quantity,
    required this.stock,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: quantity > 1 ? () => onQuantityChanged(false) : null,
              child: Container(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: quantity > 1 ? Colors.blue[600] : Colors.grey[400],
                ),
              ),
            ),
          ),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: quantity < stock ? () => onQuantityChanged(true) : null,
              child: Container(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: quantity < stock ? Colors.blue[600] : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final List<String> categories;
  final Function(String?) onChanged;

  const CategoryDropdown({
    Key? key,
    required this.selectedCategory,
    required this.categories,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: selectedCategory,
        underline: SizedBox(),
        dropdownColor: Colors.blue[600],
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
        style: TextStyle(color: Colors.white, fontSize: 14),
        items: categories.map((cat) {
          return DropdownMenuItem<String>(
            value: cat,
            child: Text(cat, style: TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}