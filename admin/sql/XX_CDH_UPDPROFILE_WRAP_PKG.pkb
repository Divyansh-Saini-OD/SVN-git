SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY apps.XX_CDH_UPDPROFILE_WRAP_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_UPDPROFILE_WRAP_PKG               	       |
-- | Description :                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       03-Mar-2013 Kedar              Script for plsql types    |
-- +===================================================================+
AS

   FUNCTION fnd_profile$save (X_NAME VARCHAR2,
	X_VALUE VARCHAR2,
	X_LEVEL_NAME VARCHAR2,
	X_LEVEL_VALUE VARCHAR2,
	X_LEVEL_VALUE_APP_ID VARCHAR2,
	X_LEVEL_VALUE2 VARCHAR2
	) RETURN INTEGER IS
 RETURN_ INTEGER;
   BEGIN
      RETURN_ := SYS.SQLJUTL.BOOL2INT(APPS.FND_PROFILE.SAVE(X_NAME,
	X_VALUE,
	X_LEVEL_NAME,
	X_LEVEL_VALUE,
	X_LEVEL_VALUE_APP_ID,
	X_LEVEL_VALUE2
	));
      return RETURN_;
   END fnd_profile$save;


END XX_CDH_UPDPROFILE_WRAP_PKG;
/
