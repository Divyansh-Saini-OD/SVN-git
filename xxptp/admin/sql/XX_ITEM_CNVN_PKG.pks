SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE APPS.XX_ITEM_CNVN_PKG
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
-- |1.0       18-Jul-2007 Arun Andavar       Added 2 parameters to     |
-- |                                         master_main procedure.    |
-- |1.1       02-Sep-2007 Paddy Sanjeevi     Modified to run master and|
-- |                                         loc separately            |	
-- +===================================================================+

AS

------------------------------------------------------------------------------------------------
--Declaring master_main procedure which gets called from OD: INV Items Conversion Master Program
------------------------------------------------------------------------------------------------

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode             OUT NOCOPY VARCHAR2
      ,p_master              IN  VARCHAR2
                     ,p_validate_only_flag  IN  VARCHAR2
                     ,p_reset_status_flag   IN  VARCHAR2
                     ,p_delete_flag         IN  VARCHAR2
                     --Added by Arun Andavar in ver 1.2 -START
                     ,p_sleep               IN  NUMBER DEFAULT 60
                     ,p_max_wait_time       IN  NUMBER DEFAULT 300
                     --Added by Arun Andavar in ver 1.2 -END
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
            ,p_master   IN  VARCHAR2
                    );


END XX_ITEM_CNVN_PKG;
/
SHOW ERRORS
EXIT;
