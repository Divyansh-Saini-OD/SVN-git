SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_PURCHPRCFRMRMS_PKG AUTHID CURRENT_USER
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
-- +===========================================================================+
-- | Name        :  XX_PO_PURCHPRCFRMRMS_PKG.pks                               |        
-- | =================================================                         |
-- |Type         Name          Description                                     |
-- |=========    ===========   ================================================|
-- |PROCEDURE    main          This Package is used in Inbound Interface of    |
-- |                           Purchase Price From RMS                         |
-- |                                                                           |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1a  05-Jun-2007 Chandan U H      Initial draft version               |                                                 |
-- |Draft 1b  01-Aug-2007 Chandan U H      Updated as per Review Comments      |
-- |1.0       02-Aug-2007 Chandan U H      Baselined                           |
-- +===========================================================================+

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

----------------------------------------------------------------------------------------
--Declaring main procedure which gets called from OD: PO Purchase Price From RMS Inbound
----------------------------------------------------------------------------------------
PROCEDURE main (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                ,p_debug_flag    IN          VARCHAR2
                ,p_purge_days    IN          NUMBER
                );

END  XX_PO_PURCHPRCFRMRMS_PKG;
/
SHOW ERRORS
EXIT;