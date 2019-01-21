SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_SOLAR_ACTIVITIES_PKG
AS
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                     Wipro Technologies                                |
-- +=======================================================================+
-- | Name             :XX_CDH_SOLAR_ACTIVITIES_PKG.pkb                     |
-- | Rice ID          :Load SOLAR ACTIVITIES into Oracle Common View       |
-- | Description      :This package contains procedure to load activities  |
-- |                   from Image table to CDH Common view table           |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      25-Mar-2008 Rizwan A           Initial version                |
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
    lc_package_name           VARCHAR2(32)  := 'XX_CDH_SOLAR_ACTIVITIES_PKG';
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
-- | Name             : SOLAR_ACTIVITIES_MAIN                              |
-- | Description      : This procedure is used to load the activities from |
-- |                    Image table to oracle Common view table            |
-- |                                                                       |
-- | Parameters       : Name          IN/OUT  Data Type   Description      |
-- |                                                                       |
-- |                    x_errbuf      OUT     VARCHAR2    Error Description|
-- |                    x_retcode     OUT     NUMBER      Error Number     |
-- |                    p_conv_grp_id IN      VARCHAR2    W/N/S/C group    |
-- |                    p_run         IN      VARCHAR2    Yes/No           |
-- |                                                                       |
-- +=======================================================================+
PROCEDURE solar_activities_main (   x_errbuf              OUT NOCOPY VARCHAR2
                                   ,x_retcode             OUT NOCOPY NUMBER
                                   ,p_conv_grp_id         IN         VARCHAR2
                                   ,p_run                 IN         VARCHAR2
                                )
AS
ln_acvt_owner              VARCHAR2(100);
lc_acvt_type               xx_jtf_imp_tasks_int.task_type_name%TYPE;
lc_acvt_status             xx_jtf_imp_tasks_int.task_status_name%TYPE;
lc_acvt_subject            xx_jtf_imp_tasks_int.task_name%TYPE;
lc_created_by_module       CONSTANT VARCHAR2(10)          := 'XXSOLAR';
lc_interface_status        CONSTANT VARCHAR2(1)           := '1';
lc_insert_update_flag      CONSTANT VARCHAR2(1)           := 'I';
lc_process_name            CONSTANT VARCHAR2(20)          := 'SOLAR ACTIVITIES';
lc_package_name            CONSTANT VARCHAR2(100)         := 'XX_CDH_SOLAR_ACTIVITIES_PKG';
lc_procedure_name          CONSTANT VARCHAR2(100)         := 'SOLAR_ACTIVITIES_MAIN';
lc_party_site              CONSTANT VARCHAR2(40)          := 'OD_PARTY_SITE';
lc_party                   CONSTANT VARCHAR2(5)           := 'PARTY';
lc_source_system           CONSTANT VARCHAR2(2)           := 'S0';
lc_source_system_code      CONSTANT VARCHAR2(6)           := 'SOLAR';
lc_object_code             VARCHAR2(240);
lc_obj_orig_system         VARCHAR2(240);
lc_obj_orig_system_ref     VARCHAR2(240);
ln_counter                 PLS_INTEGER;
lc_lookup_type             VARCHAR2(30)                   := 'XX_CRM_REV_BAND_TYPES';
ln_batch_id                NUMBER;
lc_batch_descr             VARCHAR2(1996);
lc_batch_name              VARCHAR2(255);
lc_batch_error_msg         VARCHAR2(2000);
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
lc_priority_name           VARCHAR2(40) := 'Medium';
CURSOR lcu_activities IS
SELECT  ACVT.INTERNID
	,ACVT.CHGDATE
	,ACVT.CHGTIME
	,ACVT.STAMP2
	,ACVT.STAMP2_VC
	,ACVT.ACT_DATE
	,ACVT.START_TIME
	,ACVT.END_TIME
	,ACVT.ACTV_TYPE
	,ACVT.ACTV_SUBJECT
	,ACVT.ACT_STATUS
	,ACVT.CONT_TYPE
	,ACVT.SP_CALL_OBJCTV
	,ACVT.SP_CALL_OBJCTV_PLAIN
	,ACVT.CALL_SUMMARY
	,ACVT.REC_CREA_DT
	,ACVT.REC_CREA_BY
	,ACVT.REC_CHNG_DT
	,ACVT.REC_CHNG_BY
	,ACVT.REC_CHNG_TIME
	,XCSS.SITE_TYPE
	,XCSS.ID
	,XCSS.NAME
	,XCSS.ADDR1
	,XCSS.STATE
	,XCSS.COUNTRY
	,XCSS.ALT_ADDR1
	,XCSS.ALT_STATE
	,XCSS.ALT_COUNTRY
	--,UPPER(P_CONV_GRP_ID)
	,XCSS.CONVERSION_REP_ID
   FROM XXCNV.xx_cdh_solar_activities_image ACVT
       ,XXCNV.xx_cdh_solar_siteimage    XCSS
  WHERE  ACVT.internid = XCSS.internid
  AND    XCSS.site_type IN ('PROSPECT','TARGET','SHIPTO')
  AND    EXISTS (  SELECT 1
		   FROM   fnd_lookup_values FLV
		   WHERE  FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
		   AND    FLV.enabled_flag = 'Y'
		   AND    FLV.language     = 'US'
		   AND    FLV.lookup_code  = UPPER(XCSS.rev_band)
		   AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE - 1)
					      AND NVL(FLV.end_date_active,SYSDATE + 1)
		 )
  AND    EXISTS  (  SELECT 1
		     FROM   xx_cdh_solar_conversion_group XCSCG
		     WHERE  XCSCG.conversion_group_id = UPPER(p_conv_grp_id)
		     AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id
		     AND    XCSCG.validate_status     ='OK'
		     AND   ( SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE)
						       AND NVL(XCSCG.end_date_active,SYSDATE + 1 ))
		 )
  AND XCSS.status ='ACTIVE';
BEGIN
    FND_FILE.PUT_LINE (FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE (FND_FILE.LOG
         ,  RPAD ('Office DEPOT', 40, ' ')
         || LPAD ('DATE: ', 30, ' ')
         || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
         );
    FND_FILE.PUT_LINE (FND_FILE.LOG
         ,LPAD ('OD: SOLAR load ACTIVITIES to CV tables', 53, ' ')
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
    FOR  lr_activities in lcu_activities
    LOOP
            lc_object_code         := NULL;
            lc_obj_orig_system     := NULL;
            lc_obj_orig_system_ref := NULL;
            lc_insert_flag         := 'Y';
	    ----------------------------------------------------------------------
	    ---                      GENERATE OSR                              ---
	    ----------------------------------------------------------------------
	    IF lr_activities.site_type IN ('PROSPECT','TARGET')
            THEN
	      lc_obj_orig_system_ref := LPAD(lr_activities.internid,10,'0') || '-00001-S0';
              lc_object_code := lc_party;
              lc_obj_orig_system := 'S0';
            ELSIF lr_activities.site_type ='SHIPTO'
            THEN
              lc_object_code := lc_party_site;
              lc_obj_orig_system := 'A0';
              lc_obj_orig_system_ref := SUBSTR(lr_activities.id,1,8) || '-' || SUBSTR(lr_activities.id,9,5) || '-A0';
             END IF;
             ln_counter := ln_counter+1;
	     ----------------------------------------------------------------------
	     ---                      ACTIVITY OWNER                            ---
	     ----------------------------------------------------------------------
             ln_acvt_owner := NULL;
            BEGIN
            
	    SELECT SP_ID_NEW 
 	      INTO ln_acvt_owner
              FROM XXTPS.xxtps_sp_mapping
             WHERE EMPLOYEE_NUMBER = SUBSTR(lr_activities.rec_crea_by,2)
	       AND ROWNUM = 1;

	    EXCEPTION
            WHEN OTHERS THEN
              lc_insert_flag :='N';
              FND_FILE.PUT_LINE (FND_FILE.LOG,SQLERRM||SQLCODE);
              x_retcode :=1;
            END;
             IF ln_acvt_owner IS NULL
             THEN
               lc_insert_flag :='N';
               fnd_file.put_line (fnd_file.LOG ,'Oracle Resource ID is null for the Legacy user ' || lr_activities.REC_CREA_BY||'-'||lr_activities.internid );
             END IF;
             IF lc_insert_flag ='Y'
             THEN
	        ----------------------------------------------------------------------
	        ---                         SEQUENCE                               ---
	        ----------------------------------------------------------------------
                 SELECT xx_jtf_imp_tasks_int_s.NEXTVAL
                 INTO ln_record_id
                 FROM DUAL;
	        ----------------------------------------------------------------------
	        ---                      ACTIVITY TYPE                             ---
	        ----------------------------------------------------------------------
		BEGIN
		SELECT description
		  INTO lc_acvt_type
		 FROM fnd_common_lookups
		 WHERE lookup_type = 'XX_CDH_SOLAR_ACTIVITY_TYPES'
		   AND enabled_flag = 'Y'
		   AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE - 1)
		   AND NVL(end_date_active,SYSDATE + 1)
		   AND lookup_code= upper(lr_activities.actv_type);
                EXCEPTION
		WHEN OTHERS THEN
                   lc_acvt_type :='In Person Visit'; --'Business Review';
		END;
	        ----------------------------------------------------------------------
	        ---                      ACTIVITY STATUS                           ---
	        ----------------------------------------------------------------------
		BEGIN
		SELECT description
		  INTO lc_acvt_status
		 FROM fnd_common_lookups
		 WHERE lookup_type = 'XX_CDH_SOLAR_ACTIVITY_STATUS'
		   AND enabled_flag = 'Y'
		   AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE - 1)
		   AND NVL(end_date_active,SYSDATE + 1)
		   AND lookup_code= upper(lr_activities.act_status);
                EXCEPTION
		WHEN OTHERS THEN
                   lc_acvt_status :='';
		END;
	        ----------------------------------------------------------------------
	        ---                      ACTIVITY SUBJECT                          ---
	        ----------------------------------------------------------------------
                IF lr_activities.actv_subject IS NULL THEN
		   lc_acvt_subject :='Solar Activity';
		ELSE
		     BEGIN
			SELECT description
			  INTO lc_acvt_subject
			 FROM fnd_common_lookups
			 WHERE lookup_type = 'XX_CDH_SOLAR_ACTIVITY_SUBJECTS'
			   AND enabled_flag = 'Y'
			   AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE - 1)
			   AND NVL(end_date_active,SYSDATE + 1)
			   AND lookup_code= upper(lr_activities.actv_subject);
                     EXCEPTION
		     WHEN OTHERS THEN
 		         lc_acvt_subject :=lr_activities.actv_subject;
                     END;
		END IF;
		----------------------------------------------------------------------
	        ---              LOAD INTO INTERFACE TBL                           ---
	        ----------------------------------------------------------------------
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
                           --,scheduled_start_date --Not needed
                           ,scheduled_end_date
                           --,actual_end_date --Not needed
                           ,task_type_name
                           ,task_name
                           ,task_status_name
                           ,attribute15
                           ,created_by
                        )VALUES(
                           ln_batch_id
                          ,lc_created_by_module
                          ,SYSDATE
                          ,ln_record_id
                          ,lc_insert_update_flag
                          ,lc_interface_status
                          ,lc_obj_orig_system
                          ,lc_obj_orig_system_ref
                          ,lc_object_code
                          ,LPAD(lr_activities.internid,10,'0') || '-' || lr_activities.stamp2_vc
                          ,nvl(lr_activities.sp_call_objctv_plain,' ')
                          ,lc_priority_name
                          ,ln_acvt_owner
                          --,lr_task.create_date
                          ,lr_activities.act_date
                          --,lr_task.completed_dt
                          ,lc_acvt_type
                          ,lc_acvt_subject
                          ,lc_acvt_status
                          ,LPAD(lr_activities.internid,10,'0')|| '-' ||lr_activities.stamp2_vc
                          ,ln_created_by
                          );
	        ----------------------------------------------------------------------
	        ---              LOAD INTO INTERFACE REF TBL                       ---
	        ----------------------------------------------------------------------
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
                          ,lc_created_by_module
                          ,SYSDATE
                          ,ln_record_id
                          ,lc_insert_update_flag
                          ,lc_interface_status
                          ,LPAD(lr_activities.internid,10,'0') || '-' || lr_activities.stamp2_vc
                          ,LPAD(lr_activities.internid,10,'0') || '-' || lr_activities.stamp2_vc
                          ,lc_object_code
                          ,lc_obj_orig_system
                          ,lc_obj_orig_system_ref
                          ,'ACTIVITIES FROM SOLAR'
                          ,'S0'
                          ,ln_created_by);
         END IF; -- End of insert flag check
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
     fnd_file.put_line (fnd_file.LOG ,'Execution of Program OD: Load SOLAR Activities to CV tables Skipped'  );
     fnd_file.put_line (fnd_file.LOG ,' ');
  WHEN  EXP_BATCH_ID_INVLD
  THEN
     ROLLBACK;
     FND_MESSAGE.set_name ('XXCRM', 'XX_CDH_0015_INVD_BATCH');
     lc_message := fnd_message.get;
     LOG_EXCEPTION(
                      p_record_control_id      => NULL
                     ,p_procedure_name         => 'SOLAR_ACTIVITIES_MAIN'
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
                    ,p_procedure_name          => 'SOLAR_ACTIVITIES_MAIN'
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
END SOLAR_ACTIVITIES_MAIN;
END XX_CDH_SOLAR_ACTIVITIES_PKG;

/

SHOW ERRORS;    