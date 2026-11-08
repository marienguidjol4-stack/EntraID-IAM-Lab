# creer_groupes.ps1 - cree les groupes du lab Entra ID et leurs membres
# Lit groupes.csv (Nom;Description) et appartenances.csv (Groupe;Membre;TypeMembre)
# TypeMembre = Utilisateur (Membre = login) ou Groupe (Membre = nom de groupe)
# Relancable sans risque : les groupes et appartenances existants sont ignores.
# Usage (depuis la racine du depot) : .\scripts\creer_groupes.ps1

# Une seule fois : Install-Module Microsoft.Graph.Groups -Scope CurrentUser
$domaine = "identitytestlab.onmicrosoft.com"
Connect-MgGraph -Scopes "Group.ReadWrite.All","GroupMember.ReadWrite.All","User.Read.All" -TenantId $domaine -NoWelcome

# 1) Groupes de sécurité (appartenance affectée)
$ids = @{}
$crees = 0
foreach ($g in (Import-Csv (Join-Path $PSScriptRoot '..\data\groupes.csv') -Delimiter ';' -Encoding UTF8)) {
    $existant = Get-MgGroup -Filter "displayName eq '$($g.Nom)'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existant) { $ids[$g.Nom] = $existant.Id; Write-Host "Existe déjà : $($g.Nom)"; continue }
    try {
        $nouveau = New-MgGroup -DisplayName $g.Nom -Description $g.Description `
            -MailEnabled:$false -SecurityEnabled:$true `
            -MailNickname ($g.Nom -replace '[^A-Za-z0-9-]','')
        $ids[$g.Nom] = $nouveau.Id
        $crees++
        Write-Host "Créé : $($g.Nom)"
    }
    catch { Write-Host "ERREUR groupe $($g.Nom) : $($_.Exception.Message)" -ForegroundColor Red }
}
if ($crees -gt 0) { Write-Host "Attente de la propagation (20 s)..."; Start-Sleep -Seconds 20 }

# 2) Appartenances (utilisateurs et groupes imbriqués)
foreach ($l in (Import-Csv (Join-Path $PSScriptRoot '..\data\appartenances.csv') -Delimiter ';' -Encoding UTF8)) {
    $gid = $ids[$l.Groupe]
    if ($l.TypeMembre -eq 'Groupe') { $mid = $ids[$l.Membre] }
    else {
        $u = Get-MgUser -Filter "userPrincipalName eq '$($l.Membre)@$domaine'" -ErrorAction SilentlyContinue
        $mid = $u.Id
    }
    if (-not $gid -or -not $mid) {
        Write-Host "ERREUR : introuvable ($($l.Membre) -> $($l.Groupe))" -ForegroundColor Red
        continue
    }
    try {
        New-MgGroupMember -GroupId $gid -DirectoryObjectId $mid
        Write-Host "Ajouté : $($l.Membre) -> $($l.Groupe)"
    }
    catch {
        if ($_.Exception.Message -match 'already exist') { Write-Host "Déjà membre : $($l.Membre) -> $($l.Groupe)" }
        else { Write-Host "ERREUR $($l.Membre) -> $($l.Groupe) : $($_.Exception.Message)" -ForegroundColor Red }
    }
}

# 3) Récapitulatif
Write-Host "`nRécapitulatif :"
foreach ($nom in ($ids.Keys | Sort-Object)) {
    $n = @(Get-MgGroupMember -GroupId $ids[$nom] -All).Count
    "{0,-28} {1} membre(s)" -f $nom, $n
}
