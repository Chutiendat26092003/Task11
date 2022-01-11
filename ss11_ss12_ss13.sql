
--SS11

USE AdventureWorks2019
GO

--1
CREATE TABLE Production.parts
(
    part_id INT NOT NULL,
	part_name varchar(100)
)
GO

--2
CREATE CLUSTERED INDEX ix_parts_id ON Production.parts(part_id)

--3
EXEC sp_rename
    N'Production.parts.ix_parts_id',
	N'index_parts_id',
	N'INDEX'

--4
ALTER INDEX index_parts_id 
ON Production.parts
DISABLE -- vô hiệu hóa k thể xem bảng Production.parts có gì 

ALTER INDEX index_parts_id 
ON Production.parts
REBUILD -- xây dựng lại index 

SELECT * FROM  Production.parts

--5
ALTER INDEX ALL ON Production.parts
DISABLE

--6
DROP INDEX IF EXISTS
index_part_id ON Production.parts

--7
CREATE NONCLUSTERED INDEX index_customer_storeid
ON Sales.Customer(StoreID)

--8
CREATE UNIQUE INDEX AK_Customer_rowguid
ON Sales.Customer(rowguid)

--9
CREATE INDEX index_cust_personID
ON Sales.Customer(PersonID)
WHERE PersonID IS NOT NULL

--10
SELECT CustomerID, PersonID, StoreID
FROM Sales.Customer
WHERE PersonID = 17000

--11
CREATE PARTITION FUNCTION partition_function (INT) 
RANGE LEFT FOR VALUES (20200630, 20200731, 20200831)

--12
(SELECT 20200613 date, $PARTITION.partition_function(20200613) PartitionNumber)
UNION 
(SELECT 20200713 date, $PARTITION.partition_function(20200713) PartitionNumber)
UNION 
(SELECT 20200813 date, $PARTITION.partition_function(20200813) PartitionNumber)
UNION 
(SELECT 20200913 date, $PARTITION.partition_function(20200913) PartitionNumber)

--13
CREATE PRIMARY XML INDEX PXML_ProductModel_CatalogDescription
ON Production.ProductModel(CatalogDescription)

--14
CREATE XML INDEX IXML_ProductModel_CatalogDescription_Path
ON Production.ProductModel(CatalogDescription)
USING XML INDEX PXML_ProductModel_CatalogDescription
FOR PATH 

--15
CREATE COLUMNSTORE INDEX IX_SalesOrderDetail_ProductIDOrderQty_ColumnStore
ON Sales.SalesOrderDetail(ProductID, OrderQty)

--16
SELECT ProductID, SUM(OrderQty)
FROM Sales.SalesOrderDetail
GROUP BY ProductID


-------------------------------------------------------------

--SS12
USE AdventureWorks2019
GO

--1
CREATE TABLE Locations
(
    LocationID INT,
	LocName VARCHAR(100)
)
GO

CREATE TABLE LocationHistory
(
    LocationID INT,
	ModifiedDate DATETIME
)
GO

--2
CREATE TRIGGER TG_INSERT_Locations ON Locations
FOR INSERT
NOT FOR REPLICATION AS
BEGIN
    INSERT INTO dbo.LocationHistory
    SELECT LocationID, GETDATE()
	FROM Inserted
END

--3
INSERT INTO dbo.Locations
(
    LocationID,
    LocName
)
VALUES
(   443101, -- LocationID - int
    'Alaska' -- LocName - varchar(100)
    )

SELECT * FROM dbo.Locations

--4
CREATE TRIGGER TG_UPDATE_Locations ON Locations 
FOR UPDATE 
NOT FOR REPLICATION 
AS 
BEGIN 
    INSERT INTO dbo.LocationHistory
    SELECT LocationID, GETDATE()
	FROM Inserted
END 

--5
UPDATE dbo.Locations SET LocName = 'Atlanta' WHERE LocationID = 443101

SELECT * FROM dbo.LocationHistory

--6
CREATE TRIGGER TG_DELETE_Location ON Locations 
FOR DELETE 
NOT FOR REPLICATION 
AS
BEGIN 
    INSERT INTO dbo.LocationHistory
	SELECT LocationID, GETDATE()
	FROM Inserted
END 

--7
DELETE FROM dbo.Locations
WHERE LocationID = 443101

SELECT * FROM dbo.LocationHistory

--8
CREATE TRIGGER AFTER_INSERT_Locations ON Locations
AFTER  INSERT 
AS 
BEGIN 
   INSERT INTO dbo.LocationHistory
   SELECT LocationID, GETDATE()
   FROM  Inserted
END 

--9
INSERT INTO dbo.Locations
(
    LocationID,
    LocName
)
VALUES
(   443103, -- LocationID - int
    'SAN ROMAN' -- LocName - varchar(100)
    )

SELECT * FROM dbo.LocationHistory

--10
CREATE TRIGGER INSTEADOF_DELETE_Locations ON Locations
INSTEAD OF DELETE  
AS 
BEGIN 
    SELECT 'Sample Instead of trigger' AS [Message]
END 

--11
DELETE FROM dbo.Locations WHERE LocationID = 443101

SELECT * FROM dbo.Locations

--12
EXEC sp_settriggerorder @triggername = 'TG_DELETE_Location', @order = 'FIRST', @StmTTYPE = 'DELETE'

--13
sp_helptext TG_DELETE_Location

--14
ALTER TRIGGER TG_UPDATE_Locations ON  Locations
WITH encryption FOR INSERT --                       -- mã hóa TRIGGER 
AS 
IF '443101' IN (SELECT LocationID FROM Inserted)
BEGIN 
    PRINT 'Locations cannot be update'
	ROLLBACK TRANSACTION
END 

sp_helptext TG_UPDATE_Locations

--15
DROP TRIGGER TG_UPDATE_Locations

--16
CREATE TRIGGER Secure ON DATABASE
FOR DROP_TABLE, ALTER_TABLE AS
PRINT 'You must diable Trigger "Secure" to drop or alter tables!'
ROLLBACK

--17
CREATE TRIGGER Emplyee_Deletion ON HumanResources.Employee
AFTER DELETE 
AS
BEGIN 
   PRINT 'Deletion will affect EmployeepayHistory table'
   DELETE FROM HumanResources.EmployeePayHistory WHERE BusinessEntityID IN
   (SELECT BusinessEntityID FROM deleted)
END

--18
CREATE TRIGGER Deletion_Confirmation
ON HumanResources.EmployeePayHistory AFTER DELETE 
AS
BEGIN 
   PRINT 'Employee details successfully deleted from EmployeePayHistory table'
END

DELETE FROM EmployeePayHistory WHERE EmpID = 1

--19
CREATE TRIGGER Accounting ON Production.TranasctionHistory 
AFTER UPDATE 
AS 
IF (UPDATE(TranasctionID) OR UPDATE(ProductID))
BEGIN 
   RAISERROR (50009, 16, 10)
END 

--20
USE AdventureWorks2019
GO

CREATE TRIGGER PODetails
ON Purchasing.PurchaseOrderDetail AFTER INSERT 
AS 
UPDATE Purchasing.PurchaseOrderHeader
SET SubTotal = SubTotal + LineTotal 
FROM Inserted
WHERE Inserted.PurchaseOrderID = PurchaseOrderHeader.PurchaseOrderID

--21
CREATE TRIGGER PODetailsMutiple
ON Purchasing.PurchaseOrderDetail AFTER INSERT AS 
UPDATE Purchasing.PurchaseOrderHeader
SET SubTotal = SubTotal + (SELECT SUM(LineTotal) FROM Inserted
                           WHERE Inserted.PurchaseOrderID = PurchaseOrderHeader.PurchaseOrderID)
WHERE PurchaseOrderHeader.PurchaseOrderID IN (SELECT PurchaseOrderID FROM Inserted)

--22
CREATE TRIGGER [track_logins] ON ALL SERVER
FOR LOGON AS 
BEGIN 
    INSERT INTO LoginActivity
	SELECT EVENTDATA(), GETDATE()
END


-----------------------------------------------------------------------------

--SS13
