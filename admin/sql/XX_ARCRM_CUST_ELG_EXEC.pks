CREATE OR REPLACE PACKAGE xx_arcrm_cust_elg_exec AS
PROCEDURE main (
      p_errbuf       OUT      VARCHAR2,
      p_retcode      OUT      NUMBER,
      p_actiontype   IN       VARCHAR2,
      p_filepath     IN       VARCHAR2,
      p_batchlimit   IN       NUMBER,
      p_size	     IN       NUMBER,
      p_delimiter    IN       VARCHAR2   ,
      p_last_run_date in    VARCHAR2,
      p_to_run_date   in    VARCHAR2 ,
      p_sample_count  in    number );   
end;
/
show errors;