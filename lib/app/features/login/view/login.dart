import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Assuming your cubit and state are in these paths
// Make sure these paths are correct for your project structure.
import 'package:score_board/app/features/login/cubit/login_cubit.dart';
import 'package:score_board/app/features/login/cubit/login_state.dart';

// Assuming your AppRouter and HomeRoute are defined for navigation.
// Adjust this import path if necessary.
// If HomeRoute is not defined, navigation on success will cause an error.
// You might need to create a placeholder HomeRoute or use your actual target route.
import 'package:score_board/router/app_router.gr.dart'; // Example path

@RoutePage()
class LoginRoute extends StatelessWidget {
  const LoginRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LoginCubit(), // LoginCubit instantiates its own dependencies
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.status == LoginStatus.success) {
            // Navigate to the home screen or dashboard on successful login/signup
            AutoRouter.of(context).replaceAll(
                [const DashboardRoute()],); // Ensure HomeRoute is defined
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == LoginStatus.failure) {
            // Show an error message if login/signup fails
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'An unknown error occurred.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          // Pass the loading status to LoginPage
          return LoginPage(isLoading: state.status == LoginStatus.loading);
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  // Receive loading state

  const LoginPage({super.key, this.isLoading = false});
  final bool isLoading;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String backgroundImageUrl =
        'https://images.unsplash.com/photo-1530305408560-82d13781b33a?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2072&q=80';

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const NetworkImage(backgroundImageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Optional: Handle image loading error, e.g., show a fallback.
                  },
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Welcome Back', // Updated title
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue', // Updated subtitle
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),),
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: Colors.white.withOpacity(0.7),),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.white),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),),
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: Colors.white.withOpacity(0.7),),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.white),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          if (widget.isLoading) // Use widget.isLoading
                            const CircularProgressIndicator(color: Colors.white)
                          else
                            Column(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.9),
                                    foregroundColor: Colors.blueGrey[800],
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15,),
                                    textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),),
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      context
                                          .read<LoginCubit>()
                                          .loginWithEmailAndPassword(
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                    }
                                  },
                                  child: const Text('Sign In'),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.7),),
                                    foregroundColor:
                                        Colors.white.withOpacity(0.9),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15,),
                                    textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),),
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      context
                                          .read<LoginCubit>()
                                          .signUpWithEmailAndPassword(
                                            // Corrected to signUp
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                    }
                                  },
                                  child: const Text('Create Account'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: widget.isLoading
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Forgot Password clicked (not implemented yet).',),),
                                    );
                                  },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
