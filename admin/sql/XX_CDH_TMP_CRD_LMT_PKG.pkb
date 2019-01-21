SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_CDH_TMP_CRD_LMT_PKG

WHENEVER SQLERROR CONTINUE
create or replace PACKAGE BODY XX_CDH_TMP_CRD_LMT_PKG
AS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_CDH_TMP_CRD_LMT_PKG                                                               |
-- |                                                                                                     |
-- | Description :                                                                                       |
-- |                                                                                                     |
-- | Rice ID     : E3512                                                                                 |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- |=========    ===========  =============        ======================================================|
-- |  1.0        21-MAR-2016  Manikant Kasu        Program to update the credit limit to original amount |
-- |                                               after temp credit limit expires                       |
-- |  1.1        15-NOV-2016  Vasu Raparla         Modified for TempCreditUpload Tool process            |
-- +=====================================================================================================+

g_proc              VARCHAR2(80) := NULL;
g_debug             VARCHAR2(1)  := 'N';
gc_success          VARCHAR2(100)   := 'SUCCESS';
gc_failure          VARCHAR2(100)   := 'FAILURE';

-- +======================================================================+
-- |                          Office Depot Inc.                           |
-- +======================================================================+
-- | Name             : log_debug_msg                                     |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
-- +======================================================================+

PROCEDURE log_debug_msg ( p_debug_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;

BEGIN
  
  IF (g_debug = 'Y') THEN
    XX_COM_ERROR_LOG_PUB.log_error
      (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXCDH'
        ,p_program_type            => 'LOG'             
        ,p_attribute15             => 'XX_CDH_TMP_CRD_LMT_PKG'      
        ,p_attribute16             => g_proc
        ,p_program_id              => 0                    
        ,p_module_name             => 'CDH'      
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
    FND_FILE.PUT_LINE(FND_FILE.log, p_debug_msg);
  END IF;
END log_debug_msg;

-- +======================================================================+
-- |                          Office Depot Inc.                           |
-- +======================================================================+
-- | Name             : log_error                                         |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
-- +======================================================================+

PROCEDURE log_error ( p_error_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;
 
BEGIN
  
  XX_COM_ERROR_LOG_PUB.log_error
      (
        p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCDH'
      ,p_program_type            => 'ERROR'             
      ,p_attribute15             => 'XX_CCDH_iREC_TMP_CRD_LMT_PKG'      
      ,p_attribute16             => g_proc
      ,p_program_id              => 0                    
      ,p_module_name             => 'CDH'      
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => 'MAJOR'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
  FND_FILE.PUT_LINE(FND_FILE.LOG, p_error_msg);    

END log_error;
-- +===================================================================+
-- | Name  : get_cust_details                                       |
-- | Description     :Gets cust_accoount_id from the Account_number    |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      :p_account_num                                    |
-- +===================================================================+

procedure get_cust_details(p_customer_number  IN  hz_cust_accounts.account_number%TYPE,
                            p_currency         IN VARCHAR2,
                            x_cust_accnt_id    OUT hz_cust_accounts.cust_account_id%TYPE,
                            x_cust_prof_id     OUT hz_customer_profiles.cust_account_profile_id%TYPE,
                            x_cust_prof_amt_id OUT hz_cust_profile_amts.cust_acct_profile_amt_id%TYPE,
                            x_return_status    OUT VARCHAR2,
                            x_error_msg        OUT VARCHAR2
                              ) is 
  
BEGIN
    x_return_status := NULL;
    x_error_msg     := NULL;
    x_cust_accnt_id := NULL;
    x_cust_prof_id  := NULL;
    x_cust_prof_amt_id:=NULL;
    
   SELECT hca.cust_account_id,hcp.cust_account_profile_id,hcpa.cust_acct_profile_amt_id
     INTO x_cust_accnt_id,x_cust_prof_id,x_cust_prof_amt_id
     FROM hz_cust_accounts hca, 
          hz_customer_profiles hcp, 
          hz_cust_profile_amts hcpa
    WHERE 1 = 1
      AND hca.cust_account_id         = hcp.cust_account_id
      AND hcp.cust_account_profile_id = hcpa.cust_account_profile_id
      AND hcp.site_use_id is null
      AND hcpa.site_use_id is null
      AND hcpa.currency_code  = upper(p_currency)
      AND hca.account_number  = p_customer_number;
     
     x_return_status := gc_success;
  EXCEPTION
   WHEN NO_DATA_FOUND
    THEN
      x_return_status := gc_failure;
      x_error_msg     := 'No Data found for Customer :'||p_customer_number;
    WHEN TOO_MANY_ROWS
    THEN
      x_return_status := gc_failure;
      x_error_msg     := 'Too many Records found for Customer:'||p_customer_number;

    WHEN OTHERS
    THEN
      x_return_status := gc_failure;
      x_error_msg     := 'Error while getting the Customer info '||SQLERRM;
  END get_cust_details;

-- +===================================================================+
-- | Name  : get_active_crd_lmt_count                                  |
-- | Description :Gets the count of exisisting credit limits for the   |
-- |              given parameters                                     |
-- |                                                                   |
-- +===================================================================+

function get_active_crd_lmt_count( p_cust_account_id    IN hz_cust_accounts.cust_account_id%TYPE,
                                   p_cust_prof_id       IN hz_customer_profiles.cust_account_profile_id%TYPE,
                                   p_cust_prof_amt_id   IN hz_cust_profile_amts.cust_acct_profile_amt_id%TYPE,
                                   p_attr_group_id      IN XX_CDH_CUST_ACCT_EXT_B.ATTR_GROUP_ID%TYPE,
                                   p_start_date         IN XX_CDH_CUST_ACCT_EXT_B.D_EXT_ATTR1%TYPE,
                                   p_end_date           IN XX_CDH_CUST_ACCT_EXT_B.D_EXT_ATTR2%TYPE
                                  ) return number is 
ln_tmp_clmt_cnt number :=0; 

  BEGIN
    
    
    SELECT count(1)
      INTO ln_tmp_clmt_cnt
      FROM XX_CDH_CUST_ACCT_EXT_B
     WHERE CUST_ACCOUNT_ID = p_cust_account_id
       AND N_EXT_ATTR4       = p_cust_prof_id
       AND N_EXT_ATTR1       = p_cust_prof_amt_id
       AND ATTR_GROUP_ID     = p_attr_group_id
      AND(
           ( ( p_start_date  BETWEEN d_ext_attr1 AND d_ext_attr2 ) or (p_end_date BETWEEN d_ext_attr1 AND d_ext_attr2) )   
                                                        or
         ( ( d_ext_attr1 between  p_start_date and p_end_date) or ( d_ext_attr2 between  p_start_date and p_end_date) )
         );
         return ln_tmp_clmt_cnt;
  EXCEPTION
   WHEN NO_DATA_FOUND
    THEN
     ln_tmp_clmt_cnt :=-1;
     return ln_tmp_clmt_cnt;
    WHEN OTHERS
    THEN
     ln_tmp_clmt_cnt :=-1;
     return ln_tmp_clmt_cnt;
  END get_active_crd_lmt_count;
  
-- +===================================================================+
-- | Name  : update stg table
-- | Description     : The update stg table sets the record status     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      :
-- +===================================================================+

  PROCEDURE update_stg_table(p_record_id      IN     xx_cdh_temp_credit_limit_stg.record_id%TYPE,
                             p_status         IN     xx_cdh_temp_credit_limit_stg.status%TYPE,
                             p_error_msg      IN     xx_cdh_temp_credit_limit_stg.error_message%TYPE,
                             x_return_status  OUT    VARCHAR2  
                             )

  AS
  BEGIN   
  x_return_status := null;
    UPDATE xx_cdh_temp_credit_limit_stg
             SET status        = p_status,
                 error_message = p_error_msg
           WHERE record_id     = p_record_id;

        log_debug_msg( SQL%ROWCOUNT ||' Row(s) updated in xx_cdh_temp_credit_limit_stg for record id  :'|| p_record_id);
 x_return_status := gc_success;
  EXCEPTION
    WHEN OTHERS
    THEN
      x_return_status := gc_failure;
      log_error('Error Updating Staging table xx_cdh_temp_credit_limit_stg '||substr(sqlerrm,1,100));
  END update_stg_table;
 -- +===================================================================+
-- | Name  : SET_CONTEXT                                               |
-- | Description     : This process sets context                       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      :  p_batch_id                                     |
-- +===================================================================+ 
PROCEDURE SET_CONTEXT
   AS 
     l_user_id                       NUMBER;
     l_responsibility_id             NUMBER;
     l_responsibility_appl_id        NUMBER;  
  
  -- set the user to ODCDH for bypassing VPD
   BEGIN
    SELECT user_id,
           responsibility_id,
           responsibility_application_id
      INTO l_user_id,                      
           l_responsibility_id,            
           l_responsibility_appl_id
      FROM fnd_user_resp_groups 
     WHERE user_id=(SELECT user_id 
                      FROM fnd_user 
                     WHERE user_name='ODCDH')
       AND responsibility_id=(SELECT responsibility_id 
                                FROM FND_RESPONSIBILITY 
                               WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
							   
    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );
					   
     log_debug_msg (' User Id:' || l_user_id);
     log_debug_msg (' Responsibility Id:' || l_responsibility_id);
     log_debug_msg (' Responsibility Application Id:' || l_responsibility_appl_id);

  EXCEPTION
    WHEN OTHERS THEN
    log_debug_msg ('Exception in initializing : ' || SQLERRM);
    
  END SET_CONTEXT;
-- +===================================================================+
-- | Name  : insert_cust_ext_table
-- | Description     : Inserts data into XX_CDH_CUST_ACCT_EXT_B        |
-- |                   table                                           |
-- |                                                                   |
-- | Parameters      :
-- +===================================================================+

  PROCEDURE insert_cust_ext_table(p_cust_account_id  IN  xx_cdh_cust_acct_ext_b.cust_account_id%TYPE,  
                                  p_attr_group_id    IN  xx_cdh_cust_acct_ext_b.attr_group_id%TYPE,
                                  p_c_ext_attr1      IN  xx_cdh_cust_acct_ext_b.c_ext_attr1%TYPE,
                                  p_c_ext_attr3      IN  xx_cdh_cust_acct_ext_b.c_ext_attr3%TYPE,
                                  p_cust_prof_amt_id IN  xx_cdh_cust_acct_ext_b.n_ext_attr1%TYPE,
                                  p_temp_crd_lmt     IN  xx_cdh_cust_acct_ext_b.n_ext_attr2%TYPE,
                                  p_cust_prof_id     IN  xx_cdh_cust_acct_ext_b.n_ext_attr4%TYPE,
                                  p_start_date       IN  xx_cdh_cust_acct_ext_b.d_ext_attr1%TYPE,
                                  p_end_date         IN  xx_cdh_cust_acct_ext_b.d_ext_attr2%TYPE,
                                  x_return_status    OUT VARCHAR2 ,
                                  x_error_message    OUT VARCHAR2
                                  )is
  BEGIN   
  x_return_status := null;
  SET_CONTEXT;
                  insert into XX_CDH_CUST_ACCT_EXT_B
                       ( EXTENSION_ID,
                         CUST_ACCOUNT_ID,
                         ATTR_GROUP_ID,
                         C_EXT_ATTR1,
                         C_EXT_ATTR3,
                         N_EXT_ATTR1,
                         N_EXT_ATTR2,
                         N_EXT_ATTR4,
                         D_EXT_ATTR1,
                         D_EXT_ATTR2,
                         CREATED_BY ,
                         CREATION_DATE,
                         LAST_UPDATED_BY,
                         LAST_UPDATE_DATE)
                values  (ego_extfwk_s.nextval,
                         p_cust_account_id,
                         p_attr_group_id,
                         p_c_ext_attr1,
                         'N',
                         p_cust_prof_amt_id,
                         p_temp_crd_lmt,
                         p_cust_prof_id,
                         p_start_date,
                         p_end_date,
                         fnd_global.user_id,
                         sysdate,
                         fnd_global.user_id,
                         sysdate
                         );
        x_return_status := gc_success;
  EXCEPTION
    WHEN OTHERS
    THEN
      x_return_status := gc_failure;
      x_error_message := 'Error Inserting Data into  XX_CDH_CUST_ACCT_EXT_B table :'||substr(sqlerrm,1,50);
      log_error('Error Inserting Data into  XX_CDH_CUST_ACCT_EXT_B table:'||substr(sqlerrm,1,50));
  END insert_cust_ext_table;
 -- +===================================================================+
-- | Name  : generate_report                                           |
-- | Description     : This process generates the report output        |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      :  p_batch_id                                     |
-- +===================================================================+ 
  PROCEDURE generate_report(p_batch_id       IN     xx_cdh_ebill_conts_upload_stg.batch_id%TYPE
                            )
  AS

  CURSOR cur_rep(p_batch_id  IN  xx_cdh_temp_credit_limit_stg.batch_id%TYPE,
                 p_status    IN  xx_cdh_temp_credit_limit_stg.status%TYPE)
  IS
      SELECT *
      FROM xx_cdh_temp_credit_limit_stg 
      WHERE batch_id   =  p_batch_id
        AND status     =  p_status;

  ln_header_rec          NUMBER := 1;
  lc_line                VARCHAR2(4000) := NULL;
  lc_header              VARCHAR2(4000) := NULL;
  lc_head_line           VARCHAR2(4000) := NULL;

  BEGIN


    log_debug_msg('Batch id : '|| p_batch_id);
    log_debug_msg(chr(10));

    FOR cur_rep_rec IN cur_rep(p_batch_id => p_batch_id , 
                              p_status    => 'C')
    LOOP
      BEGIN
      lc_line := NULL;

      IF ln_header_rec = 1
       THEN
        log_debug_msg('Processing successful records ..');
        fnd_file.put_line(fnd_file.output, '****************************************** REPORT FOR SUCCESSFUL RECORDS ***********************************************');
        fnd_file.put_line(fnd_file.output, chr(10));

        ln_header_rec := 2;

        lc_header := RPAD('CustomerNumber',  15, ' ')||chr(9)||
		                 RPAD('TempCreditLimit',  15, ' ')||chr(9)||
                     RPAD('StartDate',  15, ' ')||chr(9)||
                     RPAD('EndDate',  15, ' ')
                     ;


        fnd_file.put_line(fnd_file.output , lc_header);

        lc_head_line := RPAD('----------------',  15, '-')||chr(9)||
		                    RPAD('----------------',  15, '-')||chr(9)||
                        RPAD('--------------------------',  15, '-')||chr(9)||
                        RPAD('--------------------------',  15, '-')||chr(9)
                        ;

        fnd_file.put_line(fnd_file.output , lc_head_line);
      END IF;

      lc_line := RPAD(cur_rep_rec.customer_number,15, ' ')||chr(9)||
	               RPAD(cur_rep_rec.temp_credit_limit,15, ' ')||chr(9)||
                 RPAD(cur_rep_rec.start_date,15, ' ')||chr(9)||
                 RPAD(cur_rep_rec.end_date,15, ' ')
                 ;

       fnd_file.put_line(fnd_file.output, lc_line);

      EXCEPTION
        WHEN OTHERS
        THEN
         fnd_file.put_line(fnd_file.log, ' unable to write record id '|| cur_rep_rec.record_id ||' to report output '|| SQLERRM);
      END;
    END LOOP;

    ln_header_rec := 1;

    FOR cur_err_rec IN cur_rep(p_batch_id  =>  p_batch_id ,
                               p_status    =>  'E')
    LOOP
      BEGIN

      lc_line := NULL;

      IF ln_header_rec = 1
      THEN
      
        log_debug_msg('Processing Failed records ..');
        fnd_file.put_line(fnd_file.output, chr(10));
        fnd_file.put_line(fnd_file.output, chr(10));
        fnd_file.put_line(fnd_file.output, '********************************************* REPORT FOR FAILED RECORDS ********************************************');
        fnd_file.put_line(fnd_file.output, chr(10));

        lc_header := RPAD('CustomerNumber',  15, ' ')||chr(9)||
		                 RPAD('TempCreditLimit', 15, ' ')||chr(9)||
                     RPAD('StartDate',  15, ' ')||chr(9)||
                     RPAD('EndDate',  15, ' ')||chr(9)||
                     RPAD('Error Message',250,' ')||chr(9);

        fnd_file.put_line(fnd_file.output , lc_header);

        lc_head_line := RPAD('---------------',  15, '-')||chr(9)||
		                    RPAD('---------------',  15, '-')||chr(9)||
                        RPAD('----------------', 15, '-')||chr(9)||
                        RPAD('----------------', 15, '-')||chr(9)||
                        RPAD('--------------------------',  250, '-')
                        ;

        fnd_file.put_line(fnd_file.output , lc_head_line);
        ln_header_rec := 2;
      END IF;

      lc_line := RPAD(cur_err_rec.customer_number,15, ' ')||chr(9)||
	               RPAD(cur_err_rec.temp_credit_limit,15, ' ')||chr(9)||
                 RPAD(cur_err_rec.start_date,15, ' ')||chr(9)||
                 RPAD(cur_err_rec.end_date,15, ' ')||chr(9)||
                 RPAD(NVL(cur_err_rec.error_message,' '),250, ' ')||chr(9)
                 ;
       fnd_file.put_line(fnd_file.output, lc_line);

      EXCEPTION
        WHEN OTHERS
        THEN
         fnd_file.put_line(fnd_file.log, ' unable to write record id '|| cur_err_rec.record_id ||' to report output '|| SQLERRM);
      END;
    END LOOP;

  EXCEPTION
    WHEN OTHERS
    THEN
      log_debug_msg('Error generating report '||substr(SQLERRM,1,100));
  END generate_report;

-- +====================================================================+
-- | Name       :  update_profile_amount                                |
-- |                                                                    |
-- | Description: Procedure to update the original credit limit once the|
-- |              temp credit expires                                   |
-- | Parameters : p_run_date                                            |
-- |              p_debug_flag                                          |
-- |                                                                    |
-- +====================================================================+
PROCEDURE update_profile_amount ( x_errbuf                   OUT NOCOPY   VARCHAR2
                                 ,x_retcode                  OUT NOCOPY   NUMBER
                                 ,p_run_date                 IN           VARCHAR2
                                 ,p_debug_flag               IN           VARCHAR2
                                )
IS

  l_run_date                      DATE := NULL;
  
  lc_return_status                VARCHAR2(1);
  ln_msg_count                    NUMBER;
  lc_msg_data                     VARCHAR2(2000);
  
  ln_object_version_number        NUMBER;
  ln_customer_profile_rec_type    hz_customer_profile_v2pub.cust_profile_amt_rec_type;
      
  CURSOR c_crd_lmt_ed_recs	
  IS
  select ext.extension_id               e_extension_id,
         ext.cust_account_id            e_cust_account_id,
         ext.n_ext_attr1                e_cust_acct_profile_amt_id,
         ext.n_ext_attr2                e_temp_credit_limit,
         ext.n_ext_attr3                e_orig_credit_limit,
         ext.d_ext_attr1                e_start_date, 
         ext.d_ext_attr2                e_end_date,
         ext.c_ext_attr3                e_credit_limit_flag,
         hcpa.cust_acct_profile_amt_id  h_cust_acct_profile_amt_id,
         hcpa.overall_credit_limit      h_overall_credit_limit,
         hcpa.trx_credit_limit          h_trx_credit_limit,
         hcpa.object_version_number     h_object_version_number    
  from   HZ_CUST_PROFILE_AMTS hcpa
        ,XX_CDH_CUST_ACCT_EXT_B ext
        ,ego_attr_groups_v attr
  where 1 = 1
  and ext.n_ext_attr1 = hcpa.cust_acct_profile_amt_id
  and ext.attr_group_id = attr.ATTR_GROUP_ID
  and attr.attr_group_type = 'XX_CDH_CUST_ACCOUNT' 
  and attr.attr_group_name = 'TEMPORARY_CREDITLIMIT'
  and nvl(ext.c_ext_attr3,'N') <> 'Y'
  and nvl(ext.c_ext_attr4,'N') <> 'Y' 
  order by ext.cust_account_id,ext.d_ext_attr2
  ;
  
  CURSOR c_crd_lmt_sd_recs	
  IS
  select ext.extension_id               e_extension_id,
         ext.cust_account_id            e_cust_account_id,
         ext.n_ext_attr1                e_cust_acct_profile_amt_id,
         ext.n_ext_attr2                e_temp_credit_limit,
         ext.n_ext_attr3                e_orig_credit_limit,
         ext.d_ext_attr1                e_start_date, 
         ext.d_ext_attr2                e_end_date,
         ext.c_ext_attr3                e_credit_limit_flag,
         hcpa.cust_acct_profile_amt_id  h_cust_acct_profile_amt_id,
         hcpa.overall_credit_limit      h_overall_credit_limit,
         hcpa.trx_credit_limit          h_trx_credit_limit,
         hcpa.object_version_number     h_object_version_number    
  from   HZ_CUST_PROFILE_AMTS hcpa
        ,XX_CDH_CUST_ACCT_EXT_B ext
        ,ego_attr_groups_v attr
  where 1 = 1
  and ext.n_ext_attr1 = hcpa.cust_acct_profile_amt_id
  and ext.attr_group_id = attr.ATTR_GROUP_ID
  and attr.attr_group_type = 'XX_CDH_CUST_ACCOUNT' 
  and attr.attr_group_name = 'TEMPORARY_CREDITLIMIT'
  and nvl(ext.c_ext_attr3,'N') <> 'Y'
  and nvl(ext.c_ext_attr4,'N') <> 'Y' 
  order by ext.cust_account_id,ext.d_ext_attr1
  ;

BEGIN 
    
    g_proc := 'update_profile_amount';
    g_debug := p_debug_flag;
    
    log_debug_msg('Temp Credit Limit Update - Process Begins....');
    log_debug_msg('P_Run_Date :' || p_run_date);
    l_run_date := to_date(p_run_date,'DD-MON-RRRR HH24:MI:SS');
    
    FOR r_crd_lmt_rec IN c_crd_lmt_ed_recs 
    LOOP
     
     ln_customer_profile_rec_type := NULL; 
     ln_customer_profile_rec_type.cust_acct_profile_amt_id := r_crd_lmt_rec.h_cust_acct_profile_amt_id;
     
     --IF Conditions 
     IF ( r_crd_lmt_rec.e_end_date <= l_run_date )
     THEN
        log_debug_msg('     ');      
        log_debug_msg('Updating Credit Limit for cust_acct_id      :' || r_crd_lmt_rec.e_cust_account_id);      
        log_debug_msg('End Date for the Temp Credit Limit          :' || r_crd_lmt_rec.e_end_date);
        log_debug_msg('Before Credit Limit Update');
        log_debug_msg('Temp Credit Limit for customer              :' || r_crd_lmt_rec.e_temp_credit_limit);
        log_debug_msg('Temp Originial Credit Limit for customer    :' || r_crd_lmt_rec.e_orig_credit_limit);
        log_debug_msg('Originial Credit Limit for customer Profile :' || r_crd_lmt_rec.h_trx_credit_limit);     

        ln_customer_profile_rec_type.overall_credit_limit     := r_crd_lmt_rec.e_orig_credit_limit;
        ln_customer_profile_rec_type.trx_credit_limit         := r_crd_lmt_rec.e_orig_credit_limit;
        ln_customer_profile_rec_type.attribute1               := 'N';
   
        update_profile_amount_api(ln_customer_profile_rec_type,r_crd_lmt_rec.h_object_version_number);
      
        BEGIN
              Update XX_CDH_CUST_ACCT_EXT_B
                 SET c_ext_attr4      = 'Y',
                     last_update_date = sysdate
               WHERE extension_id     = r_crd_lmt_rec.e_extension_id
                 AND n_ext_attr1      = r_crd_lmt_rec.e_cust_acct_profile_amt_id
               ;
              COMMIT;
          
          EXCEPTION
            WHEN OTHERS 
            THEN
                log_error( 'EXCEPTION in WHEN OTHERS Update Statement For Current Credit Limit Update: ' || SQLERRM ||', Error Code :'||SQLCODE);
                x_retcode := 2;
        END;
 
        log_debug_msg('After Credit Limit Update');
        log_debug_msg('Temp Credit Limit for customer              :' || r_crd_lmt_rec.e_temp_credit_limit);
        log_debug_msg('Temp Originial Credit Limit for customer    :' || r_crd_lmt_rec.e_orig_credit_limit);
        log_debug_msg('Originial Credit Limit for customer Profile :' || r_crd_lmt_rec.e_orig_credit_limit);     
     END IF;
     
   END LOOP;   -- c_crd_lmt_ed_recs
  
   FOR r_crd_lmt_rec IN c_crd_lmt_sd_recs 
   LOOP

     ln_customer_profile_rec_type := NULL; 
     ln_customer_profile_rec_type.cust_acct_profile_amt_id := r_crd_lmt_rec.h_cust_acct_profile_amt_id;
        
     IF ( trunc(r_crd_lmt_rec.e_start_date) = trunc(to_date(l_run_date,'DD-MON-RRRR HH24:MI:SS')+1) AND r_crd_lmt_rec.e_orig_credit_limit IS NULL )
     THEN
         log_debug_msg('     ');      
         log_debug_msg('Updating Credit Limit for cust_acct_id      :' || r_crd_lmt_rec.e_cust_account_id);      
         log_debug_msg('Start Date for the Temp Credit Limit        :' || r_crd_lmt_rec.e_start_date);
         log_debug_msg('Before Credit Limit Update');
         log_debug_msg('Temp Credit Limit for customer              :' || r_crd_lmt_rec.e_temp_credit_limit);
         log_debug_msg('Temp Originial Credit Limit for customer    :' || r_crd_lmt_rec.e_orig_credit_limit);
         log_debug_msg('Originial Credit Limit for customer Profile :' || r_crd_lmt_rec.h_trx_credit_limit);

         BEGIN
              Update XX_CDH_CUST_ACCT_EXT_B
                 SET n_ext_attr3      = r_crd_lmt_rec.h_trx_credit_limit,
                     last_update_date = sysdate
               WHERE extension_id     = r_crd_lmt_rec.e_extension_id
                 AND n_ext_attr1      = r_crd_lmt_rec.e_cust_acct_profile_amt_id
              ;
              COMMIT;
              
         EXCEPTION
             WHEN OTHERS 
             THEN
                 log_error( 'EXCEPTION in WHEN OTHERS Update Statement For Future Credit Limit Update: ' || SQLERRM ||', Error Code :'||SQLCODE);
                 x_retcode := 2;
        END;
        
        --Initializing values to be updated to hz_cust_profile_amts table       
        ln_customer_profile_rec_type.overall_credit_limit     := r_crd_lmt_rec.e_temp_credit_limit;
        ln_customer_profile_rec_type.trx_credit_limit         := r_crd_lmt_rec.e_temp_credit_limit;
        ln_customer_profile_rec_type.attribute1               := 'Y';
        
        update_profile_amount_api(ln_customer_profile_rec_type,r_crd_lmt_rec.h_object_version_number);
   
        log_debug_msg('After Credit Limit Update');
        log_debug_msg('Temp Credit Limit for customer              :' || r_crd_lmt_rec.e_temp_credit_limit);
        log_debug_msg('Temp Originial Credit Limit for customer    :' || r_crd_lmt_rec.h_trx_credit_limit);
        log_debug_msg('Originial Credit Limit for customer Profile :' || r_crd_lmt_rec.e_temp_credit_limit);

     END IF;

   END LOOP;   -- c_crd_lmt_sd_recs
   
  log_debug_msg('     ');      
  log_debug_msg('END of update_profile_amount procedure...');
 
  EXCEPTION
       WHEN OTHERS 
       THEN
            log_error( 'EXCEPTION in WHEN OTHERS update_profile_amount : ' || SQLERRM ||', Error Code :'||SQLCODE);
            x_retcode := 2;
            
END update_profile_amount;

-- +====================================================================+
-- | Name       :  update_profile_amount_api                            |
-- |                                                                    |
-- | Description: Procedure to call the API to update the original      |
-- |              credit limit once the temp credit expires             |
-- | Parameters : p_cust_profile_amt_rec                                |
-- |              p_object_version_num                                  |
-- |                                                                    |
-- +====================================================================+
PROCEDURE update_profile_amount_api(  p_cust_profile_amt_rec  IN  hz_customer_profile_v2pub.cust_profile_amt_rec_type
                                     ,p_object_version_num    IN  NUMBER
)
IS

  lc_return_status         VARCHAR2 (1);
  ln_msg_count             NUMBER;
  lc_msg_data              VARCHAR2 (4000);
 
  ln_object_version_num    NUMBER;

BEGIN
      ln_object_version_num := p_object_version_num;
      
      log_debug_msg('Calling HZ_CUSTOMER_PROFILE_V2HUB API to update amount for cust_acct_id :' || p_cust_profile_amt_rec.cust_account_id );
      HZ_CUSTOMER_PROFILE_V2PUB.update_cust_profile_amt ( p_init_msg_list         => fnd_api.g_true ,
                                                          p_cust_profile_amt_rec  => p_cust_profile_amt_rec ,
                                                          p_object_version_number => ln_object_version_num ,
                                                          x_return_status         => lc_return_status ,
                                                          x_msg_count             => ln_msg_count ,
                                                          x_msg_data              => lc_msg_data    
                                                        );

        IF lc_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS 
        THEN
            log_debug_msg('API successfully updated credit limit');
            COMMIT;
        ELSE          
            IF ln_MSG_COUNT > 0 
            THEN
                log_error('API returned Error while trying to update the credit limit');
                FOR counter IN 1..ln_MSG_COUNT
                LOOP
                    log_error('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_TRUE));
                END LOOP;
            FND_MSG_PUB.Delete_Msg;
            END IF;
        END IF;
      log_debug_msg('END of Call to update amount...');
 
 EXCEPTION
       WHEN OTHERS 
       THEN
            log_error( 'EXCEPTION in WHEN OTHERS in update_profile_amount_api: ' || SQLERRM);
            
END update_profile_amount_api;

-- +====================================================================+
-- | Name       :  update_profile_amount                                |
-- |                                                                    |
-- | Description: Procedure to update customer profile credit limit amt |
-- |              from Temp Credit Limit OAF page                       |
-- | Parameters : p_prof_amt_id                                         |
-- |              p_cr_limit                                            |
-- |              p_orig_cr_limit                                       |
-- |              p_dml_typ                                             |
-- +====================================================================+
procedure update_profile_amount (    x_errmsg        OUT NOCOPY      VARCHAR2,
                                     x_retcode       OUT NOCOPY      NUMBER,
                                     p_prof_amt_id   IN              hz_cust_profile_amts.cust_acct_profile_amt_id%TYPE,
                                     p_cr_limit      IN              hz_cust_profile_amts.overall_credit_limit%TYPE,
                                     p_orig_cr_limit OUT NOCOPY      hz_cust_profile_amts.cust_acct_profile_amt_id%TYPE,
                                     p_dml_typ       IN              VARCHAR2
                                ) is 
  lc_return_status         VARCHAR2 (1);
  ln_msg_count             NUMBER;
  lc_msg_data              VARCHAR2 (2000);
  ln_object_version_number NUMBER;
  lc_procedure             VARCHAR2 (50) := 'update_profile_amount';
  lr_amt_rec               hz_customer_profile_v2pub.cust_profile_amt_rec_type;
  ln_overall_credit_limit  NUMBER;
  l_user_id                NUMBER;
  l_responsibility_id      NUMBER;
  l_responsibility_appl_id NUMBER;
BEGIN
   log_debug_msg(lc_procedure ||'- Begin');
  -- Initializing OUT NOCOPY Variables
  x_retcode := 0;
  x_errmsg  := NULL;
  -----------------------------
  -- Get Object Version Number
  -----------------------------
  BEGIN
    ln_object_version_number := NULL;
    
       SELECT object_version_number,
              overall_credit_limit
         INTO ln_object_version_number,
              ln_overall_credit_limit
         FROM hz_cust_profile_amts
        WHERE cust_acct_profile_amt_id = p_prof_amt_id;
  EXCEPTION
  WHEN OTHERS THEN
    x_retcode := '2';
    x_errmsg  := 'Error while fetching object_version_number for cust_prof_amt_id - ' || p_prof_amt_id;
    log_error(x_errmsg);
  END;

  IF x_retcode = 0 THEN
    BEGIN
      lr_amt_rec                          := NULL;
      lr_amt_rec.cust_acct_profile_amt_id := p_prof_amt_id;
      lr_amt_rec.overall_credit_limit     := p_cr_limit;
      lr_amt_rec.trx_credit_limit         := p_cr_limit;
      
      if (p_dml_typ ='INSERT')
         then 
            lr_amt_rec.attribute1         := 'Y';
        elsif(p_dml_typ ='UPDATE')
         then
            lr_amt_rec.attribute1         := 'N';
      end if;
      
      hz_customer_profile_v2pub.update_cust_profile_amt ( p_init_msg_list        => fnd_api.g_true 
                                                        , p_cust_profile_amt_rec => lr_amt_rec 
                                                        , p_object_version_number=> ln_object_version_number 
                                                        , x_return_status        => lc_return_status 
                                                        , x_msg_count            => ln_msg_count 
                                                        , x_msg_data             => lc_msg_data );
     
     IF lc_return_status = fnd_api.g_ret_sts_success 
      THEN 
       x_retcode       := 0;
       p_orig_cr_limit := ln_overall_credit_limit;
       log_debug_msg('Successfully updated credit limit for cust_profile_amt_id :' ||lr_amt_rec.cust_acct_profile_amt_id);
      ELSE
        lc_msg_data       := NULL;
        IF (ln_msg_count   > 0) THEN
          log_error('Error in API while trying to update the credit limit for cust_profile_amt_id :' ||lr_amt_rec.cust_acct_profile_amt_id);
          FOR counter IN 1 .. ln_msg_count
          LOOP
            lc_msg_data := lc_msg_data || ' ' || fnd_msg_pub.get (counter, fnd_api.g_false);
          END LOOP;
        END IF;
        fnd_msg_pub.delete_msg;
        x_errmsg  := 'Error while updating creditlimit : ' || lc_msg_data;
        x_retcode := '2';
      END IF;

    EXCEPTION
    WHEN OTHERS THEN
      x_retcode := '2';
      x_errmsg  := 'Error while updating credit : ' || substr(SQLERRM,1,100);
    END;
  END IF;
  log_debug_msg(lc_procedure ||'- End');

 EXCEPTION
    WHEN OTHERS THEN
      x_retcode := '2';
      x_errmsg  := 'Error while updating credit : ' || substr(SQLERRM,1,100);
    
END update_profile_amount;

-- +====================================================================+
-- | Name       : format_date                                           |
-- |                                                                    |
-- | Description: Procedure to format DATE input parameter              |
-- |                                                                    |
-- | Parameters : p_dml_typ                                             |
-- |              p_in_date                                             |
-- |              p_out_date                                            |
-- +====================================================================+
procedure format_date (p_dml_typ    IN  VARCHAR2,
                       p_in_date    IN  VARCHAR2,
                       p_out_date   OUT TIMESTAMP,
                       x_errmsg     OUT NOCOPY  VARCHAR2,
                       x_retcode    OUT NOCOPY NUMBER
                      ) is 
BEGIN
    log_debug_msg('format_date- Begin');
    x_retcode := 0;
    x_errmsg  := NULL;
    p_out_date :=to_date((trunc(CAST(to_timestamp(p_in_date,'yyyy-mm-dd hh24:mi:ss.ff9') AS DATE))||' 23:59:59'),'DD-MON-YYYY HH24:MI:SS');
    x_retcode := 0;
    log_debug_msg('format_date- End');
    Exception 
    when others then 
    x_retcode := '2';
    x_errmsg  := 'Error Converting Date while '|| p_dml_typ||': ' || substr(SQLERRM,1,100);
    log_error(x_errmsg);
End format_date;
  -- +===================================================================+
  -- | Name  : fetch_data                                                |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_CDH_TEMP_CREDIT_LIMIT_STG          |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+ 
PROCEDURE fetch_data(p_customer_number        VARCHAR2,
                   p_temp_credit_limit      VARCHAR2,
                   p_start_date             DATE,
                   p_end_date               DATE,
                   p_currency               VARCHAR2)
                   is
  lc_err_msg varchar2(2000);
  BEGIN
  
       insert into XX_CDH_TEMP_CREDIT_LIMIT_STG(BATCH_ID,
                                               RECORD_ID,
                                               CUSTOMER_NUMBER,                          
                                               TEMP_CREDIT_LIMIT,
                                               START_DATE,
                                               END_DATE,
                                               CURRENCY,
                                               STATUS,
                                               CREATION_DATE,
                                               CREATED_BY,
                                               LAST_UPDATE_DATE,
                                               LAST_UPDATED_BY
                                               )
                                       values (fnd_global.session_id,
                                               xx_cdh_tmp_crd_lmt_stg_rec_s.nextval,
                                               p_customer_number,
                                               p_temp_credit_limit,
                                               p_start_date,
                                               to_date(trunc(p_end_date)||' 23:59:59','DD-MON-YYYY HH24:MI:SS'),
                                               p_currency,
                                               'N',
                                               sysdate,
                                               fnd_global.user_id,
                                               sysdate,
                                               fnd_global.user_id
                                               );
                                        commit;
                 exception when others then                       
                    lc_err_msg := SQLERRM;
                    Raise_Application_Error (-20343, 'Error inserting the data..'||SQLERRM);
END fetch_data ;
  -- +===================================================================+
  -- | Name  : extract
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records insert into XX_CDH_CUST_ACCT_EXT_B      |
  -- |                                                                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+                     
PROCEDURE extract(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER) is

CURSOR cur_extract(p_batch_id  IN xx_cdh_temp_credit_limit_stg.batch_id%TYPE,
                   p_status    IN xx_cdh_temp_credit_limit_stg.status%TYPE
                      ) is 
SELECT *
  FROM xx_cdh_temp_credit_limit_stg
  WHERE 1 =1
    AND status   = NVL(p_status,status)
    AND batch_id = NVL(p_batch_id,batch_id)
    ORDER BY record_id ;
   --------------------------------
   -- Local Variable Declaration --
   -------------------------------- 
  ln_attr_group_id      NUMBER :=0;
  lc_err_flag           VARCHAR2(1);
  lc_err_message        VARCHAR2(4000):=null;
  ln_batch_id           NUMBER;
  ln_user_id            fnd_user.user_id%TYPE;
  lc_user_name          fnd_user.user_name%TYPE;
  lc_debug_flag         VARCHAR2(1) := NULL;
  ln_customer_id        NUMBER;
  ln_cust_profile_id    NUMBER;
  ln_cust_prof_amt_id   NUMBER;
  ln_extn_id            NUMBER;
  lc_err_rec_exists     VARCHAR2(5):='N';
  lc_upd_err_msg        VARCHAR2(2000);
  ln_orig_crd_lmt       NUMBER;
  lc_return_status      VARCHAR2(20);
  lc_upd_ret_status     VARCHAR2(20);
  lc_ins_ret_status     VARCHAR2(20);
  ln_tmp_cr_lnt_count   number :=0;
  lc_cust_error_message VARCHAR2(2000);
  lc_ins_error_message  VARCHAR2(2000);

BEGIN 
    fnd_file.put_line(fnd_file.log,'Temp Credit Limit extract - Process Begins....');
    
      x_retcode :=0;
    -- Get the Debug flag
    BEGIN     
     SELECT xftv.source_value1
       INTO lc_debug_flag
       FROM xx_fin_translatedefinition xft,
            xx_fin_translatevalues xftv
      WHERE xft.translate_id    = xftv.translate_id
        AND xft.enabled_flag      = 'Y'
        AND xftv.enabled_flag     = 'Y'
        AND xft.translation_name  = 'XXOD_CDH_TMP_CRD_LMT_UPL';

    EXCEPTION
      WHEN OTHERS
      THEN
        lc_debug_flag := 'N';
    END;
    
    log_debug_msg ('Debug Flag :'||lc_debug_flag);

    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF; 
    
    ln_user_id := fnd_global.user_id;
    log_debug_msg('Getting the user name ..');
    
    SELECT user_name
    INTO lc_user_name
    FROM fnd_user
    WHERE user_id = ln_user_id;

    log_debug_msg('User Name :'|| lc_user_name);

    fnd_file.put_line(fnd_file.log ,'Purge all the successful records from staging table for USER :'||lc_user_name);
    
    DELETE FROM xx_cdh_temp_credit_limit_stg
    WHERE status = 'C'
    AND Created_by = ln_user_id;

    fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Record(s) deleted from staging table');

    COMMIT;
    
     fnd_file.put_line(fnd_file.log, 'Removing Duplicate records from staging table ..');

    DELETE FROM xx_cdh_temp_credit_limit_stg a
    WHERE EXISTS ( SELECT 1
                   FROM xx_cdh_temp_credit_limit_stg b
                   WHERE  1=1
                     AND  customer_number =a.customer_number
                     AND  start_date = a.start_date   
                     AND  end_date   = a.end_date 
                     AND  currency   = a.currency
                     AND status = a.status
                     AND ROWID < A.ROWID );

    IF SQL%ROWCOUNT > 0
    THEN
      fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Duplicate Records deleted from staging table');
    END IF;
	
	COMMIT;

    log_debug_msg('Getting the next batch id .............');

    SELECT xx_cdh_tmp_crdlmt_stg_batch_s.nextval                                      --create sequence
    INTO ln_batch_id
    FROM dual;

    fnd_file.put_line(fnd_file.log, 'Batch id      :'||  ln_batch_id);
    fnd_file.put_line(fnd_file.log, 'session_id    :'||  fnd_global.session_id);
    fnd_file.put_line(fnd_file.log, 'User id       :'||  ln_user_id);

    fnd_file.put_line(fnd_file.log, 'Update the batch id in stg table for User id :'|| ln_user_id);

    UPDATE xx_cdh_temp_credit_limit_stg
       SET batch_id   = ln_batch_id
     WHERE created_by = ln_user_id
       AND status     = 'N';

    fnd_file.put_line(fnd_file.log ,SQL%ROWCOUNT||'  records Updated for user : '|| ln_user_id || ' with batch id :'|| ln_batch_id );

    COMMIT;
    
    BEGIN 
        SELECT grp.ATTR_GROUP_ID 
          INTO ln_attr_group_id
          FROM EGO_ATTR_GROUPS_V grp 
         WHERE grp.APPLICATION_ID = 222 
           AND grp.ATTR_GROUP_NAME = 'TEMPORARY_CREDITLIMIT' 
           AND grp.ATTR_GROUP_TYPE = 'XX_CDH_CUST_ACCOUNT';
     EXCEPTION
      WHEN OTHERS
       THEN
         fnd_file.put_line(fnd_file.log,'Error deriving Attribute Group:'||substr(sqlerrm,1,50));
         x_retcode:=2;
    END;
    
    log_debug_msg ('ATTR_GROUP_ID :'||ln_attr_group_id);
 
  for rec in cur_extract(p_batch_id => ln_batch_id,
                          p_status   => 'N') 
    loop
    ln_customer_id        := null;
    ln_cust_profile_id    := null;
    ln_cust_prof_amt_id   := null;
    lc_return_status      := null;
    lc_cust_error_message := null;
    lc_ins_error_message  := null;
    ln_tmp_cr_lnt_count   := 0;
    lc_err_message        := null;
    lc_upd_err_msg        := null;
    ln_orig_crd_lmt       := null;
    ln_extn_id            := null;
    lc_upd_ret_status     := null;
    lc_ins_ret_status     := null;
    lc_err_flag           :='N';
    -----
    --Extracting Customer information
    -----   
    get_cust_details(p_customer_number  => rec.customer_number,
                     p_currency         => rec.currency ,
                     x_cust_accnt_id    => ln_customer_id,
                     x_cust_prof_id     => ln_cust_profile_id,
                     x_cust_prof_amt_id => ln_cust_prof_amt_id,
                     x_return_status    => lc_return_status,
                     x_error_msg        => lc_cust_error_message  
                              ) ;
      IF lc_return_status != gc_success
              THEN
                lc_err_flag:='Y';
                lc_err_message := SUBSTR(lc_cust_error_message,1,4000);
                log_error(lc_err_message);
      END IF;

      log_debug_msg ('Cust_account_id :'||ln_customer_id);
      log_debug_msg ('Cust_profile_id :'||ln_cust_profile_id);
      log_debug_msg ('Cust_prf_amt_id :'||ln_cust_prof_amt_id);
      
    -----
    --StartDate validation
    -----
    if (rec.start_date <= sysdate)
    then
         lc_err_flag:='Y';
         lc_err_message :=  SUBSTR(lc_err_message||'-'||'StartDate should be greater than todays date ',1,4000);
         
    end if;
    
    if (rec.start_date > rec.end_date)
    then
         lc_err_flag:='Y';
         lc_err_message :=  SUBSTR(lc_err_message||'-'||'EndDate cannot be earlier than StartDate ',1,4000);
    end if;
    -----
    --EndDate validation
    -----
    if (rec.end_date < sysdate)
    then
         lc_err_flag:='Y';
         lc_err_message :=  SUBSTR(lc_err_message||'-'||'EndDate cannot be earlier than todays date  ',1,4000);
    end if;
    -----
    --Active Credit limit validation
    -----   
     
     ln_tmp_cr_lnt_count:=   get_active_crd_lmt_count(ln_customer_id,
                                   ln_cust_profile_id
                                   ,ln_cust_prof_amt_id
                                   ,ln_attr_group_id
                                   ,rec.start_date
                                   ,rec.end_date);
        log_debug_msg ('Temporary Credit Limit Count :'||ln_tmp_cr_lnt_count);
      
     if (ln_tmp_cr_lnt_count > 0)
      then
         lc_err_flag:='Y';
         lc_err_message :=  SUBSTR(lc_err_message||'-'||'Active Credit limit Exists for the given date range  ',1,4000);
     elsif (ln_tmp_cr_lnt_count < 0)
       then
         lc_err_flag:='Y';
         lc_err_message :=  SUBSTR(lc_err_message||'-'||'Error deriving active credit limit for the given date range  ',1,4000);
     end if;
     
      -----------------
      -- Insert into XX_CDH_CUST_ACCT_EXT_B
      -----------------
           
      if (nvl(lc_err_flag,'N') ='N')
        then
          insert_cust_ext_table  (p_cust_account_id   => ln_customer_id   ,  
                                  p_attr_group_id     => ln_attr_group_id ,
                                  p_c_ext_attr1       => ln_cust_prof_amt_id,
                                  p_c_ext_attr3       => 'N',
                                  p_cust_prof_amt_id  => ln_cust_prof_amt_id,
                                  p_temp_crd_lmt      => rec.temp_credit_limit,
                                  p_cust_prof_id      => ln_cust_profile_id,
                                  p_start_date        => rec.start_date,
                                  p_end_date          => rec.end_date ,
                                  x_return_status     => lc_ins_ret_status ,
                                  x_error_message     => lc_ins_error_message
                                  );
                         
            if lc_ins_ret_status != gc_success
            then
              lc_err_flag:='Y';
              lc_err_message :=  SUBSTR(lc_err_message||'-'||lc_ins_error_message,1,4000);
            end if;
    end if;    
    
    if (nvl(lc_err_flag,'N') ='N')
      then
            log_debug_msg ('Updating staging Table for Success ');
            update_stg_table( p_record_id  => rec.record_id,
                             p_status        => 'C',
                             p_error_msg     => null,
                             x_return_status => lc_upd_ret_status);
    else 
           log_debug_msg ('Updating staging Table for Error ');
           lc_err_rec_exists     :='Y';
           update_stg_table( p_record_id  => rec.record_id,
                             p_status        => 'E',
                             p_error_msg     => lc_err_message,
                             x_return_status => lc_upd_ret_status);
                             
      end if;
    commit;
    end loop;
  
    generate_report(ln_batch_id);
    if(lc_err_rec_exists ='Y')
     then
      log_debug_msg ('Error uploading Temp Credit Limit : '||lc_err_message);
      fnd_file.put_line(fnd_file.log,'Temp Credit Limit extract - Process Ended in Error....');
      x_retcode := 2;
    end if;
    fnd_file.put_line(fnd_file.log,'Temp Credit Limit extract - Process Ends....');
EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Temp Credit Limit extract - Process Ended in Error....'||SQLERRM);
      x_retcode := 2;
    
END extract;
                                
END XX_CDH_TMP_CRD_LMT_PKG;
/
SHOW ERR