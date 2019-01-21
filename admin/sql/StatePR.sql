set serveroutput on

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :4299.sql                                                                    |--
--|                                                                                             |--
--| Program Name   :This script is to add Puerto Rico as state                                  |--        
--|                                                                                             |--   
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              26-Mar-2010       Naga kalyan             Initial version                  |--
--+=============================================================================================+-- 

begin

insert into
 apps.hz_geographies
 (geography_id, object_version_number, geography_type,
 geography_name, geography_use, geography_code, start_date, end_date,
 multiple_parent_flag, created_by_module, country_code, geography_element1,
 geography_element1_id, geography_element1_code, geography_element2,
 geography_element2_id, geography_element2_code, last_updated_by, creation_date,
 created_by, last_update_date, last_update_login, application_id)
 values
 (53, 1, 'STATE',
 'Puerto Rico', 'MASTER_REF', 'PR', sysdate, '27-OCT-4712',
 'N', 'HZ_GEO_HIERARCHY', 'US', 'United States',
 1, 'US', 'Puerto Rico', 53, 'PR', 1, sysdate,
 1, sysdate, 0, 222);


commit;

exception when others then

dbms_output.put_line('Failed with exception ' || sqlerrm);

end;

/