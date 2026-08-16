import 'app_lang.dart';

/// Chaînes UI FR / EN / AR.
abstract final class S {
  static String get(String key) {
    final map = switch (AppLang.current) {
      AppLanguage.fr => _fr,
      AppLanguage.en => _en,
      AppLanguage.ar => _ar,
    };
    return map[key] ?? _fr[key] ?? key;
  }

  // ——— Nav ———
  static String get home => get('home');
  static String get quran => get('quran');
  static String get prayer => get('prayer');
  static String get hadith => get('hadith');
  static String get duas => get('duas');
  static String get settings => get('settings');

  // ——— Common ———
  static String get retry => get('retry');
  static String get cancel => get('cancel');
  static String get save => get('save');
  static String get share => get('share');
  static String get favorites => get('favorites');
  static String get categories => get('categories');
  static String get readMore => get('readMore');
  static String get listen => get('listen');
  static String get stop => get('stop');
  static String get previous => get('previous');
  static String get next => get('next');
  static String get source => get('source');
  static String get reset => get('reset');
  static String get done => get('done');
  static String get tap => get('tap');
  static String get logout => get('logout');

  // ——— Home ———
  static String get quickAccess => get('quickAccess');
  static String get nextPrayer => get('nextPrayer');
  static String get verseOfDay => get('verseOfDay');
  static String get duaOfDay => get('duaOfDay');
  static String get duasOfDay => get('duasOfDay');
  static String get duaUnavailable => get('duaUnavailable');

  // ——— Prayer ———
  static String get nextSalat => get('nextSalat');
  static String get inCountdown => get('inCountdown');
  static String get now => get('now');
  static String get notifAllow => get('notifAllow');
  static String get notification => get('notification');

  // ——— Duas ———
  static String get duasFeatured => get('duasFeatured');
  static String get reciteHint => get('reciteHint');
  static String get goal => get('goal');
  static String get nextDuaHint => get('nextDuaHint');
  static String get lastDua => get('lastDua');
  static String get goingNextDua => get('goingNextDua');
  static String get duaCopied => get('duaCopied');
  static String get searchDua => get('searchDua');

  // ——— Hadith ———
  static String get hadithFeatured => get('hadithFeatured');
  static String get hadithOfDay => get('hadithOfDay');
  static String get hadithCopied => get('hadithCopied');
  static String get searchHadith => get('searchHadith');
  static String get hadithDetail => get('hadithDetail');
  static String get addFavorite => get('addFavorite');
  static String get emptyFavorites => get('emptyFavorites');

  // ——— Quran ———
  static String get narratedBy => get('narratedBy');
  static String get book => get('book');
  static String get surahs => get('surahs');
  static String get tafsir => get('tafsir');
  static String get searchSurah => get('searchSurah');
  static String get lastReading => get('lastReading');
  static String get noSurahFound => get('noSurahFound');
  static String get verses => get('verses');

  // ——— Settings ———
  static String get account => get('account');
  static String get preferences => get('preferences');
  static String get system => get('system');
  static String get appLanguage => get('appLanguage');
  static String get theme => get('theme');
  static String get light => get('light');
  static String get dark => get('dark');
  static String get notifications => get('notifications');
  static String get location => get('location');
  static String get locationHint => get('locationHint');
  static String get refreshLocation => get('refreshLocation');
  static String get locationUpdated => get('locationUpdated');
  static String get locationFailed => get('locationFailed');
  static String get photoUpdated => get('photoUpdated');
  static String get photoFailed => get('photoFailed');
  static String get privacyPolicy => get('privacyPolicy');
  static String get about => get('about');
  static String get offlineTitle => get('offlineTitle');
  static String get offlineHint => get('offlineHint');
  static String get offlineBrowse => get('offlineBrowse');
  static String get offlineBrowseHint => get('offlineBrowseHint');
  static String get syncPending => get('syncPending');
  static String get translationApiNote => get('translationApiNote');
  static String get notifHint => get('notifHint');
  static String get defaultUser => get('defaultUser');
  static String get profilePhoto => get('profilePhoto');
  static String get chooseGallery => get('chooseGallery');
  static String get takePhoto => get('takePhoto');
  static String get removePhoto => get('removePhoto');
  static String get changePhoto => get('changePhoto');
  static String get changeDisplayName => get('changeDisplayName');
  static String get changePassword => get('changePassword');
  static String get displayName => get('displayName');
  static String get displayNameHint => get('displayNameHint');
  static String get nameEmpty => get('nameEmpty');
  static String get nameUpdated => get('nameUpdated');
  static String get googlePasswordHint => get('googlePasswordHint');
  static String get currentPassword => get('currentPassword');
  static String get newPassword => get('newPassword');
  static String get passwordMinHint => get('passwordMinHint');
  static String get confirmPassword => get('confirmPassword');
  static String get fillAllFields => get('fillAllFields');
  static String get passwordTooShort => get('passwordTooShort');
  static String get passwordMismatch => get('passwordMismatch');
  static String get passwordSame => get('passwordSame');
  static String get passwordUpdated => get('passwordUpdated');
  static String get nameUpdateFailed => get('nameUpdateFailed');
  static String get passwordUpdateFailed => get('passwordUpdateFailed');
  static String get locationGpsOff => get('locationGpsOff');
  static String get locationPermissionDenied => get('locationPermissionDenied');
  static String get locationUnavailable => get('locationUnavailable');
  static String myPosition(String coords) =>
      get('myPosition').replaceAll('{c}', coords);

  static String get onboardWelcomeTitle => get('onboardWelcomeTitle');
  static String get onboardWelcomeBody => get('onboardWelcomeBody');
  static String get onboardLocationTitle => get('onboardLocationTitle');
  static String get onboardLocationBody => get('onboardLocationBody');
  static String get onboardNotifTitle => get('onboardNotifTitle');
  static String get onboardNotifBody => get('onboardNotifBody');
  static String get onboardEnableLocation => get('onboardEnableLocation');
  static String get onboardEnableNotifs => get('onboardEnableNotifs');
  static String get onboardSkip => get('onboardSkip');

  static String get privacyIntroTitle => get('privacyIntroTitle');
  static String get privacyIntroBody => get('privacyIntroBody');
  static String get privacyDataTitle => get('privacyDataTitle');
  static String get privacyDataBody => get('privacyDataBody');
  static String get privacyLocationTitle => get('privacyLocationTitle');
  static String get privacyLocationBody => get('privacyLocationBody');
  static String get privacyNotifTitle => get('privacyNotifTitle');
  static String get privacyNotifBody => get('privacyNotifBody');
  static String get privacyRightsTitle => get('privacyRightsTitle');
  static String get privacyRightsBody => get('privacyRightsBody');
  static String get privacyUpdated => get('privacyUpdated');

  // ——— Auth ———
  static String get login => get('login');
  static String get register => get('register');
  static String get forgotPassword => get('forgotPassword');
  static String get email => get('email');
  static String get password => get('password');
  static String get name => get('name');

  // ——— Prayer names ———
  static String prayerName(String key) {
    final k = 'prayer_$key'.toLowerCase();
    return get(k);
  }

  static String notifMode(String mode) => get('mode_$mode');

  // ——— Notifications (textes courts) ———
  static String get notifPrayerTime => get('notifPrayerTime');
  /// Ex. « C'est l'heure de salat Asr »
  static String notifPrayerTimeFor(String prayerName) =>
      get('notifPrayerTimeFor').replaceAll('{name}', prayerName);
  static String get notifAdhan => get('notifAdhan');
  static String get notifTakbir => get('notifTakbir');
  static String get notifDuaOfDay => get('notifDuaOfDay');
  static String get notifChannelPrayer => get('notifChannelPrayer');
  static String get notifChannelAdhkar => get('notifChannelAdhkar');

  static const _fr = {
    'home': 'Accueil',
    'quran': 'Coran',
    'prayer': 'Prière',
    'hadith': 'Hadith',
    'duas': 'Douas',
    'settings': 'Paramètres',
    'retry': 'Réessayer',
    'cancel': 'Annuler',
    'save': 'Enregistrer',
    'share': 'Partager',
    'favorites': 'Favoris',
    'categories': 'Catégories',
    'readMore': 'Lire la suite',
    'listen': 'Écouter',
    'stop': 'Arrêter',
    'previous': 'Précédente',
    'next': 'Suivante',
    'source': 'SOURCE',
    'reset': 'Réinitialiser',
    'done': 'TERMINÉ',
    'tap': 'TAPER',
    'logout': 'Déconnexion',
    'quickAccess': 'Accès Rapide',
    'nextPrayer': 'PROCHAINE SALAT',
    'verseOfDay': 'Verset du jour',
    'duaOfDay': 'Doua du jour',
    'duasOfDay': 'Douas du jour',
    'duaUnavailable': 'Doua indisponible pour le moment',
    'nextSalat': 'PROCHAINE PRIÈRE',
    'inCountdown': 'Dans',
    'now': 'Maintenant',
    'notifAllow': 'Autorise les notifications pour les rappels de prière.',
    'notification': 'Notification',
    'duasFeatured': 'Douas en vedette',
    'reciteHint': 'Récite avec présence et sérénité.',
    'goal': 'Objectif',
    'nextDuaHint': 'Tapotez jusqu’à l’objectif, puis doua suivante',
    'lastDua': 'Dernière doua de la liste',
    'goingNextDua': 'Passage à la doua suivante…',
    'duaCopied': 'Doua copiée',
    'searchDua': 'Rechercher une invocation…',
    'hadithFeatured': 'Hadiths en vedette',
    'hadithOfDay': 'HADITH DU JOUR',
    'hadithCopied': 'Hadith copié',
    'searchHadith': 'Rechercher un hadith…',
    'hadithDetail': 'Détail Hadith',
    'addFavorite': 'Ajouter aux favoris',
    'emptyFavorites': 'Ajoute des hadiths à tes favoris',
    'narratedBy': 'Rapporté par :',
    'book': 'LIVRE',
    'surahs': 'Sourates',
    'tafsir': 'Tafsir',
    'searchSurah': 'Rechercher une sourate…',
    'lastReading': 'DERNIÈRE LECTURE',
    'noSurahFound': 'Aucune sourate trouvée',
    'verses': 'Versets',
    'account': 'Compte',
    'preferences': 'Préférences',
    'system': 'Système',
    'appLanguage': 'Langue de l’application',
    'theme': 'Thème',
    'light': 'Clair',
    'dark': 'Sombre',
    'notifications': 'Notifications',
    'location': 'Localisation',
    'locationHint': 'Pour les horaires de prière précis',
    'refreshLocation': 'Actualiser la position',
    'locationUpdated': 'Localisation mise à jour',
    'locationFailed': 'Impossible d’actualiser la position',
    'photoUpdated': 'Photo de profil mise à jour',
    'photoFailed': 'Impossible de changer la photo',
    'privacyPolicy': 'Politique de confidentialité',
    'about': 'À propos',
    'offlineTitle': 'Hors ligne',
    'offlineHint':
        'Pas de connexion. Les données enregistrées restent visibles. Réessaie quand le réseau revient.',
    'offlineBrowse': 'Lecture hors ligne',
    'offlineBrowseHint':
        'En Wi‑Fi, Coran, prières, hadiths et douas se téléchargent seuls',
    'syncPending': 'Synchronisation dès le retour du réseau…',
    'translationApiNote': 'Traduction (source API · anglais)',
    'notifHint': 'Adhan et rappels quotidiens',
    'defaultUser': 'Utilisateur Noor',
    'profilePhoto': 'Photo de profil',
    'chooseGallery': 'Choisir depuis la galerie',
    'takePhoto': 'Prendre une photo',
    'removePhoto': 'Supprimer la photo',
    'changePhoto': 'Changer la photo de profil',
    'changeDisplayName': 'Changer le nom d’affichage',
    'changePassword': 'Modifier le mot de passe',
    'displayName': 'Nom d’affichage',
    'displayNameHint': 'Ton prénom',
    'nameEmpty': 'Le nom ne peut pas être vide',
    'nameUpdated': 'Nom mis à jour',
    'googlePasswordHint':
        'Compte Google : le mot de passe se change dans ton compte Google.',
    'currentPassword': 'Mot de passe actuel',
    'newPassword': 'Nouveau mot de passe',
    'passwordMinHint': 'Minimum 6 caractères',
    'confirmPassword': 'Confirmer',
    'fillAllFields': 'Remplis tous les champs',
    'passwordTooShort':
        'Le nouveau mot de passe doit avoir au moins 6 caractères',
    'passwordMismatch': 'Les nouveaux mots de passe ne correspondent pas',
    'passwordSame': 'Le nouveau mot de passe doit être différent',
    'passwordUpdated': 'Mot de passe mis à jour',
    'locationGpsOff':
        'Active la localisation dans les paramètres du téléphone.',
    'locationPermissionDenied':
        'Localisation refusée. Active-la dans les paramètres de l’app.',
    'locationUnavailable':
        'Impossible d’obtenir ta position. Réessaie plus tard.',
    'myPosition': 'Ma position ({c})',
    'auth_invalid_email': 'Adresse e-mail invalide.',
    'auth_user_disabled': 'Ce compte a été désactivé.',
    'auth_user_not_found': 'Aucun compte avec cet e-mail.',
    'auth_wrong_password': 'Mot de passe incorrect.',
    'auth_email_already_in_use': 'Cet e-mail est déjà utilisé.',
    'auth_weak_password': 'Mot de passe trop faible (min. 6 caractères).',
    'auth_invalid_credential': 'Identifiants incorrects.',
    'auth_too_many_requests': 'Trop de tentatives. Réessaie plus tard.',
    'auth_network_request_failed': 'Connexion impossible. Vérifie le réseau.',
    'auth_operation_not_allowed':
        'Méthode de connexion non activée dans Firebase.',
    'auth_account_exists_with_different_credential':
        'Un compte existe déjà avec une autre méthode de connexion.',
    'auth_requires_recent_login': 'Reconnecte-toi pour continuer.',
    'auth_email_not_verified':
        'Vérifie ton e-mail avant de te connecter. Un nouveau lien a été envoyé.',
    'auth_google_sign_in_cancelled': 'Connexion Google annulée.',
    'auth_google_config_missing':
        'Connexion Google non configurée. Réinstalle l’app ou contacte le support.',
    'auth_google_signin_failed': 'Échec de la connexion Google. Réessaie.',
    'auth_invalid_display_name': 'Nom invalide (1 à 40 caractères).',
    'auth_password_not_available':
        'Ce compte utilise Google. Change le mot de passe dans ton compte Google.',
    'auth_unknown': 'Erreur d’authentification ({code}).',
    'auth_network_generic': 'Erreur réseau. Réessaie.',
    'auth_generic': 'Connexion impossible. Réessaie.',
    'nameUpdateFailed': 'Impossible de modifier le nom. Réessaie.',
    'passwordUpdateFailed':
        'Impossible de modifier le mot de passe. Réessaie.',
    'auth_signup_verify':
        'Compte créé. Vérifie ton e-mail (lien envoyé), puis connecte-toi.',
    'auth_reset_sent': 'E-mail de réinitialisation envoyé.',
    'onboardWelcomeTitle': 'Bienvenue sur Noor Al-Iman',
    'onboardWelcomeBody':
        'Coran, prières, hadiths et douas — un compagnon quotidien pour ta pratique.',
    'onboardLocationTitle': 'Localisation',
    'onboardLocationBody':
        'Autorise la localisation pour des horaires de prière précis selon ta ville.',
    'onboardNotifTitle': 'Notifications',
    'onboardNotifBody':
        'Reçois un rappel à l’heure de chaque salat pour ne pas manquer la prière.',
    'onboardEnableLocation': 'Autoriser la localisation',
    'onboardEnableNotifs': 'Autoriser les notifications',
    'onboardSkip': 'Passer',
    'privacyIntroTitle': 'Qui sommes-nous',
    'privacyIntroBody':
        'Noor Al-Iman est une application spirituelle (Coran, prières, hadiths, douas). Nous collectons uniquement ce qui est nécessaire au fonctionnement du compte et des horaires de prière.',
    'privacyDataTitle': 'Données du compte',
    'privacyDataBody':
        'E-mail, nom d’affichage, photo de profil (optionnelle) et préférences (langue, thème, modes de notification prière). Ces données sont liées à ton compte Firebase et accessibles uniquement par toi.',
    'privacyLocationTitle': 'Localisation',
    'privacyLocationBody':
        'La position (ou un libellé de ville) sert uniquement au calcul des horaires de prière. Elle peut être stockée localement et synchronisée sur ton compte. Tu peux la rafraîchir ou la refuser à tout moment.',
    'privacyNotifTitle': 'Notifications',
    'privacyNotifBody':
        'Les rappels de prière sont planifiés localement sur ton appareil. Tu peux les désactiver dans les paramètres.',
    'privacyRightsTitle': 'Tes droits',
    'privacyRightsBody':
        'Tu peux te déconnecter, supprimer tes données côté compte via les outils Firebase, ou nous contacter pour toute demande. Aucune publicité tierce n’est intégrée dans cette version.',
    'privacyUpdated': 'Dernière mise à jour : août 2026',
    'login': 'Se connecter',
    'register': 'S’inscrire',
    'forgotPassword': 'Mot de passe oublié',
    'email': 'E-mail',
    'password': 'Mot de passe',
    'name': 'Nom',
    'prayer_fajr': 'Fajr',
    'prayer_sunrise': 'Chourouq',
    'prayer_dhuhr': 'Dhuhr',
    'prayer_asr': 'Asr',
    'prayer_maghrib': 'Maghrib',
    'prayer_isha': 'Isha',
    'mode_off': 'Désactivé',
    'mode_vibration': 'Vibreur',
    'mode_takbir': 'Takbir',
    'mode_adhan': 'Adhan',
    'notifPrayerTime': 'Il est l’heure',
    'notifPrayerTimeFor': 'C’est l’heure de salat {name}',
    'notifAdhan': 'Adhan',
    'notifTakbir': 'Takbir',
    'notifDuaOfDay': 'Doua du jour',
    'notifChannelPrayer': 'Salat',
    'notifChannelAdhkar': 'Adhkar',
  };

  static const _en = {
    'home': 'Home',
    'quran': 'Quran',
    'prayer': 'Prayer',
    'hadith': 'Hadith',
    'duas': 'Duas',
    'settings': 'Settings',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'save': 'Save',
    'share': 'Share',
    'favorites': 'Favorites',
    'categories': 'Categories',
    'readMore': 'Read more',
    'listen': 'Listen',
    'stop': 'Stop',
    'previous': 'Previous',
    'next': 'Next',
    'source': 'SOURCE',
    'reset': 'Reset',
    'done': 'DONE',
    'tap': 'TAP',
    'logout': 'Log out',
    'quickAccess': 'Quick access',
    'nextPrayer': 'NEXT PRAYER',
    'verseOfDay': 'Verse of the day',
    'duaOfDay': 'Dua of the day',
    'duasOfDay': 'Duas of the day',
    'duaUnavailable': 'Dua unavailable right now',
    'nextSalat': 'NEXT PRAYER',
    'inCountdown': 'In',
    'now': 'Now',
    'notifAllow': 'Allow notifications for prayer reminders.',
    'notification': 'Notification',
    'duasFeatured': 'Featured duas',
    'reciteHint': 'Recite with presence and serenity.',
    'goal': 'Goal',
    'nextDuaHint': 'Tap until the goal, then next dua',
    'lastDua': 'Last dua in the list',
    'goingNextDua': 'Going to the next dua…',
    'duaCopied': 'Dua copied',
    'searchDua': 'Search a dua…',
    'hadithFeatured': 'Featured hadiths',
    'hadithOfDay': 'HADITH OF THE DAY',
    'hadithCopied': 'Hadith copied',
    'searchHadith': 'Search a hadith…',
    'hadithDetail': 'Hadith detail',
    'addFavorite': 'Add to favorites',
    'emptyFavorites': 'Add hadiths to your favorites',
    'narratedBy': 'Narrated by:',
    'book': 'BOOK',
    'surahs': 'Surahs',
    'tafsir': 'Tafsir',
    'searchSurah': 'Search a surah…',
    'lastReading': 'LAST READING',
    'noSurahFound': 'No surah found',
    'verses': 'Verses',
    'account': 'Account',
    'preferences': 'Preferences',
    'system': 'System',
    'appLanguage': 'App language',
    'theme': 'Theme',
    'light': 'Light',
    'dark': 'Dark',
    'notifications': 'Notifications',
    'location': 'Location',
    'locationHint': 'For accurate prayer times',
    'refreshLocation': 'Refresh location',
    'locationUpdated': 'Location updated',
    'locationFailed': 'Could not refresh location',
    'photoUpdated': 'Profile photo updated',
    'photoFailed': 'Could not change photo',
    'privacyPolicy': 'Privacy policy',
    'about': 'About',
    'offlineTitle': 'Offline',
    'offlineHint':
        'No connection. Saved data stays available. Retry when you are back online.',
    'offlineBrowse': 'Offline browsing',
    'offlineBrowseHint':
        'On Wi‑Fi, Quran, prayers, hadiths and duas download automatically',
    'syncPending': 'Will sync when you are back online…',
    'translationApiNote': 'Translation (API source · English)',
    'notifHint': 'Adhan and daily reminders',
    'defaultUser': 'Noor user',
    'profilePhoto': 'Profile photo',
    'chooseGallery': 'Choose from gallery',
    'takePhoto': 'Take a photo',
    'removePhoto': 'Remove photo',
    'changePhoto': 'Change profile photo',
    'changeDisplayName': 'Change display name',
    'changePassword': 'Change password',
    'displayName': 'Display name',
    'displayNameHint': 'Your first name',
    'nameEmpty': 'Name cannot be empty',
    'nameUpdated': 'Name updated',
    'googlePasswordHint':
        'Google account: change the password in your Google account.',
    'currentPassword': 'Current password',
    'newPassword': 'New password',
    'passwordMinHint': 'At least 6 characters',
    'confirmPassword': 'Confirm',
    'fillAllFields': 'Fill in all fields',
    'passwordTooShort': 'New password must be at least 6 characters',
    'passwordMismatch': 'New passwords do not match',
    'passwordSame': 'New password must be different',
    'passwordUpdated': 'Password updated',
    'locationGpsOff': 'Turn on location in your phone settings.',
    'locationPermissionDenied':
        'Location denied. Enable it in the app settings.',
    'locationUnavailable': 'Could not get your location. Try again later.',
    'myPosition': 'My location ({c})',
    'auth_invalid_email': 'Invalid email address.',
    'auth_user_disabled': 'This account has been disabled.',
    'auth_user_not_found': 'No account found with this email.',
    'auth_wrong_password': 'Incorrect password.',
    'auth_email_already_in_use': 'This email is already in use.',
    'auth_weak_password': 'Password too weak (min. 6 characters).',
    'auth_invalid_credential': 'Incorrect credentials.',
    'auth_too_many_requests': 'Too many attempts. Try again later.',
    'auth_network_request_failed': 'Connection failed. Check your network.',
    'auth_operation_not_allowed':
        'Sign-in method not enabled in Firebase.',
    'auth_account_exists_with_different_credential':
        'An account already exists with another sign-in method.',
    'auth_requires_recent_login': 'Sign in again to continue.',
    'auth_email_not_verified':
        'Verify your email before signing in. A new link was sent.',
    'auth_google_sign_in_cancelled': 'Google sign-in cancelled.',
    'auth_google_config_missing':
        'Google sign-in is not configured. Reinstall the app or contact support.',
    'auth_google_signin_failed': 'Google sign-in failed. Try again.',
    'auth_invalid_display_name': 'Invalid name (1 to 40 characters).',
    'auth_password_not_available':
        'This account uses Google. Change the password in your Google account.',
    'auth_unknown': 'Authentication error ({code}).',
    'auth_network_generic': 'Network error. Try again.',
    'auth_generic': 'Could not connect. Try again.',
    'nameUpdateFailed': 'Could not update name. Try again.',
    'passwordUpdateFailed': 'Could not update password. Try again.',
    'auth_signup_verify':
        'Account created. Check your email (link sent), then sign in.',
    'auth_reset_sent': 'Password reset email sent.',
    'onboardWelcomeTitle': 'Welcome to Noor Al-Iman',
    'onboardWelcomeBody':
        'Quran, prayers, hadiths and duas — a daily companion for your practice.',
    'onboardLocationTitle': 'Location',
    'onboardLocationBody':
        'Allow location for accurate prayer times based on your city.',
    'onboardNotifTitle': 'Notifications',
    'onboardNotifBody':
        'Get a reminder at each prayer time so you don’t miss salat.',
    'onboardEnableLocation': 'Allow location',
    'onboardEnableNotifs': 'Allow notifications',
    'onboardSkip': 'Skip',
    'privacyIntroTitle': 'Who we are',
    'privacyIntroBody':
        'Noor Al-Iman is a spiritual app (Quran, prayers, hadiths, duas). We only collect what is needed for your account and prayer times.',
    'privacyDataTitle': 'Account data',
    'privacyDataBody':
        'Email, display name, optional profile photo, and preferences (language, theme, prayer notification modes). Data is tied to your Firebase account and only accessible by you.',
    'privacyLocationTitle': 'Location',
    'privacyLocationBody':
        'Your position (or city label) is used only to compute prayer times. It may be stored locally and synced to your account. You can refresh or deny it anytime.',
    'privacyNotifTitle': 'Notifications',
    'privacyNotifBody':
        'Prayer reminders are scheduled locally on your device. You can turn them off in settings.',
    'privacyRightsTitle': 'Your rights',
    'privacyRightsBody':
        'You can sign out, delete account data via Firebase tools, or contact us for any request. No third-party ads are included in this version.',
    'privacyUpdated': 'Last updated: August 2026',
    'login': 'Sign in',
    'register': 'Sign up',
    'forgotPassword': 'Forgot password',
    'email': 'Email',
    'password': 'Password',
    'name': 'Name',
    'prayer_fajr': 'Fajr',
    'prayer_sunrise': 'Sunrise',
    'prayer_dhuhr': 'Dhuhr',
    'prayer_asr': 'Asr',
    'prayer_maghrib': 'Maghrib',
    'prayer_isha': 'Isha',
    'mode_off': 'Off',
    'mode_vibration': 'Vibrate',
    'mode_takbir': 'Takbir',
    'mode_adhan': 'Adhan',
    'notifPrayerTime': 'It is time',
    'notifPrayerTimeFor': 'It is time for {name} prayer',
    'notifAdhan': 'Adhan',
    'notifTakbir': 'Takbir',
    'notifDuaOfDay': 'Dua of the day',
    'notifChannelPrayer': 'Prayer',
    'notifChannelAdhkar': 'Adhkar',
  };

  static const _ar = {
    'home': 'الرئيسية',
    'quran': 'القرآن',
    'prayer': 'الصلاة',
    'hadith': 'الحديث',
    'duas': 'الأدعية',
    'settings': 'الإعدادات',
    'retry': 'إعادة المحاولة',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'share': 'مشاركة',
    'favorites': 'المفضلة',
    'categories': 'التصنيفات',
    'readMore': 'اقرأ المزيد',
    'listen': 'استماع',
    'stop': 'إيقاف',
    'previous': 'السابق',
    'next': 'التالي',
    'source': 'المصدر',
    'reset': 'إعادة',
    'done': 'تم',
    'tap': 'اضغط',
    'logout': 'تسجيل الخروج',
    'quickAccess': 'وصول سريع',
    'nextPrayer': 'الصلاة القادمة',
    'verseOfDay': 'آية اليوم',
    'duaOfDay': 'دعاء اليوم',
    'duasOfDay': 'أدعية اليوم',
    'duaUnavailable': 'الدعاء غير متاح حالياً',
    'nextSalat': 'الصلاة القادمة',
    'inCountdown': 'بعد',
    'now': 'الآن',
    'notifAllow': 'اسمح بالإشعارات لتلقي الأذان.',
    'notification': 'إشعار',
    'duasFeatured': 'أدعية مميزة',
    'reciteHint': 'اتلُ بخشوع وطمأنينة.',
    'goal': 'الهدف',
    'nextDuaHint': 'اضغط حتى الهدف ثم الدعاء التالي',
    'lastDua': 'آخر دعاء في القائمة',
    'goingNextDua': 'الانتقال إلى الدعاء التالي…',
    'duaCopied': 'تم نسخ الدعاء',
    'searchDua': 'ابحث عن دعاء…',
    'hadithFeatured': 'أحاديث مميزة',
    'hadithOfDay': 'حديث اليوم',
    'hadithCopied': 'تم نسخ الحديث',
    'searchHadith': 'ابحث عن حديث…',
    'hadithDetail': 'تفاصيل الحديث',
    'addFavorite': 'إضافة إلى المفضلة',
    'emptyFavorites': 'أضف أحاديث إلى المفضلة',
    'narratedBy': 'رواه:',
    'book': 'الكتاب',
    'surahs': 'السور',
    'tafsir': 'التفسير',
    'searchSurah': 'ابحث عن سورة…',
    'lastReading': 'آخر قراءة',
    'noSurahFound': 'لم يتم العثور على سورة',
    'verses': 'آيات',
    'account': 'الحساب',
    'preferences': 'التفضيلات',
    'system': 'النظام',
    'appLanguage': 'لغة التطبيق',
    'theme': 'المظهر',
    'light': 'فاتح',
    'dark': 'داكن',
    'notifications': 'الإشعارات',
    'location': 'الموقع',
    'locationHint': 'لأوقات الصلاة الدقيقة',
    'refreshLocation': 'تحديث الموقع',
    'locationUpdated': 'تم تحديث الموقع',
    'locationFailed': 'تعذر تحديث الموقع',
    'photoUpdated': 'تم تحديث صورة الملف',
    'photoFailed': 'تعذر تغيير الصورة',
    'privacyPolicy': 'سياسة الخصوصية',
    'about': 'حول التطبيق',
    'offlineTitle': 'بدون اتصال',
    'offlineHint':
        'لا يوجد اتصال. تبقى البيانات المحفوظة متاحة. أعد المحاولة عند عودة الشبكة.',
    'offlineBrowse': 'التصفح دون اتصال',
    'offlineBrowseHint':
        'على الواي فاي يُحمَّل القرآن والصلوات والأحاديث والأدعية تلقائيًا',
    'syncPending': 'ستتم المزامنة عند عودة الاتصال…',
    'translationApiNote': 'ترجمة (مصدر API · إنجليزي)',
    'notifHint': 'الأذان والتذكيرات اليومية',
    'defaultUser': 'مستخدم نور',
    'profilePhoto': 'صورة الملف الشخصي',
    'chooseGallery': 'اختيار من المعرض',
    'takePhoto': 'التقاط صورة',
    'removePhoto': 'حذف الصورة',
    'changePhoto': 'تغيير صورة الملف الشخصي',
    'changeDisplayName': 'تغيير الاسم المعروض',
    'changePassword': 'تغيير كلمة المرور',
    'displayName': 'الاسم المعروض',
    'displayNameHint': 'اسمك',
    'nameEmpty': 'لا يمكن أن يكون الاسم فارغًا',
    'nameUpdated': 'تم تحديث الاسم',
    'googlePasswordHint':
        'حساب Google: غيّر كلمة المرور من حساب Google.',
    'currentPassword': 'كلمة المرور الحالية',
    'newPassword': 'كلمة المرور الجديدة',
    'passwordMinHint': '6 أحرف على الأقل',
    'confirmPassword': 'تأكيد',
    'fillAllFields': 'املأ جميع الحقول',
    'passwordTooShort': 'يجب أن تكون كلمة المرور الجديدة 6 أحرف على الأقل',
    'passwordMismatch': 'كلمتا المرور الجديدتان غير متطابقتين',
    'passwordSame': 'يجب أن تكون كلمة المرور الجديدة مختلفة',
    'passwordUpdated': 'تم تحديث كلمة المرور',
    'locationGpsOff': 'فعّل الموقع من إعدادات الهاتف.',
    'locationPermissionDenied':
        'تم رفض الموقع. فعّله من إعدادات التطبيق.',
    'locationUnavailable': 'تعذر الحصول على موقعك. حاول لاحقًا.',
    'myPosition': 'موقعي ({c})',
    'auth_invalid_email': 'عنوان البريد غير صالح.',
    'auth_user_disabled': 'تم تعطيل هذا الحساب.',
    'auth_user_not_found': 'لا يوجد حساب بهذا البريد.',
    'auth_wrong_password': 'كلمة المرور غير صحيحة.',
    'auth_email_already_in_use': 'هذا البريد مستخدم بالفعل.',
    'auth_weak_password': 'كلمة المرور ضعيفة جدًا (6 أحرف على الأقل).',
    'auth_invalid_credential': 'بيانات الدخول غير صحيحة.',
    'auth_too_many_requests': 'محاولات كثيرة. حاول لاحقًا.',
    'auth_network_request_failed': 'تعذر الاتصال. تحقق من الشبكة.',
    'auth_operation_not_allowed':
        'طريقة تسجيل الدخول غير مفعّلة في Firebase.',
    'auth_account_exists_with_different_credential':
        'يوجد حساب بالفعل بطريقة تسجيل دخول أخرى.',
    'auth_requires_recent_login': 'سجّل الدخول مرة أخرى للمتابعة.',
    'auth_email_not_verified':
        'تحقق من بريدك قبل تسجيل الدخول. تم إرسال رابط جديد.',
    'auth_google_sign_in_cancelled': 'تم إلغاء تسجيل الدخول عبر Google.',
    'auth_google_config_missing':
        'تسجيل الدخول عبر Google غير مضبوط. أعد تثبيت التطبيق أو تواصل مع الدعم.',
    'auth_google_signin_failed': 'فشل تسجيل الدخول عبر Google. حاول مجددًا.',
    'auth_invalid_display_name': 'اسم غير صالح (من 1 إلى 40 حرفًا).',
    'auth_password_not_available':
        'هذا الحساب يستخدم Google. غيّر كلمة المرور من حساب Google.',
    'auth_unknown': 'خطأ في المصادقة ({code}).',
    'auth_network_generic': 'خطأ في الشبكة. حاول مجددًا.',
    'auth_generic': 'تعذر الاتصال. حاول مجددًا.',
    'nameUpdateFailed': 'تعذر تعديل الاسم. حاول مجددًا.',
    'passwordUpdateFailed': 'تعذر تعديل كلمة المرور. حاول مجددًا.',
    'auth_signup_verify':
        'تم إنشاء الحساب. تحقق من بريدك (تم إرسال رابط) ثم سجّل الدخول.',
    'auth_reset_sent': 'تم إرسال بريد إعادة تعيين كلمة المرور.',
    'onboardWelcomeTitle': 'مرحبًا بك في نور الإيمان',
    'onboardWelcomeBody':
        'قرآن وصلوات وأحاديث وأدعية — رفيق يومي لعبادتك.',
    'onboardLocationTitle': 'الموقع',
    'onboardLocationBody':
        'اسمح بالموقع للحصول على أوقات صلاة دقيقة حسب مدينتك.',
    'onboardNotifTitle': 'الإشعارات',
    'onboardNotifBody':
        'استقبل تذكير الأذان أو التكبير حتى لا تفوتك الصلاة.',
    'onboardEnableLocation': 'السماح بالموقع',
    'onboardEnableNotifs': 'السماح بالإشعارات',
    'onboardSkip': 'تخطي',
    'privacyIntroTitle': 'من نحن',
    'privacyIntroBody':
        'نور الإيمان تطبيق روحاني (قرآن، صلوات، أحاديث، أدعية). نجمع فقط ما يلزم للحساب وأوقات الصلاة.',
    'privacyDataTitle': 'بيانات الحساب',
    'privacyDataBody':
        'البريد، الاسم، الصورة الاختيارية، والتفضيلات (اللغة، المظهر، أوضاع تنبيه الصلاة). البيانات مرتبطة بحساب Firebase ومتاحة لك وحدك.',
    'privacyLocationTitle': 'الموقع',
    'privacyLocationBody':
        'يُستخدم الموقع (أو اسم المدينة) فقط لحساب أوقات الصلاة، وقد يُخزَّن محليًا ويُزامن مع حسابك. يمكنك التحديث أو الرفض في أي وقت.',
    'privacyNotifTitle': 'الإشعارات',
    'privacyNotifBody':
        'تُجدول تذكيرات الصلاة محليًا على جهازك (أذان / تكبير / اهتزاز). يمكنك إيقافها من الإعدادات.',
    'privacyRightsTitle': 'حقوقك',
    'privacyRightsBody':
        'يمكنك تسجيل الخروج أو حذف بيانات الحساب عبر أدوات Firebase أو التواصل معنا. لا إعلانات طرف ثالث في هذا الإصدار.',
    'privacyUpdated': 'آخر تحديث: أغسطس 2026',
    'login': 'تسجيل الدخول',
    'register': 'إنشاء حساب',
    'forgotPassword': 'نسيت كلمة المرور',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'name': 'الاسم',
    'prayer_fajr': 'الفجر',
    'prayer_sunrise': 'الشروق',
    'prayer_dhuhr': 'الظهر',
    'prayer_asr': 'العصر',
    'prayer_maghrib': 'المغرب',
    'prayer_isha': 'العشاء',
    'mode_off': 'إيقاف',
    'mode_vibration': 'اهتزاز',
    'mode_takbir': 'تكبير',
    'mode_adhan': 'أذان',
    'notifPrayerTime': 'حان الوقت',
    'notifPrayerTimeFor': 'حان وقت صلاة {name}',
    'notifAdhan': 'أذان',
    'notifTakbir': 'تكبير',
    'notifDuaOfDay': 'دعاء اليوم',
    'notifChannelPrayer': 'الصلاة',
    'notifChannelAdhkar': 'الأذكار',
  };
}

