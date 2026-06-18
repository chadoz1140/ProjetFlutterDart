# Projet PRBD 2526 - Groupe c01 - ReserVite

## Notes de version

### Utilisateurs de test

Après réinitialisation de la base de données, tous les utilisateurs ont le même mot de passe :

```text
Password1,
```

| Email | Mot de passe | Rôle |
|---|---|---|
| boverhaegen@epfc.eu | Password1, | manager |
| bepenelle@epfc.eu | Password1, | manager |
| gedielman@epfc.eu | Password1, | manager |
| manager@epfc.eu | Password1, | manager |
| xapigeolet@epfc.eu | Password1, | client |
| mamichel@epfc.eu | Password1, | client |
| brlacroix@epfc.eu | Password1, | client |
| client@epfc.eu | Password1, | client |

### Liste des bugs connus

* Aucun bug trouver pour le moment

### Liste des fonctionnalités supplémentaires

* Aucune fonctionnalité demandée n’est laissée non implémentée.

### Divers

ReserVite est une application de réservation de restaurants pensée autour de deux profils : le client et le manager.

Le client peut rechercher des restaurants, consulter les détails, créer une réservation, la modifier si elle est encore éditable, l’annuler, et suivre ses réservations selon leur statut.

Le manager dispose d’un espace dédié pour gérer ses restaurants, leurs services, leurs tables et les réservations associées. Il peut notamment confirmer une réservation en assignant les tables disponibles, marquer une réservation comme terminée ou l’annuler.

Le projet utilise Flutter avec Riverpod pour le frontend, et PostgreSQL/PostgREST pour le backend. Les règles métier principales sont gérées côté base de données avec des fonctions SQL et des triggers, afin de garder une cohérence même si une action est appelée directement depuis l’API.


