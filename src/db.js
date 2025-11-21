// Database connection module with managed identity support and error handling
// Following prompt-008 requirements

const sql = require('mssql');
const { DefaultAzureCredential, ManagedIdentityCredential } = require('@azure/identity');

let pool = null;
let connectionError = null;

// Dummy data for fallback when database is unavailable
const dummyData = {
  expenses: [
    {
      ExpenseId: 1,
      UserName: 'Demo User',
      CategoryName: 'Travel',
      AmountMinor: 2540,
      Currency: 'GBP',
      ExpenseDate: '2025-10-20',
      Description: 'Taxi from airport to client site',
      StatusName: 'Submitted',
      SubmittedAt: new Date().toISOString()
    },
    {
      ExpenseId: 2,
      UserName: 'Demo User',
      CategoryName: 'Meals',
      AmountMinor: 1425,
      Currency: 'GBP',
      ExpenseDate: '2025-09-15',
      Description: 'Client lunch meeting',
      StatusName: 'Approved',
      SubmittedAt: new Date().toISOString()
    },
    {
      ExpenseId: 3,
      UserName: 'Demo User',
      CategoryName: 'Supplies',
      AmountMinor: 799,
      Currency: 'GBP',
      ExpenseDate: '2025-11-01',
      Description: 'Office stationery',
      StatusName: 'Draft',
      SubmittedAt: null
    }
  ],
  categories: [
    { CategoryId: 1, CategoryName: 'Travel' },
    { CategoryId: 2, CategoryName: 'Meals' },
    { CategoryId: 3, CategoryName: 'Supplies' },
    { CategoryId: 4, CategoryName: 'Accommodation' },
    { CategoryId: 5, CategoryName: 'Other' }
  ],
  statuses: [
    { StatusId: 1, StatusName: 'Draft' },
    { StatusId: 2, StatusName: 'Submitted' },
    { StatusId: 3, StatusName: 'Approved' },
    { StatusId: 4, StatusName: 'Rejected' }
  ]
};

async function initializeConnection() {
  try {
    const connectionString = process.env.SQL_CONNECTION_STRING;
    const managedIdentityClientId = process.env.MANAGED_IDENTITY_CLIENT_ID;

    if (!connectionString) {
      throw new Error('SQL_CONNECTION_STRING environment variable not set');
    }

    // Parse connection string
    const serverMatch = connectionString.match(/Server=tcp:([^,;]+)/i);
    const databaseMatch = connectionString.match(/(?:Initial Catalog|Database)=([^;]+)/i);

    if (!serverMatch || !databaseMatch) {
      throw new Error('Invalid connection string format');
    }

    const config = {
      server: serverMatch[1],
      database: databaseMatch[1],
      authentication: {
        type: 'azure-active-directory-msi-app-service',
        options: {
          clientId: managedIdentityClientId
        }
      },
      options: {
        encrypt: true,
        trustServerCertificate: false,
        connectTimeout: 30000
      }
    };

    pool = await sql.connect(config);
    connectionError = null;
    console.log('Database connection established successfully');
    return true;
  } catch (error) {
    connectionError = {
      message: error.message,
      location: 'db.js:initializeConnection',
      timestamp: new Date().toISOString()
    };
    console.error('Database connection failed:', error);
    return false;
  }
}

async function query(sqlQuery, params = {}) {
  try {
    if (!pool) {
      await initializeConnection();
    }

    if (!pool) {
      throw new Error('Database connection not available');
    }

    const request = pool.request();
    
    // Add parameters
    for (const [key, value] of Object.entries(params)) {
      request.input(key, value);
    }

    const result = await request.query(sqlQuery);
    return { success: true, data: result.recordset };
  } catch (error) {
    connectionError = {
      message: error.message,
      location: 'db.js:query',
      timestamp: new Date().toISOString()
    };
    console.error('Query failed:', error);
    return { success: false, error: connectionError };
  }
}

function getConnectionError() {
  return connectionError;
}

function getDummyData(type) {
  return dummyData[type] || [];
}

module.exports = {
  initializeConnection,
  query,
  getConnectionError,
  getDummyData,
  sql
};
