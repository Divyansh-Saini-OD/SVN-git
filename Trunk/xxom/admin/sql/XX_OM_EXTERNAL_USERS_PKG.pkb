SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 

CREATE OR REPLACE PACKAGE BODY XX_OM_EXTERNAL_USERS_PKG AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_OM_EXTERNAL_USER_PKG.pkb                                       |
-- | Description:                                                              |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======  ===========  =============    ====================================|
-- |1.0      14-May-2010  Matthew Craig    Initial draft version               |
-- +===========================================================================+

    v_cp_enabled            BOOLEAN := TRUE;
  
-- +===========================================================================+
-- | Name: generate_ldif_file                                                  |
-- |                                                                           |
-- | Description:                                                              |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE generate_ldif_file 
IS
    x_retcode VARCHAR2(100);
    x_errbuff VARCHAR2(100);
BEGIN
    generate_ldif_file (x_retcode,x_errbuff);
    
END;

PROCEDURE generate_ldif_file (
     x_retcode          OUT NOCOPY VARCHAR2
    ,x_errbuff          OUT NOCOPY VARCHAR2)
IS

    x number := 0;
    CURSOR c_stores  
    IS
        SELECT
             SUBSTR(o.name,2,5) givenname
            ,SUBSTR(o.name,8,30) surname
            ,substr(o.name,2,60) displayname
            ,SUBSTR(o.name,2,5) || '@officedepot.com' email
            ,SUBSTR(o.name,2,5) user_id
        FROM   
             apps.hr_all_organization_units o
        WHERE  
                o.type like 'STORE%'
            AND date_to IS NULL;
                    

BEGIN

    write_output('#');
    write_output('# LDIF FILE for TD Service Users ');
    write_output('#');
    write_output('');
    write_output('');
    

    -- Main query Loop
    FOR ext_user IN c_stores
    LOOP 
        write_output('dn: cn='||ext_user.user_id||',cn=odstores,cn=users,dc=odcorp,dc=net');
        write_output('givenname: ' || ext_user.givenname);
        write_output('sn: ' || ext_user.surname);
        write_output('displayname: ' || ext_user.displayname);
        write_output('mail:' || ext_user.email);
        write_output('uid: ' || ext_user.user_id);
        write_output('cn: ' || ext_user.user_id);
        write_output('userpassword: ODtds10');
        write_output('objectclass: inetorgperson');
        write_output('objectclass: person');
        write_output('objectclass: orcluserv2');
        write_output('objectclass: organizationalPerson');
        write_output('objectclass: top');
        write_output(' ');
        
 --       x:= x + 1;
 --       if x > 5 then
 --           exit;
 --       end if;
    END LOOP;
    write_output('***DONE***');
EXCEPTION

    WHEN OTHERS THEN
        x_errbuff := 'ERROR:Untrapped error' || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);

END generate_ldif_file;



PROCEDURE write_output( pbuff VARCHAR2) IS
BEGIN
  IF v_cp_enabled THEN
     IF fnd_global.conc_request_id > 0  THEN
         FND_FILE.PUT_LINE( FND_FILE.output, pBUFF);
     ELSE
         null;
     END IF;
  ELSE
    dbms_output.put_line(pbuff) ;
  END IF;
END write_output;

PROCEDURE LOG_MESSAGE(pBUFF  IN  VARCHAR2) IS
BEGIN
  IF v_cp_enabled THEN
     IF fnd_global.conc_request_id > 0  THEN
         FND_FILE.PUT_LINE( FND_FILE.LOG, pBUFF);
     ELSE
         null;
     END IF;
  ELSE
    dbms_output.put_line(pbuff) ;
  END IF;
  EXCEPTION
     WHEN OTHERS THEN
        RETURN;
END LOG_MESSAGE;


END XX_OM_EXTERNAL_USERS_PKG;
/
SHOW ERRORS PACKAGE BODY XX_OM_EXTERNAL_USERS_PKG;
EXIT;

