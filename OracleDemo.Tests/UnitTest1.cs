using OracleDemo.Api.Models;

namespace OracleDemo.Tests;

public class HealthResponseTests
{
    [Fact]
    public void HealthResponse_DefaultsToOk()
    {
        var response = new HealthResponse();

        Assert.Equal("ok", response.Status);
    }

    [Fact]
    public void HealthResponse_TimestampIsPopulated()
    {
        var before = DateTime.UtcNow;
        var response = new HealthResponse();
        var after = DateTime.UtcNow;

        Assert.NotEqual(default, response.Timestamp);
        Assert.True(response.Timestamp >= before && response.Timestamp <= after.AddSeconds(1));
    }
}

public class OracleInfoResponseTests
{
    [Fact]
    public void OracleInfoResponse_PropertiesCanBeSet()
    {
        var response = new OracleInfoResponse
        {
            CurrentUser = "ORACLE_EQUITY_LAB",
            ContainerName = "FREEPDB1",
            ServiceName = "freepdb1",
            DatabaseTime = DateTime.UtcNow
        };

        Assert.Equal("ORACLE_EQUITY_LAB", response.CurrentUser);
        Assert.Equal("FREEPDB1", response.ContainerName);
        Assert.Equal("freepdb1", response.ServiceName);
        Assert.NotEqual(default, response.DatabaseTime);
    }
}