import 'package:eigen_flutter/widgets/auth/auth_card.dart';
import 'package:flutter/material.dart';
// import 'package:eigen_flutter/widgets/auth/card.dart';



class AuthScreen extends StatefulWidget {
  final String initialMode;
  const AuthScreen({super.key, required this.initialMode});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late bool _isSignIn;
  late AnimationController _controller;
  late Animation<Offset> _outSlide;
  late Animation<Offset> _inSlide;
  late Animation<double> _outFade;
  late Animation<double> _inFade;
  late Animation<double> _outScale;
  late Animation<double> _inScale;

  bool _showingNext = false;
  bool _isSignInNext = false;

  @override
  void initState() {
    super.initState();
    _isSignIn = widget.initialMode == 'signin';

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _outSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.1, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInCubic),
    ));

    _inSlide = Tween<Offset>(
      begin: const Offset(1.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    ));

    _outFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _inFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _outScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _inScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _swap() {
    setState(() {
      _showingNext = true;
      _isSignInNext = !_isSignIn;
    });

    _controller.forward().then((_) {
      setState(() {
        _isSignIn = _isSignInNext;
        _showingNext = false;
      });
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36093D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Back + branding row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: 36),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'E I G E N',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _isSignIn ? 'Hop\nBack In.' : 'Start your\njourney.',
                      key: ValueKey(_isSignIn),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // AuthCard area
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final animating = _controller.isAnimating;
                  final inFirstHalf = _controller.value < 0.5;

                  return Stack(
                    children: [
                      // Ghost card behind — adds depth
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                        ),
                      ),

                      // Incoming card (slides in from right)
                      if (animating && !inFirstHalf && _showingNext)
                        Positioned.fill(
                          child: SlideTransition(
                            position: _inSlide,
                            child: FadeTransition(
                              opacity: _inFade,
                              child: ScaleTransition(
                                scale: _inScale,
                                alignment: Alignment.bottomCenter,
                                child: AuthCard(
                                  isSignIn: _isSignInNext,
                                  onSwap: _swap,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Current card (slides out to left)
                      if (!animating || inFirstHalf)
                        Positioned.fill(
                          child: SlideTransition(
                            position: animating ? _outSlide : _noSlide,
                            child: FadeTransition(
                              opacity: animating ? _outFade : _noFade,
                              child: ScaleTransition(
                                scale: animating ? _outScale : _noScale,
                                alignment: Alignment.bottomCenter,
                                child: AuthCard(
                                  isSignIn: _isSignIn,
                                  onSwap: _swap,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Static animations for when not animating
  Animation<Offset> get _noSlide => AlwaysStoppedAnimation(Offset.zero);
  Animation<double> get _noFade => const AlwaysStoppedAnimation(1.0);
  Animation<double> get _noScale => const AlwaysStoppedAnimation(1.0);
}

