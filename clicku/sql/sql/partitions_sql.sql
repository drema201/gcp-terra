CREATE TABLE visits
(
    VisitDate Date,
    Hour UInt8,
    ClientID UUID
 )
ENGINE = MergeTree()
PARTITION BY toDate(VisitDate)
ORDER BY Hour;

CREATE TABLE visits2
(
    VisitDate Date,
    EventType String, --Nullable(String)  DB::Exception: Partition key contains nullable columns, but `setting allow_nullable_key` is disabled
    UserID  String  --Nullable(String) Sorting key contains nullable columns, but `setting allow_nullable_key` is disabled
 )
ENGINE = MergeTree()
PARTITION BY (toDate(VisitDate), EventType)
ORDER BY (EventType, VisitDate, UserID);

select name, table, database,active from system.parts WHERE table='visits2';