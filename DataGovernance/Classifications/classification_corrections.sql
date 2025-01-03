
use DBA
go 


select 'USE ' + QUOTENAME(databasename) + '; ADD SENSITIVITY CLASSIFICATION TO '+ QUOTENAME(table_schema) + '.' + QUOTENAME(table_name) + '.' + QUOTENAME(column_name) + 
		' WITH (LABEL = ''Confidential'', INFORMATION_TYPE = '''+ classify_info_type +''', RANK = MEDIUM );'
		,* 
from data_catalog where classify_label = 'Confidential - Pseudonymize'
order by instancename;


select 'USE ' + QUOTENAME(databasename) + '; ADD SENSITIVITY CLASSIFICATION TO '+ QUOTENAME(table_schema) + '.' + QUOTENAME(table_name) + '.' + QUOTENAME(column_name) + 
		' WITH (LABEL = ''Confidential'', INFORMATION_TYPE = '''+ 'Name' +''', RANK = MEDIUM );'
		,* 
from data_catalog 
where classify_label = 'Confidential - Pseudonymize'
order by instancename;

