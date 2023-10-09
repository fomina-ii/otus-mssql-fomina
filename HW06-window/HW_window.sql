/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

;WITH CamulativeSales AS (
	SELECT YEAR(InvoiceDate) as [Year], MONTH(InvoiceDate) as [Month], SUM(l.ExtendedPrice) as CumulativeSum
	FROM Sales.Invoices as i
	JOIN Sales.InvoiceLines as l on l.InvoiceID = i.InvoiceID
	WHERE YEAR(InvoiceDate) >= 2015
	GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
),
Sales AS (
	SELECT i.InvoiceID, CustomerName, InvoiceDate, SUM(l.ExtendedPrice) as SaleSum
	FROM Sales.Invoices as i
	JOIN Sales.InvoiceLines as l on l.InvoiceID = i.InvoiceID
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
	WHERE YEAR(i.InvoiceDate) >= 2015
	GROUP BY i.InvoiceID, CustomerName, InvoiceDate
)

SELECT InvoiceID, CustomerName, InvoiceDate, SaleSum, CumulativeSum
FROM Sales
JOIN CamulativeSales as c on c.Year = YEAR(InvoiceDate) and Month = MONTH(InvoiceDate)
WHERE YEAR(InvoiceDate) >= 2015
ORDER BY InvoiceDate


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/


-- Производительность с помощью set statistics io on:
	-- Первый запрос: кол-во чтений в таблице 'Invoices': 22800, в таблице 'InvoiceLines': 10006
	-- Второй запрос: кол-во чтений в таблице 'Invoices': 11400, в таблице 'InvoiceLines': 5003 (т.е. в два раза меньше)
-- Производительность с помощью set statistics time on:
	-- Особой разницы нет
-- Производительность с помощью Execution plan:
	-- Первый запрос 62%
	-- Второй запрос 38% (наиболее предпочтителен)

SELECT DISTINCT
	i.InvoiceID,
	CustomerName,
	InvoiceDate,
	SUM(l.ExtendedPrice) OVER (PARTITION BY i.InvoiceID) as SaleSum,
	SUM(l.ExtendedPrice) OVER (PARTITION BY YEAR(InvoiceDate), MONTH(InvoiceDate)) as CumulativeSum
FROM Sales.Invoices as i
JOIN Sales.InvoiceLines as l on l.InvoiceID = i.InvoiceID
JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
WHERE YEAR(i.InvoiceDate) >= 2015
ORDER BY InvoiceDate

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

-- В задании сказано получить список, поэтому использовала функцию STRING_AGG
SELECT [Month] , STRING_AGG([Description], ' / ') as [TwoTheMostPopularProducts]
FROM (
	SELECT
		MONTH(i.InvoiceDate) as [Month],
		[Description],
		SUM(Quantity) as [Quantity],
		ROW_NUMBER() OVER (PARTITION BY MONTH(i.InvoiceDate) ORDER BY SUM([Quantity]) DESC) as RowNum
	FROM Sales.Invoices as i
	JOIN Sales.InvoiceLines as l on l.InvoiceID = i.InvoiceID
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
	WHERE YEAR(i.InvoiceDate) = 2016
	GROUP BY MONTH(i.InvoiceDate), [Description]
) as T
WHERE RowNum in (1, 2)
GROUP BY Month

-- Но можно и так
SELECT [Month], [Description]
FROM (
	SELECT
		MONTH(i.InvoiceDate) as [Month],
		[Description],
		SUM(Quantity) as [Quantity],
		ROW_NUMBER() OVER (PARTITION BY MONTH(i.InvoiceDate) ORDER BY SUM([Quantity]) DESC) as RowNum
	FROM Sales.Invoices as i
	JOIN Sales.InvoiceLines as l on l.InvoiceID = i.InvoiceID
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
	WHERE YEAR(i.InvoiceDate) = 2016
	GROUP BY MONTH(i.InvoiceDate), [Description]
) as T
WHERE RowNum in (1, 2)

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

-- Можно было вывести все строки в одном запросе, но тогда получается много дублей, избавилась от дублей в CTE
;WITH DistItems AS (
	SELECT DISTINCT
		l.StockItemID,
		l.Description,
		w.Brand,
		[TypicalWeightPerUnit],
		l.UnitPrice + l.TaxRate as Price
	FROM Sales.Invoices as i
	JOIN Sales.InvoiceLines as l on l.InvoiceID = i.InvoiceID
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
	JOIN Warehouse.StockItems as w on w.StockItemID = l.StockItemID
	WHERE YEAR(i.InvoiceDate) = 2016
)

SELECT
	StockItemID,
	[Description],
	Brand,
	Price,
	ROW_NUMBER() OVER (PARTITION BY SUBSTRING([Description], 1, 1) ORDER BY SUBSTRING([Description], 1, 1)) as RowNumByLetter,
	(SELECT COUNT(DISTINCT StockItemID) FROM DistItems AS d) as QuantityOfItems, -- оконной функцией уникальные ID посчитать не вышло
	COUNT(StockItemID) OVER (PARTITION BY SUBSTRING([Description], 1, 1) ORDER BY SUBSTRING([Description], 1, 1)) as QuantityByLetter,
	LEAD([Description], 1) OVER (ORDER BY [Description]) as NextItemName,
	LAG(StockItemID, 1) OVER (ORDER BY [Description]) as PrevItemID,
	COALESCE(LAG([Description], 2) OVER (ORDER BY [Description]), 'No items') as BackTwoRowsItem,
	NTILE(30) OVER (ORDER BY [TypicalWeightPerUnit]) WeightGroup
FROM DistItems as i

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT [SalespersonPersonID], FullName, [CustomerID], CustomerName, [InvoiceDate], [SumDoc]
FROM (
	SELECT DISTINCT 
		[SalespersonPersonID],
		p.FullName,
		FIRST_VALUE(i.[CustomerID]) OVER (PARTITION BY [SalespersonPersonID] ORDER BY [InvoiceDate] DESC, i.InvoiceID DESC) as [CustomerID],
		FIRST_VALUE(c.CustomerName) OVER (PARTITION BY [SalespersonPersonID] ORDER BY [InvoiceDate] DESC, i.InvoiceID DESC) as CustomerName,
		FIRST_VALUE([InvoiceDate]) OVER (PARTITION BY [SalespersonPersonID] ORDER BY [InvoiceDate] DESC, i.InvoiceID DESC) as [InvoiceDate],
		SUM(ExtendedPrice) OVER (PARTITION BY [SalespersonPersonID] ORDER BY [InvoiceDate] DESC, i.InvoiceID DESC) as [SumDoc],
		ROW_NUMBER() OVER (PARTITION BY [SalespersonPersonID] ORDER BY [InvoiceDate] DESC, i.InvoiceID DESC) as rn
	FROM [Sales].[Invoices] as i
	JOIN Sales.InvoiceLines as l on l.InvoiceID = i.InvoiceID
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
	JOIN Application.People as p on PersonID = [SalespersonPersonID]
) as T
WHERE rn = 1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT [CustomerID], CustomerName, [StockItemID], InvoiceDate
FROM (
	SELECT 
		i.[CustomerID],
		c.CustomerName,
		l.[StockItemID],
		l.Description,
		l.UnitPrice,
		ROW_NUMBER() OVER (PARTITION BY i.[CustomerID] ORDER BY UnitPrice DESC) as RN,
		MAX(i.InvoiceDate) AS InvoiceDate
	FROM [Sales].[Invoices] as i
	JOIN Sales.InvoiceLines as l on l.InvoiceID = i.InvoiceID
	JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
	JOIN Application.People as p on PersonID = [SalespersonPersonID]
	GROUP BY i.[CustomerID], c.CustomerName, l.[StockItemID], l.Description, l.UnitPrice
) as T
WHERE rn in (1, 2)
ORDER BY [CustomerID], UnitPrice DESC