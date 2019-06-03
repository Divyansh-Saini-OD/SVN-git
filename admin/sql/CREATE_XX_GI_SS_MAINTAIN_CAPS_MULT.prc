create or replace PROCEDURE XX_GI_SS_MAINTAIN_CAPS_MULT
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
 p_start_date            IN varchar2,
 p_ss_days_cap           IN number,
 p_madfil_days_cap       IN number,
 p_madlt_days_cap        IN number,
 p_ss_days_cap_gss       IN number,
 p_madfil_days_cap_gss   IN number,
 p_madlt_days_cap_gss    IN number,
 p_multiplier            IN number, 
 p_multiplier_gss        IN number,
 p_user_id               IN number,
 p_user_login            IN number,
 p_priority_order        OUT NOCOPY number,
 p_priority_name         OUT NOCOPY varchar2,
 p_priority_matrix       OUT NOCOPY varchar2,
 p_update_type_cd        OUT NOCOPY varchar2,
 p_type_cd               OUT NOCOPY varchar2,
 p_error_code            OUT NOCOPY number,
 p_error_message         OUT NOCOPY varchar2
 
 )

AS

begin

declare

--variables used in validate hierarchy call
 v_business_channel varchar2(02);
 v_country_cd       varchar2(03);
 v_loc_id           number;
 v_dept_id          number;
 v_class_id         number;
 v_sub_class        number;
 v_sku              number;
 v_abc_class        varchar2(01);
 v_vendor_id        number;
 v_matrix_result    varchar2(09);
 v_search_order     number;
 v_hierarchy_name   varchar2(50);
 v_error_code       number;
 v_error_message    varchar2(100);
 v_proc_name        varchar2(30) := 'XX_GI_SS_MAINTAIN_CAPS_MULT';
 
--misc
v_cap_fnd_flg          varchar2(01);
v_mult_fnd_flg         varchar2(01);
v_type_cd              varchar2(01);
v_type_cd_new          varchar2(01);
v_ss_days_cap          number;
v_madfil_days_cap      number;
v_madlt_days_cap       number;
v_ss_days_cap_gss      number;
v_madfil_days_cap_gss  number;
v_madlt_days_cap_gss   number;
v_multiplier           number; 
v_multiplier_gss       number;
v_start_date           date;
         
BEGIN

begin

p_error_code            := 0;
p_error_message         := null;

end;
  
if p_start_date is null
  then
  v_start_date         := trunc(sysdate);
else
 v_start_date          := to_date(p_start_date,'YYYY-MM-DD');
end if;

v_ss_days_cap          := nvl(p_ss_days_cap,0);
v_madfil_days_cap      := nvl(p_madfil_days_cap,0);
v_madlt_days_cap       := nvl(p_madlt_days_cap,0);
v_ss_days_cap_gss      := nvl(p_ss_days_cap_gss,0);
v_madfil_days_cap_gss  := nvl(p_madfil_days_cap_gss,0);
v_madlt_days_cap_gss   := nvl(p_madlt_days_cap_gss,0);
v_multiplier           := nvl(p_multiplier,0);
v_multiplier_gss       := nvl(p_multiplier_gss,0);

v_type_cd_new          := 'B';
v_cap_fnd_flg          := 'N';
v_mult_fnd_flg         := 'N';

if v_multiplier     > 0
or v_multiplier_gss > 0
 then
 v_mult_fnd_flg        := 'Y';
end if;

if v_ss_days_cap         > 0
or v_madfil_days_cap     > 0
or v_madlt_days_cap      > 0
or v_ss_days_cap_gss     > 0
or v_madfil_days_cap_gss > 0
or v_madlt_days_cap_gss  > 0 
 then
 v_cap_fnd_flg        := 'Y';
end if;

if v_mult_fnd_flg = 'Y'
and v_cap_fnd_flg = 'N'
then
v_type_cd_new := 'M';
end if;
  
if v_mult_fnd_flg = 'N'
and v_cap_fnd_flg = 'Y'
then
v_type_cd_new := 'C';
end if;

--dbms_output.put_line('New type code and start date are :'||v_type_cd_new||'-'||v_start_date);

begin
 v_business_channel := p_business_channel;
 v_country_cd       := p_country_cd;
 v_loc_id           := p_loc_id;
 v_dept_id          := p_dept_id;
 v_class_id         := p_class_id;
 v_sub_class        := p_sub_class;
 v_sku              := p_sku;
 v_abc_class        := p_abc_class;
 v_vendor_id        := p_vendor_id;
 v_matrix_result    := 'NNNNNNNNN';
 v_search_order     := 0;  
 v_hierarchy_name   := ' ';
 v_error_code       := 0;  
 v_error_message    := ' ';
end;
   
  XX_GI_SS_VALIDATE_HIERARCHY
  (
  v_business_channel 
 ,v_country_cd       
 ,v_loc_id           
 ,v_dept_id          
 ,v_class_id         
 ,v_sub_class     
 ,v_sku              
 ,v_abc_class        
 ,v_vendor_id        
 ,v_matrix_result    
 ,v_search_order     
 ,v_hierarchy_name   
 ,v_error_code       
 ,v_error_message
 )
 ;

p_priority_order  := v_search_order;
p_priority_name   := v_hierarchy_name;
p_priority_matrix := v_matrix_result;

--dbms_output.put_line('Output from call is :'||v_search_order||'-'||v_hierarchy_name||'-'||v_matrix_result);

 if v_error_code <> 0
    then
    -- dbms_output.put_line('Call to validate failed :'||v_error_code||v_error_message);
     p_error_code    := v_error_code;
     p_error_message := v_error_message;
 end if;
 
 v_business_channel := nvl(p_business_channel,'  ');
 v_country_cd       := nvl(p_country_cd,'   ');
 v_loc_id           := nvl(p_loc_id,0);
 v_dept_id          := nvl(p_dept_id,0);
 v_class_id         := nvl(p_class_id,0);
 v_sub_class        := nvl(p_sub_class,0);
 v_sku              := nvl(p_sku,0);
 v_abc_class        := nvl(p_abc_class,' ');
 v_vendor_id        := nvl(p_vendor_id,0);
 
 if p_error_code = 0
   then
 begin
   select type_cd
     into v_type_cd
         from  xx_gi_ss_caps_mult_master 
     where business_channel = v_business_channel
       and country_cd       = v_country_cd
       and loc_id           = v_loc_id
       and dept_id          = v_dept_id
       and class_id         = v_class_id
       and sub_class_id     = v_sub_class
       and sku              = v_sku
       and vendor_id        = v_vendor_id
       and abc_class        = v_abc_class
       and trunc(start_dt)  = trunc(v_start_date)
      ;

 EXCEPTION
    WHEN OTHERS
      then 
        v_type_cd := 'N';
      end;
 end if;

--dbms_output.put_line('New or Existing type code is :'||v_type_cd);
p_type_cd := v_type_cd_new;

if v_type_cd = 'N'
and p_error_code = 0
 then
  begin
  p_update_type_cd := 'I';
  insert into xx_gi_ss_caps_mult_master
  (business_channel
  ,country_cd
  ,loc_id
  ,dept_id
  ,class_id
  ,sub_class_id
  ,sku
  ,abc_class
  ,vendor_id
  ,start_dt
  ,ss_days_cap
  ,madfil_days_cap
  ,madlt_days_cap
  ,ss_days_cap_gss
  ,madfil_days_cap_gss
  ,madlt_days_cap_gss
  ,multiplier
  ,multiplier_gss
  ,priority_order
  ,type_cd
  ,created_by
  ,creation_date
  ,last_updated_by
  ,last_update_date
  ,last_update_login)
  values
 (v_business_channel
,v_country_cd
,v_loc_id
,v_dept_id
,v_class_id
,0
,v_sku
,v_abc_class
,v_vendor_id
,trunc(v_start_date)
,v_ss_days_cap 
,v_madfil_days_cap
,v_madlt_days_cap 
,v_ss_days_cap_gss
,v_madfil_days_cap_gss
,v_madlt_days_cap_gss
,v_multiplier
,v_multiplier_gss
,p_priority_order
,v_type_cd_new
,p_user_id
,sysdate
,0
,null
,0
)
  ;
   EXCEPTION
    WHEN OTHERS
      then 
        p_error_code    := sqlcode;
        p_error_message := v_proc_name||sqlerrm;
  end;
  
end if;

if v_type_cd <> 'N'
and p_error_code = 0
 then
  begin
    p_update_type_cd := 'U';
    update xx_gi_ss_caps_mult_master
    set ss_days_cap           = v_ss_days_cap
       ,madfil_days_cap       = v_madfil_days_cap
       ,madlt_days_cap        = v_madlt_days_cap
       ,ss_days_cap_gss       = v_ss_days_cap_gss
       ,madfil_days_cap_gss   = v_madfil_days_cap_gss
       ,madlt_days_cap_gss    = v_madlt_days_cap_gss
       ,multiplier            = v_multiplier
       ,multiplier_gss        = v_multiplier_gss
       ,type_cd               = v_type_cd_new
       ,last_update_date      = sysdate
       ,last_updated_by       = p_user_id
       ,last_update_login     = p_user_login
       where business_channel = v_business_channel
       and country_cd         = v_country_cd
       and loc_id             = v_loc_id
       and dept_id            = v_dept_id
       and class_id           = v_class_id
       and sub_class_id       = v_sub_class
       and sku                = v_sku
       and vendor_id          = v_vendor_id
       and abc_class          = v_abc_class
       and trunc(start_dt)    = trunc(v_start_date);
       EXCEPTION
    WHEN OTHERS
      then 
        p_error_code    := sqlcode;
        p_error_message := v_proc_name||sqlerrm;
  end;
end if;

if p_error_code = 0
then
 commit;
end if;

END;
 
end XX_GI_SS_MAINTAIN_CAPS_MULT;
