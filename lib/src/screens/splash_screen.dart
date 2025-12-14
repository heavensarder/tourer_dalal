import 'package:flutter/material.dart';
import 'package:tourer_dalal/src/config/constants.dart';
import 'package:tourer_dalal/src/config/theme.dart'; // For spacing

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3), () {}); // 3 seconds delay
    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for the logo
            Image.asset(
              'assets/images/my_logo.png', // Use the actual logo
              width: 150,
              height: 150,
            ),
            SizedBox(height: kSpacingM),
            Text(
              'Tourer Dalal',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            SizedBox(height: kSpacingS),
            Text(
              'Version: 1',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
            ),
            Text(
              'Developed by Heaven Sarder',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}