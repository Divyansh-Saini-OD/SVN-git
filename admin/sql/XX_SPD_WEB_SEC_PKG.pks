create or replace PACKAGE XX_SP_FND_WEB_SEC_PKG AS

function validate_login( i_username in varchar2, i_password in varchar2 ) 
 return VARCHAR2;
	
END XX_SP_FND_WEB_SEC_PKG;