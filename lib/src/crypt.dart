import 'dart:async';

import 'package:flutter/services.dart';

//import 'package:cryptography/cryptography.dart';
//import 'dart:typed_data';



import 'package:encrypt/encrypt.dart';


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