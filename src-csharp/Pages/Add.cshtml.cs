using Microsoft.AspNetCore.Mvc.RazorPages;
using ExpenseManagementApp.Services;

namespace ExpenseManagementApp.Pages;

public class AddModel : PageModel
{
    private readonly DatabaseService _databaseService;
    
    public string? ErrorMessage { get; set; }

    public AddModel(DatabaseService databaseService)
    {
        _databaseService = databaseService;
    }

    public void OnGet()
    {
        ErrorMessage = _databaseService.GetConnectionError();
    }
}
