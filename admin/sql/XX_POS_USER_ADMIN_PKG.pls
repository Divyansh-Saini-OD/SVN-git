REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.27.12000000.2=120.29)(115.17=120.0):~PROD:~PATH:~FILE 

/*+=======================================================================+
--|               Copyright (c) 1998, 2014 Oracle Corporation                   |
--|                       Redwood Shores, CA, USA                         |
--|                         All rights reserved.                          |
--+=======================================================================+
--| FILENAME                                                              |
--|     POSADMB.pls                                                       |
--|                                                                       |
--| DESCRIPTION                                                           |
--|     Handles the supplier user in r12                                  |
--|                                                                       |
--+======================================================================*/

SET VERIFY OFF

WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE or REPLACE PACKAGE BODY pos_user_admin_pkg as
/*$Header: POSADMB.pls 120.30.12010000.12 2014/07/24 09:26:04 ppotnuru ship $ */ 

g_module CONSTANT VARCHAR2(30) := 'POS_USER_ADMIN_PKG';

procedure reset_password
  ( p_user_id           IN  NUMBER
  , x_return_status     OUT NOCOPY VARCHAR2
  , x_msg_count         OUT NOCOPY NUMBER
  , x_msg_data          OUT NOCOPY VARCHAR2
  )
IS
   l_process              wf_process_activities.process_name%TYPE;
   l_itemkey              wf_items.item_key%TYPE;
   l_itemtype             wf_items.item_type%TYPE;

   l_unencrypted_password VARCHAR2(30);
   l_enterprise_name      VARCHAR2(240);
   l_resetpass            BOOLEAN;

   CURSOR fnd_user_cur IS
      SELECT * FROM fnd_user WHERE user_id = p_user_id;

   l_fnd_user_rec fnd_user_cur%ROWTYPE;

BEGIN
   OPEN fnd_user_cur;
   FETCH fnd_user_cur INTO l_fnd_user_rec;

   IF ( fnd_user_cur%notfound) THEN
      CLOSE fnd_user_cur;
      raise_application_error(-20001,'POSADMB: reset_password: Invalid user_id');

    ELSE
      CLOSE fnd_user_cur;
   END IF;

   l_process  := 'POS_BPR_RESET_PASS';
   l_itemtype := 'POSBPR';
   l_itemkey  := to_char(p_user_id) || ':' || to_char(sysdate,'RRDDDSSSSS');

   l_unencrypted_password := POS_PASSWORD_UTIL_PKG.generate_user_pwd();
   l_resetpass := FND_USER_PKG.ChangePassword(l_fnd_user_rec.user_name, l_unencrypted_password);

   fnd_user_pkg.updateuser
     ( x_user_name                 => l_fnd_user_rec.user_name,
       x_owner                      => NULL,
       x_end_date                   => l_fnd_user_rec.end_date,
       x_password_date              => fnd_user_pkg.null_date,
       x_password_accesses_left     => l_fnd_user_rec.password_accesses_left,
       x_password_lifespan_accesses => l_fnd_user_rec.password_lifespan_accesses,
       x_password_lifespan_days     => l_fnd_user_rec.password_lifespan_days,
       x_email_address              => l_fnd_user_rec.email_address,
       x_fax                        => l_fnd_user_rec.fax,
       x_customer_id                => l_fnd_user_rec.customer_id
       );

   pos_enterprise_util_pkg.get_enterprise_party_name
     (l_enterprise_name,
      x_msg_data,
      x_return_status
      );

   IF x_msg_data IS NOT NULL THEN
      x_msg_count := 1;
   END IF;

   pos_log.log_call_result
     (p_module        => 'POSADMB',
      p_prefix        => 'call fnd_user_pkg.update_user',
      p_return_status => x_return_status,
      p_msg_count     => x_msg_count,
      p_msg_data      => x_msg_data
      );

   IF x_return_status IS NULL OR x_return_status <> fnd_api.g_ret_sts_success THEN
      RETURN;
   END IF;

   -- Send the email to user about the new password
   wf_engine.CreateProcess(itemtype => l_itemtype,
                           itemkey  => l_itemkey,
                           process  => l_process);

   wf_engine.SetItemAttrText (itemtype   => l_itemtype,
                              itemkey    => l_itemkey,
                              aname      => 'USERNAME',
                              avalue     => l_fnd_user_rec.user_name);

   wf_engine.SetItemAttrText (itemtype   => l_itemtype,
                              itemkey    => l_itemkey,
                              aname      => 'ENTERPRISE_NAME',
                              avalue     => l_enterprise_name);

   wf_engine.SetItemAttrText (itemtype   => l_itemtype,
                              itemkey    => l_itemkey,
                               aname      => 'PASSWORD',
                              avalue     => l_unencrypted_password);

   wf_engine.StartProcess(itemtype => l_itemtype,
                          itemkey  => l_itemkey);

   x_return_status := fnd_api.g_ret_sts_success;

EXCEPTION
   WHEN OTHERS THEN
      pos_log.log_sqlerrm('POSADMB', 'in reset_password');
      RAISE;
END reset_password;

PROCEDURE set_user_inactive_date
  ( p_user_id            IN NUMBER
  , p_inactive_date      IN DATE
  , x_return_status     OUT NOCOPY VARCHAR2
  , x_msg_count         OUT NOCOPY NUMBER
  , x_msg_data          OUT NOCOPY VARCHAR2
   )
  IS
     CURSOR fnd_user_cur IS
	SELECT user_name FROM fnd_user WHERE user_id = p_user_id;

     l_fnd_user_rec fnd_user_cur%ROWTYPE;
     l_end_date DATE;
     l_start_date DATE;
     l_old_inactive_date date;
BEGIN
   OPEN fnd_user_cur;
   FETCH fnd_user_cur INTO l_fnd_user_rec;

   IF ( fnd_user_cur%notfound) THEN
      CLOSE fnd_user_cur;
      raise_application_error(-20001,'POSADMB: end_date_user_account: Invalid user_id');

    ELSE
      CLOSE fnd_user_cur;
   END IF;

   if p_inactive_date is null then
    select start_date, end_date
    into l_start_date,l_old_inactive_date
    from fnd_user
    where user_name = l_fnd_user_rec.user_name;

    if (l_old_inactive_date is not null) then
        fnd_user_pkg.enableuser(username => l_fnd_user_rec.user_name,
        start_date => l_start_date);
    end if;
   else
    l_end_date := p_inactive_date;
   fnd_user_pkg.updateuser
     ( x_user_name  => l_fnd_user_rec.user_name,
       x_owner      => NULL,
       x_end_date   => l_end_date
       );
   end if;


   x_return_status := fnd_api.g_ret_sts_success;

EXCEPTION
   WHEN OTHERS THEN
      pos_log.log_sqlerrm('POSADMB', 'in reset_password');
      RAISE;
END set_user_inactive_date;

procedure grant_user_resp
  ( p_user_id           IN  NUMBER
  , p_resp_id           IN  NUMBER
  , p_resp_app_id       IN  NUMBER
  , x_return_status     OUT NOCOPY VARCHAR2
  , x_msg_count         OUT NOCOPY NUMBER
  , x_msg_data          OUT NOCOPY VARCHAR2
  )
IS
BEGIN
   x_return_status := fnd_api.g_ret_sts_success;
   fnd_user_resp_groups_api.upload_assignment
     ( user_id                       => p_user_id,
       responsibility_id             => p_resp_id,
       responsibility_application_id => p_resp_app_id,
       security_group_id             => 0,
       start_date                    => Sysdate,
       end_date                      => NULL,
       description                   => 'POS User Profile'
       );

   x_return_status := fnd_api.g_ret_sts_success;

EXCEPTION
   WHEN OTHERS THEN
      pos_log.log_sqlerrm
        ('POSADMB',
         'in grant_user_resp: p_user_id = ' || p_user_id
         || ' p_resp_id = ' || p_resp_id
         || ' p_resp_app_id = ' || p_resp_app_id
         );
      RAISE;
END grant_user_resp;

procedure grant_user_resp
  ( p_user_id           IN NUMBER
  , p_resp_key          IN VARCHAR2
  , p_resp_app_id       IN NUMBER
  , x_return_status     OUT NOCOPY VARCHAR2
  , x_msg_count         OUT NOCOPY NUMBER
  , x_msg_data          OUT NOCOPY VARCHAR2
  ) IS
     l_resp_id NUMBER;
BEGIN
   x_return_status := fnd_api.g_ret_sts_success;
   SELECT responsibility_id INTO l_resp_id
     FROM fnd_responsibility
    WHERE responsibility_key = p_resp_key
      AND application_id = p_resp_app_id;

   grant_user_resp
     (p_user_id       => p_user_id,
      p_resp_id       => l_resp_id,
      p_resp_app_id   => p_resp_app_id,
      x_return_status => x_return_status,
      x_msg_count     => x_msg_count,
      x_msg_data      => x_msg_data
      );

END grant_user_resp;

procedure grant_user_resps
  ( p_user_id           IN  NUMBER
  , p_resp_ids          IN  po_tbl_number
  , p_resp_app_ids      IN  po_tbl_number
  , x_return_status     OUT NOCOPY VARCHAR2
  , x_msg_count         OUT NOCOPY NUMBER
  , x_msg_data          OUT NOCOPY VARCHAR2
    )
  IS
BEGIN
   SAVEPOINT grant_user_resps_sp;

   FOR i IN 1..p_resp_ids.COUNT LOOP
      grant_user_resp
        (p_user_id          => p_user_id,
         p_resp_id          => p_resp_ids(i),
         p_resp_app_id      => p_resp_app_ids(i),
         x_return_status    => x_return_status,
         x_msg_count        => x_msg_count,
         x_msg_data         => x_msg_data
         );
      IF x_return_status IS NULL
        OR x_return_status <> fnd_api.g_ret_sts_success THEN
         ROLLBACK TO grant_user_resps_sp;
         RETURN;
      END IF;
   END LOOP;

   x_return_status := fnd_api.g_ret_sts_success;

END grant_user_resps;

procedure revoke_user_resp
  ( p_user_id           IN NUMBER
  , p_resp_id           IN NUMBER
  , p_resp_app_id       IN NUMBER
  , x_return_status     OUT NOCOPY VARCHAR2
  , x_msg_count         OUT NOCOPY NUMBER
  , x_msg_data          OUT NOCOPY VARCHAR2
  )
  IS
     l_start_date DATE;
     CURSOR l_cur IS
        SELECT start_date FROM fnd_user_resp_groups_direct 
          WHERE user_id = p_user_id AND responsibility_id = p_resp_id
	      AND responsibility_application_id = p_resp_app_id; 
BEGIN
   OPEN l_cur;
   FETCH l_cur INTO l_start_date;
   IF l_cur%notfound THEN
      CLOSE l_cur;
      x_return_status := fnd_api.g_ret_sts_success;
      RETURN;
   END IF;
   fnd_user_resp_groups_api.upload_assignment
     ( user_id                       => p_user_id,
       responsibility_id             => p_resp_id,
       responsibility_application_id => p_resp_app_id,
       security_group_id             => 0,
       start_date                    => l_start_date,
       end_date                      => sysdate,
       description                   => 'POS User Profile'
       );
   x_return_status := fnd_api.g_ret_sts_success;

EXCEPTION
   WHEN OTHERS THEN
      pos_log.log_sqlerrm('POSADMB', 'in revoke_user_resp');
      RAISE;
END revoke_user_resp;

procedure revoke_user_resps
  ( p_user_id           IN  NUMBER
  , p_resp_ids          IN  po_tbl_number
  , p_resp_app_ids      IN  po_tbl_number
  , x_return_status     OUT NOCOPY VARCHAR2
  , x_msg_count         OUT NOCOPY NUMBER
  , x_msg_data          OUT NOCOPY VARCHAR2
    )
  IS
BEGIN
   SAVEPOINT revoke_user_resps_sp;

   FOR i IN 1..p_resp_ids.COUNT LOOP
      revoke_user_resp
        (p_user_id          => p_user_id,
         p_resp_id          => p_resp_ids(i),
         p_resp_app_id      => p_resp_app_ids(i),
         x_return_status    => x_return_status,
         x_msg_count        => x_msg_count,
         x_msg_data         => x_msg_data
         );
      IF x_return_status IS NULL
        OR x_return_status <> fnd_api.g_ret_sts_success THEN
         ROLLBACK TO revoke_user_resps_sp;
         RETURN;
      END IF;
   END LOOP;

   x_return_status := fnd_api.g_ret_sts_success;

END revoke_user_resps;

procedure update_user_info
  ( p_party_id          IN  NUMBER
  , p_user_name_prefix  IN  VARCHAR2
  , p_user_name_f       IN  VARCHAR2
  , p_user_name_m       IN  VARCHAR2
  , p_user_name_l       IN  VARCHAR2
  , p_user_title        IN  VARCHAR2
  , p_user_email        IN  VARCHAR2
  , p_user_phone        IN  VARCHAR2
  , p_user_extension    IN  VARCHAR2
  , p_user_fax          IN  VARCHAR2
  , x_return_status     OUT NOCOPY VARCHAR2
  , x_msg_count         OUT NOCOPY NUMBER
  , x_msg_data          OUT NOCOPY VARCHAR2
  )
IS
  l_person_rec            hz_party_v2pub.person_rec_type;
  l_profile_id            NUMBER;

  CURSOR l_user_cur IS
     SELECT user_name
       FROM fnd_user
       WHERE person_party_id = p_party_id;

  CURSOR l_party_cur IS
     SELECT object_version_number, last_update_date
       FROM hz_parties
      WHERE party_id = p_party_id;

  l_party_rec l_party_cur%ROWTYPE;

  l_return_status VARCHAR2(1);
  l_msg_count     NUMBER;
  l_msg_data      VARCHAR2(3000);
BEGIN
   OPEN l_party_cur;
   FETCH l_party_cur INTO l_party_rec;
   IF l_party_cur%notfound THEN
      CLOSE l_party_cur;
      x_return_status := fnd_api.g_ret_sts_error;
      x_msg_count := 1;
      x_msg_data := 'invalid party id ' || p_party_id;
      RETURN;
   END IF;
   CLOSE l_party_cur;

   IF l_party_rec.object_version_number IS NULL THEN
      l_party_rec.object_version_number := 0;
   END IF;

    --call TCA API's
   --fnd_client_info.set_org_context('-3113');

   l_person_rec.person_pre_name_adjunct := p_user_name_prefix;
   l_person_rec.person_first_name       := p_user_name_f;
   l_person_rec.person_middle_name      := p_user_name_m;
   l_person_rec.person_last_name        := p_user_name_l;
   l_person_rec.person_pre_name_adjunct := p_user_title;
   l_person_rec.party_rec.party_id      := p_party_id;

   UPDATE hz_person_profiles
     SET effective_start_date=trunc(SYSDATE)
     WHERE party_id = p_party_id;

   hz_party_v2pub.update_person
     ( p_person_rec                  => l_person_rec,
       p_party_object_version_number => l_party_rec.object_version_number,
       x_profile_id                  => l_profile_id,
       x_return_status               => x_return_status,
       x_msg_count                   => x_msg_count,
       x_msg_data                    => x_msg_data
       );

   pos_log.log_call_result
     (p_module        => 'POSADMB',
      p_prefix        => 'call hz_party_v2pub.update_person.update_person',
      p_return_status => x_return_status,
      p_msg_count     => x_msg_count,
      p_msg_data      => x_msg_data
      );

   IF x_return_status IS NULL OR x_return_status <> fnd_api.g_ret_sts_success THEN
      RETURN;
   END IF;

   pos_hz_contact_point_pkg.update_party_phone
     ( p_party_id          => p_party_id,
       p_country_code      => NULL,
       p_area_code         => NULL,
       p_number            => p_user_phone,
       p_extension         => p_user_extension,
       x_return_status     => x_return_status,
       x_msg_count         => x_msg_count,
       x_msg_data          => x_msg_data
     );

   IF x_return_status IS NULL OR x_return_status <> fnd_api.g_ret_sts_success THEN
      RETURN;
   END IF;

   pos_hz_contact_point_pkg.update_party_fax
     ( p_party_id          => p_party_id,
       p_country_code      => NULL,
       p_area_code         => NULL,
       p_number            => p_user_fax,
       p_extension         => NULL,
       x_return_status     => x_return_status,
       x_msg_count         => x_msg_count,
       x_msg_data          => x_msg_data
     );

   IF x_return_status IS NULL OR x_return_status <> fnd_api.g_ret_sts_success THEN
      RETURN;
   END IF;

   IF p_user_email IS NOT NULL THEN
      pos_hz_contact_point_pkg.update_party_email
       ( p_party_id          => p_party_id,
         p_email             => p_user_email,
         x_return_status     => x_return_status,
         x_msg_count         => x_msg_count,
         x_msg_data          => x_msg_data
       );
  END IF;

  IF x_return_status IS NULL OR x_return_status <> fnd_api.g_ret_sts_success THEN
     RETURN;
  END IF;

   --set email address in fnd_user as well as TCA.

  FOR l_user_rec IN l_user_cur LOOP
     fnd_user_pkg.updateuser
       ( x_user_name     => l_user_rec.user_name,
         x_owner         => NULL,
         x_email_address => p_user_email,
         x_customer_id   => p_party_id
         );
  END LOOP;

  x_return_status := fnd_api.g_ret_sts_success;

EXCEPTION
    WHEN OTHERS THEN
       pos_log.log_sqlerrm('POSADMB', 'in update_user_info');
       raise_application_error(-20002,'POSADMB:UPDATE_USER_INFO: Caught an exception', true);
END update_user_info;

PROCEDURE createsecattr
  ( p_user_id        IN NUMBER
  , p_attribute_code IN VARCHAR2
  , p_app_id         IN NUMBER
  , p_varchar2_value IN VARCHAR2 DEFAULT NULL
  , p_date_value     IN DATE DEFAULT NULL
  , p_number_value   IN NUMBER DEFAULT NULL
  )
IS
   l_return_status VARCHAR2(1);
   l_msg_count     NUMBER;
   l_msg_data      VARCHAR2(2000);
BEGIN
   icx_user_sec_attr_pvt.create_user_sec_attr
     ( p_api_version_number => 1.0,
       p_return_status      => l_return_status,
       p_msg_count          => l_msg_count,
       p_msg_data           => l_msg_data,
       p_web_user_id        => p_user_id,
       p_attribute_code     => p_attribute_code,
       p_attribute_appl_id  => p_app_id,
       p_varchar2_value     => p_varchar2_value,
       p_date_value         => p_date_value,
       p_number_value       => p_number_value,
       p_created_by         => fnd_global.user_id,
       p_creation_date      => Sysdate,
       p_last_updated_by    => fnd_global.user_id,
       p_last_update_date   => Sysdate,
       p_last_update_login  => fnd_global.login_id
       );

   pos_log.log_call_result
     (p_module        => 'POSADMB',
      p_prefix        => 'call icx_user_sec_attr_pvt.create_user_sec_attr ',
      p_return_status => l_return_status,
      p_msg_count     => l_msg_count,
      p_msg_data      => l_msg_data
      );

   IF l_return_status IS NULL OR l_return_status <> fnd_api.g_ret_sts_success THEN
      IF l_msg_count > 0 THEN
         pos_log.combine_fnd_msg(l_msg_count, l_msg_data);
      END IF;

      raise_application_error(-20001
                              ,'POSADMB.createsecattr '
                              || ' return status ' || l_return_status
                              || ' msg count ' || l_msg_count
                              || ' msg data ' || l_msg_data
                              );
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      pos_log.log_sqlerrm('POSADMB','in createsecattr');
      RAISE;
END createsecattr;

PROCEDURE deletesecattr
  ( p_user_id        IN NUMBER
  , p_attribute_code IN VARCHAR2
  , p_app_id         IN NUMBER
  , p_varchar2_value IN VARCHAR2 DEFAULT NULL
  , p_date_value     IN DATE DEFAULT NULL
  , p_number_value   IN NUMBER DEFAULT NULL
  )
IS
   l_return_status VARCHAR2(1);
   l_msg_count     NUMBER;
   l_msg_data      VARCHAR2(2000);
BEGIN
   icx_user_sec_attr_pvt.delete_user_sec_attr
     ( p_api_version_number => 1.0,
       p_return_status      => l_return_status,
       p_msg_count          => l_msg_count,
       p_msg_data           => l_msg_data,
       p_web_user_id        => p_user_id,
       p_attribute_code     => p_attribute_code,
       p_attribute_appl_id  => p_app_id,
       p_varchar2_value     => p_varchar2_value,
       p_date_value         => p_date_value,
       p_number_value       => p_number_value
       );

   pos_log.log_call_result
     (p_module        => 'POSADMB',
      p_prefix        => 'call icx_user_sec_attr_pvt.delete_user_sec_attr ',
      p_return_status => l_return_status,
      p_msg_count     => l_msg_count,
      p_msg_data      => l_msg_data
      );

   IF l_return_status IS NULL OR l_return_status <> fnd_api.g_ret_sts_success THEN
      IF l_msg_count > 0 THEN
         pos_log.combine_fnd_msg(l_msg_count, l_msg_data);
      END IF;

      raise_application_error(-20001
                              ,'POSADMB.deletesecattr '
                              || ' return status ' || l_return_status
                              || ' msg count ' || l_msg_count
                              || ' msg data ' || l_msg_data
                              );
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      pos_log.log_sqlerrm('POSADMB','in deletesecattr');
      RAISE;
END deletesecattr;


-- The following are backward compatible versions of the
-- procedures above. The difference between these and their
-- corresponding versions above is that the error messages
-- are combined into one in the output parameter.
--
-- For new code, please use the new versions above

procedure grant_user_resp
  ( p_user_id           IN NUMBER
  , p_resp_id           IN NUMBER
  , p_resp_app_id       IN NUMBER
  , x_status            OUT NOCOPY VARCHAR2
  , x_exception_msg     OUT NOCOPY VARCHAR2
  )
IS
   l_return_status   VARCHAR2(1);
   l_msg_count       NUMBER;
   l_msg_data        VARCHAR2(3000);
BEGIN
   grant_user_resp
      (p_user_id            => p_user_id,
       p_resp_id            => p_resp_id,
       p_resp_app_id        => p_resp_app_id,
       x_return_status      => l_return_status,
       x_msg_count          => l_msg_count,
       x_msg_data           => l_msg_data
      );

   x_status := l_return_status;
   IF l_return_status = fnd_api.g_ret_sts_success THEN
      x_exception_msg := NULL;
   ELSE
      IF l_msg_count = 1 THEN
         x_exception_msg := l_msg_data;
      ELSE
         pos_log.combine_fnd_msg(l_msg_count, x_exception_msg);
      END IF;
  END IF;
END grant_user_resp;

procedure revoke_user_resp
  ( p_user_id           IN NUMBER
  , p_resp_id           IN NUMBER
  , p_resp_app_id       IN NUMBER
  , x_status            OUT NOCOPY VARCHAR2
  , x_exception_msg     OUT NOCOPY VARCHAR2
  )
IS
   l_return_status   VARCHAR2(1);
   l_msg_count       NUMBER;
   l_msg_data        VARCHAR2(3000);
BEGIN
   revoke_user_resp
      (p_user_id            => p_user_id,
       p_resp_id            => p_resp_id,
       p_resp_app_id        => p_resp_app_id,
       x_return_status      => l_return_status,
       x_msg_count          => l_msg_count,
       x_msg_data           => l_msg_data
      );

   x_status := l_return_status;
   IF l_return_status = fnd_api.g_ret_sts_success THEN
      x_exception_msg := NULL;
   ELSE
      IF l_msg_count = 1 THEN
         x_exception_msg := l_msg_data;
      ELSE
         pos_log.combine_fnd_msg(l_msg_count, x_exception_msg);
      END IF;
  END IF;
END revoke_user_resp;

procedure update_user_info
  ( p_party_id          IN  NUMBER
  , p_user_name_prefix  IN  VARCHAR2
  , p_user_name_f       IN  VARCHAR2
  , p_user_name_m       IN  VARCHAR2
  , p_user_name_l       IN  VARCHAR2
  , p_user_title        IN  VARCHAR2
  , p_user_email        IN  VARCHAR2
  , p_user_phone        IN  VARCHAR2
  , p_user_extension    IN  VARCHAR2
  , p_user_fax          IN  VARCHAR2
  , x_status            OUT NOCOPY VARCHAR2
  , x_exception_msg     OUT NOCOPY VARCHAR2
  )
IS
   l_return_status   VARCHAR2(1);
   l_msg_count       NUMBER;
   l_msg_data        VARCHAR2(3000);
BEGIN
   update_user_info
      (p_party_id           => p_party_id,
       p_user_name_prefix   => p_user_name_prefix,
       p_user_name_f        => p_user_name_f,
       p_user_name_m        => p_user_name_m,
       p_user_name_l        => p_user_name_l,
       p_user_title         => p_user_title,
       p_user_email         => p_user_email,
       p_user_phone         => p_user_phone,
       p_user_extension     => p_user_extension,
       p_user_fax           => p_user_fax,
       x_return_status      => l_return_status,
       x_msg_count          => l_msg_count,
       x_msg_data           => l_msg_data
      );

   x_status := l_return_status;
   IF l_return_status = fnd_api.g_ret_sts_success THEN
      x_exception_msg := NULL;
   ELSE
      IF l_msg_count = 1 THEN
         x_exception_msg := l_msg_data;
      ELSE
         pos_log.combine_fnd_msg(l_msg_count, x_exception_msg);
      END IF;
  END IF;
END update_user_info;

PROCEDURE create_supplier_user_account
  (p_user_name        IN  VARCHAR2,
   p_user_email       IN  VARCHAR2,
   p_person_party_id  IN  NUMBER,
   p_resp_ids         IN  po_tbl_number,
   p_resp_app_ids     IN  po_tbl_number,
   p_sec_attr_codes   IN  po_tbl_varchar30,
   p_sec_attr_numbers IN  po_tbl_number,
   p_password         IN  VARCHAR2 DEFAULT NULL,
   x_return_status    OUT NOCOPY VARCHAR2,
   x_msg_count        OUT NOCOPY NUMBER,
   x_msg_data         OUT NOCOPY VARCHAR2,
   x_user_id          OUT NOCOPY NUMBER,
   x_password         OUT NOCOPY VARCHAR2
   )
  IS
     l_unencrypted_password VARCHAR2(200);
     l_testname NUMBER;
	 vl_password_lifespan_days fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;
     l_password_lifespan_days NUMBER DEFAULT NULL;
     event_id Number;
      CURSOR l_party_cur IS
         SELECT party_type, status
           FROM hz_parties
          WHERE party_id = p_person_party_id;

      l_party_rec l_party_cur%ROWTYPE;

      l_count     INTEGER;

      CURSOR l_fnd_user_cur IS
         SELECT user_id
           FROM fnd_user
          WHERE user_name = p_user_name;

      l_fnd_user_rec l_fnd_user_cur%ROWTYPE;
BEGIN
   SAVEPOINT create_supp_user_account_sp;

   IF p_user_name IS NULL THEN
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_message.set_name('POS', 'POS_CRSUSER_USERNAME_NULL');
      fnd_msg_pub.ADD;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
      RETURN;
   END IF;

   OPEN l_fnd_user_cur;
   FETCH l_fnd_user_cur INTO l_fnd_user_rec;
   IF l_fnd_user_cur%found THEN
      CLOSE l_fnd_user_cur;
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_message.set_name('POS', 'POS_CRSUSER_USERNAME_EXISTS');
      fnd_message.set_token('USER_NAME', p_user_name);
      fnd_msg_pub.ADD;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
      RETURN;
   END IF;
   CLOSE l_fnd_user_cur;

   IF p_user_email IS NULL THEN
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_message.set_name('POS', 'POS_CRSUSER_EMAIL_NULL');
      fnd_msg_pub.ADD;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
      RETURN;
   END IF;

   IF p_person_party_id IS NULL THEN
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_message.set_name('POS', 'POS_CRSUSER_PERSON_PARTY_NULL');
      fnd_msg_pub.ADD;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
      RETURN;
   END IF;

   OPEN l_party_cur;
   FETCH l_party_cur INTO l_party_rec;
   IF l_party_cur%notfound THEN
      CLOSE l_party_cur;
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_message.set_name('POS', 'POS_CRSUSER_BAD_PERSON_PARTYID');
      fnd_message.set_token('PERSON_PARTY_ID', p_person_party_id);
      fnd_msg_pub.ADD;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
      RETURN;
   END IF;
   CLOSE l_party_cur;

   IF l_party_rec.status <> 'A' THEN
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_message.set_name('POS', 'POS_CRSUSER_PERSON_PARTY_INACT');
      fnd_message.set_token('PERSON_PARTY_ID', p_person_party_id);
      fnd_msg_pub.ADD;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
      RETURN;
   END IF;

   IF l_party_rec.party_type <> 'PERSON' THEN
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_message.set_name('POS', 'POS_CRSUSER_PARTY_NOT_PERSON');
      fnd_message.set_token('PERSON_PARTY_ID', p_person_party_id);
      fnd_msg_pub.ADD;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
      RETURN;
   END IF;

   IF p_password IS NULL THEN
      l_unencrypted_password := pos_password_util_pkg.generate_user_pwd();
    ELSE
      l_unencrypted_password := p_password;
   END IF;

   --sso integration, if user exists in oid
   --and synch is allowed, then no need to pass the password
   l_testname := FND_USER_PKG.TestUserName(p_user_name);
   IF (l_testname = FND_USER_PKG.USER_SYNCHED) THEN
     l_unencrypted_password := NULL;
   END IF;
   
   -- Bug: 14292251
   -- Fteching the profile value
   FND_PROFILE.GET('POS_SUPPLIER_USER_PASSWORD_EXP_DAYS',vl_password_lifespan_days);

   IF (vl_password_lifespan_days IS NOT NULL OR vl_password_lifespan_days<>'') THEN
      BEGIN
	  -- Converting fetched value to number
      l_password_lifespan_days := to_number(vl_password_lifespan_days);
      EXCEPTION
      WHEN VALUE_ERROR THEN
          --Throwing error if the conversion to number didn't happen due to invalid characters
		  --Only VALUE_ERROR can occur while conversion
		  x_return_status := fnd_api.g_ret_sts_error;
          fnd_message.set_name('POS', 'POS_SUPP_USER_PWD_EXP_ERROR');
          fnd_message.set_token('POS_PROFILE_OPTION_NAME', 'POS: Supplier User Account Password Expiration Days');
		  x_msg_data := fnd_message.get;
		  raise_application_error(-20001,x_msg_data,false);
          RETURN;
      END;
   END IF;

   x_user_id :=
     fnd_user_pkg.createuserid
     (x_user_name            => p_user_name,
      x_owner                => NULL,          -- created by current user
      x_unencrypted_password => l_unencrypted_password,
      x_description          => p_user_name,
      x_email_address        => p_user_email,
	  x_password_lifespan_days => l_password_lifespan_days
      );

   -- set the person_party_id column in fnd_user
   fnd_user_pkg.updateuserparty
    (x_user_name        => p_user_name,
     x_owner            => NULL,
     x_person_party_id  => p_person_party_id
     );

   x_password := l_unencrypted_password;

   -- set the user workflow mail preference to HTML
   fnd_preference.put(upper(p_user_name), 'WF', 'MAILTYPE', 'MAILHTML');

   l_count := p_resp_ids.COUNT;
   FOR l_index IN 1..l_count LOOP
      grant_user_resp
        ( p_user_id        => x_user_id,
          p_resp_id        => p_resp_ids(l_index),
          p_resp_app_id    => p_resp_app_ids(l_index),
          x_return_status  => x_return_status,
          x_msg_count      => x_msg_count,
          x_msg_data       => x_msg_data
          );
      IF x_return_status IS NULL OR
        x_return_status <> fnd_api.g_ret_sts_success THEN
         ROLLBACK TO create_supp_user_account_sp;
         RETURN;
      END IF;
   END LOOP;

   -- assign securing attribute values to the user
   l_count := p_sec_attr_codes.COUNT;
   FOR l_index IN 1..l_count LOOP
      createsecattr
        ( p_user_id        => x_user_id,
          p_attribute_code => p_sec_attr_codes(l_index),
          p_app_id         => 177,
          p_number_value   => p_sec_attr_numbers(l_index)
          );
   END LOOP;

   -- set profile options for external user
   -- Namely: APPS_SERVLET_AGENT, APPS_WEB_AGENT
   POS_SUPPLIER_USER_REG_PKG.set_profile_opt_ext_user(x_user_id);

   x_return_status := fnd_api.g_ret_sts_success;
    
/* Begin Supplier Hub - Supplier Data Publication */
      /* Raise Supplier User Creation event*/
     event_id:= pos_appr_rej_supp_event_raise.raise_appr_rej_supp_event('oracle.apps.pos.supplier.approvesupplieruser', p_person_party_id, x_user_id);
      
/* End Supplier Hub - Supplier Data Publication */

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK TO create_supp_user_account_sp;
      x_return_status := fnd_api.g_ret_sts_error;
      x_msg_count := 1;
      x_msg_data := Sqlerrm;
      pos_log.log_sqlerrm('POSADMB', 'in create_supplier_user_account');

END create_supplier_user_account;

-- code added for bug 7699191, to send the admin email id in supplier user notification mail
FUNCTION get_contact_email RETURN VARCHAR2
  IS
     CURSOR l_cur IS
        SELECT email_address
          FROM fnd_user
         WHERE user_id = fnd_global.user_id;

     l_email fnd_user.email_address%TYPE;
BEGIN
   OPEN l_cur;
   FETCH l_cur INTO l_email;
   CLOSE l_cur;
   RETURN l_email;
END get_contact_email;
-- code added for bug 7699191, to send the admin email id in supplier user notification mail

PROCEDURE create_supplier_user_ntf
  (p_user_name       IN  VARCHAR2,
   p_user_email      IN  VARCHAR2,
   p_person_party_id IN  NUMBER,
   p_password        IN  VARCHAR2 DEFAULT NULL,
   x_return_status   OUT NOCOPY VARCHAR2,
   x_msg_count       OUT NOCOPY NUMBER,
   x_msg_data        OUT NOCOPY VARCHAR2,
   x_user_id         OUT NOCOPY NUMBER,
   x_password        OUT NOCOPY VARCHAR2
   )
  IS
     l_resp_ids         po_tbl_number;
     l_resp_app_ids     po_tbl_number;
     l_sec_attr_codes   po_tbl_varchar30;
     l_sec_attr_numbers po_tbl_number;
     l_enterprise_name    hz_parties.party_name%TYPE;
     lv_exception_msg VARCHAR2(32000);
     lv_status        VARCHAR2(240);
     l_itemtype wf_items.item_type%TYPE;
     l_itemkey  wf_items.item_key%TYPE;
     l_process  wf_process_activities.process_name%TYPE;
     l_user_in_oid        VARCHAR2(1);

BEGIN
   l_resp_ids := po_tbl_number();
   l_resp_app_ids := po_tbl_number();
   l_sec_attr_codes := po_tbl_varchar30();
   l_sec_attr_numbers := po_tbl_number();

   /* Bug 5680160 Start */
   l_user_in_oid := 'N';
   if (FND_USER_PKG.TestUserName(p_user_name) = FND_USER_PKG.USER_SYNCHED) then
     l_user_in_oid := 'Y';
   end if;
   /* Bug 5680160 End */
   create_supplier_user_account
     (p_user_name        => p_user_name,
      p_user_email       => p_user_email,
      p_person_party_id  => p_person_party_id,
      p_resp_ids         => l_resp_ids,
      p_resp_app_ids     => l_resp_app_ids,
      p_sec_attr_codes   => l_sec_attr_codes,
      p_sec_attr_numbers => l_sec_attr_numbers,
      p_password         => p_password,
      x_return_status    => x_return_status,
      x_msg_count        => x_msg_count,
      x_msg_data         => x_msg_data,
      x_user_id          => x_user_id,
      x_password         => x_password
      );

   -- Send the email informing the supplier user
   -- with the username and password information.

   l_process := 'SEND_APPRV_REG_USER_NTF';
   /* Bug 5680160 Start */
   IF (l_user_in_oid = 'Y') THEN
        l_process := 'SEND_APPRV_USER_SSOSYNC_NTF';
   END IF;
   /* Bug 5680160 End */
   l_itemtype := 'POSREGV2';
   l_itemkey := Substr('POSREGV2_' || x_user_id || '_' || 'cntusr' || '_' ||
     fnd_crypto.smallrandomnumber(), 0, 240);

   wf_engine.CreateProcess(itemtype => l_itemtype,
                           itemkey  => l_itemkey,
                           process  => l_process
                           );

   wf_engine.SetItemAttrText (itemtype   => l_itemtype,
                              itemkey    => l_itemkey,
                              aname      => 'LOGON_PAGE_URL',
                              avalue     => pos_url_pkg.get_external_login_url
                              );

   wf_engine.SetItemAttrText (itemtype   => l_itemtype,
                              itemkey    => l_itemkey,
                              aname      => 'ASSIGNED_USER_NAME',
                              avalue     => Upper(p_user_name)
                              );

   wf_engine.SetItemAttrText (itemtype   => l_itemtype,
                              itemkey    => l_itemkey,
                              aname      => 'FIRST_LOGON_KEY',
                              avalue     => x_password
                              );

   wf_engine.SetItemAttrText (itemtype   => l_itemtype,
                              itemkey    => l_itemkey,
                              aname      => 'CONTACT_EMAIL',
                              avalue     => get_contact_email
                              );

   pos_enterprise_util_pkg.get_enterprise_party_name
     ( l_enterprise_name, lv_exception_msg, lv_status);

   wf_engine.SetItemAttrText (itemtype   => l_itemtype,
                              itemkey    => l_itemkey,
                              aname      => 'ENTERPRISE_NAME',
                              avalue     => l_enterprise_name
                              );

   -- Bug 8325979 - Following attributes have been replaced with FND Messages

   wf_engine.SetItemAttrText  (itemtype   => l_itemtype,
                             itemkey    => l_itemkey,
                             aname      => 'POS_APPRV_REG_USER_SUBJECT',
                             avalue     => GET_SUPP_USER_ACCNT_SUBJECT(l_enterprise_name));


   wf_engine.SetItemAttrText  (itemtype   => l_itemtype, itemkey    => l_itemkey,
                              aname      => 'POS_APPRV_REG_USER_BODY',
                              avalue     => 'PLSQLCLOB:pos_user_admin_pkg.GENERATE_SUPP_USER_ACCNT_BODY/'||l_itemtype ||':' ||l_itemkey
                             );


   wf_engine.StartProcess (itemtype => l_itemtype,
                           itemkey  => l_itemkey
                           );


END create_supplier_user_ntf;


PROCEDURE create_supplier_user_account
  (p_user_name       IN  VARCHAR2,
   p_user_email      IN  VARCHAR2,
   p_person_party_id IN  NUMBER,
   p_password        IN  VARCHAR2 DEFAULT NULL,
   x_return_status   OUT NOCOPY VARCHAR2,
   x_msg_count       OUT NOCOPY NUMBER,
   x_msg_data        OUT NOCOPY VARCHAR2,
   x_user_id         OUT NOCOPY NUMBER,
   x_password        OUT NOCOPY VARCHAR2
   )
  IS
     l_resp_ids         po_tbl_number;
     l_resp_app_ids     po_tbl_number;
     l_sec_attr_codes   po_tbl_varchar30;
     l_sec_attr_numbers po_tbl_number;
BEGIN
   l_resp_ids := po_tbl_number();
   l_resp_app_ids := po_tbl_number();
   l_sec_attr_codes := po_tbl_varchar30();
   l_sec_attr_numbers := po_tbl_number();

   create_supplier_user_account
     (p_user_name        => p_user_name,
      p_user_email       => p_user_email,
      p_person_party_id  => p_person_party_id,
      p_resp_ids         => l_resp_ids,
      p_resp_app_ids     => l_resp_app_ids,
      p_sec_attr_codes   => l_sec_attr_codes,
      p_sec_attr_numbers => l_sec_attr_numbers,
      p_password         => p_password,
      x_return_status    => x_return_status,
      x_msg_count        => x_msg_count,
      x_msg_data         => x_msg_data,
      x_user_id          => x_user_id,
      x_password         => x_password
      );

END create_supplier_user_account;

PROCEDURE assign_vendor_reg_def_resp
  (p_user_id         IN  NUMBER,
   p_vendor_id       IN  NUMBER,
   p_pon_def_also    IN  VARCHAR2,
   x_return_status   OUT NOCOPY VARCHAR2,
   x_msg_count       OUT NOCOPY NUMBER,
   x_msg_data        OUT NOCOPY VARCHAR2
   )
  IS
     l_resp_profile  fnd_profile_option_values.profile_option_value%TYPE;
     l_instr_index   NUMBER;
     l_resp_key      fnd_responsibility.responsibility_key%TYPE;
     l_resp_app_id   NUMBER;
     l_step          NUMBER;
BEGIN
   x_return_status := fnd_api.g_ret_sts_success;
   l_step := 1;
   fnd_profile.get('POS_DEFAULT_SUP_REG_RESP', l_resp_profile);

   IF l_resp_profile IS NOT NULL THEN
      l_instr_index := Instr(l_resp_profile, ':');
      l_resp_key := Substr(l_resp_profile, 0, l_instr_index - 1);
      l_resp_app_id := To_number(SUBSTR(l_resp_profile, l_instr_index + 1));

      grant_user_resp
	(p_user_id       => p_user_id,
	 p_resp_key      => l_resp_key,
	 p_resp_app_id   => l_resp_app_id,
	 x_return_status => x_return_status,
	 x_msg_count     => x_msg_count,
	 x_msg_data      => x_msg_data
	 );

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
	 RETURN;
      END IF;
   END IF;

   -- bug 5415703
   IF p_pon_def_also IS NOT NULL AND p_pon_def_also = 'Y' THEN

      l_step := 2;
      l_resp_profile := NULL;

      fnd_profile.get('PON_DEFAULT_EXT_USER_RESP', l_resp_profile);

      IF l_resp_profile IS NOT NULL THEN
	 l_resp_key := l_resp_profile;

	 SELECT application_id INTO l_resp_app_id
	   FROM fnd_application WHERE application_short_name = 'PON';

	 grant_user_resp
	   (p_user_id       => p_user_id,
	    p_resp_key      => l_resp_key,
	    p_resp_app_id   => l_resp_app_id,
	    x_return_status => x_return_status,
	    x_msg_count     => x_msg_count,
	    x_msg_data      => x_msg_data
	    );

	 IF x_return_status <> fnd_api.g_ret_sts_success THEN
	    RETURN;
	 END IF;
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_error;
      x_msg_count := 1;
      x_msg_data := Sqlerrm;
      pos_log.log_sqlerrm('POSADMB', 'in assign_vendor_reg_def_resp, step ' || l_step );

END assign_vendor_reg_def_resp;


/* Added following procedure for Business Classification Recertification ER
7489217 */
procedure add_certntf_subscription
  ( p_user_id           IN  NUMBER
  , x_status            OUT NOCOPY VARCHAR2
  , x_exception_msg     OUT NOCOPY VARCHAR2
  ) IS

 cursor c1 is
 select count(*)
 from pos_spmntf_subscription
 where user_id = p_user_id and
 event_type = 'SUPP_BUS_CLASS_RECERT_NTF';

 l_subscr_count  number;
BEGIN
-- Insert new record in the spm notification events table for the
-- business classification recert notifications


   x_status := fnd_api.g_ret_sts_success;
open c1;
fetch c1 into l_subscr_count;
close c1;

if (l_subscr_count = 0 ) then
 insert into pos_spmntf_subscription
 (subscription_id,
  created_by,
  creation_date,
  last_updated_by,
  last_update_date,
  last_update_login,
  event_type,
  user_id)
 values
 (POS_SPMNTF_SUBSCRIPTION_S.nextval,
  fnd_global.user_id,
  sysdate,
  fnd_global.user_id,
  sysdate,
  fnd_global.login_id,
  'SUPP_BUS_CLASS_RECERT_NTF',
  p_user_id);
 commit;
 x_status := fnd_api.g_ret_sts_success;

end if;
EXCEPTION
    WHEN OTHERS THEN
      x_status := fnd_api.g_ret_sts_error;
      x_exception_msg := 'Error creating notification subscription'||Sqlerrm;
       pos_log.log_sqlerrm('POSADMB', x_exception_msg);

END add_certntf_subscription;

procedure remove_certntf_subscription
  ( p_user_id           IN  NUMBER
  , x_status            OUT NOCOPY VARCHAR2
  , x_exception_msg     OUT NOCOPY VARCHAR2
  ) IS

 cursor c1 is
 select count(*)
 from pos_spmntf_subscription
 where user_id = p_user_id and
 event_type = 'SUPP_BUS_CLASS_RECERT_NTF';

 l_subscr_count  number := 0;


BEGIN
   x_status := fnd_api.g_ret_sts_success;

   open c1;
   fetch c1 into l_subscr_count;
   close c1;
--  Delete the Notification subscription record

   if (l_subscr_count > 0 ) then
    delete from pos_spmntf_subscription
    where event_type = 'SUPP_BUS_CLASS_RECERT_NTF'
      and user_id = p_user_id;
   commit;
   x_status := fnd_api.g_ret_sts_success;
  end if;
EXCEPTION
    WHEN OTHERS THEN
      x_status := fnd_api.g_ret_sts_error;
      x_exception_msg := 'Error removing notification subscription'||Sqlerrm;
       pos_log.log_sqlerrm('POSADMB', x_exception_msg);

END remove_certntf_subscription;

procedure get_certntf_subscription
  ( p_user_id           IN  NUMBER
  , x_subscr_exists     OUT NOCOPY VARCHAR2
  ) IS

BEGIN

    select 'Y'
    into x_subscr_exists
    from pos_spmntf_subscription
    where event_type = 'SUPP_BUS_CLASS_RECERT_NTF'
      and user_id = p_user_id;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
     x_subscr_exists := 'N';
END get_certntf_subscription;

-------------------------------------------------------------------------------
--Start of Comments
--Name: GET_SUPP_USER_ACCNT_SUBJECT
--Type:
--  Function
--Function:
--  It returns the tokens replaced FND message to Notification Message Subject
--Function Usage:
--  This function is used to replace the workflow message subject by FND Message & its tokens
--Logic Implemented:
-- The FND Message Name 'POS_APPRV_REG_USER_SUBJECT' will be replaced with
-- corresponding Message Text and tokens inside the Message Text also be replaced.
-- Then, replaced FND message will be return to the corresponding attribute
--Parameters:
--  Enterprise Name
--IN:
--  Enterprise Name
--OUT:
--  l_document
--Bug Number for reference:
--  8325979
--End of Comments
------------------------------------------------------------------------------

FUNCTION GET_SUPP_USER_ACCNT_SUBJECT(p_enterprise_name IN VARCHAR2)
RETURN VARCHAR2  IS
l_document VARCHAR2(32000);

BEGIN

        fnd_message.set_name('POS','POS_APPRV_REG_USER_SUBJECT');
        fnd_message.set_token('ENTERPRISE_NAME', p_enterprise_name);
        l_document :=  fnd_message.get;
  RETURN l_document;
END GET_SUPP_USER_ACCNT_SUBJECT;

-------------------------------------------------------------------------------
--Start of Comments
--Name: GENERATE_SUPP_USER_ACCNT_BODY
--Type:
--  Procedure
--Procedure:
--  It returns the tokens replaced FND message to Notification Message Body
--Procedure Usage:
--  It is being used to replace the workflow message Body by FND Message & its tokens
--Logic Implemented:
-- For HTML Body:
-- The FND Message Name 'POS_APPRV_REG_USER_HTML_BODY' will be replaced with
-- corresponding Message Text and tokens inside the Message Text also be replaced.
-- Then, replaced FND message will be return to the corresponding attribute
-- For TEXT Body:
-- The FND Message Name 'POS_APPRV_REG_USER_TEXT_BODY' will be replaced with
-- corresponding Message Text and tokens inside the Message Text also be replaced.
-- Then, replaced FND message will be return to the corresponding attribute
--Parameters:
--  document_id
--IN:
--  document_id
--OUT:
--  document
--Bug Number for reference:
--  8325979
--End of Comments
------------------------------------------------------------------------------

PROCEDURE GENERATE_SUPP_USER_ACCNT_BODY(p_document_id    IN VARCHAR2,
			               display_type  IN VARCHAR2,
			               document      IN OUT NOCOPY CLOB,
			               document_type IN OUT NOCOPY VARCHAR2)
IS

NL              VARCHAR2(1) := fnd_global.newline;
l_document      VARCHAR2(32000) := '';
l_note          VARCHAR2(32000) := '';
l_enterprisename VARCHAR2(1000) := '';
l_url           VARCHAR2(3000) := '';
l_email    VARCHAR2(1000) := '';
l_username      VARCHAR2(500) := '';
l_password      VARCHAR2(100) := '';
l_disp_type     VARCHAR2(20) := 'text/plain';
l_item_type wf_items.item_type%TYPE;
l_item_key  wf_items.item_key%TYPE;

BEGIN

  l_item_type := substr(p_document_id, 1, instr(p_document_id, ':') - 1);
  l_item_key := substr(p_document_id, instr(p_document_id, ':') + 1, length(p_document_id));

  l_enterprisename := wf_engine.GetItemAttrText (itemtype   => l_item_type,
                                         	itemkey    => l_item_key,
                                         	aname      => 'ENTERPRISE_NAME');
  l_url :=  wf_engine.GetItemAttrText (itemtype   => l_item_type,
                                         	itemkey    => l_item_key,
                                         	aname      => 'LOGON_PAGE_URL');
  l_username := wf_engine.GetItemAttrText (itemtype   => l_item_type,
                                         	itemkey    => l_item_key,
                                         	aname      => 'ASSIGNED_USER_NAME');
  l_password := wf_engine.GetItemAttrText (itemtype   => l_item_type,
                                         	itemkey    => l_item_key,
                                         	aname      => 'FIRST_LOGON_KEY');
  l_email := wf_engine.GetItemAttrText (itemtype   => l_item_type,
                                         	itemkey    => l_item_key,
                                         	aname      => 'CONTACT_EMAIL');
  l_note :='';

 IF display_type = 'text/html' THEN
      l_disp_type:= display_type;
        fnd_message.set_name('POS','POS_APPRV_REG_USER_HTML_BODY');
        fnd_message.set_token('ENTERPRISE_NAME',l_enterprisename);
        fnd_message.set_token('LOGON_PAGE_URL',l_url);
        fnd_message.set_token('ASSIGNED_USER_NAME',l_username);
        fnd_message.set_token('FIRST_LOGON_KEY',l_password);
        fnd_message.set_token('CONTACT_EMAIL',l_email);
        fnd_message.set_token('NOTE',l_note);
        l_document :=   l_document || NL || NL || fnd_message.get;
   	    WF_NOTIFICATION.WriteToClob(document, l_document);

  ELSE
        l_disp_type:= display_type;
        fnd_message.set_name('POS','POS_APPRV_REG_USER_TEXT_BODY');
        fnd_message.set_token('ENTERPRISE_NAME',l_enterprisename);
        fnd_message.set_token('LOGON_PAGE_URL',l_url);
        fnd_message.set_token('ASSIGNED_USER_NAME',l_username);
        fnd_message.set_token('FIRST_LOGON_KEY',l_password);
        fnd_message.set_token('CONTACT_EMAIL',l_email);
        fnd_message.set_token('NOTE',l_note);
        l_document :=   l_document || NL || NL || fnd_message.get;
   	    WF_NOTIFICATION.WriteToClob(document, l_document);

  END IF;

EXCEPTION
WHEN OTHERS THEN
    RAISE;
END GENERATE_SUPP_USER_ACCNT_BODY;

-------------------------------------------------------------------------------
--Start of Comments
--Name: send_mail_contact
--Type:
--  Procedure
--Procedure Usage:
--  It is being used to send mail to the contact that he will not have access to iSupplier page
--Logic Implemented:
-- :
-- The FND Message Name 'POS_SUPP_END_CONT_SUB' will be replaced with
-- corresponding Message Text and tokens inside the Message Text also be replaced.
-- Then, replaced FND message will be return to the corresponding attribute
-- For TEXT Body:
-- The FND Message Name 'POS_SUPP_END_CONT_BODY' will be replaced with
-- corresponding Message Text and tokens inside the Message Text also be replaced.
-- Then, replaced FND message will be return to the corresponding attribute
--Parameters:
--  p_user_id , p_result
--IN:
--  p_user_id
--OUT:
--  p_result
--Bug Number for reference:
--  17158302
--End of Comments
------------------------------------------------------------------------------

procedure send_mail_contact
  ( p_user_id           IN  NUMBER
  , p_end_date          IN DATE
  , p_result    IN OUT NOCOPY VARCHAR2
  ) IS
 l_notification_id NUMBER;
 wfItemType VARCHAR2(50) := 'POSNOTIF';
 l_enterprise_name      VARCHAR2(240);
 x_msg_data VARCHAR2(32000);
 x_return_status  VARCHAR2(240);
 l_adhoc_user  wf_users.name%TYPE;

  CURSOR fnd_user_cur IS
	SELECT user_name,email_address FROM fnd_user WHERE user_id = p_user_id;

     l_fnd_user_rec fnd_user_cur%ROWTYPE;

BEGIN
    OPEN fnd_user_cur;
   FETCH fnd_user_cur INTO l_fnd_user_rec;

   IF ( fnd_user_cur%notfound) THEN
      CLOSE fnd_user_cur;
      raise_application_error(-20001,'POSADMB: end_date_user_account: Invalid user_id');

    ELSE
      CLOSE fnd_user_cur;

   END IF;

    pos_enterprise_util_pkg.get_enterprise_party_name
     (l_enterprise_name,
      x_msg_data,
      x_return_status
      );
    l_adhoc_user := 'ADHOC_USER_' || l_fnd_user_rec.user_name || '_' ||
                      TO_CHAR(SYSDATE, 'MMDDYYYY_HH24MISS') ||
                      fnd_crypto.smallrandomnumber;

    wf_directory.createadhocuser
     ( name          =>  l_adhoc_user,
       display_name  => l_fnd_user_rec.user_name,
       email_address => l_fnd_user_rec.email_address
       );

    l_notification_id := wf_notification.send(role => l_adhoc_user,
                                                  msg_type => wfItemType,
                                                  msg_name => 'SUPPMESSAGE');

     fnd_message.set_name('POS','POS_SUPP_END_CONT_SUB');
     fnd_message.set_token('COMPANY',l_enterprise_name );
    -- Message subject
    wf_notification.Setattrtext(nid => l_notification_id,
                                      aname =>'#FROM_ROLE',
                                      avalue =>fnd_global.user_name);

     wf_notification.Setattrtext(nid => l_notification_id,
                                      aname =>'SUPPMSGSUB',
                                      avalue => fnd_message.get);

     fnd_message.set_name('POS','POS_SUPP_END_CONT_BODY');
     fnd_message.set_token('COMPANY',l_enterprise_name );
     fnd_message.set_token('ENDDATE',p_end_date);

        -- Message Body
    wf_notification.Setattrtext(nid => l_notification_id,
                                      aname => 'SUPPMSGBD',
                                      avalue => fnd_message.get);
      p_result := 'S';
EXCEPTION
   WHEN OTHERS THEN
      pos_log.log_sqlerrm('POSADMB', 'send_mail_contact');
      RAISE;
END send_mail_contact;


END pos_user_admin_pkg;
/

--show error
COMMIT;
EXIT;
