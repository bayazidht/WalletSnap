const List<CurrencyModel> defaultCurrencies = [
  CurrencyModel(
    code: 'USD',
    symbol: '\$',
  ),
  CurrencyModel(
    code: 'KRW',
    symbol: '₩',
  ),
  CurrencyModel(
    code: 'EUR',
    symbol: '€',
  ),
  CurrencyModel(
    code: 'GBP',
    symbol: '£',
  ),
  CurrencyModel(
    code: 'BDT',
    symbol: '৳',
  ),
  CurrencyModel(
    code: 'INR',
    symbol: '₹',
  ),
  CurrencyModel(
    code: 'JPY',
    symbol: '¥',
  ),
];

class CurrencyModel {
  final String code;
  final String symbol;

  const CurrencyModel({
    required this.code,
    required this.symbol,
  });
}
