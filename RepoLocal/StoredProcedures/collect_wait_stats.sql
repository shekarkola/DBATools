USE [DBAClient]
GO

/*------------------------------------------------------------------------------------------------------------------------------------------------
-- Author:			Shekar Kola
-- Create date:		2021-09-26
-- Description:		Wait Stats collection script
--------------------------------------------------------------------

Version: 20210926
	-	The average values won't be calculated accurately when they compared with previous value and get the difference as current value.
	-	All average values removed to process part of this procedure, the average will be calculated value in central repository
	-	@Last_sample parameter changed to @prev_sample and considered last second sample from last 5 days 

Version: 20210920
	-	The logic changed to load accumulated values first into additional columns, 
		once loaded it will be compared with previous accumulated values, and difference only be considered as current waits along with it's time  

Version: 20201210
	-	Initial Version 
	-	Collects the waits stats and load into historical table, as the wait_stats accumulated values, current loading values compred with previously loaded values,
		Only the difference value recorded in historical table
--------------------------------------------------------------------------------------------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE [dbo].[collect_wait_stats] AS

SET NOCOUNT ON

IF (SELECT OBJECT_ID ('wait_stats') ) IS NULL 
BEGIN
CREATE TABLE [dbo].[wait_stats]
(
	[sample_time] [datetime] NOT NULL DEFAULT GETDATE(),
	[wait_type] [nvarchar](60) NOT NULL,
	[wait_sec] [decimal](15, 4) NULL,
	[resource_wait_sec] [decimal](15, 4) NULL,
	[signal_wait_sec] [decimal](15, 4) NULL,
	[wait_count] [bigint],
	[accum_wait_sec] DECIMAL(15,4),
	[accum_resource_wait_sec]  DECIMAL(15,4),
	[accum_signal_wait_sec]  DECIMAL(15,4),
	[accum_wait_count] bigint

)  ;

	CREATE CLUSTERED INDEX ci_wait_stats on wait_stats ([sample_time], [wait_type]);
END 

Declare @now datetime;
Declare @prev_sample  datetime; 
	
	set @now = GETDATE ();
	select @prev_sample = MAX(sample_time) from wait_stats where sample_time >= GETDATE() -5;
	--WITH test as (
	--			select DENSE_RANK() OVER (order by sample_time desc) rank_
	--					,sample_time
	--			from wait_stats
	--			where sample_time >= GETDATE() -5
	--			)

	--			select TOP 1 @prev_sample = sample_time
	--			from test
	--			where rank_ = 3;

insert into wait_stats ([sample_time], [wait_type], [accum_wait_sec], [accum_resource_wait_sec], [accum_signal_wait_sec], [accum_wait_count])
SELECT
		@now as sample_time,
        [wait_type],
        cast ([wait_time_ms] / 1000.0 AS DECIMAL(15,4) ) wait_sec,
        cast( ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS DECIMAL(15,4)) resource_wait_sec,
        cast([signal_wait_time_ms] / 1000.0 AS DECIMAL(15,4)) signal_wait_sec,
        [waiting_tasks_count] AS wait_count

--- Average Values won't be correct when accumulated values collected and adjusted with previous accumulated value ------------------
		--CAST( (CASE WHEN [waiting_tasks_count] = 0 THEN 0 
		--	ELSE ([wait_time_ms] / 1000.0) / [waiting_tasks_count] 
		--END) as DECIMAL(15,4)) avg_wait_time_sec
		--,CAST((CASE WHEN [waiting_tasks_count] = 0 THEN 0 
		--	ELSE (signal_wait_time_ms / 1000.0) / [waiting_tasks_count] 
		--END) as DECIMAL(15,4)) avg_sing_wait_sec
		--,CAST( (CASE WHEN [waiting_tasks_count] = 0 THEN 0 
		--	ELSE ( ([wait_time_ms] - [signal_wait_time_ms])/ 1000.0) / [waiting_tasks_count] 
		--END) as DECIMAL(15,4)) avg_res_wait_sec

       --, 100.0 * [waiting_tasks_count] / SUM ([waiting_tasks_count]) OVER() AS [tasks_percent]
       -- ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]

    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        -- These wait types are almost 100% never a problem and so they are
        -- filtered out to avoid them skewing the results. Click on the URL
        -- for more information.
        N'BROKER_EVENTHANDLER', -- https://www.sqlskills.com/help/waits/BROKER_EVENTHANDLER
        N'BROKER_RECEIVE_WAITFOR', -- https://www.sqlskills.com/help/waits/BROKER_RECEIVE_WAITFOR
        N'BROKER_TASK_STOP', -- https://www.sqlskills.com/help/waits/BROKER_TASK_STOP
        N'BROKER_TO_FLUSH', -- https://www.sqlskills.com/help/waits/BROKER_TO_FLUSH
        N'BROKER_TRANSMITTER', -- https://www.sqlskills.com/help/waits/BROKER_TRANSMITTER
        N'CHECKPOINT_QUEUE', -- https://www.sqlskills.com/help/waits/CHECKPOINT_QUEUE
        N'CHKPT', -- https://www.sqlskills.com/help/waits/CHKPT
        N'CLR_AUTO_EVENT', -- https://www.sqlskills.com/help/waits/CLR_AUTO_EVENT
        N'CLR_MANUAL_EVENT', -- https://www.sqlskills.com/help/waits/CLR_MANUAL_EVENT
        N'CLR_SEMAPHORE', -- https://www.sqlskills.com/help/waits/CLR_SEMAPHORE
        N'CXCONSUMER', -- https://www.sqlskills.com/help/waits/CXCONSUMER
 
        -- Maybe comment these four out if you have mirroring issues
        N'DBMIRROR_DBM_EVENT', -- https://www.sqlskills.com/help/waits/DBMIRROR_DBM_EVENT
        N'DBMIRROR_EVENTS_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_EVENTS_QUEUE
        N'DBMIRROR_WORKER_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_WORKER_QUEUE
        N'DBMIRRORING_CMD', -- https://www.sqlskills.com/help/waits/DBMIRRORING_CMD
 
        N'DIRTY_PAGE_POLL', -- https://www.sqlskills.com/help/waits/DIRTY_PAGE_POLL
        N'DISPATCHER_QUEUE_SEMAPHORE', -- https://www.sqlskills.com/help/waits/DISPATCHER_QUEUE_SEMAPHORE
        N'EXECSYNC', -- https://www.sqlskills.com/help/waits/EXECSYNC
        N'FSAGENT', -- https://www.sqlskills.com/help/waits/FSAGENT
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', -- https://www.sqlskills.com/help/waits/FT_IFTS_SCHEDULER_IDLE_WAIT
        N'FT_IFTSHC_MUTEX', -- https://www.sqlskills.com/help/waits/FT_IFTSHC_MUTEX
 
        -- Maybe comment these six out if you have AG issues
        N'HADR_CLUSAPI_CALL', -- https://www.sqlskills.com/help/waits/HADR_CLUSAPI_CALL
        N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', -- https://www.sqlskills.com/help/waits/HADR_FILESTREAM_IOMGR_IOCOMPLETION
        N'HADR_LOGCAPTURE_WAIT', -- https://www.sqlskills.com/help/waits/HADR_LOGCAPTURE_WAIT
        N'HADR_NOTIFICATION_DEQUEUE', -- https://www.sqlskills.com/help/waits/HADR_NOTIFICATION_DEQUEUE
        N'HADR_TIMER_TASK', -- https://www.sqlskills.com/help/waits/HADR_TIMER_TASK
        N'HADR_WORK_QUEUE', -- https://www.sqlskills.com/help/waits/HADR_WORK_QUEUE
 
        N'KSOURCE_WAKEUP', -- https://www.sqlskills.com/help/waits/KSOURCE_WAKEUP
        N'LAZYWRITER_SLEEP', -- https://www.sqlskills.com/help/waits/LAZYWRITER_SLEEP
        N'LOGMGR_QUEUE', -- https://www.sqlskills.com/help/waits/LOGMGR_QUEUE
        N'MEMORY_ALLOCATION_EXT', -- https://www.sqlskills.com/help/waits/MEMORY_ALLOCATION_EXT
        N'ONDEMAND_TASK_QUEUE', -- https://www.sqlskills.com/help/waits/ONDEMAND_TASK_QUEUE
        N'PARALLEL_REDO_DRAIN_WORKER', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_DRAIN_WORKER
        N'PARALLEL_REDO_LOG_CACHE', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_LOG_CACHE
        N'PARALLEL_REDO_TRAN_LIST', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_TRAN_LIST
        N'PARALLEL_REDO_WORKER_SYNC', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_SYNC
        N'PARALLEL_REDO_WORKER_WAIT_WORK', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_WAIT_WORK
        N'PREEMPTIVE_OS_FLUSHFILEBUFFERS', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_OS_FLUSHFILEBUFFERS 
        N'PREEMPTIVE_XE_GETTARGETSTATE', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_XE_GETTARGETSTATE
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', -- https://www.sqlskills.com/help/waits/PWAIT_ALL_COMPONENTS_INITIALIZED
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', -- https://www.sqlskills.com/help/waits/PWAIT_DIRECTLOGCONSUMER_GETNEXT
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', -- https://www.sqlskills.com/help/waits/QDS_PERSIST_TASK_MAIN_LOOP_SLEEP
        N'QDS_ASYNC_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_ASYNC_QUEUE
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
            -- https://www.sqlskills.com/help/waits/QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP
        N'QDS_SHUTDOWN_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_SHUTDOWN_QUEUE
        N'REDO_THREAD_PENDING_WORK', -- https://www.sqlskills.com/help/waits/REDO_THREAD_PENDING_WORK
        N'REQUEST_FOR_DEADLOCK_SEARCH', -- https://www.sqlskills.com/help/waits/REQUEST_FOR_DEADLOCK_SEARCH
        N'RESOURCE_QUEUE', -- https://www.sqlskills.com/help/waits/RESOURCE_QUEUE
        N'SERVER_IDLE_CHECK', -- https://www.sqlskills.com/help/waits/SERVER_IDLE_CHECK
        N'SLEEP_BPOOL_FLUSH', -- https://www.sqlskills.com/help/waits/SLEEP_BPOOL_FLUSH
        N'SLEEP_DBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DBSTARTUP
        N'SLEEP_DCOMSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DCOMSTARTUP
        N'SLEEP_MASTERDBREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERDBREADY
        N'SLEEP_MASTERMDREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERMDREADY
        N'SLEEP_MASTERUPGRADED', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERUPGRADED
        N'SLEEP_MSDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_MSDBSTARTUP
        N'SLEEP_SYSTEMTASK', -- https://www.sqlskills.com/help/waits/SLEEP_SYSTEMTASK
        N'SLEEP_TASK', -- https://www.sqlskills.com/help/waits/SLEEP_TASK
        N'SLEEP_TEMPDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_TEMPDBSTARTUP
        N'SNI_HTTP_ACCEPT', -- https://www.sqlskills.com/help/waits/SNI_HTTP_ACCEPT
        N'SOS_WORK_DISPATCHER', -- https://www.sqlskills.com/help/waits/SOS_WORK_DISPATCHER
        N'SP_SERVER_DIAGNOSTICS_SLEEP', -- https://www.sqlskills.com/help/waits/SP_SERVER_DIAGNOSTICS_SLEEP
        N'SQLTRACE_BUFFER_FLUSH', -- https://www.sqlskills.com/help/waits/SQLTRACE_BUFFER_FLUSH
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', -- https://www.sqlskills.com/help/waits/SQLTRACE_INCREMENTAL_FLUSH_SLEEP
        N'SQLTRACE_WAIT_ENTRIES', -- https://www.sqlskills.com/help/waits/SQLTRACE_WAIT_ENTRIES
        N'VDI_CLIENT_OTHER', -- https://www.sqlskills.com/help/waits/VDI_CLIENT_OTHER
        N'WAIT_FOR_RESULTS', -- https://www.sqlskills.com/help/waits/WAIT_FOR_RESULTS
        N'WAITFOR', -- https://www.sqlskills.com/help/waits/WAITFOR
        N'WAITFOR_TASKSHUTDOWN', -- https://www.sqlskills.com/help/waits/WAITFOR_TASKSHUTDOWN
        N'WAIT_XTP_RECOVERY', -- https://www.sqlskills.com/help/waits/WAIT_XTP_RECOVERY
        N'WAIT_XTP_HOST_WAIT', -- https://www.sqlskills.com/help/waits/WAIT_XTP_HOST_WAIT
        N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', -- https://www.sqlskills.com/help/waits/WAIT_XTP_OFFLINE_CKPT_NEW_LOG
        N'WAIT_XTP_CKPT_CLOSE', -- https://www.sqlskills.com/help/waits/WAIT_XTP_CKPT_CLOSE
        N'XE_DISPATCHER_JOIN', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_JOIN
        N'XE_DISPATCHER_WAIT', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_WAIT
        N'XE_TIMER_EVENT' -- https://www.sqlskills.com/help/waits/XE_TIMER_EVENT
        )
    AND [waiting_tasks_count] > 0 and [wait_time_ms] > 900
---- Accumulated data insert completed ---------------------------------------------------------------------------------------------



--- UPDATE Current wait stats Old ----------------------------------------------------------------------------------------------------------------------------------------
--;with ws as (
--select   sample_time, wait_type
--		,wait_count		
--		,wait_sec			
--		,signal_wait_sec	
--		,resource_wait_sec

--		,accum_wait_count			- LAG(accum_wait_count) OVER (PARTITION BY wait_type ORDER BY sample_time) as cur_wait_count
--		,accum_wait_sec				- LAG(accum_wait_sec) OVER (PARTITION BY wait_type ORDER BY sample_time) as cur_wait_sec
--		,accum_signal_wait_sec		- LAG(accum_signal_wait_sec) OVER (PARTITION BY wait_type ORDER BY sample_time) as cur_signal_wait_sec
--		,accum_resource_wait_sec	- LAG(accum_resource_wait_sec) OVER (PARTITION BY wait_type ORDER BY sample_time) as cur_resource_wait_sec

--from wait_stats as ws
--where sample_time >= @prev_sample and accum_wait_count is not null 
--)
---- select * from ws
--UPDATE ws SET
--		 wait_count=			cur_wait_count		
--		,wait_sec=				cur_wait_sec			
--		,signal_wait_sec=		cur_signal_wait_sec	
--		,resource_wait_sec=		cur_resource_wait_sec	


--- UPDATE Current wait stats New ----------------------------------------------------------------------------------------------------------------------------------------
;with prev as (
select	sample_time, wait_type
		,accum_wait_count			 
		,accum_wait_sec				 
		,accum_signal_wait_sec		 
		,accum_resource_wait_sec	
from wait_stats
where sample_time = @prev_sample
)
, cur as (
select   sample_time, wait_type
		,wait_count		
		,wait_sec			
		,signal_wait_sec	
		,resource_wait_sec
		,accum_wait_count			 
		,accum_wait_sec				 
		,accum_signal_wait_sec		 
		,accum_resource_wait_sec	
from wait_stats
where sample_time = @now
)

update cur set 
		 wait_count			=	ISNULL( (cur.accum_wait_count			- prev.accum_wait_count), 0)
		,wait_sec			=	ISNULL( (cur.accum_wait_sec				- prev.accum_wait_sec), 0)  
		,signal_wait_sec	=	ISNULL( (cur.accum_signal_wait_sec		- prev.accum_signal_wait_sec), 0)
		,resource_wait_sec	=	ISNULL( (cur.accum_resource_wait_sec	- prev.accum_resource_wait_sec), 0)
from cur
left join prev on cur.wait_type = prev.wait_type
-------------------------------------------------------------------------------------------------------------------------------------------

-- Clean old data
delete from wait_stats where sample_time <= DATEADD (DAY,-35, GETDATE())
