SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_ORG_CUST_BO_PUB
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_ORG_CUST_BO_PUB                                            |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   15-Oct-2012     Sreedhar Mohan       Initial draft version                    |
-- +=========================================================================================+

AS

g_bo_process_id   NUMBER := 0;

PROCEDURE initialize( 
   p_bo_customer_type       IN  VARCHAR2,
   p_bpel_process_id        IN  VARCHAR2
)
IS

BEGIN
  XX_CDH_CUST_UTIL_BO_PVT.log_msg( g_bo_process_id, 'g_bo_process_id in initialize start: ' || g_bo_process_id);
  select xx_cdh_customer_bo_proc_id_s.nextval
  into   g_bo_process_id
  from   dual;
  XX_CDH_CUST_UTIL_BO_PVT.log_msg( g_bo_process_id, 'g_bo_process_id in initialize end: ' || g_bo_process_id);

EXCEPTION
  WHEN OTHERS THEN
    XX_CDH_CUST_UTIL_BO_PVT.log_msg( g_bo_process_id, 'Exception in initialize: ' || SQLERRM);
END initialize;

PROCEDURE do_commit (
   p_bo_customer_type     IN  VARCHAR2,
   p_create_update_flag   IN  VARCHAR2,
   p_bpel_process_id      IN  NUMBER DEFAULT   0
)
AS                    
v_xx_cdh_tbl_name_typelist_t    xx_cdh_tbl_name_typelist_t; --xx_cdh_tbl_name_typelist_t is custom table type object
v_bo_tbl_name_gtlist_t          xx_cdh_tbl_name_typelist_t;

  i number:=1;
  j number:=1;  
  v_cnt NUMBER:=0;

BEGIN

   --populate the v_xx_cdh_tbl_name_typelist_t from translation definition
   IF P_BO_CUSTOMER_TYPE = 'DIRECT' THEN
     SELECT CAST
     (MULTISET
      (
        select SOURCE_VALUE1
        from   XX_FIN_TRANSLATEDEFINITION DEF,
               XX_FIN_TRANSLATEVALUES     VAL
        WHERE  DEF.TRANSLATE_ID=VAL.TRANSLATE_ID
        AND    DEF.TRANSLATION_NAME='XX_CDH_BO_SAVED_ENT_DIREC'
      ) AS xx_cdh_tbl_name_typelist_t
     )
     INTO v_xx_cdh_tbl_name_typelist_t
     FROM dual;
   ELSE
     SELECT CAST
     (MULTISET
      (
        select SOURCE_VALUE1
        from   XX_FIN_TRANSLATEDEFINITION DEF,
               XX_FIN_TRANSLATEVALUES     VAL
        WHERE  DEF.TRANSLATE_ID=VAL.TRANSLATE_ID
        AND    DEF.TRANSLATION_NAME='XX_CDH_BO_SAVED_ENT_CONTR'
      ) AS xx_cdh_tbl_name_typelist_t
     )
     INTO v_xx_cdh_tbl_name_typelist_t
     FROM dual;   
   END IF;
   
   /* ***Uncomment this for verification***
   SELECT CAST
   (MULTISET
    (
      select bo_entity_name
      from   XX_CDH_SAVED_BO_ENTITIES_GT
    ) AS xx_cdh_tbl_name_typelist_t
   )
   INTO v_bo_tbl_name_gtlist_t
   FROM dual;     

  FOR i in 1..v_xx_cdh_tbl_name_typelist_t.COUNT LOOP
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(' Translation tbl_name   : ' || i || ': ' ||v_xx_cdh_tbl_name_typelist_t(i).tbl_name);
  END LOOP;
  
  FOR j in 1..v_bo_tbl_name_gtlist_t.COUNT LOOP
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(' BO tbl_name   : ' || j || ': ' ||v_bo_tbl_name_gtlist_t(j).tbl_name);
  END LOOP;  
  ***Uncomment this for verification*** */
  
  select count(1)
    into v_cnt
   from TABLE ( cast ( v_xx_cdh_tbl_name_typelist_t as xx_cdh_tbl_name_typelist_t) ) a
  WHERE NOT EXISTS ( SELECT 'x'
        from XX_CDH_SAVED_BO_ENTITIES_GT
       where bo_entity_name=a.tbl_name);

  XX_CDH_CUST_UTIL_BO_PVT.log_msg(g_bo_process_id, 'Count :'||to_char(v_cnt));
  
  IF (p_create_update_flag = 'U') THEN
    COMMIT;
  ELSE
    IF ( v_cnt > 0 AND p_create_update_flag = 'C') THEN

      --set the interface_status = 4 (incomplete_processing) in XX_CDH_CUST_BO_STG table
      update xxcrm.XX_CDH_CUST_BO_STG
      set    interface_status = 4
      where  bpel_process_id = p_bpel_process_id
      and    interface_status = 2;

      ROLLBACK;

    ELSE

      --set the interface_status = 7 (success_complete) in XX_CDH_CUST_BO_STG table
      update xxcrm.XX_CDH_CUST_BO_STG
      set    interface_status = 7
      where  bpel_process_id = p_bpel_process_id
      and    interface_status = 2;

      COMMIT;

    END IF;
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(g_bo_process_id, 'Exception in do_commit: ' || SQLERRM);
END do_commit;                    

PROCEDURE raise_wf_business_event
   (
    x_errbuf                OUT   VARCHAR2
   ,x_retcode               OUT   VARCHAR2
   ,p_bpel_process_id       IN    NUMBER
   ,p_orig_system_reference IN    VARCHAR2
   )
AS
  l_bo_process_id           NUMBER;
  l_list                    WF_PARAMETER_LIST_T;
  l_param                   WF_PARAMETER_T;
  l_key                     VARCHAR2(240);
  l_arg_name                VARCHAR2(2000);
  l_arg_value               VARCHAR2(2000);
  l_one_arg_name            VARCHAR2(200);
  l_one_arg_value           VARCHAR2(200);
  l_event                   VARCHAR2(240);
  l_event_enabled           VARCHAR2(2) := NULL;
  l_data                    CLOB := NULL;
  l_module_name             VARCHAR2(50);
  fnd_status                BOOLEAN;
  l_event_name              VARCHAR2(255);

BEGIN

  select xx_cdh_customer_bo_proc_id_s.nextval
  into   l_bo_process_id
  from   dual;
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(l_bo_process_id, '(+)XX_CDH_ORG_CUST_BO_PUB.raise_wf_business_event(+)');

  l_event_name := NVL(FND_PROFILE.VALUE('XX_CDH_CUSTOMER_BO_WF_EVENT'),'od.cdh.bo.aopscustsync.test');

  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(l_bo_process_id, '(=)l_event_name: ' || l_event_name);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(l_bo_process_id, '(=)FND_GLOBAL.user_id: ' || FND_GLOBAL.user_id);

  IF FND_GLOBAL.user_id is NULL THEN

    FND_GLOBAL.apps_initialize(
                         109991,
                         51269,
                         222
                       );
  END IF;
  --Get the item key
  l_key := HZ_EVENT_PKG.item_key( l_event_name );
  
  -- initialization of object variables
  l_list := WF_PARAMETER_LIST_T();
  
  -- Add Context values to the list
  hz_event_pkg.AddParamEnvToList(l_list); 

  l_param := WF_PARAMETER_T( NULL, NULL );
  l_param.SetName('XX_BPEL_PROCESS_ID');
  l_param.SetValue(p_bpel_process_id);

  l_list.extend;
  l_list(l_list.last) := l_param; 

  l_param:= null;

  l_param := WF_PARAMETER_T( NULL, NULL );
  l_param.SetName('XX_ORIG_SYSTEM_REFERENCE');
  l_param.SetValue(p_orig_system_reference);

  l_list.extend;
  l_list(l_list.last) := l_param; 

  l_event := HZ_EVENT_PKG.event(l_event_name); 

  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(=)Before Raising Event');
  -- Raise Event         
  Wf_Event.Raise
    ( p_event_name   =>  l_event,
      p_event_key    =>  l_key,
      p_parameters   =>  l_list,
      p_event_data   =>  l_data
     );
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(=)After Raising Event - Success');

  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(-)XX_CDH_ORG_CUST_BO_PUB.raise_wf_business_event(-)');

EXCEPTION
    WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  l_bo_process_id        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  null            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
          , p_procedure_name         =>  'raise_wf_business_event'              
          , p_bo_table_name          =>  null        
          , p_bo_column_name         =>  null       
          , p_bo_column_value        =>  null       
          , p_orig_system            =>  null
          , p_orig_system_reference  =>  null
          , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.raise_wf_business_event '  || SQLERRM      
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      ); 
     x_errbuf := 'UnExpected Error Occured In the Procedure - event_main : ' || SQLERRM;
     x_retcode := 2; 
END raise_wf_business_event;

PROCEDURE create_org_cust_bo(
    p_xx_cdh_customer_bo   IN         HZ_ORG_CUST_BO,
    p_xx_cdh_ext_objs      IN         XX_CDH_EXT_BO_TBL,
    p_bpel_process_id      IN         NUMBER DEFAULT   0,
    p_cust_prof_cls_name   IN         VARCHAR2,
    p_ab_flag              IN         VARCHAR2,
    p_reactivated_flag     IN         VARCHAR2,
    p_CREATED_BY_MODULE    IN         VARCHAR2,
    x_account_osr          OUT NOCOPY VARCHAR2,
    x_account_id           OUT NOCOPY NUMBER,
    x_party_id             OUT NOCOPY NUMBER,
    x_return_status        OUT NOCOPY VARCHAR2,
    x_errbuf               OUT NOCOPY VARCHAR2
)
IS

  l_create_update_flag     VARCHAR2(1) := 'C';
  l_os_owner_table_id      number := 0;  
  l_party_id               NUMBER;
  x_cust_account_id        NUMBER;
  l_valid_obj                BOOLEAN;
  --customer profile id out
  x_cp_id                  NUMBER;
    
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_return_obj_flag        varchar2(1);

  l_organization_id        NUMBER;
  l_organization_os        VARCHAR2(30);
  l_organization_osr       VARCHAR2(255);

  X_MESSAGES               APPS.HZ_MESSAGE_OBJ_TBL;
  X_RETURN_OBJ             APPS.HZ_PARTY_SITE_BO;
  x_cust_acct_id           NUMBER;
  X_PARTY_SITE_ID          NUMBER;  
  X_PARTY_SITE_OS          VARCHAR2(200);
  X_PARTY_SITE_OSR         VARCHAR2(200);
  
  --Copy all nested collection objects from PARTY LAYER into local collection objects
  l_organization_obj       HZ_ORGANIZATION_BO := P_XX_CDH_CUSTOMER_BO.organization_obj;
  l_account_objs           HZ_CUST_ACCT_BO_TBL := P_XX_CDH_CUSTOMER_BO.account_objs;

BEGIN
  -- Standard start of API savepoint
  SAVEPOINT create_org_cust_bo;
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(+)XX_CDH_ORG_CUST_BO_PUB.create_org_cust_bo(+)');

  --Initaialize
  initialize(p_XX_CDH_CUSTOMER_BO.account_objs(1).customer_type, p_bpel_process_id);

  --Check whether the org_cust_bo that is passed is valid  
  l_valid_obj := HZ_REGISTRY_VALIDATE_BO_PVT.is_oca_bo_comp(
                   p_org_obj  => l_organization_obj,
                   p_ca_objs  => p_xx_cdh_customer_bo.account_objs
                 );

  IF NOT(l_valid_obj) THEN
    RAISE fnd_api.g_exc_error;
  END IF;  
  
  --Create Party layer objects
  XX_CDH_PARTY_BO_PVT.create_organization_bo(
    p_init_msg_list       => fnd_api.g_false,
    p_validate_bo_flag    => fnd_api.g_true,
    p_organization_obj    => l_organization_obj,
    p_created_by_module   => p_created_by_module,
    x_return_status       => l_return_status,
    x_msg_count           => l_msg_count,
    x_msg_data            => l_msg_data,
    x_organization_id     => l_organization_id, 
    x_organization_os     => l_organization_os, 
    x_organization_osr    => l_organization_osr
  );
  
  IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
    RAISE fnd_api.g_exc_error;
  END IF;

  HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := p_created_by_module;

  --Create Account Layer Objects
  IF((l_account_objs IS NOT NULL) AND
     (l_account_objs.COUNT > 0)) THEN    
   
   XX_CDH_ACCOUNT_BO_WRAP_PVT.save_cust_accounts(
     p_account_objs       => l_account_objs,   
     p_bo_process_id      => g_bo_process_id,
     p_bpel_process_id    => p_bpel_process_id,
     p_cust_prof_cls_name => p_cust_prof_cls_name,
     p_ab_flag            => p_ab_flag,
     p_reactivated_flag   => p_reactivated_flag,
     p_parent_id          => l_organization_id,
     p_parent_os          => l_organization_obj.orig_system,
     p_parent_osr         => l_organization_obj.orig_system_reference,
     p_created_by_module  => p_created_by_module,
     p_create_update_flag => 'C',
     p_parent_obj_type    => 'ORG',
     x_return_status      => l_return_status,
     x_errbuf             => x_errbuf,
     x_cust_acct_id       => x_cust_acct_id
   );
   XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(=)XX_CDH_ORG_CUST_BO_PUB.create_org_cust_bo, After save_accounts, x_cust_acct_id: ' || x_cust_acct_id);   
    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE fnd_api.g_exc_error;
    END IF;
  END IF;

  --Call procedure to create Account level extensibles 
  IF((p_xx_cdh_ext_objs IS NOT NULL) AND
     (p_xx_cdh_ext_objs.COUNT > 0)) THEN  
    FOR i IN 1..p_xx_cdh_ext_objs.COUNT
    LOOP
      XX_CRM_EXTN_ATTBT_SYNC_PKG.process_account_record (
        p_cust_account_id        => x_cust_acct_id,
        p_orig_system            => l_organization_obj.orig_system,
        p_orig_sys_reference     => l_organization_obj.orig_system_reference,
        p_account_status         => l_account_objs(1).status,
        p_attr_group_type        => p_xx_cdh_ext_objs(i).attr_group_type,
        p_attr_group_name        => p_xx_cdh_ext_objs(i).attr_group_name,
        p_attributes_data_table  => p_xx_cdh_ext_objs(i).attributes_data_table,
        x_return_status          => l_return_status,
        x_error_message          => x_errbuf
      );
      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE fnd_api.g_exc_error;
		--***Evaluate whether or not to supress the exception
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  G_BO_PROCESS_ID        
            , p_bpel_process_id        =>  p_bpel_process_id       
            , p_bo_object_name         =>  'HZ_ORG_CUST_BO'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
            , p_procedure_name         =>  'create_org_cust_bo'              
            , p_bo_table_name          =>  'HZ_CUST_ACCOUNTS'        
            , p_bo_column_name         =>  'CUST_ACCOUNT_ID'       
            , p_bo_column_value        =>  null       
            , p_orig_system            =>  null
            , p_orig_system_reference  =>  null
            , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.create_org_cust_bo while calling process_account_record'  || x_errbuf || ', ' || SQLERRM      
            , p_oracle_error_code      =>  SQLCODE    
            , p_oracle_error_msg       =>  SQLERRM 
        );
      END IF;	
    END LOOP;
  END IF;

  --Call procedure to create E-Billing entities
  XX_CDH_EBILL_ENT_PKG.insert_epdf_entities(
    p_orig_system_reference  => l_organization_obj.orig_system_reference,
    p_cust_account_id        => x_cust_acct_id,
    x_errbuf                 => x_errbuf,
    x_retcode                => l_return_status
  );

  --Call commit process
  do_commit(l_account_objs(1).attribute18, l_create_update_flag, p_bpel_process_id);
  
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(-)XX_CDH_ORG_CUST_BO_PUB.create_org_cust_bo(-)');
EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      --ROLLBACK to create_org_cust_bo;
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  G_BO_PROCESS_ID        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  'HZ_ORG_CUST_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
          , p_procedure_name         =>  'create_org_cust_bo'              
          , p_bo_table_name          =>  'HZ_CUST_ACCOUNTS'        
          , p_bo_column_name         =>  'CUST_ACCOUNT_ID'       
          , p_bo_column_value        =>  null       
          , p_orig_system            =>  null
          , p_orig_system_reference  =>  null
          , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.create_org_cust_bo '  || SQLERRM      
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      );  
      X_RETURN_STATUS := 'E';    
      X_ERRBUF        := 'Error in XX_CDH_ORG_CUST_BO_PUB.create_org_cust_bo'     || SQLERRM;                                          
    WHEN OTHERS THEN
      ROLLBACK to create_org_cust_bo;
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  G_BO_PROCESS_ID        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  'HZ_ORG_CUST_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
          , p_procedure_name         =>  'create_org_cust_bo'              
          , p_bo_table_name          =>  'HZ_CUST_ACCOUNTS'        
          , p_bo_column_name         =>  'CUST_ACCOUNT_ID'       
          , p_bo_column_value        =>  null       
          , p_orig_system            =>  null
          , p_orig_system_reference  =>  null
          , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.create_org_cust_bo '  || SQLERRM      
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      );  
      X_RETURN_STATUS := 'E';    
      X_ERRBUF        := 'Error in XX_CDH_ORG_CUST_BO_PUB.create_org_cust_bo'     || SQLERRM;                                          
END create_org_cust_bo;                            

PROCEDURE update_org_cust_bo(
    p_xx_cdh_customer_bo   IN         HZ_ORG_CUST_BO,
    p_xx_cdh_ext_objs      IN         XX_CDH_EXT_BO_TBL,
    p_bpel_process_id      IN         NUMBER DEFAULT   0,
    p_cust_prof_cls_name   IN         VARCHAR2,
    p_ab_flag              IN         VARCHAR2,
    p_reactivated_flag     IN         VARCHAR2,
    p_created_by_module    IN         VARCHAR2,
    x_account_osr          OUT NOCOPY VARCHAR2,
    x_account_id           OUT NOCOPY NUMBER,
    x_party_id             OUT NOCOPY NUMBER,
    x_return_status        OUT NOCOPY VARCHAR2,
    x_errbuf               OUT NOCOPY VARCHAR2
)
IS

  l_create_update_flag     VARCHAR2(1) := 'U';
  l_os_owner_table_id      number := 0;  
  l_party_id               NUMBER;
  x_cust_account_id        NUMBER;
  l_valid_obj              BOOLEAN;
  --customer profile id out
  x_cp_id                  NUMBER;
  x_organization_id        NUMBER;
  l_organization_os        VARCHAR2(30);
  l_organization_osr       VARCHAR2(255);
    
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_return_obj_flag        varchar2(1);
    
  X_MESSAGES               APPS.HZ_MESSAGE_OBJ_TBL;
  X_RETURN_OBJ             APPS.HZ_PARTY_SITE_BO;
  x_cust_acct_id           NUMBER;
  X_PARTY_SITE_ID          NUMBER;  
  X_PARTY_SITE_OS          VARCHAR2(200);
  X_PARTY_SITE_OSR         VARCHAR2(200);
  
  --Copy all nested collection objects from PARTY LAYER into local collection objects
  l_organization_obj       HZ_ORGANIZATION_BO := P_XX_CDH_CUSTOMER_BO.organization_obj;
  l_account_objs           HZ_CUST_ACCT_BO_TBL := P_XX_CDH_CUSTOMER_BO.account_objs;

BEGIN
  -- Standard start of API savepoint
  SAVEPOINT update_org_cust_bo;
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(+)XX_CDH_ORG_CUST_BO_PUB.update_org_cust_bo(+)');

  --Initaialize
  initialize(p_XX_CDH_CUSTOMER_BO.account_objs(1).customer_type, p_bpel_process_id);

  x_organization_id := p_xx_cdh_customer_bo.organization_obj.organization_id;
  l_organization_os := p_xx_cdh_customer_bo.organization_obj.orig_system;
  l_organization_osr:= p_xx_cdh_customer_bo.organization_obj.orig_system_reference;

  -- check input party_id and os+osr
  hz_registry_validate_bo_pvt.validate_ssm_id(
    px_id              => x_organization_id,
    px_os              => l_organization_os,
    px_osr             => l_organization_osr,
    p_obj_type         => 'ORGANIZATION',
    p_create_or_update => 'U',
    x_return_status    => l_return_status,
    x_msg_count        => l_msg_count,
    x_msg_data         => l_msg_data);

  IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
    RAISE FND_API.G_EXC_ERROR;
  END IF;
  
  --Create Party layer objects
  XX_CDH_PARTY_BO_PVT.save_organization_bo(
    p_init_msg_list       => fnd_api.g_false,      
    p_validate_bo_flag    => fnd_api.g_true,
    p_organization_obj    => l_organization_obj,
    p_created_by_module   => p_created_by_module,
    x_return_status       => l_return_status,
    x_msg_count           => l_msg_count,
    x_msg_data            => l_msg_data,
    x_organization_id     => x_organization_id, 
    x_organization_os     => l_organization_os, 
    x_organization_osr    => l_organization_osr
  );
  IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
    RAISE fnd_api.g_exc_error;
  END IF;

  HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := p_created_by_module;

  --Update Account Layer Objects
  IF((l_account_objs IS NOT NULL) AND
     (l_account_objs.COUNT > 0)) THEN    
   
   XX_CDH_ACCOUNT_BO_WRAP_PVT.save_cust_accounts(
     p_account_objs       => l_account_objs,   
     p_bo_process_id      => g_bo_process_id,
     p_bpel_process_id    => p_bpel_process_id,
     p_cust_prof_cls_name => p_cust_prof_cls_name,
     p_ab_flag            => p_ab_flag,
     p_reactivated_flag   => p_reactivated_flag,
     p_parent_id          => l_party_id,
     p_parent_os          => l_organization_obj.orig_system,
     p_parent_osr         => l_organization_obj.orig_system_reference,
     p_created_by_module  => p_created_by_module,
     p_create_update_flag => 'U',
     p_parent_obj_type    => 'ORG',
     x_return_status      => l_return_status,
     x_errbuf             => x_errbuf,
     x_cust_acct_id       => x_cust_acct_id
   );

   XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(=)XX_CDH_ORG_CUST_BO_PUB.update_org_cust_bo, After save_accounts, x_cust_acct_id: ' || x_cust_acct_id);   
   
    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE fnd_api.g_exc_error;
    END IF;
  END IF;       
  --Call procedure to create Account level extensibles 
  --***Evaluate whether this is needed to be called in Save logic
  IF((p_xx_cdh_ext_objs IS NOT NULL) AND
     (p_xx_cdh_ext_objs.COUNT > 0)) THEN  
    FOR i IN 1..p_xx_cdh_ext_objs.COUNT
    LOOP
      XX_CRM_EXTN_ATTBT_SYNC_PKG.process_account_record (
        p_cust_account_id        => x_cust_acct_id,
        p_orig_system            => l_organization_obj.orig_system,
        p_orig_sys_reference     => l_organization_obj.orig_system_reference,
        p_account_status         => l_account_objs(1).status,
        p_attr_group_type        => p_xx_cdh_ext_objs(i).attr_group_type,
        p_attr_group_name        => p_xx_cdh_ext_objs(i).attr_group_name,
        p_attributes_data_table  => p_xx_cdh_ext_objs(i).attributes_data_table,
        x_return_status          => l_return_status,
        x_error_message          => x_errbuf
      );
      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE fnd_api.g_exc_error;
		--***Evaluate whether or not to supress the exception
      END IF;	
    END LOOP;
  END IF;
  --Call commit process
  do_commit(l_account_objs(1).customer_type, l_create_update_flag, p_bpel_process_id);
  
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(-)XX_CDH_ORG_CUST_BO_PUB.update_org_cust_bo(-)');
EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK to update_org_cust_bo;
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  G_BO_PROCESS_ID        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  'HZ_ORG_CUST_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
          , p_procedure_name         =>  'update_org_cust_bo'              
          , p_bo_table_name          =>  'HZ_CUST_ACCOUNTS'        
          , p_bo_column_name         =>  'CUST_ACCOUNT_ID'       
          , p_bo_column_value        =>  null       
          , p_orig_system            =>  null
          , p_orig_system_reference  =>  null
          , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.update_org_cust_bo '  || SQLERRM      
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      );  
      X_RETURN_STATUS := 'E';    
      X_ERRBUF        := 'Error in XX_CDH_ORG_CUST_BO_PUB.update_org_cust_bo'     || SQLERRM;                                          
    WHEN OTHERS THEN
      ROLLBACK to update_org_cust_bo;
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  G_BO_PROCESS_ID        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  'HZ_ORG_CUST_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
          , p_procedure_name         =>  'update_org_cust_bo'              
          , p_bo_table_name          =>  'HZ_CUST_ACCOUNTS'        
          , p_bo_column_name         =>  'CUST_ACCOUNT_ID'       
          , p_bo_column_value        =>  null       
          , p_orig_system            =>  null
          , p_orig_system_reference  =>  null
          , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.update_org_cust_bo '  || SQLERRM      
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      );  
      X_RETURN_STATUS := 'E';    
      X_ERRBUF        := 'Error in XX_CDH_ORG_CUST_BO_PUB.update_org_cust_bo'     || SQLERRM;                                          
END update_org_cust_bo;                            

PROCEDURE process_account (
    p_xx_cdh_customer_bo   IN         HZ_ORG_CUST_BO,
    p_xx_cdh_ext_objs      IN         XX_CDH_EXT_BO_TBL,
    p_bpel_process_id      IN         NUMBER DEFAULT   0,
    p_cust_prof_cls_name   IN         VARCHAR2,
    p_ab_flag              IN         VARCHAR2,
    p_reactivated_flag     IN         VARCHAR2,
    p_created_by_module    IN         VARCHAR2,
    x_account_osr          OUT NOCOPY VARCHAR2,
    x_account_id           OUT NOCOPY NUMBER,
    x_party_id             OUT NOCOPY NUMBER,
    x_return_status        OUT NOCOPY VARCHAR2,
    x_errbuf               OUT NOCOPY VARCHAR2
)
IS
      
  l_orig_system_ref_id     number := 0;
  L_XX_CDH_CUSTOMER_BO     HZ_ORG_CUST_BO := p_XX_CDH_CUSTOMER_BO;
 
  l_return_status          varchar2(1) := X_RETURN_STATUS;
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_errbuf                 varchar2(2000) := X_ERRBUF;
  l_organization_id        number(15);
  l_organization_os        varchar2(30);
  l_organization_osr       varchar2(255);
  l_create_update_flag     varchar2(1) := 'C';
  
BEGIN
  -- initialize API return status to success.
  l_return_status := FND_API.G_RET_STS_SUCCESS;
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(+)XX_CDH_ORG_CUST_BO_PUB.process_account(+), start_time: ' || to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));

  l_organization_id := p_xx_cdh_customer_bo.organization_obj.organization_id;
  l_organization_os := p_xx_cdh_customer_bo.organization_obj.orig_system;
  l_organization_osr:= p_xx_cdh_customer_bo.organization_obj.orig_system_reference;

  -- check root business object to determine that it should be
  -- create or update, call HZ_REGISTRY_VALIDATE_BO_PVT
  l_create_update_flag := HZ_REGISTRY_VALIDATE_BO_PVT.check_bo_op(
                            p_entity_id      => l_organization_id,
                            p_entity_os      => l_organization_os,
                            p_entity_osr     => l_organization_osr,
                            p_entity_type    => 'HZ_PARTIES',
                            p_parent_id      => NULL,
                            p_parent_obj_type=> NULL 
                          );

  IF(l_create_update_flag = 'E') THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_API_INVALID_ID');
    FND_MSG_PUB.ADD;
    FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
    FND_MESSAGE.SET_TOKEN('OBJECT', 'ORG_CUST');
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

  IF(l_create_update_flag = 'C') THEN
    create_org_cust_bo(
	  p_xx_cdh_customer_bo  => p_xx_cdh_customer_bo,
	  p_xx_cdh_ext_objs     => p_xx_cdh_ext_objs,
	  p_bpel_process_id     => p_bpel_process_id,
	  p_cust_prof_cls_name  => p_cust_prof_cls_name,
	  p_ab_flag             => p_ab_flag,
	  p_reactivated_flag    => p_reactivated_flag,
	  p_created_by_module   => l_create_update_flag,
	  x_account_osr         => x_account_osr,  
	  x_account_id          => x_account_id,  
	  x_party_id            => x_party_id,     
	  x_return_status       => x_return_status,
	  x_errbuf              => x_errbuf  
    );
  ELSIF(l_create_update_flag = 'U') THEN
    update_org_cust_bo(
	  p_xx_cdh_customer_bo  => p_xx_cdh_customer_bo,
	  p_xx_cdh_ext_objs     => p_xx_cdh_ext_objs,
	  p_bpel_process_id     => p_bpel_process_id,
	  p_cust_prof_cls_name  => p_cust_prof_cls_name,
	  p_ab_flag             => p_ab_flag,
	  p_reactivated_flag    => p_reactivated_flag,
	  p_created_by_module   => l_create_update_flag,
	  x_account_osr         => x_account_osr,  
	  x_account_id          => x_account_id,  
	  x_party_id            => x_party_id,     
	  x_return_status       => x_return_status,
	  x_errbuf              => x_errbuf        
    );
  ELSE
    RAISE FND_API.G_EXC_ERROR;
  END IF;

  IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
    RAISE fnd_api.g_exc_error;
  END IF;
  
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(-)XX_CDH_ORG_CUST_BO_PUB.process_account(-), complete_time: ' || to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));

EXCEPTION
  WHEN fnd_api.g_exc_error THEN
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  G_BO_PROCESS_ID        
        , p_bpel_process_id        =>  p_bpel_process_id       
        , p_bo_object_name         =>  'HZ_ORG_CUST_BO'            
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id                    
        , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
        , p_procedure_name         =>  'process_account'              
        , p_bo_table_name          =>  'HZ_CUST_ACCOUNTS'        
        , p_bo_column_name         =>  'CUST_ACCOUNT_ID'       
        , p_bo_column_value        =>  null       
        , p_orig_system            =>  null
        , p_orig_system_reference  =>  null
        , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.process_account '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );  
    X_RETURN_STATUS := 'E';    
    X_ERRBUF        := 'Error in XX_CDH_ORG_CUST_BO_PUB.process_account'     || SQLERRM;                                          
  WHEN OTHERS THEN
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  G_BO_PROCESS_ID        
        , p_bpel_process_id        =>  p_bpel_process_id       
        , p_bo_object_name         =>  'HZ_ORG_CUST_BO'            
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id                    
        , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
        , p_procedure_name         =>  'process_account'              
        , p_bo_table_name          =>  'HZ_CUST_ACCOUNTS'        
        , p_bo_column_name         =>  'CUST_ACCOUNT_ID'       
        , p_bo_column_value        =>  null       
        , p_orig_system            =>  null
        , p_orig_system_reference  =>  null
        , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.process_account '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );  
    X_RETURN_STATUS := 'E';    
    X_ERRBUF        := 'Error in XX_CDH_ORG_CUST_BO_PUB.process_account'     || SQLERRM;                                          
END process_account;

PROCEDURE process_account (
    p_xx_cdh_customer_bo   IN         HZ_ORG_CUST_BO,
    p_xx_cdh_ext_objs      IN         XX_CDH_EXT_BO_TBL,
    p_bpel_process_id      IN         NUMBER DEFAULT   0,
    p_cust_prof_cls_name   IN         VARCHAR2,
    p_ab_flag              IN         VARCHAR2,
    p_reactivated_flag     IN         VARCHAR2,
    p_created_by_module    IN         VARCHAR2
)
IS
      
  l_orig_system_ref_id     number := 0;
  L_XX_CDH_CUSTOMER_BO     HZ_ORG_CUST_BO := p_XX_CDH_CUSTOMER_BO;
 
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_errbuf                 varchar2(2000);
  l_account_osr            varchar2(255); 
  l_account_id             number;  
  l_party_id               number;
  l_organization_id        number(15);
  l_organization_os        varchar2(30);
  l_organization_osr       varchar2(255);
  l_create_update_flag     varchar2(1) := 'C';
  
BEGIN

 process_account (
    p_xx_cdh_customer_bo   => p_xx_cdh_customer_bo,
    p_xx_cdh_ext_objs      => p_xx_cdh_ext_objs,
    p_bpel_process_id      => p_bpel_process_id,
    p_cust_prof_cls_name   => p_cust_prof_cls_name,
    p_ab_flag              => p_ab_flag,
    p_reactivated_flag     => p_reactivated_flag,
    p_created_by_module    => p_created_by_module,
    x_account_osr          => l_account_osr,  
    x_account_id           => l_account_id,   
    x_party_id             => l_party_id,     
    x_return_status        => l_return_status,
    x_errbuf               => l_errbuf       
  );

EXCEPTION
  WHEN OTHERS THEN
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  G_BO_PROCESS_ID        
        , p_bpel_process_id        =>  p_bpel_process_id       
        , p_bo_object_name         =>  'HZ_ORG_CUST_BO'            
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id                    
        , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
        , p_procedure_name         =>  'process_account'              
        , p_bo_table_name          =>  'HZ_CUST_ACCOUNTS'        
        , p_bo_column_name         =>  'CUST_ACCOUNT_ID'       
        , p_bo_column_value        =>  null       
        , p_orig_system            =>  null
        , p_orig_system_reference  =>  null
        , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.process_account '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );  
END process_account;

PROCEDURE process_external_user(
    p_bpel_process_id       IN         NUMBER DEFAULT   0,
    p_xx_cdh_ext_user_bo    IN         XX_CDH_EXT_USER_BO,
    p_orig_system_reference IN         VARCHAR2
) 
IS

  l_messages               HZ_MESSAGE_OBJ_TBL;
  l_return_status          VARCHAR2(1);
  l_web_user_status        VARCHAR2(1);
  x_cust_account_id        NUMBER;
  x_ship_to_acct_site_id   NUMBER;
  x_bill_to_acct_site_id   NUMBER;
  x_party_id               NUMBER;

BEGIN
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(+)XX_CDH_ORG_CUST_BO_PUB.process_external_user(+)');

  --Create Role Responsibility
  XX_CDH_WEBCONTACTS_BO_PUB.save_role_resp ( 
                            p_orig_system           => p_xx_cdh_ext_user_bo.orig_system       
                          , p_cust_acct_osr         => p_xx_cdh_ext_user_bo.cust_acct_osr     
                          , p_cust_acct_cnt_osr     => p_xx_cdh_ext_user_bo.contact_osr 
                          , p_cust_acct_site_osr    => p_xx_cdh_ext_user_bo.acct_site_osr
                          , p_record_type           => p_xx_cdh_ext_user_bo.record_type       
                          , p_permission_flag       => p_xx_cdh_ext_user_bo.permission_flag   
                          , p_action                => p_xx_cdh_ext_user_bo.action_type            
                          , p_web_contact_id        => p_xx_cdh_ext_user_bo.userid    
                          , px_cust_account_id      => x_cust_account_id     
                          , px_ship_to_acct_site_id => x_ship_to_acct_site_id
                          , px_bill_to_acct_site_id => x_bill_to_acct_site_id
                          , px_party_id             => x_party_id            
                          , x_web_user_status       => l_web_user_status
                          , x_return_status         => l_return_status
                          , x_messages              => l_messages
                          );

  IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
    RAISE fnd_api.g_exc_error;
    --***Evaluate whether or not to supress the exception
  END IF;

  --Save External User

  XX_EXTERNAL_USERS_BO_PUB.save_ext_user( 
                         p_userid                => p_xx_cdh_ext_user_bo.userid              
                       , p_password              => p_xx_cdh_ext_user_bo.password            
                       , p_first_name            => p_xx_cdh_ext_user_bo.first_name          
                       , p_middle_initial        => p_xx_cdh_ext_user_bo.middle_initial      
                       , p_last_name             => p_xx_cdh_ext_user_bo.last_name           
                       , p_email                 => p_xx_cdh_ext_user_bo.email               
                       , p_status                => p_xx_cdh_ext_user_bo.status              
                       , p_orig_system           => p_xx_cdh_ext_user_bo.orig_system         
                       , p_cust_acct_osr         => p_xx_cdh_ext_user_bo.cust_acct_osr       
                       , p_contact_osr           => p_xx_cdh_ext_user_bo.contact_osr         
                       , p_acct_site_osr         => p_xx_cdh_ext_user_bo.acct_site_osr       
                       , p_record_type           => p_xx_cdh_ext_user_bo.record_type         
                       , p_access_code           => p_xx_cdh_ext_user_bo.access_code         
                       , p_permission_flag       => p_xx_cdh_ext_user_bo.permission_flag     
                       , p_cust_account_id       => p_xx_cdh_ext_user_bo.cust_account_id     
                       , p_ship_to_acct_site_id  => p_xx_cdh_ext_user_bo.ship_to_acct_site_id
                       , p_bill_to_acct_site_id  => p_xx_cdh_ext_user_bo.bill_to_acct_site_id
                       , p_party_id              => p_xx_cdh_ext_user_bo.party_id            
                       , x_return_status         => l_return_status
                       , x_messages              => l_messages
                       );    
                       
  IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
    RAISE fnd_api.g_exc_error;
    --***Evaluate whether or not to supress the exception
  END IF;                                                    
                                                   
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(-)XX_CDH_ORG_CUST_BO_PUB.process_external_user(-)');
EXCEPTION
  WHEN OTHERS THEN
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  G_BO_PROCESS_ID        
        , p_bpel_process_id        =>  p_bpel_process_id       
        , p_bo_object_name         =>  'XX_CDH_EXT_USER_USER_BO'            
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id                    
        , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
        , p_procedure_name         =>  'process_external_user'              
        , p_bo_table_name          =>  'XX_EXTERNAL_USERS'        
        , p_bo_column_name         =>  'CUST_ACCOUNT_ID'       
        , p_bo_column_value        =>  null       
        , p_orig_system            =>  null
        , p_orig_system_reference  =>  null
        , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.process_external_user '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );  
END process_external_user;

PROCEDURE process_customer_data(
    p_bpel_process_id       IN         NUMBER DEFAULT   0,
    p_orig_system_reference IN         VARCHAR2
)
is
   l_org_cust_xml_payload      sys.XMLTYPE;
   l_cdh_acct_xml_payload      sys.XMLTYPE;
   l_org_cust_bo_payload       HZ_ORG_CUST_BO := null;
   l_cdh_acct_bo_payload       XX_CDH_ACCT_EXT_BO := null;
   xx_cdh_ext_objs             XX_CDH_EXT_BO_TBL := XX_CDH_EXT_BO_TBL();
   l_cust_prof_cls_name        varchar2(60);
   l_ab_flag                   varchar2(1);           
   l_reactivated_flag          varchar2(1); 
   l_created_by_module         varchar2(60);

BEGIN
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(+)XX_CDH_ORG_CUST_BO_PUB.process_customer_data,p_bpel_process_id :' || p_bpel_process_id || ', p_orig_system_reference :' || p_orig_system_reference || '(+)');

  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)Before getting the payload');

  select org_cust_bo_payload,
         acct_ext_bo_payload
  into   l_org_cust_xml_payload,
         l_cdh_acct_xml_payload
  from   xxcrm.XX_CDH_CUST_BO_STG
  where  bpel_process_id = p_bpel_process_id
  and    interface_status = 1;

  --set the interface_status = 2 (in_process) in XX_CDH_CUST_BO_STG table
  update xxcrm.XX_CDH_CUST_BO_STG
  set    interface_status = 2
  where  bpel_process_id = p_bpel_process_id
  and    interface_status = 1;
  commit;

  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)After getting the payload');

  --convert XMLTYPE into object_type

  l_org_cust_xml_payload.toObject(l_org_cust_bo_payload);
  l_cdh_acct_xml_payload.toObject(l_cdh_acct_bo_payload);
  xx_cdh_ext_objs         := l_cdh_acct_bo_payload.xx_cdh_ext_objs;
  l_cust_prof_cls_name    := l_cdh_acct_bo_payload.cust_prof_cls_name;
  l_ab_flag               := l_cdh_acct_bo_payload.ab_flag;      
  l_reactivated_flag      := l_cdh_acct_bo_payload.reactivated_flag;  
  l_created_by_module     := l_cdh_acct_bo_payload.created_by_module;  

  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)After converting the payload into object type');

  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)Before calling XX_CDH_ORG_CUST_BO_PUB.process_account(=)');

  -- Running the BO 
  XX_CDH_ORG_CUST_BO_PUB.process_account( 
    p_xx_cdh_customer_bo => l_org_cust_bo_payload,
    p_xx_cdh_ext_objs    => xx_cdh_ext_objs,
    p_bpel_process_id    => p_bpel_process_id,   
    p_cust_prof_cls_name => l_cust_prof_cls_name, 
    p_ab_flag            => l_ab_flag,            
    p_reactivated_flag   => l_reactivated_flag,   
    p_created_by_module  => l_created_by_module      
  ); 

  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(-)After calling XX_CDH_ORG_CUST_BO_PUB.process_account(-)');

EXCEPTION
    WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  p_bpel_process_id        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  null            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
          , p_procedure_name         =>  'process_customer_data'              
          , p_bo_table_name          =>  null        
          , p_bo_column_name         =>  null       
          , p_bo_column_value        =>  null       
          , p_orig_system            =>  null
          , p_orig_system_reference  =>  null
          , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.process_customer_data '  || SQLERRM      
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      );    
END process_customer_data;

--Comments
procedure sync_customer(
    p_bpel_process_id       IN         NUMBER DEFAULT   0,
    p_xx_cdh_customer_bo    IN         HZ_ORG_CUST_BO,
    p_xx_cdh_acct_ext_bo    IN         XX_CDH_ACCT_EXT_BO,
    p_orig_system_reference IN         VARCHAR2
)
IS
  l_hz_org_cust_bo_payload     sys.XMLTYPE;
  l_xx_cdh_acct_ext_bo_payload sys.XMLTYPE; 
  x_errbuf                     VARCHAR2(2000);
  x_retcode                    NUMBER;
BEGIN
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(+)XX_CDH_ORG_CUST_BO_PUB.sync_customer(+)');

  l_hz_org_cust_bo_payload     := XMLTYPE(p_xx_cdh_customer_bo);
  l_xx_cdh_acct_ext_bo_payload := XMLTYPE(p_xx_cdh_acct_ext_bo);

  --Dump the payload into database with the interface_status = 1 (inserted) in XX_CDH_CUST_BO_STG table
  insert into XXCRM.XX_CDH_CUST_BO_STG 
  (   BPEL_PROCESS_ID      ,
      ORG_CUST_BO_PAYLOAD  ,
      ACCT_EXT_BO_PAYLOAD  ,
      INTERFACE_STATUS     ,
      ORIG_SYSTEM_REFERENCE, 
      CREATION_DATE        ,
      CREATED_BY           
  ) values
  (
      p_bpel_process_id           ,
      l_hz_org_cust_bo_payload    ,
      l_xx_cdh_acct_ext_bo_payload,
      1                           ,
      p_orig_system_reference     ,
      SYSDATE                     ,
      FND_GLOBAL.user_id          
  );

  commit;

  --Now Raise the Business Event
   raise_wf_business_event
   (
    x_errbuf                
   ,x_retcode               
   ,p_bpel_process_id       
   ,p_orig_system_reference 
   );
  commit;
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(=)XX_CDH_ORG_CUST_BO_PUB.sync_customer, x_errbuf: ' || x_errbuf);
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(=)XX_CDH_ORG_CUST_BO_PUB.sync_customer, x_retcode: ' || x_retcode);
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(G_BO_PROCESS_ID, '(-)XX_CDH_ORG_CUST_BO_PUB.sync_customer(-)');

EXCEPTION
    WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  G_BO_PROCESS_ID        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  'HZ_ORG_CUST_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_ORG_CUST_BO_PUB'            
          , p_procedure_name         =>  'sync_customer'              
          , p_bo_table_name          =>  null        
          , p_bo_column_name         =>  null       
          , p_bo_column_value        =>  null       
          , p_orig_system            =>  null
          , p_orig_system_reference  =>  null
          , p_exception_log          =>  'Exception in XX_CDH_ORG_CUST_BO_PUB.sync_customer '  || SQLERRM      
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      ); 
END sync_customer;   

END XX_CDH_ORG_CUST_BO_PUB;
/
SHOW ERRORS;
