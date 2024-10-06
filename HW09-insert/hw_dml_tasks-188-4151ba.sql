/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO [Sales].[Customers] ([CustomerName],[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID]
								,[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[CreditLimit]
								,[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays]
								,[PhoneNumber],[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL]
								,[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode],[DeliveryLocation],[PostalAddressLine1]
								,[PostalAddressLine2],[PostalPostalCode],[LastEditedBy])
VALUES 
    ('Test Customer 77777', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2013-01-01', 0.000, 0,	0, 7, '(308) 555-0100', '(308) 555-0101', '', '', 'http://www.tailspintoys.com', 'Shop 38', '1877 Mittal Road', 90410, 0xE6100000010CE73F5A52A4BF444010638852B1A759C0, 'PO Box 8975', 'Ribeiroville', 90410, 1),
    ('Test Customer 77778', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2013-01-01', 0.000, 0,	0, 7, '(308) 555-0100', '(308) 555-0101', '', '', 'http://www.tailspintoys.com', 'Shop 38', '1877 Mittal Road', 90410, 0xE6100000010CE73F5A52A4BF444010638852B1A759C0, 'PO Box 8975', 'Ribeiroville', 90410, 1),
	('Test Customer 77779', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2013-01-01', 0.000, 0,	0, 7, '(308) 555-0100', '(308) 555-0101', '', '', 'http://www.tailspintoys.com', 'Shop 38', '1877 Mittal Road', 90410, 0xE6100000010CE73F5A52A4BF444010638852B1A759C0, 'PO Box 8975', 'Ribeiroville', 90410, 1),
    ('Test Customer 77780', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2013-01-01', 0.000, 0,	0, 7, '(308) 555-0100', '(308) 555-0101', '', '', 'http://www.tailspintoys.com', 'Shop 38', '1877 Mittal Road', 90410, 0xE6100000010CE73F5A52A4BF444010638852B1A759C0, 'PO Box 8975', 'Ribeiroville', 90410, 1),
    ('Test Customer 77771', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2013-01-01', 0.000, 0,	0, 7, '(308) 555-0100', '(308) 555-0101', '', '', 'http://www.tailspintoys.com', 'Shop 38', '1877 Mittal Road', 90410, 0xE6100000010CE73F5A52A4BF444010638852B1A759C0, 'PO Box 8975', 'Ribeiroville', 90410, 1)


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM [Sales].[Customers]
--SELECT * FROM [Sales].[Customers]
WHERE [CustomerName] = 'Test Customer 77771'


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE [Sales].[Customers]
SET [CustomerName] = 'Test Customer 77777-NEW'
WHERE [CustomerName] = 'Test Customer 77777'

/*
4. Написать MERGE, который вставит вставит запись в Customers, если ее там нет, и изменит если она уже есть
*/

MERGE INTO [Sales].[Customers] AS t1
USING (
    SELECT 'Test Customer 77777' AS CustomerName, 
           1 AS BillToCustomerID, 
           3 AS CustomerCategoryID,
           1 AS BuyingGroupID,
           1001 AS PrimaryContactPersonID,
           1002 AS AlternateContactPersonID,
           3 AS DeliveryMethodID,
           19586 AS DeliveryCityID,
           19586 AS PostalCityID,
           NULL AS CreditLimit,
           '2013-01-01' AS AccountOpenedDate,
           0.000 AS StandardDiscountPercentage,
           0 AS IsStatementSent,
           0 AS IsOnCreditHold,
           7 AS PaymentDays,
           '(308) 555-0100' AS PhoneNumber,
           '(308) 555-0101' AS FaxNumber,
           '' AS DeliveryRun,
           '' AS RunPosition,
           'http://www.tailspintoys.com' AS WebsiteURL,
           'Shop 38' AS DeliveryAddressLine1,
           '1877 Mittal Road' AS DeliveryAddressLine2,
           90410 AS DeliveryPostalCode,
           0xE6100000010CE73F5A52A4BF444010638852B1A759C0 AS DeliveryLocation,
           'PO Box 8975' AS PostalAddressLine1,
           'Ribeiroville' AS PostalAddressLine2,
           90410 AS PostalPostalCode,
           1 AS LastEditedBy
) AS t2
ON t1.CustomerName = t2.CustomerName

-- Если запись существует, обновляем ее
WHEN MATCHED
THEN UPDATE SET 
        t1.BillToCustomerID = t2.BillToCustomerID,
        t1.CustomerCategoryID = t2.CustomerCategoryID,
        t1.BuyingGroupID = t2.BuyingGroupID,
        t1.PrimaryContactPersonID = t2.PrimaryContactPersonID,
        t1.AlternateContactPersonID = t2.AlternateContactPersonID,
        t1.DeliveryMethodID = t2.DeliveryMethodID,
        t1.DeliveryCityID = t2.DeliveryCityID,
        t1.PostalCityID = t2.PostalCityID,
        t1.CreditLimit = t2.CreditLimit,
        t1.AccountOpenedDate = t2.AccountOpenedDate,
        t1.StandardDiscountPercentage = t2.StandardDiscountPercentage,
        t1.IsStatementSent = t2.IsStatementSent,
        t1.IsOnCreditHold = t2.IsOnCreditHold,
        t1.PaymentDays = t2.PaymentDays,
        t1.PhoneNumber = t2.PhoneNumber,
        t1.FaxNumber = t2.FaxNumber,
        t1.DeliveryRun = t2.DeliveryRun,
        t1.RunPosition = t2.RunPosition,
        t1.WebsiteURL = t2.WebsiteURL,
        t1.DeliveryAddressLine1 = t2.DeliveryAddressLine1,
        t1.DeliveryAddressLine2 = t2.DeliveryAddressLine2,
        t1.DeliveryPostalCode = t2.DeliveryPostalCode,
        t1.DeliveryLocation = t2.DeliveryLocation,
        t1.PostalAddressLine1 = t2.PostalAddressLine1,
        t1.PostalAddressLine2 = t2.PostalAddressLine2,
        t1.PostalPostalCode = t2.PostalPostalCode,
        t1.LastEditedBy = t2.LastEditedBy

-- Если запись не существует, вставляем новую
WHEN NOT MATCHED 
THEN 
    INSERT (
        CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID,
        PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID,
        PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage,
        IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber,
        DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
        DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2,
        PostalPostalCode, LastEditedBy
    )
    VALUES (
        t2.CustomerName, t2.BillToCustomerID, t2.CustomerCategoryID, t2.BuyingGroupID,
        t2.PrimaryContactPersonID, t2.AlternateContactPersonID, t2.DeliveryMethodID, t2.DeliveryCityID,
        t2.PostalCityID, t2.CreditLimit, t2.AccountOpenedDate, t2.StandardDiscountPercentage,
        t2.IsStatementSent, t2.IsOnCreditHold, t2.PaymentDays, t2.PhoneNumber, t2.FaxNumber,
        t2.DeliveryRun, t2.RunPosition, t2.WebsiteURL, t2.DeliveryAddressLine1, t2.DeliveryAddressLine2,
        t2.DeliveryPostalCode, t2.DeliveryLocation, t2.PostalAddressLine1, t2.PostalAddressLine2,
        t2.PostalPostalCode, t2.LastEditedBy
    );


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

-- Копируем данные из таблицы в файл на локальный компьютер
DECLARE @out varchar(250);
set @out = 'bcp WideWorldImporters.Sales.Customers OUT "D:\customers_data.txt" -T -S ' + @@SERVERNAME + ' -c';
PRINT @out;
EXEC master..xp_cmdshell @out

-- Создаем пустую копию таблицы
DROP TABLE IF EXISTS WideWorldImporters.Sales.Customers_Copy;
SELECT * INTO WideWorldImporters.Sales.Customers_Copy FROM WideWorldImporters.Sales.Customers
WHERE 1 = 2; 

-- Копируем данные из файла в таблицу
DECLARE @in varchar(250);
set @in = 'bcp WideWorldImporters.Sales.Customers_Copy IN "D:\customers_data.txt" -T -S ' + @@SERVERNAME + ' -c';
EXEC master..xp_cmdshell @in;

-- Смотрим результат
SELECT *
FROM WideWorldImporters.Sales.Customers_Copy;