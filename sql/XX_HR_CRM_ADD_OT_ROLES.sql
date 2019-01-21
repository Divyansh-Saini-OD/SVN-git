declare
cursor lcu_rol IS
SELECT    distinct JRRV.role_id
                 , JRRV.role_code
FROM       apps.jtf_rs_roles_vl JRRV
           ,apps.jtf_rs_job_roles JRJR
          ,apps.per_jobs PRJ
WHERE    JRRV.role_id = JRJR.role_id
AND JRJR.job_id = PRJ.job_id
and PRJ.name 
in
('CNBSD:000110:MANAGER, DISTRICT SALES',
'USBSD:000110:MANAGER, DISTRICT SALES',
'USBSD:000114:DIRECTOR, REGIONAL SALES I',
'USBSD:000188:DIRECTOR, REGIONAL SALES II',
'USBSD:001273:MANAGER, DISTRICT SALES II');

-- Resources that are DSM's and RSD's
cursor lcu_manager_resources IS
SELECT 
     distinct rsc.resource_id, rr.role_resource_id, rsc.source_name, rr.start_date_active
       from apps.jtf_rs_resource_extns_vl rsc,
            apps.jtf_rs_role_relations    rr,
            apps.jtf_rs_roles_vl          rol,
            apps.jtf_rs_job_roles         jr,
            apps.per_jobs                 js            
      where rsc.resource_id = rr.role_resource_id
       AND rr.role_id            = rol.role_id
       AND rol.role_id           = jr.role_id
       AND jr.job_id             = js.job_id       
       AND rr.role_resource_type = 'RS_INDIVIDUAL'
       AND (rol.role_type_code   IN ('SALES', 'TELESALES') or rol.row_id is null)
       AND nvl(rr.delete_flag,'N')  <> 'Y'
       AND  nvl(rol.manager_flag,'N')  = 'Y'
       AND trunc(sysdate) between nvl(rsc.start_date_active, sysdate-1)
                              AND nvl(rsc.end_date_active,   sysdate+1)
       AND trunc(sysdate) between nvl(rr.start_date_active, sysdate-1)
                              AND nvl(rr.end_date_active,   sysdate+1)
      AND (
        js.name like 'CNBSD:000110%'
        OR  js.name like 'CNBSD:000110%'
        OR  js.name like 'USBSD:000114%'
        OR  js.name like 'USBSD:000188%'
        OR  js.name like 'USBSD:001273%'
      );

--       AND js.name in ('CNBSD:000110:MANAGER, DISTRICT SALES',
 --                       'USBSD:000110:MANAGER, DISTRICT SALES',
 --                       'USBSD:000114:DIRECTOR, REGIONAL SALES I',
--                        'USBSD:000188:DIRECTOR, REGIONAL SALES II',
--                        'USBSD:001273:MANAGER, DISTRICT SALES II');
                    

cursor lcu_check_rsc_grp_rol_exist (p_resource_id NUMBER, p_role_id NUMBER)
IS
SELECT 
      'Y'
       from apps.jtf_rs_resource_extns_vl rsc,
            apps.jtf_rs_group_members     mem,
            apps.jtf_rs_groups_vl         grp,
            apps.jtf_rs_role_relations    rr,
            apps.jtf_rs_roles_vl          rol,
            apps.jtf_rs_job_roles         jr,
            apps.per_jobs                 js
      where rsc.resource_id      = mem.resource_id
       AND mem.group_id          = grp.group_id
       AND mem.group_member_id   = rr.role_resource_id
       AND rr.role_id            = rol.role_id
       AND rol.role_id           = jr.role_id
       AND jr.job_id             = js.job_id
       AND rsc.category          = 'EMPLOYEE'
       AND rr.role_resource_type = 'RS_GROUP_MEMBER'
       AND (rol.role_type_code   IN ('SALES', 'TELESALES') or rol.row_id is null)
       AND nvl(mem.delete_flag,'N') <> 'Y'
       AND nvl(rr.delete_flag,'N')  <> 'Y'
       AND  nvl(rol.manager_flag,'N')  = 'N'
       AND trunc(sysdate) between nvl(rsc.start_date_active, sysdate-1)
                              AND nvl(rsc.end_date_active,   sysdate+1)
       AND trunc(sysdate) between nvl(rr.start_date_active, sysdate-1)
                              AND nvl(rr.end_date_active,   sysdate+1)
       AND trunc(sysdate) between nvl(grp.start_date_active, sysdate-1)
                              AND nvl(grp.end_date_active,   sysdate+1)
       AND grp.group_name like 'OD_GRP%'
       AND rsc.resource_id = p_resource_id
       AND rol.role_id = p_role_id; 

cursor lcu_check_rsc_ind_rol_exist (p_resource_id NUMBER, p_role_id NUMBER)
IS       
SELECT 
     'Y'
       from apps.jtf_rs_resource_extns_vl rsc,
            apps.jtf_rs_role_relations    rr,
            apps.jtf_rs_roles_vl          rol,
            apps.jtf_rs_job_roles         jr,
            apps.per_jobs                 js            
      where rsc.resource_id = rr.role_resource_id
       AND rr.role_id            = rol.role_id
       AND rol.role_id           = jr.role_id
       AND jr.job_id             = js.job_id       
       AND rr.role_resource_type = 'RS_INDIVIDUAL'
       AND (rol.role_type_code   IN ('SALES', 'TELESALES') or rol.row_id is null)
       AND nvl(rr.delete_flag,'N')  <> 'Y'
       AND  nvl(rol.manager_flag,'N')  = 'N'
       AND trunc(sysdate) between nvl(rsc.start_date_active, sysdate-1)
                              AND nvl(rsc.end_date_active,   sysdate+1)
       AND trunc(sysdate) between nvl(rr.start_date_active, sysdate-1)
                              AND nvl(rr.end_date_active,   sysdate+1)
       AND rsc.resource_id = p_resource_id
       AND rol.role_id = p_role_id; 
       
--Get the role_resource_id at the group level
cursor lcu_get_role_rsc_id_for_grp (p_resource_id NUMBER)
IS
SELECT 
      distinct rr.role_resource_id, rr.start_date_active
       from apps.jtf_rs_resource_extns_vl rsc,
            apps.jtf_rs_group_members     mem,
            apps.jtf_rs_groups_vl         grp,
            apps.jtf_rs_role_relations    rr,
            apps.jtf_rs_roles_vl          rol,
            apps.jtf_rs_job_roles         jr,
            apps.per_jobs                 js
      where rsc.resource_id      = mem.resource_id
       AND mem.group_id          = grp.group_id
       AND mem.group_member_id   = rr.role_resource_id
       AND rr.role_id            = rol.role_id
       AND rol.role_id           = jr.role_id
       AND jr.job_id             = js.job_id
       AND rsc.category          = 'EMPLOYEE'
       AND rr.role_resource_type = 'RS_GROUP_MEMBER'
       AND (rol.role_type_code   IN ('SALES', 'TELESALES') or rol.row_id is null)
       AND nvl(mem.delete_flag,'N') <> 'Y'
       AND nvl(rr.delete_flag,'N')  <> 'Y'
       AND  nvl(rol.manager_flag,'N')  = 'Y'
       AND trunc(sysdate) between nvl(rsc.start_date_active, sysdate-1)
                              AND nvl(rsc.end_date_active,   sysdate+1)
       AND trunc(sysdate) between nvl(rr.start_date_active, sysdate-1)
                              AND nvl(rr.end_date_active,   sysdate+1)
       AND trunc(sysdate) between nvl(grp.start_date_active, sysdate-1)
                              AND nvl(grp.end_date_active,   sysdate+1)
       AND grp.group_name like 'OD_GRP%'
       AND rsc.resource_id = p_resource_id;

  ln_resource_id number;
  lc_rec_found varchar2(1);
  ln_role_resource_id number;
  lc_ret_stat VARCHAR2(250);
  ln_msg_cnt number;
  lc_msg_data VARCHAR2(2500);
  ln_role_relate_id number;  
  ld_start_date_active DATE;
BEGIN

    FOR managers_rec IN lcu_manager_resources
    LOOP
    
      FOR role_rec IN lcu_rol 
      LOOP
        dbms_output.put_line('managers_rec.resource_id=' || managers_rec.resource_id);
        dbms_output.put_line('managers_rec.source_name=' || managers_rec.source_name);
        dbms_output.put_line('role_rec.role_code=' || role_rec.role_code);
        dbms_output.put_line('role_rec.role_id=' || role_rec.role_id);
        
        lc_rec_found := NULL;
        
        IF lcu_check_rsc_ind_rol_exist%ISOPEN THEN
          close lcu_check_rsc_ind_rol_exist;
        END IF;
        
        OPEN  lcu_check_rsc_ind_rol_exist(managers_rec.resource_id, role_rec.role_id);
        FETCH lcu_check_rsc_ind_rol_exist into lc_rec_found;
        dbms_output.put_line('lc_rec_found =' || lc_rec_found);

        CLOSE lcu_check_rsc_ind_rol_exist;
        

        IF NVL(lc_rec_found, 'N') = 'N' THEN
         dbms_output.put_line('INSIDE');
          XX_JTF_RS_ROLE_RELATE_PUB.create_resource_role_relate
          (
             P_API_VERSION          => 1.0,
             P_ROLE_RESOURCE_TYPE   => 'RS_INDIVIDUAL',
             P_ROLE_RESOURCE_ID     => managers_rec.role_resource_id,
             P_ROLE_ID              => role_rec.role_id,
             P_ROLE_CODE            => role_rec.role_code,
             P_START_DATE_ACTIVE    => managers_rec.start_date_active,
             X_RETURN_STATUS        => lc_ret_stat,
             X_MSG_COUNT            => ln_msg_cnt,
             X_MSG_DATA             => lc_msg_data,
             X_ROLE_RELATE_ID       => ln_role_relate_id
          );  
          
          IF lc_ret_stat = FND_API.G_RET_STS_SUCCESS THEN
          
            dbms_output.put_line('Resource role individual created successfully for role code  ' || role_rec.role_code);
          
          ELSE
            dbms_output.put_line('ERROR creating a individual role relation. Role code: ' 
                                  || role_rec.role_code
                                  || ' resource id: ' 
                                  || managers_rec.resource_id);
          END IF;
          
          lc_rec_found := NULL;

          IF lcu_check_rsc_grp_rol_exist%ISOPEN THEN
            CLOSE lcu_check_rsc_grp_rol_exist;
          END IF;
          
          OPEN  lcu_check_rsc_grp_rol_exist(managers_rec.resource_id, role_rec.role_id);
          FETCH lcu_check_rsc_grp_rol_exist into lc_rec_found;
          CLOSE lcu_check_rsc_grp_rol_exist;

          IF NVL(lc_rec_found, 'N') = 'N' THEN
          
            ln_role_resource_id := NULL;
            ld_start_date_active := NULL;
            --get the role_resource_id at the group level
            OPEN lcu_get_role_rsc_id_for_grp(managers_rec.resource_id);
            FETCH lcu_get_role_rsc_id_for_grp into ln_role_resource_id, ld_start_date_active;

            IF lcu_get_role_rsc_id_for_grp%NOTFOUND THEN
              dbms_output.put_line('resource id ' || managers_rec.resource_id || 'not found at the grp level. Role resource id not found');
            ELSE
              XX_JTF_RS_ROLE_RELATE_PUB.create_resource_role_relate
              (
                 P_API_VERSION          => 1.0,
                 P_ROLE_RESOURCE_TYPE   => 'RS_GROUP_MEMBER',
                 P_ROLE_RESOURCE_ID     => ln_role_resource_id,
                 P_ROLE_ID              => role_rec.role_id,
                 P_ROLE_CODE            => role_rec.role_code,
                 P_START_DATE_ACTIVE    => ld_start_date_active,
               X_RETURN_STATUS        => lc_ret_stat,
               X_MSG_COUNT            => ln_msg_cnt,
               X_MSG_DATA             => lc_msg_data,
               X_ROLE_RELATE_ID       => ln_role_relate_id
              );
                  
              IF lc_ret_stat = FND_API.G_RET_STS_SUCCESS THEN
              
                dbms_output.put_line('Resource role group created successfully for role code ' || role_rec.role_code);
              
              ELSE
                dbms_output.put_line('ERROR creating a group role relation. Role code: ' 
                                      || role_rec.role_code
                                      || ' resource id: ' 
                                      || managers_rec.resource_id);
              END IF;
            END IF;
            IF lcu_get_role_rsc_id_for_grp%ISOPEN THEN
              CLOSE lcu_get_role_rsc_id_for_grp;
            END IF;
          END IF;
        ELSE
          dbms_output.put_line('FOUND');
        END IF;
      
      END LOOP;      
      
    END LOOP;
    
    COMMIT;

    EXCEPTION WHEN OTHERS THEN
    rollback;
      dbms_output.put_line('EXCEPTION');
      dbms_output.put_line(SQLERRM);
      IF lcu_manager_resources%ISOPEN THEN
        CLOSE lcu_manager_resources;
      END IF;
      IF lcu_rol%ISOPEN THEN
        CLOSE lcu_rol;
      END IF;
END;
/


