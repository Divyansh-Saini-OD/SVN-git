-- $Id$
-- $Rev:$
-- $HeadURL:$
-- $Author:$
-- $Date:$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XXBI_ACTIVITY_DT_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_ACTIVITY_DT_PKG.pks                           |
-- | Description :  Contact Strategy Last Activity Date Program        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  19-May-2009 Indra Varada       Initial draft version     |
-- |                                                                   |
-- |                                                                   | 
-- +===================================================================+
AS

 PROCEDURE site_activity_dt (
         x_errbuf         OUT NOCOPY VARCHAR2,
         x_retcode        OUT NOCOPY VARCHAR2,
         p_fr_date        IN  VARCHAR2
   );
   
 PROCEDURE lead_activity_dt (
         x_errbuf         OUT NOCOPY VARCHAR2,
         x_retcode        OUT NOCOPY VARCHAR2,
         p_fr_date        IN  VARCHAR2
   );
   
 PROCEDURE opportunity_activity_dt (
         x_errbuf         OUT NOCOPY VARCHAR2,
         x_retcode        OUT NOCOPY VARCHAR2,
         p_fr_date        IN  VARCHAR2
   );

END XXBI_ACTIVITY_DT_PKG;
/
SHOW ERRORS;