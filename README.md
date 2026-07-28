# Noor Al-Iman

App Flutter — Coran, prières, Qibla.

## Lancer

```bash
flutter pub get
flutter run
```

## Architecture

```
lib/
  app/                    # bootstrap, thème, auth gate
  features/
    auth/                 # login, register, Firestore users/{uid}
      data/
        repositories/     # AuthRepository, UserRepository
        services/           # AuthErrorMapper
      presentation/
        cubit/
        pages/
        widgets/
    home/                 # accueil, prières, paramètres
    quran/                # mushaf, audio, favoris cloud
```
