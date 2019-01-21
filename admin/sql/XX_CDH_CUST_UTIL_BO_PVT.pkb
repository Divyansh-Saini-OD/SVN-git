SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_CUST_UTIL_BO_PVT
  -- +==========================================================================================+
  -- |                  Office Depot - Project Simplify                                         |
  -- +==========================================================================================|
  -- |Name       : XX_CDH_CUST_UTIL_BO_PVT                                                      |
  -- |Description: Wrapper for having utility procs and functions. Contains log messages and    |
  -- |             exceptions                                                                   |
  -- |                                                                                          |
  -- |Change Record:                                                                            |
  -- |                                                                                          |
  -- |Version     Date            Author               Remarks                                  |
  -- |                                                                                          |
  -- |DRAFT 1   18-OCT-2012   Sreedhar Mohan           Initial draft version                    |
  -- |                                                                                          |
  -- +==========================================================================================+
AS
  -- +==========================================================================================+
  -- | Name             : LOG_MSG                                                               |
  -- | Description      : This procedure inserts log messages into XX_CDH_CUSTOMER_BO_LOG       |
  -- |                                                                                          |
  -- +==========================================================================================+

PROCEDURE log_msg(   
  p_bo_process_id           IN NUMBER DEFAULT 0,
  p_msg                     IN VARCHAR2
)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION ;
  BEGIN
    IF NVL(FND_PROFILE.VALUE('XX_CDH_CUSTOMER_BO_LOG_ENABLE'),'N')='Y' THEN
      INSERT INTO xx_cdh_customer_bo_log
        VALUES(xx_cdh_customer_bo_log_s.NEXTVAL
              ,p_bo_process_id
              ,p_msg
              ,SYSDATE
              ,FND_GLOBAL.user_id
              );
        COMMIT;
     ELSE
        ROLLBACK;
     END IF;
  EXCEPTION
  WHEN OTHERS THEN
     ROLLBACK;
  END LOG_MSG;
  
PROCEDURE log_exception (
  p_bo_process_id           IN NUMBER DEFAULT 0,
  p_bpel_process_id         IN NUMBER,  
  p_bo_object_name          IN VARCHAR2,
  p_log_date                IN DATE, 
  p_logged_by               IN NUMBER,
  p_package_name            IN VARCHAR2,
  p_procedure_name          IN VARCHAR2,
  p_bo_table_name           IN VARCHAR2,
  p_bo_column_name          IN VARCHAR2,
  p_bo_column_value         IN VARCHAR2,
  p_orig_system             IN VARCHAR2,
  p_orig_system_reference   IN VARCHAR2,
  p_exception_log           IN VARCHAR2,
  p_oracle_error_code       IN VARCHAR2,
  p_oracle_error_msg        IN VARCHAR2 
)
IS
  PRAGMA AUTONOMOUS_TRANSACTION ;
BEGIN

  --set the interface_status = 6 (error) in XX_CDH_CUST_BO_STG table
  update xxcrm.XX_CDH_CUST_BO_STG
  set    interface_status = 6
  where  bpel_process_id = p_bpel_process_id
  and    interface_status = 2;

  insert into XX_CDH_CUST_BO_EXCEPTIONS 
         (
           EXCEPTION_ID         
          ,BO_PROCESS_ID        
          ,BPEL_PROCESS_ID      
          ,BO_OBJECT_NAME       
          ,LOG_DATE              
          ,PACKAGE_NAME         
          ,PROCEDURE_NAME       
          ,BO_TABLE_NAME        
          ,BO_COLUMN_NAME       
          ,BO_COLUMN_VALUE      
          ,ORIG_SYSTEM          
          ,ORIG_SYSTEM_REFERENCE
          ,EXCEPTION_LOG        
          ,ORACLE_ERROR_CODE    
          ,ORACLE_ERROR_MSG
         )                                       
   VALUES(
          XX_CDH_CUST_BO_EXCEPTIONS_S.NEXTVAL
         ,P_BO_PROCESS_ID
         ,P_BPEL_PROCESS_ID
         ,P_BO_OBJECT_NAME
         ,SYSDATE
         ,P_PACKAGE_NAME         
         ,P_PROCEDURE_NAME       
         ,P_BO_TABLE_NAME        
         ,P_BO_COLUMN_NAME       
         ,P_BO_COLUMN_VALUE      
         ,P_ORIG_SYSTEM          
         ,P_ORIG_SYSTEM_REFERENCE
         ,P_EXCEPTION_LOG        
         ,P_ORACLE_ERROR_CODE    
         ,P_ORACLE_ERROR_MSG
         );
   COMMIT;

EXCEPTION
  when others then
     rollback;                          
END Log_exception;

PROCEDURE save_gt(
  p_bo_process_id           IN NUMBER,
  p_bo_entity_name          IN VARCHAR2,
  p_bo_table_id             IN NUMBER,
  p_orig_system             IN VARCHAR2,
  p_orig_system_reference   IN VARCHAR2
)
AS                    
  PRAGMA AUTONOMOUS_TRANSACTION ;
  
  BEGIN

      INSERT INTO XX_CDH_SAVED_BO_ENTITIES_GT 
              (
                BO_PROCESS_ID        
               ,BO_ENTITY_NAME       
               ,BO_TABLE_ID          
               ,ORIG_SYSTEM          
               ,ORIG_SYSTEM_REFERENCE
               ,LAST_COMMIT_DATE     
               ,COMMITTED_BY         
               ,TRANS_VALIDATED_FLAG 
              )                                       
        VALUES(
               P_BO_PROCESS_ID
              ,P_BO_ENTITY_NAME
              ,P_BO_TABLE_ID
              ,P_ORIG_SYSTEM
              ,P_ORIG_SYSTEM_REFERENCE
              ,sysdate
              ,FND_GLOBAL.user_id
              ,NULL
              );
        COMMIT;

  EXCEPTION
  WHEN OTHERS THEN
     ROLLBACK;     
end save_gt;

procedure purge_gt
IS
begin
  EXECUTE IMMEDIATE 'truncate table XX_CDH_SAVED_BO_ENTITIES_GT';
end purge_gt;

FUNCTION get_orig_system_ref_id(
  p_orig_system             IN VARCHAR2,
  p_orig_system_reference   IN VARCHAR2, 
  p_owner_table_name        IN VARCHAR2
) RETURN NUMBER
is
        cursor get_orig_sys_ref_id_csr 
        is
        SELECT ORIG_SYSTEM_REF_ID
        FROM   HZ_ORIG_SYS_REFERENCES
        WHERE  ORIG_SYSTEM = p_orig_system
        and ORIG_SYSTEM_REFERENCE = p_orig_system_reference
        and owner_table_name = p_owner_table_name
        and status = 'A';

l_orig_system_ref_id number;
begin
        open get_orig_sys_ref_id_csr;
        fetch get_orig_sys_ref_id_csr into l_orig_system_ref_id;
        close get_orig_sys_ref_id_csr;
        return l_orig_system_ref_id;
end get_orig_system_ref_id;

function get_os_owner_table_id(
  p_orig_system             IN VARCHAR2,
  p_orig_system_reference   IN VARCHAR2, 
  p_owner_table_name        IN VARCHAR2
) RETURN NUMBER
is
        cursor get_os_owner_table_id_csr 
        is
        SELECT OWNER_TABLE_ID
        FROM   HZ_ORIG_SYS_REFERENCES
        WHERE  ORIG_SYSTEM = p_orig_system
        and ORIG_SYSTEM_REFERENCE = p_orig_system_reference
        and owner_table_name = p_owner_table_name
        and status = 'A';

l_os_owner_table_id number;
begin
        open get_os_owner_table_id_csr;
        fetch get_os_owner_table_id_csr into l_os_owner_table_id;
        close get_os_owner_table_id_csr;
        return l_os_owner_table_id;
end get_os_owner_table_id;

-- +===================================================================+
-- | Name        : is_account_exists                                   |
-- | Description : Function to checks whether customer account         |
-- |               already exists or not                               |
-- | Parameters  : p_acct_orig_sys_ref,p_orig_sys                      |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_account_exists(
  p_acct_orig_sys_ref       IN VARCHAR2,
  p_acct_orig_sys           IN VARCHAR2
) RETURN NUMBER
IS

lc_acct_orig_sys_ref    VARCHAR2(2000) := p_acct_orig_sys_ref;
lc_acct_orig_sys        VARCHAR2(2000) := p_acct_orig_sys;
ln_cust_account_id      NUMBER;

BEGIN

   SELECT owner_table_id
   INTO   ln_cust_account_id
   FROM   hz_orig_sys_references
   WHERE  orig_system_reference = lc_acct_orig_sys_ref
   AND    orig_system           = lc_acct_orig_sys
   AND    owner_table_name      = 'HZ_CUST_ACCOUNTS'
   AND    status                = 'A';

   RETURN ln_cust_account_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;

END is_account_exists;


-- +===================================================================+
-- | Name        : is_acct_site_exists                                 |
-- | Description : Function to check whether customer account site     |
-- |               already exists or not                               |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys                      |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_acct_site_exists(
  p_site_orig_sys_ref       IN VARCHAR2,
  p_site_orig_sys           IN VARCHAR2
) RETURN NUMBER
IS

lc_site_orig_sys_ref    VARCHAR2(2000) := p_site_orig_sys_ref;
lc_site_orig_sys        VARCHAR2(2000) := p_site_orig_sys;
ln_acct_site_id         NUMBER;

BEGIN

   SELECT hosr.owner_table_id
   INTO   ln_acct_site_id
   FROM   hz_orig_sys_references hosr,
          hz_cust_acct_sites     hcas
   WHERE  hosr.orig_system_reference  = lc_site_orig_sys_ref
   AND    hosr.orig_system            = lc_site_orig_sys
   AND    hosr.owner_table_name       = 'HZ_CUST_ACCT_SITES_ALL'
   AND    hosr.status                 = 'A'
   AND    hcas.cust_acct_site_id      = hosr.owner_table_id;

   RETURN   ln_acct_site_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;


END is_acct_site_exists ;


-- +===================================================================+
-- | Name        : is_acct_site_use_exists                             |
-- | Description : Function to check whether customer account site use |
-- |               already exists or not                               |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys,p_site_code          |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_acct_site_use_exists(
  p_site_orig_sys_ref       IN VARCHAR2,
  p_orig_sys                IN VARCHAR2,
  p_site_code               IN VARCHAR2
) RETURN NUMBER
IS

lc_site_orig_sys_ref    VARCHAR2(2000) := p_site_orig_sys_ref;
lc_orig_sys             VARCHAR2(2000) := p_orig_sys;
ln_site_use_id          NUMBER;

BEGIN

   SELECT hcsu.site_use_id
   INTO   ln_site_use_id
   FROM   apps.hz_orig_sys_references hosr,
          apps.hz_cust_acct_sites     hcs,
          apps.hz_cust_site_uses      hcsu
   WHERE  hosr.orig_system_reference  = p_site_orig_sys_ref
   AND    hosr.orig_system            = p_orig_sys
   AND    hcs.status                  = 'A'
   AND    hosr.owner_table_name       = 'HZ_CUST_ACCT_SITES_ALL'
   AND    hosr.status                 = 'A'
   AND    hcsu.status                 = 'A'
   AND    hcs.cust_acct_site_id       = hosr.owner_table_id
   AND    hcs.cust_acct_site_id       = hcsu.cust_acct_site_id
   AND    hcsu.site_use_code          = p_site_code;

   RETURN ln_site_use_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;

END is_acct_site_use_exists;

-- +===================================================================+
-- | Name        : bill_to_use_id_val                                  |
-- | Description : Funtion to get bill_to_use_id                       |
-- |                                                                   |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys,p_site_code          |
-- |                                                                   |
-- +===================================================================+
FUNCTION bill_to_use_id_val(
  p_bill_to_orig_sys        IN VARCHAR2,
  p_bill_to_orig_add_ref    IN VARCHAR2
) RETURN NUMBER
AS
ln_site_use_id  NUMBER := NULL;
BEGIN

    IF(p_bill_to_orig_sys IS NOT NULL AND p_bill_to_orig_add_ref IS NOT NULL)THEN

        BEGIN
            SELECT hosr.owner_table_id
            INTO   ln_site_use_id
            FROM   hz_orig_sys_references hosr,
                   hz_cust_site_uses      hcsu
            WHERE  hosr.orig_system           = p_bill_to_orig_sys
            AND    hosr.orig_system_reference = p_bill_to_orig_add_ref
            AND    hosr.owner_table_name      = 'HZ_CUST_SITE_USES_ALL'
            AND    hosr.status                = 'A'
            AND    hcsu.site_use_id           = hosr.owner_table_id;

            RETURN ln_site_use_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN NULL;
            WHEN OTHERS THEN
                RETURN NULL;
        END;

    END IF;

END bill_to_use_id_val;

END XX_CDH_CUST_UTIL_BO_PVT;
/
SHOW ERRORS;