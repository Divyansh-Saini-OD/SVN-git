SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_CONV_SEAMLESS_PKG 

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XXCDHCONVSEAMLESSS.pls                             |
-- | Description :  CDH Customer Conversion Seamless Package Spec      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  17-Apr-2007 Indra Varada       Initial draft version     |
-- |DRAFT 1b  25-Apr-2007 Indra Varada       Modified procedure sig.   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   | 
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

AS

PROCEDURE seamless_aops_conversion
   (   x_errbuf                 OUT VARCHAR2,
       x_retcode                OUT VARCHAR2,
       p_batch_type             IN  VARCHAR2,
       p_submit_extract_owb     IN  VARCHAR2,
       p_submit_update          IN  VARCHAR2,
       p_submit_load_owb        IN  VARCHAR2,
       p_submit_bulk            IN  VARCHAR2,
       p_process_party_rel      IN  VARCHAR2,
       p_process_accounts       IN  VARCHAR2,
       p_process_acct_sites     IN  VARCHAR2,
       p_process_acct_site_uses IN  VARCHAR2,
       p_process_contacts       IN  VARCHAR2,
       p_process_contact_points IN  VARCHAR2,
       p_process_profiles       IN  VARCHAR2,
       p_process_bank           IN  VARCHAR2,
       p_process_ext_attrib     IN  VARCHAR2,
       p_import_run_option      IN  VARCHAR2,
       p_run_batch_dedup        IN  VARCHAR2,
       p_batch_dedup_rule       IN  VARCHAR2,
       p_action_duplicates      IN  VARCHAR2,
       p_run_addr_val           IN  VARCHAR2,
       p_run_reg_dedup          IN  VARCHAR2,
       p_reg_dedup_rule         IN  VARCHAR2,
       p_gen_fuz_key            IN  VARCHAR2
   );

PROCEDURE seamless_conv_other_sources
   (   x_errbuf                 OUT VARCHAR2,
       x_retcode                OUT VARCHAR2,
       p_source_system          IN  VARCHAR2,
       p_submit_load_owb        IN  VARCHAR2,
       p_submit_bulk            IN  VARCHAR2,
       p_process_party_rel      IN  VARCHAR2,
       p_process_accounts       IN  VARCHAR2,
       p_process_acct_sites     IN  VARCHAR2,
       p_process_acct_site_uses IN  VARCHAR2,
       p_process_contacts       IN  VARCHAR2,
       p_process_contact_points IN  VARCHAR2,
       p_process_profiles       IN  VARCHAR2,
       p_process_bank           IN  VARCHAR2,
       p_process_ext_attrib     IN  VARCHAR2,
       p_import_run_option      IN  VARCHAR2,
       p_run_batch_dedup        IN  VARCHAR2,
       p_batch_dedup_rule       IN  VARCHAR2,
       p_action_duplicates      IN  VARCHAR2,
       p_run_addr_val           IN  VARCHAR2,
       p_run_reg_dedup          IN  VARCHAR2,
       p_reg_dedup_rule         IN  VARCHAR2,
       p_gen_fuz_key            IN  VARCHAR2
   );


END XX_CDH_CONV_SEAMLESS_PKG;
/
SHOW ERRORS;
