# PowerShell script to configure Azure SQL Database
# Imports schema and grants managed identity permissions

param(
    [Parameter(Mandatory=$true)]
    [string]$SqlServer,
    
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$ManagedIdentityName,
    
    [Parameter(Mandatory=$true)]
    [string]$SchemaFile
)

Write-Host "=================================="
Write-Host "Configuring Azure SQL Database"
Write-Host "=================================="
Write-Host "SQL Server: $SqlServer"
Write-Host "Database: $DatabaseName"
Write-Host "Managed Identity: $ManagedIdentityName"
Write-Host ""

# Get Azure AD access token for SQL Database
Write-Host "Getting Azure AD access token..."
$token = az account get-access-token --resource https://database.windows.net --query accessToken -o tsv

if (-not $token) {
    Write-Error "Failed to get access token"
    exit 1
}

# Wait for SQL server to be ready
Write-Host "Waiting for SQL server to be ready..."
Start-Sleep -Seconds 30

# Test connection
Write-Host "Testing connection to SQL server..."
$testQuery = "SELECT @@VERSION"
try {
    $testQuery | sqlcmd -S $SqlServer -d $DatabaseName -G -P $token -b
    Write-Host "Connection successful!"
} catch {
    Write-Error "Failed to connect to SQL server: $_"
    exit 1
}

# Import database schema
Write-Host ""
Write-Host "Importing database schema from: $SchemaFile"
try {
    sqlcmd -S $SqlServer -d $DatabaseName -G -P $token -i $SchemaFile -b
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Schema imported successfully!"
    } else {
        Write-Warning "Schema import completed with warnings (exit code: $LASTEXITCODE)"
    }
} catch {
    Write-Error "Failed to import schema: $_"
    Write-Host ""
    Write-Host "Manual import command:"
    Write-Host "sqlcmd -S $SqlServer -d $DatabaseName -G -i $SchemaFile"
    exit 1
}

# Grant managed identity permissions
Write-Host ""
Write-Host "Granting managed identity access to database..."
$grantSql = @"
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$ManagedIdentityName')
BEGIN
    CREATE USER [$ManagedIdentityName] FROM EXTERNAL PROVIDER;
END

ALTER ROLE db_datareader ADD MEMBER [$ManagedIdentityName];
ALTER ROLE db_datawriter ADD MEMBER [$ManagedIdentityName];
ALTER ROLE db_ddladmin ADD MEMBER [$ManagedIdentityName];
"@

try {
    $grantSql | sqlcmd -S $SqlServer -d $DatabaseName -G -P $token -b
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Managed identity permissions granted successfully!"
    } else {
        Write-Warning "Permission grant completed with warnings (exit code: $LASTEXITCODE)"
    }
} catch {
    Write-Error "Failed to grant permissions: $_"
    Write-Host ""
    Write-Host "Manual grant command:"
    Write-Host $grantSql
    exit 1
}

Write-Host ""
Write-Host "=================================="
Write-Host "Database Configuration Complete!"
Write-Host "=================================="
