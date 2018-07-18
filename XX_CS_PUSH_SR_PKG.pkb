create or replace
PACKAGE BODY XX_CS_PUSH_SR_PKG AS

  PROCEDURE ASSIGN_SRs (X_ERRBUF      OUT NOCOPY VARCHAR2, 
                        X_RETCODE     OUT NOCOPY NUMBER,
                        P_GROUP_ID  IN NUMBER,
                        P_RESOURCE_ID IN NUMBER, 
                        P_NUMBER      IN NUMBER) AS
  
  lx_msg_count            NUMBER; 
  lx_msg_data             VARCHAR2(2000); 
  lx_request_id           NUMBER; 
  lx_request_number       VARCHAR2(50); 
  lx_interaction_id       NUMBER; 
  lx_workflow_process_id  NUMBER; 
  lx_msg_index_out        NUMBER; 
  lx_return_status        VARCHAR2(1); 
  ln_user_id              NUMBER;
  ln_resp_appl_id         number   :=  514;
  ln_resp_id              number   := 21739;
  lc_resource_type        varchar2(100) :=  'RS_EMPLOYEE';
  ln_incident_id          number;
  ln_obj_ver              number;
  
  l_service_request_rec   CS_ServiceRequest_PUB.service_request_rec_type; 
  l_notes_table           CS_SERVICEREQUEST_PUB.notes_table; 
  l_contacts_tab          CS_SERVICEREQUEST_PUB.contacts_table; 

  l_ctr                 NUMBER := 0;
  l_NUM_OF_DIST_ITEMS   NUMBER := 1;
  l_dist_wr_cur_cnt     NUMBER;
  lc_res_check_flag     VARCHAR2(1) := 'N';
  lc_return_msg         VARCHAR2(2000);
  ld_pst_date           date := HZ_TIMEZONE_PUB.Convert_DateTime(1,4,sysdate);
  ld_mst_date           date := HZ_TIMEZONE_PUB.Convert_DateTime(1,3,sysdate);
  ld_cst_date           date := HZ_TIMEZONE_PUB.Convert_DateTime(1,2,sysdate);

  ln_cst_time           number := (TO_CHAR(ld_cst_date ,'HH24.MI'))*3600;
  ln_mst_time           number := (TO_CHAR(ld_mst_date ,'HH24.MI'))*3600;
  ln_pst_time           number := (TO_CHAR(ld_pst_date ,'HH24.MI'))*3600;
  ln_est_time           number := (TO_CHAR(sysdate,'HH24.MI')*3600);

  
  CURSOR l_dist_wr_cur IS
    SELECT /*+ first_rows */ 
        item.work_item_id,
        item.workitem_pk_id,
        item.owner_id,
        item.owner_type,
        cb.incident_id,
        cb.incident_number,
        cb.object_version_number
    FROM ieu_uwqm_items item,
         cs_incidents_all_b cb
    WHERE cb.incident_id = item.workitem_pk_id
    AND   cb.incident_owner_id is null
    AND   cb.owner_group_id = p_group_id
    AND  item.workitem_obj_code = 'SR'
    AND  item.distribution_status_id = 1
    AND  item.status_id = 0
    AND  cb.incident_status_id <> 2
    AND  nvl(cb.status_flag, 'N') <> 'C'
   -- AND  nvl(close_flag,'N') <> 'Y'
    AND  item.reschedule_time <= sysdate
    and decode(cb.time_zone_id,4,ln_pst_time,3,ln_mst_time,2,ln_cst_time,1,ln_est_time) between 28800 and 61200 
    ORDER BY priority_level, due_date ;
   
       
    l_dist_nw_item  l_dist_wr_cur%rowtype;
		        
  BEGIN
      -- CS_ADMIN user
      begin
        select user_id
        into ln_user_id
        from fnd_user
        where user_name = 'CS_ADMIN';
      exception
        when others then
          x_retcode := 1;
          x_errbuf  := 'Error while selecting user id';
      end;
    
    FND_GLOBAL.APPS_INITIALIZE(user_id => ln_user_id,
                              resp_id => ln_resp_id, 
                              resp_appl_id => ln_resp_appl_id);

    lc_return_msg := 'Group Id : '||p_group_id ||' Resource Id: '||p_resource_id|| ' number '||p_number;
    fnd_file.put_line(fnd_file.log, lc_return_msg);

    IF ln_user_id is not null then
      -- Resource Verification
      begin
        select 'Y' 
        into lc_res_check_flag
        from jtf_rs_group_members
        where group_id = p_group_id
        and resource_id = p_resource_id
        and nvl(delete_flag, 'N') <> 'Y';
      EXCEPTION 
        WHEN OTHERS THEN
           lc_res_check_flag := 'N';
      end;
           
      IF lc_res_check_flag = 'Y' then
        l_ctr := 0;
        
        -- select Resource existing open SRs
          begin
            select count(*) 
            into l_dist_wr_cur_cnt 
            from cs_incidents_all_b
            where incident_owner_id = p_resource_id
            and owner_group_id = p_group_id
            and incident_status_id in (
            select incident_status_id 
            from cs_incident_statuses
            where incident_subtype = 'INC'
            and  nvl(close_flag,'N') <> 'Y'
            and  nvl(on_hold_flag,'N') <> 'Y');
          exception
            when others then
              l_dist_wr_cur_cnt := 1;
          end;
          
          lc_return_msg := l_dist_wr_cur_cnt||'SRs already assinged. ';
          fnd_file.put_line(fnd_file.log, lc_return_msg);
          begin
     
            -- Select the top Work Items for Distribution
            OPEN l_dist_wr_cur;
            LOOP
  
               FETCH l_dist_wr_cur into l_dist_nw_item;
               exit when ( (l_dist_wr_cur%NOTFOUND) OR (l_dist_wr_cur_cnt > p_number) ) ;
              --DBMS_OUTPUT.PUT_LINE('SR '||l_dist_nw_item.incident_number);
               l_dist_wr_cur_cnt := l_dist_wr_cur_cnt + 1;
               ln_incident_id   := l_dist_nw_item.incident_id;
               ln_obj_ver       := l_dist_nw_item.object_version_number;
  
           
              	CS_ServiceRequest_PUB.Update_Owner
                        ( p_api_version		      => 2.0,
                          p_init_msg_list	      => fnd_api.g_false, 
                          p_commit		      => fnd_api.g_false,
                          p_resp_appl_id	      => ln_resp_appl_id,
                          p_resp_id                   => ln_resp_id    ,
                          p_user_id	              => ln_user_id,
                          p_login_id		      => null,
                          p_request_id  	      => ln_incident_id,
                          p_request_number	      => null,
                          p_object_version_number     => ln_obj_ver,
                          p_owner_id		      => p_resource_id,
                          p_owner_group_id            => p_group_id,
                          p_resource_type             => lc_resource_type,
                          p_audit_comments	      => null,
                          p_called_by_workflow	      => fnd_api.g_false,
                          p_workflow_process_id	      => null,
                          p_comments		      => null,
                          p_public_comment_flag	      => fnd_api.g_false,
                          x_interaction_id	      => lx_interaction_id,
                          x_return_status	      => lx_return_status ,
                          x_msg_count		      => lx_msg_count ,
                          x_msg_data		      => lx_msg_data );
                          
                        

                IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS) then
                  IF (FND_MSG_PUB.Count_Msg > 1) THEN
                  --Display all the error messages
                    FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                            FND_MSG_PUB.Get(
                                      p_msg_index => j,
                                      p_encoded => 'F',
                                      p_data => lx_msg_data,
                                      p_msg_index_out => lx_msg_index_out );
        
                          DBMS_OUTPUT.PUT_LINE(lx_msg_data);
                    END LOOP;
                  ELSE
                              --Only one error
                          FND_MSG_PUB.Get(
                                      p_msg_index => 1,
                                      p_encoded => 'F',
                                      p_data => lx_msg_data,
                                      p_msg_index_out => lx_msg_index_out );
                          DBMS_OUTPUT.PUT_LINE(lx_msg_data);
                          DBMS_OUTPUT.PUT_LINE(lx_msg_index_out );
                  END IF;
                  lx_msg_data := lx_msg_data;
                 ELSE
                  
                     begin
                             update ieu_uwqm_items
                             set distribution_status_id = 2
                             where work_item_id = l_dist_nw_item.work_item_id;
                    exception
                      when others then
                           x_retcode := 1;
                           x_errbuf  := 'Error while updating work Item Id';
                           lc_return_msg := 'Error while updating work item Id '||sqlerrm;
                           fnd_file.put_line(fnd_file.log, lc_return_msg);
                    end;  
                  
                      lc_return_msg := 'SR# '||l_dist_nw_item.incident_number|| ' assinged. ';
                      fnd_file.put_line(fnd_file.log, lc_return_msg);
                 END IF;
                        
               l_ctr := l_ctr + 1;
  
            END LOOP;
            CLOSE l_dist_wr_cur;
            COMMIT;
           end;
      ELSE
           lc_return_msg := 'Resource is not exists in this group. ';
           fnd_file.put_line(fnd_file.log, lc_return_msg);
      END IF;
    end if; -- user id
  END ASSIGN_SRs;

END XX_CS_PUSH_SR_PKG;
/
show errors;
exit;