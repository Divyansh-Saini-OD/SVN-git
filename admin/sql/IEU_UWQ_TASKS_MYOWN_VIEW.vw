   SET SHOW         OFF
   SET VERIFY       OFF
   SET ECHO         OFF
   SET TAB          OFF
   SET FEEDBACK     ON

-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                       Wipro Technologies                                    |
-- +=============================================================================+
-- | Name : IEU_UWQ_TASKS_MYOWN_V                                                |
-- | Description : Replacing the Standard view with three new columns            |
-- |               Cost,Customer Number and  Customer Account                    |
-- |                                                                             |
-- |                                                                             |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |Version   Date          Author                Remarks                        |
-- |=======   ==========   ================      ==============================  |
-- | 1.0     24-Oct-2007   Chaitanya Nath        Added the columns Cost,         |
-- |                                             Customer_Number and             |
-- |                                             Customer_Account to the STD View|
-- | 1.1     01-Apr-2008   Madankumar J          Modified to include the column  |
-- |                                             country_code                    |
-- +=============================================================================+

CREATE OR REPLACE VIEW "APPS"."IEU_UWQ_TASKS_MYOWN_V" ("IEU_OBJECT_FUNCTION"
                                                      ,"IEU_OBJECT_PARAMETERS"
                                                      ,"IEU_MEDIA_TYPE_UUID"
                                                      ,"IEU_PARAM_PK_COL"
                                                      ,"IEU_PARAM_PK_VALUE"
                                                      ,"RESOURCE_ID"
                                                      ,"RESOURCE_TYPE"
                                                      ,"TASK_ID"
                                                      ,"TASK_NUMBER"
                                                      ,"TASK_NAME"
                                                      ,"TASK_TYPE"
                                                      ,"TASK_STATUS"
                                                      ,"TASK_PRIORITY"
                                                      ,"PLANNED_START_DATE"
                                                      ,"PLANNED_END_DATE"
                                                      ,"SCHEDULED_START_DATE"
                                                      ,"SCHEDULED_END_DATE"
                                                      ,"ACTUAL_START_DATE"
                                                      ,"ACTUAL_END_DATE"
                                                      ,"SOURCE_OBJECT_TYPE"
                                                      ,"SOURCE_OBJECT_TYPE_CODE"
                                                      ,"SOURCE_OBJECT_ID"
                                                      ,"CUSTOMER_NAME"
                                                      ,"GLOBAL_TIMEZONE_NAME"
                                                      ,"GMT_DEVIATION_HOURS"
                                                      ,"DURATION"
                                                      ,"DURATION_UOM"
                                                      ,"ESCALATION_LEVEL"
                                                      ,"TASK_STATUS_ID"
                                                      ,"TASK_TYPE_ID"
                                                      ,"PRIMARY_PHONE"
                                                      ,"PRIMARY_EMAIL"
                                                      ,"CREATION_DATE"
                                                      ,"LAST_UPDATE_DATE"
                                                      ,"IEU_ACTION_OBJECT_CODE"
                                                      ,"DESCRIPTION"
                                                      ,"SOURCE_DOCUMENT_NAME"
                                                      ,"OBJECT_VERSION_NUMBER"
                                                      ,"SHORT_PAY_AMOUNT"
                                                      ,"CUSTOMER_NUMBER"
                                                      ,"CUSTOMER_ACCOUNT"
                                                      ,"COUNTRY_CODE")--Country code Included
AS
SELECT b.object_Function IEU_OBJECT_FUNCTION,
       b.object_parameters IEU_OBJECT_PARAMETERS,
       '' IEU_MEDIA_TYPE_UUID, 'Source_Object_id' IEU_PARAM_PK_COL, 
       to_char(Source_object_id) IEU_PARAM_PK_VALUE,
       a.owner_id Resource_id,
       a.owner_type_code Resource_type,
       a.Task_id, 
       Task_Number,
       tasks_tl.Task_Name,
       typ.name Task_Type, 
       sts_tl.name Task_Status, 
       pri.name Task_Priority,
       Planned_Start_Date, 
       Planned_End_Date, 
       Scheduled_Start_Date,
       Scheduled_End_Date,
       Actual_Start_Date,
       Actual_End_Date,
       tl.name Source_Object_type,
       Source_Object_type_code,
       Source_Object_Id,
       parties.party_name customer_name,
       global_timezone_name,
       tz.gmt_deviation_hours, 
       duration, 
       duration_uom,
       escalation_level,
       a.task_status_id,
       a.task_type_id,
       jtf_task_uwq_pvt.get_primary_phone( a.task_id) primary_phone,
       hcp.email_address primary_email,
       a.creation_date,
       a.last_update_date,
       a.source_object_type_code IEU_ACTION_OBJECT_CODE,
       tasks_tl.description,
       a.source_object_name source_document_name,
       a.object_version_number, 
       a.costs short_pay_amount,
       parties.party_number customer_number,
       hca.account_number customer_account,
       a.attribute3 COUNTRY_CODE                --Country Code Included
 FROM  jtf_tasks_b a,
       jtf_task_statuses_tl sts_tl, 
       jtf_tasks_tl tasks_tl,
       jtf_objects_b b,
       jtf_objects_tl tl,
       jtf_task_priorities_tl pri,
       hz_timezones tz, 
       jtf_task_types_tl typ, 
       jtf_task_contacts jtc,
       hz_contact_points hcp,
       hz_parties parties ,
       hz_cust_accounts hca
WHERE a.source_object_type_code = b.object_code 
and a.task_type_id = typ.task_type_id 
and customer_id = parties.party_id(+)
and typ.language=userenv('LANG') 
and a.task_id = tasks_tl.task_id 
and tasks_tl.language = userenv('lang') 
and (a.owner_type_code is null or a.owner_type_code not in ('RS_GROUP','RS_TEAM'))
and tz.timezone_id(+) = a.timezone_id 
and b.object_code = tl.object_code 
and tl.language = userenv('lang') 
and a.task_priority_id = pri.task_priority_id (+) 
and pri.language(+) = userenv('LANG')
and a.open_flag = 'Y'
and a.TASK_STATUS_ID = sts_tl.TASK_STATUS_ID
and sts_tl.LANGUAGE = userenv('LANG')
and nvl(a.deleted_flag, 'N') <> 'Y' 
and a.entity = 'TASK'
and jtc.task_id(+) = a.task_id 
AND jtc.primary_flag(+) = 'Y' 
AND hcp.owner_table_id(+) = jtc.contact_id
AND hcp.owner_table_name(+) = 'HZ_PARTIES'
AND hcp.contact_point_type(+) = 'EMAIL' 
AND hcp.primary_flag(+) = 'Y'
AND hca.party_id = parties.party_id;




