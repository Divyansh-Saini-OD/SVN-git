SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_SOLAR_TASKS_PKG 
AS

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |              Oracle NAIO Consulting Organization                      |
-- +=======================================================================+
-- | Name             :XX_CDH_SOLAR_TASKS_PKG.pkb                          |
-- | Rice ID          :I0906 load SOLAR TASKS into Oracle Common View      |
-- | Description      :This package contains procedure to load Tasks data  |
-- |                   from Image table to CDH Common view table           |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      14_Nov-2007 David Woods        Initial version                |
-- |1.1      23-Jan-2008 Hema Chikkanna     Modified code to convert into  |
-- |                                        Package procedure, added       |
-- |                                        exception handling             |
-- |1.2      11-Feb-2008 Hema Chikkanna     Modified code to include       |
-- |                                        Revenue Band in the filter     |
-- |                                        criteria                       |
-- |1.3      16-Feb-2008 Hema Chikkanna     Included lookup for Rev Band   |
-- |1.4      12-Mar-2008 Hema Chikkanna     Task Conversion for Customers  | 
-- +=======================================================================+


-- +=======================================================================+
-- | Name         : LOG_ECEPTION                                           |
-- | Description  : This procedure is used to log the exceptions           |
-- |                                                                       |
-- | Parameters   : Name                   IN/OUT  Type     Description    |
-- |                                                                       |
-- |                p_record_control_id    IN     NUMBER    Record Ctl ID  |
-- |                p_procedure_name       IN     VARCHAR2  Procedure Name |
-- |                p_staging_table_name   IN     VARCHAR2  Stg Table Name |
-- |                p_staging_column_name  IN     VARCHAR2  Stg Column     |
-- |                p_staging_column_value IN     VARCHAR2  Stg Value      |
-- |                p_batch_id             IN     NUMBER    Batch ID       |
-- |                p_exception_log        IN     VARCHAR2  Exception Log  |
-- |                p_source_system_code   IN     VARCHAR2  Source Code    |
-- |                p_source_system_ref    IN     VARCHAR2  Source Ref     |
-- |                p_oracle_error_code    IN     VARCHAR2  Error Code     |
-- |                p_oracle_error_msg     IN     VARCHAR2  Error Message  |
-- +=======================================================================+


PROCEDURE LOG_EXCEPTION(
                         p_record_control_id      IN NUMBER
                        ,p_procedure_name         IN VARCHAR2
                        ,p_staging_table_name     IN VARCHAR2
                        ,p_staging_column_name    IN VARCHAR2
                        ,p_staging_column_value   IN VARCHAR2
                        ,p_batch_id               IN NUMBER
                        ,p_exception_log          IN VARCHAR2
                        ,p_source_system_code     IN VARCHAR2
                        ,p_source_system_ref      IN VARCHAR2
                        ,p_oracle_error_code      IN VARCHAR2
                        ,p_oracle_error_msg       IN VARCHAR2
                        )
 
AS
    lc_package_name           VARCHAR2(32)  := 'XX_CDH_SOLAR_TASKS_PKG';
    lc_source_system_code     VARCHAR2(5)   := 'SOLAR';
    ln_conversion_id          NUMBER        := 0906;
    
 BEGIN 
 
    XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc(   
             p_conversion_id          => ln_conversion_id
            ,p_record_control_id      => p_record_control_id 
            ,p_source_system_code     => lc_source_system_code
            ,p_package_name           => lc_package_name
            ,p_procedure_name         => p_procedure_name
            ,p_staging_table_name     => p_staging_table_name
            ,p_staging_column_name    => p_staging_column_name
            ,p_staging_column_value   => p_staging_column_value
            ,p_source_system_ref      => p_source_system_ref
            ,p_batch_id               => p_batch_id
            ,p_exception_log          => p_exception_log
            ,p_oracle_error_code      => p_oracle_error_code
            ,p_oracle_error_msg       => p_oracle_error_msg);

  EXCEPTION
  
      WHEN OTHERS 
      THEN
      
          fnd_file.put_line (fnd_file.LOG,'Error in Calling Procedure :'||SQLERRM);
          
          
 END LOG_EXCEPTION;

-- +=======================================================================+
-- | Name             : SOLAR_TASKS_MAIN                                   |
-- | Description      : This procedure is used to load the Tasks from      |
-- |                    Imange table to oracle Common view table           |
-- |                                                                       |
-- | Parameters       : Name          IN/OUT  Data Type   Description      |
-- |                                                                       |
-- |                    x_errbuf      OUT     VARCHAR2    Error Description|
-- |                    x_retcode     OUT     NUMBER      Error Number     |
-- |                    p_conv_grp_id IN      VARCHAR2    W/N/S/C group    |
-- |                    p_run         IN      VARCHAR2    Yes/No           |
-- |                                                                       |
-- +=======================================================================+

PROCEDURE solar_tasks_main (   x_errbuf              OUT NOCOPY VARCHAR2
                              ,x_retcode             OUT NOCOPY NUMBER
                              ,p_conv_grp_id         IN         VARCHAR2
                              ,p_run                 IN         VARCHAR2
                           )
AS
LC_PROCESS_NAME            CONSTANT VARCHAR2(20)          := 'SOLAR TASKS';

LC_CREATED_BY_MODULE       CONSTANT VARCHAR2(10)          := 'XXSOLAR';
LC_INTERFACE_STATUS        CONSTANT VARCHAR2(1)           := '1';
LC_INSERT_UPDATE_FLAG      CONSTANT VARCHAR2(1)           := 'I';
LC_SOURCE_SYSTEM           CONSTANT VARCHAR2(2)           := 'S0';
LC_TASKS_STATUS            CONSTANT VARCHAR2(20)          := 'I';
LC_XXTPS_SP_MAPPING        CONSTANT VARCHAR2(100)         := 'XXTPS_SP_MAPPING';
LC_JTF_ROLE_REL            CONSTANT VARCHAR2(100)         := 'JTF_RS_ROLE_RELATIONS';
LC_PACKAGE_NAME            CONSTANT VARCHAR2(100)         := 'XX_CDH_SOLAR_TASKS_PKG';
LC_PROCEDURE_NAME          CONSTANT VARCHAR2(100)         := 'SOLAR_TASKS_MAIN';
LC_SOURCE_SYSTEM_CODE      CONSTANT VARCHAR2(6)           := 'SOLAR';
LC_STG_COLUMN2             CONSTANT VARCHAR2(20)          := 'SP_ID_ORIG';
LC_STG_COLUMN1             CONSTANT VARCHAR2(20)          := 'ATTRIBUTE15';

lc_party_site              CONSTANT VARCHAR2(40)          := 'OD_PARTY_SITE';
LC_party                   CONSTANT VARCHAR2(5)           := 'PARTY';

lc_aops_id                 VARCHAR2(40);

lc_object_code             VARCHAR2(240);
lc_obj_orig_system         VARCHAR2(240);
lc_obj_orig_system_ref     VARCHAR2(240); 
ln_counter                 PLS_INTEGER;

lc_lookup_type             VARCHAR2(30)                   := 'XX_CRM_REV_BAND_TYPES';

ln_batch_id                NUMBER;
lc_batch_descr             VARCHAR2(1996);
lc_batch_name              VARCHAR2(255); 
lc_batch_error_msg         VARCHAR2(2000);

lc_error_msg               VARCHAR2(2000);

ln_created_by              NUMBER         := FND_GLOBAL.user_id;
ld_creation_date           DATE           := SYSDATE;
ln_last_updated_by         NUMBER         := FND_GLOBAL.user_id;
ld_last_update_date        DATE           := SYSDATE;
ln_last_update_login       NUMBER         := FND_GLOBAL.login_id;

EXP_SKIP_PROCEDURE         EXCEPTION;
EXP_BATCH_ID_INVLD         EXCEPTION;

lc_message                 VARCHAR2(4000);

lc_insert_flag             VARCHAR2(1);  
ln_record_id               PLS_INTEGER;
lc_descr                   VARCHAR2(2000);
lc_priority_name           VARCHAR2(40);
lc_task_status             VARCHAR2(40);  

CURSOR lcu_task IS 
   SELECT * 
   FROM XXCNV.xx_cdh_solar_todoimage    XCST
   WHERE UPPER(XCST.responsibility) <> '4SURE'
   AND   XCST.completed ='N'
   AND (CASE 
          WHEN TO_CHAR(XCST.task_date,'DD-MON-YYYY') != '01-JAN-1900'   THEN XCST.task_date
          ELSE XCST.rec_chng_dt
          END>= (SYSDATE - 30)        
            OR   CASE 
                 WHEN TO_CHAR(XCST.rec_chng_dt,'DD-MON-YYYY') != '01-JAN-1900'    THEN XCST.rec_chng_dt
               ELSE XCST.rec_crea_dt
               END >= (SYSDATE - 365));
               
CURSOR lcu_site(p_internid IN NUMBER) IS
  SELECT XCSS.site_type,
         XCSS.internid,
         XCSS.id,
         XCSS.state,
         XCSS.name,                                         
         UPPER(p_conv_grp_id),                              
         XCSS.conversion_rep_id,                           
         XSM.sp_id_new                                      
  FROM   XXCNV.xx_cdh_solar_siteimage    XCSS
        ,XXTPS.xxtps_sp_mapping          XSM 
  WHERE  XCSS.internid = p_internid
  AND    XCSS.site_type IN ('PROSPECT','TARGET','SHIPTO')
  AND    EXISTS (  SELECT 1
                   FROM   fnd_lookup_values FLV
                   WHERE  FLV.lookup_type  = lc_lookup_type
                   AND    FLV.enabled_flag = 'Y'
                   AND    FLV.language     = 'US'
                   AND    FLV.lookup_code  = UPPER(XCSS.rev_band)
                   AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE - 1) 
                                              AND NVL(FLV.end_date_active,SYSDATE + 1)
                        )
  AND    EXISTS   (  SELECT 1
                     FROM   xx_cdh_solar_conversion_group XCSCG
                     WHERE  XCSCG.conversion_group_id = UPPER(p_conv_grp_id)
                     AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id
                     AND    XCSCG.validate_status     ='OK'
                     AND   ( SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                                                       AND NVL(XCSCG.end_date_active,SYSDATE + 1 )) 
                          )
  AND XCSS.status ='ACTIVE'
  AND XCSS.conversion_rep_id = XSM.sp_id_orig(+);

       

BEGIN

        
    FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE (FND_FILE.LOG
         ,  RPAD ('Office DEPOT', 40, ' ')
         || LPAD ('DATE: ', 30, ' ')
         || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
         );
    FND_FILE.PUT_LINE (FND_FILE.LOG
         ,LPAD ('OD: SOLAR load TASKS to CV tables', 53, ' ')
         );
    FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');


    IF NVL(p_run,'N') = 'N' THEN
    
           
       RAISE EXP_SKIP_PROCEDURE; 
       
      
    END IF;
    
    ---------------------
    -- Generate Batch ID
    ---------------------
    FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Derivation of Batch ID');
    FND_FILE.PUT_LINE (FND_FILE.LOG, '-----------------------');
    FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');
    
    XX_CDH_SOLAR_CONV_PKG.get_batch_id
                                          (  p_process_name      => LC_PROCESS_NAME
                                            ,p_group_id          => p_conv_grp_id
                                            ,x_batch_name        => lc_batch_name
                                            ,x_batch_descr       => lc_batch_descr
                                            ,x_batch_id          => ln_batch_id
                                            ,x_error_msg         => lc_batch_error_msg
                                          );
    
    IF ln_batch_id IS NOT NULL 
    THEN
        -------------------------------------
        --Insert the generated batch id into 
        --XX_CDH_SOLAR_BATCH_ID table
        -------------------------------------
        INSERT INTO xxcnv.xx_cdh_solar_batch_id
                 ( batch_id
                  ,batch_name
                  ,description
                  ,created_by         
                  ,creation_date      
                  ,last_updated_by    
                  ,last_update_date   
                  ,last_update_login  
                  )
        VALUES    ( ln_batch_id
                   ,lc_batch_name
                   ,lc_batch_descr
                   ,ln_created_by
                   ,ld_creation_date
                   ,ln_last_updated_by
                   ,ld_last_update_date
                   ,ln_last_update_login
                  );
        
        COMMIT;
        
        FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch ID: '|| ln_batch_id);
        FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch Name: '|| lc_batch_descr);
        FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');   
             
    ELSE
       
       IF lc_batch_error_msg IS NOT NULL
       THEN
       
          FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error While Generating Batch ID: '|| lc_batch_error_msg);
          FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');
          
       END IF;   
           
       RAISE EXP_BATCH_ID_INVLD; 
        
    END IF;
 -----------------------------------------------
  -- Insert records into the interface tables
 -----------------------------------------------
    ln_counter :=0;
    
    FOR  lr_task in lcu_task
    LOOP
    
      FOR lr_site in lcu_site(lr_task.internid)
      LOOP
            lc_object_code         := NULL; 
            lc_obj_orig_system     := NULL;
            lc_obj_orig_system_ref := NULL;
            lc_insert_flag         := 'Y';
            lc_priority_name       := NULL;
            lc_descr               := NULL;
            lc_task_status         := NULL;
           
            IF lr_site.site_type IN ('PROSPECT','TARGET')
            THEN
              
              lc_object_code := lc_party;
              lc_obj_orig_system := 'S0';
              lc_obj_orig_system_ref := LPAD(lr_site.internid,10,'0') || '-00001-S0';
              
            ELSIF lr_site.site_type ='SHIPTO'
            THEN
            
              lc_object_code := lc_party_site;
              lc_obj_orig_system := 'A0';
              lc_obj_orig_system_ref := SUBSTR(lr_site.id,1,8) || '-' || SUBSTR(lr_site.id,9,5) || '-A0';
              
             END IF;
             
             ln_counter := ln_counter+1;
             
             lc_aops_id := NULL;
             
 
            BEGIN 
               SELECT attribute15
               INTO   lc_aops_id
               FROM   jtf_rs_role_relations JRRR
               WHERE  JRRR.attribute15 = lr_site.sp_id_new
               AND    ROWNUM=1;
            EXCEPTION
               
              WHEN OTHERS 
              THEN
              lc_insert_flag :='N';
              FND_FILE.PUT_LINE (FND_FILE.LOG,SQLERRM||SQLCODE);
              x_retcode :=1;
              
            END;   
            
            
             
             IF lc_aops_id IS NULL
             THEN
               lc_insert_flag :='N';
               fnd_file.put_line (fnd_file.LOG ,'AOPS ID is null for the Rep '||lr_site.sp_id_new||'-'||lr_task.internid );
             
             END IF;
             
             IF lc_insert_flag ='Y'
             THEN
             
                 SELECT xx_jtf_imp_tasks_int_s.NEXTVAL 
                 INTO ln_record_id 
                 FROM DUAL;

                 IF lr_task.descr IS NULL
                 THEN

                    lc_descr :='Not Available';

                 ELSE

                    lc_descr := lr_task.descr;

                 END IF; 

                 IF lr_task.priority ='1'
                 THEN

                     lc_priority_name :='High';
                     
                 ELSIF lr_task.priority ='2'
                 THEN
                    lc_priority_name :='Medium';
                    
                 ELSIF lr_task.priority ='3'
                 THEN
                    lc_priority_name :='Low';
                    
                 ELSE
                    lc_priority_name :='Unprioritized';
                    
                 END IF; 
                
                 IF lr_task.completed ='N'
                 THEN
                    lc_task_status := 'In Progress';
                    
                 ELSIF lr_task.completed ='Y'
                 THEN
                    lc_task_status := 'Close';
                 END IF;  
             
              INSERT INTO xx_jtf_imp_tasks_int
                           (batch_id                             
                           ,created_by_module                      
                           ,creation_date                                  
                           ,record_id           
                           ,insert_update_flag 
                           ,interface_status           
                           ,source_object_orig_system                    
                           ,source_object_orig_system_ref              
                           ,source_object_code               
                           ,task_original_system_ref    
                           ,description                            
                           ,task_priority_name                
                           ,owner_original_system_ref 
                           ,scheduled_start_date
                           ,scheduled_end_date
                           ,actual_end_date
                           ,task_type_name
                           ,task_name
                           ,task_status_name
                           ,attribute15
                           ,created_by
                        )VALUES( 
                           ln_batch_id
                          ,LC_CREATED_BY_MODULE
                          ,SYSDATE
                          ,ln_record_id
                          ,LC_INSERT_UPDATE_FLAG
                          ,LC_INTERFACE_STATUS
                          ,lc_obj_orig_system
                          ,lc_obj_orig_system_ref
                          ,lc_object_code
                          ,LPAD(lr_task.internid,10,'0') || '-' || lr_task.stamp2
                          ,lc_descr
                          ,lc_priority_name
                          ,lc_aops_id
                          ,lr_task.create_date 
                          ,lr_task.task_date
                          ,lr_task.completed_dt
                          ,'Other'
                          ,lc_descr
                          ,lc_task_status
                          ,LPAD(lr_task.internid,10,'0')|| '-' ||lr_task.stamp2
                          ,ln_created_by
                          );
                          
             INSERT INTO xx_jtf_imp_task_refs_int
                          (batch_id                             
                          ,created_by_module  
                          ,creation_date
                          ,record_id
                          ,insert_update_flag
                          ,interface_status 
                          ,task_orig_system_ref
                          ,task_ref_orig_system_ref
                          ,object_type_code
                          ,object_orig_sys
                          ,object_orig_system_ref
                          ,object_details
                          ,task_ref_orig_system
                          ,created_by
                         )VALUES(
                           ln_batch_id                             
                          ,LC_CREATED_BY_MODULE  
                          ,SYSDATE
                          ,ln_record_id
                          ,LC_INSERT_UPDATE_FLAG
                          ,LC_INTERFACE_STATUS 
                          ,LPAD(lr_task.internid,10,'0') || '-' || lr_task.stamp2          
                          ,LPAD(lr_task.internid,10,'0') || '-' || lr_task.stamp2 
                          ,lc_object_code               
                          ,lc_obj_orig_system
                          ,lc_obj_orig_system_ref
                          ,'TODO FROM SOLAR'             
                          ,'S0'
                          ,ln_created_by);
            
         END IF; -- End of insert flag check    
             
      END LOOP;
      
    END LOOP;
    
    COMMIT;
    
    fnd_file.put_line (fnd_file.LOG,' ');
    fnd_file.put_line (fnd_file.LOG ,'Number of Records Inserted into XX_JTF_IMP_TASKS_INT :'||ln_counter);
    fnd_file.put_line (fnd_file.LOG,' ');
    fnd_file.put_line (fnd_file.LOG ,'Number of Records Inserted into XX_JTF_IMP_TASK_REFS_INT :'||ln_counter);
    fnd_file.put_line (fnd_file.LOG,' ');
    
    
EXCEPTION

  WHEN EXP_SKIP_PROCEDURE
  THEN
  
     ROLLBACK;
     
     fnd_file.put_line (fnd_file.LOG ,'Execution of Program OD: Load SOLAR Tasks to CV tables Skipped'  );
     fnd_file.put_line (fnd_file.LOG ,' ');
        
     
  WHEN  EXP_BATCH_ID_INVLD
  THEN
  
     ROLLBACK;
     
     FND_MESSAGE.set_name ('XXCRM', 'XX_CDH_0015_INVD_BATCH');
      
     lc_message := fnd_message.get;

     
     LOG_EXCEPTION(
                      p_record_control_id      => NULL 
                     ,p_procedure_name         => 'SOLAR_TASKS_MAIN'
                     ,p_staging_table_name     => NULL
                     ,p_staging_column_name    => NULL
                     ,p_staging_column_value   => NULL
                     ,p_batch_id               => NULL
                     ,p_exception_log          => 'Solar Tasks : Batch ID is NULL'
                     ,p_source_system_code     => NULL
                     ,p_source_system_ref      => NULL
                     ,p_oracle_error_code      => 0015
                     ,p_oracle_error_msg       => lc_message
                  );
                  
    x_retcode := 2;
    
    x_errbuf  := lc_message;
                  
     
   
  WHEN OTHERS 
  THEN
  
    ROLLBACK;
    
    FND_MESSAGE.set_name ('XXCRM', 'XX_CDH_0016_UNEXPECTED_ERR');
    FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
    FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);
    
    lc_message := FND_MESSAGE.get;
    
    LOG_EXCEPTION(
                     p_record_control_id       => NULL 
                    ,p_procedure_name          => 'SOLAR_TASKS_MAIN'
                    ,p_staging_table_name      => NULL
                    ,p_staging_column_name     => NULL
                    ,p_staging_column_value    => NULL
                    ,p_batch_id                => ln_batch_id
                    ,p_exception_log           => 'Solar Tasks : Unexpected Error'
                    ,p_source_system_code      => NULL
                    ,p_source_system_ref       => NULL
                    ,p_oracle_error_code       => SQLCODE
                    ,p_oracle_error_msg        => lc_message
                 );
                 
    x_retcode := 2;
    
    x_errbuf  := lc_message;
    
    
   
END SOLAR_TASKS_MAIN;


END XX_CDH_SOLAR_TASKS_PKG;
/

SHOW ERRORS;    