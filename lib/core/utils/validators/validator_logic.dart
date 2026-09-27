library;

String digitsOnly(String? value) => (value ?? '').replaceAll(RegExp(r'\D'), '');

enum NameError { empty, tooShort, tooLong }

NameError? checkName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return NameError.empty;
  if (name.length < 3) return NameError.tooShort;
  if (name.length > 100) return NameError.tooLong;
  return null;
}

enum PhoneError { empty, invalid }

PhoneError? checkPhone(String? value, {int localLength = 8}) {
  final digits = digitsOnly(value);
  if (digits.isEmpty) return PhoneError.empty;
  return digits.length == localLength ? null : PhoneError.invalid;
}

final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

enum EmailError { empty, invalid }

EmailError? checkEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return EmailError.empty;
  return _email.hasMatch(email) ? null : EmailError.invalid;
}

enum PasswordError { empty, tooShort }

PasswordError? checkPassword(String? value, {int minLength = 8}) {
  final password = value ?? '';
  if (password.isEmpty) return PasswordError.empty;
  return password.length >= minLength ? null : PasswordError.tooShort;
}
