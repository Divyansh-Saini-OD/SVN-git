DECLARE
   g_last_update_date    DATE   := SYSDATE;
   g_last_updated_by     NUMBER;
   g_last_update_login   NUMBER;
   g_application_id      NUMBER;
   g_responsibility_id   NUMBER;
   l_function_id         NUMBER;
   CURSOR c_update_menu --(l_function_id number)
   IS
        SELECT DISTINCT MENU_ID,
          SUB_MENU_ID,
          FUNCTION_ID,
          ENTRY_SEQUENCE,
          GRANT_FLAG,
          USER_MENU_NAME,
          SUB_MENU_NAME,
          UPPER(USER_FUNCTION_NAME),
          PROMPT,
          DESCRIPTION
        FROM
          (SELECT frv.responsibility_name,
            lvl r_lvl,
            ROWNUMBER RW_NUM,
            entry_sequence ,
            ( lvl
            || '.'
            || rownumber
            || '.'
            || ENTRY_SEQUENCE) MENU_SEQ,
            User_MENU_NAME,
            fm.menu_id,
            SUB_MENU_NAME,
            sub_menu_id,
            prompt,
            fm.description,
            grant_flag,
            TYPE,
            FUNCTION_NAME,
            fm.function_id,
            user_function_name,
            fff.description form_description
          FROM
            (SELECT LEVEL lvl,
              menu_id,
              ROW_NUMBER() OVER(PARTITION BY LEVEL, menu_id, entry_sequence ORDER BY entry_sequence) AS rownumber,
              entry_sequence,
              (SELECT user_menu_name
              FROM FND_MENUS_VL FMVL
              WHERE 1          = 1
              AND fmvl.menu_id = fmv.menu_id
              ) user_menu_name,
              (SELECT user_menu_name
              FROM fnd_menus_vl fmvl
              WHERE 1          = 1
              AND FMVL.MENU_ID = FMV.SUB_MENU_ID
              ) SUB_MENU_NAME,
              (SELECT menu_id
              FROM FND_MENUS_VL FMVL
              WHERE 1          = 1
              AND fmvl.menu_id = fmv.sub_menu_id
              ) sub_menu_id,
              function_id,
              prompt,
              description,
              grant_flag
            FROM apps.fnd_menu_entries_vl fmv
              START WITH menu_id IN
              (SELECT menu_id
              FROM fnd_menus_vl
              --WHERE (UPPER(user_menu_name) LIKE '%DISCO%'
              --OR UPPER(menu_name) LIKE '%DISCO%')
              WHERE (UPPER(user_menu_name) LIKE '%DISCOV%' OR UPPER(PROMPT) LIKE '%DISCOV%' --Changed to fix the Defect#27732
              OR UPPER(menu_name) LIKE '%DISCOV%')                                          --Changed to fix the Defect#27732
              )
              CONNECT BY PRIOR menu_id = sub_menu_id
            ) fm,
            apps.fnd_form_functions_vl fff,
            apps.fnd_responsibility_vl frv
          WHERE fff.function_id(+) = fm.function_id
          AND frv.menu_id          = fm.menu_id
          ORDER BY frv.responsibility_name,
            lvl,
            ENTRY_SEQUENCE
          ) STUFF
        WHERE 1=1
        --AND (UPPER (stuff.user_menu_name) LIKE '%DISCO%' 
        --OR UPPER(sub_menu_name) LIKE '%DISCO%'
        --OR UPPER(FUNCTION_NAME) LIKE '%DISCO%'
        --OR UPPER(USER_FUNCTION_NAME) LIKE '%DISCO%')
        AND (UPPER (stuff.user_menu_name) LIKE '%DISCOV%' OR UPPER(PROMPT) LIKE '%DISCOV%'   --Changed to fix the Defect#27732
        OR UPPER(sub_menu_name) LIKE '%DISCOV%'                                              --Changed to fix the Defect#27732
        OR UPPER(FUNCTION_NAME) LIKE '%DISCOV%'                                              --Changed to fix the Defect#27732
        OR UPPER(USER_FUNCTION_NAME) LIKE '%DISCOV%');                                       --Changed to fix the Defect#27732
BEGIN
   SELECT USER_ID
     INTO g_last_updated_by
     FROM fnd_user
    WHERE user_name = 'ANONYMOUS';
   g_last_update_login := g_last_updated_by;
   FOR c_update_menu_rec IN c_update_menu --(c_function_rec.function_id)
   LOOP
      BEGIN
        IF C_UPDATE_MENU_REC.FUNCTION_ID is not null then
        	 fnd_menu_entries_pkg.update_row
                	       (x_menu_id                => c_update_menu_rec.menu_id,
                        	x_entry_sequence         => c_update_menu_rec.entry_sequence,
                       		X_SUB_MENU_ID            => C_UPDATE_MENU_REC.SUB_MENU_ID,
	                        X_FUNCTION_ID            => C_UPDATE_MENU_REC.FUNCTION_ID,  --C_FUNCTION_REC.FUNCTION_ID,--l_function_id,
        	                x_grant_flag             => 'N', --C_UPDATE_MENU_REC.GRANT_FLAG,
                	        x_prompt                 => c_update_menu_rec.prompt,
                        	x_description            => c_update_menu_rec.description,
	                        x_last_update_date       => g_last_update_date,
        	                x_last_updated_by        => g_last_updated_by,
                	        x_last_update_login      => g_last_update_login
                       		);
         Else
                 fnd_menu_entries_pkg.delete_row
                	       (x_menu_id                => c_update_menu_rec.menu_id,
                        	X_ENTRY_SEQUENCE         => C_UPDATE_MENU_REC.ENTRY_SEQUENCE
                          );
         END IF;
	          DBMS_OUTPUT.put_line ( 'function_id'||C_UPDATE_MENU_REC.function_id);
        	  DBMS_OUTPUT.PUT_LINE ( 'user_menu_name '||C_UPDATE_MENU_REC.USER_MENU_NAME);
	          DBMS_OUTPUT.PUT_LINE ( 'user_Submenu_name '||C_UPDATE_MENU_REC.SUB_MENU_NAME);
        	  DBMS_OUTPUT.put_line ( 'Menu prompt '||c_update_menu_rec.prompt);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (   'Failed the update Menu '
                                  || c_update_menu_rec.user_menu_name ||'-' ||SQLERRM
                                 );
      END;
   END LOOP;
   COMMIT;
   --  Compiling Security Profile
   DECLARE
   l_request_id          NUMBER;
   BEGIN
      SELECT application_id, responsibility_id
        INTO g_application_id, g_responsibility_id
        FROM fnd_responsibility_tl
       WHERE responsibility_name = 'System Administrator';
      fnd_global.apps_initialize (g_last_updated_by,
                                  g_responsibility_id,
                                  g_application_id
                                 );
      l_request_id :=
         fnd_request.submit_request (application      => 'FND',
                                     program          => 'FNDSCMPI',
                                     argument1        => 'No'
                                    );
      DBMS_OUTPUT.put_line ('Request ID: ' || l_request_id);
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('Error While compiling Security Profile'||'-' ||SQLERRM);
   END;
EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('Error'||'-' ||SQLERRM);
END;