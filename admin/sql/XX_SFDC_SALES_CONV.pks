-- $Id: XX_SFDC_SALES_CONV.pks 90515 2010-01-12 18:03:44Z Prasad Devar $
-- $Rev: 90515 $
-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XX_SFDC_SALES_CONV.pks $
-- $Author: Prasad Devar $
-- $Date: 2010-01-12 13:03:44 -0500 (Tue, 12 Jan 2010) $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_SFDC_SALES_CONV AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_SFDC_SALES_CONV                                                       |
-- | Description : Custom package for data migration.                                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        08-Apr-2009     Prasad Devar               Initial version                          |
-- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
-- +=========================================================================================+

date_format      VARCHAR2(50) := 'yyyy-mm-dd"T"hh24:mm:ss';
G_LEVEL_ID                      CONSTANT  NUMBER       := 10001;
G_LEVEL_VALUE                   CONSTANT  NUMBER       := 0;

 PROCEDURE create_assignments(
    X_ERRBUF               OUT NOCOPY  VARCHAR2,
    X_RETCODE             OUT NOCOPY VARCHAR2,
    p_start_date             IN DATE   ,
   p_conv_flag             IN  VARCHAR2
   );

END XX_SFDC_SALES_CONV;
/

SHOW ERRORS;
