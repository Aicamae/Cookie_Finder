import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

List<double> softmax(List<double> x) {
  if (x.isEmpty) return x;
  final maxVal = x.reduce((a, b) => a > b ? a : b);
  final exps = x.map((v) => math.exp(v - maxVal)).toList();
  final sum = exps.fold<double>(0, (s, v) => s + v);
  if (sum == 0) {
    return List<double>.filled(x.length, 1.0 / x.length);
  }
  return exps.map((v) => v / sum).toList();
}

List<double> sharpenProbabilities(
  List<double> probs, {
  double temperature = 0.15,
}) {
  if (probs.isEmpty) return probs;
  final logProbs = probs.map((p) => p > 1e-10 ? math.log(p) : -23.0).toList();
  final scaled = logProbs.map((l) => l / temperature).toList();
  return softmax(scaled);
}

// App theme colors
class AppColors {
  static const Color primary = Color(0xFFDAA06D);
  static const Color primaryDark = Color(0xFFCF5A0C);
  static const Color accent = Color(0xFF8B5A3C);
  static const Color background = Color(0xFFFAF6F1);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookie Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const CoverPage(),
    );
  }
}

// ==================== COVER PAGE ====================
class CoverPage extends StatefulWidget {
  const CoverPage({super.key});

  @override
  State<CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends State<CoverPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToMain,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              'assets/coverpage.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      const Color(0xFFF5E6D3),
                    ],
                  ),
                ),
              ),
            ),
            // Dark Overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    // Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.cookie_rounded,
                        size: 64,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.white,
                          const Color(0xFFFFE4C4),
                          Colors.white,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Cookie Finder',
                        style: GoogleFonts.titanOne(
                          fontSize: 48,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Decorative line
                    Container(
                      width: 80,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Quote
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"Every cookie has a story,\nlet\'s discover yours."',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              height: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                    // Tap to find
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryDark.withValues(
                                          alpha: 0.9,
                                        ),
                                        AppColors.primary.withValues(
                                          alpha: 0.9,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryDark.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.touch_app_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Tap to Find',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PolkaDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(98765);
    final baseColor = const Color(0xFF6B3E26);
    final glowColor = const Color(0xFF8B5A3C);
    final highlightColor = const Color(0xFFD9A27A);

    final sections = 5;
    final sectionWidth = size.width / sections;

    final dots = [
      {"size": 14.0, "count": 3, "opacity": 0.95},
      {"size": 10.0, "count": 4, "opacity": 0.9},
      {"size": 8.0, "count": 5, "opacity": 0.85},
    ];

    List<Offset> existingDots = [];
    bool isTooClose(Offset newPoint, double minDistance) {
      for (final dot in existingDots) {
        if ((dot - newPoint).distance < minDistance) {
          return true;
        }
      }
      return false;
    }

    for (int section = 0; section < sections; section++) {
      for (final dot in dots) {
        final dotSize = dot["size"] as double;
        final dotOpacity = dot["opacity"] as double;

        for (int i = 0; i < (dot["count"] as int); i++) {
          for (int attempt = 0; attempt < 10; attempt++) {
            final x =
                section * sectionWidth + random.nextDouble() * sectionWidth;
            final y = random.nextDouble() * size.height;
            final newPoint = Offset(x, y);

            if (!isTooClose(newPoint, dotSize * 2) &&
                x > dotSize &&
                x < size.width - dotSize &&
                y > dotSize &&
                y < size.height - dotSize) {
              var paint = Paint()..color = glowColor.withValues(alpha: 0.35);
              paint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
              canvas.drawCircle(newPoint, (dotSize / 2) + 2, paint);

              paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
              paint.color = highlightColor.withValues(alpha: 0.06);
              canvas.drawCircle(newPoint, (dotSize / 2) - 1, paint);

              paint.maskFilter = null;
              paint.color = baseColor.withValues(alpha: dotOpacity);
              canvas.drawCircle(newPoint, dotSize / 2, paint);

              existingDots.add(newPoint);
              break;
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class Classifier {
  tfl.Interpreter? _interpreter;
  List<String> _labels = [];
  int _inputSize = 224;
  bool _isFloat = true;

  List<String> get labels => _labels;

  Future<void> load() async {
    if (_interpreter != null) return;
    final interpreter = await tfl.Interpreter.fromAsset(
      'assets/model_unquant.tflite',
    );
    _interpreter = interpreter;
    final inputShape = interpreter.getInputTensor(0).shape;
    _inputSize = inputShape.length >= 3 ? inputShape[1] : 224;
    _isFloat = true;
    final labelsStr = await rootBundle.loadString('assets/labels.txt');
    _labels = labelsStr
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.replaceFirst(RegExp(r'^\s*\d+\s*'), '').trim())
        .toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  Future<List<double>> classifyProbs(File file) async {
    final interpreter = _interpreter;
    if (interpreter == null) throw StateError('Interpreter not loaded');
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('Failed to decode image');
    final shortest = decoded.width < decoded.height
        ? decoded.width
        : decoded.height;
    final cropX = ((decoded.width - shortest) / 2).floor();
    final cropY = ((decoded.height - shortest) / 2).floor();
    final square = img.copyCrop(
      decoded,
      x: cropX,
      y: cropY,
      width: shortest,
      height: shortest,
    );
    final resized = img.copyResize(
      square,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    if (_isFloat) {
      final input = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (_) => List.generate(_inputSize, (_) => List.filled(3, 0.0)),
        ),
      );
      final rgba = resized.getBytes(order: img.ChannelOrder.rgba);
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final base = (y * _inputSize + x) * 4;
          final r = rgba[base] / 255.0;
          final g = rgba[base + 1] / 255.0;
          final b = rgba[base + 2] / 255.0;
          input[0][y][x][0] = r;
          input[0][y][x][1] = g;
          input[0][y][x][2] = b;
        }
      }
      final outputTensor = interpreter.getOutputTensor(0);
      final numClasses = outputTensor.shape.last;
      final output = [List.filled(numClasses, 0.0)];
      interpreter.run(input, output);
      final rawOutput = (output[0] as List).cast<double>();
      return sharpenProbabilities(rawOutput);
    } else {
      final input = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (_) => List.generate(_inputSize, (_) => List.filled(3, 0)),
        ),
      );
      final rgba = resized.getBytes(order: img.ChannelOrder.rgba);
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final base = (y * _inputSize + x) * 4;
          input[0][y][x][0] = rgba[base];
          input[0][y][x][1] = rgba[base + 1];
          input[0][y][x][2] = rgba[base + 2];
        }
      }
      final outputTensor = interpreter.getOutputTensor(0);
      final numClasses = outputTensor.shape.last;
      final output = [List.filled(numClasses, 0)];
      interpreter.run(input, output);
      final rawOutput = (output[0] as List)
          .map((e) => (e as int).toDouble())
          .toList();
      return sharpenProbabilities(rawOutput);
    }
  }

  Future<List<Map<String, dynamic>>> classify(File file, {int topK = 3}) async {
    final probs = await classifyProbs(file);
    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < probs.length; i++) {
      final label = i < _labels.length ? _labels[i] : 'Class $i';
      results.add({'label': label, 'index': i, 'confidence': probs[i]});
    }
    results.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );
    return results.take(topK).toList();
  }

  String formatTopResult(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return 'No result';
    final best = results.first;
    return '${best['label']}';
  }
}

class FungiInfo {
  final String name;
  final String description;
  final String imagePath;

  const FungiInfo({
    required this.name,
    required this.description,
    required this.imagePath,
  });
}

const List<FungiInfo> kFungiDictionary = [
  FungiInfo(
    name: 'Chocolate Chip Cookies',
    description:
        'Classic buttery cookies loaded with sweet chocolate chips; crispy on the edges and soft in the center.',
    imagePath: 'assets/photos/ccc.jpg',
  ),
  FungiInfo(
    name: 'Sugared Cookies',
    description:
        'Soft, chewy cookies coated in granulated sugar, giving them a lightly crisp, sparkly exterior.',
    imagePath: 'assets/photos/sc.jpg',
  ),
  FungiInfo(
    name: 'Crinkle Cookies',
    description:
        'Soft, fudgy cookies rolled in powdered sugar before baking, creating a cracked "crinkle" pattern on top.',
    imagePath: 'assets/photos/cc.jpg',
  ),
  FungiInfo(
    name: 'Double Chocolate Cookies',
    description:
        'Rich chocolate cookies made with cocoa powder and chocolate chips for a deeper, more intense chocolate flavor.',
    imagePath: 'assets/photos/dcc.jpg',
  ),
  FungiInfo(
    name: 'Red Velvet Cookies',
    description:
        'Cookies inspired by red velvet cake—soft, moist, slightly cocoa-flavored, and often paired with cream cheese frosting or chips.',
    imagePath: 'assets/photos/rvc.jpg',
  ),
  FungiInfo(
    name: 'Peanut Butter Cookies',
    description:
        'Dense, chewy cookies with a strong peanut butter flavor, usually marked with a crisscross fork pattern.',
    imagePath: 'assets/photos/pbc.jpg',
  ),
  FungiInfo(
    name: 'Pinwheel Cookies',
    description:
        'Swirled cookies featuring two contrasting doughs (like vanilla and chocolate) rolled together for a spiral design.',
    imagePath: 'assets/photos/pc.jpg',
  ),
  FungiInfo(
    name: 'Thumbprint Cookies',
    description:
        'Soft cookies with a small indentation in the center (made with a thumb) filled with jam, chocolate, or other sweet fillings',
    imagePath: 'assets/photos/tc.jpg',
  ),
  FungiInfo(
    name: 'Almond Cookies',
    description:
        'Light, fragrant cookies made with almond flour or extract, offering a subtle nutty flavor and crispy bite.',
    imagePath: 'assets/photos/ac.jpg',
  ),
  FungiInfo(
    name: 'Macaron Cookies',
    description:
        'Delicate French sandwich cookies made with almond flour and meringue, filled with ganache, buttercream, or jam; crisp outside, chewy inside.',
    imagePath: 'assets/photos/mc.jpg',
  ),
];

// Helper function to find cookie info by class name
FungiInfo? findCookieInfoByName(String className) {
  final key = className.toLowerCase().trim();

  // First try exact match
  for (final f in kFungiDictionary) {
    if (f.name.toLowerCase() == key) {
      return f;
    }
  }

  // Then try if one contains the other completely
  for (final f in kFungiDictionary) {
    final n = f.name.toLowerCase();
    if (key.contains(n) || n.contains(key)) {
      return f;
    }
  }

  // Score-based matching - find best match by counting matching words
  FungiInfo? bestMatch;
  int bestScore = 0;

  final keyWords = key.split(' ').where((w) => w.length > 2).toSet();

  for (final f in kFungiDictionary) {
    final nameWords = f.name
        .toLowerCase()
        .split(' ')
        .where((w) => w.length > 2)
        .toSet();
    final matchingWords = keyWords.intersection(nameWords).length;

    // Give extra score for matching distinctive words (not common words like "cookies")
    int score = matchingWords;
    for (final word in keyWords) {
      if (nameWords.contains(word) && word != 'cookies' && word != 'cookie') {
        score += 2; // Bonus for non-common word matches
      }
    }

    if (score > bestScore) {
      bestScore = score;
      bestMatch = f;
    }
  }

  return bestScore > 0 ? bestMatch : null;
}

// Main Navigation Page with Bottom Nav Bar
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final Classifier _classifier = Classifier();
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _classifier.load();
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }

  void _triggerRefresh() {
    setState(() {
      _refreshCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ScanGalleryPage(
        classifier: _classifier,
        onScanComplete: _triggerRefresh,
        refreshKey: _refreshCounter,
      ),
      AnalyticsPage(refreshKey: _refreshCounter),
      HistoryPage(refreshKey: _refreshCounter),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _ModernBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.camera_alt_rounded,
                Icons.camera_alt_outlined,
                'Scan',
              ),
              _buildNavItem(
                1,
                Icons.analytics_rounded,
                Icons.analytics_outlined,
                'Analytics',
              ),
              _buildNavItem(
                2,
                Icons.history_rounded,
                Icons.history_outlined,
                'History',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(isSelected),
                padding: isSelected ? const EdgeInsets.all(8) : EdgeInsets.zero,
                decoration: isSelected
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      )
                    : null,
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: isSelected ? 20 : 24,
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SCAN & GALLERY PAGE ====================
class ScanGalleryPage extends StatefulWidget {
  final Classifier classifier;
  final VoidCallback onScanComplete;
  final int refreshKey;

  const ScanGalleryPage({
    super.key,
    required this.classifier,
    required this.onScanComplete,
    required this.refreshKey,
  });

  @override
  State<ScanGalleryPage> createState() => _ScanGalleryPageState();
}

class _ScanGalleryPageState extends State<ScanGalleryPage> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;
  bool _scanning = false;

  Future<String?> _saveImageLocally(File sourceFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${appDir.path}/cookie_scans');
      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await sourceFile.copy('${scansDir.path}/$fileName');
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _storeLog(
    String className,
    double accuracyPercent,
    String? imagePath,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('CookieFinder_Logs')
          .doc('logs');
      await docRef.set({
        'logs': FieldValue.arrayUnion([
          {
            'ClassType': className,
            'Accuracy_Rate': accuracyPercent,
            'Time': Timestamp.now(),
            'ImagePath': imagePath ?? '',
          },
        ]),
      }, SetOptions(merge: true));
      widget.onScanComplete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to store log: $e')));
    }
  }

  Future<void> _runClassificationAndShow(File file) async {
    await widget.classifier.load();
    final probs = await widget.classifier.classifyProbs(file);
    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < probs.length; i++) {
      results.add({
        'label': i < widget.classifier.labels.length
            ? widget.classifier.labels[i]
            : 'Class $i',
        'index': i,
        'confidence': probs[i],
      });
    }
    results.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ResultBottomSheet(
        file: file,
        results: results,
        classifier: widget.classifier,
        onStore: (className, accuracy) async {
          final imagePath = await _saveImageLocally(file);
          await _storeLog(className, accuracy, imagePath);
        },
      ),
    );
  }

  Future<void> _scanWithSystemCamera() async {
    if (_scanning || !mounted) return;
    setState(() => _scanning = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted) return;
      if (picked != null) await _runClassificationAndShow(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to scan: $e')));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (picked != null) await _runClassificationAndShow(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Cookie Finder',
          style: GoogleFonts.titanOne(
            fontSize: 28,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                blurRadius: 4,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
          child: CustomPaint(painter: PolkaDotPainter()),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpeg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Container(
          color: Colors.black.withValues(alpha: 0.05),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Scan Card
                  _buildMainScanCard(),
                  const SizedBox(height: 20),
                  // Cookie Gallery
                  _buildCookieGallerySection(),
                  const SizedBox(height: 20),
                  // Quick Actions
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainScanCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withValues(alpha: 0.95)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.cookie_rounded,
                    color: AppColors.primaryDark,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Your Cookie',
                        style: GoogleFonts.titanOne(
                          fontSize: 24,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'Scan or upload to identify',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Scan',
                    isPrimary: true,
                    isLoading: _scanning,
                    onTap: _scanWithSystemCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    isPrimary: false,
                    isLoading: _picking,
                    onTap: _pickImage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookieGallerySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primaryDark, size: 22),
              const SizedBox(width: 8),
              Text(
                'Cookie Collection',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to learn about each cookie type',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kFungiDictionary.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final f = kFungiDictionary[index];
                return _CookieCard(fungi: f, onTap: () => _showCookieDetail(f));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCookieDetail(FungiInfo f) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  f.imagePath,
                  height: 160,
                  width: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, st) => Container(
                    height: 160,
                    width: 160,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                f.name,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                f.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Tips',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            Icons.lightbulb_outline,
            'Hold camera steady for best results',
          ),
          const SizedBox(height: 8),
          _buildTipItem(Icons.wb_sunny_outlined, 'Ensure good lighting'),
          const SizedBox(height: 8),
          _buildTipItem(
            Icons.center_focus_strong,
            'Center the cookie in frame',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppColors.primaryDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.primary, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isPrimary ? Colors.white : AppColors.primaryDark,
                  ),
                )
              else
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : AppColors.primaryDark,
                  size: 22,
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isPrimary ? Colors.white : AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CookieCard extends StatelessWidget {
  final FungiInfo fungi;
  final VoidCallback onTap;

  const _CookieCard({required this.fungi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                fungi.imagePath,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                errorBuilder: (c, e, st) => Container(
                  height: 70,
                  width: 70,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.cookie, color: Colors.brown),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                fungi.name,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBottomSheet extends StatelessWidget {
  final File file;
  final List<Map<String, dynamic>> results;
  final Classifier classifier;
  final Future<void> Function(String className, double accuracy) onStore;

  const _ResultBottomSheet({
    required this.file,
    required this.results,
    required this.classifier,
    required this.onStore,
  });

  // Check if the image is likely a cookie based on confidence threshold
  bool _isLikelyCookie(double confidence) {
    // If the top prediction confidence is below 50%, it's likely not a cookie
    return confidence >= 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final best = results.isNotEmpty ? results.first : null;
    final rawConfidence = (best?['confidence'] as num?)?.toDouble() ?? 0;
    final rawLabel = best?['label'] as String? ?? 'Unknown';

    // Determine if this is actually a cookie or unknown
    final isValidCookie = _isLikelyCookie(rawConfidence);
    final bestLabel = isValidCookie ? rawLabel : 'Unknown';
    // If not a cookie, show very low confidence (random low value)
    final bestConfidence = isValidCookie
        ? rawConfidence
        : 0.05 + (rawConfidence * 0.1);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Result Title
              Text(
                'Result:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Scanned Image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    file,
                    height: 160,
                    width: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Cookie Name
              Text(
                bestLabel,
                style: GoogleFonts.titanOne(
                  fontSize: 26,
                  color: isValidCookie ? AppColors.primaryDark : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              // Warning message for unknown
              if (!isValidCookie) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'This doesn\'t appear to be a cookie',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Distribution
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prediction Distribution',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...results.take(5).map((result) {
                      final label = result['label'] as String;
                      final confidence = (result['confidence'] as num)
                          .toDouble();
                      final percent = confidence * 100.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                label.length > 14
                                    ? '${label.substring(0, 14)}...'
                                    : label,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: confidence.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 45,
                              child: Text(
                                '${percent.toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await onStore(bestLabel, bestConfidence * 100);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Save to History',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ANALYTICS PAGE ====================
class AnalyticsPage extends StatelessWidget {
  final int refreshKey;

  const AnalyticsPage({super.key, required this.refreshKey});

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final doc = await FirebaseFirestore.instance
        .collection('CookieFinder_Logs')
        .doc('logs')
        .get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null) return [];
    final raw = (data['logs'] as List<dynamic>?) ?? [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Widget _findImageWidget(String className, {double size = 44}) {
    final match = findCookieInfoByName(className);
    if (match == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.cookie,
          size: size * 0.5,
          color: AppColors.primaryDark,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        match.imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.cookie,
            size: size * 0.5,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(refreshKey),
        future: _loadHistory(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDark),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load analytics',
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            );
          }
          final items = snap.data ?? [];
          final totalScans = items.length;
          final Map<String, int> counts = {};
          for (final it in items) {
            final name = it['ClassType']?.toString() ?? 'Unknown';
            counts[name] = (counts[name] ?? 0) + 1;
          }
          final categories = counts.length;
          final sortedEntries = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                    ),
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: PolkaDotPainter(),
                          size: Size.infinite,
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Analytics',
                                  style: GoogleFonts.titanOne(
                                    fontSize: 32,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track cookie detections and scanning trends',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Total Scans: $totalScans | Top $categories Classes Detected',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _ModernStatCard(
                              icon: Icons.qr_code_scanner_rounded,
                              label: 'Total Scans',
                              value: '$totalScans',
                              color: AppColors.primaryDark,
                              gradient: [
                                AppColors.primaryDark,
                                AppColors.primary,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModernStatCard(
                              icon: Icons.category_rounded,
                              label: 'Categories',
                              value: '$categories',
                              color: AppColors.accent,
                              gradient: [
                                AppColors.accent,
                                const Color(0xFFBC8F6E),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Second row of stats
                      Row(
                        children: [
                          Expanded(
                            child: _ModernStatCard(
                              icon: Icons.trending_up_rounded,
                              label: 'Avg Accuracy',
                              value: _calculateAvgAccuracy(items),
                              color: const Color(0xFF4CAF50),
                              gradient: [
                                const Color(0xFF4CAF50),
                                const Color(0xFF81C784),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModernStatCard(
                              icon: Icons.star_rounded,
                              label: 'Top Cookie',
                              value: sortedEntries.isNotEmpty
                                  ? _shortenName(sortedEntries.first.key)
                                  : '-',
                              color: const Color(0xFFFF9800),
                              gradient: [
                                const Color(0xFFFF9800),
                                const Color(0xFFFFB74D),
                              ],
                              isText: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Top Categories Section
                      _buildModernSectionCard(
                        title: 'Top Categories',
                        subtitle: 'Most detected cookie types',
                        icon: Icons.leaderboard_rounded,
                        child: items.isEmpty
                            ? _buildEmptyState(
                                'No categories yet',
                                'Start scanning to see your top cookies!',
                              )
                            : Column(
                                children: sortedEntries
                                    .take(8)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final idx = entry.key;
                                      final e = entry.value;
                                      final percentage =
                                          (e.value / totalScans * 100)
                                              .toStringAsFixed(1);
                                      return _ModernCategoryItem(
                                        rank: idx + 1,
                                        name: e.key,
                                        count: e.value,
                                        percentage: percentage,
                                        total: totalScans,
                                        imageWidget: _findImageWidget(
                                          e.key,
                                          size: 50,
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // Distribution Section
                      _buildModernSectionCard(
                        title: 'Distribution',
                        subtitle: 'Visual breakdown of your scans',
                        icon: Icons.pie_chart_rounded,
                        child: items.isEmpty
                            ? _buildEmptyState(
                                'No data yet',
                                'Your scan distribution will appear here',
                              )
                            : _ModernDistributionChart(
                                counts: counts,
                                total: totalScans,
                              ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _calculateAvgAccuracy(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return '-';
    double total = 0;
    int count = 0;
    for (final item in items) {
      final acc = item['Accuracy_Rate'];
      if (acc != null) {
        total += (acc as num).toDouble();
        count++;
      }
    }
    if (count == 0) return '-';
    return '${(total / count).toStringAsFixed(1)}%';
  }

  String _shortenName(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0].substring(0, math.min(3, words[0].length))}. ${words.last}';
    }
    return name.length > 10 ? '${name.substring(0, 10)}...' : name;
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cookie_outlined,
              size: 48,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryDark, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final List<Color> gradient;
  final bool isText;

  const _ModernStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: isText
                ? GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )
                : GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDistributionChart extends StatelessWidget {
  final Map<String, int> counts;
  final int total;

  const _ModernDistributionChart({required this.counts, required this.total});

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      AppColors.primaryDark,
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF5D4037),
      const Color(0xFF8D6E63),
      const Color(0xFFBCAAA4),
      const Color(0xFFD7CCC8),
      const Color(0xFF795548),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // Donut Chart
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _DonutChartPainter(
                    entries: entries.take(6).toList(),
                    total: total,
                    colors: colors,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Total',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: entries.take(6).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final e = entry.value;
              final pct = (e.value / total * 100).toStringAsFixed(1);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors[idx % colors.length].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors[idx % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_shortenName(e.key)} $pct%',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _shortenName(String name) {
    final words = name.split(' ');
    if (words.length > 1) {
      return words.first.substring(0, math.min(4, words.first.length));
    }
    return name.length > 8 ? '${name.substring(0, 8)}...' : name;
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int total;
  final List<Color> colors;

  _DonutChartPainter({
    required this.entries,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < entries.length && i < colors.length; i++) {
      final sweepAngle = (entries[i].value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.02,
        sweepAngle - 0.04,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ModernCategoryItem extends StatelessWidget {
  final int rank;
  final String name;
  final int count;
  final String percentage;
  final int total;
  final Widget imageWidget;

  const _ModernCategoryItem({
    required this.rank,
    required this.name,
    required this.count,
    required this.percentage,
    required this.total,
    required this.imageWidget,
  });

  @override
  Widget build(BuildContext context) {
    final progress = count / total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank == 1
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: rank == 1
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.accent,
                    ][rank - 1]
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3 ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Cookie Image
          imageWidget,
          const SizedBox(width: 12),
          // Name and Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryDark,
                                    AppColors.primary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Percentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$percentage%',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HISTORY PAGE ====================
class HistoryPage extends StatefulWidget {
  final int refreshKey;

  const HistoryPage({super.key, required this.refreshKey});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _localRefreshKey = 0;

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final doc = await FirebaseFirestore.instance
        .collection('CookieFinder_Logs')
        .doc('logs')
        .get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null) return [];
    final raw = (data['logs'] as List<dynamic>?) ?? [];
    final mapped = raw.whereType<Map<String, dynamic>>().toList();
    mapped.sort((a, b) {
      final ta = a['Time'];
      final tb = b['Time'];
      DateTime da = ta is Timestamp
          ? ta.toDate()
          : DateTime.tryParse(ta?.toString() ?? '') ?? DateTime(1970);
      DateTime db = tb is Timestamp
          ? tb.toDate()
          : DateTime.tryParse(tb?.toString() ?? '') ?? DateTime(1970);
      return db.compareTo(da);
    });
    return mapped;
  }

  Future<void> _deleteHistoryItem(Map<String, dynamic> item) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Entry',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this scan entry?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('CookieFinder_Logs')
          .doc('logs');

      // Remove the item from the logs array
      await docRef.update({
        'logs': FieldValue.arrayRemove([item]),
      });

      // Delete the local image file if it exists
      final imagePath = item['ImagePath']?.toString();
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Refresh the list
      if (mounted) {
        setState(() {
          _localRefreshKey++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Entry deleted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _findImageWidget(String className, {double size = 44}) {
    final match = findCookieInfoByName(className);
    if (match == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.cookie,
          size: size * 0.5,
          color: AppColors.primaryDark,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        match.imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.cookie,
            size: size * 0.5,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey('${widget.refreshKey}_$_localRefreshKey'),
        future: _loadHistory(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDark),
            );
          }
          if (snap.hasError) {
            return _buildErrorState();
          }
          final items = snap.data ?? [];

          return CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                    ),
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: PolkaDotPainter(),
                          size: Size.infinite,
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'History',
                                      style: GoogleFonts.titanOne(
                                        fontSize: 32,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.history,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${items.length} scans',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your recent cookie detections',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              if (items.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final it = items[index];
                      final className =
                          it['ClassType']?.toString() ?? 'Unknown';
                      final acc = it['Accuracy_Rate'] as num?;
                      final imagePath = it['ImagePath']?.toString();
                      final timeRaw = it['Time'];
                      final dt = timeRaw is Timestamp
                          ? timeRaw.toDate()
                          : DateTime.tryParse(timeRaw?.toString() ?? '') ??
                                DateTime(1970);

                      return _ModernHistoryCard(
                        className: className,
                        accuracy: acc?.toDouble(),
                        dateTime: dt,
                        imagePath: imagePath,
                        defaultImage: _findImageWidget(className, size: 60),
                        onTap: () => _showDetailDialog(
                          context,
                          it,
                          className,
                          acc?.toDouble(),
                          dt,
                          imagePath,
                        ),
                        onDelete: () => _deleteHistoryItem(it),
                      );
                    }, childCount: items.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    Map<String, dynamic> item,
    String className,
    double? accuracy,
    DateTime dateTime,
    String? imagePath,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildDetailImage(imagePath, className),
              ),
              const SizedBox(height: 20),
              Text(
                className,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  accuracy != null
                      ? '${accuracy.toStringAsFixed(1)}% confidence'
                      : 'No accuracy data',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatFullDate(dateTime),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailImage(String? imagePath, String className) {
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snap) {
          if (snap.data == true) {
            return Image.file(file, height: 180, width: 180, fit: BoxFit.cover);
          }
          return _buildDefaultDetailImage(className);
        },
      );
    }
    return _buildDefaultDetailImage(className);
  }

  Widget _buildDefaultDetailImage(String className) {
    final match = findCookieInfoByName(className);
    if (match != null) {
      return Image.asset(
        match.imagePath,
        height: 180,
        width: 180,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      width: 180,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.cookie, size: 60, color: AppColors.primaryDark),
    );
  }

  String _formatFullDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 64,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No scan history yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start scanning cookies to build your history.\nAll your detections will appear here.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load history',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please check your connection',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ModernHistoryCard extends StatelessWidget {
  final String className;
  final double? accuracy;
  final DateTime dateTime;
  final String? imagePath;
  final Widget defaultImage;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ModernHistoryCard({
    required this.className,
    required this.accuracy,
    required this.dateTime,
    required this.imagePath,
    required this.defaultImage,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      imageWidget = FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snap) {
          if (snap.data == true) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                file,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => defaultImage,
              ),
            );
          }
          return defaultImage;
        },
      );
    } else {
      imageWidget = defaultImage;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Cookie Image with subtle border
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: imageWidget,
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          className,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Detected: ${_formatDate(dateTime)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accuracy Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      accuracy != null
                          ? '${accuracy!.toStringAsFixed(1)}%'
                          : '-',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Delete Button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
