# Noor Al-Iman — Release v1.0.0

## Package

- **applicationId / namespace** : `com.nooraliman.app`
- **Version** : `1.0.0+1` (`pubspec.yaml`)

## Signature Android

Fichiers locaux (gitignored) :

- `android/upload-keystore.jks`
- `android/key.properties` (copier depuis `key.properties.example`)

### Empreintes à ajouter dans Firebase Console

**Release (upload keystore)**

- SHA-1 : `4E:B9:1D:4B:75:FC:2B:B4:25:C6:65:B3:35:20:07:1E:2E:0C:93:DF`
- SHA-256 : `58:47:D4:58:D6:17:BF:62:8E:9F:AA:4C:8C:7E:49:D5:4E:E0:46:A3:AC:CC:B0:F7:74:DA:F9:7F:9D:6C:B8:F1`

**Debug** (machine de dev — si présent) :

- SHA-1 : `C1:18:09:3F:36:9E:0E:D7:E3:49:B4:22:19:77:6F:E7:2F:6A:26:E0`
- SHA-256 : `72:E9:43:24:5C:29:DA:3B:BE:D3:8D:3D:E4:03:B4:1D:BE:72:A5:77:F5:DA:21:0C:95:BD:A6:A2:38:99:2D:41`

### Build APK / App Bundle

```bash
flutter build apk --release
flutter build appbundle --release
```

Sorties :

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## Firebase — actions manuelles obligatoires

Le package a changé (`com.example…` → `com.nooraliman.app`). Dans [Firebase Console](https://console.firebase.google.com/) projet `noor-al-iman-app` :

1. **Project settings → Your apps → Add app → Android**
   - Package name : `com.nooraliman.app`
2. Coller les **SHA-1 / SHA-256** (debug + release) ci-dessus.
3. Télécharger le **nouveau** `google-services.json` et remplacer `android/app/google-services.json`.
4. (Optionnel) Activer Google Sign-In / mettre à jour OAuth clients si besoin.
5. Déployer les règles Firestore :

```bash
firebase deploy --only firestore:rules
```

Fichier source : `firestore.rules` (accès owner-only sur `users`, `user_locations`, `quran_data`, `prayer_settings`).

Sans l’étape 1–3, Auth / Google Sign-In peuvent échouer après install release.

## Contenu FR

- UI complète FR / EN / AR.
- Titres des douas : dictionnaire local (`dua_titles.dart`).
- Traductions de douas : l’API Ummah ne fournit que l’anglais ; FR utilise le mapping local quand disponible, sinon l’anglais avec mention « source API ».

## Portfolio

Captures téléphone : dossier portfolio `noor-al-iman` (01–06). Voir `PORTFOLIO.md`.
