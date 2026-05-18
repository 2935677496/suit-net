import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';


const int _pbkdf2Iterations = 15536;
const int _derivedKeyLength = 32;
const String _pbkdf2Salt = 'yujhygtfredswcvf';

class CryptoUtils {
  const CryptoUtils._();

  static Uint8List deriveKey(String password) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(
        Pbkdf2Parameters(
          Uint8List.fromList(utf8.encode(_pbkdf2Salt)),
          _pbkdf2Iterations,
          _derivedKeyLength,
        ),
      );

    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List randomBytes(int length, {Random? random}) {
    final rng = random ?? Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  static Uint8List processAesCbc({
    required bool forEncryption,
    required Uint8List key,
    required Uint8List iv,
    required Uint8List input,
  }) {
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    cipher.init(
      forEncryption,
      PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
        ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
        null,
      ),
    );

    return cipher.process(input);
  }

  static Uint8List processLoginAesEcb({
    required bool forEncryption,
    required Uint8List key,
    required Uint8List input,
  }) {
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      ECBBlockCipher(AESEngine()),
    );

    cipher.init(
      forEncryption,
      PaddedBlockCipherParameters<KeyParameter, Null>(
        KeyParameter(key),
        null,
      ),
    );

    return cipher.process(input);
  }
}

String loginEncrypt(String plainText, String base64Key) {
  if (base64Key.trim().isEmpty) {
    throw Exception('登录加密失败: 密钥不能为空，已阻止明文密码传输');
  }

  try {
    final key = base64Decode(base64Key);
    final encryptedBytes = CryptoUtils.processLoginAesEcb(
      forEncryption: true,
      key: Uint8List.fromList(key),
      input: Uint8List.fromList(utf8.encode(plainText)),
    );

    return base64Encode(encryptedBytes);
  } catch (e) {
    throw Exception('登录加密失败: $e');
  }
}

String loginDecrypt(String encryptedText, String base64Key) {
  if (base64Key.trim().isEmpty) {
    throw Exception('登录解密失败: 密钥不能为空');
  }

  try {
    final key = base64Decode(base64Key);
    final cipherBytes = base64Decode(encryptedText);
    final plainBytes = CryptoUtils.processLoginAesEcb(
      forEncryption: false,
      key: Uint8List.fromList(key),
      input: Uint8List.fromList(cipherBytes),
    );

    return utf8.decode(plainBytes);
  } catch (e) {
    throw Exception('登录解密失败: $e');
  }
}
