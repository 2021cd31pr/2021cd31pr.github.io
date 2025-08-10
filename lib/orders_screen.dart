import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersScreen extends StatefulWidget {
  final String ownerId;
  final String city;

  const OrdersScreen({super.key, required this.ownerId, required this.city});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late DatabaseReference dbRef;
  String? shopId;
  Map<String, dynamic> orders = {};
  Map<String, String> userOrderMap = {}; // orderId -> userId

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance.ref();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final shopsSnapshot = await dbRef.child("cities/${widget.city}/shops").get();

    for (var shop in shopsSnapshot.children) {
      if (shop.child("ownerId").value == widget.ownerId) {
        shopId = shop.key;

        final ordersSnap = shop.child("orders");
        final data = Map<String, dynamic>.from(ordersSnap.value as Map? ?? {});
        setState(() => orders = data);
        break;
      }
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (shopId == null) return;

    await dbRef.child("cities/${widget.city}/shops/$shopId/orders/$orderId/status").set(newStatus);

    final userSnap = await dbRef.child("users").get();
    for (var user in userSnap.children) {
      final ordersMap = user.child("orders").value as Map?;
      if (ordersMap != null && ordersMap.containsKey(orderId)) {
        await dbRef.child("users/${user.key}/orders/$orderId/status").set(newStatus);
        break;
      }
    }

    // Update totalRevenue if delivered
    if (newStatus == "delivered") {
      final orderSnap = await dbRef.child("cities/${widget.city}/shops/$shopId/orders/$orderId").get();
      if (orderSnap.exists) {
        final orderData = Map<String, dynamic>.from(orderSnap.value as Map);
        final orderTotal = orderData["total"] ?? 0;

        final revenueSnap = await dbRef.child("cities/${widget.city}/shops/$shopId/totalRevenue").get();
        final currentRevenue = revenueSnap.exists ? revenueSnap.value as num : 0;

        final updatedRevenue = currentRevenue + (orderTotal as num);
        await dbRef.child("cities/${widget.city}/shops/$shopId/totalRevenue").set(updatedRevenue);
      }
    }

    fetchOrders();
  }

  void _shareLocation(double lat, double lng) async {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final uri = Uri.parse("whatsapp://send?text=Customer Location: $url");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp")),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "delivered":
        return Colors.green;
      case "dispatched":
        return Colors.blue;
      case "accepted":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Orders")),
      body: orders.isEmpty
          ? const Center(child: Text("No orders yet"))
          : ListView(
        padding: const EdgeInsets.all(12),
        children: orders.entries.map((entry) {
          final orderId = entry.key;
          final order = Map<String, dynamic>.from(entry.value);

          final address = order['address'] ?? {};
          final location = order['location'] ?? {};
          final items = (order["items"] as List<dynamic>? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();


          final name = order["name"] ?? "N/A";
          final phone = order["phone"] ?? "N/A";
          final total = order["total"] ?? 0;
          final status = order["status"] ?? "ordered";
          final time = order["timestamp"] ?? "";

          final fullAddress = "${address['house'] ?? ""}, ${address['street'] ?? ""}, "
              "${address['landmark'] ?? ""}, ${address['city'] ?? ""} - ${address['pinCode'] ?? ""}";

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text("Customer: $name", style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Chip(
                        label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white)),
                        backgroundColor: getStatusColor(status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Phone: $phone"),
                  Text("Total Amount: ₹$total"),
                  const SizedBox(height: 8),
                  const Text("Items:", style: TextStyle(fontWeight: FontWeight.w500)),
                  ...items.map((item) {
                    return Text("• ${item['name']} x${item['quantity']}");
                  }),
                  const Divider(),
                  const Text("Address:", style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(fullAddress),
                  const SizedBox(height: 6),
                  if (location['lat'] != null && location['lng'] != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        _shareLocation(location['lat'], location['lng']);
                      },
                      icon: const Icon(Icons.share_location),
                      label: const Text("Share Location via WhatsApp"),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Status:", style: TextStyle(color: Colors.grey[700])),
                      DropdownButton<String>(
                        value: status,
                        items: const [
                          DropdownMenuItem(value: "ordered", child: Text("Ordered")),
                          DropdownMenuItem(value: "accepted", child: Text("Accepted")),
                          DropdownMenuItem(value: "dispatched", child: Text("Dispatched")),
                          DropdownMenuItem(value: "delivered", child: Text("Delivered")),
                        ],
                        onChanged: (val) {
                          if (val != null) updateOrderStatus(orderId, val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
