import 'package:btcpayserver_app/components/footer.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../components/infostore.dart';
import '../components/classes.dart';
import '../services/storage.dart';
import '../services/btcpayapi.dart';

// ignore: must_be_immutable
class Invoices extends StatefulWidget {
  Invoices({
    super.key,
    required this.isLogged
  });

  late bool isLogged;

  @override
  State<Invoices> createState() => _InvoicesState();
}

class _InvoicesState extends State<Invoices> {
  final _secureStorage = SecureStorage();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _btcPayApi = BTCPayAPI();
  late Future<List<Store>> _listStores;
  late Future<List<App>> _listApps;
  late Future<List<Invoice>> _listInvoices;
  bool _isLoading = false;
  late String _storeName = '';
  late String _userEmail = '';
  late final Future<dynamic> _appVersion;

  @override
  void initState() {
    super.initState();
    _checkSession();
    _getInfo();
    _appVersion = _getVersion();
    _listInvoices = _getListInvoices();
    _listApps = _getListApps();
    _listStores = _getListStores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Invoices'),
        centerTitle: true,
        actions: const [],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xffffffff),
        child: Center(
          child: Column(
            children: [
              Image.asset(
                'images/logo.png',
                height: 300,
                ),
              InfoStore(
                isLoading: _isLoading,
                name: _storeName,
                email: _userEmail
              ),
              FutureBuilder<List<Store>>(
                future: _listStores,
                builder: (context, snapshot) {
                  return Container(
                    width: 250.0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.green, borderRadius: BorderRadius.circular(10)),
                    child:  DropdownButton<String>(
                      hint: const Text("Select store"),
                      onChanged: (String? storeId) async {
                        await _updateStore(storeId);
                      },
                      items: snapshot.data?.map((s) =>
                        DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.name),
                        )
                      ).toList(),
                    )
                  );
                }
              ),
              FutureBuilder<List<App>>(
                future: _listApps,
                builder: (context, snapshot) {
                  return Container(
                    width: 250.0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color:Colors.green, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButton<String>(
                      hint: const Text("Select App"),
                      onChanged: (String? appId) async {
                        await _updateApp(appId);
                      },
                      items: snapshot.data?.map((app) =>
                        DropdownMenuItem<String>(
                          value: app.id,
                          child: Text(app.name),
                        )
                      ).toList(),
                    )
                  );
                }
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onPressed: () async {
                  await _clearDevice(context);
                },
                label: const Text("Disconnect"),
                icon: const Icon(Icons.logout)
              ),
              FutureBuilder<dynamic>(
                future: _appVersion,
                builder: (context, snapshot) {
                  return Text('Version ${snapshot.data}');
                },
              ),
            ],
          )
        )
      ),
      body: FutureBuilder<dynamic>(
        future: _listInvoices,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: _pullRefresh,
            child: _renderListInvoices(snapshot),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff1f7944),
        onPressed: () async {
                _openPos();
              },
        tooltip: 'Open POS',
        child:  const Icon(Icons.point_of_sale_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      bottomNavigationBar: Footer(isLogged: widget.isLogged),
    );
  }

  Widget _renderListInvoices(AsyncSnapshot snapshot) {
    if (snapshot.hasData) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(21),
        scrollDirection:  Axis.vertical,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              for (var i in snapshot.data)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: _handleStatusColor(i.status),
                  child: ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                      child: _renderIcon(i),
                    ),
                    title: _renderTitle(i),
                    subtitle: Text(DateFormat('dd/MM/yyyy, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(i.createdTime * 1000))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(i.metadata['itemDesc']),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    dense: true,
                    onTap: i.status == 'New' ? () => _launchURL(i.checkoutLink) : null
                  ),
                )
            ],
          ),
        )
      );
    } else {
      return Center(
        child: Column(
            children: [
              Center(
                child:
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: Image.asset(
                                    "images/logo.png")
                                .image))),
              ),
              const CircularProgressIndicator(
                    backgroundColor: Colors.green,
                    valueColor: AlwaysStoppedAnimation(Colors.grey),
                    
                  ),
            ],
          ),
      );
    }
  }

  _checkSession() async {
    var isLogged = await _secureStorage.sessionAlive();
    widget.isLogged = isLogged;
  }

  Future<void> _pullRefresh() async {
    List<Invoice> freshInvoices = await _getListInvoices();
    setState(() {
      _listInvoices = Future.value(freshInvoices);
    });
  }

  _updateApp(appId) async {
    setState(() {
      _isLoading = true;
    });
    final appIdStored = await _secureStorage.readSecureData('APPID');
    if (appId != appIdStored) {
      var apps = await _getListApps();
      String? appType;
      for (var a in apps) {
        if (appId == a.id) {
          appType = a.appType;
          break;
        }
      }
      var app = appType == 'PointOfSale'
          ? await _btcPayApi.getPosById(appId)
          : await _btcPayApi.getCrowdfundById(appId);
      var store = await _btcPayApi.getStoreById(app['storeId']);
      setState(() {
          _storeName = store['name'];
        });
      await _secureStorage.writeSecureData('STOREID', store['id']);
      await _secureStorage.writeSecureData('NAME', store['name']);
      await _secureStorage.writeSecureData('APPID', app['id']);
      await _secureStorage.writeSecureData('APPTYPE', app['appType']);
      await _pullRefresh();
    } else {
      _renderMessage('Pos già selezionato!');
    }
    setState(() {
      _isLoading = false;
    });
  }

  _updateStore(storeId) async {
    setState(() {
      _isLoading = true;
    });
    final storeIdStored = await _secureStorage.readSecureData('STOREID');
    if (storeId != storeIdStored) {
      App app = await _getFirstAppByStore(storeId);
      if (app.id.isNotEmpty) {
        var store = await _btcPayApi.getStoreById(storeId);
        setState(() {
            _storeName = store['name'];
          });
        await _secureStorage.writeSecureData('STOREID', storeId!);
        await _secureStorage.writeSecureData('NAME', store['name']);
        await _secureStorage.writeSecureData('APPID', app.id);
        await _secureStorage.writeSecureData('APPTYPE', app.appType);
        await _pullRefresh();
      } else {
        _renderMessage('Non è presente una app per questo negozio!');
      }
    } else {
      _renderMessage('Store già selezionato!');
    }
    setState(() {
      _isLoading = false;
    });
  }

  _renderMessage(String text) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.closeDrawer();
    }
  }

  _getInfo() async {
    var storeName = await _secureStorage.readSecureData('NAME');
    var userEmail = await _secureStorage.readSecureData('EMAIL');
    setState(() {
      _storeName = storeName.toString();
      _userEmail = userEmail.toString();
    });
  }

  Future<List<Invoice>> _getListInvoices() async {
    var data = await _btcPayApi.getInvoices();
    List<Invoice> invoices = [];
    for (var item in data) {
      invoices.add(Invoice(
        item['id'], item["storeId"],
        item['amount'], item['status'],
        item['createdTime'], item['checkoutLink'],
        item['metadata']
      ));
    }
    return invoices;
  }

  Future<List<Store>> _getListStores() async {
    var data = await _btcPayApi.getStores();
    List<Store> stores = [];
    for (var item in data) {
      stores.add(Store(item['id'], item["name"]));
    }
    return stores;
  }

  Future<List<App>> _getListApps() async {
    var data = await _btcPayApi.getApps();
    List<App> apps = [];
    for (var item in data) {
      apps.add(App(item['id'], item["name"], item['appType']));
    }
    return apps;
  }

  Future<App> _getFirstAppByStore(storeId) async {
    List<dynamic> apps = await _btcPayApi.getApps();
    // ignore: prefer_typing_uninitialized_variables
    dynamic app;
    String id = '';
    String name = '';
    String type = '';
    for (var a in apps) {
      if (a['storeId'] == storeId) {
        app = a;
        break;
      }
    }
    if (app != null) {
      id = app['id'];
      name = app['name'];
      type = app['appType'];
    }
    return App(id, name, type);
  }

  _openPos() async {
    Map<String, String> storage = await _secureStorage.readAllSecureData();
    String? host = storage['HOST'];
    String? appId = storage['APPID'];
    String? appType = storage['APPTYPE'];
    String webUrl = appType == 'PointOfSale' ? '$host/apps/$appId/pos' : '$host/apps/$appId/crowdfund';
    _launchURL(webUrl);
  }

  _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    } else {
      // Wait until the browser closes
      await Future.delayed(const Duration(milliseconds: 100));
      while (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await _pullRefresh();
    }
  }

  _clearDevice(context) async {
    await _secureStorage.deleteAllSecureData();
    Navigator.pushNamed(context, '/settings');
  }

  _handleStatusColor (status) { 
    switch (status) {
      case "New":
        return const Color(0xffcedd20);
      case "Settled":
        return const Color(0xff51b13d);
      case "Expired": 
        return const Color(0xffdcdcdc);
    }
    return status;
  }

  _renderTitle (Invoice i) {
    return Row(
      children: [
        Text(i.status),
        Text(' - ${i.amount}'),
        const Icon(
          Icons.euro,
          size: 12,
          color: Colors.black
        ),
      ],
    );
  }

  _renderIcon (Invoice i) {
    switch (i.status) {
      case "New":{
        return const Icon(Icons.open_in_new);
      }
      case "Settled":{
        return const Icon(Icons.done_outline);
      }
      case "Expired":{ 
        return const Icon(Icons.do_not_disturb_on);
      }
    }
  }

  _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
