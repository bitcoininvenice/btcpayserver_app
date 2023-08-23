import 'package:flutter/material.dart';

import '../services/storage.dart';

// ignore: must_be_immutable
class Footer extends StatefulWidget {
  Footer({
    super.key,
    required this.isLogged
  });

  late bool isLogged;

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return  AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 69.0,
      child: BottomAppBar(
        color: const Color(0xff51b13d),
        elevation: 3.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            showSettings(),
            const Spacer(),
            showPayments(),
          ],
        )
      ),
    );
  }

  _checkSession() async {
    var isLogged = await _secureStorage.sessionAlive();
    widget.isLogged = isLogged;
  }

  _renderButton(icon, route) {
    return IconButton(
      icon: icon,
      onPressed: () async {
        if (ModalRoute.of(context)?.settings.name != route) {
          if (widget.isLogged) {
              // ignore: use_build_context_synchronously
              Navigator.pushNamed(context, route);
          } else {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fill out all the fields required!')),
            );
          }
        }
      },
    );
  }

  showSettings() {
    return _renderButton(const Icon(Icons.settings, color: Colors.white), '/settings');
  }

  showPayments() {
    return _renderButton(const Icon(Icons.list, color: Colors.white), '/invoices');
  }
}