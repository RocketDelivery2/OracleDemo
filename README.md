# OracleDemo

A hands-on Oracle AI Database 26ai and ASP.NET Core .NET 8 demo project demonstrating Oracle database development, C# integration, schema design, and practical Oracle development patterns.

## Overview

This project demonstrates:
- **Oracle Database Project** for Visual Studio (schema design, SQL, and database metadata)
- **ASP.NET Core .NET 8 Web API** with Oracle connectivity using ODP.NET
- **SQL and PL/SQL** development in Oracle
- **ODP.NET / Oracle.ManagedDataAccess.Core** for data access
- **Oracle Developer Tools for Visual Studio** integration
- Practical patterns for Oracle database work from .NET applications

The solution is **fully runnable with F5 / Start** from Visual Studio or via `dotnet run` from PowerShell.

## Solution Structure

```
OracleDemo
├── OracleDemo/              - Oracle Database Project (schema definitions)
├── OracleDemo.Api/          - ASP.NET Core .NET 8 Web API
└── OracleDemo.Tests/        - xUnit test project
```

## Running the Application

### Prerequisites

- .NET 8 SDK installed
- Oracle AI Database 26ai Free running locally on 127.0.0.1:1521/FREEPDB1
- Local Oracle credentials configured

### Set the Environment Variable

Before running the API, configure the Oracle connection secret as an environment variable:

```powershell
# PowerShell: set the connection secret before running the API
# The API will look for this environment variable at runtime
$env:ORACLE_EQUITY_LAB_CREDENTIAL = "<your-oracle-connection-secret>"

# Then run the API from the solution root or the API directory
dotnet run --project OracleDemo.Api
```

> Note: Refer to the C# source code to see the exact environment variable name the API expects.

### Run in Visual Studio

1. Open `OracleDemo.slnx` in Visual Studio 2022
2. Set **OracleDemo.Api** as the startup project (if not already set)
3. Press **F5** to build and run
4. The API will start on `http://localhost:5270`

### API Endpoints

#### GET `/health`

Health check endpoint (does not require Oracle connection).

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-09-30T02:02:48.7130909Z"
}
```

**Example:**
```powershell
Invoke-WebRequest -Uri "http://localhost:5270/health"
```

#### GET `/api/oracle/info`

Returns information about the connected Oracle database. Requires the Oracle credential environment variable to be set.

**Response:**
```json
{
  "currentUser": "ORACLE_EQUITY_LAB",
  "containerName": "FREEPDB1",
  "serviceName": "freepdb1",
  "databaseTime": "2026-09-30T02:02:49"
}
```

**Example:**
```powershell
Invoke-WebRequest -Uri "http://localhost:5270/api/oracle/info"
```

If Oracle is not connected or the password is not set, you will receive a 500 error without exposing the password or connection string details.

## Build and Test

```powershell
# Restore NuGet packages
dotnet restore

# Build the solution
dotnet build OracleDemo.Api/OracleDemo.Api.csproj
dotnet build OracleDemo.Tests/OracleDemo.Tests.csproj

# Run tests
dotnet test OracleDemo.Tests/OracleDemo.Tests.csproj
```

## Database Connection Details

The API connects to Oracle using:

- **Host:** 127.0.0.1
- **Port:** 1521
- **Service Name:** FREEPDB1
- **User ID:** ORACLE_EQUITY_LAB
- **Credential:** Loaded from environment variable at runtime (see source code for variable name)

**Configuration is safe:**
- Passwords are **never** committed to version control
- `appsettings.json` contains only safe, non-secret values (host, port, user ID)
- The password must be supplied via the environment variable at runtime
- No credentials are logged or exposed in error messages

## Oracle Developer Tools

SQL scripts can be executed against the Oracle Database Project using **Oracle Developer Tools for Visual Studio**.

## Security

This project follows strict security practices:

- **Credentials are never committed to source control.** All passwords, API keys, and connection strings with secrets are excluded from Git.
- **Never commit `.env` files, passwords, API keys, or private keys.**
- A pre-commit hook (`scripts/Test-Secrets.ps1`) scans staged files for secret patterns before allowing commits.
- After cloning, configure the hook by running:
  ```powershell
  git config core.hooksPath .githooks
  ```

## License

This project is provided as-is for educational purposes.
