using Microsoft.AspNetCore.Mvc;
using OracleDemo.Api.Models;

namespace OracleDemo.Api.Controllers;

[ApiController]
[Route("health")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public ActionResult<HealthResponse> Get()
    {
        return Ok(new HealthResponse { Status = "ok" });
    }
}
