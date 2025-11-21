using Microsoft.AspNetCore.Mvc;
using ExpenseManagementApp.Services;

namespace ExpenseManagementApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class HealthController : ControllerBase
    {
        private readonly DatabaseService _databaseService;

        public HealthController(DatabaseService databaseService)
        {
            _databaseService = databaseService;
        }

        /// <summary>
        /// Health check endpoint
        /// </summary>
        /// <returns>Health status of the application and database</returns>
        [HttpGet]
        [ProducesResponseType(typeof(object), 200)]
        public ActionResult<object> GetHealth()
        {
            var error = _databaseService.GetConnectionError();
            return Ok(new
            {
                status = error != null ? "degraded" : "healthy",
                database = error != null ? "disconnected" : "connected",
                error = error
            });
        }
    }
}
