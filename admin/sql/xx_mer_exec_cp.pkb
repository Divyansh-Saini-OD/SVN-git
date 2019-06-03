CREATE OR REPLACE PACKAGE BODY xx_mer_exec_cp_pkg AS
------------------------------------------------------------------------------------------------------
-- Package Name: xx_mer_exec_cp_pkg
-- Author:       Antonio Morales
-- Objective:    Excecute Concurrent Programs
-- Date:         13-Nov-2007
-- History:
--
-----------------------------------------------------------------------------------------------------
-- Gets the number of parameters for a given CP
------------------------------------------------------------------------------------------------------
FUNCTION xx_mer_get_cp_npar    ( p_conc_pgm_shortname IN VARCHAR2
                               ) RETURN NUMBER IS
                               
v_npar NUMBER;

BEGIN

 BEGIN
  SELECT count(*)
    INTO v_npar
    FROM fnd_descr_flex_col_usage_vl
   WHERE descriptive_flexfield_name like upper('%' || p_conc_pgm_shortname);
 EXCEPTION
  WHEN OTHERS THEN
       v_npar:= 0;
 END;
 RETURN v_npar;
END xx_mer_get_cp_npar;

-----------------------------------------------------------------------------------------------------
-- Gets the user id and initialize a CM session
------------------------------------------------------------------------------------------------------
FUNCTION xx_mer_get_user_id    ( p_module_name        IN VARCHAR2
                                ,p_app_name           IN VARCHAR2
                                ,p_username           IN VARCHAR2
                               ) RETURN NUMBER IS

 v_event             VARCHAR2(100);

BEGIN

 v_event := 'Getting user information';

 SELECT u.user_id
       ,a.application_id
       ,r.responsibility_id
  INTO  v_user_id
       ,v_app_id
       ,v_resp_id
   FROM fnd_user           u
       ,fnd_application    a
       ,fnd_responsibility r
  WHERE u.user_name              = p_username
    AND a.application_short_name = p_app_name
    AND a.application_id         = r.application_id;

 v_event := 'APPS Initialize';

 dbms_output.put_line(chr(10) || 'Init '|| p_app_name  ||
                     ' user_id=' || v_user_id || ' / resp_id=' || v_resp_id || ' / appl_resp_id=' || v_app_id);
 fnd_global.apps_initialize(v_user_id,v_resp_id,v_app_id);
 dbms_output.put_line('fnd_global.user_id='||fnd_global.user_id);
 RETURN fnd_global.user_id;
 
EXCEPTION
 WHEN OTHERS THEN
    dbms_output.put_line(v_event || ' ' || sqlerrm);
    xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                        ,p_module_name
                                        ,v_event
                                        ,'E'
                                        ,'1'
                                        ,sqlerrm
                                        ,v_user_id
                                        ,fnd_global.login_id
                                       );
    x_error_buff := sqlerrm;
    v_rcode := sqlcode * -1;
    dbms_output.put_line(v_event || ' ' || sqlerrm);
    RETURN v_rcode;

END xx_mer_get_user_id;                          
------------------------------------------------------------------------------------------------------
-- Execute a given  CP
------------------------------------------------------------------------------------------------------
FUNCTION xx_mer_get_cp_default ( p_parname IN VARCHAR2
                                ,p_nrec    IN PLS_INTEGER
                               ) RETURN VARCHAR2 IS

v_default_string_result VARCHAR2(2000) := NULL;
v_default_date_result   DATE           := NULL;
v_sqlstmt               VARCHAR2(2000) := NULL;
v_nrec                  PLS_INTEGER    := 0;

BEGIN
 FOR rc IN (SELECT cp.application_id
                  ,cp.concurrent_program_name
                  ,dv.end_user_column_name
                  ,dv.default_type
                  ,vs.format_type  
                  ,dv.default_value
                  ,dv.column_seq_num
                  ,vs.flex_value_set_name
                  ,vs.maximum_size
             FROM  fnd_concurrent_programs     cp
                  ,fnd_descr_flex_col_usage_vl dv
                  ,fnd_flex_value_sets         vs
            WHERE upper(cp.concurrent_program_name)      IN upper(p_parname)
              AND upper(dv.descriptive_flexfield_name) LIKE '%'||upper(cp.concurrent_program_name)||'%'
              AND cp.application_id                       = dv.application_id
              AND dv.flex_value_set_id                    = vs.flex_value_set_id 
            ORDER BY dv.column_seq_num) LOOP
v_nrec := v_nrec + 1;
IF v_nrec = p_nrec THEN
 IF rc.default_type = 'D' THEN
    IF rc.format_type = 'X' THEN
       v_default_date_result := trunc(sysdate);
     ELSE
       v_default_date_result := sysdate;
    END IF;
    v_default_string_result := to_char(v_default_date_result,'yyyy/mm/dd hh24:mi:ss');
 ELSIF rc.default_type = 'S' THEN
    IF rc.format_type IN ('X','D','Y','L','Y') THEN
       EXECUTE IMMEDIATE rc.default_value INTO v_default_date_result;
       IF rc.format_type = 'X' THEN
          v_default_date_result := trunc(v_default_date_result);
       END IF;
       v_default_string_result := to_char(v_default_date_result,'yyyy/mm/dd hh24:mi:ss');
     ELSE
       EXECUTE IMMEDIATE rc.default_value INTO v_default_string_result;
    END IF;
 ELSIF upper(rc.default_type) IN ('C','N') THEN
       v_default_string_result := rc.default_value;
 END IF;
 dbms_output.put_line('result='||v_default_string_result||' max='||rc.maximum_size||' str='||
                         substr(v_default_string_result,1,rc.maximum_size)||
                         ' type=' || rc.default_type || ' format='||rc.format_type||' value='||rc.default_value);
END IF;
END LOOP;
 RETURN v_default_string_result;
 
END xx_mer_get_cp_default;

------------------------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------------------------
FUNCTION exec_cp  ( p_module_name        IN VARCHAR2
                   ,p_app_name           IN VARCHAR2
                   ,p_conc_pgm_shortname IN VARCHAR2
                   ,p_username           IN VARCHAR2
                   ,argument1            IN VARCHAR2 DEFAULT chr(0)
                   ,argument2            IN VARCHAR2 DEFAULT chr(0)
                   ,argument3            IN VARCHAR2 DEFAULT chr(0)
                   ,argument4            IN VARCHAR2 DEFAULT chr(0)
                   ,argument5            IN VARCHAR2 DEFAULT chr(0)
                   ,argument6            IN VARCHAR2 DEFAULT chr(0)
                   ,argument7            IN VARCHAR2 DEFAULT chr(0)
                   ,argument8            IN VARCHAR2 DEFAULT chr(0)
                   ,argument9            IN VARCHAR2 DEFAULT chr(0)
                   ,argument10           IN VARCHAR2 DEFAULT chr(0)
                   ,argument11           IN VARCHAR2 DEFAULT chr(0)
                   ,argument12           IN VARCHAR2 DEFAULT chr(0)
                   ,argument13           IN VARCHAR2 DEFAULT chr(0)
                   ,argument14           IN VARCHAR2 DEFAULT chr(0)
                   ,argument15           IN VARCHAR2 DEFAULT chr(0)
                   ,argument16           IN VARCHAR2 DEFAULT chr(0)
                   ,argument18           IN VARCHAR2 DEFAULT chr(0)
                   ,argument19           IN VARCHAR2 DEFAULT chr(0)
                   ,argument20           IN VARCHAR2 DEFAULT chr(0)
                   ,argument21           IN VARCHAR2 DEFAULT chr(0)
                   ,argument22           IN VARCHAR2 DEFAULT chr(0)
                   ,argument23           IN VARCHAR2 DEFAULT chr(0)
                   ,argument24           IN VARCHAR2 DEFAULT chr(0)
                   ,argument25           IN VARCHAR2 DEFAULT chr(0)
                   ,argument26           IN VARCHAR2 DEFAULT chr(0)
                   ,argument27           IN VARCHAR2 DEFAULT chr(0)
                   ,argument28           IN VARCHAR2 DEFAULT chr(0)
                   ,argument29           IN VARCHAR2 DEFAULT chr(0)
                   ,argument30           IN VARCHAR2 DEFAULT chr(0)
                   ,argument31           IN VARCHAR2 DEFAULT chr(0)
                   ,argument32           IN VARCHAR2 DEFAULT chr(0)
                   ,argument33           IN VARCHAR2 DEFAULT chr(0)
                   ,argument34           IN VARCHAR2 DEFAULT chr(0)
                   ,argument35           IN VARCHAR2 DEFAULT chr(0)
		     	   ,argument36           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument37           IN VARCHAR2 DEFAULT chr(0)
  	     		   ,argument38           IN VARCHAR2 DEFAULT chr(0)
		     	   ,argument39           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument40           IN VARCHAR2 DEFAULT chr(0)
	     		   ,argument41           IN VARCHAR2 DEFAULT chr(0)
  		     	   ,argument42           IN VARCHAR2 DEFAULT chr(0)
			       ,argument43           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument44           IN VARCHAR2 DEFAULT chr(0)
	     		   ,argument45           IN VARCHAR2 DEFAULT chr(0)
		     	   ,argument46           IN VARCHAR2 DEFAULT chr(0)
			       ,argument47           IN VARCHAR2 DEFAULT chr(0)
       			   ,argument48           IN VARCHAR2 DEFAULT chr(0)
	     		   ,argument49           IN VARCHAR2 DEFAULT chr(0)
		     	   ,argument50           IN VARCHAR2 DEFAULT chr(0)
			       ,argument51           IN VARCHAR2 DEFAULT chr(0)
       			   ,argument52           IN VARCHAR2 DEFAULT chr(0)
	     		   ,argument53           IN VARCHAR2 DEFAULT chr(0)
		     	   ,argument54           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument55           IN VARCHAR2 DEFAULT chr(0)
	               ,argument56           IN VARCHAR2 DEFAULT chr(0)
			       ,argument57           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument58           IN VARCHAR2 DEFAULT chr(0)
                   ,argument59           IN VARCHAR2 DEFAULT chr(0)
		     	   ,argument60           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument61           IN VARCHAR2 DEFAULT chr(0)
	     		   ,argument62           IN VARCHAR2 DEFAULT chr(0)
  		     	   ,argument63           IN VARCHAR2 DEFAULT chr(0)
			       ,argument64           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument65           IN VARCHAR2 DEFAULT chr(0)
	     		   ,argument66           IN VARCHAR2 DEFAULT chr(0)
		     	   ,argument67           IN VARCHAR2 DEFAULT chr(0)
			       ,argument68           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument69           IN VARCHAR2 DEFAULT chr(0)
	     		   ,argument70           IN VARCHAR2 DEFAULT chr(0)
		     	   ,argument71           IN VARCHAR2 DEFAULT chr(0)
			       ,argument72           IN VARCHAR2 DEFAULT chr(0)
       			   ,argument73           IN VARCHAR2 DEFAULT chr(0)
	     		   ,argument74           IN VARCHAR2 DEFAULT chr(0)
		     	   ,argument75           IN VARCHAR2 DEFAULT chr(0)
                   ,argument76           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument77           IN VARCHAR2 DEFAULT chr(0)
         		   ,argument78           IN VARCHAR2 DEFAULT chr(0)
                   ,argument79           IN VARCHAR2 DEFAULT chr(0)
     			   ,argument80           IN VARCHAR2 DEFAULT chr(0)
                   ,argument81           IN VARCHAR2 DEFAULT chr(0)
                   ,argument82           IN VARCHAR2 DEFAULT chr(0)
                   ,argument83           IN VARCHAR2 DEFAULT chr(0)
                   ,argument84           IN VARCHAR2 DEFAULT chr(0)
                   ,argument85           IN VARCHAR2 DEFAULT chr(0)
                   ,argument86           IN VARCHAR2 DEFAULT chr(0)
                   ,argument87           IN VARCHAR2 DEFAULT chr(0)
                   ,argument88           IN VARCHAR2 DEFAULT chr(0)
                   ,argument89           IN VARCHAR2 DEFAULT chr(0)
                   ,argument90           IN VARCHAR2 DEFAULT chr(0)
                   ,argument91           IN VARCHAR2 DEFAULT chr(0)
                   ,argument92           IN VARCHAR2 DEFAULT chr(0)
                   ,argument93           IN VARCHAR2 DEFAULT chr(0)
                   ,argument94           IN VARCHAR2 DEFAULT chr(0)
                   ,argument95           IN VARCHAR2 DEFAULT chr(0)
                   ,argument96           IN VARCHAR2 DEFAULT chr(0)
                   ,argument97           IN VARCHAR2 DEFAULT chr(0)
                   ,argument98           IN VARCHAR2 DEFAULT chr(0)
                   ,argument99           IN VARCHAR2 DEFAULT chr(0)
                   ,argument100          IN VARCHAR2 DEFAULT chr(0)
                  ) RETURN NUMBER IS
 
 v_event               VARCHAR2(100);
 v_request_id          NUMBER;
 v_call_status         BOOLEAN;
 v_user_id             NUMBER := 0;                    -- EBs user id
 v_resp_id             NUMBER := 0;                    --  Responsibility_id (fnd_responsibility table)
                                                       -- 'All purchasing super user'
 v_app_id              NUMBER := 0;                    -- Application_id from (fnd_responsibility table), 'XXMER''
 v_request_phase       VARCHAR2(200);
 v_request_status      VARCHAR2(200);
 v_dev_request_phase   VARCHAR2(200);
 v_dev_request_status  VARCHAR2(200);
 v_request_status_mesg VARCHAR2(200);

BEGIN

 
 v_request_id := fnd_request.submit_request( p_app_name
                                            ,p_conc_pgm_shortname
                                            ,NULL
                                            ,NULL
                                            ,FALSE
                                            ,argument1
                                            ,argument2
                                            ,argument3
                                            ,argument4
                                            ,argument5
                                            ,argument6
                                            ,argument7
                                            ,argument8
                                            ,argument9
                                            ,argument10
                                            ,argument11
                                            ,argument12
                                            ,argument13
                                            ,argument14
                                            ,argument15
                                            ,argument16
                                            ,argument18
                                            ,argument19
                                            ,argument20
                                            ,argument21
                                            ,argument22
                                            ,argument23
                                            ,argument24
                                            ,argument25
                                            ,argument26
                                            ,argument27
                                            ,argument28
                                            ,argument29
                                            ,argument30
                                            ,argument31
                                            ,argument32
                                            ,argument33
                                            ,argument34
                                            ,argument35
                                            ,argument36
                                            ,argument37
                                            ,argument38
                                            ,argument39
                                            ,argument40
                                            ,argument41
                                            ,argument42
                                            ,argument43
                                            ,argument44
                                            ,argument45
                                            ,argument46
                                            ,argument47
                                            ,argument48
                                            ,argument49
                                            ,argument50
                                            ,argument51
                                            ,argument52
                                            ,argument53
                                            ,argument54
                                            ,argument55
                                            ,argument56
                                            ,argument57
                                            ,argument58
                                            ,argument59
                                            ,argument60
                                            ,argument61
                                            ,argument62
                                            ,argument63
                                            ,argument64
                                            ,argument65
                                            ,argument66
                                            ,argument67
                                            ,argument68
                                            ,argument69
                                            ,argument70
                                            ,argument71
                                            ,argument72
                                            ,argument73
                                            ,argument74
                                            ,argument75
                                            ,argument76
                                            ,argument77
                                            ,argument78
                                            ,argument79
                                            ,argument80
                                            ,argument81
                                            ,argument82
                                            ,argument83
                                            ,argument84
                                            ,argument85
                                            ,argument86
                                            ,argument87
                                            ,argument88
                                            ,argument89
                                            ,argument90
                                            ,argument91
                                            ,argument92
                                            ,argument93
                                            ,argument94
                                            ,argument95
                                            ,argument96
                                            ,argument97
                                            ,argument98
                                            ,argument99
                                            ,argument100
                                           );

 COMMIT;

IF v_request_id > 0 THEN
   dbms_output.put_line('Successfully submitted['|| v_request_id || '] ' || to_char(sysdate,'mi:ss'));
   v_request_status_mesg := NULL;
   WHILE v_request_status_mesg IS NULL LOOP
--    dbms_output.put_line('Waiting.....');
       v_call_status := fnd_concurrent.wait_for_request(v_request_id,
                                                        10, --v_interval,
                                                         3,  --v_max_wait,
                                                        v_request_phase,
                                                        v_request_status,
                                                        v_dev_request_phase,
                                                        v_dev_request_status,
                                                        v_request_status_mesg);
    END LOOP;
    COMMIT;
    dbms_output.put_line('Message =[' || v_request_status_mesg || '] ' ||
                         ' Status=[' || v_dev_request_status || '] ' || to_char(sysdate,'hh24:mi:ss'));
    v_rcode:=0;
ELSE
   dbms_output.put_line('Error process not Submitted='||fnd_message.get);
   v_rcode:=1;
END IF;
 RETURN v_rcode;
EXCEPTION
 WHEN OTHERS THEN
    dbms_output.put_line(v_event || ' ' || sqlerrm);
    xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                        ,p_module_name
                                        ,v_event
                                        ,'E'
                                        ,'1'
                                        ,sqlerrm
                                        ,v_user_id
                                        ,fnd_global.login_id
                                       );
    x_error_buff := sqlerrm;
    v_rcode := sqlcode * -1;
    dbms_output.put_line(v_event || ' ' || sqlerrm);
    RETURN v_rcode;
END;

END xx_mer_exec_cp_pkg;