-- +===================================================================+
-- |                        Office Depot                               |
-- |                                                                   |
-- +===================================================================+
-- | Adhoc Script :  XX_CDH_RELIABLE_CONTACTS_STG_DCScript.sql         |
-- | Description  :  Script to clean duplicate records from reliable   |
-- |                 customers contacts staging table,                 |
-- |                 XX_CDH_RELIABLE_CONTACTS_STG                      |
-- | Rice Id      :                                                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       23-APR-2015  Manikant Kasu      Initial draft version    |
-- +===================================================================+

DECLARE

ln_count NUMBER :=  0;

BEGIN 

  dbms_output.put_line ('Begin...');
  
  SELECT COUNT(*)
  INTO ln_count
  FROM XX_CDH_RELIABLE_CONTACTS_STG A 
   WHERE 1 = 1
     AND A.STATUS_FLAG    = 'N'
     AND A.CCU_CONTACT_ID = (SELECT B.CCU_CONTACT_ID
                               FROM XX_CDH_RELIABLE_CONTACTS_STG B
                              WHERE 1 = 1
                                AND STATUS_FLAG = 'S'
                                AND b.ccu_contact_id = a.CCU_CONTACT_ID)
    ;
  dbms_output.put_line ('Total number of Duplicate records...:' ||ln_count);  
  
  dbms_output.put_line ('Duplicate records being cleared...');  
  DELETE FROM XX_CDH_RELIABLE_CONTACTS_STG A 
   WHERE 1 = 1
     AND A.STATUS_FLAG    = 'N'
     AND A.CCU_CONTACT_ID = (SELECT B.CCU_CONTACT_ID
                               FROM XX_CDH_RELIABLE_CONTACTS_STG B
                              WHERE 1 = 1
                                AND b.STATUS_FLAG = 'S'
                                AND b.ccu_contact_id = a.CCU_CONTACT_ID)
    ;

COMMIT;

 dbms_output.put_line ('End...');

 EXCEPTION 
     WHEN OTHERS THEN 
         dbms_output.put_line ('Exception in WHEN OTHERS when deleting duplicates, error:'|| SQLERRM);
END;
/