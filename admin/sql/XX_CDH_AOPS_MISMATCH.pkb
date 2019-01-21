  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
  -- +===================================================================================+
  -- |                                                                                   |
  -- | Name             :  XX_CDH_AOPS_MISMATCH                                          |
  -- | Description      :  This package compares the relationships from AOPS and CDH     |
  -- |                     and updates in CDH as it is in AOPS.				     |
  -- |                                                                                   |
  -- |                                                                                   |
  -- |                                                                                   |
  -- | This package contains the following sub programs:                                 |
  -- | =================================================                                 |
  -- |Type         Name             Description                                          |
  -- |=========    ===========      =====================================================|
  -- |PROCEDURE    Main             This is the public procedure. The concurrent program |
  -- |                              OD: CDH AOPS MISMATCH DETAIL REPORT will call this   |
  -- |                              public procedure.                                    |
  -- |                                                                                   |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date        Author                       Remarks                         |
  -- |=======   ==========  ==========================   ================================|
  -- |1	        28-Oct-12   Deepak Viswanathan		       Initial version                 |
  -- |2	        21-Sep-12   Pooja Mehra			             Changes made for not picking    |
  -- |	    	        					                          end dated relationships.	     |
  -- |3         18-Nov-15   Manikant Kasu	    	         Removed schema references as per|
  -- |	    	        					                         GSCC R12.2.2 Compliance.  	     |
  -- +===================================================================================+

create or replace
PACKAGE BODY XX_CDH_AOPS_MISMATCH
AS

  PROCEDURE XX_CDH_AOPS_MISMATCH_RPT (errbuf out NOCOPY varchar2
                                    , retcode out NOCOPY varchar2)
  AS

  TYPE NUMLIST IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE STATUS IS TABLE OF VARCHAR2(50) INDEX BY BINARY_INTEGER;

  CDH_DATA NUMLIST;    -- WILL HOLD THE CHILD AS ID AND PARENT AS VALUE
  AOPS_DATA NUMLIST;   -- WILL HOLD THE CHILD AS ID AND PARENT AS VALUE
  AOPS_STATUS STATUS;  -- WILL HOLD THE STATUS OF THE DATA (SUCCESS, ERROR, NULL)

  INT_CHILD  NUMBER;    -- TEMPORARY VARIABLE TO STORE THE CURRENT CHILD VALUE
  INT_PARENT NUMBER;    -- TEMPORARY VARIABLE TO STORE THE CURRENT PARENT VALUE
  INT_RPT    NUMBER;    -- VARIABLE USED TO STORE THE REPORT TBALE INDEX NUMBER
  INT_AOPS_CDH NUMBER;  --
  INT_SUCCESS NUMBER := 0;
  INT_FAIL NUMBER := 0;

  TYPE REPORTREC IS RECORD (    -- WILL BE USED TO DISPLAY THE RESULT
        EBIZ_CHILD_ID   NUMBER,
        EBIZ_PARENT_ID  NUMBER,
        AOPS_CHILD_ID   NUMBER,
        AOPS_PARENT_ID  NUMBER,
        ACTION          VARCHAR2(100)
        );

 TYPE REPORTTAB IS TABLE OF REPORTREC INDEX BY BINARY_INTEGER;
 REPORT REPORTTAB;

  CURSOR CUR_CDH IS
SELECT SUBSTR(C.ORIG_SYSTEM_REFERENCE, 1, 8)  CHILD
      , SUBSTR(B.ORIG_SYSTEM_REFERENCE, 1, 8) PARENT
FROM  HZ_RELATIONSHIPS A,
      HZ_CUST_ACCOUNTS B,
      HZ_CUST_ACCOUNTS C
WHERE A.RELATIONSHIP_CODE  = 'PARENT_COMPANY'
  AND A.RELATIONSHIP_TYPE  = 'OD_CUST_HIER'
  AND A.SUBJECT_TYPE       = 'ORGANIZATION'
  AND A.OBJECT_TYPE        = 'ORGANIZATION'
  AND A.DIRECTION_CODE     = 'P'
  AND A.OBJECT_TABLE_NAME  = 'HZ_PARTIES'
  AND A.SUBJECT_TABLE_NAME = 'HZ_PARTIES'
  AND A.STATUS             = 'A'
  AND A.OBJECT_ID          = C.PARTY_ID
  AND A.SUBJECT_ID         = B.PARTY_ID 
  AND SYSDATE BETWEEN A.START_DATE AND NVL (A.END_DATE, SYSDATE+1); --added by Pooja-Mehra. Defect #20300
  
  
  TYPE CUR_AOPS_TYPE  IS REF CURSOR;
  CUR_AOPS CUR_AOPS_TYPE;

  INT_CDH NUMBER;
  INT_AOPS NUMBER;
  T_START NUMBER;
  T1 NUMBER;
  T2 NUMBER;

  INT_EBIZ_ONLY NUMBER := 0;
  INT_REL_MISMATCH NUMBER := 0;
  INT_AOPS_ONLY NUMBER := 0;
  INT_AOPS_IGNORE NUMBER := 0;
  INT_AOPS_STATUS_SUCCESS NUMBER:= 0;

  GC_DB_LINK VARCHAR2(100);
  L_QUERY VARCHAR2(1000);
BEGIN
    errbuf := '';
    retcode := 0;
    gc_db_link := substr(fnd_profile.value('XX_CDH_AOPS_MISMATCH_DBLINK_NAME'),instr(fnd_profile.value('XX_CDH_AOPS_MISMATCH_DBLINK_NAME'),'@')+1);    
	  L_QUERY := 'SELECT FCU005P_CUSTOMER_ID, FCU005P_PARENT_ID FROM RACOONDTA.FCU005P@' || GC_DB_LINK;
    T_START := DBMS_UTILITY.GET_TIME;
    T1 := DBMS_UTILITY.GET_TIME;
    INT_CDH  := 0;
    INT_AOPS := 0;
    INT_RPT  := -1;
    FND_FILE.put_line(FND_FILE.log, 'Remote DB = ' || gc_db_link);
    FND_FILE.put_line(FND_FILE.log, 'query = ' || l_query);
  /*STEP 1 . PULL OUT RECORDS FROM AOPS TO VERIFY FROM CDH  */
    OPEN CUR_AOPS FOR L_QUERY;
    LOOP
      BEGIN
        FETCH CUR_AOPS INTO INT_CHILD, INT_PARENT;
        EXIT WHEN CUR_AOPS%NOTFOUND;
        AOPS_DATA(INT_CHILD) := INT_PARENT;
        INT_AOPS := INT_AOPS + 1;
      EXCEPTION
        WHEN OTHERS THEN        
        FND_FILE.put_line(FND_FILE.log, 'ERROR WHILE LOADING AOPS DATA STEP 1. FOR ITEM NUMBER : ' || INT_AOPS);
        retcode := 1;
      END;
    END LOOP;
    CLOSE CUR_AOPS;
    T2 := DBMS_UTILITY.GET_TIME;
    FND_FILE.put_line(FND_FILE.log, 'DATA RECEIVED FROM AOPS = ' || INT_AOPS);
    FND_FILE.put_line(FND_FILE.log, 'TIME TAKEN FOR AOPS ' || TO_CHAR(ROUND(((T2 - T1)/100),2)) || ' SEC.');

  /*STEP 2 . PULL OUT RECORDS FROM AOPS TO VERIFY FROM CDH  */
    T1 := DBMS_UTILITY.GET_TIME;
    OPEN CUR_CDH;
    LOOP
      BEGIN
        FETCH CUR_CDH INTO INT_CHILD, INT_PARENT;
        EXIT WHEN CUR_CDH%NOTFOUND;
        CDH_DATA(INT_CHILD) := INT_PARENT;
        INT_CDH := INT_CDH + 1;
        /*STEP 3 . CHECK IF PARENT CHILD RELATIONSHIP FOR THE SLECTED ITEM IS SAME IN AOPS AND CDH */
        BEGIN
          IF AOPS_DATA(INT_CHILD) <> INT_PARENT THEN
          /* POINT 1 : Relationship in CDH does not match with relationship in AOPS    */
            INT_RPT := INT_RPT + 1;
            REPORT(INT_RPT).EBIZ_CHILD_ID  := INT_CHILD;
            REPORT(INT_RPT).EBIZ_PARENT_ID := INT_PARENT;
            REPORT(INT_RPT).AOPS_CHILD_ID  := INT_CHILD;
            REPORT(INT_RPT).AOPS_PARENT_ID := AOPS_DATA(INT_CHILD);
            REPORT(INT_RPT).ACTION         := 'REL MISMATCH';
            AOPS_STATUS(INT_CHILD) := 'ERROR';
	          INT_REL_MISMATCH := INT_REL_MISMATCH + 1;
          ELSE
            INT_SUCCESS := INT_SUCCESS + 1;
            AOPS_STATUS(INT_CHILD) := 'SUCCESS';
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          /* POINT 2 : Relationship exists in CDH but does not exist in AOPS */
            INT_RPT := INT_RPT + 1;
            REPORT(INT_RPT).EBIZ_CHILD_ID  := INT_CHILD;
            REPORT(INT_RPT).EBIZ_PARENT_ID := INT_PARENT;
            REPORT(INT_RPT).AOPS_CHILD_ID  := 0;
            REPORT(INT_RPT).AOPS_PARENT_ID := 0;
            REPORT(INT_RPT).ACTION         := 'EBIZ ONLY';
	    INT_EBIZ_ONLY := INT_EBIZ_ONLY + 1;
        END;
      EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.put_line(FND_FILE.log, 'ERROR IN PROCESSING CDH LOOP FOR CHILD = ' || INT_CHILD || ' AND PARENT = ' || INT_PARENT ||' WITH MSG ' || SQLERRM);
          retcode := 1;
      END;
    END LOOP;
    CLOSE CUR_CDH;
    T2 := DBMS_UTILITY.GET_TIME;
    FND_FILE.put_line(FND_FILE.log, 'DATA RECEIVED FROM CDH = ' || INT_CDH);
    FND_FILE.put_line(FND_FILE.log, 'TIME TAKEN FOR AOPS COMPARISION : ' || TO_CHAR(ROUND(((T2 - T1)/(100*60)),2)) || ' MIN.');

    /* STEP 4 . PRINT ELEMENTS FROM AOPS THAT HAVE NOT BEEN MARKED AS THESE ARE NOT AVAILABLE IN CDH  */

    T1 := DBMS_UTILITY.GET_TIME;
    INT_AOPS := AOPS_DATA.FIRST;
    LOOP
      BEGIN
        EXIT WHEN INT_AOPS IS NULL;
        IF NVL(AOPS_STATUS(INT_AOPS),'XXX') <> 'XXX' THEN  --IF HAS A VALUE THEN THE REORD GOT CAPTURED IN EITHER POINT 1 OR POINT 2
          INT_AOPS_STATUS_SUCCESS := INT_AOPS_STATUS_SUCCESS + 1;
        END IF;
        INT_AOPS := AOPS_DATA.NEXT(INT_AOPS);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN -- THERE WILL BE NO ENTRY IN THE AOPS_STATUS TABLE FOR CHILD WHERE NO RELATIONSHIP WAS FOUND IN CDH
          /*Check if the corresponding customer exists in CDH. If yes then mark it as error else ignore */
          BEGIN
            SELECT COUNT(1) 
            INTO  INT_AOPS_CDH
            FROM  HZ_CUST_ACCOUNTS CA
            WHERE CA.ORIG_SYSTEM_REFERENCE LIKE LPAD(INT_AOPS,8,'0') || '-%'
               OR CA.ORIG_SYSTEM_REFERENCE LIKE LPAD(AOPS_DATA(INT_AOPS),8,'0') || '-%';

            IF INT_AOPS_CDH = 2 THEN
              --INSERT THIS DATA INTO THE REPORT TABLE
              INT_RPT := INT_RPT + 1;
              REPORT(INT_RPT).EBIZ_CHILD_ID  := 0;
              REPORT(INT_RPT).EBIZ_PARENT_ID := 0;
              REPORT(INT_RPT).AOPS_CHILD_ID  := LPAD(INT_AOPS,8,'0');
              REPORT(INT_RPT).AOPS_PARENT_ID := LPAD(AOPS_DATA(INT_AOPS),8,'0');
              REPORT(INT_RPT).ACTION         := 'AOPS ONLY';
              INT_AOPS_ONLY := INT_AOPS_ONLY + 1;
	    ELSE
	      FND_FILE.put_line(FND_FILE.log, 'Parent / Child does not exist IN CDH for parent = ' || AOPS_DATA(INT_AOPS) || ' and child = ' || INT_AOPS || '. Error = ' || SQLERRM);
            END IF;

            INT_AOPS := AOPS_DATA.NEXT(INT_AOPS);

          EXCEPTION
           WHEN OTHERS THEN
             INT_AOPS := AOPS_DATA.NEXT(INT_AOPS);
             retcode := 1;
             FND_FILE.put_line(FND_FILE.log, 'Error in finding customer data in CDH for parent = ' || AOPS_DATA(INT_AOPS) || ' and child = ' || INT_AOPS || '. Error = ' || SQLERRM);
          END;
      END;
    END LOOP;

    T2 := DBMS_UTILITY.GET_TIME;
    FND_FILE.put_line(FND_FILE.log, 'TIME TAKEN TO NAVIGATE AOPS FOR POINT 3 : ' || TO_CHAR(ROUND(((T2 - T1)/(100*60)),2)) || ' MIN.');

    FND_FILE.put_line(FND_FILE.log, 'SUCCESS = ' || INT_SUCCESS);
    FND_FILE.put_line(FND_FILE.log, 'FAILURE = ' || INT_RPT);

    FND_FILE.put_line(FND_FILE.output, '******************************************************************************');
    FND_FILE.put_line(FND_FILE.output, 'EBIZ CHILD ID, EBIZ PARENT ID, AOPS CHILD ID, AOPS PARENT ID, STATUS');
    FND_FILE.put_line(FND_FILE.output, '******************************************************************************');

    T1 := DBMS_UTILITY.GET_TIME;
    FOR INDX IN REPORT.FIRST .. REPORT.LAST LOOP
      FND_FILE.put_line(FND_FILE.output, RPAD(REPORT(INDX).EBIZ_CHILD_ID,13) ||',' || RPAD(REPORT(INDX).EBIZ_PARENT_ID,15) ||',' || RPAD(REPORT(INDX).AOPS_CHILD_ID,14) ||',' || RPAD(REPORT(INDX).AOPS_PARENT_ID,15) || ',' ||REPORT(INDX).ACTION);
    END LOOP;
    FND_FILE.put_line(FND_FILE.output, 'EBIZ ONLY = ' || INT_EBIZ_ONLY || ' RELATION MISMATCH = ' || INT_REL_MISMATCH || ' AOPS ONLY = ' || INT_AOPS_ONLY);
    T2 := DBMS_UTILITY.GET_TIME;
    FND_FILE.put_line(FND_FILE.log, 'TIME TAKEN FOR REPORT PRINTING ' || TO_CHAR(ROUND(((T2 - T1)/100),2)) || ' SEC.');
    FND_FILE.put_line(FND_FILE.log, 'TOTAL TIME TAKEN : ' || TO_CHAR(ROUND(((T2 - T_START)/(100*60)),2)) || ' MIN.');
  EXCEPTION
  WHEN OTHERS THEN
     errbuf := 'ERROR ' || SQLERRM;
     retcode := 2;   
  END XX_CDH_AOPS_MISMATCH_RPT;
end XX_CDH_AOPS_MISMATCH;
/