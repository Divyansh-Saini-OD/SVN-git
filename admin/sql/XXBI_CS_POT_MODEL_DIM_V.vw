-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_CS_POT_MODEL_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CS_POT_MODEL_DIM_V.vw                         |
-- | Description :  View for Contact Strategy Model Type Dimension     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       15-Mar-2009   Sreekanth Rao    Initial version           |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT 
   lookup_code   id,
   meaning       value
FROM
   apps.fnd_lookup_values 
WHERE
    lookup_type = 'XXBI_CS_MODEL_TYPE'
AND nvl(enabled_flag,'N') = 'Y'
AND sysdate between nvl(start_date_active,sysdate-1) and nvl(end_date_active,sysdate+1)
/
SHOW ERRORS;
EXIT;