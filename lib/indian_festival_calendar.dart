import 'package:flutter/material.dart';

/// Helper class to calculate Indian festivals for any year
/// Festivals are calculated based on fixed dates and lunar calendar approximations
class IndianFestivalCalendar {
  
  /// Get all Indian festivals for a given year
  static Map<DateTime, String> getFestivalsForYear(int year) {
    final festivals = <DateTime, String>{};
    
    // Fixed date festivals (same date every year)
    _addFixedFestivals(festivals, year);
    
    // Variable date festivals (approximate lunar calendar dates)
    // Note: For production, use a proper lunar calendar library
    _addVariableFestivals(festivals, year);
    
    return festivals;
  }
  
  /// Add festivals that occur on fixed dates every year
  static void _addFixedFestivals(Map<DateTime, String> festivals, int year) {
    // January
    festivals[DateTime(year, 1, 1)] = 'New Year';
    festivals[DateTime(year, 1, 13)] = 'Lohri';
    festivals[DateTime(year, 1, 14)] = 'Makar Sankranti';
    festivals[DateTime(year, 1, 26)] = 'Republic Day';
    
    // April
    festivals[DateTime(year, 4, 14)] = 'Ambedkar Jayanti';
    festivals[DateTime(year, 4, 14)] = 'Baisakhi';
    
    // May
    festivals[DateTime(year, 5, 1)] = 'May Day';
    
    // August
    festivals[DateTime(year, 8, 15)] = 'Independence Day';
    
    // October
    festivals[DateTime(year, 10, 2)] = 'Gandhi Jayanti';
    
    // December
    festivals[DateTime(year, 12, 25)] = 'Christmas';
  }
  
  /// Add festivals based on lunar calendar (approximate dates)
  /// These are approximations - for exact dates, integrate a lunar calendar library
  static void _addVariableFestivals(Map<DateTime, String> festivals, int year) {
    // This is a simplified approximation
    // For production, use packages like 'hijri' or lunar calendar calculations
    
    switch (year) {
      case 2024:
        festivals[DateTime(2024, 2, 14)] = 'Vasant Panchami';
        festivals[DateTime(2024, 3, 8)] = 'Maha Shivaratri';
        festivals[DateTime(2024, 3, 25)] = 'Holi';
        festivals[DateTime(2024, 4, 9)] = 'Ugadi';
        festivals[DateTime(2024, 4, 17)] = 'Ram Navami';
        festivals[DateTime(2024, 4, 21)] = 'Mahavir Jayanti';
        festivals[DateTime(2024, 5, 23)] = 'Buddha Purnima';
        festivals[DateTime(2024, 6, 17)] = 'Eid al-Adha';
        festivals[DateTime(2024, 7, 17)] = 'Muharram';
        festivals[DateTime(2024, 8, 19)] = 'Raksha Bandhan';
        festivals[DateTime(2024, 8, 26)] = 'Janmashtami';
        festivals[DateTime(2024, 9, 7)] = 'Ganesh Chaturthi';
        festivals[DateTime(2024, 9, 16)] = 'Eid-e-Milad';
        festivals[DateTime(2024, 10, 12)] = 'Dussehra';
        festivals[DateTime(2024, 11, 1)] = 'Diwali';
        festivals[DateTime(2024, 11, 15)] = 'Guru Nanak Jayanti';
        break;
        
      case 2025:
        festivals[DateTime(2025, 2, 2)] = 'Vasant Panchami';
        festivals[DateTime(2025, 2, 26)] = 'Maha Shivaratri';
        festivals[DateTime(2025, 3, 14)] = 'Holi';
        festivals[DateTime(2025, 3, 30)] = 'Ugadi';
        festivals[DateTime(2025, 4, 6)] = 'Ram Navami';
        festivals[DateTime(2025, 4, 10)] = 'Mahavir Jayanti';
        festivals[DateTime(2025, 4, 18)] = 'Good Friday';
        festivals[DateTime(2025, 5, 12)] = 'Buddha Purnima';
        festivals[DateTime(2025, 6, 7)] = 'Eid al-Adha';
        festivals[DateTime(2025, 7, 6)] = 'Muharram';
        festivals[DateTime(2025, 8, 9)] = 'Raksha Bandhan';
        festivals[DateTime(2025, 8, 16)] = 'Janmashtami';
        festivals[DateTime(2025, 8, 27)] = 'Ganesh Chaturthi';
        festivals[DateTime(2025, 9, 5)] = 'Eid-e-Milad';
        festivals[DateTime(2025, 10, 2)] = 'Dussehra';
        festivals[DateTime(2025, 10, 21)] = 'Diwali';
        festivals[DateTime(2025, 11, 5)] = 'Guru Nanak Jayanti';
        break;
        
      case 2026:
        festivals[DateTime(2026, 1, 22)] = 'Vasant Panchami';
        festivals[DateTime(2026, 2, 16)] = 'Maha Shivaratri';
        festivals[DateTime(2026, 3, 3)] = 'Holi';
        festivals[DateTime(2026, 3, 19)] = 'Ugadi';
        festivals[DateTime(2026, 3, 27)] = 'Ram Navami';
        festivals[DateTime(2026, 3, 31)] = 'Mahavir Jayanti';
        festivals[DateTime(2026, 4, 3)] = 'Good Friday';
        festivals[DateTime(2026, 5, 1)] = 'Buddha Purnima';
        festivals[DateTime(2026, 5, 27)] = 'Eid al-Adha';
        festivals[DateTime(2026, 6, 25)] = 'Muharram';
        festivals[DateTime(2026, 7, 29)] = 'Raksha Bandhan';
        festivals[DateTime(2026, 8, 5)] = 'Janmashtami';
        festivals[DateTime(2026, 8, 16)] = 'Ganesh Chaturthi';
        festivals[DateTime(2026, 8, 25)] = 'Eid-e-Milad';
        festivals[DateTime(2026, 9, 21)] = 'Dussehra';
        festivals[DateTime(2026, 10, 9)] = 'Diwali';
        festivals[DateTime(2026, 11, 24)] = 'Guru Nanak Jayanti';
        break;
        
      case 2027:
        festivals[DateTime(2027, 2, 11)] = 'Vasant Panchami';
        festivals[DateTime(2027, 3, 6)] = 'Maha Shivaratri';
        festivals[DateTime(2027, 3, 22)] = 'Holi';
        festivals[DateTime(2027, 4, 8)] = 'Ugadi';
        festivals[DateTime(2027, 4, 15)] = 'Ram Navami';
        festivals[DateTime(2027, 4, 19)] = 'Mahavir Jayanti';
        festivals[DateTime(2027, 4, 26)] = 'Good Friday';
        festivals[DateTime(2027, 5, 20)] = 'Buddha Purnima';
        festivals[DateTime(2027, 5, 17)] = 'Eid al-Adha';
        festivals[DateTime(2027, 6, 15)] = 'Muharram';
        festivals[DateTime(2027, 8, 18)] = 'Raksha Bandhan';
        festivals[DateTime(2027, 8, 25)] = 'Janmashtami';
        festivals[DateTime(2027, 9, 5)] = 'Ganesh Chaturthi';
        festivals[DateTime(2027, 9, 14)] = 'Eid-e-Milad';
        festivals[DateTime(2027, 10, 10)] = 'Dussehra';
        festivals[DateTime(2027, 10, 29)] = 'Diwali';
        festivals[DateTime(2027, 11, 14)] = 'Guru Nanak Jayanti';
        break;
        
      default:
        // For years not explicitly defined, use 2025 as template
        // and add a note that dates are approximate
        festivals[DateTime(year, 2, 2)] = 'Vasant Panchami (approx)';
        festivals[DateTime(year, 2, 26)] = 'Maha Shivaratri (approx)';
        festivals[DateTime(year, 3, 14)] = 'Holi (approx)';
        festivals[DateTime(year, 3, 30)] = 'Ugadi (approx)';
        festivals[DateTime(year, 4, 6)] = 'Ram Navami (approx)';
        festivals[DateTime(year, 4, 10)] = 'Mahavir Jayanti (approx)';
        festivals[DateTime(year, 5, 12)] = 'Buddha Purnima (approx)';
        festivals[DateTime(year, 8, 9)] = 'Raksha Bandhan (approx)';
        festivals[DateTime(year, 8, 16)] = 'Janmashtami (approx)';
        festivals[DateTime(year, 8, 27)] = 'Ganesh Chaturthi (approx)';
        festivals[DateTime(year, 10, 2)] = 'Dussehra (approx)';
        festivals[DateTime(year, 10, 21)] = 'Diwali (approx)';
        festivals[DateTime(year, 11, 5)] = 'Guru Nanak Jayanti (approx)';
    }
  }
  
  /// Get festival name for a specific date (if any)
  static String? getFestivalForDate(DateTime date) {
    final festivals = getFestivalsForYear(date.year);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return festivals[dateOnly];
  }
  
  /// Check if a date is a festival
  static bool isFestival(DateTime date) {
    return getFestivalForDate(date) != null;
  }
  
  /// Get all festivals in a date range
  static Map<DateTime, String> getFestivalsInRange(DateTime start, DateTime end) {
    final festivals = <DateTime, String>{};
    
    // Get unique years in the range
    final years = <int>{};
    for (var date = start; date.isBefore(end) || date.isAtSameMomentAs(end); date = date.add(const Duration(days: 1))) {
      years.add(date.year);
    }
    
    // Get festivals for each year
    for (var year in years) {
      final yearFestivals = getFestivalsForYear(year);
      yearFestivals.forEach((date, name) {
        if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
            (date.isBefore(end) || date.isAtSameMomentAs(end))) {
          festivals[date] = name;
        }
      });
    }
    
    return festivals;
  }
}
