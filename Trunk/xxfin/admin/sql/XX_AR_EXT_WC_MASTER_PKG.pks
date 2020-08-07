create or replace
PACKAGE XX_AR_EXT_WC_MASTER_PKG AS
PROCEDURE AR_EXT_MAIN ( 
 p_errbuf	OUT VARCHAR2	
,p_retcode	OUT NUMBER	
,p_action_type IN VARCHAR2
,p_last_run_date	IN VARCHAR2	
,p_to_run_date	IN VARCHAR2	
,P_no_of_threads	IN NUMBER	
,P_content_type	IN NUMBER	
,p_batch_limit   IN NUMBER
,P_compute_stats	IN VARCHAR2
,p_debug	in varchar2 );
TYPE REQ_ID IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
END;
/
SHOW ERRORS
