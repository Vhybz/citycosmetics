import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/auth_provider.dart';
import '../services/user_provider.dart';
import '../models/user_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _motionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    _motionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    _controller.forward();

    // Fail-safe timer
    final forceTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });

    // Exactly 6 seconds splash screen duration
    await Future.delayed(const Duration(seconds: 6));

    if (!mounted) {
      forceTimer.cancel();
      return;
    }

    try {
      final currentUser = ref.read(authServiceProvider).currentUser;

      if (currentUser != null) {
        ref.read(currentUserIdProvider.notifier).state = currentUser.id;

        try {
          final users = await ref
              .read(userProvider.notifier)
              .service
              .getUsers()
              .timeout(const Duration(seconds: 2));

          UserAccount? userAccount;
          try {
            userAccount = users.firstWhere((u) => u.id == currentUser.id);
          } catch (_) {
            userAccount = null;
          }

          if (userAccount != null && userAccount.status == AccountStatus.approved) {
            forceTimer.cancel();
            ref.read(sessionUserProfileProvider.notifier).state = userAccount;
            if (userAccount.isPasscodeEnabled &&
                userAccount.passcode != null &&
                userAccount.passcode!.isNotEmpty) {
              ref.read(passcodeUnlockedProvider.notifier).state = false;
            } else {
              ref.read(passcodeUnlockedProvider.notifier).state = true;
            }

            if (mounted) {
              switch (userAccount.activePrimaryRole) {
                case UserRole.admin:
                case UserRole.superAdmin:
                  Navigator.pushReplacementNamed(context, '/admin');
                  break;
                case UserRole.cashier:
                  Navigator.pushReplacementNamed(context, '/cashier');
                  break;
              }
            }
            return;
          }
        } catch (e) {
          debugPrint('Splash Auth Timeout/Error: $e');
        }
      }
    } catch (e) {
      debugPrint('Splash: Auth check error: $e');
    }

    forceTimer.cancel();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF0F172A); // Midnight Blue
    const bgBottom = Color(0xFF020617); // Deep Slate Navy
    const accentBlue = Color(0xFF2563EB); // Electric Sapphire
    const lightBlue = Color(0xFF60A5FA); // Vivid Light Blue
    const skyBlue = Color(0xFF93C5FD); // Silk Sky Blue

    return Scaffold(
      backgroundColor: bgBottom,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final progress = _motionAnimation.value;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Larger Realistic Storefront & Delivery Truck Animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: SizedBox(
                              width: 250,
                              height: 190,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(230, 160),
                                    painter: _ShopAndCarPainter(
                                      animationProgress: progress,
                                      accentColor: accentBlue,
                                    ),
                                  ),

                                  // Brand Badge Circle Overlay at Bottom Right
                                  Positioned(
                                    bottom: 0,
                                    right: 8,
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: accentBlue,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/logo/logo.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Clean Brand Name
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              const Text(
                                'CITY COSMETICS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4.0,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Subtitle in Blue
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 16, height: 1, color: lightBlue.withValues(alpha: 0.5)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      'RETAIL & WHOLESALE',
                                      style: TextStyle(
                                        color: skyBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 3.0,
                                      ),
                                    ),
                                  ),
                                  Container(width: 16, height: 1, color: lightBlue.withValues(alpha: 0.5)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Minimal, Elegant Blue Loading Line
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 130,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: const Color(0x22FFFFFF),
                                    valueColor: const AlwaysStoppedAnimation<Color>(lightBlue),
                                    minHeight: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'SUNYANI • GHANA',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter that renders a larger, highly realistic storefront and a delivery truck loaded with cargo boxes.
class _ShopAndCarPainter extends CustomPainter {
  final double animationProgress;
  final Color accentColor;

  _ShopAndCarPainter({
    required this.animationProgress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);

    final sidewalkPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    final shopWallPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final roofPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final glassPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final glassHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Warm interior glow that brightens as doors open
    final interiorGlowPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.35 + (animationProgress * 0.55))
      ..style = PaintingStyle.fill;

    final doorPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final truckBodyPaint = Paint()
      ..color = const Color(0xFFDC2626) // Deep realistic red delivery truck
      ..style = PaintingStyle.fill;

    final truckCabinPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = const Color(0xFFD97706) // Cardboard box brown
      ..style = PaintingStyle.fill;

    final boxTapePaint = Paint()
      ..color = const Color(0xFFFEF3C7) // Tape color
      ..style = PaintingStyle.fill;

    final wheelPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final rimPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    final windowPaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // --- Ground / Sidewalk ---
    final sidewalkRect = Rect.fromLTWH(center.dx - 100, center.dy + 48, 200, 16);
    canvas.drawRect(sidewalkRect, sidewalkPaint);
    canvas.drawRect(sidewalkRect, strokePaint);

    // --- 1. LARGER & MORE REALISTIC SHOP BUILDING ---
    final shopRect = Rect.fromCenter(center: Offset(center.dx + 20, center.dy - 8), width: 126, height: 92);

    // Warm Interior Glow (revealed as doors open)
    canvas.drawRect(
      Rect.fromLTWH(shopRect.left + 10, shopRect.top + 18, shopRect.width - 20, shopRect.height - 18),
      interiorGlowPaint,
    );

    // Shop Walls
    canvas.drawRect(shopRect, shopWallPaint);
    canvas.drawRect(shopRect, strokePaint);

    // Shop Awning / Roof Overhang with Trim
    final roofRect = Rect.fromLTWH(shopRect.left - 8, shopRect.top - 16, shopRect.width + 16, 16);
    canvas.drawRect(roofRect, roofPaint);
    canvas.drawRect(roofRect, strokePaint);
    canvas.drawRect(
      Rect.fromLTWH(roofRect.left, roofRect.bottom - 3, roofRect.width, 3),
      Paint()..color = Colors.white24,
    );

    // Illuminated Store Sign Board ("CITY COSMETICS")
    final signRect = Rect.fromCenter(center: Offset(shopRect.center.dx, shopRect.top - 8), width: 88, height: 14);
    canvas.drawRect(signRect, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(signRect.left + 6, signRect.top + 4, signRect.width - 12, 2),
      Paint()..color = accentColor,
    );

    // Large Glass Display Windows with Mullions (Pane Dividers)
    final windowLeft = Rect.fromLTWH(shopRect.left + 12, shopRect.top + 22, 28, 34);
    final windowRight = Rect.fromLTWH(shopRect.right - 40, shopRect.top + 22, 28, 34);
    canvas.drawRect(windowLeft, glassPaint);
    canvas.drawRect(windowRight, glassPaint);
    canvas.drawLine(Offset(windowLeft.center.dx, windowLeft.top), Offset(windowLeft.center.dx, windowLeft.bottom), strokePaint);
    canvas.drawLine(Offset(windowLeft.left, windowLeft.center.dy), Offset(windowLeft.right, windowLeft.center.dy), strokePaint);
    canvas.drawLine(Offset(windowRight.center.dx, windowRight.top), Offset(windowRight.center.dx, windowRight.bottom), strokePaint);
    canvas.drawLine(Offset(windowRight.left, windowRight.center.dy), Offset(windowRight.right, windowRight.center.dy), strokePaint);
    canvas.drawRect(Rect.fromLTWH(windowLeft.left + 4, windowLeft.top + 4, 3, 20), glassHighlightPaint);
    canvas.drawRect(Rect.fromLTWH(windowRight.left + 4, windowRight.top + 4, 3, 20), glassHighlightPaint);

    // --- 2. SHOP DOORS OPENING GRADUALLY ---
    final doorOpenProgress = ((animationProgress - 0.15) / 0.7).clamp(0.0, 1.0);
    const doorWidth = 16.0;
    const doorHeight = 48.0;
    final doorY = shopRect.bottom - doorHeight;

    // Left Glass Door
    final leftDoorX = shopRect.center.dx - doorWidth - (doorOpenProgress * 26);
    final leftDoorRect = Rect.fromLTWH(leftDoorX, doorY, doorWidth * (1.0 - (doorOpenProgress * 0.4)), doorHeight);
    canvas.drawRect(leftDoorRect, doorPaint);
    canvas.drawRect(leftDoorRect.deflate(2), glassPaint);

    // Right Glass Door
    final rightDoorX = shopRect.center.dx + (doorOpenProgress * 14);
    final rightDoorRect = Rect.fromLTWH(rightDoorX, doorY, doorWidth * (1.0 - (doorOpenProgress * 0.4)), doorHeight);
    canvas.drawRect(rightDoorRect, doorPaint);
    canvas.drawRect(rightDoorRect.deflate(2), glassPaint);

    // --- 3. DELIVERY TRUCK WITH BOXES INSIDE DRIVING TO THE SHOP ---
    final startX = -80.0;
    final endX = center.dx - 40.0;
    // Apply an ease-out curve to make the truck brake/decelerate smoothly as it parks
    final driveCurve = Curves.easeOutCubic.transform(animationProgress);
    final truckX = startX + (driveCurve * (endX - startX));
    final truckY = center.dy + 22.0;

    // Truck cargo box & cab
    final cargoRect = Rect.fromLTWH(truckX, truckY, 38, 26);
    final cabRect = Rect.fromLTWH(truckX + 38, truckY + 6, 20, 20);

    // Truck Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(truckX + 28, truckY + 28), width: 56, height: 6),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Draw Truck Cargo Body
    canvas.drawRect(cargoRect, truckBodyPaint);
    canvas.drawRect(cargoRect, strokePaint);
    
    // --- OPEN CARGO BAY (Dark interior so boxes look inside) ---
    final cargoBayRect = Rect.fromLTWH(truckX + 2, truckY + 2, 34, 22);
    canvas.drawRect(cargoBayRect, Paint()..color = const Color(0xFF0F172A)); // Dark interior

    // --- BOXES VISIBLE INSIDE TRUCK CARGO ---
    final box1 = Rect.fromLTWH(truckX + 4, truckY + 14, 12, 10);
    final box2 = Rect.fromLTWH(truckX + 18, truckY + 12, 14, 12);
    canvas.drawRect(box1, boxPaint);
    canvas.drawRect(box1, strokePaint);
    canvas.drawRect(box2, boxPaint);
    canvas.drawRect(box2, strokePaint);
    canvas.drawLine(Offset(box1.center.dx, box1.top), Offset(box1.center.dx, box1.bottom), boxTapePaint);
    canvas.drawLine(Offset(box2.center.dx, box2.top), Offset(box2.center.dx, box2.bottom), boxTapePaint);

    // Draw Truck Cab
    canvas.drawRect(cabRect, truckCabinPaint);
    canvas.drawRect(cabRect, strokePaint);

    // Truck Cab Windshield & Side Window
    final windshieldRect = Rect.fromLTWH(truckX + 48, truckY + 8, 7, 9);
    final sideWindowRect = Rect.fromLTWH(truckX + 40, truckY + 8, 6, 9);
    canvas.drawRect(windshieldRect, windowPaint);
    canvas.drawRect(sideWindowRect, windowPaint);

    // Side Mirror
    canvas.drawRect(
      Rect.fromLTWH(truckX + 55, truckY + 11, 2, 5),
      Paint()..color = Colors.black87,
    );

    // Realistic Spinning Wheels
    void drawSpinningWheel(Offset wheelCenter) {
      final wheelRect = Rect.fromCenter(center: wheelCenter, width: 12, height: 12);
      canvas.drawOval(wheelRect, wheelPaint);
      canvas.drawOval(wheelRect.deflate(3.5), rimPaint);
      
      // Calculate wheel rotation based on distance traveled so it rolls realistically!
      final rotationAngle = (truckX * 0.2); 
      
      canvas.save();
      canvas.translate(wheelCenter.dx, wheelCenter.dy);
      canvas.rotate(rotationAngle); 
      canvas.drawLine(const Offset(-3, 0), const Offset(3, 0), Paint()..color=Colors.black87..strokeWidth=1);
      canvas.drawLine(const Offset(0, -3), const Offset(0, 3), Paint()..color=Colors.black87..strokeWidth=1);
      canvas.restore();
    }

    drawSpinningWheel(Offset(truckX + 11, truckY + 26));
    drawSpinningWheel(Offset(truckX + 44, truckY + 26));

    // Headlights and Beam
    if (animationProgress > 0.3) {
      final headlightPaint = Paint()
        ..color = Colors.yellowAccent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(truckX + 58, truckY + 16), 3.5, headlightPaint);

      // Light beam on ground as it approaches shop
      final beamPath = Path()
        ..moveTo(truckX + 58, truckY + 18)
        ..lineTo(truckX + 85, truckY + 28)
        ..lineTo(truckX + 58, truckY + 24)
        ..close();
      canvas.drawPath(beamPath, Paint()..color = Colors.yellowAccent.withValues(alpha: 0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _ShopAndCarPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}
