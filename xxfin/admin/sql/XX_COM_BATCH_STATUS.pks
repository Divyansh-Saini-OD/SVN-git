 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 SET SHOW OFF
 PROMPT Creating Package XX_COM_BATCH_STATUS
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

create or replace PACKAGE XX_COM_BATCH_STATUS AS

 -- +=====================================================================+
 -- |                  Office Depot - Project Simplify                    |
 -- |                       WIPRO Technologies                            |
 -- +=====================================================================+
 -- | Name : XX_COM_BATCH_STATUS                                          |
----|                                                                     |
 -- | Change Record:                                                      |
 -- |===============                                                      |
 -- |Version   Date              Author                 Remarks           |
 -- |======   ==========     =============        ======================= |
 -- |Draft 1A 10-Nov-2010    Saravanan             Initial version        |
 -- |                                                                     |
 -- +=====================================================================+


  PROCEDURE Status_Report_Main (  x_errbuf                   OUT NOCOPY      VARCHAR2
                                , x_retcode                  OUT NOCOPY      NUMBER
                                , p_period_stat              VARCHAR2 
                                , p_int_status               VARCHAR2 
                                , p_file_stat                VARCHAR2
                                , p_batch_stat               VARCHAR2
                                , p_job_stat                 VARCHAR2
                                , p_start_date               VARCHAR2
                                , p_end_date                 VARCHAR2
                                , p_file_folder              VARCHAR2
                                , p_file_start_Date          VARCHAR2
                                , p_file_end_date            VARCHAR2 
                                , p_email_list               VARCHAR2
                                );
 PROCEDURE insert_interface_data;

 PROCEDURE Send_Status_Email (  p_request_id  NUMBER
                              , p_email_id    VARCHAR2);

FUNCTION get_threshold (p_cp_name VARCHAR2
                       ,org VARCHAR2
                       )
 RETURN VARCHAR2;

END XX_COM_BATCH_STATUS;
/
