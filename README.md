# Noor Al-Iman

App Flutter — Coran, prières, Hadith (cours : Auth, Firestore, SharedPreferences, Cubit, Rest API, UI).

## Lancer

```bash
flutter pub get
flutter run
```

## Architecture (leçons)

```
lib/
  app/                         # MaterialApp, thème, AuthGate, Firebase
  data/web_services/           # UmmahApiService (comme web_services du cours)
  features/
    auth/                      # Firebase Auth + Cubit + Firestore users
      data/repositories/
      presentation/cubit|pages|widgets/
    home/                      # Accueil + localisation SharedPreferences
      data/models|repositories|services/
      presentation/cubit|pages|widgets/
    prayer/                    # Horaires + notifications (prefs)
    quran/                     # API + Cubit + favoris Firestore/prefs
    hadith/                    # API + SharedPreferences favoris
```

## Stack cours

| Lesson | Usage dans l’app |
|--------|------------------|
| Firebase Auth | Login / Register / Google / AuthCubit |
| Cloud Firestore | Profil, localisation, Coran, prefs prière |
| SharedPreferences | Position, favoris hadith/coran, modes notif |
| Cubit | AuthCubit, HomeCubit, Quran*Cubit |
| Rest API (http) | `UmmahApiService` + mosquées |
| UI pages | Accueil, Coran, Prière, Hadith, Paramètres |
