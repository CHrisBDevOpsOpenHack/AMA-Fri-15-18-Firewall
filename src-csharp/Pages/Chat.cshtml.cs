using Microsoft.AspNetCore.Mvc.RazorPages;
using ExpenseManagementApp.Services;

namespace ExpenseManagementApp.Pages;

public class ChatModel : PageModel
{
    private readonly IConfiguration _configuration;
    
    public string? ErrorMessage { get; set; }

    public ChatModel(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public void OnGet()
    {
        // Check if GenAI is configured
        var openAIEndpoint = _configuration["OpenAI__Endpoint"];
        if (string.IsNullOrEmpty(openAIEndpoint))
        {
            ErrorMessage = "GenAI services are not yet configured. Run deploy-with-chat.sh to enable full AI chat capabilities. The chat will work with limited functionality.";
        }
    }
}
