-- +===================================================================+
-- |                        Office Depot Inc.                          |
-- +===================================================================+
-- | Adhoc Script :  XX_MON_TPS_DATA_COPY.sql                          |
-- | Description  :  Script to copy records from APPS Schema table to  |
-- |                                             XXFIN Schema          |
-- | Rice Id      :  E2025                                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       23-APR-2015  Manikant Kasu      Initial draft version    |
-- +===================================================================+

DECLARE 

ln_count  NUMBER := NULL;

BEGIN
 ln_count := 0;
 
 dbms_output.put_line ('Begin copying records from APPS.xx_mon_tps to XXFIN.xx_mon_tps....');
 
 -- Checking number of records to be inserted in this run
 SELECT COUNT(*)
 INTO ln_count
 FROM APPS.XX_MON_TPS
 WHERE 1 = 1
 ;
 dbms_output.put_line ('Total number of records to be copied from APPS.xx_mon_tps to XXFIN.xx_mon_tps :' ||ln_count);
 
INSERT INTO XXFIN.XX_MON_TPS
( SELECT a.REQUEST_ID              , 
	       a.PROGRAM_NAME            , 
	       a.START_DATE              , 
         a.END_DATE                , 
         a.VOLUME                  , 
         a.PROCESSING_TIME_IN_SEC  , 
	       a.THROUGHPUT              , 
	       a.ORG_ID                  , 
	       a.CYCLE_DATE              , 
	       a.EVENT                   , 
	       a.USER_NAME 
   FROM  APPS.XX_MON_TPS A
  WHERE  1 = 1
    AND  NOT EXISTS( SELECT  1     
                       FROM  XXFIN.XX_MON_TPS B
                      WHERE  B.request_id = A.request_id) 
 );
 
 COMMIT;
 
 -- Checking number of records inserted in this run
 SELECT COUNT(*)
 INTO ln_count
 FROM XXFIN.XX_MON_TPS
 WHERE 1 = 1
 ;
 dbms_output.put_line ('Total number of records copied APPS.xx_mon_tps to XXFIN.xx_mon_tps :' ||ln_count);
 
 dbms_output.put_line ('End of Copying records from APPS.xx_mon_tps to XXFIN.xx_mon_tps....');
 
 EXCEPTION 
   WHEN OTHERS THEN 
      dbms_output.put_line ('Exception in when others while inserting records into xx_mon_tps, error:'||SQLERRM);

END;
