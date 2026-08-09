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
  static String get search => get('search');
  static String get favorites => get('favorites');
  static String get categories => get('categories');
  static String get featured => get('featured');
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
  static String get remaining => get('remaining');
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
  static String get back => get('back');

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
  static String get translationApiNote => get('translationApiNote');

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
    'search': 'Rechercher',
    'favorites': 'Favoris',
    'categories': 'Catégories',
    'featured': 'En vedette',
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
    'remaining': 'Il reste',
    'verseOfDay': 'Verset du jour',
    'duaOfDay': 'Doua du jour',
    'duasOfDay': 'Douas du jour',
    'duaUnavailable': 'Doua indisponible pour le moment',
    'nextSalat': 'PROCHAINE PRIÈRE',
    'inCountdown': 'Dans',
    'now': 'Maintenant',
    'notifAllow': 'Autorise les notifications pour recevoir l’adhan.',
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
    'back': 'Retour',
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
    'translationApiNote': 'Traduction (source API · anglais)',
    'onboardWelcomeTitle': 'Bienvenue sur Noor Al-Iman',
    'onboardWelcomeBody':
        'Coran, prières, hadiths et douas — un compagnon quotidien pour ta pratique.',
    'onboardLocationTitle': 'Localisation',
    'onboardLocationBody':
        'Autorise la localisation pour des horaires de prière précis selon ta ville.',
    'onboardNotifTitle': 'Notifications',
    'onboardNotifBody':
        'Reçois le rappel d’adhan ou de takbir pour ne pas manquer la prière.',
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
        'Les rappels de prière sont planifiés localement sur ton appareil (adhan / takbir / vibreur). Tu peux les désactiver dans les paramètres.',
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
    'search': 'Search',
    'favorites': 'Favorites',
    'categories': 'Categories',
    'featured': 'Featured',
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
    'remaining': 'Time left',
    'verseOfDay': 'Verse of the day',
    'duaOfDay': 'Dua of the day',
    'duasOfDay': 'Duas of the day',
    'duaUnavailable': 'Dua unavailable right now',
    'nextSalat': 'NEXT PRAYER',
    'inCountdown': 'In',
    'now': 'Now',
    'notifAllow': 'Allow notifications to receive the adhan.',
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
    'back': 'Back',
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
    'translationApiNote': 'Translation (API source · English)',
    'onboardWelcomeTitle': 'Welcome to Noor Al-Iman',
    'onboardWelcomeBody':
        'Quran, prayers, hadiths and duas — a daily companion for your practice.',
    'onboardLocationTitle': 'Location',
    'onboardLocationBody':
        'Allow location for accurate prayer times based on your city.',
    'onboardNotifTitle': 'Notifications',
    'onboardNotifBody':
        'Get adhan or takbir reminders so you don’t miss prayer time.',
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
        'Prayer reminders are scheduled locally on your device (adhan / takbir / vibrate). You can turn them off in settings.',
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
    'search': 'بحث',
    'favorites': 'المفضلة',
    'categories': 'التصنيفات',
    'featured': 'مميزة',
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
    'remaining': 'المتبقي',
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
    'back': 'رجوع',
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
    'translationApiNote': 'ترجمة (مصدر API · إنجليزي)',
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
  };
}

