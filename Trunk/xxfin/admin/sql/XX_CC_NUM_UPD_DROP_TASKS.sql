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
-- |              This script has to be executed once all CC# update scripts|
-- |              executed successfully.                                   |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     14-Oct-2015  Madhu Bolli        Initial.                      |
-- | 1.1     20-Apr-2016  Madhu Bolli        Added the code the task UPDATE_CCNO_IBY_SEC_SEG_DATA |
-- | 1.2     11-May-2016  Madhu Bolli        Commented the task 'UPDATE_AP_CC_DATA'  as we not using this|
-- +=======================================================================+

-- Drop the task UPDATE_CCNO_IBY_CC_DATA created to update CC data of IBY tables 
exec DBMS_PARALLEL_EXECUTE.DROP_TASK ('UPDATE_CCNO_IBY_CC_DATA');
/

-- Drop the task UPDATE_CCNO_IBY_SEC_SEG_DATA created to update CC data of IBY tables 
exec DBMS_PARALLEL_EXECUTE.DROP_TASK ('UPDATE_CCNO_IBY_SEC_SEG_DATA');
/

-- Drop the task UPDATE_AP_CC_DATA created to update CC data of IBY tables 
--exec DBMS_PARALLEL_EXECUTE.DROP_TASK ('UPDATE_AP_CC_DATA');
--/

