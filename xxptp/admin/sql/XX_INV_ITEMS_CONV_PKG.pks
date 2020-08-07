SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_INV_ITEMS_CONV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_INV_ITEMS_CONV_PKG.pks                          |
-- | Description :  INV Item Master Package Spec                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  16-May-2007 Fajna K.P          Initial draft version     |
-- |DRAFT 1b  29-May-2007 Parvez Siddiqui    TL Reviewed               |
-- |DRAFT 1c  30-May-2007 Fajna K.P          Incorporated TL Review    |
-- |                                         Comments                  |
-- |DRAFT 1d  05-Jun-2007 Fajna K.P          Incorporated Onsite Review|
-- |                                         Comments                  |
-- |DRAFT 1e  07-Jun-2007 Susheel Raina      TL Reviewed               |
-- |DRAFT 1f  08-Jun-2007 Fajna K.P          Incorporated Onsite Review|
-- |                                         Comments                  |
-- |DRAFT 1g  12-Jun-2007 Fajna K.P          Incorporated TL Review    |
-- |                                         Comments                  |
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

------------------------------------------------------------------------------------------------
--Declaring master_main procedure which gets called from OD: INV Items Conversion Master Program
------------------------------------------------------------------------------------------------
PROCEDURE master_main(
                       x_errbuf              OUT NOCOPY VARCHAR2
                      ,x_retcode             OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag  IN  VARCHAR2
                      ,p_reset_status_flag   IN  VARCHAR2
                      ,p_delete_flag         IN  VARCHAR2
                     );

----------------------------------------------------------------------------------------------
--Declaring child_main procedure which gets called FROM OD: INV Items Conversion Child Program  
----------------------------------------------------------------------------------------------
PROCEDURE child_main(
                      x_errbuf             OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag IN  VARCHAR2
                     ,p_reset_status_flag  IN  VARCHAR2
                     ,p_delete_flag        IN  VARCHAR2
                     ,p_batch_id           IN  NUMBER
                    );


END XX_INV_ITEMS_CONV_PKG;
/
SHOW ERRORS
EXIT;



