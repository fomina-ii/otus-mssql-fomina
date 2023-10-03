/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

-- Вариант 1: подзапрос (query cost 3%) - более предпочтителен
SELECT
	DISTINCT(PersonID),
	FullName
FROM Sales.Invoices as i
JOIN Application.People as p on p.PersonID = i.SalespersonPersonID and p.IsSalesperson = 1
WHERE PersonID NOT IN (SELECT DISTINCT SalespersonPersonID
					   FROM Sales.Invoices as si
					   WHERE si.InvoiceDate = '2015-07-04')

-- Вариант 2: CTE (query cost 97%)
;WITH CTE AS (
	SELECT DISTINCT SalespersonPersonID
	FROM Sales.Invoices as si
	WHERE si.InvoiceDate = '2015-07-04')

SELECT
	DISTINCT(PersonID),
	FullName
FROM Sales.Invoices as i
JOIN Application.People as p on p.PersonID = i.SalespersonPersonID and p.IsSalesperson = 1
LEFT JOIN CTE as c on p.PersonID = c.SalespersonPersonID
WHERE c.SalespersonPersonID IS NULL

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

-- Вариант 1: подзапрос (query cost 50%)
SELECT DISTINCT
	[StockItemID],
	[Description],
	[UnitPrice] as [MinPrice]
FROM Sales.InvoiceLines
WHERE [UnitPrice] = (SELECT MIN([UnitPrice])
					  FROM Sales.InvoiceLines)

-- Вариант 2: CTE (query cost 50%)
;WITH CTE AS (
	SELECT MIN([UnitPrice]) as [MinPrice]
	FROM Sales.InvoiceLines
)
SELECT DISTINCT
	[StockItemID],
	[Description],
	[UnitPrice] as [MinPrice]
FROM Sales.InvoiceLines as i
JOIN CTE as c on c.MinPrice = i.UnitPrice

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

-- Вариант 1: без подзапроса (query cost 30%) - более предпочтителен
SELECT TOP 5
	ct.[CustomerID],
	sc.[CustomerName],
	[TransactionAmount] as [MaxTransactionAmount]
FROM [Sales].[CustomerTransactions] ct
JOIN Sales.Customers as sc on sc.CustomerID = ct.CustomerID
ORDER BY [MaxTransactionAmount] DESC

-- Вариант 2: подзапрос (query cost 35%)
SELECT
	ct.[CustomerID],
	sc.[CustomerName],
	[TransactionAmount] as [MaxTransactionAmount]
FROM [Sales].[CustomerTransactions] ct
JOIN Sales.Customers as sc on sc.CustomerID = ct.CustomerID
WHERE [TransactionAmount] in (SELECT TOP 5 [TransactionAmount]
							  FROM [Sales].[CustomerTransactions]
							  ORDER BY [TransactionAmount] DESC)
ORDER BY [MaxTransactionAmount] DESC

-- Вариант 3: CTE (query cost 35%)
;WITH CTE AS (
	SELECT TOP 5 [TransactionAmount] as [TransactionAmount]
	FROM [Sales].[CustomerTransactions]
	ORDER BY [TransactionAmount] DESC
)
SELECT
	ct.[CustomerID],
	sc.[CustomerName],
	ct.[TransactionAmount] as [MaxTransactionAmount]
FROM [Sales].[CustomerTransactions] ct
JOIN Sales.Customers as sc on sc.CustomerID = ct.CustomerID
JOIN CTE AS c on c.[TransactionAmount] = ct.TransactionAmount
ORDER BY [MaxTransactionAmount] DESC


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

;WITH CTE AS (
	SELECT distinct top 3 [UnitPrice]
	FROM [WideWorldImporters].[Sales].[InvoiceLines]
	ORDER BY [UnitPrice] DESC
)

SELECT
	sc.DeliveryCityID as [CityID],
	ac.[CityName],
    ap.FullName as [PackedBy]
FROM [WideWorldImporters].[Sales].[Invoices] as si
JOIN Sales.Customers as sc on sc.CustomerID = si.CustomerID  -- для получения инф о городе доставки
JOIN [Application].[Cities] as ac on ac.CityID = sc.DeliveryCityID -- город доставки
JOIN Sales.InvoiceLines as sl on sl.InvoiceID = si.InvoiceID  -- для получения инф о цене товара
JOIN CTE as c on c.UnitPrice = sl.[UnitPrice]  -- цена товара
JOIN Application.People as ap on ap.PersonID = si.[PackedByPersonID] -- имя упаковщика 
GROUP BY sc.DeliveryCityID, ac.[CityName], ap.FullName  -- избавляемся от дубликатов


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

----------- Если я правильно поняла, invoice - это выставленный счет

-- Запрос выводит ID, даты счета, имя продавца, сумму выставленного клиенту счета и сумму выбранных клиентом товаров
-- при условии, что сумма счета больше 27000 и комплектация завершена

-- Я протестировала три варианта кода.
-- Вариант 1:
;WITH CTE_OrderLines AS (
	SELECT OrderID, SUM(ol.PickedQuantity * ol.UnitPrice) AS TotalSummForPickedItems
	FROM [WideWorldImporters].[Sales].[OrderLines] as ol
	GROUP BY OrderID
)
SELECT 
	i.InvoiceID, 
	i.InvoiceDate,
	p.FullName AS SalesPersonName,
	SUM(il.Quantity * il.UnitPrice) AS TotalSummByInvoice,
	TotalSummForPickedItems 
FROM Sales.Invoices as i
JOIN Application.People as p on p.PersonID = i.SalespersonPersonID
JOIN Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
JOIN CTE_OrderLines as ol on ol.OrderId = i.OrderId
GROUP BY i.InvoiceId, i.InvoiceDate, p.FullName, i.OrderID, TotalSummForPickedItems
HAVING SUM(il.Quantity * il.UnitPrice) > 27000
ORDER BY TotalSummByInvoice DESC

-- Вариант 2:
;WITH CTE_SalesTotals AS (
    SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
    FROM Sales.InvoiceLines
    GROUP BY InvoiceId
    HAVING SUM(Quantity * UnitPrice) > 27000
)
SELECT 
    i.InvoiceID, 
    i.InvoiceDate,
    p.FullName AS SalesPersonName,
    st.TotalSumm AS TotalSummByInvoice, 
    SUM(ol.PickedQuantity * ol.UnitPrice) AS TotalSummForPickedItems
FROM Sales.Invoices i
JOIN Application.People p ON p.PersonID = i.SalespersonPersonID
JOIN Sales.OrderLines ol ON ol.OrderId = i.OrderId
JOIN CTE_SalesTotals st ON i.InvoiceID = st.InvoiceID
GROUP BY i.InvoiceID, i.InvoiceDate, p.FullName, st.TotalSumm
ORDER BY st.TotalSumm DESC;

-- Вариант 3:
;WITH CTE_OrderLines AS (
	SELECT OrderID, SUM(ol.PickedQuantity * ol.UnitPrice) AS TotalSummForPickedItems
	FROM [WideWorldImporters].[Sales].[OrderLines] as ol
	GROUP BY OrderID
),
CTE_SalesTotals AS (
    SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
    FROM Sales.InvoiceLines
    GROUP BY InvoiceId
    HAVING SUM(Quantity * UnitPrice) > 27000
)
SELECT 
    i.InvoiceID, 
    i.InvoiceDate,
    p.FullName AS SalesPersonName,
    st.TotalSumm AS TotalSummByInvoice, 
    TotalSumm AS TotalSummForPickedItems
FROM Sales.Invoices i
JOIN Application.People p ON p.PersonID = i.SalespersonPersonID
JOIN CTE_OrderLines ol ON ol.OrderId = i.OrderId
JOIN CTE_SalesTotals st ON i.InvoiceID = st.InvoiceID
ORDER BY st.TotalSumm DESC;

-- Сравнивала планы выполнения и время выполнения с помощью SET STATISTICS TIME ON. Несколько тестов показали, что все запросы выполняются быстро,
-- и часто то один, то другой запрос оказывался быстрее. Однако третий вариант чаще "выигрывал".

-- Я выбираю третий вариант не только из-за скорости выполнения, но и из-за удобства чтения и логики запроса.
-- В CTE я вычисляю суммы счета и выбранных товаров, а в итоговой таблице вывожу результаты.

-- В подсчете TotalSummByInvoice я исключила условие WHERE Orders.PickingCompletedWhen IS NOT NULL, 
-- так как сумма (PickedQuantity * UnitPrice) по этому условию равна нулю, что противоречит другому условию SUM(Quantity * UnitPrice),
-- значит при объединении запросов такие строки в любом случае не будут выводиться