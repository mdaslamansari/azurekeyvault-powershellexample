#Variable Section
$ResourceGroupName = 'AzureLearning'
$Location = 'EastUS'
$SQLServerName = 'aslsoftsqlserver'
$DBName = 'MyDB'
$KeyVaultName = 'aslsoftSecureKeyVault'
$dbconnectionstring = 'dbconnection'

#Login-AzureRMAccount #This is to login to the Azure Account

Get-AzureRmSubscription #This will get the list of all your subscriptions

Select-AzureRmSubscription -Subscription 'aaaaaaaaabbbbxxxxxxxxxxx' #This will select the required subscription which will be used

Get-AzureRmResourceGroup #This is just to get the already available resource groups

New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -Force #It will create Resource Group

#It will create SQL Server
New-AzureRmSqlServer -ServerName $SQLServerName `
                     -ResourceGroupName $ResourceGroupName `
                     -Location $Location `
                     -ServerVersion '12.0' `
                     -SqlAdministratorCredentials (Get-Credential) `
                     -Verbose

#It will create SQL Database
New-AzureRmSqlDatabase -DatabaseName $DBName `
                       -ServerName $SQLServerName `
                       -ResourceGroupName $ResourceGroupName `
                       -Verbose

#It will create firewall rule for specific range of IP address on the database server
New-AzureRmSqlServerFirewallRule -ServerName $SQLServerName -FirewallRuleName 'dbfirewall' -ResourceGroupName $ResourceGroupName -StartIpAddress '10.10.10.10' -EndIpAddress '10.10.10.20' -Verbose

#It will create firewall rule for all IP address on the database server
New-AzureRmSqlServerFirewallRule -ServerName $SQLServerName -ResourceGroupName $ResourceGroupName -AllowAllAzureIPs 

New-AzureRmKeyVault -Name $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $Location -Sku Standard #It will create Key Vault in Azure

#Below two commands will create a secret value for the database connection string and will add it to the Azure key vault as a secret.
#Once done, we do not need to keep connection string (sensitive information) in the script to connect to the database.
$secretvalue = ConvertTo-SecureString -String 'Server=tcp:aslsoftsqlserver.database.windows.net,1433;Initial Catalog=MyDB;Persist Security Info=False;User ID=dbadmin;Password=Password123;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;' -AsPlainText -Force

Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $dbconnectionstring -SecretValue $secretvalue 

#Section to create table and write some data to table in Azure SQL

$connection = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $dbconnectionstring).SecretValueText #This line is reading Azure key vault for the database connection string (secret)

$conn = New-Object System.Data.SqlClient.SqlConnection($connection)

$conn.Open() #Database connection established 

#I wrote query here and it can be imported from sql script file.
$query = @"
            Create Table tblProduct
            (
                ID int IDENTITY(1,1) PRIMARY KEY,
                ProductName varchar(50) NOT NULL,
                Quantity int
            )

            Insert into tblProduct (ProductName,Quantity)
            Values ('iPhone',1)
"@
    
$cmd= New-Object System.Data.SqlClient.SqlCommand($query,$conn)

$cmd.ExecuteNonQuery() #Database query executed

$conn.Close() #Database connection closed 
    
