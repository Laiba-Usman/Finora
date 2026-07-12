import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  // Fetch exchange rates for a base currency
  Future<Map<String, double>> fetchExchangeRates(String baseCurrency) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$baseCurrency'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> rates = data['rates'] as Map<String, dynamic>;
        
        return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } else {
        throw Exception('Failed to load currency exchange rates');
      }
    } catch (e) {
      // Return hardcoded default fallback rates in case of offline/network failure
      return {
        'USD': 1.0,
        'EUR': 0.92,
        'GBP': 0.78,
        'JPY': 155.0,
        'INR': 83.5,
        'CAD': 1.36,
        'AUD': 1.50,
      };
    }
  }

  // Convert amount between currencies
  double convert(double amount, double fromRate, double toRate) {
    if (fromRate == 0) return 0;
    // Base is USD, so converting from currency X to USD, then USD to currency Y
    double amountInBase = amount / fromRate;
    return amountInBase * toRate;
  }
}
