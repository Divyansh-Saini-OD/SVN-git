set serveroutput on size 999999;

declare


lv_object_version_number NUMBER ; 
lv_count_s number := 0;
lv_count_f number := 0;

    cursor c1 is
    select hou.organization_id,hou.name,hrl.location_code,
           hlt.language,hoi.org_information2,hrl.location_id,hrl.inventory_organization_id,
           hrl.object_version_number,org.operating_unit
      from hr_all_organization_units hou,
           hr_organization_information hoi,
           hr_locations_all hrl,
           hr_locations_all_tl hlt,
           org_organization_definitions org
     where hou.organization_id = hoi.organization_id
       and hoi.org_information_context = 'CLASS'
       and hoi.org_information1 = 'INV'
       and hou.location_id = hrl.location_id
       and hrl.location_id = hlt.location_id
       and hou.organization_id = org.organization_id
       and hou.type not in ('HNODE','TMPL','MAS','VAL')
       and hou.date_from <= sysdate
       and hlt.source_lang = 'US'
       and hrl.inventory_organization_id is null
       and hrl.inactive_date is null
       and hou.date_to is null
      order by hou.organization_id ;

Begin

      for crec in c1 loop
        lv_object_version_number := crec.object_version_number ;
              
        hr_location_api.update_location
            (    p_validate                       => false
                ,p_effective_date                 => sysdate 
                ,p_language_code                  => crec.language
                ,p_location_id                    => crec.location_id 
                ,p_operating_unit_id              => crec.operating_unit
                ,p_inventory_organization_id      => crec.organization_id
                ,p_object_version_number          => lv_object_version_number
            );
      
      commit;         

        IF  lv_object_version_number = crec.object_version_number THEN
           lv_count_f := lv_count_f + 1 ;
           --dbms_output.put_line('Unable to update HR Location');
        ELSE
           lv_count_s := lv_count_s + 1 ;
           --dbms_output.put_line('Updated HR Location');
        END IF;
        
      end loop;
      
      commit;     
           dbms_output.put_line('Unable to update HR Location count :'||lv_count_f);
           dbms_output.put_line('Updated HR Location count :'||lv_count_s);
Exception
  when others then
      dbms_output.put_line('Other Errors in API'||sqlerrm);
end;  
/