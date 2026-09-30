// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Interceptor';

  @override
  String get activateLabel => 'Activer';

  @override
  String get activatedLabel => 'Activé';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get validateLabel => 'Valider';

  @override
  String get requiredLabel => 'requis';

  @override
  String get viewLabel => 'Voir';

  @override
  String get dismissLabel => 'Ignorer';

  @override
  String get statsEntryLabel => 'Statistiques avancées';

  @override
  String get premiumLockedTitle => 'Statistiques avancées';

  @override
  String get premiumLockedDescription =>
      'Débloque des statistiques détaillées : temps gagné par rapport à avant Interceptor, temps gagné par rapport à la période précédente, dissuasion par application et par type de défi, et une estimation du temps gagné basée sur tes dissuasions.';

  @override
  String get premiumDebugToggleLabel =>
      'Premium activé (test — en attendant le vrai paiement)';

  @override
  String get unlockTeaserTitle => 'Découvre ton temps gagné';

  @override
  String get unlockButton => 'Débloquer les statistiques';

  @override
  String get periodDay => 'Jour';

  @override
  String get periodWeek => 'Semaine';

  @override
  String get periodMonth => 'Mois';

  @override
  String get periodYear => 'Année';

  @override
  String get resetStatsButton => 'Réinitialiser les statistiques';

  @override
  String get resetStatsConfirmTitle => 'Réinitialiser les statistiques ?';

  @override
  String get resetStatsConfirmBody =>
      'Tous les compteurs (défis, dissuasions, historique quotidien, bases de comparaison) repartiront à zéro. Les apps ciblées et leurs défis choisis ne sont pas affectés. Cette action est irréversible.';

  @override
  String get resetStatsConfirmAction => 'Réinitialiser';

  @override
  String get cancelLabel => 'Annuler';

  @override
  String get statVsBeforeInstall => 'Temps gagné vs avant Interceptor';

  @override
  String get statVsPreviousDay => 'Temps gagné vs hier';

  @override
  String get statVsPreviousWeek => 'Temps gagné vs semaine passée';

  @override
  String get statVsPreviousMonth => 'Temps gagné vs mois passé';

  @override
  String get statVsPreviousYear => 'Temps gagné vs année passée';

  @override
  String get statEstimate => 'Temps gagné estimé (dissuasions)';

  @override
  String get dissuasionByAppTitle => 'Dissuasion par application';

  @override
  String get noDataForPeriod => 'Pas de données pour cette période.';

  @override
  String get statsLoadErrorText => 'Chargement interrompu, réessaie.';

  @override
  String get retryLabel => 'Réessayer';

  @override
  String get vsPreviousPeriodIncompleteNote =>
      'Historique en cours de constitution — ce chiffre est une estimation partielle (sous-estimée).';

  @override
  String get vsBeforeInstallIncompleteNote =>
      'Non disponible pour au moins une app ajoutée il y a plus d\'une semaine — cette période ne peut plus être récupérée.';

  @override
  String get perAppDetailTitle => 'Détail par application';

  @override
  String get notAvailableLabel => 'Non disponible';

  @override
  String get weeklyRecapBannerText =>
      'Ton récapitulatif de la semaine est prêt !';

  @override
  String get weeklyRecapOptOut => 'Ne plus afficher ce rappel chaque semaine';

  @override
  String get onboardingTitle => 'Reprends la main sur tes apps';

  @override
  String get onboardingIntro =>
      'Interceptor insère un petit défi avant l\'ouverture des apps que tu choisis, pour casser le réflexe d\'ouverture automatique. Deux réglages Android sont nécessaires — ils s\'activent en un tap, tu reviens automatiquement ici après.';

  @override
  String get onboardingContinueButton => 'J\'ai activé, continuer';

  @override
  String get a11yCardTitle => 'Service d\'accessibilité';

  @override
  String get a11yCardDescription =>
      'Indispensable : permet de détecter quelle app tu lances.';

  @override
  String get a11yStep1 =>
      'Cherche \"Interceptor\" dans la liste (parfois sous \"Applications installées\" ou \"Services téléchargés\")';

  @override
  String get a11yStep2 => 'Ouvre-le et active l\'interrupteur en haut';

  @override
  String get a11yStep3 =>
      'Confirme en appuyant sur \"Autoriser\" dans la fenêtre qui apparaît';

  @override
  String get a11yStep4 =>
      'Reviens ici avec la flèche retour — c\'est automatique, pas besoin de rien taper';

  @override
  String get usageAccessCardTitle => 'Accès à l\'utilisation';

  @override
  String get usageAccessCardDescription =>
      'Optionnel : affiche ton temps passé sur chaque app pendant les défis.';

  @override
  String get usageAccessStep1 =>
      'Cherche \"Interceptor\" dans la liste des apps';

  @override
  String get usageAccessStep2 => 'Active l\'interrupteur à côté de son nom';

  @override
  String get addAppButton => 'Ajouter une app';

  @override
  String get usageAccessBanner =>
      'Active l\'accès à l\'utilisation pour afficher ton temps passé sur chaque app pendant les défis.';

  @override
  String get statTriggered => 'Défis affichés';

  @override
  String get statSolved => 'Défis résolus';

  @override
  String get statCancelled => 'Dissuasions';

  @override
  String get typeBreakdownTitle => 'Dissuasion par type de défi';

  @override
  String typeBreakdownLine(String label, int rate, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'déclenchements',
      one: 'déclenchement',
    );
    return '$label : $rate% ($count $_temp0)';
  }

  @override
  String homeAppSubtitle(int count, String types, int grace) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Défis',
      one: 'Défi',
    );
    return '$_temp0 : $types · grâce $grace min';
  }

  @override
  String get emptyStateMessage =>
      'Aucune app surveillée pour l\'instant.\nAjoute une app pour lui associer un défi.';

  @override
  String get pickerTitle => 'Choisir des apps';

  @override
  String get minOneChallengeRequired =>
      'Au moins un défi doit rester sélectionné.';

  @override
  String get narrowingReminder =>
      'Rappel : le but est de te freiner, pas de réduire les défis possibles au plus facile à expédier.';

  @override
  String get mirrorNeedsCameraPermission =>
      'Le défi Miroir a besoin de l\'accès à la caméra pour être activé.';

  @override
  String get possibleChallengesTitle => 'Défis possibles';

  @override
  String get possibleChallengesSubtitle =>
      'À chaque déclenchement, un des défis cochés est tiré au hasard.';

  @override
  String get graceDurationTitle => 'Durée de grâce après un défi résolu';

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
  String get saveButton => 'Enregistrer';

  @override
  String get removeAppButton => 'Retirer cette app';

  @override
  String get statShownLabel => 'Affichés';

  @override
  String get statSolvedLabel => 'Résolus';

  @override
  String get challengeTypeMath => 'Calcul mental';

  @override
  String get challengeTypePuzzle => 'Casse-tête';

  @override
  String get challengeTypeAction => 'Action réelle';

  @override
  String get challengeTypeDelay => 'Délai de réflexion';

  @override
  String get challengeTypeMirror => 'Miroir';

  @override
  String get challengeDescMath => 'Résoudre une opération simple';

  @override
  String get challengeDescPuzzle => 'Grille de Schulte ou Simon, au hasard';

  @override
  String get challengeDescAction =>
      'Compter des pas ou secouer le téléphone, au hasard';

  @override
  String get challengeDescDelay => 'Un temps de réflexion avant de continuer';

  @override
  String get challengeDescMirror =>
      'Face à face avec la personne responsable de ton addiction au smartphone ! (caméra requise)';

  @override
  String get challengeSolvedTitle => 'Défi réussi !';

  @override
  String tryingToOpen(String appName) {
    return 'Tu essaies d\'ouvrir $appName';
  }

  @override
  String usageTodayLine(String duration) {
    return 'Utilisation aujourd\'hui : $duration';
  }

  @override
  String openAppButton(String appName) {
    return 'Ouvrir $appName';
  }

  @override
  String get cancelChallengeButton => 'Annuler et rester ici';

  @override
  String get mathPrompt =>
      'Résous ce petit calcul pour continuer, histoire de faire ce choix en conscience.';

  @override
  String get mathWrongAnswer => 'Pas tout à fait, réessaie.';

  @override
  String schultePrompt(int gridSize) {
    return 'Touche les nombres dans l\'ordre, de 1 à $gridSize';
  }

  @override
  String get simonPreparing => 'Prépare-toi, observe bien...';

  @override
  String get simonPlayback => 'Regarde la séquence...';

  @override
  String simonInput(int current, int total) {
    return 'Reproduis la séquence ($current/$total)';
  }

  @override
  String get simonWrong => 'Raté, nouvelle séquence...';

  @override
  String get shakePrompt => 'Secoue le téléphone';

  @override
  String get stepsPrompt => 'Fais quelques pas, téléphone en main';

  @override
  String get delayQuestion1 => 'Pourquoi veux-tu ouvrir cette app maintenant ?';

  @override
  String get delayQuestion2 => 'Qu\'est-ce que tu espères y trouver ?';

  @override
  String get delayQuestion3 => 'Est-ce que ça peut attendre quelques minutes ?';

  @override
  String get delayQuestion4 => 'Qu\'étais-tu en train de faire avant ?';

  @override
  String continueWithCountdown(int remaining) {
    return 'Continuer ($remaining)';
  }

  @override
  String get mirrorPunchline1 => 'Tu t\'es vu quand tu scrolles ?';

  @override
  String get mirrorPunchline2 => 'Cette tête-là, pour ouvrir ça ?';

  @override
  String get mirrorPunchline3 => 'Regarde-toi bien avant de replonger.';

  @override
  String get mirrorPunchline4 => 'C\'est vraiment le moment ?';

  @override
  String get mirrorCameraUnavailable => 'Caméra indisponible pour ce défi.';
}
