using Microsoft.AspNetCore.Mvc;
using ExpenseManagementApp.Models;
using ExpenseManagementApp.Services;

namespace ExpenseManagementApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class CategoriesController : ControllerBase
    {
        private readonly DatabaseService _databaseService;
        private readonly ILogger<CategoriesController> _logger;

        public CategoriesController(DatabaseService databaseService, ILogger<CategoriesController> logger)
        {
            _databaseService = databaseService;
            _logger = logger;
        }

        /// <summary>
        /// Get all active expense categories
        /// </summary>
        /// <returns>List of expense categories</returns>
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<List<ExpenseCategory>>), 200)]
        public async Task<ActionResult<ApiResponse<List<ExpenseCategory>>>> GetCategories()
        {
            try
            {
                var categories = await _databaseService.GetCategoriesAsync();
                var error = _databaseService.GetConnectionError();
                
                return Ok(new ApiResponse<List<ExpenseCategory>>
                {
                    Success = error == null,
                    Data = categories,
                    Error = error
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting categories");
                return Ok(new ApiResponse<List<ExpenseCategory>>
                {
                    Success = false,
                    Data = new List<ExpenseCategory>(),
                    Error = $"Failed to retrieve categories: {ex.Message} (CategoriesController.cs:GetCategories)"
                });
            }
        }
    }
}
