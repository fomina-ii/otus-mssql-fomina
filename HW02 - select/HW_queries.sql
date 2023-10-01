/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' or StockItemName LIKE 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT A.SupplierID, SupplierName
FROM Purchasing.Suppliers AS A
LEFT JOIN Purchasing.PurchaseOrders AS B ON A.SupplierID = B.SupplierID
WHERE B.SupplierID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT
    o.[OrderID],
    FORMAT([OrderDate], 'dd.MM.yyyy') as [Date],
    FORMAT([OrderDate], 'MMMM', 'en') as [Month],
    DATEPART(QUARTER, [OrderDate]) AS [Quarter],
    CASE 
        WHEN MONTH([OrderDate]) BETWEEN 1 AND 4 THEN 1
        WHEN MONTH([OrderDate]) BETWEEN 5 AND 8 THEN 2
        WHEN MONTH([OrderDate]) BETWEEN 9 AND 12 THEN 3
    END AS [ThirdOfYear],
    c.CustomerName
FROM Sales.Orders AS o
LEFT JOIN Sales.Customers as c on c.[CustomerID] = o.CustomerID 
LEFT JOIN Sales.OrderLines as l on l.OrderID = o.OrderID
WHERE (l.UnitPrice > 100 or l.Quantity > 20) and l.PickingCompletedWhen IS NOT NULL
ORDER BY [Quarter], [ThirdOfYear], [OrderDate]
OFFSET 1000 ROWS
FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT TOP (1000) 
	DeliveryMethodName,
	[ExpectedDeliveryDate],
    p.SupplierName,
	ap.PreferredName as ContactPerson
FROM [Purchasing].[PurchaseOrders] as po
LEFT JOIN Application.DeliveryMethods as d on d.DeliveryMethodID = po.DeliveryMethodID
LEFT JOIN Purchasing.Suppliers as p on p.SupplierID = po.SupplierID
LEFT JOIN Application.People as ap on ap.PersonID = po.[ContactPersonID]
WHERE [ExpectedDeliveryDate] between '2013-01-01' and '2013-01-31'
	and DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
	and IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP (10) 
	OrderID,
	sc.CustomerName,
	p.FullName as [Manager]
FROM [WideWorldImporters].[Sales].[Orders] as so
LEFT JOIN Sales.Customers as sc on sc.CustomerID = so.CustomerID
LEFT JOIN Application.People as p on p.PersonID = SalespersonPersonID and IsSalesperson = 1
ORDER BY [OrderDate] DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT 
	sc.CustomerID,
	sc.CustomerName,
	sc.PhoneNumber
FROM [WideWorldImporters].[Sales].[Orders] as so
LEFT JOIN [Sales].[OrderLines] as o on o.OrderID = so.OrderID
LEFT JOIN [Warehouse].[StockItems] as si on si.StockItemID = o.StockItemID
LEFT JOIN Sales.Customers as sc on sc.CustomerID = so.CustomerID
WHERE si.StockItemName = 'Chocolate frogs 250g'