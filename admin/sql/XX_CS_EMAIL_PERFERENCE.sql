
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
-- +=========================================================================================+
-- | Name         : XX_CS_EMAIL_PERFERENCE                                                   |
-- | Description  : Update User Preference                                                   |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date          Author           Remarks                                        | 
-- |=======    ==========    =============    ===============================================+
-- |DRAFT 1A   01-04-2008   Raj Jagarlamudi    Initial Version                               |
-- +=========================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


CREATE OR REPLACE
PROCEDURE      XX_CS_EMAIL_PERFERENCE AS

CURSOR c_get_user IS
select user_name 
from JTF_RS_DEFRESOURCES_VL 
where resource_id in (
select v1.resource_id 
from jtf_rs_defresgroups_vl v1,
     jtf_rs_group_usages v
where v.group_id = v1.group_id
and v.usage = 'SUPPORT');

v_user_name 	varchar2(50);

CURSOR c_get_pref IS 
SELECT preference_value 
FROM FND_USER_PREFERENCES 
WHERE user_name = v_user_name 
AND module_name = 'WF' 
AND preference_name = 'MAILTYPE'; 

v_value FND_USER_PREFERENCES.preference_value%TYPE := 'MAILHTML'; 
v_currval FND_USER_PREFERENCES.preference_value%TYPE; 
v_found BOOLEAN := FALSE; 
v_changed BOOLEAN := FALSE; 

BEGIN
  BEGIN
   OPEN c_get_user;
   LOOP
   FETCH c_get_user INTO v_user_name;
   EXIT WHEN C_GET_USER%NOTFOUND;
    
	BEGIN 
	OPEN c_get_pref; 
	FETCH c_get_pref INTO v_currval; 
	IF c_get_pref%NOTFOUND THEN 
		v_found := FALSE; 
		DBMS_OUTPUT.PUT_LINE ( 'Preference not found, creating it...' ); 
		INSERT INTO FND_USER_PREFERENCES ( user_name 
		, module_name 
		, preference_name 
		, preference_value ) 
		VALUES ( v_user_name 
		, 'WF' 
		, 'MAILTYPE' 
		, v_value ); 
	ELSE 
		v_found := TRUE; 
	END IF; 
	CLOSE c_get_pref; 

	IF (v_found) THEN 
	   IF (v_currval != v_value) THEN 
		DBMS_OUTPUT.PUT_LINE ( 'Preference not valid, updating it...' ); 

		UPDATE FND_USER_PREFERENCES SET preference_value = v_value 
		WHERE user_name = '-WF_DEFAULT-' 
		AND module_name = 'WF' 
		AND preference_name = 'MAILTYPE'; 
	   ELSE 
		DBMS_OUTPUT.PUT_LINE ( 'Preference correct - no action' ); 
	   END IF; 
       END IF; 
      COMMIT;
    END;
    
    END LOOP;
    CLOSE c_get_user;
    END;
END;

/

