SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 

Delete from xxfin.xx_fin_translatevalues 
where translate_id = (	select translate_id 
			from   apps.xx_fin_translatedefinition 
			where  TRANSLATION_NAME like '%AR PURGE SCHEDULE');

Delete from xxfin.XX_FIN_TRANSLATERESPONSIBILITY 
where translate_id = (	select translate_id 
			from   apps.xx_fin_translatedefinition 
			where  TRANSLATION_NAME like '%AR PURGE SCHEDULE');

Delete from xxfin.xx_fin_translatedefinition
where TRANSLATION_NAME like '%AR PURGE SCHEDULE';

--*
--* Create TRANSLATEDEFINITION entry for AR PURGE SCHEDULE
--*
insert into xxfin.xx_fin_translatedefinition 
       (TRANSLATE_ID
       ,TRANSLATION_NAME
       ,PURPOSE
       ,TRANSLATE_DESCRIPTION
       ,RELATED_MODULE
       ,SOURCE_FIELD1
       ,SOURCE_FIELD2
       ,SOURCE_FIELD3
       ,SOURCE_FIELD4
       ,SOURCE_FIELD5
       ,CREATION_DATE
       ,CREATED_BY
       ,LAST_UPDATE_DATE
       ,LAST_UPDATED_BY
       ,LAST_UPDATE_LOGIN
       ,START_DATE_ACTIVE
       ,ENABLED_FLAG
       ,DO_NOT_REFRESH)
select	XX_FIN_TRANSLATEDEFINITION_S.nextval
       ,ou.name||' - AR PURGE SCHEDULE'
       ,'DEFAULT'
       ,'AR Purge Schedule Control Data'
       ,'AR'
       ,'Date-Range Type'
       ,'Start Date'
       ,'Increment'
       ,'End Date'
       ,'Status'
       ,sysdate
       ,-1
       ,sysdate
       ,-1
       ,-1
       ,sysdate
       ,'Y'
       ,'N'
from HR_OPERATING_UNITS ou;

--*
--* Create XX_FIN_TRANSLATERESPONSIBILITY for AR PURGE SCHEDULE
--*
Insert into xxfin.XX_FIN_TRANSLATERESPONSIBILITY 
      (TRANSLATE_ID
      ,Responsibility_id
      ,CREATION_DATE
      ,CREATED_BY
      ,LAST_UPDATE_DATE
      ,LAST_UPDATED_BY
      ,LAST_UPDATE_LOGIN
      ,SECURITY_VALUE_ID) 
select	 d.translate_id
	,r.responsibility_id
	,sysdate
	,-1
	,sysdate
	,-1
	,-1
	,XX_FIN_TRANSLATERESPONSIBIL_S.NEXTVAL
from fnd_responsibility_vl r, xx_fin_translatedefinition d
where (r.responsibility_name like 'OD (%) AR Setup_IT' or r.responsibility_name like 'OD (%) AR Batch Jobs')
and d.TRANSLATION_NAME like '% - AR PURGE SCHEDULE';

--*
--* Create xx_fin_translatevalues for AR PURGE SCHEDULE
--*
Insert into xxfin.xx_fin_translatevalues 
      (TRANSLATE_ID
      ,SOURCE_VALUE1
      ,SOURCE_VALUE2
      ,SOURCE_VALUE3
      ,SOURCE_VALUE4
      ,CREATION_DATE
      ,CREATED_BY
      ,LAST_UPDATE_DATE
      ,LAST_UPDATED_BY
      ,START_DATE_ACTIVE
      ,ENABLED_FLAG
      ,TRANSLATE_VALUE_ID) 
Select translate_id
      ,'1'
      ,'28-JUN-2009'
      ,'7'
      ,'25-JUL-2009'
      ,sysdate
      ,-1
      ,sysdate
      ,-1
      ,sysdate
      ,'Y'
      ,XX_FIN_TRANSLATEVALUES_S.NEXTVAL
from   apps.xx_fin_translatedefinition 
where  TRANSLATION_NAME like '% - AR PURGE SCHEDULE';

Insert into xxfin.xx_fin_translatevalues 
      (TRANSLATE_ID
      ,SOURCE_VALUE1
      ,SOURCE_VALUE2
      ,SOURCE_VALUE3
      ,SOURCE_VALUE4
      ,CREATION_DATE
      ,CREATED_BY
      ,LAST_UPDATE_DATE
      ,LAST_UPDATED_BY
      ,START_DATE_ACTIVE
      ,ENABLED_FLAG
      ,TRANSLATE_VALUE_ID) 
Select translate_id
      ,'2'
      ,'28-JUN-2009'
      ,'14'
      ,'25-JUL-2009'
      ,sysdate
      ,-1
      ,sysdate
      ,-1
      ,sysdate
      ,'Y'
      ,XX_FIN_TRANSLATEVALUES_S.NEXTVAL
from   apps.xx_fin_translatedefinition 
where  TRANSLATION_NAME like '% - AR PURGE SCHEDULE';

Insert into xxfin.xx_fin_translatevalues 
      (TRANSLATE_ID
      ,SOURCE_VALUE1
      ,SOURCE_VALUE2
      ,SOURCE_VALUE3
      ,SOURCE_VALUE4
      ,CREATION_DATE
      ,CREATED_BY
      ,LAST_UPDATE_DATE
      ,LAST_UPDATED_BY
      ,START_DATE_ACTIVE
      ,ENABLED_FLAG
      ,TRANSLATE_VALUE_ID) 
Select translate_id
      ,'3'
      ,'28-JUN-2009'
      ,'28'
      ,'25-JUL-2009'
      ,sysdate
      ,-1
      ,sysdate
      ,-1
      ,sysdate
      ,'Y'
      ,XX_FIN_TRANSLATEVALUES_S.NEXTVAL
from   apps.xx_fin_translatedefinition 
where  TRANSLATION_NAME like '% - AR PURGE SCHEDULE';

COMMIT;
