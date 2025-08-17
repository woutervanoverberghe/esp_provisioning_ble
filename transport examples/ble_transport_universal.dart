// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:esp_provisioning_ble/esp_provisioning_ble.dart';

import 'package:universal_ble/universal_ble.dart';

class ble_device {
  BleDevice device;
  ble_device(this.device){

  }
}

class TransportBLE implements ProvTransport {
  final ble_device  peripheral;
  final String serviceUUID;
  late final Map<String, String> nuLookup; //charcsitc uuid map
  final Map<String, String> lockupTable;
  
  Map<String, BleCharacteristic > characteristicsmap = {}; //list of charcsitc with name

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

  late BleDevice device;
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
      await device.connect();
      print("Connect Successfully!!!");
    } catch (e) {
      print("Error: trying to Connect $e");
    }
    try {
      if(Platform.isLinux){

        List<BleService> services = await device.discoverServices();
        await _readDescriptors(services);
      }
    } catch (e) {
      print("Error: trying to DiscoverAllServicesAndCharacteristics: $e");
    }
    return await device.isConnected;
  }

  Future _readDescriptors(List<BleService> services) async{

    //check if correct service
    BleService? servicetemp = null;
    for (BleService serv in services){
      if (serv.uuid == this.serviceUUID){
        servicetemp = serv;
      }
    }
    if (servicetemp == null){
      return;
    }
    BleService service = servicetemp;

    //create character map
    nuLookup.forEach((key, charid) {
      for (BleCharacteristic char in service.characteristics){
        if (char.uuid == charid){

          characteristicsmap[key] = char;
        }
      } 
    });

    print(characteristicsmap);
    
  }


  @override
  Future<Uint8List> sendReceive(String? epName, Uint8List? data) async {
    BleCharacteristic? char;
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
    bool check = await device.isConnected;
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

    if (await device.isConnected == false){
      return true;
    }
    BleConnectionState state = await device.connectionState;
    int retries = 0;
    while( state !=  BleConnectionState.disconnected){
      state = await device.connectionState;
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (retries > 10){
        return false;
      }
      retries = retries +1;
    }
   
    return true;
  }

  void dispose() {
    print('dispose ble');
  }
}
