REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Program Name   : XX_INV_RMS_EBS_INT.grt                                                     |--        
--|                                                                                             |--   
--| Purpose        : Inserting data into XX_INV_EBS_CONTROL with batch_size process name        |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              21-Jul-2008       Paddy Sanjeevi          Original                         |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE
             
PROMPT          
PROMPT Deleting data from XX_INV_EBS_CONTROL
PROMPT          

DELETE FROM xx_inv_ebs_control;

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Inserting data into XX_INV_EBS_CONTROL
PROMPT

INSERT INTO xx_inv_ebs_control
	( control_id
	 ,process_name
	 ,stop_running_flag
	 ,ebs_batch_size
	 ,ebs_threads
	 ,creation_date
	 ,created_by
	 ,last_update_date
	 ,last_updated_by)
VALUES 
	( 0
	 ,'ITEM_MASTER'
	 ,'N'
	 ,300
	 ,6
	 ,SYSDATE
	 ,-1
	 ,SYSDATE
	 ,-1
	 );

INSERT INTO xx_inv_ebs_control
	( control_id
	 ,process_name
	 ,stop_running_flag
	 ,ebs_batch_size
	 ,ebs_threads
	 ,creation_date
	 ,created_by
	 ,last_update_date
	 ,last_updated_by)
VALUES 
	( 0
	 ,'ITEM_LOC'
	 ,'N'
	 ,4000
	 ,10
	 ,SYSDATE
	 ,-1
	 ,SYSDATE
	 ,-1
	 );

INSERT INTO xx_inv_ebs_control
	( control_id
	 ,process_name
	 ,stop_running_flag
	 ,ebs_batch_size
	 ,ebs_threads
	 ,creation_date
	 ,created_by
	 ,last_update_date
	 ,last_updated_by)
VALUES 
	( 0
	 ,'MERCH_HIER'
	 ,'N'
	 ,0
	 ,0
	 ,SYSDATE
	 ,-1
	 ,SYSDATE
	 ,-1
	 );

INSERT INTO xx_inv_ebs_control
	( control_id
	 ,process_name
	 ,stop_running_flag
	 ,ebs_batch_size
	 ,ebs_threads
	 ,creation_date
	 ,created_by
	 ,last_update_date
	 ,last_updated_by)
VALUES 
	( 0
	 ,'ORG_HIER'
	 ,'N'
	 ,0
	 ,0
	 ,SYSDATE
	 ,-1
	 ,SYSDATE
	 ,-1
	 );

INSERT INTO xx_inv_ebs_control
	( control_id
	 ,process_name
	 ,stop_running_flag
	 ,ebs_batch_size
	 ,ebs_threads
	 ,creation_date
	 ,created_by
	 ,last_update_date
	 ,last_updated_by)
VALUES 
	( 0
	 ,'ITEM_XREF'
	 ,'N'
	 ,0
	 ,0
	 ,SYSDATE
	 ,-1
	 ,SYSDATE
	 ,-1
	 );

INSERT INTO xx_inv_ebs_control
	( control_id
	 ,process_name
	 ,stop_running_flag
	 ,ebs_batch_size
	 ,ebs_threads
	 ,creation_date
	 ,created_by
	 ,last_update_date
	 ,last_updated_by)
VALUES 
	( 0
	 ,'LOCATION'
	 ,'N'
	 ,0
	 ,0
	 ,SYSDATE
	 ,-1
	 ,SYSDATE
	 ,-1
	 );

COMMIT;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================


