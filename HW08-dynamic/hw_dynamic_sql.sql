/*

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

/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

USE WideWorldImporters

DECLARE @dml AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

-- Формирование списка клиентов с фильтром по ID
SELECT
	@ColumnName = ISNULL(@ColumnName + ',', '') + QUOTENAME(CustomerName)
FROM (
	SELECT DISTINCT [CustomerName]
	FROM [Sales].[Invoices] as i
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
    WHERE c.CustomerID BETWEEN 2 AND 6
	) AS names

SET @dml = 
  N'SELECT [Date], ' + @ColumnName + ' FROM
  (
  SELECT 
		CA.[Date],
		CustomerName,
		[OrderID]
	FROM [Sales].[Invoices] as i
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
	CROSS APPLY (SELECT FORMAT(DATEADD(mm, DATEDIFF(mm, 0, [InvoiceDate]), 0), ''dd.MM.yyyy'') as [Date]) as CA
	WHERE i.[CustomerID] BETWEEN 2 and 6
	) as PivotTable
    PIVOT ( COUNT([OrderID]) FOR CustomerName
		IN (' + @ColumnName + ')) AS PVTTable
	ORDER BY CAST([Date] as date)'


EXEC sp_executesql @dml
