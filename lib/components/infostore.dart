import 'package:flutter/material.dart';

class InfoStore extends StatelessWidget {
  const InfoStore( {
    super.key,
    required this.isLoading,
    required this.name,
    required this.email,
  });

  final bool isLoading;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    /// Usage
    return Card(
        color: Colors.green,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: isLoading
                ? const CircularProgressIndicator(
                    strokeWidth: 2.0,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation(Colors.teal),
                    
                  )
                : const Icon(
                    Icons.store,
                    color: Colors.white,
                  ),
              title: Text(name),
              subtitle: Text(email),
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: <Widget>[
            //     TextButton(
            //       child: const Text('BUY TICKETS'),
            //       onPressed: () {/* ... */},
            //     ),
            //     const SizedBox(width: 8),
            //     TextButton(
            //       child: const Text('LISTEN'),
            //       onPressed: () {/* ... */},
            //     ),
            //     const SizedBox(width: 8),
            //   ],
            // ),
          ],
        ),
    );
  }
}