SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XX_CDH_UPDPROFILE_WRAP_PKG AS
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


   FUNCTION fnd_profile$save (X_NAME VARCHAR2,
	X_VALUE VARCHAR2,
	X_LEVEL_NAME VARCHAR2,
	X_LEVEL_VALUE VARCHAR2,
	X_LEVEL_VALUE_APP_ID VARCHAR2,
	X_LEVEL_VALUE2 VARCHAR2
	) RETURN INTEGER;
END XX_CDH_UPDPROFILE_WRAP_PKG;


/

