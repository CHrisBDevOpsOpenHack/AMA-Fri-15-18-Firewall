namespace ExpenseManagementApp.Models
{
    public class Expense
    {
        public int ExpenseId { get; set; }
        public int UserId { get; set; }
        public int CategoryId { get; set; }
        public int StatusId { get; set; }
        public int AmountMinor { get; set; }
        public string Currency { get; set; } = "GBP";
        public DateTime ExpenseDate { get; set; }
        public string? Description { get; set; }
        public string? ReceiptFile { get; set; }
        public DateTime? SubmittedAt { get; set; }
        public int? ReviewedBy { get; set; }
        public DateTime? ReviewedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        
        // Navigation properties
        public string? UserName { get; set; }
        public string? CategoryName { get; set; }
        public string? StatusName { get; set; }
        
        public decimal AmountGBP => AmountMinor / 100.0m;
        public string FormattedAmount => $"£{AmountGBP:F2}";
    }
}
