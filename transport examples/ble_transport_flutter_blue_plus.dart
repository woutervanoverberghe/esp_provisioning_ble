// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:esp_provisioning_ble/esp_provisioning_ble.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

//for flutter blueplus
class ble_device {
  BluetoothDevice device;
  ble_device(this.device){

  }
}


class TransportBLE implements ProvTransport {
  final ble_device  peripheral;
  final String serviceUUID;
  late final Map<String, String> nuLookup; //charcsitc uuid map
  final Map<String, String> lockupTable;
  Map<String, BluetoothCharacteristic > characteristicsmap = {}; //list of charcsitc with name
  List<BluetoothService> services = [];
  static const PROV_BLE_SERVICE = '1775244d-6b43-439b-877c-060f2d9bed07';//'021a9004-0382-4aea-bff4-6b3f1c5adfb4';
  static const PROV_BLE_EP = {
    'prov-ctrl': 'ff4f',
    'prov-scan': 'ff50',
    'prov-session': 'ff51',
    'prov-config': 'ff52',
    'proto-ver': 'ff53',
    'callback': 'ff54',
    'websocket': 'ff55',
    'plantid': 'ff56',
  };

  late BluetoothDevice device;
  TransportBLE(this.peripheral,
      {this.serviceUUID = PROV_BLE_SERVICE, this.lockupTable = PROV_BLE_EP}) {

    device = peripheral.device;

    //create characteristic map
    nuLookup = {
      for (var name in lockupTable.keys)
        name: serviceUUID.substring(0, 4) +
            int.parse(lockupTable[name]!, radix: 16)
                .toRadixString(16)
                .padLeft(4, '0') +
            serviceUUID.substring(8)
    };
  }

  @override
  Future<bool> connect() async {
    disconnect();
    try {
      await device.connect(mtu : 256);
      print("Connect Successfully!!!");
    } catch (e) {
      print("Error: trying to Connect $e");
    }
    try {
      if (Platform.isAndroid || Platform.isIOS){
        
        services = await device.discoverServices();
        await _readDescriptors();
      } else if(Platform.isLinux){

        services = await device.discoverServices();
        _createDescriptorsLinux();
      }
        //transactionId: 'discoverAllServicesAndCharacteristics');
    } catch (e) {
      print("Error: trying to DiscoverAllServicesAndCharacteristics: $e");
    }
    return await device.isConnected;
  }

  Future _readDescriptors() async{
    
    for (var service in services){
      if(service.serviceUuid.str == serviceUUID){

        for(BluetoothCharacteristic c in service.characteristics) {
          if (c.descriptors.isNotEmpty){
            var value = await c.descriptors.first.read();
            characteristicsmap[utf8.decode(Uint8List.fromList( value ) )] = c;
          }
        }
      }
    }

    print(characteristicsmap);
    
  }
  Future _createDescriptorsLinux() async{
    
    for (var servicesnames in nuLookup.keys){
        BluetoothCharacteristic c = BluetoothCharacteristic(
              remoteId: device.remoteId, 
              serviceUuid: Guid(serviceUUID), 
              characteristicUuid: Guid(nuLookup[servicesnames]!), 
            );

        characteristicsmap[servicesnames] = c;
        
    }

    print(characteristicsmap);
  }


  @override
  Future<Uint8List> sendReceive(String? epName, Uint8List? data) async {
    BluetoothCharacteristic? char;
    if (data != null) {
      if (data.isNotEmpty) {

        
          char = characteristicsmap[epName ?? ""];
          
    
          if (char!= null){
            
            await char.write(data);

            return Uint8List.fromList(await  char.read() );
          }
        }
      }
    

    
    return Uint8List.fromList([]);

  }

  @override
  Future<bool> disconnect() async {
    bool check = device.isConnected;
    if (check) {
      try {
        await device.disconnect();
        return true;
      } on Exception catch (e) {
        print("Error trying to disconnect device: $e");
        return false;
      }
    } else {
      return true;
    }
  }

  @override
  Future<bool> checkConnect() async {
    return device.isConnected;
  }

  Future<bool> waitDisconnected() async{

    Completer<bool> completerdisconnect = Completer<bool>();
    if (device.isConnected == false){
      return true;
    }
    
    StreamSubscription streamlistner = device.connectionState.listen((state) {

      if (state == BluetoothConnectionState.disconnected) {
        print('Device disconnected');
        // Handle disconnectionµ
        completerdisconnect.complete(true);
      }
    });

    
    bool res = await completerdisconnect.future;
    streamlistner.cancel();
    return res;
  }

  void dispose() {
    print('dispose ble');
  }
}
