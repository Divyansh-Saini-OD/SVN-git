col USN noprint
col recnum noprint
set termout off
set feedback off
set verify off
set head off
set pagesize 13
set trimspool on
spool c:/temp/users.ldif
select c.ext_user_id USN,'01' recnum,'dn:cn='||c.userid||',ou=na,cn=odcustomer,cn=odexternal,cn=Users,dc=odcorp,dc=net'
  from xxcrm.xx_external_users c
union
select c.ext_user_id USN,'02' recnum,'objectclass:top' 
  from xxcrm.xx_external_users c
union
select c.ext_user_id USN,'03' recnum,'objectclass: person'
  from xxcrm.xx_external_users c
union 
select c.ext_user_id USN, '04' recnum, 'objectclass: inetorgperson' 
  from xxcrm.xx_external_users c
union
select c.ext_user_id USN, '05' recnum, 'objectclass: organizationalperson' 
  from xxcrm.xx_external_users c
union
select c.ext_user_id USN,'06' recnum, 'objectclass: orcluser' 
  from xxcrm.xx_external_users c
union
select c.ext_user_id USN,'07' recnum, 'objectclass: orcluserv2' 
  from xxcrm.xx_external_users c
union
select c.ext_user_id USN,'08' recnum,'mail:'||c.email
  from xxcrm.xx_external_users c
union
select c.ext_user_id USN,'09' recnum,'userpassword:'|| xx_external_users_pkg.decipher( upper(c.password) )
  from xxcrm.xx_external_users c
union
select c.ext_user_id USN,'10' recnum,'uid:'||c.userid 
  from xxcrm.xx_external_users c
--union
--select c.ext_user_id USN,'11' recnum,
--       'orcldefaultprofilegroup:cn=portal_user,cn=portal_groups,cn=groups,dc=odcorp,dc=net'
--  from xxcrm.xx_external_users c
union
select c.ext_user_id USN,'12' recnum,'cn:'||c.userid
  from xxcrm.xx_external_users c
union
select c.ext_user_id USN,'13' recnum,'sn:'||c.person_last_name 
  from xxcrm.xx_external_users c
order by 1,2
/
spool off