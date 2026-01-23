--Query Store
--Erstellt während dem normalen DB Gebrauch Statistiken zu Abfragen

--Rechtsklick auf die DB -> Properties -> Query Store

USE Demo20260120;

SELECT * FROM M004_Index WHERE Freight > 50;

CREATE NONCLUSTERED INDEX M007_QS_Index
ON [dbo].[M004_Index] ([Freight])
INCLUDE ([id],[OrderDate],[RequiredDate],[ShippedDate],[CustomerID],[CompanyName],[ContactName],[ContactTitle],[Address],[City],[Region],[PostalCode],[Country],[Phone],[OrderID],[EmployeeID],[LastName],[FirstName],[Title],[UnitPrice],[Quantity],[Discount],[ProductID],[ProductName],[UnitsInStock])

SELECT Txt.query_text_id, Txt.query_sql_text, Pl.plan_id, Qry.*  
FROM sys.query_store_plan AS Pl 
JOIN sys.query_store_query AS Qry ON Pl.query_id = Qry.query_id  
JOIN sys.query_store_query_text AS Txt ON Qry.query_text_id = Txt.query_text_id;

SELECT UseCounts, Cacheobjtype, Objtype, TEXT, query_plan
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
CROSS APPLY sys.dm_exec_query_plan(plan_handle) --Pläne visualisieren