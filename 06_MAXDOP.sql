--MAXDOP
--Maximum Degree of Parallelism
--Anzahl Prozessorkerne einschränken, pro Abfrage
--SQL Server entscheidet selbstständig über Parallelisierung

--MAXDOP kann auf 3 verschiedenen Ebenen gesetzt werden:
--Query > DB > Server

--Cost Threshold for Parallelism: Mindeste Kosten im Execution Plan für Parallelisierung
--MAXDOP: Gibt die maximale Anzahl der zu verwendenden CPU-Kerne an

USE Demo20260120;

SET STATISTICS time, io ON;

--Keine Einstellungen
SELECT Freight, FirstName, LastName
FROM M004_Index
WHERE Freight > (SELECT AVG(Freight) FROM M004_Index);
--CPU-Zeit = 234 ms, verstrichene Zeit = 921 ms (MAXDOP 10, Server)

--MAXDOP auf Query Ebene
SELECT Freight, FirstName, LastName
FROM M004_Index
WHERE Freight > (SELECT AVG(Freight) FROM M004_Index)
OPTION(MAXDOP 1);
--CPU-Zeit = 203 ms, verstrichene Zeit = 759 ms

SELECT Freight, FirstName, LastName
FROM M004_Index
WHERE Freight > (SELECT AVG(Freight) FROM M004_Index)
OPTION(MAXDOP 2);
--CPU-Zeit = 345 ms, verstrichene Zeit = 863 ms

SELECT Freight, FirstName, LastName
FROM M004_Index
WHERE Freight > (SELECT AVG(Freight) FROM M004_Index)
OPTION(MAXDOP 4);
--CPU-Zeit = 578 ms, verstrichene Zeit = 712 ms

SELECT Freight, FirstName, LastName
FROM M004_Index
WHERE Freight > (SELECT AVG(Freight) FROM M004_Index)
OPTION(MAXDOP 8);
--CPU-Zeit = 501 ms, verstrichene Zeit = 769 ms