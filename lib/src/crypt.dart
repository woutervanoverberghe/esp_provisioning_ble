import 'dart:async';

import 'package:flutter/services.dart';

//import 'package:cryptography/cryptography.dart';
//import 'dart:typed_data';



import 'package:encrypt/encrypt.dart';

import 'dart:typed_data';
import 'package:pointycastle/api.dart' show KeyParameter, ParametersWithIV, StreamCipher;
import 'package:pointycastle/pointycastle.dart'; // for the registry that resolves 'AES/CTR'


class Crypt {
  static const MethodChannel _channel = MethodChannel('esp_provisioning_ble');

  Future<bool> init(Uint8List key, Uint8List iv) async {
    return await _channel.invokeMethod('init', {
      'key': key,
      'iv': iv,
    });
  }

  Future<Uint8List> crypt(Uint8List data) async {
    return await _channel.invokeMethod(
      'crypt',
      {
        'data': data,
      },
    );
  }
}

class Crypto {
  Encrypter? _encrypter;
  late IV ivSpec;
  bool init(Uint8List key, Uint8List iv) {
    
    ivSpec = IV(iv);
    final secretKey = Key(key);
    try {
    
      _encrypter = Encrypter(AES(secretKey, mode: AESMode.ctr, padding: null));

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Uint8List? crypt(Uint8List data) {
    return _encrypter!.encryptBytes(data, iv: ivSpec ).bytes;
  }

  Uint8List? decrypt(Uint8List data) {
    try {
      
      final encryptedData = Encrypted(data);
      List<int >listdata = _encrypter!.decryptBytes(encryptedData);
      return Uint8List.fromList(listdata);
    } catch (e) {
      print(e);
    }

    return null;
  }


}


class AESCTRStream {
  late final Uint8List _key;
  late final Uint8List _iv;
  late final bool _forEncryption;
  late StreamCipher _cipher;
  bool _initialized = false;

  /// Initialize once, just like Java's Cipher.init(...)
  void init( Uint8List key,    Uint8List iv,) {
    bool forEncryption = true;

    if (!(key.length == 16 || key.length == 24 || key.length == 32)) {
      throw ArgumentError('AES key must be 16/24/32 bytes, got ${key.length}.');
    }
    if (iv.length != 16) {
      throw ArgumentError('AES-CTR IV must be 16 bytes, got ${iv.length}.');
    }

    _key = Uint8List.fromList(key);
    _iv = Uint8List.fromList(iv);
    _forEncryption = forEncryption;

    _cipher = StreamCipher('AES/CTR/NoPadding')
      ..init(
        _forEncryption,
        ParametersWithIV<KeyParameter>(KeyParameter(_key), _iv),
      );

    _initialized = true;
  }

  /// Process a chunk without finalizing — equivalent to Java's cipher.update(data)
  Uint8List crypt(Uint8List data) {
    if (!_initialized) {
      throw StateError('Cipher not initialized. Call init() first.');
    }
    final out = Uint8List(data.length);
    _cipher.processBytes(data, 0, data.length, out, 0);
    return out;
  }

  /// Reset back to the IV/counter start (same as new Cipher with same key/IV).
  /// Call this if you need to restart the stream from the beginning.
  void resetToStart() {
    _cipher
      ..reset()
      ..init(
        _forEncryption,
        ParametersWithIV<KeyParameter>(KeyParameter(_key), _iv),
      );
  }
}



// class Crypto2 {
//   SecretKey? _secretKey;
//   Ctr? _ctr;

//   Future<bool> init(Map<String, dynamic> call) async {
//     try {
//       final key = call['key'] as Uint8List?;
//       final iv = call['iv'] as Uint8List?;

//       if (key == null || iv == null) {
//         throw ArgumentError('Key or IV is null');
//       }

//       _secretKey = SecretKey(key);
//       final algorithm = AesCtr.with256bits(
//         nonce: iv,
//       );
//       _ctr = Ctr(algorithm);
//       return true;
//     } catch (e) {
//       print(e);
//       return false;
//     }
//   }

//   Future<Uint8List?> crypt(Map<String, dynamic> call) async {
//     if (_secretKey == null || _ctr == null) {
//       throw StateError('Cipher not initialized. Call init() first.');
//     }

//     final data = call['data'] as Uint8List?;
//     if (data == null) {
//       throw ArgumentError('Data is null');
//     }

//     final secretBox = await _ctr!.encrypt(
//       data,
//       secretKey: _secretKey!,
//     );
//     return secretBox.cipherText;
//   }
// }