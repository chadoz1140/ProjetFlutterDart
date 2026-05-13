import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/core/tools/validating_text_editing_controller.dart';
import 'package:prbd_2526_c01/core/widgets/dialog_box.dart';
import 'package:prbd_2526_c01/providers/security_provider.dart';

import '../../models/user.dart';

class LoginPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends ConsumerState<LoginPage>{
  static const String _debugPassword = 'Password1,';

  late ValidatingTextEditingController _emailController;
  late ValidatingTextEditingController _passwordController;

  @override
  void initState(){
    super.initState();
    _initControllers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final simulatedTime = DateTime(2024, 12, 4, 16, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: ()=> _resetForm(),
          ),
        ],
        elevation: 2,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Tooltip(
                  message: 'Date/heure simulée utilisée pour les tests.\nCliquez pour modifier.',
                  child: Text(
                    DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_FR')
                        .format(simulatedTime),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),

              ),
          ),
        ),
      ),

      body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 32),
                            const Icon(
                              Icons.restaurant,
                              size: 80,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Connectez-vous',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              autofocus: true,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              onFieldSubmitted: (_) => _submitForm(context),
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                errorText: _emailController.errorText,
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              onFieldSubmitted: (_) => _submitForm(context),
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                                errorText: _passwordController.errorText,
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _submitForm(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Se connecter'),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                              child: const Text(
                                'Pas encore de compte ? S\'inscrire',
                              ),
                            ),
                          ],
                        ),
                    ),
                  ),
              ),
              if (kDebugMode) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Raccourcis de débogage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Se connecter directement en tant que :',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _login(
                                    context,
                                    'brlacroix@epfc.eu',
                                    _debugPassword
                                );
                              },
                              icon: const Icon(Icons.person),
                              label: const Text('Client (Bruno)'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _login(
                                    context,
                                    'mamichel@epfc.eu',
                                    _debugPassword
                                );
                              },
                              icon: const Icon(Icons.person),
                              label: const Text('Client (Marc)'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _login(
                                    context,
                                    'bepenelle@epfc.eu',
                                    _debugPassword
                                );
                              },
                              icon: const Icon(Icons.manage_accounts),
                              label: const Text('Manager (Benoît)'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _login(
                                    context,
                                    'gedielman@epfc.eu',
                                    _debugPassword
                                );
                              },
                              icon: const Icon(Icons.manage_accounts),
                              label: const Text('Manager (Geoffrey)'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _resetDatabase(context);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réinitialiser la base de données'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

            ],

          )
      ),
    );
    
  }

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void>_submitForm(BuildContext context) async{
    if(!await _validateForm()) return;
    _login(context, _emailController.text, _passwordController.text);
  }

  Future<bool> _validateForm() async {
    await _emailController.validateAndWait();
    await _passwordController.validateAndWait();
    return _emailController.isValid == true && _passwordController.isValid == true;
  }

  void _login(BuildContext context, String email, String password) async{
    await ref.read(securityProvider.notifier).login(email, password);
    var securityState = ref.read(securityProvider);

    if(!context.mounted) return;
    securityState.when(
        data: (_) => Navigator.pushReplacementNamed(context, '/searchRestaurants'),
        error: (error, _) => _showErrorOrSuccesMessage(context, 'Email ou mot de passe incorrect', true),
        loading: (){},
    );
  }

  void _resetDatabase(BuildContext context) async {
    final result = await DialogBox(
      title:'Réinitialiser la base de données',
      message: 'Êtes-vous sûr de vouloir réinitialiser la base de données ? '
          'Cette action supprimera toutes les données et les restaurera aux valeurs par défaut.',
      actions: ['Annuler', 'Réinitialiser'],
    ).show(context);
    if(result != 'Réinitialiser') return;

    await ref.read(securityProvider.notifier).resetDatabase();
    if (!context.mounted) return;
    var securityState = ref.read(securityProvider);

    securityState.when(
        data: (_) => _showErrorOrSuccesMessage(context, 'Base de données réinitialisée', false),
        error: (err, _) => _showErrorOrSuccesMessage(context, 'Erreur lors de la réinitialisation', true),
        loading: (){},
    );
  }

  void _showErrorOrSuccesMessage(BuildContext context, String message, bool error) {
    if(error){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetForm() {
    _emailController.dispose();
    _passwordController.dispose();

    _initControllers();
    setState(() {});
  }

  void _initControllers(){
    _emailController = ValidatingTextEditingController(
      validator: (value) => User.validateEmail(value, isLogin: true)
    );

    _emailController.onAfterValidated = () => setState(() {});

    _passwordController = ValidatingTextEditingController(
        validator: User.validatePasswordLogin
    );
    _passwordController.onAfterValidated = () => setState(() {});
  }

}