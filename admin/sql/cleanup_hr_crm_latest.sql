set serverout on size 1000000
spool cleanup_hr_crm.txt

declare
  cursor lcu_prxy_role is
  select *
  from   apps.jtf_rs_roles_vl
  where  role_name = 'PRXY';

  cursor lcu_comp_relate is
  select jrrr.role_relate_id, jrrr.role_resource_type, jrrr.start_date_active, jrrr.end_date_active,
         decode(jrrr.role_resource_type, 'RS_GROUP_MEMBER', 1, 'RS_GROUP', 2, 3) del_order,
         jrrr.object_version_number
  from   apps.jtf_rs_role_relations jrrr,
         apps.jtf_rs_roles_vl jrrv
  where  jrrv.role_type_code = 'SALES_COMP'
    and  jrrr.role_id = jrrv.role_id
    and  nvl(jrrr.delete_flag, 'N') <> 'Y'
  order by 5;

  cursor lcu_sales_comp_roles is
  select j.job_role_id, j.job_id, j.role_id, j.job_name, r.role_name
  from   apps.jtf_rs_job_roles_vl j,
         apps.jtf_rs_roles_vl r
  where  r.role_type_code = 'SALES_COMP'
    and  j.role_id = r.role_id;

  cursor lcu_groups is
  select *
  from   apps.jtf_rs_groups_vl;


  ln_msg_count                  NUMBER ;
  lc_return_status              VARCHAR2(5000);
  lc_msg_data                   VARCHAR2(5000);
  lc_error_flag                 VARCHAR2(1) := 'N';

begin
  -- Update attribute14 for Proxy role
  for prxy_rec in lcu_prxy_role loop
    JTF_RS_ROLES_PKG.UPDATE_ROW(X_ROLE_ID                      => prxy_rec.role_id,
                                X_ATTRIBUTE3                   => prxy_rec.attribute3,
                                X_ATTRIBUTE4                   => prxy_rec.attribute4,
                                X_ATTRIBUTE5                   => prxy_rec.attribute5,
                                X_ATTRIBUTE6                   => prxy_rec.attribute6,
                                X_ATTRIBUTE7                   => prxy_rec.attribute7,
                                X_ATTRIBUTE8                   => prxy_rec.attribute8,
                                X_ATTRIBUTE9                   => prxy_rec.attribute9,
                                X_ATTRIBUTE10                  => prxy_rec.attribute10,
                                X_ATTRIBUTE11                  => prxy_rec.attribute11,
                                X_ATTRIBUTE12                  => prxy_rec.attribute12,
                                X_ATTRIBUTE13                  => prxy_rec.attribute13,
                                X_ATTRIBUTE14                  => 'PRXY',
                                X_ATTRIBUTE15                  => prxy_rec.attribute15,
                                X_ATTRIBUTE_CATEGORY           => prxy_rec.attribute_category,
                                X_ROLE_CODE                    => prxy_rec.role_code,
                                X_ROLE_TYPE_CODE               => prxy_rec.role_type_code,
                                X_SEEDED_FLAG                  => prxy_rec.seeded_flag,
                                X_MEMBER_FLAG                  => prxy_rec.member_flag,
                                X_ADMIN_FLAG                   => prxy_rec.admin_flag,
                                X_LEAD_FLAG                    => prxy_rec.lead_flag,
                                X_MANAGER_FLAG                 => prxy_rec.manager_flag,
                                X_ACTIVE_FLAG                  => prxy_rec.active_flag,
                                X_OBJECT_VERSION_NUMBER        => prxy_rec.object_version_number,
                                X_ATTRIBUTE1                   => prxy_rec.attribute1,
                                X_ATTRIBUTE2                   => prxy_rec.attribute2,
                                X_ROLE_NAME                    => prxy_rec.role_name,
                                X_ROLE_DESC                    => prxy_rec.role_desc,
                                X_LAST_UPDATE_DATE             => sysdate,
                                X_LAST_UPDATED_BY              => FND_GLOBAL.USER_ID,
                                X_LAST_UPDATE_LOGIN            => FND_GLOBAL.LOGIN_ID
                               );


  end loop;

  -- Delete Sales Comp role relations
  for sc_relate_rec in lcu_comp_relate loop
      ln_msg_count     := null;
      lc_return_status := null;
      lc_msg_data      := null;

      JTF_RS_ROLE_RELATE_PUB.delete_resource_role_relate
        (P_API_VERSION         => 1.0,
         P_ROLE_RELATE_ID      => sc_relate_rec.role_relate_id,
         P_OBJECT_VERSION_NUM  => sc_relate_rec.object_version_number,
         X_RETURN_STATUS       => lc_return_status,
         X_MSG_COUNT           => ln_msg_count,
         X_MSG_DATA            => lc_msg_data
        );     

      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        dbms_output.put_line('Error Deleting Role Relate id = ' || sc_relate_rec.role_relate_id || '----> ' || 
                              substr(fnd_msg_pub.get(1, FND_API.G_FALSE), 1, 100)
                            );
        dbms_output.put_line('lc_retrun_status = ' || lc_return_status || ' lc_msg_data = ' || lc_msg_data);
        lc_error_flag := 'Y';
        exit;
      END IF;
  end loop;

  -- Delete Sales Comp job role mapping

  for sc_rec in lcu_sales_comp_roles loop
    JTF_RS_JOB_ROLES_PKG.DELETE_ROW(X_JOB_ROLE_ID     => sc_rec.job_role_id);
  end loop;

  -- Set group start date for all groups to 01/01/1980
  for group_rec in lcu_groups loop
    ln_msg_count     := null;
    lc_return_status := null;
    lc_msg_data      := null;

    jtf_rs_groups_pub.update_resource_group(P_API_VERSION                  => 1.0,
                                            P_GROUP_ID                     => group_rec.group_id,
                                            P_GROUP_NUMBER                 => group_rec.group_number,
                                            P_START_DATE_ACTIVE            => to_date('01-JAN-1980'),
                                            P_OBJECT_VERSION_NUM           => group_rec.object_version_number,
                                            X_RETURN_STATUS                => lc_return_status,
                                            X_MSG_COUNT                    => ln_msg_count,
                                            X_MSG_DATA                     => lc_msg_data
                                           );

     IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       dbms_output.put_line('Error Updating group with id = ' || group_rec.group_id || '----> ' || 
                            substr(fnd_msg_pub.get(1, FND_API.G_FALSE), 1, 100)
                           );
       dbms_output.put_line('lc_retrun_status = ' || lc_return_status || ' lc_msg_data = ' || lc_msg_data);
       lc_error_flag := 'Y';
       exit;
     END IF;

  end loop;


  if lc_error_flag = 'Y' then
    rollback;
  else
    commit;
  end if;

    
end;
/

spool off
set serverout off
