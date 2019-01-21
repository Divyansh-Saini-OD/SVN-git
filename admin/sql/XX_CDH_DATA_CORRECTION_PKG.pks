CREATE OR REPLACE PACKAGE xx_cdh_data_correction_pkg
-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- |                         Oracle Consulting                                                  |
-- +============================================================================================+
-- | Name        : XX_CDH_DATA_CORRECTION_PKG                                                   |
-- | Description : Custom package for data corrections                                          |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        17-Sep-2007     Rajeev Kamath        Initial version                             |
-- |2.0        10-Jul-2007     Ambarish Mukherjee   Added code for operating unit fix AOPS      |
-- |3.0        15-Jul-2008     Indra Varada         Modified Code For Operating Unit Fix AOPS   |
-- |3.1        29-Jul-2008     Indra Varada         New Procdedure added to inactivate site     |
-- |3.2        02-Jan-2009     Indra Varada         Moved Data Correction Private Procedure     |
-- |                                                Declarations into Spec to handle dynamic    |
-- |                                                Calling,proc main decl. changed             |
-- |3.3        02-Jan-2009     Naga Kalyan          New Procedure fix_multiple_sites_uses       |
-- |                                                added to inactivate duplicate sites and     |
-- |                                                uses in 404 Op Unit.                        |
-- |3.4        14-Jan-2009     Indra Varada         Duplicate grandparent added to spec         |
-- |3.5        15-Feb-2009     Indra Varada         Added Procedure to Convert customer from    |
-- |                                                 indirect to Direct                         |
-- |3.6        22-Apr-2009     Indra Varada         Added procedure to correct CA OSR for       |
-- |                                                   Site Uses                                |
-- |3.7        06-May-2009     Sreedhar Mohan       Added procedure to correct Dup party        |
-- |                                                   Sites for the same site OSR              |
-- |3.8        21-May-2009     Indra Varada         Added procedure to non US,CA Country ou     |
-- |                                                  This script is for one time run only      |
-- |3.9        02-Jun-2009     Indra Varada         Added procedure to fix 'REVOKED' roles      |
-- |4.0        05-Jun-2009     Indra Varada         Data Fix For QC#15686                       |
-- |4.1        09-Jun-2009     Indra Varada     Added procedure to fix prospect flag            |
-- |4.2        09-Jun-2009     Kalyan         Added procedure to activate account               |
-- |                                                profile status.                             |
-- |4.3        02-July-2009    Indra Varada         Procedures added to fix duplicate acct      |
-- |                                                roles, null states, null provinces          |
-- |4.4        09-July-2009    Indra Varada         FiX To Remove Duplicate SPC Defect#493      |
-- |4.5        09-July-2009    Kalyan               FiX To Correct invalid hz_org_contact       |
--                                                  records.                                    |
-- |4.6        23-July-2009    Kalyan               FiX To inactivate direct customer records   |
--                                                  in xx_tm_nam_terr_entity_dtls.              |
-- |4.7        17-Sep-2009     Kalyan               FiX To reset fdk_code for tasks.            |
-- |4.8        19-Nov-2009     Indra Varada         Fix to correct account name party name sync |
-- |4.8        19-Jan-2010     Kalyan               Fix collection/contact records related to   |
-- |                                                hz_cust_account_roles/hz_contact_points.    |
-- |4.9        21-Jan-2010     Devi                 Fix AB collection/contact records related   |
-- |                                                to hz_cust_account_roles/hz_contact_points. |
-- |5.0        22-Sep-2010     Srini                Adding seq_issue_alert procedure.           |
-- |5.1        15-Jun-2011     Indra Varada         GrandParent Relationship end date           |
-- |5.2        02-Jan-2012     Dheeraj Vernekar     Adding xx_cdh_loyalty_code_fix_main procedure|
-- |                                                for correcting primary flag of party loyalty |
-- |                                                class code, QC 15894.                       |
-- |5.3          29-MAY-2012      Devendra Petkar        SFDC - Duplicate party id            |
-- |5.4          07-JUL-2012      Devendra Petkar        ePDF enhancement - Update Historical email  |
-- |                            subject for Invoice and Consolidate Bill    |
--- 5.5          27-Sep-2013    Pratesh Shukla       Changed parameter p_aops_acct from number to Varchar2
---                                                  in procedure XX_CDH_DATA_CORRECTION_PKG.convert_indirect_to_direct
--- 5.6          13-MAY-2015   Sridhar Pamu          Added xxcdh_update_null_pt to correct null payment |
---                                                  terms in Customer Profiles for defect 34126 |
-- |5.8        11-May-2016     Sreedhar Mohan        Removed procedure fix_duplicate_banks       |
-- |                                                 Removed procedure inactivate_entity_dtls    |
-- |5.9        26-Jul-2016     Prasad Devar         Removed table reference for TOPS retire Project    |
-- |5.10       21-Sep-2016     Hanmanth Jogiraju     Removed fix_ab_collect_rec procedures       |
-- |5.11      04-MAR-2017     Sridhar Pamu         Added procedure  xxcdh_update_override_terms for defect 40857 |
-- +============================================================================================+
AS
-- +===================================================================+
-- | Name        : main                                                |
-- |                                                                   |
-- | Description : concurrent program main                             |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE main (
      x_errbuf           OUT      VARCHAR2,
      x_retcode          OUT      VARCHAR2,
      p_commit           IN       VARCHAR2,
      p_procedure_name   IN       VARCHAR2
   );

--- ******* DATA CORRECTION PROCEDURE DECLARATIONS Begins ******
   PROCEDURE fix_party_inactive (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_incorrect_org_id (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_hz_loc_assignments (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_duplicate_prim_acct_st_use (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_duplicate_person_profiles (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE inactivate_acct_sites (
      x_errbuf        OUT      VARCHAR2,
      x_retcode       OUT      VARCHAR2,
      p_account_osr   IN       VARCHAR2
   );

   PROCEDURE fix_duplicate_role_resp (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_ca_osr (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_attribute_prospect (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_ou_change (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_duplicate_grandparents (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

--- ******* DATA CORRECTION PROCEDURE DECLARATIONS Ends ******

   -- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- |                                                                   |
-- | Description : Procedure used to store the count of records that   |
-- |               are processed/failed/succeeded                      |
-- | Parameters  : p_debug_msg                                         |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE log_debug_msg (p_debug_msg IN VARCHAR2);

-- +===================================================================+
-- | Name        : log_exception                                       |
-- | Description : This procedure is used for logging exceptions into  |
-- |                conversion common elements tables.                 |
-- |                                                                   |
-- | Parameters :  p_conversion_id,p_record_control_id,p_procedure_name|
-- |               p_batch_id,p_exception_log,p_oracle_error_msg       |
-- +===================================================================+
   PROCEDURE log_exception (
      p_record_control_id      IN   NUMBER,
      p_source_system_code     IN   VARCHAR2,
      p_source_system_ref      IN   VARCHAR2,
      p_procedure_name         IN   VARCHAR2,
      p_staging_table_name     IN   VARCHAR2,
      p_staging_column_name    IN   VARCHAR2,
      p_staging_column_value   IN   VARCHAR2,
      p_batch_id               IN   NUMBER,
      p_exception_log          IN   VARCHAR2,
      p_oracle_error_code      IN   VARCHAR2,
      p_oracle_error_msg       IN   VARCHAR2
   );

-- +===================================================================+
-- | Name        : acct_ou_correction_main                             |
-- |                                                                   |
-- | Description : concurrent program main                             |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE acct_ou_correction_main (
      x_errbuf         OUT      VARCHAR2,
      x_retcode        OUT      VARCHAR2,
      p_bulk_process   IN       VARCHAR2 DEFAULT 'N',
      p_batch_id       IN       NUMBER,
      p_account_osr    IN       VARCHAR2
   );

-- +===================================================================+
-- | Name        : inactivate_acct_sites_main                          |
-- |                                                                   |
-- | Description : concurrent program main                             |
-- |                                                                   |
-- | Parameters  : p_account_osr                                       |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE inactivate_acct_sites_main (
      x_errbuf        OUT      VARCHAR2,
      x_retcode       OUT      VARCHAR2,
      p_account_osr   IN       VARCHAR2
   );

-- +===================================================================+
-- | Name        :         NUM_CHARS                                   |
-- | Description :         This Function will be used to find the      |
-- |                       count of a patterm in a string              |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :         INSTRING, INPATTERN                         |
-- |                                                                   |
-- | Returns     :         error message                               |
-- |                                                                   |
-- +===================================================================+
   FUNCTION num_chars (instring VARCHAR2, inpattern VARCHAR2)
      RETURN NUMBER;

-- +===================================================================+
-- | Name        : fix_multiple_sites_uses                             |
-- |                                                                   |
-- | Description : Inactivate duplicate sites and uses in 404 Op Unit. |
-- |                                                                   |
-- | Parameters  :  p_commit                                           |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE fix_multiple_sites_uses (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

-- +===================================================================+
-- | Name        : fix_bill_to_data                                    |
-- |                                                                   |
-- | Description : Set bill_to_site_use_id to null when BILL_TO usage  |
-- |               is 'I'.                                             |
-- |                                                                   |
-- | Parameters  :  p_commit                                           |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE fix_bill_to_data (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE convert_indirect_to_direct (
      x_errbuf      OUT      VARCHAR2,
      x_retcode     OUT      VARCHAR2,
      p_aops_acct   IN       VARCHAR2,
      p_commit      IN       VARCHAR2
   );

   PROCEDURE fix_dup_primary_site (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_ca_shipto_site_use_osr (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_dup_party_sites (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE flush_summary_batchid (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE flush_summary_summaryid (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE flush_custprofiles_batch (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE flush_classifics_batch (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE flush_extensibles_batch (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE fix_country_ou_onetime (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE end_fin_hier_rels (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_revoke_roles (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE fix_loc_content_source (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE fix_party_prospect_flag (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE activate_acct_prof (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE fix_dup_acct_roles (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE fix_null_states (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE fix_null_provinces (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE fix_dup_spc (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE fix_invalid_cnt (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE nodes_correction (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE acct_party_name_sync (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE fix_collect_rec (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE seq_issue_alert (
      x_errbuf    OUT NOCOPY      VARCHAR2,
      x_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE end_grandparent_rel (
      x_errbuf    OUT NOCOPY      VARCHAR2,
      x_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE xx_cdh_loyalty_code_fix_main (
      x_errbuf    OUT NOCOPY      VARCHAR2,
      x_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE sp_fix_cust_account_attribute6 (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_ins_account_master (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_del_notaops_site_master (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_ins_del_site_master (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_sfdc_hz_orig_system_ref (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_sfdc_dup_party (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_dup_billdocs (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_wc_collector_id (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_insert_epdf (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE fix_dup_psite_ext_attribs (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   );

   PROCEDURE sp_epdf_upd_transmission_dtl (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_epdf_ins_file_name_dtl (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_epdf_purge_billdocs_proc (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

   PROCEDURE sp_epdf_purge_billdocs_inproc (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

--To purge xx_cdh_ebl_log
   PROCEDURE sp_reset_ebl_log (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

--To purge ebl contacts upload / download stg tables
   PROCEDURE sp_purge_ebl_upload_contact (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

-- To correct NULL payment terms in Customer Profile record
   PROCEDURE xxcdh_update_null_pt (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );

-- To Correct Override terms flag in customer profiles.
   PROCEDURE xxcdh_update_override_terms (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   );
END xx_cdh_data_correction_pkg;
/

SHOW ERRORS;