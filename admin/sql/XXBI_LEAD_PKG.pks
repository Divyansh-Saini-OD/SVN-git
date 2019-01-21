-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;



create or replace
PACKAGE XXBI_LEAD_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_LEAD_PKG.pks                                  |
-- | Description :  DBI Reporting Lead Fact Table Population Pkg       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS

  PROCEDURE pop_lead_fact (
         x_errbuf         OUT NOCOPY VARCHAR2,
         x_retcode        OUT NOCOPY VARCHAR2,
         p_trunc_flag     IN  VARCHAR2,
         p_fr_date        IN  VARCHAR2
   );
   

END XXBI_LEAD_PKG;
/
SHOW ERRORS;
EXIT;
