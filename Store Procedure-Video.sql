USE AdventureWorks2019
GO

--  Tạo ra Store Procedure lấy ra toàn bộ nhân viên vào làm theo năm có tham số đầu vào là một năm 
CREATE PROCEDURE sp_DisplayEmployeeHireYear
     @HireYear INT
AS 
SELECT * FROM HumanResources.Employee
WHERE DATEPART(YY, HireDate) = @HireYear
GO

EXECUTE dbo.sp_DisplayEmployeeHireYear @HireYear = 2009 -- int
GO


--  Tạo ra Store Procedure đếm số người vào làm trong 1 năm xác định có tham số đầu vào là một năm, tham sô đầu ra là số người vào làm trong năm mà ta cần tìm
-- sủ dụng OUTPUT
CREATE PROCEDURE sp_DisplayEmployeeHireYearCount 
     @HireYear INT,
	 @Count INT OUTPUT
AS 
SELECT @Count = COUNT(*) FROM HumanResources.Employee
WHERE DATEPART(YY, HireDate) = @HireYear
GO

DECLARE @Number INT
EXECUTE dbo.sp_DisplayEmployeeHireYearCount @HireYear = 2009,         -- int
                                            @Count = @Number OUTPUT -- int
PRINT @Number
GO 


-- sủ dụng RETURN 
CREATE PROCEDURE sp_DisplayEmployeeHireYearCount2
     @HireYear INT
AS 
DECLARE @Count INT 
SELECT @Count = COUNT(*) FROM HumanResources.Employee
WHERE DATEPART(YY, HireDate) = @HireYear
RETURN @Count
GO

DECLARE @Number INT
EXECUTE @Number = dbo.sp_DisplayEmployeeHireYearCount2 @HireYear = 2009 -- Giá trị trả về của  hàm băng  
PRINT @Number
GO 




-- Tạo bảng tạm #Student 
CREATE TABLE #Students
(
    RollNo VARCHAR(6) PRIMARY KEY,
	FullName NVARCHAR(100),
	BirthDay DATETIME DEFAULT DATEADD(yy, -18, GETDATE())
)
GO

--  Tạo ra thủ tục lưu trữ tạm để chèn dữ liệu vào bảng tạm 
CREATE PROCEDURE #spInsertStudent 
    @rollNo VARCHAR(6),
	@fullName NVARCHAR(100),
	@birthDay DATETIME
AS BEGIN
    IF(@birthDay IS NULL)
	    SET @birthDay = DATEADD(yy, -18, GETDATE())
    INSERT INTO #Students(RollNo, FullName, BirthDay)
           VALUES(@rollNo, @fullName, @birthDay)
END 
GO
-- Sử dụng thủ tục lưu trữ để chèn dữ liệu vào bảng 
EXEC dbo.#spInsertStudent @rollNo = 'A12345',                     -- varchar(6)
                          @fullName = N'Abc',                     -- nvarchar(100)
                          @birthDay = '2000-01-06 12:11:53'       -- datetime

EXEC dbo.#spInsertStudent @rollNo = 'A54321',                     -- varchar(6)
                          @fullName = N'Vbbbb',                   -- nvarchar(100)
                          @birthDay = null                        -- datetime

SELECT * FROM #Students

-- Tạo thủ tục lưu trữ để xóa dữ liệu từ bảng theo RollNo 
CREATE PROCEDURE #spDeleteStudents
     @rollNo varchar(6)
AS BEGIN 
     DELETE FROM #Students WHERE RollNo = @rollNo 
END 

-- xóa dữ liệu 
EXECUTE dbo.#spInsertStudent 'A12345'
GO  

-- Tạo một thủ tục lưu trữ dữ liệu sử dụng RETURN trả về một số nguyên 
CREATE PROCEDURE  Cal_Square @num INT=0 AS
BEGIN
    RETURN (@num * @num);
END
GO

DECLARE @square INT
EXEC @square = Cal_Square 10
PRINT @square
GO



-----------------------

-- Xem định nghĩa thủ tục lưu trữ bằng hàm OBJECT_DEFINITION
SELECT OBJECT_DEFINITION(OBJECT_ID('HumanResources.usUpdateEmployeePersonalInfo')) AS DEFINITION 
                                                                                     
-- Xem định nghĩa thủ tục lưu trữ bằng
SELECT DEFINITION FROM sys.sql_modules 
WHERE OBJECT_ID = OBJECT_ID('HumanResources.usUpdateEmployeePersonalInfo')
GO 

-- Thủ tục lưu trữ hệ thống xem các thành phần mà thủ tục lưu trữ phụ thuộc 
sp_depends 'HumanResources.usUpdateEmployeePersonalInfo'
GO 

-------------------------------------

CREATE PROCEDURE sp_DisplayEmpkoyees AS
SELECT * FROM HumanResources.Employee
GO 

ALTER PROCEDURE sp_DisplayEmpkoyees AS
SELECT * FROM HumanResources.Employee
WHERE Gender = 'F'
GO

EXEC dbo.sp_DisplayEmpkoyees 
GO 

DROP PROCEDURE dbo.sp_DisplayEmpkoyees
GO 


-----------
CREATE PROCEDURE sp_EmplyeeHire
AS
BEGIN
    -- Hiển thị 
	EXECUTE dbo.sp_DisplayEmployeeHireYear @HireYear = 2009 -- int
	DECLARE @Number INT 
	EXECUTE dbo.sp_DisplayEmployeeHireYearCount @HireYear = 2009,         -- int
	                                            @Count = @Number OUTPUT -- int
    PRINT N'Số nhân viên vào làm năm 2009 là: ' + CONVERT(VARCHAR(3), @Number)
END
GO 

EXEC dbo.sp_EmplyeeHire
GO 


-- Thay đổi thủ tục lưu trữ sp_EmployeeHire có khối TRY ... CATCH
ALTER PROCEDURE dbo.sp_EmplyeeHire
     @HireYear INT 
AS 
BEGIN
    EXECUTE dbo.sp_DisplayEmployeeHireYear @HireYear 
	DECLARE @number INT 
	-- Lỗi xảy ra ở đây có thủ tục sp_DisplayEmployeeHireYearCount chỉ truyền vào 2 than số mà truyền 2 tham sô mà ta truyền 3 
    IF @@ERROR <> 0
	    PRINT N'Có Lỗi xảy ra trong khi thực hiện thủ tục lưu trữ'
    PRINT N'Số nhân viên vào làm năm là: ' +  CONVERT(VARCHAR(3), @Number)
END

EXEC dbo.sp_EmplyeeHire
GO 