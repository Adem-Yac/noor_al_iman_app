# Noor Al-Iman

Application Flutter — compagnon spirituel (Coran, Hadith, prières, Qibla).

## Stack (cahier des charges)

- Flutter + **Cubit/Bloc**
- **Dio** → UmmahAPI
- **Firebase** (Auth, Firestore, FCM, Storage)
- SharedPreferences pour les préférences locales

## Architecture (feature-first)

```
lib/
  main.dart
  app/                    # MaterialApp, thème
  core/                   # (à venir) network, errors, DI
  features/
    welcome/
      presentation/
        pages/
        widgets/
    # home, quran, hadith, prayer, qibla, settings…
```

Flux prévu : `UI → Cubit → Repository → Service (Dio/Firebase)`.

## Lancer

```bash
flutter pub get
flutter run
```
