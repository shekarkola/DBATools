---> Contact Info: 
select 'ADD SENSITIVITY CLASSIFICATION TO ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.'+ QUOTENAME(t.name) + '.'+ QUOTENAME(c.name)
		+ ' WITH (LABEL = ''Confidential - GDPR'', INFORMATION_TYPE = ''Contact Info'', RANK = MEDIUM);'
		,t.name as tablename, c.name as colname, ty.name as data_type
from  sys.all_columns as c 
join sys.tables as t on c.object_id = t.object_id 
join sys.types as ty on c.user_type_id = ty.system_type_id
where c.name like '%email%' 
and (ty.name = 'varchar' OR ty.name = 'text' OR ty.name = 'ntext' OR ty.name = 'nvarchar' OR ty.name = 'char' OR ty.name = 'nchar' OR ty.name = 'sysname');


	---> Drop wrong classification: 
	select	'DROP SENSITIVITY CLASSIFICATION FROM ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.'+ QUOTENAME(t.name) + '.'+ QUOTENAME(c.name) + ';' 
			,t.name as tablename, c.name as colname, ty.name as data_type
			,sc.label, sc.information_type
	from sys.sensitivity_classifications as sc 
	join sys.tables as t on sc.major_id = t.object_id
	join sys.all_columns as c on sc.major_id = c.object_id and sc.minor_id = c.column_id
	join sys.types as ty on c.user_type_id = ty.system_type_id
	where c.name like '%email%' 
	and ty.name NOT IN ('varchar' ,'text' ,'ntext' ,'nvarchar' ,'char', 'nchar', 'sysname')


select 'ADD SENSITIVITY CLASSIFICATION TO ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.'+ QUOTENAME(t.name) + '.'+ QUOTENAME(c.name)
		+ ' WITH (LABEL = ''Confidential - GDPR'', INFORMATION_TYPE = ''Contact Info'', RANK = MEDIUM);'
		,t.name as tablename, c.name as colname, ty.name as data_type
from  sys.all_columns as c 
join sys.tables as t on c.object_id = t.object_id 
join sys.types as ty on c.user_type_id = ty.system_type_id
where (c.name like '%phone%' or c.name like '%phonenum%' or c.name like '%contact%'or c.name like '%contactnum%')
and (ty.name = 'varchar' OR ty.name = 'text' OR ty.name = 'ntext' OR ty.name = 'nvarchar' OR ty.name = 'char' OR ty.name = 'nchar' OR ty.name = 'sysname');

	---> Drop wrong classifications: 
	select	'DROP SENSITIVITY CLASSIFICATION FROM ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.'+ QUOTENAME(t.name) + '.'+ QUOTENAME(c.name) + ';' 
			,t.name as tablename, c.name as colname, ty.name as data_type
			,sc.label, sc.information_type
	from sys.sensitivity_classifications as sc 
	join sys.tables as t on sc.major_id = t.object_id
	join sys.all_columns as c on sc.major_id = c.object_id and sc.minor_id = c.column_id
	join sys.types as ty on c.user_type_id = ty.system_type_id
	where (c.name like '%phone%' or c.name like '%phonenum%' or c.name like '%contact%'or c.name like '%contactnum%')
	and ty.name NOT IN ('varchar' ,'text' ,'ntext' ,'nvarchar' ,'char', 'nchar', 'sysname')

----> Credentials 
select 'ADD SENSITIVITY CLASSIFICATION TO ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.'+ QUOTENAME(t.name) + '.'+ QUOTENAME(c.name)
		+ ' WITH (LABEL = ''Internal'', INFORMATION_TYPE = ''Credentials'', RANK = MEDIUM);'
		,t.name as tablename, c.name as colname, ty.name as data_type
from  sys.all_columns as c 
join sys.tables as t on c.object_id = t.object_id 
join sys.types as ty on c.user_type_id = ty.system_type_id
where (c.name like '%userid%' or c.name like '%username%' or c.name like '%user[_]id%'  or c.name like '%user[_]name%' or c.name like '%password%')
and (ty.name = 'varchar' OR ty.name = 'text' OR ty.name = 'ntext' OR ty.name = 'nvarchar' OR ty.name = 'char' OR ty.name = 'nchar' OR ty.name = 'sysname');


-----> Audit Trail
select 'ADD SENSITIVITY CLASSIFICATION TO ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.'+ QUOTENAME(t.name) + '.'+ QUOTENAME(c.name)
		 + ' WITH (LABEL = ''General'', INFORMATION_TYPE = ''Audit Trail'', RANK = LOW);'
		,t.name as tablename, c.name as colname, ty.name as data_type
from  sys.all_columns as c 
join sys.tables as t on c.object_id = t.object_id 
join sys.types as ty on c.user_type_id = ty.system_type_id
where (c.name like 'CREATED%' OR c.name like 'MODIFIED%')
and (ty.name = 'varchar' OR ty.name = 'text' OR ty.name = 'ntext' OR ty.name = 'nvarchar' OR ty.name = 'char' OR ty.name = 'nchar' OR ty.name = 'sysname' 
	OR ty.name like 'date%');

GO 