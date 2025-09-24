import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gympad/constants/app_styles.dart';

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
      body: Stack(
        children: [
          // Background pager with images
          PageView.builder(
            itemCount: images.length,
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => _IntroSlide(image: images[index]),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content Panel Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  final page =
                      _pageController.hasClients && _pageController.page != null
                          ? _pageController.page!.round().clamp(
                            0,
                            images.length - 1,
                          )
                          : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28.0),
                          child: AnimatedSwitcher(
                            duration: const Duration(seconds: 1),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder:
                                (currentChild, previousChildren) => Stack(
                                  alignment: Alignment.topLeft,
                                  children: [
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                ),
                            transitionBuilder: (child, animation) {
                              final isIncoming =
                                  child.key == ValueKey('intro-$page');
                              final curved = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              );
                              Animation<Offset> offset;
                              if (isIncoming) {
                                offset = Tween<Offset>(
                                  begin: const Offset(0.35, 0),
                                  end: Offset.zero,
                                ).animate(curved);
                              } else {
                                // outgoing: animation runs 1->0, so reverse to get 0->1 progression
                                final rev = ReverseAnimation(curved);
                                offset = Tween<Offset>(
                                  begin: Offset.zero,
                                  end: const Offset(-0.35, 0),
                                ).animate(rev);
                              }
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: offset,
                                  child: child,
                                ),
                              );
                            },
                            child: _IntroText(
                              key: ValueKey('intro-$page'),
                              title: titles[page],
                              description: descriptions[page],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _DotsIndicator(length: images.length, index: page),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.white.withOpacity(0.5),
                                    ),
                                    foregroundColor: AppColors.white,
                                    shape: const StadiumBorder(),
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  onPressed: () {
                                    if (page == images.length - 1) {
                                      context.go('/login');
                                      return;
                                    }
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 450,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  child: Text(
                                    page == images.length - 1
                                        ? 'Log In'
                                        : 'Next',
                                    style: AppTextStyles.button.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  final String image;
  const _IntroSlide({required this.image});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
      child: Container(),
    );
  }
}

class _IntroText extends StatelessWidget {
  final String title;
  final String description;
  const _IntroText({super.key, required this.title, required this.description});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.white,
            fontSize: 40,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          description,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white.withOpacity(0.82),
          ),
        ),
      ],
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int length;
  final int index;
  const _DotsIndicator({required this.length, required this.index});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 10,
          width: active ? 28 : 10,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
