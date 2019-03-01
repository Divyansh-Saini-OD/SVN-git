create or replace PACKAGE BODY XXCDH_SEAMLESS_CONV

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXCDH_SEAMLESS_CONV.pkb                            |
-- | Description :  New CDH Customer Conversion Seamless Package Body  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  10-Aug-2011 Sreedhar Mohan     Initial draft version     |
-- |                                         copied from               |
-- |                                         XXCDH_SEAMLESS_PKG        |
-- |DRAFT 1b  07-JUL-14   Sridhar Pamu       Modified seamless_conv_other_sources|
-- |                                         Procedure to fix the Request calling|
-- |                                         Defect 28730   
-- |DRAFT 1c  27-JAN-2019 BIAS               Changed to replace user_lock 
--                                           to dbms_lock              |
-- +===================================================================+


AS

-- +===================================================================+
-- | Name        :  seamless_aops_conversion                           |
-- | Description :  This procedure will be registered as a Concurrent  |
-- |                Program and will be polling AOPS database to fetch |
-- |                and submit AOPS conversion batches.                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_message                                          |
-- |                                                                   |
-- | Returns     :  VARCHAR2                                           |
-- |                                                                   |
-- +===================================================================+

PROCEDURE seamless_aops_conversion
   (   x_errbuf                        OUT VARCHAR2,
       x_retcode                       OUT VARCHAR2,
       p_batch_type                    IN  VARCHAR2,
       p_submit_update                 IN  VARCHAR2,
       p_sbmt_load_INT_to_STG          IN  VARCHAR2,
       p_submit_bulk                   IN  VARCHAR2,
       p_process_party_rel             IN  VARCHAR2,
       p_process_accounts              IN  VARCHAR2,
       p_process_acct_sites            IN  VARCHAR2,
       p_process_acct_site_uses        IN  VARCHAR2,
       p_process_contacts              IN  VARCHAR2,
       p_process_contact_points        IN  VARCHAR2,
       p_process_profiles              IN  VARCHAR2,
       p_process_bank                  IN  VARCHAR2,
       p_process_ext_attrib            IN  VARCHAR2,
       p_import_run_option             IN  VARCHAR2,
       p_run_batch_dedup               IN  VARCHAR2,
       p_batch_dedup_rule              IN  VARCHAR2,
       p_action_duplicates             IN  VARCHAR2,
       p_run_addr_val                  IN  VARCHAR2,
       p_run_reg_dedup                 IN  VARCHAR2,
       p_reg_dedup_rule                IN  VARCHAR2,
       p_gen_fuz_key                   IN  VARCHAR2
   )
IS

TYPE lt_ebs_batch_rec_type     IS RECORD
   (   ebs_batch_id            NUMBER
   );

lt_ebs_batch_rec               lt_ebs_batch_rec_type;

TYPE lt_ebs_batch_cur_type     IS REF CURSOR;

lc_ebs_batch_cur               lt_ebs_batch_cur_type;

ln_counter                      NUMBER := 0;
lv_batch_submitted              VARCHAR2(1) := 'N';
lv_select_query                 VARCHAR2(2000);
lt_conc_request_id              NUMBER;
ln_start_batch                  NUMBER;
ln_end_batch                    NUMBER;
LN_START_EBS_BATCH              NUMBER;
LN_END_EBS_BATCH                NUMBER;
le_skip_process                 EXCEPTION;
l_start_date                    VARCHAR2(30);
l_end_date                      VARCHAR2(30);
l_hold_value                    VARCHAR2(30);
l_wait_time                     NUMBER;
BEGIN

   l_start_date                 := NVL(fnd_profile.value('XX_CDH_SEAMLESS_START_DATE'),'SYSDATE-1');
   l_end_date                   := NVL(fnd_profile.value('XX_CDH_SEAMLESS_END_DATE'),'SYSDATE');
   l_hold_value                 := NVL(fnd_profile.value_wnps('XX_CDH_SEAMLESS_HOLD_VALUE'),'NO_HOLD');
   l_wait_time                  := NVL(fnd_profile.value('XX_CDH_SEAMLESS_WAIT_TIME'),30000);

   WHILE l_hold_value = 'ON_HOLD' LOOP
      DBMS_LOCK.SLEEP(l_wait_time);
      l_hold_value                 := NVL(fnd_profile.value_wnps('XX_CDH_SEAMLESS_HOLD_VALUE'),'NO_HOLD');
   END LOOP;

   -----------------------------------
   -- The select query for the cursor
   -----------------------------------
      --defect 29511 -- CA Conversion Program is not picking the batches to process
      lv_select_query := null;

      IF FND_GLOBAL.ORG_ID = 404 THEN

        lv_select_query :=
          ' SELECT batch_id    '||
          ' FROM   hz_imp_batch_summary '||
          ' WHERE  original_system=''A0'''||
          ' AND    batch_status in (''EXTRACTED'',''ACTIVE'') ' ||
          ' AND    description LIKE ''DELTA%'''   ||
          ' AND TRUNC(CREATION_DATE) BETWEEN TRUNC(' || l_start_date || ') AND TRUNC(' || l_end_date || ') ' ||
          ' AND    load_type = '''||p_batch_type || '''' ||
          ' ORDER BY batch_id';

      ELSIF FND_GLOBAL.ORG_ID = 403 THEN

        lv_select_query :=
          ' SELECT batch_id    '||
          ' FROM   hz_imp_batch_summary '||
          ' WHERE  original_system=''A0'''||
          ' AND    batch_status in (''READY_FOR_CA'') ' ||
          ' AND    description LIKE ''DELTA%'''   ||
          ' AND TRUNC(CREATION_DATE) BETWEEN TRUNC(' || l_start_date || ') AND TRUNC(' || l_end_date || ') ' ||
          ' AND    load_type = '''||p_batch_type || '''' ||
          ' ORDER BY batch_id';

      END IF;


   fnd_file.put_line (fnd_file.log, 'Query Used - ' || lv_select_query);

   OPEN lc_ebs_batch_cur FOR lv_select_query;
   LOOP

      FETCH lc_ebs_batch_cur INTO lt_ebs_batch_rec;

      EXIT WHEN lc_ebs_batch_cur%NOTFOUND;

         ln_counter := ln_counter + 1;

         ln_start_ebs_batch := lt_ebs_batch_rec.ebs_batch_id;
         ln_end_ebs_batch   := lt_ebs_batch_rec.ebs_batch_id;

      ---------------------
      -- Submit AOPS Master
      ---------------------

            lt_conc_request_id := FND_REQUEST.submit_request
                                          (   application => 'XXCNV',
                                              program     => 'XX_CDH_NEW_CONV_MASTER_PKG',
                                              description => NULL,
                                              start_time  => NULL,
                                              sub_request => FALSE,
                                              argument1   => ln_start_ebs_batch,
                                              argument2   => ln_end_ebs_batch,
                                              argument3   => p_submit_update,
                                              argument4   => p_sbmt_load_INT_to_STG,
                                              argument5   => p_submit_bulk,
                                              argument6   => p_process_party_rel,
                                              argument7   => p_process_accounts,
                                              argument8   => p_process_acct_sites,
                                              argument9  => p_process_acct_site_uses,
                                              argument10  => p_process_contacts,
                                              argument11  => p_process_contact_points,
                                              argument12  => p_process_profiles,
                                              argument13  => p_process_bank,
                                              argument14  => p_process_ext_attrib,
                                              argument15  => p_import_run_option,
                                              argument16  => p_run_batch_dedup,
                                              argument17  => p_batch_dedup_rule,
                                              argument18  => p_action_duplicates,
                                              argument19  => p_run_addr_val,
                                              argument20  => p_run_reg_dedup,
                                              argument21  => p_reg_dedup_rule,
                                              argument22  => p_gen_fuz_key
                                          );

            IF lt_conc_request_id = 0 THEN
               x_errbuf  := fnd_message.get;
               x_retcode := 2;
               fnd_file.put_line (fnd_file.log, 'AOPS Conversion Master Program failed to submit: ' || x_errbuf);
               x_errbuf  := 'AOPS Conversion Master Program to submit: ' || x_errbuf;
            ELSE
               fnd_file.put_line (fnd_file.log, ' ');
               fnd_file.put_line (fnd_file.log, 'Submitted AOPS Conversion Master Program : '|| TO_CHAR( lt_conc_request_id ));
               fnd_file.put_line (fnd_file.log, 'Start Batch Id : '|| ln_start_batch);
               fnd_file.put_line (fnd_file.log, 'End   Batch Id : '|| ln_end_batch);
               COMMIT;
            END IF;
   END LOOP;
   CLOSE lc_ebs_batch_cur;

   IF ln_counter = 0 THEN
      fnd_file.put_line (fnd_file.log, 'No Eligible Batches were found to submit..');
   END IF;

EXCEPTION
   WHEN le_skip_process THEN
      NULL;
   WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure seamless_aops_conversion - Error - '||SQLERRM);
      x_errbuf := 'Unexpected Error in proecedure seamless_aops_conversion - Error - '||SQLERRM;
      x_retcode := 2;

END seamless_aops_conversion;

-- +===================================================================+
-- | Name        :  seamless_conv_other_sources                        |
-- | Description :  This procedure will be registered as a Concurrent  |
-- |                Program and will be look at hz_imp_batch_summary   |
-- |                table and submit all active batches.               |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_message                                          |
-- |                                                                   |
-- | Returns     :  VARCHAR2                                           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE seamless_conv_other_sources
   (   x_errbuf                        OUT VARCHAR2,
       x_retcode                       OUT VARCHAR2,
       p_source_system                 IN  VARCHAR2,
       p_sbmt_load_INT_to_STG          IN  VARCHAR2,
       p_submit_bulk                   IN  VARCHAR2,
       p_process_party_rel             IN  VARCHAR2,
       p_process_accounts              IN  VARCHAR2,
       p_process_acct_sites            IN  VARCHAR2,
       p_process_acct_site_uses        IN  VARCHAR2,
       p_process_contacts              IN  VARCHAR2,
       p_process_contact_points        IN  VARCHAR2,
       p_process_profiles              IN  VARCHAR2,
       p_process_bank                  IN  VARCHAR2,
       p_process_ext_attrib            IN  VARCHAR2,
       p_import_run_option             IN  VARCHAR2,
       p_run_batch_dedup               IN  VARCHAR2,
       p_batch_dedup_rule              IN  VARCHAR2,
       p_action_duplicates             IN  VARCHAR2,
       p_run_addr_val                  IN  VARCHAR2,
       p_run_reg_dedup                 IN  VARCHAR2,
       p_reg_dedup_rule                IN  VARCHAR2,
       p_gen_fuz_key                   IN  VARCHAR2
   )
   IS

TYPE lt_active_batch_rec_type     IS RECORD
   (   batch_id            NUMBER
   );

lt_active_batch_rec               lt_active_batch_rec_type;

TYPE lt_active_batch_cur_type     IS REF CURSOR;

lc_active_batch_cur               lt_active_batch_cur_type;

/*CURSOR lc_fetch_active_batch_cur
IS
SELECT batch_id
FROM   hz_imp_batch_summary
WHERE  batch_status = 'ACTIVE';*/

le_skip_procedure                EXCEPTION;
le_submit_failed                 EXCEPTION;
ln_ebs_batch_id                  NUMBER;
lb_success                       BOOLEAN;
ln_req_id                        NUMBER;
lv_select_query                 VARCHAR2(2000);
ln_start_aops_batch             NUMBER;
ln_end_aops_batch               NUMBER;
l_start_date                    VARCHAR2(30);
l_end_date                      VARCHAR2(30);
l_hold_value                    VARCHAR2(30);
l_wait_time                     NUMBER;
BEGIN

  l_start_date                 := NVL(fnd_profile.value('XX_CDH_SEAMLESS_START_DATE'),'SYSDATE-1');
  l_end_date                   := NVL(fnd_profile.value('XX_CDH_SEAMLESS_END_DATE'),'SYSDATE');
  l_hold_value                 := NVL(fnd_profile.value_wnps('XX_CDH_SEAMLESS_HOLD_VALUE'),'NO_HOLD');
  l_wait_time                  := NVL(fnd_profile.value('XX_CDH_SEAMLESS_WAIT_TIME'),30000);

  WHILE l_hold_value = 'ON_HOLD' LOOP
      DBMS_LOCK.SLEEP(l_wait_time);
      l_hold_value                 := NVL(fnd_profile.value_wnps('XX_CDH_SEAMLESS_HOLD_VALUE'),'NO_HOLD');
  END LOOP;

   IF p_source_system IS NOT NULL THEN

     IF NVL(p_submit_bulk,'Y') = 'Y' THEN

      lv_select_query := 'SELECT batch_id   ' ||
                        ' FROM  hz_imp_batch_summary  ' ||
                        ' WHERE batch_status = ''ACTIVE'' ' ||
                        ' AND TRUNC(CREATION_DATE) BETWEEN TRUNC(' || l_start_date || ') AND TRUNC(' || l_end_date || ') ' ||
                       ' AND original_system = ''' || p_source_system || '''';
     ELSE

       lv_select_query := 'SELECT batch_id   ' ||
                        ' FROM  hz_imp_batch_summary  ' ||
                        ' WHERE TRUNC(CREATION_DATE) BETWEEN TRUNC(' || l_start_date || ') AND TRUNC(' || l_end_date || ') ' ||
                       ' AND original_system = ''' || p_source_system || '''';
     END IF;

   ELSE

    IF NVL(p_submit_bulk,'Y') = 'Y' THEN

      lv_select_query := 'SELECT batch_id   ' ||
                        ' FROM  hz_imp_batch_summary  ' ||
                        ' WHERE batch_status = ''ACTIVE'' ' ||
                        ' AND TRUNC(CREATION_DATE) BETWEEN TRUNC(' || l_start_date || ') AND TRUNC(' || l_end_date || ')';

    ELSE

      lv_select_query := 'SELECT batch_id   ' ||
                        ' FROM  hz_imp_batch_summary  ' ||
                        ' WHERE TRUNC(CREATION_DATE) BETWEEN TRUNC(' || l_start_date || ') AND TRUNC(' || l_end_date || ')';
    END IF;
   END IF;

   fnd_file.put_line (fnd_file.log, 'Query Used - ' || lv_select_query);

   OPEN lc_active_batch_cur FOR lv_select_query;
   LOOP

      FETCH lc_active_batch_cur INTO lt_active_batch_rec;
      EXIT WHEN lc_active_batch_cur%NOTFOUND;

      ----------------------------------------------------------
      -- Set the context for the request set XX_CDH_CONV_AOPS_RS
      ----------------------------------------------------------
      lb_success := fnd_submit.set_request_set('XXCNV', 'XX_CDH_CONV_NEWSET_OTH_SOURCES');

      IF ( lb_success ) THEN

          ----------------------------------------------------------------------------------
          -- Submit program OD: CDH Load Oracle INT to STG Process which is in stage STAGE10
          ----------------------------------------------------------------------------------
       /*
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CONV_LOAD_INT_STG_PKG',
                              stage       => 'XX_CDH_CONV_LOAD_INT_STG_PKG',
                              argument1   => lt_active_batch_rec.batch_id
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;
          */ --- commented on 07-Jul-14 To fix the program sequence issue Defect 28730



-------------------------------------------------------------------------
       ------ Added on 07-Jul-14  To fix the program sequence issue Defect 28730
--------------------------------------------------------------------------
      ----------------------------------------------------------------------------------
      -- Submit program OD: CDH Load Oracle INT to STG Process which is in stage STAGE10
      ----------------------------------------------------------------------------------

      lb_success := fnd_submit.submit_program
                       (  application => 'XXCNV',
                          program     => 'XX_CDH_CONV_LOAD_INT_STG1',
                          stage       => 'XX_CDH_CONV_LOAD_INT_STG_PKG',
                          argument1   => lt_active_batch_rec.batch_id
                       );
      IF ( NOT lb_success ) THEN
         RAISE le_submit_failed;
      END IF;
       ----------------------------------------------------------------------------------
      -- Submit program OD: CDH Load Oracle INT to STG Process which is in stage STAGE10
      ----------------------------------------------------------------------------------

      lb_success := fnd_submit.submit_program
                       (  application => 'XXCNV',
                          program     => 'XX_CDH_CONV_LOAD_INT_STG2',
                          stage       => 'XX_CDH_CONV_LOAD_INT_STG_PKG',
                          argument1   => lt_active_batch_rec.batch_id
                       );
      IF ( NOT lb_success ) THEN
         RAISE le_submit_failed;
      END IF;
       ----------------------------------------------------------------------------------
      -- Submit program OD: CDH Load Oracle INT to STG Process which is in stage STAGE10
      ----------------------------------------------------------------------------------

      lb_success := fnd_submit.submit_program
                       (  application => 'XXCNV',
                          program     => 'XX_CDH_CONV_LOAD_INT_STG3',
                          stage       => 'XX_CDH_CONV_LOAD_INT_STG_PKG',
                          argument1   => lt_active_batch_rec.batch_id
                       );
      IF ( NOT lb_success ) THEN
         RAISE le_submit_failed;
      END IF;
       ----------------------------------------------------------------------------------
      -- Submit program OD: CDH Load Oracle INT to STG Process which is in stage STAGE10
      ----------------------------------------------------------------------------------

      lb_success := fnd_submit.submit_program
                       (  application => 'XXCNV',
                          program     => 'XX_CDH_CONV_LOAD_INT_STG4',
                          stage       => 'XX_CDH_CONV_LOAD_INT_STG_PKG',
                          argument1   => lt_active_batch_rec.batch_id
                       );
      IF ( NOT lb_success ) THEN
         RAISE le_submit_failed;
      END IF;
       ----------------------------------------------------------------------------------
      -- Submit program OD: CDH Load Oracle INT to STG Process which is in stage STAGE10
      ----------------------------------------------------------------------------------

      lb_success := fnd_submit.submit_program
                       (  application => 'XXCNV',
                          program     => 'XX_CDH_CONV_LOAD_INT_STG5',
                          stage       => 'XX_CDH_CONV_LOAD_INT_STG_PKG',
                          argument1   => lt_active_batch_rec.batch_id
                       );
      IF ( NOT lb_success ) THEN
         RAISE le_submit_failed;
      END IF;

      -----------------------------------------------------------  Code Ends ---ADDED ON 07-Jul-14  to fix the  program sequence issue.

          ----------------------------------------------------------------------------------
          -- Submit program OD: CDH Activate Bulk Batch Program which is in stage STAGE15
          ----------------------------------------------------------------------------------
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_ACTIVATE_BULK_BATCH',
                              stage       => 'XX_CDH_ACT_BULK_BATCH',
                              argument1   => lt_active_batch_rec.batch_id
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;
          -------------------------------------------------------------------------------
          -- Submit program OD: CDH Submit Bulk Import Program which is in stage STAGE20
          -------------------------------------------------------------------------------

          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_SUBMIT_BULK_WRAPPER',
                              stage       => 'XX_CDH_BULK_IMP_WRAPPER',
                              argument1   => p_submit_bulk,
                              argument2   => lt_active_batch_rec.batch_id,
                              argument3   => p_import_run_option,
                              argument4   => p_run_batch_dedup  ,
                              argument5   => p_batch_dedup_rule ,
                              argument6   => p_action_duplicates,
                              argument7   => p_run_addr_val     ,
                              argument8   => p_run_reg_dedup    ,
                              argument9   => p_reg_dedup_rule   ,
                              argument10  => p_gen_fuz_key
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          --------------------------------------------------------------------------------------
          -- Submit program OD: CDH Customer Account Conversion Program which is in stage STAGE30
          --------------------------------------------------------------------------------------

          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CUST_ACCOUNT_CONV',
                              stage       => 'XX_CDH_ACCT_CONV',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_accounts
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          --------------------------------------------------------------------------------------
          -- Submit program OD: CDH Party Relationship Conversion which is in stage STAGE30
          --------------------------------------------------------------------------------------

          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_PARTY_RELATIONSHIP_CONV',
                              stage       => 'XX_CDH_ACCT_CONV',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_party_rel
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          ---------------------------------------------------------------------------------------------
          -- Submit program OD: CDH Customer Account Site Conversion Program which is in stage STAGE40
          ---------------------------------------------------------------------------------------------
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CUST_ACCT_SITE_CONV',
                              stage       => 'XX_CDH_ACCT_SITE_CONV',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_acct_sites
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          --------------------------------------------------------------------------------------------------
          -- Submit program OD: CDH Customer Account Site Uses Conversion Program which is in stage STAGE50
          --------------------------------------------------------------------------------------------------
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CUST_ACCT_SITE_USE_CONV',
                              stage       => 'XX_CDH_CONV_OTH_ENT',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_acct_site_uses
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          --------------------------------------------------------------------------------------------------
          -- Submit program OD: CDH Customer Contact Points Conversion Program which is in stage STAGE50
          --------------------------------------------------------------------------------------------------
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CUST_CONTACT_POINT_CONV',
                              stage       => 'XX_CDH_CONV_OTH_ENT',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_contact_points
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          --------------------------------------------------------------------------------------------------
          -- Submit program OD: CDH Customer Contact Conversion Program which is in stage STAGE50
          --------------------------------------------------------------------------------------------------
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CUST_CONTACT_CONV',
                              stage       => 'XX_CDH_CONV_OTH_ENT',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_contacts
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          --------------------------------------------------------------------------------------------------
          -- Submit program OD: CDH Customer Profile Conversion Program which is in stage STAGE50
          --------------------------------------------------------------------------------------------------
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CUST_PROFILE_CONV',
                              stage       => 'XX_CDH_CONV_OTH_ENT',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_profiles
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          --------------------------------------------------------------------------------------------------
          -- Submit program OD: CDH Customer Bank  Payment Conversion Program which is in stage STAGE50
          --------------------------------------------------------------------------------------------------
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CUST_BANK_PAYMETH_CONV',
                              stage       => 'XX_CDH_CONV_OTH_ENT',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_bank
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          --------------------------------------------------------------------------------------------------
          -- Submit program OD: CDH Customer Extensible Attributes Conversion Program which is in stage STAGE50
          --------------------------------------------------------------------------------------------------
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CUST_EXT_ATTRIB_CONV',
                              stage       => 'XX_CDH_CONV_OTH_ENT',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_ext_attrib
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          -------------------------------------------------------------------------------------------------------------
          -- Submit program OD: CDH Contact Role Responsibility Conversion Program which is in stage STAGE60
          -------------------------------------------------------------------------------------------------------------
          lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CONTACT_ROLE_RESP',
                              stage       => 'XX_CDH_CONT_ROLE_RESP',
                              argument1   => lt_active_batch_rec.batch_id,
                              argument2   => p_process_contacts
                           );
          IF ( NOT lb_success ) THEN
             RAISE le_submit_failed;
          END IF;

          ------------------------------
          -- Submit the Request Set
          ------------------------------
          ln_req_id := fnd_submit.submit_set(null,FALSE);

          IF ln_req_id = 0 THEN
             x_errbuf  := fnd_message.get;
             x_retcode := 2;
             fnd_file.put_line (fnd_file.log, 'Error while submitting Request Set - '||x_errbuf);
          ELSE
             fnd_file.put_line (fnd_file.log, ' ');
             fnd_file.put_line (fnd_file.log, '-------------------------------------------------------- ');
             fnd_file.put_line (fnd_file.log, 'Batch ID: '||lt_active_batch_rec.batch_id);
             fnd_file.put_line (fnd_file.log, 'Request Set submitted with request id: '|| TO_CHAR( ln_req_id ));
             COMMIT;
          END IF;
       END IF;

   END LOOP;


EXCEPTION
   WHEN le_submit_failed THEN
      fnd_file.put_line (fnd_file.log, 'Error while submitting request Set - '||fnd_message.get);
      x_errbuf := 'Error while submitting request Set - '||fnd_message.get;
      x_retcode := 2;
   WHEN le_skip_procedure THEN
      NULL;
   WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure submit_conv_request_set - Error - '||SQLERRM);
      x_errbuf := 'Unexpected Error in proecedure submit_conv_request_set - Error - '||SQLERRM;
      x_retcode := 2;

END seamless_conv_other_sources;

END XXCDH_SEAMLESS_CONV;