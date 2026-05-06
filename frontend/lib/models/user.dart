class User {

  static String? validateEmail(String? email){
    if(email == null || email.isEmpty){
      return 'Veuillez saisir une adresse e-mail.';
    }else{
      return null;
    }
  }

  static String? validatePassword(String? value){
    if(value == null || value.isEmpty) return 'Veuillez saisir votre mot de passe.';
    return null;
  }


}