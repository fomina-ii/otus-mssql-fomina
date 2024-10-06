DELETE FROM Warehouse.Colors
WHERE ColorName LIKE N'�����������������';

DELETE FROM Warehouse.Colors
WHERE ColorName LIKE N'����������';


DELETE FROM Warehouse.Colors
WHERE ColorName LIKE N'�����';

DELETE FROM Warehouse.Colors
WHERE ColorName LIKE N'�������';

SELECT *
FROM Warehouse.Colors;

SELECT * FROM Application.Countries;

DELETE FROM Application.Countries
WHERE CountryName LIKE N'����';

----------------------------------------------

SELECT 
     CountryID
    , CountryName
    , FormalName
    , IsoAlpha3Code
    , IsoNumericCode
    , CountryType
    , LatestRecordedPopulation
    , Continent
    , Region
    , Subregion
    , LastEditedBy
INTO [Application].Countries_Copy
FROM [Application].Countries;

SELECT * FROM [Application].Countries_Copy;

INSERT INTO [Application].Countries_Copy
    ( CountryID
    , CountryName
    , FormalName
    , IsoAlpha3Code
    , IsoNumericCode
    , CountryType
    , LatestRecordedPopulation
    , Continent
    , Region
    , Subregion
    , LastEditedBy)
VALUES
    ( NEXT VALUE FOR Sequences.CountryID
    , N'����'
    , N'������� ������� �����'
    , 'MON'
    , 895
    , 'UN Member State'
    , 0
    , N'��� �����'
    , N'��� �����'
    , N'��� �����'
    , 1),
    (NEXT VALUE FOR Sequences.CountryID
    , N'�����'
    , N'������� ������� ����'
    , 'FOB'
    , 896
    , 'UN Member State'
    , 0
    , N'��� �����'
    , N'��� �����'
    , N'��� �����'
    , 1);

SELECT * FROM [Application].Countries_Copy
WHERE EXISTS (SELECT * 
	FROM [Application].Countries
	WHERE [Application].Countries_Copy.CountryName = [Application].Countries.CountryName);

DELETE FROM [Application].Countries_Copy
WHERE EXISTS (SELECT * 
	FROM [Application].Countries
	WHERE [Application].Countries_Copy.CountryName = [Application].Countries.CountryName);

--DROP TABLE IF EXISTS [Application].Countries_Copy;

--DELETE FROM [Copy]
SELECT [Countries].CountryName
FROM [Application].Countries_Copy AS [Copy]
INNER JOIN [Application].Countries [Countries]
ON [Countries].CountryName = [Copy].CountryName;

---------------------------------------------
---DELETE ��������
--1. SELECT INTO...
INSERT INTO [Application].Countries_Copy
    SELECT * FROM [Application].Countries_Copy
    WHERE CountryID BETWEEN 10 AND 20;

    -- ���� ���������:
SELECT
      CountryID
    , CountryName
    , COUNT(*)
FROM [Application].Countries_Copy
GROUP BY CountryID, CountryName
HAVING COUNT(*) > 1;

SELECT
      CountryID
    , CountryName
    , ROW_NUMBER() OVER (PARTITION BY CountryName ORDER BY CountryName) AS N
FROM [Application].Countries_Copy;

WITH Dubl AS
(
SELECT
      CountryID
    , CountryName
    , ROW_NUMBER() OVER (PARTITION BY CountryName ORDER BY CountryName) AS N
FROM [Application].Countries_Copy
)
SELECT *
FROM Dubl
WHERE N > 1;

---��������

WITH Dubl AS
(
SELECT
      CountryID
    , CountryName
    , ROW_NUMBER() OVER (PARTITION BY CountryName ORDER BY CountryName) AS N
FROM [Application].Countries_Copy
)
DELETE
FROM Dubl
WHERE N > 1;

---------------
--DROP TABLE IF EXISTS Warehouse.Color_Copy;
--DROP TABLE IF EXISTS Warehouse.Color_Archive;

SELECT * INTO Warehouse.Color_Copy
FROM Warehouse.Colors;

SELECT * FROM Warehouse.Color_Copy;

SELECT * INTO Warehouse.Color_Archive
FROM Warehouse.Colors
WHERE 1 = 2;

SELECT * FROM Warehouse.Color_Archive;

DECLARE @rowcount INT,
		@batchsize INT = 2;

SET @rowcount = @batchsize;
--- �������� �� ������
WHILE @rowcount = @batchsize
BEGIN
	DELETE top (@batchsize) FROM Warehouse.Color_Copy
	OUTPUT
          deleted.ColorID
        , deleted.ColorName
        , deleted.LastEditedBy
        , deleted.ValidFrom
        , deleted.ValidTo
    INTO Warehouse.Color_Archive
    (
          ColorID
        , ColorName
        , LastEditedBy
        , ValidFrom
        , ValidTo
        )
	SET @rowcount = @@ROWCOUNT;
END