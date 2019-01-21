
CREATE OR REPLACE FORCE VIEW "APPS"."XX_CRM_CUST_SIC_CODE_V" ("PARTY_ID", "SIC_CODE", "STATUS", "START_DATE_ACTIVE", "END_DATE_ACTIVE", "CREATION_DATE", "CREATED_BY", "LAST_UPDATE_DATE", "LAST_UPDATED_BY") AS 
select OWNER_TABLE_ID,
CLASS_CODE,
STATUS,
START_DATE_ACTIVE,
END_DATE_ACTIVE,
CREATION_DATE,
CREATED_BY,
LAST_UPDATE_DATE,
LAST_UPDATED_BY
FROM
(
select OWNER_TABLE_ID,
CLASS_CODE,
STATUS,
START_DATE_ACTIVE,
END_DATE_ACTIVE,
CREATION_DATE,
CREATED_BY,
LAST_UPDATE_DATE,
LAST_UPDATED_BY,
rank() over (partition by owner_table_id order by creation_date desc) latest
from apps.hz_code_assignments cc
where sysdate between start_date_active
      and nvl(end_date_active,TO_DATE('12/31/4712','MM/DD/RRRR')) and status = 'A'
      and class_category = '1987 SIC'
      and owner_table_name = 'HZ_PARTIES'
      and actual_content_source = 'GDW'
) res WHERE res.latest = 1;