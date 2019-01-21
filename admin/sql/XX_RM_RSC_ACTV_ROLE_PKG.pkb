SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

 CREATE OR REPLACE PACKAGE BODY XX_RM_RSC_ACTV_ROLE_PKG
 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             : XX_RM_RSC_ACTV_ROLE_PKG                                           |
 -- | Description      : This program is for querying and detailing the Luis program.      |
 -- |                                                                                      | 
 -- |                                                                                      |
 -- | This package contains the following sub programs:                                    |
 -- | =================================================                                    |
 -- |Type         Name                  Description                                        |
 -- |=========    ===========           ================================================   |
 -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and display |
 -- |                                   the  resource details with active sales role.      |
 -- |                                           .                                          |
 -- |Change Record:                                                                        |
 -- |===============                                                                       |
 -- |Version   Date         Author           Remarks                                       |
 -- |=======   ==========   =============    ============================================= |
 -- |Draft 1a  01-JUL-2008  Satyasrinivas    Initial draft version                         |
 -- +===================================================================================== +

 AS
 
     -- +====================================================================+
     -- | Name        :  display_log                                         |
     -- | Description :  This procedure is invoked to print in the log file  |
     -- |                                                                    |
     -- | Parameters  :  Log Message                                         |
     -- +====================================================================+
 
     PROCEDURE display_log(
                           p_message IN VARCHAR2
                          )
 
     IS
 
     BEGIN
 
          FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
 
    END display_log;
    
        -- +====================================================================+
        -- | Name        :  display_out                                         |
        -- | Description :  This procedure is invoked to print in the output    |
        -- |                file                                                |
        -- |                                                                    |
        -- | Parameters  :  Log Message                                         |
        -- +====================================================================+
    
        PROCEDURE display_out(
                              p_message IN VARCHAR2
                             )
    
        IS
    
        BEGIN
    
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
    
        END display_out;
        
        
        
        -- +====================================================================+
        -- | Name        :  Main_Proc                                           |
        -- | Description :  This is the Main Procedure  invoked by the          |
        -- |                Concurrent Program                                  |
        -- |                file                                                |
        -- |                                                                    |
        -- | Parameters  :  Log Message                                         |
        -- +====================================================================+
        
        
        PROCEDURE Main_Proc (
	                      x_errbuf           OUT VARCHAR2
	                    , x_retcode          OUT NUMBER
                            )
                    
        IS
  
               
        Cursor C_RSC_ACTIV_ROL 
        IS
       select 
        JRRE.source_name
       ,JRRDV.ROLE_NAME 
       ,JRRDV.admin_flag
       ,JRRDV.manager_flag
       ,JRRDV.member_flag
       ,JRGV.GROUP_NAME
       ,JRRR.attribute15 
       ,jrrdv.attribute15 division
       ,jrrdv.attribute14
       from 
        jtf_rs_role_relations JRRR
       ,jtf_rs_resource_extns JRRE
       ,jtf_rs_group_members JRGM
       ,jtf_rs_groups_vl JRGV
       ,jtf_rs_salesreps JRSR
       ,jtf_rs_role_details_vl JRRDV
       where
        JRRR.role_resource_id = jrgm.group_member_id 
        and JRGM.resource_id = JRRE.resource_id 
        and JRGV.group_id = JRGM.group_id 
        and JRSR.resource_id = JRRE.resource_id 
        and JRRR.role_id = JRRDV.role_id
        and JRRDV.role_type_code = 'SALES'
	and nvl(jrgm.delete_flag,'N') ='N'
	and jrsr.org_id = fnd_profile.value('ORG_ID')
	and sysdate between jrrr.START_DATE_ACTIVE and nvl(jrrr.end_date_active,sysdate);
        
      

        BEGIN
        
        x_retcode := 0;
       
              display_out(
                          RPAD(' Sales Person Name',50)||chr(9)
                        ||RPAD(' Sales Person Role',25)||chr(9)
                        ||RPAD(' Admin Flag',15)||chr(9)
                        ||RPAD(' Manager Flag',15)||chr(9)
                        ||RPAD(' Member Flag',15)||chr(9)
                        ||RPAD(' Group',25)||chr(9)
                        ||RPAD(' Legacy Rep Id',30)||chr(9)
                        ||RPAD(' Division',25)||chr(9)
                        ||RPAD(' Role Type',30)||chr(9)
                        );
                        
                OPEN  C_RSC_ACTIV_ROL;
                FETCH C_RSC_ACTIV_ROL BULK COLLECT INTO ln_res_act_tbl_type;
                CLOSE C_RSC_ACTIV_ROL;  
                
                IF ln_res_act_tbl_type.count > 0 THEN
                      --display_log('Displaying the sales person details in the out file')
                     FOR i IN ln_res_act_tbl_type.FIRST.. ln_res_act_tbl_type.LAST
                        LOOP
         
                           display_out(' '
                                     ||RPAD(NVL(ln_res_act_tbl_type(i).source_name,'(null)'),50)||chr(9)
                                     ||RPAD(ln_res_act_tbl_type(i).role_name,25)||chr(9)
                                     ||RPAD(NVL(ln_res_act_tbl_type(i).admin_flag,'(null)'),15)||chr(9)
                                     ||RPAD(NVL(ln_res_act_tbl_type(i).manager_flag,'(null)'),15)||chr(9)
                                     ||RPAD(NVL(ln_res_act_tbl_type(i).member_flag,'(null)'),15)||chr(9)
                                     ||RPAD(ln_res_act_tbl_type(i).group_name,25)||chr(9)
                                     ||RPAD(NVL(ln_res_act_tbl_type(i).attribute15,'(null)'),30)||chr(9)
                                     ||RPAD(NVL(ln_res_act_tbl_type(i).division,'(null)'),25)||chr(9)
                                     ||RPAD(NVL(ln_res_act_tbl_type(i).attribute14,'(null)'),30)||chr(9)
                                      );
                   
                        END LOOP;
                END IF;
           
         
           EXCEPTION WHEN OTHERS THEN
                 x_retcode := 2;
                 x_errbuf  := SUBSTR('Unexpected error occurred.Error:'||SQLERRM,1,255);
                 XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                 P_PROGRAM_TYPE            => 'CONCURRENT PROGRAM'
                                                ,P_PROGRAM_NAME            => 'XX_RM_RSC_ACTV_ROLE_PKG.MAIN_PROC'
                                                ,P_PROGRAM_ID              => NULL
                                                ,P_MODULE_NAME             => 'CN'
                                                ,P_ERROR_LOCATION          => 'WHEN OTHERS EXCEPTION'
                                                ,P_ERROR_MESSAGE_COUNT     => NULL
                                                ,P_ERROR_MESSAGE_CODE      => x_retcode
                                                ,P_ERROR_MESSAGE           => x_errbuf
                                                ,P_ERROR_MESSAGE_SEVERITY  => 'MAJOR'
                                                ,P_NOTIFY_FLAG             => 'Y'
                                                ,P_OBJECT_TYPE             => 'Luis Program report'
                                                ,P_OBJECT_ID               => NULL
                                                ,P_ATTRIBUTE1              => NULL
                                                ,P_ATTRIBUTE3              => NULL
                                                ,P_RETURN_CODE             => NULL
                                                ,P_MSG_COUNT               => NULL
                                               );
       END MAIN_PROC;       
       END XX_RM_RSC_ACTV_ROLE_PKG;       
/       
SHOW ERRORS;     
       
     -- EXIT;
       
       REM============================================================================================
       REM                                   End Of Script                                            
       REM============================================================================================    