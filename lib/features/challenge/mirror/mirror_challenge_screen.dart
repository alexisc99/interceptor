import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../challenge_scaffold.dart';

class MirrorChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;
  final ChallengeType resolvedType;
  final int? usageMinutesToday;

  const MirrorChallengeScreen({
    super.key,
    required this.appConfig,
    required this.resolvedType,
    required this.usageMinutesToday,
  });

  @override
  State<MirrorChallengeScreen> createState() => _MirrorChallengeScreenState();
}

enum _Stage { loading, preview, viewing, unavailable }

class _MirrorChallengeScreenState extends State<MirrorChallengeScreen> {
  static const _viewDuration = 5;
  static const _punchlineCount = 4;

  late final int _punchlineIndex = Random().nextInt(_punchlineCount);

  CameraController? _controller;
  _Stage _stage = _Stage.loading;
  String? _photoPath;
  int _remaining = _viewDuration;
  Timer? _timer;
  bool _solved = false;
  // Set the instant "Annuler" is tapped — checked before every further step
  // of the camera setup/capture chain below, so cancelling mid-preview (or
  // mid-capture) can't race a still-in-flight takePicture() call against
  // the activity tearing down.
  bool _cancelling = false;

  void _handleCancel() {
    _cancelling = true;
    _timer?.cancel();
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted || _cancelling) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _stage = _Stage.preview;
      });
      // A brief live moment before the shot, so it doesn't feel like a jump scare.
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || _cancelling) return;
      await _capture();
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.unavailable);
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      if (mounted && !_cancelling) setState(() => _stage = _Stage.unavailable);
      return;
    }
    try {
      final file = await controller.takePicture();
      if (_cancelling) {
        // _handleCancel() already disposed _controller; this is the one we
        // captured with, now stale.
        await File(file.path).delete().catchError((_) => File(file.path));
        return;
      }
      await controller.dispose();
      if (!mounted) {
        await File(file.path).delete().catchError((_) => File(file.path));
        return;
      }
      setState(() {
        _controller = null;
        _photoPath = file.path;
        _stage = _Stage.viewing;
      });
      _startViewingTimer();
    } catch (_) {
      if (mounted && !_cancelling) setState(() => _stage = _Stage.unavailable);
    }
  }

  void _startViewingTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining--);
      if (_remaining <= 0) _timer?.cancel();
    });
  }

  Future<void> _deletePhoto() async {
    final path = _photoPath;
    if (path == null) return;
    _photoPath = null;
    try {
      await File(path).delete();
    } catch (_) {
      // Already gone or never fully written — nothing to clean up.
    }
  }

  Future<void> _continue() async {
    await StatsRepository().recordSolved(widget.appConfig.packageName, widget.resolvedType);
    await _deletePhoto();
    if (mounted) setState(() => _solved = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _deletePhoto();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChallengeScaffold(
      icon: Icons.camera_front,
      packageName: widget.appConfig.packageName,
      appName: widget.appConfig.appName,
      resolvedType: widget.resolvedType,
      usageMinutesToday: widget.usageMinutesToday,
      solved: _solved,
      onCancel: _handleCancel,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final punchlines = [
      l10n.mirrorPunchline1,
      l10n.mirrorPunchline2,
      l10n.mirrorPunchline3,
      l10n.mirrorPunchline4,
    ];
    final punchline = punchlines[_punchlineIndex];

    switch (_stage) {
      case _Stage.loading:
        return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
      case _Stage.unavailable:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.mirrorCameraUnavailable, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _continue, child: Text(l10n.continueLabel)),
          ],
        );
      case _Stage.preview:
        final controller = _controller;
        return _FramedPhoto(
          punchline: punchline,
          child: controller != null && controller.value.isInitialized
              ? CameraPreview(controller)
              : const SizedBox.shrink(),
        );
      case _Stage.viewing:
        final path = _photoPath;
        final canContinue = _remaining <= 0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (path != null)
              _FramedPhoto(punchline: punchline, child: Image.file(File(path), fit: BoxFit.cover)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canContinue ? _continue : null,
              child: Text(canContinue ? l10n.continueLabel : l10n.continueWithCountdown(_remaining)),
            ),
          ],
        );
    }
  }
}

class _FramedPhoto extends StatelessWidget {
  final String punchline;
  final Widget child;

  const _FramedPhoto({required this.punchline, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.black, child: child),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                punchline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
