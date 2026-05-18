import 'dart:convert';

import 'package:cryptography/cryptography.dart';

abstract class PinHasher {
  Future<String> hash(String pin);
}

class Sha256PinHasher implements PinHasher {
  const Sha256PinHasher();

  @override
  Future<String> hash(String pin) async {
    final digest = await Sha256().hash(utf8.encode(pin));
    return base64UrlEncode(digest.bytes);
  }
}
