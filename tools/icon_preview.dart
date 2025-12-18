import 'package:flutter/material.dart';

/// Cookie Finder App Icon Preview Tool
/// Run this standalone to preview your app icon design
/// 
/// Usage: 
/// 1. Copy this to a new Flutter project or use it with your main app
/// 2. Set IconPreviewApp as your home widget temporarily
/// 3. Run and see how your icon looks at different sizes

void main() {
  runApp(const IconPreviewApp());
}

class IconPreviewApp extends StatelessWidget {
  const IconPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookie Finder Icon Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDAA06D)),
      ),
      home: const IconPreviewPage(),
    );
  }
}

class IconPreviewPage extends StatelessWidget {
  const IconPreviewPage({super.key});

  // Cookie Finder brand colors
  static const Color primaryColor = Color(0xFFDAA06D);
  static const Color primaryDark = Color(0xFFCF5A0C);
  static const Color accentColor = Color(0xFF8B5A3C);
  static const Color chipColor = Color(0xFF5D4037);
  static const Color cookieBase = Color(0xFFE8C59D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Cookie Finder - Icon Preview'),
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main Icon Preview
            const Text(
              'Main Icon Design',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 24),
            
            // Large preview - Variant A (Cookie with magnifying glass)
            _buildIconVariant(
              size: 192,
              label: 'Variant A: Cookie + Search',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cookie base
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cookieBase,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  // Chocolate chips
                  ..._buildChocolateChips(50),
                  // Magnifying glass overlay
                  Positioned(
                    right: 25,
                    bottom: 25,
                    child: Icon(
                      Icons.search,
                      size: 48,
                      color: Colors.white.withOpacity(0.9),
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Variant B - Simple cookie icon
            _buildIconVariant(
              size: 192,
              label: 'Variant B: Simple Cookie',
              child: const Icon(
                Icons.cookie,
                size: 100,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Variant C - CF Monogram
            _buildIconVariant(
              size: 192,
              label: 'Variant C: CF Monogram',
              child: const Text(
                'CF',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -4,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),
            
            // Size Variations
            const Text(
              'Size Variations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [192, 144, 96, 72, 48, 36].map((size) {
                return Column(
                  children: [
                    _buildMiniIcon(size.toDouble()),
                    const SizedBox(height: 8),
                    Text(
                      '${size}px',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),
            
            // On different backgrounds
            const Text(
              'Background Tests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                Colors.white,
                Colors.black,
                const Color(0xFF1E1E1E),
                const Color(0xFFE3F2FD),
                const Color(0xFFF3E5F5),
              ].map((bgColor) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildMiniIcon(72),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),
            
            // Color Palette Reference
            const Text(
              'Brand Colors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildColorSwatch('Primary', primaryColor, '#DAA06D'),
                _buildColorSwatch('Primary Dark', primaryDark, '#CF5A0C'),
                _buildColorSwatch('Accent', accentColor, '#8B5A3C'),
                _buildColorSwatch('Chip', chipColor, '#5D4037'),
                _buildColorSwatch('Cookie Base', cookieBase, '#E8C59D'),
              ],
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildIconVariant({
    required double size,
    required String label,
    required Widget child,
  }) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryDark, primaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(child: child),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryDark, primaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Icon(
        Icons.cookie,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }

  List<Widget> _buildChocolateChips(double radius) {
    final chips = [
      const Offset(-25, -20),
      const Offset(15, -30),
      const Offset(-35, 10),
      const Offset(30, 5),
      const Offset(-10, 25),
      const Offset(20, 30),
    ];

    return chips.map((offset) {
      return Positioned(
        left: radius + offset.dx - 6,
        top: radius + offset.dy - 6,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: chipColor,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildColorSwatch(String name, Color color, String hex) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        Text(
          hex,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }
}


