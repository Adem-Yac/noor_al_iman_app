/// Chemins Firestore Noor Al-Iman (collections = tables).
///
/// Schéma documenté dans `docs/FIRESTORE.md`.
abstract final class FirestorePaths {
  /// Profil compte — doc `{uid}`
  static const users = 'users';

  /// Position GPS / ville — doc `{uid}`
  static const userLocations = 'user_locations';

  /// Dernière lecture Coran + favoris — doc `{uid}`
  static const quranData = 'quran_data';

  /// Modes notifs prière — doc `{uid}`
  static const prayerSettings = 'prayer_settings';

  /// Favoris hadiths — doc `{uid}`
  static const hadithData = 'hadith_data';
}
