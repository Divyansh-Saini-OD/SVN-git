-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
package body XXSCS_LOAD_STG_DATA AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XXSCS_LOAD_STG_DATA                                                       |
-- | Description : Custom package for data migration.                                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        08-Apr-2009     Kalyan               Initial version                          |
-- |1.1        03-Aug-2009     Kalyan               Populate task_id in fdbk lines.          |
-- |                                                Pick  fdbk lines on update of SIC/WCW    |
-- |1.2        26-Aug-2009     Kalyan               Added Feedback lines for party tasks.    |
-- |1.3        27-Jul-2010     Mangalasundari K    Changed the Condition as  a part of       |
-- |                                                QC# 6891 in the Cursor C_TASKS_REPORT    |
-- +=========================================================================================+
g_limit NUMBER := 500;
bulk_errors EXCEPTION;
PRAGMA EXCEPTION_INIT (bulk_errors, -24381);
TYPE R_CURSOR IS REF CURSOR;
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
-- +===================================================================+
-- | Name             : GENERATE_TASKS_REPORT                          |
-- | Description      : This procedure extracts Completed Tasks        |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE GENERATE_TASKS_REPORT( x_errbuf              OUT NOCOPY VARCHAR2
                        ,x_retcode             OUT NOCOPY VARCHAR2
                                          , p_start_date         IN            VARCHAR2
					  , p_end_date           IN            VARCHAR2
                                          , p_update_prof       IN            VARCHAR2
                       ) is 
ln_succ_update_date date;
ln_new_update_date date;
   l_from_date     DATE;
   l_to_date       DATE;
l_update_prof      VARCHAR2(1):=p_update_prof;
 l_error_messege VARCHAR2(2000);
CURSOR C_TASKS_REPORT IS 
SELECT a.task_name  as task_name,
  p.attribute13 as Cust_Type,
  --b.fdbk_id as FDBK_ID, --Commented as a part of Defect 6891
  COALESCE( SUBSTR(hcasa.orig_system_reference, 1,instr(hcasa.orig_system_reference,'-')-1),SUBSTR(cs.orig_system_reference, 1,instr(cs.orig_system_reference,'-')-1)) as Cust_Id,
  COALESCE(SUBSTR(hcasa.orig_system_reference, instr(hcasa.orig_system_reference,'-',1) +1 , instr(hcasa.orig_system_reference,'-',1,2) -instr(hcasa.orig_system_reference,'-',1,1)-1), SUBSTR(cs.orig_system_reference, instr(cs.orig_system_reference,'-',1)+1 , instr(cs.orig_system_reference,'-',1,2) -instr(cs.orig_system_reference,'-',1,1)-1)) as Seq,
  ps.party_site_number as party_site_number ,
  p.party_number as party_number,
  a.user_name as Emp_Id,
  a.task_update_date as Last_update_Date,
  DECODE(a.entity_type , 'OD_PARTY_SITE',to_char(party_site_number),'PARTY',to_char(party_number), 'TASK',to_char(a.task_number),a.entity_id ) as Entity_Id,
  a.entity_type as Entity_Type,
  a.task_number as Task_Num,
  a.task_type as Task_Type,
  a.task_date as Due_Date,
  a.tsk_status as Task_Status,
  p.party_name as Party_Name
FROM
  (SELECT TSK.source_object_type_code ENTITY_TYPE,
    DECODE( TSK.source_object_type_code, 'OPPORTUNITY', OPP.lead_number, 'LEAD' , LEAD.lead_number, to_char(tsk.source_object_id))    ENTITY_ID,
    DECODE( TSK.source_object_type_code, 'OPPORTUNITY', OPP.customer_id, 'LEAD' , LEAD.customer_id, tsk.customer_id) party_id,
    DECODE(TSK.source_object_type_code, 'OD_PARTY_SITE',tsk.source_object_id, tsk.address_id) party_site_id,
    TSK.creation_date task_creation_date,
    TSK.last_update_date task_update_date,
    TSK.created_by task_created_by,
    TSK.task_id,
    TSK.task_number,
    tsk.task_name,
    usr.user_name,
    TSK.scheduled_end_date task_date,
    TSKTYP.name task_type,
    TSK.scheduled_end_date fdbk_code,
    TSKSTAT.name tsk_status,
opp.lead_number, lead.lead_number
  FROM apps.JTF_TASKS_VL TSK,
    apps.jtf_task_types_vl TSKTYP,
    apps.jtf_task_statuses_vl TSKSTAT,
    apps.AS_SALES_LEADS LEAD, -- leads
    apps.AS_LEADS_ALL OPP,    -- opportunities
    apps.fnd_user usr
  WHERE TSKTYP.task_type_id      = TSK.task_type_id
  AND TSKSTAT.task_status_id     = TSK.task_status_id
  AND usr.user_id                = TSK.created_by
  AND TSK.scheduled_end_date    IS NOT NULL
  AND TSK.source_object_id       = OPP.lead_id(+)
  AND TSK.source_object_id       = LEAD.sales_lead_id(+)
  AND NVL(LEAD.deleted_flag,'N') = 'N'
  AND NVL(OPP.deleted_flag,'N')  = 'N'
  --AND TSK.last_update_date BETWEEN ln_succ_update_date AND ln_new_update_date --Commented as a part of Defect 6891
  AND TSK.scheduled_end_date BETWEEN  ln_succ_update_date AND trunc(ln_new_update_date) +1-(1/3600)-- For Defect 6891
  AND TSKSTAT.name                       IN ('Completed','Closed','Close')
  ) a,
  /*( SELECT DISTINCT h.fdbk_id,
    l.attribute1 task_id
  FROM apps.xxscs_fdbk_hdr h,
    apps.xxscs_fdbk_line_dtl l
  WHERE h.fdbk_id         =l.fdbk_id
  AND l.attribute_category='TASK_ID'
  AND h.last_update_date BETWEEN ln_succ_update_date AND ln_new_update_date
  ) b,*/ --Commented as a part of Defect 6891
  apps.hz_parties p,
  apps.hz_cust_accounts_all cs,
  apps.hz_party_sites ps,
  apps.hz_cust_acct_sites_all hcasa
WHERE p.party_id(+)    =a.party_id
AND cs.party_id(+)     =a.party_id
AND ps.party_site_id(+)=a.party_site_id
--AND a.task_id             = b.task_id(+)
AND hcasa.party_site_id(+)=a.party_site_id
order by task_update_date;

Type xx_tsk_report_tbl is table of C_TASKS_REPORT%rowtype index by binary_integer;
lc_tsk_report_tbl xx_tsk_report_tbl ;

begin
display_log ('p_start_date '||p_start_date);
display_log ('p_end_date '||p_end_date);
display_log ('l_from_date   '||l_from_date  );
   IF nvl(p_start_date,'NO') <> 'NO' THEN 
    BEGIN
display_log ('Inside begin   ');
display_log ('p_start_date '||p_start_date);
         l_from_date  := to_date(p_start_date,'yyyy/mm/dd hh24:mi:ss');
         l_to_date    := to_date(p_end_date,'yyyy/mm/dd hh24:mi:ss');
    EXCEPTION
      WHEN OTHERS
      THEN
        l_error_messege   :=  'Please enter the Date in valid format of mm/dd/yyyy hh24:mi:ss';
      END;
	display_log ('l_from_date '||ln_succ_update_date);
	display_log ('l_to_date '||l_to_date);

	ln_succ_update_date:=l_from_date;
        ln_new_update_date:=l_to_date;
	display_log ('ln_succ_update_date '||ln_succ_update_date);
	display_log ('ln_new_update_date '||ln_new_update_date);
   ELSE 
      BEGIN
           SELECT to_date(FPOV.profile_option_value,'DD-MON-YYYY HH24:MI:SS')
           INTO   ln_succ_update_date
           FROM   fnd_profile_option_values FPOV
                  , fnd_profile_options FPO
           WHERE  FPO.profile_option_id = FPOV.profile_option_id
           AND    FPO.application_id = FPOV.application_id
           AND    FPOV.level_id = G_LEVEL_ID
           AND    FPOV.level_value = G_LEVEL_VALUE
           AND    FPOV.profile_option_value IS NOT NULL
           AND    FPO.profile_option_name = 'XXSCS_TASKS_EXT_DT';
      EXCEPTION
         WHEN OTHERS THEN
             ln_succ_update_date := NULL;
      END;
      BEGIN
		ln_new_update_date:= sysdate;
      EXCEPTION
         WHEN OTHERS THEN
             ln_new_update_date:= NULL;
      END; 
	display_log ('ln_succ_update_date '||ln_succ_update_date);
	display_log ('ln_new_update_date '||ln_new_update_date);

      l_update_prof  :='Y';
      display_log('ln_succ_update_date ='||ln_succ_update_date);

END IF;
display_log ('out side ln_succ_update_date '||ln_succ_update_date);
	display_log (' out side  ln_new_update_date '||ln_new_update_date);
      OPEN C_TASKS_REPORT ;
      FETCH C_TASKS_REPORT  bulk collect INTO lc_tsk_report_tbl; 
      CLOSE C_TASKS_REPORT ;

display_log ('lc_tsk_report_tbl.count '||lc_tsk_report_tbl.count);
      IF lc_tsk_report_tbl.count > 0 THEN       


                
      display_out( ' Name'||chr(9)
		 ||' Cust Type'||chr(9)
		-- ||' FDBK ID'||chr(9)
		 ||' Customer Account'||chr(9)
                 ||' Seq '||chr(9)
                 ||' Party Site Number'||chr(9)
                 ||' Party Number'||chr(9)
                 ||' Emp ID'||chr(9)
                 ||' Last update Date'||chr(9)
                 ||' Entity Id'||chr(9)
                 ||' Entity Type'||chr(9)
                 ||' Task Num'||chr(9)
                 ||' Task Type'||chr(9)
                 ||' Due Date'||chr(9)
                 ||' Party Name'||chr(9));
         
        FOR i IN lc_tsk_report_tbl.first .. lc_tsk_report_tbl.last
        LOOP

 display_out(nvl(lc_tsk_report_tbl(i).task_name,'(null)')||chr(9)
                 ||nvl(lc_tsk_report_tbl(i).Cust_Type,'(null)')||chr(9)
                 --||nvl(to_char(lc_tsk_report_tbl(i).FDBK_ID),'(null)')||chr(9)  --Commented as a part of Defect 6891
                 ||nvl(to_char(lc_tsk_report_tbl(i).Cust_Id),'(null)')||chr(9)
                 ||nvl(to_char(lc_tsk_report_tbl(i).Seq),'(null)')||chr(9)
                 ||nvl(to_char(lc_tsk_report_tbl(i).Party_Site_Number),'(null)')||chr(9)
                 ||nvl(to_char(lc_tsk_report_tbl(i).Party_Number),'(null)')||chr(9)
                 ||nvl(to_char(lc_tsk_report_tbl(i).Emp_ID),'(null)')||chr(9)                 		 		 	                 ||nvl(to_char(lc_tsk_report_tbl(i).Last_update_Date),'(null)')||chr(9)	 
                 ||nvl(to_char(lc_tsk_report_tbl(i).Entity_Id),'(null)')||chr(9)
                 ||nvl(lc_tsk_report_tbl(i).Entity_Type,'(null)')||chr(9)
                 ||nvl(to_char(lc_tsk_report_tbl(i).Task_Num),'(null)')||chr(9)
                 ||nvl(lc_tsk_report_tbl(i).Task_Type,'(null)')||chr(9)
                 ||nvl(to_char(lc_tsk_report_tbl(i).Due_Date),'(null)')||chr(9)	 
                 ||nvl(lc_tsk_report_tbl(i).Party_Name,'(null)')||chr(9));                  
                 

        END LOOP;  
       END IF;
        display_log('Update the sysdate '||to_CHAR(ln_new_update_date,'DD-MON-YYYY HH24:MI:SS'));
       IF NVL(upper(l_update_prof),'N') =  'Y' THEN
      IF FND_PROFILE.SAVE('XXSCS_TASKS_EXT_DT',to_CHAR(ln_new_update_date,'DD-MON-YYYY HH24:MI:SS'),'SITE') THEN                     COMMIT;
                               
       END IF;
      END IF;
END;



PROCEDURE  DE_RANK ( p_party_site_id  xxscs_fdbk_hdr.party_site_id%type,
                     p_fdk_code       xxscs_fdbk_line_dtl.fdk_code%type,
                     p_fdk_value      xxscs_fdbk_line_dtl.fdk_value%type,
                     p_fdk_date       xxscs_fdbk_line_dtl.fdk_date%type)  IS
--------------------------------------------------------------------------------------------------
-- DERANKING PROCESS
--------------------------------------------------------------------------------------------------
  CURSOR  C_New_Ranks (C_In_Party_Site_ID IN NUMBER) IS
  SELECT  potential_id,
          party_site_id,
          potential_type_cd
  FROM    apps.xxbi_cs_potential_all_v
  WHERE   party_site_id =  C_In_Party_Site_ID;
  X_Error_Msg   varchar2(2000);
  l_cont_after_date  DATE;
  l_next_sunday  DATE;
BEGIN
 -- Derank the potential if No followup required is selected as feedback value for follow up agreed on call
     IF p_fdk_code = 'FLWP_AGCL' AND p_fdk_value = 'NFUR' THEN
        -- De rank the potential
        BEGIN
           DELETE
           FROM   XXCRM.XXSCS_POTENTIAL_NEW_RANK
           WHERE  party_site_id = p_party_site_id;
           FOR j in C_New_Ranks (p_party_site_id)
           LOOP
             INSERT INTO XXCRM.XXSCS_POTENTIAL_NEW_RANK
               (
                 POTENTIAL_NEW_RANK_ID,
                 POTENTIAL_ID,
                 PARTY_SITE_ID,
                 POTENTIAL_TYPE_CD,
                 NEW_RANK,
                 CREATED_BY,
                 CREATION_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_DATE,
                 LAST_UPDATE_LOGIN,
                 REQUEST_ID
               )
              VALUES
               (
                 XXSCS_POTENTIAL_NEW_RANK_S.nextval,
                 j.POTENTIAL_ID,
                 j.PARTY_SITE_ID,
                 j.POTENTIAL_TYPE_CD,
                 -1000000,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.login_id,
                 NULL
                );
             END LOOP;
        --COMMIT;
        EXCEPTION WHEN OTHERS THEN
         -- X_Ret_Code  := 'E';
--          X_Error_Msg := 'Error while de-ranking potential (No Followup) for feedback ID '||j.POTENTIAL_ID
--                                                                                          ||'. '
--                                                                                          ||sqlerrm;
                    XXSCS_CONT_STRATEGY_PKG.Log_Exception
                            (p_error_location          => 'XXSCS_LOAD_STG_DATA'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_LOAD_STG_DATA.DE_RANK'
                            );
           --      gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
           --      gc_return_code := X_Ret_Code;
       END;
     END IF; -- i.fdk_code = 'FLWP_AGCL' AND i.fdk_value = 'NFUR' THEN
     IF p_fdk_code = 'CONTACT_AFTER_DATE' THEN
        -- Get the Week Day after which the de-ranking has to happen
        -- Business Rule: If Do not contact until after date falls in this week DO not de-rank the potential record,
        -- If the date falls after the current weekend (following sunday) de-rank the potential record
       -- check this code
       l_cont_after_date := to_date(p_fdk_date,'DD-MON-RR');
         SELECT
            decode(to_char(sysdate,'fmDAY'),
                                'MONDAY',trunc(sysdate+6),
                                'TUESDAY',trunc(sysdate+5),
                                'WEDNESDAY',trunc(sysdate+4),
                                'THURSDAY',trunc(sysdate+3),
                                'FRIDAY',trunc(sysdate+2),
                                'SATURDAY',trunc(sysdate+1),
                                'SUNDAY',trunc(sysdate),
                                trunc(sysdate))
          INTO
             l_next_sunday
          from
             dual;
       IF l_cont_after_date > trunc(l_next_sunday ) THEN
       -- De rank the potential record
        BEGIN
           DELETE FROM XXCRM.XXSCS_POTENTIAL_NEW_RANK
           WHERE party_site_id = p_party_site_id;
           FOR j in C_New_Ranks (p_party_site_id)
           LOOP
             INSERT INTO XXCRM.XXSCS_POTENTIAL_NEW_RANK
               (
                 POTENTIAL_NEW_RANK_ID,
                 POTENTIAL_ID,
                 PARTY_SITE_ID,
                 POTENTIAL_TYPE_CD,
                 NEW_RANK,
                 CREATED_BY,
                 CREATION_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_DATE,
                 LAST_UPDATE_LOGIN,
                 REQUEST_ID
               )
              VALUES
               (
                 XXSCS_POTENTIAL_NEW_RANK_S.nextval,
                 j.POTENTIAL_ID,
                 j.PARTY_SITE_ID,
                 j.POTENTIAL_TYPE_CD,
                 -1000000,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.login_id,
                 NULL
                );
             END LOOP;
        EXCEPTION WHEN OTHERS THEN
--         -- X_Ret_Code  := 'E';
--          X_Error_Msg := 'Error while de-ranking the potential due to response contact after date for feedback ID '|| j.POTENTIAL_ID
--                                                                                                                   ||'. '
--                                                                                                                   ||sqlerrm;
                    XXSCS_CONT_STRATEGY_PKG.Log_Exception
                            (p_error_location          => 'XXSCS_LOAD_STG_DATA'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_LOAD_STG_DATA.DE_RANK'
                            );
       END;
     END IF; -- l_date > trunc(l_next_sunday ) THEN
     END IF; -- i.fdk_code = 'CONTACT_AFTER_DATE' THEN
END DE_RANK;

procedure set_unique_date AS

counter NUMBER;

cursor  c_dup IS 
select  CUSTOMER_ACCOUNT_ID, ADDRESS_ID , CREATION_DATE 
from    apps.XXSCS_FDBK_HDR_STG      hdr
where   CUSTOMER_ACCOUNT_ID is not null
and     ADDRESS_ID is not null
group by CUSTOMER_ACCOUNT_ID, ADDRESS_ID , CREATION_DATE
having  count(1) > 1;

cursor c_select_set ( p_CUSTOMER_ACCOUNT_ID apps.XXSCS_FDBK_HDR_STG.CUSTOMER_ACCOUNT_ID%TYPE ,
                      p_ADDRESS_ID          apps.XXSCS_FDBK_HDR_STG.ADDRESS_ID%TYPE ,
                      p_CREATION_DATE       apps.XXSCS_FDBK_HDR_STG.CREATION_DATE%TYPE) IS 
select  FDBK_ID
from    apps.XXSCS_FDBK_HDR_STG      hdr
WHERE   CUSTOMER_ACCOUNT_ID = p_CUSTOMER_ACCOUNT_ID
AND     ADDRESS_ID = p_ADDRESS_ID
AND     CREATION_DATE  = p_CREATION_DATE
order by FDBK_ID;

cursor c_count_dup IS 
select  count(1) cnt
from    (
        select  1
        from  apps.XXSCS_FDBK_HDR_STG      hdr
        where   CUSTOMER_ACCOUNT_ID is not null
        and     ADDRESS_ID is not null
        group by CUSTOMER_ACCOUNT_ID, ADDRESS_ID , CREATION_DATE
        having count(1) > 1);

BEGIN

   loop
      for rec_count_dup IN c_count_dup LOOP
        IF rec_count_dup.cnt = 0 THEN
          RETURN; 
        ELSE
          counter := 0;
          for rec_dup IN c_dup LOOP
            for rec_select_set IN c_select_set( rec_dup.CUSTOMER_ACCOUNT_ID,
                                                rec_dup.ADDRESS_ID,
                                                rec_dup.CREATION_DATE) loop
              update   apps.XXSCS_FDBK_HDR_STG 
              set      creation_date = creation_date + ((counter*1)/(24*3600))
              where    FDBK_ID = rec_select_set.FDBK_ID;
              counter := counter +1;
            end loop;
          END LOOP;-- FOR LOOP IN ELSE
        END IF; 
      END LOOP; -- FIRST FOR LOOP
    end loop; -- OUTER LOOOP

EXCEPTION WHEN OTHERS THEN

fnd_file.put_line (fnd_file.log,'Exception in set_unique_date: ' || sqlerrm);

end set_unique_date;

procedure load_feedback_add_hdr_lines(  x_errbuf	  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                           )  AS
                                                      
CURSOR  c_add_lines IS
select  hdr.party_id, MAF.FDBK_ID , MAF.FDBK_LINE_ID , AD.FDK_DATE ACTIVITY_DATE, CAD.FDK_DATE,
        HDR.ATTRIBUTE_CATEGORY , HDR.ATTRIBUTE1, MAF.FDK_VALUE, HDR.CREATED_BY
FROM    apps.XXSCS_FDBK_HDR_STG      hdr,
        apps.XXSCS_FDBK_LINE_DTL_STG MAF,
        apps.XXSCS_FDBK_LINE_DTL_STG AD,
        apps.XXSCS_FDBK_LINE_DTL_STG CAD
WHERE   hdr.FDBK_ID = MAF.FDBK_ID
AND     hdr.FDBK_ID = AD.FDBK_ID
AND     hdr.FDBK_ID = CAD.FDBK_ID
and     hdr.ATTRIBUTE2 is null
and     MAF.FDK_CODE = 'MASS_APPLY_FLAG'
AND     CAD.FDK_CODE = 'CONTACT_AFTER_DATE'
AND     AD.FDK_CODE = 'ACTY_DT';
--and     MAF.FDK_VALUE = 'Y';

-- ACTIVITY_DATE, CONTACT_AFTER_DATE

CURSOR  c_party_sites(p_party_id HZ_PARTY_SITES.party_id%TYPE) IS
/*select  party_site_id , to_number(substr(hps.orig_system_reference,instr(hps.orig_system_reference,'-',1,1)+1,instr(hps.orig_system_reference,'-',1,2)-instr(hps.orig_system_reference,'-',1,1)-1)) address_id
from    apps.hz_party_sites hps
where   party_id = p_party_id;

*/
select  hps.party_site_id , to_number(substr(hps.orig_system_reference,instr(hps.orig_system_reference,'-',1,1)+1,instr(hps.orig_system_reference,'-',1,2)-instr(hps.orig_system_reference,'-',1,1)-1)) address_id, rs.user_id
from
XX_TM_NAM_TERR_CURR_ASSIGN_V cv,
JTF_RS_RESOURCE_EXTNS_VL rs,
apps.hz_party_sites hps
where rs.resource_id=cv.resource_id
and cv.entity_type='PARTY_SITE'
and hps.party_site_id= cv.entity_id
and hps.party_id = p_party_id;
TYPE t_add_lines IS TABLE OF  c_add_lines%ROWTYPE;
l_add_lines_tab t_add_lines;

BEGIN

  OPEN c_add_lines;

  LOOP
  FETCH c_add_lines BULK COLLECT INTO l_add_lines_tab LIMIT g_limit;

    FOR indx IN 1..l_add_lines_tab.count LOOP
      -- insert additional headers/lines 
      FOR head_rec IN (select * from apps.XXSCS_FDBK_HDR_STG hdr where hdr.fdbk_id = l_add_lines_tab(indx).fdbk_id)  loop
      
      -- NEW HEADER UPDATE ENTITY_TYPE = 'PARTY_SITE', ENTITYT_id = PARTY_SITE_ID,
      -- PARTY_SITE_ID = PARTY_SITE_ID
      -- 2 LINES WITH CONTACT_AFTER_dT, ACTIVITY_DT
        FOR party_site_rec IN c_party_sites(l_add_lines_tab(indx).party_id) loop
          IF ((l_add_lines_tab(indx).FDK_VALUE='ALL_SITES_ASSIGNED' AND l_add_lines_tab(indx).created_BY = party_site_rec.user_id
          ) OR  l_add_lines_tab(indx).FDK_VALUE='ALL_SITES')
         THEN
          insert into apps.XXSCS_FDBK_HDR_STG (
          FDBK_ID 		,
          CUSTOMER_ACCOUNT_ID 	,
          ADDRESS_ID 		,
          PARTY_SITE_ID 	,
          PARTY_ID 		,
          MASS_APPLY_FLAG 	,
          CONTACT_ID 		,
          LAST_UPDATED_EMP 	,
          SALES_TERRITORY_ID 	,
          RESOURCE_ID 		,
          ROLE_ID 		,
          GROUP_ID 		,
          LANGUAGE 		,
          SOURCE_LANG 		,
          CREATED_BY 		,
          CREATION_DATE 	,
          LAST_UPDATED_BY 	,
          LAST_UPDATE_DATE 	,
          LAST_UPDATE_LOGIN 	,
          REQUEST_ID 		,
          PROGRAM_APPLICATION_ID  ,
          PROGRAM_ID 		,
          PROGRAM_UPDATE_DATE 	,
          ATTRIBUTE_CATEGORY	,
          ATTRIBUTE1 		,
          ATTRIBUTE2 		,
          ATTRIBUTE3 		,
          ATTRIBUTE4 		,
          ATTRIBUTE5 		,
          ATTRIBUTE6 		,
          ATTRIBUTE7 		,
          ATTRIBUTE8 		,
          ATTRIBUTE9 		,
          ATTRIBUTE10 		,
          ATTRIBUTE11 		,
          ATTRIBUTE12 		,
          ATTRIBUTE13 		,
          ATTRIBUTE14 		,
          ATTRIBUTE15 		,
          ATTRIBUTE16 		,
          ATTRIBUTE17 		,
          ATTRIBUTE18 		,
          ATTRIBUTE19 		,
          ATTRIBUTE20 		,
          ENTITY_ID 		,
          ENTITY_TYPE )
          values 
          (
          XXSCS_FDBK_ID_S.nextval		, -- get from sequence ?
          head_rec.CUSTOMER_ACCOUNT_ID 	,
          party_site_rec.ADDRESS_ID 		,
          party_site_rec.PARTY_SITE_ID 	, -- modify this party_site_id
          head_rec.PARTY_ID 		,
          head_rec.MASS_APPLY_FLAG 	,
          head_rec.CONTACT_ID 		,
          head_rec.LAST_UPDATED_EMP 	,
          head_rec.SALES_TERRITORY_ID 	,
          head_rec.RESOURCE_ID 		,
          head_rec.ROLE_ID 		,
          head_rec.GROUP_ID 		,
          head_rec.LANGUAGE 		,
          head_rec.SOURCE_LANG 		,
          head_rec.CREATED_BY 		,
          head_rec.CREATION_DATE 		,
          head_rec.LAST_UPDATED_BY 	,
          head_rec.LAST_UPDATE_DATE 	,
          head_rec.LAST_UPDATE_LOGIN 	,
          head_rec.REQUEST_ID 		,
          head_rec.PROGRAM_APPLICATION_ID  ,
          head_rec.PROGRAM_ID 		,
          head_rec.PROGRAM_UPDATE_DATE 	,
          head_rec.ATTRIBUTE_CATEGORY	,
          head_rec.ATTRIBUTE1 		,
          head_rec.ATTRIBUTE2 		,
          head_rec.ATTRIBUTE3 		,
          head_rec.ATTRIBUTE4 		,
          head_rec.ATTRIBUTE5 		,
          head_rec.ATTRIBUTE6 		,
          head_rec.ATTRIBUTE7 		,
          head_rec.ATTRIBUTE8 		,
          head_rec.ATTRIBUTE9 		,
          head_rec.ATTRIBUTE10 		,
          head_rec.ATTRIBUTE11 		,
          head_rec.ATTRIBUTE12 		,
          head_rec.ATTRIBUTE13 		,
          head_rec.ATTRIBUTE14 		,
          head_rec.ATTRIBUTE15 		,
          head_rec.ATTRIBUTE16 		,
          head_rec.ATTRIBUTE17 		,
          head_rec.ATTRIBUTE18 		,
          head_rec.ATTRIBUTE19 		,
          head_rec.ATTRIBUTE20 		,
          party_site_rec.PARTY_SITE_ID 		, -- party_site_id
          'PARTY_SITE');                          -- entity_type = PARTY_SITE
          
          -- INSERT fdbk_lines 2 LINES WITH CONTACT_AFTER_dT, ACTIVITY_DT
          
          FOR line_rec IN (select * from apps.XXSCS_FDBK_LINE_DTL_STG line where line.FDBK_LINE_ID= l_add_lines_tab(indx).FDBK_LINE_ID)  loop
                --line  for CONTACT_AFTER_dT
              insert into XXSCS_FDBK_LINE_DTL_STG (
                  FDBK_LINE_ID 		,
                  FDBK_ID 		,
                  FDK_CODE 		,
                  FDK_VALUE 		,
                  FDK_TXT 		,
                  FDK_DATE 		,
                  FDK_PICK_VALUE 	,
                  LAST_UPDATED_EMP 	,
                  LANGUAGE 		,
                  SOURCE_LANG 		,
                  CREATED_BY 		,
                  CREATION_DATE 	,
                  LAST_UPDATED_BY 	,
                  LAST_UPDATE_DATE 	,
                  LAST_UPDATE_LOGIN 	,
                  REQUEST_ID 		,
                  PROGRAM_APPLICATION_ID,
                  PROGRAM_ID 		,
                  PROGRAM_UPDATE_DATE 	,
                  ATTRIBUTE_CATEGORY 	,
                  ATTRIBUTE1 		,
                  ATTRIBUTE2 		,
                  ATTRIBUTE3 		,
                  ATTRIBUTE4 		,
                  ATTRIBUTE5 		,
                  ATTRIBUTE6 		,
                  ATTRIBUTE7 		,
                  ATTRIBUTE8 		,
                  ATTRIBUTE9 		,
                  ATTRIBUTE10 		,
                  ATTRIBUTE11 		,
                  ATTRIBUTE12 		,
                  ATTRIBUTE13 		,
                  ATTRIBUTE14 		,
                  ATTRIBUTE15 		,
                  ATTRIBUTE16 		,
                  ATTRIBUTE17 		,
                  ATTRIBUTE18 		,
                  ATTRIBUTE19 		,
                  ATTRIBUTE20
                  ) values
                  (
                  XXSCS_FDBK_LINE_ID_S.nextval 	, -- get from sequence
                  XXSCS_FDBK_ID_S.currval 		,
                  'CONTACT_AFTER_DT' 		,
                  line_rec.FDK_VALUE 		,
                  line_rec.FDK_TXT 		,
                  l_add_lines_tab(indx).FDK_DATE 	,
                  'FDK_DATE' 	,
                  line_rec.LAST_UPDATED_EMP 	,
                  line_rec.LANGUAGE 		,
                  line_rec.SOURCE_LANG 		,
                  line_rec.CREATED_BY 		,
                  line_rec.CREATION_DATE 		,
                  line_rec.LAST_UPDATED_BY 	,
                  line_rec.LAST_UPDATE_DATE 	,
                  line_rec.LAST_UPDATE_LOGIN 	,
                  line_rec.REQUEST_ID 		,
                  line_rec.PROGRAM_APPLICATION_ID 	,
                  line_rec.PROGRAM_ID 		,
                  line_rec.PROGRAM_UPDATE_DATE 	,
                  line_rec.ATTRIBUTE_CATEGORY 	,
                  line_rec.ATTRIBUTE1 		,
                  line_rec.ATTRIBUTE2 		,
                  line_rec.ATTRIBUTE3 		,
                  line_rec.ATTRIBUTE4 		,
                  line_rec.ATTRIBUTE5 		,
                  line_rec.ATTRIBUTE6 		,
                  line_rec.ATTRIBUTE7 		,
                  line_rec.ATTRIBUTE8 		,
                  line_rec.ATTRIBUTE9 		,
                  line_rec.ATTRIBUTE10 		,
                  line_rec.ATTRIBUTE11 		,
                  line_rec.ATTRIBUTE12 		,
                  line_rec.ATTRIBUTE13 		,
                  line_rec.ATTRIBUTE14 		,
                  line_rec.ATTRIBUTE15 		,
                  line_rec.ATTRIBUTE16 		,
                  line_rec.ATTRIBUTE17 		,
                  line_rec.ATTRIBUTE18 		,
                  line_rec.ATTRIBUTE19 		,
                  line_rec.ATTRIBUTE20
                  );
                  
--                  AND     HDR.ATTRIBUTE_CATEGORY =  'SOURCE'
--AND     HDR.ATTRIBUTE1 = 'System Generated'
-- CALL DERANK
                  IF head_rec.ATTRIBUTE_CATEGORY = 'SOURCE' AND head_rec.ATTRIBUTE1 = 'System Generated' THEN
                  DE_RANK (party_site_rec.PARTY_SITE_ID,
                            'CONTACT_AFTER_DT',
                            line_rec.FDK_VALUE,
                            l_add_lines_tab(indx).FDK_DATE);
                  END IF;
                  
                  --  Line  for ACTIVITY_DT
                  insert into XXSCS_FDBK_LINE_DTL_STG (
                  FDBK_LINE_ID 		,
                  FDBK_ID 		,
                  FDK_CODE 		,
                  FDK_VALUE 		,
                  FDK_TXT 		,
                  FDK_DATE 		,
                  FDK_PICK_VALUE 	,
                  LAST_UPDATED_EMP 	,
                  LANGUAGE 		,
                  SOURCE_LANG 		,
                  CREATED_BY 		,
                  CREATION_DATE 	,
                  LAST_UPDATED_BY 	,
                  LAST_UPDATE_DATE 	,
                  LAST_UPDATE_LOGIN 	,
                  REQUEST_ID 		,
                  PROGRAM_APPLICATION_ID,
                  PROGRAM_ID 		,
                  PROGRAM_UPDATE_DATE 	,
                  ATTRIBUTE_CATEGORY 	,
                  ATTRIBUTE1 		,
                  ATTRIBUTE2 		,
                  ATTRIBUTE3 		,
                  ATTRIBUTE4 		,
                  ATTRIBUTE5 		,
                  ATTRIBUTE6 		,
                  ATTRIBUTE7 		,
                  ATTRIBUTE8 		,
                  ATTRIBUTE9 		,
                  ATTRIBUTE10 		,
                  ATTRIBUTE11 		,
                  ATTRIBUTE12 		,
                  ATTRIBUTE13 		,
                  ATTRIBUTE14 		,
                  ATTRIBUTE15 		,
                  ATTRIBUTE16 		,
                  ATTRIBUTE17 		,
                  ATTRIBUTE18 		,
                  ATTRIBUTE19 		,
                  ATTRIBUTE20
                  ) values
                  (
                  XXSCS_FDBK_LINE_ID_S.nextval	,  -- get from sequence
                  XXSCS_FDBK_ID_S.currval 	,
                  'ACTY_DT' 		,
                  line_rec.FDK_VALUE 		,
                  line_rec.FDK_TXT 		,
                  l_add_lines_tab(indx).ACTIVITY_DATE 	,
                  'FDK_DATE'                    ,
                  line_rec.LAST_UPDATED_EMP 	,
                  line_rec.LANGUAGE 		,
                  line_rec.SOURCE_LANG 		,
                  line_rec.CREATED_BY 		,
                  line_rec.CREATION_DATE 		,
                  line_rec.LAST_UPDATED_BY 	,
                  line_rec.LAST_UPDATE_DATE 	,
                  line_rec.LAST_UPDATE_LOGIN 	,
                  line_rec.REQUEST_ID 		,
                  line_rec.PROGRAM_APPLICATION_ID 	,
                  line_rec.PROGRAM_ID 		,
                  line_rec.PROGRAM_UPDATE_DATE 	,
                  line_rec.ATTRIBUTE_CATEGORY 	,
                  line_rec.ATTRIBUTE1 		,
                  line_rec.ATTRIBUTE2 		,
                  line_rec.ATTRIBUTE3 		,
                  line_rec.ATTRIBUTE4 		,
                  line_rec.ATTRIBUTE5 		,
                  line_rec.ATTRIBUTE6 		,
                  line_rec.ATTRIBUTE7 		,
                  line_rec.ATTRIBUTE8 		,
                  line_rec.ATTRIBUTE9 		,
                  line_rec.ATTRIBUTE10 		,
                  line_rec.ATTRIBUTE11 		,
                  line_rec.ATTRIBUTE12 		,
                  line_rec.ATTRIBUTE13 		,
                  line_rec.ATTRIBUTE14 		,
                  line_rec.ATTRIBUTE15 		,
                  line_rec.ATTRIBUTE16 		,
                  line_rec.ATTRIBUTE17 		,
                  line_rec.ATTRIBUTE18 		,
                  line_rec.ATTRIBUTE19 		,
                  line_rec.ATTRIBUTE20
                  );
          END LOOP; -- new lines
        END IF;
        END LOOP;   -- new header    
        
      END LOOP;     -- party sites
        END LOOP; -- processing rows in pl/sql table

  -- update lines not to be picked again incase of non-clearing of stage data by GDW
  commit;
  EXIT WHEN l_add_lines_tab.COUNT < g_limit;
  -- DELETE ENTITY_TYPE = PARTY RECORDS
  -- SET CREATION_DATE = TASK_LAST_UPDATE_DATE ( ADD LOGIC) IN HEADER
END LOOP;

close  c_add_lines;

      UPDATE  apps.XXSCS_FDBK_HDR_STG        
      SET     attribute2 = 'Processed' ;
-- set unique creation_date values
set_unique_date;

commit;

END load_feedback_add_hdr_lines;

-- Load into feedback Header Staging Table
procedure load_feedback_hdr(  x_errbuf	  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                           )  AS
-- source table  XXSCS_FDBK_HDR
-- target table  XXSCS_FDBK_HDR_STG
TYPE XXSCS_FDBK_HDR_typ IS TABLE OF XXCRM.XXSCS_FDBK_HDR_STG%ROWTYPE INDEX BY PLS_INTEGER;
t_XXSCS_FDBK_HDR XXSCS_FDBK_HDR_typ;
TYPE FDBK_ID_typ IS TABLE OF XXSCS_FDBK_HDR_STG.FDBK_ID%TYPE index by PLS_INTEGER;
t_fdbk_id FDBK_ID_typ;

CURSOR  c_XXSCS_FDBK_HDR IS
select  FDBK_ID 		,
	CUSTOMER_ACCOUNT_ID 	,
	ADDRESS_ID 		,
	PARTY_SITE_ID 		,
	PARTY_ID 		,
	MASS_APPLY_FLAG 	,
	CONTACT_ID 		,
	LAST_UPDATED_EMP 	,
	SALES_TERRITORY_ID 	,
	RESOURCE_ID 		,
	ROLE_ID 		,
	GROUP_ID 		,
	LANGUAGE 		,
	SOURCE_LANG 		,
	CREATED_BY 		,
	CREATION_DATE 		,
	LAST_UPDATED_BY 	,
	LAST_UPDATE_DATE 	,
	LAST_UPDATE_LOGIN 	,
	REQUEST_ID 		,
	PROGRAM_APPLICATION_ID  ,
	PROGRAM_ID 		,
	PROGRAM_UPDATE_DATE 	,
	ATTRIBUTE_CATEGORY	,
	ATTRIBUTE1 		,
	ATTRIBUTE2 		,
	ATTRIBUTE3 		,
	ATTRIBUTE4 		,
	ATTRIBUTE5 		,
	ATTRIBUTE6 		,
	ATTRIBUTE7 		,
	ATTRIBUTE8 		,
	ATTRIBUTE9 		,
	ATTRIBUTE10 		,
	ATTRIBUTE11 		,
	ATTRIBUTE12 		,
	ATTRIBUTE13 		,
	ATTRIBUTE14 		,
	ATTRIBUTE15 		,
	ATTRIBUTE16 		,
	ATTRIBUTE17 		,
	ATTRIBUTE18 		,
	ATTRIBUTE19 		,
	ATTRIBUTE20 		,
	ENTITY_ID 		,
	ENTITY_TYPE
FROM   XXSCS_FDBK_HDR
WHERE  EXTRACT_FLAG IS NULL OR EXTRACT_FLAG = 'E';

BEGIN
      fnd_file.put_line (fnd_file.log,'Entering load_feedback_hdr');
      x_retcode := 'S';
      
      OPEN c_XXSCS_FDBK_HDR;
      LOOP
        FETCH c_XXSCS_FDBK_HDR bulk collect into t_XXSCS_FDBK_HDR limit g_limit;
        
        BEGIN
          FORALL  indx IN t_XXSCS_FDBK_HDR.FIRST..t_XXSCS_FDBK_HDR.LAST SAVE EXCEPTIONS
            insert into xxcrm.XXSCS_FDBK_HDR_STG values  t_XXSCS_FDBK_HDR(indx)
            returning FDBK_ID bulk collect into t_fdbk_id;
        EXCEPTION
         WHEN bulk_errors
         THEN
            fnd_file.put_line (fnd_file.log,'Start *** Errors-Insert-XXSCS_FDBK_HDR_STG');
            FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT    LOOP
              DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
              fnd_file.put(fnd_file.log,'FDBK_ID ' || t_XXSCS_FDBK_HDR(SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX).FDBK_ID || ':');
              fnd_file.put_line (fnd_file.log,'Error Code' || SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
            END LOOP;
            fnd_file.put_line (fnd_file.log,'End *** Errors-Insert-XXSCS_FDBK_HDR_STG');
         END;
         
         BEGIN
          FORALL  indx IN t_fdbk_id.FIRST..t_fdbk_id.LAST SAVE EXCEPTIONS
          UPDATE  XXSCS_FDBK_HDR  SET EXTRACT_FLAG = 'P'
          WHERE   FDBK_ID = t_fdbk_id(indx);
         EXCEPTION
         WHEN bulk_errors
         THEN
            fnd_file.put_line (fnd_file.log,'Start *** Errors-Update-XXSCS_FDBK_HDR');
            FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT    LOOP
              DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
              fnd_file.put(fnd_file.log,'FDBK_ID ' || t_fdbk_id(SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX) || ':');
              fnd_file.put_line (fnd_file.log,'Error Code' || SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
            END LOOP;
            fnd_file.put_line (fnd_file.log,'End *** Errors-Update-XXSCS_FDBK_HDR');
         END;
         
          COMMIT;
          EXIT WHEN  t_XXSCS_FDBK_HDR.COUNT < g_limit ;
          
      END LOOP;
      
      CLOSE c_XXSCS_FDBK_HDR;
      fnd_file.put_line (fnd_file.log,'Exiting load_feedback_hdr');
EXCEPTION WHEN OTHERS THEN
      x_retcode := 'E';
      x_errbuf  := SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in load_feedback_hdr ' || x_errbuf);
END load_feedback_hdr;

-- Procedure to mark feedback lines as inactive 'I' for the below conditions.
procedure mark_error_lines IS

cursor  c_error_lines IS
        select  fdbk_id , fdk_code, min(fdbk_line_id) AS m_fdbk_line_id
        from    xxscs_fdbk_line_dtl
        where   fdk_code IN (
                'ACTY_DT',
                'CONTACT_ID',
                'CONTACT_NOTES_TXT',
                'CONTACT_AFTER_DATE',
                'KEYED_SIC_GROUP_CD',
                'OD_WHITE_COLLAR_WORKER_CNT' )
        AND  EXTRACT_FLAG IS NULL OR EXTRACT_FLAG = 'E'
        group by fdbk_id,fdk_code
        having count(1) > 1;
BEGIN
        for rec_error_lines IN c_error_lines  loop
        update  xxscs_fdbk_line_dtl
        set     EXTRACT_FLAG = 'I'
        where   fdbk_id = rec_error_lines.fdbk_id
        and     fdk_code =  rec_error_lines.fdk_code
        and     fdbk_line_id <> rec_error_lines.m_fdbk_line_id;
        
        commit;
        
      end loop;
EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' mark_error_lines ');
END mark_error_lines;

-- Load into feedback Line Detail Staging Table
procedure load_feedback_line( x_errbuf	  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                            )  IS
-- source table  XXSCS_FDBK_LINE_DTL
-- target table  XXSCS_FDBK_LINE_DTL_STG
TYPE XXSCS_FDBK_LINE_typ IS TABLE OF XXSCS_FDBK_LINE_DTL_STG%ROWTYPE INDEX BY PLS_INTEGER;
t_XXSCS_FDBK_LINE XXSCS_FDBK_LINE_typ;
TYPE FDBK_LINE_ID_typ IS TABLE OF XXSCS_FDBK_LINE_DTL.FDBK_LINE_ID%TYPE INDEX BY
PLS_INTEGER;
t_FDBK_LINE_ID  FDBK_LINE_ID_typ;
CURSOR c_XXSCS_FDBK_LINE IS
select  FDBK_LINE_ID 		,
	FDBK_ID 		,
	FDK_CODE 		,
	FDK_VALUE 		,
	FDK_TXT 		,
	FDK_DATE 		,
	FDK_PICK_VALUE 		,
	LAST_UPDATED_EMP 	,
	LANGUAGE 		,
	SOURCE_LANG 		,
	CREATED_BY 		,
	CREATION_DATE 		,
	LAST_UPDATED_BY 	,
	LAST_UPDATE_DATE 	,
	LAST_UPDATE_LOGIN 	,
	REQUEST_ID 		,
	PROGRAM_APPLICATION_ID 	,
	PROGRAM_ID 		,
	PROGRAM_UPDATE_DATE 	,
	ATTRIBUTE_CATEGORY 	,
	ATTRIBUTE1 		,
	ATTRIBUTE2 		,
	ATTRIBUTE3 		,
	ATTRIBUTE4 		,
	ATTRIBUTE5 		,
	ATTRIBUTE6 		,
	ATTRIBUTE7 		,
	ATTRIBUTE8 		,
	ATTRIBUTE9 		,
	ATTRIBUTE10 		,
	ATTRIBUTE11 		,
	ATTRIBUTE12 		,
	ATTRIBUTE13 		,
	ATTRIBUTE14 		,
	ATTRIBUTE15 		,
	ATTRIBUTE16 		,
	ATTRIBUTE17 		,
	ATTRIBUTE18 		,
	ATTRIBUTE19 		,
	ATTRIBUTE20
FROM   XXSCS_FDBK_LINE_DTL
WHERE  EXTRACT_FLAG IS NULL OR EXTRACT_FLAG = 'E';

BEGIN
      fnd_file.put_line (fnd_file.log,'Entering load_feedback_line');
      x_retcode := 'S';
      mark_error_lines;
      
      OPEN c_XXSCS_FDBK_LINE;
      LOOP
        FETCH c_XXSCS_FDBK_LINE bulk collect into t_XXSCS_FDBK_LINE limit g_limit;
        BEGIN
          FORALL  indx IN t_XXSCS_FDBK_LINE.FIRST..t_XXSCS_FDBK_LINE.LAST SAVE EXCEPTIONS
            insert into XXSCS_FDBK_LINE_DTL_STG values t_XXSCS_FDBK_LINE(indx)
            returning FDBK_LINE_ID bulk collect into t_FDBK_LINE_ID;
        EXCEPTION
         WHEN bulk_errors
         THEN
            fnd_file.put_line (fnd_file.log,'Start *** Errors-Insert-XXSCS_FDBK_LINE_DTL_STG');
            FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT    LOOP
              DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
              fnd_file.put(fnd_file.log,'FDBK_LINE_ID ' || t_XXSCS_FDBK_LINE(SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX).FDBK_LINE_ID || ':');
              fnd_file.put_line (fnd_file.log,'Error Code' || SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
            END LOOP;
            fnd_file.put_line (fnd_file.log,'End *** Errors-Insert-XXSCS_FDBK_LINE_DTL_STG');
         END;
        BEGIN
          FORALL  indx IN t_XXSCS_FDBK_LINE.FIRST..t_XXSCS_FDBK_LINE.LAST SAVE EXCEPTIONS
          UPDATE  XXSCS_FDBK_LINE_DTL  SET EXTRACT_FLAG = 'P'
          WHERE   FDBK_LINE_ID = t_FDBK_LINE_ID(indx);
        EXCEPTION
         WHEN bulk_errors
         THEN
            fnd_file.put_line (fnd_file.log,'Start *** Errors-Update-XXSCS_FDBK_LINE_DTL');
            FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT    LOOP
              DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
              fnd_file.put(fnd_file.log,'FDBK_LINE_ID ' || t_FDBK_LINE_ID(SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX) || ':');
              fnd_file.put_line (fnd_file.log,'Error Code' || SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
            END LOOP;
            fnd_file.put_line (fnd_file.log,'End *** Errors-Update-XXSCS_FDBK_LINE_DTL');
         END;
         
          COMMIT;
          EXIT WHEN t_XXSCS_FDBK_LINE.COUNT < g_limit;
      END LOOP;
      
      CLOSE c_XXSCS_FDBK_LINE;
      fnd_file.put_line (fnd_file.log,'Exiting load_feedback_line');
EXCEPTION WHEN OTHERS THEN
      x_retcode := 'E';
      x_errbuf  := SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in load_feedback_line ' || x_errbuf);
END load_feedback_line;

-- -- Load into feedback Question Staging Table
procedure load_feedback_qstn( x_errbuf	  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                            )  IS
-- source table XXSCS_FDBK_QSTN
-- target table XXSCS_FDBK_QSTN_STG
TYPE XXSCS_FDBK_QSTN_typ IS TABLE OF XXSCS_FDBK_QSTN_STG%ROWTYPE INDEX BY PLS_INTEGER;
t_XXSCS_FDBK_QSTN XXSCS_FDBK_QSTN_typ;
TYPE FDBK_QSTN_ID_typ IS TABLE OF XXSCS_FDBK_QSTN.FDBK_QSTN_ID%TYPE INDEX BY PLS_INTEGER;
t_FDBK_QSTN_ID_typ FDBK_QSTN_ID_typ;

CURSOR c_XXSCS_FDBK_QSTN IS
select  FDBK_QSTN_ID 		,
	FDK_CODE 		,
	FDK_CODE_DESC 		,
	FDK_GDW_CODE 		,
	FDK_GDW_CODE_DESC 	,
	EFFECTIVE_START_DT 	,
	EFFECTIVE_END_DT 	,
	FDK_TYPE 		,
	SORT_SEQ 		,
	LANGUAGE 		,
	SOURCE_LANG 		,
	CREATED_BY 		,
	CREATION_DATE 		,
	LAST_UPDATED_BY 	,
	LAST_UPDATE_DATE 	,
	LAST_UPDATE_LOGIN 	,
	REQUEST_ID 		,
	PROGRAM_APPLICATION_ID  ,
	PROGRAM_ID 		,
	PROGRAM_UPDATE_DATE 	,
	ATTRIBUTE_CATEGORY 	,
	ATTRIBUTE1 		,
	ATTRIBUTE2 		,
	ATTRIBUTE3 		,
	ATTRIBUTE4 		,
	ATTRIBUTE5 		,
	ATTRIBUTE6 		,
	ATTRIBUTE7 		,
	ATTRIBUTE8 		,
	ATTRIBUTE9 		,
	ATTRIBUTE10 		,
	ATTRIBUTE11 		,
	ATTRIBUTE12 		,
	ATTRIBUTE13 		,
	ATTRIBUTE14	 	,
	ATTRIBUTE15 		,
	ATTRIBUTE16 		,
	ATTRIBUTE17 		,
	ATTRIBUTE18 		,
	ATTRIBUTE19 		,
	ATTRIBUTE20 		,
	FRM_CODE 		,
	GDW_PICK_FLAG 		,
	ORA_SEQ 		,
	FDK_PICK_VALUE 		,
	FDK_HDR_FLAG 		,
	ORA_PICK_FLAG 		,
	ACTION_CODE 		,
	REQUIRED 		,
	OPPORTUNITY 		,
	LEAD 			,
	ACTION_STATUS 		,
	ACTION_TYPE 		,
	MIN_RANGE 		,
	MAX_RANGE 		,
	NUMBER_ONLY 		,
	ENTITY_STATUS 		,
	ENTITY_REASON 		,
	MULTI_RESULT
FROM    XXSCS_FDBK_QSTN
WHERE   GDW_PICK_FLAG = 'Y';
-- Pick only GDW_PICK_FLAG = 'Y';

BEGIN
      fnd_file.put_line (fnd_file.log,'Entering load_feedback_qstn');
      x_retcode := 'S';
      -- Delete from XXSCS_FDBK_QSTN_STG
      DELETE
      FROM    XXSCS_FDBK_QSTN_STG;
      OPEN c_XXSCS_FDBK_QSTN;
      
      LOOP
          FETCH c_XXSCS_FDBK_QSTN bulk collect into t_XXSCS_FDBK_QSTN limit g_limit;
          
          BEGIN
                FORALL  indx IN t_XXSCS_FDBK_QSTN.FIRST..t_XXSCS_FDBK_QSTN.LAST SAVE EXCEPTIONS
                  insert into XXSCS_FDBK_QSTN_STG values t_XXSCS_FDBK_QSTN(indx) RETURNING
                  FDBK_QSTN_ID BULK COLLECT INTO t_FDBK_QSTN_ID_typ;
                EXCEPTION
                WHEN bulk_errors
                THEN
                    fnd_file.put_line (fnd_file.log,'Start *** Errors-Insert-XXSCS_FDBK_QSTN_STG');
                    
                    FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT    LOOP
                        DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
                        fnd_file.put(fnd_file.log,'FDBK_QSTN_ID ' || t_XXSCS_FDBK_QSTN(SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX).FDBK_QSTN_ID || ':');
                        fnd_file.put_line (fnd_file.log,'Error Code' || SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
                    END LOOP;
                    fnd_file.put_line (fnd_file.log,'End *** Errors-Insert-XXSCS_FDBK_QSTN_STG');
                END;
               BEGIN
                    FORALL  indx IN t_XXSCS_FDBK_QSTN.FIRST..t_XXSCS_FDBK_QSTN.LAST SAVE EXCEPTIONS
                    UPDATE  XXSCS_FDBK_QSTN  SET EXTRACT_DATE = SYSDATE
                    WHERE   FDBK_QSTN_ID = t_FDBK_QSTN_ID_typ(indx);
               EXCEPTION
               WHEN bulk_errors
               THEN
                    fnd_file.put_line (fnd_file.log,'Start *** Errors-Update-XXSCS_FDBK_QSTN');
                    FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT    LOOP
                      DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
                      fnd_file.put(fnd_file.log,'FDBK_QSTN_ID ' || t_FDBK_QSTN_ID_typ(SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX) || ':');
                      fnd_file.put_line (fnd_file.log,'Error Code' || SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
                    END LOOP;
                    fnd_file.put_line (fnd_file.log,'End *** Errors-Update-XXSCS_FDBK_QSTN');
           END;
          COMMIT;
          
          EXIT WHEN t_XXSCS_FDBK_QSTN.COUNT < g_limit ;
      END LOOP;
      
      CLOSE c_XXSCS_FDBK_QSTN;
      fnd_file.put_line (fnd_file.log,'Exiting load_feedback_qstn');
EXCEPTION WHEN OTHERS THEN
      x_retcode := 'E';
      x_errbuf  := SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in load_feedback_qstn ' || x_errbuf);
END load_feedback_qstn;

-- -- Load into feedback Response Staging Table
procedure load_feedback_resp( x_errbuf	  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                            )  IS
-- source table XXSCS_FDBK_RESP
-- target table XXSCS_FDBK_RESP_STG
TYPE XXSCS_FDBK_RESP_typ IS TABLE OF XXSCS_FDBK_RESP_STG%ROWTYPE INDEX BY PLS_INTEGER;
t_XXSCS_FDBK_RESP XXSCS_FDBK_RESP_typ;
TYPE FDBK_RESP_ID_typ IS TABLE OF XXSCS_FDBK_RESP.FDBK_RESP_ID%TYPE INDEX BY PLS_INTEGER;
t_FDBK_RESP_ID FDBK_RESP_ID_typ;

CURSOR c_XXSCS_FDBK_RESP IS
select  FDBK_RESP_ID 		,
	FDBK_QSTN_ID 		,
	FDK_CODE 		,
	FDK_VALUE 		,
	FDK_VALUE_DESC 		,
	FDK_GDW_CODE 		,
	FDK_GDW_VALUE	 	,
	FDK_GDW_VALUE_DESC 	,
	EFFECTIVE_START_DT 	,
	EFFECTIVE_END_DT 	,
	LANGUAGE 		,
	SOURCE_LANG 		,
	CREATED_BY 		,
	CREATION_DATE 		,
	LAST_UPDATED_BY 	,
	LAST_UPDATE_DATE 	,
	LAST_UPDATE_LOGIN 	,
	REQUEST_ID 		,
	PROGRAM_APPLICATION_ID	,
	PROGRAM_ID 		,
	PROGRAM_UPDATE_DATE 	,
	ATTRIBUTE_CATEGORY 	,
	ATTRIBUTE1 		,
	ATTRIBUTE2 		,
	ATTRIBUTE3 		,
	ATTRIBUTE4 		,
	ATTRIBUTE5 		,
	ATTRIBUTE6 		,
	ATTRIBUTE7 		,
	ATTRIBUTE8 		,
	ATTRIBUTE9 		,
	ATTRIBUTE10 		,
	ATTRIBUTE11 		,
	ATTRIBUTE12 		,
	ATTRIBUTE13 		,
	ATTRIBUTE14 		,
	ATTRIBUTE15 		,
	ATTRIBUTE16 		,
	ATTRIBUTE17 		,
	ATTRIBUTE18 		,
	ATTRIBUTE19 		,
	ATTRIBUTE20 		,
	ORA_PICK_FLAG 		,
	GDW_PICK_FLAG 		,
	ACTION_CODE 		,
	OPPORTUNITY 		,
	LEAD 			,
	ACTION_STATUS 		,
	ACTION_TYPE 		,
	ORA_SEQ 		,
	ENTITY_STATUS 		,
	ENTITY_REASON
FROM    XXSCS_FDBK_RESP
WHERE   GDW_PICK_FLAG = 'Y';
-- Pick only GDW_PICK_FLAG = 'Y';

BEGIN
      fnd_file.put_line (fnd_file.log,'Entering load_feedback_resp');
      x_retcode := 'S';
      -- Delete entries from XXSCS_FDBK_RESP_STG;
      delete
      from  XXSCS_FDBK_RESP_STG;
      
      OPEN c_XXSCS_FDBK_RESP;
      LOOP
          FETCH c_XXSCS_FDBK_RESP bulk collect into t_XXSCS_FDBK_RESP limit g_limit;
          
          BEGIN
              FORALL indx IN t_XXSCS_FDBK_RESP.FIRST..t_XXSCS_FDBK_RESP.LAST SAVE EXCEPTIONS
              insert into XXSCS_FDBK_RESP_STG values t_XXSCS_FDBK_RESP(indx)
              RETURNING FDBK_RESP_ID BULK COLLECT INTO t_FDBK_RESP_ID;
          EXCEPTION
           WHEN bulk_errors
           THEN
              fnd_file.put_line (fnd_file.log,'Start *** Errors-Insert-XXSCS_FDBK_RESP_STG');
              FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT    LOOP
                DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
                fnd_file.put(fnd_file.log,'FDBK_RESP_ID ' || t_XXSCS_FDBK_RESP(SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX).FDBK_RESP_ID || ':');
                fnd_file.put_line (fnd_file.log,'Error Code' || SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
              END LOOP;
              fnd_file.put_line (fnd_file.log,'End *** Errors-Insert-XXSCS_FDBK_RESP_STG');
           END;
           
           BEGIN
                FORALL  indx IN t_XXSCS_FDBK_RESP.FIRST..t_XXSCS_FDBK_RESP.LAST SAVE EXCEPTIONS
                UPDATE  XXSCS_FDBK_RESP  SET EXTRACT_DATE = SYSDATE
                WHERE   FDBK_RESP_ID = t_FDBK_RESP_ID(indx);
          EXCEPTION
          WHEN bulk_errors
          THEN
              fnd_file.put_line (fnd_file.log,'Start *** Errors-Update-XXSCS_FDBK_RESP');
              FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT    LOOP
                DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
                fnd_file.put(fnd_file.log,'FDBK_RESP_ID ' || t_FDBK_RESP_ID(SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX) || ':');
                fnd_file.put_line (fnd_file.log,'Error Code' || SQL%BULK_EXCEPTIONS(indx).ERROR_CODE);
              END LOOP;
              fnd_file.put_line (fnd_file.log,'End *** Errors-Update-XXSCS_FDBK_RESP');
          END;
          
          COMMIT;
          EXIT WHEN t_XXSCS_FDBK_RESP.COUNT < g_limit ;
      END LOOP;
      
      CLOSE c_XXSCS_FDBK_RESP;
      fnd_file.put_line (fnd_file.log,'Exiting load_feedback_resp');
EXCEPTION WHEN OTHERS THEN
  x_retcode := 'E';
  x_errbuf  := SQLERRM;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in load_feedback_resp ' || x_errbuf);
END load_feedback_resp;

function count_diff(
                    p_attr_group_id IN HZ_PARTY_SITES_EXT_B.attr_group_id%type,
                    p_party_site IN HZ_PARTY_SITES_EXT_B.party_site_id%TYPE,
                    p_wcw_count  IN HZ_PARTY_SITES_EXT_B.N_EXT_ATTR8%type)
return varchar2 IS
v_cnt  NUMBER;
BEGIN
      --fnd_file.put_line(fnd_file.log, 'value of p_attr_group_id '  || p_attr_group_id);
      --fnd_file.put_line(fnd_file.log, 'value of p_party_site '  || p_party_site);
      --fnd_file.put_line(fnd_file.log, 'value of p_wcw_count '  || p_wcw_count);
      
      select nvl(N_EXT_ATTR8,-1)  INTO v_cnt
      from   HZ_PARTY_SITES_EXT_B
      where  extension_id = (
              select max(extension_id)
              from   HZ_PARTY_SITES_EXT_B
              where  party_site_id = p_party_site
              and    attr_group_id = p_attr_group_id );
              
       IF  v_cnt = nvl(p_wcw_count,-1) THEN
            return 'N' ;
       END IF;
            return 'Y';
      EXCEPTION WHEN OTHERS THEN
          return 'Y';
          
END count_diff;

function count_diff_sic(
                        p_attr_group_id IN HZ_PARTY_SITES_EXT_B.attr_group_id%type,
                        p_party_site    IN HZ_PARTY_SITES_EXT_B.party_site_id%TYPE,
                        p_sic           IN HZ_PARTY_SITES_EXT_B.C_EXT_ATTR10%type)
return varchar2 IS
v_cnt  NUMBER;
BEGIN
      --fnd_file.put_line(fnd_file.log, 'value of p_attr_group_id '  || p_attr_group_id);
      --fnd_file.put_line(fnd_file.log, 'value of p_party_site '  || p_party_site);
      --fnd_file.put_line(fnd_file.log, 'value of p_wcw_count '  || p_wcw_count);
      
      select nvl(C_EXT_ATTR10,-1)  INTO v_cnt
      from   HZ_PARTY_SITES_EXT_B
      where  extension_id = (
              select max(extension_id)
              from   HZ_PARTY_SITES_EXT_B
              where  party_site_id = p_party_site
              and    attr_group_id = p_attr_group_id );
       IF  v_cnt = nvl(p_sic,-1) THEN
            return 'N' ;
       END IF;
            return 'Y';
            
EXCEPTION WHEN OTHERS THEN
    return 'Y';
END count_diff_sic;

function get_fdbk_lines(
                        p_last_extract_dt IN DATE,
                        p_extract_to_dt   IN DATE,
                        p_attr_group_id   IN EGO_ATTR_GROUPS_V.attr_group_id%TYPE)
return SYS_REFCURSOR IS
v_cnt                 NUMBER;
v_attr_group_id       EGO_ATTR_GROUPS_V.attr_group_id%type;
v_last_upd_date       VARCHAR2(20);
v_last_ext_date       DATE;
v_pick_prospect_value VARCHAR2(10);
l_cursor          SYS_REFCURSOR;

BEGIN
fnd_profile.get('XXSCS_PICK_PROSPECT', v_pick_prospect_value);
IF  upper(v_pick_prospect_value) = 'Y'   THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'XXSCS_PICK_PROSPECT = Y ' || ' Picking prospects ');
open l_cursor FOR
SELECT *
FROM  (
------------------------------------------------------------
-- Leads Closed
------------------------------------------------------------
SELECT    substr(hps.orig_system_reference,1,instr(hps.orig_system_reference,'-',1,1)-1) customer_account_id,
          to_number(substr(hps.orig_system_reference,instr(hps.orig_system_reference,'-',1,1)+1,instr(hps.orig_system_reference,'-',1,2)-instr(hps.orig_system_reference,'-',1,1)-1)) address_id,
          ASL.address_id party_site_id,
          ASL.customer_id party_id,
          ASL.last_update_date update_date, --fdbk creation_date last_update_date
          ASL.last_updated_by updated_by, --fdbk created_by updated by
         'LEAD'               entity_type,
          null task_id,
          ASL.sales_lead_id    entity_id,
          'FLWP_AGCL' fdk_code,
          'NFUR' fdk_value,
           NULL fdk_date   ,
         'FDK_VALUE'  FDK_PICK_VALUE,
          usr.user_name 
FROM      apps.AS_SALES_LEADS           ASL,
          apps.hz_party_sites           hps,
          apps.fnd_user                 usr
WHERE     ASL.address_id = hps.party_site_id
AND       nvl(ASL.deleted_flag,'N') = 'N'
AND       usr.user_id = ASL.last_updated_by 
AND       status_open_flag = 'N'
AND       close_reason = 'NO_FOLLOWUP_REQUIRED'
AND       asl.last_update_date BETWEEN p_last_extract_dt and p_extract_to_dt
and       not exists (  select 1
                        FROM    xxcrm.xxscs_fdbk_hdr h,
                                xxcrm.xxscs_fdbk_line_dtl d
                        where   h.fdbk_id=d.fdbk_id
                        and     d.last_update_date BETWEEN p_last_extract_dt and p_extract_to_dt
                        and     h.entity_id= asl.sales_lead_id
                        and     h.entity_type='LEAD'
                        and     fdk_code= 'FLWP_AGCL'               
                        and     fdk_value= 'NFUR'  )

UNION ALL
------------------------------------------------------------------
-- Tasks Created for Leads , Opportunities , Parties , Party Sites
-------------------------------------------------------------------

SELECT  decode(a.ENTITY_TYPE,
              'PARTY', substr(hzp.orig_system_reference,1,instr(hzp.orig_system_reference,'-',1,1)-1),
              substr(hps.orig_system_reference,1,instr(hps.orig_system_reference,'-',1,1)-1) ) customer_account_id,
        to_number(decode( a.entity_type,
                          'PARTY',substr(hzp.orig_system_reference,instr(hzp.orig_system_reference,'-',1,1)+1,instr(hzp.orig_system_reference,'-',1,2)-instr(hzp.orig_system_reference,'-',1,1)-1),
                          substr(hps.orig_system_reference,instr(hps.orig_system_reference,'-',1,1)+1,instr(hps.orig_system_reference,'-',1,2)-instr(hps.orig_system_reference,'-',1,1)-1))) address_id,
        a.party_site_id party_site_id,
        a.party_id party_id,
        a.task_update_date, -- for records to process, creation and last udpated date in fdbk hdr and dtl
        a.task_created_by created_by, -- for created by and last udpated by in fdbk hdr and dtl
        decode(a.ENTITY_TYPE,
              'OD_PARTY_SITE','PARTY_SITE',
              a.entity_type)entity_type,
        a.task_id,
        a.entity_id entity_id,
        a.fdbk_code fdbk_code,
        NULL fdk_value,
        a.task_date fdk_date,
        'FDK_DATE'   FDK_PICK_VALUE,
        a.user_name
FROM    (
        SELECT  TSK.source_object_type_code ENTITY_TYPE,
                tsk.source_object_id ENTITY_ID,
                decode( TSK.source_object_type_code,
                          'OPPORTUNITY',  OPP.customer_id,
                          'LEAD'       , LEAD.customer_id,
                          tsk.customer_id) party_id,
              --  tsk.customer_id  party_id,
                decode(TSK.source_object_type_code,
                      'OD_PARTY_SITE',tsk.source_object_id,
                      tsk.address_id) party_site_id,
                TSK.creation_date task_creation_date,
                TSK.last_update_date  task_update_date,                
                TSK.created_by    task_created_by,
                TSK.task_id,
                usr.user_name,
                TSK.scheduled_end_date task_date,
                TSKTYP.name task_type,
                CASE WHEN trunc(TSK.scheduled_end_date) <= trunc(TSK.last_update_date)
                THEN 'ACTY_DT'
                ELSE 'CONTACT_AFTER_DATE'
                END fdbk_code,
                CASE  WHEN trunc(TSK.scheduled_end_date) <= trunc(TSK.last_update_date)
                      THEN TSKSTAT.name
                      ELSE NULL
                END   tsk_status
        FROM    apps.JTF_TASKS_VL             TSK,
                apps.jtf_task_types_vl        TSKTYP,
                apps.jtf_task_statuses_vl     TSKSTAT,
                apps.AS_SALES_LEADS           LEAD,  -- leads
                apps.AS_LEADS_ALL             OPP,   -- opportunities
                apps.fnd_user                 usr
        WHERE   TSKTYP.task_type_id = TSK.task_type_id
        AND   	TSKSTAT.task_status_id = TSK.task_status_id 
        AND     usr.user_id= TSK.created_by   
        AND     TSK.scheduled_end_date IS NOT NULL
        AND     TSK.source_object_id = OPP.lead_id(+)
        AND     TSK.source_object_id = LEAD.sales_lead_id(+)
        AND     nvl(LEAD.deleted_flag,'N') = 'N'
        AND     nvl(OPP.deleted_flag,'N') = 'N' 
        AND   	TSKTYP.name in (select  source_value1
                                from    apps.XX_FIN_TRANSLATEVALUES
                                where   translate_id IN (
                                SELECT  translate_id
                                FROM    apps.XX_FIN_TRANSLATEDEFINITION
                                WHERE   TRANSLATION_NAME = 'OD_SCS_TASK_TYPE'))
        and     TSK.source_object_type_code IN ('LEAD','OPPORTUNITY','OD_PARTY_SITE','PARTY')
        and     TSK.last_update_date between   p_last_extract_dt and p_extract_to_dt
         -- additional condition
        AND     TSK.task_id NOT IN (
                                SELECT  attribute1
                                from    apps.xxscs_fdbk_line_dtl
                                where   attribute_category = 'TASK_ID'
                                and     last_update_date between  p_last_extract_dt and p_extract_to_dt
                                AND     TSK.CREATION_DATE = TSK.LAST_UPDATE_DATE
                                )
        ) a,
        apps.hz_party_sites hps,
        apps.hz_parties     hzp
WHERE   a.party_site_id = hps.party_site_id(+)
and     a.party_id = hzp.party_id
and     nvl(tsk_status,'Completed')  in ( select  source_value1
        from    apps.XX_FIN_TRANSLATEVALUES
        where   translate_id IN (
        SELECT  translate_id
        FROM    apps.XX_FIN_TRANSLATEDEFINITION
        WHERE   TRANSLATION_NAME = 'OD_SCS_TASK_STATUS'))

UNION ALL
-- Additional Lines
SELECT  decode(a.ENTITY_TYPE,
              'PARTY', substr(hzp.orig_system_reference,1,instr(hzp.orig_system_reference,'-',1,1)-1),
              substr(hps.orig_system_reference,1,instr(hps.orig_system_reference,'-',1,1)-1) ) customer_account_id,
        to_number(decode( a.entity_type,
                          'PARTY',substr(hzp.orig_system_reference,instr(hzp.orig_system_reference,'-',1,1)+1,instr(hzp.orig_system_reference,'-',1,2)-instr(hzp.orig_system_reference,'-',1,1)-1),
                          substr(hps.orig_system_reference,instr(hps.orig_system_reference,'-',1,1)+1,instr(hps.orig_system_reference,'-',1,2)-instr(hps.orig_system_reference,'-',1,1)-1))) address_id,
        a.party_site_id party_site_id,
        a.party_id party_id,
        a.task_update_date, -- for records to process, creation and last udpated date in fdbk hdr and dtl
        a.task_created_by created_by, -- for created by and last udpated by in fdbk hdr and dtl
        decode(a.ENTITY_TYPE,
              'OD_PARTY_SITE','PARTY_SITE',
              a.entity_type)entity_type,
        a.TASK_ID,
        a.entity_id entity_id,
        a.fdbk_code fdbk_code,
          decode(a.task_type,'In Person Visit','IN_PRSN','Mail','BY_MAIL','Call','BY_PHNE','Email','BY_EMAIL',NULL) fdk_value,
        null fdk_date,
        'FDK_VALUE'  FDK_PICK_VALUE,
        a.user_name
FROM     (SELECT  TSK.source_object_type_code ENTITY_TYPE,
                  tsk.source_object_id ENTITY_ID,
                  decode( TSK.source_object_type_code,
                          'OPPORTUNITY',  OPP.customer_id,
                          'LEAD'       , LEAD.customer_id,
                          tsk.customer_id) party_id,
                 -- tsk.customer_id  party_id,
                 -- tsk.address_id party_site_id,
                  decode( TSK.source_object_type_code,
                          'OD_PARTY_SITE',tsk.source_object_id,
                          'OPPORTUNITY',  OPP.address_id,
                          'LEAD'       , LEAD.address_id,
                          tsk.address_id) party_site_id,
                  TSK.creation_date  task_creation_date,
                  TSK.last_update_date  task_update_date,      
                  TSK.created_by     task_created_by,
                  TSK.task_id,
                  usr.user_name,
                  TSK.scheduled_end_date task_date,
                  TSKTYP.name task_type,		  
                  CASE  WHEN trunc(TSK.scheduled_end_date) <= trunc(TSK.last_update_date)
                        THEN 'CUST_CONTACTED'
                        ELSE 'CONTACT_AFTER_DATE'
                               END   fdbk_code,
                     CASE  WHEN trunc(TSK.scheduled_end_date) <= trunc(TSK.last_update_date)
                        THEN TSKSTAT.name
                        ELSE NULL
                  END   tsk_status
          FROM    apps.JTF_TASKS_VL             TSK,
                  apps.jtf_task_types_vl        TSKTYP,
                  apps.AS_SALES_LEADS           LEAD,  -- leads
                  apps.AS_LEADS_ALL             OPP,   -- opportunities
                  apps.jtf_task_statuses_vl     TSKSTAT   ,
                  apps.fnd_user                 usr
          WHERE   TSKTYP.task_type_id = TSK.task_type_id
          AND     TSK.scheduled_end_date IS NOT NULL
	    AND     usr.user_id= TSK.created_by   
          AND     TSK.source_object_id = OPP.lead_id(+)
          AND     TSK.source_object_id = LEAD.sales_lead_id(+)
          AND     nvl(LEAD.deleted_flag,'N') = 'N'
          AND     nvl(OPP.deleted_flag,'N') = 'N' 
          AND     TSKSTAT.task_status_id = TSK.task_status_id
          AND     TSKTYP.name in (  select  source_value1
                              from    apps.XX_FIN_TRANSLATEVALUES
                              where   translate_id IN (
                                      SELECT  translate_id
                                      FROM    apps.XX_FIN_TRANSLATEDEFINITION
                                      WHERE   TRANSLATION_NAME = 'OD_SCS_TASK_TYPE'))
          and     TSK.source_object_type_code IN ('LEAD','OPPORTUNITY','OD_PARTY_SITE','PARTY')
          and     TSK.last_update_date between   p_last_extract_dt and p_extract_to_dt
          -- additional condition
          AND     TSK.task_id NOT IN (
                                      SELECT  attribute1
                                      from    apps.xxscs_fdbk_line_dtl
                                      where   attribute_category = 'TASK_ID'
                                      and     last_update_date  between p_last_extract_dt and p_extract_to_dt
                                      AND     TSK.CREATION_DATE = TSK.LAST_UPDATE_DATE
                                      )
          ) a,
          apps.hz_party_sites hps,
          apps.hz_parties     hzp
  WHERE   a.party_site_id = hps.party_site_id(+)
  and     a.party_id = hzp.party_id
  and     tsk_status   in (
          select  source_value1
          from    apps.XX_FIN_TRANSLATEVALUES
          where   translate_id IN (
          SELECT  translate_id
          FROM    apps.XX_FIN_TRANSLATEDEFINITION
          WHERE   TRANSLATION_NAME = 'OD_SCS_TASK_STATUS'))

UNION ALL
-- OD white collar worker
-- party_id, party_site_id, entity_type, entity_id
SELECT   substr(hps.orig_system_reference,1, instr(hps.orig_system_reference,'-')-1)    	--CUSTOMER_ACCOUNT_ID
         ,to_number(substr(hps.orig_system_reference, instr(hps.orig_system_reference,'-')+1,5)) --  ADDRESS_ID
         ,HPS.party_site_id        --PARTY_SITE_ID
         ,hps.party_id                               -- PARTY_ID
         ,hpx.last_update_date                       -- creation_DATE                               -- LAST_UPDATED_EMP
         ,hpx.last_updated_by
         ,'PARTY_SITE'                                       -- entity_type
         ,null
         ,hps.party_site_id                                       -- entity_id
         ,'OD_WHITE_COLLAR_WORKER_CNT'  	     -- FDK_CODE
         ,to_char(hpx.N_EXT_ATTR8)                            --FDK_VALUE
         --,NULL                                       -- FDK_TXT
         ,NULL                                       -- FDK_DATE
         ,'FDK_TXT'                                  -- FDK_PICK_VALUE
        ,fu.user_name
FROM    HZ_PARTY_SITES_EXT_B hpx ,
        hz_party_sites       hps,
      --   hz_cust_accounts     hca,
        fnd_user             fu
where   attr_group_id = p_attr_group_id
and     hpx.last_update_date between p_last_extract_dt and p_extract_to_dt
--and     hps.party_id = hca.party_id
--and     count_diff ( p_attr_group_id, HPX.party_site_id , N_EXT_ATTR8) = 'Y'
and     hpx.party_site_id = hps.party_site_id
--and     hpx.N_EXT_ATTR8 is not null
and     fu.user_id = hpx.last_updated_by
AND     fu.user_name NOT IN (
        select  source_value1
        from    XX_FIN_TRANSLATEVALUES
        where   translate_id = (
        SELECT  translate_id
        FROM    XX_FIN_TRANSLATEDEFINITION
        WHERE   TRANSLATION_NAME = 'XXSCS_IGNORE_USERS_FDBK'))
UNION ALL
-- SIC CODE and
SELECT   substr(hps.orig_system_reference,1, instr(hps.orig_system_reference,'-')-1)               -- CUSTOMER_ACCOUNT_ID
         ,to_number(substr(hps.orig_system_reference, instr(hps.orig_system_reference,'-')+1,5))   --  ADDRESS_ID
         ,hps.party_site_id     	--PARTY_SITE_ID
         ,hps.party_id                            	--PARTY_ID
         ,hpx.last_update_date                          --creation_DATE
         ,hpx.last_updated_by
         ,'PARTY_SITE'                                          --entity_type
         ,null
         ,hps.party_site_id                                           --entity_id
         ,'KEYED_SIC_GROUP_CD'          	        --FDK_CODE
         ,hpx.C_EXT_ATTR10                              --FDK_VALUE White Collar Workers
         --,NULL                                  	--FDK_TXT
         ,NULL                                  	--FDK_DATE
         ,'FDK_TXT'                             	--FDK_PICK_VALUE
         ,fu.user_name                          	--LAST_UPDATED_EMP
FROM    HZ_PARTY_SITES_EXT_B hpx ,
        hz_party_sites       hps,
--        hz_cust_accounts     hca,
        fnd_user             fu
where   attr_group_id = p_attr_group_id
and     hpx.last_update_date between p_last_extract_dt and p_extract_to_dt
--and     hps.party_id = hca.party_id
--and     count_diff_sic ( p_attr_group_id, hps.party_site_id , C_EXT_ATTR10) = 'Y'
and     hpx.party_site_id = hps.party_site_id
and     fu.user_id = hpx.last_updated_by
--and     hpx.C_EXT_ATTR10 IS NOT NULL
AND     fu.user_name NOT IN (
        select  source_value1
        from    XX_FIN_TRANSLATEVALUES
        where   translate_id = (
        SELECT  translate_id
        FROM    XX_FIN_TRANSLATEDEFINITION
        WHERE   TRANSLATION_NAME = 'XXSCS_IGNORE_USERS_FDBK')))
ORDER BY PARTY_ID , PARTY_SITE_ID, CUSTOMER_ACCOUNT_ID, ADDRESS_ID, entity_type, entity_id,UPDATE_DATE ,task_id, fdk_code ;

ELSE 
-- only for customer accounts 

FND_FILE.PUT_LINE(FND_FILE.LOG, 'XXSCS_PICK_PROSPECT = N ' || ' Picking customers');

open l_cursor FOR
SELECT *
FROM  (
------------------------------------------------------------
-- Leads Closed
------------------------------------------------------------
SELECT    substr(hps.orig_system_reference,1,instr(hps.orig_system_reference,'-',1,1)-1) customer_account_id,
          to_number(substr(hps.orig_system_reference,instr(hps.orig_system_reference,'-',1,1)+1,instr(hps.orig_system_reference,'-',1,2)-instr(hps.orig_system_reference,'-',1,1)-1)) address_id,
          ASL.address_id party_site_id,
          ASL.customer_id party_id,
          ASL.last_update_date update_date, --fdbk creation_date last_update_date
          ASL.last_updated_by updated_by, --fdbk created_by updated by
         'LEAD'               entity_type,
          null task_id,
          ASL.sales_lead_id    entity_id,
          'FLWP_AGCL' fdk_code,
          'NFUR' fdk_value,
           NULL fdk_date   ,
         'FDK_VALUE'  FDK_PICK_VALUE,
          usr.user_name 
FROM      apps.AS_SALES_LEADS           ASL,
          apps.hz_cust_acct_sites_all   hps,
          apps.fnd_user                 usr
WHERE     ASL.address_id = hps.party_site_id
AND       nvl(ASL.deleted_flag,'N') = 'N'
AND       status_open_flag = 'N'
AND       usr.user_id=ASL.last_updated_by
AND       close_reason = 'NO_FOLLOWUP_REQUIRED'
AND       asl.last_update_date BETWEEN p_last_extract_dt and p_extract_to_dt
and       not exists (  select 1
                        FROM    xxcrm.xxscs_fdbk_hdr h,
                                xxcrm.xxscs_fdbk_line_dtl d
                        where   h.fdbk_id=d.fdbk_id
                        and     d.last_update_date BETWEEN p_last_extract_dt and p_extract_to_dt
                        and     h.entity_id= asl.sales_lead_id
                        and     h.entity_type='LEAD'
                        and     fdk_code= 'FLWP_AGCL'               
                        and     fdk_value= 'NFUR'  )

UNION ALL
------------------------------------------------------------------
-- Tasks Created for Leads , Opportunities , Parties , Party Sites
-------------------------------------------------------------------

SELECT  decode(a.ENTITY_TYPE,
              'PARTY', substr(hzp.orig_system_reference,1,instr(hzp.orig_system_reference,'-',1,1)-1),
              substr(hps.orig_system_reference,1,instr(hps.orig_system_reference,'-',1,1)-1) ) customer_account_id,
        to_number(decode( a.entity_type,
                          'PARTY',substr(hzp.orig_system_reference,instr(hzp.orig_system_reference,'-',1,1)+1,instr(hzp.orig_system_reference,'-',1,2)-instr(hzp.orig_system_reference,'-',1,1)-1),
                          substr(hps.orig_system_reference,instr(hps.orig_system_reference,'-',1,1)+1,instr(hps.orig_system_reference,'-',1,2)-instr(hps.orig_system_reference,'-',1,1)-1))) address_id,
        a.party_site_id party_site_id,
        a.party_id party_id,
        a.task_update_date, -- for records to process, creation and last udpated date in fdbk hdr and dtl
        a.task_created_by created_by, -- for created by and last udpated by in fdbk hdr and dtl
        decode(a.ENTITY_TYPE,
              'OD_PARTY_SITE','PARTY_SITE',
              a.entity_type)entity_type,
        a.task_id,
        a.entity_id entity_id,
        a.fdbk_code fdbk_code,
        NULL fdk_value,
        a.task_date fdk_date,
        'FDK_DATE'   FDK_PICK_VALUE,
        a.user_name
FROM    (
        SELECT  TSK.source_object_type_code ENTITY_TYPE,
                tsk.source_object_id ENTITY_ID,
                decode( TSK.source_object_type_code,
                          'OPPORTUNITY',  OPP.customer_id,
                          'LEAD'       , LEAD.customer_id,
                          tsk.customer_id) party_id,
              --  tsk.customer_id  party_id,
                decode(TSK.source_object_type_code,
                      'OD_PARTY_SITE',tsk.source_object_id,
                      tsk.address_id) party_site_id,
                TSK.creation_date task_creation_date,
                TSK.last_update_date  task_update_date,                
                TSK.created_by    task_created_by,
                TSK.task_id,
                usr.user_name,
                TSK.scheduled_end_date task_date,
                TSKTYP.name task_type,
                CASE WHEN trunc(TSK.scheduled_end_date) <= trunc(TSK.last_update_date)
                THEN 'ACTY_DT'
                ELSE 'CONTACT_AFTER_DATE'
                END fdbk_code,
                CASE  WHEN trunc(TSK.scheduled_end_date) <= trunc(TSK.last_update_date)
                      THEN TSKSTAT.name
                      ELSE NULL
                END   tsk_status
        FROM    apps.JTF_TASKS_VL             TSK,
                apps.jtf_task_types_vl        TSKTYP,
                apps.jtf_task_statuses_vl     TSKSTAT,
                apps.AS_SALES_LEADS           LEAD,  -- leads
                apps.AS_LEADS_ALL             OPP ,  -- opportunities
                apps.fnd_user                 usr
        WHERE   TSKTYP.task_type_id = TSK.task_type_id
        AND   	TSKSTAT.task_status_id = TSK.task_status_id     
        AND     TSK.scheduled_end_date IS NOT NULL
        AND     usr.user_id= TSK.last_updated_by   
        AND     TSK.source_object_id = OPP.lead_id(+)
        AND     TSK.source_object_id = LEAD.sales_lead_id(+)
        AND     nvl(LEAD.deleted_flag,'N') = 'N'
        AND     nvl(OPP.deleted_flag,'N') = 'N' 
        AND   	TSKTYP.name in (select  source_value1
                                from    apps.XX_FIN_TRANSLATEVALUES
                                where   translate_id IN (
                                SELECT  translate_id
                                FROM    apps.XX_FIN_TRANSLATEDEFINITION
                                WHERE   TRANSLATION_NAME = 'OD_SCS_TASK_TYPE'))
        and     TSK.source_object_type_code IN ('LEAD','OPPORTUNITY','OD_PARTY_SITE','PARTY')
        and     TSK.last_update_date between   p_last_extract_dt and p_extract_to_dt
         -- additional condition
        AND     TSK.task_id NOT IN (
                                SELECT  attribute1
                                from    apps.xxscs_fdbk_line_dtl
                                where   attribute_category = 'TASK_ID'
                                and     last_update_date between  p_last_extract_dt and p_extract_to_dt
                                AND     TSK.CREATION_DATE = TSK.LAST_UPDATE_DATE
                                )
        ) a,
        apps.hz_cust_acct_sites_all hps,
        apps.hz_cust_accounts     hzp
WHERE   a.party_site_id = hps.party_site_id(+)
and     a.party_id = hzp.party_id
and     nvl(tsk_status,'Completed')  in ( select  source_value1
        from    apps.XX_FIN_TRANSLATEVALUES
        where   translate_id IN (
        SELECT  translate_id
        FROM    apps.XX_FIN_TRANSLATEDEFINITION
        WHERE   TRANSLATION_NAME = 'OD_SCS_TASK_STATUS'))

UNION ALL
-- Additional Lines
SELECT  decode(a.ENTITY_TYPE,
              'PARTY', substr(hzp.orig_system_reference,1,instr(hzp.orig_system_reference,'-',1,1)-1),
              substr(hps.orig_system_reference,1,instr(hps.orig_system_reference,'-',1,1)-1) ) customer_account_id,
        to_number(decode( a.entity_type,
                          'PARTY',substr(hzp.orig_system_reference,instr(hzp.orig_system_reference,'-',1,1)+1,instr(hzp.orig_system_reference,'-',1,2)-instr(hzp.orig_system_reference,'-',1,1)-1),
                          substr(hps.orig_system_reference,instr(hps.orig_system_reference,'-',1,1)+1,instr(hps.orig_system_reference,'-',1,2)-instr(hps.orig_system_reference,'-',1,1)-1))) address_id,
        a.party_site_id party_site_id,
        a.party_id party_id,
        a.task_update_date, -- for records to process, creation and last udpated date in fdbk hdr and dtl
        a.task_created_by created_by, -- for created by and last udpated by in fdbk hdr and dtl
        decode(a.ENTITY_TYPE,
              'OD_PARTY_SITE','PARTY_SITE',
              a.entity_type)entity_type,
        a.TASK_ID,
        a.entity_id entity_id,
        a.fdbk_code fdbk_code,
          decode(a.task_type,'In Person Visit','IN_PRSN','Mail','BY_MAIL','Call','BY_PHNE','Email','BY_EMAIL',NULL) fdk_value,
        null fdk_date,
        'FDK_VALUE'  FDK_PICK_VALUE,
        a.user_name
FROM     (SELECT  TSK.source_object_type_code ENTITY_TYPE,
                  tsk.source_object_id ENTITY_ID,
                  decode( TSK.source_object_type_code,
                          'OPPORTUNITY',  OPP.customer_id,
                          'LEAD'       , LEAD.customer_id,
                          tsk.customer_id) party_id,
                 -- tsk.customer_id  party_id,
                 -- tsk.address_id party_site_id,
                  decode( TSK.source_object_type_code,
                          'OD_PARTY_SITE',tsk.source_object_id,
                          'OPPORTUNITY',  OPP.address_id,
                          'LEAD'       , LEAD.address_id,
                          tsk.address_id) party_site_id,
                  TSK.creation_date  task_creation_date,
                  TSK.last_update_date  task_update_date,      
                  TSK.created_by     task_created_by,
                  TSK.task_id,
                  usr.user_name,
                  TSK.scheduled_end_date task_date,
                  TSKTYP.name task_type,		  
                  CASE  WHEN trunc(TSK.scheduled_end_date) <= trunc(TSK.last_update_date)
                        THEN 'CUST_CONTACTED'
                        ELSE 'CONTACT_AFTER_DATE'
                               END   fdbk_code,
                     CASE  WHEN trunc(TSK.scheduled_end_date) <= trunc(TSK.last_update_date)
                        THEN TSKSTAT.name
                        ELSE NULL
                  END   tsk_status
          FROM    apps.JTF_TASKS_VL             TSK,
                  apps.jtf_task_types_vl        TSKTYP,
                  apps.AS_SALES_LEADS           LEAD,  -- leads
                  apps.AS_LEADS_ALL             OPP,   -- opportunities
                  apps.jtf_task_statuses_vl     TSKSTAT  ,
                  apps.fnd_user                 usr             
          WHERE   TSKTYP.task_type_id = TSK.task_type_id
          AND     TSK.scheduled_end_date IS NOT NULL
          AND     usr.user_id= TSK.last_updated_by 
          AND     TSK.source_object_id = OPP.lead_id(+)
          AND     TSK.source_object_id = LEAD.sales_lead_id(+)
          AND     nvl(LEAD.deleted_flag,'N') = 'N'
          AND     nvl(OPP.deleted_flag,'N') = 'N' 
          AND     TSKSTAT.task_status_id = TSK.task_status_id
          AND     TSKTYP.name in (  select  source_value1
                              from    apps.XX_FIN_TRANSLATEVALUES
                              where   translate_id IN (
                                      SELECT  translate_id
                                      FROM    apps.XX_FIN_TRANSLATEDEFINITION
                                      WHERE   TRANSLATION_NAME = 'OD_SCS_TASK_TYPE'))
          and     TSK.source_object_type_code IN ('LEAD','OPPORTUNITY','OD_PARTY_SITE','PARTY')
          and     TSK.last_update_date between   p_last_extract_dt and p_extract_to_dt
          -- additional condition
          AND     TSK.task_id NOT IN (
                                      SELECT  attribute1
                                      from    apps.xxscs_fdbk_line_dtl
                                      where   attribute_category = 'TASK_ID'
                                      and     last_update_date  between p_last_extract_dt and p_extract_to_dt
                                      AND     TSK.CREATION_DATE = TSK.LAST_UPDATE_DATE
                                      )
          ) a,
          apps.hz_cust_acct_sites_all hps,
          apps.hz_cust_accounts     hzp
  WHERE   a.party_site_id = hps.party_site_id(+)
  and     a.party_id = hzp.party_id
  and     tsk_status   in (
          select  source_value1
          from    apps.XX_FIN_TRANSLATEVALUES
          where   translate_id IN (
          SELECT  translate_id
          FROM    apps.XX_FIN_TRANSLATEDEFINITION
          WHERE   TRANSLATION_NAME = 'OD_SCS_TASK_STATUS'))

UNION ALL
-- OD white collar worker
-- party_id, party_site_id, entity_type, entity_id
SELECT   substr(cas.orig_system_reference,1, instr(cas.orig_system_reference,'-')-1)    	--CUSTOMER_ACCOUNT_ID
         ,to_number(substr(cas.orig_system_reference, instr(cas.orig_system_reference,'-')+1,5)) --  ADDRESS_ID
         ,cas.party_site_id        --PARTY_SITE_ID
         ,hps.party_id                               -- PARTY_ID
         ,hpx.last_update_date                       -- creation_DATE
      
         ,hpx.last_updated_by
         ,'PARTY_SITE'                                       -- entity_type
         ,null
         ,hps.party_site_id                                       -- entity_id
         ,'OD_WHITE_COLLAR_WORKER_CNT'  	     -- FDK_CODE
         ,to_char(hpx.N_EXT_ATTR8)                            --FDK_VALUE
         --,NULL                                       -- FDK_TXT
         ,NULL                                       -- FDK_DATE
         ,'FDK_TXT'                                  -- FDK_PICK_VALUE
         ,fu.user_name                               -- LAST_UPDATED_EMP
FROM    apps.HZ_PARTY_SITES_EXT_B   hpx ,
        apps.hz_party_sites         hps,
        apps.hz_cust_accounts       hca,
        apps.hz_cust_acct_sites_all cas,
        apps.fnd_user               fu
where   attr_group_id = p_attr_group_id
and     hpx.last_update_date between p_last_extract_dt and p_extract_to_dt
and     hps.party_id = hca.party_id
--and     count_diff ( p_attr_group_id, HPX.party_site_id , N_EXT_ATTR8) = 'Y'
and     hpx.party_site_id = hps.party_site_id
and     cas.party_site_id = hps.party_site_id
--and     hpx.N_EXT_ATTR8 is not null
and     fu.user_id = hpx.last_updated_by
AND     fu.user_name NOT IN (
        select  source_value1
        from    XX_FIN_TRANSLATEVALUES
        where   translate_id = (
        SELECT  translate_id
        FROM    XX_FIN_TRANSLATEDEFINITION
        WHERE   TRANSLATION_NAME = 'XXSCS_IGNORE_USERS_FDBK'))
UNION ALL
-- SIC CODE and
SELECT   substr(cas.orig_system_reference,1, instr(cas.orig_system_reference,'-')-1)               -- CUSTOMER_ACCOUNT_ID
         ,to_number(substr(cas.orig_system_reference, instr(cas.orig_system_reference,'-')+1,5))   --  ADDRESS_ID
         ,cas.party_site_id     	--PARTY_SITE_ID
         ,hps.party_id                            	--PARTY_ID
         ,hpx.last_update_date                          --creation_DATE
         ,hpx.last_updated_by
         ,'PARTY_SITE'                                          --entity_type
         ,null
         ,hps.party_site_id                                           --entity_id
         ,'KEYED_SIC_GROUP_CD'          	        --FDK_CODE
         ,hpx.C_EXT_ATTR10                              --FDK_VALUE White Collar Workers
         --,NULL                                  	--FDK_TXT
         ,NULL                                  	--FDK_DATE
         ,'FDK_TXT'                             	--FDK_PICK_VALUE
         ,fu.user_name                          	--LAST_UPDATED_EMP
FROM    apps.HZ_PARTY_SITES_EXT_B hpx ,
        apps.hz_party_sites       hps,
        apps.hz_cust_accounts     hca,
        apps.hz_cust_acct_sites_all cas,
        apps.fnd_user             fu
where   attr_group_id = p_attr_group_id
and     hpx.last_update_date between p_last_extract_dt and p_extract_to_dt
and     hps.party_id = hca.party_id
--and     count_diff_sic ( p_attr_group_id, hps.party_site_id , C_EXT_ATTR10) = 'Y'
and     hpx.party_site_id = hps.party_site_id
and     cas.party_site_id = hps.party_site_id
and     fu.user_id = hpx.last_updated_by
--and     hpx.C_EXT_ATTR10 IS NOT NULL
AND     fu.user_name NOT IN (
        select  source_value1
        from    XX_FIN_TRANSLATEVALUES
        where   translate_id = (
        SELECT  translate_id
        FROM    XX_FIN_TRANSLATEDEFINITION
        WHERE   TRANSLATION_NAME = 'XXSCS_IGNORE_USERS_FDBK')))
ORDER BY PARTY_ID , PARTY_SITE_ID, CUSTOMER_ACCOUNT_ID, ADDRESS_ID, entity_type, entity_id,UPDATE_DATE ,task_id, fdk_code ;

END IF;

return l_cursor;

end get_fdbk_lines;

-- Check for existing feedback header
function get_fdbk_id( p_party_id        xxscs_fdbk_hdr.fdbk_id%type,
                      p_party_site_id   xxscs_fdbk_hdr.party_site_id%TYPE,
                      p_entity_type     xxscs_fdbk_hdr.entity_type%TYPE,
                      p_entity_id       xxscs_fdbk_hdr.entity_id%TYPE,
                      p_last_date       DATE,
                      p_user_id         NUMBER)
         return NUMBER IS
         
l_fdbk_id      xxscs_fdbk_hdr.fdbk_id%type := -1;

BEGIN
      -- check for 1st row for the following conditions
      select  MAX(fdbk_id) into l_fdbk_id
      from    xxscs_fdbk_hdr
      where   party_id = p_party_id
      and     nvl(party_site_id,-1) = nvl(p_party_site_id,-1)
      and     entity_type = p_entity_type
      and     entity_id = p_entity_id
      and     creation_date > p_last_date
      and     created_by = p_user_id;
--      and     rownum =1;
      return nvl(l_fdbk_id,-1);
      
EXCEPTION

WHEN NO_DATA_FOUND THEN
--    FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Data Found in get_fdbk_id ' || 'party_id ' || p_party_id ||
--                         'p_party_site_id ' || p_party_site_id || 'p_entity_type' || p_entity_type ||
--                         'p_entity_id' || p_entity_id);
    return l_fdbk_id;
    
WHEN  OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception others  ' || sqlerrm || sqlcode);
      return l_fdbk_id;
end get_fdbk_id;

-- Check for existing feedback lines
function get_fdbk_line_id(p_fdbk_id   xxscs_fdbk_hdr.fdbk_id%type,
                          p_FDK_CODE  xxscs_fdbk_line_dtl.FDK_CODE%type,
                          p_FDK_VALUE xxscs_fdbk_line_dtl.FDK_VALUE%type
                          )
         return NUMBER IS
l_fdbk_line_id      xxscs_fdbk_line_dtl.fdbk_line_id%type := -1;

BEGIN
        -- check for 1st row for the following conditions
      select  fdbk_line_id   into l_fdbk_line_id
      from    xxscs_fdbk_line_dtl
      where   fdbk_id = p_fdbk_id
      and     FDK_CODE = p_FDK_CODE
      and     FDK_VALUE = p_FDK_VALUE
      and     rownum =1;
      
return l_fdbk_line_id;

EXCEPTION WHEN NO_DATA_FOUND THEN

      --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Data Found in get_fdbk_id ' || 'fdbk_id ' || p_fdbk_id ||
      --                         'FDK_CODE ' || p_FDK_CODE || 'FDK_VALUE' || p_FDK_VALUE );
      return l_fdbk_line_id;
      
WHEN  OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception others  ' || sqlerrm || sqlcode);
      return l_fdbk_line_id;
end get_fdbk_line_id;



-- Populate Feedback Header and Line tables based on last_update_date
-- in Party Site Ext Att Table
procedure load_fdbk_hdr_line ( x_errbuf	  OUT NOCOPY VARCHAR2
                            ,x_retcode  OUT NOCOPY VARCHAR2
                          )  IS                          
TYPE t_fdbk_rec IS RECORD ( customer_account_id   xxscs_fdbk_hdr.customer_account_id%TYPE,
                            address_id            xxscs_fdbk_hdr.address_id%TYPE,
                            party_site_id         xxscs_fdbk_hdr.party_site_id%TYPE,
                            party_id              xxscs_fdbk_hdr.party_id%TYPE,
                            creation_date         xxscs_fdbk_hdr.creation_date%TYPE, -- for records to process, creation and last udpated date in fdbk hdr and dtl
                            created_by            xxscs_fdbk_hdr.created_by%TYPE, -- for created by and last udpated by in fdbk hdr and dtl
                            entity_type           xxscs_fdbk_hdr.entity_type%TYPE,
                            task_id               JTF_TASKS_B.task_id%TYPE,
                            entity_id             xxscs_fdbk_hdr.entity_id%TYPE,
                            fdbk_code             xxscs_fdbk_line_dtl.fdk_code%TYPE,
                            fdk_value             xxscs_fdbk_line_dtl.fdk_value%TYPE,
                            fdk_date              xxscs_fdbk_line_dtl.fdk_date%TYPE,
                            fdk_pick_value        xxscs_fdbk_line_dtl.FDK_PICK_VALUE%TYPE,
                            last_upd_emp          xxscs_fdbk_hdr.LAST_UPDATED_EMP%TYPE   );
TYPE t_fdbk_tab IS TABLE OF t_fdbk_rec INDEX BY PLS_INTEGER;
v_hz_ps_ext_tbl       t_fdbk_tab;
v_attr_group_id       EGO_ATTR_GROUPS_V.attr_group_id%type;
v_last_ext_date       DATE;
v_mass_apply_value     VARCHAR2(200);
l_current_date        DATE;
l_ref_cursor          SYS_REFCURSOR;
v_last_upd_date       VARCHAR2(20);
l_fdbk_id             xxscs_fdbk_line_dtl.fdbk_id%TYPE;
l_fdbk_line_id        xxscs_fdbk_line_dtl.fdbk_line_id%TYPE;
l_success             boolean;
l_counter		    NUMBER := 1;
l_line_counter        NUMBER :=0;
l_resource_id         xxscs_fdbk_hdr.resource_id%type;
l_role_id             xxscs_fdbk_hdr.role_id%type;
l_group_id            xxscs_fdbk_hdr.group_id%type;
l_sales_terr_id       xxscs_fdbk_hdr.sales_territory_id%type;

BEGIN

      select  sysdate into l_current_date
      from    dual;
      select  attr_group_id into v_attr_group_id
      from    EGO_ATTR_GROUPS_V
      where   ATTR_GROUP_type = 'HZ_PARTY_SITES_GROUP'
      and     attr_group_name = 'SITE_DEMOGRAPHICS'
      and     rownum = 1;
      
      fnd_profile.get('XXSCS_FD_HL_EXT_DT', v_last_upd_date);
      fnd_profile.get('XXSCS_MASS_APPLY', v_mass_apply_value);

    /*  
      IF v_last_upd_date is NULL THEN
      x_retcode := 2;
      x_errbuf := 'Profile XXSCS FeedBack HeaderLine Extract Date is Null'
      v_last_ext_date := sysdate+1;
      RETURN;
      END IF;
    */  
      v_last_ext_date := nvl(TO_DATE(v_last_upd_date,'DD-MON-RRRR HH24:MI:SS'), SYSDATE+1);
      l_ref_cursor := get_fdbk_lines( v_last_ext_date,
                                      l_current_date,
                                      v_attr_group_id );
      loop
      fetch l_ref_cursor bulk collect into v_hz_ps_ext_tbl limit g_limit;
      
        for indx  IN 1..v_hz_ps_ext_tbl.count loop
          -- parameters to passs:  party_id, party_site_id, entity_type, entity_id
          l_fdbk_id := get_fdbk_id(v_hz_ps_ext_tbl(indx).party_id, v_hz_ps_ext_tbl(indx).party_site_id,
                                  v_hz_ps_ext_tbl(indx).entity_type, v_hz_ps_ext_tbl(indx).entity_id,
                                  v_last_ext_date, fnd_global.USER_ID);
          IF ( v_hz_ps_ext_tbl(indx).FDbK_CODE = 'CONTACT_AFTER_DATE' OR 
              v_hz_ps_ext_tbl(indx).FDbK_CODE = 'ACTY_DT'  OR
              l_fdbk_id < 0 ) THEN
                    l_line_counter := 0;
          
--            BEGIN          
--                IF   v_hz_ps_ext_tbl(indx).entity_type = 'PARTY'  THEN    
--                
--                          
--                    SELECT  rol.resource_id, rol.role_id, rol.group_id , rel.attribute15  INTO
--                            l_resource_id , l_role_id, l_group_id, l_sales_terr_id
--                    FROM    apps.JTF_RS_GROUP_MBR_ROLE_VL ROL,
--                            apps.JTF_RS_ROLE_RELATIONS REL
--                    WHERE   rol.group_member_id = rel.role_resource_id
--                    and     rel.role_resource_type = 'RS_GROUP_MEMBER'
--                    and     sysdate between rel.start_date_active and NVL(rel.end_DATE_ACTIVE,SYSDATE) 
--                    and     sysdate between rol.start_date_active and NVL(rol.end_DATE_ACTIVE,SYSDATE)
--                    and     (rol.resource_id, rol.role_id, rol.group_id) IN      
--                            ( select  rol.resource_id, rol.role_id, rol.group_id
--                              from    apps.XX_TM_NAM_TERR_CURR_ASSIGN_V 
--                              where   entity_type = 'PARTY_SITE'
--                              and     entity_id = ( select party_site_id
--                                                    from   apps.hz_party_sites hps
--                                                    where  hps.party_id = v_hz_ps_ext_tbl(indx).entity_id 
--                                                    and    identifying_address_flag = 'Y'
--                                                    and    rownum = 1)
--                              and     rownum =1)
--                    and     rownum=1;
--                ELSE
--                
--                  SELECT    rol.resource_id, rol.role_id, rol.group_id , rel.attribute15  INTO
--                            l_resource_id , l_role_id, l_group_id, l_sales_terr_id
--                    FROM    apps.JTF_RS_GROUP_MBR_ROLE_VL ROL,
--                            apps.JTF_RS_ROLE_RELATIONS REL
--                    WHERE   rol.group_member_id = rel.role_resource_id
--                    and     rel.role_resource_type = 'RS_GROUP_MEMBER'
--                    and     sysdate between rel.start_date_active and NVL(rel.end_DATE_ACTIVE,SYSDATE) 
--                    and     sysdate between rol.start_date_active and NVL(rol.end_DATE_ACTIVE,SYSDATE)
--                    and     (rol.resource_id, rol.role_id, rol.group_id) IN      
--                            ( select  rol.resource_id, rol.role_id, rol.group_id
--                              from    apps.XX_TM_NAM_TERR_CURR_ASSIGN_V 
--                              where   entity_type = v_hz_ps_ext_tbl(indx).entity_type
--                              and     entity_id = v_hz_ps_ext_tbl(indx).entity_id
--                              and     rownum =1)
--                    and     rownum=1;
--                END IF;
--          
--          EXCEPTION WHEN OTHERS THEN
--            
--            fnd_file.put_line(fnd_file.log, 'Error in querying l_resource_id , l_role_id, l_group_id ' || sqlerrm );
--          END;
                    
                    
                    -- Populate xxscs_fdbk_hdr
                    insert into  xxscs_fdbk_hdr (
                          FDBK_ID	        ,
                          CUSTOMER_ACCOUNT_ID ,
                          ADDRESS_ID 		,
                          PARTY_SITE_ID 	,
                          PARTY_ID		,
                          MASS_APPLY_FLAG 	,
                          CONTACT_ID 		,
                          LAST_UPDATED_EMP 	,
                          SALES_TERRITORY_ID 	,
                          RESOURCE_ID 	,
                          ROLE_ID 		,
                          GROUP_ID 		,
                          LANGUAGE 		,
                          SOURCE_LANG 	,
                          CREATED_BY 		,
                          CREATION_DATE 	,
                          LAST_UPDATED_BY 	,
                          LAST_UPDATE_DATE	,
                          REQUEST_ID 		,
                          PROGRAM_APPLICATION_ID  ,
                          PROGRAM_ID 		,
                          PROGRAM_UPDATE_DATE,
                          ENTITY_ID,
                          ENTITY_TYPE,
                          ATTRIBUTE_CATEGORY,
                          ATTRIBUTE1
                    ) values (
                            XXSCS_FDBK_ID_S.nextval     --        FDBK_ID			,
                            ,v_hz_ps_ext_tbl(indx).customer_account_id    --	CUSTOMER_ACCOUNT_ID 	,
                            ,v_hz_ps_ext_tbl(indx).address_id             --	ADDRESS_ID 		,
                            ,v_hz_ps_ext_tbl(indx).party_site_id          --	PARTY_SITE_ID 		,
                            ,v_hz_ps_ext_tbl(indx).party_id               --	PARTY_ID		,
                            ,null                            --	MASS_APPLY_FLAG 	, -- check this
                            ,null                            --	CONTACT_ID 		,
                            ,v_hz_ps_ext_tbl(indx).last_upd_emp                  --	LAST_UPDATED_EMP 	,
                            ,l_sales_terr_id                           --	SALES_TERRITORY_ID 	,
                            ,l_resource_id                            --	RESOURCE_ID 		,
                            ,l_role_id                            --	ROLE_ID 		,
                            ,l_group_id                            --	GROUP_ID 		,
                            ,null                            --	LANGUAGE 		,
                            ,null                            --	SOURCE_LANG 		,
                            ,fnd_global.USER_ID              --	CREATED_BY 		,
                            ,v_hz_ps_ext_tbl(indx).creation_date
                           -- ,l_current_date + l_counter*1 / (24*3600)                         --	CREATION_DATE 		,
                            ,fnd_global.USER_ID              --	LAST_UPDATED_BY 	,
                            ,v_hz_ps_ext_tbl(indx).creation_date                      --	LAST_UPDATE_DATE	,
                            ,fnd_global.CONC_REQUEST_ID                         --	REQUEST_ID 		,
                            ,null                         --	PROGRAM_APPLICATION_ID  ,
                            ,fnd_global.CONC_PROGRAM_ID                         --	PROGRAM_ID 		,
                            ,SYSDATE                      --	PROGRAM_UPDATE_DATE
                            ,v_hz_ps_ext_tbl(indx).ENTITY_ID   --  ENTITY_ID
                            ,v_hz_ps_ext_tbl(indx).ENTITY_TYPE --  ENTITY_TYPE
                            ,'SOURCE'
                            ,'System Generated'
                    );
                    
                    select  XXSCS_FDBK_ID_S.currval into l_fdbk_id from dual;
              END IF;
              -- check the params passed
    --          l_fdbk_line_id := get_fdbk_line_id(l_fdbk_id, v_hz_ps_ext_tbl(indx).FDbK_CODE, v_hz_ps_ext_tbl(indx).FDK_VALUE);
    --          IF  ( v_hz_ps_ext_tbl(indx).FDbK_CODE = 'CONTACT_AFTER_DATE' OR l_fdbk_line_id < 0 ) THEN
                        l_line_counter := l_line_counter + 1;
                        -- Populate xxscs_fdbk_line_dtl
                        insert into  xxscs_fdbk_line_dtl
                        (
                              FDBK_LINE_ID 	,
                              FDBK_ID 		,
                              FDK_CODE 		,
                              FDK_VALUE 		,
                              FDK_TXT 		,
                              FDK_DATE 		,
                              FDK_PICK_VALUE 	,
                              LAST_UPDATED_EMP 	,
                              LANGUAGE 		,
                              SOURCE_LANG 	,
                              CREATED_BY 		,
                              CREATION_DATE 	,
                              LAST_UPDATED_BY 	,
                              LAST_UPDATE_DATE 	,
                              LAST_UPDATE_LOGIN 	,
                              REQUEST_ID 		,
                              PROGRAM_APPLICATION_ID	,
                              PROGRAM_ID 		,
                              PROGRAM_UPDATE_DATE ,
                              EXTRACT_FLAG ,
                              ATTRIBUTE_CATEGORY,
                              ATTRIBUTE1
                        ) values
                        (
                                XXSCS_FDBK_LINE_ID_S.nextval       --  FDBK_LINE_ID,
                                ,l_fdbk_id                         --  FDBK_ID     ,
                                ,v_hz_ps_ext_tbl(indx).FDbK_CODE    --  FDK_CODE     ,
                                ,DECODE( v_hz_ps_ext_tbl(indx).FDbK_CODE,'OD_WHITE_COLLAR_WORKER_CNT',NULL,  'KEYED_SIC_GROUP_CD', NULL, v_hz_ps_ext_tbl(indx).FDK_VALUE )   --  White Collar Workers,
                                ,DECODE( v_hz_ps_ext_tbl(indx).FDbK_CODE,'OD_WHITE_COLLAR_WORKER_CNT',v_hz_ps_ext_tbl(indx).FDK_VALUE,  'KEYED_SIC_GROUP_CD',  v_hz_ps_ext_tbl(indx).FDK_VALUE )                           --  FDK_TXT ,
                                ,v_hz_ps_ext_tbl(indx).fdk_date                             --  FK_DATE ,
                                ,v_hz_ps_ext_tbl(indx).fdk_pick_value   --	FDK_PICK_VALUE 		,
                                ,v_hz_ps_ext_tbl(indx).last_upd_emp     --  LAST_UPDATED_EMP 	,  
                                ,NULL                              --  LANGUAGE 		,
                                ,NULL                              --  SOURCE_LANG 		,
                                ,v_hz_ps_ext_tbl(indx).created_by  --  CREATED_BY 		,
                                ,v_hz_ps_ext_tbl(indx).creation_date
                             --   ,l_current_date + l_counter*1 / (24*3600) + l_line_counter*1 / (24*3600)   --  CREATION_DATE 		,
                                ,v_hz_ps_ext_tbl(indx).created_by      --  LAST_UPDATED_BY 	,
                                ,v_hz_ps_ext_tbl(indx).creation_date
                              --  ,l_current_date + l_counter*1 / (24*3600) + l_line_counter*1 / (24*3600)                          --  LAST_UPDATE_DATE 	,
                                ,NULL                              --  LAST_UPDATE_LOGIN 	,
                                ,fnd_global.CONC_REQUEST_ID                              --  REQUEST_ID 		,
                                ,NULL                              --  PROGRAM_APPLICATION_ID	,
                                ,fnd_global.CONC_PROGRAM_ID                              --  PROGRAM_ID 		,
                                ,SYSDATE                           --  PROGRAM_UPDATE_DATE 	,
                                ,null                              --  EXTRACT_FLAG
                                ,DECODE(v_hz_ps_ext_tbl(indx).task_id,NULL,null,'TASK_ID')
                                ,v_hz_ps_ext_tbl(indx).task_id
                        );
                        
                        IF  v_hz_ps_ext_tbl(indx).entity_type = 'PARTY' AND v_hz_ps_ext_tbl(indx).FDbK_CODE = 'CONTACT_AFTER_DATE' AND  
                            v_mass_apply_value IS NOT NULL THEN  
                        
                             l_line_counter := l_line_counter + 1;
                            -- Populate xxscs_fdbk_line_dtl MASS_APPLY_FLAG
                            insert into  xxscs_fdbk_line_dtl
                            (
                                  FDBK_LINE_ID 	,
                                  FDBK_ID 		,
                                  FDK_CODE 		,
                                  FDK_VALUE 		,
                                  FDK_TXT 		,
                                  FDK_DATE 		,
                                  FDK_PICK_VALUE 	,
                                  LAST_UPDATED_EMP 	,
                                  LANGUAGE 		,
                                  SOURCE_LANG 	,
                                  CREATED_BY 		,
                                  CREATION_DATE 	,
                                  LAST_UPDATED_BY 	,
                                  LAST_UPDATE_DATE 	,
                                  LAST_UPDATE_LOGIN 	,
                                  REQUEST_ID 		,
                                  PROGRAM_APPLICATION_ID,
                                  PROGRAM_ID 		,
                                  PROGRAM_UPDATE_DATE ,
                                  EXTRACT_FLAG ,
                                  ATTRIBUTE_CATEGORY,
                                  ATTRIBUTE1
                            ) values
                            (   
                                    XXSCS_FDBK_LINE_ID_S.nextval       --  FDBK_LINE_ID,
                                    ,l_fdbk_id                         --  FDBK_ID     ,
                                    ,'MASS_APPLY_FLAG'    --  FDK_CODE     ,
                                    , v_mass_apply_value   --  White Collar Workers,
                                    ,null--  FDK_TXT ,
                                    ,NULL                             --  FK_DATE ,
                                    ,'FDK_VALUE'   --	FDK_PICK_VALUE 		,
                                    ,v_hz_ps_ext_tbl(indx).last_upd_emp                    --  LAST_UPDATED_EMP 	,
                                    ,NULL                              --  LANGUAGE 		,
                                    ,NULL                              --  SOURCE_LANG 		,
                                    ,v_hz_ps_ext_tbl(indx).created_by  --  CREATED_BY 		,
                                    ,v_hz_ps_ext_tbl(indx).creation_date
                                 --   ,l_current_date + l_counter*1 / (24*3600) + l_line_counter*1 / (24*3600)   --  CREATION_DATE 		,
                                    ,v_hz_ps_ext_tbl(indx).created_by      --  LAST_UPDATED_BY 	,
                                    ,v_hz_ps_ext_tbl(indx).creation_date
                                --    ,l_current_date + l_counter*1 / (24*3600) + l_line_counter*1 / (24*3600)                          --  LAST_UPDATE_DATE 	,
                                    ,NULL                              --  LAST_UPDATE_LOGIN 	,
                                    ,fnd_global.CONC_REQUEST_ID                              --  REQUEST_ID 		,
                                    ,NULL                              --  PROGRAM_APPLICATION_ID	,
                                    ,fnd_global.CONC_PROGRAM_ID                              --  PROGRAM_ID 		,
                                    ,SYSDATE                           --  PROGRAM_UPDATE_DATE 	,
                                    ,null                              --  EXTRACT_FLAG
                                    ,DECODE(v_hz_ps_ext_tbl(indx).task_id,NULL,null,'TASK_ID')
                                    ,v_hz_ps_ext_tbl(indx).task_id
                            );
                        
                        END IF;
                           IF  ( v_hz_ps_ext_tbl(indx).FDbK_CODE = 'CONTACT_AFTER_DATE' ) THEN
                        l_line_counter := l_line_counter + 1;
                        -- Populate xxscs_fdbk_line_dtl
                        insert into  xxscs_fdbk_line_dtl
                        (
                              FDBK_LINE_ID 	,
                              FDBK_ID 		,
                              FDK_CODE 		,
                              FDK_VALUE 		,
                              FDK_TXT 		,
                              FDK_DATE 		,
                              FDK_PICK_VALUE 	,
                              LAST_UPDATED_EMP 	,
                              LANGUAGE 		,
                              SOURCE_LANG 	,
                              CREATED_BY 		,
                              CREATION_DATE 	,
                              LAST_UPDATED_BY 	,
                              LAST_UPDATE_DATE 	,
                              LAST_UPDATE_LOGIN 	,
                              REQUEST_ID 		,
                              PROGRAM_APPLICATION_ID	,
                              PROGRAM_ID 		,
                              PROGRAM_UPDATE_DATE ,
                              EXTRACT_FLAG,
                              ATTRIBUTE_CATEGORY,
                              ATTRIBUTE1
                        ) values
                        (
                                XXSCS_FDBK_LINE_ID_S.nextval       --  FDBK_LINE_ID,
                                ,l_fdbk_id                         --  FDBK_ID     ,
                                ,'ACTY_DT'    --  FDK_CODE     ,
                                ,NULL
                                ,null                        --  FDK_TXT ,
                                ,l_current_date                            --  FK_DATE ,
                                ,'FDK_DATE'   --	FDK_PICK_VALUE 		,
                                ,v_hz_ps_ext_tbl(indx).last_upd_emp                    --  LAST_UPDATED_EMP 	,
                                ,NULL                              --  LANGUAGE 		,
                                ,NULL                              --  SOURCE_LANG 		,
                                ,v_hz_ps_ext_tbl(indx).created_by  --  CREATED_BY 		,
                                ,l_current_date
                             --   ,l_current_date + l_counter*1 / (24*3600) + l_line_counter*1 / (24*3600)   --  CREATION_DATE 		,
                                ,v_hz_ps_ext_tbl(indx).created_by      --  LAST_UPDATED_BY 	,
                                ,l_current_date
                              --  ,l_current_date + l_counter*1 / (24*3600) + l_line_counter*1 / (24*3600)                          --  LAST_UPDATE_DATE 	,
                                ,NULL                              --  LAST_UPDATE_LOGIN 	,
                                ,fnd_global.CONC_REQUEST_ID                              --  REQUEST_ID 		,
                                ,NULL                              --  PROGRAM_APPLICATION_ID	,
                                ,fnd_global.CONC_PROGRAM_ID                              --  PROGRAM_ID 		,
                                ,SYSDATE                           --  PROGRAM_UPDATE_DATE 	,
                                ,null                              --  EXTRACT_FLAG
                                ,DECODE(v_hz_ps_ext_tbl(indx).task_id,NULL,null,'TASK_ID')
                                ,v_hz_ps_ext_tbl(indx).task_id
                        );
    END IF;
                        
                 DE_RANK ( v_hz_ps_ext_tbl(indx).party_site_id,
                           v_hz_ps_ext_tbl(indx).FDbK_CODE,
                           v_hz_ps_ext_tbl(indx).FDK_VALUE,
                           v_hz_ps_ext_tbl(indx).fdk_date);
    --          END IF;
                  l_counter := l_counter + 1;
          end loop;
          
          exit when v_hz_ps_ext_tbl.count < g_limit ;
          commit;
      end loop;
      
     l_success := fnd_profile.save(X_NAME  => 'XXSCS_FD_HL_EXT_DT',
                      X_VALUE => TO_CHAR(l_current_date,'DD-MON-RRRR HH24:MI:SS'),
                      X_LEVEL_NAME => 'SITE' );
                      
     if(l_success) THEN
       fnd_file.put_line(fnd_file.log, 'profile value set for XXSCS_FD_HL_EXT_DT');
     ELSE
       fnd_file.put_line(fnd_file.log, 'failure setting profile valuefor XXSCS_FD_HL_EXT_DT');
     END IF;
     
EXCEPTION WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error in load_fdbk_hdr_line ' || sqlerrm );
END load_fdbk_hdr_line;

procedure load_stage_data ( x_errbuf	  OUT NOCOPY VARCHAR2
                            ,x_retcode  OUT NOCOPY VARCHAR2
                          )  IS
BEGIN
    -- Load into feedback header
      load_feedback_hdr(x_errbuf ,x_retcode) ;
    -- Load into feedback Line Detail Staging Table
      load_feedback_line( x_errbuf ,x_retcode) ;
    -- Load into feedback Question Staging Table
      load_feedback_qstn( x_errbuf ,x_retcode ) ;
    -- Load into feedback Response Staging Table
      load_feedback_resp( x_errbuf ,x_retcode ) ;
    -- Load additional lines to hdr, lines
      load_feedback_add_hdr_lines(x_errbuf ,x_retcode);
END load_stage_data;
END XXSCS_LOAD_STG_DATA;

/
SHOW ERRORS;