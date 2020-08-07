create or replace package body XX_SP_FND_WEB_SEC_PKG as

function validate_login( i_username in varchar2, i_password in varchar2 ) return VARCHAR2 is

      begin

       return (fnd_web_sec.validate_login(i_username,i_password));

      exception

       when others then return 'N';

      end validate_login;

end XX_SP_FND_WEB_SEC_PKG;
/
