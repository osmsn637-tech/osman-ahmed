class LoginRequestDto {
  const LoginRequestDto({
    required this.phone,
    required this.password,
    this.countryCode = '966',
  });

  final String phone;
  final String password;
  final String countryCode;

  Map<String, dynamic> toJson() => {
        'country_code': countryCode,
        'phone': phone,
        'password': password,
      };
}
