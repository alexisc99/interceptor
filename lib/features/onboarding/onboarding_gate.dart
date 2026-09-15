import 'package:flutter/material.dart';

import '../../core/platform/interception_channel.dart';
import '../home/home_screen.dart';
import 'onboarding_screen.dart';

/// Shows the onboarding flow until the accessibility service is enabled,
/// then hands off to the home screen. Re-checks whenever the app resumes,
/// since enabling the service happens in the system Settings app.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> with WidgetsBindingObserver {
  bool? _isEnabled;

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
    final enabled = await InterceptionChannel.isAccessibilityServiceEnabled();
    if (mounted) setState(() => _isEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEnabled == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isEnabled == false) {
      return OnboardingScreen(onRefresh: _refresh);
    }
    return const HomeScreen();
  }
}
