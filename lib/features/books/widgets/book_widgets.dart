import 'package:flutter/material.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.title,
    required this.meta,
    required this.progress,
    this.locked = false,
    this.onTap,
  });
  final String title;
  final String meta;
  final double progress;
  final bool locked;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover-ish thumbnail: a book needs a visual anchor, not
                  // just a line icon (library still has no real covers).
                  Container(
                    width: 44,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: locked
                          ? null
                          : LinearGradient(
                              colors: [
                                AppTheme.primary.withValues(alpha: 0.85),
                                AppTheme.primaryDark.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: locked ? AppTheme.card : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      locked ? Icons.lock : Icons.menu_book,
                      color: locked ? AppTheme.inkMuted : Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!locked)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: AppTheme.success,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
