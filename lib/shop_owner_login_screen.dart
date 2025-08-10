import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'shop_owner_home_screen.dart';

class ShopOwnerLoginScreen extends StatefulWidget {
  const ShopOwnerLoginScreen({super.key});

  @override
  State<ShopOwnerLoginScreen> createState() => _ShopOwnerLoginScreenState();
}

class _ShopOwnerLoginScreenState extends State<ShopOwnerLoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("users");
  bool isLoading = false;

  void loginOwner() async {
    setState(() => isLoading = true);
    final snapshot = await dbRef.get();
    bool found = false;

    if (snapshot.exists) {
      final users = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in users.entries) {
        final user = Map<String, dynamic>.from(entry.value);
        if (user["role"] == "shopOwner" &&
            user["username"] == usernameController.text.trim() &&
            user["password"] == passwordController.text.trim()) {
          found = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ShopOwnerHomeScreen(
                shopOwnerName: user["name"] ?? "Shop Owner",
                city: user["city"] ?? "Unknown",
                ownerId: entry.key,
              ),
            ),
          );
          break;
        }
      }
    }

    if (!found) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Shop Owner Login",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      labelText: "Username",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      labelText: "Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: loginOwner,
                      icon: const Icon(Icons.login),
                      label: const Text("Login", style: TextStyle(fontSize: 16,color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
