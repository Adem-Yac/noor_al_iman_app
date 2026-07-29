import 'package:flutter_test/flutter_test.dart';
import 'package:noor_al_iman_app/features/home/data/models/home_data.dart';
import 'package:noor_al_iman_app/features/prayer/data/models/prayer_summary.dart';

void main() {
  test('parses UmmahAPI prayer status and progress', () {
    final prayer = PrayerSummary.fromJson({
      'data': {
        'prayer_times': {'dhuhr': '13:24', 'asr': '16:42', 'fajr': '05:10'},
        'current_status': {
          'current_prayer': 'dhuhr',
          'next_prayer': 'asr',
          'time_until_next': '45 minutes',
          'minutes_until_next': 45,
        },
      },
    });

    expect(prayer.currentTime, '13:24');
    expect(prayer.nextTime, '16:42');
    expect(prayer.displayTimes.length, 3);
    expect(prayer.progress, closeTo(0.77, 0.01));
  });

  test('parses today hijri calendar', () {
    final calendar = IslamicCalendar.fromJson({
      'data': {
        'gregorian': {
          'day_of_week': 'Saturday',
          'day': 25,
          'month_name': 'July',
        },
        'hijri': {'day': 11, 'month_name': 'Safar', 'year': 1448},
      },
    });

    expect(calendar.gregorianLabel, 'Samedi 25 Juillet');
    expect(calendar.hijriLabel, '11 Safar 1448');
  });

  test('parses the French random verse', () {
    final verse = DailyVerse.fromJson({
      'data': {
        'surah': {'number': 2, 'name_english': 'Al-Baqarah'},
        'verse': {
          'ayah': 255,
          'arabic': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
          'translations': {
            'french': 'Allah! Point de divinité à part Lui.',
            'sahih_international': 'Allah - there is no deity except Him.',
          },
        },
        'audio': [
          {'ayah_audio': 'https://example.com/ayah.mp3'},
        ],
      },
    });

    expect(verse.reference, 'Al-Baqarah: 255');
    expect(verse.surahNumber, 2);
    expect(verse.french, contains('Allah'));
    expect(verse.audioUrl, endsWith('ayah.mp3'));
  });
}
