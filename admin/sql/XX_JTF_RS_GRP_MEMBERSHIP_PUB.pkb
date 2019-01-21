SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY xx_jtf_rs_grp_membership_pub AS

  /*****************************************************************************************
   ******************************************************************************************/

  /* Package variables. */

  G_PKG_NAME         VARCHAR2(30) := 'XX_JTF_RS_GRP_MEMBERSHIP_PUB';



PROCEDURE create_group_membership
 (P_API_VERSION           IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_RESOURCE_ID          IN   NUMBER,
   P_GROUP_ID             IN   NUMBER,
   P_ROLE_ID              IN   NUMBER,
   P_START_DATE           IN   DATE,
   P_END_DATE             IN   DATE DEFAULT NULL,
  -- Added on 25/02/08 for Bonus date at Group membership role level(CR for Bonus Date):Start
   P_ATTRIBUTE1           IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE1%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE2           IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE2%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE3           IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE3%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE4           IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE4%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE5           IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE5%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE6           IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE6%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE7           IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE7%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE8           IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE8%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE9           IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE9%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE10          IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE10%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE11          IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE11%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE12          IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE12%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE13          IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE13%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE14          IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE14%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE15          IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE15%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE_CATEGORY   IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE_CATEGORY%TYPE   DEFAULT  NULL,
   -- Added on 25/02/08 for Bonus date at Group membership role level(CR for Bonus Date):End   
   X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY  NUMBER,
   X_MSG_DATA             OUT NOCOPY  VARCHAR2
  ) IS

    l_api_version         constant number := 1.0;
    l_api_name            constant varchar2(30) := 'CREATE_GROUP_MEMBERSHIP';
    l_return_status       varchar2(100) := fnd_api.g_ret_sts_success;
    l_msg_count           number;
    l_msg_data            varchar2(2000);

    /* Out Parameters  for Create Role Relation*/

    l_role_relate_id         number;
    l_role_relate_id_old     number;
    l_object_version_number  number;
    l_object_version_number_old  number;
    l_start_date_active      date;
    l_end_date_active        date;
    l_resource_start_date    date;
    l_resource_end_date      date;
    l_resource_name          varchar2(240);
    l_group_name             varchar2(240);

    /* Out Parameters  for Create Group Member*/

    l_group_member_id     number;

    /* Cursor  Variables to get role realtions */

    cursor chk_role_relate(l_role_id number, l_resource_id number)
    is
    select   role_relate_id,start_date_active,end_date_active,object_version_number
    from     jtf_rs_role_relations
    where    role_id = l_role_id
    and      role_resource_id = l_resource_id
    and      role_resource_type = 'RS_INDIVIDUAL'
    and      nvl(delete_flag, 'N') <> 'Y'
    order by start_date_active desc;

    cursor get_resource_dates(l_resource_id number)
    is
    select   start_date_active,
             end_date_active,
             resource_name
    from     jtf_rs_resource_extns_vl
    where    resource_id = l_resource_id;

    cursor get_group_name(l_group_id number)
    is
    select   group_name
    from     jtf_rs_groups_vl
    where    group_id = l_group_id;

    /* Cursor  Variables to check group member exists or not */

    cursor check_group_member_exists(l_group_id number, l_resource_id number)
    is
    select   group_member_id
    from     jtf_rs_group_members
    where    group_id = l_group_id
    and      resource_id = l_resource_id
    and      nvl(delete_flag, 'N') <> 'Y';

    cursor role_type_dtl(l_role_id number)
    is
    select   trunc(lkp.start_date_active),
             trunc(lkp.end_date_active)
    from     fnd_lookups lkp, jtf_rs_roles_b rol
    where    rol.role_id = l_role_id
    and      lkp.lookup_type = 'JTF_RS_ROLE_TYPE'
    and      lkp.lookup_code = rol.role_type_code;

    l_role_type_start_date  date;
    l_role_type_end_date    date;
    l_new_role_start_date   date;
    l_new_role_end_date     date;

BEGIN
    x_return_status := fnd_api.g_ret_sts_success;

    savepoint cr_grp_memship;

 --Initialize the message List   if P_INIT_MSG_LIST is set to TRUE
    if fnd_api.tO_BOOLEAN(p_init_msg_list)
    then
       fnd_msg_pub.Initialize;
    end if;

    open get_resource_dates(p_resource_id);
    fetch get_resource_dates
    into  l_resource_start_date,
          l_resource_end_date,
          l_resource_name;
    close get_resource_dates;

    if (p_role_id is not null) then

       open role_type_dtl(p_role_id);
       fetch role_type_dtl
       into  l_role_type_start_date,
             l_role_type_end_date;
       close role_type_dtl;

    open chk_role_relate(p_role_id,p_resource_id);
    fetch chk_role_relate
    into  l_role_relate_id,
          l_start_date_active,
          l_end_date_active,
          l_object_version_number;
    if chk_role_relate%NOTFOUND
    then
--dbms_output.put_line(' resource id = ' || to_char(p_resource_id));
--dbms_output.put_line(' role id = ' || to_char(p_role_id));
       /* Calling the role relate api's to create resource role relation */

       if ( l_role_type_end_date is NULL OR
             ( trunc(l_role_type_end_date) >= trunc(l_resource_start_date))) then

          l_new_role_start_date := greatest(l_resource_start_date, l_role_type_start_date);

          if  (l_resource_end_date is NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          elsif (l_resource_end_date is NULL and l_role_type_end_date is NOT NULL) then
             l_new_role_end_date := l_role_type_end_date;
          elsif (l_resource_end_date is NOT NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          else
             l_new_role_end_date := least(l_resource_end_date, l_role_type_end_date);
          end if;
       else
          l_new_role_start_date := l_resource_start_date;
          l_new_role_end_date := l_resource_end_date;
       end if;

       jtf_rs_role_relate_pub.create_resource_role_relate
                   (p_api_version          => 1.0
                   ,p_init_msg_list        => fnd_api.g_false
                   ,p_commit               => fnd_api.g_false
                   ,p_role_resource_type   => 'RS_INDIVIDUAL'
                   ,p_role_resource_id     => p_resource_id
                   ,p_role_id              => p_role_id
                   ,p_role_code            => null
                   ,p_start_date_active    => l_new_role_start_date
                   ,p_end_date_active      => l_new_role_end_date
                   ,x_return_status        => l_return_status
                   ,x_msg_count            => l_msg_count
                   ,x_msg_data             => l_msg_data
                   ,x_role_relate_id       => l_role_relate_id
                   );
      if not (l_return_status = fnd_api.g_ret_sts_success) THEN
         raise fnd_api.g_exc_unexpected_error;
      end if;

    else

    if (p_start_date >= l_start_date_active) and (p_start_date <= nvl(l_end_date_active,p_start_date))
    then
       if ((p_end_date > l_end_date_active) or p_end_date is NULL) and (l_end_date_active is NOT NULL)
       then
--          dbms_output.put_line('update the role end date with ' ||to_char(l_resource_end_date));

          l_new_role_start_date := l_start_date_active;

          if  (l_resource_end_date is NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          elsif (l_resource_end_date is NULL and l_role_type_end_date is NOT NULL) then
             l_new_role_end_date := l_role_type_end_date;
          elsif (l_resource_end_date is NOT NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          else
             l_new_role_end_date := least(l_resource_end_date, l_role_type_end_date);
          end if;

          jtf_rs_role_relate_pvt.update_resource_role_relate
                (P_API_VERSION          => 1.0,
                 P_INIT_MSG_LIST        => fnd_api.g_false,
                 P_COMMIT               => fnd_api.g_false,
                 P_ROLE_RELATE_ID       => l_role_relate_id,
                 P_START_DATE_ACTIVE    => l_new_role_start_date,
                 P_END_DATE_ACTIVE      => l_new_role_end_date,
                 P_OBJECT_VERSION_NUM   => l_object_version_number,
                 X_RETURN_STATUS        => l_return_status,
                 X_MSG_COUNT            => l_msg_count,
                 X_MSG_DATA             => l_msg_data);
          if not (l_return_status = fnd_api.g_ret_sts_success) THEN
              raise fnd_api.g_exc_unexpected_error;
          end if;
       else
--          dbms_output.put_line('no need to update the role');
       null;
       end if;
    elsif (p_start_date >= l_start_date_active)
    then
--          dbms_output.put_line('update the role end date with ' ||to_char(l_resource_end_date));

          l_new_role_start_date := l_start_date_active;

          if  (l_resource_end_date is NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          elsif (l_resource_end_date is NULL and l_role_type_end_date is NOT NULL) then
             l_new_role_end_date := l_role_type_end_date;
          elsif (l_resource_end_date is NOT NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          else
             l_new_role_end_date := least(l_resource_end_date, l_role_type_end_date);
          end if;

          jtf_rs_role_relate_pvt.update_resource_role_relate
                (P_API_VERSION          => 1.0,
                 P_INIT_MSG_LIST        => fnd_api.g_false,
                 P_COMMIT               => fnd_api.g_false,
                 P_ROLE_RELATE_ID       => l_role_relate_id,
                 P_START_DATE_ACTIVE    => l_new_role_start_date,
                 P_END_DATE_ACTIVE      => l_new_role_end_date,
                 P_OBJECT_VERSION_NUM   => l_object_version_number,
                 X_RETURN_STATUS        => l_return_status,
                 X_MSG_COUNT            => l_msg_count,
                 X_MSG_DATA             => l_msg_data);
          if not (l_return_status = fnd_api.g_ret_sts_success) THEN
              raise fnd_api.g_exc_unexpected_error;
          end if;
    elsif (p_start_date < l_start_date_active)
    then
       fetch chk_role_relate into l_role_relate_id_old,l_start_date_active,l_end_date_active,l_object_version_number_old;
       if chk_role_relate%NOTFOUND
       then
           l_start_date_active := l_resource_start_date;
       else
           l_start_date_active := l_end_date_active+1;
       end if;
--       dbms_output.put_line('update role start date with'|| to_char(l_end_date_active+1) || ' the role end date with'||to_char(l_resource_end_date));

          if ( l_role_type_end_date is NULL OR
                ( trunc(l_role_type_end_date) >= trunc(l_start_date_active))) then

             l_new_role_start_date := greatest(l_start_date_active, l_role_type_start_date);

             if  (l_resource_end_date is NULL and l_role_type_end_date is NULL) then
                l_new_role_end_date := l_resource_end_date;
             elsif (l_resource_end_date is NULL and l_role_type_end_date is NOT NULL) then
                l_new_role_end_date := l_role_type_end_date;
             elsif (l_resource_end_date is NOT NULL and l_role_type_end_date is NULL) then
                l_new_role_end_date := l_resource_end_date;
             else
                l_new_role_end_date := least(l_resource_end_date, l_role_type_end_date);
             end if;
          else
             l_new_role_start_date := l_start_date_active;
             l_new_role_end_date := l_resource_end_date;
          end if;

          jtf_rs_role_relate_pvt.update_resource_role_relate
                (P_API_VERSION          => 1.0,
                 P_INIT_MSG_LIST        => fnd_api.g_false,
                 P_COMMIT               => fnd_api.g_false,
                 P_ROLE_RELATE_ID       => l_role_relate_id,
                 P_START_DATE_ACTIVE    => l_new_role_start_date,
                 P_END_DATE_ACTIVE      => l_new_role_end_date,
                 P_OBJECT_VERSION_NUM   => l_object_version_number,
                 X_RETURN_STATUS        => l_return_status,
                 X_MSG_COUNT            => l_msg_count,
                 X_MSG_DATA             => l_msg_data);
          if not (l_return_status = fnd_api.g_ret_sts_success) THEN
              raise fnd_api.g_exc_unexpected_error;
          end if;

    end if;

    end if;

    close chk_role_relate;
    end if;
--dbms_output.put_line(' resource role_relate id = ' || to_char(l_role_relate_id));

    open  check_group_member_exists(p_group_id, p_resource_id);
    fetch check_group_member_exists
    into  l_group_member_id;
    if check_group_member_exists%NOTFOUND
    then

        jtf_rs_group_members_pub.create_resource_group_members
                   (p_api_version          => 1.0
                   ,p_init_msg_list        => fnd_api.g_false
                   ,p_commit               => fnd_api.g_false
                   ,p_group_id             => p_group_id
                   ,p_group_number         => null
                   ,p_resource_id          => p_resource_id
                   ,p_resource_number      => null
                   ,x_return_status        => l_return_status
                   ,x_msg_count            => l_msg_count
                   ,x_msg_data             => l_msg_data
                   ,x_group_member_id      => l_group_member_id
                  );

        if not (l_return_status = fnd_api.g_ret_sts_success) THEN
           raise fnd_api.g_exc_unexpected_error;
        end if;
     else
         if (p_role_id is null) then
            open get_group_name(p_group_id);
            fetch get_group_name
            into  l_group_name;
            close get_group_name;

--   hk_debug_proc(l_resource_name ||' is already a member of '||l_group_name);

            fnd_message.set_name('JTF', 'JTF_RS_RESOURCE_EXISTS_GROUP');
            fnd_message.set_token('P_RESOURCE',l_resource_name);
            fnd_message.set_token('P_GROUP',l_group_name);
            fnd_msg_pub.add;
            RAISE fnd_api.g_exc_unexpected_error;

         end if;
     end if;
--dbms_output.put_line('group_member_id id = ' || to_char(l_group_member_id));

       /* Calling the role relate api's to create resource role relation */
    if (p_role_id is not null) then
    /*
     Commented on 22/02/08 for Bonus date at Group membership role level(CR for Bonus Date)
    jtf_rs_role_relate_pub.create_resource_role_relate
                  (p_api_version          => 1.0
                  ,p_init_msg_list        => fnd_api.g_false
                  ,p_commit               => fnd_api.g_false
                  ,p_role_resource_type   => 'RS_GROUP_MEMBER'
                  ,p_role_resource_id     => l_group_member_id
                  ,p_role_id              => p_role_id
                  ,p_role_code            => null
                  ,p_start_date_active    => p_start_date
                  ,p_end_date_active      => p_end_date
                  ,x_return_status        => l_return_status
                  ,x_msg_count            => l_msg_count
                  ,x_msg_data             => l_msg_data
                  ,x_role_relate_id       => l_role_relate_id
                  );
     Commented on 22/02/08 for Bonus date at Group membership role level(CR for Bonus Date)
     */
     --Added on 25/02/08 for Bonus date at Group membership role level(CR for Bonus Date)
     XX_JTF_RS_ROLE_RELATE_PUB.Create_Resource_Role_Relate
                  (p_api_version          => 1.0
                  ,p_init_msg_list        => fnd_api.g_false
                  ,p_commit               => fnd_api.g_false
                  ,p_role_resource_type   => 'RS_GROUP_MEMBER'
                  ,p_role_resource_id     => l_group_member_id
                  ,p_role_id              => p_role_id
                  ,p_role_code            => null
                  ,p_start_date_active    => p_start_date
                  ,p_end_date_active      => p_end_date
                  ,p_attribute1           => p_attribute1        
                  ,p_attribute2           => p_attribute2        
                  ,p_attribute3           => p_attribute3        
                  ,p_attribute4           => p_attribute4        
                  ,p_attribute5           => p_attribute5        
                  ,p_attribute6           => p_attribute6        
                  ,p_attribute7           => p_attribute7        
                  ,p_attribute8           => p_attribute8        
                  ,p_attribute9           => p_attribute9        
                  ,p_attribute10          => p_attribute10       
                  ,p_attribute11          => p_attribute11       
                  ,p_attribute12          => p_attribute12       
                  ,p_attribute13          => p_attribute13       
                  ,p_attribute14          => p_attribute14       
                  ,p_attribute15          => p_attribute15       
                  ,p_attribute_category   => p_attribute_category                            
                  ,x_return_status        => l_return_status
                  ,x_msg_count            => l_msg_count
                  ,x_msg_data             => l_msg_data
                  ,x_role_relate_id       => l_role_relate_id
                  );     
    --Added on 25/02/08 for Bonus date at Group membership role level(CR for Bonus Date)
    
    if not (l_return_status = fnd_api.g_ret_sts_success) THEN
       raise fnd_api.g_exc_unexpected_error;
    end if;
    end if;

--dbms_output.put_line(' group role_relate id = ' || to_char(l_role_relate_id));

    if fnd_api.to_boolean(p_commit)
    then
       commit work;
    end if;

 fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);

 exception
    when fnd_api.g_exc_unexpected_error
    then
      rollback to cr_grp_memship;
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);
    WHEN fnd_api.g_exc_error
    THEN
      ROLLBACK TO cr_grp_memship;
      x_return_status := fnd_api.g_ret_sts_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count, p_data => x_msg_data);
    when others
    then
      rollback to cr_grp_memship;
      fnd_message.set_name ('JTF', 'JTF_RS_UNEXP_ERROR');
      fnd_message.set_token('P_SQLCODE',SQLCODE);
      fnd_message.set_token('P_SQLERRM',SQLERRM);
      fnd_message.set_token('P_API_NAME',l_api_name);
      FND_MSG_PUB.add;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);

END create_group_membership;

PROCEDURE update_group_membership
 (P_API_VERSION           IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_RESOURCE_ID          IN   NUMBER,
   P_ROLE_ID              IN   NUMBER,
   P_ROLE_RELATE_ID       IN   NUMBER,
   P_START_DATE           IN   DATE DEFAULT  FND_API.G_MISS_DATE,
   P_END_DATE             IN   DATE DEFAULT  FND_API.G_MISS_DATE,
   P_OBJECT_VERSION_NUM   IN   NUMBER,
   X_RETURN_STATUS        OUT NOCOPY VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY NUMBER,
   X_MSG_DATA             OUT NOCOPY VARCHAR2
  ) IS

    l_api_version         constant number := 1.0;
    l_api_name            constant varchar2(30) := 'UPDATE_GROUP_MEMBERSHIP';
    l_return_status       varchar2(100) := fnd_api.g_ret_sts_success;
    l_msg_count           number;
    l_msg_data            varchar2(2000);
    l_object_version_num  number := p_object_version_num;

    /* Out Parameters  for Create Role Relation*/

    l_role_relate_id         number;
    l_role_relate_id_old     number;
    l_object_version_number  number;
    l_object_version_number_old  number;
    l_start_date_active      date;
    l_end_date_active        date;
    l_resource_start_date    date;
    l_resource_end_date      date;

    /* Cursor  Variables to get role realtions */

    cursor chk_role_relate(l_role_id number, l_resource_id number)
    is
    select   role_relate_id,start_date_active,end_date_active,object_version_number
    from     jtf_rs_role_relations
    where    role_id = l_role_id
    and      role_resource_id = l_resource_id
    and      role_resource_type = 'RS_INDIVIDUAL'
    and      nvl(delete_flag, 'N') <> 'Y'
    order by start_date_active desc;

    cursor get_resource_dates(l_resource_id number)
    is
    select   start_date_active,
             end_date_active
    from     jtf_rs_resource_extns
    where    resource_id = l_resource_id;

    cursor role_type_dtl(l_role_id number)
    is
    select   trunc(lkp.start_date_active),
             trunc(lkp.end_date_active)
    from     fnd_lookups lkp, jtf_rs_roles_b rol
    where    rol.role_id = l_role_id
    and      lkp.lookup_type = 'JTF_RS_ROLE_TYPE'
    and      lkp.lookup_code = rol.role_type_code;

    l_role_type_start_date  date;
    l_role_type_end_date    date;
    l_new_role_start_date   date;
    l_new_role_end_date     date;

BEGIN
    x_return_status := fnd_api.g_ret_sts_success;

    savepoint upd_grp_memship;

 --Initialize the message List   if P_INIT_MSG_LIST is set to TRUE
    if fnd_api.tO_BOOLEAN(p_init_msg_list)
    then
       fnd_msg_pub.Initialize;
    end if;

    open get_resource_dates(p_resource_id);
    fetch get_resource_dates
    into  l_resource_start_date,
          l_resource_end_date;
    close get_resource_dates;

    open role_type_dtl(p_role_id);
    fetch role_type_dtl
    into  l_role_type_start_date,
          l_role_type_end_date;
    close role_type_dtl;

    open chk_role_relate(p_role_id,p_resource_id);
    fetch chk_role_relate
    into  l_role_relate_id,
          l_start_date_active,
          l_end_date_active,
          l_object_version_number;

    if (p_start_date >= l_start_date_active) and (p_start_date <= nvl(l_end_date_active,p_start_date))
    then
       if (p_end_date > l_end_date_active) and (l_end_date_active is NOT NULL)
       then
--          dbms_output.put_line('update the role end date with ' ||to_char(l_resource_end_date));

          l_new_role_start_date := l_start_date_active;

          if  (l_resource_end_date is NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          elsif (l_resource_end_date is NULL and l_role_type_end_date is NOT NULL) then
             l_new_role_end_date := l_role_type_end_date;
          elsif (l_resource_end_date is NOT NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          else
             l_new_role_end_date := least(l_resource_end_date, l_role_type_end_date);
          end if;

          jtf_rs_role_relate_pub.update_resource_role_relate
                (P_API_VERSION          => 1.0,
                 P_INIT_MSG_LIST        => fnd_api.g_false,
                 P_COMMIT               => fnd_api.g_false,
                 P_ROLE_RELATE_ID       => l_role_relate_id,
                 P_START_DATE_ACTIVE    => l_new_role_start_date,
                 P_END_DATE_ACTIVE      => l_new_role_end_date,
                 P_OBJECT_VERSION_NUM   => l_object_version_number,
                 X_RETURN_STATUS        => l_return_status,
                 X_MSG_COUNT            => l_msg_count,
                 X_MSG_DATA             => l_msg_data);
          if not (l_return_status = fnd_api.g_ret_sts_success) THEN
              raise fnd_api.g_exc_unexpected_error;
          end if;
       else
--          dbms_output.put_line('no need to update the role');
       null;
       end if;
    elsif (p_start_date >= l_start_date_active)
    then
--          dbms_output.put_line('update the role end date with ' ||to_char(l_resource_end_date));

          l_new_role_start_date := l_start_date_active;

          if  (l_resource_end_date is NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          elsif (l_resource_end_date is NULL and l_role_type_end_date is NOT NULL) then
             l_new_role_end_date := l_role_type_end_date;
          elsif (l_resource_end_date is NOT NULL and l_role_type_end_date is NULL) then
             l_new_role_end_date := l_resource_end_date;
          else
             l_new_role_end_date := least(l_resource_end_date, l_role_type_end_date);
          end if;

          jtf_rs_role_relate_pub.update_resource_role_relate
                (P_API_VERSION          => 1.0,
                 P_INIT_MSG_LIST        => fnd_api.g_false,
                 P_COMMIT               => fnd_api.g_false,
                 P_ROLE_RELATE_ID       => l_role_relate_id,
                 P_START_DATE_ACTIVE    => l_new_role_start_date,
                 P_END_DATE_ACTIVE      => l_new_role_end_date,
                 P_OBJECT_VERSION_NUM   => l_object_version_number,
                 X_RETURN_STATUS        => l_return_status,
                 X_MSG_COUNT            => l_msg_count,
                 X_MSG_DATA             => l_msg_data);
          if not (l_return_status = fnd_api.g_ret_sts_success) THEN
              raise fnd_api.g_exc_unexpected_error;
          end if;
    elsif (p_start_date < l_start_date_active)
    then
       fetch chk_role_relate into l_role_relate_id_old,l_start_date_active,l_end_date_active,l_object_version_number_old;
       if chk_role_relate%NOTFOUND
       then
           l_start_date_active := l_resource_start_date;
       else
           l_start_date_active := l_end_date_active+1;
       end if;
--       dbms_output.put_line('update role start date with'|| to_char(l_end_date_active+1) || ' the role end date with'||to_char(l_resource_end_date));

          if ( l_role_type_end_date is NULL OR
                ( trunc(l_role_type_end_date) >= trunc(l_start_date_active))) then

             l_new_role_start_date := greatest(l_start_date_active, l_role_type_start_date);

             if  (l_resource_end_date is NULL and l_role_type_end_date is NULL) then
                l_new_role_end_date := l_resource_end_date;
             elsif (l_resource_end_date is NULL and l_role_type_end_date is NOT NULL) then
                l_new_role_end_date := l_role_type_end_date;
             elsif (l_resource_end_date is NOT NULL and l_role_type_end_date is NULL) then
                l_new_role_end_date := l_resource_end_date;
             else
                l_new_role_end_date := least(l_resource_end_date, l_role_type_end_date);
             end if;
          else
             l_new_role_start_date := l_start_date_active;
             l_new_role_end_date := l_resource_end_date;
          end if;

          jtf_rs_role_relate_pub.update_resource_role_relate
                (P_API_VERSION          => 1.0,
                 P_INIT_MSG_LIST        => fnd_api.g_false,
                 P_COMMIT               => fnd_api.g_false,
                 P_ROLE_RELATE_ID       => l_role_relate_id,
                 P_START_DATE_ACTIVE    => l_new_role_start_date,
                 P_END_DATE_ACTIVE      => l_new_role_end_date,
                 P_OBJECT_VERSION_NUM   => l_object_version_number,
                 X_RETURN_STATUS        => l_return_status,
                 X_MSG_COUNT            => l_msg_count,
                 X_MSG_DATA             => l_msg_data);
          if not (l_return_status = fnd_api.g_ret_sts_success) THEN
              raise fnd_api.g_exc_unexpected_error;
          end if;

    end if;

    close chk_role_relate;

--dbms_output.put_line(' resource role_relate id = ' || to_char(l_role_relate_id));

       /* Calling the role relate api's to create resource role relation */

    jtf_rs_role_relate_pub.update_resource_role_relate
                  (p_api_version          => 1.0
                  ,p_init_msg_list        => fnd_api.g_false
                  ,p_commit               => fnd_api.g_false
                  ,p_role_relate_id       => p_role_relate_id
                  ,p_start_date_active    => p_start_date
                  ,p_end_date_active      => p_end_date
                  ,p_object_version_num   => l_object_version_num
                  ,x_return_status        => l_return_status
                  ,x_msg_count            => l_msg_count
                  ,x_msg_data             => l_msg_data
                  );

    if not (l_return_status = fnd_api.g_ret_sts_success) THEN
       raise fnd_api.g_exc_unexpected_error;
    end if;

--dbms_output.put_line(' group role_relate id = ' || to_char(l_role_relate_id));

    if fnd_api.to_boolean(p_commit)
    then
       commit work;
    end if;

 fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);

 exception
    when fnd_api.g_exc_unexpected_error
    then
      rollback to upd_grp_memship;
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);
    WHEN fnd_api.g_exc_error
    THEN
      ROLLBACK TO upd_grp_memship;
      x_return_status := fnd_api.g_ret_sts_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count, p_data => x_msg_data);
    when others
    then
      rollback to upd_grp_memship;
      fnd_message.set_name ('JTF', 'JTF_RS_UNEXP_ERROR');
      fnd_message.set_token('P_SQLCODE',SQLCODE);
      fnd_message.set_token('P_SQLERRM',SQLERRM);
      fnd_message.set_token('P_API_NAME',l_api_name);
      FND_MSG_PUB.add;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);

END update_group_membership;

PROCEDURE delete_group_membership
 (P_API_VERSION           IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_GROUP_ID             IN   NUMBER,
   P_RESOURCE_ID          IN   NUMBER,
   P_GROUP_MEMBER_ID      IN   NUMBER,
   P_ROLE_RELATE_ID       IN   NUMBER,
   P_OBJECT_VERSION_NUM   IN   NUMBER,
   X_RETURN_STATUS        OUT NOCOPY VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY NUMBER,
   X_MSG_DATA             OUT NOCOPY VARCHAR2
  ) IS

    l_api_version         constant number := 1.0;
    l_api_name            constant varchar2(30) := 'DELETE_GROUP_MEMBERSHIP';
    l_return_status       varchar2(100) := fnd_api.g_ret_sts_success;
    l_msg_count           number;
    l_msg_data            varchar2(2000);

    /* Cursor  Variables to check group member has to be deleted or not */

    cursor group_member_exists(l_group_member_id number)
    is
    select   role_relate_id
    from     jtf_rs_role_relations
    where    role_resource_id = l_group_member_id
    and      role_resource_type = 'RS_GROUP_MEMBER'
    and      nvl(delete_flag, 'N') <> 'Y';

    l_role_relete_id  jtf_rs_role_relations.role_relate_id%type;

    /* Cursor  Variables to get object_version_number for group member */

    cursor get_obj_ver_num(l_group_member_id number)
    is
    select   object_version_number
    from     jtf_rs_group_members
    where    group_member_id = l_group_member_id;

    l_object_version_num  jtf_rs_role_relations.object_version_number%type;

BEGIN

    x_return_status := fnd_api.g_ret_sts_success;

    savepoint del_grp_memship;

  --Initialize the message List   if P_INIT_MSG_LIST is set to TRUE

    if fnd_api.tO_BOOLEAN(p_init_msg_list)
    then
       fnd_msg_pub.Initialize;
    end if;

    if (p_role_relate_id is not null) then
         jtf_rs_role_relate_pub.delete_resource_role_relate
               (P_API_VERSION          => 1.0,
                P_INIT_MSG_LIST        => fnd_api.g_false,
                P_COMMIT               => fnd_api.g_false,
                P_ROLE_RELATE_ID       => p_role_relate_id,
                P_OBJECT_VERSION_NUM   => p_object_version_num,
                X_RETURN_STATUS        => l_return_status,
                X_MSG_COUNT            => l_msg_count,
                X_MSG_DATA             => l_msg_data);
         if not (l_return_status = fnd_api.g_ret_sts_success) THEN
             raise fnd_api.g_exc_unexpected_error;
         end if;
    else
--        open group_member_exists(p_group_member_id);
--        fetch group_member_exists
--        into  l_role_relete_id;
--        if group_member_exists%NOTFOUND
--        then

           open get_obj_ver_num(p_group_member_id);
           fetch get_obj_ver_num
           into  l_object_version_num;
           close get_obj_ver_num;

           jtf_rs_group_members_pub.delete_resource_group_members
               (P_API_VERSION          => 1.0,
                P_INIT_MSG_LIST        => fnd_api.g_false,
                P_COMMIT               => fnd_api.g_false,
                P_GROUP_ID             => p_group_id,
                P_GROUP_NUMBER         => null,
                P_RESOURCE_ID          => p_resource_id,
                P_RESOURCE_NUMBER      => null,
                P_OBJECT_VERSION_NUM   => l_object_version_num,
                X_RETURN_STATUS        => l_return_status,
                X_MSG_COUNT            => l_msg_count,
                X_MSG_DATA             => l_msg_data);

           if not (l_return_status = fnd_api.g_ret_sts_success) THEN
              raise fnd_api.g_exc_unexpected_error;
           end if;
--        end if;
--        close group_member_exists;
    end if;

     if fnd_api.to_boolean(p_commit)
     then
       commit work;
     end if;

    fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);

    exception
       when fnd_api.g_exc_unexpected_error
       then
         rollback to del_grp_memship;
         x_return_status := fnd_api.g_ret_sts_error;
         fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);
       WHEN fnd_api.g_exc_error
       THEN
         ROLLBACK TO del_grp_memship;
         x_return_status := fnd_api.g_ret_sts_error;
         FND_MSG_PUB.count_and_get (p_count => x_msg_count, p_data => x_msg_data);
       when others
       then
         rollback to del_grp_memship;
         fnd_message.set_name ('JTF', 'JTF_RS_UNEXP_ERROR');
         fnd_message.set_token('P_SQLCODE',SQLCODE);
         fnd_message.set_token('P_SQLERRM',SQLERRM);
         fnd_message.set_token('P_API_NAME',l_api_name);
         FND_MSG_PUB.add;
         x_return_status := fnd_api.g_ret_sts_unexp_error;
         fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);

END delete_group_membership;

END xx_jtf_rs_grp_membership_pub;
/

SHOW ERRORS;

EXIT