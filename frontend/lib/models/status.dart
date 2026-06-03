enum Status{
  pending('En attente'),
  confirmed('Confirmée'),
  completed('Terminée'),
  cancelled('Annulée');

  final String value;
  const Status (this.value);

  static Status fromJson(String value) {
    return Status.values.firstWhere(
          (e) => e.name == value,
    );
  }
}