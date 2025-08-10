import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddFromAvailableProductsScreen extends StatefulWidget {
  final String ownerId;
  final String city;

  const AddFromAvailableProductsScreen({
    super.key,
    required this.ownerId,
    required this.city,
  });

  @override
  State<AddFromAvailableProductsScreen> createState() =>
      _AddFromAvailableProductsScreenState();
}

class _AddFromAvailableProductsScreenState
    extends State<AddFromAvailableProductsScreen> {
  final dbRef = FirebaseDatabase.instance.ref();

  String? _shopId;
  bool _loadingShop = true;

  final TextEditingController _search = TextEditingController();
  String _q = "";

  // simple pagination
  final int _pageSize = 24;
  String? _lastKey;
  bool _isLoading = false;
  bool _hasMore = true;

  final List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _displayed = [];

  @override
  void initState() {
    super.initState();
    _resolveShopId();
    _fetchNext();
  }

  Future<void> _resolveShopId() async {
    final snap =
    await dbRef.child("cities/${widget.city}/shops").get();
    for (var s in snap.children) {
      if (s.child("ownerId").value == widget.ownerId) {
        _shopId = s.key;
        break;
      }
    }
    setState(() => _loadingShop = false);
  }

  Future<void> _fetchNext() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    Query q = dbRef.child("allproducts").orderByKey().limitToFirst(_pageSize + 1);
    if (_lastKey != null) q = q.startAfter([_lastKey]);

    final snapshot = await q.get();

    int count = 0;
    for (final c in snapshot.children) {
      final data = Map<String, dynamic>.from(c.value as Map);
      _all.add({
        "key": c.key,
        "name": data["name"] ?? "",
        "quantity": data["quantity"] ?? "",
        "mrp": data["mrp"] ?? 0,
        "price": data["price"] ?? 0,
        "stock": data["stock"] ?? 0,
        "imageUrl": data["imageUrl"] ?? "",
      });
      _lastKey = c.key;
      count++;
      if (count >= _pageSize) break;
    }

    if (count < _pageSize) _hasMore = false;

    _applySearch();
    setState(() => _isLoading = false);
  }

  void _applySearch() {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) {
      _displayed = List<Map<String, dynamic>>.from(_all);
    } else {
      _displayed = _all
          .where((p) => p["name"].toString().toLowerCase().contains(q))
          .toList();
    }
    setState(() {});
  }

  void _openEditAddSheet(Map<String, dynamic> p) {
    final mrpCtrl = TextEditingController(text: p["mrp"].toString());
    final priceCtrl = TextEditingController(text: p["price"].toString());
    final stockCtrl = TextEditingController(text: p["stock"].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p["name"],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mrpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "MRP",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Stock",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Add to My Shop"),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _addToShop(
                    p,
                    mrp: int.tryParse(mrpCtrl.text) ?? 0,
                    price: int.tryParse(priceCtrl.text) ?? 0,
                    stock: int.tryParse(stockCtrl.text) ?? 0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToShop(
      Map<String, dynamic> p, {
        required int mrp,
        required int price,
        required int stock,
      }) async {
    if (_loadingShop || _shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop not found for this owner.")),
      );
      return;
    }

    final newKey = dbRef
        .child("cities/${widget.city}/shops/$_shopId/products")
        .push()
        .key!;

    final payload = {
      "name": p["name"],
      "quantity": p["quantity"],
      "mrp": mrp,
      "price": price,
      "stock": stock,
      "imageUrl": p["imageUrl"],
    };

    await dbRef
        .child("cities/${widget.city}/shops/$_shopId/products/$newKey")
        .set(payload);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product added to your shop.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add from Available Products")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) {
                _q = v;
                _applySearch();
              },
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
                    !_isLoading &&
                    _hasMore) {
                  _fetchNext();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                itemCount: _displayed.length + (_hasMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= _displayed.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final p = _displayed[i];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (p["imageUrl"] as String).isNotEmpty
                            ? Image.network(
                          p["imageUrl"],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                        )
                            : Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image),
                        ),
                      ),
                      title: Text(
                        p["name"],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Qty: ${p['quantity']}   MRP: ₹${p['mrp']}   Price: ₹${p['price']}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: TextButton(
                        onPressed: () => _openEditAddSheet(p),
                        child: const Text("ADD"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
