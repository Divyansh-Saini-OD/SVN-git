REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : SOLAR Conversion                                                           |--
--|                                                                                             |--
--| Program Name   : Runtime Execution Scripts                                                  |--
--|                                                                                             |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              11-Jun-2008       Sathya Prabha Rani      Initial version                  |--
--+=============================================================================================+--

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF



PROMPT
PROMPT Script - CUSTOMER DETAILS
PROMPT




PROMPT
PROMPT Script - PROSPECT DETAILS
PROMPT



PROMPT
PROMPT Script - Total number of prospects in CV  tables
PROMPT


SELECT count(*)
FROM   apps.xxod_hz_imp_parties_int
WHERE  batch_id = :batchid;


PROMPT
PROMPT Script - Total number of Prospects in Interface table
PROMPT

SELECT count(*)
FROM   apps.hz_imp_parties_int
WHERE  batch_id = :batchid
AND    error_id IS NULL;


PROMPT
PROMPT Script - Total Number of Prospects sites in CV tables 
PROMPT


SELECT count(*) 
FROM   apps.xxod_hz_imp_addresses_int
WHERE  batch_id = :batch_id;


PROMPT
PROMPT Script - Total Number of Prospects Sites in Interface table
PROMPT


SELECT count(*)
FROM   apps.hz_imp_addresses_int
WHERE  batch_id = :batch_id
AND    error_id IS NULL;


PROMPT
PROMPT Script - Total Number of Prospects Sites uses in CV Table
PROMPT

SELECT count(*)
FROM   apps.xxod_hz_imp_addressuses_int
WHERE  batch_id = :batch_id
AND    error_id IS NULL;


PROMPT
PROMPT Script - Total Number of Prospects sites in Interface tables 
PROMPT

SELECT count(*) 
FROM   apps.hz_imp_addressuses_int
WHERE  batch_id = :batch_id
AND    error_id IS NULL;


PROMPT
PROMPT Script - Total number of prospects Contact Points in CV Table
PROMPT

SELECT count(*)
FROM   apps.xxod_hz_imp_contactpts_int
WHERE  batch_id = :batch_id ;


PROMPT
PROMPT Script - Total number of prospects Contact Points in Interface table
PROMPT

SELECT count(*)
FROM   apps.hz_imp_contactpts_int
WHERE  batch_id = :batch_id ;



PROMPT
PROMPT Script - PROSPECT CONTACT DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Prospects Contacts in Staging Table
PROMPT


SELECT count(*)
FROM   apps.xxod_hz_imp_contacts_int
WHERE  batch_id = :batch_id;
       

PROMPT
PROMPT Script - Total Number of Prospects Contacts in CV Table
PROMPT

SELECT count(*)
FROM   apps.hz_imp_contacts_int
WHERE  batch_id = :batch_id;


     
PROMPT
PROMPT Script - CUSTOMER CONTACT DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Customer Contacts in Staging table
PROMPT


SELECT count(*)
FROM   apps.xxod_hz_imp_contacts_int
WHERE  batch_id = :batch_id;


PROMPT
PROMPT Script - Total Number of Customer Contacts in CV table
PROMPT


SELECT count(*)
FROM   apps.hz_imp_contacts_int
WHERE  batch_id = :batch_id ;



PROMPT
PROMPT Script - PROSPECT ASSIGNMENTS DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Prospects Assignements in Staging Table
PROMPT


SELECT count(*) 
FROM   apps.xxod_hz_imp_parties_int  
WHERE  batch_id = :batchId;


PROMPT
PROMPT Script - Total Number of Prospects Assignements in CV Table
PROMPT


SELECT count(*) 
FROM   hz_imp_parties_int  
WHERE  batch_id = :BatchId;



PROMPT
PROMPT Script - NOTES DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of notes in CV table
PROMPT


SELECT count(*) 
FROM   apps.xx_cdh_solar_notes_extr3
WHERE  batch_id = :batchid;


PROMPT
PROMPT Script - Total number of notes in Interface Table
PROMPT


SELECT count(*) 
FROM   apps.xx_jtf_notes_int
WHERE  batch_id = :batchid;
 

PROMPT
PROMPT Script - Total Number of Notes in Interface Table attached to Prospects
PROMPT


SELECT DISTINCT CSNE.source_object_orig_system_ref
FROM   apps.xx_jtf_notes_int          JNI,
       apps.xx_cdh_solar_notes_extr3  CSNE,
       apps.xx_cdh_solar_noteimage    CSN,
       apps.xx_cdh_solar_siteimage    CSS
WHERE  JNI.batch_id = :batchid
AND    JNI.parent_note_orig_system_ref = CSNE.parent_note_orig_system_ref 
AND    CSNE.source_object_orig_system_ref = lpad(CSN.internid,10,'0') || '-00001-S0'
AND    CSN.internid =  CSS.internid
AND    UPPER(CSS.site_type) IN ('PROSPECT','TARGET');


PROMPT
PROMPT Script - Total Number of notes in interface Table attached to Customer Sites
PROMPT


SELECT DISTINCT CSNE.source_object_orig_system_ref
FROM   apps.xx_jtf_notes_int          JNI,
       apps.xx_cdh_solar_notes_extr3  CSNE ,
       apps.xx_cdh_solar_noteimage    CSN,
       apps.xx_cdh_solar_siteimage    CSS
WHERE  JNI.batch_id = :batchid
AND    JNI.parent_note_orig_system_ref = CSNE.parent_note_orig_system_ref 
AND    CSNE.source_object_orig_system_ref = lpad(CSN.internid,10,'0') || '-00001-S0'
AND    CSN.internid =  CSS.internid
AND    UPPER(CSS.site_type) = 'SHIPTO';
 
 

PROMPT
PROMPT Script - TASK DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of tasks in Interface table
PROMPT


SELECT count(*) 
FROM   apps.xx_jtf_imp_tasks_int  
WHERE  batch_id = :batch_id;


PROMPT
PROMPT Script - Total Number of Tasks in Interface table attached to prospects
PROMPT


SELECT count(*) 
FROM   apps.xx_JTF_IMP_TASKS_INT C
WHERE  C.customer_id IS NULL
AND    C.batch_id  = :batchId;


PROMPT
PROMPT Script - Total Number of tasks in Interface table attached to Customer
PROMPT

SELECT count(*) 
FROM   apps.xx_JTF_IMP_TASKS_INT C
WHERE  C.customer_id IS NOT NULL
AND    C.batch_id  = :batchId;
   
   
   
PROMPT
PROMPT Script - ACTIVITIES DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Activities in Interface table
PROMPT


SELECT count(*) 
FROM   apps.xx_jtf_imp_tasks_int  
WHERE  batch_id = :batch_id;


PROMPT
PROMPT Script - Total Number of Activites in Interface table attached to Prospects
PROMPT

SELECT count(*) 
FROM   apps.xx_jtf_imp_tasks_int C
WHERE  C.customer_id IS NULL
AND    C.batch_id  = :batchId;
  

PROMPT
PROMPT Script - Total Number of Activities in Interface table attached to Customers 
PROMPT


SELECT count(*) 
FROM   apps.XX_jtf_imp_tasks_int C
WHERE  C.customer_id IS NOT NULL
AND    C.batch_id  = :batchId;


PROMPT
PROMPT Script - LEADS DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Leads in CV Table
PROMPT


SELECT count(*) AS cnt_lead
FROM   XXCNV.xx_cdh_solar_org_leads_stg
WHERE  batch_id = :p_batch_id;


PROMPT
PROMPT Script - Total Number of Leads in Interface Table
PROMPT


SELECT count(*) 
FROM   apps.as_import_interface
WHERE  batch_id = :p_batch_id;



PROMPT
PROMPT Script - OPPORTUNITIES DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Opportunities in Interface Table
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1
WHERE  batch_id = :batchid;



PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
