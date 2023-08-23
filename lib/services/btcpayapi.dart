
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'storage.dart';

class BTCPayAPI{

  final _secureStorage = SecureStorage();
  final version = 'v1';

  Future<Map<String, String>> buildHeader () async {
    Map<String, String> storage = await _secureStorage.readAllSecureData();
    String? token = storage['TOKEN'];
    String? base64 = storage['BASIC'];
    return {
            'Token' : token.toString(),
            HttpHeaders.authorizationHeader: 'Basic $base64',
          };
  }

  Future<Uri> buildUrl(path) async {
    String? host = await _secureStorage.readSecureData('HOST');
    return Uri.parse('${host.toString()}/api/$version/$path');
  }

  Future sendGetRequest(path) async {
    Uri uri = await buildUrl(path);
    final response = await http.get(
      uri,
      headers: await buildHeader(),
    );
    final res = json.decode(response.body);
    final int status = response.statusCode;
    if (status == 200){
      return res;
    } else {
      throw Exception('Error Status $status $uri');
    }
  }

  getUser(host, token, base64) async {
    final response = await http.get(
      Uri.parse('$host/api/v1/users/me'),
      headers: {
        'Token' : token,
        HttpHeaders.authorizationHeader: 'Basic $base64',
      },
    );
    final res = json.decode(response.body);
    if (response.statusCode == 200){
      await _secureStorage.writeSecureData('EMAIL', res['email']);
      return res['email'];
    } else {
      return res['message'];
    }
  }

  Future getStores()  async {
    return sendGetRequest('stores');
  }

  Future getStoreById(storeId)  async {
    return sendGetRequest('stores/$storeId');
  }

  Future getPosById(appId)  async {
    return sendGetRequest('apps/pos/$appId');
  }

  Future getCrowdfundById(appId)  async {
    return sendGetRequest('apps/crowdfund/$appId');
  }

  Future getApps() async {
    return sendGetRequest('apps');
  }

  Future getInvoices() async {
    String storeId = await _secureStorage.readSecureData('STOREID');
    return sendGetRequest('stores/$storeId/invoices');
  }
}