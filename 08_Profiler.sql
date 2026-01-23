--Profiler
--Live Verfolgung aller möglichen DB-Ereignisse
--Kann für den Tuning Advisor verwendet werden

--StmtStarted
--StmtCompleted
--BatchStarted
--BatchCompleted
--Column Filters: DatabaseName LIKE Demo20260120

SELECT * FROM M005_Kompression;

-----------------------------------------------------------------------

--Tracer befüllen

SELECT * FROM M004_Index;

--Table Scan
--Cost: 19.5, logische Lesevorgänge: 26257, CPU-Zeit = 250 ms, verstrichene Zeit = 793 ms
SELECT * FROM M004_Index WHERE OrderID >= 11000;

--Nach Index
--Index Seek
--Cost: 2.02, logische Lesevorgänge: 2684, CPU-Zeit = 125 ms, verstrichene Zeit = 740 ms
SELECT * FROM M004_Index WHERE OrderID >= 11000;

--Auf bestimmte Abfragen Indizes aufbauen
--Table Scan
--Cost: 19.5, logische Lesevorgänge: 26257, CPU-Zeit = 62 ms, verstrichene Zeit = 78 ms
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice
FROM M004_Index
WHERE ProductName = 'Chocolade';

--Nach Index
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice
FROM M004_Index
WHERE ProductName = 'Chocolade';
--Index Seek
--Cost: 0.02, logische Lesevorgänge: 26, CPU-Zeit = 0 ms, verstrichene Zeit = 72 ms

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
--Index Scan, weil die gesuchten Spalten vollständig in dem Index vorhanden sind
--Gesamttabelle muss nicht durchsucht werden, weil die anderen Spalten uninteressant sind für uns
--Cost: 7.12, logische Lesevorgänge: 8861, CPU-Zeit = 328 ms, verstrichene Zeit = 2670 ms

--Weitere, nicht im Index inkludierte Spalten
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice, Freight
FROM M004_Index
WHERE ProductName = 'Chocolade';

-----------------------------------------------------------------------

