import 'package:flutter/material.dart';
import '../core/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Smart Cosmetics POS',
      subtitle: '21ST CENTURY BEAUTY RETAIL',
      description: 'Streamline cosmetic sales, track stock, and manage your beauty store effortlessly.',
      icon: Icons.storefront_rounded,
      color: const Color(0xFF3B82F6), // Electric Blue
    ),
    OnboardingData(
      title: 'Barcoded Precision',
      subtitle: 'ZERO LEAKAGE, FULL CONTROL',
      description: 'Scan product barcodes for instant register checkout and 100% inventory precision.',
      icon: Icons.qr_code_scanner_rounded,
      color: const Color(0xFF10B981), // Emerald Green
    ),
    OnboardingData(
      title: 'Growth Analytics',
      subtitle: 'DATA-DRIVEN DOMINANCE',
      description: 'Real-time profit tracking and business insights. Manage multiple branches from your smartphone.',
      icon: Icons.insights_rounded,
      color: const Color(0xFF8B5CF6), // Royal Purple
    ),
    OnboardingData(
      title: 'Offline Syncing',
      subtitle: 'UNSTOPPABLE RELIABILITY',
      description: 'No internet? No problem. Complete sales offline and sync automatically when network returns.',
      icon: Icons.cloud_done_rounded,
      color: const Color(0xFF06B6D4), // Cyan
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmall = size.height < 700;
    const blueBlack = AppColors.primaryBlueBlack; // Color(0xFF0F172A)
    const darkNavy = Color(0xFF020617);

    return Scaffold(
      backgroundColor: darkNavy,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [blueBlack, darkNavy],
          ),
        ),
        child: Stack(
          children: [
            // Soft geometric glowing circles (No background images)
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pages[_currentPage].color.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pages[_currentPage].color.withValues(alpha: 0.06),
                ),
              ),
            ),

            // 1. Content PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) => setState(() => _currentPage = page),
              itemCount: _pages.length,
              itemBuilder: (context, index) => _buildPage(_pages[index], index == _currentPage, isSmall),
            ),

            // 2. Top Branding & Skip
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storefront_rounded, color: Colors.blueAccent, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'CITY COSMETICS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Bottom Controls
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 30,
              right: 30,
              child: Column(
                children: [
                  // Progress Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) => _buildDot(index)),
                  ),
                  SizedBox(height: isSmall ? 30 : 40),
                  
                  // Action Button
                  Center(
                    child: SizedBox(
                      width: size.width > 460 ? 400 : double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            Navigator.pushReplacementNamed(context, '/login');
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500), 
                              curve: Curves.easeInOut
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].color,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: _pages[_currentPage].color.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Row(
                            key: ValueKey(_currentPage),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _pages.length - 1 ? 'GET STARTED' : 'CONTINUE',
                                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 15),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                _currentPage == _pages.length - 1 ? Icons.check_circle_outline : Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data, bool isActive, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Animated Icon / Graphic Badge
          AnimatedScale(
            duration: const Duration(milliseconds: 600),
            scale: isActive ? 1.0 : 0.6,
            curve: Curves.elasticOut,
            child: Container(
              padding: EdgeInsets.all(isSmall ? 28 : 36),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: data.color.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: data.color.withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                ],
              ),
              child: Icon(data.icon, size: isSmall ? 70 : 90, color: data.color),
            ),
          ),
          SizedBox(height: isSmall ? 32 : 48),
          
          // Text Content
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isActive ? 1.0 : 0.0,
            child: Column(
              children: [
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 28 : 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 14 : 16,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmall ? 100 : 120), // Bottom space for controls
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isSelected = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isSelected ? 32 : 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? _pages[_currentPage].color : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: _pages[_currentPage].color.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title, 
    required this.subtitle,
    required this.description, 
    required this.icon,
    required this.color,
  });
}
