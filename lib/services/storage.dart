import 'package:flutter_secure_storage/flutter_secure_storage.dart';

AndroidOptions _getAndroidOptions() => const AndroidOptions(
  encryptedSharedPreferences: true,
);

IOSOptions _getIOSOptions() => const IOSOptions(
  accountName: 'flutter_secure_storage_service',
);

final _storage = FlutterSecureStorage(aOptions: _getAndroidOptions(), iOptions: _getIOSOptions());

class SecureStorage{

  Future writeSecureData(String key, String value)  async {
    var writeData = await _storage.write(key: key, value: value);
    return writeData;
  }

  Future readSecureData(String key) async {
    var readData = await _storage.read(key: key);
    return readData;
  }
  
  Future readAllSecureData() async {
    Map<String, String> readAll = await _storage.readAll(iOptions: _getIOSOptions(), aOptions: _getAndroidOptions());
    return readAll;
  }
  
  Future deleteSecureData(String key) async{
    var deleteData = await _storage.delete(key: key);
    return deleteData;
  }

  Future deleteAllSecureData() async{
    var deleteData = await _storage.deleteAll(
      iOptions: _getIOSOptions(),
      aOptions: _getAndroidOptions(),
    );
    return deleteData;
  }

  Future<bool> sessionAlive () async {
    final storage = await readAllSecureData();
    String? host = storage['HOST'];
    String? email = storage['EMAIL'];
    String? name = storage['NAME'];
    String? storeId = storage['STOREID'];
    String? basic = storage['BASIC'];
    String? appType = storage['APPTYPE'];
    String? appId = storage['APPID'];
    return host != null && email != null && name != null
            && basic != null && storeId != null && appType != null
            && appId != null;
  }
}