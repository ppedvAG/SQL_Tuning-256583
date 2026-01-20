/*
	Dateigruppen:
	Datenbank aufteilen in Dateien
	Dateigruppe: Logische Einheit auf dem Datenbankserver
	Datei: Eigentliche Datei, die auf beliebige Datenträger gelegt werden kann

	[PRIMARY]: Hauptgruppe, existiert immer, enthält standardmäßig alle Files (kann leer bleiben)

	Die Hauptdatei hat die Endung .mdf
	Die Logdatei hat die Endung .ldf
	Die Nebendateien haben die Endung .ndf
*/

USE Demo20260120;

/*
	Rechtsklick auf die Datenbank -> Properties
	Filegroup erstellen -> Files erstellen
	Logical Name: Name den der SQL Server verwendet
	File Name: Dateiname im Ordner auf dem System selbst
*/

CREATE TABLE M002_Test1
(
	id int identity,
	test char(4100)
)
ON Aktiv;

INSERT INTO M002_Test1 VALUES('XYZ')
GO 10000  --Autogrowth wird aktiviert

--Wie kann ich eine Tabelle verschieben, die auf einer anderen Dateigruppe ist?
--Neu erstellen, Daten verschieben, alte Tabelle löschen
--Problem: Foreign Keys
CREATE TABLE M002_Archiv
(
	id int identity,
	test char(4100)
) ON Archiv;

INSERT INTO M002_Archiv
SELECT test FROM M002_Test1;

DROP TABLE M002_Test1;

--Dateigruppe wieder verkleinern:
--DBCC SHRINKFILE ('Archiv', 8);

-----------------------------------------------------

--Salamitaktik
--Aufteilung von großen Tabellen in mehrere kleine Tabellen
--Über eine indizierte View können alle Tabellen verbunden werden
--Wenn die View allgemein angesprochen wird, greift diese nur auf die Tabellen zu, die auch tatsächlich benötigt werden

CREATE TABLE M002_Umsatz
(
	datum date,
	umsatz float
);

--Transactions: Speichern den Zwischenstand von Statements temporär
--Danach kann dieser Stand angeschaut werden
--Bei Fehlerfällen kann ein Rollback gemacht werden
--Wenn alles in Ordnung ist, kann ein Commit gemacht werden (um diese Änderungen zu speichern)
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED: Daten ansehen, während der Transaction
BEGIN TRANSACTION;
DECLARE @i int = 0;
WHILE @i < 100000
BEGIN
	INSERT INTO M002_Umsatz VALUES
	(DATEADD(DAY, FLOOR(RAND()*1095), '20210101'), RAND() * 1000);
	SET @i += 1;
END
COMMIT;

TRUNCATE TABLE M002_Umsatz;  --Alle Daten löschen

/*
	Pläne: Zeigen den Pfad des SQL-Statements an
	- Gelesene Zeilen
	- Verbrauchte Zeit
	- ...

	Button: Include Actual Execution Plan
*/

SET STATISTICS time, io ON;

SELECT * FROM M002_Umsatz;  --Table Scan: Gesamte Tabelle wird durchsucht

-----------------------------------------------------

CREATE TABLE M002_Umsatz2021
(
	datum date,
	umsatz float,
	CONSTRAINT Umsatz2021 CHECK(YEAR(datum) = 2021)
);

CREATE TABLE M002_Umsatz2022
(
	datum date,
	umsatz float
);

CREATE TABLE M002_Umsatz2023
(
	datum date,
	umsatz float
);

ALTER TABLE M002_Umsatz2022 ADD CONSTRAINT Umsatz2022 CHECK(YEAR(datum) = 2022);
ALTER TABLE M002_Umsatz2023 ADD CONSTRAINT Umsatz2023 CHECK(YEAR(datum) = 2023);

INSERT INTO M002_Umsatz2021 SELECT * FROM M002_Umsatz WHERE YEAR(datum) = 2021;
INSERT INTO M002_Umsatz2022 SELECT * FROM M002_Umsatz WHERE YEAR(datum) = 2022;
INSERT INTO M002_Umsatz2023 SELECT * FROM M002_Umsatz WHERE YEAR(datum) = 2023;

--Alle Daten anzeigen
SELECT * FROM M002_Umsatz2021
UNION ALL
SELECT * FROM M002_Umsatz2022
UNION ALL
SELECT * FROM M002_Umsatz2023

--Indizierte View
--Greift nur auf Tabellen zu, die auch benötigt werden
CREATE VIEW M002_UmsatzGesamt
AS
SELECT * FROM M002_Umsatz2021
UNION ALL
SELECT * FROM M002_Umsatz2022
UNION ALL
SELECT * FROM M002_Umsatz2023

SELECT *
FROM M002_UmsatzGesamt
WHERE YEAR(datum) = 2021;