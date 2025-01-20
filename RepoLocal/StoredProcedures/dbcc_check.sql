USE [DBAClient]
GO
/****** Object:  StoredProcedure [dbo].[DBCC_CHECK]    Script Date: 1/20/2025 1:34:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:			SHEKAR KOLA
-- Create date:		2019-09-03
-- Modified date:	2019-10-03
-- Description:	
-- =============================================
ALTER PROCEDURE [dbo].[DBCC_CHECK]
	-- Add the parameters for the stored procedure here
	@DBName sysname = null,
	@ExcludeDBs sysname = null
AS
BEGIN
	SET NOCOUNT ON;

		Declare @DBCCommand nvarchar (500);
		Declare @Databases Table (DBName sysname);

		Declare @is_DB_HADREnabled bit;
		Declare @isPrimaryReplica bit;

IF (SELECT OBJECT_ID ('dbcc_history')) IS NULL 
	BEGIN 
		CREATE TABLE [dbo].[DBCC_HISTORY](
			[InstanceFullName] [nvarchar](256) NULL,
			[Error] [int] NULL,
			[Level] [int] NULL,
			[State] [int] NULL,
			[MessageText] [varchar](7000) NULL,
			[RepairLevel] [int] NULL,
			[Status] [int] NULL,
			[DbId] [int] NULL,
			[DbFragId] [int] NULL,
			[ObjectId] [int] NULL,
			[IndexId] [int] NULL,
			[PartitionID] [int] NULL,
			[AllocUnitID] [int] NULL,
			[RidDbId] [int] NULL,
			[RidPruId] [int] NULL,
			[File] [int] NULL,
			[Page] [int] NULL,
			[Slot] [int] NULL,
			[RefDbId] [int] NULL,
			[RefPruId] [int] NULL,
			[RefFile] [int] NULL,
			[RefPage] [int] NULL,
			[RefSlot] [int] NULL,
			[Allocation] [int] NULL,
			[LogDatetime] [datetime] NULL
		);
		ALTER TABLE [dbo].[DBCC_HISTORY] ADD  DEFAULT (getdate()) FOR [LogDatetime];
	END

	IF (@DBName is null)
	BEGIN
	insert into @Databases
		select name
		from sys.databases
		where name not in ('model','tempdb')
				and source_database_id is null 
				and is_read_only = 0
				and state = 0
				and name not in (select value from string_split(@ExcludeDBs, ','));
	END

	IF @DBName is not null 
	BEGIN
		Insert into @Databases 
		select distinct value from string_split(@DBName, ',')
		where value not in (select value from string_split(@ExcludeDBs, ','));
	END
	

	While exists (select * from @Databases)
	begin 
		set @DBName = (select top 1  DBName from @Databases);
		set @DBCCommand = 'DBCC CHECKDB (' ;
		set @DBCCommand = @DBCCommand + (select QUOTENAME(@DBName) + ') with TableResults, NO_INFOMSGS; ' );

		--Validate if database par of AG -----------------------------------------------------------------------------------------------------
			Select @is_DB_HADREnabled = IIF(group_database_id IS NULL, 0,1) from sys.databases where [name] = @DBName;
			BEGIN
				IF EXISTS (select db.name
							from sys.dm_hadr_database_replica_states as hadr
								join sys.databases as db on hadr.group_database_id = db.group_database_id
							where is_local = 1 and is_primary_replica = 1 and db.name = @DBName
							)
					SET @isPrimaryReplica = 1 
				ELSE 
					SET @isPrimaryReplica = 0 
			END
		--Validate if database par of AG -----------------------------------------------------------------------------------------------------
		IF @is_DB_HADREnabled = 0 or @isPrimaryReplica = 1
			BEGIN
				BEGIN TRY 
					Print FORMAT (GETDATE(), 'yyyy-MM-dd HH:MM:ss') + ' DBCC execution Started for '+ @DBName + '; '; 
					Print FORMAT (GETDATE(), 'yyyy-MM-dd HH:MM:ss') + ' Executing... '+ @DBCCommand ; 
					Insert into dbcc_history 
								(	[Error] ,
									[Level] ,
									[State] ,
									[MessageText] ,
									[RepairLevel] ,
									[Status] ,
									[DbId] ,
									[DbFragId] ,
									[ObjectId] ,
									[IndexId] ,
									[PartitionID] ,
									[AllocUnitID] ,
									[RidDbId] ,
									[RidPruId] ,
									[File] ,
									[Page] ,
									[Slot] ,
									[RefDbId] ,
									[RefPruId],
									[RefFile] ,
									[RefPage] ,
									[RefSlot] ,
									[Allocation] 
								)
					Exec (@DBCCommand);
				END TRY 
		
				BEGIN CATCH
						SELECT 	 ERROR_NUMBER() AS ErrorNumber
								,ERROR_SEVERITY() as ErrorSeverity
								,ERROR_LINE() AS ErrorLine 
								,ERROR_MESSAGE() AS ErrorMessage;
						DELETE FROM @Databases where dbname = @DBName
				END CATCH
				Update dbcc_history set InstanceFullName = @@SERVERNAME where DbId = DB_ID (@DBName);
				Print FORMAT (GETDATE(), 'yyyy-MM-dd HH:MM:ss') + ' DBCC execution Completed for ' + @DBName + '; '; 
				DELETE FROM @Databases where dbname = @DBName;
			END
			--Validate/execute database par of AG END-----------------------------------------------------------------------------------------------------
		ELSE
		Print FORMAT (GETDATE(), 'yyyy-MM-dd HH:MM:ss') + ' Database [' + @DBName + '] is part of AG and this is not primary replica; '; 
		DELETE FROM @Databases where dbname = @DBName;
	END

END
