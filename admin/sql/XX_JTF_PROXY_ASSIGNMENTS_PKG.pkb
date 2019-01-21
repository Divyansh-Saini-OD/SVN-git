CREATE OR REPLACE PACKAGE BODY XX_JTF_PROXY_ASSIGNMENTS_PKG AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_JTF_PROXY_ASSIGNMENTS_PKG.pkb                          |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | This stored procedure is the handler for the form                        |
-- | XX_JTF_PROXY_ASSIGNMENTS.fmb.                                            |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author              Remarks                         |
-- |========  =========== ==================  ================================|
-- |1.0       14-APR-2009  Phil Price         Initial version                 |
-- |                                                                          |
-- +==========================================================================+


G_PACKAGE CONSTANT VARCHAR2(30) := 'XX_JTF_PROXY_ASSIGNMENTS_PKG';

--
-- Subversion keywords
--
GC_SVN_HEAD_URL constant varchar2(500) := '$HeadURL$';
GC_SVN_REVISION constant varchar2(100) := '$Rev$';
GC_SVN_DATE     constant varchar2(100) := '$Date$';

LF constant varchar2(1) := chr(10);
-- ============================================================================


-------------------------------------------------------------------------------
function compare_values_vc (val1 in varchar2, val2 in varchar2) return boolean is
-------------------------------------------------------------------------------
begin
  if ((val1 = val2) OR ((val1 is null) AND (val2 is null))) then
    return true;
  else
    return false;
  end if;
end compare_values_vc;
-- ============================================================================


-------------------------------------------------------------------------------
function compare_values_num (val1 in number, val2 in number) return boolean is
-------------------------------------------------------------------------------
begin
  if ((val1 = val2) OR ((val1 is null) AND (val2 is null))) then
    return true;
  else
    return false;
  end if;
end compare_values_num;
-- ============================================================================


-------------------------------------------------------------------------------
function compare_values_dt (val1 in date, val2 in date) return boolean is
-------------------------------------------------------------------------------
begin
  if ((val1 = val2) OR ((val1 is null) AND (val2 is null))) then
    return true;
  else
    return false;
  end if;
end compare_values_dt;
-- ============================================================================


-------------------------------------------------------------------------------
procedure create_role_relate_rec (p_role_resource_type in  varchar2,
                                  p_role_resource_id   in  number,
                                  p_role_id            in  number,
                                  p_role_code          in  varchar2,
                                  p_start_date_active  in  date,
                                  p_end_date_active    in  date,
                                  p_role_relate_id     out number) is
-------------------------------------------------------------------------------

  lc_ctx  varchar2(500);
  lc_proc varchar2(100) := G_PACKAGE || '.create_role_relate_rec';

  lc_return_status      varchar2(1);
  ln_msg_count          number;
  lc_msg_data           varchar2(2000);

  lc_one_msg            varchar2(1000);
  lc_msg                varchar2(2000);

begin

  lc_ctx := 'jtf_rs_role_relate_pub.create_resource_role_relate - p_role_resource_type=' || p_role_resource_type ||
            ' p_role_resource_id=' || p_role_resource_id ||
            ' p_role_id='   || p_role_id;

  jtf_rs_role_relate_pub.create_resource_role_relate
         (p_api_version        => 1.0,
          p_init_msg_list      => fnd_api.G_TRUE,
          p_commit             => fnd_api.G_FALSE,
          p_role_resource_type => p_role_resource_type,
          p_role_resource_id   => p_role_resource_id,
          p_role_id            => p_role_id,
          p_role_code          => p_role_code,
          p_start_date_active  => p_start_date_active,
          p_end_date_active    => p_end_date_active,
          x_role_relate_id     => p_role_relate_id,
          x_return_status      => lc_return_status,
          x_msg_count          => ln_msg_count,
          x_msg_data           => lc_msg_data);

  if (lc_return_status = fnd_api.G_RET_STS_SUCCESS) then

    if (p_role_relate_id is null) then
      fnd_message.set_name('XXCRM', 'XX_CRM_0091_API_ERROR_UNKNOWN');
      fnd_message.set_token('DETAILS',
                            'x_role_relate_id is null after jtf_rs_role_relate_pub.create_resource_role_relate.' ||
                            '  p_role_resource_type=' || p_role_resource_type);
      app_exception.raise_exception; 
    end if;

  else
    for i in 1..ln_msg_count loop
      lc_one_msg := fnd_msg_pub.Get (p_encoded   => fnd_api.G_FALSE,
                                     p_msg_index => i);

      if (i = 1) then
        lc_msg := substr(lc_one_msg, 1, 2000);
      else
        lc_msg := substr(lc_msg || LF || lc_one_msg,1,2000);
      end if;
    end loop;

    fnd_message.set_name('XXCRM', 'XX_CRM_0090_API_ERROR'); 
    fnd_message.set_token('API_ERROR', lc_msg); 
    app_exception.raise_exception; 
  end if;




end create_role_relate_rec;
-- ============================================================================


-------------------------------------------------------------------------------
procedure assign_role_to_resource (p_resource_id            in number,
                                   p_resource_start_date    in date,
                                   p_role_assign_start_date in date,
                                   p_role_id                in number,
                                   p_role_code              in varchar2) is
-------------------------------------------------------------------------------

  lc_ctx  varchar2(500);
  lc_proc varchar2(100) := G_PACKAGE || '.assign_role_to_resource';

  ln_role_relate_id  number;

  cursor c_role (c_resource_id number,
                 c_role_id     number) is
    --
    -- No more than 1 record should exist but just in case more than
    -- one record would be fetched, use the most recently created one.
    --
    select role_relate_id,
           object_version_number,
           start_date_active,
           end_date_active
      from jtf_rs_role_relations
    where role_resource_id   = c_resource_id
      and role_id            = c_role_id
      and role_resource_type = 'RS_INDIVIDUAL'
      and delete_flag        = 'N'
    order by creation_date desc, role_relate_id desc; 

  rec c_role%rowtype;

begin

  lc_ctx := 'open c_role - p_resource_id=' || p_resource_id || ' p_role_id=' || p_role_id;
  open c_role (p_resource_id, p_role_id);

  lc_ctx := 'fetch c_role - p_resource_id=' || p_resource_id || ' p_role_id=' || p_role_id;
  fetch c_role into rec;

  if (c_role%notfound) then
    rec.role_relate_id := null;
  end if;

  lc_ctx := 'close c_role - p_resource_id=' || p_resource_id || ' p_role_id=' || p_role_id;
  close c_role;

  if (rec.role_relate_id is not null) then
    --
    -- We found a record with this role.  Verify it is active on or before the start date requested.
    --
    if (p_role_assign_start_date between rec.start_date_active
                                     and nvl(rec.end_date_active, p_role_assign_start_date+1)) then
      null;  -- the role has been assigned to the individual on or before the start date requested.

    else
      --
      -- Update the start date that the role is available to this individual.
      --
      lock_row (x_role_relate_id        => rec.role_relate_id,
                x_object_version_number => rec.object_version_number);

      update_row (x_role_relate_id        => rec.role_relate_id,
                  x_start_date_active     => p_resource_start_date,
                  x_end_date_active       => null,
                  x_object_version_number => rec.object_version_number);
    end if;

  else -- role not assigned to this user.  Assign it here.

    create_role_relate_rec (p_role_resource_type => 'RS_INDIVIDUAL',
                            p_role_resource_id   => p_resource_id,
                            p_role_id            => p_role_id,
                            p_role_code          => p_role_code,
                            p_start_date_active  => p_resource_start_date,
                            p_end_date_active    => null,
                            p_role_relate_id     => ln_role_relate_id);
  end if;
end assign_role_to_resource;
-- ============================================================================


-------------------------------------------------------------------------------
procedure lock_row (x_role_relate_id        in number,
                    x_object_version_number in number) is
-------------------------------------------------------------------------------

  lc_ctx  varchar2(500);
  lc_proc varchar2(100) := G_PACKAGE || '.lock_row';

  cursor c1 is
    select object_version_number
      from jtf_rs_role_relations
     where role_relate_id = x_role_relate_id
       for update of role_relate_id NOWAIT;

  rec c1%ROWTYPE;

begin
  lc_ctx := 'OPEN c1';
  OPEN c1;

  lc_ctx := 'fetch c1';
  fetch c1 into rec;

  if (c1%notfound) then
    lc_ctx := 'close c1(1)';
    close c1;
    fnd_message.set_name('FND', 'FORM_RECORD_DELETED');
    app_exception.raise_exception;
  end if;

  lc_ctx := 'close c1(2)';
  close c1;

  lc_ctx := 'compare values';
  if (rec.object_version_number = x_object_version_number) then
    null;

  else
    fnd_message.set_name('FND', 'FORM_RECORD_CHANGED');
    app_exception.raise_exception;
  end if;
end lock_row;
-- ============================================================================


-------------------------------------------------------------------------------
procedure insert_row (x_resource_id           in  number,
                      x_resource_start_date   in  date,
                      x_group_id              in  number,
                      x_role_resource_type    in  varchar2,
                      x_role_id               in  number,
                      x_role_code             in  varchar2,
                      x_start_date_active     in  date,
                      x_end_date_active       in  date,
                      x_role_relate_id        out number,
                      x_object_version_number out number) is
-------------------------------------------------------------------------------

  lc_ctx  varchar2(500);
  lc_proc varchar2(100) := G_PACKAGE || '.insert_row';

  ln_group_member_id    number;

  lc_return_status      varchar2(1);
  ln_msg_count          number;
  lc_msg_data           varchar2(2000);

  lc_one_msg            varchar2(1000);
  lc_msg                varchar2(2000);

  cursor c_grp_member (c_group_id    number,
                       c_resource_id number) is
    --
    -- No more than 1 record should exist but just in case more than
    -- one record would be fetched, use the most recently created one.
    --
    select group_member_id
      from jtf_rs_group_members
     where group_id    = x_group_id
       and resource_id = x_resource_id
       and delete_flag = 'N'
     order by creation_date desc, group_member_id desc;

begin
  assign_role_to_resource (p_resource_id            => x_resource_id,
                           p_resource_start_date    => x_resource_start_date,
                           p_role_assign_start_date => x_start_date_active,
                           p_role_id                => x_role_id,
                           p_role_code              => x_role_code);

  lc_ctx := 'open c_grp_member - x_group_id=' || x_group_id || ' x_resource_id=' || x_resource_id;
  open c_grp_member (x_group_id, x_resource_id);

  lc_ctx := 'fetch c_grp_member - x_group_id=' || x_group_id || ' x_resource_id=' || x_resource_id;
  fetch c_grp_member into ln_group_member_id;

  if (c_grp_member%notfound) then
    ln_group_member_id := null;
  end if;

  lc_ctx := 'close c_grp_member - x_group_id=' || x_group_id || ' x_resource_id=' || x_resource_id;
  close c_grp_member;

  if (ln_group_member_id is null) then
    --
    -- Need to add this resource as a group member.
    --
    lc_ctx := 'jtf_rs_grp_membership_pub.create_group_membership - x_resource_id=' || x_resource_id ||
              ' x_group_id=' || x_group_id ||
              ' x_role_id='   || x_role_id;

    --
    -- create_group_membership also calls create_resource_role_relate so we
    -- dont need to call it below after creating the group membership record.
    --
    jtf_rs_grp_membership_pub.create_group_membership
           (p_api_version   => 1.0,
            p_init_msg_list => fnd_api.G_TRUE,
            p_commit        => fnd_api.G_FALSE,
            p_resource_id   => x_resource_id,
            p_group_id      => x_group_id,
            p_role_id       => x_role_id,
            p_start_date    => least(x_start_date_active,trunc(sysdate)),
            p_end_date      => null,
            x_return_status => lc_return_status,
            x_msg_count     => ln_msg_count,
            x_msg_data      => lc_msg_data);

    if (lc_return_status = fnd_api.G_RET_STS_SUCCESS) then
      --
      -- Get the group_member_id and role_relate_id just created.  It isn't returned by the above API.
      --
      begin
        select grpm.group_member_id,
               rrel.role_relate_id
          into ln_group_member_id,
               x_role_relate_id
          from jtf_rs_group_members  grpm,
               jtf_rs_role_relations rrel
         where grpm.group_member_id    = rrel.role_resource_id
           and rrel.role_resource_type = 'RS_GROUP_MEMBER'     
           and grpm.delete_flag        = 'N'
           and rrel.delete_flag        = 'N'
           and grpm.group_id           = x_group_id
           and grpm.resource_id        = x_resource_id;

      exception
        when others then
          fnd_message.set_name('XXCRM', 'XX_CRM_0091_API_ERROR_UNKNOWN');
          fnd_message.set_token('DETAILS', 'Internal error getting group_member_id after ' ||
                                ' jtf_rs_grp_membership_pub.create_group_membership.  Error=' || SQLERRM);
          app_exception.raise_exception; 
      end;

    else
      for i in 1..ln_msg_count loop
        lc_one_msg := fnd_msg_pub.Get (p_encoded   => fnd_api.G_FALSE,
                                       p_msg_index => i);

        if (i = 1) then
          lc_msg := substr('CREATE_GROUP_MEMBERSHIP: ' || lc_one_msg, 1, 2000);
        else
          lc_msg := substr(lc_msg || LF || lc_one_msg,1,2000);
        end if;
      end loop;

      fnd_message.set_name('XXCRM', 'XX_CRM_0090_API_ERROR'); 
      fnd_message.set_token('API_ERROR', lc_msg); 
      app_exception.raise_exception; 
    end if;

  else
    create_role_relate_rec (p_role_resource_type => x_role_resource_type,
                            p_role_resource_id   => ln_group_member_id,
                            p_role_id            => x_role_id,
                            p_role_code          => x_role_code,
                            p_start_date_active  => x_start_date_active,
                            p_end_date_active    => x_end_date_active,
                            p_role_relate_id     => x_role_relate_id);
  end if;

  --
  -- Return the current object_version_number so the form record has the updated info.
  --
  select object_version_number
    into x_object_version_number
    from jtf_rs_role_relations
   where role_relate_id = x_role_relate_id;
end insert_row;
-- ============================================================================


-------------------------------------------------------------------------------
procedure update_row (x_role_relate_id        in number,
                      x_start_date_active     in date,
                      x_end_date_active       in date,
                      x_object_version_number in out number) is
-------------------------------------------------------------------------------

  lc_ctx  varchar2(500);
  lc_proc varchar2(100) := G_PACKAGE || '.update_row';

  lc_return_status      varchar2(1);
  ln_msg_count          number;
  lc_msg_data           varchar2(2000);

  lc_one_msg            varchar2(1000);
  lc_msg                varchar2(2000);

  ln_orig_obj_ver_num   number;

begin
  ln_orig_obj_ver_num := x_object_version_number;

  lc_ctx := 'jtf_rs_role_relate_pub.update_resource_role_relate - x_role_relate_id=' || x_role_relate_id ||
            ' x_object_version_number=' || x_object_version_number;

  jtf_rs_role_relate_pub.update_resource_role_relate
         (p_api_version        => 1.0,
          p_init_msg_list      => fnd_api.G_TRUE,
          p_commit             => fnd_api.G_FALSE,
          p_role_relate_id     => x_role_relate_id,
          p_start_date_active  => x_start_date_active,
          p_end_date_active    => x_end_date_active,
          p_object_version_num => x_object_version_number,
          x_return_status      => lc_return_status,
          x_msg_count          => ln_msg_count,
          x_msg_data           => lc_msg_data);

  if (lc_return_status = fnd_api.G_RET_STS_SUCCESS) then
    --
    -- The API will report success if data validations pass but x_role_relate_id has an invalid value.
    -- If the x_object_version_number has the same value upon exit that it had upon entry, the update
    -- statement didn't work.
    --
    if (ln_orig_obj_ver_num = x_object_version_number) then
      fnd_message.set_name('XXCRM', 'XX_CRM_0091_API_ERROR_UNKNOWN');
      fnd_message.set_token('DETAILS', 'x_object_version_number should have incremented but before API = ' ||
                            ln_orig_obj_ver_num || ';  after API = ' || x_object_version_number); 
      app_exception.raise_exception; 
    end if;

  else
    for i in 1..ln_msg_count loop
      lc_one_msg := fnd_msg_pub.Get (p_encoded   => fnd_api.G_FALSE,
                                     p_msg_index => i);

      if (i = 1) then
        lc_msg := substr(lc_one_msg, 1, 2000);
      else
        lc_msg := substr(lc_msg || LF || lc_one_msg,1,2000);
      end if;
    end loop;

    fnd_message.set_name('XXCRM', 'XX_CRM_0090_API_ERROR'); 
    fnd_message.set_token('API_ERROR', lc_msg); 
    app_exception.raise_exception; 
  end if;
end update_row;
-- ============================================================================


-------------------------------------------------------------------------------
procedure delete_row (x_role_relate_id        in number,
                      x_object_version_number in number) is
-------------------------------------------------------------------------------

  lc_ctx  varchar2(500);
  lc_proc varchar2(100) := G_PACKAGE || '.delete_row';

  lc_return_status      varchar2(1);
  ln_msg_count          number;
  lc_msg_data           varchar2(2000);

  lc_one_msg            varchar2(1000);
  lc_msg                varchar2(2000);

  ln_orig_obj_ver_num   number;

begin

  ln_orig_obj_ver_num := x_object_version_number;

  lc_ctx := 'jtf_rs_role_relate_pub.delete_resource_role_relate - x_role_relate_id=' || x_role_relate_id ||
            ' x_object_version_number=' || x_object_version_number;

  --
  -- The API delete_resource_role_relate doesn't actually delete the jtf_rs_role_relations record.
  -- Instead, it updates the record and sets the delete_flag = "Y".
  --
  -- Note the the object_version_numer is an input only parameter to the API so it isn't incremented
  -- after the delete operation.  In addition, object_version_number is not updated in
  -- jtf_rs_role_relations as a result of this delete operation.
  --
  jtf_rs_role_relate_pub.delete_resource_role_relate
         (p_api_version        => 1.0,
          p_init_msg_list      => fnd_api.G_TRUE,
          p_commit             => fnd_api.G_FALSE,
          p_role_relate_id     => x_role_relate_id,
          p_object_version_num => x_object_version_number,
          x_return_status      => lc_return_status,
          x_msg_count          => ln_msg_count,
          x_msg_data           => lc_msg_data);

  if (lc_return_status != fnd_api.G_RET_STS_SUCCESS) then
    for i in 1..ln_msg_count loop
      lc_one_msg := fnd_msg_pub.Get (p_encoded   => fnd_api.G_FALSE,
                                     p_msg_index => i);

      if (i = 1) then
        lc_msg := substr(lc_one_msg, 1, 2000);
      else
        lc_msg := substr(lc_msg || LF || lc_one_msg,1,2000);
      end if;
    end loop;

    fnd_message.set_name('XXCRM', 'XX_CRM_0090_API_ERROR'); 
    fnd_message.set_token('API_ERROR', lc_msg); 
    app_exception.raise_exception; 
  end if;
end delete_row;
-- ============================================================================

end XX_JTF_PROXY_ASSIGNMENTS_PKG;
/
show err
