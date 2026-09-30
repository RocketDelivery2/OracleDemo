namespace OracleDemo.Api.Models;

public class OracleInfoResponse
{
    public string CurrentUser { get; set; } = string.Empty;
    public string ContainerName { get; set; } = string.Empty;
    public string ServiceName { get; set; } = string.Empty;
    public DateTime DatabaseTime { get; set; }
}
