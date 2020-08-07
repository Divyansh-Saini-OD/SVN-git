SET VERIFY        OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_CUSTOM_LIA_PKG                                     |
-- |                                                                   |
-- | Description: Forms Personalization for auto population            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       25-May-08   Raj Jagarlamudi  Initial draft version       |
-- |1.1       13-Jun-08   Raj Jagarlamudi  added AOPS id procedure     |
-- |1.2       02-JUL-08   Raj Jagarlamudi  Added for EC                |
---+===================================================================+

CREATE OR REPLACE
PACKAGE BODY XX_CS_CUSTOM_LIA_PKG AS
  
/***********************************************************************/
PROCEDURE UPDATE_SR(P_SR_REQUEST_ID IN NUMBER)
AS
    l_res_date         date;
    l_resv_date        date;
    ln_aops_customer   number;
    lc_owner           varchar2(200);
    ln_customer        number;
    ln_type_id         number;
    l_create_date      date;
BEGIN
 
  begin 
    select incident_type_id, 
           customer_id,
           creation_date
    into   ln_type_id,
           ln_customer,
           l_create_date
    from cs_incidents_all_b
    where incident_id = p_sr_request_id;
  exception
    when others then
       null;
  end;
  
  If ln_type_id is not null then
    begin
      select (l_create_date + to_number(attribute1)/24),
             (l_create_date + to_number(attribute2)/24)
       into l_res_date, 
            l_resv_date 
       from cs_incident_types_b
       where incident_type_id = ln_type_id;
     exception
       when others then
         l_res_date  := sysdate;
         l_resv_date := (sysdate + 24/24 ) ;
    end; 
  end if;
   
  If ln_customer is not null then 
     begin
      select substr(orig_system_reference,1,8)
      into ln_aops_customer
      from hz_cust_accounts
      where party_id = ln_customer;
    exception
      when others then
        ln_aops_customer := null;
    end; 
  end if;
  
  begin 
     update cs_incidents_all_b
     set obligation_date = l_res_date,
         expected_resolution_date = l_resv_date,
         incident_attribute_9 = ln_aops_customer,
         incident_context = 'ORDER'
     where incident_id = p_sr_request_id;
     
     commit;
  exception
    when others then
      null;
  end;
END UPDATE_SR;   

/**************************************************************************
-- Task Assignment 
**************************************************************************/
PROCEDURE TASK_ASSIGN (P_SR_REQUEST_ID IN NUMBER)
AS 

BEGIN

    XX_CS_CUSTOM_LIA_PKG.UPDATE_SR_STATUS(P_SR_REQUEST_ID, 'Waiting');
    
EXCEPTION
  WHEN OTHERS THEN
     null;
END TASK_ASSIGN;
/**************************************************************************
-- Close Task 
**************************************************************************/
PROCEDURE TASK_CLOSED (P_SR_REQUEST_ID IN NUMBER)
AS 

BEGIN
    XX_CS_CUSTOM_LIA_PKG.UPDATE_SR_STATUS(P_SR_REQUEST_ID, 'Respond');
exception
  when others then
     null;
END TASK_CLOSED;
/***************************************************************************
  -- Update SR status
*****************************************************************************/
Procedure Update_SR_status(p_sr_request_id    in number,
                           p_status            in varchar2)
IS
      x_msg_data         varchar2(500);
      x_msg_count	 NUMBER;
      x_interaction_id   NUMBER;
      x_return_status    varchar2(25);
      ln_obj_ver         NUMBER;
      ln_msg_index       number;
      ln_msg_index_out   number;
      ln_user_id         number ; 
      ln_resp_appl_id    number :=  514;
      ln_resp_id         number := 21739; 
      lc_comments        varchar2(1000);
      ln_status_id       number;
      ln_ext_status_id   number;
      lc_status          varchar2(25);
      
BEGIN

     begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    exception
      when others then
        ln_user_id := fnd_global.user_id;
    end;
    
     /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

     /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
     SELECT object_version_number, 
            incident_status_id
     INTO ln_obj_ver, ln_ext_status_id
     FROM   cs_incidents_all_b
     WHERE  incident_id = p_sr_request_id;
    EXCEPTION
      WHEN OTHERS THEN
         ln_ext_status_id := ln_status_id;
    END;
     /*********************************************************************
       -- Get status id
      *********************************************************************/
      begin 
        select incident_status_id, name
        into ln_status_id, lc_status
        from CS_INCIDENT_STATUSES_VL 
        where name = p_status;
      exception
      when others then
         ln_status_id := null;
      end;
      
      If p_status = 'Respond' then
        lc_comments := 'Task response received';
      else
        lc_comments := 'Waiting for response from Assignee';
      End if;
     
    /***********************************************************************
     -- Update SR
     ***********************************************************************/
     IF ln_ext_status_id <> ln_status_id then
      CS_SERVICEREQUEST_PUB.Update_Status
            (p_api_version		=> 2.0,
             p_init_msg_list	        => FND_API.G_TRUE,
             p_commit		        => FND_API.G_FALSE,
              x_return_status	        => x_return_status,
              x_msg_count	        => x_msg_count,
              x_msg_data		=> x_msg_data,
              p_resp_appl_id	        => ln_resp_appl_id,
              p_resp_id		        => ln_resp_id,
              p_user_id		        => ln_user_id,
              p_login_id		=> NULL,
              p_request_id		=> p_sr_request_id,
              p_request_number	        => NULL,
              p_object_version_number   => ln_obj_ver,
              p_status_id	 	=> ln_status_id,
              p_status		        => lc_status,
              p_closed_date		=> SYSDATE,
              p_audit_comments	        => NULL,
              p_called_by_workflow	=> NULL,
              p_workflow_process_id	=> NULL,
              p_comments		=> NULL,
              p_public_comment_flag	=> NULL,
              x_interaction_id	        => x_interaction_id );

   -- DBMS_OUTPUT.PUT_LINE('Before update note '||x_return_status);
    -- Check errors

       IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
          IF (FND_MSG_PUB.Count_Msg > 1) THEN
          --Display all the error messages
            FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                    FND_MSG_PUB.Get(
                              p_msg_index => j,
                              p_encoded => 'F',
                              p_data => x_msg_data,
                              p_msg_index_out => ln_msg_index_out);

                  DBMS_OUTPUT.PUT_LINE(x_msg_data);
            END LOOP;
          ELSE
                      --Only one error
                  FND_MSG_PUB.Get(
                              p_msg_index => 1,
                              p_encoded => 'F',
                              p_data => x_msg_data,
                              p_msg_index_out => ln_msg_index_out);
                  DBMS_OUTPUT.PUT_LINE(x_msg_data);
                  DBMS_OUTPUT.PUT_LINE(ln_msg_index_out);
          END IF;
          x_msg_data := x_msg_data;
      END IF;
     COMMIT;
    end if;
exception
  when others then
     null;
END Update_SR_Status;

END XX_CS_CUSTOM_LIA_PKG;
/
show errors;
exit;
