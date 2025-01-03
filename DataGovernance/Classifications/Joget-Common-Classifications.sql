use joget_dx8_pom;

select 'ADD SENSITIVITY CLASSIFICATION TO ' + QUOTENAME(TABLE_SCHEMA) + '.'+ QUOTENAME(TABLE_NAME) + '.'+ QUOTENAME(COLUMN_NAME)
    + ' WITH (LABEL = ''General'', INFORMATION_TYPE = ''Audit Trail'', RANK = LOW);'
from INFORMATION_SCHEMA.COLUMNS 
where COLUMN_NAME like 'createdBy%'
or COLUMN_NAME like 'modifiedBy%'
or COLUMN_NAME = 'dateCreated'
or COLUMN_NAME = 'dateModified';



use joget_dx8_pom;

select 'ADD SENSITIVITY CLASSIFICATION TO ' + QUOTENAME(TABLE_SCHEMA) + '.'+ QUOTENAME(TABLE_NAME) + '.'+ QUOTENAME(COLUMN_NAME)
    + ' WITH (LABEL = ''Internal'', INFORMATION_TYPE = ''System Configuration'', RANK = LOW);'
	,*
from INFORMATION_SCHEMA.COLUMNS 
where TABLE_NAME like 'SHK%'



use joget_dx8_pom;

select 'ADD SENSITIVITY CLASSIFICATION TO ' + QUOTENAME(TABLE_SCHEMA) + '.'+ QUOTENAME(TABLE_NAME) + '.'+ QUOTENAME(COLUMN_NAME)
    + ' WITH (LABEL = ''Internal'', INFORMATION_TYPE = ''System Configuration'', RANK = LOW);'
	,*
from INFORMATION_SCHEMA.COLUMNS 
where TABLE_NAME like 'dir%'
and TABLE_NAME <> 'dir_user'
and COLUMN_NAME not like '%name'
and COLUMN_NAME not like 'user%'




select 'ADD SENSITIVITY CLASSIFICATION TO ' + QUOTENAME(TABLE_SCHEMA) + '.'+ QUOTENAME(TABLE_NAME) + '.'+ QUOTENAME(COLUMN_NAME)
    + ' WITH (LABEL = ''Internal'', INFORMATION_TYPE = ''Credentials'', RANK = MEDIUM);'
	,*
from INFORMATION_SCHEMA.COLUMNS 
where TABLE_NAME like 'dir%'
and ( COLUMN_NAME like '%name' or COLUMN_NAME like 'user%')

