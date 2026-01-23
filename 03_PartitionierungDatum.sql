USE Demo20260120;

DROP PARTITION SCHEME sch_Datum;
DROP PARTITION FUNCTION pf_Datum;

CREATE PARTITION FUNCTION pf_Datum(DATE) AS
RANGE LEFT FOR VALUES('20211231', '20221231', '20231231')

CREATE PARTITION SCHEME sch_Datum AS
PARTITION pf_Datum TO (P1, P2, P3, P4)

DROP TABLE M003_Umsatz;

CREATE TABLE M003_Umsatz
(
	datum date,
	umsatz float,
	constraint pk primary key (datum, umsatz)
);

INSERT INTO M003_Umsatz
SELECT * FROM M002_Umsatz;

select * from M003_Umsatz order by 1;

select OBJECT_NAME(object_id), * from sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')

insert into M003_Umsatz values ('20250101', 123);