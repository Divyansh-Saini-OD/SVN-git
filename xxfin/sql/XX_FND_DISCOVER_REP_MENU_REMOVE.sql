-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Oracle                                                                                    | 
-- +============================================================================================+ 
-- |  Name:  Remove Discoverer Report Menus and Functions from R12 responsibilities                                          | 
-- |  Description: This SQL Script will be used to remove Discoverer Report Menus and Functions |
-- |                from R12 responsibilities.                                                  |
-- |                                                                                            |
-- |                                                                                            |
-- |                                                                                            |
-- |                                                                                            |
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         18-Nov-2013  Srinivas         Initial version                                  | 
-- +============================================================================================+
DECLARE
   g_last_update_date    DATE   := SYSDATE;
   g_last_updated_by     NUMBER;
   g_last_update_login   NUMBER;
   g_application_id      NUMBER;
   g_responsibility_id   NUMBER;
   l_function_id         NUMBER;
   
   
   CURSOR c_function
   IS
    SELECT function_id
      FROM fnd_form_functions_vl
     WHERE UPPER (user_function_name) =upper('OD Cash Positioning Gapping Discoverer Launch Read Only');
 
   CURSOR c_update_menu(l_function_id number)
   IS
      SELECT fmev.menu_id, fmev.entry_sequence, fmev.sub_menu_id,
             fmev.grant_flag, fmev.prompt, fmev.description, fm.menu_name,UPPER(user_function_name)
        FROM fnd_menu_entries_vl fmev, fnd_form_functions_vl ff, fnd_menus fm
       WHERE fmev.menu_id = fm.menu_id
         AND fmev.function_id = ff.function_id
         AND ff.function_id=l_function_id;
        
         
BEGIN
   SELECT user_id
     INTO g_last_updated_by
     FROM fnd_user
    WHERE user_name = '643121';

   g_last_update_login := g_last_updated_by;
   
   FOR c_function_rec IN c_function
   LOOP
       DBMS_OUTPUT.put_line ( 'c_function_rec.function_id'||c_function_rec.function_id);
   FOR c_update_menu_rec IN c_update_menu(c_function_rec.function_id)
   LOOP
      BEGIN
         fnd_menu_entries_pkg.update_row
                       (x_menu_id                => c_update_menu_rec.menu_id,
                        x_entry_sequence         => c_update_menu_rec.entry_sequence,
                        x_sub_menu_id            => c_update_menu_rec.sub_menu_id,
                        x_function_id            => c_function_rec.function_id,--l_function_id,
                        x_grant_flag             => 'N', --C_UPDATE_MENU_REC.GRANT_FLAG,
                        x_prompt                 => c_update_menu_rec.prompt,
                        x_description            => c_update_menu_rec.description,
                        x_last_update_date       => g_last_update_date,
                        x_last_updated_by        => g_last_updated_by,
                        x_last_update_login      => g_last_update_login
                       );
          DBMS_OUTPUT.put_line ( 'c_update_menu_rec.prompt '||c_update_menu_rec.prompt);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line (   'Failed the update Menu '
                                  || c_update_menu_rec.menu_name ||'-' ||SQLERRM
                                 );
      END;
   END LOOP;
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
/