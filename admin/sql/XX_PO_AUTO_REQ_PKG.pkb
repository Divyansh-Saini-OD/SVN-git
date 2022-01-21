CREATE OR REPLACE PACKAGE BODY XX_PO_AUTO_REQ_PKG AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       WIPRO Technologies                                       |
-- +================================================================================+
-- | Name :       E0980 -- PO Auto Requisition Import                               |
-- | Description : To automatically import the Requisitions into Oracle             |
-- |                from the staging tables.                                        |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date          Author              Remarks                             |
-- |=======   ==========   =============        ====================================|
-- |1.0       21-MAR-2007  Gowri Shankar        Initial version                     |
-- |1.1       21-AUG-2007  Aravind A.           Fixed defect 1424                   |
-- |1.2       28-AUG-2007  Shivkumar Iyer       Fixed defect 1643                   |
-- |1.3       10-SEP-2007  Aravind A.           Fixed defect 1911                   |
-- |1.4       02-OCT-2007  Aravind A.           Fixed defect 2199                   |
-- |1.5       09-OCT-2007  Anitha D.            Fixed defect 2322                   |
-- |1.6       12-NOV-2007  Radhika Raman        Made changes for CR#267             |
-- |                                            (defect 2371)                       |
-- |1.7       26-NOV-2007  Radhika Raman        Made changes for defect 2814        |
-- |1.8       03-DEC-2007  Radhika Raman        Made changes for defect 2845        |
-- |1.9       03-JAN-2008  Gowri Shankar        Made changes for defect 3285(CR)    |
-- |2.0       03-JAN-2008  Gowri Shankar        Made changes for defect 3285(CR)    |
-- |2.1       04-MAR-2008  Radhika Raman        Fixed defect 5135                   |
-- |2.2       25-JUL-2008  Radhika Raman        Fixed defect 9178                   |
-- |2.3       21-AUG-2009  Bushrod Thomas       Made changes for CR 411             |
-- |2.4       08-OCT-2009  Bushrod Thomas       Fixed defect 2973                   |
-- |2.5       30-APR-2010  Usha R               Fixed defect 5338
-- |2.6       02-JUL-2010  Cindhu Nagarajan     Made changes for Defect# 5313       |
-- |2.7        23-APR-2012  Somali Nanda	      Made changes for getting distict    |
-- |						                       UOM for defect 18178             |
-- |2.8        25-JUL-2012  OD AMS Offshore     Fixed defect 13344 Catalogue Items  |
-- |                                            deriving proper Charge Account while| 
-- |                                            Loading the records from Requisition| 
-- |                                            Loader                              |
-- |2.9        18-JUL-2012  Aradhna Sharma      Changes for R12 Upgrade Retrofit    |
-- |                                            for E0980.                          |
-- |                                            Added following for                 |
-- |2.10       19-JUL-2012 Satyajeet Mishra     Web ADI and retrofit                |
-- |                                            a)submit_request                    |
-- |                                            b)get_record                        |
-- |2.11       17-Feb-2014 Darshini            Changes for defect 28162.            |
-- |2.12       08-Mar-2014 Darshini            Added additional condition to the    |
-- |                                           Buyer validation for defect 28774.   |
-- |2.13       11-Mar-2014 Veronica            Commented unwanted log messages      |
-- |                                           for defect 28866.                    |
-- |2.14       08-Apr-2014 Veronica            Commented unwanted log messages      |
-- |                                           for defect 29406.                    |
-- |2.15       11-Nov-2016 Suresh Ponnambalam  Defect 39900. Added condition        |
-- |                                           lc_source_type_code <> 'INVENTORY'   |
-- |2.16       06-JUN-2016 Suresh Naragam      Changes done for the defect#40571    |
-- |                                           to validate the requestor cost center          |
-- |                                           with Requisition Loader File Cost Center       |
-- |2.17       14-JUL-2017 Suresh Naragam      Changes done for the defect#42467 for          |
-- |                                           adding the instance name in the e-mail subject |
-- +==========================================================================================+

    lc_error_loc                VARCHAR2(2000) := NULL;
    lc_error_debug              VARCHAR2(2000) := NULL;
    lc_err_msg                  VARCHAR2(4000);
    gc_category                 VARCHAR2(200)  :='PO CATEGORY';
/*  -- commenting for defect 9178 as this function is not needed,
       request id is being fetched in shell script itself.
-- +===================================================================+
-- | Name : GET_REQUEST_ID                                             |
-- | Description : To get the Request ID of                            |
-- |                 'OD: PO Requisitions Extract Program'             |
-- |    It will return the Request ID of                               |
-- |                 'OD: PO Requisitions Extract Program'             |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns: ln_request_id                                            |
-- +===================================================================+

    FUNCTION GET_REQUEST_ID RETURN NUMBER
    AS
        ln_request_id   NUMBER;


    BEGIN

        lc_error_loc := 'Get the Request ID of the program ''OD: PO Requisitions Extract Program''';
        lc_error_debug := '';

        SELECT MAX(request_id)
        INTO   ln_request_id
        FROM   fnd_concurrent_requests
        WHERE  concurrent_program_id =
                   (SELECT concurrent_program_id
                    FROM   fnd_concurrent_programs
                    WHERE  concurrent_program_name = 'XXPOREQEXT');

        RETURN ln_request_id;

    EXCEPTION
        WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0001_ERROR');
            FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
            FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
            FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (fnd_file.log,lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,P_ERROR_LOCATION          => 'Error at ' || lc_error_loc
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition');

            FND_FILE.PUT_LINE (fnd_file.log,'Error Location: '||lc_error_loc);
            FND_FILE.PUT_LINE (fnd_file.log,'Error Debug: '||lc_error_debug);

            RETURN -1;

    END GET_REQUEST_ID; */ -- end of changes for defect 9178

-- +===================================================================+
-- | Name : CHECK_REQ_HEADER                                           |
-- | Description : To check if the Requisition Line information is     |
-- |                 same for all the Requisition distributions        |
-- |    It will check if the Requisition Line information is           |
-- |                 same for all the Requisition Distributions        |
-- | Parameters : p_batch_id                                           |
-- |                                                                   |
-- | Returns: 1 or 0 or -1                                             |
-- +===================================================================+

    FUNCTION CHECK_REQ_HEADER (
        p_batch_id         IN NUMBER) RETURN NUMBER
    AS
        ln_group_count   NUMBER := 0;
    BEGIN

        /*SELECT COUNT(*)
        INTO   ln_group_count
        FROM   xx_po_requisitions_stg
        WHERE  batch_id = p_batch_id
        GROUP BY
               requisition_type,preparer_name, interface_source_code, req_description;*/

        --Fixed defect 1911
        SELECT COUNT(*)
        INTO   ln_group_count
        FROM   xx_po_requisitions_stg
        WHERE  batch_id = p_batch_id
        GROUP BY
               preparer_emp_nbr, interface_source_code, req_description;
               -- defect 2845; changed to preparer emp number
        RETURN 1;

    EXCEPTION

    WHEN TOO_MANY_ROWS THEN
       RETURN 0;

    WHEN NO_DATA_FOUND THEN
       RETURN -1;

    END CHECK_REQ_HEADER;

-- +===================================================================+
-- | Name : CHECK_REQ_LINE                                             |
-- | Description : To check if the Requisition header information is   |
-- |                 same for all the Requisition lines                |
-- |    It will check if the Requisition header information is         |
-- |                 same for all the Requisition lines                |
-- | Parameters : p_batch_id, p_req_line_number                        |
-- |                                                                   |
-- | Returns: 1 or 0                                                   |
-- +===================================================================+

    FUNCTION CHECK_REQ_LINE (
        p_batch_id         IN NUMBER
        ,p_req_line_number IN VARCHAR2) RETURN NUMBER
    AS
        ln_group_count   NUMBER := 0;
    BEGIN

        SELECT COUNT(*)
        INTO   ln_group_count
        FROM   xx_po_requisitions_stg
        WHERE  batch_id = p_batch_id
        AND    req_line_number = p_req_line_number
        GROUP BY
               req_line_number, UPPER(line_type), item, category, item_description, UPPER(unit_of_measure), quantity, price
               ,need_by_date, organization, location
               ,destination_type_code;

        RETURN 1;

    EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;

    END CHECK_REQ_LINE;

-- +===================================================================+
-- | Name : PROCESS_REJ_REC                                            |
-- | Description : To get the Rejection details of 'Requisition Import'|
-- |                                                                   |
-- |    It will get the rejection details, and of  'Requisition Import'|
-- |    from PO_INTERFACE_ERRORS table                                 |
-- | Parameters : p_request_id                                         |
-- +===================================================================+

    PROCEDURE PROCESS_REJ_REC(
        p_request_id         IN NUMBER)
    AS
/*    CURSOR c_req_reject_rec IS
    (
        SELECT
               column_name
              ,error_message
              ,table_name
        FROM
              po_interface_errors PIE
        WHERE PIE.request_id = p_request_id
        AND   PIE.interface_type = 'REQIMPORT'
    );*/
   -- defect 2322
    CURSOR c_req_line_reject_rec IS
    (
        SELECT
               PIE.column_name
              ,PIE.error_message
              ,PIE.table_name
              ,PRIA.interface_source_line_id
        FROM
              po_interface_errors PIE, po_requisitions_interface_all PRIA
        WHERE PIE.request_id = p_request_id
        AND   PIE.interface_transaction_id = PRIA.transaction_id
        AND   PIE.interface_type = 'REQIMPORT'
        AND   PIE.table_name = 'PO_REQUISITIONS_INTERFACE'
    );

    CURSOR c_req_dist_reject_rec IS
    (
        SELECT
               PIE.column_name
              ,PIE.error_message
              ,PIE.table_name
              ,PRIA.interface_source_line_id
              ,PRDI.distribution_number
        FROM
              po_interface_errors PIE
              ,po_req_dist_interface_all PRDI
              , po_requisitions_interface_all PRIA
        WHERE PIE.request_id = p_request_id
        AND   PIE.interface_transaction_id = PRDI.transaction_id
        AND   PIE.interface_type = 'REQIMPORT'
        AND   PIE.table_name = 'PO_REQ_DIST_INTERFACE'
        AND   PRIA.req_dist_sequence_id = PRDI.dist_sequence_id
    );
    ln_line_err_count   NUMBER:=0;
    ln_dist_err_count   NUMBER:=0;
    BEGIN

        FOR lcu_req_line_reject_rec IN c_req_line_reject_rec
        LOOP
            IF (ln_line_err_count = 0) THEN
                FND_FILE.PUT_LINE (fnd_file.output,'');
                FND_FILE.PUT_LINE (fnd_file.output,'Rejected Records from Requisition Import - Errors in Requisition lines');
                FND_FILE.PUT_LINE (fnd_file.output,RPAD('-',150, '-'));
            END IF;

            ln_line_err_count:= ln_line_err_count+1;

            FND_FILE.PUT_LINE (fnd_file.output,RPAD('Line# ',7, ' ')||RPAD('Table Name',30, ' ')
                                  ||RPAD('Column Name',30, ' ')
                                  ||'Error Message');    --defect  2322
            FND_FILE.PUT_LINE (fnd_file.output,RPAD('-----',7, ' ')||RPAD('----------',30, ' ')
                                  ||RPAD('-----------',30, ' ')
                                  ||'-------------');    --defect  2322
            FND_FILE.PUT_LINE (fnd_file.output,RPAD(lcu_req_line_reject_rec.interface_source_line_id,7, ' ')||RPAD(lcu_req_line_reject_rec.table_name,30, ' ')||RPAD(lcu_req_line_reject_rec.column_name,30, ' ')||lcu_req_line_reject_rec.error_message);

        END LOOP;


        FOR lcu_req_dist_reject_rec IN c_req_dist_reject_rec
        LOOP
            IF (ln_dist_err_count=0) THEN

               FND_FILE.PUT_LINE (fnd_file.output,RPAD('-',150, '-'));

               FND_FILE.PUT_LINE (fnd_file.output,'');
               FND_FILE.PUT_LINE (fnd_file.output,'Rejected Records from Requisition Import - Errors in distributions');
               FND_FILE.PUT_LINE (fnd_file.output,RPAD('-',150, '-'));
            END IF;
            ln_dist_err_count:=ln_dist_err_count+1;

            FND_FILE.PUT_LINE (fnd_file.output,RPAD('Line# ',7, ' ')||RPAD('Dist# ',7, ' ')||RPAD('Table Name',30, ' ')||RPAD('Column Name',30, ' ')||'Error Message');    --defect  2322

            FND_FILE.PUT_LINE (fnd_file.output,RPAD('-----',7, ' ')||RPAD('-----',7, ' ')||RPAD('----------',30, ' ')||RPAD('-----------',30, ' ') ||'-------------');    --defect  2322

            FND_FILE.PUT_LINE (fnd_file.output,RPAD(lcu_req_dist_reject_rec.interface_source_line_id,7, ' ')||RPAD(lcu_req_dist_reject_rec.distribution_number,7, ' ')||RPAD(lcu_req_dist_reject_rec.table_name,30, ' ')||RPAD(lcu_req_dist_reject_rec.column_name,30, ' ')||lcu_req_dist_reject_rec.error_message);

        END LOOP;

        IF (ln_dist_err_count > 0) THEN
           FND_FILE.PUT_LINE (fnd_file.output,RPAD('-',150, '-'));
        END IF;

    END PROCESS_REJ_REC;

    PROCEDURE SEND_TEMPLATE_ERROR(lc_msg VARCHAR2)
    AS
        ln_conc_request_id           fnd_concurrent_requests.request_id%TYPE;
        lc_email_address             per_all_people_f.email_address%TYPE;
		lc_instance_name             VARCHAR2(30);
    BEGIN

      BEGIN
        SELECT PAPF.email_address
        INTO   lc_email_address
        FROM   per_all_people_f PAPF
              ,fnd_user FU
        WHERE  FU.employee_id = PAPF.person_id
        AND    FU.user_id = fnd_global.user_id
        AND    sysdate between PAPF.effective_start_date and PAPF.effective_end_date;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0088_NO_EMPLOYEE');
          lc_err_msg := FND_MESSAGE.GET;
          FND_FILE.PUT_LINE (fnd_file.output,lc_err_msg);

          XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_program_type            => 'CONCURRENT PROGRAM'
              ,p_program_name            => gc_concurrent_program_name
              ,p_program_id              => fnd_global.conc_program_id
              ,p_module_name             => 'PO'
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => lc_err_msg
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
              ,p_object_type             => 'PO Automatic Requisition'
              );
      END;
	  
	  --Added for defect#42467
	  BEGIN
	    SELECT instance_name
		INTO lc_instance_name
		FROM v$instance;
	  EXCEPTION WHEN OTHERS THEN
	    lc_instance_name := NULL;
	  END;

      IF lc_email_address IS NOT NULL THEN
        ln_conc_request_id := fnd_request.submit_request (
                                'XXFIN'
                                ,'XXODROEMAILER'
                                ,''
                                ,''
                                ,FALSE
                                ,''
                                ,lc_email_address
                                ,lc_instance_name||' : '||lc_msg  --Changed for defect#42467
                                ,'Please find attached the output file of ''OD: PO Auto Requisition Import Output'''
                                ,'Y'
                                ,fnd_global.conc_request_id);
        COMMIT;      -- Defect 5135
      ELSE
        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0089_NO_EMAIL');
          lc_err_msg := FND_MESSAGE.GET;
          FND_FILE.PUT_LINE (fnd_file.output,lc_err_msg);

          XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_program_type            => 'CONCURRENT PROGRAM'
              ,p_program_name            => gc_concurrent_program_name
              ,p_program_id              => fnd_global.conc_program_id
              ,p_module_name             => 'PO'
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => lc_err_msg
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
              ,p_object_type             => 'PO Automatic Requisition'
              );
      END IF;

    END SEND_TEMPLATE_ERROR;


-- +===================================================================+
-- | Name : CHARGE_ACCT_RULE_SEG_VAL   -- Added for R1.1 CR411         |
-- | Description : If there is an item category expense account rule   |
-- |                 for the specified segment, return its segment val |
-- |               Else return the given fallback value                |
-- | Parameters : p_batch_id, p_req_line_number                        |
-- |                                                                   |
-- | Returns: segment value                                            |
-- +===================================================================+
    FUNCTION CHARGE_ACCT_RULE_SEG_VAL (
        p_category_id   IN PO_RULE_EXPENSE_ACCOUNTS.rule_value_id%TYPE
       ,p_segment_num   IN PO_RULE_EXPENSE_ACCOUNTS.segment_num%TYPE
       ,p_fallback_val  IN VARCHAR2 := NULL)
    RETURN VARCHAR2
    AS
        lc_po_rule_exp_acc_seg_val PO_RULE_EXPENSE_ACCOUNTS.segment_value%TYPE;
        lc_rule_type               PO_RULE_EXPENSE_ACCOUNTS.rule_type%TYPE := 'ITEM CATEGORY';
    BEGIN
        SELECT segment_value
        INTO   lc_po_rule_exp_acc_seg_val
        FROM   PO_RULE_EXPENSE_ACCOUNTS -- also see PO_RULE_EXPENSE_ACCOUNTS_V
        WHERE  rule_value_id = p_category_id
        AND    segment_num = p_segment_num
        AND    rule_type = lc_rule_type
        AND    org_id=FND_PROFILE.value('ORG_ID');

        RETURN lc_po_rule_exp_acc_seg_val;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN p_fallback_val;
    END CHARGE_ACCT_RULE_SEG_VAL;  -- End of Addition for R1.1 CR411


-- +===================================================================+
-- | Name : PROCESS                                                    |
-- | Description : To automatically import the Rquisitions into Oracle |
-- |                                                                   |
-- |    It will validate the Requisition information from the staging  |
-- |    tables and then insert into standard interface tables          |
-- |    PO_REQUISITIONS_INTERFACE_ALL, PO_REQ_DIST_INTERFACE_ALL       |
-- |    Then it will submit the standard import request set            |
-- |                                   "Requisition Import"            |
-- |    This procedure is the executable of the concurrent program     |
-- |          'OD: PO Auto Requisition Load Program'                   |
-- | Parameters : x_error_buff, x_ret_code, p_batch_id                 |
-- |                                                                   |
-- | Returns: x_error_buff, x_ret_code                                 |
-- +===================================================================+

   PROCEDURE PROCESS(
        x_error_buff         OUT VARCHAR2
       ,x_ret_code           OUT NUMBER
       ,p_batch_id          IN VARCHAR2)
    AS
    --Cursor to get the Requisition Line information
    CURSOR c_req_intf_line IS
        (
        SELECT * FROM
        (
        SELECT
             req_line_number
            ,requisition_type
            --,preparer_name   -- defect 2845
            ,LPAD(preparer_emp_nbr,6,0) preparer_emp_nbr  -- defect 2845
            ,interface_source_code
            ,destination_type_code
            ,line_type
            ,req_description
            --,item
            --Fixed defect 1424
            --,DECODE(SUBSTR(item,1,1),'`',SUBSTR(item,2),SUBSTR(item,1)) item   --CR# 267
            ,LPAD(item,5,0) item
            ,category
            ,item_description
            ,unit_of_measure
            ,quantity
            ,price
            ,need_by_date
            --CR# 267
            --,organization
            ,LPAD(organization,6,0) organization
            --CR# 267
            --,location
            ,LPAD(location,6,0) location
            ,LPAD(source_organization,6,0) source_organization
			,charge_account_segment2
        FROM
            xx_po_requisitions_stg
        WHERE
            batch_id = p_batch_id
        GROUP BY
            req_line_number
            ,requisition_type
            ,preparer_emp_nbr  -- defect 2845
            ,interface_source_code
            ,destination_type_code
            ,line_type
            ,req_description
            ,item
            ,category
            ,item_description
            ,unit_of_measure
            ,quantity
            ,price
            ,need_by_date
            ,organization
            ,location
            ,source_organization
			,charge_account_segment2
        ORDER BY req_line_number
        )
    );

    --Cursor to get the Requisition Distribution information

    CURSOR c_req_intf_dist (
        p_req_line_number VARCHAR2
    ) IS
    (
    SELECT * FROM
       (
        SELECT
                req_line_number_dist
                ,distribution_quantity
                ,project
                --,task
                --Fixed defect 2199
                ,DECODE(SUBSTR(task,1,1),'`',SUBSTR(task,2),SUBSTR(task,1)) task
                ,expenditure_type
                ,expenditure_org
                ,expenditure_item_date
                ,LPAD(charge_account_segment1,4,0) charge_account_segment1
                ,LPAD(charge_account_segment2,5,0) charge_account_segment2
                ,LPAD(charge_account_segment3,8,0) charge_account_segment3
                ,LPAD(charge_account_segment4,6,0) charge_account_segment4
                ,LPAD(charge_account_segment5,4,0) charge_account_segment5
                ,LPAD(charge_account_segment6,2,0) charge_account_segment6
                ,LPAD(charge_account_segment7,6,0) charge_account_segment7
        FROM
                xx_po_requisitions_stg
        WHERE   batch_id = p_batch_id
        AND     req_line_number = p_req_line_number
        GROUP BY
                req_line_number_dist
               ,distribution_quantity
               ,project
               ,task
               ,expenditure_type
               ,expenditure_org
               ,expenditure_item_date
               ,charge_account_segment1
               ,charge_account_segment2
               ,charge_account_segment3
               ,charge_account_segment4
               ,charge_account_segment5
               ,charge_account_segment6
               ,charge_account_segment7
        ORDER BY req_line_number_dist
        )
    );
    

    lc_req_type_name             po_document_types_all.type_name%TYPE;
    ln_preparer_id               per_all_people_f.person_id%TYPE;
    ln_deliver_to_requester_id   per_all_people_f.person_id%TYPE;
    lc_source_type_code          po_lookup_codes.lookup_code%TYPE;
    lc_destination_type_code     po_lookup_codes.lookup_code%TYPE;
    lc_line_type                 po_line_types_val_v.line_type%TYPE;
    ln_suggested_buyer_id        po_requisitions_interface_all.suggested_buyer_id%TYPE;
    ln_location_id               hr_locations.location_id%TYPE;
    --ln_suggested_vendor_id       po_vendors.vendor_id%TYPE;
    --ln_suggested_vendor_site_id  po_vendor_sites_all.vendor_site_id%TYPE;
    ln_item_id                   mtl_system_items_b.inventory_item_id%TYPE;
    lc_purchasing_enabled        mtl_system_items_b.purchasing_enabled_flag%TYPE;
    lc_internal_enabled          mtl_system_items_b.internal_order_enabled_flag%TYPE;
    ln_category_id               mtl_categories_b.category_id%TYPE;
    ln_derived_category_id       mtl_categories_b.category_id%TYPE;                -- Added for R1.1 CR 411 for use in defaulting CCID segments when category not specified
    ln_organization_id           hr_all_organization_units.organization_id%TYPE;
    ln_source_organization_id    hr_all_organization_units.organization_id%TYPE;
    --lc_destination_organization  hr_all_organization_units.name%TYPE;
    lc_uom                       po_requisitions_interface_all.unit_of_measure%TYPE;
    lc_item_description          po_requisitions_interface_all.item_description%TYPE;
    ln_price                     po_requisitions_interface_all.unit_price%TYPE;
    ln_quantity                  po_requisitions_interface_all.quantity%TYPE;
    ln_amount                    po_requisitions_interface_all.amount%TYPE;        -- Added for R1.1 CR 411 for Service line types
    lc_error_flag                VARCHAR2(1) := 'N';
    lc_com_error_flag            VARCHAR2(1) := 'N';
    ln_charge_account_id         gl_code_combinations.code_combination_id%TYPE;
    ln_dist_sequence_id          NUMBER;
    lc_charge_acct_seg1          po_requisitions_interface_all.charge_account_segment1%TYPE;
    lc_charge_acct_seg2          po_requisitions_interface_all.charge_account_segment2%TYPE;
    lc_charge_acct_seg3          po_requisitions_interface_all.charge_account_segment3%TYPE;
    lc_charge_acct_seg4          po_requisitions_interface_all.charge_account_segment4%TYPE;
    lc_charge_acct_seg5          po_requisitions_interface_all.charge_account_segment5%TYPE;
    lc_charge_acct_seg6          po_requisitions_interface_all.charge_account_segment6%TYPE;
    lc_charge_acct_seg7          po_requisitions_interface_all.charge_account_segment7%TYPE;
    lb_req_set                   BOOLEAN;
    lb_req_import                BOOLEAN;
    lb_req_imp_excep             BOOLEAN;
    ln_req_submit                fnd_concurrent_requests.request_id%TYPE;
    ln_conc_request_id           fnd_concurrent_requests.request_id%TYPE;
    lc_phase                     VARCHAR2(50);
    lc_status                    VARCHAR2(50);
    lc_devphase                  VARCHAR2(50);
    lc_devstatus                 VARCHAR2(50);
    lc_message                   VARCHAR2(50);
    lb_req_status                BOOLEAN;
    ln_req_imp_request_id        fnd_concurrent_requests.request_id%TYPE;
    LC_REQ_NUMBER                PO_REQUISITION_HEADERS_ALL.SEGMENT1%TYPE;
    --Added by AMD team to capture header_id of the processed requisition
    lc_req_header_id             PO_REQUISITION_HEADERS_ALL.REQUISITION_HEADER_ID%TYPE;
    ln_number                    NUMBER;
    lc_expenditure_type          pa_expenditure_types.expenditure_type%TYPE;
    lc_exp_org                   hr_all_organization_units.name%TYPE;
    lc_interface_source_code     po_requisitions_interface_all.interface_source_code%TYPE;
    ln_exp_org_id                hr_all_organization_units.organization_id%TYPE;
    lc_company                   hr_all_organization_units.name%TYPE;
    ln_sob_id                    gl_ledgers.ledger_id%TYPE;   -------------gl_sets_of_books.set_of_books_id%TYPE;  ---- #2.9  made changes for R12 retrofit by Aradhna Sharma on 18-JUL-2013
    ln_chart_of_acct_id          gl_ledgers.chart_of_accounts_id%TYPE;  --------------gl_sets_of_books.chart_of_accounts_id%TYPE;   ---- #2.9  made changes for R12 retrofit by Aradhna Sharma on 18-JUL-2013
    lc_project_Acct_context      po_req_dist_interface_all.project_accounting_context%TYPE;
    ld_expenditure_item_date     po_req_dist_interface_all.expenditure_item_date%TYPE;
    lc_email_address             per_all_people_f.email_address%TYPE;
    ln_project_id                pa_projects_all.project_id%TYPE;
    ln_task_id                   pa_tasks.task_id%TYPE;
    ln_count                     NUMBER;
    ln_req_hdr_check             NUMBER;
    ln_req_line_check            NUMBER;
    lc_msg                       VARCHAR2(200);
    lc_err_msg                   VARCHAR2(4000);
    lc_category_segment          VARCHAR2(2000);
    ln_dist_quantity             NUMBER := 0;
    EX_REQ_NOTFOUND              EXCEPTION;
    EX_REQ_HEADER                EXCEPTION;
    EX_REQ_LINE                  EXCEPTION;
    CAT_SEG_NOTFOUND             EXCEPTION;
    ln_tot_lead_time             NUMBER;
    ln_pre_time                  NUMBER;
    ln_full_time                 NUMBER;
    ln_post_time                 NUMBER;
    --ln_inv_flag                  VARCHAR2(1);
    ld_need_by_date              DATE;
    ln_customer_count            NUMBER;
    ln_inv_org_id                hr_locations.inventory_organization_id%TYPE;

    /*Start of Defect 3285*/
    lc_project_type_class_code   pa_project_types.project_type_class_code%TYPE;
    lc_service_type_code         pa_tasks.service_type_code%TYPE;

    lc_org_to_comp_val_set       pa_segment_value_lookup_sets.segment_value_lookup_set_name%TYPE;
    lc_exp_org_to_cc_val_set     pa_segment_value_lookup_sets.segment_value_lookup_set_name%TYPE;
    lc_ser_type_to_acct_val_set  pa_segment_value_lookup_sets.segment_value_lookup_set_name%TYPE;
    lc_exp_type_to_acct_val_set  pa_segment_value_lookup_sets.segment_value_lookup_set_name%TYPE;
    lc_org_to_lob_val_set        pa_segment_value_lookup_sets.segment_value_lookup_set_name%TYPE;
    lc_inter_company             po_requisitions_interface_all.charge_account_segment5%TYPE;
    lc_future                    po_requisitions_interface_all.charge_account_segment7%TYPE;
    lc_proj_type                 VARCHAR2(80);
    lc_task_billable_flag        pa_tasks.billable_flag%TYPE;

    -- Start of additions for R1.1 CR 411
    lc_balance_sheet_accout_break XX_FIN_TRANSLATEVALUES.target_value1%TYPE;
    lc_balance_sheet_cost_center  XX_FIN_TRANSLATEVALUES.target_value2%TYPE;
    lc_balance_sheet_location     XX_FIN_TRANSLATEVALUES.target_value3%TYPE;
    lc_distribution_amount        XX_PO_REQUISITIONS_STG.distribution_quantity%TYPE;
    lc_distribution_quantity      XX_PO_REQUISITIONS_STG.distribution_quantity%TYPE;
    lc_service_line_types         XX_FIN_TRANSLATEVALUES.source_value9%TYPE;
    lb_line_type_is_service       BOOLEAN;
    -- End of additions for R1.1 CR 411


    EX_ACCT_DER_TRANS_NOT_DEF    EXCEPTION;
    /*End of Defect 3285*/
	-- Changes for the defect#40571 Start
	ln_default_code_comb_id per_all_assignments_f.default_code_comb_id%TYPE;
    lc_segment2  			gl_code_combinations.segment2%TYPE;
    ln_resp_count 			NUMBER;
    lc_responsibility_name  VARCHAR2(250) := NULL;
	-- Changes for the defect#40571 End

    BEGIN

    --Parameters
    lc_error_loc := 'Printing the Parameters of the program';
    lc_error_debug := '';
    FND_FILE.PUT_LINE (fnd_file.log,'Batch ID: '||p_batch_id);

    --Get the Concurrent Program Name
    lc_error_loc   := 'Get the Concurrent Program Name';
    lc_error_debug := 'Concurrent Program id: '||fnd_global.conc_program_id;

    SELECT FCPT.user_concurrent_program_name
    INTO   gc_concurrent_program_name
    FROM   fnd_concurrent_programs_tl FCPT
    WHERE  FCPT.concurrent_program_id = fnd_global.conc_program_id
    AND    FCPT.language = 'US';

    --To check if Requisition Header detail is same for all the Requisition Line.
    lc_error_loc   := 'Check if Requisition Header detail is same for all the Requisition Line';
    lc_error_debug := '';

    ln_req_hdr_check := check_req_header(p_batch_id);

    IF (ln_req_hdr_check = 0) THEN
        RAISE EX_REQ_HEADER;
    END IF;

    IF (ln_req_hdr_check = -1) THEN
        RAISE EX_REQ_NOTFOUND;
    END IF;

    BEGIN
      lc_error_loc := 'Fetch default category segments';
      lc_error_debug := '';

      SELECT meaning
      INTO lc_category_segment
      FROM fnd_lookup_values
      WHERE lookup_type = 'XX_PO_AUTO_REQ'
      AND   lookup_code = 'CATEGORY_SEGMENTS'
      AND   enabled_flag = 'Y'
      AND   SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+2);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE CAT_SEG_NOTFOUND;
    END;

    FND_FILE.PUT_LINE (fnd_file.output,'Validation Errors');
    FND_FILE.PUT_LINE (fnd_file.output,RPAD('-',150,'-'));
    FND_FILE.PUT_LINE (fnd_file.output,RPAD('Line#',08, ' ') ||RPAD('Dist#',08, ' ')||'Error Message');
    FND_FILE.PUT_LINE (fnd_file.output,RPAD('-----',08, ' ') ||RPAD('-----',08, ' ')||'-------------');

    /*Start of Defect 3285, to get the Value set, Default Value for the Account segment from the OD Translation*/

    BEGIN

        lc_error_loc := 'Getting the Account Generator rules from the Lookup PO_AUTO_REQ_DEFAULTS';
        lc_error_debug := '';

        SELECT  UPPER(XFTV.source_value1), UPPER(XFTV.source_value2)
                ,UPPER(XFTV.source_value3), UPPER(XFTV.source_value4)
                ,UPPER(XFTV.source_value5), UPPER(XFTV.source_value6)
                ,UPPER(XFTV.source_value7),UPPER(XFTV.source_value8)
                ,',' || UPPER(XFTV.source_value9) || ',',XFTV.target_value1,XFTV.target_value2,XFTV.target_value3   -- Added for R1.1 CR 411 defect 1321
        INTO    lc_org_to_comp_val_set, lc_exp_org_to_cc_val_set
                ,lc_ser_type_to_acct_val_set,lc_exp_type_to_acct_val_set
                ,lc_org_to_lob_val_set, lc_inter_company
                ,lc_future,lc_proj_type
                ,lc_service_line_types,lc_balance_sheet_accout_break,lc_balance_sheet_cost_center,lc_balance_sheet_location -- Added for R1.1 CR 411 defect 1321
        FROM    xx_fin_translatedefinition XFTD
                ,xx_fin_translatevalues XFTV
        WHERE  XFTD.translate_id = xftv.translate_id
        AND    XFTD.translation_name = 'PO_AUTO_REQ_DEFAULTS'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND    NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND    NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN

            lc_org_to_comp_val_set := NULL;
            lc_exp_org_to_cc_val_set := NULL;
            lc_ser_type_to_acct_val_set := NULL;
            lc_exp_type_to_acct_val_set := NULL;
            lc_org_to_lob_val_set := NULL;
            lc_inter_company := NULL;
            lc_future := NULL;

    END;

    IF (lc_org_to_comp_val_set IS NULL OR lc_exp_org_to_cc_val_set IS NULL
                    OR lc_ser_type_to_acct_val_set IS NULL OR lc_exp_type_to_acct_val_set IS NULL
                    OR lc_org_to_lob_val_set IS NULL OR lc_inter_company IS NULL
                    OR lc_future IS NULL) THEN

        RAISE EX_ACCT_DER_TRANS_NOT_DEF;

    END IF;
    /*End of Defect 3285, to get the Value set, Default Value for the Account segment from the OD Translation*/

    -- Validate Each Requisition Line in Excel Sheet

    FOR lcu_req_intf_line in c_req_intf_line
    LOOP
        --Reinitializing the Local Variables
        ln_item_id := NULL;
        lc_req_type_name := NULL;
        ln_preparer_id := NULL;
        lc_source_type_code := NULL;
        ln_deliver_to_requester_id := NULL;
        lc_destination_type_code := NULL;
        lc_line_type := NULL;
        lc_uom := NULL;
        ln_location_id := NULL;
        ln_organization_id := NULL;
        --ln_suggested_vendor_id := NULL; CR # 267
        --ln_suggested_vendor_site_id := NULL;
        ln_dist_sequence_id := NULL;
        ln_category_id := NULL;
        ln_derived_category_id := NULL;
        lc_error_flag := 'N';
        lc_interface_source_code := lcu_req_intf_line.interface_source_code;
        ln_dist_quantity := 0;

        lc_item_description := NULL;
        ln_amount           := NULL; -- Added for R1.1 CR 411
        ln_quantity         := NULL; -- Added for R1.1 CR 411
        ln_price            := NULL;
        ln_source_organization_id := NULL;
        lc_purchasing_enabled := NULL;
        lc_internal_enabled   := NULL;
        ln_suggested_buyer_id :=NULL;



        ln_req_line_check := 0;


        --Requisition Type Validation
        lc_req_type_name := lcu_req_intf_line.REQUISITION_TYPE;

        BEGIN

          lc_error_loc := 'Validating Requisition Type';
          lc_error_debug := 'Requisition Type: '||lcu_req_intf_line.REQUISITION_TYPE;

          IF (lcu_req_intf_line.REQUISITION_TYPE IS NULL) THEN

              lc_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0009_REQ_BLANK');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                               ||RPAD(' ',08, ' ')||lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);

          ELSE

              SELECT document_subtype
              INTO lc_req_type_name
              FROM PO_DOCUMENT_TYPES_V
              WHERE UPPER(TYPE_NAME) = UPPER(lcu_req_intf_line.REQUISITION_TYPE) -- Added UPPER() -- defect 2845
              AND rownum = 1; -- Included this for defect 28162 in case the responsibility has MOAC enabled.

          END IF;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_error_flag := 'Y';
          FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0010_INVALID_REQ');
          lc_err_msg := FND_MESSAGE.GET;
          FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                       ||RPAD(' ',08, ' ')||lc_err_msg);

          XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_program_type            => 'CONCURRENT PROGRAM'
              ,p_program_name            => gc_concurrent_program_name
              ,p_program_id              => fnd_global.conc_program_id
              ,p_module_name             => 'PO'
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
              ,p_object_type             => 'PO Automatic Requisition'
              ,p_object_id               => lcu_req_intf_line.req_line_number);
        END;


        --Preparer Name Validation
        BEGIN

          lc_error_loc := 'Validating Preparer Name';
          lc_error_debug := 'Preparer Name: '||lcu_req_intf_line.preparer_emp_nbr;  -- defect 2845 changed column name

          IF ( lcu_req_intf_line.preparer_emp_nbr IS NULL ) THEN
              lc_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0011_PREPARER_BLANK');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                               ||RPAD(' ',08, ' ')||lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);

          ELSE

              SELECT PAPF.person_id, PAPF.email_address
              INTO   ln_preparer_id, lc_email_address
              FROM   per_all_people_f PAPF
              WHERE  sysdate between PAPF.effective_start_date and PAPF.effective_end_date
              AND    PAPF.employee_number = lcu_req_intf_line.preparer_emp_nbr; -- defect 2845 changed to employee number
              --AND    PAPF.full_name = lcu_req_intf_line.preparer_name; -- defect 2845

              -- CR# 267
              -- deliver_to_requester_id is same as Preparer id

               ln_deliver_to_requester_id := ln_preparer_id;

           END IF;

          EXCEPTION
          WHEN NO_DATA_FOUND THEN
              lc_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0012_INVALID_PREP');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                           ||RPAD(' ',08, ' ')||lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);

        END;

        -- Commented the Deliver To Requester validation for CR# 267
        --Deliver To Requestor Name Validation
        /******************************************************************************

        BEGIN

            lc_error_loc := 'Validating Requestor Name';
            lc_error_debug := 'Requisition Type: '||lcu_req_intf_line.DELIVER_TO_REQUESTOR_NAME;

            IF ( lcu_req_intf_line.deliver_to_requestor_name IS NULL ) THEN
                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0013_DELIV_BLANK');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                 ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);

             ELSE
                SELECT  PAPF.person_id
                INTO    ln_deliver_to_requester_id
                FROM    per_all_people_f PAPF
                WHERE   sysdate between PAPF.effective_start_date and PAPF.effective_end_date
                AND     PAPF.full_name = lcu_req_intf_line.deliver_to_requestor_name;
             END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0014_INVALID_DELIV');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                 ||RPAD(' ',08, ' ')||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);

        END;
        ******************************************************************************/

        -- Commented the Source Type Code Validation  for the CR# 267
        --Source Type Code Validation
        /******************************************************************************
        BEGIN

            lc_error_loc := 'Validating Requisition Source Type Code';
            lc_error_debug := 'Requisition Source Type Code: '||lcu_req_intf_line.source_type_code;

            IF ( lcu_req_intf_line.source_type_code IS NULL ) THEN

                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0015_SOURCE_BLANK');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                 ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

            ELSE

                SELECT PLC.lookup_code
                INTO   lc_source_type_code
                FROM   po_lookup_codes PLC
                WHERE  PLC.lookup_TYPE = 'REQUISITION SOURCE TYPE'
                AND    UPPER(PLC.displayed_field) = UPPER(lcu_req_intf_line.source_type_code);

             END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0016_INVALID_SOURCE');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                             ||RPAD(' ',08, ' ')||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);
        END;
        ******************************************************************************/

        -- Populate Source Type Code based on CR# 267

        IF UPPER(lcu_req_intf_line.requisition_type) = UPPER('Purchase Requisition') THEN
           lc_source_type_code:='VENDOR';
        ELSIF UPPER(lcu_req_intf_line.requisition_type) = UPPER('Internal Requisition') THEN
           lc_source_type_code:='INVENTORY';
        END IF;


        --Destination Type Code Validation  --  CR# 267
        /******************************************************************************
         BEGIN

            lc_error_loc := 'Validating Requisition Destination Type Code';
            lc_error_debug := 'Requisition Destination Type Code: '||lcu_req_intf_line.destination_type_code;

            IF ( lcu_req_intf_line.destination_type_code IS NULL ) THEN

                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0017_DEST_BLANK');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                             ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

            ELSE

                SELECT PLC.lookup_code
                INTO   lc_destination_type_code
                FROM   po_lookup_codes PLC
                WHERE  PLC.lookup_TYPE = 'DESTINATION TYPE'
                AND    UPPER(PLC.displayed_field) = UPPER(lcu_req_intf_line.destination_type_code);

            END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0018_INVALID_DEST');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                             ||RPAD(' ',08, ' ')||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);

        END;
        ******************************************************************************/

        -- Validating Requisition Line Number
        lc_error_loc   := 'Validating Requisition Line Number';
        lc_error_debug := 'Req line number::'||lcu_req_intf_line.req_line_number;

        IF (lcu_req_intf_line.req_line_number IS NULL) THEN

            lc_error_flag := 'Y';
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0002_REQ_LINENO');
            lc_err_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                             ||RPAD(' ',08, ' ')||lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               => lcu_req_intf_line.req_line_number);

        ELSE
           --To check if Requisition Line detail is same for all the Requisition Distribution.
            ln_req_line_check := check_req_line(p_batch_id,lcu_req_intf_line.req_line_number);
            IF (ln_req_line_check = 0) THEN
                RAISE EX_REQ_LINE;
            END IF;

        END IF;


        --Line Type Validation
        BEGIN

          lc_error_loc := 'Validating Line Type';
          lc_error_debug := 'Requisition Line Type: '||lcu_req_intf_line.line_type;

          IF ( lcu_req_intf_line.line_type IS NULL ) THEN

              lc_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0019_LINE_BLANK');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                           ||RPAD(' ',08, ' ')||lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);

          ELSE

              SELECT PLT.line_type
              INTO   lc_line_type
              FROM   po_line_types_val_v PLT
              WHERE  UPPER(PLT.line_type) = UPPER(lcu_req_intf_line.line_type); -- defect 2845 Added UPPER()

          END IF;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_error_flag := 'Y';
          FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0020_INVALID_LINE');
          lc_err_msg := FND_MESSAGE.GET;
          FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                              ||RPAD(' ',08, ' ')||lc_err_msg);

          XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_program_type            => 'CONCURRENT PROGRAM'
              ,p_program_name            => gc_concurrent_program_name
              ,p_program_id              => fnd_global.conc_program_id
              ,p_module_name             => 'PO'
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
              ,p_object_type             => 'PO Automatic Requisition'
              ,p_object_id               => lcu_req_intf_line.req_line_number);
        END;


        IF lc_line_type IS NOT NULL AND INSTR(lc_service_line_types,',' || UPPER(lc_line_type) || ',')>0 THEN -- Added this IF block for R1.1 CR 411 Defect 1348
          lb_line_type_is_service := TRUE;
        ELSE
          lb_line_type_is_service := FALSE;
        END IF;

        --Validating Destination Organization
        lc_error_loc := 'Validating Destination Organization';
        lc_error_debug := 'Destination Organization: '||lcu_req_intf_line.organization;

        IF (lcu_req_intf_line.organization IS NULL) THEN

            lc_error_flag := 'Y';
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0031_ORG_BLANK');
            lc_err_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                ||RPAD(' ',08, ' ')||lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               => lcu_req_intf_line.req_line_number);

        ELSE

         BEGIN
             lc_error_loc := 'Validate Destination Organization ';

             SELECT HAOU.organization_id
             INTO   ln_organization_id
             FROM   hr_all_organization_units HAOU
                   ,mtl_parameters  MP
             WHERE  HAOU.organization_id = MP.organization_id
             AND    HAOU.name  LIKE lcu_req_intf_line.organization||'%';

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            lc_error_flag := 'Y';
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0032_INVALID_ORG');
            lc_err_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                            ||RPAD(' ',08, ' ')||lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               => lcu_req_intf_line.req_line_number);

         WHEN TOO_MANY_ROWS THEN
             BEGIN
              lc_error_loc := 'Fetch Destination Organization ID for duplicate';
               SELECT organization_id
               INTO ln_organization_id
               FROM fnd_lookup_values FLV,
                    org_organization_definitions OOD
               WHERE lookup_type = 'XX_AUTO_REQ_ORG_DEFAULTS'
               AND   lookup_code = lcu_req_intf_line.organization
               AND   OOD.organization_name = FLV.meaning
               AND   enabled_flag = 'Y'
               AND   SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+2);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
               lc_error_flag := 'Y';
               FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0081_DUPLICATE_ORG');
               FND_MESSAGE.SET_TOKEN('ORG',lcu_req_intf_line.organization);
               lc_err_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                              ||RPAD(' ',08, ' ')||lc_err_msg);

               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);

            END;
         END;

        END IF;

        --Validating Location

        BEGIN

          lc_error_loc := 'Validating Location';
          lc_error_debug := 'Location: '||lcu_req_intf_line.location;

          IF (lcu_req_intf_line.location IS NULL) THEN

              lc_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0033_LOC_BLANK');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                  ||RPAD(' ',08, ' ') || lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);
          ELSE
            BEGIN
              SELECT location_id, inventory_organization_id
              INTO   ln_location_id, ln_inv_org_id  -- CR #267
              FROM   hr_locations
              WHERE  location_code LIKE lcu_req_intf_line.location||'%'; -- CR# 267. only 6 digit number will be given

              -- Check whether location is assigned to an inventory organization
              IF ln_inv_org_id IS NULL THEN
                  lc_error_flag := 'Y';
                  FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0035_LOC_ORG');
                  lc_err_msg := FND_MESSAGE.GET;
                  FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                  ||RPAD(' ',08, ' ')||lc_err_msg);

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                       p_program_type            => 'CONCURRENT PROGRAM'
                      ,p_program_name            => gc_concurrent_program_name
                      ,p_program_id              => fnd_global.conc_program_id
                      ,p_module_name             => 'PO'
                      ,p_error_message_count     => 1
                      ,p_error_message_code      => 'E'
                      ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                      ,p_error_message_severity  => 'Major'
                      ,p_notify_flag             => 'N'
                      ,p_object_type             => 'PO Automatic Requisition'
                      ,p_object_id               => lcu_req_intf_line.req_line_number);
              END IF;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lc_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0034_INVALID_LOC');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                              ||RPAD(' ',08, ' ')||lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);

            WHEN TOO_MANY_ROWS THEN
               BEGIN
                lc_error_loc := 'Fetch Destination Location ID for duplicate location';
                 SELECT HL.location_id
                 INTO ln_location_id
                 FROM fnd_lookup_values FLV,
                      hr_locations HL
                 WHERE lookup_type = 'XX_AUTO_REQ_ORG_DEFAULTS'
                 AND   lookup_code = lcu_req_intf_line.location
                 AND   HL.location_code = FLV.meaning
                 AND   FLV.enabled_flag = 'Y'
                 AND   SYSDATE BETWEEN FLV.start_date_active AND NVL(FLV.end_date_active,SYSDATE+2);
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 lc_error_flag := 'Y';
                 FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0013_DUPLICATE_LOC');
                 FND_MESSAGE.SET_TOKEN('LOC',lcu_req_intf_line.location);
                 lc_err_msg := FND_MESSAGE.GET;
                 FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                ||RPAD(' ',08, ' ')||lc_err_msg);

                 XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

              END;
            END;
          END IF;



        END;


        IF UPPER(lcu_req_intf_line.requisition_type) = UPPER('Internal Requisition') THEN

          -- Validate Source Organization id it is an Internal Requisition   -- defect 1643

          BEGIN
            lc_error_loc := 'Validating Source Organization';
            lc_error_debug := 'Source Organization : '||lcu_req_intf_line.source_organization;

            IF (lcu_req_intf_line.source_organization IS NULL) THEN

                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0075_SRCE_ORG_BLANK');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                    ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

            ELSE
              BEGIN
                SELECT organization_id
                INTO   ln_source_organization_id
                FROM   org_organization_definitions
                WHERE  organization_name LIKE lcu_req_intf_line.source_organization||'%';


              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0076_INVALID_SRCE_ORG');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                    ||RPAD(' ',08, ' ')||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);
                WHEN TOO_MANY_ROWS THEN
                  BEGIN
                    lc_error_loc := 'Fetch Source Organization ID for duplicate';

                     SELECT organization_id
                     INTO ln_source_organization_id
                     FROM fnd_lookup_values FLV,
                          org_organization_definitions OOD
                     WHERE lookup_type = 'XX_AUTO_REQ_ORG_DEFAULTS'
                     AND   lookup_code = lcu_req_intf_line.source_organization
                     AND   OOD.organization_name = FLV.meaning
                     AND   enabled_flag = 'Y'
                     AND   SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+2);

                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0081_DUPLICATE_ORG');
                    FND_MESSAGE.SET_TOKEN('ORG',lcu_req_intf_line.source_organization);
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                  ||RPAD(' ',08, ' ')||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                       p_program_type            => 'CONCURRENT PROGRAM'
                      ,p_program_name            => gc_concurrent_program_name
                      ,p_program_id              => fnd_global.conc_program_id
                      ,p_module_name             => 'PO'
                      ,p_error_message_count     => 1
                      ,p_error_message_code      => 'E'
                      ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                      ,p_error_message_severity  => 'Major'
                      ,p_notify_flag             => 'N'
                      ,p_object_type             => 'PO Automatic Requisition'
                      ,p_object_id               => lcu_req_intf_line.req_line_number);

                  END;
               END;
            END IF;
          END;

          -- Validate whether destination location is assigned to any customer
          -- for an Internal Requisition -- CR# 267
          BEGIN
            lc_error_loc := 'Check if location is associated to customer';
            lc_error_debug := 'Location::'||lcu_req_intf_line.location;

            SELECT COUNT(customer_id)
            INTO ln_customer_count
            FROM po_location_associations_all
            WHERE location_id = ln_location_id;

            IF ln_customer_count = 0 THEN

               lc_error_flag := 'Y';
               FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0079_DESTLOC_CUSTOMER');
               lc_err_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                              ||RPAD(' ',08, ' ')||lc_err_msg);

               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);

            END IF;

          END;

        END IF;


        --Line Quantity Validation
        BEGIN
          lc_error_loc := 'Validating Line Quantity';
          lc_error_debug := 'Quantity: '||lcu_req_intf_line.quantity;

          ln_number := to_number(lcu_req_intf_line.quantity);
          ln_quantity := ln_number;  -- Added for R1.1 CR 411

          IF (lcu_req_intf_line.quantity <= 0 AND NOT lb_line_type_is_service) THEN -- Added AND NOT lb_line_type_is_service for R1.1 CR 411

              lc_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0006_QUAN_VALUE');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                               ||RPAD(' ',08, ' ')||lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);


          ELSIF (lcu_req_intf_line.quantity IS NULL AND NOT lb_line_type_is_service) THEN -- Added AND NOT lb_line_type_is_service for R1.1 CR 411

              lc_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0007_QUAN_BLANK');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                               ||RPAD(' ',08, ' ')||lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);
          END IF;

        EXCEPTION
          WHEN VALUE_ERROR THEN
              lc_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0008_QUAN_NO');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                               ||RPAD(' ',08, ' ')||lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => gc_concurrent_program_name
                  ,p_program_id              => fnd_global.conc_program_id
                  ,p_module_name             => 'PO'
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'PO Automatic Requisition'
                  ,p_object_id               => lcu_req_intf_line.req_line_number);

        END;


        -- Check for Item and Item Attributes
        IF (lcu_req_intf_line.item IS NOT NULL) THEN

            --Item Validation
            BEGIN

                lc_error_loc := 'Validating Item';
                lc_error_debug := 'Requisition Item: '||lcu_req_intf_line.item ;

                -- CR# 267
                --  Validating whether Item is assigned to destination organization and other attributes of item

                SELECT  MSI.inventory_item_id
                       ,MSI.purchasing_enabled_flag
                       ,MSI.internal_order_enabled_flag
                       ,NVL (MSI.preprocessing_lead_time,0)
                       ,NVL (MSI.full_lead_time,0)
                       ,NVL (MSI.postprocessing_lead_time,0)
                INTO   ln_item_id
                      ,lc_purchasing_enabled
                      ,lc_internal_enabled
                      ,ln_pre_time
                      ,ln_full_time
                      ,ln_post_time
                FROM   mtl_system_items_b MSI
                WHERE  MSI.segment1 = lcu_req_intf_line.item
                AND    MSI.organization_id = ln_organization_id;

                -- CR# 267
                -- Need By date is calculated if item is given based on item attributes.
                IF UPPER(lcu_req_intf_line.requisition_type) = UPPER('Purchase Requisition') THEN
                   ln_tot_lead_time := ln_pre_time + ln_full_time + ln_post_time;
                   ld_need_by_date := TO_DATE(TO_CHAR(TRUNC(SYSDATE + ln_tot_lead_time),'MM/DD/YYYY')||' 23:59:59','MM/DD/YYYY HH24:MI:SS');
                ELSIF UPPER(lcu_req_intf_line.requisition_type) = UPPER('Internal Requisition') THEN
                   ld_need_by_date := SYSDATE;
                END IF;


                -- CR# 267
                --Validating whether item is purchasing enabled
                IF UPPER(lcu_req_intf_line.requisition_type) = UPPER('Purchase Requisition') THEN
                   IF lc_purchasing_enabled = 'N' THEN

                      lc_error_flag := 'Y';
                      FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0078_PURCH_ENABLED');
                      lc_err_msg := FND_MESSAGE.GET;
                      FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                     ||RPAD(' ',08, ' ')||lc_err_msg);

                       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                          p_program_type            => 'CONCURRENT PROGRAM'
                         ,p_program_name            => gc_concurrent_program_name
                         ,p_program_id              => fnd_global.conc_program_id
                         ,p_module_name             => 'PO'
                         ,p_error_message_count     => 1
                         ,p_error_message_code      => 'E'
                         ,p_error_message           => lc_err_msg
                         ,p_error_message_severity  => 'Major'
                         ,p_notify_flag             => 'N'
                         ,p_object_type             => 'PO Automatic Requisition'
                         ,p_object_id               => lcu_req_intf_line.req_line_number);

                   END IF;
                END IF;

                -- CR# 267
                --Validating whether item is internal order enabled
                IF UPPER(lcu_req_intf_line.requisition_type) = UPPER('Internal Requisition') THEN
                   IF lc_internal_enabled = 'N' THEN

                      lc_error_flag := 'Y';
                      FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0082_INTERNAL_ENABLED');
                      lc_err_msg := FND_MESSAGE.GET;
                      FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                     ||RPAD(' ',08, ' ')||lc_err_msg);

                       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                          p_program_type            => 'CONCURRENT PROGRAM'
                         ,p_program_name            => gc_concurrent_program_name
                         ,p_program_id              => fnd_global.conc_program_id
                         ,p_module_name             => 'PO'
                         ,p_error_message_count     => 1
                         ,p_error_message_code      => 'E'
                         ,p_error_message           => lc_err_msg
                         ,p_error_message_severity  => 'Major'
                         ,p_notify_flag             => 'N'
                         ,p_object_type             => 'PO Automatic Requisition'
                         ,p_object_id               => lcu_req_intf_line.req_line_number);

                   END IF;
                END IF;

            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0021_INVALID_ITEM');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                    ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

            END;

                -- CR# 267
                -- The following values should be null if item is given
                lc_item_description := NULL;
                ln_price            := NULL;
                lc_uom              := NULL;
                ln_category_id      := NULL;

        ELSE -- lcu_req_intf_line.item IS NULL

            -- CR# 267
            -- Item should be provided if it is an Internal Requisition
                  IF (UPPER(lcu_req_intf_line.requisition_type) = UPPER('Internal Requisition')) THEN

                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0022_ITEM_INV');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                        ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

            END IF;

            -- Validating Category
            IF lcu_req_intf_line.category IS NULL THEN

               lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0024_ITEM_CAT');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                        ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

            ELSE

               BEGIN
                 lc_error_loc:='Category validation';
                 lc_error_debug:='Seg1::'||lcu_req_intf_line.category||'Remaining::'||lc_category_segment;
                 SELECT category_id
                 INTO   ln_category_id
                 FROM   mtl_categories
                 WHERE  segment1||'.'||segment2||'.'||segment3||'.'
                                   ||segment4||'.'||segment5 =
                                      -- CR# 267
                                       lcu_req_intf_line.category || '.' || lc_category_segment;

               EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0023_INVALID_ITEM_CAT');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                        ||RPAD(' ',08, ' ')||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);
               END;

            END IF;

            --Validating Item Description
            IF (lcu_req_intf_line.item_description IS NULL) THEN

                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0025_ITEM_DESC');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                        ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

            END IF;


            -- Unit Price Validation
            BEGIN

                lc_error_loc := 'Validating Price for a non-catalog requisition';
                lc_error_debug := 'Price: '||lcu_req_intf_line.price;

                ln_number := to_number(lcu_req_intf_line.price);

                IF (lcu_req_intf_line.price <= 0) THEN

                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0003_PRICE_VALUE');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                     ||RPAD(' ',08, ' ')||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);

                ELSIF (lcu_req_intf_line.price IS NULL) THEN

                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0004_PRICE_BLANK');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.log, lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);

                END IF;

            EXCEPTION
                WHEN VALUE_ERROR THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0005_PRICE_NO');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                     ||RPAD(' ',08, ' ')||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);

            END;

            --CR# 267
            -- Item Description and price should be populated from excel sheet for Non-Catalog Requisition
            lc_item_description := lcu_req_intf_line.item_description;
            ln_price            := lcu_req_intf_line.price;
            ld_need_by_date     := lcu_req_intf_line.need_by_date;

            IF NOT lb_line_type_is_service THEN -- Added for R1.1 CR 411 --> Service line types should not validate UOM.
              ---Validating Unit of Measure

              IF (lcu_req_intf_line.unit_of_measure IS NOT NULL) THEN
                BEGIN

                    lc_error_loc := 'Checking for Unit of Measure';
                    lc_error_debug := 'Unit of Measure: '||lcu_req_intf_line.unit_of_measure;

                    SELECT unit_of_measure
                    INTO   lc_uom
                    -- FROM   mtl_uom_conversions_val_v         -- commented out for defect 18178
				    FROM MTL_UNITS_OF_MEASURE  -- modified for defect 18178
                    WHERE  UPPER(unit_of_measure) = UPPER(lcu_req_intf_line.unit_of_measure)  -- defect 2845 Added UPPER()
					AND NVL(DISABLE_DATE,SYSDATE+1)    > SYSDATE  ; -- Added for defect 18178

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lc_error_flag := 'Y';
                        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0026_INVALID_UOM');
                        lc_err_msg := FND_MESSAGE.GET;
                        FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                        ||RPAD(' ',08, ' ')||lc_err_msg);

                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                             p_program_type            => 'CONCURRENT PROGRAM'
                            ,p_program_name            => gc_concurrent_program_name
                            ,p_program_id              => fnd_global.conc_program_id
                            ,p_module_name             => 'PO'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      => 'E'
                            ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                            ,p_error_message_severity  => 'Major'
                            ,p_notify_flag             => 'N'
                            ,p_object_type             => 'PO Automatic Requisition'
                            ,p_object_id               => lcu_req_intf_line.req_line_number);

                END;

              ELSE

                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0027_ITEM_UOM');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                    ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

              END IF;
            END IF;

            -- Need By Date validation -- CR# 267
            IF (lcu_req_intf_line.need_by_date IS NULL) THEN

                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0039_NEED_DATE_BLANK');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                  ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);
            END IF;

        END IF;    --Completing Item and Item Attributes validation for catalog as well as Non-Catalog requisitions


        --Validating Buyer

        BEGIN

             --CR# 267
             -- commented buyer validation
             /*****************************************************************************
             lc_error_loc := 'Validating Buyer';
             lc_error_debug := 'Requisition Buyer: '||lcu_req_intf_line.buyer;

            IF (lcu_req_intf_line.buyer IS NULL) THEN

                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0029_BUYER_BLANK');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                    ||RPAD(' ',08, ' ')||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

            ELSE

                SELECT agent_id
                INTO   ln_suggested_buyer_id
                FROM   po_agents_v
                WHERE  agent_name = lcu_req_intf_line.buyer;
            END IF;
             ******************************************************************************/


          --CR# 267
          -- Buyer ID will be defaulted based on the category and the org id

          lc_error_loc := 'Fetching Buyer';
          lc_error_debug:='';
          -- Defect 39900
		  IF lc_source_type_code <> 'INVENTORY' 
		  THEN
          IF lcu_req_intf_line.item IS NULL THEN

            SELECT XICA.buyer_id
            INTO   ln_suggested_buyer_id
            FROM   xx_icx_cat_atts_by_org XICA
            WHERE  XICA.org_id      = FND_PROFILE.VALUE('ORG_ID')
            AND    XICA.category_id = ln_category_id
			AND    XICA.buyer_id = (SELECT PA.agent_id FROM po_agents PA                           --Added condition for defect# 28774 
                                WHERE SYSDATE between nvl(PA.start_date_active, sysdate-1)
                                                  and nvl(PA.end_date_active, sysdate+1)
                                  AND PA.agent_id = XICA.buyer_id);

          ELSE
            SELECT XICA.buyer_id
            INTO  ln_suggested_buyer_id
            FROM   mtl_item_categories MIC
                  ,mtl_category_sets MCS
                  ,xx_icx_cat_atts_by_org XICA
            WHERE MIC.category_set_id = MCS.category_set_id
            AND   XICA.category_id = MIC.category_id
            AND   XICA.org_id      = FND_PROFILE.VALUE('ORG_ID')
            AND   MIC.inventory_item_id = ln_item_id
            AND   MIC.organization_id = ln_organization_id
            AND   MCS.category_set_name = 'PO CATEGORY'
			AND    XICA.buyer_id = (SELECT PA.agent_id FROM po_agents PA                         --Added condition for defect# 28774
                                WHERE SYSDATE between nvl(PA.start_date_active, sysdate-1)
                                                  and nvl(PA.end_date_active, sysdate+1)
                                  AND PA.agent_id = XICA.buyer_id);

          END IF;
		  END IF;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_error_flag := 'Y';
          FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0030_INVALID_BUYER');
          lc_err_msg := FND_MESSAGE.GET;
          FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                          ||RPAD(' ',08, ' ')||lc_err_msg);

          XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_program_type            => 'CONCURRENT PROGRAM'
              ,p_program_name            => gc_concurrent_program_name
              ,p_program_id              => fnd_global.conc_program_id
              ,p_module_name             => 'PO'
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
              ,p_object_type             => 'PO Automatic Requisition'
              ,p_object_id               => lcu_req_intf_line.req_line_number);

        END;


        --Commented Validating Supplier for CR# 267
                /******************************************************************************
        --Fixed defect 1643 - Start
        IF UPPER(lcu_req_intf_line.requisition_type) = 'PURCHASE REQUISITION' THEN


                BEGIN
                    lc_error_loc := 'Validating Supplier';
                    lc_error_debug := 'Supplier: '||lcu_req_intf_line.supplier_name;

                    IF (lcu_req_intf_line.supplier_name IS NULL) THEN
                        lc_error_flag := 'Y';
                        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0035_SUPP_BLANK');
                        lc_err_msg := FND_MESSAGE.GET;
                        FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                            ||RPAD(' ',08, ' ')||lc_err_msg);
                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                             p_program_type            => 'CONCURRENT PROGRAM'
                            ,p_program_name            => gc_concurrent_program_name
                            ,p_program_id              => fnd_global.conc_program_id
                            ,p_module_name             => 'PO'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      => 'E'
                            ,p_error_message           => lc_err_msg
                            ,p_error_message_severity  => 'Major'
                            ,p_notify_flag             => 'N'
                            ,p_object_type             => 'PO Automatic Requisition'
                            ,p_object_id               => lcu_req_intf_line.req_line_number);
                    ELSE
                        SELECT PV.vendor_id
                        INTO   ln_suggested_vendor_id
                        FROM   po_vendors PV
                        WHERE  PV.vendor_name = lcu_req_intf_line.supplier_name;
                    END IF;

                    --Validating Supplier Site
                    BEGIN
                        lc_error_loc := 'Validating Supplier Site';
                        lc_error_debug := 'Supplier Site: '||lcu_req_intf_line.supplier_site;
                        IF (lcu_req_intf_line.supplier_site IS NULL) THEN
                            lc_error_flag := 'Y';
                            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0036_SUPP_SITE_BLANK');
                            lc_err_msg := FND_MESSAGE.GET;
                            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                            ||RPAD(' ',08, ' ')||lc_err_msg);
                            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);

                        ELSE

                            SELECT PVSA.vendor_site_id
                            INTO   ln_suggested_vendor_site_id
                            FROM   po_vendors PV
                                  ,po_vendor_sites_all PVSA
                            WHERE  PV.vendor_name = lcu_req_intf_line.supplier_name
                            AND    PVSA.vendor_site_code = lcu_req_intf_line.supplier_site
                            AND    PV.vendor_id = PVSA.vendor_id;

                         END IF;

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            lc_error_flag := 'Y';
                            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0037_INVALID_SUPP_SITE');
                            lc_err_msg := FND_MESSAGE.GET;
                            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                            ||RPAD(' ',08, ' ')||lc_err_msg);

                            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);

                    END;

                EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            lc_error_flag := 'Y';
                            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0038_INVALID_SUPP');
                            lc_err_msg := FND_MESSAGE.GET;
                            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                            ||RPAD(' ',08, ' ')||lc_err_msg);

                            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);

                END;

        END IF; -- defect 1643
        ******************************************************************************/
		
		-- Changes for the defect#40571 --Preparer Cost Center Validation
        BEGIN

          lc_error_loc := 'Validating Requisition Preparer Cost Center';
          lc_error_debug := 'Preparer Charge Account : '||lcu_req_intf_line.charge_account_segment2
		                    ||' and '||' Preparer : '||lcu_req_intf_line.preparer_emp_nbr;  
		  
		  ln_resp_count := 0;
		  lc_responsibility_name := NULL;
		
		  BEGIN
		    SELECT responsibility_name
		    INTO lc_responsibility_name
		    FROM fnd_responsibility_tl
		    WHERE responsibility_id = fnd_global.resp_id;
		  EXCEPTION WHEN OTHERS THEN
		   fnd_file.put_line(fnd_file.log,'Error while getting the responsiblity_name');
		    lc_responsibility_name := NULL;
		  END;
		  --fnd_file.put_line(fnd_file.log,' Logged In Responsibility Name '||lc_responsibility_name);
		
		  -- Checking current responsibility for cost center validation is required or not
		  SELECT count(1)
		  INTO ln_resp_count
		  FROM   xx_fin_translatedefinition xftd
			    ,xx_fin_translatevalues xftv
			    ,fnd_responsibility_tl frt
		  WHERE xftd.translate_id = xftv.translate_id
		  AND   xftd.TRANSLATION_NAME = 'XX_PO_AUTO_REQ_RESP_LIST'
		  AND   xftv.source_value1 = 'COST_CENTER'
		  AND   xftv.TARGET_VALUE1 = frt.RESPONSIBILITY_NAME
		  AND   frt.responsibility_id = fnd_global.resp_id
		  AND   sysdate BETWEEN xftv.start_date_active AND    NVL(xftv.end_date_active,sysdate+1)
		  AND   sysdate BETWEEN xftd.start_date_active AND    NVL(xftd.end_date_active,sysdate+1)
		  AND   xftv.ENABLED_FLAG = 'Y'
		  AND   xftd.enabled_flag = 'Y';

	     ln_default_code_comb_id := NULL;
	     lc_segment2 := NULL;
	   
	     -- Checking Logged in Responslibility Name with the list of responsiblities defined in Transations
	     IF lcu_req_intf_line.charge_account_segment2 IS NOT NULL AND ln_resp_count = 0  --If it matched Skip this validation
	     THEN
		   BEGIN
		     SELECT default_code_comb_id 
		     INTO ln_default_code_comb_id
		     FROM per_all_assignments_f
		     WHERE assignment_number = lcu_req_intf_line.preparer_emp_nbr;
		   EXCEPTION WHEN NO_DATA_FOUND THEN
		     ln_default_code_comb_id := NULL;
		   WHEN OTHERS THEN
		     ln_default_code_comb_id := NULL;
		     fnd_file.put_line(fnd_file.log,'Error while getting the default Code Combination Id :'||SQLERRM);
		   END;
		   BEGIN
		     SELECT segment2
		     INTO lc_segment2
		     FROM gl_code_combinations
		     WHERE code_combination_id = ln_default_code_comb_id;
		   EXCEPTION WHEN NO_DATA_FOUND THEN
		     lc_segment2 := NULL;
		   WHEN OTHERS THEN
		     lc_segment2 := NULL;
		     fnd_file.put_line(fnd_file.log,'Error while getting the Cost Center code (Segment2) :'||SQLERRM);
		   END;
	     END IF;
	   
	     IF NVL(lcu_req_intf_line.charge_account_segment2,'XX') <> NVL(lc_segment2,'XX') AND ln_resp_count = 0  --If it matched Skip it
	     THEN
		   lc_err_msg := 'Requisition is not created because Cost Center details(Req Cost Center : '||lcu_req_intf_line.charge_account_segment2||') is not same as default cost center '||lc_segment2||' for Preparer '||lcu_req_intf_line.preparer_emp_nbr;
		   fnd_file.put_line(fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')||RPAD(' ',08, ' ')||lc_err_msg);
		   
		   lc_error_flag := 'Y';
		   
           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               => lcu_req_intf_line.req_line_number);
		  END IF;
        END;
		--- Changes for the defect#40571  End.


        --Inserting into the Interface table PO_REQUISITIONS_INTERFACE_ALL, only if there no Validation error for that line.

        IF (lc_error_flag <> 'Y') THEN

            --Generating Interface Distribution sequence id from PO_REQ_DIST_INTERFACE_S

            lc_error_loc := 'Generating Interface Distribution sequence id from PO_REQ_DIST_INTERFACE_S';
            lc_error_debug := '';


            IF lb_line_type_is_service THEN              -- Start of R1.1 CR 411 Defect 1348
              ln_amount        := ln_price;
              ln_price         := null;
              ln_quantity      := null;
              ln_dist_quantity := null;
              lc_uom           := null;
            END IF;                                       -- End of R1.1 CR 411 Defect 1348


            SELECT PO_REQ_DIST_INTERFACE_S.nextval
            INTO   ln_dist_sequence_id
            FROM SYS.dual;

            lc_error_loc := 'Inserting into PO_REQUISITIONS_INTERFACE_ALL';
            lc_error_debug := 'Requisition Line No: '||lcu_req_intf_line.req_line_number;

            --Inserting into PO_REQUISITIONS_INTERFACE_ALL
            INSERT INTO po_requisitions_interface_all
            (
                requisition_type
                ,preparer_id
                ,interface_source_code
                ,source_type_code
                ,deliver_to_requestor_id
                ,destination_type_code
                ,authorization_status
                ,header_description
                ,line_type
                ,item_id
                ,category_id
                ,item_description
                ,unit_of_measure
                ,quantity
                ,unit_price
                ,amount              --added for R1.1 CR 411
                ,need_by_date
                ,suggested_buyer_id
                ,deliver_to_location_id
                ,source_organization_id
                ,destination_organization_id
                ,req_dist_sequence_id
                ,multi_distributions
                ,batch_id
                ,group_code
                ,org_id
                ,interface_source_line_id  -- defect 2322
            )
            VALUES
            (
                 lc_req_type_name
                ,ln_preparer_id
                ,lcu_req_intf_line.interface_source_code
                ,lc_source_type_code
                ,ln_deliver_to_requester_id
                ,lcu_req_intf_line.destination_type_code -- CR# 267
                ,'INCOMPLETE'
                ,lcu_req_intf_line.req_description
                ,lc_line_type
                ,ln_item_id
                ,ln_category_id
                ,lc_item_description  --,lcu_req_intf_line.item_description -- CR# 267
                ,lc_uom
                ,ln_quantity         --,lcu_req_intf_line.quantity -- Changed for R1.1 CR 411
                ,ln_price            --,lcu_req_intf_line.price  -- CR# 267
                ,ln_amount           -- Added for R1.1 CR 411
                ,ld_need_by_date     --,lcu_req_intf_line.need_by_date -- CR# 267
                ,ln_suggested_buyer_id
                ,ln_location_id
                ,ln_source_organization_id -- Fixed Defect 1643
                ,ln_organization_id
                ,ln_dist_sequence_id
                ,'Y'
                ,p_batch_id
                ,p_batch_id
                ,fnd_profile.value('ORG_ID')
                ,lcu_req_intf_line.req_line_number   -- defect 2322
            );
        ELSE

            lc_com_error_flag := 'Y';

        END IF;

        --Opening the Distribution Cursor for the particular Distribution Line
        ln_dist_quantity:=0;

        lc_error_loc := 'looping for distributions';
        lc_error_debug := 'Requisition Line No: '||lcu_req_intf_line.req_line_number;

        FOR lcu_req_intf_dist IN c_req_intf_dist (lcu_req_intf_line.req_line_number)
        LOOP

            --Reinitializing the Local Variables

            ln_exp_org_id := NULL;
            lc_project_Acct_context := NULL;
            ln_project_id := NULL;
            ln_task_id := NULL;
            ln_charge_account_id := NULL;
            lc_company := NULL;
            lc_exp_org := NULL;
            ld_expenditure_item_date := NULL;
            lc_charge_acct_seg1 := NULL;
            lc_charge_acct_seg2 := NULL;
            lc_charge_acct_seg3 := NULL;
            lc_charge_acct_seg4 := NULL;
            lc_charge_acct_seg5 := NULL;
            lc_charge_acct_seg6 := NULL;
            lc_charge_acct_seg7 := NULL;
            lc_expenditure_type := NULL;
            lc_distribution_amount   := NULL; -- Added for R1.1 CR 411 Defect 2973
            lc_distribution_quantity := lcu_req_intf_dist.distribution_quantity; -- Added for R1.1 CR 411 Defect 1348

            --Validating Requisition Distribution Number
            BEGIN

                lc_error_loc := 'Validating Requisition Distribution Number';
                lc_error_debug := 'Requisition Distribution No: '||lcu_req_intf_dist.req_line_number_dist;

                ln_number := to_number(lcu_req_intf_dist.req_line_number_dist);

                IF (lcu_req_intf_dist.req_line_number_dist IS NULL) THEN

                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0040_DIST_LIN_BLANK');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                          ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                          ||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);

                END IF;

            EXCEPTION
                WHEN VALUE_ERROR THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0041_DIST_NO');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                          ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                          ||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);
            END;

            --Validating  Distribution Quantity
            IF lb_line_type_is_service THEN -- Added Service line type distribution quantity validation exclusion for R1.1 CR 411 Defect 1348
              lc_distribution_amount := lc_distribution_quantity;
              lc_distribution_quantity := NULL;
            ELSE
              BEGIN

                lc_error_loc := 'Validating Requisition Distribution Quantity';
                lc_error_debug := 'Requisition Distribution Quantity: '||lcu_req_intf_dist.distribution_quantity;

                ln_number := to_number(lcu_req_intf_dist.distribution_quantity);

                IF (lcu_req_intf_dist.distribution_quantity <= 0) THEN

                  lc_error_flag := 'Y';
                  FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0042_DIST_QUAN_VALUE');
                  lc_err_msg := FND_MESSAGE.GET;
                  FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                        ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                        ||lc_err_msg);

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                       p_program_type            => 'CONCURRENT PROGRAM'
                      ,p_program_name            => gc_concurrent_program_name
                      ,p_program_id              => fnd_global.conc_program_id
                      ,p_module_name             => 'PO'
                      ,p_error_message_count     => 1
                      ,p_error_message_code      => 'E'
                      ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                      ,p_error_message_severity  => 'Major'
                      ,p_notify_flag             => 'N'
                      ,p_object_type             => 'PO Automatic Requisition'
                      ,p_object_id               => lcu_req_intf_line.req_line_number);


                ELSIF (lcu_req_intf_dist.distribution_quantity IS NULL) THEN

                  lc_error_flag := 'Y';
                  FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0043_DIST_QUAN_BLANK');
                  lc_err_msg := FND_MESSAGE.GET;
                  FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                      ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                      ||lc_err_msg);

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

                END IF;

                ln_dist_quantity := ln_dist_quantity + nvl(ln_number,0);

              EXCEPTION
                  WHEN VALUE_ERROR THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0008_QUAN_NO');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                          ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                          ||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);
              END;
            END IF;

            --Checking for Project,  Charge Account
            IF (lcu_req_intf_dist.project IS NULL) THEN

              IF ln_category_id IS NULL THEN -- For R1.1 CR 411, added this block to lookup category when only item is given (for use in CHARGE_ACCT_RULE_SEG_VAL)
                BEGIN
                  SELECT category_id
                  INTO   ln_derived_category_id
                  FROM   mtl_item_categories MC
                        ,mtl_category_sets_tl MCS                        --Added for defect 5338
                  WHERE  MC.inventory_item_id    = ln_item_id
                  AND    MC.organization_id      = ln_organization_id
                  AND    MC.CATEGORY_SET_ID      = MCS.CATEGORY_SET_ID   --Added for defect 5338
                  AND    MCS.CATEGORY_SET_NAME   = gc_category;          --Added for defect 5338
                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN                              --Added for defect 5338
                       FND_FILE.PUT_LINE (fnd_file.log,'Fetching Too many rows when deriving the derived_category_id value ');

                    WHEN OTHERS THEN
                      NULL; -- not fatal
                END;
              END IF;

              -- CR# 267
              lc_charge_acct_seg1 := lcu_req_intf_dist.charge_account_segment1;
              lc_charge_acct_seg2 := CHARGE_ACCT_RULE_SEG_VAL(NVL(ln_category_id,ln_derived_category_id),'SEGMENT2',lcu_req_intf_dist.charge_account_segment2); -- Updated for R1.1 CR411 prod defect 1137
              lc_charge_acct_seg3 := CHARGE_ACCT_RULE_SEG_VAL(NVL(ln_category_id,ln_derived_category_id),'SEGMENT3',lcu_req_intf_dist.charge_account_segment3); -- Updated for R1.1 CR411 prod defect 1137
              lc_charge_acct_seg4 := lcu_req_intf_dist.charge_account_segment4;
              lc_charge_acct_seg5 := lcu_req_intf_dist.charge_account_segment5;
              lc_charge_acct_seg6 := lcu_req_intf_dist.charge_account_segment6;
              lc_charge_acct_seg7 := lcu_req_intf_dist.charge_account_segment7;

              IF (lc_charge_acct_seg1 IS NULL OR
                  lc_charge_acct_seg2 IS NULL OR
                  lc_charge_acct_seg3 IS NULL OR
                  lc_charge_acct_seg4 IS NULL OR
                  lc_charge_acct_seg5 IS NULL OR
                  lc_charge_acct_seg6 IS NULL OR
                  lc_charge_acct_seg7 IS NULL  )
              THEN
                lc_error_flag := 'Y';
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0044_PROJ_CA_BLANK');
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                          ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                          ||lc_err_msg);

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'PO'
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'PO Automatic Requisition'
                    ,p_object_id               => lcu_req_intf_line.req_line_number);

              END IF;

            ELSE -- lcu_req_intf_dist.project IS NOT NULL

                lc_project_Acct_context := 'Y';

                /*
                IF (lcu_req_intf_line.item IS NULL) THEN
                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0045_ITEM_PROJ_BLANK');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                          ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                          ||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);

                END IF;
                */

                IF (lcu_req_intf_dist.task IS NULL OR lcu_req_intf_dist.expenditure_type IS NULL
                        OR lcu_req_intf_dist.expenditure_org IS NULL OR lcu_req_intf_dist.expenditure_item_date IS NULL) THEN

                    lc_error_flag := 'Y';
                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0046_PROJ_PROVIDED');
                    lc_err_msg := FND_MESSAGE.GET;
                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                          ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                          ||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);


                ELSE
                    --Get the Project Organization, Project Type
                    BEGIN

                        lc_error_loc := 'Validating Project';
                        lc_error_debug := 'Project: '|| lcu_req_intf_dist.project;

                        SELECT -- HAOU.name  -- Commented for Defect # 5313
                               pp.project_id, ppt.project_type_class_code
                        INTO   -- lc_company  -- Commented for Defect # 5313
                               ln_project_id, lc_project_type_class_code
                        FROM   pa_projects PP
                              ,hr_all_organization_units HAOU
                              ,pa_project_types PPT                  --Defect 3285
                        WHERE PP.carrying_out_organization_id = HAOU.organization_id
                        AND   UPPER(PP.segment1) = UPPER(lcu_req_intf_dist.project) -- defect 2845 Added UPPER()
                        AND   PP.project_type = PPT.project_type;    --Defect 3285

                         --Validation the Task Number, of the Project
                        BEGIN

                            lc_error_loc := 'Validating Project Task';
                            lc_error_debug := 'Project Task: '||lcu_req_intf_dist.task;

                            SELECT task_id
                                   ,service_type_code     --Defect 3285
                                   ,billable_flag         --Defect 3285
                            INTO   ln_task_id
                                   ,lc_service_type_code  --Defect 3285
                                   ,lc_task_billable_flag --Defect 3285
                            FROM   pa_tasks
                            WHERE  project_id = ln_project_id
                            AND    task_number = lcu_req_intf_dist.task;

                            --Getting the Company (Segment1 of  Charge Account), from the Project Orgnanization

/*****************R 1.4  QC DefectID# 5313 Fix****************Start****************/
                        SELECT HAOU.name
                        INTO   lc_company
                        FROM   hr_all_organization_units HAOU
                             , pa_tasks                  PAT
                        WHERE PAT.carrying_out_organization_id = HAOU.organization_id
                        AND   PAT.task_id= ln_task_id;

/*****************R 1.4  QC DefectID# 5313 Fix****************End****************/
                            BEGIN

                                lc_error_loc := 'Deriving the Company Segment from Project Organization';
                                lc_error_debug := 'Project Organization: '||lc_company;

                                /*SELECT  segment_value
                                INTO  lc_charge_acct_seg1
                                FROM  pa_segment_value_lookups PVL,
                                      pa_segment_value_lookup_sets PVLS
                                WHERE PVLS.segment_value_lookup_set_id = PVL.segment_value_lookup_set_id
                                AND  PVLS.segment_value_lookup_set_name = 'Organization to Company'
                                AND  PVL.segment_value_lookup = lc_company;*/

                                --Fixed defect 2199 -Start

                                SELECT  segment_value
                                INTO  lc_charge_acct_seg1
                                FROM  pa_segment_value_lookups PVL,
                                      pa_segment_value_lookup_sets PVLS
                                WHERE PVLS.segment_value_lookup_set_id = PVL.segment_value_lookup_set_id
                                AND  UPPER(PVLS.segment_value_lookup_set_name) = lc_org_to_comp_val_set
                                AND  PVL.segment_value_lookup = lc_company;

                                --Fixed defect 2199 -End

                            EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                    lc_error_flag := 'Y';
                                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0047_PROJ_NOT_DEF');
                                    lc_err_msg := FND_MESSAGE.GET;
                                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                                        ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                                        ||lc_err_msg);

                                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                         p_program_type            => 'CONCURRENT PROGRAM'
                                        ,p_program_name            => gc_concurrent_program_name
                                        ,p_program_id              => fnd_global.conc_program_id
                                        ,p_module_name             => 'PO'
                                        ,p_error_message_count     => 1
                                        ,p_error_message_code      => 'E'
                                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                        ,p_error_message_severity  => 'Major'
                                        ,p_notify_flag             => 'N'
                                        ,p_object_type             => 'PO Automatic Requisition'
                                        ,p_object_id               => lcu_req_intf_line.req_line_number);

                            END;

                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            lc_error_flag := 'Y';
                            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0048_INVALID_TASK_NO');
                            lc_err_msg := FND_MESSAGE.GET;
                            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                                     ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                                     ||lc_err_msg);

                            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);

                        END;


                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            lc_error_flag := 'Y';
                            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0051_INVALID_PROJ');
                            lc_err_msg := FND_MESSAGE.GET;
                            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                                         ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                                         ||lc_err_msg);

                            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);

                    END;

                END IF;

                --Validating Expenditure Type

                BEGIN

                    lc_error_loc := 'Validating Expenditure Type';
                    lc_error_debug := 'Expenditure Type: '||lcu_req_intf_dist.expenditure_type;

                    SELECT expenditure_type
                    INTO   lc_expenditure_type
                    FROM   pa_expenditure_types
                    WHERE  UPPER(expenditure_type) =
                             UPPER(lcu_req_intf_dist.expenditure_type);-- defect 2845  Added UPPER()

                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lc_error_flag := 'Y';
                        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0055_INVALID_EXP_TYPE');
                        lc_err_msg := FND_MESSAGE.GET;
                        FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                        ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                        ||lc_err_msg);

                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);

                END;

                /*Start of Defect 3285 to derive Account Segment*/

                IF (lc_project_type_class_code = lc_proj_type AND lc_task_billable_flag = 'Y') THEN

                    BEGIN

                        lc_error_loc := 'Deriving the Account Segment from the Task Service Type';
                        lc_error_debug := 'Task Service Type Code: '|| lc_service_type_code;

                        SELECT  PVL.segment_value
                        INTO    lc_charge_acct_seg3
                        FROM    pa_segment_value_lookups PVL,
                                pa_segment_value_lookup_sets PVLS
                        WHERE   PVLS.segment_value_lookup_set_id = PVL.segment_value_lookup_set_id
                        AND     UPPER(PVLS.segment_value_lookup_set_name) = lc_ser_type_to_acct_val_set
                        AND     PVL.segment_value_lookup = lc_service_type_code;

                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                lc_error_flag := 'Y';
                                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0083_CIP_ACC_NOT_DEF');
                                lc_err_msg := FND_MESSAGE.GET;
                                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                                         ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                                         ||lc_err_msg);

                                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                     p_program_type            => 'CONCURRENT PROGRAM'
                                    ,p_program_name            => gc_concurrent_program_name
                                    ,p_program_id              => fnd_global.conc_program_id
                                    ,p_module_name             => 'PO'
                                    ,p_error_message_count     => 1
                                    ,p_error_message_code      => 'E'
                                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                    ,p_error_message_severity  => 'Major'
                                    ,p_notify_flag             => 'N'
                                    ,p_object_type             => 'PO Automatic Requisition'
                                    ,p_object_id               => lcu_req_intf_line.req_line_number);

                    END;

                ELSE

                    --Deriving the Account Segment from Expenditure Type

                    BEGIN

                        lc_error_loc := 'Deriving the Account Segment from Expenditure Type';
                        lc_error_debug := 'Expenditure Type: '||lc_expenditure_type;

                        --Fixed defect 2199 -Start
                        SELECT PVL.segment_value
                        INTO   lc_charge_acct_seg3
                        FROM   pa_segment_value_lookups PVL,
                               pa_segment_value_lookup_sets PVLS
                        WHERE  PVLS.segment_value_lookup_set_id = PVL.segment_value_lookup_set_id
                        AND    UPPER(PVLS.segment_value_lookup_set_name) = lc_exp_type_to_acct_val_set
                        AND    PVL.segment_value_lookup = lc_expenditure_type;
                        --Fixed defect 2199 -End

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            lc_error_flag := 'Y';
                            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0054_ACC_NOT_DEF');
                            lc_err_msg := FND_MESSAGE.GET;
                            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                ||lc_err_msg);

                            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);

                    END;

                END IF;
                /*End of Defect 3285 to derive Account Segment*/

                -- Start of R1.1 CR 441 change for Location and Cost Center derivation (defect 1347)

                IF ln_project_id IS NOT NULL AND lc_charge_acct_seg3 IS NOT NULL THEN -- Need Account (seg3) to derive Cost Center and Location

                    --Checking if the Expenditure Item Date is with in the active Project Date
                    lc_error_loc := 'Checking if the Expenditure Item Date is with in the active Project Date';
                    lc_error_debug := 'Project ID :'||ln_project_id;

                    SELECT count(*)
                    INTO   ln_count
                    FROM   pa_projects PP
                    WHERE  PP.project_id = ln_project_id
                    AND    lcu_req_intf_dist.expenditure_item_date BETWEEN
                            NVL(PP.start_date,lcu_req_intf_dist.expenditure_item_date) AND
                                     NVL(PP.completion_date,lcu_req_intf_dist.expenditure_item_date);

                    ld_expenditure_item_date := lcu_req_intf_dist.expenditure_item_date;

                    IF (ln_count = 0) THEN

                        lc_error_flag := 'Y';
                        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0050_DATE_PROJ');
                        lc_err_msg := FND_MESSAGE.GET;
                        FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                                     ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                                     ||lc_err_msg);

                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);

                    END IF;

                    --Validating Expenditure Organization
                    BEGIN

                        lc_error_loc := 'Validating Expenditure Organization';
                        lc_error_debug := 'Expenditure Organization: '||lcu_req_intf_dist.expenditure_org;

                        SELECT POEV.name, organization_id
                        INTO   lc_exp_org, ln_exp_org_id
                        FROM   PA_ORGANIZATIONS_EXPEND_V POEV
                        WHERE  ACTIVE_FLAG = 'Y'
                        AND    trunc(SYSDATE) between POEV.date_from
                                       AND nvl(POEV.date_to, trunc(sysdate))
                        AND    UPPER(POEV.name) =  UPPER(lcu_req_intf_dist.expenditure_org); -- defect 2845 Added UPPER()

                        IF lc_charge_acct_seg3 < lc_balance_sheet_accout_break THEN -- Balance Sheet Account break
                          lc_charge_acct_seg2 := lc_balance_sheet_cost_center;
                        ELSE
                          /*Start of Defect 3285, to Derive the Cost Center Segment from Exp Org*/
                          BEGIN

                            lc_error_loc := 'Deriving the Cost Center Segment from Expenditure Organization';
                            lc_error_debug := 'Expenditure Organization: '||lc_exp_org;

                            SELECT  segment_value
                            INTO    lc_charge_acct_seg2
                            FROM    pa_segment_value_lookups PVL,
                                    pa_segment_value_lookup_sets PVLS
                            WHERE   PVLS.segment_value_lookup_set_id = PVL.segment_value_lookup_set_id
                            AND     UPPER(PVLS.segment_value_lookup_set_name) = lc_exp_org_to_cc_val_set
                            AND     PVL.segment_value_lookup = lc_exp_org;

                          EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                lc_error_flag := 'Y';
                                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0053_INVALID_COST_CENTER');
                                lc_err_msg := FND_MESSAGE.GET;
                                FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                ||lc_err_msg);

                                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                     p_program_type            => 'CONCURRENT PROGRAM'
                                    ,p_program_name            => gc_concurrent_program_name
                                    ,p_program_id              => fnd_global.conc_program_id
                                    ,p_module_name             => 'PO'
                                    ,p_error_message_count     => 1
                                    ,p_error_message_code      => 'E'
                                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                    ,p_error_message_severity  => 'Major'
                                    ,p_notify_flag             => 'N'
                                    ,p_object_type             => 'PO Automatic Requisition'
                                    ,p_object_id              => lcu_req_intf_line.req_line_number);
                          END;
                        END IF;
                        /*End of Defect 3285, to Derive the Cost Center Segment from Exp Org*/

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            lc_error_flag := 'Y';
                            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0052_INVALID_EXP');
                            lc_err_msg := FND_MESSAGE.GET;
                            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                                         ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                                         ||lc_err_msg);

                            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);
                    END;

                    IF lc_charge_acct_seg3 < lc_balance_sheet_accout_break THEN -- Balance Sheet Account break
                       lc_charge_acct_seg4 := lc_balance_sheet_location;
                    ELSE

                      /*Start of Defect 3285*/
                      --Checking if the Category Location Code is assigned to the Project
                      BEGIN
                        lc_error_loc := 'Getting the Category Location Code assigned to Project';
                        lc_error_debug := 'Project: '|| lcu_req_intf_dist.project;

                        /* -- Location derivation logic changed for R1.1 CR411 defect 1347
                        SELECT   ppc.class_code
                        INTO     lc_charge_acct_seg4
                        FROM     pa_project_classes ppc
                        WHERE    ppc.project_id = ln_project_id
                        AND      ppc.class_category = 'LOCATION';
                        */

                        SELECT   NVL(T.attribute1,NVL(P.attribute1,lc_balance_sheet_location))
                        INTO     lc_charge_acct_seg4
                        FROM     PA_TASKS T
                                ,PA_PROJECTS_ALL P
                        WHERE    T.task_id = ln_task_id
                        AND      P.project_id = T.project_id;


                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            lc_error_flag := 'Y';
                            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0087_CATEG_LOC_NOT_DEF');
                            lc_err_msg := FND_MESSAGE.GET;
                            FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                                         ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                                         ||lc_err_msg);

                            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => gc_concurrent_program_name
                                ,p_program_id              => fnd_global.conc_program_id
                                ,p_module_name             => 'PO'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'PO Automatic Requisition'
                                ,p_object_id               => lcu_req_intf_line.req_line_number);

                      END;
                    END IF;
                END IF;
                /*End of Defect 3285*/

                -- End of R1.1 CR 441 change for Location and Cost Center derivation (defect 1347)


                /*Start of Defect 3285 to derive LOB Segment*/

                --Deriving the LOB Segment from Project Organization

                BEGIN

                    lc_error_loc := 'Deriving the LOB Segment from Project Organization';
                    lc_error_debug := 'Project Organization: '||lc_company;

                    SELECT  segment_value
                    INTO  lc_charge_acct_seg6
                    FROM  pa_segment_value_lookups PVL,
                          pa_segment_value_lookup_sets PVLS
                    WHERE PVLS.segment_value_lookup_set_id = PVL.segment_value_lookup_set_id
                    AND  UPPER(PVLS.segment_value_lookup_set_name) = lc_org_to_lob_val_set
                    AND  PVL.segment_value_lookup = lc_company;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lc_error_flag := 'Y';
                        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0085_LOB_NOT_DEF');
                        lc_err_msg := FND_MESSAGE.GET;
                        FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                                         ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                                         ||lc_err_msg);

                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                     p_program_type            => 'CONCURRENT PROGRAM'
                                    ,p_program_name            => gc_concurrent_program_name
                                    ,p_program_id              => fnd_global.conc_program_id
                                    ,p_module_name             => 'PO'
                                    ,p_error_message_count     => 1
                                    ,p_error_message_code      => 'E'
                                    ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                                    ,p_error_message_severity  => 'Major'
                                    ,p_notify_flag             => 'N'
                                    ,p_object_type             => 'PO Automatic Requisition'
                                    ,p_object_id               => lcu_req_intf_line.req_line_number);

                END;

                /*End of Defect 3285  to derive LOB Segment*/

                --Location Segment
                --lc_charge_acct_seg4 := '000000';     --Commented for Defect 3285

                --Intercompany Segment
                lc_charge_acct_seg5 := lc_inter_company;    --Defect 3285

                --Line of Business Segment
                --lc_charge_acct_seg6 := '00';     --Commented for Defect 3285

                --Future Segment
                lc_charge_acct_seg7 := lc_future;    --Defect 3285

            END IF;

            --Validate charge account segments and get the Code Combination Id (OR)
            --Validate project information and CREATE COMBINATION
              BEGIN

                lc_error_loc := 'Getting the Set of Books ID from the Profile';
                lc_error_debug := '';

                ln_sob_id := fnd_profile.value('GL_SET_OF_BKS_ID');

                --Getting the Chart of Accounts ID from the Set of Books ID

                lc_error_loc := 'Getting the Chart of Accounts ID from the Set of Books ID';
                lc_error_debug := 'Set of Books ID: '||ln_sob_id;

                SELECT gsb.chart_of_accounts_id
                INTO   ln_chart_of_acct_id
                FROM   gl_ledgers gsb  ----------------  gl_sets_of_books gsb ---- #2.9  made changes for R12 retrofit by Aradhna Sharma on 18-JUL-2013
                WHERE  gsb.ledger_id = ln_sob_id ;    ------------gsb.set_of_books_id = ln_sob_id; ---- #2.9  made changes for R12 retrofit by Aradhna Sharma on 18-JUL-2013

                IF (fnd_flex_keyval.validate_segs('CREATE_COMBINATION',
                   'SQLGL','GL#',ln_chart_of_acct_id,lc_charge_acct_seg1||'.'
                            ||lc_charge_acct_seg2||'.'||lc_charge_acct_seg3||'.'
                            ||lc_charge_acct_seg4||'.'||lc_charge_acct_seg5||'.'
                            ||lc_charge_acct_seg6||'.'||lc_charge_acct_seg7)) THEN

                lc_error_loc := 'Getting the Code Combination ID for the Charge Account';
                lc_error_debug := 'Charge Account: '||lc_charge_acct_seg1||'.'||lc_charge_acct_seg2||'.'
                                                    ||lc_charge_acct_seg3||'.'||lc_charge_acct_seg4||'.'
                                                    ||lc_charge_acct_seg5||'.'||lc_charge_acct_seg6||'.'
                                                    ||lc_charge_acct_seg7;

                    SELECT gcc.code_combination_id
                    INTO   ln_charge_account_id
                    FROM   gl_code_combinations gcc
                    WHERE  gcc.chart_of_accounts_id = ln_chart_of_acct_id
                    AND    gcc.segment1 = lc_charge_acct_seg1
                    AND    gcc.segment2 = lc_charge_acct_seg2
                    AND    gcc.segment3 = lc_charge_acct_seg3
                    AND    gcc.segment4 = lc_charge_acct_seg4
                    AND    gcc.segment5 = lc_charge_acct_seg5
                    AND    gcc.segment6 = lc_charge_acct_seg6
                    AND    gcc.segment7 = lc_charge_acct_seg7;
                ELSE

                    lc_error_flag := 'Y';
                    lc_err_msg := 'Charge Account: '||lc_charge_acct_seg1
                                                    ||'.'||lc_charge_acct_seg2||'.'
                                                    ||lc_charge_acct_seg3||'.'||lc_charge_acct_seg4||'.'
                                                    ||lc_charge_acct_seg5||'.'||lc_charge_acct_seg6||'.'
                                                    ||lc_charge_acct_seg7||' '||fnd_flex_keyval.error_message;

                    FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),08, ' ')
                                    ||RPAD(nvl(lcu_req_intf_dist.req_line_number_dist,' '),08, ' ')
                                    ||lc_err_msg);

                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                         p_program_type            => 'CONCURRENT PROGRAM'
                        ,p_program_name            => gc_concurrent_program_name
                        ,p_program_id              => fnd_global.conc_program_id
                        ,p_module_name             => 'PO'
                        ,p_error_message_count     => 1
                        ,p_error_message_code      => 'E'
                        ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                        ,p_error_message_severity  => 'Major'
                        ,p_notify_flag             => 'N'
                        ,p_object_type             => 'PO Automatic Requisition'
                        ,p_object_id               => lcu_req_intf_line.req_line_number);

                END IF;

              END;



            --Inserting into PO_REQ_DIST_INTERFACE_ALL, if there is no error

            IF (lc_error_flag <> 'Y') THEN

                lc_error_loc := 'Inserting into PO_REQ_DIST_INTERFACE_ALL';
                lc_error_debug := 'Requisition Line No: '||lcu_req_intf_line.req_line_number
                                   ||'Requisition Distn No: '||lcu_req_intf_dist.req_line_number_dist;

                INSERT INTO po_req_dist_interface_all
                (
                 dist_sequence_id
                ,distribution_number
                ,quantity
                ,amount                   -- Added for R1.1 CR 411 defect 2973
                ,charge_account_id
                ,project_id
                ,task_id
                ,expenditure_type
                ,expenditure_organization_id
                ,destination_type_code
                ,destination_organization_id
                ,interface_source_code
                ,batch_id
                ,project_accounting_context
                ,expenditure_item_date
                ,org_id
                ,distribution_attribute1
                )
                VALUES
                (
                 ln_dist_sequence_id
                ,lcu_req_intf_dist.req_line_number_dist
                ,lc_distribution_quantity  -- Changed to local variable for R1.1 CR 411 defect 1348
                ,lc_distribution_amount    -- Added for R1.1 CR 411 defect 2973
                ,ln_charge_account_id
                ,ln_project_id
                ,ln_task_id
                ,lc_expenditure_type
                ,ln_exp_org_id
                ,lcu_req_intf_line.destination_type_code
                ,ln_organization_id
                ,lcu_req_intf_line.interface_source_code
                ,p_batch_id
                ,lc_project_Acct_context
                ,ld_expenditure_item_date
                ,fnd_profile.value('ORG_ID')
                ,ln_charge_account_id
                );

            ELSE

                UPDATE xx_po_requisitions_stg
                SET    status = 'ERROR'
                WHERE  req_line_number = lcu_req_intf_line.req_line_number
                AND    req_line_number_dist = lcu_req_intf_dist.req_line_number_dist
                AND    batch_id = p_batch_id;

                lc_com_error_flag := 'Y';

            END IF;

        END LOOP;

        IF NOT lb_line_type_is_service THEN-- R1.1 CR 411 defect 1348 -> Added Service line type exclusion to this distribution quantity validation
          IF (ln_dist_quantity <> lcu_req_intf_line.quantity) THEN
              lc_error_flag:= 'Y';
              lc_com_error_flag := 'Y';
              FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0056_TOT_DIS_LIN_QUAN');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE (fnd_file.output,RPAD(nvl(lcu_req_intf_line.req_line_number,' '),16, ' ')
                                   ||lc_err_msg);

              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               => lcu_req_intf_line.req_line_number);

          END IF;
        END IF;

    END LOOP;

    FND_FILE.PUT_LINE (fnd_file.output,RPAD('-',150,'-'));
    --If any of the Distribution, or Line is falied in validation, then the whole Requisition should not be processed

    IF (lc_com_error_flag = 'Y') THEN

       lc_error_loc:='Deleting from interface tables if error';
       lc_error_debug:='Batch ID'||p_batch_id;

        DELETE
        FROM po_requisitions_interface_all
        WHERE batch_id = p_batch_id;

        DELETE
        FROM po_req_dist_interface_all
        WHERE batch_id = p_batch_id;

        x_ret_code := 2;

    ELSE

        --Submitting the Requisition Import (Report Set)

        lc_error_loc := 'Submitting the Requisition Import (Report Set)';
        lc_error_debug := '';

        lb_req_set := fnd_submit.set_request_set('PO','FNDRSSUB37');

        lc_error_loc := 'Submitting the Requisition Import (STAGE10 of Request set)';
        lc_error_debug := '';

        lb_req_import    :=   fnd_submit.submit_program('PO'
                                                       ,'REQIMPORT'
                                                       ,'STAGE10'
                                                       ,'XLS'
                                                       ,p_batch_id
                                                       ,'BUYER'
                                                       ,NULL
                                                       ,'Y'
                                                       ,'N');

        lc_error_loc := 'Submitting the Requisition Import Exceptions Report (STAGE20 of Request set)';
        lc_error_debug := '';

        lb_req_imp_excep := fnd_submit.submit_program('PO'
                                                     ,'POXREQIM'
                                                     ,'STAGE20'
                                                     ,NULL
                                                     ,lc_interface_source_code
                                                     ,p_batch_id
                                                     ,'N');


        ln_req_submit := fnd_submit.submit_set(SYSDATE, FALSE);

        FND_FILE.PUT_LINE (fnd_file.log,'Request set(Requisition Import): '||ln_req_submit);

        lc_error_loc := 'Waiting for the completion of Requisition Import (Report Set)';
        lc_error_debug := '';

        COMMIT;

        --Waiting for the completion of the 'Requisition Import' Request set.

        lb_req_status := fnd_concurrent.wait_for_request(ln_req_submit
                                                        ,'15'
                                                        ,''
                                                        ,lc_phase
                                                        ,lc_status
                                                        ,lc_devphase
                                                        ,lc_devstatus
                                                        ,lc_message);

        lc_error_loc := 'Getting the Request id of Requisition Import';
        lc_error_debug := '';

        --Getting the Request ID of the Requisition Import concurrent program.

        SELECT FCR.request_id
        INTO   ln_req_imp_request_id
        FROM   fnd_concurrent_programs FCP
               ,fnd_concurrent_requests FCR
        WHERE  FCP.concurrent_program_name = 'REQIMPORT'
        AND    FCP.concurrent_program_id = FCR.concurrent_program_id
        AND    FCR.priority_request_id = ln_req_submit;

        --Checking for the rejected records from the Requisition Import

        lc_error_loc := 'Checking for the rejected records from the Requisition Import';
        lc_error_debug := 'Request ID of Requisition Import: '||ln_req_imp_request_id;
        FND_FILE.PUT_LINE (fnd_file.output,'Request ID of Requisition Import: '||ln_req_imp_request_id);
        process_rej_rec(ln_req_imp_request_id);

        --Get the Requisition Number of the Requistion imported through our process

        lc_error_loc := 'Getting the Requisition Number created by this process';
        lc_error_debug := '';

        BEGIN

            SELECT PRH.SEGMENT1,PRH.REQUISITION_HEADER_ID
            INTO   lc_req_number,lc_req_header_id--Added by AMS team to update the vendor details based on the requisition
            FROM   po_requisition_headers_all PRH
            WHERE  PRH.request_id = ln_req_imp_request_id;

            FND_FILE.PUT_LINE (fnd_file.output,'Imported Requisition Number: '||lc_req_number);
            
            	--Added by AMS team. #Bug 13344
          
              FOR rec_new_line_vendor_info in (SELECT l.*,
           ( SELECT v.VENDOR_ID
              FROM  AP_SUPPLIERS  V    ----PO_VENDORS V     ---- #2.9  made changes for R12 retrofit by Aradhna Sharma on 18-JUL-2013
              WHERE V.VENDOR_NAME= L.SUGGESTED_VENDOR_NAME) new_vendor_id,
              (SELECT v.VENDOR_SITE_ID
              FROM AP_SUPPLIER_SITES_ALL   V   -------------PO_VENDOR_SITES_ALL V ---- #2.9  made changes for R12 retrofit by Aradhna Sharma on 18-JUL-2013
              WHERE V.VENDOR_SITE_CODE = L.SUGGESTED_VENDOR_LOCATION
              AND ROWNUM =1) new_vendor_site_id,
            (SELECT VC.VENDOR_CONTACT_ID 
              FROM AP_SUPPLIER_CONTACTS  VC,   --------------PO_VENDOR_CONTACTS VC,   ---- #2.9  made changes for R12 retrofit by Aradhna Sharma on 18-JUL-2013
	           AP_SUPPLIER_SITES_ALL   V   -------------PO_VENDOR_SITES_ALL V  ---- #2.9  made changes for R12 retrofit by Aradhna Sharma on 18-JUL-2013
              WHERE VC.LAST_NAME = TRIM(SUBSTR(L.SUGGESTED_VENDOR_CONTACT, 1 ,INSTR(L.SUGGESTED_VENDOR_CONTACT, ',', 1, 1)-1))
              AND VC.FIRST_NAME = TRIM(SUBSTR(L.SUGGESTED_VENDOR_CONTACT ,-INSTR(L.SUGGESTED_VENDOR_CONTACT, ',', 1, 1)))
              AND VC.VENDOR_SITE_ID = V.VENDOR_SITE_ID
              AND V.VENDOR_SITE_CODE = L.SUGGESTED_VENDOR_LOCATION) new_vendor_contact_id
              FROM PO_REQUISITION_LINES_ALL L
              WHERE 1=1
              AND L.REQUISITION_HEADER_ID = LC_REQ_HEADER_ID) LOOP
              
              -- Moved the log messages inside the IF for defect 28866
              IF (REC_NEW_LINE_VENDOR_INFO.SUGGESTED_VENDOR_NAME IS NOT NULL) THEN

              -- Commented the below log messages for defect 29406.
              --FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Vendor Id value :::'|| REC_NEW_LINE_VENDOR_INFO.NEW_VENDOR_ID);
              --FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Vendor Site Id value :::'|| REC_NEW_LINE_VENDOR_INFO.new_vendor_site_id);
              --FND_FILE.PUT_LINE (fnd_file.output,'Vendor Contact Id value :::'|| rec_new_line_vendor_info.new_vendor_contact_id);
              
              --FND_FILE.PUT_LINE (fnd_file.output,'Updating Vendor Information based on the ASL');
              UPDATE PO_REQUISITION_LINES_ALL l
               SET VENDOR_ID = REC_NEW_LINE_VENDOR_INFO.NEW_VENDOR_ID
                  ,VENDOR_SITE_ID = REC_NEW_LINE_VENDOR_INFO.new_vendor_site_id
                  ,VENDOR_CONTACT_ID = rec_new_line_vendor_info.new_vendor_contact_id
                  WHERE 1=1
                   AND L.REQUISITION_HEADER_ID = LC_REQ_HEADER_ID
		               AND L.REQUISITION_LINE_ID = rec_new_line_vendor_info.REQUISITION_LINE_ID;
                  COMMIT; 
              ELSE
                  NULL;
              END IF;
              
              END LOOP;
               --End of #Bug 13344

       EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE (fnd_file.output,'');
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0057_REQ_NOT_CREATED');
            lc_err_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.output,lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               => '');

        END;


    END IF;

    --Submitting the 'OD:Concurrent Request Output Emailer Program'

    lc_error_loc := 'Submitting the ''OD:Concurrent Request Output Emailer Program''';
    lc_error_debug := '';

    COMMIT;

    IF lc_com_error_flag = 'Y' THEN
       lc_msg := 'OD:PO Auto Requisition Import Requisition Data Errors';
    ELSE
       lc_msg := 'OD:PO Auto Requisition Import Output';
    END IF;

    send_template_error(lc_msg);
/*
    ln_conc_request_id := fnd_request.submit_request (
                                'XXFIN'
                                ,'XXODROEMAILER'
                                ,''
                                ,''
                                ,FALSE
                                ,''
                                ,lc_email_address
                                ,lc_msg
                                ,'Please find attached the output file of ''OD: PO Auto Requisition Import Output'''
                                ,'Y'
                                ,fnd_global.conc_request_id);
   COMMIT;     -- Defect 5135


   FND_FILE.PUT_LINE (fnd_file.log,'Request id of Mailer: '||ln_conc_request_id);
*/
    EXCEPTION
        WHEN EX_REQ_HEADER THEN
            lc_error_flag := 'Y';
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0058_HEAD_INFO_LIN');
            lc_err_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.log,lc_err_msg);
            FND_FILE.PUT_LINE (fnd_file.output,lc_err_msg);
            x_ret_code := 2;
            lc_msg := 'OD:PO Auto Requisition Import Requisition Data Errors';
            send_template_error(lc_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               =>'');

        WHEN EX_REQ_LINE THEN
            lc_error_flag := 'Y';
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0059_LIN_INFO_DIST');
            lc_err_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.log,lc_err_msg);
            FND_FILE.PUT_LINE (fnd_file.output,lc_err_msg);
            x_ret_code := 2;
            lc_msg := 'OD:PO Auto Requisition Import Requisition Data Errors';
            send_template_error(lc_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               =>'');

        WHEN EX_REQ_NOTFOUND THEN
            lc_error_flag := 'Y';
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0060_REQ_NOTFOUND');
            lc_err_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.log,lc_err_msg);
            FND_FILE.PUT_LINE (fnd_file.output,lc_err_msg);
            x_ret_code := 2;
            lc_msg := 'OD:PO Auto Requisition Import Requisition Data Errors';
            send_template_error(lc_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               => '');

        WHEN CAT_SEG_NOTFOUND THEN
            lc_error_flag := 'Y';
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0080_CAT_SEG_NOTFOUND');
            lc_err_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.log,lc_err_msg);
            FND_FILE.PUT_LINE (fnd_file.output,lc_err_msg);
            x_ret_code := 2;
            lc_msg := 'OD:PO Auto Requisition Import Requisition Data Errors';
            send_template_error(lc_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               => '');

        /*Start of Defect 3285*/
        WHEN EX_ACCT_DER_TRANS_NOT_DEF THEN
            lc_error_flag := 'Y';
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0086_ACCT_DERIV_TRAN');
            lc_err_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.log,lc_err_msg);
            FND_FILE.PUT_LINE (fnd_file.output,lc_err_msg);
            x_ret_code := 2;
            lc_msg := 'OD:PO Auto Requisition Import Requisition Data Errors';
            send_template_error(lc_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition'
                ,p_object_id               => '');

        /*End of Defect 3285*/

        WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0001_ERROR');
            FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
            FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
            FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
            lc_err_msg :=  FND_MESSAGE.GET;
            FND_FILE.PUT_LINE (fnd_file.log,lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'PO'
                ,p_error_location          => 'Error at ' || substr(lc_error_loc,1,50)
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Batch ID::'||p_batch_id||' '||lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'PO Automatic Requisition');

            x_ret_code := 2;
            lc_msg := 'OD:PO Auto Requisition Import Requisition Data Errors';
            send_template_error(lc_msg);

    END;

-- +===================================================================+
-- | Name :  Submit_request                                            |
-- | Description : Submits request for custom program for validatio    |
-- +===================================================================+
   PROCEDURE submit_request(x_message OUT VARCHAR2)
   IS
     ln_batch_id   number;
     ln_request_id NUMBER;
   BEGIN
      -- ------------------------
	  -- Deriving the batch id
	  -- ------------------------
      SELECT xx_po_req_batch_stg_s.nextval
        INTO ln_batch_id
        FROM SYS.DUAL;   
	   
      -- --------------------------------------
	  -- All new records are expected to be entered in the application with sessionid
	  -- Assign the actual batch id to all the records
	  -- --------------------------------------
	  BEGIN
        UPDATE xx_po_requisitions_stg 
		   SET batch_id = ln_batch_id
         WHERE batch_id = fnd_global.session_id;
      END;
	 
	  -- --------------------------------------
	  -- Submit the concurretn program
	  -- --------------------------------------
	  ln_request_id :=
          FND_REQUEST.SUBMIT_REQUEST 
		                       ( application   => 'XXFIN'
                                , program      => 'XX_PO_AUTO_REQ_PKG_PROCESS'
                                , start_time    => sysdate
                                , sub_request   => false
                                , argument1    => ln_batch_id
                                );
 
    
    COMMIT;
	 x_message := 'Request '||ln_request_id||'Submited';
   EXCEPTION
      WHEN OTHERS THEN
        x_message :='Error '||SQLERRM;
   END submit_request;

-- +===================================================================+
-- | Name :  get_record                                                |
-- | Description : To automatically import the Rquisitions into Oracle |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns:                                                          |
-- +===================================================================+
   PROCEDURE get_record(
		 p_requisition_type	IN  VARCHAR2
		,p_preparer_emp_nbr	IN  VARCHAR2
		,p_req_description	IN  VARCHAR2
		,p_req_line_number	IN  VARCHAR2
		,p_line_type	    IN  VARCHAR2
		,p_item	            IN  VARCHAR2
		,p_category	        IN  VARCHAR2
		,p_item_description	IN  VARCHAR2
		,p_unit_of_measure	IN  VARCHAR2
		,p_price	        IN  VARCHAR2
		,p_need_by_date	    IN  VARCHAR2
		,p_quantity	        IN  VARCHAR2
		,p_organization	        IN  VARCHAR2
		,p_source_organization	IN  VARCHAR2
		,p_location	            IN  VARCHAR2
		,p_req_line_number_dist	IN  VARCHAR2
		,p_distribution_quantity	IN  VARCHAR2
		,p_charge_acct_segment1	IN  VARCHAR2
		,p_charge_acct_segment2	IN  VARCHAR2
		,p_charge_acct_segment3	IN  VARCHAR2
		,p_charge_acct_segment4	IN  VARCHAR2
		,p_charge_acct_segment5	IN  VARCHAR2
		,p_charge_acct_segment6	IN  VARCHAR2
		,p_charge_acct_segment7	IN  VARCHAR2
		,p_project	            IN  VARCHAR2
		,p_task	                IN  VARCHAR2
		,p_expenditure_type	    IN  VARCHAR2
		,p_expenditure_org	    IN  VARCHAR2
		,p_expenditure_item_date	IN  VARCHAR2
        ,p_file_name             IN VARCHAR2		      
		)
   IS  
     lv_error_msg varchar2(1000);
   BEGIN
   
     INSERT INTO xx_po_requisitions_stg
         (	requisition_type
         ,	preparer_emp_nbr
         ,  req_description
         ,  req_line_number
         ,  line_type
         ,  item
         ,  category
         ,  item_description
         ,  unit_of_measure
         ,  price
         ,  need_by_date
         ,  quantity
         ,  organization
         ,  source_organization
         ,  location
         ,  req_line_number_dist
         ,  distribution_quantity
         ,  charge_account_segment1
         ,  charge_account_segment2
         ,  charge_account_segment3
         ,  charge_account_segment4
         ,  charge_account_segment5
         ,  charge_account_segment6
         ,  charge_account_segment7
         ,  project
         ,  task
         ,  expenditure_type
         ,  expenditure_org
         ,  expenditure_item_date
         ,  request_id            
         ,  interface_source_code  
         ,  destination_type_code  
         ,  file_name
         ,  batch_id
          )
     VALUES
	   (  p_requisition_type
        , p_preparer_emp_nbr
        , p_req_description
        , p_req_line_number
        , p_line_type
        , p_item
        , p_category
        , p_item_description
        , p_unit_of_measure
        , p_price
        , TO_DATE(TRIM(p_need_by_date),'MM/DD/YYYY HH24:MI')
        , p_quantity
        , p_organization
        , p_source_organization
        , p_location
        , p_req_line_number_dist
        , p_distribution_quantity
        , p_charge_acct_segment1
        , p_charge_acct_segment2
        , p_charge_acct_segment3
        , p_charge_acct_segment4
        , p_charge_acct_segment5
        , p_charge_acct_segment6
        , p_charge_acct_segment7
        , p_project
        , p_task
        , p_expenditure_type
        , p_expenditure_org
        , TO_DATE(TRIM(p_expenditure_item_date),'MM/DD/YYYY HH24:MI')
        , 1234
        , 'XLS'
        , 'EXPENSE'
        , p_file_name
		, fnd_global.session_id
        ) ;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      lv_error_msg := 'Custom Error :'||SQLERRM;
      raise_application_error (-20001, lv_error_msg);
  end GET_RECORD;	
END XX_PO_AUTO_REQ_PKG;
/