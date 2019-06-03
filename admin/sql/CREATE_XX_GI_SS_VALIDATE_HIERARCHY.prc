create or replace PROCEDURE XX_GI_SS_VALIDATE_HIERARCHY 
(
 p_business_channel IN varchar2,
 p_country_cd       IN varchar2,
 p_loc_id           IN number,
 p_dept_id          IN number,
 p_class_id         IN number,
 p_sub_class_id     IN number,
 p_sku              IN number,
 p_abc_class        IN varchar2,
 p_vendor_id        IN number,
 p_matrix_result    OUT NOCOPY varchar2,
 p_search_order     OUT NOCOPY number,
 p_hierarchy_name   OUT NOCOPY varchar2,
 p_error_code       OUT NOCOPY number,
 p_error_message    OUT NOCOPY varchar2
)

AS

begin

declare

p_matrix               varchar2(09) := 'NNNNNNNNN';
p_business_channel_flg varchar2(01) := 'N';
p_country_cd_flg       varchar2(01) := 'N';
p_loc_id_flg           varchar2(01) := 'N';
p_dept_id_flg          varchar2(01) := 'N';
p_class_id_flg         varchar2(01) := 'N';
p_sub_class_id_flg     varchar2(01) := 'N';
p_sku_flg              varchar2(01) := 'N';
p_abc_class_flg        varchar2(01) := 'N';
p_vendor_id_flg        varchar2(01) := 'N';
v_proc_name            varchar2(30) := 'XX_GI_SS_VALIDATE_HIERARCHY';

BEGIN

p_error_code     := 0;
p_search_order   := 0;
p_error_message  := NULL;
p_hierarchy_name := NULL;
p_matrix_result  := p_matrix;

if p_business_channel is not null
  then
    p_business_channel_flg := 'Y';
end if;
if p_country_cd is not null
  then
    p_country_cd_flg := 'Y';
end if;
if p_loc_id is not null
  then
    p_loc_id_flg := 'Y';
end if;
if p_dept_id is not null
  then
    p_dept_id_flg := 'Y';
end if;
if p_class_id is not null
  then
    p_class_id_flg := 'Y';
end if;
if p_sub_class_id is not null
  then
    p_sub_class_id_flg := 'Y';
end if;
if p_sku is not null
  then
    p_sku_flg := 'Y';
end if;
if p_abc_class is not null
  then
    p_abc_class_flg := 'Y';
end if;
if p_vendor_id is not null
  then
    p_vendor_id_flg := 'Y';
end if;

p_matrix := p_business_channel_flg||
            p_country_cd_flg||        
            p_loc_id_flg||            
            p_dept_id_flg||          
            p_class_id_flg||          
            p_sub_class_id_flg||     
            p_sku_flg||               
            p_vendor_id_flg||         
            p_abc_class_flg;
            
select priority_search_order,
       priority_name
   into p_search_order,
        p_hierarchy_name
from  xx_gi_ss_parms_priority 
where priority_matrix = p_matrix
  and active_flg      = 'Y'
;

p_matrix_result := p_matrix;

if P_search_order = 99
  then
   p_error_code    :=  9999;
   p_error_message := v_proc_name||' Hierarchy Combination Not Entered';
end if;
 
   EXCEPTION
    WHEN OTHERS
      then 
        p_search_order := 9999;
        p_error_code   := sqlcode;
        p_error_message :=v_proc_name||' Invalid Hierarchy Combination: '||p_matrix||'-'||sqlerrm;
      end;
    
end XX_GI_SS_VALIDATE_HIERARCHY;
