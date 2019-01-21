
  CREATE OR REPLACE FORCE VIEW "APPS"."XX_CRM_CUST_LOYALTY_V" ("PARTY_ID", "LOY_CODE", "LOY_MEANING", "STATUS", "START_DATE_ACTIVE", "END_DATE_ACTIVE", "CREATION_DATE", "CREATED_BY", "LAST_UPDATE_DATE", "LAST_UPDATED_BY") AS 
  select cc.OWNER_TABLE_ID,
cc.CLASS_CODE,
cust_loy.meaning,
cc.STATUS,
cc.START_DATE_ACTIVE,
cc.END_DATE_ACTIVE,
cc.CREATION_DATE,
cc.CREATED_BY,
cc.LAST_UPDATE_DATE,
cc.LAST_UPDATED_BY 
from apps.hz_code_assignments cc,
      (
       SELECT lookup_code,meaning FROM APPS.FND_LOOKUP_VALUES
       WHERE LOOKUP_TYPE = 'Customer Loyalty'
       AND enabled_flag = 'Y'
      ) cust_loy
where sysdate between cc.start_date_active
      and nvl(cc.end_date_active,TO_DATE('12/31/4712','MM/DD/RRRR')) and cc.status = 'A'
      and cc.class_category = 'Customer Loyalty'
      and cc.owner_table_name = 'HZ_PARTIES'
      and cc.class_code = cust_loy.lookup_code
      and cc.primary_flag = 'Y';
 
