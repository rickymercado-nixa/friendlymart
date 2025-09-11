import 'package:flutter/material.dart';

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
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: selectedCategory,
        underline: const SizedBox(),
        dropdownColor: Colors.blue[600],
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: categories.map((cat) {
          return DropdownMenuItem<String>(
            value: cat,
            child: Text(cat, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
