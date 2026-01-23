--Kompression

--Daten verkleinern
--Weniger Daten laden, dafür aber mehr Leistung beim Dekomprimieren verwenden

--Zwei Typen:
--Row Compression: 50%
--Page Compression: 75%
--Page Compression setzt Row Compression voraus

USE Demo20260120;

SELECT *
INTO M005_Kompression
FROM M004_Index;

SET STATISTICS time, io ON;

--Rechtsklick auf die Tabelle -> Storage -> Manage Compression

SELECT * FROM M005_Kompression;
--Ohne Kompression
--logische Lesevorgänge: 26562, CPU-Zeit = 782 ms, verstrichene Zeit = 7474 ms

--Row Compression
--Vorher: 207MB, Nachher: 125MB, 40% Ersparnis
SELECT * FROM M005_Kompression;
--logische Lesevorgänge: 15947, CPU-Zeit = 828 ms, verstrichene Zeit = 6975 ms

--Page Compression
--Vorher: 124MB, Nachher: 62MB, 50% Ersparnis
--Original: 207MB, 70% Ersparnis
SELECT * FROM M005_Kompression;
--logische Lesevorgänge: 7792, CPU-Zeit = 1454 ms, verstrichene Zeit = 7519 ms

--Partitionen können auch komprimiert werden
--Selber Assistent

--Kompression auf der DB allgemein anschauen
SELECT t.name AS TableName, p.partition_number AS PartitionNumber, p.data_compression_desc AS Compression
FROM sys.partitions AS p
JOIN sys.tables AS t ON t.object_id = p.object_id;