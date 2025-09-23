import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final List<String> images = [
    'assets/intro_images/im1.jpg',
    'assets/intro_images/im2.webp',
    'assets/intro_images/im3.webp',
    'assets/intro_images/im4.jpg',
  ];

  final List<String> titles = [
    'Welcome to GymPad',
    'Track Your Workouts',
    'Personalized Plans',
    'Join the Community',
  ];

  final List<String> descriptions = [
    'Your ultimate fitness companion app.',
    'Log exercises, sets, and reps with ease.',
    'Get workout plans tailored to your goals.',
    'Connect with fellow fitness enthusiasts.',
  ];

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        itemCount: images.length,
        controller: _pageController,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(images[index]),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titles[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      descriptions[index],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        if (index == images.length - 1) {
                          context.go('/login');
                          return;
                        }
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInCubic,
                        );
                      },
                      child: Text(
                        index == images.length - 1 ? "Log In" : "Next",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
