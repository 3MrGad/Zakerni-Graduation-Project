import 'package:flutter/material.dart';
import 'animated_background.dart';

class AlzheimerSignUpPage extends StatefulWidget {
  @override
  _AlzheimerSignUpPageState createState() => _AlzheimerSignUpPageState();
}

class _AlzheimerSignUpPageState extends State<AlzheimerSignUpPage> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _createAccount() {
    // هنا هتضيف منطق إنشاء الحساب
    print('إنشاء حساب جديد...');
    print('الاسم: ${_nameController.text}');
    print('الإيميل: ${_emailController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية المتحركة
          AnimatedBackground(),
          
          // محتوى الصفحة الأساسي
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // الهيدر مع الشعار
                        _buildHeader(),
                        SizedBox(height: 32),
                        
                        // حقل الاسم
                        _buildTextField(
                          controller: _nameController,
                          label: 'الاسم بالكامل',
                          icon: Icons.person,
                          hint: 'أدخل اسمك بالكامل'
                        ),
                        SizedBox(height: 20),
                        
                        // حقل الإيميل
                        _buildTextField(
                          controller: _emailController,
                          label: 'البريد الإلكتروني',
                          icon: Icons.email,
                          hint: 'example@email.com',
                          keyboardType: TextInputType.emailAddress
                        ),
                        SizedBox(height: 20),
                        
                        // حقل الباسورد
                        _buildTextField(
                          controller: _passwordController,
                          label: 'كلمة المرور',
                          icon: Icons.lock,
                          hint: 'أدخل كلمة مرور قوية',
                          isPassword: true
                        ),
                        SizedBox(height: 32),
                        
                        // زر إنشاء الحساب
                        _buildSignUpButton(),
                        SizedBox(height: 20),
                        
                        // رابط تسجيل الدخول
                        _buildLoginLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // أيقونة الدماغ (رمز للذاكرة)
        Icon(
          Icons.psychology,
          size: 80,
          color: Colors.blue[700],
        ),
        SizedBox(height: 16),
        Text(
          'ذاكرتي',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'نساعدك في رحلة الذاكرة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue[600]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _createAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Text(
          'إنشاء حساب',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'لديك حساب بالفعل؟',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            // التنقل لصفحة تسجيل الدخول
            print('الذهاب لتسجيل الدخول...');
          },
          child: Text(
            'سجل الدخول',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}