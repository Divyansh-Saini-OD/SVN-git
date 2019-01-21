create or replace package XX_IEX_DIARYNOTES_EXTRACT_PKG
AS
--+========================================================================================+
--|      Office Depot - Project FIT                                                        |
--|   Capgemini/Office Depot/Consulting Organization                                       |
--+========================================================================================+
--|Name        :XX_IEX_DIARYNOTES_EXTRACT_PKG                                              |
--|RICE        :                                                                           |
--|Description :This Package is used for inserting data into diary notes staging table     |
--|             and extract data from staging table to flat file. Then the file will be    |
--|                transferred to Webcollect                                               |
--|                                                                                        |
--|                                                                                        |
--|Change Record:                                                                          |
--|==============                                                                          |
--|Version   Date            Author                      Remarks                           |
--|=======   ===========     ====================        ===============                   |
--|1.00      18-OCT-2011     Gangi Reddy M               Initial Version                   |
--+========================================================================================+
    -- This procedure is used to call the insert_diarynotes and extract_stagedata procedures
   PROCEDURE diary_notes_main (
       p_errbuf           OUT      VARCHAR2
      ,p_retcode          OUT      NUMBER
     ,p_cycle_date      IN       VARCHAR2
     ,p_batch_num       IN       NUMBER
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
     ,p_process_type    IN       VARCHAR2
   );
    -- Record Type Declaration
   TYPE diary_notes IS RECORD
   (
       note_id             jtf_notes_b.jtf_note_id%TYPE
      ,cust_account_id     hz_cust_accounts.cust_account_id%TYPE
      ,note_date           jtf_notes_b.creation_date%TYPE
      ,status              fnd_lookups.meaning%TYPE
      ,source_name         jtf_rs_resource_extns.source_name%TYPE
      ,bill_to_site_use_id         hz_cust_site_uses_all.bill_to_site_use_id%TYPE
      ,contact_last_name   hz_parties.person_last_name%TYPE
      ,contact_first_name  hz_parties.person_first_name%TYPE
      ,action_code         fnd_lookups.meaning%TYPE
      ,note_text           jtf_notes_tl.notes%TYPE
      ,attachments         VARCHAR2 (1)
      ,creation_date       hz_cust_accounts.creation_date%TYPE
      ,last_updated_by     hz_cust_accounts.last_updated_by%TYPE
      ,request_id          hz_cust_accounts.request_id%TYPE
      ,created_by          hz_cust_accounts.created_by%TYPE
      ,last_update_date    hz_cust_accounts.last_update_date%TYPE
      ,cycle_date          DATE
      ,batch_num           NUMBER
   );
    --Table type declaration
   TYPE diary_notes_tbl_type IS TABLE OF diary_notes;

    TYPE req_number_tbl_type IS TABLE OF fnd_concurrent_requests.request_id%TYPE
      INDEX BY PLS_INTEGER;

   TYPE file_name_tbl_type IS TABLE OF VARCHAR2(240)
      INDEX BY PLS_INTEGER;

END XX_IEX_DIARYNOTES_EXTRACT_PKG;
/

