import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ornek_flutter_web/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ornek_flutter_web/widgets/form_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _particleController;
  
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  
  bool _usernameFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _phoneFocused = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _usernameFocusNode.addListener(() {
      setState(() {
        _usernameFocused = _usernameFocusNode.hasFocus;
      });
    });
    
    _emailFocusNode.addListener(() {
      setState(() {
        _emailFocused = _emailFocusNode.hasFocus;
      });
    });
    
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordFocused = _passwordFocusNode.hasFocus;
      });
    });
    
    _phoneFocusNode.addListener(() {
      setState(() {
        _phoneFocused = _phoneFocusNode.hasFocus;
      });
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _usernameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
        },
      );

      if (response.user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beklenmedik bir hata oluştu: $e'), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(30, (index) => _buildParticle(index)),
            
            // Circular segments background
            Positioned(
              top: -100,
              left: -100,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) => Transform.rotate(
                  angle: _animationController.value * 2 * pi,
                  child: Container(
                    width: 400,
                    height: 400,
                    child: Stack(
                      children: [
                        ...List.generate(40, (index) => _buildCircularSegment(index)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Back button
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.cyan,
                  size: 28,
                ),
              ).animate().fadeIn(delay: 200.ms),
            ),
            
            // Main content
            Center(
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(50),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.cyan, Colors.blue, Colors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'Kayıt Ol',
                          style: GoogleFonts.orbitron(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.3),
                      
                      const SizedBox(height: 50),
                      
                      // Username field
                      _buildModernTextField(
                        controller: _usernameController,
                        hintText: 'Kullanıcı Adı',
                        icon: Icons.person_outline,
                        focusNode: _usernameFocusNode,
                        isFocused: _usernameFocused,
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.3),
                      
                      const SizedBox(height: 25),
                      
                      // Email field
                      _buildModernTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        focusNode: _emailFocusNode,
                        isFocused: _emailFocused,
                        keyboardType: TextInputType.emailAddress,
                      ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideX(begin: 0.3),
                      
                      const SizedBox(height: 25),
                      
                      // Password field
                      _buildModernTextField(
                        controller: _passwordController,
                        hintText: 'Şifre',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        focusNode: _passwordFocusNode,
                        isFocused: _passwordFocused,
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: -0.3),
                      
                      const SizedBox(height: 25),
                      
                      // Phone field
                      _buildModernTextField(
                        controller: _phoneController,
                        hintText: 'Telefon Numarası',
                        icon: Icons.phone_outlined,
                        focusNode: _phoneFocusNode,
                        isFocused: _phoneFocused,
                        keyboardType: TextInputType.phone,
                      ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideX(begin: 0.3),
                      
                      const SizedBox(height: 40),
                      
                      // Sign up button
                      _buildModernButton().animate().fadeIn(delay: 600.ms, duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParticle(int index) {
    final random = Random(index);
    final size = random.nextDouble() * 4 + 1;
    final initialX = random.nextDouble() * MediaQuery.of(context).size.width;
    final initialY = random.nextDouble() * MediaQuery.of(context).size.height;
    final duration = random.nextInt(3000) + 2000;
    
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + random.nextDouble()) % 1.0;
        final x = initialX + (sin(progress * 2 * pi) * 50);
        final y = initialY + (cos(progress * 2 * pi) * 30);
        
        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyan.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.5),
                  blurRadius: size * 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCircularSegment(int index) {
    final angle = (index * 9.0) * (pi / 180);
    final radius = 180.0;
    final segmentLength = 15.0;
    
    return Positioned(
      left: 200 + cos(angle) * radius,
      top: 200 + sin(angle) * radius,
      child: Transform.rotate(
        angle: angle + pi / 2,
        child: Container(
          width: 2,
          height: segmentLength,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan.withOpacity(0.1),
                Colors.cyan.withOpacity(0.4),
                Colors.cyan.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required FocusNode focusNode,
    required bool isFocused,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: isFocused 
              ? Colors.cyan.withOpacity(0.8)
              : Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: isFocused ? [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ] : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (hintText == 'Telefon Numarası') return null; // Phone is optional
            return 'Lütfen ${hintText.toLowerCase()}nizi girin.';
          }
          if (hintText == 'Şifre' && value.length < 6) {
            return 'Şifre en az 6 karakter olmalıdır.';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 18,
          ),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              icon,
              color: isFocused 
                  ? Colors.blue.withOpacity(0.9)
                  : Colors.cyan.withOpacity(0.7),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.7), // Matlaştırılmış turuncu
            Colors.deepOrange.withOpacity(0.6),
            Colors.red.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _isLoading ? null : _signUp,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text(
                    'Kayıt Ol',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}