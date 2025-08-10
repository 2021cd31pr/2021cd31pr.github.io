import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UpdateShopBannerScreen extends StatefulWidget {
  final String ownerId;
  final String city;

  const UpdateShopBannerScreen({
    super.key,
    required this.ownerId,
    required this.city,
  });

  @override
  State<UpdateShopBannerScreen> createState() => _UpdateShopBannerScreenState();
}

class _UpdateShopBannerScreenState extends State<UpdateShopBannerScreen> {
  final bannerController = TextEditingController();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  String? currentBanner;

  @override
  void initState() {
    super.initState();
    fetchCurrentBanner();
  }

  void fetchCurrentBanner() async {
    final shopSnapshot = await dbRef.child("cities/${widget.city}/shops").get();
    for (var shop in shopSnapshot.children) {
      if (shop.child("ownerId").value == widget.ownerId) {
        currentBanner = shop.child("bannerUrl").value?.toString();
        bannerController.text = currentBanner ?? "";
        setState(() {});
        break;
      }
    }
  }

  void updateBanner() async {
    final newBanner = bannerController.text.trim();
    if (newBanner.isEmpty) return;

    final shopSnapshot = await dbRef.child("cities/${widget.city}/shops").get();
    for (var shop in shopSnapshot.children) {
      if (shop.child("ownerId").value == widget.ownerId) {
        await dbRef
            .child("cities/${widget.city}/shops/${shop.key}/bannerUrl")
            .set(newBanner);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("✅ Banner updated")));
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Shop Banner")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: bannerController,
              decoration: const InputDecoration(labelText: "Banner Image URL"),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            if (bannerController.text.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  bannerController.text,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 100),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: updateBanner,
              icon: const Icon(Icons.upload),
              label: const Text("Update Banner"),
            ),
          ],
        ),
      ),
    );
  }
}
