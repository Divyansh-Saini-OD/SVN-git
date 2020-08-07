-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Providge Consulting                                |
-- +==========================================================================+
-- | Name :APPS.XX_AR_CONSBILL_BATCH_SOURCES_V                                |
-- | Description : Create the view of AR batch sources of transactions        |
-- |               that should be displayed as part of consolidated bills     |
-- |               in iReceivables.                                           |
-- |                                                                          |
-- | RICE: E2052 R1.2 CR619                                                   |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     01-Dec-2009  Bushrod Thomas       Initial version               |
-- |                                                                          |
-- +==========================================================================+

   SET SHOW         OFF
   SET VERIFY       OFF
   SET ECHO         OFF
   SET TAB          OFF
   SET FEEDBACK     ON

   CREATE OR REPLACE FORCE VIEW "APPS"."XX_AR_CONSBILL_BATCH_SOURCES_V" ("BATCH_SOURCE_ID") AS 
   SELECT batch_source_id 
     FROM RA_BATCH_SOURCES_ALL
    WHERE name IN
          (SELECT V.source_value1 
             FROM XX_FIN_TRANSLATEDEFINITION D JOIN XX_FIN_TRANSLATEVALUES V 
               ON V.translate_id=D.translate_id
            WHERE D.translation_name = 'AR_CONSBILL_BATCH_SOURCES');

SHOW ERROR
