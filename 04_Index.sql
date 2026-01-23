--Index

/*
	Table Scan: Durchsuche alle Daten in der Tabelle (langsam)
	Index Scan: Durchsuche bestimme Teile der Tabelle (besser)
	Index Seek: Gehe gezielt auf bestimmte Daten ¸ber einen Index (am besten)

	Clustered Index:
	- Sortiert neue Datens‰tze automatisch in die entsprechenden Seiten hinein, anhand der Indexspalte
	- Wird automatisch mit dem Primary Key erstellt (falls noch nicht vorhanden)
	- Kann nur einmal pro Tabelle existieren
	- Nachteil: Bei Tabellen mit vielen Datenbewegungen kostet dieser Index viel Perfomance

	Non-clustered Index:
	- Standardindex
	- Zwei Teile: Schl¸sselspalten (¸ber den der Index Datens‰tze sucht), inkludierten Spalten (zus‰tzliche Spalten, die bei der Suche auch beachtet werden)
	- ‹ber die ausgew‰hlten Spalten entscheidet die Datenbank selbst, welcher Index verwendet wird
	- Verh‰lt sich wie zus‰tzliche "Tabellen"
*/

--Groﬂe Tabelle erzeugen (Demo)

USE Northwind;
SELECT  Orders.OrderDate, Orders.RequiredDate, Orders.ShippedDate, Orders.Freight, Customers.CustomerID, Customers.CompanyName, Customers.ContactName, Customers.ContactTitle, Customers.Address, Customers.City, 
        Customers.Region, Customers.PostalCode, Customers.Country, Customers.Phone, Orders.OrderID, Employees.EmployeeID, Employees.LastName, Employees.FirstName, Employees.Title, [Order Details].UnitPrice, 
        [Order Details].Quantity, [Order Details].Discount, Products.ProductID, Products.ProductName, Products.UnitsInStock
INTO Demo20260120.dbo.M004_Index
FROM    [Order Details] INNER JOIN
        Products ON Products.ProductID = [Order Details].ProductID INNER JOIN
        Orders ON [Order Details].OrderID = Orders.OrderID INNER JOIN
        Employees ON Orders.EmployeeID = Employees.EmployeeID INNER JOIN
        Customers ON Orders.CustomerID = Customers.CustomerID;

USE Demo20260120;

INSERT INTO M004_Index
SELECT * FROM M004_Index
GO 8;

--Performanceoptimierung mit Indizes

SET STATISTICS time, io ON;

SELECT * FROM M004_Index;

--Table Scan
--Cost: 19.5, logische Lesevorg‰nge: 26257, CPU-Zeit = 250 ms, verstrichene Zeit = 793 ms
SELECT * FROM M004_Index WHERE OrderID >= 11000;

--Nach Index
--Index Seek
--Cost: 2.02, logische Lesevorg‰nge: 2684, CPU-Zeit = 125 ms, verstrichene Zeit = 740 ms
SELECT * FROM M004_Index WHERE OrderID >= 11000;

--Index begutachten
SELECT OBJECT_NAME(object_id), *
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');

--Auf bestimmte Abfragen Indizes aufbauen
--Table Scan
--Cost: 19.5, logische Lesevorg‰nge: 26257, CPU-Zeit = 62 ms, verstrichene Zeit = 78 ms
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice
FROM M004_Index
WHERE ProductName = 'Chocolade';

--Nach Index
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice
FROM M004_Index
WHERE ProductName = 'Chocolade';
--Index Seek
--Cost: 0.02, logische Lesevorg‰nge: 26, CPU-Zeit = 0 ms, verstrichene Zeit = 72 ms

--ContactName Spalte entfernen
SELECT CompanyName, ProductName, Quantity * UnitPrice
FROM M004_Index
WHERE ProductName = 'Chocolade';
--Immer noch selber Index

--ProductName + ContactName Spalten entfernen
SELECT CompanyName, Quantity * UnitPrice
FROM M004_Index
WHERE ProductName = 'Chocolade';
--Immer noch selber Index

--Ohne Where
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice
FROM M004_Index;
--Index Scan, weil die gesuchten Spalten vollst‰ndig in dem Index vorhanden sind
--Gesamttabelle muss nicht durchsucht werden, weil die anderen Spalten uninteressant sind f¸r uns
--Cost: 7.12, logische Lesevorg‰nge: 8861, CPU-Zeit = 328 ms, verstrichene Zeit = 2670 ms

--Weitere, nicht im Index inkludierte Spalten
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice, Freight
FROM M004_Index
WHERE ProductName = 'Chocolade';
--Index Seek + Lookup
--RID Lookup: Sucht in der Tabelle nach den Daten, die im Index nicht enthalten sind

--------------------------------------------------------------------------------------

--Indizierte Sicht
--View mit Index
--Benˆtigt SCHEMABINDING
--SCHEMABINDING: Sperrt die Tabellenstruktur der unterliegenden Tabellen, solange die View existiert
ALTER TABLE M004_INDEX ADD id int identity;

DROP VIEW Adressen;
GO
CREATE VIEW Adressen WITH SCHEMABINDING
AS
SELECT id, CompanyName, Address, City, Region, PostalCode, Country
FROM dbo.M004_Index;

SELECT * FROM Adressen; --Ohne Index: Table Scan

SELECT * FROM Adressen; --Mit Index: Clustered Index Scan

CREATE NONCLUSTERED INDEX Test ON dbo.Adressen (Country) INCLUDE (CompanyName, Address, City, Region, PostalCode);

--Wenn ein unique Clustered Index erstellt wird, kˆnnen weitere Non-clustered Indizes erstellt werden
SELECT * FROM Adressen WHERE Country = 'UK';

--Auch bei SELECT auf die unterliegende Tabelle wird der Index von der View verwendet
SELECT id, CompanyName, Address, City, Region, PostalCode, Country FROM M004_Index WHERE Country = 'UK';

/*
--Wenn die View mehrere Tabellen hat, kann dadurch ein Index auf mehrere Tabellen gleichzeitig gelegt werden

--Index mit mehreren Tabellen
--DROP VIEW M004_UmsatzGesamtIndex;

--GO
--CREATE VIEW M004_UmsatzGesamtIndex WITH SCHEMABINDING
--AS
--SELECT id, datum, umsatz FROM dbo.M002_Umsatz2021
--UNION ALL
--SELECT id, datum, umsatz FROM dbo.M002_Umsatz2022
--UNION ALL
--SELECT id, datum, umsatz FROM dbo.M002_Umsatz2023

--ALTER TABLE M002_Umsatz2021 ADD id int identity(2021000000, 1);
--ALTER TABLE M002_Umsatz2022 ADD id int identity(2022000000, 1);
--ALTER TABLE M002_Umsatz2023 ADD id int identity(2023000000, 1);

--SELECT * FROM M004_UmsatzGesamtIndex;
*/

SET IDENTITY_INSERT M004_Index ON;

INSERT INTO Adressen (id, CompanyName) VALUES (1234568, 'ppedv'); --Clustered Index Insert f¸r id, Table Insert f¸r CompanyName

CREATE NONCLUSTERED INDEX Test2 ON dbo.Adressen (CompanyName) INCLUDE (Country, Address, City, Region, PostalCode);

DELETE FROM Adressen WHERE CompanyName = 'ppedv'; --Bei DELETE auch ¸ber View + Index

--------------------------------------------------------------------------------------

--Columnstore Index
--Indiziert genau eine Spalte
--Erzeugt effektiv eine Tabelle ¸ber diese eine Spalte
--Jedes Segment ist 2^20 Bytes groﬂ (1048576)
--Segmente die nicht voll gef¸llt werden kˆnnen, werden im Deltastore abgelegt
--Die Segmente werden bei der Suche wieder zusammengeh‰ngt:
-- | S1 | S2 | S3 | S4 | ...

SELECT *
INTO M004_CS
FROM M004_Index;

ALTER TABLE M004_CS DROP COLUMN id;

--INSERT INTO M004_CS
--SELECT * FROM M004_CS
--GO 5

ALTER TABLE M004_CS ADD id int identity;

SELECT * FROM M004_CS;
--Cost 655, logische Lesevorg‰nge: 1056394, CPU-Zeit = 32578 ms, verstrichene Zeit = 257433 ms

SELECT id FROM M004_CS;
--Cost 655, logische Lesevorg‰nge: 1056394, CPU-Zeit = 5469 ms, verstrichene Zeit = 40978 ms

SELECT id FROM M004_CS;
--Cost 4, logische LOB-Lesevorg‰nge: 29199 (large object), CPU-Zeit = 2156 ms, verstrichene Zeit = 73794 ms

SELECT id FROM M004_CS WHERE id BETWEEN 10000 and 100000;

--ColumnStore Indizes ansehen
SELECT OBJECT_NAME(object_id), *
FROM sys.dm_db_column_store_row_group_physical_stats

------------------------------------------------------------------

--Indizes warten
--‹ber Zeit werden die Indizes unorganisiert
---> Reorganize oder Rebuild
--Total Fragmentation: Wie verstreut der Index ist
--Sollte regelm‰ﬂig gemacht werden
--Bei kleinen Indizes: Reorganize, bei groﬂen Indizes: direkt Rebuild