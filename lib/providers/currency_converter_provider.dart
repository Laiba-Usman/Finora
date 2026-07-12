import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_keys.dart';

class CurrencyConverterProvider with ChangeNotifier {
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double? _amount;
  double? _convertedAmount;
  double? _exchangeRate;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCachedData = false;

  // Getters
  String get fromCurrency => _fromCurrency;
  String get toCurrency => _toCurrency;
  double? get amount => _amount;
  double? get convertedAmount => _convertedAmount;
  double? get exchangeRate => _exchangeRate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCachedData => _isCachedData;

  final List<String> currencies = [
    'USD', 'EUR', 'GBP', 'PKR', 'INR', 'JPY', 'AED', 'SAR', 'CNY', 'AUD', 'CAD'
  ];

  void setFromCurrency(String value) {
    if (_fromCurrency != value) {
      _fromCurrency = value;
      notifyListeners();
    }
  }

  void setToCurrency(String value) {
    if (_toCurrency != value) {
      _toCurrency = value;
      notifyListeners();
    }
  }

  void swapCurrencies() {
    final temp = _fromCurrency;
    _fromCurrency = _toCurrency;
    _toCurrency = temp;
    
    if (_amount != null && _amount! > 0) {
      convertCurrency(inputAmount: _amount!, from: _fromCurrency, to: _toCurrency);
    } else {
      notifyListeners();
    }
  }

  Future<void> convertCurrency({
    required double inputAmount,
    required String from,
    required String to,
  }) async {
    _amount = inputAmount;
    _fromCurrency = from;
    _toCurrency = to;
    _isLoading = true;
    _errorMessage = null;
    _convertedAmount = null;
    _exchangeRate = null;
    _isCachedData = false;
    notifyListeners();

    final url = Uri.parse('https://v6.exchangerate-api.com/v6/${ApiKeys.exchangeRateApiKey}/latest/$from');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = data['conversion_rates'] as Map<String, dynamic>;
          final rate = (rates[to] as num?)?.toDouble();
          
          if (rate != null) {
            _exchangeRate = rate;
            _convertedAmount = inputAmount * rate;
            
            // Cache the successful rates locally
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_rates_$from', json.encode(rates));
            await prefs.setInt('cached_time_$from', DateTime.now().millisecondsSinceEpoch);
          } else {
            _errorMessage = 'Currency $to is not supported.';
          }
        } else {
          final errorType = data['error-type'] ?? 'Unknown API error';
          await _loadFromCache(inputAmount, from, to, 'API Error: $errorType');
        }
      } else {
        await _loadFromCache(inputAmount, from, to, 'Server error (status: ${response.statusCode})');
      }
    } catch (e) {
      await _loadFromCache(inputAmount, from, to, 'Failed to fetch rates. Please check your internet connection.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache(double inputAmount, String from, String to, String initialError) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRatesStr = prefs.getString('cached_rates_$from');
      
      if (cachedRatesStr != null) {
        final rates = json.decode(cachedRatesStr) as Map<String, dynamic>;
        final rate = (rates[to] as num?)?.toDouble();
        
        if (rate != null) {
          _exchangeRate = rate;
          _convertedAmount = inputAmount * rate;
          _isCachedData = true;
          _errorMessage = null;
          return;
        }
      }
    } catch (cacheError) {
      debugPrint('Failed to load from cache: $cacheError');
    }
    
    _errorMessage = initialError;
  }
}
