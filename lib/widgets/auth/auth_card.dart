import 'package:eigen_flutter/providers/auth_provider.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/auth_repository.dart';
import 'package:eigen_flutter/repositories/profile_repository.dart';
import 'package:eigen_flutter/widgets/auth/field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCard extends ConsumerStatefulWidget {
  final bool isSignIn;
  final VoidCallback onSwap;

  const AuthCard({required this.isSignIn, required this.onSwap, super.key});

  @override
  ConsumerState<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends ConsumerState<AuthCard> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _repo = AuthRepository();
  final _profile_repo = ProfileRepository();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // Reset fields + error when card swaps
  @override
  void didUpdateWidget(AuthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSignIn != widget.isSignIn) {
      _emailController.clear();
      _passwordController.clear();
      _usernameController.clear();
      setState(() => _error = null);
    }
  }

  Future<void> _submit(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!widget.isSignIn && username.isEmpty) {
      setState(() => _error = 'Please enter a username.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      AuthResponse response;
      if (widget.isSignIn) {
        response = await _repo.signIn(email: email, password: password);
      } else {
        response = await _repo.signUp(email: email, password: password, username: username);
      }
      print("HERE IS THE RESPONSE OF SUPABASE");
      
      String accessToken = response.session!.accessToken;
      print(accessToken);
      final result = await _profile_repo.getProfile(token: accessToken);

      switch (result) {
        case ApiSuccess(:final data):
          // store it in global state
          ref.read(authProvider.notifier).updateProfile(data);
          ref.read(authProvider.notifier).updateAccessToken(accessToken);
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
            }
            
        case ApiFailure(:final exception):
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(exception.message)),
          );
      }

    
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 32,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pill handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              widget.isSignIn ? 'Sign In' : 'Sign Up',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 28),

            if (!widget.isSignIn) ...[
              Field(
                label: 'Username',
                hint: 'madame curie',
                controller: _usernameController,
              ),
              const SizedBox(height: 20),
            ],

            Field(
              label: 'Email',
              hint: 'you@example.com',
              controller: _emailController,
            ),
            const SizedBox(height: 20),
            Field(
              label: 'Password',
              hint: '••••••••',
              obscure: true,
              controller: _passwordController,
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 36),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _loading ? null : (){_submit(context);},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF36093D),
                  disabledBackgroundColor: const Color(0xFF36093D).withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.isSignIn ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Swap row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.isSignIn
                      ? "Don't have an account?"
                      : 'Already have an account?',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _loading ? null : widget.onSwap,
                  child: Text(
                    widget.isSignIn ? 'Sign Up' : 'Sign In',
                    style: const TextStyle(
                      color: Color(0xFF36093D),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF36093D),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}