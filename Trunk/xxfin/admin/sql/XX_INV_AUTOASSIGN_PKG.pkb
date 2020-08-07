SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_INV_AUTOASSIGN_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE BODY XX_INV_AUTOASSIGN_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      INV Auto Assign Items                                 |
-- | Description : To automatically assign the items to the            |
-- |                organization in organization group                 |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       27-FEB-2007  Gowri Shankar        Initial version        |
-- |1.1       09-NOV-2007  Radhika Raman        Modified for           |
-- |                                              Defect: 2591         |
-- |1.2       12-FEB-2008  Radhika Raman        Modified for Defect    |
-- |                                            4561                   |
-- |1.3       12-FEB-2008  Radhika Raman        Modified for defect    |
-- |                                            4608 - for performance |
-- |                                                                   |
-- |1.4       19-MAY-2008  Subbu Pillai         Modified for Defect    |
-- |                       Ram                     7199 - Performance  |
-- +===================================================================+
-- +===================================================================+
-- | Name : PROCESS                                                    |
-- | Description : This Program automatically assigns the items to the |
-- | Inventory organization, to which it is not assigned previously    |
-- |                                                                   |
-- | Program "OD: INV Auto Assign Items".                              |
-- |                                                                   |
-- | Parameters : p_item_from, p_item_to, p_category_set_id            |
-- |  , p_org_group_id, p_item_status, p_organization_id               |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+
    PROCEDURE PROCESS(
        x_error_buff           OUT VARCHAR2
       ,x_ret_code             OUT NUMBER
       ,p_task_type            IN  NUMBER -- defect 4561
       ,p_item_from            IN  VARCHAR2
       ,p_item_to              IN  VARCHAR2
       ,p_category_set_name    IN  VARCHAR2 -- Modified for defect 2591
       ,p_org_group_id         IN  NUMBER
       ,p_item_status          IN  VARCHAR2
       ,p_organization_id      IN  NUMBER)
    AS
    
	--Commented out for Defect 7199 by Ram. Using BULK Collect Instead
    
        /*CURSOR c_inv_org_group IS        
          SELECT XIVOGM.organization_id organization_id
          FROM   xx_inv_org_group XIVOG
                ,xx_inv_org_group_members XIVOGM
          WHERE  XIVOG.group_id = XIVOGM.group_id
          AND    XIVOG.group_id = p_org_group_id
          ORDER BY 1
        ;*/  
        
        -- Added dynamic cursor for defect 2591
        /*  
        CURSOR c_inv_item (
            p_master_org_id NUMBER
        ) IS
        (
        SELECT MSI.inventory_item_id
              ,MSI.segment1
        FROM   mtl_system_items_fvl MSI
        WHERE  MSI.organization_id = p_master_org_id
        AND    MSI.segment1 BETWEEN NVL(p_item_from, MSI.segment1) AND NVL(p_item_to,MSI.segment1)
        AND    MSI.inventory_item_status_code <> 'Inactive'
        AND    EXISTS ( SELECT 1
                        FROM  mtl_item_categories_v MIC
                        WHERE MIC.organization_id = p_master_org_id
                        AND   MIC.inventory_item_id = MSI.inventory_item_id
                        AND   MIC.category_set_id = NVL(p_category_set_id,MIC.category_set_id)
                       )
        );  */

        CURSOR c_success_rec_create ( p_set_process_id NUMBER ) IS
        (
          SELECT MSI.segment1
                ,HAOU.name
          FROM   mtl_system_items_interface MSI
                ,hr_all_organization_units HAOU
          WHERE MSI.organization_id = HAOU.organization_id
          AND   MSI.set_process_id = p_set_process_id
          AND   MSI.process_flag = '7'
        );
        
        CURSOR c_reject_rec_create ( p_set_process_id NUMBER ) IS
        (
          SELECT MSI.segment1
                ,HAOU.name
                ,MIE.table_name
                ,MIE.column_name
                ,MIE.error_message
          FROM   mtl_system_items_interface MSI
                ,mtl_interface_errors MIE
                ,hr_all_organization_units HAOU
          WHERE MIE.transaction_id = MSI.transaction_id
          AND   MSI.organization_id = HAOU.organization_id
          AND   MSI.set_process_id = p_set_process_id
          AND   MSI.process_flag <> '7'
        );
        
        CURSOR c_success_rec_update ( p_set_process_id NUMBER ) IS
        (
          SELECT  MSI.segment1
                 ,HAOU.name
                 ,MSI.inventory_item_status_code
          FROM    mtl_system_items_interface MSI
                 ,hr_all_organization_units HAOU
          WHERE   MSI.organization_id = HAOU.organization_id
          AND     MSI.set_process_id = p_set_process_id
          AND     MSI.process_flag = '7'
        );
        
        CURSOR c_reject_rec_update ( p_set_process_id NUMBER ) IS
        (
          SELECT MSI.segment1
                ,HAOU.name
                ,MIE.table_name
                ,MIE.column_name
                ,MIE.error_message
          FROM   mtl_system_items_interface MSI
                ,mtl_interface_errors MIE
                ,hr_all_organization_units HAOU
          WHERE MIE.transaction_id = MSI.transaction_id
          AND   MSI.organization_id = HAOU.organization_id
          AND   MSI.set_process_id = p_set_process_id
          AND   MSI.process_flag <> '7'
        );
        
        
        ln_master_org_id            mtl_parameters.master_organization_id%TYPE;
        lc_item_number              mtl_system_items_b.segment1%TYPE;
        lc_item_status_code         mtl_system_items_b.inventory_item_status_code%TYPE;
        ln_set_process_id_create    mtl_system_items_interface.set_process_id%TYPE;
        ln_set_process_id_update    mtl_system_items_interface.set_process_id%TYPE;
        ln_conc_req_id_create       fnd_concurrent_requests.request_id%TYPE;
        ln_conc_req_id_update       fnd_concurrent_requests.request_id%TYPE;
        lc_phase_create             VARCHAR2(50);
        lc_status_create            VARCHAR2(50);
        lc_devphase_create          VARCHAR2(50);
        lc_devstatus_create         VARCHAR2(50);
        lc_message_create           VARCHAR2(50);
        lb_req_status_create        BOOLEAN;
        lc_phase_update             VARCHAR2(50);
        lc_status_update            VARCHAR2(50);
        lc_devphase_update          VARCHAR2(50);
        lc_devstatus_update         VARCHAR2(50);
        lc_message_update           VARCHAR2(50);
        lb_req_status_update        BOOLEAN;
        lc_import_item_create       VARCHAR2(1) := 'N';
        lc_import_item_update       VARCHAR2(1) := 'N';
        lc_record_found             VARCHAR2(1) := 'N';
        lc_err_msg                  VARCHAR2(4000);
        lc_error_loc                VARCHAR2(2000);
        lc_loc_err_msg              VARCHAR2(2000);
        lc_error_debug              VARCHAR2(2000);
        EX_ITEM_CATSET_PARAM        EXCEPTION;
        EX_INV_ORGANIZATION         EXCEPTION;
        CAT_SET_NOT_DEFINED         EXCEPTION;
        EX_NO_ITEM_STATUS           EXCEPTION;
        
        /*TYPE plsql_tbl_type  IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
        lt_plsql                    plsql_tbl_type;
        lt_plsql_upd                plsql_tbl_type;
        lt_plsql_req                plsql_tbl_type;
        ln_batch_cnt                PLS_INTEGER := 0;
        ln_batch_upd_cnt            PLS_INTEGER := 0;
        ln_item_allow_cnt           PLS_INTEGER := 0;
        ln_item_cnt                 PLS_INTEGER := 0;
        ln_item_upd_cnt             PLS_INTEGER := 0;
        ln_req_cnt                  PLS_INTEGER := 1;
        lc_select_clause            VARCHAR2(200);
        lc_from_clause              VARCHAR2(1000);
        lc_where_clause             VARCHAR2(1000);
        lc_query                    VARCHAR2(4000);
        ln_inventory_item_id        mtl_system_items_b.inventory_item_id%TYPE;
        lc_item_nbr                 mtl_system_items_b.segment1%TYPE;
        ln_category_set_id          mtl_category_sets.category_set_id%TYPE;*/
        
        -- Commented for Defect ID 7199
        /*TYPE item_csr_type IS REF CURSOR;
        lcu_items                   item_csr_type;
        
        TYPE item_rec_type IS RECORD --defect 4608
                    (inventory_item_id    MTL_SYSTEM_ITEMS_B.inventory_item_id%TYPE,
                     segment1             MTL_SYSTEM_ITEMS_B.segment1%TYPE);
                     
        TYPE item_tbl_type IS TABLE OF item_rec_type INDEX BY BINARY_INTEGER; -- defect 4608
        
        lt_item_table              item_tbl_type; --defect 4608
        ln_rec_count               NUMBER(5):=1; --defect 4608*/
        
        TYPE plsql_tbl_type  IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
        lt_plsql                    plsql_tbl_type;
        lt_plsql_upd                plsql_tbl_type;
        lt_plsql_req                plsql_tbl_type;
        ln_batch_cnt                PLS_INTEGER := 0;
        ln_batch_upd_cnt            PLS_INTEGER := 0;
        ln_item_allow_cnt           PLS_INTEGER := 0;
        ln_item_cnt                 PLS_INTEGER := 0;
        ln_item_upd_cnt             PLS_INTEGER := 0;
        ln_req_cnt                  PLS_INTEGER := 1;
        lc_select_clause            VARCHAR2(200);
        lc_from_clause              VARCHAR2(1000);
        lc_where_clause             VARCHAR2(1000);
        lc_query                    VARCHAR2(4000);
	ln_inventory_item_id        mtl_system_items_b.inventory_item_id%type ;
        ln_organization_id          mtl_system_items_b.organization_id%type ; 
        ln_category_set_id          mtl_category_sets.category_set_id%TYPE;
        
        -- Added by Ram to Improve performance as per Defect ID 7199
        type ln_org_id_tbl is table of mtl_system_items_b.organization_id%type index by binary_integer;
        ln_org_id_t ln_org_id_tbl ;

        type ln_inventory_item_id_tbl is table of mtl_system_items_b.inventory_item_id%type index by binary_integer;
        ln_inventory_item_id_t ln_inventory_item_id_tbl;

        type ln_segment1_tbl is table of mtl_system_items_b.segment1%type index by binary_integer;
        ln_segment1_t ln_segment1_tbl;
        
       
    BEGIN
        --Printing the Parameters
        lc_error_loc   := 'Printing the Parameters of the program';
        lc_error_debug := '';
        FND_FILE.PUT_LINE(fnd_file.log,'Parameters');
        FND_FILE.PUT_LINE(fnd_file.log,'----------');
        FND_FILE.PUT_LINE(fnd_file.log,'Item From: '||p_item_from);
        FND_FILE.PUT_LINE(fnd_file.log,'Item To: '||p_item_to);
        FND_FILE.PUT_LINE(fnd_file.log,'Category set: '||p_category_set_name);
        FND_FILE.PUT_LINE(fnd_file.log,'Organization Group: '||p_org_group_id);
        FND_FILE.PUT_LINE(fnd_file.log,'Item Status: '||p_item_status);
        FND_FILE.PUT_LINE(fnd_file.log,'----------');
        
             
        --Checking if the Inventory Orgnanization is selected
        lc_error_loc   := 'Checking if the Inventory Orgnanization is selected';
        lc_error_debug := '';
        
        IF (p_organization_id IS NULL) THEN
            RAISE EX_INV_ORGANIZATION;
        END IF;
        
        IF ((p_item_from IS NULL AND p_item_to IS NULL) AND (p_category_set_name IS NULL)) THEN
            RAISE EX_ITEM_CATSET_PARAM;
        END IF;    
        
        
        IF (p_category_set_name IS NOT NULL) THEN  -- Defect 2591
        BEGIN
            SELECT category_set_id 
            INTO ln_category_set_id
            FROM mtl_category_sets 
            WHERE category_set_name = p_category_set_name;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             RAISE CAT_SET_NOT_DEFINED;
        END;
        END IF;
        
        IF p_task_type = 2 THEN   -- -- defect 4561
           IF (p_item_status IS NULL) THEN
               RAISE EX_NO_ITEM_STATUS;
           END IF;
        END IF;   
        
         --Get the Organization id of the Master Inventory Organization
        lc_error_loc   := 'Get the Organization id of the Master Inventory Organization';
        lc_error_debug := '';
        SELECT master_organization_id
        INTO   ln_master_org_id
        FROM   mtl_parameters
        WHERE  organization_id = p_organization_id;
        
        -- Used BULK COLLECT for performance improvement as per Defect ID 7199. Added by Ram
        SELECT XIVOGM.organization_id BULK COLLECT INTO ln_org_id_t
        FROM   xx_inv_org_group XIVOG
                ,xx_inv_org_group_members XIVOGM
        WHERE  XIVOG.group_id = XIVOGM.group_id
        AND    XIVOG.group_id = p_org_group_id
        ORDER BY 1;
        
        --Form the Query to fetch the list of items  -- Added for Defect 2591
        lc_select_clause := 'SELECT MSI.inventory_item_id ,MSI.segment1 '; 
        lc_from_clause := ' FROM   mtl_system_items_b MSI ';
        --lc_where_clause := ' WHERE MSI.inventory_item_id IN (SELECT inventory_item_id '      Commented out by Subbu for Defect 7199
		 lc_where_clause := ' WHERE EXISTS (SELECT 1 '    
                                         ||' FROM  mtl_item_categories MIC '
                                         ||'      ,mtl_categories_b MCB '
                                         ||'      ,mtl_category_sets MCS '
                                         ||' WHERE MIC.category_set_id = MCS.category_set_id '
                                         ||' AND MCB.category_id = MIC.category_id '
                                         ||' AND MIC.organization_id = '||ln_master_org_id  
                                         ||' AND category_set_name = ''PO CATEGORY'''
                                         ||' AND MCB.segment2 = ''NON-TRADE'''
                                         ||' AND MIC.INVENTORY_ITEM_ID= MSI.INVENTORY_ITEM_ID)'        
                        ||' AND   MSI.organization_id = '||ln_master_org_id
                        ||' AND length(MSI.segment1) = 5' 
                        ||' AND MSI.inventory_item_status_code <> ''Inactive''';
                        
        IF p_category_set_name IS NOT NULL THEN
            lc_from_clause := lc_from_clause||' ,mtl_item_categories MIC';
            lc_where_clause := lc_where_clause||' AND   MSI.inventory_item_id = MIC.inventory_item_id '
                                              ||' AND   MIC.category_set_id = '||ln_category_set_id
                                              ||' AND   MIC.organization_id = '||ln_master_org_id;
        END IF;
        
        IF ((p_item_from IS NOT NULL) AND (p_item_to IS NOT NULL)) THEN
           lc_where_clause:=lc_where_clause||' AND MSI.segment1 BETWEEN '''||p_item_from||''' AND '''||p_item_to||'''';
        END IF;
        
                
        lc_query:=lc_select_clause||lc_from_clause||lc_where_clause;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Query::'||lc_query);                
        
        BEGIN
            SELECT   val.target_value15
            INTO     ln_item_allow_cnt
            FROM     xx_fin_translatevalues val, xx_fin_translatedefinition def
            WHERE    val.translate_id=def.translate_id
            AND      translation_name = 'IPO_ITEM_ATTRIBUTE_DEFLT2';
        EXCEPTION
        WHEN OTHERS THEN
            ln_item_allow_cnt := 0;
        END;
                
        --Get the Concurrent Program Name
        lc_error_loc   := 'Get the Concurrent Program Name';
        lc_error_debug := 'Concurrent Program id: '||fnd_global.conc_program_id;
        
        SELECT FCPT.user_concurrent_program_name
        INTO   gc_concurrent_program_name
        FROM   fnd_concurrent_programs_tl FCPT
        WHERE  FCPT.concurrent_program_id = fnd_global.conc_program_id
        AND    FCPT.language = 'US';
          
        
        --Deriving the SET_PROCESS_ID from the sequence mtl_system_items_intf_sets_s
        lc_error_loc   := 'Deriving the SET_PROCESS_ID from the sequence MTL_SYSTEM_ITEMS_INTF_SETS_S Create';
        lc_error_debug := '';
        SELECT mtl_system_items_intf_sets_s.NEXTVAL
        INTO   ln_set_process_id_create
        FROM   SYS.DUAL;
        
        ln_batch_cnt := 1;
        lt_plsql (ln_batch_cnt) := ln_set_process_id_create;
        
        lc_error_loc   := 'Deriving the SET_PROCESS_ID from the sequence MTL_SYSTEM_ITEMS_INTF_SETS_S Update';
        lc_error_debug := '';
        
        SELECT mtl_system_items_intf_sets_s.NEXTVAL
        INTO   ln_set_process_id_update
        FROM   SYS.DUAL;
        
        ln_batch_upd_cnt := 1;
        lt_plsql_upd (ln_batch_upd_cnt) := ln_set_process_id_update;
        
        
        -- Commented for Defect ID 7199
        /*-- START of modification  for defect 4608 for performance reasons
        OPEN lcu_items FOR lc_query;  -- Dynamic query added for Defect 2591
        LOOP
                FETCH lcu_items INTO  ln_inventory_item_id, lc_item_nbr;
                EXIT WHEN lcu_items%NOTFOUND;
                lt_item_table(ln_rec_count).inventory_item_id:= ln_inventory_item_id;
                lt_item_table(ln_rec_count).segment1:= lc_item_nbr;
                ln_rec_count:=ln_rec_count+1;
        END LOOP;
        CLOSE lcu_items;
        -- END of modification defect 4608*/
        
        -- Added BULK COLLECT for performance improvment as per Defect ID 7199. Added by Ram
        EXECUTE IMMEDIATE lc_query BULK COLLECT INTO ln_inventory_item_id_t, ln_segment1_t ; 
        
        --Opening the cursor for organization groups. 
        lc_error_loc:='Looping for each organization';
        FOR i IN ln_org_id_t.first .. ln_org_id_t.last  -- changed the organization loop as OUTER loop for performance - defect 4608
        LOOP 
        
           FOR ln_loop_count IN ln_inventory_item_id_t.FIRST .. ln_inventory_item_id_t.LAST -- defect 4608
           LOOP               
               
                --To check if the Item is already assigned to the Organization
                lc_error_loc  := 'Check if the Item is already assigned to the Organization, and to fetch Item Status';
                lc_error_debug := 'Inventory Item id: '||ln_inventory_item_id_t(ln_loop_count);
                lc_error_debug := 'Inventory Organization id: '
                                                ||ln_org_id_t(i);                
                BEGIN
                    SELECT segment1, inventory_item_status_code
                    INTO   lc_item_number, lc_item_status_code
                    FROM   mtl_system_items_fvl
                    WHERE  organization_id = ln_org_id_t(i)
                    AND    inventory_item_id = ln_inventory_item_id_t(ln_loop_count);
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lc_item_number := NULL;
                END;
                
                --IF Item is not assigned to the Inventory Organization
                IF (p_task_type = 1)  AND (lc_item_number IS NULL)  THEN  -- defect 4561
                    
                    --Inserting into the Interface table mtl_system_items_interface
                    lc_error_loc   := 'Inserting into the Interface table MTL_SYSTEM_ITEMS_INTERFACE for the Item Assignment';
                    lc_error_debug := 'Inventory number: '||ln_segment1_t(ln_loop_count)||' Organization_id: '||ln_org_id_t(i);
                    lc_import_item_create := 'Y';
                    
                    IF ln_item_allow_cnt > 0 THEN
                        IF ln_item_cnt = ln_item_allow_cnt THEN
                            ln_item_cnt := 0;
                            SELECT mtl_system_items_intf_sets_s.NEXTVAL
                            INTO   ln_set_process_id_create
                            FROM   SYS.DUAL;
                            ln_batch_cnt := ln_batch_cnt + 1;
                            lt_plsql(ln_batch_cnt) := ln_set_process_id_create;
                        END IF;
                        ln_item_cnt := ln_item_cnt + 1;
                    END IF;
                    
                    INSERT INTO mtl_system_items_interface
                    (
                     segment1
                    ,copy_item_number
                    ,organization_id
                    ,process_flag
                    ,transaction_type
                    ,copy_organization_id
                    ,set_process_id
                    ,inventory_item_status_code
                    )
                    VALUES
                    (
                     ln_segment1_t(ln_loop_count) -- defect 4608
                    ,ln_segment1_t(ln_loop_count) -- defect 4608
                    ,ln_org_id_t(i)
                    ,'1'
                    ,'CREATE'
                    ,ln_master_org_id
                    ,ln_set_process_id_create
                    ,p_item_status
                    );
                    
                END IF;
                
                IF (p_task_type = 2)  AND (lc_item_status_code <> p_item_status) THEN  -- defect 4561
                
                    --Inserting into the Interface table mtl_system_items_interface
                    lc_error_loc   := 'Inserting into the Interface table MTL_SYSTEM_ITEMS_INTERFACE for the Item Assignment';
                    lc_error_debug := 'Item number: '||ln_segment1_t(ln_loop_count)||' Organization_id: '||ln_org_id_t(i);
                    lc_import_item_update := 'Y';
                                        
                    IF ln_item_allow_cnt > 0 THEN
                        IF ln_item_upd_cnt = ln_item_allow_cnt THEN
                            ln_item_upd_cnt := 0;
                            SELECT mtl_system_items_intf_sets_s.NEXTVAL
                            INTO   ln_set_process_id_update
                            FROM   SYS.DUAL;
                            ln_batch_upd_cnt := ln_batch_upd_cnt+1;
                            lt_plsql_upd(ln_batch_upd_cnt) := ln_set_process_id_update;
                        END IF;
                        ln_item_upd_cnt := ln_item_upd_cnt + 1;
                    END IF;
                                                           
                    INSERT INTO mtl_system_items_interface
                    (
                    inventory_item_id
                    ,segment1
                    ,organization_id
                    ,process_flag
                    ,transaction_type
                    ,set_process_id
                    ,inventory_item_status_code
                    )
                    VALUES
                    (
                     ln_inventory_item_id_t(ln_loop_count)  -- defect 4608
                    ,ln_segment1_t(ln_loop_count) -- defect 4608
                    ,ln_org_id_t(i)
                    ,'1'
                    ,'UPDATE'
                    ,ln_set_process_id_update
                    ,p_item_status
                    );
                    
                END IF;
                
            
           END LOOP;
            
          COMMIT;
            
        END LOOP;
        
        
        
        ln_batch_cnt := 1;
        
        IF (lc_import_item_create = 'Y') THEN
            FOR ln_batch_cnt IN lt_plsql.FIRST..lt_plsql.LAST
            LOOP
              --Submitting the Standard program "Import Items" program for Assigning the Items
              lc_error_loc   := 'Submitting the Standard program Import Items for Assiging the Items';
              lc_error_debug := 'SET_PROCESS_ID: '||lt_plsql(ln_batch_cnt);
              ln_conc_req_id_create := FND_REQUEST.SUBMIT_REQUEST(
                                              'INV'
                                              ,'INCOIN'
                                              ,''
                                              ,''
                                              ,FALSE
                                              ,p_organization_id
                                              ,'1'
                                              ,'1'
                                              ,'1'
                                              ,'2'
                                              ,lt_plsql(ln_batch_cnt)
                                              ,'1'
                                              );
              FND_FILE.PUT_LINE(fnd_file.log,'Request id of the Import Items for Assigning the Items: '||ln_conc_req_id_create);
              COMMIT;
              lt_plsql_req (ln_req_cnt) := ln_conc_req_id_create;
              ln_req_cnt := ln_req_cnt + 1;
            END LOOP;
        END IF;
        
        ln_batch_upd_cnt := 1;
        IF (lc_import_item_update = 'Y') THEN
            
            FOR ln_batch_upd_cnt IN lt_plsql_upd.FIRST..lt_plsql_upd.LAST
            LOOP
                --Submitting the Standard program "Import Items" program for Updatinf the Items for Item Status
                lc_error_loc   := 'Submitting the Standard program Import Items for Updating the Items';
                lc_error_debug := 'SET_PROCESS_ID: '||lt_plsql_upd(ln_batch_upd_cnt);
                ln_conc_req_id_update := FND_REQUEST.SUBMIT_REQUEST(
                                                'INV'
                                                ,'INCOIN'
                                                ,''
                                                ,''
                                                ,FALSE
                                                ,p_organization_id
                                                ,'1'
                                                ,'1'
                                                ,'1'
                                                ,'2'
                                                ,lt_plsql_upd(ln_batch_upd_cnt)
                                                ,'2');
                FND_FILE.PUT_LINE(fnd_file.log,'Request id of the Import Items for Updating the Items: '||ln_conc_req_id_update);
            COMMIT;
            
            lt_plsql_req (ln_req_cnt) := ln_conc_req_id_update;
            ln_req_cnt := ln_req_cnt + 1;
            
            END LOOP;
        END IF;
/*
        IF (lc_import_item_create = 'Y') THEN
            --Wait till the completion of Import Items program for Assigning the Items
            lc_error_loc   := 'Wait till the completion of Import Items program for Assigning the Items';
            lc_error_debug := '';
            lb_req_status_create := fnd_concurrent.wait_for_request(
                                             ln_conc_req_id_create
                                            ,'15'
                                            ,''
                                            ,lc_phase_create
                                            ,lc_status_create
                                            ,lc_devphase_create
                                            ,lc_devstatus_create
                                            ,lc_message_create);
            --Checking the status of the 'Import Items' program
            IF ((lc_status_create = 'Warning')
                        OR(lc_status_update = 'Warning')) THEN
                x_ret_code := 1;
            ELSIF ((lc_status_create = 'Error')
                        OR(lc_status_update = 'Error')) THEN
                x_ret_code := 2;
            END IF;
        END IF;
*/
        IF (lc_import_item_update = 'Y') OR (lc_import_item_create = 'Y') THEN
            --Wait till the completion of Import Items program for Updating the Items
            lc_error_loc   := 'Wait till the completion of Import Items program for Assigning the Items for Updating the Items';
            lc_error_debug := '';
            
            ln_req_cnt := 1;
            FOR ln_req_cnt IN lt_plsql_req.FIRST..lt_plsql_req.LAST
            LOOP
              lb_req_status_update := fnd_concurrent.wait_for_request(
                                               lt_plsql_req(ln_req_cnt)
                                              ,'15'
                                              ,''
                                              ,lc_phase_update
                                              ,lc_status_update
                                              ,lc_devphase_update
                                              ,lc_devstatus_update
                                              ,lc_message_update);
              IF (lc_status_update = 'Warning') THEN
                x_ret_code := 1;
              ELSIF (lc_status_update = 'Error') THEN
                x_ret_code := 2;
              END IF;
            END LOOP;
            --Checking the status of the 'Import Items' program
        END IF;
        
    ln_batch_cnt := 1;
    
    FOR ln_batch_cnt IN lt_plsql.FIRST..lt_plsql.LAST
    LOOP
        --Printing the Successfully processed records for New Assignment
        lc_error_loc   := 'Printing the Successfully processed records for New Assignment';
        lc_error_debug := '';
        FND_FILE.PUT_LINE(fnd_file.output,'************************************************************Newly Assigned Items************************************************************');
        FND_FILE.PUT_LINE(fnd_file.output,'************************************************************For Batch No : '|| lt_plsql(ln_batch_cnt)||'**************************************');
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,RPAD('Item Number',20, ' ')||RPAD('Assigned Organization',80, ' '));
        FND_FILE.PUT_LINE(fnd_file.output,RPAD('-----------',20, ' ')||RPAD('---------------------',80, ' '));
        --Opening the cursor for Successfully processed records for New Assignment
        lc_error_loc   := 'Opening the cursor for Successfully processed records';
        lc_error_debug := '';
        FOR lcu_success_rec_create IN c_success_rec_create (lt_plsql(ln_batch_cnt))
        LOOP
            lc_record_found := 'Y';
            FND_FILE.PUT_LINE(fnd_file.output,'');
            FND_FILE.PUT(fnd_file.output,RPAD(lcu_success_rec_create.segment1,20, ' '));
            FND_FILE.PUT(fnd_file.output,RPAD(lcu_success_rec_create.name,80, ' '));
        END LOOP;
        IF (lc_record_found = 'N') THEN
            FND_FILE.PUT_LINE(fnd_file.output,'');
            FND_FILE.PUT_LINE(fnd_file.output,lpad('---No Data Found---',77,' '));
        END IF;
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,'');
        lc_record_found := 'N';
        --Printing the Rejected records for New Assignment
        lc_error_loc   := 'Printing The Rejected Records for New Assignment';
        lc_error_debug := '';
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,'*******************************************************Rejected Items - New Assignment*******************************************************');
        FND_FILE.PUT_LINE(fnd_file.output,'*******************************************************For Batch No : '|| lt_plsql(ln_batch_cnt)||'********************************************');
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,RPAD('Item Number',20, ' ')
                                        ||RPAD('Organization Name',40, ' ')
                                        ||RPAD('Table Name' ,40, ' ')
                                        ||RPAD('Column Name',25, ' ')
                                        ||'Error Message');
        FND_FILE.PUT_LINE(fnd_file.output,RPAD('-----------',20, ' ')
                                        ||RPAD('-----------------' ,40, ' ')
                                        ||RPAD('----------' ,40, ' ')
                                        ||RPAD('-----------',25, ' ')
                                        ||'--------------');
        --Opening the cursor for Rejected records for New Assignment
        lc_error_loc   := 'Opening the cursor for Rejected records';
        lc_error_debug := '';
        FOR lcu_reject_rec_create IN c_reject_rec_create (lt_plsql(ln_batch_cnt))
        LOOP
            lc_record_found := 'Y';
            FND_FILE.PUT_LINE(fnd_file.output,'');
            FND_FILE.PUT(fnd_file.output,RPAD(lcu_reject_rec_create.segment1  ,20, ' ')
                                      ||RPAD(lcu_reject_rec_create.name  ,40, ' ')
                                      ||RPAD(lcu_reject_rec_create.table_name ,40, ' ')
                                      ||RPAD(lcu_reject_rec_create.column_name,25, ' ')
                                      ||lcu_reject_rec_create.error_message);
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'INV'
                ,p_error_location          => 'Rejected records from MTL_INTERFACE_ERRORS for New Assignment'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lcu_reject_rec_create.error_message
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'Item Assignment'
                ,p_object_id               => lcu_reject_rec_create.segment1);
        END LOOP;
        IF (lc_record_found = 'N') THEN
            FND_FILE.PUT_LINE(fnd_file.output,'');
            FND_FILE.PUT_LINE(fnd_file.output,lpad('---No Data Found---',77,' '));
        END IF;
        lc_record_found := 'N';
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,'');
        --Printing the Successfully processed records for Item Status Updation
        lc_error_loc   := 'Printing the Successfully processed records for New Assignment';
        lc_error_debug := '';
        --Puring the Interface table MTL_SYSTEM_ITEMS_INTERFACE for the suceessfully processed records 
        DELETE FROM mtl_system_items_interface
        WHERE set_process_id = lt_plsql(ln_batch_cnt)
        AND   process_flag = 7;
    END LOOP;
    ln_batch_upd_cnt := 1;
    FOR ln_batch_upd_cnt IN lt_plsql_upd.FIRST..lt_plsql_upd.LAST
    LOOP
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,'******************************************************Newly Updated Items - Item Status******************************************************');
        FND_FILE.PUT_LINE(fnd_file.output,'******************************************************For Batch No : '|| lt_plsql_upd(ln_batch_upd_cnt)||'********************************************');
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,RPAD('Item Number',20, ' ')||RPAD('Assigned Organization',50, ' ')||RPAD('New Item Status',30, ' '));
        FND_FILE.PUT_LINE(fnd_file.output,RPAD('-----------',20, ' ')||RPAD('---------------------',50, ' ')||RPAD('---------------',30, ' '));
        --Opening the cursor for Successfully processed records
        lc_error_loc   := 'Opening the cursor for Successfully processed records for Updation of Item Status';
        lc_error_debug := '';
        FOR lcu_success_rec_update IN c_success_rec_update (lt_plsql_upd(ln_batch_upd_cnt))
        LOOP
            lc_record_found := 'Y';
            FND_FILE.PUT_LINE(fnd_file.output,'');
            FND_FILE.PUT(fnd_file.output,RPAD(lcu_success_rec_update.segment1,20, ' '));
            FND_FILE.PUT(fnd_file.output,RPAD(lcu_success_rec_update.name,50, ' '));
            FND_FILE.PUT(fnd_file.output,RPAD(lcu_success_rec_update.inventory_item_status_code,30, ' '));
        END LOOP;
        IF (lc_record_found = 'N') THEN
            FND_FILE.PUT_LINE(fnd_file.output,'');
            FND_FILE.PUT_LINE(fnd_file.output,lpad('---No Data Found---',77,' '));
        END IF;
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,'');
        lc_record_found := 'N';
        --Printing the Rejected records for the Item Status Updation
        lc_error_loc   := 'Printing The Rejected Records for Item Status Updation';
        lc_error_debug := '';
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,'****************************************************Rejected Items - Item Status Updation****************************************************');
FND_FILE.PUT_LINE(fnd_file.output,'************************************************************For Batch No : '|| lt_plsql_upd(ln_batch_upd_cnt)||'********************************************');
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,RPAD('Item Number',20, ' ')
                                        ||RPAD('Organization Name',40, ' ')
                                        ||RPAD('Table Name' ,40, ' ')
                                        ||RPAD('Column Name',25, ' ')
                                        ||'Error Message');
        FND_FILE.PUT_LINE(fnd_file.output,RPAD('-----------',20, ' ')
                                        ||RPAD('-----------------' ,40, ' ')
                                        ||RPAD('----------' ,40, ' ')
                                        ||RPAD('-----------',25, ' ')
                                        ||'--------------');
        --Opening the cursor for Rejected records for New Assignment
        lc_error_loc   := 'Opening the cursor for Rejected records for Item Status Updation';
        lc_error_debug := '';
        FOR lcu_reject_rec_update IN c_reject_rec_update (lt_plsql_upd(ln_batch_upd_cnt))
        LOOP
            lc_record_found := 'Y';
            FND_FILE.PUT_LINE(fnd_file.output,'');
            FND_FILE.PUT(fnd_file.output,RPAD(lcu_reject_rec_update.segment1  ,20, ' ')
                                      ||RPAD(lcu_reject_rec_update.name  ,40, ' ')
                                      ||RPAD(lcu_reject_rec_update.table_name ,40, ' ')
                                      ||RPAD(lcu_reject_rec_update.column_name,25, ' ')
                                      ||lcu_reject_rec_update.error_message);
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => fnd_global.conc_program_id
                ,p_module_name             => 'INV'
                ,p_error_location          => 'Rejected records from MTL_INTERFACE_ERRORS for Updation ITEM_STATUS'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lcu_reject_rec_update.error_message
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'Item Assignment'
                ,p_object_id               => lcu_reject_rec_update.segment1);
        END LOOP;
        --Puring the Interface table MTL_SYSTEM_ITEMS_INTERFACE for the suceessfully processed records 
        DELETE FROM mtl_system_items_interface
        WHERE set_process_id = lt_plsql_upd(ln_batch_upd_cnt)
        AND   process_flag = 7;
    END LOOP;
        IF (lc_record_found = 'N') THEN
            FND_FILE.PUT_LINE(fnd_file.output,'');
            FND_FILE.PUT_LINE(fnd_file.output,lpad('---No Data Found---',77,' '));
        END IF;
    EXCEPTION
        WHEN EX_ITEM_CATSET_PARAM THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_INV_0001_VAL_NOT_PROVIDED');
            lc_err_msg := fnd_message.get;
            FND_FILE.PUT_LINE(fnd_file.log,lc_err_msg);
            FND_FILE.PUT_LINE(fnd_file.output,lc_err_msg);
            x_ret_code := 2;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'INV'
                ,p_error_location          => ''
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'Item Assignment');
        WHEN EX_INV_ORGANIZATION THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_INV_0002_ORG_NOT_SELECTED');
            lc_err_msg := fnd_message.get;
            FND_FILE.PUT_LINE(fnd_file.log,lc_err_msg);
            FND_FILE.PUT_LINE(fnd_file.output,lc_err_msg);
            x_ret_code := 2;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'INV'
                ,p_error_location          => ''
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'Item Assignment');
        WHEN CAT_SET_NOT_DEFINED THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_INV_0035_CAT_SET_NOT_AVLBLE');
            FND_MESSAGE.SET_TOKEN('CAT_SET',p_category_set_name);
            lc_err_msg := fnd_message.get;
            FND_FILE.PUT_LINE(fnd_file.log,lc_err_msg);
            FND_FILE.PUT_LINE(fnd_file.output,lc_err_msg);
            x_ret_code := 2;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'INV'
                ,p_error_location          => ''
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'Item Assignment');  
        WHEN EX_NO_ITEM_STATUS THEN        -- added for defect 4561
            FND_MESSAGE.SET_NAME('XXFIN','XX_INV_0036_NO_ITEM_STATUS');
            lc_err_msg := fnd_message.get;
            FND_FILE.PUT_LINE(fnd_file.log,lc_err_msg);
            FND_FILE.PUT_LINE(fnd_file.output,lc_err_msg);
            x_ret_code := 2;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'INV'
                ,p_error_location          => ''
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'Item Assignment');  
        WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_INV_0003_ERROR');
            FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
            FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
            FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
            lc_loc_err_msg :=  FND_MESSAGE.GET;
            FND_FILE.PUT_LINE(fnd_file.log,lc_loc_err_msg);
            x_ret_code   := 2;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'INV'
                ,p_error_location          => 'Error at ' || SUBSTR(lc_error_loc,1,50)
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => lc_loc_err_msg
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'Item Assignment');
    END PROCESS;
END XX_INV_AUTOASSIGN_PKG;
/
SHOW ERROR;