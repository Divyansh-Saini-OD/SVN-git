SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_ASN_ADD_LOOKUP_CODE_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name   : XX_ASN_ADD_LOOKUP_CODE_PKG.pkb                                                |
-- | Rice Id      : E1307_Site_Level_Attributes                                              |  
-- | Description      : This package adds a new lookup value 'PARTY_SITE'to                  |
-- |                    two lookups ASN_LEAD_VIEW_NOTES and ASN_OPPTY_VIEW_NOTES             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0        20-Nov-2007       Ankur Tandon        Initial Creation                        |
-- |                                                                                         |
-- +=========================================================================================+
AS

   -- Who columns
 
   gc_conc_prg_id                      NUMBER         := apps.fnd_global.conc_request_id; 
   

   -- +===================================================================+
   -- | Name  : Create_lookup_value_main                                  |
   -- | Description:       This Procedure is reqistered as current program|
   -- |                    to create PARTY_SITE lookup code.              |
   -- |                                                                   |
   -- |                                                                   |
   -- +===================================================================+
   PROCEDURE create_lookup_value_main( x_errbuf  OUT NOCOPY  VARCHAR2
                                   ,x_retcode OUT NOCOPY  NUMBER)
   IS
     ln_retcode    NUMBER := 0;
     ln_lookup_exists NUMBER := 0;
     lc_message    VARCHAR2(4000);
     
   BEGIN
     -- Check if value exists in lookup type 'ASN_LEAD_VIEW_NOTES'. If not insert lookup code 'PARTY_SITE'
     
     BEGIN
     
      SELECT count(1)
      INTO   ln_lookup_exists
      FROM   fnd_lookup_values
      WHERE  lookup_type = 'ASN_LEAD_VIEW_NOTES'
      AND    lookup_code = 'PARTY_SITE';

      IF ln_lookup_exists = 0 THEN

         INSERT INTO FND_LOOKUP_VALUES (
              lookup_type,
              language,
              lookup_code,
              meaning,
              enabled_flag,
              start_date_active,
              created_by,
              creation_date,
              last_updated_by,
              last_update_login,
              last_update_date,
              source_lang,
              security_group_id,
              view_application_id,
              tag
          ) VALUES (
              'ASN_LEAD_VIEW_NOTES',
              'US',
              'PARTY_SITE',
              'Site',
              'Y',
              trunc(SYSDATE-1),
              2,
              SYSDATE,
              2,
              0,
              SYSDATE,
              'US',
              0,
              0,
              '30'
           );

         
         COMMIT;
         FND_FILE.put_line (fnd_file.log,'PARTY_SITE Lookup Code added to Lookup Type ASN_LEAD_VIEW_NOTES.');
         FND_FILE.put_line (fnd_file.log,'Committed changes.. ');
      ELSE
         FND_FILE.put_line (fnd_file.log,'PARTY_SITE Lookup Code already exists for Lookup Type ASN_LEAD_VIEW_NOTES.');
      
      END IF;

      
     EXCEPTION
       WHEN OTHERS THEN
           x_retcode := 2;
           FND_FILE.put_line (fnd_file.log,'Unexpected Error - '||SQLERRM );
           ROLLBACK;
	   FND_FILE.put_line (fnd_file.log,'Rollback changes.. ');
     END;
     
     -- Check if value exists in lookup type 'ASN_OPPTY_VIEW_NOTES'. If not insert lookup code 'PARTY_SITE'
      
      ln_lookup_exists := 0;
      
      BEGIN
      
      SELECT count(1)
      INTO   ln_lookup_exists
      FROM   fnd_lookup_values
      WHERE  lookup_type = 'ASN_OPPTY_VIEW_NOTES'
      AND    lookup_code = 'PARTY_SITE';

      IF ln_lookup_exists = 0 THEN

         INSERT INTO FND_LOOKUP_VALUES (
              lookup_type,
              language,
              lookup_code,
              meaning,
              enabled_flag,
              start_date_active,
              created_by,
              creation_date,
              last_updated_by,
              last_update_login,
              last_update_date,
              source_lang,
              security_group_id,
              view_application_id,
              tag
          ) VALUES (
              'ASN_OPPTY_VIEW_NOTES',
              'US',
              'PARTY_SITE',
              'Site',
              'Y',
              trunc(SYSDATE-1),
              2,
              SYSDATE,
              2,
              0,
              SYSDATE,
              'US',
              0,
              0,
              '30'
           );
 
     
         COMMIT;
         FND_FILE.put_line (fnd_file.log,'PARTY_SITE Lookup Code added to Lookup Type ASN_OPPTY_VIEW_NOTES.');
         FND_FILE.put_line (fnd_file.log,'Committed changes.. ');
      ELSE
         FND_FILE.put_line (fnd_file.log,'PARTY_SITE Lookup Code already exists for Lookup Type ASN_OPPTY_VIEW_NOTES.');

      END IF;

      
     EXCEPTION
       WHEN OTHERS THEN
           x_retcode := 2;
           FND_FILE.put_line (fnd_file.log,'Unexpected Error - '||SQLERRM );
           ROLLBACK;
	   FND_FILE.put_line (fnd_file.log,'Rollback changes.. ');
     END;
           
   END create_lookup_value_main;

END XX_ASN_ADD_LOOKUP_CODE_PKG;
/

SHOW ERROR;

--EXIT;