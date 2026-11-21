// Route: /premium
// AUDIT-FIX F1 (audit-fix-plan-2026-10-30 §4): server-side Play
// verification is still pending, so the buy button is a
// "coming soon" state — it NEVER starts a purchase that would
// charge without granting premium. No new purchase flow is
// wired here; when verification lands, the gate comes off.
// Price (F2): the Play product price when queryProductDetails()
// returns one, AppConfig's code price only as fallback.
// Restore calls billingService.restore(). Neither buy nor restore
// ever grants premium by itself: premium is shown only when
// billingService.isPremium() (server-verified entitlement ONLY)
// says so. The Settings DEMO test switch is never read here, so
// it cannot make the paywall show a premium member card.
// Play Billing only — deliberately no bKash/Nagad button.
// PHASE 13 (H8): feature list is honest only — Class 6 books, model
// tests, practice/quizzes, premium-only voice capped at 30 min/period.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ai_voice_service.dart';
import '../../core/services/app_config.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/premium_strings.dart';
import '../../theme/app_theme.dart';
import 'widgets/premium_benefits_card.dart';
import '../../theme/themed_scaffold.dart';

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});
  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  bool _loading = true;
  bool _isPremium = false;
  int _remaining = 0;

  /// Real Play price (e.g. "$5.00") when Play returns a product,
  /// null when it does not — then the code price is the fallback.
  String? _playPrice;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final premium = await billingService.isPremium();
    final budget = await aiVoiceService.budget();
    final product = await billingService.queryProductDetails();
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _remaining = budget.remaining;
      _playPrice = product?.price;
      _loading = false;
    });
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Audit-fix F1 gate (audit-fix-plan-2026-10-30 §4, server
  // verification pending): explains the coming-soon state and
  // deliberately does NOT call billingService.buy().
  void _comingSoon() {
    final s = isBangla ? premiumStringsBn : premiumStringsEn;
    _msg(s['comingSoonNote']!);
  }

  Future<void> _restore() async {
    final s = isBangla ? premiumStringsBn : premiumStringsEn;
    final ok = await billingService.restore();
    await _refresh();
    _msg(ok ? s['restoreDone']! : s['restoreNone']!);
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? premiumStringsBn : premiumStringsEn;
    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(s['paywallTitle']!),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (var i = 0; i < 2; i++)
                  Container(
                    height: 88,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
              ],
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                Text(
                  s['paywallSub']!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.workspace_premium,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(s['planTitle']!),
                    subtitle: Text(s['planSub']!),
                    trailing: Chip(
                      label: Text(
                        _isPremium ? s['planPremium']! : s['planFree']!,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isPremium)
                  // UI palette (গ): premium-active card uses the
                  // gold → purple premium gradient with white text.
                  Container(
                    decoration: BoxDecoration(
                      gradient: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.premiumGradientDark
                          : AppTheme.premiumGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.verified, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            s['premiumActive']!,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            s['premiumActiveSub']!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${s['remainingLabel']!}: $_remaining ${s['minutesUnit']!} ${s['perPeriod']!}",
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      PremiumBenefitsCard(
                        voice: s['voiceFeat']!,
                        books: s['booksFeat']!,
                        tests: s['testsFeat']!,
                        practice: s['practiceFeat']!,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s['premiumOnlyNote']!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // F2: Play price when available, code price fallback.
                Text(
                  _playPrice == null
                      ? s['price']!
                      : '$_playPrice ${s['perMonth']!}',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  s['voiceCap']!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  s['noHidden']!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (_isPremium)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context.push('/voice'),
                    child: Text(s['voiceTitle']!),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    // F1 gate: coming-soon state, never a purchase.
                    onPressed: _comingSoon,
                    child: Text(s['comingSoon']!),
                  ),
                if (!_isPremium)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      s['comingSoonNote']!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _restore, child: Text(s['restore']!)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: Text(s['free']!),
                ),
                const SizedBox(height: 12),
                Text(
                  s['billingNote']!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  s['verifyNote']!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                if (AppConfig.demoMode)
                  Text(
                    s['demoNote']!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
    );
  }
}
