using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using ExpenseManagementApp.Services;

namespace ExpenseManagementApp.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly DatabaseService _databaseService;

    public string? ErrorMessage { get; set; }

    public IndexModel(ILogger<IndexModel> logger, DatabaseService databaseService)
    {
        _logger = logger;
        _databaseService = databaseService;
    }

    public void OnGet()
    {
        ErrorMessage = _databaseService.GetConnectionError();
    }
}
