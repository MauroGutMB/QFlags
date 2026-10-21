import '../l10n/strings.dart';

class Country {
  const Country({required this.code, required this.en, required this.pt});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        code: json['code'] as String,
        en: json['en'] as String,
        pt: json['pt'] as String,
      );

  final String code;
  final String en;
  final String pt;

  String name(AppLang lang) => lang == AppLang.pt ? pt : en;

  String get flagAsset => 'assets/flags/$code.png';

  @override
  bool operator ==(Object other) => other is Country && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
