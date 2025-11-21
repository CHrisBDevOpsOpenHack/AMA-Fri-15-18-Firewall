using System.ComponentModel.DataAnnotations;

namespace ExpenseManagementApp.Models
{
    public class CreateExpenseRequest
    {
        [Required]
        [Range(0.01, 999999.99, ErrorMessage = "Amount must be between £0.01 and £999,999.99")]
        public decimal Amount { get; set; }
        
        [Required]
        public DateTime Date { get; set; }
        
        [Required]
        public int Category { get; set; }
        
        [MaxLength(1000)]
        public string? Description { get; set; }
    }
}
