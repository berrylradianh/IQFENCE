class PhoneNormalizer {
  static String normalize(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('62')) {
      return cleaned;
    } else if (cleaned.startsWith('0')) {
      return '62${cleaned.substring(1)}';
    } else {
      return '62$cleaned';
    }
  }
}
