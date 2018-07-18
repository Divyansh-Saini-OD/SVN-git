create or replace
PACKAGE BODY XX_CS_MPS_SYNC_PKG AS

  PROCEDURE TONER_REQ_SYNC( X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                            X_RETCODE         OUT  NOCOPY  NUMBER,
                            P_TYPE            IN VARCHAR2,
                            P_DAYS            IN NUMBER) AS
 
CURSOR C1 IS
select cb.incident_id, cb.object_version_number
from cs_incidents_all_b cb, cs_incident_types_tl ct
where ct.incident_type_id = cb.incident_type_id
and ct.name = 'MPS Supplies Request'
and cb.incident_status_id = 102;

c1_rec  c1%rowtype;

lc_status           varchar2(100);
ln_status_id        number;
ln_user_id          number ;
ln_resp_appl_id     number := 514;
ln_resp_id          number := 21739;
x_return_status     varchar2(25);
lc_message          varchar2(250);
lx_interaction_id   NUMBER;
ln_obj_ver          number;
lx_msg_count        NUMBER;
lx_msg_data         VARCHAR2(2000);

BEGIN

   select user_id
   into ln_user_id
   from fnd_user
   where user_name = 'CS_ADMIN';

   fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
   
   IF P_TYPE = 'IN PROGRESS' THEN
    BEGIN
     open c1;
     loop
     fetch c1 into c1_rec;
     exit when c1%notfound;
  
        ln_status_id := 9100;
  
  
    -- update SR status
  
            Begin
                -- DBMS_OUTPUT.PUT_LINE('Status '||ln_status_id||' '||lc_sr_status);
                   CS_SERVICEREQUEST_PUB.Update_Status
                    (p_api_version	=> 2.0,
                    p_init_msg_list	=> FND_API.G_TRUE,
                    p_commit		=> FND_API.G_FALSE,
                    x_return_status	=> x_return_status,
                    x_msg_count	        => lx_msg_count,
                    x_msg_data		=> lx_msg_data,
                    p_resp_appl_id	=> ln_resp_appl_id,
                    p_resp_id		=> ln_resp_id,
                    p_user_id		=> ln_user_id,
                    p_login_id		=> NULL,
                    p_request_id		=> c1_rec.incident_id,
                    p_request_number	=> null,
                    p_object_version_number => c1_rec.object_version_number,
                    p_status_id	 	=> ln_status_id,
                    p_status		=> null,
                    p_closed_date		=> SYSDATE,
                    p_audit_comments	=> NULL,
                    p_called_by_workflow	=> NULL,
                    p_workflow_process_id	=> NULL,
                    p_comments		=> NULL,
                    p_public_comment_flag	=> NULL,
                    x_interaction_id	=> lx_interaction_id);
  
  
          commit;
        END;
  
          FND_FILE.PUT_LINE(FND_FILE.LOG,'SRID '||c1_rec.incident_id||'-'||X_RETURN_STATUS||' '||LX_MSG_DATA);
        end loop;
        close c1;
      exception
        when others then
           X_RETCODE := 1;
           X_ERRBUF := SQLERRM;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR WHILE UPDATING srS  : '|| SQLERRM);
      END;
    
    END IF;
  END TONER_REQ_SYNC;

END XX_CS_MPS_SYNC_PKG;
/
show errors;
exit;