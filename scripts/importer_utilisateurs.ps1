# importer_utilisateurs.ps1 - cree les comptes du lab Entra ID a partir de utilisateurs.csv
# Aucun secret dans ce fichier : le mot de passe est saisi a l'execution.
# Usage (depuis la racine du depot) : .\scripts\importer_utilisateurs.ps1

# 1) Une seule fois (accepter l'installation du fournisseur NuGet si demande)
# Install-Module Microsoft.Graph.Users -Scope CurrentUser

# 2) Connexion avec le compte administrateur du tenant (accepter la demande de consentement)
$domaine = "identitytestlab.onmicrosoft.com"
Connect-MgGraph -Scopes "User.ReadWrite.All" -TenantId $domaine

$mdp = Read-Host "Mot de passe initial du lab (non versionné)"

Import-Csv (Join-Path $PSScriptRoot '..\data\utilisateurs.csv') -Delimiter ';' -Encoding UTF8 | ForEach-Object {
    $upn = "$($_.Login)@$domaine"

    # Evite les doublons si le script est relance
    $existant = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
    if ($existant) { Write-Host "Existe déjà : $upn"; return }

    if     ($_.Login -like 'adm-*')  { $nom = "ADM $($_.Prenom) $($_.Nom)" }
    elseif ($_.Login -eq 'bg-01')    { $nom = "Compte urgence 01" }
    else                             { $nom = "$($_.Prenom) $($_.Nom)" }

    $params = @{
        DisplayName       = $nom
        UserPrincipalName = $upn
        MailNickname      = $_.Login
        GivenName         = $_.Prenom
        Surname           = $_.Nom
        JobTitle          = $_.Fonction
        UsageLocation     = "FR"
        AccountEnabled    = $true
        PasswordProfile   = @{ Password = $mdp; ForceChangePasswordNextSignIn = $true }
    }
    # Les comptes adm- et bg-01 n'ont pas de département
    if ($_.Departement) { $params.Department = $_.Departement }

    try {
        New-MgUser @params | Out-Null
        Write-Host "Créé : $upn"
    }
    catch {
        Write-Host "ERREUR $upn : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Verification
Get-MgUser -All -Property DisplayName,UserPrincipalName,Department |
    Select-Object DisplayName,UserPrincipalName,Department | Sort-Object UserPrincipalName | Format-Table -AutoSize
