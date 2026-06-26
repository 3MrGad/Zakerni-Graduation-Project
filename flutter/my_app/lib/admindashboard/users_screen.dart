import 'package:flutter/material.dart';
import 'add_user_screen.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const UsersScreen({super.key, this.onBack});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedFilter = "All";

  List<Map<String, dynamic>> _allUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
    fetchUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void fetchUsers() async {
    try {
      final data = await ApiService.getUsers();

      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredUsers {
    final query = searchController.text.toLowerCase().trim();

    return _allUsers.where((user) {
      final name = (user["name"] ?? "").toString().toLowerCase();
      final email = (user["email"] ?? "").toString().toLowerCase();

      // 🔥 توحيد role (مهم جدًا)
      final role = (user["role"] ?? "").toString().toLowerCase();

      final selectedRole = selectedFilter.toLowerCase();

      final matchesSearch =
          query.isEmpty || name.contains(query) || email.contains(query);

      final matchesRole = selectedRole == "all" || role == selectedRole;

      return matchesSearch && matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B4F68);
    final users = filteredUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE7EEF3),
        elevation: 0,
        automaticallyImplyLeading: true,
        title: const Text(
          "Manage Users",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onBack?.call();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddUserScreen(),
            ),
          );

          if (result == true) {
            fetchUsers();
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by name or email...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["All", "Patient", "Caregiver", "Admin"]
                    .map((role) => _filterChip(role, primaryColor))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  "${users.length} users",
                  style: const TextStyle(color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? const Center(child: Text("No users found"))
                      : ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _userCard(user, primaryColor);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, Color primaryColor) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user, Color primaryColor) {
    final roleRaw = (user["role"] ?? "").toString();
    final role = roleRaw.toLowerCase();

    final roleColors = {
      "patient": Colors.blue.shade100,
      "caregiver": Colors.green.shade100,
      "admin": Colors.pink.shade100,
    };

    final displayRole = roleRaw.isNotEmpty
        ? roleRaw[0].toUpperCase() + roleRaw.substring(1)
        : "User";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            (user["name"] ?? "U").toString().substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(user["name"] ?? ""),
        subtitle: Text(user["email"] ?? ""),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: roleColors[role] ?? Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(displayRole),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  _allUsers.remove(user);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("User deleted"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
