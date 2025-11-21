using Azure.Core;
using Azure.Identity;
using Microsoft.Data.SqlClient;
using ExpenseManagementApp.Models;

namespace ExpenseManagementApp.Services
{
    public class DatabaseService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<DatabaseService> _logger;
        private string? _connectionError;
        private bool _isConnected = false;

        public DatabaseService(IConfiguration configuration, ILogger<DatabaseService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        private async Task<SqlConnection> GetConnectionAsync()
        {
            var connectionString = _configuration["SQL_CONNECTION_STRING"];
            var managedIdentityClientId = _configuration["MANAGED_IDENTITY_CLIENT_ID"];

            if (string.IsNullOrEmpty(connectionString) || string.IsNullOrEmpty(managedIdentityClientId))
            {
                _connectionError = "Database configuration not found. Please ensure SQL_CONNECTION_STRING and MANAGED_IDENTITY_CLIENT_ID are set.";
                _logger.LogError(_connectionError);
                throw new InvalidOperationException(_connectionError);
            }

            var connection = new SqlConnection(connectionString);

            try
            {
                var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
                {
                    ManagedIdentityClientId = managedIdentityClientId
                });

                var tokenRequestContext = new TokenRequestContext(new[] { "https://database.windows.net/.default" });
                var token = await credential.GetTokenAsync(tokenRequestContext);
                connection.AccessToken = token.Token;

                await connection.OpenAsync();
                _isConnected = true;
                _connectionError = null;
                return connection;
            }
            catch (Exception ex)
            {
                _isConnected = false;
                _connectionError = $"Database connection failed: {ex.Message} (DatabaseService.cs:GetConnectionAsync)";
                _logger.LogError(ex, "Failed to connect to database");
                throw;
            }
        }

        public string? GetConnectionError()
        {
            return _connectionError;
        }

        public bool IsConnected()
        {
            return _isConnected;
        }

        public async Task<List<Expense>> GetAllExpensesAsync()
        {
            try
            {
                using var connection = await GetConnectionAsync();
                using var command = new SqlCommand(@"
                    SELECT 
                        e.ExpenseId,
                        u.UserName,
                        c.CategoryName,
                        e.AmountMinor,
                        e.Currency,
                        e.ExpenseDate,
                        e.Description,
                        s.StatusName,
                        e.SubmittedAt
                    FROM dbo.Expenses e
                    JOIN dbo.Users u ON e.UserId = u.UserId
                    JOIN dbo.ExpenseCategories c ON e.CategoryId = c.CategoryId
                    JOIN dbo.ExpenseStatus s ON e.StatusId = s.StatusId
                    ORDER BY e.ExpenseDate DESC
                ", connection);

                var expenses = new List<Expense>();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    expenses.Add(new Expense
                    {
                        ExpenseId = reader.GetInt32(0),
                        UserName = reader.GetString(1),
                        CategoryName = reader.GetString(2),
                        AmountMinor = reader.GetInt32(3),
                        Currency = reader.GetString(4),
                        ExpenseDate = reader.GetDateTime(5),
                        Description = reader.IsDBNull(6) ? null : reader.GetString(6),
                        StatusName = reader.GetString(7),
                        SubmittedAt = reader.IsDBNull(8) ? null : reader.GetDateTime(8)
                    });
                }

                return expenses;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get expenses");
                _connectionError = $"Failed to retrieve expenses: {ex.Message} (DatabaseService.cs:GetAllExpensesAsync)";
                return GetDummyExpenses();
            }
        }

        public async Task<List<Expense>> GetPendingExpensesAsync()
        {
            try
            {
                using var connection = await GetConnectionAsync();
                using var command = new SqlCommand(@"
                    SELECT 
                        e.ExpenseId,
                        u.UserName,
                        c.CategoryName,
                        e.AmountMinor,
                        e.Currency,
                        e.ExpenseDate,
                        e.Description,
                        e.SubmittedAt
                    FROM dbo.Expenses e
                    JOIN dbo.Users u ON e.UserId = u.UserId
                    JOIN dbo.ExpenseCategories c ON e.CategoryId = c.CategoryId
                    JOIN dbo.ExpenseStatus s ON e.StatusId = s.StatusId
                    WHERE s.StatusName = 'Submitted'
                    ORDER BY e.SubmittedAt ASC
                ", connection);

                var expenses = new List<Expense>();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    expenses.Add(new Expense
                    {
                        ExpenseId = reader.GetInt32(0),
                        UserName = reader.GetString(1),
                        CategoryName = reader.GetString(2),
                        AmountMinor = reader.GetInt32(3),
                        Currency = reader.GetString(4),
                        ExpenseDate = reader.GetDateTime(5),
                        Description = reader.IsDBNull(6) ? null : reader.GetString(6),
                        SubmittedAt = reader.IsDBNull(7) ? null : reader.GetDateTime(7),
                        StatusName = "Submitted"
                    });
                }

                return expenses;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get pending expenses");
                _connectionError = $"Failed to retrieve pending expenses: {ex.Message} (DatabaseService.cs:GetPendingExpensesAsync)";
                return GetDummyExpenses().Where(e => e.StatusName == "Submitted").ToList();
            }
        }

        public async Task<List<ExpenseCategory>> GetCategoriesAsync()
        {
            try
            {
                using var connection = await GetConnectionAsync();
                using var command = new SqlCommand(@"
                    SELECT CategoryId, CategoryName
                    FROM dbo.ExpenseCategories
                    WHERE IsActive = 1
                    ORDER BY CategoryName
                ", connection);

                var categories = new List<ExpenseCategory>();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    categories.Add(new ExpenseCategory
                    {
                        CategoryId = reader.GetInt32(0),
                        CategoryName = reader.GetString(1),
                        IsActive = true
                    });
                }

                return categories;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get categories");
                _connectionError = $"Failed to retrieve categories: {ex.Message} (DatabaseService.cs:GetCategoriesAsync)";
                return GetDummyCategories();
            }
        }

        public async Task<int> CreateExpenseAsync(CreateExpenseRequest request)
        {
            try
            {
                using var connection = await GetConnectionAsync();
                using var command = new SqlCommand(@"
                    INSERT INTO dbo.Expenses (UserId, CategoryId, StatusId, AmountMinor, Currency, ExpenseDate, Description, CreatedAt)
                    VALUES (
                        (SELECT TOP 1 UserId FROM dbo.Users WHERE RoleId = (SELECT RoleId FROM dbo.Roles WHERE RoleName = 'Employee')),
                        @categoryId,
                        (SELECT StatusId FROM dbo.ExpenseStatus WHERE StatusName = 'Draft'),
                        @amountMinor,
                        'GBP',
                        @date,
                        @description,
                        SYSUTCDATETIME()
                    );
                    SELECT SCOPE_IDENTITY();
                ", connection);

                command.Parameters.AddWithValue("@categoryId", request.Category);
                command.Parameters.AddWithValue("@amountMinor", (int)(request.Amount * 100));
                command.Parameters.AddWithValue("@date", request.Date);
                command.Parameters.AddWithValue("@description", (object?)request.Description ?? DBNull.Value);

                var result = await command.ExecuteScalarAsync();
                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create expense");
                _connectionError = $"Failed to create expense: {ex.Message} (DatabaseService.cs:CreateExpenseAsync)";
                throw;
            }
        }

        public async Task SubmitExpenseAsync(int expenseId)
        {
            try
            {
                using var connection = await GetConnectionAsync();
                using var command = new SqlCommand(@"
                    UPDATE dbo.Expenses
                    SET StatusId = (SELECT StatusId FROM dbo.ExpenseStatus WHERE StatusName = 'Submitted'),
                        SubmittedAt = SYSUTCDATETIME()
                    WHERE ExpenseId = @expenseId
                ", connection);

                command.Parameters.AddWithValue("@expenseId", expenseId);
                await command.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to submit expense");
                _connectionError = $"Failed to submit expense: {ex.Message} (DatabaseService.cs:SubmitExpenseAsync)";
                throw;
            }
        }

        public async Task ApproveExpenseAsync(int expenseId)
        {
            try
            {
                using var connection = await GetConnectionAsync();
                using var command = new SqlCommand(@"
                    UPDATE dbo.Expenses
                    SET StatusId = (SELECT StatusId FROM dbo.ExpenseStatus WHERE StatusName = 'Approved'),
                        ReviewedBy = (SELECT TOP 1 UserId FROM dbo.Users WHERE RoleId = (SELECT RoleId FROM dbo.Roles WHERE RoleName = 'Manager')),
                        ReviewedAt = SYSUTCDATETIME()
                    WHERE ExpenseId = @expenseId
                ", connection);

                command.Parameters.AddWithValue("@expenseId", expenseId);
                await command.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to approve expense");
                _connectionError = $"Failed to approve expense: {ex.Message} (DatabaseService.cs:ApproveExpenseAsync)";
                throw;
            }
        }

        public async Task RejectExpenseAsync(int expenseId)
        {
            try
            {
                using var connection = await GetConnectionAsync();
                using var command = new SqlCommand(@"
                    UPDATE dbo.Expenses
                    SET StatusId = (SELECT StatusId FROM dbo.ExpenseStatus WHERE StatusName = 'Rejected'),
                        ReviewedBy = (SELECT TOP 1 UserId FROM dbo.Users WHERE RoleId = (SELECT RoleId FROM dbo.Roles WHERE RoleName = 'Manager')),
                        ReviewedAt = SYSUTCDATETIME()
                    WHERE ExpenseId = @expenseId
                ", connection);

                command.Parameters.AddWithValue("@expenseId", expenseId);
                await command.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to reject expense");
                _connectionError = $"Failed to reject expense: {ex.Message} (DatabaseService.cs:RejectExpenseAsync)";
                throw;
            }
        }

        private List<Expense> GetDummyExpenses()
        {
            return new List<Expense>
            {
                new Expense
                {
                    ExpenseId = 1,
                    UserName = "Alice Example",
                    CategoryName = "Travel",
                    AmountMinor = 2540,
                    Currency = "GBP",
                    ExpenseDate = DateTime.Now.AddDays(-7),
                    Description = "Taxi from airport to client site",
                    StatusName = "Submitted",
                    SubmittedAt = DateTime.Now.AddDays(-7)
                },
                new Expense
                {
                    ExpenseId = 2,
                    UserName = "Alice Example",
                    CategoryName = "Meals",
                    AmountMinor = 1425,
                    Currency = "GBP",
                    ExpenseDate = DateTime.Now.AddDays(-15),
                    Description = "Client lunch meeting",
                    StatusName = "Approved",
                    SubmittedAt = DateTime.Now.AddDays(-15)
                },
                new Expense
                {
                    ExpenseId = 3,
                    UserName = "Alice Example",
                    CategoryName = "Supplies",
                    AmountMinor = 799,
                    Currency = "GBP",
                    ExpenseDate = DateTime.Now.AddDays(-2),
                    Description = "Office stationery",
                    StatusName = "Draft"
                }
            };
        }

        private List<ExpenseCategory> GetDummyCategories()
        {
            return new List<ExpenseCategory>
            {
                new ExpenseCategory { CategoryId = 1, CategoryName = "Travel", IsActive = true },
                new ExpenseCategory { CategoryId = 2, CategoryName = "Meals", IsActive = true },
                new ExpenseCategory { CategoryId = 3, CategoryName = "Supplies", IsActive = true },
                new ExpenseCategory { CategoryId = 4, CategoryName = "Accommodation", IsActive = true },
                new ExpenseCategory { CategoryId = 5, CategoryName = "Other", IsActive = true }
            };
        }
    }
}
