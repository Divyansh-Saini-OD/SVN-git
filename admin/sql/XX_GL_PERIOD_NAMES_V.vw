SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Creating VIEW XX_GL_PERIOD_NAMES_V

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                      Wipro/Office Depot                           |
-- +===================================================================+
-- | Name       : XX_GL_PERIOD_NAMES_V                                 |
-- | Description: View for  the extract - GL I1360 - Oracle GL Feed    |
-- |              to Hyperion (Used in Value set)                      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author            Remarks                   |
-- |=======   ==========   =============     ==========================|
-- |1.0       14-JUN-2008  Hemalatha S       Initial version           |
-- |1.1       14-JUN-2013  Kiran Kumar R     Included R12 Retrofit     |
-- |                                         Changes                   | 
-- +===================================================================+

CREATE OR REPLACE VIEW XX_GL_PERIOD_NAMES_V ( period_name,period_year,period_num,short_name )
AS
SELECT GPS.period_name 
      ,GPS.period_year 
      ,GPS.period_num 
      --,GSB.short_name                                                        --commented by kiran(V1.1) as per R12 Retrofit Change
      ,GL.short_name                                                           --added by kiran (V1.1) as per R12 Retrofit Change
FROM   GL_PERIOD_STATUSES GPS
      --,GL_SETS_OF_BOOKS GSB                                                  --commented by kiran (V1.1) as per R12 Retrofit Change
      ,GL_LEDGERS GL                                                           --added by kiran (V1.1) as per R12 Retrofit Change
WHERE  GPS.CLOSING_STATUS IN ('C','O')
--AND    GSB.SET_OF_BOOKS_ID=GPS.SET_OF_BOOKS_ID                               --commented by kiran(V1.1) as per R12 Retrofit Change
AND    GL.LEDGER_ID=GPS.LEDGER_ID                                              --added by kiran (V1.1) as per R12 Retrofit Change
AND    APPLICATION_ID= (SELECT application_id
                        FROM   fnd_application
                        WHERE  application_short_name = 'SQLGL')
UNION
SELECT GPS.period_name
      ,GPS.period_year
      ,GPS.period_num
      ,'ALL'
FROM   GL_PERIOD_STATUSES GPS
      --,GL_SETS_OF_BOOKS GSB                                                  --commented by kiran (V1.1) as per R12 Retrofit Change
      ,GL_LEDGERS GL                                                           --added by kiran (V1.1) as per R12 Retrofit Change
WHERE  GPS.CLOSING_STATUS IN ('C','O')
--AND    GSB.SET_OF_BOOKS_ID=GPS.SET_OF_BOOKS_ID                               --commented by kiran (V1.1) as per R12 Retrofit Change
AND    GL.LEDGER_ID=GPS.LEDGER_ID                                              --added by kiran (V1.1) as per R12 Retrofit Change
AND    APPLICATION_ID= (SELECT application_id
                        FROM   fnd_application
                        WHERE  application_short_name = 'SQLGL');

SHOW ERR