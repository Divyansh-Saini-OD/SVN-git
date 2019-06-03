CREATE OR REPLACE FUNCTION "XXPTP"."GISSLEADTIME" (p_country_cd varchar2, p_loc_id number, p_vendor_id number,
p_whse_item_cd varchar2, p_xdock_loc_id number)
RETURN number AS
v_lead_time           number;
v_loc_id              number;
BEGIN

v_lead_time := 0;

if p_whse_item_cd in ('W', 'X', 'C')
  then
  v_loc_id := p_xdock_loc_id;
  else
  v_loc_id := p_loc_id;
end if;

--dbms_output.put_line('Using loc_id :'||v_loc_id);

 begin
     select (calc_lt + po_mail_lt + ship_lt + rcpt_lt + loc_lt) lead_time
     into  v_lead_time
  from xx_gi_ss_venloc_intf_stg
  where vendor_id = p_vendor_id
    and country_cd = p_country_cd
    and loc_id     = v_loc_id
    ;

   EXCEPTION
    WHEN OTHERS
      then 
       v_lead_time   := -1;        
  end;

--dbms_output.put_line('Result of Vendor/Country/Loc :'||p_vendor_id||'-'||p_country_cd||'-'||v_loc_id||'-'||v_lead_time); 

  if v_lead_time = -1
     then
      begin
      select (calc_lt + po_mail_lt + ship_lt + rcpt_lt + loc_lt) lead_time
     into  v_lead_time
  from xx_gi_ss_ventrd_intf_stg
  where vendor_id  = p_vendor_id 
    and country_cd = p_country_cd
    ;

   EXCEPTION
    WHEN OTHERS
      then 
         v_lead_time   := 7;       
  end;
  --dbms_output.put_line('Result of Vendor/Country :'||p_vendor_id||'-'||p_country_cd||'-'||v_lead_time); 
  end if;
  
RETURN v_lead_time;
END GISSLEADTIME;