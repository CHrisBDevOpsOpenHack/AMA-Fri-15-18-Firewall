using Microsoft.AspNetCore.Mvc;
using ExpenseManagementApp.Models;
using ExpenseManagementApp.Services;

namespace ExpenseManagementApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class ExpensesController : ControllerBase
    {
        private readonly DatabaseService _databaseService;
        private readonly ILogger<ExpensesController> _logger;

        public ExpensesController(DatabaseService databaseService, ILogger<ExpensesController> logger)
        {
            _databaseService = databaseService;
            _logger = logger;
        }

        /// <summary>
        /// Get all expenses
        /// </summary>
        /// <returns>List of all expenses</returns>
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<List<Expense>>), 200)]
        public async Task<ActionResult<ApiResponse<List<Expense>>>> GetAllExpenses()
        {
            try
            {
                var expenses = await _databaseService.GetAllExpensesAsync();
                var error = _databaseService.GetConnectionError();
                
                return Ok(new ApiResponse<List<Expense>>
                {
                    Success = error == null,
                    Data = expenses,
                    Error = error
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all expenses");
                return Ok(new ApiResponse<List<Expense>>
                {
                    Success = false,
                    Data = new List<Expense>(),
                    Error = $"Failed to retrieve expenses: {ex.Message} (ExpensesController.cs:GetAllExpenses)"
                });
            }
        }

        /// <summary>
        /// Get pending expenses for approval
        /// </summary>
        /// <returns>List of expenses with 'Submitted' status</returns>
        [HttpGet("pending")]
        [ProducesResponseType(typeof(ApiResponse<List<Expense>>), 200)]
        public async Task<ActionResult<ApiResponse<List<Expense>>>> GetPendingExpenses()
        {
            try
            {
                var expenses = await _databaseService.GetPendingExpensesAsync();
                var error = _databaseService.GetConnectionError();
                
                return Ok(new ApiResponse<List<Expense>>
                {
                    Success = error == null,
                    Data = expenses,
                    Error = error
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting pending expenses");
                return Ok(new ApiResponse<List<Expense>>
                {
                    Success = false,
                    Data = new List<Expense>(),
                    Error = $"Failed to retrieve pending expenses: {ex.Message} (ExpensesController.cs:GetPendingExpenses)"
                });
            }
        }

        /// <summary>
        /// Create a new expense
        /// </summary>
        /// <param name="request">Expense details</param>
        /// <returns>Created expense ID</returns>
        [HttpPost]
        [ProducesResponseType(typeof(ApiResponse<int>), 200)]
        public async Task<ActionResult<ApiResponse<int>>> CreateExpense([FromBody] CreateExpenseRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new ApiResponse<int>
                {
                    Success = false,
                    Error = "Invalid request data"
                });
            }

            try
            {
                var expenseId = await _databaseService.CreateExpenseAsync(request);
                return Ok(new ApiResponse<int>
                {
                    Success = true,
                    Data = expenseId,
                    Message = "Expense created successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating expense");
                return Ok(new ApiResponse<int>
                {
                    Success = false,
                    Error = $"Failed to create expense: {ex.Message} (ExpensesController.cs:CreateExpense)",
                    Message = "Failed to create expense (using demo mode)"
                });
            }
        }

        /// <summary>
        /// Submit an expense for approval
        /// </summary>
        /// <param name="id">Expense ID</param>
        /// <returns>Success status</returns>
        [HttpPost("{id}/submit")]
        [ProducesResponseType(typeof(ApiResponse<object>), 200)]
        public async Task<ActionResult<ApiResponse<object>>> SubmitExpense(int id)
        {
            try
            {
                await _databaseService.SubmitExpenseAsync(id);
                return Ok(new ApiResponse<object>
                {
                    Success = true,
                    Message = "Expense submitted successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error submitting expense");
                return Ok(new ApiResponse<object>
                {
                    Success = false,
                    Error = $"Failed to submit expense: {ex.Message} (ExpensesController.cs:SubmitExpense)",
                    Message = "Failed to submit expense (using demo mode)"
                });
            }
        }

        /// <summary>
        /// Approve an expense
        /// </summary>
        /// <param name="id">Expense ID</param>
        /// <returns>Success status</returns>
        [HttpPost("{id}/approve")]
        [ProducesResponseType(typeof(ApiResponse<object>), 200)]
        public async Task<ActionResult<ApiResponse<object>>> ApproveExpense(int id)
        {
            try
            {
                await _databaseService.ApproveExpenseAsync(id);
                return Ok(new ApiResponse<object>
                {
                    Success = true,
                    Message = "Expense approved successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error approving expense");
                return Ok(new ApiResponse<object>
                {
                    Success = false,
                    Error = $"Failed to approve expense: {ex.Message} (ExpensesController.cs:ApproveExpense)",
                    Message = "Failed to approve expense (using demo mode)"
                });
            }
        }

        /// <summary>
        /// Reject an expense
        /// </summary>
        /// <param name="id">Expense ID</param>
        /// <returns>Success status</returns>
        [HttpPost("{id}/reject")]
        [ProducesResponseType(typeof(ApiResponse<object>), 200)]
        public async Task<ActionResult<ApiResponse<object>>> RejectExpense(int id)
        {
            try
            {
                await _databaseService.RejectExpenseAsync(id);
                return Ok(new ApiResponse<object>
                {
                    Success = true,
                    Message = "Expense rejected successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rejecting expense");
                return Ok(new ApiResponse<object>
                {
                    Success = false,
                    Error = $"Failed to reject expense: {ex.Message} (ExpensesController.cs:RejectExpense)",
                    Message = "Failed to reject expense (using demo mode)"
                });
            }
        }
    }
}
