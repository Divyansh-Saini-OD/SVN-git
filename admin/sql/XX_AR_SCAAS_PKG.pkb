create or replace package body xx_ar_scaas_pkg is

-- +==============================================================================================+
-- |                               Office Depot                                                   |
-- +==============================================================================================+
-- | Name        :  XX_AR_SCAAS_PKG.pkb                                                           |
-- |                                                                                              |
-- | Subversion Info:                                                                             |
-- |                                                                                              |
-- |                                                                                              |
-- |                                                                                              |
-- | Description :                                                                                |
-- |                                                                                              |
-- | package for XX_AR_SCAAS_PKG process.                                                         |
-- |                                                                                              |
-- |                                                                                              |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version   Date         Author             Remarks                                             |
-- |========  ===========  =================  ====================================================|
-- |1.0       01-Jul-2021  Divyansh Saini     Initial version                                     |
-- +==============================================================================================+


/*********************************************************************
* procedure to put logs
*********************************************************************/
Procedure logs(p_message IN VARCHAR2,p_def IN BOOLEAN DEFAULT FALSE) IS
  lc_message VARCHAR2(2000);
BEGIN
    --if debug is on (defaults to true)
    IF (g_debug_profile OR p_def)
    THEN
      lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF')
                         || ' => ' || p_message, 1, g_max_log_size);

      -- if in concurrent program, print to log file
      IF (g_conc_req_id > 0)
      THEN
        fnd_file.put_line(fnd_file.LOG, lc_message);
      -- else print to DBMS_OUTPUT
      ELSE
        DBMS_OUTPUT.put_line(lc_message);
      END IF;
    END IF;
  EXCEPTION
      WHEN OTHERS
      THEN
          NULL;
END;

/*********************************************************************
* procedure to set global variables
*********************************************************************/

procedure set_global_variables IS

  lv_debug_pro_val VARCHAR2(100) := FND_PROFILE.VALUE('XX_AR_SCAAS_DEBUG');
BEGIN

    g_package_name   := 'XX_AR_SCAAS_PKG';
    IF lv_debug_pro_val in ('Yes','Y') THEN
       g_debug_profile  := True;
    ELSE
       g_debug_profile  := False;
    END IF;
    g_max_log_size  := 2000;
    g_conc_req_id   := fnd_global.conc_request_id;

EXCEPTION
      WHEN OTHERS
      THEN
          NULL;
END;

/*********************************************************************
* Function to trim file values
*********************************************************************/
FUNCTION get_converted_text(p_value IN VARCHAR2)
  RETURN VARCHAR2 IS
  lv_value VARCHAR2(2000);
BEGIN
   /*Replace carriage return line break*/
   SELECT TRIM(REPLACE(REPLACE(REPLACE(p_value,CHR(10)),CHR(13)),CHR(9)))
     INTO lv_value
     FROM DUAL;

     SELECT REPLACE(lv_value,'|','')
       INTO lv_value
      FROM DUAl;
    /*Fix for colon*/
     SELECT REPLACE(lv_value,'''','''''')
       INTO lv_value
      FROM DUAl;
    /*Fix for ampersand*/
     SELECT REPLACE(lv_value,'&','''||'||'''&'''||'||''')
       INTO lv_value
      FROM DUAl;
   RETURN lv_value;
EXCEPTION
  WHEN OTHERS THEN
     RETURN p_value;
END;
-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : get_inventory_item_id                                               |
-- | Description : Function to get inventory_item_id                                   |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+
Function get_inventory_item_id (p_name            IN varchar2)
RETURN mtl_system_items_b%ROWTYPE IS
  ln_item_id  NUMBER := '';
  r_item_info mtl_system_items_b%ROWTYPE;
BEGIN
   logs('Get inventory Id');
   logs('Item name '||p_name);
   SELECT msib.*
    INTO   r_item_info
    FROM   mtl_system_items_b msib,
           mtl_parameters mp
    WHERE  msib.segment1               = p_name
    AND    mp.organization_id          = msib.organization_id
    AND    mp.master_organization_id   = mp.organization_id;
    logs('Return Id '||ln_item_id);
    RETURN r_item_info;

EXCEPTION WHEN OTHERS THEN
   logs('Error while getting item Id '||SQLERRM);
return null;
END;

-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : get_std_message                                                     |
-- | Description : Function to get messages                                            |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+

FUNCTION get_std_message(p_msg_type IN  VARCHAR2) RETURN VARCHAR2 IS
   p_msg_name VARCHAR2(100);
BEGIN
  p_msg_name :='XX_AR_SCAAS_RPT_'||p_msg_type;
  fnd_message.set_name('XXFIN', p_msg_name);
  return fnd_message.get;

EXCEPTION WHEN OTHERS THEN
   RETURN null;
END;

-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : check_duplicate                                                     |
-- | Description : Function to check_duplicate                                         |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+
PROCEDURE check_duplicate IS

BEGIN

   UPDATE XX_AR_SCAAS_INTERFACE i
      SET STATUS = 'Duplicate'
    WHERE EXISTS (SELECT 1 
                    FROM XX_AR_SCAAS_INTERFACE_HIST h
                   WHERE h.SUBSCRIPTION_ID = i.SUBSCRIPTION_ID
                     AND h.AOPS_NUMBER     = i.AOPS_NUMBER
                     AND h.ITEM_NAME       = i.ITEM_NAME
                     AND h.n_ext_attr1     = i.n_ext_attr1
                     AND h.c_ext_attr2     = i.c_ext_attr2);
EXCEPTION WHEN OTHERS THEN
   logs('  Error in check_duplicate '||SQLERRM,true);
END;


-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : populate_invoice_number                                             |
-- | Description : Function to get invoice number                                      |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+

PROCEDURE populate_invoice_number IS

   cursor c1 is 
      SELECT distinct cust_account_id ,process_id
        FROM xx_ar_scaas_interface_hist 
       WHERE NVL(invoice_number,'-1')  = '-1';
   lv_sql varchar2(2000);
   lv_str varchar2(2000);
BEGIN
    for rec in c1 loop

        lv_sql := 'SELECT distinct customer_trx_id from ra_customer_trx_lines_all where interface_line_attribute1 = '''||rec.cust_account_id||
        ''' AND interface_line_attribute2 = '''||rec.process_id||''' AND ROWNUM = 1';

        BEGIN
            execute immediate lv_sql INTO lv_str;
		EXCEPTION WHEN OTHERS THEN
		    logs('  Get invoice failed for process: '||rec.process_id||' AND customer: '||rec.cust_account_id||'.Error :'||SQLERRM,true);
        lv_str := '-1';
	    END;

        update xx_ar_scaas_interface_hist
           set invoice_number = lv_str
         where process_id = rec.process_id
           and cust_account_id = rec.cust_account_id;

    end loop;

EXCEPTION WHEN OTHERS THEN
   logs('  Error in populate_invoice_number '||SQLERRM,true);
END;
-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : get_term_id                                                         |
-- | Description : Function to get get_term_id                                         |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+
Function get_term_id (p_name        IN varchar2)
RETURN number IS
  ln_term_id NUMBER := '';
BEGIN
   logs('Get inventory Id');
   logs('Term name '||p_name);
   SELECT term_id
     INTO ln_term_id
     FROM ra_terms_tl
    WHERE name = p_name;
    logs('Return Id '||ln_term_id);
    RETURN ln_term_id;

EXCEPTION WHEN OTHERS THEN
   logs('Error while getting item Id '||SQLERRM);
return null;
END;

PROCEDURE purge_file_data(p_file_id NUMBER) IS

BEGIN

   INSERT INTO xx_ar_scaas_files_hist SELECT * FROM xx_ar_scaas_files WHERE process_id = p_file_id;

   execute IMMEDIATE 'DELETE FROM xx_ar_scaas_files WHERE process_id = :1' USING p_file_id;

EXCEPTION WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in purge_file_data '||SQLERRM);
END;

-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : insert_ra_intf_lines                                                |
-- | Description : Insert data into ra_interface lines                                 |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+
PROCEDURE insert_ra_intf_lines (x_ra_intf_lines_info  ra_interface_lines_all%ROWTYPE) IS

BEGIN
    logs('Starting insert_ra_intf_lines(+)');

    INSERT INTO ra_interface_lines_all VALUES x_ra_intf_lines_info;

    logs('Starting insert_ra_intf_lines(-)');
EXCEPTION WHEN OTHERS THEN
    logs('Unable to insert data for line '||SQLERRM,true);
END insert_ra_intf_lines;

-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : insert_ra_intf_dists                                                |
-- | Description : Insert data into ra_interface distribution                          |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+
PROCEDURE insert_ra_intf_dists (x_ra_intf_dists_info  ra_interface_distributions_all%ROWTYPE) IS

BEGIN
    logs('Starting insert_ra_intf_dists(+)');

    INSERT INTO ra_interface_distributions_all VALUES x_ra_intf_dists_info;

    logs('End insert_ra_intf_dists(-)');
EXCEPTION WHEN OTHERS THEN
    logs('Unable to insert data for line '||SQLERRM,true);
END insert_ra_intf_dists;

-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : check_req_status                                                    |
-- | Description : Checking request completion status                                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+

PROCEDURE check_req_status(p_request_id IN NUMBER) IS

   lv_status     VARCHAR2(10);
   lv_phase      VARCHAR2(10) := 'X';
   ld_start_time DATE   := sysdate;
   ld_curr_time  DATE   := sysdate;

BEGIN

   WHILE ( lv_phase != 'C')
   LOOP
       SELECT status_code,phase_code
         INTO lv_status,lv_phase
         FROM fnd_concurrent_requests
        WHERE request_id = p_request_id;
        ld_curr_time := sysdate;
    IF (ld_curr_time - ld_start_time)*24*60 > 5 THEN
        lv_phase := 'C';
    END IF;
    DBMS_lock.sleep(10);
    END LOOP;

    IF UPPER(lv_status) = 'C' AND UPPER(lv_phase) = 'C' THEN
        logs('Program completed successful for the Request Id: ' || p_request_id );
    ELSE
        logs('Program did not complete normally. ');
    END IF;

EXCEPTION WHEN OTHERS THEN
   logs('Checking status failed '||SQLERRM,true);
END check_req_status;

/*********************************************************************
* Function to check the length of source AOPS Number
*********************************************************************/
FUNCTION check_aops_number(p_value IN VARCHAR2)
  RETURN VARCHAR2 IS
BEGIN
   IF length(p_value) >8 THEN
      logs('check_aops_number ' ||p_value);
      RETURN p_value||'-00001-A0';
   ELSE
      logs('check_aops_number ' ||p_value);
      RETURN lpad(p_value,8,'0')||'-00001-A0';
   END IF;
EXCEPTION WHEN OTHERS THEN
  RETURN p_value;
END check_aops_number;

-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : fetch_cust_details                                                  |
-- | Description : Procedure to get customer details                                   |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+

PROCEDURE fetch_cust_details(p_process_id IN NUMBER) IS

  TYPE rec_type is RECORD  (cust_account_id NUMBER,
                            AOPS_NUMBER VARCHAR2(240));
  TYPE tab_type IS TABLE OF rec_type;
  lt_tab_type tab_type:=tab_type();

  TYPE cust_rec_type is RECORD  (cust_acct_site_id NUMBER,
                            cust_account_id NUMBER);
  TYPE cust_tab_type IS TABLE OF cust_rec_type;
  lt_cust_tab_type cust_tab_type:=cust_tab_type();

  cursor c_cust_data IS
       SELECT distinct hca.cust_account_id,xx.bill_to_customer_osr
         FROM hz_cust_accounts hca,
              XX_AR_SCAAS_INTERFACE xx
        WHERE HCA.orig_system_reference = check_aops_number(substr(xx.bill_to_customer_osr,1,instr(xx.bill_to_customer_osr,'-')-1))
          AND hca.status = 'A'
          AND xx.status  = 'NEW'
          AND xx.process_id = p_process_id;
  cursor c_bill_to_id IS
      SELECT HCSU.cust_acct_site_id,HCAS.cust_account_id
        FROM hz_cust_acct_sites_all hcas,
             hz_cust_site_uses_all hcsu,
             XX_AR_SCAAS_INTERFACE xx
       WHERE 1=1
         AND HCSU.CUST_ACCT_SITE_ID = HCAS.CUST_ACCT_SITE_ID
         AND hcas.status = 'A'
         AND hcsu.status = 'A'
         AND HCSU.SITE_USE_CODE = 'BILL_TO'
         AND HCSU.PRIMARY_FLAG = 'Y'
         AND xx.cust_account_id = HCAS.cust_account_id
         AND xx.status  = 'NEW'
         AND xx.process_id = p_process_id;

  cursor c_ship_to_id IS
      SELECT HCSU.cust_acct_site_id,HCAS.cust_account_id
        FROM hz_cust_acct_sites_all hcas,
             hz_cust_site_uses_all hcsu,
             XX_AR_SCAAS_INTERFACE xx
       WHERE 1=1
         AND HCSU.CUST_ACCT_SITE_ID = HCAS.CUST_ACCT_SITE_ID
         AND hcas.status = 'A'
         AND hcsu.status = 'A'
         AND HCSU.SITE_USE_CODE = 'SHIP_TO'
         AND HCSU.PRIMARY_FLAG = 'Y'
         AND xx.cust_account_id = HCAS.cust_account_id
         AND xx.status  = 'NEW'
         AND xx.process_id = p_process_id;

  bulk_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(bulk_errors, -24381);
  l_error_count  NUMBER;

BEGIN
   logs('Start fetch_cust_details(+)',true);
   open c_cust_data;
   FETCH c_cust_data BULK COLLECT INTO lt_tab_type;
   CLOSE c_cust_data;
   logs('Update cust_account_id');
    BEGIN
      FORALL i in lt_tab_type.FIRST ..lt_tab_type.LAST SAVE EXCEPTIONS
      UPDATE XX_AR_SCAAS_INTERFACE
         SET cust_account_id = lt_tab_type(i).cust_account_id
       WHERE bill_to_customer_osr = lt_tab_type(i).AOPS_NUMBER
         AND process_id = p_process_id;
    EXCEPTION
    WHEN bulk_errors THEN
      l_error_count := SQL%BULK_EXCEPTIONS.count;
      FOR i IN 1 .. l_error_count LOOP
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Error: ' || i || 
          ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index ||
          ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
      END LOOP;
    END;

   
   open c_bill_to_id;
   FETCH c_bill_to_id BULK COLLECT INTO lt_cust_tab_type;
   CLOSE c_bill_to_id;
   logs('Update cust_account_id');
    BEGIN
      FORALL i in lt_cust_tab_type.FIRST ..lt_cust_tab_type.LAST SAVE EXCEPTIONS
      UPDATE XX_AR_SCAAS_INTERFACE
         SET bill_to_site_id = lt_cust_tab_type(i).cust_acct_site_id
       WHERE cust_account_id = lt_cust_tab_type(i).cust_account_id
         AND process_id = p_process_id;
    EXCEPTION
    WHEN bulk_errors THEN
      l_error_count := SQL%BULK_EXCEPTIONS.count;
      FOR i IN 1 .. l_error_count LOOP
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Error: ' || i || 
          ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index ||
          ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
      END LOOP;
    END;
    
   lt_cust_tab_type.delete;
   lt_cust_tab_type :=cust_tab_type();

   open c_ship_to_id;
   FETCH c_ship_to_id BULK COLLECT INTO lt_cust_tab_type;
   CLOSE c_ship_to_id;
   logs('Update cust_account_id');
    BEGIN
      FORALL i in lt_cust_tab_type.FIRST ..lt_cust_tab_type.LAST SAVE EXCEPTIONS
      UPDATE XX_AR_SCAAS_INTERFACE
         SET ship_to_site_id = lt_cust_tab_type(i).cust_acct_site_id
       WHERE cust_account_id = lt_cust_tab_type(i).cust_account_id
         AND process_id = p_process_id;
    EXCEPTION
    WHEN bulk_errors THEN
      l_error_count := SQL%BULK_EXCEPTIONS.count;
      FOR i IN 1 .. l_error_count LOOP
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Error: ' || i || 
          ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index ||
          ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
      END LOOP;
    END;
   logs('Start fetch_cust_details(-)',true);
EXCEPTION WHEN OTHERS THEN
   FND_FILE.PUT_LINE (FND_FILE.LOG,'Unknown Error fetch_cust_details '||SQLERRM);
END;

-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : Create_groups                                                       |
-- | Description : Procedure to create groups of item and customer                     |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+

PROCEDURE Create_groups(p_process_id IN NUMBER,p_error OUT BOOLEAN) IS

  TYPE rec_type IS RECORD (rank_id NUMBER,record_id NUMBER);
  TYPE tab_type IS TABLE OF rec_type;
  lt_tab_type tab_type := tab_type();
  bulk_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(bulk_errors, -24381);
  l_error_count  NUMBER;
  
  CURSOR c_ranks IS
     SELECT DENSE_RANK() OVER (order by cust_account_id,item_name)
        ,record_id
        from xx_ar_scaas_interface a where process_id = p_process_id and status = 'NEW';
  
BEGIN
   OPEN c_ranks;
   FETCH c_ranks BULK COLLECT INTO lt_tab_type;
   CLOSE c_ranks;
   
   logs('Update cust_account_id');
    BEGIN
      FORALL i in lt_tab_type.FIRST ..lt_tab_type.LAST SAVE EXCEPTIONS
      UPDATE XX_AR_SCAAS_INTERFACE
         SET group_id = lt_tab_type(i).rank_id
       WHERE record_id = lt_tab_type(i).record_id
         AND process_id = p_process_id;
    EXCEPTION
    WHEN bulk_errors THEN
      l_error_count := SQL%BULK_EXCEPTIONS.count;
      FOR i IN 1 .. l_error_count LOOP
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Error: ' || i || 
          ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index ||
          ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
      END LOOP;
    END;
   p_error := FALSE; 
EXCEPTION WHEN OTHERS THEN
   p_error := TRUE;
   FND_FILE.PUT_LINE (FND_FILE.LOG,'Unknown Error Create_groups '||SQLERRM);
END;

-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : process_data                                                        |
-- | Description : Procedure to callchild program to load ar interface                 |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+
procedure process_data (errbuf         out varchar2,
                        retcode        out number,
                        p_process_id   IN  NUMBER,
                        p_thread_count IN  NUMBER)is
  ln_cnt_err_request   NUMBER;
  lc_request_data      VARCHAR2(200);
  ln_parent_request_id NUMBER;
  ln_thread_count      NUMBER :=0;
  ln_total_count       NUMBER :=0;
  ln_curr_req_id       NUMBER :=0;
  lc_error_loc         VARCHAR2(200);
  lv_cur_sql           VARCHAR2(2000);
  TYPE record_id_typ is RECORD (minId NUMBER,maxId NUMBER);
  TYPE record_tab is TABLE OF record_id_typ;
  l_record_tab record_tab := record_tab();
  lb_error  BOOLEAN;
BEGIN
  logs('Start Process_data(+)',true);
  set_global_variables;
  lc_request_data      := fnd_conc_global.request_data;
  SELECT count(distinct BILL_TO_CUSTOMER_OSR)
    INTO ln_total_count
    FROM xx_ar_scaas_interface
   WHERE process_id = p_process_id;
   
   
   fetch_cust_details(p_process_id);
   Create_groups(p_process_id,lb_error);
   IF lb_error THEN
      return;
   END IF;

   IF ln_total_count >0 AND ln_total_count < p_thread_count THEN
      SELECT min(cust_account_id) mnid,max(cust_account_id) mxid
        BULK COLLECT INTO l_record_tab
        FROM xx_ar_scaas_interface
      WHERE process_id = p_process_id;
   ELSIF ln_total_count >0 AND ln_total_count > p_thread_count THEN
      SELECT max(cust_account_id)mxid,min(cust_account_id)mnid
        BULK COLLECT INTO l_record_tab
        FROM (
                            SELECT cust_account_id,trunc(cnt/p_thread_count)+ sign(mod(cnt,p_thread_count)) cnth FROm(
                            select cust_account_id,sum(1) OVER (order by cust_account_id) cnt
                            from xx_ar_scaas_interface
                            WHERE process_id = p_process_id))
                            group by cnth;
   ELSIF ln_total_count = 0 THEN
     logs('No Data Present to process',true);
   END IF;
   IF lc_request_data IS NULL THEN
     FOR indx in 1..l_record_tab.count LOOP
        logs('Submitting Child for customer for records between '||l_record_tab(indx).minId || ' AND '||l_record_tab(indx).maxId);
        ln_thread_count:=ln_thread_count+1;
        ln_curr_req_id  := fnd_request.submit_request(application => 'XXFIN'
                                             ,program     => 'XX_AR_SCAAS_CHILD_PROCESS'
                                             ,sub_request => TRUE
                                             ,argument1   => l_record_tab(indx).minId
                                             ,argument2   => l_record_tab(indx).maxId
                                             ,argument3   => p_process_id);

     END LOOP;
     IF (ln_thread_count > 0) THEN
            fnd_conc_global.set_req_globals(conc_status  => 'PAUSED'
                                           ,request_data => 'COMPLETE');
         END IF;
   ELSE
    SELECT COUNT(*)
      INTO   ln_cnt_err_request
      FROM   fnd_concurrent_requests
     WHERE  parent_request_id = g_conc_req_id
       AND    phase_code = 'C'
       AND    status_code = 'E';

       IF ln_cnt_err_request <> 0 THEN
          lc_error_loc := ln_cnt_err_request || ' Child Requests are Errored Out.Please, Check the Child Requests LOG for Details';
          logs(lc_error_loc,true);
          retcode := 2;
       ELSE
          lc_error_loc := 'All the Child Programs Completed Normal...';
          logs(lc_error_loc,true);
       END IF;

   END IF;
    purge_file_data(p_process_id);
   logs('Process_data(-)',true);
END process_data;


-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : process_data_child                                                  |
-- | Description : Procedure to callchild program to load ar interface                 |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+
procedure process_data_child (errbuf       out varchar2,
                              retcode      out number,
                              p_min_id     IN  NUMBER,
                              p_max_id     IN  NUMBER,
                              p_process_id IN  NUMBER)is
   ln_customer_id         hz_cust_accounts.cust_account_id%TYPE;
   ln_bill_to_address_id  hz_cust_site_uses_all.cust_acct_site_id%TYPE;
   ln_ship_to_address_id  hz_cust_site_uses_all.cust_acct_site_id%TYPE;
   ln_organization_id     NUMBER;
   ln_limit               NUMBER;
   ln_org_id              NUMBER;
   lv_source              VARCHAR2(100);
   ln_cc_id               gl_code_combinations.code_combination_id%TYPE;
   lv_segment1            gl_code_combinations.segment1%TYPE;
   lv_segment2            gl_code_combinations.segment2%TYPE;
   lv_segment3            gl_code_combinations.segment3%TYPE;
   lv_segment4            gl_code_combinations.segment4%TYPE;
   lv_segment5            gl_code_combinations.segment5%TYPE;
   lv_segment6            gl_code_combinations.segment6%TYPE;
   lv_segment7            gl_code_combinations.segment7%TYPE;
   loc_error              EXCEPTION;
   source_not_found       EXCEPTION;
   type_not_found         EXCEPTION;
   
   TYPE det_rec IS RECORD (
             cust_account_id NUMBER,
             bill_to_site_id NUMBER,
             ship_to_site_id NUMBER,
             item_name VARCHAR2(100),
             ITEM_DESCRIPTION VARCHAR2(500),
             UNIT_OF_MEASURE VARCHAR2(200),
             SUBSCRIPTION_ID NUMBER,
             SUBSCRIPTION_NUMBER NUMBER,
             process_id NUMBER,
             TRX_DATE date ,
             AMOUNT NUMBER,
             quantity NUMBER,
             record_id NUMBER,
             group_id NUMBER
   );
   
   TYPE det_tab IS TABLE OF det_rec;
   
   Det_data det_tab := det_tab();
   lr_ra_intf_lines_info  ra_interface_lines_all%ROWTYPE;
   lr_ra_intf_dists_info  ra_interface_distributions_all%ROWTYPE;
   lr_item_info           mtl_system_items_b%ROWTYPE;
   ln_interface_line_id   NUMBER := 0;
   ln_trx_number          NUMBER := 0;
   lv_cons_flag           hz_customer_profiles.CONS_INV_FLAG%TYPE;
   ln_term_id             hz_customer_profiles.standard_terms%TYPE;
   ld_billing_date        ar_cons_bill_cycle_dates.billable_date%TYPE;
   ln_billing_cycle_id    ra_terms.billing_cycle_id%TYPE;
   lv_term_name           ra_terms.name%TYPE;

   CURSOR c_dist_det(p_group_id NUMBER) IS
      SELECT *
        FROM xx_ar_scaas_interface
         WHERE status = 'NEW'
           AND process_id = p_process_id
           AND group_id = p_group_id;

   CURSOR c_get_det IS
      SELECT max(cust_account_id) cust_account_id,
             max(bill_to_site_id) bill_to_site_id,
             max(ship_to_site_id) ship_to_site_id,
             max(item_name) item_name,
             max(ITEM_DESCRIPTION) ITEM_DESCRIPTION,
             max(UNIT_OF_MEASURE) UNIT_OF_MEASURE,
             max(SUBSCRIPTION_ID) SUBSCRIPTION_ID,
             max(SUBSCRIPTION_NUMBER) SUBSCRIPTION_NUMBER,
             max(process_id) process_id,
             max(TRX_DATE) TRX_DATE,
             max(AMOUNT) AMOUNT,
             sum(quantity) quantity,
             max(record_id) record_id,
             group_id
        FROM xx_ar_scaas_interface
       WHERE status = 'NEW'
         AND cust_account_id between p_min_id AND p_max_id
         AND process_id = p_process_id
       group by group_id;

BEGIN
    set_global_variables;
    logs('process_data_child(+) ',true);
    --Get organization_id
    logs('Getting organization_id');
    BEGIN
       SELECT ood.ORGANIZATION_ID,ood.operating_unit
         INTO   ln_organization_id, ln_org_id
         FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues     XFTV
               ,org_organization_definitions ood
         WHERE  XFTD.translate_id       = XFTV.translate_id
         AND    XFTD.translation_name   = 'XX_AR_SCAAS_INTERFACE'
         AND    XFTV.source_value1      = 'ITEM_ORG'
         AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND    XFTV.enabled_flag       = 'Y'
         AND    XFTD.enabled_flag       = 'Y'
         AND    ood.operating_unit      = xftv.target_value1
         AND    ood.ORGANIZATION_CODE   = xftv.target_value2;
    EXCEPTION WHEN OTHERS THEN
       logs('Unable to get ln_organization_id '||SQLERRM);
       ln_organization_id := NULL;
    END;
    --Getting Process limits
    logs('Getting Process limits');
    BEGIN
       SELECT   xftv.target_value1
         INTO   ln_limit
         FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues     XFTV
         WHERE  XFTD.translate_id       = XFTV.translate_id
         AND    XFTD.translation_name   = 'XX_AR_SCAAS_INTERFACE'
         AND    XFTV.source_value1      = 'BULK_LIMIT'
         AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND    XFTV.enabled_flag       = 'Y'
         AND    XFTD.enabled_flag       = 'Y';
    EXCEPTION WHEN OTHERS THEN
       logs('Unable to get ln_limit '||SQLERRM);
       ln_limit := 1000;
    END;
    --Get Source Type
    logs('Getting Process limits');
    BEGIN
       SELECT   xftv.target_value1
         INTO   lv_source
         FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues     XFTV
         WHERE  XFTD.translate_id       = XFTV.translate_id
         AND    XFTD.translation_name   = 'XX_AR_SCAAS_INTERFACE'
         AND    XFTV.source_value1      = 'SOURCE'
         AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND    XFTV.enabled_flag       = 'Y'
         AND    XFTD.enabled_flag       = 'Y';
    EXCEPTION WHEN OTHERS THEN
       logs('Unable to get lv_source '||SQLERRM);
       raise source_not_found;
    END;
    --Get Transaction Type
    logs('Getting Process limits');
    BEGIN
       SELECT   rctt.cust_trx_type_id,rctt.GL_ID_REV,gcc.segment1,gcc.segment2,gcc.segment3,gcc.segment4,gcc.segment5,gcc.segment6,gcc.segment7
         INTO   g_type_id,ln_cc_id,lv_segment1,lv_segment2,lv_segment3,lv_segment4,lv_segment5,lv_segment6,lv_segment7
         FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues     XFTV
               ,ra_cust_trx_types          rctt
               ,gl_code_combinations       gcc
         WHERE  XFTD.translate_id       = XFTV.translate_id
         AND    XFTD.translation_name   = 'XX_AR_SCAAS_INTERFACE'
         AND    XFTV.source_value1      = 'TRANSACTION_TYPE'
         AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND    XFTV.enabled_flag       = 'Y'
         AND    XFTD.enabled_flag       = 'Y'
         AND    upper(rctt.name)        = upper (xftv.target_value1)
         AND    rctt.GL_ID_REV          = gcc.code_combination_id;
    EXCEPTION WHEN OTHERS THEN
       logs('Unable to get g_type_id '||SQLERRM);
       raise type_not_found;
    END;

    OPEN c_get_det;
    LOOP
        FETCH c_get_det BULK COLLECT INTO Det_data LIMIT ln_limit;
        
--      ln_trx_number                                       := xx_ar_scaas_trx_s.NEXTVAL;
    FOR indx IN 1..Det_data.count LOOP

       lr_item_info := get_inventory_item_id(Det_data(indx).ITEM_NAME);
       
        BEGIN
           SELECT rt.name,
                  rt.term_id,
                  (select min(billable_date) from ar_cons_bill_cycle_dates where billing_cycle_id = rt.billing_cycle_id
                    AND billable_date > sysdate)
             INTO lv_term_name,ln_term_id,ld_billing_date
             FROM xx_cdh_cust_acct_ext_b x,
                  ra_terms rt
            WHERE x.cust_account_id = Det_data(indx).cust_account_id
              AND x.c_ext_attr2 = 'Y'
              AND x.c_ext_attr14 = rt.name
              AND sysdate between NVL(x.d_ext_attr1,sysdate) and NVL(x.d_ext_attr2,sysdate+1)
              AND x.attr_group_id IN (SELECT attr_group_id
                              FROM   ego_attr_groups_v
                              WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
                              AND    attr_group_name = 'BILLDOCS');
         
        EXCEPTIOn WHEN OTHERS THEN
           ln_term_id := 5;
           lv_term_name := 'IMMEDIATE';
        END;

       logs('Populating ra_interface_lines_all record');

          ln_interface_line_id                                := ra_customer_trx_lines_s.NEXTVAL;
          lr_ra_intf_lines_info                               := NULL;
          lr_ra_intf_lines_info.interface_line_id             := ln_interface_line_id;
--          lr_ra_intf_lines_info.trx_number                    := ln_trx_number;
          lr_ra_intf_lines_info.trx_date                      := Det_data(indx).TRX_DATE;
          lr_ra_intf_lines_info.batch_source_name             := lv_source;
          lr_ra_intf_lines_info.amount                        := ROUND(Det_data(indx).AMOUNT*Det_data(indx).quantity,2);
          lr_ra_intf_lines_info.description                   := Det_data(indx).ITEM_DESCRIPTION;
          lr_ra_intf_lines_info.line_type                     := 'LINE';

          lr_ra_intf_lines_info.currency_code                 := 'USD';
          lr_ra_intf_lines_info.conversion_type               := 'User';
          lr_ra_intf_lines_info.conversion_rate               := 1;
          lr_ra_intf_lines_info.conversion_date               := SYSDATE;

          lr_ra_intf_lines_info.header_attribute_category     := 'SALES_ACCT';
          lr_ra_intf_lines_info.header_attribute1             := Det_data(indx).cust_account_id;

          lr_ra_intf_lines_info.last_update_date              := SYSDATE;
          lr_ra_intf_lines_info.last_updated_by               := FND_GLOBAL.USER_ID;
          lr_ra_intf_lines_info.creation_date                 := SYSDATE;
          lr_ra_intf_lines_info.created_by                    := FND_GLOBAL.USER_ID;
          lr_ra_intf_lines_info.last_update_login             := FND_GLOBAL.USER_ID;

          --lr_ra_intf_lines_info.gl_date                       := SYSDATE;

          lr_ra_intf_lines_info.inventory_item_id             := NVL(lr_item_info.inventory_item_id,-1);
          lr_ra_intf_lines_info.interface_line_attribute6     := Det_data(indx).AMOUNT;
          lr_ra_intf_lines_info.uom_code                      := Det_data(indx).UNIT_OF_MEASURE;

          lr_ra_intf_lines_info.orig_system_bill_customer_id  := Det_data(indx).cust_account_id;
          lr_ra_intf_lines_info.orig_system_ship_customer_id  := Det_data(indx).cust_account_id;
          lr_ra_intf_lines_info.orig_system_sold_customer_id  := Det_data(indx).cust_account_id;
          lr_ra_intf_lines_info.orig_system_bill_address_id   := Det_data(indx).bill_to_site_id;
          lr_ra_intf_lines_info.orig_system_ship_address_id   := Det_data(indx).ship_to_site_id; --??

          lr_ra_intf_lines_info.taxable_flag                  := 'N';

          lr_ra_intf_lines_info.line_number                   := Det_data(indx).SUBSCRIPTION_ID;

          lr_ra_intf_lines_info.quantity                      := Det_data(indx).quantity;
          lr_ra_intf_lines_info.unit_selling_price            := Det_data(indx).AMOUNT;
          lr_ra_intf_lines_info.unit_standard_price           := Det_data(indx).AMOUNT;

          lr_ra_intf_lines_info.interface_line_context        := 'RECURRING BILLING';
          lr_ra_intf_lines_info.interface_line_attribute1     := Det_data(indx).cust_account_id;--Det_data(indx).SUBSCRIPTION_NUMBER || '-' || Det_data(indx).record_id;
          lr_ra_intf_lines_info.interface_line_attribute2     := Det_data(indx).process_id;
          lr_ra_intf_lines_info.interface_line_attribute3     := Det_data(indx).SUBSCRIPTION_ID;
          lr_ra_intf_lines_info.interface_line_attribute4     := Det_data(indx).record_id;
          lr_ra_intf_lines_info.interface_line_attribute5     := Det_data(indx).SUBSCRIPTION_NUMBER;

          lr_ra_intf_lines_info.interface_line_attribute11    := '0';
          lr_ra_intf_lines_info.attribute15                   := 'Y';

          lr_ra_intf_lines_info.warehouse_id                  := lr_item_info.organization_id;

          lr_ra_intf_lines_info.term_id                       := ln_term_id;
          lr_ra_intf_lines_info.term_name                     := lv_term_name;
          lr_ra_intf_lines_info.org_id                        := 404;
          lr_ra_intf_lines_info.cust_trx_type_name            := 'OD_SCAAS_INVOICE_OD';
          lr_ra_intf_lines_info.cust_trx_type_id              := g_type_id;
          IF ld_billing_date IS NOT NULL THEN
            lr_ra_intf_lines_info.billing_date                := ld_billing_date;
          END IF;
--          lr_ra_intf_lines_info.set_of_books_id               := lr_operating_unit_info.set_of_books_id;

          lr_ra_intf_lines_info.translated_description        := lr_item_info.segment1;

        logs('  calling insert_ra_intf_lines ');
        insert_ra_intf_lines(lr_ra_intf_lines_info);

        
           FOR rec_c_dist_det IN c_dist_det(Det_data(indx).group_id) LOOP

                logs('  creating rec type for distributions insertion');

                lr_ra_intf_dists_info.interface_line_id               := ln_interface_line_id;
                lr_ra_intf_dists_info.interface_line_context          := 'RECURRING BILLING';
                lr_ra_intf_dists_info.interface_line_attribute1       := Det_data(indx).cust_account_id;--Det_data(indx).SUBSCRIPTION_NUMBER || '-' || Det_data(indx).record_id;
                lr_ra_intf_dists_info.interface_line_attribute2       := Det_data(indx).process_id;
                lr_ra_intf_dists_info.interface_line_attribute3       := Det_data(indx).SUBSCRIPTION_ID;
                lr_ra_intf_dists_info.interface_line_attribute4       := Det_data(indx).record_id;
                lr_ra_intf_dists_info.interface_line_attribute5       := Det_data(indx).SUBSCRIPTION_NUMBER;
                lr_ra_intf_dists_info.account_class                   := 'REV';
                lr_ra_intf_dists_info.amount                          := ROUND(rec_c_dist_det.AMOUNT*rec_c_dist_det.quantity,2);
                --lr_ra_intf_dists_info.percent                         := 100;
                --lr_ra_intf_dists_info.code_combination_id             := ln_cc_id;
                lr_ra_intf_dists_info.segment1                        := lv_segment1;
                lr_ra_intf_dists_info.segment2                        := lv_segment2;
                lr_ra_intf_dists_info.segment3                        := lv_segment3;
                lr_ra_intf_dists_info.segment4                        := LPAD(rec_c_dist_det.c_ext_attr2, GREATEST(LENGTH(rec_c_dist_det.c_ext_attr2), 6), '0') ;--rec_c_dist_det.c_ext_attr2
                lr_ra_intf_dists_info.segment5                        := lv_segment5;
                lr_ra_intf_dists_info.segment6                        := lv_segment6;
                lr_ra_intf_dists_info.segment7                        := lv_segment7;
                lr_ra_intf_dists_info.attribute1                      := Det_data(indx).SUBSCRIPTION_NUMBER;
                lr_ra_intf_dists_info.attribute2                      := CASE WHEN rec_c_dist_det.c_ext_attr1= 'null' then '' else rec_c_dist_det.c_ext_attr1 end;
                lr_ra_intf_dists_info.attribute3                      := rec_c_dist_det.c_ext_attr2;
                lr_ra_intf_dists_info.attribute_category              := 'SCAAS_ACCT';
				lr_ra_intf_dists_info.global_attribute1               := Det_data(indx).record_id;
                lr_ra_intf_dists_info.created_by                      := FND_GLOBAL.USER_ID;
                lr_ra_intf_dists_info.creation_date                   := SYSDATE;
                lr_ra_intf_dists_info.last_updated_by                 := FND_GLOBAL.USER_ID;
                lr_ra_intf_dists_info.last_update_date                := SYSDATE;
                lr_ra_intf_dists_info.last_update_login               := FND_GLOBAL.USER_ID;
                lr_ra_intf_dists_info.org_id                          := ln_org_id;

                insert_ra_intf_dists(lr_ra_intf_dists_info);
           END LOOP;
        END LOOP;


    EXIT WHEN Det_data.count =0;
    END LOOP;

    CLOSE c_get_det;

   UPDATE xx_ar_scaas_interface
      SET status = 'Processed'
    WHERE status = 'NEW'
      AND cust_account_id between p_min_id AND p_max_id
      AND process_id = p_process_id;

    EXECUTE IMMEDIATE 'INSERT INTO xx_ar_scaas_interface_hist SELECT * FROM xx_ar_scaas_interface  WHERE cust_account_id between :1 AND :2 AND process_id = :3' USING p_min_id,p_max_id,p_process_id;
    EXECUTE IMMEDIATE 'DELETE FROM xx_ar_scaas_interface  WHERE cust_account_id between :1 AND :2 AND process_id = :3' USING p_min_id,p_max_id,p_process_id;

   logs('process_data_child(-)',true);
EXCEPTION
  WHEN source_not_found THEN
    errbuf := 'batch Source not found '||SQLERRM;
    retcode := 1;
  WHEN type_not_found THEN
    errbuf := 'Transaction Type not found '||SQLERRM;
    retcode := 1;
  WHEN loc_error THEN
    errbuf := 'Location Not found for CCID'||SQLERRM;
    retcode := 2;
  WHEN OTHERS THEN
    errbuf := 'Error while processing ' || ' . Error '||SQLERRM;
    retcode := 2;
END;

-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : load_data                                                           |
-- | Description : Procedure to extract data and populate the staging tables           |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+
PROCEDURE load_data(errbuf       OUT varchar2,
                    retcode      OUT number,
                    p_process_id IN  number) is
lf_file         UTL_FILE.FILE_TYPE;
lv_line_data    VARCHAR2(4000);
lv_col_value    VARCHAR2(200);
ln_rows         NUMBER :=0;
lv_insert_str   VARCHAR2(2000) := 'INSERT INTO XX_AR_SCAAS_INTERFACE(';
lv_select_str   VARCHAR2(2000) := '(';
lv_query        VARCHAR2(4000);
l_module_name   VARCHAR2(2000) := 'INSERT_DATA';
le_end_line     EXCEPTION;
lv_enclosed_by  varchar2(10);
lv_delimeter    varchar2(10);

type col_map_typ is record  (col_name varchar2(200),datatype  varchar2(200),format varchar2(200));
type col_map_tab is table of col_map_typ;

cursor c_col_mapping is
SELECT xtv.target_value1,target_value3 ,target_value4
  FROM XX_FIN_TRANSLATEDEFINITION xtd, XX_FIN_TRANSLATEVALUES xtv
 WHERE xtd.translate_id = xtv.translate_id
   AND XTD.TRANSLATION_NAME = 'XX_AR_SCAAS_COLUMNS'
   AND SOURCE_VALUE1 = 'XX_AR_SCAAS_INTERFACE'
order by to_NUMBER(xtv.target_value2);

tab_rec col_map_tab := col_map_tab();
cursor get_files is
   SELECT FILE_NAME,file_location,DELIMETER,skip_rows,file_id
     FROM xx_ar_scaas_files
    WHERE PROCESS_ID = p_process_id;

BEGIN
  set_global_variables;
  OPEN c_col_mapping;
  FETCH c_col_mapping bulk collect into tab_rec;
  FOR rec_get_files in get_files LOOP
    logs('  insert_data(+)');
    logs('  p_directory '||rec_get_files.file_location);
    logs('  p_file_name '||rec_get_files.FILE_NAME);
    logs('  lv_delimeter '||rec_get_files.DELIMETER);
    lf_file := utl_file.fopen(rec_get_files.file_location,rec_get_files.FILE_NAME,'r');
    lv_delimeter := rec_get_files.DELIMETER;
    lv_enclosed_by := null;
    LOOP
      logs('  Looping through file');
       BEGIN
         utl_file.get_line(lf_file,lv_line_data);
         lv_line_data := convert(lv_line_data,'utf8');
         ln_rows := ln_rows+1;
         IF ln_rows <=rec_get_files.skip_rows THEN
           Continue;
         END IF;
         lv_insert_str :='INSERT INTO XX_AR_SCAAS_INTERFACE(process_id,status';
         lv_select_str := '('||p_process_id||',''NEW''';
         IF lv_line_data like 'Trailer%' THEN
            raise le_end_line;
         END IF;
         logs('Line Data '||lv_line_data);
         logs('Looping with Data '||regexp_count(lv_line_data,lv_delimeter));
         For i in 0..regexp_count(lv_line_data,lv_delimeter) LOOP
               IF lv_line_data IS NULL THEN
               exit;
               end if;
               logs(i+1);
             IF lv_line_data like lv_enclosed_by||'%' and regexp_count(lv_line_data,lv_enclosed_by) !=0 THEN
                lv_col_value := TRIM(SUBSTR(lv_line_data,2,regexp_INSTR(lv_line_data,lv_enclosed_by||lv_delimeter,1,1)-2));
                lv_line_data := SUBSTR(lv_line_data,regexp_INSTR(lv_line_data,lv_enclosed_by||lv_delimeter,1,1)+2);
             ELSIF regexp_count(lv_line_data,lv_delimeter) != 0 THEN
                lv_col_value := TRIM(SUBSTR(lv_line_data,1,regexp_INSTR(lv_line_data,lv_delimeter,1,1)-1));
                lv_line_data := SUBSTR(lv_line_data,regexp_INSTR(lv_line_data,lv_delimeter,1,1)+1);
             ELSIF regexp_count(lv_line_data,lv_delimeter) = 0 THEN
                lv_col_value:= lv_line_data;
                lv_line_data := NULL;
             END IF;
              lv_col_value:=get_converted_text(lv_col_value);
              lv_insert_str := lv_insert_str||','||tab_rec(i+1).col_name;
              IF tab_rec(i+1).datatype = 'DATE' THEN
--                 lv_select_str := lv_select_str||',TO_DATE('''||lv_col_value||'''';
                 lv_select_str := lv_select_str||',TO_DATE(substr('''||lv_col_value||''',1,10),'''||tab_rec(i+1).format||''')';
              ELSE
                 lv_select_str := lv_select_str||','''||lv_col_value||'''';
              END IF;
         END LOOP;
         lv_query := lv_insert_str||') VALUES '||lv_select_str||')';
         logs('  lv_query '||lv_query);
         BEGIN
            execute immediate lv_query;
         EXCEPTION WHEN OTHERS THEN
            logs(' Error while inserting '||SQLERRM,true);
            logs(' Errored insert sql :'||lv_query,true);
         END;
         logs('  lv_query executed');
      EXCEPTION
        WHEN le_end_line THEN
          logs('  end found in file');
          utl_file.fclose(lf_file);
          EXIT;
        WHEN NO_DATA_FOUND THEN
          logs('  No data found in file');
          utl_file.fclose(lf_file);
          EXIT;
        WHEN OTHERS THEN
         logs('Error while insert into common table' ||SQLERRM,true);
      END;
      logs('  Loop end');
    END LOOP;
    logs('  insert_data(+)');
    purge_file_data(rec_get_files.file_id);
  END LOOP;
  check_duplicate();

EXCEPTION WHEN OTHERS THEN
   logs('  Error in insert_data '||SQLERRM,true);
   utl_file.fclose(lf_file);
   errbuf := sqlerrm;
   retcode := 2;
END;

PROCEDURE MAIN (errbuf    OUT VARCHAR2,
                retcode   OUT NUMBER,
                p_run_AI  IN  varchar2) IS
   lv_process_type        VARCHAR2(50) := 'FILE';
   ln_process_id          NUMBER;
   ln_req_id              NUMBER;
   lc_wait_flag           BOOLEAN;
   lc_phase               VARCHAR2(100);
   lc_status              VARCHAR2(100);
   lc_dev_phase           VARCHAR2(100);
   lc_dev_status          VARCHAR2(100);
   lc_message             VARCHAR2(100);
   ln_thread_count        NUMBER;
   lv_source_folder       VARCHAR2(100);
   lv_source              VARCHAR2(100);
   lv_source_id           NUMBER;
   lv_destination_folder  VARCHAR2(100);
BEGIN
   logs('Start Main (+)',True);
   set_global_variables;
   logs('Parameters '||p_run_AI,True);
-- Fetching process id
    SELECT xx_ar_scaas_prc_s.nextval
      INTO ln_process_id
      FROM dual;
    logs('process started for id '||ln_process_id,True);

    BEGIN
    SELECT   xftv.target_value1
      INTO   ln_thread_count
      FROM   xx_fin_translatedefinition XFTD
            ,xx_fin_translatevalues     XFTV
            ,org_organization_definitions ood
     WHERE  XFTD.translate_id       = XFTV.translate_id
       AND    XFTD.translation_name   = 'XX_AR_SCAAS_INTERFACE'
       AND    XFTV.source_value1      = 'THREAD_COUNT'
       AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
       AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
       AND    XFTV.enabled_flag       = 'Y'
       AND    XFTD.enabled_flag       = 'Y';
    EXCEPTION WHEN OTHERS THEN
       logs('process started for id ');
       ln_thread_count := 10;
    END;
    --Calling insert file names program
    ln_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XX_AR_SCAAS_FILE_LOAD' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_process_type, argument2=>ln_process_id);
    COMMIT;
    logs('Conc. Program submitted '||ln_req_id);
    IF ln_req_id = 0 THEN
      logs('Conc. Program  failed to submit Program',True);
    ELSE
      logs('Waiting for concurrent request to complete');
      check_req_status(ln_req_id);
      /*lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => ln_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logs('Program completed successful for the Request Id: ' || ln_req_id );
      ELSE
        logs('Program did not complete normally. ');
      END IF;*/
    END IF;
    
    BEGIN
        UPDATE xx_ar_scaas_interface
           SET process_id = ln_process_id
         WHERE status  = 'NEW';
    EXCEPTION WHEN OTHERS THEN
       null;
    END;

    --Calling process data
    ln_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XX_AR_SCAAS_PROCESS_DATA' , description => NULL , start_time => sysdate , sub_request => false , argument1=>ln_process_id, argument2=>ln_thread_count);
    COMMIT;
    logs('Conc. Program submitted '||ln_req_id);
    IF ln_req_id = 0 THEN
      logs('Conc. Program  failed to submit Program',True);
    ELSE
      logs('Waiting for concurrent request to complete');
      check_req_status(ln_req_id);
      /*lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => ln_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logs('Program completed successful for the Request Id: ' || ln_req_id );
      ELSE
        logs('Program did not complete normally. ');
      END IF;*/
    END IF;

    BEGIN
        SELECT XFTV.TARGET_VALUE1,XFTV.TARGET_VALUE2
          INTO lv_source_folder,lv_destination_folder
          FROM XX_FIN_TRANSLATEDEFINITION XFTD,
               XX_FIN_TRANSLATEVALUES XFTV
         WHERE XFTD.TRANSLATION_NAME   = 'XX_AR_SCAAS_INTERFACE'
           AND XFTV.SOURCE_VALUE1      = 'ARCHIVE'
           AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
           AND XFTD.ENABLED_FLAG       = 'Y'
           AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
    EXCEPTION WHEN OTHERS THEN
       errbuf := 'Error while getting source folder';
       retcode := 2;
    END;

    --Calling archive program
    ln_req_id:= fnd_request.submit_request ( application => 'XXFIN' , program => 'XX_AR_SCAAS_ARCH_FILE' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_source_folder, argument2=>ln_process_id,argument3=>lv_destination_folder);
    COMMIT;
    logs('Conc. Program submitted '||ln_req_id);
    IF ln_req_id = 0 THEN
      logs('Conc. Program  failed to submit Program',True);
    ELSE
      logs('Waiting for concurrent request to complete');
      check_req_status(ln_req_id);
    END IF;
    BEGIN
       SELECT   xftv.target_value1,rb.batch_source_id
         INTO   lv_source,lv_source_id
         FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues     XFTV
               ,ra_batch_sources_all     rb
         WHERE  XFTD.translate_id       = XFTV.translate_id
         AND    XFTD.translation_name   = 'XX_AR_SCAAS_INTERFACE'
         AND    XFTV.source_value1      = 'SOURCE'
         AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND    XFTV.enabled_flag       = 'Y'
         AND    rb.name                 = xftv.target_value1
         AND    XFTD.enabled_flag       = 'Y';
    EXCEPTION WHEN OTHERS THEN
       logs('Unable to get lv_source '||SQLERRM);
    END;


      IF lv_source IS NOT NULL and p_run_AI = 'YES' THEN
      ln_req_id := fnd_request.submit_request
                      (application      => 'AR',
                      program          => 'RAXTRX',
                      description      => NULL,
                      start_time       => NULL,
                      sub_request      => FALSE,
                      argument1        => 'MAIN',
                      argument2        => 'T',
                      argument3        => lv_source_id,--batch_source_id
                      argument4        => lv_source, --batch_source_name
                      argument5        =>  to_char(sysdate,'RRRR/MM/DD HH24:MI:SS'),
                      argument6        => '',
                      argument7        => '',
                      argument8        => '',
                      argument9        => '',
                      argument10       => '',
                      argument11       => '',
                      argument12       => '',
                      argument13       => '',
                      argument14       => '',
                      argument15       => '',
                      argument16       => '',
                      argument17       => '',
                      argument18       => '',
                      argument19       => '',
                      argument20       => '',
                      argument21       => '',
                      argument22       => '',
                      argument23       => '',
                      argument24       => '',
                      argument25       => '',
                      argument26       => 'N',
                      argument27       => 'Y',
                      argument28       => '',
                      argument29       => '404', -- org_id
                      argument30       => chr(0) -- end with chr(0)as end of parameters
                      );
					  COMMIT;
    END IF;
    
    IF ln_req_id = 0 THEN
      logs('By Passing AutoInvoice Run');
    ELSE
      logs('Waiting for concurrent request to complete');
      check_req_status(ln_req_id);
    END IF;
    populate_invoice_number();

    logs('End Main (-)',True);
EXCEPTION WHEN OTHERS THEN
   logs('  Error in main '||SQLERRM,true);
   errbuf := sqlerrm;
   retcode := 2;
END;

/*********************************************************************
* After report trigger for scaas
*********************************************************************/
FUNCTION afterreport RETURN BOOLEAN IS
   P_CONC_REQUEST_ID NUMBER;
   l_request_id NUMBER;
BEGIN

   Fnd_File.PUT_LINE (Fnd_File.LOG,'In parameter : P_SMTP_SERVER = '||P_SMTP_SERVER||chr(13)||'P_MAIL_FROM = '||P_MAIL_FROM||chr(13));

      P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
      Fnd_File.PUT_LINE (Fnd_File.LOG,'Submitting : XML Publisher Report Bursting Program');
      l_request_id := FND_REQUEST.SUBMIT_REQUEST ('XDO',
                                 'XDOBURSTREP',
                                 NULL,
                                 NULL,
                                 FALSE,
                                 'Y',
                                 P_CONC_REQUEST_ID,
                                 'Y');

   RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
   Fnd_File.PUT_LINE (Fnd_File.LOG,'Unexpected error while submitting bursting program '||SQLERRM);
   RETURN FALSE;
END ;


end xx_ar_scaas_pkg;
/