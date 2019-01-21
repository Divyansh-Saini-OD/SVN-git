SELECT * FROM ALL_TABLES
WHERE table_name LIKE 'XX_CDH_EBL%';

-- Synonym Creation script

SELECT 'Create synonym ' || table_name || ' for ' || owner || '.' || table_name || ';'
FROM ALL_TABLES
WHERE table_name LIKE 'XX_CDH_EBL%';


-- Drop synonym
SELECT 'Drop synonym apps.' || table_name || ';'
FROM ALL_TABLES
WHERE table_name LIKE 'XX_CDH_EBL%';


-- Drop table
SELECT 'Drop table XXCRM.' || table_name || ' cascade constraints;'
FROM ALL_TABLES
WHERE table_name LIKE 'XX_CDH_EBL%';


-- Column Details
SELECT table_name "Table Name", column_name "Column Name", data_type "Data Type"
     , DECODE (data_type, 'VARCHAR2', data_length, 'NUMBER', data_precision, null) "Data Length"
     , data_default "Default Value", nullable "Nullable Yes/No"
FROM  ALL_TAB_COLUMNS
WHERE table_name LIKE 'XX_CDH_EBL%'
ORDER BY 1, COLUMN_ID;


-- Fin Trans Tables
select * from XX_FIN_TRANSLATEDEFINITION
where  TRANSLATION_NAME = 'XX_CDH_EBILLING_FIELDS';


-- List of Index
select ai.TABLE_NAME, ai.INDEX_NAME, ai.UNIQUENESS,  COLUMN_NAME--, COLUMN_POSITION
from   ALL_IND_COLUMNS aic, all_indexes ai
where  ai.index_name = aic.index_name
and    ai.table_name like 'XX_CDH_EBL%'
order by 1, 2, COLUMN_POSITION;


Drop table XXCRM.XX_CDH_EBL_CONTACTS cascade constraints;            
Drop table XXCRM.XX_CDH_EBL_ERROR cascade constraints;               
Drop table XXCRM.XX_CDH_EBL_FILE_NAME_DTL cascade constraints;       
Drop table XXCRM.XX_CDH_EBL_MAIN cascade constraints;                
Drop table XXCRM.XX_CDH_EBL_STD_AGGR_DTL cascade constraints;        
Drop table XXCRM.XX_CDH_EBL_TEMPL_DTL cascade constraints;           
Drop table XXCRM.XX_CDH_EBL_TEMPL_HEADER cascade constraints;        
Drop table XXCRM.XX_CDH_EBL_TRANSMISSION_DTL cascade constraints;

rename table XXCRM.XX_CDH_EBL_TRANSMISSION_DTL to XXCRM.XX_CDH_EBL_TRANSMISSION_DTL1;


Drop synonym apps.XX_CDH_EBL_CONTACTS;            
Drop synonym apps.XX_CDH_EBL_ERROR;               
Drop synonym apps.XX_CDH_EBL_FILE_NAME_DTL;       
Drop synonym apps.XX_CDH_EBL_MAIN;                
Drop synonym apps.XX_CDH_EBL_STD_AGGR_DTL;        
Drop synonym apps.XX_CDH_EBL_TEMPL_DTL;           
Drop synonym apps.XX_CDH_EBL_TEMPL_HEADER;        
Drop synonym apps.XX_CDH_EBL_TRANSMISSION_DTL; 

Create synonym XX_CDH_EBL_CONTACTS for XXCRM.XX_CDH_EBL_CONTACTS;                                                
Create synonym XX_CDH_EBL_ERROR for XXCRM.XX_CDH_EBL_ERROR;                                                      
Create synonym XX_CDH_EBL_FILE_NAME_DTL for XXCRM.XX_CDH_EBL_FILE_NAME_DTL;                                      
Create synonym XX_CDH_EBL_MAIN for XXCRM.XX_CDH_EBL_MAIN;                                                        
Create synonym XX_CDH_EBL_STD_AGGR_DTL for XXCRM.XX_CDH_EBL_STD_AGGR_DTL;                                        
Create synonym XX_CDH_EBL_TEMPL_DTL for XXCRM.XX_CDH_EBL_TEMPL_DTL;                                              
Create synonym XX_CDH_EBL_TEMPL_HEADER for XXCRM.XX_CDH_EBL_TEMPL_HEADER;                                        
Create synonym XX_CDH_EBL_TRANSMISSION_DTL for XXCRM.XX_CDH_EBL_TRANSMISSION_DTL;  


-- Get Phone and Email
1. From the org_contact_id from HZ_ORG_CONTACTS, get relationship_id. 
2. From the relationship_id from HZ_PARTY_RELATIONSHIPS, get the party_id.
3. Go the HZ_CONTACT_POINTS, and get the record for this party_id as owner_table_id and owner_table_name as ‘HZ_PARTIES’.



CREATE SEQUENCE XX_CHD_EBL_TEMPL_ID
INCREMENT BY 1
START WITH 1
-- MAXVALUE <integer> / NOMAXVALUE
-- MINVALUE <integer> / NOMINVALUE
NOCYCLE -- CYCLE/
NOCACHE -- CACHE <#> / 
ORDER




