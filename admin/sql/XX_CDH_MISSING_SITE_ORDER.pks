-- $Id:$
-- $Rev:$
-- $HeadURL:$
-- $Author:$
-- $Date:$


SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_CDH_MISSING_SITE_ORDER 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_MISSING_SITE_ORDER.pks                      |
-- | Description :  Report to find Missing Sites on which orders were  |
-- |                placed in AOPS.                                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       15-Apr-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS

  PROCEDURE main
 (     x_errbuf            OUT     VARCHAR2
      ,x_retcode           OUT     VARCHAR2
      ,p_aops_ord_date     IN      VARCHAR2
      ,p_db_link           IN      VARCHAR2
 );

END XX_CDH_MISSING_SITE_ORDER;
/
SHOW ERRORS;
EXIT;