import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to fetch Indian holidays using Google Calendar API
/// This automatically provides accurate Indian holidays without manual updates
class IndianHolidayService {
  // Google Calendar API endpoint for Indian holidays
  // This is a public calendar maintained by Google
  static const String _calendarId = 'en.indian%23holiday@group.v.calendar.google.com';
  static const String _apiKey = 'AIzaSyBNlYH014_DC2DhvYoC1QNzoh00yOWJQbE'; // Public API key
  static const String _baseUrl = 'https://www.googleapis.com/calendar/v3/calendars';
  
  // Cache for holidays to avoid repeated API calls
  static final Map<int, Map<DateTime, String>> _holidayCache = {};
  
  /// Fetch Indian holidays for a specific year from Google Calendar
  static Future<Map<DateTime, String>> getHolidaysForYear(int year) async {
    // Return from cache if available
    if (_holidayCache.containsKey(year)) {
      return _holidayCache[year]!;
    }
    
    try {
      // Calculate time range for the year
      final timeMin = DateTime(year, 1, 1).toUtc().toIso8601String();
      final timeMax = DateTime(year, 12, 31, 23, 59, 59).toUtc().toIso8601String();
      
      // Build API URL
      final url = Uri.parse(
        '$_baseUrl/$_calendarId/events?key=$_apiKey&timeMin=$timeMin&timeMax=$timeMax&singleEvents=true&orderBy=startTime'
      );
      
      // Make API request
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final holidays = <DateTime, String>{};
        
        // Parse events
        if (data['items'] != null) {
          for (var event in data['items']) {
            if (event['start'] != null && event['start']['date'] != null) {
              final dateStr = event['start']['date'];
              final date = DateTime.parse(dateStr);
              final name = event['summary'] ?? 'Holiday';
              
              // Store only the date part (no time)
              final dateOnly = DateTime(date.year, date.month, date.day);
              holidays[dateOnly] = name;
            }
          }
        }
        
        // Cache the results
        _holidayCache[year] = holidays;
        return holidays;
      } else {
        print('Failed to load holidays: ${response.statusCode}');
        // Return fallback holidays if API fails
        return _getFallbackHolidays(year);
      }
    } catch (e) {
      print('Error fetching holidays from Google Calendar: $e');
      // Return fallback holidays if API fails
      return _getFallbackHolidays(year);
    }
  }
  
  /// Fallback holidays in case API is unavailable
  static Map<DateTime, String> _getFallbackHolidays(int year) {
    final holidays = <DateTime, String>{};
    
    // Fixed holidays (same date every year)
    holidays[DateTime(year, 1, 1)] = 'New Year\'s Day';
    holidays[DateTime(year, 1, 14)] = 'Makar Sankranti';
    holidays[DateTime(year, 1, 26)] = 'Republic Day';
    holidays[DateTime(year, 4, 14)] = 'Ambedkar Jayanti';
    holidays[DateTime(year, 5, 1)] = 'May Day';
    holidays[DateTime(year, 8, 15)] = 'Independence Day';
    holidays[DateTime(year, 10, 2)] = 'Gandhi Jayanti';
    holidays[DateTime(year, 12, 25)] = 'Christmas';
    
    return holidays;
  }
  
  /// Get holiday name for a specific date
  static Future<String?> getHolidayForDate(DateTime date) async {
    final holidays = await getHolidaysForYear(date.year);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return holidays[dateOnly];
  }
  
  /// Check if a date is a holiday
  static Future<bool> isHoliday(DateTime date) async {
    final holiday = await getHolidayForDate(date);
    return holiday != null;
  }
  
  /// Get all holidays in a date range
  static Future<Map<DateTime, String>> getHolidaysInRange(DateTime start, DateTime end) async {
    final holidays = <DateTime, String>{};
    
    // Get unique years in the range
    final years = <int>{};
    for (var date = start; date.isBefore(end) || date.isAtSameMomentAs(end); date = date.add(const Duration(days: 1))) {
      years.add(date.year);
    }
    
    // Get holidays for each year
    for (var year in years) {
      final yearHolidays = await getHolidaysForYear(year);
      yearHolidays.forEach((date, name) {
        if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
            (date.isBefore(end) || date.isAtSameMomentAs(end))) {
          holidays[date] = name;
        }
      });
    }
    
    return holidays;
  }
  
  /// Clear cache (useful for refreshing data)
  static void clearCache() {
    _holidayCache.clear();
  }
  
  /// Refresh holidays for a specific year (clears cache and fetches again)
  static Future<Map<DateTime, String>> refreshHolidaysForYear(int year) async {
    _holidayCache.remove(year);
    return await getHolidaysForYear(year);
  }
}
