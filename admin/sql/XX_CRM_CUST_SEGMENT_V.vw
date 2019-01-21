
 CREATE OR REPLACE FORCE VIEW "APPS"."XX_CRM_CUST_SEGMENT_V" ("PARTY_ID", "SEGMENT_CODE", "SEGMENT_MEANING","SECTOR", "STATUS", "START_DATE_ACTIVE", "END_DATE_ACTIVE", "CREATION_DATE", "CREATED_BY", "LAST_UPDATE_DATE", "LAST_UPDATED_BY") AS 
  select cc.OWNER_TABLE_ID,
cc.CLASS_CODE,
SUBSTR(cust_seg.segment_desc,0,DECODE(INSTR(cust_seg.segment_desc,' -'),0,LENGTH(cust_seg.segment_desc),INSTR(cust_seg.segment_desc,' -'))),
cust_seg.sector,
cc.STATUS,
cc.START_DATE_ACTIVE,
cc.END_DATE_ACTIVE,
cc.CREATION_DATE,
cc.CREATED_BY,
cc.LAST_UPDATE_DATE,
cc.LAST_UPDATED_BY 
from apps.hz_code_assignments cc,
     (
      select v.source_value1 sector,
             v.source_value2 segment_code,
             v.source_value3 segment_desc
      from apps.xx_fin_translatedefinition d,
           apps.xx_fin_translatevalues v
      where d.translate_id = v.translate_id
      and d.translation_name = 'XX_CRM_SFDC_SEGMENT'
     ) cust_seg
where sysdate between cc.start_date_active and nvl(cc.end_date_active,TO_DATE('12/31/4712','MM/DD/RRRR'))
and cc.status = 'A'
and cc.class_category = 'Customer Segmentation'
and cc.owner_table_name = 'HZ_PARTIES'
and cust_seg.segment_code = cc.class_code;
 
