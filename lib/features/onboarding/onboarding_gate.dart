import 'package:flutter/material.dart';

import '../../core/platform/interception_channel.dart';
import '../../core/storage/stats_repository.dart';
import '../home/home_screen.dart';
import 'onboarding_screen.dart';

/// Shows the onboarding flow until the accessibility service is enabled
/// (the one permission the app can't function without), then hands off to
/// the home screen. Usage access is offered on the same screen but isn't
/// required to continue. Re-checks whenever the app resumes, since granting
/// either permission happens in the system Settings app.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> with WidgetsBindingObserver {
  bool? _isAccessibilityEnabled;
  bool _hasUsageAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    // The challenge overlay writes stats from its own Flutter engine; reload
    // so this engine's Home screen reflects them as soon as we come back.
    await StatsRepository.reload();
    final results = await Future.wait([
      InterceptionChannel.isAccessibilityServiceEnabled(),
      InterceptionChannel.hasUsageAccess(),
    ]);
    if (mounted) {
      setState(() {
        _isAccessibilityEnabled = results[0];
        _hasUsageAccess = results[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityEnabled = _isAccessibilityEnabled;
    if (accessibilityEnabled == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (accessibilityEnabled == false) {
      return OnboardingScreen(hasUsageAccess: _hasUsageAccess, onRefresh: _refresh);
    }
    return const HomeScreen();
  }
}
