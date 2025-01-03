use DBA 
go


create view [dbo].[pbi_classify_label] as 

select distinct classify_label
from data_catalog
where is_deleted = 0 
GO

create view [dbo].[pbi_classify_infotype] as 

select distinct classify_info_type
from data_catalog
where is_deleted = 0 
GO

create view [dbo].[pbi_classif_severity] as 

select distinct classify_rank
from data_catalog
where is_deleted = 0 
GO