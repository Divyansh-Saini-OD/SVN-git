SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_CONV_AOPS_DELETES_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Oracle  Consulting Organization                  |
-- +===================================================================+
-- | Name        :  XX_CDH_CONV_AOPS_DELETES_PKG.pks                   |
-- | Description :  CDH Customer Conversion AOPS Delete Spec           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-Aug-2008 Abhradip Ghosh     Initial version           |
-- +===================================================================+
AS

g_bulk_fetch_limit NUMBER := NVL(fnd_profile.value ('XX_CDH_BULK_FETCH_LIMIT'),10000);

PROCEDURE aops_deletes_main
      (  x_errbuf              OUT VARCHAR2,
         x_retcode             OUT VARCHAR2,
         p_batch_id_from       IN  NUMBER,
         p_batch_id_to         IN  NUMBER,
         p_submit_deletes      IN  VARCHAR2,
         p_process_accounts    IN  VARCHAR2,
         p_process_addresses   IN  VARCHAR2,
         p_process_contacts    IN  VARCHAR2,
         p_process_phones      IN  VARCHAR2,
         p_process_emails      IN  VARCHAR2,
         p_process_spc         IN  VARCHAR2
      );
            
PROCEDURE aops_deletes_child
      (  x_errbuf              OUT VARCHAR2,
         x_retcode             OUT VARCHAR2,
         p_batch_id            IN  NUMBER,
         p_worker_id           IN  NUMBER,
         p_process_accounts    IN  VARCHAR2,
         p_process_addresses   IN  VARCHAR2,
         p_process_contacts    IN  VARCHAR2,
         p_process_phones      IN  VARCHAR2,
         p_process_emails      IN  VARCHAR2,
         p_process_spc         IN  VARCHAR2
      );

PROCEDURE delete_accounts(
              p_aops_entity_osr   IN  VARCHAR2
            , p_record_id         IN  VARCHAR2
            , x_return_status     OUT VARCHAR2
                         );

PROCEDURE delete_account_sites(
              p_aops_entity_osr   IN  VARCHAR2
            , p_record_id         IN  VARCHAR2
            , x_return_status     OUT VARCHAR2
                              );

PROCEDURE delete_account_contacts(
              p_aops_entity_osr   IN  VARCHAR2
            , p_record_id         IN  VARCHAR2
            , x_return_status     OUT VARCHAR2
                                 );
                                 
PROCEDURE delete_acct_cnt_pnt_phone(
              p_aops_entity_osr   IN  VARCHAR2
            , p_record_id         IN  VARCHAR2
            , x_return_status     OUT VARCHAR2
                                   );

PROCEDURE delete_acct_cnt_pnt_email(
              p_aops_entity_osr   IN  VARCHAR2
            , p_record_id         IN  VARCHAR2
            , x_return_status     OUT VARCHAR2
                                   );
                                   
PROCEDURE delete_spc(
              p_aops_entity_osr   IN  VARCHAR2
            , p_record_id         IN  VARCHAR2
            , x_return_status     OUT VARCHAR2
            );

PROCEDURE delete_www(
              p_aops_entity_osr   IN  VARCHAR2
            , p_record_id         IN  VARCHAR2
            , x_return_status     OUT VARCHAR2
            );            

PROCEDURE delete_wst(
              p_aops_entity_osr   IN  VARCHAR2
            , p_record_id         IN  VARCHAR2
            , x_return_status     OUT VARCHAR2
            );
      
END XX_CDH_CONV_AOPS_DELETES_PKG;
/
SHOW ERRORS;
