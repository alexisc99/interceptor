import 'package:flutter/widgets.dart';

import '../../core/storage/app_config_repository.dart';
import '../../l10n/app_localizations.dart';

extension ChallengeTypeL10n on ChallengeType {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ChallengeType.math:
        return l10n.challengeTypeMath;
      case ChallengeType.puzzle:
        return l10n.challengeTypePuzzle;
      case ChallengeType.action:
        return l10n.challengeTypeAction;
      case ChallengeType.delay:
        return l10n.challengeTypeDelay;
      case ChallengeType.mirror:
        return l10n.challengeTypeMirror;
    }
  }

  String description(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ChallengeType.math:
        return l10n.challengeDescMath;
      case ChallengeType.puzzle:
        return l10n.challengeDescPuzzle;
      case ChallengeType.action:
        return l10n.challengeDescAction;
      case ChallengeType.delay:
        return l10n.challengeDescDelay;
      case ChallengeType.mirror:
        return l10n.challengeDescMirror;
    }
  }
}
