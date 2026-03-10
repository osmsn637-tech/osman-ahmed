class LoginParams {
  const LoginParams({
    required this.phone,
    required this.password,
    this.countryCode = '966',
  });

  final String phone;
  final String password;
  final String countryCode;
}
