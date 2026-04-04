import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final String message;

  const SplashScreen({super.key, this.message = 'Loading HostelOutpass...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

