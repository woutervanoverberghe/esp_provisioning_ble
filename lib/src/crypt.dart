import 'dart:async';


import 'dart:typed_data';
import 'package:pointycastle/api.dart' show KeyParameter, ParametersWithIV, StreamCipher;
import 'package:pointycastle/pointycastle.dart'; // for the registry that resolves 'AES/CTR'



class AESCTRStream {
  late final Uint8List _key;
  late final Uint8List _iv;
  late final bool _forEncryption;
  late StreamCipher _cipher;
  bool _initialized = false;

  /// Initialize once, just like Java's Cipher.init(...)
  void init( Uint8List key,    Uint8List iv,) {
    bool forEncryption = true;


    _key = key;
    _iv = iv;
    _forEncryption = forEncryption;
    try {
      

      _cipher = StreamCipher('AES/CTR')
      ..init(
        _forEncryption,
        ParametersWithIV<KeyParameter>(KeyParameter(_key), _iv),
      );
      _initialized = true;
    } catch (e) {
      print(e);
    }
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

