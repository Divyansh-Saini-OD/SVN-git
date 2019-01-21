set serveroutput on 1000000;
DECLARE
  P_INIT_MSG_LIST VARCHAR2(200);
  P_LOCATION_REC APPS.HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
  P_OBJECT_VERSION_NUMBER NUMBER;
  X_RETURN_STATUS VARCHAR2(200);
  X_MSG_COUNT NUMBER;
  X_MSG_DATA VARCHAR2(2000);
  l_count NUMBER;
  l_user_id fnd_user.user_id%type;
  l_resp_id fnd_responsibility_vl.responsibility_id%type;
  l_prefix VARCHAR2(1) := ' ';

  cursor c_update_loc is
  select /*+ parallel(loc,8) */ location_id, object_version_number, province, state
  from hz_locations loc
  where (trim(province) is null and  nvl(province,'xx') =  province ) OR 
        (trim(state) is null and  nvl(state,'xx') =  state );
BEGIN
  P_INIT_MSG_LIST := NULL;
  -- Modify the code to initialize the variable
  P_LOCATION_REC := NULL;

  -- GET USER ID
    select user_id into l_user_id from fnd_user where user_name = 'ODCDH';
  -- GET RESP ID
  select responsibility_id into l_resp_id from fnd_responsibility_vl 
  where responsibility_key = 'OD_US_CDH_ADMINSTRATOR';

  FND_GLOBAL.APPS_INITIALIZE(l_user_id, l_resp_id, 222);
  MO_GLOBAL.INIT;
  MO_GLOBAL.SET_POLICY_CONTEXT('S', 404);

  select /*+ parallel(loc,8) */ count(*) into l_count 
  from hz_locations loc
  where (trim(province) is null and  nvl(province,'xx') =  province ) OR 
        (trim(state) is null and  nvl(state,'xx') =  state );

  dbms_output.put_line('The no, of records to be updated for null issues are :  '|| l_count );
  

  for update_rec IN c_update_loc loop
	  P_OBJECT_VERSION_NUMBER := update_rec.object_version_number;
  	P_LOCATION_REC.location_id := update_rec.location_id;
    P_INIT_MSG_LIST := NULL;
    X_MSG_DATA := null;
    X_RETURN_STATUS :=null;
    X_MSG_COUNT :=null;

  	IF (trim(update_rec.province) is null and  nvl(update_rec.province,'xx') =  update_rec.province ) THEN
  		P_LOCATION_REC.province := FND_API.G_MISS_CHAR;
  	END IF;

  	IF (trim(update_rec.state) is null and  nvl(update_rec.state,'xx') =  update_rec.state ) THEN
       		P_LOCATION_REC.state := FND_API.G_MISS_CHAR;
  	END IF;

  	HZ_LOCATION_V2PUB.UPDATE_LOCATION(
    		P_INIT_MSG_LIST => P_INIT_MSG_LIST,
    		P_LOCATION_REC => P_LOCATION_REC,
    		P_OBJECT_VERSION_NUMBER => P_OBJECT_VERSION_NUMBER,
    		X_RETURN_STATUS => X_RETURN_STATUS,
    		X_MSG_COUNT => X_MSG_COUNT,
    		X_MSG_DATA => X_MSG_DATA
  	);

 	if x_return_status <>'S' THEN
        hz_utility_v2pub.debug(p_message=>'update_location (+)',
                               p_prefix=>l_prefix,
                               p_msg_level=> fnd_log.LEVEL_EXCEPTION);

        hz_utility_v2pub.debug(p_message=>'Error in location_id:' || P_LOCATION_REC.location_id ,
                            p_prefix=>l_prefix,
                               p_msg_level=> fnd_log.LEVEL_EXCEPTION);

  	IF X_MSG_COUNT >= 1 THEN
      FOR I IN 1..X_MSG_COUNt
      LOOP
        	hz_utility_v2pub.debug(p_message=>'location_id :' || P_LOCATION_REC.location_id  ||
                               'Error : ' || FND_MSG_PUB.Get(I, FND_API.G_FALSE) ,
                            p_prefix=>l_prefix,
                               p_msg_level=> fnd_log.LEVEL_EXCEPTION);
      END LOOP;       
    END IF;

   end if;
 end loop;

  select /*+ parallel(loc,8) */ count(*) into l_count 
  from hz_locations loc
  where (trim(province) is null and  nvl(province,'xx') =  province ) OR 
        (trim(state) is null and  nvl(state,'xx') =  state );

  dbms_output.put_line('The no, of records remaining with null issues are:  '|| l_count );

  commit;
  
END;
/