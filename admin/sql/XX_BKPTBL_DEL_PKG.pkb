CREATE OR REPLACE
PACKAGE BODY XX_BKPTBL_DEL_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                    	    |
-- |                  Office Depot                                         	    |
-- +=================================================================================+
-- | Name  	   : RICE ID:E7028 XX_BKPTBL_DEL_PKG (XX_BKPTBL_DEL_PKG.pks)                      |
-- | Description   : OD: Backup Tables Deletion Program 	                    |
-- |                                  	    				            |
-- |Change Record:                                                         	    |
-- |===============                                                        	    |
-- |Version Date        Author            Remarks                 Description       |
-- |======= ========   ===========       ===========             ===============    |
-- |1.0     10-MAR-17  Pritdarshini Jena Initial draft version   Defect # 4082      |
-- |                                                             Automation of      |
-- |                                                             Dropping the       |
-- |                                                             Backup Tables      |
-- |                                                             created for        |
-- |                                                             Standard and Normal|
-- |                                                             changes as Part    |
-- |                                                             of Backup within   |
-- |                                                            an agreed time frame|
-- +=================================================================================+
PROCEDURE XX_BKPTBL_DEL_PROC(
    P_DATE IN VARCHAR2,
    ERRBUFF OUT VARCHAR2,
    RETCODE OUT VARCHAR2)
IS
  CURSOR TAB_DEL
  IS
    SELECT A.TABLE_NAME,
      B.CREATED
    FROM ALL_TABLES A,
      DBA_OBJECTS B
    WHERE B.OBJECT_NAME=A.TABLE_NAME
    AND A.OWNER        ='XXDBA'
    AND TABLE_NAME LIKE 'XX%BKP';
BEGIN
  FOR REC IN TAB_DEL
  LOOP
    FND_FILE.PUT_LINE(FND_FILE.LOG,'ENTERED LOOP  '||REC.TABLE_NAME);
    IF NVL (FND_DATE.CANONICAL_TO_DATE (P_DATE), SYSDATE) - REC.CREATED >= 90 THEN
      EXECUTE IMMEDIATE 'DROP TABLE XXDBA.'||REC.TABLE_NAME;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'TABLE DROPED SUCCESSFULLY : '||REC.TABLE_NAME);
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'TABLE CREATED LESS THAN 90 DAYS'||REC.TABLE_NAME);
    END IF;
    COMMIT;
  END LOOP;
END XX_BKPTBL_DEL_PROC;
END XX_BKPTBL_DEL_PKG;
/