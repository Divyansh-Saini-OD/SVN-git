CREATE OR REPLACE PROCEDURE USAGE_LABELS_LOAD(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) AS

/*---------------------------------------------------------------------------
-- Procedure Usage_Labels_Load
-- Created First Draft January, 2008
-- This procedure reads data from a staging table that resides in the 
-- EBS database and pushes data to the usage database, which is seperate from EBS,
-- This is done via  database link.
--
--
------------------------------------------------------------------------------
*/

BEGIN

DECLARE

v_count	     NUMBER := 0;
data_exception	EXCEPTION;
v_error_message VARCHAR2(2000);
v_sqlcode    VARCHAR2(20);

CURSOR cur1 IS
SELECT * FROM usage_labels_stage
ORDER BY customer_id;



BEGIN

--Cursor Check of Exception Messaging
--Cursor Main Insert of New Records

FOR main_cur IN cur1 LOOP
v_error_message := NULL;
BEGIN

INSERT INTO usage_labels@USAGE_LINK(
  CUSTOMER_ID,
  CUST_PO_NBR_LABEL,
  CUST_RELEASE_NBR_LABEL,
  DESKTOP_LOC_LABEL,
  CUST_DEPT_LABEL,
  CREATION_DATE,
  UPDATE_DATE,
  SOURCE_SYSTEM)
  VALUES(
  LTRIM(RTRIM(main_cur.customer_id)),
  LTRIM(RTRIM(main_cur.cust_po_nbr_label)),
  LTRIM(RTRIM(main_cur.cust_release_nbr_label)),
  LTRIM(RTRIM(main_cur.desktop_loc_label)),
  LTRIM(RTRIM(main_cur.cust_dept_label)),
  SYSDATE,
  SYSDATE,
  'TRD');

--Do Update of Transactions Table

UPDATE od_ext_usage_rpt@USAGE_LINK
SET CUST_PO_NUMBER_DESC = main_cur.CUST_PO_NBR_LABEL,
    CUST_RELEASE_NUMBER_DESC = main_cur.CUST_RELEASE_NBR_LABEL,
    DESKTOP_LOCATOR_DESC = main_cur.DESKTOP_LOC_LABEL,
    CUSTOMER_DEPT_DESC = main_cur.CUST_DEPT_LABEL
    where customer_id = main_cur.customer_id;


EXCEPTION

WHEN DUP_VAL_ON_INDEX THEN

UPDATE usage_labels@USAGE_LINK SET
  
  CUSTOMER_ID = TO_NUMBER(main_cur.customer_id),
  CUST_PO_NBR_LABEL = LTRIM(RTRIM(main_cur.cust_po_nbr_label)),
  CUST_RELEASE_NBR_LABEL = LTRIM(RTRIM(main_cur.cust_release_nbr_label)),
  DESKTOP_LOC_LABEL = LTRIM(RTRIM(main_cur.desktop_loc_label)),
  CUST_DEPT_LABEL = LTRIM(RTRIM(main_cur.cust_dept_label)),
  UPDATE_DATE = SYSDATE,
  SOURCE_SYSTEM = 'UPD'
WHERE CUSTOMER_ID = TO_NUMBER(main_cur.customer_id);



WHEN OTHERS THEN
dbms_output.put_line(SQLCODE||', '||SQLERRM);
FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Updating Duplicate Values');
FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||', '||SQLERRM);

v_sqlcode := SQLCODE;
v_error_message := SQLERRM;

p_retcode := SQLCODE;
P_errbuf := v_error_message;

END;
END LOOP;

EXCEPTION

WHEN OTHERS THEN
dbms_output.put_line(SQLCODE||', '||SQLERRM);
FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Updating Duplicate Values');
FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||', '||SQLERRM);

v_sqlcode := SQLCODE;
v_error_message := SQLERRM;


END;
END usage_labels_load;
/

		
