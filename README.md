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
  app/                 # thème + MaterialApp
  features/
    welcome/
    home/              # UI → Cubit → Repository → UmmahAPI / GPS
```
