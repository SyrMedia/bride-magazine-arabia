// lib/src/core/currency.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum CurrencyPosition { prefix, suffix }

class CurrencySettings {
  final String symbol;          // مثال: "ل.س" أو "$"
  final CurrencyPosition pos;   // قبل/بعد الرقم
  const CurrencySettings({required this.symbol, required this.pos});
}

// ✅ تم التعديل هنا: الرمز أصبح دولار ($) والموقع أصبح قبل الرقم (prefix)
final currencySettingsProvider = Provider<CurrencySettings>((ref) {
  return const CurrencySettings(
    symbol: '\$',                 // رمز الدولار
    pos: CurrencyPosition.prefix, // قبل الرقم (مثال: $250)
  );
});

/// يحوّل أي قيمة (String/num) إلى نص مع فواصل + رمز العملة.
/// - لو القيمة أصلاً تحتوي أي حرف غير الأرقام والفاصلة والنقطة، نرجّعها كما هي (غالبًا HTML من Woo).
String? formatPrice(dynamic raw, WidgetRef ref, {int fractionDigits = 0}) {
  if (raw == null) return null;

  final s = raw.toString().trim();
  // إذا السعر جاهز بصيغة HTML/نص (price_html)، لا نغيّره.
  final hasNonNumeric = RegExp(r'[^0-9\.\,\s]').hasMatch(s);
  if (hasNonNumeric) return s;

  // حوّل لرقم
  final num? val = num.tryParse(s.replaceAll(',', ''));
  if (val == null) return s;

  // ✅ تم التعديل هنا: استخدام 'en_US' لتظهر الأرقام بالصيغة الإنجليزية المناسبة للدولار
  final nf = NumberFormat.decimalPattern('en_US');
  nf.minimumFractionDigits = fractionDigits;
  nf.maximumFractionDigits = fractionDigits;
  final amount = nf.format(val);

  final cs = ref.read(currencySettingsProvider);
  return cs.pos == CurrencyPosition.prefix
      ? '${cs.symbol}$amount'   // إذا كان prefix يطبع $150 (بدون مسافة)
      : '$amount ${cs.symbol}'; // إذا كان suffix يطبع 150 $
}