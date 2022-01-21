whenever sqlerror exit failure rollback 
  CREATE OR REPLACE FORCE VIEW "APPS"."XXOD_ADF_COMP_SECURITY" ("SEC_ID", "MENU_ID", "FUNCTION_ID", "APPLICATION_ID", "RESPONSIBILITY_ID", "RESPONSIBILITY_KEY", "MENU_NAME", "USER_FUNCTION_NAME") AS 
  select rownum 
     , a.menu_id
     , a.function_id
     , d.application_id
     , d.responsibility_id 
     , d.responsibility_key
     , c.menu_name
     , b.user_function_name 
from   fnd_compiled_menu_functions a,
       fnd_form_functions_tl b,
       fnd_menus c,
       fnd_responsibility d
where  a.function_id = b.function_id
and    b.language='US'
and    a.menu_id = c.menu_id
and    d.menu_id = c.menu_id;

show errors
