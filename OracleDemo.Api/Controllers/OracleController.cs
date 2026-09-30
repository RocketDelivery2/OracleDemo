using Microsoft.AspNetCore.Mvc;
using OracleDemo.Api.Data;
using OracleDemo.Api.Models;

namespace OracleDemo.Api.Controllers;

[ApiController]
[Route("api/oracle")]
public class OracleController : ControllerBase
{
    private readonly IOracleDataAccess _oracleDataAccess;
    private readonly ILogger<OracleController> _logger;

    public OracleController(IOracleDataAccess oracleDataAccess, ILogger<OracleController> logger)
    {
        _oracleDataAccess = oracleDataAccess;
        _logger = logger;
    }

    [HttpGet("info")]
    public async Task<ActionResult<OracleInfoResponse>> GetInfo(CancellationToken cancellationToken)
    {
        try
        {
            var result = await _oracleDataAccess.GetOracleInfoAsync(cancellationToken);
            return Ok(new OracleInfoResponse
            {
                CurrentUser = result.CurrentUser,
                ContainerName = result.ContainerName,
                ServiceName = result.ServiceName,
                DatabaseTime = result.DatabaseTime
            });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogError("Oracle configuration error: {Message}", ex.Message);
            return StatusCode(500, new { error = "Oracle database configuration error" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error querying Oracle");
            return StatusCode(500, new { error = "Database connection failed" });
        }
    }
}
