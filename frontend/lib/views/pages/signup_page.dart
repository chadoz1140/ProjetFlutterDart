
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c01/providers/security_provider.dart';
import 'package:prbd_2526_c01/models/user.dart';
import 'package:prbd_2526_c01/core/tools/validating_text_editing_controller.dart';


class SignupPage extends ConsumerStatefulWidget{
  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  late ValidatingTextEditingController _emailController;
  late ValidatingTextEditingController _fullNameController;
  late ValidatingTextEditingController _passwordController;
  late ValidatingTextEditingController _confirmPasswordController;
  late ValidatingTextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    _emailController = ValidatingTextEditingController(
        validator: User.validateEmail,
        asyncValidator: User.validateEmailUnicity);
    _emailController.onAfterValidated = () => setState(() {});

    _fullNameController = ValidatingTextEditingController(
        validator: User.validateFullName,
        asyncValidator: User.validateFullNameUnicity);
    _fullNameController.onAfterValidated = () => setState(() {});

    _passwordController = ValidatingTextEditingController(
      validator: User.validatePasswordSignup);
    _passwordController.onAfterValidated = () => setState(() {});

    _confirmPasswordController = ValidatingTextEditingController(
        validator: (value) => User.validateConfirmPassword(value, _passwordController.text)
    );
    _confirmPasswordController.onAfterValidated = () => setState(() {});

    _phoneController = ValidatingTextEditingController(
        validator: User.validatePhone);
    _phoneController.onAfterValidated = () =>setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final simulatedTime = DateTime(2024, 12, 4, 16, 0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        title: const Text('Inscription'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () {},
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
                message:
                'Date/heure simulée utilisée pour les tests.\nCliquez pour modifier.',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.person_add, size: 80, color: Colors.blue),
                const SizedBox(height: 32),
                const Text(
                  'Créez votre compte',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  autofocus: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _fullNameController,
                  onFieldSubmitted: (_) => _submitForm(context),
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    errorText: _fullNameController.errorText,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _emailController,
                  onFieldSubmitted: (_) => _submitForm(context),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    errorText: _emailController.errorText,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _passwordController,
                  onFieldSubmitted: (_) => _submitForm(context),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    errorText: _passwordController.errorText,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _confirmPasswordController,
                  onFieldSubmitted: (_) => _submitForm(context),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                    errorText: _confirmPasswordController.errorText,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _phoneController,
                  onFieldSubmitted: (_) => _submitForm(context),
                  decoration: InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    errorText: _phoneController.errorText,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _errorsFound() ? null : () => _submitForm(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('S\'inscrire'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _errorsFound() {
    return _emailController.errorText != null ||
        _fullNameController.errorText != null ||
        _passwordController.errorText != null ||
        _confirmPasswordController.errorText != null;
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!await _validateForm()) return;
    await ref.read(securityProvider.notifier).signup(
        email: _emailController.text,
        fullName: _fullNameController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text
    );
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  Future<bool> _validateForm() async {
    await _emailController.validateAndWait();
    await _fullNameController.validateAndWait();
    await _passwordController.validateAndWait();
    await _confirmPasswordController.validateAndWait();
    await _phoneController.validateAndWait();

    return _isFormValid;
  }

  bool get _isFormValid =>
      _emailController.isValid == true &&
          _fullNameController.isValid == true &&
          _passwordController.isValid == true &&
          _confirmPasswordController.isValid == true &&
          _phoneController.isValid == true;
}