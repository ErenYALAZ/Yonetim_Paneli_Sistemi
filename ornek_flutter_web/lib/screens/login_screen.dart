import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ornek_flutter_web/screens/intro_screen.dart';
import 'package:ornek_flutter_web/screens/signup_screen.dart';
import 'package:ornek_flutter_web/screens/forgot_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late AnimationController _particleController;
  late AnimationController _loadingController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _pulseAnimation;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _loadingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_loadingController);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

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

    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    if (savedEmail != null) {
      _emailController.text = savedEmail;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  Future<void> _handleRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text.trim());
    } else {
      await prefs.remove('email');
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      await _handleRememberMe();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const IntroScreen()),
        );
      }
    } on AuthException catch (e) {
      if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      }
    } catch (e) {
       if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beklenmedik bir hata oluştu: $e'), backgroundColor: Colors.red),
      );
      }
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
    _loadingController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF283593),
              Color(0xFF3949ab),
              Color(0xFF5c6bc0),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(50, (index) => _buildParticle(context, index)),
            
            // Circular text around the login form
            Center(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: (sin(_fadeAnimation.value * pi * 2) * 0.5 + 0.5).clamp(0.0, 1.0),
                    child: SizedBox(
                      width: 700,
                      height: 700,
                      child: CustomPaint(
                        painter: CircularTextPainter(
                          text: 'Gravity Robotik Mühendislik A.Ş',
                          radius: 320,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Circular progress indicator background
            Center(
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyan.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Stack(
                  children: [
                    // Outer loading ring
                    AnimatedBuilder(
                      animation: _loadingAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _loadingAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 600,
                            height: 600,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.transparent,
                                width: 6,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Pulse effect
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 600,
                            height: 600,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyan.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Animated circular segments
                    ...List.generate(40, (index) => _buildCircularSegment(index)),
                  ],
                ),
              ),
            ),
            
            // Login form
            Center(
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(50),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Login title
                      Text(
                        'Login',
                        style: GoogleFonts.orbitron(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan,
                        ),
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.3),
                      
                      const SizedBox(height: 50),
                      
                      // Email field
                      _buildModernTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        focusNode: _emailFocusNode,
                        isFocused: _emailFocused,
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.3),
                      
                      const SizedBox(height: 40),
                      
                      // Password field
                      _buildModernTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        focusNode: _passwordFocusNode,
                        isFocused: _passwordFocused,
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: 0.3),
                      
                      const SizedBox(height: 40),
                      
                      // Remember me and Forgot password row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remember me checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: Colors.cyan,
                                checkColor: Colors.black,
                                side: BorderSide(
                                  color: Colors.cyan.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              Text(
                                'Remember Me',
                                style: TextStyle(
                                  color: Colors.cyan.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          // Forgot password
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.withOpacity(0.2),
                                  Colors.pink.withOpacity(0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ));
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.purple.withOpacity(0.8), Colors.pink.withOpacity(0.7), Colors.orange.withOpacity(0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 600.ms),
                      
                      const SizedBox(height: 40),
                      
                      // Login button
                      _buildModernButton().animate().fadeIn(delay: 800.ms, duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                      
                      const SizedBox(height: 30),
                      
                      // Signup link
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withOpacity(0.2),
                              Colors.red.withOpacity(0.2),
                              Colors.pink.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ));
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Colors.orange.withOpacity(0.9), Colors.red.withOpacity(0.8), Colors.pink.withOpacity(0.8), Colors.purple.withOpacity(0.9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                            child: Text(
                              'Signup',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.orange.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                  Shadow(
                                    color: Colors.pink.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.8, 0.8)),
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required FocusNode focusNode,
    required bool isFocused,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isFocused 
              ? Colors.blue.withOpacity(0.8)
              : Colors.cyan.withOpacity(0.3),
          width: isFocused ? 2 : 1,
        ),
        color: isFocused 
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        boxShadow: isFocused 
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bu alan zorunludur';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hintText,
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
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 20,
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
            Colors.cyan.withOpacity(0.8),
            Colors.cyan.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _isLoading ? null : _signIn,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Login',
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

  Widget _buildParticle(BuildContext context, int index) {
    final random = Random(index);
    final size = random.nextDouble() * 4 + 1;
    final opacity = random.nextDouble() * 0.5 + 0.1;
    final duration = random.nextInt(3000) + 2000;
    final delay = random.nextInt(2000);
    
    return Positioned(
      left: random.nextDouble() * MediaQuery.of(context).size.width,
      top: random.nextDouble() * MediaQuery.of(context).size.height,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.cyan.withOpacity(opacity),
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).fadeIn(
        delay: Duration(milliseconds: delay),
        duration: Duration(milliseconds: duration),
      ),
    );
  }

  Widget _buildCircularSegment(int index) {
    final angle = (index * 360 / 40) * (3.14159 / 180);
    final radius = 280.0;
    final segmentLength = 15.0;
    
    return Positioned(
      left: 300 + (radius * cos(angle)) - 2,
      top: 300 + (radius * sin(angle)) - 2,
      child: Transform.rotate(
        angle: angle + (3.14159 / 2),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final opacity = (sin(_animationController.value * 2 * 3.14159 + angle) + 1) / 2;
            return Container(
              width: 4,
              height: segmentLength,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.cyan.withOpacity(opacity * 0.8),
                    Colors.blue.withOpacity(opacity * 0.4),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoadingRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Create gradient paint for the loading ring
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    // Draw multiple arcs with different colors and opacities
    for (int i = 0; i < 8; i++) {
      final startAngle = (i * 45) * (3.14159 / 180);
      final sweepAngle = 30 * (3.14159 / 180);
      
      paint.color = Colors.cyan.withOpacity(0.8 - (i * 0.1));
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
    
    // Add some sparkle effects
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (3.14159 / 180);
      final sparkleRadius = radius + 15;
      final sparkleCenter = Offset(
        center.dx + sparkleRadius * cos(angle),
        center.dy + sparkleRadius * sin(angle),
      );
      
      final sparklePaint = Paint()
        ..color = Colors.blue.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(sparkleCenter, 2, sparklePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CircularTextPainter extends CustomPainter {
  final String text;
  final double radius;
  final double fontSize;
  final Color color;

  CircularTextPainter({
    required this.text,
    required this.radius,
    required this.fontSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Calculate the angle for each character
    final totalAngle = pi; // Half circle (180 degrees)
    final anglePerChar = totalAngle / (text.length - 1);

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final angle = -pi / 2 - (totalAngle / 2) + (i * anglePerChar); // Start from top and go clockwise

      // Calculate position for each character
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      // Create text span with shadows
      textPainter.text = TextSpan(
        text: char,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
          shadows: [
            Shadow(
              offset: const Offset(0, 0),
              blurRadius: 15,
              color: Colors.cyan.withOpacity(0.6),
            ),
            Shadow(
              offset: const Offset(0, 0),
              blurRadius: 30,
              color: Colors.blue.withOpacity(0.4),
            ),
            Shadow(
              offset: const Offset(0, 1),
              blurRadius: 5,
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        ),
      );

      textPainter.layout();

      // Save canvas state
      canvas.save();

      // Translate to character position
      canvas.translate(x, y);

      // Rotate the character to follow the circle
      canvas.rotate(angle + pi / 2);

      // Draw the character centered
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      // Restore canvas state
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}