import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import '../components/footer.dart';
import '../services/btcpayapi.dart';
import '../services/storage.dart';

// ignore: must_be_immutable
class Settings extends StatefulWidget {
  Settings({
    super.key,
    required this.isLogged
  });

  late bool isLogged;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _host = '';
  String _apiKey = '';
  String _email = '';
  String _pass = '';
  final _btcPayApi = BTCPayAPI();
  final _secureStorage = SecureStorage();

  Future<void> scanQrcode() async {
    Object barcodeScanRes = {};
    barcodeScanRes = (await FlutterBarcodeScanner.scanBarcode(
      "#42f5ef", "Cancel", true, ScanMode.QR)
    );
    var result = barcodeScanRes.toString();
    if (result != '-1') {
      Map<String, dynamic> obj = json.decode(result);
      setState(() {
        _host = obj['host'];
        _apiKey = obj['apiKey'];
      });
    }
  }

  final _formKey = GlobalKey<FormState>();
  TextEditingController apikeyController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }
  
  @override
  Widget build(BuildContext context)  {
    urlController.text = _host;
    apikeyController.text = _apiKey;
    emailController.text = _email;
    passwordController.text = _pass;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // appBar: AppBar(
      //   title: Text(widget.title),
      //   centerTitle: true,
      //   automaticallyImplyLeading: false,
      // ),
      body: Center(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                  child: Image.asset(
                  'images/logo.png',
                  height: 180,
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          child: TextFormField(
                            readOnly: widget.isLogged,
                            controller: urlController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "URL BTCPayServer",
                                suffixIcon: Icon(Icons.link)),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insert URL BTCPayServer';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          child: TextFormField(
                            readOnly: widget.isLogged,
                            controller: apikeyController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "ApiKey",
                                suffixIcon: Icon(Icons.qr_code_scanner)),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insert Apikey';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          child: TextFormField(
                            readOnly: widget.isLogged,
                            controller: emailController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(), labelText: "Email"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insert your email';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          child: TextFormField(
                            readOnly: widget.isLogged,
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(), labelText: "Password"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insert your password';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3.0),
                              child: Center(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.isLogged ? Colors.red : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding:const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  onPressed: () async {
                                    if (widget.isLogged) {
                                      await _disconnect();
                                    } else {
                                      await _handleDeviceConnection(
                                        emailController.text,
                                        passwordController.text,
                                        urlController.text,
                                        apikeyController.text
                                      );
                                    }
                                  },
                                label: widget.isLogged ? const Text('Disconnect') : const Text('Connect'),
                                icon: const Icon(Icons.login)
                              ),
                            ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            )
      ),
      floatingActionButton: Visibility( 
        visible: !widget.isLogged,
        child: FloatingActionButton(
          backgroundColor: const Color(0xff1f7944),
          onPressed: scanQrcode,
          tooltip: 'Scan Qrcode',
          // elevation: 0.0,
          child: const Icon(Icons.qr_code_scanner),
        )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      bottomNavigationBar: Footer(isLogged: widget.isLogged),
    );
  }

  _checkSession() async {
    var isLogged = await _secureStorage.sessionAlive();
    String stars = '*****';
    setState(() {
      _host = isLogged ? stars : '';
      _apiKey = isLogged ? stars : '';
      _email = isLogged ? stars : '';
      _pass = isLogged ? stars : '';
    });
    widget.isLogged = isLogged;
  }

  _disconnect() async {
    await _secureStorage.deleteAllSecureData();
    setState(() {
      _host = '';
      _apiKey = '';
      _email = '';
      _pass = '';
    });
    widget.isLogged = false;
  }

  _handleDeviceConnection(email, pass, url, apikey) async {
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode('$email:$pass');
    if (_formKey.currentState!.validate()) {
      String userEmail = await _btcPayApi.getUser(url, apikey, encoded);
      if (email == userEmail) {
        await _secureStorage.writeSecureData('HOST', url);
        await _secureStorage.writeSecureData('TOKEN', apikey);
        await _secureStorage.writeSecureData('BASIC', encoded);
        await _setStore(url, apikey, encoded, userEmail);            
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wrong credentials!')),
          );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill out all the fields required!')),
      );
    }
  }

  _setStore(host, token, base64, email) async {
    final stores = await _btcPayApi.getStores();
    List listStores = [];
    for (var s in stores) {
      listStores.add(s);
    }
    if (listStores.isNotEmpty){
      await _secureStorage.writeSecureData('STOREID', listStores.first['id']);
      await _secureStorage.writeSecureData('NAME', listStores.first['name']);
      List<dynamic> apps = await _btcPayApi.getApps();
      // ignore: prefer_typing_uninitialized_variables
      var appId;
      // ignore: prefer_typing_uninitialized_variables
      var appType;
      for (var app in apps) {
          if (app['storeId'] == listStores.first['id']) {
            appId = app['id'];
            appType = app['appType'];
            break;
          }
      }
      await _secureStorage.writeSecureData('APPID', appId);
      await _secureStorage.writeSecureData('APPTYPE', appType);
      // ignore: use_build_context_synchronously
      Navigator.pushNamed(context, '/invoices');
    } else {
      await _secureStorage.deleteSecureData('NAME');
      await _secureStorage.deleteSecureData('STOREID');
      await _secureStorage.deleteSecureData('APPID');
      await _secureStorage.deleteSecureData('APPTYPE');
    }
  }
}