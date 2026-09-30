import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Interceptor'**
  String get appTitle;

  /// No description provided for @activateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get activateLabel;

  /// No description provided for @activatedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Activé'**
  String get activatedLabel;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @validateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validateLabel;

  /// No description provided for @requiredLabel.
  ///
  /// In fr, this message translates to:
  /// **'requis'**
  String get requiredLabel;

  /// No description provided for @viewLabel.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get viewLabel;

  /// No description provided for @dismissLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get dismissLabel;

  /// No description provided for @statsEntryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques avancées'**
  String get statsEntryLabel;

  /// No description provided for @premiumLockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques avancées'**
  String get premiumLockedTitle;

  /// No description provided for @premiumLockedDescription.
  ///
  /// In fr, this message translates to:
  /// **'Débloque des statistiques détaillées : temps gagné par rapport à avant Interceptor, temps gagné par rapport à la période précédente, dissuasion par application et par type de défi, et une estimation du temps gagné basée sur tes dissuasions.'**
  String get premiumLockedDescription;

  /// No description provided for @premiumDebugToggleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Premium activé (test — en attendant le vrai paiement)'**
  String get premiumDebugToggleLabel;

  /// No description provided for @unlockTeaserTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvre ton temps gagné'**
  String get unlockTeaserTitle;

  /// No description provided for @unlockButton.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer les statistiques'**
  String get unlockButton;

  /// No description provided for @periodDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get periodYear;

  /// No description provided for @resetStatsButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les statistiques'**
  String get resetStatsButton;

  /// No description provided for @resetStatsConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les statistiques ?'**
  String get resetStatsConfirmTitle;

  /// No description provided for @resetStatsConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Tous les compteurs (défis, dissuasions, historique quotidien, bases de comparaison) repartiront à zéro. Les apps ciblées et leurs défis choisis ne sont pas affectés. Cette action est irréversible.'**
  String get resetStatsConfirmBody;

  /// No description provided for @resetStatsConfirmAction.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetStatsConfirmAction;

  /// No description provided for @cancelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelLabel;

  /// No description provided for @statVsBeforeInstall.
  ///
  /// In fr, this message translates to:
  /// **'Temps gagné vs avant Interceptor'**
  String get statVsBeforeInstall;

  /// No description provided for @statVsPreviousDay.
  ///
  /// In fr, this message translates to:
  /// **'Temps gagné vs hier'**
  String get statVsPreviousDay;

  /// No description provided for @statVsPreviousWeek.
  ///
  /// In fr, this message translates to:
  /// **'Temps gagné vs semaine passée'**
  String get statVsPreviousWeek;

  /// No description provided for @statVsPreviousMonth.
  ///
  /// In fr, this message translates to:
  /// **'Temps gagné vs mois passé'**
  String get statVsPreviousMonth;

  /// No description provided for @statVsPreviousYear.
  ///
  /// In fr, this message translates to:
  /// **'Temps gagné vs année passée'**
  String get statVsPreviousYear;

  /// No description provided for @statEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Temps gagné estimé (dissuasions)'**
  String get statEstimate;

  /// No description provided for @dissuasionByAppTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dissuasion par application'**
  String get dissuasionByAppTitle;

  /// No description provided for @noDataForPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Pas de données pour cette période.'**
  String get noDataForPeriod;

  /// No description provided for @statsLoadErrorText.
  ///
  /// In fr, this message translates to:
  /// **'Chargement interrompu, réessaie.'**
  String get statsLoadErrorText;

  /// No description provided for @retryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryLabel;

  /// No description provided for @vsPreviousPeriodIncompleteNote.
  ///
  /// In fr, this message translates to:
  /// **'Historique en cours de constitution — ce chiffre est une estimation partielle (sous-estimée).'**
  String get vsPreviousPeriodIncompleteNote;

  /// No description provided for @vsBeforeInstallIncompleteNote.
  ///
  /// In fr, this message translates to:
  /// **'Non disponible pour au moins une app ajoutée il y a plus d\'une semaine — cette période ne peut plus être récupérée.'**
  String get vsBeforeInstallIncompleteNote;

  /// No description provided for @perAppDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail par application'**
  String get perAppDetailTitle;

  /// No description provided for @notAvailableLabel.
  ///
  /// In fr, this message translates to:
  /// **'Non disponible'**
  String get notAvailableLabel;

  /// No description provided for @weeklyRecapBannerText.
  ///
  /// In fr, this message translates to:
  /// **'Ton récapitulatif de la semaine est prêt !'**
  String get weeklyRecapBannerText;

  /// No description provided for @weeklyRecapOptOut.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus afficher ce rappel chaque semaine'**
  String get weeklyRecapOptOut;

  /// No description provided for @onboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reprends la main sur tes apps'**
  String get onboardingTitle;

  /// No description provided for @onboardingIntro.
  ///
  /// In fr, this message translates to:
  /// **'Interceptor insère un petit défi avant l\'ouverture des apps que tu choisis, pour casser le réflexe d\'ouverture automatique. Deux réglages Android sont nécessaires — ils s\'activent en un tap, tu reviens automatiquement ici après.'**
  String get onboardingIntro;

  /// No description provided for @onboardingContinueButton.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai activé, continuer'**
  String get onboardingContinueButton;

  /// No description provided for @a11yCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Service d\'accessibilité'**
  String get a11yCardTitle;

  /// No description provided for @a11yCardDescription.
  ///
  /// In fr, this message translates to:
  /// **'Indispensable : permet de détecter quelle app tu lances.'**
  String get a11yCardDescription;

  /// No description provided for @a11yStep1.
  ///
  /// In fr, this message translates to:
  /// **'Cherche \"Interceptor\" dans la liste (parfois sous \"Applications installées\" ou \"Services téléchargés\")'**
  String get a11yStep1;

  /// No description provided for @a11yStep2.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre-le et active l\'interrupteur en haut'**
  String get a11yStep2;

  /// No description provided for @a11yStep3.
  ///
  /// In fr, this message translates to:
  /// **'Confirme en appuyant sur \"Autoriser\" dans la fenêtre qui apparaît'**
  String get a11yStep3;

  /// No description provided for @a11yStep4.
  ///
  /// In fr, this message translates to:
  /// **'Reviens ici avec la flèche retour — c\'est automatique, pas besoin de rien taper'**
  String get a11yStep4;

  /// No description provided for @usageAccessCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès à l\'utilisation'**
  String get usageAccessCardTitle;

  /// No description provided for @usageAccessCardDescription.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel : affiche ton temps passé sur chaque app pendant les défis.'**
  String get usageAccessCardDescription;

  /// No description provided for @usageAccessStep1.
  ///
  /// In fr, this message translates to:
  /// **'Cherche \"Interceptor\" dans la liste des apps'**
  String get usageAccessStep1;

  /// No description provided for @usageAccessStep2.
  ///
  /// In fr, this message translates to:
  /// **'Active l\'interrupteur à côté de son nom'**
  String get usageAccessStep2;

  /// No description provided for @addAppButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une app'**
  String get addAppButton;

  /// No description provided for @usageAccessBanner.
  ///
  /// In fr, this message translates to:
  /// **'Active l\'accès à l\'utilisation pour afficher ton temps passé sur chaque app pendant les défis.'**
  String get usageAccessBanner;

  /// No description provided for @statTriggered.
  ///
  /// In fr, this message translates to:
  /// **'Défis affichés'**
  String get statTriggered;

  /// No description provided for @statSolved.
  ///
  /// In fr, this message translates to:
  /// **'Défis résolus'**
  String get statSolved;

  /// No description provided for @statCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Dissuasions'**
  String get statCancelled;

  /// No description provided for @typeBreakdownTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dissuasion par type de défi'**
  String get typeBreakdownTitle;

  /// No description provided for @typeBreakdownLine.
  ///
  /// In fr, this message translates to:
  /// **'{label} : {rate}% ({count} {count, plural, =1{déclenchement} other{déclenchements}})'**
  String typeBreakdownLine(String label, int rate, int count);

  /// No description provided for @homeAppSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Défi} other{Défis}} : {types} · grâce {grace} min'**
  String homeAppSubtitle(int count, String types, int grace);

  /// No description provided for @emptyStateMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune app surveillée pour l\'instant.\nAjoute une app pour lui associer un défi.'**
  String get emptyStateMessage;

  /// No description provided for @pickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir des apps'**
  String get pickerTitle;

  /// No description provided for @minOneChallengeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un défi doit rester sélectionné.'**
  String get minOneChallengeRequired;

  /// No description provided for @narrowingReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel : le but est de te freiner, pas de réduire les défis possibles au plus facile à expédier.'**
  String get narrowingReminder;

  /// No description provided for @mirrorNeedsCameraPermission.
  ///
  /// In fr, this message translates to:
  /// **'Le défi Miroir a besoin de l\'accès à la caméra pour être activé.'**
  String get mirrorNeedsCameraPermission;

  /// No description provided for @possibleChallengesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Défis possibles'**
  String get possibleChallengesTitle;

  /// No description provided for @possibleChallengesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'À chaque déclenchement, un des défis cochés est tiré au hasard.'**
  String get possibleChallengesSubtitle;

  /// No description provided for @graceDurationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Durée de grâce après un défi résolu'**
  String get graceDurationTitle;

  /// No description provided for @graceMinutesValue.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} {minutes, plural, =1{minute} other{minutes}}'**
  String graceMinutesValue(int minutes);

  /// No description provided for @graceMinutesShort.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String graceMinutesShort(int minutes);

  /// No description provided for @saveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveButton;

  /// No description provided for @removeAppButton.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette app'**
  String get removeAppButton;

  /// No description provided for @statShownLabel.
  ///
  /// In fr, this message translates to:
  /// **'Affichés'**
  String get statShownLabel;

  /// No description provided for @statSolvedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Résolus'**
  String get statSolvedLabel;

  /// No description provided for @challengeTypeMath.
  ///
  /// In fr, this message translates to:
  /// **'Calcul mental'**
  String get challengeTypeMath;

  /// No description provided for @challengeTypePuzzle.
  ///
  /// In fr, this message translates to:
  /// **'Casse-tête'**
  String get challengeTypePuzzle;

  /// No description provided for @challengeTypeAction.
  ///
  /// In fr, this message translates to:
  /// **'Action réelle'**
  String get challengeTypeAction;

  /// No description provided for @challengeTypeDelay.
  ///
  /// In fr, this message translates to:
  /// **'Délai de réflexion'**
  String get challengeTypeDelay;

  /// No description provided for @challengeTypeMirror.
  ///
  /// In fr, this message translates to:
  /// **'Miroir'**
  String get challengeTypeMirror;

  /// No description provided for @challengeDescMath.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre une opération simple'**
  String get challengeDescMath;

  /// No description provided for @challengeDescPuzzle.
  ///
  /// In fr, this message translates to:
  /// **'Grille de Schulte ou Simon, au hasard'**
  String get challengeDescPuzzle;

  /// No description provided for @challengeDescAction.
  ///
  /// In fr, this message translates to:
  /// **'Compter des pas ou secouer le téléphone, au hasard'**
  String get challengeDescAction;

  /// No description provided for @challengeDescDelay.
  ///
  /// In fr, this message translates to:
  /// **'Un temps de réflexion avant de continuer'**
  String get challengeDescDelay;

  /// No description provided for @challengeDescMirror.
  ///
  /// In fr, this message translates to:
  /// **'Face à face avec la personne responsable de ton addiction au smartphone ! (caméra requise)'**
  String get challengeDescMirror;

  /// No description provided for @challengeSolvedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Défi réussi !'**
  String get challengeSolvedTitle;

  /// No description provided for @tryingToOpen.
  ///
  /// In fr, this message translates to:
  /// **'Tu essaies d\'ouvrir {appName}'**
  String tryingToOpen(String appName);

  /// No description provided for @usageTodayLine.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation aujourd\'hui : {duration}'**
  String usageTodayLine(String duration);

  /// No description provided for @openAppButton.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir {appName}'**
  String openAppButton(String appName);

  /// No description provided for @cancelChallengeButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler et rester ici'**
  String get cancelChallengeButton;

  /// No description provided for @mathPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Résous ce petit calcul pour continuer, histoire de faire ce choix en conscience.'**
  String get mathPrompt;

  /// No description provided for @mathWrongAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait, réessaie.'**
  String get mathWrongAnswer;

  /// No description provided for @schultePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Touche les nombres dans l\'ordre, de 1 à {gridSize}'**
  String schultePrompt(int gridSize);

  /// No description provided for @simonPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Prépare-toi, observe bien...'**
  String get simonPreparing;

  /// No description provided for @simonPlayback.
  ///
  /// In fr, this message translates to:
  /// **'Regarde la séquence...'**
  String get simonPlayback;

  /// No description provided for @simonInput.
  ///
  /// In fr, this message translates to:
  /// **'Reproduis la séquence ({current}/{total})'**
  String simonInput(int current, int total);

  /// No description provided for @simonWrong.
  ///
  /// In fr, this message translates to:
  /// **'Raté, nouvelle séquence...'**
  String get simonWrong;

  /// No description provided for @shakePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Secoue le téléphone'**
  String get shakePrompt;

  /// No description provided for @stepsPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Fais quelques pas, téléphone en main'**
  String get stepsPrompt;

  /// No description provided for @delayQuestion1.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi veux-tu ouvrir cette app maintenant ?'**
  String get delayQuestion1;

  /// No description provided for @delayQuestion2.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que tu espères y trouver ?'**
  String get delayQuestion2;

  /// No description provided for @delayQuestion3.
  ///
  /// In fr, this message translates to:
  /// **'Est-ce que ça peut attendre quelques minutes ?'**
  String get delayQuestion3;

  /// No description provided for @delayQuestion4.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'étais-tu en train de faire avant ?'**
  String get delayQuestion4;

  /// No description provided for @continueWithCountdown.
  ///
  /// In fr, this message translates to:
  /// **'Continuer ({remaining})'**
  String continueWithCountdown(int remaining);

  /// No description provided for @mirrorPunchline1.
  ///
  /// In fr, this message translates to:
  /// **'Tu t\'es vu quand tu scrolles ?'**
  String get mirrorPunchline1;

  /// No description provided for @mirrorPunchline2.
  ///
  /// In fr, this message translates to:
  /// **'Cette tête-là, pour ouvrir ça ?'**
  String get mirrorPunchline2;

  /// No description provided for @mirrorPunchline3.
  ///
  /// In fr, this message translates to:
  /// **'Regarde-toi bien avant de replonger.'**
  String get mirrorPunchline3;

  /// No description provided for @mirrorPunchline4.
  ///
  /// In fr, this message translates to:
  /// **'C\'est vraiment le moment ?'**
  String get mirrorPunchline4;

  /// No description provided for @mirrorCameraUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Caméra indisponible pour ce défi.'**
  String get mirrorCameraUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
