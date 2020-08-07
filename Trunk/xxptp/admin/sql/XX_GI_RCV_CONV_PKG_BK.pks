SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE      XX_GI_RCV_CONV_PKG_BK
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- +=============================================================================+
-- | Name        :  XX_GI_RCV_CONV_PKG_BK.pks                                    |
-- | Description :  Historical Receipts Conversion Package Spec                  |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |  Version      Date         Author             Remarks                       |
-- | =========  =========== =============== ==================================== |
-- |    1.0     21-Dec-2007   Rama Dwibhashyam   Baselined                       |
-- +=============================================================================+

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

-----------------------------------------------------------------------------------------------------------------------------
--Declaring master_main procedure which gets called from OD: GI Receipts Conversion Master Program
-----------------------------------------------------------------------------------------------------------------------------

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode             OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag  IN         VARCHAR2
                     ,p_reset_status_flag   IN         VARCHAR2
                     ,p_debug_flag          IN         VARCHAR2
                     ,p_sleep_time          IN         NUMBER
                     ,p_max_wait_time       IN         NUMBER
                     ,p_conversion_type     IN         VARCHAR2
                     );

---------------------------------------------------------------------------------------------------------------------------
--Declaring child_main procedure which gets called FROM OD: GI Receipts Conversion Child Program
---------------------------------------------------------------------------------------------------------------------------


PROCEDURE child_main(
                    x_errbuf              OUT NOCOPY VARCHAR2
                   ,x_retcode             OUT NOCOPY VARCHAR2
                   ,p_validate_only_flag  IN         VARCHAR2
                   ,p_reset_status_flag   IN         VARCHAR2
                   ,p_batch_id            IN         NUMBER
                   ,p_debug_flag          IN         VARCHAR2
                   ,p_sleep_time          IN         NUMBER
                   ,p_max_wait_time       IN         NUMBER
                   ,p_conversion_type     IN         VARCHAR2
                   );


END XX_GI_RCV_CONV_PKG_BK; 
/

SHOW ERRORS;

EXIT;