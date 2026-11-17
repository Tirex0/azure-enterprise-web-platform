$ErrorActionPreference = "Stop"

$infrastructurePath = $PSScriptRoot
$certDirectory = Join-Path $infrastructurePath "certs"
$pfxPath = Join-Path $certDirectory "app-gateway-01.pfx"
$devTfvarsPath = Join-Path $infrastructurePath "environments/dev.tfvars"
$devExamplePath = Join-Path $infrastructurePath "environments/dev.tfvars.example"

if (-not (Test-Path -LiteralPath $devTfvarsPath)) {
    Copy-Item -LiteralPath $devExamplePath -Destination $devTfvarsPath
}
New-Item -ItemType Directory -Path $certDirectory -Force | Out-Null

$securePassword = Read-Host -Prompt "New dev PFX password (remember this for GitHub Secrets)" -AsSecureString
if ($securePassword.Length -lt 8) {
    throw "Choose a PFX password with at least 8 characters."
}

$certificate = New-SelfSignedCertificate -Subject "CN=app-gateway-01.local" -DnsName "app-gateway-01.local" -CertStoreLocation "Cert:\CurrentUser\My" -KeyAlgorithm RSA -KeyLength 2048 -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(1)

try {
    Export-PfxCertificate -Cert $certificate -FilePath $pfxPath -Password $securePassword -Force | Out-Null
    Get-PfxData -FilePath $pfxPath -Password $securePassword | Out-Null
}
catch {
    Remove-Item -LiteralPath "Cert:\CurrentUser\My\$($certificate.Thumbprint)" -ErrorAction SilentlyContinue
    throw
}

Remove-Item -LiteralPath "Cert:\CurrentUser\My\$($certificate.Thumbprint)" -ErrorAction SilentlyContinue
$devTfvars = [IO.File]::ReadAllText($devTfvarsPath)
$devTfvars = [regex]::Replace($devTfvars, '(?m)^ssl_certificate_path\s*=\s*".*"$', 'ssl_certificate_path = "./certs/app-gateway-01.pfx"')
[IO.File]::WriteAllText($devTfvarsPath, $devTfvars, [Text.UTF8Encoding]::new($false))

$env:TF_VAR_ssl_certificate_password = [System.Net.NetworkCredential]::new("", $securePassword).Password
Write-Host "Created and verified $pfxPath"
Write-Host "The PFX password is set in this PowerShell session for Terraform."
Write-Host "Remember the password so you can update GitHub Secrets before running the CD workflow."
