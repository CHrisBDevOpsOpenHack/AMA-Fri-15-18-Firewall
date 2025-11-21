const express = require('express');
const path = require('path');
const rateLimit = require('express-rate-limit');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 8080;

// Rate limiting for API endpoints
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

// Rate limiting for static pages
const pageLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 500, // Limit each IP to 500 page views per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

// Apply rate limiting to API routes
app.use('/api/', apiLimiter);

// Initialize database connection
db.initializeConnection().catch(err => {
  console.error('Failed to initialize database:', err);
});

// Helper function to format amount in GBP
function formatAmount(amountMinor) {
  return `£${(amountMinor / 100).toFixed(2)}`;
}

// API Routes

// Get all expenses
app.get('/api/expenses', async (req, res) => {
  const result = await db.query(`
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
  `);

  if (result.success) {
    res.json({ 
      success: true, 
      data: result.data,
      error: null 
    });
  } else {
    // Return dummy data on error
    res.json({ 
      success: false, 
      data: db.getDummyData('expenses'),
      error: db.getConnectionError()
    });
  }
});

// Get pending expenses for approval
app.get('/api/expenses/pending', async (req, res) => {
  const result = await db.query(`
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
  `);

  if (result.success) {
    res.json({ 
      success: true, 
      data: result.data,
      error: null 
    });
  } else {
    // Return dummy data filtered for submitted status
    const dummyExpenses = db.getDummyData('expenses').filter(e => e.StatusName === 'Submitted');
    res.json({ 
      success: false, 
      data: dummyExpenses,
      error: db.getConnectionError()
    });
  }
});

// Get expense categories
app.get('/api/categories', async (req, res) => {
  const result = await db.query(`
    SELECT CategoryId, CategoryName
    FROM dbo.ExpenseCategories
    WHERE IsActive = 1
    ORDER BY CategoryName
  `);

  if (result.success) {
    res.json({ 
      success: true, 
      data: result.data,
      error: null 
    });
  } else {
    res.json({ 
      success: false, 
      data: db.getDummyData('categories'),
      error: db.getConnectionError()
    });
  }
});

// Create new expense
app.post('/api/expenses', async (req, res) => {
  const { amount, date, category, description } = req.body;

  // Convert amount to minor units (pence)
  const amountMinor = Math.round(parseFloat(amount) * 100);

  const result = await db.query(`
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
    SELECT SCOPE_IDENTITY() AS ExpenseId;
  `, {
    categoryId: category,
    amountMinor: amountMinor,
    date: date,
    description: description
  });

  if (result.success) {
    res.json({ 
      success: true, 
      message: 'Expense created successfully',
      expenseId: result.data[0]?.ExpenseId,
      error: null
    });
  } else {
    res.json({ 
      success: false, 
      message: 'Failed to create expense (using demo mode)',
      error: db.getConnectionError()
    });
  }
});

// Submit expense
app.post('/api/expenses/:id/submit', async (req, res) => {
  const { id } = req.params;

  const result = await db.query(`
    UPDATE dbo.Expenses
    SET StatusId = (SELECT StatusId FROM dbo.ExpenseStatus WHERE StatusName = 'Submitted'),
        SubmittedAt = SYSUTCDATETIME()
    WHERE ExpenseId = @expenseId
  `, { expenseId: id });

  if (result.success) {
    res.json({ 
      success: true, 
      message: 'Expense submitted successfully',
      error: null
    });
  } else {
    res.json({ 
      success: false, 
      message: 'Failed to submit expense (using demo mode)',
      error: db.getConnectionError()
    });
  }
});

// Approve expense
app.post('/api/expenses/:id/approve', async (req, res) => {
  const { id } = req.params;

  const result = await db.query(`
    UPDATE dbo.Expenses
    SET StatusId = (SELECT StatusId FROM dbo.ExpenseStatus WHERE StatusName = 'Approved'),
        ReviewedBy = (SELECT TOP 1 UserId FROM dbo.Users WHERE RoleId = (SELECT RoleId FROM dbo.Roles WHERE RoleName = 'Manager')),
        ReviewedAt = SYSUTCDATETIME()
    WHERE ExpenseId = @expenseId
  `, { expenseId: id });

  if (result.success) {
    res.json({ 
      success: true, 
      message: 'Expense approved successfully',
      error: null
    });
  } else {
    res.json({ 
      success: false, 
      message: 'Failed to approve expense (using demo mode)',
      error: db.getConnectionError()
    });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  const error = db.getConnectionError();
  res.json({
    status: error ? 'degraded' : 'healthy',
    database: error ? 'disconnected' : 'connected',
    error: error
  });
});

// Serve HTML pages with rate limiting
app.get('/', pageLimiter, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/approve', pageLimiter, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'approve.html'));
});

app.get('/add', pageLimiter, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'add.html'));
});

// Start server
app.listen(PORT, () => {
  console.log(`Expense Management System running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
