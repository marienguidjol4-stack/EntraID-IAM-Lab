# Lab Entra ID : cycle de vie des identités, accès conditionnel et MFA

Lab personnel d'IAM sur un tenant Microsoft Entra ID de test. **Toutes les identités sont fictives** et aucun secret n'est versionné.

## Objectif

Construire de façon reproductible un environnement IAM minimal sur Microsoft Entra ID, en trois étapes :

1. **Identités et groupes** : création des comptes et d'un modèle de groupes (départements, rôles, accès, privilèges).
2. **Cycle de vie JML** (Joiner, Mover, Leaver) : automatisation de l'appartenance aux groupes avec des groupes dynamiques.
3. **Accès conditionnel et MFA** : compte d'urgence, MFA pour les comptes à privilèges, politiques testées d'abord en mode « rapport seul ».

## Avancement

| Étape | Contenu | Statut |
|---|---|---|
| Sprint 1 | Utilisateurs, groupes, schéma d'architecture | Terminé |
| Sprint 2 | Groupes dynamiques et scénarios JML | À venir |
| Sprint 3 | Accès conditionnel, MFA, finalisation | À venir |

## Architecture

Les utilisateurs n'ont jamais de droits directs : ils appartiennent à des groupes de département (`GRP-DEP-`) ou de rôle (`ROLE-`), eux-mêmes membres de groupes d'accès (`ACC-`). Les comptes à privilèges sont isolés dans `PRIV-`. Le schéma complet est dans [`docs/schema-groupes.md`](docs/schema-groupes.md).

| Élément | Convention |
|---|---|
| Comptes standard | `prenom.nom` (15 comptes) |
| Comptes d'administration | `adm-prenom` (2 comptes) |
| Compte d'urgence | `bg-01` |
| Groupes | `GRP-DEP-`, `ROLE-`, `ACC-`, `PRIV-`, `TST-` (19 groupes) |
| Départements | FIN, RH, IT, VTE, ACH, JUR |

## Contenu du dépôt

```
entra-iam-lab/
├── README.md
├── .gitignore
├── data/
│   ├── utilisateurs.csv          # 18 comptes fictifs, sans mot de passe
│   ├── groupes.csv               # 19 groupes de sécurité
│   └── appartenances.csv         # 37 appartenances (utilisateurs et groupes imbriqués)
├── scripts/
│   ├── importer_utilisateurs.ps1
│   └── creer_groupes.ps1
└── docs/
    ├── schema-groupes.md
    └── captures/
```

## Reproduire le lab

**Prérequis** : un tenant Entra ID de test (par exemple via le Microsoft 365 Developer Program), un compte administrateur, PowerShell et les modules `Microsoft.Graph.Users` et `Microsoft.Graph.Groups`.

```powershell
Install-Module Microsoft.Graph.Users, Microsoft.Graph.Groups -Scope CurrentUser
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass   # limité à la session

.\scripts\importer_utilisateurs.ps1   # demande le mot de passe initial à l'exécution
.\scripts\creer_groupes.ps1
```

Avant de lancer les scripts, remplacer la variable `$domaine` par le domaine du tenant. Les deux scripts peuvent être relancés sans créer de doublons.

## Problèmes rencontrés

- **Import en bloc du portail en échec.** Le portail validait le fichier CSV, puis refusait de soumettre l'opération (« Nous n'avons pas pu soumettre l'opération en bloc »). Microsoft documente cette [limitation des opérations en bloc](https://learn.microsoft.com/fr-fr/entra/fundamentals/bulk-operations-service-limitations) et recommande PowerShell avec Microsoft Graph. Les comptes sont donc créés par script, ce qui rend aussi le lab reproductible et versionnable.
- **Exécution de scripts bloquée par Windows.** Le chargement du module Microsoft Graph demandait une confirmation pour un éditeur non approuvé. Le réglage `Set-ExecutionPolicy -Scope Process` n'agit que sur la session en cours, sans modifier la configuration de la machine.

## Sécurité et limites

- Aucun mot de passe dans le dépôt : il est saisi à l'exécution, et le fichier d'import du portail est exclu par `.gitignore`.
- Tous les comptes reçoivent le même mot de passe initial (changement forcé à la première connexion). C'est acceptable dans un lab, mais à proscrire en production, où l'on préférera un mot de passe aléatoire par compte ou un Temporary Access Pass.
- Les groupes de département sont affectés manuellement au Sprint 1, puis passent en groupes dynamiques au Sprint 2.
- Les groupes `ACC-` modélisent des accès : ils ne donnent accès à aucune application réelle dans ce lab.
