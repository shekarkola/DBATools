---- CONNECT: G42PR-SQL05\INST2 (DBA)
use DBA
go 


create view pbi_datacatalog as 

select instancename, databasename, objectid, table_schema, [table_name], [column_name], data_type, is_nullable, column_default
        ,[length], [precision], collation_name, classify_info_type, classify_label, classify_rank
        ,created_on, modified_on
from data_catalog
where is_deleted = 0 