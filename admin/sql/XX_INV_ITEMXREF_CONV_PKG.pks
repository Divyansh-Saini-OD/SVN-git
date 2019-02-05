SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_INV_ITEMXREF_CONV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_INV_ITEMXREF_CONV_PKG.pks                       |
-- | Description :  INV Item Cross Reference Master Package Spec       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author          Remarks                      |
-- |========  =========== =============== =============================|
-- |DRAFT 1a  05-May-2007 Abhradip Ghosh  Initial draft version        |
-- |DRAFT 1b  10-Apr-2007 Abhradip Ghosh  Incorporated the Master      |
-- |                                       Conversion Program Logic    |
-- |DRAFT 1c  14-Jun-2007 Abhradip Ghosh  Incorporated OnSite Comments |
-- |DRAFT 1d  14-Jun-2007 Parvez Siddiqui TL Review                    |
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

-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: INV ItemXref |
-- |                Conversion Master Concurrent Request.This would     |
-- |                submit child programs based on batch_size           |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_validate_only_flag                                |
-- |                p_reset_status_flag                                 |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag IN  VARCHAR2
                      ,p_reset_status_flag  IN  VARCHAR2
                     );

-- +===================================================================+
-- | Name        :  child_main                                         |
-- | Description :  This procedure is invoked from the OD: INV ItemXref|
-- |                Conversion Child  Concurrent Request.This would    |
-- |                submit conversion programs based on input    .     |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                p_batch_id                                         |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE child_main(
                     x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag IN  VARCHAR2
                     ,p_reset_status_flag  IN  VARCHAR2
                     ,p_batch_id           IN  NUMBER
                    );

END XX_INV_ITEMXREF_CONV_PKG;
/
SHOW ERRORS
EXIT;

