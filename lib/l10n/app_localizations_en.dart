// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Interceptor';

  @override
  String get activateLabel => 'Enable';

  @override
  String get activatedLabel => 'Enabled';

  @override
  String get continueLabel => 'Continue';

  @override
  String get validateLabel => 'Done';

  @override
  String get requiredLabel => 'required';

  @override
  String get viewLabel => 'View';

  @override
  String get dismissLabel => 'Dismiss';

  @override
  String get statsEntryLabel => 'Advanced stats';

  @override
  String get premiumLockedTitle => 'Advanced stats';

  @override
  String get premiumLockedDescription =>
      'Unlock detailed stats: time saved compared to before Interceptor, time saved compared to the previous period, deterrence by app and by challenge type, and an estimate of time saved based on your deterrences.';

  @override
  String get premiumDebugToggleLabel =>
      'Premium enabled (test — until real payment is wired up)';

  @override
  String get unlockTeaserTitle => 'Discover your time saved';

  @override
  String get unlockButton => 'Unlock statistics';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get resetStatsButton => 'Reset statistics';

  @override
  String get resetStatsConfirmTitle => 'Reset statistics?';

  @override
  String get resetStatsConfirmBody =>
      'Every counter (challenges, deterrences, daily history, comparison baselines) will go back to zero. Your targeted apps and their chosen challenges aren\'t affected. This can\'t be undone.';

  @override
  String get resetStatsConfirmAction => 'Reset';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get statVsBeforeInstall => 'Time saved vs before Interceptor';

  @override
  String get statVsPreviousDay => 'Time saved vs yesterday';

  @override
  String get statVsPreviousWeek => 'Time saved vs last week';

  @override
  String get statVsPreviousMonth => 'Time saved vs last month';

  @override
  String get statVsPreviousYear => 'Time saved vs last year';

  @override
  String get statEstimate => 'Estimated time saved (deterrences)';

  @override
  String get dissuasionByAppTitle => 'Deterrence by app';

  @override
  String get noDataForPeriod => 'No data for this period.';

  @override
  String get statsLoadErrorText => 'Couldn\'t load, try again.';

  @override
  String get retryLabel => 'Retry';

  @override
  String get vsPreviousPeriodIncompleteNote =>
      'History still building up — this number is a partial (understated) estimate.';

  @override
  String get vsBeforeInstallIncompleteNote =>
      'Unavailable for at least one app added more than a week ago — that window can no longer be recovered.';

  @override
  String get perAppDetailTitle => 'Detail by app';

  @override
  String get notAvailableLabel => 'Not available';

  @override
  String get weeklyRecapBannerText => 'Your weekly recap is ready!';

  @override
  String get weeklyRecapOptOut => 'Stop showing this reminder every week';

  @override
  String get onboardingTitle => 'Take back control of your apps';

  @override
  String get onboardingIntro =>
      'Interceptor inserts a small challenge before opening the apps you choose, to break the reflex of opening them automatically. Two Android settings are needed — they\'re one tap away, and you\'ll come back here automatically afterwards.';

  @override
  String get onboardingContinueButton => 'I\'ve enabled it, continue';

  @override
  String get a11yCardTitle => 'Accessibility service';

  @override
  String get a11yCardDescription =>
      'Required: lets the app detect which app you\'re opening.';

  @override
  String get a11yStep1 =>
      'Look for \"Interceptor\" in the list (sometimes under \"Installed apps\" or \"Downloaded services\")';

  @override
  String get a11yStep2 => 'Open it and turn on the switch at the top';

  @override
  String get a11yStep3 =>
      'Confirm by tapping \"Allow\" in the dialog that appears';

  @override
  String get a11yStep4 =>
      'Come back here with the back arrow — it\'s automatic, nothing to type';

  @override
  String get usageAccessCardTitle => 'Usage access';

  @override
  String get usageAccessCardDescription =>
      'Optional: shows how much time you\'ve spent on each app during challenges.';

  @override
  String get usageAccessStep1 => 'Look for \"Interceptor\" in the app list';

  @override
  String get usageAccessStep2 => 'Turn on the switch next to its name';

  @override
  String get addAppButton => 'Add an app';

  @override
  String get usageAccessBanner =>
      'Enable usage access to show how much time you\'ve spent on each app during challenges.';

  @override
  String get statTriggered => 'Challenges shown';

  @override
  String get statSolved => 'Challenges solved';

  @override
  String get statCancelled => 'Deterred';

  @override
  String get typeBreakdownTitle => 'Deterrence by challenge type';

  @override
  String typeBreakdownLine(String label, int rate, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'triggers',
      one: 'trigger',
    );
    return '$label: $rate% ($count $_temp0)';
  }

  @override
  String homeAppSubtitle(int count, String types, int grace) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Challenges',
      one: 'Challenge',
    );
    return '$_temp0: $types · $grace min grace';
  }

  @override
  String get emptyStateMessage =>
      'No app being watched yet.\nAdd an app to assign it a challenge.';

  @override
  String get pickerTitle => 'Choose apps';

  @override
  String get minOneChallengeRequired =>
      'At least one challenge must stay selected.';

  @override
  String get narrowingReminder =>
      'Reminder: the goal is to slow you down, not to narrow the possible challenges down to the easiest one to breeze through.';

  @override
  String get mirrorNeedsCameraPermission =>
      'The Mirror challenge needs camera access to be enabled.';

  @override
  String get possibleChallengesTitle => 'Possible challenges';

  @override
  String get possibleChallengesSubtitle =>
      'Each time it triggers, one of the checked challenges is drawn at random.';

  @override
  String get graceDurationTitle => 'Grace period after a solved challenge';

  @override
  String graceMinutesValue(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return '$minutes $_temp0';
  }

  @override
  String graceMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get saveButton => 'Save';

  @override
  String get removeAppButton => 'Remove this app';

  @override
  String get statShownLabel => 'Shown';

  @override
  String get statSolvedLabel => 'Solved';

  @override
  String get challengeTypeMath => 'Mental math';

  @override
  String get challengeTypePuzzle => 'Puzzle';

  @override
  String get challengeTypeAction => 'Real action';

  @override
  String get challengeTypeDelay => 'Reflection delay';

  @override
  String get challengeTypeMirror => 'Mirror';

  @override
  String get challengeDescMath => 'Solve a simple calculation';

  @override
  String get challengeDescPuzzle => 'Schulte grid or Simon, at random';

  @override
  String get challengeDescAction =>
      'Count steps or shake your phone, at random';

  @override
  String get challengeDescDelay => 'A moment of reflection before continuing';

  @override
  String get challengeDescMirror =>
      'Face to face with the person responsible for your smartphone addiction! (camera required)';

  @override
  String get challengeSolvedTitle => 'Challenge solved!';

  @override
  String tryingToOpen(String appName) {
    return 'You\'re trying to open $appName';
  }

  @override
  String usageTodayLine(String duration) {
    return 'Usage today: $duration';
  }

  @override
  String openAppButton(String appName) {
    return 'Open $appName';
  }

  @override
  String get cancelChallengeButton => 'Cancel and stay here';

  @override
  String get mathPrompt =>
      'Solve this quick calculation to continue, so this choice is a conscious one.';

  @override
  String get mathWrongAnswer => 'Not quite, try again.';

  @override
  String schultePrompt(int gridSize) {
    return 'Tap the numbers in order, from 1 to $gridSize';
  }

  @override
  String get simonPreparing => 'Get ready, watch closely...';

  @override
  String get simonPlayback => 'Watch the sequence...';

  @override
  String simonInput(int current, int total) {
    return 'Repeat the sequence ($current/$total)';
  }

  @override
  String get simonWrong => 'Wrong, new sequence...';

  @override
  String get shakePrompt => 'Shake your phone';

  @override
  String get stepsPrompt => 'Take a few steps, phone in hand';

  @override
  String get delayQuestion1 => 'Why do you want to open this app right now?';

  @override
  String get delayQuestion2 => 'What are you hoping to find there?';

  @override
  String get delayQuestion3 => 'Could this wait a few minutes?';

  @override
  String get delayQuestion4 => 'What were you doing before this?';

  @override
  String continueWithCountdown(int remaining) {
    return 'Continue ($remaining)';
  }

  @override
  String get mirrorPunchline1 => 'Did you see yourself scrolling?';

  @override
  String get mirrorPunchline2 => 'That face, to open this?';

  @override
  String get mirrorPunchline3 => 'Take a good look before diving back in.';

  @override
  String get mirrorPunchline4 => 'Is this really the moment?';

  @override
  String get mirrorCameraUnavailable =>
      'Camera unavailable for this challenge.';
}
