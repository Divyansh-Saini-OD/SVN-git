SET SERVEROUTPUT ON;
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : DATA_XX_SFA_PROB_STAGE_MAP.sql                               |
-- | Description : Data for win prob and stage map.                |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks            	               |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 13-SEP-2010 Lokesh Kumar  Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+

DECLARE

  rowcnt  NUMBER;
  
  CURSOR CheckRowCount IS
    SELECT count(*)
     FROM XX_SFA_PROB_STAGE_MAP;

BEGIN

   OPEN CheckRowCount;
   FETCH CheckRowCount INTO rowcnt;
   CLOSE CheckRowCount;

   IF rowcnt = 0 THEN
     dbms_output.put_line('Table is empty, going ahead with insertion');

     insert all
        into XX_SFA_PROB_STAGE_MAP values(0,24,'Plan and Engage')
	into XX_SFA_PROB_STAGE_MAP values(25,74,'Diagnose')
	into XX_SFA_PROB_STAGE_MAP values(75,99,'Propose and Close')
	into XX_SFA_PROB_STAGE_MAP values(100,100,'Implement')               	                         
      select * from dual;

        
      

   ELSE
     dbms_output.put_line('Table contains data, no insertion will be done');
   END IF;
   
   COMMIT;

END;
/
SET SERVEROUTPUT OFF;




