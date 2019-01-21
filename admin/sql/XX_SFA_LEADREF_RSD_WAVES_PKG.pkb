-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                     Wipro Technologies                                |
-- +=======================================================================+
-- | Name             :XX_SFA_LEADREF_RSD_WAVES_PKG.pks                    |
-- | Description      :I2043 RSD Waves, to validate the data for the RSD   |
-- |                   Waves that were converted from SOLAR.               |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      28-Apr-2008 Sreekanth          Intial Version                 |
-- |1.1      21-MAY-2008 Rizwan Appees      Reformatting LOG file.         |
-- |1.2      22-Aug-2008 Rizwan Appees      Fixed defect 10026.            |
-- +=======================================================================+

CREATE OR REPLACE PACKAGE BODY XX_SFA_LEADREF_RSD_WAVES_PKG
AS
  -- +===================================================================+
  -- | Name             : VALIDATE_DATA_FOR_RSD_WAVES                    |                                                                                     
  -- | Description      : Procedure to validate the data for the RSD     |                                                                       
  -- |                    Waves that were converted from SOLAR           |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- +===================================================================+
  
  PROCEDURE validate_data_for_rsd_waves
       (x_errbuf    OUT NOCOPY VARCHAR2
        ,x_retcode  OUT NOCOPY NUMBER)
  IS
  ---------------------------
  --Declaring local variables
  ---------------------------
    ln_api_version          NUMBER := 1.0;
    l_counter               NUMBER;
    ln_salesforce_id        NUMBER;
    ln_sales_group_id       NUMBER;
    lc_set_message          VARCHAR2(2000);
    l_squal_char06          VARCHAR2(4000);
    l_squal_char07          VARCHAR2(4000);
    l_squal_char59          VARCHAR2(4000);
    l_squal_char60          VARCHAR2(4000);
    l_squal_num60           VARCHAR2(4000);
    ln_cnt_res_converted    NUMBER := 0;
    lc_return_status        VARCHAR2(10);
    ln_msg_count            NUMBER;
    lc_msg_data             VARCHAR2(4000);
    ln_asignee_role_id      NUMBER;
    ln_admin_count          NUMBER;
    lc_assignee_admin_flag  VARCHAR2(2);
    lc_role                 VARCHAR2(40);--:='OD_NA_SA_AM1_ROL';
    ln_count                NUMBER;
    lc_manager_flag         VARCHAR2(2);
    lc_message_code         VARCHAR2(1000);
    lc_legacy_rep_id        VARCHAR2(100);
    lc_fnd_message          VARCHAR2(4000);
    lc_group_name           VARCHAR2(100);
    lc_resource_name        VARCHAR2(240);
    lc_division             VARCHAR2(240);
        lc_bsd_flag             VARCHAR2(1);

    ----------------------------------
    --Declaring Record Type Variables
    ----------------------------------
    lp_gen_bulk_rec         xx_tm_get_winners_on_quals.lrec_trans_rec_type;
    lx_gen_return_rec       jtf_terr_assign_pub.bulk_winners_rec_type;
    lc_application_name     xx_com_error_log.application_name%TYPE := 'XXCRM';
    lc_program_type         xx_com_error_log.program_type%TYPE := 'I2043_Lead_Referral';
    lc_program_name         xx_com_error_log.program_name%TYPE := 'XX_SFA_LEAD_REFERRAL_PKG';
    lc_module_name          xx_com_error_log.module_name%TYPE := 'SFA';
    lc_error_location       xx_com_error_log.error_location%TYPE := 'VALIDATE_RSD_WAVES';
    lc_token                VARCHAR2(4000);
    lc_error_message_code   VARCHAR2(100);
    lc_err_desc             xx_com_error_log.error_message%TYPE DEFAULT ' ';
    ex_create_err           EXCEPTION;
        ex_next_rec             EXCEPTION;
    CURSOR lcu_lead_ref IS 
      SELECT internid
             ,addr1
             ,country
             ,zip
             ,num_wc_emp_od
             ,NAME
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status IN ('VALIDATED'
                                    ,'GETWIN_ERROR');
    CURSOR lcu_admin(p_resource_id NUMBER
                      ,p_group_id NUMBER DEFAULT NULL) IS 
      SELECT COUNT(rol.admin_flag)
      FROM   jtf_rs_role_relations jrr
             ,jtf_rs_group_members mem
             ,jtf_rs_group_usages jru
             ,jtf_rs_roles_b rol
      WHERE  mem.resource_id = p_resource_id
             AND NVL(mem.delete_flag,'N') <> 'Y'
             AND mem.group_id = NVL(p_group_id,mem.group_id)
             AND jru.group_id = mem.group_id
             AND jru.USAGE = 'SALES'
             AND jrr.role_resource_id = mem.group_member_id
             AND jrr.role_resource_type = 'RS_GROUP_MEMBER'
             AND TRUNC(SYSDATE) BETWEEN TRUNC(jrr.start_date_active)
                                        AND NVL(TRUNC(jrr.end_date_active),TRUNC(SYSDATE))
             AND NVL(jrr.delete_flag,'N') <> 'Y'
             AND rol.role_id = jrr.role_id
             AND rol.role_type_code = 'SALES'
             AND rol.admin_flag = 'Y'
             AND rol.active_flag = 'Y';
      
  BEGIN
  -------------------------------------------------------------------------
  --             Process the lead referral data                          --
  -------------------------------------------------------------------------
  
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,'Submitting OD: SFA Lead Referral RSD Wave Validation');
    
    fnd_file.put_line(fnd_file.LOG,'----------------------------------------------------');
    
    FOR i IN lcu_lead_ref LOOP
      ln_cnt_res_converted := 0;
      -- Extend Qualifier Elements
      
      lp_gen_bulk_rec.squal_char06.EXTEND;
      
      lp_gen_bulk_rec.squal_char07.EXTEND;
      
      lp_gen_bulk_rec.squal_char59.EXTEND;
      
      lp_gen_bulk_rec.squal_char60.EXTEND;
      
      lp_gen_bulk_rec.squal_num60.EXTEND;
      
      lp_gen_bulk_rec.squal_char06(1) := i.zip;
      
      lp_gen_bulk_rec.squal_char07(1) := i.country;
      
      lp_gen_bulk_rec.squal_char59(1) := 'NONE';    --SIC Code(Site Level)   --Optional
      
      lp_gen_bulk_rec.squal_char60(1) := 'PROSPECT';
      
      lp_gen_bulk_rec.squal_num60(1) := i.num_wc_emp_od;
      -------------------------------------------------------------------------
      -- Call to XX_TM_GET_WINNERS_ON_QUALS.get_winners with the party_site_id
      -------------------------------------------------------------------------
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'Calling Get Winner API for, LEAD: '
                                     ||i.NAME
                                     ||' ZIP:'
                                     ||i.zip
                                     ||' COUNTRY:'
                                     ||i.country
                                     ||' TYPE:PROSPECT'
                                     ||' ODWCW:'
                                     ||i.num_wc_emp_od);
      
      xx_tm_get_winners_on_quals.get_winners(p_api_version_number => ln_api_version,p_init_msg_list => fnd_api.g_false,
                                             p_use_type => 'LOOKUP',p_source_id => - 1001,
                                             p_trans_id => - 1002,p_trans_rec => lp_gen_bulk_rec,
                                             p_resource_type => fnd_api.g_miss_char,p_role => fnd_api.g_miss_char,
                                             p_top_level_terr_id => fnd_api.g_miss_num,
                                             p_num_winners => fnd_api.g_miss_num,x_return_status => lc_return_status,
                                             x_msg_count => ln_msg_count,x_msg_data => lc_msg_data,
                                             x_winners_rec => lx_gen_return_rec);
      
      IF lc_return_status <> fnd_api.g_ret_sts_success THEN
        fnd_file.put_line(fnd_file.LOG,'Error while calling get_winners for PARTY: '
                                       ||i.NAME
                                       ||' ZIP:'
                                       ||i.zip
                                       ||' COUNTRY:'
                                       ||i.country
                                       ||' TYPE:PROSPECT'
                                       ||' ODWCW:'
                                       ||i.num_wc_emp_od);
        
        FOR k IN 1.. ln_msg_count LOOP
          lc_msg_data := fnd_msg_pub.get(p_encoded => fnd_api.g_false,p_msg_index => k);
          
          fnd_file.put_line(fnd_file.LOG,SQLERRM);
        END LOOP;
        -------------------------------------------------------------------------
        --                 Update Status in XX_SFA_LEAD_REFERRALS              --
        -------------------------------------------------------------------------
        
        lc_err_desc := 'Error while calling get_winners for interid:'
                       ||i.internid
                       ||' '
                       ||lc_msg_data;
        
        fnd_message.set_name('XXCRM','XX_SFA_094_LR_WAVE_GET_WIN_ERR');
        
        fnd_message.set_token('INTERNID',lc_err_desc);
        
        xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                           p_program_type => lc_program_type,p_program_name => lc_program_name,
                                           p_module_name => lc_module_name,p_error_location => lc_error_location,
                                           p_error_message_code => 'XX_SFA_092_LR_BATCHID_ERR',
                                           p_error_message => substr(lc_err_desc,1,4000),
                                           p_error_message_severity => 'MAJOR');
        

        UPDATE xxcrm.xx_sfa_lead_referrals
        SET    process_status = 'GETWIN_ERROR',
               error_message =  substr(lc_err_desc,1,4000) 
        WHERE  internid = i.internid;

        x_retcode := 1;
      ELSE
      -- For each resource returned from JTF_TERR_ASSIGN_PUB.get_winners
      
        l_counter := lx_gen_return_rec.resource_id.FIRST;
        
        IF nvl(l_counter,0) = 0 THEN
          ln_cnt_res_converted := 0;
          
          fnd_file.put_line(fnd_file.LOG,'Get Winner API could not get resource for PARTY: '
                                         ||i.NAME
                                         ||' ZIP:'
                                         ||i.zip
                                         ||' COUNTRY:'
                                         ||i.country
                                         ||' TYPE:PROSPECT'
                                         ||' ODWCW:'
                                         ||i.num_wc_emp_od);
          
          UPDATE xxcrm.xx_sfa_lead_referrals
          SET    process_status = 'GETWIN_ERROR' --Aug22,
          WHERE  internid = i.internid;
        
        ELSE

          fnd_file.put_line(fnd_file.LOG,'');
          
                  lc_bsd_flag := 'N';
                  
          WHILE (l_counter <= lx_gen_return_rec.terr_id.LAST) LOOP
            BEGIN
              -- Initialize the variables
              ln_salesforce_id := NULL;
              ln_sales_group_id := NULL;
              ln_asignee_role_id := NULL;
              lc_err_desc := NULL;
              lc_set_message := NULL;
              lc_role := NULL;
              ln_count := 0;
              lc_manager_flag := NULL;
                          

     
              fnd_file.put_line(fnd_file.LOG,l_counter||'. RESOURCE_ID:'||lx_gen_return_rec.resource_id(l_counter)
                                             ||' GROUP_ID:'||lx_gen_return_rec.group_id(l_counter)
                                             ||' ROLE:'||lx_gen_return_rec.role(l_counter));

              -- Fetch the assignee resource_id, sales_group_id and full_access_flag
              ln_salesforce_id := lx_gen_return_rec.resource_id(l_counter);
              ln_sales_group_id := lx_gen_return_rec.group_id(l_counter);
              lc_role := lx_gen_return_rec.ROLE(l_counter);
              
              OPEN lcu_admin(p_resource_id => ln_salesforce_id
                            ,p_group_id => ln_sales_group_id);
              
              FETCH lcu_admin INTO ln_admin_count;
              
              CLOSE lcu_admin;
              

              IF ln_admin_count = 0 THEN
                lc_assignee_admin_flag := 'N';
                fnd_file.put_line(fnd_file.LOG, 'Is Admin? :'|| lc_assignee_admin_flag);
              ELSIF ln_admin_count = 1 THEN
                lc_assignee_admin_flag := 'Y';
                fnd_file.put_line(fnd_file.LOG, 'Is Admin? :'|| lc_assignee_admin_flag);
              ELSE
                fnd_file.put_line(fnd_file.LOG, 'Is Admin? :'|| ln_admin_count);

              -- The resource has more than one admin role
              
                fnd_message.set_name('XXCRM','XX_TM_0243_ADM_MORE_THAN_ONE');
               
                fnd_message.set_token('P_RESOURCE_ID',ln_salesforce_id);
                
                lc_err_desc := fnd_message.get;
                
                fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                
                xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                   p_application_name => lc_application_name,
                                                   p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                   p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                   p_error_message_code => 'XX_TM_0243_ADM_MORE_THAN_ONE',
                                                   p_error_message => substr(lc_err_desc,1,4000),
                                                   p_error_message_severity => 'MINOR');
                
                RAISE ex_create_err;
              END IF; -- ln_admin_count = 0 
              
              IF (ln_sales_group_id IS NULL ) THEN
                IF lc_assignee_admin_flag = 'Y' THEN
                  fnd_message.set_name('XXCRM','XX_TM_0244_ADM_GRP_MANDATORY');
                  
                  fnd_message.set_token('P_RESOURCE_ID',ln_salesforce_id);
                  
                  lc_err_desc := fnd_message.get;
                  
                  fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                  
                  xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                     p_application_name => lc_application_name,
                                                     p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                     p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                     p_error_message_code => 'XX_TM_0244_ADM_GRP_MANDATORY',
                                                     p_error_message => substr(lc_err_desc,1,4000),
                                                     p_error_message_severity => 'MINOR');
                  
                  RAISE ex_create_err;
                END IF; -- lc_assignee_admin_flag = 'Y'
              END IF; -- ln_sales_group_id IS NULL
              -- Deriving the role_id and group_id of the resource if lc_role IS NULL
              
              IF (lc_role IS NULL ) THEN
                IF lc_assignee_admin_flag = 'Y' THEN
                  fnd_message.set_name('XXCRM','XX_TM_0245_ADM_ROLE_MANDATORY');
                  
                  fnd_message.set_token('P_RESOURCE_ID',ln_salesforce_id);
                  
                  lc_err_desc := fnd_message.get;
                  
                  fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                  
                  xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                     p_application_name => lc_application_name,
                                                     p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                     p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                     p_error_message_code => 'XX_TM_0245_ADM_ROLE_MANDATORY',
                                                     p_error_message => substr(lc_err_desc,1,4000),
                                                     p_error_message_severity => 'MINOR');
                  
                  RAISE ex_create_err;
                END IF; -- lc_assignee_admin_flag = 'Y'
                -- Check whether the resource is a manager
                
                SELECT COUNT(rol.manager_flag)
                INTO   ln_count
                FROM   jtf_rs_role_relations jrr
                       ,jtf_rs_group_members mem
                       ,jtf_rs_group_usages jru
                       ,jtf_rs_roles_b rol
                WHERE  mem.resource_id = ln_salesforce_id
                       AND NVL(mem.delete_flag,'N') <> 'Y'
                       AND mem.group_id = NVL(ln_sales_group_id,mem.group_id)
                       AND jru.group_id = mem.group_id
                       AND jru.USAGE = 'SALES'
                       AND jrr.role_resource_id = mem.group_member_id
                       AND jrr.role_resource_type = 'RS_GROUP_MEMBER'
                       AND TRUNC(SYSDATE) BETWEEN TRUNC(jrr.start_date_active)
                                                  AND NVL(TRUNC(jrr.end_date_active),TRUNC(SYSDATE))
                       AND NVL(jrr.delete_flag,'N') <> 'Y'
                       AND rol.role_id = jrr.role_id
                       AND rol.role_type_code = 'SALES'
                       AND rol.manager_flag = 'Y'
                       AND rol.active_flag = 'Y';
                
                IF ln_count = 0 THEN
                -- This means the resource is a sales-rep
                
                  lc_manager_flag := 'N';
                ELSIF ln_count = 1 THEN
                -- This means the resource is a manager
                
                  lc_manager_flag := 'Y';
                ELSE
                -- The resource has more than one manager role
                
                  fnd_message.set_name('XXCRM','XX_TM_0219_MGR_MORE_THAN_ONE');
                  
                  fnd_message.set_token('P_RESOURCE_ID',ln_salesforce_id);
                  
                  lc_err_desc := fnd_message.get;
                  --WRITE_LOG(lc_err_desc);
                  
                  fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                  
                  xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                     p_application_name => lc_application_name,
                                                     p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                     p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                     p_error_message_code => 'XX_TM_0219_MGR_MORE_THAN_ONE',
                                                     p_error_message => substr(lc_err_desc,1,4000),
                                                     p_error_message_severity => 'MINOR');
                  
                  RAISE ex_create_err;
                END IF; -- ln_count = 0
  
                fnd_file.put_line(fnd_file.LOG, 'Is Manager? :'|| lc_manager_flag);

                -- Derive the role_id and group_id of assignee resource
                -- with the resource_id and group_id derived
                
                BEGIN
                  SELECT jrr_asg.role_id
                         ,mem_asg.group_id
                         ,rol_asg.attribute15
                  INTO   ln_asignee_role_id
                         ,ln_sales_group_id
                         ,lc_division
                  FROM   jtf_rs_group_members mem_asg
                         ,jtf_rs_role_relations jrr_asg
                         ,jtf_rs_group_usages jru_asg
                         ,jtf_rs_roles_b rol_asg
                  WHERE  mem_asg.resource_id = ln_salesforce_id
                         AND NVL(mem_asg.delete_flag,'N') <> 'Y'
                         AND mem_asg.group_id = NVL(ln_sales_group_id,mem_asg.group_id)
                         AND jru_asg.group_id = mem_asg.group_id
                         AND jru_asg.USAGE = 'SALES'
                         AND jrr_asg.role_resource_id = mem_asg.group_member_id
                         AND jrr_asg.role_resource_type = 'RS_GROUP_MEMBER'
                         AND TRUNC(SYSDATE) BETWEEN TRUNC(jrr_asg.start_date_active)
                                                    AND NVL(TRUNC(jrr_asg.end_date_active),TRUNC(SYSDATE))
                         AND NVL(jrr_asg.delete_flag,'N') <> 'Y'
                         AND rol_asg.role_id = jrr_asg.role_id
                         AND rol_asg.role_type_code = 'SALES'
                         AND rol_asg.active_flag = 'Y'
                         AND (CASE lc_manager_flag 
                                WHEN 'Y' THEN rol_asg.attribute14
                                ELSE 'N'
                              END) = (CASE lc_manager_flag 
                                        WHEN 'Y' THEN 'HSE'
                                        ELSE 'N'
                                      END);

                    fnd_file.put_line(fnd_file.LOG,'This Resource belongs to '||lc_division||' division'); --Added, Aug21

                    IF lc_division <> 'BSD' THEN --Added, Aug21
                       raise EX_NEXT_REC;
                    END IF;
                                
                  EXCEPTION
                  WHEN no_data_found THEN
                    IF lc_manager_flag = 'Y' THEN
                      fnd_message.set_name('XXCRM','XX_TM_0229_AS_MGR_NO_HSE_ROLE');
                      
                      fnd_message.set_token('P_RESOURCE_ID',ln_salesforce_id);
                      
                      lc_err_desc := fnd_message.get;
                      
                      lc_message_code := 'XX_TM_0229_AS_MGR_NO_HSE_ROLE';

                    ELSE
                      fnd_message.set_name('XXCRM','XX_TM_0122_AS_NO_SALES_ROLE');
                      
                      fnd_message.set_token('P_RESOURCE_ID',ln_salesforce_id);
                      
                      lc_err_desc := fnd_message.get;
                      
                      lc_message_code := 'XX_TM_0122_AS_NO_SALES_ROLE';

                    END IF;
                    --WRITE_LOG(lc_err_desc);
                    
                    fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                    
                    xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                       p_application_name => lc_application_name,
                                                       p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                       p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                       p_error_message_code => lc_message_code,p_error_message => substr(lc_err_desc,1,4000),
                                                       p_error_message_severity => 'MINOR');
                    
                    RAISE ex_create_err;
                  WHEN too_many_rows THEN
                    IF lc_manager_flag = 'Y' THEN
                      fnd_message.set_name('XXCRM','XX_TM_0230_AS_MGR_HSE_ROLE');
                      
                      fnd_message.set_token('P_RESOURCE_ID',ln_salesforce_id);
                      
                      lc_err_desc := fnd_message.get;
                      
                      lc_message_code := 'XX_TM_0230_AS_MGR_HSE_ROLE';
                    ELSE
                      fnd_message.set_name('XXCRM','XX_TM_0123_AS_MANY_SALES_ROLE');
                      
                      fnd_message.set_token('P_RESOURCE_ID',ln_salesforce_id);
                      
                      lc_err_desc := fnd_message.get;
                      
                      lc_message_code := 'XX_TM_0123_AS_MANY_SALES_ROLE';
                    END IF;
                    --WRITE_LOG(lc_error_message);
                    
                    fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                    
                    xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                       p_application_name => lc_application_name,
                                                       p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                       p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                       p_error_message_code => lc_message_code,p_error_message => substr(lc_err_desc,1,4000),
                                                       p_error_message_severity => 'MINOR');
                    
                    RAISE ex_create_err;
                  
                    WHEN EX_NEXT_REC THEN -- Added, Aug20
                     RAISE ex_create_err;
                  
                    WHEN OTHERS THEN
                    fnd_message.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                    
                    lc_set_message := 'Unexpected Error while deriving role_id and role_division of the assignee.';
                    
                    fnd_message.set_token('PROCEDURE_NAME',lc_set_message);
                    
                    fnd_message.set_token('ERROR_CODE',SQLCODE);
                    
                    fnd_message.set_token('ERROR_MESSAGE',SQLERRM);
                    
                    lc_err_desc := fnd_message.get;
                    --Write_log('step 1');
                    --WRITE_LOG(lc_err_desc);
                    
                    fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                    
                    xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                       p_application_name => lc_application_name,
                                                       p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                       p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                       p_error_message_code => 'XX_TM_0007_UNEXPECTED_ERR',
                                                       p_error_message => substr(lc_err_desc,1,4000),
                                                       p_error_message_severity => 'MINOR');
                    
                    RAISE ex_create_err;
                END;
              ELSE
              -- Derive the role_id and group_id of assignee resource
              -- with the resource_id, group_id and role_code returned
              -- from get_winners
              
                BEGIN
                  SELECT jrr_asg.role_id
                         ,mem_asg.group_id
                         ,rol_asg.attribute15
                  INTO   ln_asignee_role_id
                         ,ln_sales_group_id
                         ,lc_division
                  FROM   jtf_rs_group_members mem_asg
                         ,jtf_rs_role_relations jrr_asg
                         ,jtf_rs_group_usages jru_asg
                         ,jtf_rs_roles_b rol_asg
                  WHERE  mem_asg.resource_id = ln_salesforce_id
                         AND mem_asg.group_id = NVL(ln_sales_group_id,mem_asg.group_id)
                         AND NVL(mem_asg.delete_flag,'N') <> 'Y'
                         AND jru_asg.group_id = mem_asg.group_id
                         AND jru_asg.USAGE = 'SALES'
                         AND jrr_asg.role_resource_id = mem_asg.group_member_id
                         AND jrr_asg.role_resource_type = 'RS_GROUP_MEMBER'
                         AND TRUNC(SYSDATE) BETWEEN TRUNC(jrr_asg.start_date_active)
                                                    AND NVL(TRUNC(jrr_asg.end_date_active),TRUNC(SYSDATE))
                         AND NVL(jrr_asg.delete_flag,'N') <> 'Y'
                         AND rol_asg.role_id = jrr_asg.role_id
                         AND rol_asg.role_code = lc_role
                         AND rol_asg.role_type_code = 'SALES'
                         AND rol_asg.active_flag = 'Y'; 
                         --AND rol_asg.attribute15 = 'BSD'; -- Aug22

                    fnd_file.put_line(fnd_file.LOG,'This Resource belongs to '||lc_division|| ' division');
                    
                IF lc_division <> 'BSD' THEN
                   raise EX_NEXT_REC;
                END IF;
                                                 
                EXCEPTION
                  WHEN no_data_found THEN
                    
                    lc_err_desc := 'This Resource does not belongs to BSD division';
                    --WRITE_LOG(lc_err_desc);
                    
                    fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                    
                    xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                       p_application_name => lc_application_name,
                                                       p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                       p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                       p_error_message_code => '',
                                                       p_error_message => substr(lc_err_desc,1,4000),
                                                       p_error_message_severity => 'MINOR');
                    
                    RAISE ex_create_err;
                  
                  WHEN EX_NEXT_REC THEN
                    RAISE ex_create_err;

                  WHEN OTHERS THEN
                    fnd_message.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                    
                    lc_set_message := 'Unexpected Error while deriving role_id of the assignee with the role_code';
                    
                    fnd_message.set_token('PROCEDURE_NAME',lc_set_message);
                    
                    fnd_message.set_token('ERROR_CODE',SQLCODE);
                    
                    fnd_message.set_token('ERROR_MESSAGE',SQLERRM);
                    
                    lc_err_desc := fnd_message.get;
                    --WRITE_LOG(lc_err_desc);
                    
                    fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                    
                    xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                       p_application_name => lc_application_name,
                                                       p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                       p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                       p_error_message_code => 'XX_TM_0007_UNEXPECTED_ERR',
                                                       p_error_message => substr(lc_err_desc,1,4000),
                                                       p_error_message_severity => 'MINOR');
                    
                    RAISE ex_create_err;
                END;
              END IF; -- lc_role IS NULL
              
              -- If the control has reached this point, then this resource must be  a BSD resource. Non BSD resource will not reach this point becuase of filter condition at the above steps.
                          
              lc_bsd_flag := 'Y';
                          
              BEGIN
              SELECT jrrr.attribute15,
                     jrgt.group_name,
                     jrgmv.resource_name
                INTO  lc_legacy_rep_id,
                      lc_group_name,
                      lc_resource_name
                FROM   jtf_rs_role_relations jrrr,
                       jtf_rs_group_members_vl jrgmv,
                       jtf_rs_groups_tl jrgt
               WHERE   jrrr.role_resource_id = jrgmv.group_member_id
                 AND jrgmv.group_id = jrgt.group_id
                 AND NVL(jrgmv.delete_flag,'N') = 'N'
                 AND NVL(jrrr.delete_flag,'N') = 'N'
                 AND TRUNC(SYSDATE) BETWEEN NVL(jrrr.start_date_active,SYSDATE - 1)
                                  AND NVL(jrrr.end_date_active,SYSDATE + 1)
                 AND jrrr.role_resource_type = 'RS_GROUP_MEMBER'
                 AND jrrr.role_id = ln_asignee_role_id
                 AND jrgmv.resource_id = ln_salesforce_id
                 AND jrgmv.group_id = ln_sales_group_id;
              
              IF lc_legacy_rep_id IS NULL THEN
                 lc_err_desc := 'Legacy Rep ID is not defined for the '
                                             ||'RESOURCE_ID:'||ln_salesforce_id
                                             ||'('||lc_resource_name||')'
                                             ||' GROUP_ID:'||ln_sales_group_id
                                             ||'('||lc_group_name||')'
                                             ||' ASSIGNED_ROLE_ID:'||ln_asignee_role_id
                                             ||'('||lx_gen_return_rec.role(l_counter)||')';
                 fnd_file.put_line(fnd_file.LOG,lc_err_desc);
              END IF;
              
              EXCEPTION
              WHEN OTHERS THEN
                   lc_err_desc := 'Legacy Rep ID is not defined for the '
                                             ||'RESOURCE_ID:'||ln_salesforce_id
                                             ||'('||lc_resource_name||')'
                                             ||' GROUP_ID:'||ln_sales_group_id
                                             ||'('||lc_group_name||')'
                                             ||' ASSIGNED_ROLE_ID:'||ln_asignee_role_id
                                             ||'('||lx_gen_return_rec.role(l_counter)||')';
                   fnd_file.put_line(fnd_file.LOG,lc_err_desc);
                   lc_legacy_rep_id := NULL;
              END;

              fnd_file.put_line(fnd_file.LOG,'RESOURCE_ID:'||ln_salesforce_id
                                             ||'('||lc_resource_name||')'
                                             ||' GROUP_ID:'||ln_sales_group_id
                                             ||'('||lc_group_name||')'
                                             ||' ASSIGNED_ROLE_ID:'||ln_asignee_role_id
                                             ||'('||lx_gen_return_rec.role(l_counter)||')'
                                             ||' LEGACY_REP_ID:'||lc_legacy_rep_id);

              SELECT COUNT(* )
              INTO   ln_cnt_res_converted
              FROM   xx_cdh_solar_conversion_group
              WHERE  conversion_rep_id = lc_legacy_rep_id
                AND converted_flag = 'Y';
              
              IF ln_cnt_res_converted = 0 THEN
                
                UPDATE  xxcrm.xx_sfa_lead_referrals
                   SET  process_status = 'SEND_TO_SOLAR',
                        error_message = substr(lc_err_desc,1,4000)
                 WHERE  internid       = i.internid;
                
                fnd_file.put_line(fnd_file.LOG,'This Resource has not been converted yet from SOLAR');
              
              ELSE

                UPDATE  xxcrm.xx_sfa_lead_referrals
                   SET  process_status = 'VALIDATED'
                 WHERE  internid       = i.internid;

                fnd_file.put_line(fnd_file.LOG,'This Resource has been converted from SOLAR');
                fnd_file.put_line(fnd_file.LOG,'Exiting Loop');
              
                exit; --Added, Aug20
               
              END IF; --ln_cnt_res_converted >0
              
            EXCEPTION
              WHEN ex_create_err THEN
                   Null;
              WHEN OTHERS THEN
                fnd_message.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                
                lc_set_message := 'Unexpected Error while finding resource details based on the resource id : '
                                  ||ln_salesforce_id;
                
                fnd_message.set_token('PROCEDURE_NAME',lc_set_message);
                
                fnd_message.set_token('ERROR_CODE',SQLCODE);
                
                fnd_message.set_token('ERROR_MESSAGE',SQLERRM);
                
                lc_err_desc := fnd_message.get;
                --WRITE_LOG(lc_err_desc);
                
                xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                   p_application_name => lc_application_name,
                                                   p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                   p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                   p_error_message_code => 'XX_TM_0007_UNEXPECTED_ERR',
                                                   p_error_message => substr(lc_err_desc,1,4000),
                                                   p_error_message_severity => 'MINOR');
            END;
            
            l_counter := l_counter + 1;
          END LOOP; -- l_counter <= lx_gen_return_rec.terr_id.LAST

          IF lc_bsd_flag = 'N' THEN -- Aug22
                    
            UPDATE xxcrm.xx_sfa_lead_referrals
            SET    process_status = 'GETWIN_ERROR' --Aug22,
            WHERE  internid = i.internid;

            fnd_file.put_line(fnd_file.LOG,'Error: Get Winner API did not return BSD resource. Check Territory Setup.');
            
            fnd_message.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                
            lc_set_message := 'Get Winner API did not return BSD resource.';
                
            fnd_message.set_token('PROCEDURE_NAME',lc_set_message);
                
            fnd_message.set_token('ERROR_CODE',SQLCODE);
                
            fnd_message.set_token('ERROR_MESSAGE',SQLERRM);
                
            lc_err_desc := fnd_message.get;
                --WRITE_LOG(lc_err_desc);
                
            xx_com_error_log_pub.log_error_crm(p_return_code => fnd_api.g_ret_sts_error,
                                                   p_application_name => lc_application_name,
                                                   p_program_type => lc_program_type,p_program_name => lc_program_name,
                                                   p_module_name => lc_module_name,p_error_location => lc_error_location,
                                                   p_error_message_code => 'XX_TM_0007_UNEXPECTED_ERR',
                                                   p_error_message => substr(lc_err_desc,1,4000),
                                                   p_error_message_severity => 'MINOR');
                                                                                                   
         END IF;

        END IF; --NVL(l_counter,0)
      END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
          
                          
    END LOOP; --blcu_lead_ref

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      
      fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
      
      lc_err_desc := fnd_message.get;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                         p_error_message => substr(lc_err_desc
                                                                   ||'=>'
                                                                   ||SQLERRM,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'Exception in P_Validate_Data_for_RSD_Waves'
                                     ||substr(lc_err_desc
                                              ||'=>'
                                              ||SQLERRM,1,4000));
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      x_retcode := 2;
  END validate_data_for_rsd_waves;
  -- +===================================================================+
  -- | Name             : REPORT_FOR_SOLAR                               |
  -- | Description      : Procedure to Report the unprocessed Lead       |
  -- |                    Referral records for RSD Waves not converted   |
  -- |                    to oracle EBiz yet                             |
  -- | Parameters       : x_errbuf                                       |
  -- |                    x_retcode                                      |
  -- +===================================================================+
  
  PROCEDURE report_for_solar
       (x_errbuf    OUT NOCOPY VARCHAR2
        ,x_retcode  OUT NOCOPY NUMBER)
  IS
    lc_application_name    xx_com_error_log.application_name%TYPE := 'XXCRM';
    lc_program_type        xx_com_error_log.program_type%TYPE := 'I2043_Lead_Referral';
    lc_program_name        xx_com_error_log.program_name%TYPE := 'XX_SFA_LEAD_REFERRAL_PKG';
    lc_module_name         xx_com_error_log.module_name%TYPE := 'SFA';
    lc_error_location      xx_com_error_log.error_location%TYPE := 'VALIDATE_DATA';
    lc_token               VARCHAR2(4000);
    lc_error_message_code  VARCHAR2(100);
    lc_err_desc            xx_com_error_log.error_message%TYPE DEFAULT ' ';
    ln_rec_count           NUMBER := 0;
    CURSOR lcu_lead_ref_for_solar IS 
      SELECT internid
             ,NAME
             ,addr1
             ,city
             ,state
             ,country
             ,zip
             ,phone
             ,num_wc_emp_od
             ,duns_number
             ,source
             ,rev_band
             ,fname
             ,lname
             ,contact_title
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status IN ('SEND_TO_SOLAR');
  BEGIN
  -- FND_FILE.put_line (FND_FILE.output, p_message);
  
    fnd_file.put_line(fnd_file.output,' ');
    fnd_file.put_line(fnd_file.output,rpad(' ',40)||'OD: SFA Lead Referral Report for SOLAR');
    fnd_file.put_line(fnd_file.output,rpad(' ',40)||'--------------------------------------');
    fnd_file.put_line(fnd_file.output,' ');
    fnd_file.put_line(fnd_file.output,' ');
    
    fnd_file.put_line(fnd_file.output,rpad('-',12,'-')
                                      ||'| '
                                      ||rpad('-',50,'-')
                                      ||'   '
                                      ||rpad('-',80,'-')
                                      ||'   '
                                      ||rpad('-',30,'-')
                                      ||'   '
                                      ||rpad('-',5,'-')
                                      ||'   '
                                      ||rpad('-',7,'-')
                                      ||'   '
                                      ||rpad('-',15,'-')
                                      ||'   '
                                      ||rpad('-',20,'-')
                                      ||'   '
                                      ||rpad('-',5,'-')
                                      ||'   '
                                      ||rpad('-',10,'-')
                                      ||'   '
                                      ||rpad('-',15,'-')
                                      ||'   '
                                      ||rpad('-',15,'-')
                                      ||'   '
                                      ||rpad('-',30,'-')
                                      ||'   '
                                      ||rpad('-',30,'-')
                                      ||'   '
                                      ||rpad('-',25,'-')
                                      ||' | ');
    
    fnd_file.put_line(fnd_file.output,rpad('Referral ID',12)
                                      ||'| '
                                      ||rpad('Prospect Name',50)
                                      ||' | '
                                      ||rpad('Address1',80)
                                      ||' | '
                                      ||rpad('City',30)
                                      ||' | '
                                      ||rpad('State',5)
                                      ||' | '
                                      ||rpad('Country',7)
                                      ||' | '
                                      ||rpad('Postal Code',15)
                                      ||' | '
                                      ||rpad('Phone',20)
                                      ||' | '
                                      ||rpad('OD WCW',5)
                                      ||' | '
                                      ||rpad('DUNS No',10)
                                      ||' | '
                                      ||rpad('Source',15)
                                      ||' | '
                                      ||rpad('Revenue Band',15)
                                      ||' | '
                                      ||rpad('First name',30)
                                      ||' | '
                                      ||rpad('Last Name',30)
                                      ||' | '
                                      ||rpad('Contact Title',25)
                                      ||' | ');
    
    fnd_file.put_line(fnd_file.output,rpad('-',12,'-')
                                      ||'| '
                                      ||rpad('-',50,'-')
                                      ||'   '
                                      ||rpad('-',80,'-')
                                      ||'   '
                                      ||rpad('-',30,'-')
                                      ||'   '
                                      ||rpad('-',5,'-')
                                      ||'   '
                                      ||rpad('-',7,'-')
                                      ||'   '
                                      ||rpad('-',15,'-')
                                      ||'   '
                                      ||rpad('-',20,'-')
                                      ||'   '
                                      ||rpad('-',5,'-')
                                      ||'   '
                                      ||rpad('-',10,'-')
                                      ||'   '
                                      ||rpad('-',15,'-')
                                      ||'   '
                                      ||rpad('-',15,'-')
                                      ||'   '
                                      ||rpad('-',30,'-')
                                      ||'   '
                                      ||rpad('-',30,'-')
                                      ||'   '
                                      ||rpad('-',25,'-')
                                      ||' | ');
    
    FOR i IN lcu_lead_ref_for_solar LOOP
      fnd_file.put_line(fnd_file.output,rpad(i.internid,12)
                                        ||'| '
                                        ||rpad(i.NAME,50)
                                        ||' | '
                                        ||rpad(i.addr1,80)
                                        ||' | '
                                        ||rpad(i.city,30)
                                        ||' | '
                                        ||rpad(i.state,5)
                                        ||' | '
                                        ||rpad(i.country,7)
                                        ||' | '
                                        ||rpad(i.zip,15)
                                        ||' | '
                                        ||rpad(i.phone,20)
                                        ||' | '
                                        ||rpad(i.num_wc_emp_od,5)
                                        ||' | '
                                        ||rpad(nvl(i.duns_number,' '),10)
                                        ||' | '
                                        ||rpad(i.source,15)
                                        ||' | '
                                        ||rpad(i.rev_band,15)
                                        ||' | '
                                        ||rpad(i.fname,30)
                                        ||' | '
                                        ||rpad(i.lname,30)
                                        ||' | '
                                        ||rpad(i.contact_title,25)
                                        ||' | ');
      
      UPDATE xxcrm.xx_sfa_lead_referrals
      SET    process_status = 'SENT_TO_SOLAR'
      WHERE  internid = i.internid;

      ln_rec_count := ln_rec_count + 1;
    END LOOP;

    IF ln_rec_count = 0 THEN
      fnd_file.put_line(fnd_file.output, '********************************** No Leads are found **********************************');
    END IF;
    
    fnd_file.put_line(fnd_file.output,rpad('-',12,'-')
                                      ||'| '
                                      ||rpad('-',50,'-')
                                      ||'   '
                                      ||rpad('-',80,'-')
                                      ||'   '
                                      ||rpad('-',30,'-')
                                      ||'   '
                                      ||rpad('-',5,'-')
                                      ||'   '
                                      ||rpad('-',7,'-')
                                      ||'   '
                                      ||rpad('-',15,'-')
                                      ||'   '
                                      ||rpad('-',20,'-')
                                      ||'   '
                                      ||rpad('-',5,'-')
                                      ||'   '
                                      ||rpad('-',10,'-')
                                      ||'   '
                                      ||rpad('-',15,'-')
                                      ||'   '
                                      ||rpad('-',15,'-')
                                      ||'   '
                                      ||rpad('-',30,'-')
                                      ||'   '
                                      ||rpad('-',30,'-')
                                      ||'   '
                                      ||rpad('-',25,'-')
                                      ||' | ');
  
  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      
      fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
      
      lc_err_desc := fnd_message.get;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                         p_error_message => substr(lc_err_desc
                                                                   ||'=>'
                                                                   ||SQLERRM,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'Exception in P_LR_Report_For_Solar'
                                     ||substr(lc_err_desc
                                              ||'=>'
                                              ||SQLERRM,1,4000));
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      x_retcode := 2;
  END report_for_solar;
END XX_SFA_LEADREF_RSD_WAVES_PKG;
/
Show Errors
