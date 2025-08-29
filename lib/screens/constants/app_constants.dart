import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = "FriendlyMart";
  static const String appVersion = "1.0.0";

  // Firebase Collection Names
  static const String productsCollection = "products";
  static const String cartsCollection = "carts";
  static const String ordersCollection = "orders";
  static const String usersCollection = "users";

  // Order Status
  static const String orderStatusPending = "Pending";
  static const String orderStatusConfirmed = "Confirmed";
  static const String orderStatusDelivering = "Delivering";
  static const String orderStatusDelivered = "Delivered";
  static const String orderStatusCancelled = "Cancelled";

  // Payment Methods
  static const String paymentCashOnDelivery = "Cash on Delivery";
  static const String paymentCard = "Card";
  static const String paymentDigitalWallet = "Digital Wallet";

  // Payment Status
  static const String paymentStatusPending = "Pending";
  static const String paymentStatusPaid = "Paid";
  static const String paymentStatusFailed = "Failed";

  // Product Categories
  static const List<String> productCategories = [
    "All",
    "Beverages",
    "Snacks",
    "Fruits",
    "Vegetables",
    "Dairy",
    "Meat",
    "Seafood",
    "Bakery",
    "Frozen",
    "Household",
    "Personal Care"
  ];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Stock Levels
  static const int lowStockThreshold = 5;
  static const int outOfStockThreshold = 0;

  // Delivery
  static const double defaultDeliveryFee = 30.0;
  static const double freeDeliveryMinimum = 500.0;
}

class AppColors {
  // Primary Colors - Blue Theme
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color darkBlue = Color(0xFF0D47A1);

  // Secondary Colors - Yellow/Amber Theme
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color lightYellow = Color(0xFFFFE082);
  static const Color darkYellow = Color(0xFFF57F17);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFFBDBDBD);
  static const Color darkGrey = Color(0xFF424242);
  static const Color black = Color(0xFF000000);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Stock Status Colors
  static const Color inStock = Color(0xFF4CAF50);
  static const Color lowStock = Color(0xFFFF9800);
  static const Color outOfStock = Color(0xFFF44336);
}

class AppTextStyles {
  // Headers
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.darkGrey,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGrey,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGrey,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.darkGrey,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkGrey,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.mediumGrey,
  );

  // Special Text
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.darkBlue,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mediumGrey,
  );
}

class AppDimensions {
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Button Heights
  static const double buttonHeight = 48.0;
  static const double smallButtonHeight = 36.0;
  static const double largeButtonHeight = 56.0;

  // Card Dimensions
  static const double cardWidth = double.infinity;
  static const double cardMinHeight = 100.0;
  static const double productImageSize = 80.0;

  // Spacing
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
}

class AppMessages {
  // Success Messages
  static const String itemAddedToCart = "Item added to cart";
  static const String itemRemovedFromCart = "Item removed from cart";
  static const String orderPlacedSuccess = "Order placed successfully!";
  static const String cartCleared = "Cart cleared";

  // Error Messages
  static const String cartEmpty = "Cart is empty!";
  static const String orderFailed = "Failed to place order. Please try again.";
  static const String networkError = "Network error. Please check your connection.";
  static const String addToCartFailed = "Failed to add item to cart";
  static const String removeFromCartFailed = "Failed to remove item from cart";
  static const String userNotLoggedIn = "User not logged in";
  static const String productNotFound = "Product not found";
  static const String insufficientStock = "Insufficient stock available";

  // Loading Messages
  static const String loading = "Loading...";
  static const String processingOrder = "Processing your order...";
  static const String addingToCart = "Adding to cart...";

  // General Messages
  static const String noProductsFound = "No products found";
  static const String cartIsEmpty = "Your cart is empty";
  static const String selectQuantity = "Select quantity";
  static const String outOfStock = "Out of stock";
}

class AppAnimations {
  // Duration
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve fastCurve = Curves.easeOut;
}