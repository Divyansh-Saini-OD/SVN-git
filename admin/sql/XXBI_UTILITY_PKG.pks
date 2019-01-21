-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;



CREATE OR REPLACE
PACKAGE XXBI_UTILITY_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_UTILITY_PKG.pks                               |
-- | Description :  DBI Package Contains Common Utilities              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS

PROCEDURE refresh_mv (
         p_mv_name          IN  VARCHAR2, -- Materialized View Name
         p_mv_refresh_type  IN  VARCHAR2, -- MV Refresh Type
         x_ret_code         OUT NUMBER,   -- 1 - Error, 0 - Success
         x_error_msg        OUT VARCHAR2  -- Error Message
   );
   
PROCEDURE refresh_mv_grp (
         x_errbuf       OUT NOCOPY VARCHAR2,
         x_retcode      OUT NOCOPY VARCHAR2,
         p_mv_grp_name  IN  VARCHAR2
   );

PROCEDURE update_urls (
         x_errbuf       OUT NOCOPY VARCHAR2,
         x_retcode      OUT NOCOPY VARCHAR2,
         p_db_object    IN  VARCHAR2,
         p_find_str     IN  VARCHAR2,
         p_replace_str  IN  VARCHAR2,
         p_commit       IN  VARCHAR2
   );

PROCEDURE object_validate (
         x_errbuf       OUT NOCOPY VARCHAR2,
         x_retcode      OUT NOCOPY VARCHAR2
   );

FUNCTION get_rsd_user_id(p_user_id IN NUMBER DEFAULT FND_GLOBAL.USER_ID) RETURN NUMBER;

FUNCTION check_active_res_role_grp(p_user_id     IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
                                   p_resource_id IN NUMBER,
                                   p_role_id     IN NUMBER,
                                   p_group_id    IN NUMBER
                                  ) RETURN VARCHAR2;

END XXBI_UTILITY_PKG;
/
SHOW ERRORS;