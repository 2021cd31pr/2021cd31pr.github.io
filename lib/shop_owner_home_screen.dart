import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'add_product_page.dart';
import 'manage_stock_screen.dart';
import 'orders_screen.dart';
import 'update_shop_banner_screen.dart';
import 'add_from_available_products_screen.dart'; // <-- NEW

class ShopOwnerHomeScreen extends StatefulWidget {
  final String shopOwnerName;
  final String city;
  final String ownerId;

  const ShopOwnerHomeScreen({
    super.key,
    required this.shopOwnerName,
    required this.city,
    required this.ownerId,
  });

  @override
  State<ShopOwnerHomeScreen> createState() => _ShopOwnerHomeScreenState();
}

class _ShopOwnerHomeScreenState extends State<ShopOwnerHomeScreen> {
  String? bannerUrl;

  @override
  void initState() {
    super.initState();
    fetchBannerUrl();
  }

  Future<void> fetchBannerUrl() async {
    final dbRef = FirebaseDatabase.instance.ref();
    final snapshot = await dbRef.child("cities/${widget.city}/shops").get();

    for (var shop in snapshot.children) {
      if (shop.child("ownerId").value == widget.ownerId) {
        setState(() {
          bannerUrl = shop.child("bannerUrl").value?.toString();
        });
        break;
      }
    }
  }

  void _refreshBanner() {
    fetchBannerUrl();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Welcome, ${widget.shopOwnerName}"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Shop Banner", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: bannerUrl != null
                    ? Image.network(
                  bannerUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                )
                    : Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(child: Text("No banner available")),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Update Banner"),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UpdateShopBannerScreen(
                        ownerId: widget.ownerId,
                        city: widget.city,
                      ),
                    ),
                  );
                  _refreshBanner();
                },
              ),
            ),
            const SizedBox(height: 12),
            Text("Manage Your Shop", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildOptionCard(
                    context,
                    icon: Icons.add_business,
                    title: "Add Product",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductScreen(
                            ownerId: widget.ownerId,
                            city: widget.city,
                          ),
                        ),
                      );
                    },
                  ),
                  // NEW OPTION
                  _buildOptionCard(
                    context,
                    icon: Icons.library_add, // “add from catalog”
                    title: "Add from Available Products",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddFromAvailableProductsScreen(
                            ownerId: widget.ownerId,
                            city: widget.city,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildOptionCard(
                    context,
                    icon: Icons.inventory_2_rounded,
                    title: "Manage Stock",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageStockScreen(
                            ownerId: widget.ownerId,
                            city: widget.city,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildOptionCard(
                    context,
                    icon: Icons.receipt_long,
                    title: "View Orders",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrdersScreen(
                            ownerId: widget.ownerId,
                            city: widget.city,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
