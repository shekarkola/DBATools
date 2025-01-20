USE [DBAClient]
GO

-- Create the stored procedure
CREATE OR ALTER PROCEDURE [dbo].[collect_server_properties]
AS
BEGIN
    DECLARE @defaultDataPath NVARCHAR(4000);
    DECLARE @defaultLogPath NVARCHAR(4000);
    DECLARE @backupPath NVARCHAR(4000);
    DECLARE @maxDOP INT;
    DECLARE @costThreshold INT;
    DECLARE @maxMemoryMB BIGINT;
    DECLARE @instanceFullName NVARCHAR(128);
    DECLARE @timestamp DATETIME;

	IF (SELECT OBJECT_ID('server_properties')) IS NULL 
		BEGIN 
		CREATE TABLE [dbo].[server_properties](
			[InstanceFullName] [nvarchar](200) NULL,
			[DefaultDataLocation] [nvarchar](4000) NULL,
			[DefaultLogLocation] [nvarchar](4000) NULL,
			[DefaultBackupLocation] [nvarchar](4000) NULL,
			[MaxDOP] [int] NULL,
			[CostThreshold] [int] NULL,
			[SQLServerVersion] [nvarchar](100) NULL,
			[ProductLevel] [nvarchar](100) NULL,
			[Edition] [nvarchar](100) NULL,
			[MaxMemoryMB] [bigint] NULL,
			[Timestamp] [datetime2](7) NULL
		);
		END 
    -- Get current timestamp
    SET @timestamp = GETDATE();

    -- Retrieve Default Data Location
    EXEC master.dbo.xp_instance_regread 
        N'HKEY_LOCAL_MACHINE', 
        N'Software\Microsoft\MSSQLServer\MSSQLServer', 
        N'DefaultData', 
        @defaultDataPath OUTPUT;

    -- Retrieve Default Log Location
    EXEC master.dbo.xp_instance_regread 
        N'HKEY_LOCAL_MACHINE', 
        N'Software\Microsoft\MSSQLServer\MSSQLServer', 
        N'DefaultLog', 
        @defaultLogPath OUTPUT;

    -- Retrieve Default Backup Location
    EXEC master.dbo.xp_instance_regread 
        N'HKEY_LOCAL_MACHINE', 
        N'Software\Microsoft\MSSQLServer\MSSQLServer', 
        N'BackupDirectory', 
        @backupPath OUTPUT;

    -- Retrieve MAXDOP
    SELECT @maxDOP = CONVERT(INT, value)
    FROM sys.configurations 
    WHERE name = 'max degree of parallelism';

    -- Retrieve Cost Threshold for Parallelism
    SELECT @costThreshold = CONVERT(INT, value)
    FROM sys.configurations 
    WHERE name = 'cost threshold for parallelism';

    -- Retrieve MAX Memory in MB
    SELECT @maxMemoryMB = CONVERT(BIGINT, value)
    FROM sys.configurations 
    WHERE name = 'max server memory (MB)';

    -- Retrieve Instance Fullname
    SELECT @instanceFullName = CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(128)) + '\' + ISNULL(CAST(SERVERPROPERTY('InstanceName') AS NVARCHAR(128)), 'MSSQLSERVER');

    -- Insert results into local table
    INSERT INTO dbo.server_properties (
        InstanceFullName,
        DefaultDataLocation,
        DefaultLogLocation,
        DefaultBackupLocation,
        MaxDOP,
        CostThreshold,
        SQLServerVersion,
        ProductLevel,
        Edition,
        MaxMemoryMB,
        Timestamp
    )
    VALUES (
        @instanceFullName,
        @defaultDataPath,
        @defaultLogPath,
        @backupPath,
        @maxDOP,
        @costThreshold,
        CONVERT(NVARCHAR(100), SERVERPROPERTY('ProductVersion')),
        CONVERT(NVARCHAR(100), SERVERPROPERTY('ProductLevel')),
        CONVERT(NVARCHAR(100), SERVERPROPERTY('Edition')),
        @maxMemoryMB,
        @timestamp
    );
	-- Delete records older than 30 days
    DELETE FROM dbo.server_properties WHERE Timestamp <= DATEADD(DAY, -30, GETDATE());
END;
