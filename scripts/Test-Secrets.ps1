<#
.SYNOPSIS
    Scan staged Git content for secrets and dangerous files.

.DESCRIPTION
    This script checks STAGED (indexed) files for:
    - High-risk file types (.pfx, .p12, .key, .pem, .keystore, .env files)
    - Secret patterns in text content (passwords, tokens, keys, connection strings)

    Reads exact staged content using "git show :<path>" to check the index,
    not the working tree.

    Exit code: 0 if safe, nonzero if secrets/dangerous files detected.

.PARAMETER NoExit
    If set, do not exit with error code (used for testing).
#>

param(
    [switch]$NoExit
)

$ErrorActionPreference = 'Continue'

Write-Host "Scanning staged files for secrets..." -ForegroundColor Cyan

# High-risk file types that should never be staged
$dangerousExtensions = @('.pfx', '.p12', '.key', '.pem', '.keystore')
$dangerousNames = @('.env', 'oracle.env', 'secrets.json')

# Secret patterns to detect in text content
$secretPatterns = @(
    @{ pattern = 'Password\s*='; description = 'Password assignment' },
    @{ pattern = 'Pwd\s*='; description = 'Password abbreviation' },
    @{ pattern = 'passwd\s*='; description = 'Password (Unix style)' },
    @{ pattern = 'ORACLE_PWD'; description = 'Oracle password variable' },
    @{ pattern = 'ORACLE_EQUITY_LAB_PWD'; description = 'App password variable' },
    @{ pattern = 'api_key|apikey'; description = 'API key' },
    @{ pattern = 'client_secret'; description = 'Client secret' },
    @{ pattern = 'access_token|refresh_token'; description = 'Token' },
    @{ pattern = 'Bearer\s+[A-Za-z0-9\-_.~\+/]+=*'; description = 'Bearer token' },
    @{ pattern = 'BEGIN PRIVATE KEY|BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY|BEGIN EC PRIVATE KEY'; description = 'Private key block' },
    @{ pattern = 'AccountKey\s*='; description = 'Azure account key' },
    @{ pattern = 'SharedAccessSignature\s*='; description = 'Azure SAS' },
    @{ pattern = 'User\s+Id\s*=.*Password\s*='; description = 'Connection string with password' }
)

# Get list of staged files from git index
$stagedFiles = git diff --cached --name-only 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Could not read staged files: $stagedFiles" -ForegroundColor Red
    if (-not $NoExit) { exit 1 }
    return 1
}

if (-not $stagedFiles) {
    Write-Host "[OK] No staged files to check." -ForegroundColor Green
    if (-not $NoExit) { exit 0 }
    return 0
}

$foundIssues = 0

# Check each staged file
foreach ($file in $stagedFiles) {
    # Skip git internals
    if ($file -match '^\\.git') {
        continue
    }

    # Check for dangerous file extensions
    $extension = [System.IO.Path]::GetExtension($file).ToLower()
    if ($dangerousExtensions -contains $extension) {
        Write-Host "[DANGER] Staged high-risk file type: $file" -ForegroundColor Red
        Write-Host "         File extension: $extension" -ForegroundColor Red
        Write-Host "         Action: Remove this file before committing" -ForegroundColor Red
        Write-Host ""
        $foundIssues++
        continue
    }

    # Check for dangerous filenames
    $filename = [System.IO.Path]::GetFileName($file).ToLower()
    if ($dangerousNames -contains $filename) {
        Write-Host "[DANGER] Staged dangerous file: $file" -ForegroundColor Red
        Write-Host "         Action: Remove this file before committing" -ForegroundColor Red
        Write-Host ""
        $foundIssues++
        continue
    }

    # Check for .env.* patterns
    if ($file -match '\\.env\\..+$' -or $file -match '\\.env$') {
        Write-Host "[DANGER] Staged .env file: $file" -ForegroundColor Red
        Write-Host "         Action: Remove this file before committing" -ForegroundColor Red
        Write-Host ""
        $foundIssues++
        continue
    }

    # Skip the secret scanner script itself
    if ($file -eq "scripts/Test-Secrets.ps1" -or $file -eq "scripts\Test-Secrets.ps1") {
        continue
    }

    # Skip binary files that we cannot safely inspect
    if ($file -match '\\.exe$|\\.dll$|\\.pdb$|\\.nupkg$|\\.zip$|\\.jar$') {
        continue
    }

    # Skip build and IDE directories
    if ($file -match '(^|\\\\)(bin|obj|.vs|.git|TestResults|packages|node_modules)(\\\\|$)') {
        continue
    }

    # Now read the STAGED content using git show :<path>
    # This reads the exact blob from the index, not the working tree
    $stagedContent = git show ":$file" 2>&1
    if ($LASTEXITCODE -ne 0) {
        # If we can't read it and it looks like it might be secret-bearing, fail closed
        if ($file -match '(config|secret|password|credential|auth|key|token|\.json$|\.xml$|\.config$|\.js$|\.ts$|\.cs$)') {
            Write-Host "[UNSAFE] Could not inspect staged file: $file" -ForegroundColor Red
            Write-Host "         Action: Verify it contains no secrets, or remove it" -ForegroundColor Red
            Write-Host ""
            $foundIssues++
        }
        continue
    }

    # Check staged content for secret patterns
    # Skip pattern checks for documentation files (.md) - they reference variable names, not secrets
    if ($file -match '\\.md$') {
        continue
    }

    foreach ($secretTest in $secretPatterns) {
        if ($stagedContent -match $secretTest.pattern) {
            # Skip false positives

            # For .CS files: Skip if assignment comes from GetEnvironmentVariable (safe)
            if ($file -match '\.cs$' -and $stagedContent -match "GetEnvironmentVariable") {
                continue
            }

            # For Password patterns in CS files: Also skip if it's a variable assignment from GetEnvironmentVariable
            if ($secretTest.description -like "*password*" -and $file -match '\\.cs$' -and $stagedContent -match "GetEnvironmentVariable") {
                continue
            }

            Write-Host "[SECRET] Found in staged file: $file" -ForegroundColor Yellow
            Write-Host "         Pattern: $($secretTest.description)" -ForegroundColor Yellow
            Write-Host "         Action: Remove the secret before committing" -ForegroundColor Yellow
            Write-Host ""
            $foundIssues++
        }
    }
}

# Report final result
if ($foundIssues -gt 0) {
    Write-Host ("=" * 50) -ForegroundColor Red
    Write-Host "BLOCKED: Found $foundIssues security issue(s)." -ForegroundColor Red
    Write-Host "Remove all secrets/dangerous files before committing." -ForegroundColor Red
    Write-Host ("=" * 50) -ForegroundColor Red
    if (-not $NoExit) { exit 1 }
    return 1
} else {
    Write-Host "[OK] All staged content is safe." -ForegroundColor Green
    if (-not $NoExit) { exit 0 }
    return 0
}
