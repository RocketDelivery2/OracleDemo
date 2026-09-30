# OracleDemo

A hands-on Oracle AI Database 26ai demo project for learning Oracle development, schema design, SQL, PL/SQL, Oracle Developer Tools for Visual Studio, and SQL Server-to-Oracle concepts.

## Overview

This is an Oracle Database Project for Visual Studio demonstrating:
- Oracle database schema design
- SQL and PL/SQL development
- Integration with Visual Studio tools
- Practical patterns for Oracle on Windows

Currently, this project is **not an executable C# application**. It is a database development project that can be opened in Visual Studio with Oracle Developer Tools for Visual Studio.

## Running SQL in Visual Studio

SQL scripts can be executed against a configured Oracle connection using Oracle Developer Tools for Visual Studio.

### Example Query

```sql
SELECT
    USER AS current_user,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS container_name,
    SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS service_name,
    SYSTIMESTAMP AS database_time
FROM DUAL;
```

## Connection Information

To connect to the demo database from Visual Studio:

- **Host:** 127.0.0.1
- **Port:** 1521
- **Service Name:** FREEPDB1
- **Username:** Provide your own local Oracle credentials
- **Password:** Provide your own local Oracle credentials

**Note:** Users must supply their own local Oracle database connection and credentials. No credentials are provided in this repository.

## Prerequisites

- Visual Studio 2022 or later
- Oracle Developer Tools for Visual Studio
- Oracle AI Database 26ai Free (or compatible Oracle database)
- Local Oracle database connection configured

## Project Structure

- `OracleDemo.oradbproj` - Oracle Database Project file
- `OracleDemo.slnx` - Visual Studio solution file

## Security

This project follows strict security practices:

- **Credentials are never committed to source control.** All passwords, API keys, and connection strings with secrets are excluded from Git.
- **Never commit .env files, passwords, API keys, or private keys.**
- The repository includes a pre-commit hook (`scripts/Test-Secrets.ps1`) that scans staged files for secret patterns before allowing commits.
- After cloning, configure the hook by running:
  ```powershell
  git config core.hooksPath .githooks
  ```

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/RocketDelivery2/OracleDemo.git
   ```

2. Configure the pre-commit hook:
   ```powershell
   git config core.hooksPath .githooks
   ```

3. Open `OracleDemo.slnx` in Visual Studio

4. Configure your Oracle connection in Visual Studio

5. Execute SQL scripts using the Oracle Developer Tools

## License

This project is provided as-is for educational purposes.
