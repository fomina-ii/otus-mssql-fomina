/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

-- через OPENXML
-- Считываем XML-файл
DECLARE @xmlDocument XML;
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'D:\otus-mssql\otus-mssql-fomina\HW10-xml\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
AS data;

-- docHandle - это просто число
DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

-- запрос
--DROP TABLE IF EXISTS #StockItems
SELECT *
INTO #StockItems
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] nvarchar(150) '@Name'
    ,[SupplierID] INT 'SupplierID'
    ,[UnitPackageID] INT 'UnitPackageID'
    ,[OuterPackageID] INT 'OuterPackageID'
    ,[QuantityPerOuter] INT 'QuantityPerOuter'
    ,[TypicalWeightPerUnit] DECIMAL(18,3) 'TypicalWeightPerUnit'
	,[LeadTimeDays] INT 'LeadTimeDays'
	,[IsChillerStock] INT 'IsChillerStock'
	,[TaxRate] DECIMAL(18,3) 'TaxRate'
	,[UnitPrice] DECIMAL(18,6) 'UnitPrice'
	)
SELECT *
FROM #StockItems

-- Удалить handle
EXEC sp_xml_removedocument @docHandle

-- через XQuery
-- Считываем XML-файл
DECLARE @x XML;
SET @x = ( 
  SELECT * FROM OPENROWSET
  (BULK 'D:\otus-mssql\otus-mssql-fomina\HW10-xml\StockItems-188-1fb5df.xml',
   SINGLE_CLOB) AS d);

-- запрос
SELECT  
  t.Item.value('@Name[1]', 'nvarchar(150)') AS [StockItemName],
  t.Item.value('SupplierID[1]', 'INT') AS [SupplierID],
  t.Item.value('UnitPackageID[1]', 'INT') AS [UnitPackageID],
  t.Item.value('OuterPackageID[1]', 'INT') AS [OuterPackageID],
  t.Item.value('QuantityPerOuter[1]', 'INT') AS [QuantityPerOuter],
  t.Item.value('TypicalWeightPerUnit[1]', 'DECIMAL(18,3)') AS [TypicalWeightPerUnit],
  t.Item.value('LeadTimeDays[1]', 'INT') AS [LeadTimeDays],
  t.Item.value('IsChillerStock[1]', 'INT') AS [IsChillerStock],
  t.Item.value('TaxRate[1]', 'DECIMAL(18,3)') AS [TaxRate],
  t.Item.value('UnitPrice[1]', 'DECIMAL(18,6)') AS [UnitPrice]
FROM @x.nodes('/StockItems/Item') AS t(Item);

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT *
FROM #StockItems
FOR XML RAW('Item'), ROOT('StockItems'), ELEMENTS;

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT
	[StockItemID],
	[StockItemName],
	[CustomFields],
	CustomFields,
    JSON_VALUE(CustomFields, '$.CountryOfManufacture') as [CountryOfManufacture],
	JSON_VALUE(CustomFields, '$.Tags[0]') as [FirstTag]
FROM [WideWorldImporters].[Warehouse].[StockItems]

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


SELECT
	[StockItemID],
	[StockItemName],
	STRING_AGG(Value, ', ') as [AllTags]
FROM [WideWorldImporters].[Warehouse].[StockItems]
CROSS APPLY OPENJSON(JSON_QUERY(CustomFields, '$.Tags')) 
--where JSON_QUERY(CustomFields, '$.Tags') like '%Vintage%'
WHERE Value = 'Vintage' OR EXISTS (
    SELECT 1
    FROM OPENJSON(JSON_QUERY(CustomFields, '$.Tags')) 
    WHERE Value = 'Vintage'
)
GROUP BY [StockItemID], [StockItemName]