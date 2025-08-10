import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManageStockScreen extends StatefulWidget {
  final String ownerId;
  final String city;

  const ManageStockScreen({
    super.key,
    required this.ownerId,
    required this.city,
  });

  @override
  State<ManageStockScreen> createState() => _ManageStockScreenState();
}

class _ManageStockScreenState extends State<ManageStockScreen> {
  late DatabaseReference dbRef;
  String? shopId;

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance.ref();
    findShopId();
  }

  Future<void> findShopId() async {
    final shopsSnapshot = await dbRef.child("cities/${widget.city}/shops").get();
    for (var shop in shopsSnapshot.children) {
      if (shop.child("ownerId").value == widget.ownerId) {
        setState(() {
          shopId = shop.key;
        });
        break;
      }
    }
  }

  void updateStockAndPrice(String productId, int newStock, double newPrice) async {
    if (shopId == null) return;
    final updates = {
      'stock': newStock,
      'price': newPrice,
    };
    await dbRef.child("cities/${widget.city}/shops/$shopId/products/$productId").update(updates);
  }

  void deleteProduct(String productId) async {
    if (shopId == null) return;

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await dbRef.child("cities/${widget.city}/shops/$shopId/products/$productId").remove();
    }
  }

  void showEditDialog(String productId, Map<String, dynamic> product) {
    final stockController = TextEditingController(text: product['stock'].toString());
    final priceController = TextEditingController(text: product['price'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Edit - ${product['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Stock",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(stockController.text) ?? product['stock'];
              final newPrice = double.tryParse(priceController.text) ?? product['price'].toDouble();
              updateStockAndPrice(productId, newStock, newPrice);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Stock")),
      body: shopId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DatabaseEvent>(
        stream: dbRef.child("cities/${widget.city}/shops/$shopId/products").onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No products found"));
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          return ListView(
            padding: const EdgeInsets.all(10),
            children: productsMap.entries.map((entry) {
              final productId = entry.key;
              final product = Map<String, dynamic>.from(entry.value);

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty
                        ? Image.network(
                      product['imageUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 50),
                    )
                        : const Icon(Icons.image_not_supported, size: 50),
                  ),
                  title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("₹${product['price']} | Stock: ${product['stock']}"),
                      Text("Sales: ${product['sales'] ?? 0}", style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  onTap: () => showEditDialog(productId, product),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteProduct(productId),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
