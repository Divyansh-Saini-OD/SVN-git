SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_QP_MODIFIERS_IMPORT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_QP_MODIFIERS_IMPORT_PKG.pks                     |
-- | Description :  QP Modifiers  Package Specification                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  14-May-2007 Abhradip Ghosh     Initial draft version     |
-- |DRAFT 1b  12-Jun-2007 Abhradip Ghosh     Onsite Review Incorporated|
-- |DRAFT 1c  12-Jun-2007 Parvez Siddiqui    TL Review                 |
-- +===================================================================+

AS
----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------

-----------------------------------
--Declaring Global Record Variables 
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

---------------------------------------------------------------------------------------------------
--Declaring master_main procedure which gets called from OD: QP Modifiers Conversion Master Program
---------------------------------------------------------------------------------------------------
-- +====================================================================+
-- | Name        :  master_main                                         |
-- |                                                                    |
-- | Description :  This procedure is invoked from the OD: QP Modifiers |
-- |                Conversion Master Concurrent Request.This would     |
-- |                submit child programs based on batch_size           |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :                                          |
-- |                p_validate_omly_flag                                |
-- |                p_reset_status_flag                                 |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE master_main(
                      x_errbuf             OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag IN         VARCHAR2
                     ,p_reset_status_flag  IN         VARCHAR2
                     );
                     
-------------------------------------------------------------------------------------------------
--Declaring child_main procedure which gets called from OD: QP Modifiers Conversion Child Program
-------------------------------------------------------------------------------------------------                 
-- +=================================================================================+
-- | Name        :  child_main                                                       |
-- |                                                                                 |
-- | Description :  This procedure is invoked from the OD: QP Modifiers              |
-- |                Conversion Child Concurrent Request.This would                   |
-- |                validate the records and call qp_modifiers_pub.process_modifiers |
-- |                to process the records to the EBS tables.                        |
-- |                                                                                 |
-- |                                                                                 |
-- | Parameters  :                                                          |
-- |                p_validate_omly_flag                                             |
-- |                p_reset_status_flag                                              |
-- |                p_batch_id                                                       |
-- |                                                                                 |
-- | Returns     :  x_errbuf                                                         |
-- |                x_retcode                                                        |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE child_main(
                     x_errbuf             OUT NOCOPY VARCHAR2
                    ,x_retcode            OUT NOCOPY VARCHAR2
                    ,p_validate_only_flag IN         VARCHAR2
                    ,p_reset_status_flag  IN         VARCHAR2
                    ,p_batch_id           IN         NUMBER
                   );         

END XX_QP_MODIFIERS_IMPORT_PKG;
/
SHOW ERRORS
EXIT;



