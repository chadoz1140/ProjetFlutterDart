
import 'dart:core';

import 'package:prbd_2526_c01/models/security.dart';

class User {
  final int id;
  final String email;
  final String password;
  final String fullName;
  final String role;
  final String? phone;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.phone = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
    );
  }

  static String? validateEmail(String? email, {bool isLogin = false}) {
    if (email == null || email.isEmpty) {
      return 'requis';
    }

    if (isLogin) return null;

    if (!RegExp(r'^[A-Za-z0-9+_.-]+@epfc\.eu$').hasMatch(email)) {
      return 'Veuillez entrer une addresse email valide.';
    }
    return null;
  }

  static Future<String?> validateEmailUnicity(String? email) async {
    var res = await Security.isEmailAvailable(email: email?.trim());
    return res ? null : 'Cet email est déjà utilisé.';
  }

  static String? validateFullName(String? fullName) {
    if(fullName == null || fullName.isEmpty) {
      return 'requis';
    } else if (fullName.length < 5) {
      return 'Le nom complet doit contenir au moins 5 caractères';
    } else {
      return null;
    }
  }

  static Future<String?> validateFullNameUnicity(String? fullName) async {
    var res = await Security.isFullNameAvailable(fullName: fullName?.trim());
    return res ? null : 'Ce nom est déjà utilisé.';
  }


  static String? validatePasswordLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'requis';
    }
    return null;
  }

  static String? validatePasswordSignup(String? value) {
    if (value == null || value.isEmpty) {
      return 'requis';
    }
    return validatePasswordFormat(value);
  }

  static String? validateConfirmPassword(String? value, String? password) {
    String? passwordError = validatePasswordLogin(value);
    if (passwordError != null) return passwordError;
    if (value != password) return 'Les deux mots de passe doivent être identiques.';
    return null;
  }

  static String? validatePasswordFormat(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!value.contains(RegExp(r'[a-z]'))) {
        return 'Le mot de passe doit contenir au moins une lettre majuscule.';
      } else if (!value.contains(RegExp(r'[0-9]'))) {
        return 'Le mot de passe doit contenir au moins un chiffre.';
      } else if (!value.contains(RegExp(r'[@$!%*?&,]'))) {
        return 'Le mot de passe doit contenir au moins un caractère special (@\$!%*?&,)';
      } else if(value.length < 8)
        return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone != null && phone.isNotEmpty) {
      if (!RegExp(r'^(\+32\s?|0)[1-9]\d{0,2}(\s?\d{2}){3}$').hasMatch(phone)) {
        return 'Veuillez entrer un numéro de téléphone valide.';
      }
    }
    return null;
  }
}