DROP DATABASE IF EXISTS	Demo20260120;
CREATE DATABASE Demo20260120;

/*
	Was sollte beachtet werden, beim Aufbau einer Datenbank?
	- 1. Jede Zelle sollte nur einen Wert beinhalten; wenn eine Zelle mehrere Werte beinhält, sollte diese in mehrere Spalten aufgeteilt werden
	- 2. Jeder Datensatz muss einen Primary Key haben
	- 3. Beziehungen sollten nur zwischen Schlüsselspalten sein (Primary Keys)

	Redundanz vermeiden (Daten nicht doppelt speichern)
	- Weniger Speicherbedarf
	- Keine Inkonsistenz -> Referenzen können sich nicht unterscheiden
	- Beziehungen zw. den Tabellen
	- Größere Tabellen in kleinere Tabellen aufteilen

	Beziehungen
	Orders <-> Addresses <-> Customers
*/

-- Verbesserung Northwind
USE Northwind;

DROP TABLE IF EXISTS Addresses;
CREATE TABLE Addresses
(
	AddressID int identity primary key,
	Address varchar(60),
	City varchar(15),
	Region varchar(15),
	PostalCode varchar(10),
	Country varchar(15)
);

INSERT INTO Addresses
SELECT ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry
FROM Orders
GROUP BY ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry;

--ALTER TABLE Orders ADD AddressID INT;

--Cursor: Zeiger, der auf einzelne Zeilen in der Tabelle zeigt
--Tabelle Zeile für Zeile durchgehen
DECLARE OrderCursor CURSOR FOR 
SELECT ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry FROM Orders;  --Tabelle definieren, welche angegriffen werden soll

DECLARE OrderIDCursor CURSOR FOR
SELECT OrderID FROM Orders;

DECLARE @ShipAddress nvarchar(60), @ShipCity nvarchar(15), @ShipRegion nvarchar(15), @ShipPostalCode nvarchar(10), @ShipCountry nvarchar(15);
DECLARE @CurrentOrderID int;

OPEN OrderCursor;
OPEN OrderIDCursor;

--Einmal Fetchen um den Cursor zu betreten
FETCH NEXT FROM OrderCursor INTO @ShipAddress, @ShipCity, @ShipRegion, @ShipPostalCode, @ShipCountry;
FETCH NEXT FROM OrderIDCursor INTO @CurrentOrderID;

WHILE @@FETCH_STATUS = 0  --@@FETCH_STATUS = 0: Sind noch weitere Daten vorhanden?
BEGIN
	FETCH NEXT FROM OrderCursor INTO @ShipAddress, @ShipCity, @ShipRegion, @ShipPostalCode, @ShipCountry;
	FETCH NEXT FROM OrderIDCursor INTO @CurrentOrderID;

	DECLARE @FoundID int =
	(SELECT TOP 1 AddressID
	FROM Addresses
	WHERE Address = @ShipAddress AND City = @ShipCity AND Region = @ShipRegion AND PostalCode = @ShipPostalCode AND Country = @ShipCountry);

	UPDATE Orders SET AddressID = @FoundID WHERE OrderID = @CurrentOrderID;
END

CLOSE OrderCursor;
CLOSE OrderIDCursor;
DEALLOCATE OrderCursor;
DEALLOCATE OrderIDCursor;

--ALTER TABLE Orders DROP ShipAddress;
--Alle Adressenspalten droppen

-------------------------------------------------------------------

/*
	Seiten:
	8192 Byte große Blöcke (8KB)
	Werden immer vollständig vom DB Server gelesen
	8060B für tatsächliche Daten
	132B für Management Daten

	Max. 700DS pro Seite
	Ein Datensatz muss immer auf eine Seite passen (darf nicht herausragen)
	-> Leerer Raum sollte minimiert werden (Füllgrad in Prozent)
*/

--dbcc: Database Console Commands
--Normalerweise, werden diese Befehle auf dem Server selbst eingegeben (meistens per Secure Shell)

--showcontig: Zeigt Seiteninformationen zu einem DB Objekt an
dbcc showcontig('Orders')

--Wichtige Zahlen:
--Bytes frei pro Seite (Durchschnitt), Mittlere Seitendichte (voll)
--Füllgrad sollte maximiert werden -> Weniger Seiten laden -> Geschwindigkeit
--80%: OK, 90% Gut, > 95%: Sehr Gut

USE Demo20260120;

--Absichtlich ineffizient
CREATE TABLE M001_Test1
(
	id int identity,
	test char(4100)
);

INSERT INTO M001_Test1
VALUES('ABC')
GO 20000  --Befehl X mal ausführen

dbcc showcontig('M001_Test1')
-- Mittlere Seitendichte (voll).....................: 50.79%
-- Weil 4100 nicht zweimal auf eine Seite passt

CREATE TABLE M001_Test2
(
	id int identity,
	test varchar(4100)
);

INSERT INTO M001_Test2
VALUES('ABC')
GO 20000  --Befehl X mal ausführen

dbcc showcontig('M001_Test2')
-- Mittlere Seitendichte (voll).....................: 95.01%
-- varchar verkleinert sich automatisch, im Gegensatz zu char
-- WICHTIG: varchar benötigt von Haus aus immer 2 Byte mehr pro Datensatz als char

CREATE TABLE M001_Test3
(
	id int identity,
	test varchar(max)
);

INSERT INTO M001_Test3
VALUES('ABC')
GO 20000  --Befehl X mal ausführen

dbcc showcontig('M001_Test3')
-- Mittlere Seitendichte (voll).....................: 95.01%
-- Selbes Ergebnis wie davor

CREATE TABLE M001_Test4
(
	id int identity,
	test nvarchar(max)
);

INSERT INTO M001_Test4
VALUES('ABC')
GO 20000  --Befehl X mal ausführen

dbcc showcontig('M001_Test4')
-- Mittlere Seitendichte (voll).....................: 94.70%
-- Seiten 52 -> 60 (13% mehr Seiten)
-- nvarchar nur verwenden, wenn notwendig

-------------------------------------------------------------------

--Statistiken für Zeit und Lesevorgängen aktivieren/deaktivieren
SET STATISTICS time, io ON;

USE Northwind;

--sys.dm_db_index_physical_stats: Gesamtstatistiken über die DB anzeigen
SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');

-------------------------------------------------------------------

--Northwind optimieren
--Customers Tabelle

dbcc showcontig('Customers'); --72.81%

--Datentypen

--Text
--char(X): Fixe Länge (1B pro Zeichen, immer X Byte groß)
--varchar: Variable Länge (1B pro Zeichen, kann sich selbst verkleinern -> Inhalt Bytes groß + 2B, 2B für Verkleinerung notwendig)
--nchar, nvarchar: Unicode Varianten von den beiden obigen Typen, 2B pro Zeichen (nur wenn notwendig verwenden)
--text: nicht verwenden

--Numerische Typen
--tinyint, smallint, int, bigint
--1B, 2B, 4B, 8B
--Maxima: 256, 65536, 2147483648, 18446744073709552000

--Kommazahlen
--float: 8B
--decimal: Anzahl Vorkommastellen und Gesamtstellen müssen hier angegeben werden

--Datumswerte
--datetime: 8B
--Date: 3B
--Time: 3B-5B (je nach Präzision)
--datetime2: 6B bis 8B (je nach Länge des Millisekundenanteils)

--Customers:
--nvarchar durch varchar austauschen bei [PostalCode],[Country],[Phone],[Fax]
--nchar kann durch char ersetzt werden

-- Bytes frei pro Seite (Durchschnitt).....................: 2200.5
-- Mittlere Seitendichte (voll).....................: 72.81%
ALTER TABLE Customers ALTER COLUMN PostalCode varchar(10);
ALTER TABLE Customers ALTER COLUMN Country varchar(15);
ALTER TABLE Customers ALTER COLUMN Phone varchar(24);
ALTER TABLE Customers ALTER COLUMN Fax varchar(24);
ALTER TABLE Customers ALTER COLUMN CustomerID char(5);
ALTER TABLE Orders ALTER COLUMN CustomerID char(5);

dbcc showcontig('Customers'); --72.81%