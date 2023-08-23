import 'package:flutter/material.dart';

import 'views/invoices.dart';
import 'views/settings.dart';
import '../services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SecureStorage secureStorage = SecureStorage();
  bool isLogged = await secureStorage.sessionAlive();
  runApp(MyApp( isLogged: isLogged));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.isLogged
  });
  
  // ignore: prefer_typing_uninitialized_variables
  final isLogged;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BTCPayServer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff51b13d),
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 120.0, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontSize: 21.0, fontFamily: 'Roboto'),
          bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Roboto'),
        ),
        // textTheme: Platform.isAndroid ? blackMountainView : blackCupertino,
        // visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: const Settings(title: 'BTCPayServer'),
      // home: home,
      // home: MainPage(),
      initialRoute: isLogged ? '/invoices' : '/settings',
      routes: {
        '/settings': (context) => Settings(isLogged: isLogged),
        '/invoices': (context) => Invoices(isLogged: isLogged),
      },
    );
  }
}
