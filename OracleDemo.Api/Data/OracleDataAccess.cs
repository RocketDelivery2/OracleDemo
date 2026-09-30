using Oracle.ManagedDataAccess.Client;

namespace OracleDemo.Api.Data;

public class OracleDataAccess : IOracleDataAccess
{
    private readonly ILogger<OracleDataAccess> _logger;
    private readonly string _connectionString;

    public OracleDataAccess(ILogger<OracleDataAccess> logger, IConfiguration configuration)
    {
        _logger = logger;
        _connectionString = BuildConnectionString(configuration);
    }

    public async Task<OracleInfoResult> GetOracleInfoAsync(CancellationToken cancellationToken = default)
    {
        using var connection = new OracleConnection(_connectionString);

        try
        {
            await connection.OpenAsync(cancellationToken);

            using var command = connection.CreateCommand();
            command.CommandText = @"
                SELECT
                    USER AS current_user,
                    SYS_CONTEXT('USERENV', 'CON_NAME') AS container_name,
                    SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS service_name,
                    SYSTIMESTAMP AS database_time
                FROM DUAL";

            using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (await reader.ReadAsync(cancellationToken))
            {
                return new OracleInfoResult
                {
                    CurrentUser = reader.GetString(0) ?? string.Empty,
                    ContainerName = reader.GetString(1) ?? string.Empty,
                    ServiceName = reader.GetString(2) ?? string.Empty,
                    DatabaseTime = reader.GetDateTime(3)
                };
            }

            throw new InvalidOperationException("No data returned from Oracle");
        }
        catch (OracleException ex)
        {
            _logger.LogError(ex, "Oracle database error");
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error accessing Oracle");
            throw;
        }
    }

    private string BuildConnectionString(IConfiguration configuration)
    {
        var oracleConfig = configuration.GetSection("Oracle");
        var dataSource = oracleConfig["DataSource"] ?? "127.0.0.1:1521/FREEPDB1";
        var userId = oracleConfig["UserId"] ?? "ORACLE_EQUITY_LAB";

        var secret = Environment.GetEnvironmentVariable("ORACLE_EQUITY_LAB_CREDENTIAL")
            ?? throw new InvalidOperationException("ORACLE_EQUITY_LAB_CREDENTIAL environment variable not set");

        var builder = new OracleConnectionStringBuilder
        {
            DataSource = dataSource,
            UserID = userId
        };
        builder.Password = secret;
        builder.Pooling = false;

        return builder.ToString();
    }
}
