create or replace
PACKAGE XX_CDH_PROFILE_AMT_TEST AS 

  procedure proc_main 
  (
  x_errbuf OUT VARCHAR2,
  x_retcode OUT VARCHAR2,
  p_cust_account_id IN NUMBER,
  p_site_use_id in number :=null,
  p_profile_class_id in number := 0,
   p_create_amt IN VARCHAR2:='T'
  );
  
  /* TODO enter package declarations (types, exceptions, methods etc) here */ 

END XX_CDH_PROFILE_AMT_TEST;
/