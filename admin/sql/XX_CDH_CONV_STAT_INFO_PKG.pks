-- SVN FILE: $Id$
-- @author $Author$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_CONV_STAT_INFO_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                         Wipro Technologies                        |
-- +===================================================================+
-- | Name        :  XX_CDH_CONV_STAT_INFO_PKG                          |
-- | Description :  CDH Conversion Statistical Information Package     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  06-Aug-2007 Shabbar Hasan      Initial draft version     |
-- |                                                                   |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name        :  tca_ent_stat_info                                  |
-- | Description :  This procedure is invoked from OD: CDH TCA Entities|
-- |                Statistical Info Program Concurrent Request.It     |
-- |                extracts those accounts from hz_cust_accounts which|
-- |                have been created / modified after a given date and|
-- |                inserts them into a custom table,                  |
-- |                XX_CDH_TCA_ENTITY_STAT_INFO.                       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  Last Update Date                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE tca_ent_stat_info ( x_errbuf            OUT   NOCOPY VARCHAR2
                             ,x_retcode           OUT   NOCOPY NUMBER
                             ,p_last_update_date  IN           VARCHAR2
                            );

END XX_CDH_CONV_STAT_INFO_PKG;
/
SHOW ERRORS;