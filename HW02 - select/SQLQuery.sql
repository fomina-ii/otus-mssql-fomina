/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, JOIN".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� WideWorldImporters ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' or StockItemName LIKE 'Animal%'

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

SELECT A.SupplierID, SupplierName
FROM Purchasing.Suppliers AS A
LEFT JOIN Purchasing.PurchaseOrders AS B ON A.SupplierID = B.SupplierID
WHERE B.SupplierID IS NULL

/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
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
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
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
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
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
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
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