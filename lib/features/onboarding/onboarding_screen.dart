import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/images/manage_money_cuate_1.webp",
      "title": "Mulai Hidup Lebih Teratur",
      "description": "Awali kebiasaan baik\ndengan mencatat keuangan harian.",
    },
    {
      "image": "assets/images/manage_money_cuate_1_1.webp",
      "title": "Kategori Pengeluaran",
      "description": "Bantu kamu memahami ke mana uangmu pergi.",
    },
    {
      "image": "assets/images/manage_money_cuate_1_2.webp",
      "title": "Grafik Sederhana",
      "description": "Lihat ringkasan keuanganmu dengan cepat.",
    },
  ];

  void _goToNextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Image.asset(
                            item["image"]!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                item["title"]!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                item["description"]!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_onboardingData.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 10,
                  width: (index == _currentPage) ? 30 : 10,
                  decoration: BoxDecoration(
                    color: (index == _currentPage)
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _goToNextPage,
                    child: Text(
                      _currentPage == _onboardingData.length - 1
                          ? "Mulai"
                          : "Berikutnya",
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text("Lewati"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
