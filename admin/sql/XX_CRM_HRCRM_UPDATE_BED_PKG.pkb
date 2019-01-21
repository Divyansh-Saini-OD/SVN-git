SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT 'Creating XX_CRM_HRCRM_UPDATE_BED_PKG package body'
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_CRM_HRCRM_UPDATE_BED_PKG
  -- +====================================================================================+
  -- |                  Office Depot - Project Simplify                                   |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                        |
  -- +====================================================================================+
  -- |                                                                                    |
  -- | Name             :  XX_CRM_HRCRM_UPDATE_BED_PKG                                    |
  -- | Description      :  This custom package is needed to update the attribute14 to null|
  -- |                     that was populated by the HRCRM program                        |
  -- |                                                                                    |
  -- |                                                                                    |
  -- | Change Record:                                                                     |
  -- |===============                                                                     |
  -- |Version   Date        Author           Remarks                                      |
  -- |=======   ==========  =============    =============================================|
  -- |Draft 1a  10-Jun-08   Gowri Nagarajan  Initial draft version                        |
  -- +====================================================================================+
IS
   ----------------------------
   --Declaring Global Constants
   ----------------------------
   GC_APPN_NAME                CONSTANT VARCHAR2(30):= 'XXCRM';
   GC_PROGRAM_TYPE             CONSTANT VARCHAR2(40):= 'E1002_HR_CRM_Synchronization';
   GC_MODULE_NAME              CONSTANT VARCHAR2(30):= 'TM';
   GC_ERROR_STATUS             CONSTANT VARCHAR2(30):= 'ACTIVE';
   GC_NOTIFY_FLAG              CONSTANT VARCHAR2(1) :=  'Y';

   -- ---------------------------
   -- Global Variable Declaration
   -- ---------------------------
   
   gn_biz_grp_id               NUMBER      := FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID')   ;
   gc_conc_prg_id              NUMBER                    DEFAULT   -1                      ;



   -- +===================================================================+
   -- | Name  : WRITE_LOG                                                 |
   -- |                                                                   |
   -- | Description:       This Procedure shall write to the concurrent   |
   -- |                    program log.                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE WRITE_LOG (p_message IN VARCHAR2)

   IS

      lc_error_message VARCHAR2(2000);

   BEGIN

      fnd_file.put_line(fnd_file.log,p_message);      

   EXCEPTION

      WHEN OTHERS THEN
      lc_error_message := 'Unexpected error during log ' || SQLERRM;
      fnd_file.put_line(fnd_file.log,lc_error_message);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_UPDATE_BED_PKG.WRITE_LOG'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_UPDATE_BED_PKG.WRITE_LOG'
                                  ,p_error_message_code      => NULL
                                  ,p_error_message           => lc_error_message
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );

   END; 

   -- +===================================================================+
   -- | Name  : WRITE_OUT                                                 |
   -- |                                                                   |
   -- | Description:       This Procedure shall write to the concurrent   |
   -- |                    program output.                                |
   -- |                                                                   |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE WRITE_OUT (p_message IN VARCHAR2)
   IS

      lc_error_message  varchar2(2000);

   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);      

   EXCEPTION

      WHEN OTHERS THEN
      lc_error_message := 'Unexpected error when writing output ' || SQLERRM;
      fnd_file.put_line(fnd_file.log,lc_error_message);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_UPDATE_BED_PKG.WRITE_OUT'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_UPDATE_BED_PKG.WRITE_OUT'
                                  ,p_error_message_code      => NULL
                                  ,p_error_message           => lc_error_message
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );
   END;
  
   -- +===================================================================+
   -- | Name  : MAIN                                                      |
   -- |                                                                   |
   -- | Description:       This is the public procedure.The concurrent    |
   -- |                    program OD:CRM HRCRM Update BED Program        |
   -- |                    will call this public procedure                |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE MAIN
                 (x_errbuf       OUT VARCHAR2
                 ,x_retcode      OUT NUMBER
                 ,p_person_id    IN  NUMBER                
                 )
   IS            
     ln_count NUMBER :=0;       
        
   -- ---------------------------
   -- Begin of the MAIN procedure
   -- ---------------------------

   BEGIN

       fnd_msg_pub.initialize;

       gc_conc_prg_id := FND_GLOBAL.CONC_REQUEST_ID;

       -- --------------------------------------
       -- DISPLAY PROJECT NAME AND PROGRAM NAME
       -- --------------------------------------

       WRITE_LOG(RPAD('Office Depot',50)||'Date: '||trunc(SYSDATE));
       WRITE_LOG(RPAD(' ',76,'-'));
       WRITE_LOG(LPAD('OD:CRM HRCRM Update BED Program',52));
       WRITE_LOG(RPAD(' ',76,'-'));
       WRITE_LOG('');
       WRITE_LOG('Input Parameters ');
       WRITE_LOG('Person Id : '||p_person_id);
       WRITE_LOG('As-Of-Date: '||SYSDATE);


       WRITE_OUT(RPAD(' Office Depot',64)||LPAD(' Date: '||trunc(SYSDATE),16));
       WRITE_OUT(RPAD(' ',80,'-'));
       WRITE_OUT(LPAD('OD:CRM HRCRM Update BED Program',50));
       WRITE_OUT(RPAD(' ',80,'-'));
       WRITE_OUT('');      
              

       -- -----------------------------------
       -- Update the Attribute14(BED) to Null
       -- -----------------------------------
       
       UPDATE jtf_rs_role_relations 
       SET    attribute14 = NULL 
       WHERE  role_resource_id IN 
      			(SELECT  JRRR.role_resource_id 
      			 FROM    jtf_rs_role_relations  JRRR 
      			        ,jtf_rs_group_members   JRGM 
      			 WHERE   JRRR.attribute14 IS NOT NULL 
      			 AND     JRRR.role_resource_type = 'RS_GROUP_MEMBER' 
      			 AND     JRRR.role_resource_id   = JRGM.group_member_id 
      			 AND     JRRR.role_id IN 
      					      (SELECT role_id 
      					       FROM   jtf_rs_roles_vl JRRV 
      					       WHERE  JRRV.role_type_code IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST') 
      					      ) 
      			 AND    NVL(JRRR.attribute15,'N') <> 'CLEANUP' 
      			 AND    JRGM.group_id IN 
      						(SELECT group_id 
      						 FROM   jtf_rs_group_usages 
      						 WHERE  usage IN ('SALES_COMP','COMP_PAYMENT','SALES') 
      						) 
      			 AND    JRRR.delete_flag           = 'N' 
      			 AND    JRGM.delete_flag           = 'N' 
      			 AND    JRGM.resource_id IN 
      						 (SELECT JRRE.resource_id 
      						  FROM 
      							(SELECT   PAAF.person_id      PERSON_ID 
      								, PAAF.ass_attribute9 
      								, PAAF.supervisor_id 
      								, PAAF.business_group_id 
      							 FROM   ( SELECT * 
      								  FROM per_all_assignments_f p1 
      								  WHERE  trunc(SYSDATE) BETWEEN p1.effective_start_date 
      								  AND  DECODE( 
      									     (SELECT  system_person_type 
      									      FROM    per_person_type_usages_f p 
      										    , per_person_types         ppt 
      									      WHERE   TRUNC(SYSDATE) BETWEEN p.effective_start_date AND p.effective_end_date 
      									      AND     PPT. person_type_id   =  p.person_type_id 
      									      AND     p.person_id           =  p1.person_id 
      									      AND     PPT.business_group_id =  gn_biz_grp_id), 
      									      'EX_EMP',TRUNC(SYSDATE),'EMP', p1.effective_end_date) 
      								) PAAF 
      							      , ( SELECT * 
      								  FROM per_all_people_f p 
      								  WHERE  SYSDATE BETWEEN p.effective_start_date AND p.effective_end_date 
      								) PAPF 
      							       ,  per_person_types         PPT 
      							       , (SELECT * 
      								  FROM per_person_type_usages_f p 
      								  WHERE SYSDATE BETWEEN p.effective_start_date AND p.effective_end_date) PPTU 
      							 WHERE    PAAF.person_id               = PAPF.person_id 
      							 AND      PAPF.person_id               = PPTU.person_id 
      							 AND      PPT. person_type_id          = PPTU.person_type_id 
      							 AND     (PPT.system_person_type       = 'EMP' 
      							 OR       PPT.system_person_type       = 'EX_EMP') 
      							 AND      PAAF.business_group_id       = gn_biz_grp_id 
      							 AND      PAPF.business_group_id       = gn_biz_grp_id 
      							 AND      PPT .business_group_id       = gn_biz_grp_id 
      							 CONNECT BY PRIOR PAAF.person_id       = PAAF.supervisor_id 
      							 START WITH     PAAF.person_id         = p_person_id
      							 ) t 
      							, jtf_rs_resource_extns_vl  JRRE 
      						      WHERE t.person_id = JRRE.source_id 
      							  ) 
      );    
      
      ln_count := SQL%ROWCOUNT;
      
      COMMIT;
	      
      WRITE_OUT((RPAD(' '||'Number of records updated',27))||' '||' : '||ln_count);
	      
   EXCEPTION  

   WHEN OTHERS THEN
      x_errbuf  := 'Completed with errors,  '||SQLERRM ;
      x_retcode := 2 ;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_UPDATE_BED_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_UPDATE_BED_PKG.MAIN'
                            ,p_error_message_code      => NULL
                            ,p_error_message           => x_errbuf
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );                            
                     

   END MAIN;

END XX_CRM_HRCRM_UPDATE_BED_PKG;
/

SHOW ERRORS

EXIT
