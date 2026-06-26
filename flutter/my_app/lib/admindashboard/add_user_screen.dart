import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = "patient";
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ⚠️ حطي التوكن هنا أو من SharedPreferences
  //String? token;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      //token = await ApiService.getToken();

      //if (token == null) {
      //throw Exception("No token found");
      //}
      List<String> names = nameController.text.trim().split(" ");

      String firstName = names.first;
      String lastName = names.length > 1 ? names.sublist(1).join(" ") : " ";

      await ApiService.addUser({
        "Fname": firstName,
        "Lname": lastName,
        "Email": emailController.text.trim(),
        "password": passwordController.text,
        "password_confirmation": passwordController.text,
        "type": selectedRole,
      });

      /*List<String> names = nameController.text.trim().split(" ");

      String firstName = names.first;

      String lastName = names.length > 1 ? names.sublist(1).join(" ") : "";

      await ApiService.addUser(
        {
          "Fname": nameController.text.trim(),
          "Lname": "",
          "Email": emailController.text.trim(),
          "password": passwordController.text,
          "type": selectedRole,
        },
      );*/

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User added successfully!"),
            backgroundColor: Color(0xFF4A7C59),
          ),
        );

        Navigator.pop(context, {
          "id": DateTime.now().millisecondsSinceEpoch,
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "role": selectedRole,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B4F68);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE7EEF3),
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        title: const Text(
          "Add User",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFFF2BCD0),
                child: Icon(Icons.person_add, size: 40, color: primaryColor),
              ),
              const SizedBox(height: 25),
              _field("Name", nameController),
              const SizedBox(height: 15),
              _field("Email", emailController),
              const SizedBox(height: 15),
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.length < 6 ? "Min 6 characters" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(
                    value: "patient",
                    child: Text("Patient"),
                  ),
                  DropdownMenuItem(
                    value: "caregiver",
                    child: Text("Caregiver"),
                  ),
                  DropdownMenuItem(
                    value: "admin",
                    child: Text("Admin"),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => selectedRole = v);
                },
                decoration: InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save User"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }
}
