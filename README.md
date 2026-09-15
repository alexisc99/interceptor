# Interceptor

Reprends la main sur tes apps chronophages. Interceptor insère un petit défi
conscient (calcul mental, casse-tête, action réelle, délai de réflexion)
avant l'ouverture des apps que tu choisis, pour casser le réflexe
d'ouverture automatique — sans les bloquer complètement.

## Comment ça marche

- Un service d'accessibilité Android détecte quand une app ciblée passe au
  premier plan et affiche un défi à la place.
- Une fois le défi résolu, un bouton explicite ("Ouvrir <app>") permet de
  lancer l'app — la résolution du défi ne l'ouvre pas automatiquement.
- Une période de grâce configurable évite de redéclencher le défi à chaque
  bascule d'app.
- Tout reste en local sur l'appareil (Hive) ; aucune donnée n'est envoyée à
  l'extérieur.

## Défis disponibles

- **Calcul mental** — une opération simple à résoudre.
- **Casse-tête** — grille de Schulte ou Simon, au hasard.
- **Action réelle** — compter des pas ou secouer le téléphone, au hasard.
- **Délai de réflexion** — une question et un court compte à rebours avant
  de pouvoir continuer.

## Statistiques

- Compteurs par app : défis affichés, résolus, et dissuasions (annulations
  volontaires — la friction a fonctionné).
- Répartition de la dissuasion par type de défi.
- Comparaison du temps d'utilisation quotidien moyen avant/après l'ajout
  d'une app (nécessite la permission "Accès à l'utilisation").

## Développement

Projet Flutter (Android uniquement pour l'instant) avec une partie native
Kotlin pour le service d'accessibilité et la lecture des statistiques
d'utilisation Android (`UsageStatsManager`).

```bash
flutter pub get
flutter build apk --release
```

Le mode debug ne fonctionne pas pour l'écran de défi (point d'entrée Dart
alternatif non résolu en JIT) — utiliser `--release` ou `--profile` pour
tester sur appareil.
