#Variable Section
{
    $ResourceGroupName = 'AzureLearning'
    $Location = 'EastUS'
    $SQLServerName = 'aslsoftSQLServer'
    $DBName = 'MyDB'
    $KeyVaultName = 'aslsoftSecureKeyVault'
    $dbconnectionstring = 'dbconnection'
}

Login-AzureRMAccount

Get-AzureRmSubscription

Select-AzureRmSubscription -Subscription 'xxxxxxxxxxxxxxxaaaaaaaaaaaaa'

Get-AzureRmResourceGroup

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


New-AzureRmKeyVault -Name $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $Location -Sku Standard

$secretvalue = ConvertTo-SecureString -String 'Server=tcp:aslsoftsqlserver.database.windows.net,1433;Initial Catalog=MyDB;Persist Security Info=False;User ID=dbadmin;Password=Password123;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;' -AsPlainText -Force

$secret = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $dbconnectionstring -SecretValue $secretvalue 

#Section to create table and write some data to table in Azure SQL

$connection = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $dbconnectionstring).SecretValueText

$ser = New-Object System.Data.SqlClient.SqlConnection($connection)

$ser.Open()

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
    
$cmd= New-Object System.Data.SqlClient.SqlCommand($query,$ser)

$cmd.ExecuteNonQuery()

$ser.Close()
    
