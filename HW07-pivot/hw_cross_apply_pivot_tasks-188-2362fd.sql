/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

;WITH PivotData as (
	SELECT 
		CA.[Date],
		CA2.CustomerName,
		[OrderID]
	FROM [Sales].[Invoices] as i
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
	CROSS APPLY (SELECT FORMAT(DATEADD(mm, DATEDIFF(mm, 0, [InvoiceDate]), 0), 'dd.MM.yyyy') as [Date]) as CA
	CROSS APPLY (SELECT Substring(CustomerName, Charindex('(', CustomerName) + 1, Charindex(')', CustomerName) - Charindex('(', CustomerName) - 1) as [CustomerName]) as CA2
	WHERE i.[CustomerID] BETWEEN 2 and 6
)

SELECT *
FROM PivotData
PIVOT ( COUNT([OrderID]) FOR CustomerName
		IN ([Gasport, NY], [Jessie, ND], [Medicine Lodge, KS], [Peeples Valley, AZ], [Sylvanite, MT])
	) as PivotTable
ORDER BY CAST([Date] as date)

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT [CustomerName], [AddressLine]
FROM (
	SELECT
		[CustomerName],
		[DeliveryAddressLine1],
		[DeliveryAddressLine2],
		[PostalAddressLine1],
		[PostalAddressLine2]
	FROM [Sales].[Customers]
	WHERE [CustomerName] LIKE 'Tailspin Toys%'
	) as T
UNPIVOT (AddressLine for AddressLines 
		IN ([DeliveryAddressLine1], [DeliveryAddressLine2], [PostalAddressLine1], [PostalAddressLine2])) as unpt

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/


SELECT [CountryID], [CountryName], [Code]
FROM (
	SELECT
		[CountryID]
		,[CountryName]
		,[IsoAlpha3Code]
		,CAST([IsoNumericCode] as nvarchar(3)) as [IsoNumericCode]
	FROM [WideWorldImporters].[Application].[Countries]
	) AS PivotTable
UNPIVOT (Code for PivotColumns
		IN ([IsoAlpha3Code], [IsoNumericCode])) as upvt

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

-- с использованием CROSS APPLY
SELECT A.[CustomerID], A.CustomerName, ca.*, InvoiceDate
FROM Sales.Customers as A
CROSS APPLY (
	SELECT TOP 2 [StockItemID], MAX(UnitPrice) as UnitPrice
	FROM Sales.InvoiceLines as l
	JOIN [Sales].[Invoices] as i on l.InvoiceID = i.InvoiceID
	WHERE i.[CustomerID] = A.[CustomerID]
	GROUP BY [StockItemID]
	ORDER BY MAX(UnitPrice) DESC
	) AS ca
CROSS APPLY (
	SELECT InvoiceDate
	FROM [Sales].[Invoices] as ii
	JOIN Sales.InvoiceLines as ll on ll.InvoiceID = ii.InvoiceID
	WHERE ii.CustomerID = A.[CustomerID] and ll.StockItemID = ca.StockItemID
	) as ca2
ORDER BY [CustomerID], UnitPrice DESC, [StockItemID], InvoiceDate

-- с использованием оконной функции
SELECT [CustomerID], CustomerName, [StockItemID], UnitPrice, InvoiceDate
FROM (
	SELECT 
		i.[CustomerID],
		c.CustomerName,
		l.[StockItemID],
		l.Description,
		l.UnitPrice,
		DENSE_RANK() OVER (PARTITION BY i.[CustomerID] ORDER BY UnitPrice DESC) as RN,
		i.InvoiceDate
	FROM [Sales].[Invoices] as i
	JOIN Sales.InvoiceLines as l on l.InvoiceID = i.InvoiceID
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
) as T
WHERE rn in (1, 2)
ORDER BY [CustomerID], UnitPrice DESC, [StockItemID], InvoiceDate