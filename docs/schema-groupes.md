# Schéma d'architecture v1 — modèle de groupes du lab Entra ID

Les utilisateurs n'ont jamais de droits directs : ils appartiennent à des groupes de département (`GRP-DEP-`) ou de rôle (`ROLE-`), qui sont eux-mêmes membres de groupes d'accès (`ACC-`). Les comptes à privilèges sont isolés dans `PRIV-`.

```mermaid
flowchart LR
  U["15 comptes standard<br/>prenom.nom"]
  A["adm-hugo, adm-awa"]
  B["bg-01"]
  DEP["GRP-DEP-FIN / RH / IT<br/>VTE / ACH / JUR"]
  ROLE["ROLE-Responsable<br/>ROLE-Support-IT"]
  ACC["8 groupes ACC-*<br/>accès aux ressources"]
  PRIV["PRIV-Admins-IT"]
  PBG["PRIV-BreakGlass"]
  TST["TST-CA-Pilote<br/>(tests S3)"]
  U --> DEP
  U --> ROLE
  DEP --> ACC
  ROLE --> ACC
  A --> PRIV
  B --> PBG
  U -.-> TST
```

## Groupes

| Préfixe | Rôle | Groupes |
|---|---|---|
| `GRP-DEP-` | Département (devient dynamique au S2) | FIN, RH, IT, VTE, ACH, JUR |
| `ROLE-` | Fonction | Responsable, Support-IT |
| `ACC-` | Accès à une ressource (contiennent des groupes) | ERP-Finance, SIRH-RH, Outils-IT, CRM-Ventes, Achats-Fournisseurs, Contrats-Juridique, Reporting-Direction, Helpdesk-IT |
| `PRIV-` | Comptes à privilèges | Admins-IT, BreakGlass |
| `TST-` | Tests | CA-Pilote |
