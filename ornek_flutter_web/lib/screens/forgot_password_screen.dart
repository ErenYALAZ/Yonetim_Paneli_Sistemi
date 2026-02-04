import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ornek_flutter_web/widgets/form_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _particleController;
  
  final _emailFocusNode = FocusNode();
  bool _emailFocused = false;
  
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
    
    _emailFocusNode.addListener(() {
      setState(() {
        _emailFocused = _emailFocusNode.hasFocus;
      });
    });
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eğer bu e-posta kayıtlıysa, bir sıfırlama linki gönderildi.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beklenmedik bir hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
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
              right: -100,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) => Transform.rotate(
                  angle: -_animationController.value * 2 * pi,
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
                          colors: [Colors.purple, Colors.pink, Colors.orange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'Şifremi Unuttum',
                          style: GoogleFonts.orbitron(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.3),
                      
                      const SizedBox(height: 30),
                      
                      // Description
                      Text(
                        'Şifre sıfırlama linki almak için e-posta adresinizi girin.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      
                      const SizedBox(height: 50),
                      
                      // Email field
                      _buildModernTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        focusNode: _emailFocusNode,
                        isFocused: _emailFocused,
                        keyboardType: TextInputType.emailAddress,
                      ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideX(begin: 0.3),
                      
                      const SizedBox(height: 40),
                      
                      // Send reset link button
                      _buildModernButton().animate().fadeIn(delay: 400.ms, duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
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
              color: Colors.purple.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.5),
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
                Colors.purple.withOpacity(0.1),
                Colors.purple.withOpacity(0.4),
                Colors.purple.withOpacity(0.1),
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
              ? Colors.purple.withOpacity(0.8)
              : Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: isFocused ? [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
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
            return 'Lütfen e-posta adresinizi girin.';
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
                  ? Colors.pink.withOpacity(0.9)
                  : Colors.purple.withOpacity(0.7),
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
            Colors.purple.withOpacity(0.8),
            Colors.pink.withOpacity(0.7),
            Colors.orange.withOpacity(0.6), // Matlaştırılmış turuncu
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _isLoading ? null : _sendResetLink,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text(
                    'Sıfırlama Linki Gönder',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}