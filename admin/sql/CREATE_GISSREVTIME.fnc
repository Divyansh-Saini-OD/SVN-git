  CREATE OR REPLACE FUNCTION "XXPTP"."GISSREVTIME" (p_country_cd varchar2, p_loc_id number, p_vendor_id number,
p_whse_item_cd varchar2, p_xdock_loc_id number)
RETURN number AS
v_review_time           number;
v_review_time_lvl       number;
v_loc_id                number;
BEGIN

if p_whse_item_cd in ('W', 'X', 'C')
  then
  v_loc_id := p_xdock_loc_id;
  else
  v_loc_id := p_loc_id;
end if;

v_review_time   := 7;

 begin
     select review_time, 1
  into  v_review_time, v_review_time_lvl
  from xx_gi_ss_venrvt_intf_stg
  where vendor_id  = p_vendor_id
    and country_cd = p_country_cd
    and loc_id     = v_loc_id
    ;

   EXCEPTION
    WHEN OTHERS
      then 
       v_review_time   := -1;        
  end;

--dbms_output.put_line('Result of Vendor/Country/Loc :'||p_vendor_id||'-'||p_country_cd||'-'||p_loc_id||'-'||v_review_time); 

  if v_review_time = -1
     then
      begin
     select review_time, 2
  into  v_review_time, v_review_time_lvl
  from xx_gi_ss_venrvt_intf_stg
  where vendor_id  = p_vendor_id
    ;

   EXCEPTION
    WHEN OTHERS
      then 
         v_review_time   := -1;       
  end;
  end if;
  
--dbms_output.put_line('Result of Vendor :'||p_vendor_id||'-'||v_review_time);

 if v_review_time = -1
     then
      begin
     select review_time, 3
  into  v_review_time, v_review_time_lvl
  from xx_gi_ss_venrvt_intf_stg
  where loc_id     = v_loc_id
    and country_cd = p_country_cd
    ;

   EXCEPTION
    WHEN OTHERS
      then 
       v_review_time   := 7;    
  end;
  end if;

--dbms_output.put_line('Result of Country/Loc :'||p_country_cd||'-'||p_loc_id||'-'||v_review_time);

RETURN v_review_time;
END GISSREVTIME;