SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_TM_INSERT_TPS_STG_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_INSERT_TPS_STG_PKG.pkb                                              |
-- | Description : Package Body to insert records in the TOPS staging table for Re-assignment|
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   25-Jul-2008       Piyush Khandelwal   Initial draft version                   |
-- |DRAFT 1b   13-Mar-2009       Kishore Jena        Changed main query to select party site |
-- |                                                 creation/re-activation date as request  |
-- |                                                 effective date if it is later than      |
-- |                                                 original request effective date.        | 
-- |V2	       02-Aug-2011	     Satish Silveri	     fix for defect 13001		             |
-- |Ver3.0     07-Jan-2015       Pooja Mehra		 Modified main_proc to pick up OMX sites |
-- |												 as well.								 |					
-- +=========================================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------
G_ERRBUF     VARCHAR2(2000);
G_LAST_UPDATE_DATE          DATE            := SYSDATE;
G_LAST_UPDATED_BY           PLS_INTEGER     := FND_GLOBAL.USER_ID;
G_CREATION_DATE             DATE            := SYSDATE;
G_CREATED_BY                PLS_INTEGER     := FND_GLOBAL.USER_ID;
G_LAST_UPDATE_LOGIN         PLS_INTEGER     := FND_GLOBAL.LOGIN_ID;
G_PROG_APPL_ID              PLS_INTEGER     := FND_GLOBAL.PROG_APPL_ID;
G_REQUEST_ID                PLS_INTEGER     := FND_GLOBAL.CONC_REQUEST_ID;


-- +================================================================================+
-- | Name        :  Log_Exception                                                   |
-- | Description :  This procedure is used to log any exceptions raised using custom|
-- |                Error Handling Framework                                        |
-- +================================================================================+
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;

BEGIN

  XX_COM_ERROR_LOG_PUB.log_error_crm
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XXCRM'
     ,p_program_type            => 'Insert Program For TOPS Staging'
     ,p_program_name            => 'XX_TM_INSERT_TPS_STG_PKG.main_proc'
     ,p_module_name             => 'TM'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     ,p_program_id              => G_REQUEST_ID
     );

END Log_Exception;

--------------------------------------------------------------------------------------------
  -- Procedure registered as Concurrent program to perform the reassignment of resource,role --
  -- and group on the basis of territory ID                                              --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_PROC(X_ERRBUF  OUT NOCOPY VARCHAR2,
                      X_RETCODE OUT NOCOPY NUMBER
                      )
  -- +===================================================================+
    -- | Name       : MAIN_PROC                                            |
    -- | Description: *** See above ***                                    |
    -- |                                                                   |
    -- | Parameters : No Input Parameters                                  |
    -- |                                                                   |
    -- | Returns    : Standard Out parameters of a concurrent program      |
    -- |                                                                   |
    -- +===================================================================+
   IS
    lc_error_code       VARCHAR2(10)  ;
    lc_error_message    VARCHAR2(4000);
    ln_record_id        NUMBER := 0;
    lc_from_resource_id NUMBER := 0;
    lc_from_role_id     NUMBER := 0;
    lc_from_group_id    NUMBER := 0;
    lc_party_type       VARCHAR(10);
    lc_status           VARCHAR(40) ;
    lc_status_message   VARCHAR(4000) ;
    lc_flag             VARCHAR(1) := Null ;
    lc_from_division VARCHAR2(100) ;
    lc_to_division   VARCHAR2(100);
    ln_counter          NUMBER;
    ln_total_rec_cnt    NUMBER := 0;
    ln_total_err_cnt    NUMBER := 0;
    ln_total_retro_cnt  NUMBER :=0;
    ln_total_normal_cnt NUMBER :=0; 
   

    -- Cursor to fetch records from TOPS table

     CURSOR   LCU_GET_TPS_REC IS
     SELECT   TSR.site_request_id,
              TSR.creation_date,
              TSR.created_by,
              TSR.last_update_date,
              TSR.last_updated_by,
              TSR.program_application_id,
              TSR.program_id,
              TSR.program_update_date,
              TSR.request_id,
              TSR.goal_id,
              TSR.to_resource_id,
              TSR.to_role_id,
              TSR.to_group_id,
              TSR.party_site_id,
              TSR.request_reason_code,
              TSR.request_reason,
              -- Changed for party sites re-activated/created later than request effective date
              -- TSR.effective_date
              GREATEST(TSR.effective_date, 
                       (select NVL(MIN(TNT.start_date_active), TSR.effective_date)
                        FROM   apps.XX_TM_NAM_TERR_HISTORY_DTLS TNT
                        WHERE  TNT.party_site_id = TSR.party_site_id
                       )
                      ) effective_date,
              TSR.request_status_code,
              TSR.review_completion_method,
              TSR.review_completion_date,
              TSR.reject_reason_code,
              TSR.reject_reason,
              TSR.direction_code,
              TSR.territory_iface_date,
              TSR.from_resource_id,
              TSR.from_role_id,
              TSR.from_group_id,
              TSR.bulk_request_id,
              TSR.terr_rec_id,
              TSR.previous_site_request_id
     FROM     apps.xxtps_site_requests TSR
     WHERE    TSR.request_status_code = 'QUEUED'
     AND      trunc(TSR.effective_date) <= trunc(sysdate);
     --AND      trunc(tsr.creation_date) = trunc(sysdate);
     
     -- Cursor to fetch Division

     CURSOR lcu_division(p_resource_id IN NUMBER, p_role_id IN NUMBER, p_group_id IN NUMBER,p_effective_date IN DATE) IS

     SELECT jrrb.attribute15
     FROM  jtf_rs_group_members jrgm,
             jtf_rs_roles_b jrrb,
           jtf_rs_role_relations jrrr
     WHERE jrgm.resourcE_id = p_resource_id
     AND   jrgm.group_id = p_group_id
     AND   NVL(jrgm.delete_flag,'N') ='N'
     AND   jrgm.group_member_id = jrrr.role_resourcE_id
    -- AND   p_effective_date between jrrr.start_date_active and NVL(jrrr.end_date_active,sysdate)
     AND   jrrr.role_id = p_role_id
     AND   jrrb.role_id = jrrr.role_id;
     
     -- Cursor to fetch Division based on resource,role and group

     CURSOR lcu_to_division(p_resource_id IN NUMBER, 
                         p_role_id IN NUMBER, 
                         p_group_id IN NUMBER,
                         p_effective_date IN DATE) IS
     select * from (  -- fix for defect 13001
     SELECT jrrb.attribute15, jrrr.start_date_active, nvl(jrrr.end_date_active,sysdate) end_date_active
     FROM  jtf_rs_group_members jrgm,
             jtf_rs_roles_b jrrb,
           jtf_rs_role_relations jrrr
     WHERE jrgm.resourcE_id = p_resource_id
     AND   jrgm.group_id = p_group_id
     AND   NVL(jrgm.delete_flag,'N') ='N'
     AND   jrgm.group_member_id = jrrr.role_resourcE_id
     --AND   p_effective_date between jrrr.start_date_active and NVL(jrrr.end_date_active,sysdate)
     AND   jrrr.role_id = p_role_id
     AND   jrrb.role_id = jrrr.role_id
     ORDER BY nvl(jrrr.end_date_active,sysdate) DESC -- fix for defect 13001
     ) where rownum = 1 ; -- fix for defect 13001

     -- Cursor to fetch Division based on resource, role

     CURSOR lcu_division_resrole(p_resource_id IN NUMBER, 
                         p_role_id IN NUMBER 
                         ) IS
     select * from (  -- fix for defect 13001
     SELECT jrrb.attribute15, jrrr.start_date_active, nvl(jrrr.end_date_active,sysdate) end_date_active
     FROM  jtf_rs_roles_b jrrb,
           jtf_rs_role_relations jrrr
     WHERE jrrr.role_resourcE_id = p_resource_id
     AND   NVL(jrrr.delete_flag,'N') ='N'
     AND   jrrr.role_id = p_role_id
     AND   jrrb.role_id = jrrr.role_id
     ORDER BY  nvl(jrrr.end_date_active,sysdate) DESC -- fix for defect 13001
     ) where rownum = 1 ; -- fix for defect 13001
     
     --Cursor to fetch fiscal month start date
     cursor lcu_fiscal_month ( p_date in date) is
     select 
     start_date 
     from 
     gl_periods
     where 
     period_type='41'
     and p_date between start_date and end_date;
     
     ld_res_grp_rol      date;
     ld_res_role         date;
     ld_effective        date;
     lc_to_division_rec lcu_to_division%rowtype;
     lc_div_resrole_rec lcu_division_resrole%rowtype;
     ld_default_fiscal   date:='30-dec-07';
     G_LEVEL_ID          number:=10001; 
     G_LEVEL_VALUE       number:=0;
     --Cursor to validate Prospect or Customer

     CURSOR  lcu_party_type ( p_party_site_id IN NUMBER) is
     SELECT  hp.attribute13
     FROM    hz_parties hp,
               hz_party_sites hps
     WHERE   hp.party_id = hps.party_id
     AND     hps.party_site_id = p_party_site_id
     AND     hp.status='A'
     AND     hps.status='A'
     AND     hp.party_type='ORGANIZATION';


     BEGIN
       ln_counter :=0;
       ln_total_err_cnt :=0;
       ln_total_retro_cnt :=0;
       ln_total_normal_cnt :=0;
      
   BEGIN
   
        SELECT to_date(FPOV.profile_option_value)
        INTO   ld_default_fiscal
        FROM   fnd_profile_option_values FPOV
               , fnd_profile_options FPO
        WHERE  FPO.profile_option_id = FPOV.profile_option_id
        AND    FPO.application_id = FPOV.application_id
        AND    FPOV.level_id = G_LEVEL_ID
        AND    FPOV.level_value = G_LEVEL_VALUE
        AND    FPOV.profile_option_value IS NOT NULL
        AND    FPO.profile_option_name = 'XX_TM_RETRO_FISCAL_START_DATE';
   
   EXCEPTION
      WHEN OTHERS THEN
          ld_default_fiscal := '30-dec-07';
          X_ERRBUF:='OD: TM Retro Default Fiscal Start Date isn''t setup';
          
          
   END;      
       --Main Loop
       FOR lr_blk_tps IN LCU_GET_TPS_REC LOOP
       
             
         ln_record_id        := 0;
         lc_flag             := 'Y';
         lc_from_resource_id := 0;
         lc_from_role_id     := 0;
         lc_from_group_id    := 0;
         lc_from_division    := null;
         lc_to_division      := null;
         lc_party_type       := null;
         lc_status := null;
         lc_status_message :=null;
         ld_res_grp_rol    :=null;
         ld_res_role       :=null;
         ld_effective      :=null;
         ln_counter :=ln_counter+1;

         SELECT XXCRM.XX_CRM_TPS_Record_Id_S.nextval
         INTO ln_record_id
         FROM dual;
         --FND_FILE.PUT_LINE(FND_FILE.LOG,lr_blk_tps.FROM_RESOURCE_ID ||'   '||
         --                               lr_blk_tps.FROM_ROLE_ID||'   '||
         --                               lr_blk_tps.FROM_GROUP_ID||'   '||
         --                               lr_blk_tps.EFFECTIVE_DATE);
         -- Change validationn from effective date to sysdate
         OPEN lcu_division(
                         lr_blk_tps.FROM_RESOURCE_ID
                        ,lr_blk_tps.FROM_ROLE_ID
                        ,lr_blk_tps.FROM_GROUP_ID
                        ,trunc(sysdate));
                        --,lr_blk_tps.EFFECTIVE_DATE);
         FETCH lcu_division INTO lc_from_division;
         --FND_FILE.PUT_LINE(FND_FILE.LOG,lc_from_division);
         IF lc_from_division is NULL THEN
         
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0267_FRM_DIV_NT_EXIST');
            lc_flag := 'N';
            lc_status := null;
            lc_status := 'ERROR';
            lc_status_message:= FND_MESSAGE.GET;

            Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                           ,p_error_message_code =>  lc_status
                           ,p_error_msg          =>  lc_status_message
                           );

         END IF;
         CLOSE lcu_division;
        
         IF lc_flag = 'Y' THEN

           OPEN lcu_to_division(
                            lr_blk_tps.TO_RESOURCE_ID
                           ,lr_blk_tps.TO_ROLE_ID
                           ,lr_blk_tps.TO_GROUP_ID
                           ,lr_blk_tps.EFFECTIVE_DATE);

           FETCH lcu_to_division INTO lc_to_division_rec;


           IF lc_to_division_rec.attribute15 is null THEN

             FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0268_TO_DIV_NT_EXIST');
             lc_flag := 'N';
             lc_status := null;
             lc_status := 'ERROR';
             lc_status_message:= FND_MESSAGE.GET;

             Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                            ,p_error_message_code =>  lc_status
                            ,p_error_msg          =>  lc_status_message
                           );
           ELSE -- Added for new changes
              --Fiscal date based on the Resource,role and group combination
              OPEN lcu_fiscal_month(p_date => lc_to_division_rec.start_date_active);
              FETCH lcu_fiscal_month INTO ld_res_grp_rol;
              CLOSE lcu_fiscal_month;
              
              IF ld_res_grp_rol IS NULL THEN 
              ld_res_grp_rol:= ld_default_fiscal;
              END IF;
              
              --Fiscal date based on the effective date
              OPEN lcu_fiscal_month(p_date => lr_blk_tps.EFFECTIVE_DATE);
              FETCH lcu_fiscal_month INTO ld_effective;
              CLOSE lcu_fiscal_month;
              -- Resource, role and group combination validation  
              -- fiscal month start date for effective date and 
              -- Resource, role and group start date
             
              IF (trunc(lr_blk_tps.EFFECTIVE_DATE) 
              BETWEEN trunc(lc_to_division_rec.start_date_active) 
              AND  trunc(lc_to_division_rec.end_date_active) )                
              OR
              (ld_res_grp_rol=ld_effective) 
              THEN
              APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                    ' Site Request Id'||trunc(lr_blk_tps.site_request_id)||
                                    ' effective date'||trunc(lr_blk_tps.EFFECTIVE_DATE)||
                                    ' Res-Grp-Rol Start date'||trunc(lc_to_division_rec.start_date_active)||
                                    ' End date'||trunc(lc_to_division_rec.end_date_active)||
                                    ' Res-Grp-Rol Fiscal month '||ld_res_grp_rol||
                                    ' Effective Date Fiscal month '||ld_effective);
              lc_to_division:=lc_to_division_rec.attribute15;
              
              ELSE
                --Retriving resource role dtls 
                OPEN lcu_division_resrole(p_resource_id => lr_blk_tps.TO_RESOURCE_ID,
                                          p_role_id     => lr_blk_tps.TO_ROLE_ID);
                
                FETCH lcu_division_resrole INTO lc_div_resrole_rec;
                CLOSE lcu_division_resrole;
                
                --Fiscal date based on the Resource and role combination
                OPEN lcu_fiscal_month(p_date => lc_div_resrole_rec.start_date_active);
                FETCH lcu_fiscal_month INTO ld_res_role;
                CLOSE lcu_fiscal_month;

                IF ld_res_role IS NULL THEN 
                ld_res_role:= ld_default_fiscal;
                END IF;
                
                -- Resource and role combination validation  
                -- fiscal month start date for effective date and 
                -- Resource and role combination 
                APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                    ' Site Request Id'||lr_blk_tps.site_request_id||
                                    ' effective date'||trunc(lr_blk_tps.EFFECTIVE_DATE)||
                                    ' Res-Rol Start date'||trunc(lc_div_resrole_rec.start_date_active)||
                                    ' End date'||trunc(lc_div_resrole_rec.end_date_active)||
                                    ' Effective date fiscal month '||ld_effective ||
                                    ' Res-Rol fiscal month '||ld_res_role);
                IF (trunc(lr_blk_tps.EFFECTIVE_DATE) 
                BETWEEN trunc(lc_div_resrole_rec.start_date_active) 
                AND  trunc(lc_div_resrole_rec.end_date_active) )  then 
                APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,' first condition');
                elsif  (  ld_res_role=ld_effective ) THEN 
                APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,' second condition');
                end if;
                IF (trunc(lr_blk_tps.EFFECTIVE_DATE) 
                BETWEEN trunc(lc_div_resrole_rec.start_date_active) 
                AND  trunc(lc_div_resrole_rec.end_date_active) )                
                OR
                (  ld_res_role=ld_effective ) THEN 
                
                APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                    ' Site Request Id'||trunc(lr_blk_tps.site_request_id)||
                                    ' effective date'||trunc(lr_blk_tps.EFFECTIVE_DATE)||
                                    ' Res-Rol Start date'||trunc(lc_div_resrole_rec.start_date_active)||
                                    ' End date'||trunc(lc_div_resrole_rec.end_date_active)||
                                    ' Effective date fiscal month '||ld_effective ||
                                    ' Res-Rol fiscal month '||ld_res_role);
                
                lc_to_division:=lc_div_resrole_rec.attribute15;
                ELSE 
                  FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0268_TO_DIV_NT_EXIST');
                  lc_flag := 'N';
                  lc_status := null;
                  lc_status := 'ERROR';
                  lc_status_message:= FND_MESSAGE.GET;

                  Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                           ,p_error_message_code =>  lc_status
                           ,p_error_msg          =>  lc_status_message
                           );
                END IF;  --end of Resource and role combination validation        
              
              END IF; --end of Resource, role and group combination validation 
           END IF;
           CLOSE lcu_to_division;
         END IF;

         IF lc_flag = 'Y' AND lc_from_division <> lc_to_division THEN

             FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0271_FRM_TO_DIV_NT_MTCH');
             lc_flag := 'N';
             lc_status := null;
             lc_status := 'ERROR';
             lc_status_message:= FND_MESSAGE.GET;

             Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                             ,p_error_message_code =>  lc_status
                             ,p_error_msg          =>  lc_status_message
                              );
         END IF;
         

         IF lc_flag = 'Y' THEN

             OPEN lcu_party_type(lr_blk_tps.party_site_id);

             FETCH lcu_party_type INTO lc_party_type;

             CLOSE lcu_party_type;

  /*Insert for Retro Records*/

         IF trunc(lr_blk_tps.effective_date) <= trunc(sysdate-1) 
			AND (lc_party_type = 'CUSTOMER' OR lc_party_type = 'PROSPECT') 
			AND lc_from_division = 'BSD'
         THEN
         
                  For i IN (SELECT resource_id,
                                          resource_role_id,
                                              group_id,start_date_active,
                                              end_date_active
                       FROM   XX_TM_NAM_TERR_HISTORY_DTLS
                             WHERE  party_site_id = lr_blk_tps.PARTY_SITE_ID
                             AND    division = lc_from_division)
             LOOP

               IF lr_blk_tps.effective_date between i.start_date_active and nvl(i.end_date_active,sysdate) THEN

                  lc_from_resource_id := i.resource_id;
                  lc_from_role_id := i.resource_role_id;
                  lc_from_group_id := i.group_id;
               END IF;

             END LOOP;

             IF lc_from_resource_id =0 OR lc_from_role_id = 0 OR lc_from_group_id = 0 THEN

               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0269_RES_ROLE_GRP_NT_VALID');
               lc_flag := 'N';
               lc_status := null;
               lc_status := 'ERROR';
               lc_status_message:= FND_MESSAGE.GET;

               Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                              ,p_error_message_code =>  lc_status
                              ,p_error_msg          =>  lc_status_message
                             );
             END IF;

             IF lc_flag = 'Y' THEN
             ln_total_retro_cnt := ln_total_retro_cnt +1;

               Begin

                             
                   INSERT INTO XX_CRM_TPS_SITE_REQUESTS_STG
                   (
                         RECORD_ID
                              ,SITE_REQUEST_ID
                              ,CREATION_DATE
                              ,CREATED_BY
                              ,LAST_UPDATE_DATE
                              ,LAST_UPDATED_BY
                              ,PROGRAM_APPLICATION_ID
                              ,PROGRAM_ID
                              ,PROGRAM_UPDATE_DATE
                              ,REQUEST_ID
                              ,GOAL_ID
                              ,TO_RESOURCE_ID
                              ,TO_ROLE_ID
                              ,TO_GROUP_ID
                              ,PARTY_SITE_ID
                              ,REQUEST_REASON_CODE
                              ,REQUEST_REASON
                              ,EFFECTIVE_DATE
                              ,REQUEST_STATUS_CODE
                              ,REVIEW_COMPLETION_METHOD
                              ,REVIEW_COMPLETION_DATE
                              ,REJECT_REASON_CODE
                              ,REJECT_REASON
                              ,DIRECTION_CODE
                              ,TERRITORY_IFACE_DATE
                              ,FROM_RESOURCE_ID
                              ,FROM_ROLE_ID
                              ,FROM_GROUP_ID
                              ,BULK_REQUEST_ID
                              ,TERR_REC_ID
                              ,PREVIOUS_SITE_REQUEST_ID
                              ,ATTRIBUTE1
            
                   )
                   VALUES
                   (
                       ln_record_id
                      ,lr_blk_tps.SITE_REQUEST_ID
                      ,SYSDATE
                      ,G_CREATED_BY
                      ,SYSDATE
                      ,G_LAST_UPDATED_BY
                      ,G_PROG_APPL_ID
                      ,G_REQUEST_ID
                      ,sysdate
                      ,lr_blk_tps.request_id
                      ,lr_blk_tps.goal_id
                      ,lr_blk_tps.TO_RESOURCE_ID
                      ,lr_blk_tps.TO_ROLE_ID
                      ,lr_blk_tps.TO_GROUP_ID
                      ,lr_blk_tps.PARTY_SITE_ID
                      ,lr_blk_tps.REQUEST_REASON_CODE
                      ,lr_blk_tps.REQUEST_REASON
                      ,trunc(lr_blk_tps.EFFECTIVE_DATE)
                      ,lr_blk_tps.REQUEST_STATUS_CODE
                      ,lr_blk_tps.REVIEW_COMPLETION_METHOD
                      ,lr_blk_tps.REVIEW_COMPLETION_DATE
                      ,lr_blk_tps.REJECT_REASON_CODE
                            ,lr_blk_tps.REJECT_REASON
                            ,lr_blk_tps.DIRECTION_CODE
                            ,lr_blk_tps.TERRITORY_IFACE_DATE
                            ,lc_from_resource_id 
                      ,lc_from_role_id 
                      ,lc_from_group_id   
                            ,lr_blk_tps.BULK_REQUEST_ID
                            ,lr_blk_tps.TERR_REC_ID
                            ,lr_blk_tps.PREVIOUS_SITE_REQUEST_ID
                            ,'RETRO'
                   );


               EXCEPTION
                 WHEN OTHERS THEN

                   FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0270_UNEXPECTED_ERR');
                   FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                   FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                   lc_flag := 'N';
                   lc_status := null;
                   lc_status := 'ERROR';
                   lc_status_message:= FND_MESSAGE.GET;

                   Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                                  ,p_error_message_code =>  lc_status
                                  ,p_error_msg          =>  lc_status_message
                                 ); 
               END;

               IF lc_flag = 'Y' THEN
               
               ln_total_normal_cnt := ln_total_normal_cnt+1;
                
                 BEGIN
                    ln_record_id  :=0;

                   SELECT XXCRM.XX_CRM_TPS_Record_Id_S.nextval
                   INTO ln_record_id
                   FROM dual;

                   INSERT INTO XX_CRM_TPS_SITE_REQUESTS_STG
                   (
                         RECORD_ID
                                  ,SITE_REQUEST_ID
                                  ,CREATION_DATE
                              ,CREATED_BY
                              ,LAST_UPDATE_DATE
                              ,LAST_UPDATED_BY
                              ,PROGRAM_APPLICATION_ID
                              ,PROGRAM_ID
                              ,PROGRAM_UPDATE_DATE
                              ,REQUEST_ID
                              ,GOAL_ID
                              ,TO_RESOURCE_ID
                              ,TO_ROLE_ID
                              ,TO_GROUP_ID
                              ,PARTY_SITE_ID
                              ,REQUEST_REASON_CODE
                              ,REQUEST_REASON
                              ,EFFECTIVE_DATE
                              ,REQUEST_STATUS_CODE
                              ,REVIEW_COMPLETION_METHOD
                              ,REVIEW_COMPLETION_DATE
                              ,REJECT_REASON_CODE
                              ,REJECT_REASON
                              ,DIRECTION_CODE
                              ,TERRITORY_IFACE_DATE
                              ,FROM_RESOURCE_ID
                              ,FROM_ROLE_ID
                              ,FROM_GROUP_ID
                              ,BULK_REQUEST_ID
                              ,TERR_REC_ID
                              ,PREVIOUS_SITE_REQUEST_ID
                              ,ATTRIBUTE1

                   )
                   VALUES
                   (
                       ln_record_id
                      ,lr_blk_tps.SITE_REQUEST_ID
                      ,SYSDATE
                      ,G_CREATED_BY
                      ,SYSDATE
                      ,G_LAST_UPDATED_BY
                      ,G_PROG_APPL_ID
                      ,G_REQUEST_ID
                      ,sysdate
                      ,lr_blk_tps.request_id
                      ,lr_blk_tps.goal_id
                      ,lr_blk_tps.TO_RESOURCE_ID
                      ,lr_blk_tps.TO_ROLE_ID
                      ,lr_blk_tps.TO_GROUP_ID
                      ,lr_blk_tps.PARTY_SITE_ID
                      ,lr_blk_tps.REQUEST_REASON_CODE
                      ,lr_blk_tps.REQUEST_REASON
                      ,trunc(SYSDATE)
                      ,lr_blk_tps.REQUEST_STATUS_CODE
                      ,lr_blk_tps.REVIEW_COMPLETION_METHOD
                      ,lr_blk_tps.REVIEW_COMPLETION_DATE
                      ,lr_blk_tps.REJECT_REASON_CODE
                              ,lr_blk_tps.REJECT_REASON
                              ,lr_blk_tps.DIRECTION_CODE
                              ,lr_blk_tps.TERRITORY_IFACE_DATE
                              ,lr_blk_tps.from_resource_id         
                      ,lr_blk_tps.from_role_id            
                      ,lr_blk_tps.from_group_id     
                              ,lr_blk_tps.BULK_REQUEST_ID
                              ,lr_blk_tps.TERR_REC_ID
                              ,lr_blk_tps.PREVIOUS_SITE_REQUEST_ID
                              ,'NORMAL'
                   );

               EXCEPTION
               WHEN OTHERS THEN

                 FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0270_UNEXPECTED_ERR');
                 FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                 FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                 lc_flag := 'N';
                 lc_status := null;
                 lc_status := 'ERROR';
                 lc_status_message:= FND_MESSAGE.GET;

                 Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                                ,p_error_message_code =>  lc_status
                                ,p_error_msg          =>  lc_status_message
                               );
                 END;
               END IF;

             END IF;
         ELSIF  trunc(lr_blk_tps.effective_date) >= trunc(sysdate-1) AND lc_party_type = 'CUSTOMER' AND lc_from_division = 'BSD'
         THEN
                 ln_total_normal_cnt := ln_total_normal_cnt+1;
                 BEGIN
                 
                       INSERT INTO XX_CRM_TPS_SITE_REQUESTS_STG
                       (
                         RECORD_ID
                              ,SITE_REQUEST_ID
                              ,CREATION_DATE
                              ,CREATED_BY
                              ,LAST_UPDATE_DATE
                              ,LAST_UPDATED_BY
                              ,PROGRAM_APPLICATION_ID
                              ,PROGRAM_ID
                              ,PROGRAM_UPDATE_DATE
                              ,REQUEST_ID
                              ,GOAL_ID
                              ,TO_RESOURCE_ID
                              ,TO_ROLE_ID
                              ,TO_GROUP_ID
                              ,PARTY_SITE_ID
                              ,REQUEST_REASON_CODE
                              ,REQUEST_REASON
                              ,EFFECTIVE_DATE
                              ,REQUEST_STATUS_CODE
                              ,REVIEW_COMPLETION_METHOD
                              ,REVIEW_COMPLETION_DATE
                              ,REJECT_REASON_CODE
                              ,REJECT_REASON
                              ,DIRECTION_CODE
                              ,TERRITORY_IFACE_DATE
                              ,FROM_RESOURCE_ID
                              ,FROM_ROLE_ID
                              ,FROM_GROUP_ID
                              ,BULK_REQUEST_ID
                              ,TERR_REC_ID
                              ,PREVIOUS_SITE_REQUEST_ID
                               ,ATTRIBUTE1

                   )
                   VALUES
                   (
                       ln_record_id
                      ,lr_blk_tps.SITE_REQUEST_ID
                      ,SYSDATE
                      ,G_CREATED_BY
                      ,SYSDATE
                      ,G_LAST_UPDATED_BY
                      ,G_PROG_APPL_ID
                      ,G_REQUEST_ID
                      ,sysdate
                      ,lr_blk_tps.request_id
                      ,lr_blk_tps.goal_id
                      ,lr_blk_tps.TO_RESOURCE_ID
                      ,lr_blk_tps.TO_ROLE_ID
                      ,lr_blk_tps.TO_GROUP_ID
                      ,lr_blk_tps.PARTY_SITE_ID
                      ,lr_blk_tps.REQUEST_REASON_CODE
                      ,lr_blk_tps.REQUEST_REASON
                      ,trunc(SYSDATE)
                      ,lr_blk_tps.REQUEST_STATUS_CODE
                      ,lr_blk_tps.REVIEW_COMPLETION_METHOD
                      ,lr_blk_tps.REVIEW_COMPLETION_DATE
                      ,lr_blk_tps.REJECT_REASON_CODE
                            ,lr_blk_tps.REJECT_REASON
                            ,lr_blk_tps.DIRECTION_CODE
                            ,lr_blk_tps.TERRITORY_IFACE_DATE
                            ,lr_blk_tps.from_resource_id         
                      ,lr_blk_tps.from_role_id           
                      ,lr_blk_tps.from_group_id    
                            ,lr_blk_tps.BULK_REQUEST_ID
                            ,lr_blk_tps.TERR_REC_ID
                            ,lr_blk_tps.PREVIOUS_SITE_REQUEST_ID
                            ,'NORMAL'
                                 );

                 EXCEPTION
                 WHEN OTHERS THEN

                   FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0270_UNEXPECTED_ERR');
                   FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                   FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                   lc_flag := 'N';
                   lc_status := null;
                   lc_status := 'ERROR';
                   lc_status_message:= FND_MESSAGE.GET;

                   Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                                  ,p_error_message_code =>  lc_status
                                  ,p_error_msg          =>  lc_status_message
                                 );
                 END;


               IF lc_flag = 'Y' THEN
                ln_total_retro_cnt := ln_total_retro_cnt +1;
                 BEGIN
                   ln_record_id  :=0;

                             SELECT XXCRM.XX_CRM_TPS_Record_Id_S.nextval
                             INTO ln_record_id
                             FROM dual;
                   
                   
                                 INSERT INTO XX_CRM_TPS_SITE_REQUESTS_STG
                                 (
                         RECORD_ID
                                    ,SITE_REQUEST_ID
                                    ,CREATION_DATE
                                    ,CREATED_BY
                                    ,LAST_UPDATE_DATE
                                    ,LAST_UPDATED_BY
                                    ,PROGRAM_APPLICATION_ID
                                    ,PROGRAM_ID
                                    ,PROGRAM_UPDATE_DATE
                                    ,REQUEST_ID
                                    ,GOAL_ID
                                    ,TO_RESOURCE_ID
                                    ,TO_ROLE_ID
                                    ,TO_GROUP_ID
                                    ,PARTY_SITE_ID
                                    ,REQUEST_REASON_CODE
                                    ,REQUEST_REASON
                                    ,EFFECTIVE_DATE
                                    ,REQUEST_STATUS_CODE
                                    ,REVIEW_COMPLETION_METHOD
                                    ,REVIEW_COMPLETION_DATE
                                    ,REJECT_REASON_CODE
                                    ,REJECT_REASON
                                    ,DIRECTION_CODE
                                    ,TERRITORY_IFACE_DATE
                                    ,FROM_RESOURCE_ID
                                    ,FROM_ROLE_ID
                                    ,FROM_GROUP_ID
                                    ,BULK_REQUEST_ID
                                    ,TERR_REC_ID
                                    ,PREVIOUS_SITE_REQUEST_ID
                                    ,ATTRIBUTE1

                                 )
                                 VALUES
                                 (
                                     ln_record_id
                                    ,lr_blk_tps.SITE_REQUEST_ID
                                    ,SYSDATE
                                    ,G_CREATED_BY
                                    ,SYSDATE
                                  ,G_LAST_UPDATED_BY
                                  ,G_PROG_APPL_ID
                                  ,G_REQUEST_ID
                                  ,sysdate
                                  ,lr_blk_tps.request_id
                                  ,lr_blk_tps.goal_id
                                  ,lr_blk_tps.TO_RESOURCE_ID
                                  ,lr_blk_tps.TO_ROLE_ID
                                  ,lr_blk_tps.TO_GROUP_ID
                                  ,lr_blk_tps.PARTY_SITE_ID
                                  ,lr_blk_tps.REQUEST_REASON_CODE
                                  ,lr_blk_tps.REQUEST_REASON
                                  ,trunc(lr_blk_tps.EFFECTIVE_DATE)
                                  ,lr_blk_tps.REQUEST_STATUS_CODE
                                  ,lr_blk_tps.REVIEW_COMPLETION_METHOD
                                  ,lr_blk_tps.REVIEW_COMPLETION_DATE
                                  ,lr_blk_tps.REJECT_REASON_CODE
                                  ,lr_blk_tps.REJECT_REASON
                                  ,lr_blk_tps.DIRECTION_CODE
                                  ,lr_blk_tps.TERRITORY_IFACE_DATE
                                  ,lr_blk_tps.from_resource_id    
                        ,lr_blk_tps.from_role_id              
                        ,lr_blk_tps.from_group_id  
                                  ,lr_blk_tps.BULK_REQUEST_ID
                                  ,lr_blk_tps.TERR_REC_ID
                                  ,lr_blk_tps.PREVIOUS_SITE_REQUEST_ID
                                  ,'RETRO'
                                 );


                   EXCEPTION
                   WHEN OTHERS THEN

                     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0270_UNEXPECTED_ERR');
                     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                     lc_flag := 'N';
                     lc_status := null;
                     lc_status := 'ERROR';
                     lc_status_message:= FND_MESSAGE.GET;

                     Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                                    ,p_error_message_code =>  lc_status
                                    ,p_error_msg          =>  lc_status_message
                                   );
                 END;
               END IF;

          ELSE
              ln_total_normal_cnt := ln_total_normal_cnt+1;
                   BEGIN
                   INSERT INTO XX_CRM_TPS_SITE_REQUESTS_STG
                               (
                         RECORD_ID
                                    ,SITE_REQUEST_ID
                                    ,CREATION_DATE
                                    ,CREATED_BY
                                    ,LAST_UPDATE_DATE
                                    ,LAST_UPDATED_BY
                                    ,PROGRAM_APPLICATION_ID
                                    ,PROGRAM_ID
                                    ,PROGRAM_UPDATE_DATE
                                    ,REQUEST_ID
                                    ,GOAL_ID
                                    ,TO_RESOURCE_ID
                                    ,TO_ROLE_ID
                                    ,TO_GROUP_ID
                                    ,PARTY_SITE_ID
                                    ,REQUEST_REASON_CODE
                                    ,REQUEST_REASON
                                    ,EFFECTIVE_DATE
                                    ,REQUEST_STATUS_CODE
                                    ,REVIEW_COMPLETION_METHOD
                                    ,REVIEW_COMPLETION_DATE
                                    ,REJECT_REASON_CODE
                                    ,REJECT_REASON
                                    ,DIRECTION_CODE
                                    ,TERRITORY_IFACE_DATE
                                    ,FROM_RESOURCE_ID
                                    ,FROM_ROLE_ID
                                    ,FROM_GROUP_ID
                                    ,BULK_REQUEST_ID
                                    ,TERR_REC_ID
                                    ,PREVIOUS_SITE_REQUEST_ID
                                    ,ATTRIBUTE1

                                 )
                                 VALUES
                                 (
                                   ln_record_id
                                  ,lr_blk_tps.SITE_REQUEST_ID
                                  ,SYSDATE
                                  ,G_CREATED_BY
                                  ,SYSDATE
                                  ,G_LAST_UPDATED_BY
                                  ,G_PROG_APPL_ID
                                  ,G_REQUEST_ID
                                  ,sysdate
                                  ,lr_blk_tps.request_id
                                  ,lr_blk_tps.goal_id
                                  ,lr_blk_tps.TO_RESOURCE_ID
                                  ,lr_blk_tps.TO_ROLE_ID
                                  ,lr_blk_tps.TO_GROUP_ID
                                  ,lr_blk_tps.PARTY_SITE_ID
                                  ,lr_blk_tps.REQUEST_REASON_CODE
                                  ,lr_blk_tps.REQUEST_REASON
                                  ,trunc(SYSDATE)
                                  ,lr_blk_tps.REQUEST_STATUS_CODE
                                  ,lr_blk_tps.REVIEW_COMPLETION_METHOD
                                  ,lr_blk_tps.REVIEW_COMPLETION_DATE
                                  ,lr_blk_tps.REJECT_REASON_CODE
                                  ,lr_blk_tps.REJECT_REASON
                                  ,lr_blk_tps.DIRECTION_CODE
                                  ,lr_blk_tps.TERRITORY_IFACE_DATE
                                  ,lr_blk_tps.from_resource_id    
                        ,lr_blk_tps.from_role_id              
                        ,lr_blk_tps.from_group_id  
                                  ,lr_blk_tps.BULK_REQUEST_ID
                                  ,lr_blk_tps.TERR_REC_ID
                                  ,lr_blk_tps.PREVIOUS_SITE_REQUEST_ID
                                  ,'NORMAL'
                                  );

                   EXCEPTION
                   WHEN OTHERS THEN

                     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0270_UNEXPECTED_ERR');
                     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                     lc_flag := 'N';
                     lc_status := null;
                     lc_status := 'ERROR';
                     lc_status_message:= FND_MESSAGE.GET;

                     Log_Exception ( p_error_location     =>  'XX_TM_INSERT_TPS_STG_PKG.main_proc'
                                    ,p_error_message_code =>  lc_status
                                    ,p_error_msg          =>  lc_status_message
                                   );
                 END;
                              END IF;
                  END IF;
            
                       BEGIN  ---Updating record status  
                       
                       IF  lc_status IS NULL THEN
                        lc_status := 'READY_REASSIGN';
                        lc_status_message := Null;
                       END IF;
                      
                                                    
                         UPDATE xxtps_site_requests 
                         SET    request_status_code = lc_status,
                                reject_reason = lc_status_message ,
                                program_id = G_REQUEST_ID,
                                last_update_date = sysdate                          
                         WHERE  request_status_code = 'QUEUED' 
                         AND    site_request_id = lr_blk_tps.site_request_id;
                         
                       
                         
                          EXCEPTION
                          WHEN OTHERS THEN
                             G_ERRBUF  := null;
                             APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Unexpected error in UPDATING request_status_code for xxtps_site_requests  - ' ||SQLERRM);
                             FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0253_MAIN_PRG_ERRR');
                             FND_MESSAGE.SET_TOKEN('SQLERR', SQLERRM);
                             G_ERRBUF  := FND_MESSAGE.GET;
                             X_RETCODE := 2;
                             Rollback;
                             Return;
                                                       
                             Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                            ,p_error_message_code =>  'XX_TM_0253_MAIN_PRG_ERR'
                                            ,p_error_msg          =>  G_ERRBUF
                                           );    
                          END;  ---Updating record status                               
                     
                     ln_total_rec_cnt:=ln_counter;
                    
                    IF  lc_status = 'ERROR' THEN
                    ln_total_err_cnt := ln_total_err_cnt +1;
                    END IF;
       
       END LOOP;
           IF ln_total_rec_cnt = 0 THEN
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Records Found To Process :' ||ln_total_rec_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'NO Records Found To Process :' ||ln_total_rec_cnt);
           END IF; 
           
           IF ln_total_rec_cnt > 0 AND ln_total_rec_cnt = ln_total_err_cnt THEN
            x_retcode :=2;
           ELSIF ln_total_rec_cnt > 0 AND ln_total_rec_cnt > ln_total_err_cnt  AND ln_total_err_cnt >0 THEN
            x_retcode :=1;
           END iF; 
           
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No.Of Successfull Retro Records :' ||ln_total_retro_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No.Of Successfull Normal Records :' ||ln_total_normal_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No.Of Reassignment Requests :' ||ln_total_rec_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No.Of Reassignment Requests Failed transformation :' ||ln_total_err_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No.Of Reassignemnt requests successfully transformed :' ||TO_CHAR(ln_total_rec_cnt - ln_total_err_cnt) );
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
            
           
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No.Of Successfull Retro Records :' ||ln_total_retro_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No.Of Successfull Normal Records :' ||ln_total_normal_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------------------------------------------------' );
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------------------------------------------------' );   
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No.Of Reassignment Requests :' ||ln_total_rec_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No.Of Reassignment Requests Failed transformation :' ||ln_total_err_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No.Of Reassignemnt requests successfully transformed :' ||TO_CHAR(ln_total_rec_cnt - ln_total_err_cnt) );
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------------------------------------------------' );
            APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------------------------------------------------' );   
              
       COMMIT;
  END MAIN_PROC ;  ---End of main procrdure

END XX_TM_INSERT_TPS_STG_PKG;



/
SHOW ERRORS;
--EXIT;
