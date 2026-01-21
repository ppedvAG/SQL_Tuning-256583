/*
	Partionierung:
	Logische Aufteilung in "mehrere" Tabellen
	Eine einzelne normale Tabelle mit logischen Untertabellen (Untergruppen)
	SQL Server macht SELECT/INSERT komplett transparent
*/

--Anforderungen:
--Partitionsfunktion: Bestimmt anhand eines Inputs die Bereiche (z.B.: 0-100, 101-200, 201-300, Rest)
--Partitionsschema: Legt anhand der Partitionsfunktion die Daten in die entsprechenden Filegruppen hinein

USE Demo20260120;

CREATE PARTITION FUNCTION pfZahl(int) AS
RANGE LEFT FOR VALUES(100, 200); --0-100, 101-200, 201-Ende

--CREATE PARTITION SCHEME schZahl AS
--PARTITION pfZahl TO (P1, P2, P3); --Vorher Filegruppen erstellen

--Filegruppe + File per Code erstellen
ALTER DATABASE [Demo20260120] ADD FILEGROUP [P1];

ALTER DATABASE [Demo20260120] ADD FILE
(
	NAME = N'P1',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\Demo20260120_P1.ndf',
	SIZE = 8192KB,
	FILEGROWTH = 65536KB
)
TO FILEGROUP [P1];

ALTER DATABASE [Demo20260120] ADD FILEGROUP [P2];

ALTER DATABASE [Demo20260120] ADD FILE
(
	NAME = N'P2',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\Demo20260120_P2.ndf',
	SIZE = 8192KB,
	FILEGROWTH = 65536KB
)
TO FILEGROUP [P2];

ALTER DATABASE [Demo20260120] ADD FILEGROUP [P3];

ALTER DATABASE [Demo20260120] ADD FILE
(
	NAME = N'P3',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\Demo20260120_P3.ndf',
	SIZE = 8192KB,
	FILEGROWTH = 65536KB
)
TO FILEGROUP [P3];

--Jetzt Schema anlegen
CREATE PARTITION SCHEME schZahl AS
PARTITION pfZahl TO (P1, P2, P3);

---------------------------------------------------------------------

--Jetzt Tabelle erstellen
CREATE TABLE M003_Test
(
	id int identity,
	zahl float
) ON schZahl(id);  --Hier Schema + Spalte angeben, nach der Partitioniert werden soll

BEGIN TRAN;
DECLARE @i int = 0;
WHILE @i < 100000
BEGIN
	INSERT INTO M003_Test VALUES (RAND() * 1000);
	SET @i += 1;
END
COMMIT;

--Nichts besonderes zu sehen
SELECT * FROM M003_Test;

--SELECT mit einer Einschränkung (WHERE)
SELECT * FROM M003_Test WHERE id <= 50;

--Partitionen überblicken
SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');

--Prüfen, in welchen Bereich ein Datensatz kommen würde
SELECT $partition.pfZahl(50); --1
SELECT $partition.pfZahl(150); --2
SELECT $partition.pfZahl(250); --3

--Die Partitionsfunktion kann auch Zwecksentfremdet werden
--Bereiche angeben und einfach nur die Funktion benutzen ohne Partitionen
SELECT COUNT(*)
FROM M003_Test
GROUP BY $partition.pfZahl(id);  --Jedem Datensatz eine Zahl anhand der PF zuweisen, danach gruppieren

--Beispiel: Jahreszahlen
--Herausfinden, wieviele Datensätze es pro Jahr gibt
--PF anlegen mit Jahreszahlen (2026, 2025, 2024, ...)
--GROUP BY auf beliebige Tabelle mit dieser PF im GROUP BY
--Tabelle muss dafür nicht partitioniert sein

---------------------------------------------------------------------

--Übersicht über alle Partitionen finden
SELECT * FROM sys.filegroups;
SELECT * FROM sys.allocation_units;

SELECT OBJECT_NAME(ips.object_id), name, ips.partition_number FROM sys.filegroups fg
JOIN sys.allocation_units au ON fg.data_space_id = au.data_space_id
JOIN sys.partitions p ON p.hobt_id = au.container_id
JOIN sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED') ips ON ips.hobt_id = p.hobt_id

--Daten per Partition bewegen
CREATE TABLE M003_Archiv
(
	id int identity,
	zahl float
) ON P1;  --Liegt auf P1 (Filegroup, nicht partitioniert)

ALTER TABLE M003_Test
SWITCH PARTITION(1) TO M003_Archiv;

--Per Hand
SELECT * FROM M003_Test WHERE $partition.pfZahl(id) = 2;

SET IDENTITY_INSERT M003_Archiv ON;

INSERT INTO M003_Archiv (id, zahl)
SELECT * FROM M003_Test WHERE $partition.pfZahl(id) = 2;

DELETE FROM M003_Test WHERE $partition.pfZahl(id) = 2;

SET IDENTITY_INSERT M003_Archiv OFF;

SELECT * FROM M003_Archiv;

--Prozeduren
DROP PROCEDURE MoveData;
GO
CREATE PROC MoveData (@partitionNumber int) AS
BEGIN
	SET IDENTITY_INSERT M003_Archiv ON;

	INSERT INTO M003_Archiv (id, zahl)
	SELECT * FROM M003_Test WHERE $partition.pfZahl(id) = @partitionNumber;

	DELETE FROM M003_Test WHERE $partition.pfZahl(id) = @partitionNumber;

	SET IDENTITY_INSERT M003_Archiv OFF;
END
GO

EXEC MoveData @partitionNumber = 3;

---------------------------------------------------------------------

--Neue Partition per Prozedur
DROP PROCEDURE NewPartition;
GO
CREATE PROC NewPartition(@newRange int) AS
BEGIN
	DECLARE @newMax int = (SELECT $partition.pfZahl(@newRange) + 1);
	
	DECLARE @path varchar(200) = CONCAT(N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\Demo20260120_P', @newMax, '.ndf');

	DECLARE @sql varchar(MAX) = CONCAT(
		'ALTER DATABASE [Demo20260120] ADD FILEGROUP [P', @newMax, '];',
		'ALTER DATABASE [Demo20260120] ADD FILE
		 (
		 	NAME = N''P', @newMax, ''',
		 	FILENAME = N''', @path, ''',
		 	SIZE = 8192KB,
		 	FILEGROWTH = 65536KB
		 )
		 TO FILEGROUP [P', @newMax,'];',
		'ALTER PARTITION SCHEME schZahl NEXT USED P', @newMax,';',
		'ALTER PARTITION FUNCTION pfZahl() SPLIT RANGE (', @newRange,')');
	EXEC (@sql);  --Raw SQL: Text als SQL ausführen
END

EXEC NewPartition @newRange = 300;

INSERT INTO M003_Test VALUES (123);