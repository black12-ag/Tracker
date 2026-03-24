class AppIdentity {
  AppIdentity._();

  static const String appName = 'Tracker';

  static const String ownerCanonicalEmail = 'muay01111@gmail.com';
  static const String ownerPhoneLocal = '0922380260';
  static const String ownerPhoneIntl = '251922380260';

  static const String contactTelegramHandle = '@muay011';
  static const String contactTelegramUrl = 'https://t.me/muay011';
  static const String contactPhone = '0907806267';

  static const String splashSeenKey = 'has_seen_video_splash';

  static String normalizeLoginIdentifier(String value) {
    final trimmed = value.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits == ownerPhoneLocal || digits == ownerPhoneIntl) {
      return ownerCanonicalEmail;
    }
    return trimmed.toLowerCase();
  }
}
