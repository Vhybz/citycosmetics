import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/auth_provider.dart';
import '../services/user_provider.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller, 
      curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.95, curve: Curves.easeInOut),
      ),
    );

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    _controller.forward();
    
    // Fail-safe: Force navigation after 8 seconds no matter what
    final forceTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        debugPrint('Splash: FAIL-SAFE TRIGGERED. Forcing navigation to onboarding.');
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });

    // Minimum 4 seconds of splash animation
    await Future.delayed(const Duration(seconds: 4));
    
    if (!mounted) {
      forceTimer.cancel();
      return;
    }

    try {
      final currentUser = ref.read(authServiceProvider).currentUser;
      
      if (currentUser != null) {
        ref.read(currentUserIdProvider.notifier).state = currentUser.id;
        
        try {
          final users = await ref.read(userProvider.notifier).service.getUsers()
              .timeout(const Duration(seconds: 3));
              
          UserAccount? userAccount;
          try {
            userAccount = users.firstWhere((u) => u.id == currentUser.id);
          } catch (_) {
            userAccount = null;
          }

          if (userAccount != null && userAccount.status == AccountStatus.approved) {
            forceTimer.cancel();
            ref.read(sessionUserProfileProvider.notifier).state = userAccount;
            if (userAccount.isPasscodeEnabled && userAccount.passcode != null && userAccount.passcode!.isNotEmpty) {
              ref.read(passcodeUnlockedProvider.notifier).state = false;
            } else {
              ref.read(passcodeUnlockedProvider.notifier).state = true;
            }
            if (mounted) {
              switch (userAccount.activePrimaryRole) {
                case UserRole.admin:
                  Navigator.pushReplacementNamed(context, '/admin');
                  break;
                case UserRole.butcher:
                  Navigator.pushReplacementNamed(context, '/butcher');
                  break;
                case UserRole.cashier:
                  Navigator.pushReplacementNamed(context, '/cashier');
                  break;
                case UserRole.superAdmin:
                  Navigator.pushReplacementNamed(context, '/admin/super');
                  break;
              }
            }
            return;
          }
        } catch (e) {
          debugPrint('Splash Auth Error (Likely Timeout): $e');
        }
      }
    } catch (e) {
      debugPrint('Splash: Unexpected auth access error: $e');
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
    const blueBlack = AppColors.primaryBlueBlack; // Color(0xFF0F172A)
    const darkNavy = Color(0xFF020617);

    return Scaffold(
      backgroundColor: blueBlack,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [blueBlack, darkNavy],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft geometric glowing circles (No background images)
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigoAccent.withValues(alpha: 0.05),
                ),
              ),
            ),

            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.25),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          Text(
                            'CITY COSMETICS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'SMART POS & INVENTORY SYSTEM',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),

                    // Modern Ring Loading Animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Initializing System... ${(_progressAnimation.value * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
