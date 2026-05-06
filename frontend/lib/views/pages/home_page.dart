import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/security_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>{
  @override
  Widget build(BuildContext context) {
    ref.watch(securityProvider);

    final user = ref.read(securityProvider.notifier).loggedUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello ${user ?? ''}',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.red,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TO DO',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
                IconButton(
                  onPressed: _logout,
                  icon: Icon(Icons.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _logout(){
    ref.read(securityProvider.notifier).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }



  
}