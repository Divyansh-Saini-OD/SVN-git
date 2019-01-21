SET ECHO OFF
SET FEEDBACK OFF
SET HEADING OFF
SET LINESIZE 1000
SET TRIMOUT   ON
SET TRIMSPOOL ON
SET NEWPAGE NONE
-- SET WRAP OFF

col dn newline
col givenname newline
col SN newline
col DISPLAYNAME newline
col MAIL newline
col UID newline
col CN newline
col USERPASSWORD newline
col ORCLUSERPRINCIPALNAME newline
col OIDCLASS1 newline
col OIDCLASS2 newline
col OIDCLASS3 newline
col OIDCLASS4 newline
col OIDCLASS5 newline
col OIDCLASS6 newline

SPOOL &spool_file
SELECT trim('dn: cn=' ||  FND_USER_NAME || ',ou=na,cn=odcustomer,cn=odexternal,cn=users,dc=odcorp,dc=net') "DN",
       trim('givenname: ' || PERSON_FIRST_NAME)  "GIVENNAME",
       trim('sn: ' || PERSON_LAST_NAME)  "SN",
       trim(REPLACE('displayname: ' || person_first_name || NVL2(person_middle_name, '', ' ' || person_middle_name ) || ' ' ||person_last_name,'  ',' '))  "DISPLAYNAME",
       trim('mail: ' || EMAIL)  "MAIL",
       trim('uid: ' || FND_USER_NAME)  "UID",
       trim('cn: ' || FND_USER_NAME)  "CN",
       trim('userpassword: ' || XX_DECIPHER(PASSWORD))  "USERPASSWORD",
       trim('orcluserprincipalname: '  || EMAIL)  "ORCLUSERPRINCIPALNAME",
       trim('objectclass: inetorgperson')  "OIDCLASS1",
       trim('objectclass: person')  "OIDCLASS2",
       trim('objectclass: orcluserv2')  "OIDCLASS3",
       trim('objectclass: orcladuser')  "OIDCLASS4",
       trim('objectclass: organizationalPerson')  "OIDCLASS5",
       trim('objectclass: top')  || CHR(10) || CHR(10) "OIDCLASS6"
FROM xx_external_users
WHERE NVL(load_status,'P')='P';
spool off
