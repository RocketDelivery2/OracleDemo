namespace OracleDemo.Api.Data;

public interface IOracleDataAccess
{
    Task<OracleInfoResult> GetOracleInfoAsync(CancellationToken cancellationToken = default);
}

public class OracleInfoResult
{
    public string CurrentUser { get; set; } = string.Empty;
    public string ContainerName { get; set; } = string.Empty;
    public string ServiceName { get; set; } = string.Empty;
    public DateTime DatabaseTime { get; set; }
}
