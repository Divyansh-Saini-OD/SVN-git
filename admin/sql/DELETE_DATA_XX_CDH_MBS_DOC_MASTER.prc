SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                Oracle Consulting Organization                         |
-- +=======================================================================+
-- | Name             :DELETE_DATA_XX_CDH_MBS_DOC_MASTER.prc               |
-- | Description      :Data management for E1331_CDH_MetaData_Attributes   |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      01-AUG-2007 Rajeev Kamath      Initial version                |
-- +=======================================================================+

-- -----------------------------------------------------
-- Delete all data from Table XX_CDH_MBS_DOCUMENT_MASTER  
-- -----------------------------------------------------
delete from XXCRM.XX_CDH_MBS_DOCUMENT_MASTER ;

commit;

SHOW ERRORS;    


        
        
        