INSERT INTO Products VALUES
 (1, N'������')
,(2, N'�����')
,(3, N'������')
,(4, N'���');
GO
--CONSTRAINT PK
INSERT INTO Products VALUES
 (1, N'�����');
 GO
 --CONSTRAINT UNIQUE
INSERT INTO Products VALUES
 (5, N'������');
 GO
 --SET VALUE IN NVARCHAR()
 INSERT INTO Products VALUES
  (5, '�����');
 INSERT INTO Products VALUES
  (6, '?');

  SELECT *
  FROM Products;

INSERT INTO Products VALUES
  (7, N'?');