<#
.SYNOPSIS
    Scan staged Git files for potential secrets.

.DESCRIPTION
    This script checks staged files for patterns that match common secret types:
    - Passwords (pwd=, password=, passwd=)
    - API keys (api_key, apikey, client_secret)
    - Tokens (access_token, Bearer, refresh_token)
    - Private keys (BEGIN PRIVATE KEY, BEGIN RSA PRIVATE KEY, etc.)
    - Connection strings with passwords
    - Oracle credentials (ORACLE_PWD, ORACLE_EQUITY_LAB_PWD)

    Run BEFORE commits to prevent secrets from being published.

    Exit code: 0 if safe, 1 if secrets detected.

.PARAMETER NoExit
    If set, do not exit with error code (used for testing).
#>

param(
    [switch]$NoExit
)

$ErrorActionPreference = 'Continue'

Write-Host "Scanning staged files for secrets..." -ForegroundColor Cyan

# List of patterns that indicate secrets
$secretPatterns = @(
    @{ pattern = 'password\s*='; description = 'Password assignment' },
    @{ pattern = 'passwd\s*='; description = 'Password assignment (short form)' },
    @{ pattern = 'pwd\s*='; description = 'Password abbreviation' },
    @{ pattern = 'ORACLE_PWD'; description = 'Oracle password variable' },
    @{ pattern = 'ORACLE_EQUITY_LAB_PWD'; description = 'Oracle app password variable' },
    @{ pattern = 'api_key|apikey'; description = 'API key' },
    @{ pattern = 'client_secret'; description = 'Client secret' },
    @{ pattern = 'access_token|refresh_token'; description = 'Token' },
    @{ pattern = 'Bearer\s+[A-Za-z0-9\-_.]+'; description = 'Bearer token' },
    @{ pattern = 'BEGIN PRIVATE KEY|BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY'; description = 'Private key block' },
    @{ pattern = 'AccountKey='; description = 'Azure account key' },
    @{ pattern = 'SharedAccessSignature='; description = 'Azure shared access signature' },
    @{ pattern = 'Secret='; description = 'Generic secret assignment' },
    @{ pattern = 'User Id=.*Password='; description = 'Connection string with password' }
)

# Get staged files from git index
$stagedFiles = git diff --cached --name-only 2>&1
if($LASTEXITCODE -ne 0){
    Write-Host "Error getting staged files: $stagedFiles" -ForegroundColor Red
    if(-not $NoExit){ exit 1 }
    return 1
}

if(-not $stagedFiles){
    Write-Host "No staged files to check." -ForegroundColor Green
    if(-not $NoExit){ exit 0 }
    return 0
}

# Directories to skip
$skipPatterns = @('\\bin\\', '\\obj\\', '\\.vs\\', '\\.git\\', '\\TestResults\\', '\\packages\\', '\\scripts\\Test-Secrets.ps1$')

$secretsFound = 0

# Check each staged file
foreach($file in $stagedFiles){
    # Skip the secret scanner script itself
    if($file -eq "scripts/Test-Secrets.ps1" -or $file -eq "scripts\Test-Secrets.ps1"){
        continue
    }

    # Skip binary and build files
    if($file -match '\.(exe|dll|pdb|nupkg|pfx|p12|key)$'){
        continue
    }

    # Skip known safe directories
    if($skipPatterns | Where-Object { $file -match $_ }){
        continue
    }

    # Check if file exists (it should, being staged)
    $fullPath = Join-Path (git rev-parse --show-toplevel) $file
    if(-not (Test-Path $fullPath)){
        continue
    }

    # Read file content
    try {
        $content = Get-Content $fullPath -Raw -ErrorAction SilentlyContinue
        if(-not $content){
            continue
        }

        # Check each secret pattern
        foreach($secretTest in $secretPatterns){
            if($content -match $secretTest.pattern){
                Write-Host "[WARNING] SECRET FOUND in: $file" -ForegroundColor Yellow
                Write-Host "   Type: $($secretTest.description)" -ForegroundColor Yellow
                Write-Host "   Action: Remove the secret before committing" -ForegroundColor Yellow
                Write-Host ""
                $secretsFound++
            }
        }
    }
    catch {
        # Skip files we can't read (binary, locked, etc.)
        continue
    }
}

if($secretsFound -gt 0){
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "ABORT: Found $secretsFound potential secret(s)." -ForegroundColor Red
    Write-Host "Remove them before committing." -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    if(-not $NoExit){ exit 1 }
    return 1
}else{
    Write-Host "[OK] No secrets detected in staged files" -ForegroundColor Green
    if(-not $NoExit){ exit 0 }
    return 0
}
