CREATE OR REPLACE FUNCTION XX_CDH_INVOKE_CUST_EVENT  
    (p_subscription_guid IN RAW, 
     p_event IN OUT NOCOPY wf_event_t
    )
RETURN VARCHAR2
IS
   l_bpel_process_id           NUMBER;
   l_orig_system_reference     VARCHAR2(255);
   l_org_cust_xml_payload      sys.XMLTYPE;
   l_cdh_acct_xml_payload      sys.XMLTYPE;
   l_org_cust_bo_payload       HZ_ORG_CUST_BO;
   l_cdh_acct_bo_payload       XX_CDH_ACCT_EXT_BO;
   l_context                   VARCHAR2(2000);
   l_instance                  varchar2(50);
   l_sid varchar2(50);
   l_spid varchar2(50);

   ln_user_id                  NUMBER;
   ln_resp_appl_id             NUMBER;
   ln_resp_id                  NUMBER;

BEGIN
  --read the parameters values passed from the event
  l_bpel_process_id        := p_event.getvalueforparameter ('XX_BPEL_PROCESS_ID');
  l_orig_system_reference  := p_event.getvalueforparameter ('XX_ORIG_SYSTEM_REFERENCE');

  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, 'Test from WF Subscription for osr: ' || l_orig_system_reference);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, 'l_bpel_process_id: ' || l_bpel_process_id);

  ln_user_id        := p_event.GetValueForParameter('USER_ID');
  ln_resp_appl_id   := p_event.GetValueForParameter('RESP_APPL_ID');
  ln_resp_id        := p_event.GetValueForParameter('RESP_ID');

  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 1 ln_user_id: ' || ln_user_id);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 1 ln_resp_appl_id: ' || ln_resp_appl_id);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 1 ln_resp_id: ' || ln_resp_id);

  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 1 FND_GLOBAL.user_id: ' || FND_GLOBAL.user_id);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 1 FND_GLOBAL.user_name: ' || FND_GLOBAL.user_name);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 1 FND_GLOBAL.resp_id: ' || FND_GLOBAL.resp_id);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 1 FND_GLOBAL.resp_name: ' || FND_GLOBAL.resp_name);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 1 FND_GLOBAL.resp_appl_id: ' || FND_GLOBAL.resp_appl_id);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 1 FND_GLOBAL.org_id: ' || FND_GLOBAL.org_id);

  /*
  IF FND_GLOBAL.user_id = 0 THEN

    FND_GLOBAL.apps_initialize(
                         109991,
                         51269,
                         222
                       );
  END IF;
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=) 2 FND_GLOBAL.user_id: ' || FND_GLOBAL.user_id);
  */
  -- Running the BO 
  /*
  XX_CDH_CUST_UTIL_BO_PVT.process_customer_data(
    p_bpel_process_id       => l_bpel_process_id,
    p_orig_system_reference => l_orig_system_reference
  );
  */
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)Before calling XX_CDH_ORG_CUST_BO_PUB.process_customer_data(+)');

  --SELECT SYS_CONTEXT ('USERENV', 'SESSION_USER') into l_context  FROM DUAL;
  --SELECT  S.SID, P.SPID into l_sid, l_spid   FROM V$SESSION s, v$PROCESS P WHERE AUDSID= SYS_CONTEXT ('USERENV','SESSIONID') and s.paddr = p.addr;

  --XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)l_context:' || l_context);
  --XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)l_instance:' || l_instance);
  --XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)l_sid:' || l_sid);
  --XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)l_spid:' || l_spid);

  --execute immediate 'alter session set events ''10046 trace name context forever, level 12''';
  --execute immediate 'alter session set events ''6508 trace name errorstack level 3''';

  apps.XX_CDH_ORG_CUST_BO_PUB.process_customer_data(
    p_bpel_process_id       => l_bpel_process_id,
    p_orig_system_reference => l_orig_system_reference
  );

  --execute immediate 'alter session set events ''10046 trace name context off'''; 
  --execute immediate 'alter session set events ''6508 trace name context off'''; 
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(-)After calling XX_CDH_ORG_CUST_BO_PUB.process_customer_data(-)');
     
  RETURN 'SUCCESS';
EXCEPTION
    WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  l_bpel_process_id        
          , p_bpel_process_id        =>  l_bpel_process_id       
          , p_bo_object_name         =>  'xx_cdh_invoke_cust_event'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'xx_cdh_invoke_cust_event'            
          , p_procedure_name         =>  'xx_cdh_invoke_cust_event'              
          , p_bo_table_name          =>  null        
          , p_bo_column_name         =>  null       
          , p_bo_column_value        =>  null       
          , p_orig_system            =>  null
          , p_orig_system_reference  =>  null
          , p_exception_log          =>  'Exception in xx_cdh_invoke_cust_event '  || SQLERRM      
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      );    
      --execute immediate 'alter session set events ''10046 trace name context off'''; 
      --execute immediate 'alter session set events ''6508 trace name context off'''; 
END XX_CDH_INVOKE_CUST_EVENT;
/
SHOW ERRORS;