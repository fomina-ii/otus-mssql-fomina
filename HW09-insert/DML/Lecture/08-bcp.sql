---cmd---
--1. CREATE Folder BCP
--2. bcp WideWorldImporters.Warehouse.Colors out "E:\BCP\WideWorldImporters.Warehouse.Colors_Copy.txt" -c -T
--bcp WideWorldImporters.Warehouse.Colors OUT "E:\BCP\demo.txt" -T -S Diabloalex666\SQLEXPRESS -c
--3. 
--DROP TABLE IF EXISTS WideWorldImporters.Warehouse.Color_Copy;
--SELECT * INTO WideWorldImporters.Warehouse.Color_Copy FROM WideWorldImporters.Warehouse.Colors
--WHERE 1 = 2; 
--4. 'bcp WideWorldImporters.Warehouse.Color_Copy IN "E:\BCP\demo.txt" -T -S Diabloalex666\SQLEXPRESS -c
--SELECT *
--FROM WideWorldImporters.Warehouse.Color_Copy;

/*
Msg 15281, Level 16, State 1, Procedure master..xp_cmdshell, Line 1 [Batch Start Line 0]
SQL Server blocked access to procedure 'sys.xp_cmdshell' of component 'xp_cmdshell' because this component is turned off as part of the security configuration for this server. 
A system administrator can enable the use of 'xp_cmdshell' by using sp_configure. For more information about enabling 'xp_cmdshell', search for 'xp_cmdshell' in SQL Server Books Online.
*/
-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

--SELECT @@SERVERNAME;

DECLARE @out varchar(250);
set @out = 'bcp WideWorldImporters.Warehouse.Colors OUT "E:\BCP\demo.txt" -T -S ' + @@SERVERNAME + ' -c';
PRINT @out;

EXEC master..xp_cmdshell @out

DROP TABLE IF EXISTS WideWorldImporters.Warehouse.Color_Copy;
SELECT * INTO WideWorldImporters.Warehouse.Color_Copy FROM WideWorldImporters.Warehouse.Colors
WHERE 1 = 2; 


DECLARE @in varchar(250);
set @in = 'bcp WideWorldImporters.Warehouse.Color_Copy IN "E:\BCP\demo.txt" -T -S ' + @@SERVERNAME + ' -c';

EXEC master..xp_cmdshell @in;

SELECT *
FROM WideWorldImporters.Warehouse.Color_Copy;