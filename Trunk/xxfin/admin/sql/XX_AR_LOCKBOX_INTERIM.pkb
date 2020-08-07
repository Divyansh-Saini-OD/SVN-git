SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_AR_LOCKBOX_INTERIM

PROMPT Program exits if the creation is not successful

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_ar_lockbox_interim_pkg
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name : populate_lockbox_interim                                         |
-- | Description : Procedure to insert the values in interim tables          |
-- |                                                                  .      |
-- |                                                                         |
-- | Parameters :    Errbuf and retcode                                      |
-- |===============                                                          |
-- |Version   Date          Author              Remarks                      |
-- |=======   ==========   =============   ==================================|
-- |   1      28-OCT-11   P.Sankaran      Initial version                    |
-- |   1.1    21-OCT-15   Vasu Raparla    Removed Schema References for R12.2|
-- +==========================================================================+
   PROCEDURE populate_lockbox_interim (
      errbuf OUT VARCHAR2
    , retcode OUT NUMBER
   )
   IS
      ln_open_trans_count           NUMBER := 0;
      ln_total_records              NUMBER := 0;
   BEGIN
      BEGIN
         EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_lockbox_interim';

         fnd_file.put_line (fnd_file.LOG, 'Truncate Ends for xx_ar_lockbox_interim at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));  
         fnd_file.put_line (fnd_file.LOG, '');                                                                                           
      END;

      BEGIN
         INSERT INTO xx_ar_lockbox_interim
            (SELECT /*+PARALLEL(APS,8) FULL(APS)*/
                    *
               FROM ar_payment_schedules_all aps
              WHERE aps.status = 'OP');

         ln_open_trans_count    := SQL%ROWCOUNT;
         fnd_file.put_line (fnd_file.LOG, 'Inserted in xx_ar_lockbox_interim table at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
         fnd_file.put_line (fnd_file.LOG, 'Total number of records inserted in xx_ar_lockbox_interim ' || ln_open_trans_count || ' rows'); 
         fnd_file.put_line (fnd_file.LOG, '');
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Insertion failed in xx_ar_lockbox_interim');
            fnd_file.put_line (fnd_file.LOG, '');
      END;
      
      BEGIN
         fnd_file.put_line (fnd_file.LOG, 'Gathering stats for xx_ar_lockbox_interim' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));      
         fnd_stats.gather_table_stats (ownname      => 'XXFIN',
                                       tabname      => 'XX_AR_LOCKBOX_INTERIM'
                                      );
         fnd_file.put_line (fnd_file.LOG, 'Finished gathering stats for xx_ar_lockbox_interim' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));                                            
      END;

      COMMIT;
   END populate_lockbox_interim;
END xx_ar_lockbox_interim_pkg;
/

SHOW ERROR
   
