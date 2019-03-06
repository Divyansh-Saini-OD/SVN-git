create or replace
PACKAGE BODY "XX_CS_SR_UTILS_PKG" AS

/*****************************************************************************
  Create Credit Disput SR
******************************************************************************/
PROCEDURE CREATE_NON_GMILL_SR (P_SOURCE         IN VARCHAR2,
                               P_REQ_TYPE        IN VARCHAR2,
                               P_PROBLEM_CODE   IN VARCHAR2,
                               P_DESCRIPTION    IN VARCHAR2,
                               P_USER_ID        IN VARCHAR2,
                               P_CUSTOMER_ID    IN NUMBER,
                               X_REQUEST_NUM    IN OUT NOCOPY VARCHAR2,
                               X_REQUEST_ID     IN OUT NOCOPY VARCHAR2,
                               X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                               X_MSG_DATA       IN OUT NOCOPY VARCHAR2) 
IS 
                        
  LR_SR_REQ_REC                APPS.XX_CS_SR_REC_TYPE;
  LR_ECOM_SITE_KEY             APPS.XX_GLB_SITEKEY_REC_TYPE;
  LT_ORDER_TBL                 APPS.XX_CS_SR_ORDER_TBL;
  lr_order_rec                 XX_CS_SR_ORDER_REC_TYPE;
  I                            BINARY_INTEGER;
  ln_req_type_id               number;
BEGIN
  -- Initialization of Record types
  I := 1;
  LT_ORDER_TBL                := XX_CS_SR_ORDER_TBL();
  lr_order_rec                := XX_CS_SR_ORDER_REC_TYPE(null,null,null,null,null,null,null,null,null,null,null,null);

  lr_sr_req_rec               := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                   NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                  null,null,null);

  BEGIN
    SELECT INCIDENT_TYPE_ID 
    INTO LN_REQ_TYPE_ID
    FROM CS_INCIDENT_TYPES_TL
    WHERE NAME = P_REQ_TYPE;
  EXCEPTION
   WHEN OTHERS THEN
       X_RETURN_STATUS := 'F';
       X_MSG_DATA  := 'Request Type is not valid';
  END;
  
IF nvl(x_return_status,'S') = 'S' then
  lr_sr_req_rec.type_id   	:= ln_req_type_id;
  lr_sr_req_rec.description	:= p_description;
  lr_sr_req_rec.channel		:= 'PHONE';
  lr_sr_req_rec.problem_code	:= p_problem_code;
  lr_sr_req_rec.user_id           := p_user_id;
  lr_sr_req_rec.request_date      := sysdate;
  lr_sr_req_rec.customer_id       := p_customer_id;

  XX_CS_SERVICEREQUEST_PKG.CREATE_SERVICEREQUEST(
                          P_SR_REQ_REC => LR_SR_REQ_REC,
                          P_ECOM_SITE_KEY => LR_ECOM_SITE_KEY,
                          P_REQUEST_ID => X_REQUEST_ID,
                          P_REQUEST_NUM => X_REQUEST_NUM,
                          X_RETURN_STATUS => X_RETURN_STATUS,
                          X_MSG_DATA => X_MSG_DATA,
                          P_ORDER_TBL => LT_ORDER_TBL );
                          
  DBMS_OUTPUT.PUT_LINE('P_REQUEST_ID = ' || X_REQUEST_ID);
  DBMS_OUTPUT.PUT_LINE('P_REQUEST_NUM = ' || X_REQUEST_NUM);
  DBMS_OUTPUT.PUT_LINE('X_RETURN_STATUS = ' || X_RETURN_STATUS);
  DBMS_OUTPUT.PUT_LINE('X_MSG_DATA = ' || X_MSG_DATA);

END IF;  
END CREATE_NON_GMILL_SR;
/*****************************************************************************
-- Update Service Request after Credit Memo issued
*****************************************************************************/
PROCEDURE UPDATE_SR(P_SR_REQUEST_ID IN NUMBER,
                    P_COMMENTS      IN VARCHAR2,
                    P_USER_ID       IN NUMBER,
                    X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                    X_MSG_DATA      IN OUT NOCOPY VARCHAR2)
IS 

  LC_SR_STATUS_ID        VARCHAR2(25);
  LT_SR_NOTES            XX_CS_SR_NOTES_REC;
  lr_ecom_site_key       XX_GLB_SITEKEY_REC_TYPE;
  LC_USER_ID             VARCHAR2(200);
  i                      NUMBER;
BEGIN
  -- Modify the code to initialize the variable
   lt_sr_notes := XX_CS_SR_NOTES_REC(null,null,null,null);


         lt_sr_notes.notes          := p_comments;
         lt_sr_notes.note_details   := p_comments;
         lt_sr_notes.created_by     := p_user_id;
         lt_sr_notes.creation_date  := sysdate;
         lc_sr_status_id            := 'Waiting';

  XX_CS_SERVICEREQUEST_PKG.UPDATE_SERVICEREQUEST(
    P_SR_REQUEST_ID => P_SR_REQUEST_ID,
    P_SR_STATUS_ID => LC_SR_STATUS_ID,
    P_SR_NOTES => LT_SR_NOTES,
    p_ecom_site_key => lr_ecom_site_key,
    P_USER_ID => P_USER_ID,
    X_RETURN_STATUS => X_RETURN_STATUS,
    X_MSG_DATA => X_MSG_DATA
  );
  
    commit;
  EXCEPTION
   WHEN OTHERS THEN
       X_RETURN_STATUS := 'F';
       X_MSG_DATA  := 'Error while updating SR '||SQLERRM;
END UPDATE_SR;

/***************************************************************************
  -- Update owner of SR
*****************************************************************************/
Procedure Update_SR_Owner(p_sr_request_id    in number,
                          p_user_id          in varchar2,
                          p_owner            in varchar2,
                          x_return_status    in out nocopy varchar2,
                          x_msg_data         in out nocopy varchar2)
IS
      x_msg_count	 NUMBER;
      x_interaction_id   NUMBER;
      ln_obj_ver         NUMBER;
      ln_group_owner_id  number;
      ln_resource_type   varchar2(100);
      ln_msg_index       number;
      ln_msg_index_out   number;
      ln_user_id         number; -- := 1955;
      ln_resp_appl_id    number :=  514;
      ln_resp_id         number := 21739;  -- Customer Support

BEGIN

    begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    exception
      when others then
        x_return_status := 'F';
        x_msg_data := 'Error while selecting userid '||sqlerrm;
    end;
    
    IF p_owner is null then 
      ln_resource_type := null;
    end if;
   /********************************************************************
    --Apps Initialization
    *******************************************************************/
    apps.fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
    
    /***********************************************************************
     -- Update SR
     ***********************************************************************/
       CS_SERVICEREQUEST_PUB.Update_owner
        (p_api_version		=> 2.0,
        p_init_msg_list	        => FND_API.G_TRUE,
        p_commit		=> FND_API.G_FALSE,
        p_resp_appl_id	        => ln_resp_appl_id,
        p_resp_id		=> ln_resp_id,
        p_user_id		=> ln_user_id,
        p_login_id		=> NULL,
        p_request_id		=> p_sr_request_id,
        p_request_number	=> NULL,
        p_object_version_number => ln_obj_ver,
        p_owner_id	 	=> p_owner,
        p_owner_group_id	=> ln_group_owner_id,
        p_resource_type		=> ln_resource_type,
        p_audit_comments	=> NULL,
        p_called_by_workflow	=> NULL,
        p_workflow_process_id	=> NULL,
        p_comments		=> NULL,
        p_public_comment_flag	=> NULL,
        x_interaction_id	=> x_interaction_id,
        x_return_status	        => x_return_status,
        x_msg_count	        => x_msg_count,
        x_msg_data		=> x_msg_data);

 --   DBMS_OUTPUT.PUT_LINE('Before update note '||x_return_status);
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

END Update_SR_Owner;
/***************************************************************************
  -- Update SR status
*****************************************************************************/
Procedure Update_SR_status(p_sr_request_id    in number,
                          p_user_id           in varchar2,
                          p_status_id         in number,
                          p_status            in varchar2,
                          x_return_status     in out nocopy varchar2,
                          x_msg_data          in out nocopy varchar2)
IS
      x_msg_count	 NUMBER;
      x_interaction_id   NUMBER;
      ln_obj_ver         NUMBER;
      ln_msg_index       number;
      ln_msg_index_out   number;
      ln_user_id         number; 
      ln_resp_appl_id    number :=  514;
      ln_resp_id         number := 21739; 
      lc_problem_code    varchar2(250);
      ln_status_id       number;
      lc_status          varchar2(50);
      ln_type_id         number;
      lc_type_name       varchar2(250);
BEGIN
     begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    exception
      when others then
        x_return_status := 'F';
    end;
     /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

     /************************************************************************
    -- Get Object version, TYPE, PROBLEM CODE
    *********************************************************************/
    BEGIN
         SELECT object_version_number,
                problem_code,
                incident_type_id 
         INTO   ln_obj_ver, 
                lc_problem_code,
                ln_type_id
         FROM   cs_incidents_all_b
         WHERE  incident_id = p_sr_request_id;
    EXCEPTION
      WHEN OTHERS THEN
          x_return_status := 'F';
    END;
    
    BEGIN
        SELECT name
        INTO   lc_type_name
        FROM  cs_incident_types  
        WHERE incident_type_id = ln_type_id;
     EXCEPTION
      WHEN OTHERS THEN
          x_return_status := 'F';
    END;
        
       BEGIN
          SELECT incident_status_id, 
                 name
          INTO  ln_status_id, lc_status
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = p_status ;
        EXCEPTION
          WHEN OTHERS THEN
            ln_status_id := 51;
            lc_status    := 'Waiting';
        END;
     
    /***********************************************************************
     -- Update SR
     ***********************************************************************/
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

            COMMIT;
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

END Update_SR_Status;
/***************************************************************************/
/*********************************************************************************
    Create Notes
*********************************************************************************/
PROCEDURE CREATE_NOTE(p_request_id           in number,
                       p_sr_notes_rec         in XX_CS_SR_NOTES_REC,
                       p_return_status        in out nocopy varchar2,
                       p_msg_data             in out nocopy varchar2)
IS

ln_api_version		number;
lc_init_msg_list	varchar2(1);
ln_validation_level	number;
lc_commit		varchar2(1);
lc_return_status	varchar2(1);
ln_msg_count		number;
lc_msg_data		varchar2(2000);
ln_jtf_note_id		number;
ln_source_object_id	number;
lc_source_object_code	varchar2(8);
lc_note_status          varchar2(8);
lc_note_type		varchar2(80);
lc_notes		varchar2(2000);
lc_notes_detail		varchar2(8000);
ld_last_update_date	Date;
ln_last_updated_by	number;
ld_creation_date	Date;
ln_created_by		number;
ln_entered_by           number;
ld_entered_date         date;
ln_last_update_login    number;
lt_note_contexts	JTF_NOTES_PUB.jtf_note_contexts_tbl_type;
ln_msg_index		number;
ln_msg_index_out	number;

begin
/************************************************************************
--Initialize the Notes parameter to create
**************************************************************************/
ln_api_version			:= 1.0;
lc_init_msg_list		:= FND_API.g_true;
ln_validation_level		:= FND_API.g_valid_level_full;
lc_commit			:= FND_API.g_true;
ln_msg_count			:= 0;
/****************************************************************************
-- If ObjectCode is Party then Object_id is party id
-- If ObjectCode is Service Request then Object_id is Service Request ID
-- If ObjectCode is TASK then Object_id is Task id
****************************************************************************/
ln_source_object_id		:= p_request_id;
lc_source_object_code		:= 'SR';
lc_note_status			:= 'I';  -- (P-Private, E-Publish, I-Public)
lc_note_type			:= 'GENERAL';
lc_notes			:= p_sr_notes_rec.notes;
lc_notes_detail			:= p_sr_notes_rec.note_details;
ln_entered_by			:= FND_GLOBAL.user_id;
ld_entered_date			:= SYSDATE;
/****************************************************************************
-- Initialize who columns
*****************************************************************************/
ld_last_update_date		:= SYSDATE;
ln_last_updated_by		:= FND_GLOBAL.USER_ID;
ld_creation_date		:= SYSDATE;
ln_created_by			:= FND_GLOBAL.USER_ID;
ln_last_update_login		:= FND_GLOBAL.LOGIN_ID;
/******************************************************************************
-- Call Create Note API
*******************************************************************************/
JTF_NOTES_PUB.create_note (p_api_version        => ln_api_version,
                 	p_init_msg_list         => lc_init_msg_list,
                   	p_commit                => lc_commit,
                   	p_validation_level      => ln_validation_level,
                  	x_return_status         => lc_return_status,
                  	x_msg_count             => ln_msg_count ,
                  	x_msg_data              => lc_msg_data,
                  	p_jtf_note_id	        => ln_jtf_note_id,
                  	p_entered_by            => ln_entered_by,
                  	p_entered_date          => ld_entered_date,
			p_source_object_id	=> ln_source_object_id,
			p_source_object_code	=> lc_source_object_code,
			p_notes			=> lc_notes,
			p_notes_detail		=> lc_notes_detail,
			p_note_type		=> lc_note_type,
			p_note_status		=> lc_note_status,
			p_jtf_note_contexts_tab => lt_note_contexts,
			x_jtf_note_id		=> ln_jtf_note_id,
			p_last_update_date	=> ld_last_update_date,
			p_last_updated_by	=> ln_last_updated_by,
			p_creation_date		=> ld_creation_date,
			p_created_by		=> ln_created_by,
			p_last_update_login	=> ln_last_update_login );
                        
    -- check for errors
      IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS) then
          IF (FND_MSG_PUB.Count_Msg > 1) THEN
          --Display all the error messages
            FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                    FND_MSG_PUB.Get(
                              p_msg_index => j,
                              p_encoded => 'F',
                              p_data => lc_msg_data,
                              p_msg_index_out => ln_msg_index_out);
            END LOOP;
          ELSE
                      --Only one error
                  FND_MSG_PUB.Get(
                              p_msg_index => 1,
                              p_encoded => 'F',
                              p_data => lc_msg_data,
                              p_msg_index_out => ln_msg_index_out);
          END IF;
      END IF;
      p_msg_data          := lc_msg_data;
      p_return_status     := lc_return_status;

END CREATE_NOTE;
/***************************************************************************/
PROCEDURE GET_DATE_TIMES (P_CAL_ID IN VARCHAR2,
                          P_START_TIME IN OUT NUMBER,
                          P_END_TIME IN OUT NUMBER,
                          P_DATE IN OUT DATE)
IS
BEGIN
      begin
            select b2.from_time, b2.to_time, b1.next_date
            into   p_start_time, p_end_time, p_date
            from    bom_calendar_dates b1,
                    bom_shift_times b2
            where b2.calendar_code = b1.calendar_code
            and    b1.calendar_code = P_CAL_ID
            and   trunc(b1.calendar_date) = trunc(p_date)
            and   b2.shift_num = 1
            and   not exists ( select 'x' from bom_calendar_exceptions
                          where calendar_code = b1.calendar_code
                          and  exception_date = b1.calendar_date
                          and  exception_set_id = b1.exception_set_id);
          exception
            when others then
                p_date := p_date + 1;
      end;

END GET_DATE_TIMES;
/***************************************************************************/
FUNCTION RES_REV_TIME_CAL (P_DATE IN DATE,
                           P_HOURS IN NUMBER,
                           P_CAL_ID IN VARCHAR2) 
RETURN DATE IS

ln_curtime    number;
ln_addtime    number;
ln_remtime    number;
i             number := 1;
x_start_time  number;
x_end_time    number;
ln_bal_hours  number;
ld_date       date;
ln_days       number;

BEGIN

  IF p_hours > 8 then
    ln_days := floor(p_hours/8);
    ld_date := p_date;
    ln_curtime := (TO_NUMBER(TO_CHAR(LD_DATE,'HH24'))*3600);
    for i in 1 .. ln_days loop
      ld_date := ld_date + 1;
           begin
             get_date_times (p_cal_id => p_cal_id,
                             p_start_time => x_start_time,
                             p_end_time => x_end_time,
                             p_date => ld_date);
           end;
    end loop;
  else
    ld_date := p_date + p_hours/24;
    ln_curtime := (TO_NUMBER(TO_CHAR(LD_DATE,'HH24'))*3600);
         begin
             get_date_times (p_cal_id => p_cal_id,
                             p_start_time => x_start_time,
                             p_end_time => x_end_time,
                             p_date => ld_date);
          end;
  end if;
  
  IF ln_curtime > x_end_time then
     ln_remtime := ln_curtime - x_end_time;
     ln_bal_hours := 8 + floor(ln_remtime/3600);
     ld_date := ld_date+1;
         begin
             get_date_times (p_cal_id => p_cal_id,
                             p_start_time => x_start_time,
                             p_end_time => x_end_time,
                             p_date => ld_date);
          end;
     ld_date := (trunc(ld_date)) + ln_bal_hours/24;   
  ELSIF ln_curtime < x_start_time then
     ln_remtime := x_start_time - ln_curtime;
     ln_bal_hours := floor(ln_remtime/3600);
     ld_date := ld_date + ln_bal_hours/24;   
  ELSE
     ln_bal_hours := floor(ln_curtime/3600);
     ld_date := ld_date + ln_bal_hours/24; 
  END IF;
  
  return ld_date;
   
END RES_REV_TIME_CAL;
/**************************************************************************/
END;
/
Show errors;
exit;