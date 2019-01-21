create or replace
PACKAGE BODY XX_CS_TDS_CLOSE_SR AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_CS_TDS_CLOSE_SR Package Body                                                    |
-- |  Description:     OD: TDS Mass Close SR                                                    |
-- |  Description:     OD: TDS Mass Close SR Tasks                                              |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- +============================================================================================+
-- |  Name:  XX_CS_TDS_CLOSE_SR.UPDATE_SRS                                                      |
-- |  Description: This pkg.procedure will close the SRs with a particular status older than    |
-- |  certain number of days.                                                                   |
-- |  Name:  XX_CS_TDS_CLOSE_SR.UPDATE_TASK                                                     |
-- |  Description: This pkg.procedure will close the SR tasks for closed/cancelled SRs.         |
-- =============================================================================================|

PROCEDURE UPDATE_SRS(ERRBUF OUT NOCOPY VARCHAR2,
                      RETCODE OUT NOCOPY NUMBER,
                      p_no_of_days IN NUMBER,
                      p_status IN VARCHAR2,
                      p_sr_number number,
                      p_owner_group_name varchar2) AS
  

cursor c2 is select cb.incident_id,cb.incident_number
from cs_incidents_all_b cb,
     cs_incident_statuses_tl ct,
   jtf_rs_groups_vl gp
where cb.incident_status_id = ct.incident_status_id
and  ct.name = p_status 
--('Work In Progress','Associate Verification','Service Interupted','Service Rejected')
and cb.creation_date < sysdate - p_no_of_days
and cb.owner_group_id=gp.group_id
and cb.problem_code = 'TDS-SERVICES'
and ct.source_lang = 'US'
and (cb.incident_number=p_sr_number or p_sr_number is null)
and (gp.group_name=p_owner_group_name or p_owner_group_name is null);



c1_rec c2%rowtype;


lc_status     varchar2(100);
ln_status_id  number;
ln_user_id    number;
x_return_status varchar2(25);
lc_message      varchar2(250);
loop_count      number;
lc_count number:=0;
lc_source_lang varchar2(30):='US';
lc_error_sr_count number :=0;
lc_no_of_days number:=0;
lc_problem_code varchar2(30):='TDS-SERVICES';
e_invalid_no_of_days exception;

BEGIN




select profile_option_value into lc_no_of_days from fnd_profile_option_values pv,fnd_profile_options p 
where p.profile_option_id=pv.profile_option_id
and p.profile_option_name='XX_CS_TDS_SR_CLOSE_DAYS';
if (p_no_of_days<lc_no_of_days) THEN
Raise e_invalid_no_of_days;
end if;
   begin
     select user_id 
     into ln_user_id
     from fnd_user
     where user_name = 'CS_ADMIN';
    end;
    
     fnd_file.put_line(fnd_file.output,'========================================================================');
     fnd_file.put_line(fnd_file.output,'                        OD: TDS Mass Close SRs'); 
     fnd_file.put_line(fnd_file.output,'========================================================================'); 
   
   open c2;
   loop
   fetch c2 into c1_rec;
   exit when c2%notfound;
      loop_count  := loop_count + 1;
      ln_status_id := 2;
      lc_status := 'Closed';
  -- update SR status
     BEGIN
     
        XX_CS_SR_UTILS_PKG.Update_SR_status(p_sr_request_id  => c1_rec.incident_id,
                                  p_user_id        => ln_user_id,
                                  p_status_id      => ln_status_id,
                                  p_status         => lc_status,
                                  x_return_status  => x_return_status,
                                  x_msg_data      => lc_message);
                          
        if x_return_status= 'E' then
                                                
                   fnd_file.put_line(fnd_file.output,'Service Request errored : '|| c1_rec.incident_number||'.'); 
           fnd_file.put_line(fnd_file.log,'Errored Service Requests : '|| c1_rec.incident_number||'.'); 
           fnd_file.put_line(fnd_file.log,'Error status received from  : '||'XX_CS_SR_UTILS_PKG.Update_SR_status'||'.'); 
           lc_error_sr_count:=lc_error_sr_count+1;
         else 
       lc_count:=lc_count+1;
       fnd_file.put_line(fnd_file.output,'Service Request closed : '|| c1_rec.incident_number||'.'); 
        end if;
               
      END;
      
      
      IF loop_count = 500 then
         commit;
         loop_count := 0;
      END if;
      end loop;
      if lc_error_sr_count>0 then 
         retcode:=1;
         end if;
      fnd_file.put_line(fnd_file.output,'Total count of SR closed : '||lc_count||'.'); 
      fnd_file.put_line(fnd_file.output,'Total count of SR errored/unprocessed : '|| lc_error_sr_count||'.');
       fnd_file.put_line(fnd_file.log,'Total count of SR closed : '||lc_count||'.'); 
      fnd_file.put_line(fnd_file.log,'Total count of SR errored/unprocessed : '|| lc_error_sr_count||'.'); 
      close c2;
     
    exception
    when e_invalid_no_of_days then
           fnd_file.put_line(FND_FILE.log,'Number of days entered is less than the minimum required. Please Check Profile Option.');
           retcode:=1;
    when others then
         fnd_file.put_line(FND_FILE.OUTPUT,SQLERRM);
          errbuf := SUBSTR(SQLERRM,1,80);
          retcode:=2;
  -- end;
  END UPDATE_SRS;
  
/*******************************************************************************
-- Task cleanup
/******************************************************************************/

PROCEDURE UPDATE_TASK( ERRBUF OUT NOCOPY VARCHAR2,
                      RETCODE OUT NOCOPY NUMBER,
                      p_sr_number number,
                      p_owner_group_name varchar2)
IS

CURSOR C1 IS
select jt.task_id, cb.incident_status_id, 
        jt.object_version_number,cb.incident_number
from jtf_tasks_b JT,
     cs_incidents_all_b cb,
     jtf_rs_groups_vl gp
where cb.incident_id = jt.source_object_id
and cb.owner_group_id=gp.group_id
and  jt.source_object_type_code = 'SR'
and (cb.incident_number=p_sr_number or p_sr_number is null)
and (gp.group_name=p_owner_group_name or p_owner_group_name is null)
and  cb.incident_status_id in (2,9100)
and  jt.task_status_id not in (11,9,7,4);

C1_REC            C1%ROWTYPE;
LOOP_COUNT        NUMBER;
ln_task_status_id NUMBER;
ln_msg_count      number;
x_msg_data       varchar2(50);
x_return_status   varchar2(25);

 BEGIN
 
  fnd_file.put_line(fnd_file.output,'========================================================================');
  fnd_file.put_line(fnd_file.output,'                        OD: TDS Mass Close SR Tasks'); 
  fnd_file.put_line(fnd_file.output,'========================================================================'); 

      OPEN C1;
      LOOP
      FETCH C1 INTO C1_REC;
      EXIT WHEN C1%NOTFOUND;

       LOOP_COUNT := LOOP_COUNT + 1;
       
       IF C1_REC.INCIDENT_STATUS_ID = 2  THEN
          ln_task_status_id   := 11; --CLOSE
       ELSE
          ln_task_status_id := 7; --cancel
       END IF;
       /**********************************************************************
        -- Update task
       ********************************************************************/
          begin
           jtf_tasks_pub.update_task
            ( p_object_version_number => c1_rec.object_version_number
              ,p_api_version          => 1.0
              ,p_init_msg_list        => fnd_api.g_true
              ,p_commit               => fnd_api.g_false
              ,p_task_id              => c1_rec.task_id
              ,x_return_status        => x_return_status
              ,x_msg_count            => ln_msg_count
              ,x_msg_data             => x_msg_data
              ,p_task_status_id       => ln_task_status_id);
              
              IF NVL(X_RETURN_STATUS,'S') <> 'S' THEN
                 retcode:=1;
                 fnd_file.put_line(FND_FILE.log,X_RETURN_STATUS||' Task Id '||c1_rec.task_id||' Unprocessed SR number : '||c1_rec.incident_number);
		     fnd_file.put_line(FND_FILE.output,X_RETURN_STATUS||' Task Id '||c1_rec.task_id||' Unprocessed SR number : '||c1_rec.incident_number);
                 else
                 fnd_file.put_line(FND_FILE.OUTPUT,X_RETURN_STATUS||' Task Id '||c1_rec.task_id||' Closed for SR number : '||c1_rec.incident_number);
              END IF;

           exception
           
           when others then
               fnd_file.put_line(FND_FILE.OUTPUT,SQLERRM);
               errbuf := SUBSTR(SQLERRM,1,80);
            end;
            
          IF loop_count = 500 then
             commit;
             loop_count := 0;
          end if;
          
        end loop;
        close c1;  
END;

/******************************************************************************/

END XX_CS_TDS_CLOSE_SR;
/