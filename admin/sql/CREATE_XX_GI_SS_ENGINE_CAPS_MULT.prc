create or replace PROCEDURE XX_GI_SS_ENGINE_CAPS_MULT
(
 
 p_loc_id                IN number,
 p_sku                   IN number,
 p_business_channel      IN varchar2,
 p_country_cd            IN varchar2,
 p_dept_id               IN number,
 p_class_id              IN number,
 p_sub_class             IN number,
 p_abc_class             IN varchar2,
 p_vendor_id             IN number,
 p_matrix_multiplier     OUT NOCOPY varchar2,
 p_matrix_cap            OUT NOCOPY varchar2, 
 p_multiplier_level      OUT NOCOPY number,
 p_cap_level             OUT NOCOPY number,
 p_ss_days_cap           OUT NOCOPY number,
 p_madfil_days_cap       OUT NOCOPY number,
 p_madlt_days_cap        OUT NOCOPY number,
 p_ss_days_cap_gss       OUT NOCOPY number,
 p_madfil_days_cap_gss   OUT NOCOPY number,
 p_madlt_days_cap_gss    OUT NOCOPY number,
 p_multiplier            OUT NOCOPY number, 
 p_multiplier_gss        OUT NOCOPY number,
 p_priority_name_mult    OUT NOCOPY varchar2,
 p_priority_name_cap     OUT NOCOPY varchar2,
 p_error_code            OUT NOCOPY number,
 p_error_message         OUT NOCOPY varchar2
 
 )

AS

begin

declare

--variables for FOR cursor loop
v_priority_name        varchar2(100) := 'Not found';
v_priority_matrix      varchar2(09)  := 'XXXXXXXXX';
v_priority_search_order number;
v_ss_days_cap           number;
v_madfil_days_cap       number;
v_madlt_days_cap        number;
v_ss_days_cap_gss       number;
v_madfil_days_cap_gss   number;
v_madlt_days_cap_gss    number;
v_multiplier            number; 
v_multiplier_gss        number;

--variables used in lookup of parms
s_business_channel     varchar2(02);
s_country_cd           varchar2(03);
s_loc_id               number;
s_dept_id              number;
s_class_id             number;
s_sub_class            number;
s_sku                  number;
s_abc_class            varchar2(01);
s_vendor_id            number;

--misc
cap_fnd_flg            varchar2(01);
mult_fnd_flg           varchar2(01);

--lookup cursor. Order from low to high so get the lowest level combinations first.
CURSOR SS_PARMS_SEARCH IS
select priority_name,
       priority_matrix,
       priority_search_order
      from xx_gi_ss_parms_priority
      where priority_matrix <> 'NNNNNNNNN'
        and active_flg       = 'Y'
      order by priority_search_order;
         
BEGIN

begin
p_matrix_multiplier     := 'XXXXXXXXX';
p_matrix_cap            := 'XXXXXXXXX';
p_multiplier_level      := 99;
p_cap_level             := 99;
p_error_code            := 0;
p_error_message         := null;
p_ss_days_cap           := 0;
p_madfil_days_cap       := 0;
p_madlt_days_cap        := 0;
p_ss_days_cap_gss       := 0;
p_madfil_days_cap_gss   := 0;
p_madlt_days_cap_gss    := 0;
p_multiplier            := 0; 
p_multiplier_gss        := 0;
p_priority_name_cap     := null;
p_priority_name_mult    := null;
v_ss_days_cap           := 0;
v_madfil_days_cap       := 0;
v_madlt_days_cap        := 0;
v_multiplier            := 0;
v_ss_days_cap_gss       := 0;
v_madfil_days_cap_gss   := 0;
v_madlt_days_cap_gss    := 0;
v_multiplier            := 0;
v_multiplier_gss        := 0;
v_priority_matrix       := 'NNNNNNNNN';
v_priority_search_order := 0;
end;

FOR v_SS_PARMS_SEARCH IN SS_PARMS_SEARCH LOOP
   
   v_priority_name         := v_SS_PARMS_SEARCH.priority_name;
   v_priority_matrix       := v_SS_PARMS_SEARCH.priority_matrix;
   v_priority_search_order := v_SS_PARMS_SEARCH.priority_search_order;
   
  dbms_output.put_line('SS Cursor Results :'||v_priority_name||'-'||v_priority_matrix
   ||'-'||v_priority_search_order);
   
   begin
   s_business_channel     := '  ';
   s_country_cd           := '   ';
   s_loc_id               := 0;
   s_dept_id              := 0;
   s_class_id             := 0;
   s_sub_class            := 0;
   s_sku                  := 0;
   s_abc_class            := ' ';
   s_vendor_id            := 0;
   end;
   
   begin
   if substr(v_priority_matrix,1,1) = 'Y'
     then
      s_business_channel := nvl(upper(p_business_channel),'  ');
   end if;
    if substr(v_priority_matrix,2,1) = 'Y'
     then
      s_country_cd       := nvl(upper(p_country_cd),'   ');
   end if;
     if substr(v_priority_matrix,3,1) = 'Y'
     then
      s_loc_id := nvl(p_loc_id,0);
   end if;
    if substr(v_priority_matrix,4,1) = 'Y'
     then
      s_dept_id          := nvl(p_dept_id,0);
   end if;
    if substr(v_priority_matrix,5,1) = 'Y'
     then
      s_class_id         := nvl(p_class_id,0);
   end if;
    if substr(v_priority_matrix,6,1) = 'Y'
     then
      s_sub_class        := nvl(p_sub_class,0);
   end if;  
     if substr(v_priority_matrix,7,1) = 'Y'
     then
      s_sku             := nvl(p_sku,0);
   end if;
    if substr(v_priority_matrix,8,1) = 'Y'
     then
      s_vendor_id        := nvl(p_vendor_id,0);
   end if;
     if substr(v_priority_matrix,9,1) = 'Y'
     then
      s_abc_class := nvl(upper(p_abc_class),'N');
   end if;
   end;
  
  begin 
  v_ss_days_cap         := 0;
  v_madfil_days_cap     := 0;
  v_madlt_days_cap      := 0;
  v_ss_days_cap_gss     := 0;
  v_madfil_days_cap_gss := 0;
  v_madlt_days_cap_gss  := 0;
  cap_fnd_flg           := 'N';
  end;  
 
 --dbms_output.put_line('Cap_Mult Lookup '||v_priority_matrix||'-'||v_priority_name);
-- dbms_output.put_line('Search Values '||s_business_channel||'-'||s_country_cd||'-'||s_loc_id||'-'||s_dept_id||'-'||s_class_id||'-'||s_sub_class||'-'||s_sku||'-'||s_vendor_id||'-'||s_abc_class);
 
 begin
   select ss_days_cap,
          madfil_days_cap,
          madlt_days_cap,
          ss_days_cap_gss,
          madfil_days_cap_gss,
          madlt_days_cap_gss
        into v_ss_days_cap,
           v_madfil_days_cap,
           v_madlt_days_cap,
           v_ss_days_cap_gss,
           v_madfil_days_cap_gss,
           v_madlt_days_cap_gss
         from  xx_gi_ss_caps_mult_master 
     where business_channel = s_business_channel
       and country_cd       = s_country_cd
       and loc_id           = s_loc_id
       and dept_id          = s_dept_id
       and class_id         = s_class_id
       and sub_class_id     = s_sub_class
       and sku              = s_sku
       and vendor_id        = s_vendor_id
       and abc_class        = s_abc_class
       and type_cd         in ('C', 'B')
       and trunc(start_dt)  =
       (select max(start_dt)
       from  xx_gi_ss_caps_mult_master 
     where business_channel = s_business_channel
       and country_cd       = s_country_cd
       and loc_id           = s_loc_id
       and dept_id          = s_dept_id
       and class_id         = s_class_id
       and sub_class_id     = s_sub_class
       and sku              = s_sku
       and vendor_id        = s_vendor_id
       and abc_class        = s_abc_class
       and type_cd         in ('C', 'B')
       and trunc(sysdate) >= trunc(start_dt) 
       )
         ;

 cap_fnd_flg           := 'Y';
 p_matrix_cap          := v_priority_matrix;
 p_cap_level           := v_priority_search_order;
 p_ss_days_cap         := v_ss_days_cap;
 p_madfil_days_cap     := v_madfil_days_cap;
 p_madlt_days_cap      := v_madlt_days_cap;
 p_ss_days_cap_gss     := v_ss_days_cap_gss;
 p_madfil_days_cap_gss := v_madfil_days_cap_gss;
 p_madlt_days_cap_gss  := v_madlt_days_cap_gss;
 p_priority_name_cap   := v_priority_name;
     
  EXIT;
  
 EXCEPTION
    WHEN OTHERS
      then 
        cap_fnd_flg := 'N';
        --dbms_output.put_line('Parms not found '||sqlcode||'-'||sqlerrm);
      end;
    
END LOOP;

FOR v_SS_PARMS_SEARCH IN SS_PARMS_SEARCH LOOP
   
   v_priority_name         := v_SS_PARMS_SEARCH.priority_name;
   v_priority_matrix       := v_SS_PARMS_SEARCH.priority_matrix;
   v_priority_search_order := v_SS_PARMS_SEARCH.priority_search_order;
   
  --dbms_output.put_line('SS Cursor Results :'||v_priority_name||'-'||v_priority_matrix
  -- ||'-'||v_priority_search_order);
   
   begin
   s_business_channel     := '  ';
   s_country_cd           := '   ';
   s_loc_id               := 0;
   s_dept_id              := 0;
   s_class_id             := 0;
   s_sub_class            := 0;
   s_sku                  := 0;
   s_abc_class            := ' ';
   s_vendor_id            := 0;
   end;
   
   begin
   if substr(v_priority_matrix,1,1) = 'Y'
     then
      s_business_channel := nvl(upper(p_business_channel),'  ');
   end if;
    if substr(v_priority_matrix,2,1) = 'Y'
     then
      s_country_cd       := nvl(upper(p_country_cd),'   ');
   end if;
     if substr(v_priority_matrix,3,1) = 'Y'
     then
      s_loc_id := nvl(p_loc_id,0);
   end if;
    if substr(v_priority_matrix,4,1) = 'Y'
     then
      s_dept_id          := nvl(p_dept_id,0);
   end if;
    if substr(v_priority_matrix,5,1) = 'Y'
     then
      s_class_id         := nvl(p_class_id,0);
   end if;
    if substr(v_priority_matrix,6,1) = 'Y'
     then
      s_sub_class        := nvl(p_sub_class,0);
   end if;  
     if substr(v_priority_matrix,7,1) = 'Y'
     then
      s_sku             := nvl(p_sku,0);
   end if;
    if substr(v_priority_matrix,8,1) = 'Y'
     then
      s_vendor_id        := nvl(p_vendor_id,0);
   end if;
     if substr(v_priority_matrix,9,1) = 'Y'
     then
      s_abc_class := nvl(upper(p_abc_class),'N');
   end if;
   end;
  
  begin 
  v_multiplier          := 0;
  v_multiplier_gss      := 0;
  mult_fnd_flg          := 'N';
  end;  
 
 --dbms_output.put_line('Mult Lookup '||v_priority_matrix||'-'||v_priority_name);
 --dbms_output.put_line('Search Values '||s_business_channel||'-'||s_country_cd||'-'||s_loc_id||'-'||s_dept_id||'-'||s_class_id||'-'||s_sub_class||'-'||s_sku||'-'||s_vendor_id||'-'||s_abc_class);
 
 begin
   select multiplier,
          multiplier_gss
         into v_multiplier,
           v_multiplier_gss
         from  xx_gi_ss_caps_mult_master 
     where business_channel = s_business_channel
       and country_cd       = s_country_cd
       and loc_id           = s_loc_id
       and dept_id          = s_dept_id
       and class_id         = s_class_id
       and sub_class_id     = s_sub_class
       and sku              = s_sku
       and vendor_id        = s_vendor_id
       and abc_class        = s_abc_class
       and type_cd         in ('M', 'B')
       and trunc(start_dt)  =
       (select max(start_dt)
       from  xx_gi_ss_caps_mult_master 
     where business_channel = s_business_channel
       and country_cd       = s_country_cd
       and loc_id           = s_loc_id
       and dept_id          = s_dept_id
       and class_id         = s_class_id
       and sub_class_id     = s_sub_class
       and sku              = s_sku
       and vendor_id        = s_vendor_id
       and abc_class        = s_abc_class
       and type_cd         in ('M', 'B')
       and trunc(sysdate) >= trunc(start_dt) 
       )
         ;

 mult_fnd_flg          := 'Y';
 p_matrix_multiplier   := v_priority_matrix;
 p_multiplier_level    := v_priority_search_order;
 p_multiplier          := v_multiplier;
 p_multiplier_gss      := v_multiplier_gss;
 p_priority_name_mult  := v_priority_name;
     
  EXIT;
  
 EXCEPTION
    WHEN OTHERS
      then 
        mult_fnd_flg := 'N';
        --dbms_output.put_line('Parms not found '||sqlcode||'-'||sqlerrm);
      end;
    
END LOOP;

 if cap_fnd_flg = 'N'
   then
    p_matrix_cap          := 'XXXXXXXXX';
    p_cap_level           := 99;
    p_ss_days_cap         := 28;
    p_madfil_days_cap     := 10;
    p_madlt_days_cap      := 4;
    p_ss_days_cap_gss     := 28;
    p_madfil_days_cap_gss := 10;
    p_madlt_days_cap_gss  := 4;
    p_priority_name_cap   := 'Default Caps';
end if;

 if mult_fnd_flg = 'N'
   then
     p_error_code := 9999;
     p_error_message := 'Multiplier not found';
 end if;

END;
 
end XX_GI_SS_ENGINE_CAPS_MULT;
