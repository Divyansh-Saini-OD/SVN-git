SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- XX_CDH_EBILL_UTIL_PKG.pkb
CREATE OR REPLACE PACKAGE BODY XX_CDH_EBILL_UTIL_PKG

 -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XX_CDH_EBILL_UTIL_PKG                                         |
  -- | Description :                                                             |
  -- | This package provides utility procedures for ebilling.                    |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author        Remarks                                 |
  -- |======== =========== ============= ========================================|
  -- |DRAFT 1A 17-MAY-2010 Lokesh        Initial draft version                   |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

AS

----------------------------------------------------------------------------
-- Private PROCEDURES and FUNCTIONS.
----------------------------------------------------------------------------


----------------------------------------------------------------------------
-- Public PROCEDURES and FUNCTIONS.
----------------------------------------------------------------------------

FUNCTION getapplicationname(appl_id NUMBER)
    RETURN VARCHAR2
    IS
    appname VARCHAR2(240) := NULL;

  CURSOR appvalue IS
  SELECT application_name
  FROM fnd_application_vl
  WHERE application_id = appl_id;

  BEGIN

    IF appl_id IS NOT NULL THEN

      OPEN appvalue;
      FETCH appvalue
      INTO appname;
      CLOSE appvalue;
    END IF;

    RETURN appname;

  END getapplicationname;

  FUNCTION getusername(user_id1 NUMBER)
    RETURN VARCHAR2 
    IS
    usern VARCHAR2(240) := NULL;

  CURSOR username1 IS
  SELECT user_name
  FROM fnd_user
  WHERE user_id = user_id1;

  BEGIN

    IF user_id1 IS NOT NULL THEN

      OPEN username1;
      FETCH username1
      INTO usern;
      CLOSE username1;
    END IF;

    RETURN usern;

  END getusername;

  FUNCTION getrespname(resp_id NUMBER)
    RETURN VARCHAR2 
    IS
    respn VARCHAR2(240) := NULL;

  CURSOR respname IS
  SELECT responsibility_name
  FROM fnd_responsibility_vl
  WHERE responsibility_id = resp_id;

  BEGIN

    IF resp_id IS NOT NULL THEN

      OPEN respname;
      FETCH respname
      INTO respn;
      CLOSE respname;
    END IF;

    RETURN respn;

  END getrespname;
  
  
  FUNCTION getParamValue(paramName varchar2)
    RETURN varchar2
  IS
    pValue varchar2(500) := null;
      
    CURSOR paramValue
    IS
      SELECT *
      FROM
        (SELECT param_value 
        FROM xx_cdh_ebl_param_setup a, XX_CDH_EBL_PARAM_MAP b
        WHERE a.param_name = paramName
	and a.param_name = b.param_name
	and b.deactive_param_flag = 'N' 
        and (fnd_global.user_id   = a.userid
        OR fnd_global.resp_id      = a.responsibilityid 
        OR fnd_global.resp_appl_id = a.applicationid
        OR a.site = 1)
        ORDER BY USERID,
          RESPONSIBILITYID,
          applicationid,
          site
        )
    WHERE rownum = 1;
    
  BEGIN
    OPEN paramValue;
    FETCH paramValue INTO pValue;
    
    IF paramValue%NOTFOUND THEN
      pValue := null;
    END IF;  
    
    CLOSE paramValue;
    
    return pValue;
    
  END getParamValue;
  
  FUNCTION getParamDesc(parameter_name VARCHAR2)
    RETURN VARCHAR2 
    IS
    pDesc VARCHAR2(4000) := NULL;

  CURSOR ParamName IS
  SELECT PARAM_DESCRIPTION
  FROM xx_cdh_ebl_param_map
  WHERE param_name = parameter_name;

  BEGIN

    IF parameter_name IS NOT NULL THEN

      OPEN ParamName;
      FETCH ParamName
      INTO pDesc;
      CLOSE ParamName;
    END IF;

    RETURN pDesc;

  END getParamDesc;


  
  
  END XX_CDH_EBILL_UTIL_PKG;

/
SHOW ERRORS;

