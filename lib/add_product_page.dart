import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddProductScreen extends StatefulWidget {
  final String ownerId;
  final String city;

  const AddProductScreen({
    super.key,
    required this.ownerId,
    required this.city,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final mrpController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final imageUrlController = TextEditingController();

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  Future<void> addProduct() async {
    if (nameController.text.trim().isEmpty ||
        quantityController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        stockController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    try {
      // Find this owner's shop in the selected city
      final shopSnapshot =
      await dbRef.child("cities/${widget.city}/shops").get();

      String? shopId;
      for (final entry in shopSnapshot.children) {
        if (entry.child("ownerId").value == widget.ownerId) {
          shopId = entry.key;
          break;
        }
      }

      if (shopId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shop not found for this owner.")),
        );
        return;
      }

      // Build product payload
      final product = {
        "name": nameController.text.trim(),
        "quantity": quantityController.text.trim(),
        "mrp": int.tryParse(mrpController.text) ?? 0,
        "price": int.tryParse(priceController.text) ?? 0,
        "stock": int.tryParse(stockController.text) ?? 0,
        "imageUrl": imageUrlController.text.trim(),
      };

      // Generate ONE key and fan-out to both locations
      final newProductKey = dbRef
          .child("cities/${widget.city}/shops/$shopId/products")
          .push()
          .key!;

      final updates = <String, dynamic>{
        // Shop collection (existing)
        "cities/${widget.city}/shops/$shopId/products/$newProductKey": product,

        // Global listing in parallel node
        "allproducts/$newProductKey": {
          ...product,
          "key": newProductKey,
          "city": widget.city,
          "shopId": shopId,
          "ownerId": widget.ownerId,
          "lowerName": nameController.text.trim().toLowerCase(),
          "createdAt": ServerValue.timestamp, // server timestamp
        },
      };

      await dbRef.update(updates);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("🎉 Product Added"),
          content: const Text(
              "Your product has been successfully added."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            )
          ],
        ),
      );

      // Clear fields
      nameController.clear();
      quantityController.clear();
      mrpController.clear();
      priceController.clear();
      stockController.clear();
      imageUrlController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add product: $e")),
      );
    }
  }

  InputDecoration _inputDecoration(String label, [String? hint]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      backgroundColor: const Color(0xFFF4F4F4),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("Fill the details below",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextField(
                controller: nameController,
                decoration:
                _inputDecoration("Product Name", "e.g., Basmati Rice"),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: quantityController,
                decoration: _inputDecoration("Quantity", "e.g., 500g, 1L"),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: mrpController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("MRP", "e.g., 100"),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Discounted Price", "e.g., 80"),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Stock Available", "e.g., 50"),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: imageUrlController,
                decoration: _inputDecoration("Product Image URL"),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              if (imageUrlController.text.isNotEmpty)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text("Preview",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrlController.text,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: addProduct,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text("Add Product"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
