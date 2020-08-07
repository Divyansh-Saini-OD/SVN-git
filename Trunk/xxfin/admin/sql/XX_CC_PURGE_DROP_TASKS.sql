SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_PURGE_DROP_TASKS.sql                               |
-- | Description : Script used to drop the tasks of DBMS_PARALLEL_EXECUTE  |
-- |              This script has to be executed once all CC purge scripts |
-- |              executed successfully.                                   |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     27-Jul-2015  Madhu Bolli        Initial.                      |
-- | 1.1     24-APR-2016  Madhu Bolli        drop the task DELETE_IBY_SEC_SEG_DATA|
-- | 1.2     09-May-2016  Madhu Bolli        Most tasks are not created as using|
-- |							single delete statement instead of DBMS_PARALLEL tasks|
-- +=======================================================================+



-- Drop the task DELETE_IBY_AR_CC_DATA created to purge CC data of IBY tables 
--exec DBMS_PARALLEL_EXECUTE.DROP_TASK ('DELETE_IBY_AR_CC_DATA');
--/

-- Drop the task DELETE_AP_CC_DATA created to purge CC data of AP tables 
--exec DBMS_PARALLEL_EXECUTE.DROP_TASK ('DELETE_AP_CC_DATA');
---/

-- Drop the task DELETE_IBY_SEC_SEG_DATA created to purge CC data of IBY tables 
--exec DBMS_PARALLEL_EXECUTE.DROP_TASK ('DELETE_IBY_SEC_SEG_DATA');
--/

-- Drop the task DELETE_IBY_CC_DATA created to purge CC data of IBY tables 
exec DBMS_PARALLEL_EXECUTE.DROP_TASK ('DELETE_IBY_CC_DATA');
/
