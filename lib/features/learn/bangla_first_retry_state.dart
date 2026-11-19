// Shared loading-failure state for the Bangla 1st Paper screens:
// message + retry button. Nothing here invents data.
import 'package:flutter/material.dart';

class BanglaFirstRetryState extends StatelessWidget {
  const BanglaFirstRetryState({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}

// Shared loading state for the Bangla screens: spinner + label
// together, so a slow fetch never looks like a blank screen.
class BanglaFirstLoadingState extends StatelessWidget {
  const BanglaFirstLoadingState({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    );
  }
}
