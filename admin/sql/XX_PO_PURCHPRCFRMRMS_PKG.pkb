SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_PURCHPRCFRMRMS_PKG
 -- +===========================================================================+
 -- |                  Office Depot - Project Simplify                          |
 -- |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
 -- +===========================================================================+
 -- | Name             :  XX_PO_PURCHPRCFRMRMS_PKG.pkb                          |
 -- | Description      :  This Package is used in Inbound Interface of          |
 -- |                     Purchase Price From RMS                               |
 -- | Change Record:                                                            |
 -- |===============                                                            |
 -- |Version   Date         Author           Remarks                            |
 -- |=======   ==========   =============    ===================================|
 -- |Draft 1a  17-Jul-2007  Chandan U H      Initial draft version              |
 -- |Draft 1b  17-JUL-2007  Chandan U H      TL Review                          |
 -- |Draft 1c  01-Aug-2007  Chandan U H      Updated as per Review Comments     |
 -- |1.0       02-Aug-2007  Chandan U H      Base Lined                         |
 -- |1.1       28-Sep-2007  Chandan U H      Incorporated Source Code and Other |
 -- |                                        comments after OD-IT Review        |
 -- |1.2       17-Oct-2007  Chandan U H      Updated for checking Sum of Quantity|
 -- |                                        in case of Same Effective Date     |
 -- |1.3       19-Nov-2007  Chandan U H      CR changes for Approved Lines,     |
 -- |                                        Duplicate Record Check and         |
 -- |                                        Multiple Currency Check            |
 -- |1.4       20-Nov-2007  Chandan U H      Populating batch Id with Custom    |
 -- |                                        sequence                           |
 -- |1.5       30-Nov-2007  Vikas Raina      Changes after onsite Testing       |
 -- +===========================================================================+
AS

-- ---------------------------
-- Global Variable Declaration
-- ---------------------------

GN_MASTER_REQUEST_ID      FND_CONCURRENT_REQUESTS.request_id%TYPE ;
GC_DEBUG_FLAG             VARCHAR2(1);
G_USER_ID                 CONSTANT po_headers_interface.created_by%TYPE  := FND_GLOBAL.user_id;
G_PO_SOURCE               CONSTANT VARCHAR2(30) := 'NA-RMSQTN'; -- Added by Chandan U H
G_CURRENCY_CODE           po_headers_all.currency_code%TYPE:=NULL;--For Currency Validation
G_AGENT_ID                per_all_people_f.person_id%TYPE;--Stores Agent Id
GN_INDEX_REQUEST_ID       PLS_INTEGER    := 0;
GC_APPROVAL_TYPE          po_quotation_approvals_all.approval_type%TYPE :='ALL ORDERS' ;
GC_APPROVAL_REASON        po_quotation_approvals_all.approval_reason%TYPE := 'Quotation from RMS'; -- V1.5
GC_COMMENTS               po_quotation_approvals_all.comments%TYPE := 'Quotation from RMS';
G_BATCH_ID                PLS_INTEGER;--To store the batch Id to be populated in the Interface Table



-- -------------------------------
-- Type declaration for request_id
-- -------------------------------

TYPE xx_qty_price_rec IS RECORD  (
                                   quantity      NUMBER
                                 , price         NUMBER
                                  );


TYPE xx_po_err_disp_rec IS RECORD (
                                   control_id     NUMBER
                                  ,error_message  VARCHAR2(1000)
                                  ,line_num       NUMBER
                                  ,vendor_name    VARCHAR2(240)
                                  ,item           VARCHAR2(40)
                                  );
 
 TYPE  gt_import_prg_req_rec IS RECORD
                                 (
                                  request_id fnd_concurrent_requests.request_id%TYPE
                                  );
-- -----------------------------------------
-- Table type for holding staging table data
-- -----------------------------------------

TYPE gt_qty_price_tbl_type       IS  TABLE  OF  xx_qty_price_rec                           INDEX BY BINARY_INTEGER;
TYPE gt_main_cur_tbl_type        IS  TABLE  OF  xx_po_price_from_rms_stg%ROWTYPE           INDEX BY BINARY_INTEGER;
TYPE g_main_cntrl_id_tbl_type    IS  TABLE  OF  xx_po_price_from_rms_stg.control_id%TYPE   INDEX BY BINARY_INTEGER;
TYPE g_po_line_update_tbl_type   IS  TABLE  OF  po_line_locations_all%ROWTYPE              INDEX BY BINARY_INTEGER;
TYPE g_po_line_loc_del_tbl_type  IS  TABLE  OF  po_line_locations_all%ROWTYPE              INDEX BY BINARY_INTEGER;
TYPE g_po_hdrs_update_tbl_type   IS  TABLE  OF  po_headers_all%ROWTYPE                     INDEX BY BINARY_INTEGER;
TYPE gt_import_prg_req_tbl_type  IS  TABLE  OF  gt_import_prg_req_rec                      INDEX BY BINARY_INTEGER;

-- ----------------------------------------
-- Variable declaration of type -table type
-- ----------------------------------------
g_qty_price_tbl             gt_qty_price_tbl_type;--tier costs and prices to be stored in this variable
g_main_cur_tbl              gt_main_cur_tbl_type;--this would hold the eligible records from staging table
g_main_cntrl_id_tbl         g_main_cntrl_id_tbl_type;--stores control_id
g_po_line_locns_update_tbl  g_po_line_update_tbl_type;--values of records which need to be updated
g_po_line_locns_delete_tbl  g_po_line_loc_del_tbl_type;--values of records which need to be deleted
gt_import_prg_req_tbl       gt_import_prg_req_tbl_type;--to store the request Ids of Import Price catalogs in case of multiple OU's

-- +=========================================================================+
-- | Name        :  display_log                                              |
-- | Description :  This procedure is invoked to print in the log file       |
-- |                                                                         |
-- |In Parameters:  p_message                                                |
-- +=========================================================================+
PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
    IF NVL(gc_debug_flag,'N') ='Y' THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
    END IF;
END;
-- +=========================================================================+
-- | Name        :  display_out                                              |
-- | Description :  This procedure is invoked to print in the output         |
-- |                file                                                     |
-- |                                                                         |
-- |In Parameters:  p_message                                                |
-- +=========================================================================+

PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )

IS

BEGIN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END display_out;
-- +========================================================================+
-- | Name        :  log_procedure                                           |
-- |                                                                        |
-- | Description :  This procedure is invoked to log the exceptions in      |
-- |                the common exception log table                          |
-- |                                                                        |
-- |                                                                        |
-- | Parameters  : p_program_type                                           |
-- |               p_program_name                                           |
-- |               p_error_location                                         |
-- |               p_error_message_code                                     |
-- |               p_error_message                                          |
-- |               p_error_message_severity                                 |
-- |               p_notify_flag                                            |
-- |               p_object_id                                              |
-- |               p_attribute1                                             |
-- +========================================================================+
PROCEDURE log_procedure(  p_program_name           IN VARCHAR2
                         ,p_error_location         IN VARCHAR2
                         ,p_error_message_code     IN VARCHAR2
                         ,p_error_message          IN VARCHAR2
                         ,p_error_message_severity IN VARCHAR2
                         ,p_notify_flag            IN VARCHAR2
                         ,p_object_id              IN VARCHAR2
                         ,p_attribute1             IN VARCHAR2
                         )
IS

BEGIN
     -- -----------------------------------------------------------------
     -- Call the common package to log exceptions
     -- -----------------------------------------------------------------
     XX_COM_ERROR_LOG_PUB.log_error (
                                     p_program_type            => 'CUSTOM API'
                                    ,p_program_name            => 'XX_PO_PURCHPRCFRMRMS_PKG'||'.'||p_program_name
                                    ,p_program_id              =>  NULL
                                    ,p_module_name             => 'PO'
                                    ,p_error_location          => p_error_location
                                    ,p_error_message_count     => NULL
                                    ,p_error_message_code      => p_error_message_code
                                    ,p_error_message           => p_error_message
                                    ,p_error_message_severity  => p_error_message_severity
                                    ,p_notify_flag             => p_notify_flag
                                    ,p_object_type             => 'Quotations Interface Program'
                                    ,p_object_id               => p_object_id
                                    ,p_attribute1              => p_attribute1
                                    ,p_attribute2              => 'PO Quotations from RMS'
                                    ,p_return_code             => NULL
                                    ,p_msg_count               => NULL
                                    );
EXCEPTION
   WHEN OTHERS THEN
       display_log('Error in logging exception messages in log_procedure of child_main procedure');
       display_log(SQLERRM);
END log_procedure;

-- +========================================================================+
-- | Name        :  delete_from_stg                                         |
-- |                                                                        |
-- | Description :  This procedure is invoked to delete the records from    |
-- |                the staging table after p_purge_days                    |
-- |                                                                        |
-- | Parameters  : p_purge_days                                             |
-- |               x_retcode                                                |
-- +========================================================================+
procedure delete_from_stg (
                            p_purge_days IN          NUMBER
                           ,x_retcode    OUT NOCOPY  NUMBER
                          )
IS

BEGIN

   display_log('Purging from Staging table the records whose last update date is more than '||p_purge_days||' if any..' );
   -- delete after p_purge_days
   DELETE
   FROM  xx_po_price_from_rms_stg
   WHERE status IN (3,4)
   AND   TRUNC(last_update_date) < TRUNC(SYSDATE - p_purge_days);

EXCEPTION
   WHEN OTHERS THEN
        log_procedure(p_program_name           => 'main'
                     ,p_error_location         => 'WHEN OTHERS THEN when deleting records from XX_PO_PRICE_FROM_RMS_STG'
                     ,p_error_message_code     =>  SQLCODE
                     ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                     ,p_error_message_severity =>  'MAJOR'
                     ,p_notify_flag            =>  'Y'
                     ,p_object_id              =>  NULL
                     ,p_attribute1             =>  NULL
                 );
     x_retcode := 1;
     display_log('Unexpected Errors when deleting from staging table');
END delete_from_stg;

-- +========================================================================+
-- | Name        :  PRE_PROCESS                                             |
-- |                                                                        |
-- | Description :  This procedure is invoked in order to retain the        |
-- |                already existing price-breaks which would get deleted on|
-- |                update of other price breaks                            |
-- |                                                                        |
-- | Parameters  : p_header_id                                              |
-- |               p_real_effective_date                                    |
-- |               p_line_id                                                |
-- |               p_line_num                                               |
-- |               p_line_type_id                                           |
-- |               x_next_shipment_num                                      |
-- |               x_interface_header_id                                    |
-- +========================================================================+
PROCEDURE pre_process ( p_control_id            IN            NUMBER
                       ,p_header_id             IN            NUMBER
                       ,p_real_effective_date   IN            DATE
                       ,p_line_id               IN            NUMBER
                       ,p_line_num              IN            NUMBER
                       ,p_line_type_id          IN            NUMBER
                       ,p_start_date            IN            DATE
                       ,x_next_shipment_num     OUT NOCOPY    NUMBER
                       ,x_interface_header_id   OUT NOCOPY    NUMBER
                       )
IS
--------------------------------
--  Local Variables Declaration
-------------------------------
lc_segment1               po_headers_all.segment1%TYPE;--segment1 at header level of the existing record which is to be retained
ln_line_type_id           po_lines_all.line_type_id%TYPE;--line_type_id at line level of the existing record which is to be retained
ln_inventory_item_id      po_lines_all.item_id%TYPE;--item_id  at line level of the existing record which is to be retained
ln_line_num               po_lines_all.line_num%TYPE;--line number at line level of the existing record which is to be retained
lc_currency_code          po_headers_all.currency_code%TYPE;--currency_code at header level of the existing record which is to be retained
ln_agent_id               po_headers_all.agent_id%TYPE;--agent_id at header level of the existing record which is to be retained
ln_vendor_id              po_headers_all.vendor_id%TYPE;-- vendor_id at header level of the existing record which is to be retained
ln_vendor_site_id         po_headers_all.vendor_site_id %TYPE;-- vendor_site_id at header level of the existing record which is to be retained
ln_organization_id        po_headers_all.org_id%TYPE;-- org_id at header level of the existing record which is to be retained
lc_unit_meas_lookup_code  po_lines_all.unit_meas_lookup_code%TYPE;--unit_meas_lookup_code at line level of the existing record which is to be retained
ld_creation_date          DATE;--creation_date at header level of the existing record which is to be retained
ld_last_update_date       DATE;--last_update_date at header level of the existing record which is to be retained
ln_created_by             PLS_INTEGER;--ln_created_by at header level of the existing record which is to be retained
ln_last_updated_by        PLS_INTEGER;--ln_last_updated_by at header level of the existing record which is to be retained
ln_last_update_login      PLS_INTEGER;--last_update_login at header level of the existing record which is to be retained
ln_next_shipment_num      PLS_INTEGER :=1;--Next shipment number


TYPE lt_retain_records_tbl is TABLE OF po_line_locations_all%ROWTYPE;
lt_retain_records lt_retain_records_tbl;--to store values of records that are to be retained
------------------------------------------------
--Cursor to fetch Header and line level details
------------------------------------------------
CURSOR lcu_header_line_records
IS
SELECT PH.segment1
      ,PH.vendor_id
      ,PH.vendor_site_id
      ,PH.org_id
      ,PH.agent_id
      ,PH.currency_code
      ,PH.creation_date
      ,PH.created_by
      ,PH.last_update_date
      ,PH.last_updated_by
      ,PH.last_update_login
      ,PL.line_type_id
      ,PL.item_id
      ,PL.line_num
      ,PL.unit_meas_lookup_code
FROM   po_headers_all PH
      ,po_lines_all PL
WHERE  PH.po_header_id  =  PL.po_header_id
AND    PH.po_header_id  =  p_header_id
AND    PL.po_line_id    =  p_line_id;
-------------------------------------------------------------
--Cursor to fetch the po_line_location details of the already
-- existing records that need to be retained
-------------------------------------------------------------
CURSOR lcu_retain_records
IS
SELECT *
FROM   po_line_locations_all
WHERE  po_header_id      = p_header_id
AND    po_line_id        = p_line_id
AND    TRUNC(start_date) <> TRUNC(p_real_effective_date)
AND    TRUNC(p_real_effective_date) NOT BETWEEN TRUNC(NVL(start_date,SYSDATE)) AND NVL(end_date, SYSDATE+3650)
AND    TRUNC(start_date) <> NVL(p_start_date, SYSDATE+3650)--Added by Chandan U H--This is to avoid retaining the Already end-dated record whose copy was being created earlier.
ORDER  BY start_date,quantity;

BEGIN

    OPEN  lcu_retain_records;
    FETCH lcu_retain_records BULK COLLECT INTO lt_retain_records;
    CLOSE lcu_retain_records;

    OPEN  lcu_header_line_records;
    FETCH lcu_header_line_records INTO  lc_segment1,ln_vendor_id,ln_vendor_site_id,ln_organization_id,ln_agent_id,lc_currency_code
                                       ,ld_creation_date,ln_created_by,ld_last_update_date,ln_last_updated_by,ln_last_update_login
                                       ,ln_line_type_id,ln_inventory_item_id,ln_line_num,lc_unit_meas_lookup_code;
        IF lcu_header_line_records%NOTFOUND THEN
            --Adding error message to stack
            log_procedure(  p_program_name           => 'pre_process'
                           ,p_error_location         => 'NO_DATA_FOUND'
                           ,p_error_message_code     =>  SQLCODE
                           ,p_error_message          =>  'No Data Found while selecting header and line level details for retain records'
                           ,p_error_message_severity =>  'MINOR'
                           ,p_notify_flag            =>  'Y'
                           ,p_object_id              =>  NULL
                           ,p_attribute1             =>  NULL
                          );

        END IF;
    CLOSE lcu_header_line_records;

    display_log('The count of Records that would be retained :'||lt_retain_records.COUNT);

       BEGIN
         INSERT INTO po_headers_interface(
                           INTERFACE_HEADER_ID
                          ,DOCUMENT_NUM
                          ,INTERFACE_SOURCE_CODE
                          ,PROCESS_CODE
                          ,BATCH_ID
                          ,ACTION
                          ,REQUEST_ID
                          ,DOCUMENT_TYPE_CODE
                          ,DOCUMENT_SUBTYPE
                          ,CURRENCY_CODE
                          ,AGENT_ID
                          ,VENDOR_ID
                          ,VENDOR_SITE_ID
                          ,ORG_ID
                          ,PO_HEADER_ID
                          ,QUOTE_WARNING_DELAY
                          ,ATTRIBUTE_CATEGORY
                          ,CREATION_DATE
                          ,CREATED_BY
                          ,LAST_UPDATE_DATE
                          ,LAST_UPDATED_BY
                          ,LAST_UPDATE_LOGIN
                          ,ATTRIBUTE1
                           )
                   VALUES(
                           PO_HEADERS_INTERFACE_S.nextval
                          ,lc_segment1
                          ,'I1078-'||p_control_id
                           ,'PENDING'
                           , G_BATCH_ID
                           ,'UPDATE'
                           ,gn_master_request_id
                           ,'QUOTATION'
                           ,'CATALOG'
                           ,lc_currency_code
                           ,ln_agent_id
                           ,ln_vendor_id
                           ,ln_vendor_site_id
                           ,ln_organization_id
                           ,p_header_id
                           ,0
                           , 'Trade Quotation'
                           ,ld_creation_date
                           ,ln_created_by
                           ,ld_last_update_date
                           ,ln_last_updated_by
                           ,ln_last_update_login
                           ,G_PO_SOURCE
                           );
       EXCEPTION
       WHEN OTHERS THEN
             log_procedure(  p_program_name           => 'pre_process'
                            ,p_error_location         => 'WHEN OTHERS THEN of inserting into po_headers_interface for Retain Records'
                            ,p_error_message_code     =>  SQLCODE
                            ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                            ,p_error_message_severity =>  'MAJOR'
                            ,p_notify_flag            =>  'Y'
                            ,p_object_id              =>  NULL
                            ,p_attribute1             =>  NULL
                           );
           display_log('Unexpected Errors When inserting into po_headers_interface for Retain Records');
       END;

    IF lt_retain_records.COUNT > 0 THEN

        FOR indx_retain_rec in lt_retain_records.FIRST..lt_retain_records.LAST
        LOOP
             BEGIN
                  INSERT INTO po_lines_interface(
                           INTERFACE_LINE_ID
                          ,INTERFACE_HEADER_ID
                          ,ACTION
                          ,LINE_NUM
                          ,SHIPMENT_NUM
                          ,LINE_TYPE
                          ,DOCUMENT_NUM
                          ,PO_LINE_ID
                          ,ITEM_ID
                          ,QUANTITY
                          ,UNIT_PRICE
                          ,UNIT_OF_MEASURE
                          ,SHIPMENT_TYPE
                          ,LINE_ATTRIBUTE_CATEGORY_LINES
                          ,SHIPMENT_ATTRIBUTE6
                          ,SHIPMENT_ATTRIBUTE7
                          ,SHIPMENT_ATTRIBUTE8
                          ,SHIPMENT_ATTRIBUTE_CATEGORY
                          ,CREATION_DATE
                          ,CREATED_BY
                          ,LAST_UPDATE_DATE
                          ,LAST_UPDATED_BY
                          ,LAST_UPDATE_LOGIN
                          ,LINE_TYPE_ID
                          ,EFFECTIVE_DATE
                          ,EXPIRATION_DATE
                         )
                 VALUES(
                           PO_LINES_INTERFACE_S.nextval
                          ,PO_HEADERS_INTERFACE_S.currval
                          ,'UPDATE'
                          ,ln_line_num
                          ,ln_next_shipment_num
                          ,'Goods'
                          ,lc_segment1
                          ,p_line_id
                          ,ln_inventory_item_id
                          ,lt_retain_records(indx_retain_rec).quantity
                          ,lt_retain_records(indx_retain_rec).price_override
                          ,lc_unit_meas_lookup_code
                          ,'QUOTATION'
                          ,'Trade Quotation'
                          ,lt_retain_records(indx_retain_rec).attribute6
                          ,lt_retain_records(indx_retain_rec).attribute7
                          ,lt_retain_records(indx_retain_rec).attribute8
                          ,'Trade Quotation'
                          ,lt_retain_records(indx_retain_rec).creation_date
                          ,lt_retain_records(indx_retain_rec).created_by
                          ,lt_retain_records(indx_retain_rec).last_update_date
                          ,lt_retain_records(indx_retain_rec).last_updated_by
                          ,lt_retain_records(indx_retain_rec).last_update_login
                          ,ln_line_type_id
                          ,lt_retain_records(indx_retain_rec).start_date
                          ,lt_retain_records(indx_retain_rec).end_date
                       );

                    ln_next_shipment_num:=ln_next_shipment_num + 1;--Increment the shipment number for each line
             EXCEPTION
             WHEN OTHERS THEN
                 log_procedure(  p_program_name           => 'pre_process'
                                ,p_error_location         => 'WHEN OTHERS THEN of inserting into po_lines_interface of retain records'
                                ,p_error_message_code     =>  SQLCODE
                                ,p_error_message          =>  'Unexpected Errors when inserting into po_lines_interface of retain records'
                                ,p_error_message_severity =>  'MAJOR'
                                ,p_notify_flag            =>  'Y'
                                ,p_object_id              =>  NULL
                                ,p_attribute1             =>  NULL
                               );
                  display_log('When OTHERS error while inserting data into PO lines interface table at retain records - '||SQLERRM);
             END;

        END LOOP;
              x_next_shipment_num:=ln_next_shipment_num;
    ELSE
               x_next_shipment_num := 1;
    END IF;-- IF lt_retain_records.COUNT > 0
    -------------------------------------------------------------------------------------------
    --Selecting the currval of interface header id which is sent as out parameter and used for
    --further line inserts which belong to this header id
    -------------------------------------------------------------------------------------------

    SELECT PO_HEADERS_INTERFACE_S.currval
    INTO   x_interface_header_id
    FROM   DUAL;

END pre_process;
-- +====================================================================+
-- | Name        : process_po                                           |
-- | Description : This procedure is invoked from the main procedure.   |
-- |               This procedure will submit the standard 'Import Price|
-- |               Catalog' concurrent to populate the EBS base tables. |
-- |                                                                    |
-- | In Parameters  :    p_batch_id                                     |
-- | Out Parameters :    x_errbuf                                       |
-- |                     x_retcode                                      |
-- |                                                                    |
-- +====================================================================+
PROCEDURE  process_po(
                      x_errbuf         OUT  NOCOPY  VARCHAR2
                     ,x_retcode        OUT  NOCOPY  NUMBER
                     ,p_batch_id       IN           NUMBER
                     ,p_debug_flag     IN           VARCHAR2
                     )
IS
----------------------------------------------
--  Local Variables and exceptions Declaration
----------------------------------------------
EX_SUBMIT_FAIL              EXCEPTION;
EX_NORMAL_COMPLETION_FAIL   EXCEPTION;

lt_conc_request_id          FND_CONCURRENT_REQUESTS.request_id%TYPE;--conc_request_id of POXPDOI
lb_wait                     BOOLEAN;--wait time
lc_phase                    VARCHAR2(50);--phase of the program
lc_status                   VARCHAR2(50);--status of the program
lc_dev_phase                VARCHAR2(50);--dev phase of the program
lc_dev_status               VARCHAR2(50);--dev status of the program
lc_message                  VARCHAR2(1000);

----------------------------------------------------
--Cursor to fetch Distinct Operating unit in a batch
----------------------------------------------------
CURSOR lcu_operating_unit
IS
SELECT DISTINCT PHI.org_id
FROM   po_headers_interface PHI
WHERE  PHI.batch_id = p_batch_id
AND    PHI.interface_source_code LIKE 'I1078-%';

BEGIN

   FOR lcu_operating_unit_rec IN lcu_operating_unit
   LOOP
       ---------------------------------------------------------------
       -- Submitting Standard Purchase Order Import concurrent program
       ---------------------------------------------------------------

       lt_conc_request_id := FND_REQUEST.submit_request(
                                                       application   => 'PO'
                                                      ,program       => 'POXPDOI'
                                                      ,description   => 'Import Price Catalogs (Blanket and Quotation) Program'
                                                      ,start_time    => NULL
                                                      ,sub_request   => FALSE -- FALSE means is not a sub request
                                                      ,argument1     => NULL --Default Buyer
                                                      ,argument2     => 'Quotation'-- Document Type
                                                      ,argument3     => 'Catalog'-- Document  SubType
                                                      ,argument4     => 'N' --Create or Update  Items
                                                      ,argument5     => 'N' -- Create Sourcing Rules
                                                      ,argument6     => 'APPROVED'--Approval Status
                                                      ,argument7     => NULL--Release Generation Method
                                                      ,argument8     => p_batch_id
                                                      ,argument9     => lcu_operating_unit_rec.org_id --NULL
                                                      ,argument10    => NULL
                                                      );

       IF lt_conc_request_id = 0 THEN
            x_errbuf  := fnd_message.GET;
            display_log('Standard Import Price Catalog program failed to submit: ' || x_errbuf);
            RAISE EX_SUBMIT_FAIL;
       ELSE
            COMMIT;
           display_log('Submitted Standard Import Price Catalog program Successfully : '|| lt_conc_request_id );
           gn_index_request_id := gn_index_request_id + 1;
           gt_import_prg_req_tbl(gn_index_request_id).request_id := lt_conc_request_id;
          ----------------------------------------------------------------
          --Wait till the standard import program completes for this Batch
          ----------------------------------------------------------------
           lb_wait := fnd_concurrent.wait_for_request(  request_id  => lt_conc_request_id
                                                       ,interval    => 20
                                                       ,phase       => lc_phase
                                                       ,status      => lc_status
                                                       ,dev_phase   => lc_dev_phase
                                                       ,dev_status  => lc_dev_status
                                                       ,message     => lc_message
                                                      );

              IF ((lc_dev_phase = 'COMPLETE') AND (lc_dev_status = 'NORMAL')) THEN

                 display_log('Submitted Standard Import Price Catalog program Successfully Completed: '||lt_conc_request_id||'completed with normal status');

              ELSE

                  display_log('Standard Import Price Catalog program with request id:'||lt_conc_request_id||'did not complete with normal status');
                  RAISE EX_NORMAL_COMPLETION_FAIL;
              END IF;--IF ((lc_dev_phase = 'COMPLETE') AND (lc_dev_status = 'NORMAL'))

       END IF;--lt_conc_request_id = 0

   END LOOP;

EXCEPTION
    WHEN EX_SUBMIT_FAIL THEN
       x_retcode := 2;
       x_errbuf  := 'Standard Import Price Catalog program failed to submit: ' || x_errbuf;

    WHEN EX_NORMAL_COMPLETION_FAIL THEN
       x_retcode := 2;
       x_errbuf  := 'Standard Import Price Catalog program failed to Complete Normally' || x_errbuf;

    WHEN OTHERS THEN
       x_errbuf  := 'Unexpected Exception is raised in Procedure PROCESS_PO '||substr(SQLERRM,1,200);
       x_retcode := 2;
END process_po;

-- +===================================================================+
-- | Name        :  approve_quotation_lines                            |
-- |                                                                   |
-- | Description :  This procedure will approve the Quotation lines    |
-- |                by calling a Standard API QUOTATION_APPROVALS_PKG  |
-- |                                                                   |
-- | In Parameters : Same as API QUOTATION_APPROVALS_PKG               |
-- |                                                                   |
-- | Out Parameters: Same as API QUOTATION_APPROVALS_PKG x_errbuf      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE approve_quotation_lines
                       (
                         p_rowid                  IN OUT NOCOPY   VARCHAR2
                        ,p_quotation_approval_id  IN OUT NOCOPY   NUMBER
                        ,p_approval_type          IN     VARCHAR2
                        ,p_approval_reason        IN     VARCHAR2
                        ,p_comments               IN     VARCHAR2
                        ,p_approver_id            IN     NUMBER
                        ,p_start_date_active      IN     DATE
                        ,p_end_date_active        IN     DATE
                        ,p_line_location_id       IN     NUMBER
                        ,p_last_update_date       IN     DATE
                        ,p_last_updated_by        IN     NUMBER
                        ,p_last_update_login      IN     NUMBER
                        ,p_creation_date          IN     DATE
                        ,p_created_by             IN     NUMBER
                        ,p_attribute_category     IN     VARCHAR2
                        ,p_attribute1             IN     VARCHAR2
                        ,p_attribute2             IN     VARCHAR2
                        ,p_attribute3             IN     VARCHAR2
                        ,p_attribute4             IN     VARCHAR2
                        ,p_attribute5             IN     VARCHAR2
                        ,p_attribute6             IN     VARCHAR2
                        ,p_attribute7             IN     VARCHAR2
                        ,p_attribute8             IN     VARCHAR2
                        ,p_attribute9             IN     VARCHAR2
                        ,p_attribute10            IN     VARCHAR2
                        ,p_attribute11            IN     VARCHAR2
                        ,p_attribute12            IN     VARCHAR2
                        ,p_attribute13            IN     VARCHAR2
                        ,p_attribute14            IN     VARCHAR2
                        ,p_attribute15            IN     VARCHAR2
                        ,p_request_id             IN     NUMBER
                        ,p_program_application_id IN     NUMBER
                        ,p_program_id             IN     NUMBER
                        ,p_program_update_date    IN     DATE
                       )

IS

p_line_id       NUMBER;
ln_line_loc_id  NUMBER;

------------------------------------------------------
--Cursor to find the all the PO Line Location Ids that
--need to be approved
------------------------------------------------------
CURSOR lcu_line_loc_id(p_request_id NUMBER)
IS
   SELECT line_location_id
   FROM   po_line_locations_all plla
   WHERE  plla.request_id = p_request_id;

BEGIN

    FOR req_id_idx IN gt_import_prg_req_tbl.FIRST..gt_import_prg_req_tbl.LAST
    LOOP
 
          FOR lcu_line_locations_rec IN lcu_line_loc_id(gt_import_prg_req_tbl(req_id_idx).request_id)
          LOOP
             display_log('Inside Loop of Cursor ');
             display_log('lcu_line_locations_rec.line_location_id '||lcu_line_locations_rec.line_location_id);
             QUOTATION_APPROVALS_PKG.Insert_Row(
                                             X_Rowid                    =>     p_rowid
                                            ,X_Quotation_Approval_ID    =>     p_quotation_approval_id
                                            ,X_Approval_Type            =>     p_approval_type
                                            ,X_Approval_Reason          =>     p_approval_reason
                                            ,X_Comments                 =>     p_comments
                                            ,X_Approver_ID              =>     p_approver_id
                                            ,X_Start_Date_Active        =>     p_start_date_active
                                            ,X_End_Date_Active          =>     p_end_date_active
                                            ,X_Line_Location_ID         =>     lcu_line_locations_rec.line_location_id
                                            ,X_Last_Update_Date         =>     p_last_update_date
                                            ,X_Last_Updated_By          =>     p_last_updated_by
                                            ,X_Last_Update_Login        =>     p_last_update_login
                                            ,X_Creation_Date            =>     p_creation_date
                                            ,X_Created_By               =>     p_created_by
                                            ,X_Attribute_Category       =>     p_attribute_category
                                            ,X_Attribute1               =>     p_attribute1
                                            ,X_Attribute2               =>     p_attribute2
                                            ,X_Attribute3               =>     p_attribute3
                                            ,X_Attribute4               =>     p_attribute4
                                            ,X_Attribute5               =>     p_attribute5
                                            ,X_Attribute6               =>     p_attribute6
                                            ,X_Attribute7               =>     p_attribute7
                                            ,X_Attribute8               =>     p_attribute8
                                            ,X_Attribute9               =>     p_attribute9
                                            ,X_Attribute10              =>     p_attribute10
                                            ,X_Attribute11              =>     p_attribute11
                                            ,X_Attribute12              =>     p_attribute12
                                            ,X_Attribute13              =>     p_attribute13
                                            ,X_Attribute14              =>     p_attribute14
                                            ,X_Attribute15              =>     p_attribute15
                                            ,X_Request_ID               =>     p_request_id
                                            ,X_Program_Application_ID   =>     p_program_application_id
                                            ,X_Program_ID               =>     p_program_id
                                            ,X_Program_Update_Date      =>     p_program_update_date
                                             );

              p_rowid                  := NULL;
              p_quotation_approval_id  := NULL;
          END LOOP;
 
    END LOOP; -- End loop for number of request Ids(Differrent OU case)
 
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        log_procedure(   p_program_name           => 'approve_quotation_lines'
                        ,p_error_location         => 'WHEN OTHERS THEN in approve_quotation_lines'
                        ,p_error_message_code     =>  SQLCODE
                        ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                        ,p_error_message_severity =>  'MAJOR'
                        ,p_notify_flag            =>  'Y'
                        ,p_object_id              =>  NULL
                        ,p_attribute1             =>  NULL
                        );

END approve_quotation_lines;

-- +===================================================================+
-- | Name        :  insert_into_po_interface                           |
-- |                                                                   |
-- | Description:  This procedure will insert records in Standard      |
-- |               Interface depending on actions to be performed      |
-- |               po_headers_interface table                          |
-- |                                                                   |
-- |                                                                   |
-- | In Parameters : p_debug_flag                                      |
-- |                                                                   |
-- |                                                                   |
-- | Out Parameters :x_errbuf                                          |
-- |                 x_retcode                                         |
-- +===================================================================+
 PROCEDURE  insert_into_po_interface   (  x_errbuf                OUT  NOCOPY  VARCHAR2
                                         ,x_retcode               OUT  NOCOPY  NUMBER
                                         ,p_control_id             IN          NUMBER
                                         ,p_create_flag            IN          VARCHAR2
                                         ,p_header_id              IN          NUMBER
                                         ,p_segment1               IN          VARCHAR2
                                         ,p_line_num               IN          NUMBER
                                         ,p_po_line_id             IN          NUMBER
                                         ,p_po_line_type_id        IN          NUMBER
                                         ,p_inventory_item_id      IN          NUMBER
                                         ,p_currency_code          IN          VARCHAR2
                                         ,p_item                   IN          VARCHAR2
                                         ,p_uom                    IN          VARCHAR2
                                         ,p_supplier               IN          NUMBER
                                         ,p_vendor_site_id         IN          NUMBER
                                         ,p_organization_id        IN          NUMBER
                                         ,p_agent_id               IN          NUMBER
                                         ,p_unit_cost              IN          NUMBER
                                         ,p_tier1_cost             IN          NUMBER
                                         ,p_tier2_cost             IN          NUMBER
                                         ,p_tier3_cost             IN          NUMBER
                                         ,p_tier4_cost             IN          NUMBER
                                         ,p_tier5_cost             IN          NUMBER
                                         ,p_tier6_cost             IN          NUMBER
                                         ,p_total_cost             IN          NUMBER
                                         ,p_unit_qty               IN          NUMBER
                                         ,p_tier1_qty              IN          NUMBER
                                         ,p_tier2_qty              IN          NUMBER
                                         ,p_tier3_qty              IN          NUMBER
                                         ,p_tier4_qty              IN          NUMBER
                                         ,p_tier5_qty              IN          NUMBER
                                         ,p_tier6_qty              IN          NUMBER
                                         ,p_price_protection_flag  IN          VARCHAR2
                                         ,p_active_date            IN          DATE
                                         ,p_real_effective_date    IN          DATE
                                         ,p_end_date               IN          DATE
                                         ,p_creation_date          IN          DATE
                                         ,p_created_by             IN          NUMBER
                                         ,p_last_update_date       IN          DATE
                                         ,p_last_updated_by        IN          NUMBER
                                         ,p_start_date             IN          DATE
                                         ,p_supplier_exists        IN          VARCHAR2
                                         ,p_interface_header_id    IN          NUMBER
                                        )
IS
---------------------------------
--  Local Variables  Declaration
---------------------------------
--ln_total_quantity           NUMBER      := 0;--sum of the quantity of the matched records
ld_copy_creation_date       DATE;--date of the record identified for creating a copy of
ld_start_date               DATE;--start date of the price break
ld_copy_date                DATE;
ln_line_num                 PLS_INTEGER := 1;--line number of the item
ln_no_lines_matching        PLS_INTEGER := 0;--7 lines need to match to qualify it for a copy record
ln_new_item_line_num        PLS_INTEGER;--line number on which new item is to be created on the existing quotation
ln_line_num_for_new         PLS_INTEGER;--line number for new item
ln_line_type_id             PLS_INTEGER;--line_type_id
ln_po_line_id               PLS_INTEGER;--line id
ln_po_line_type_id          PLS_INTEGER;--po_line_type_id
ln_line_num_for_delete      PLS_INTEGER;--line number for delete operation
ln_next_shipment_num        PLS_INTEGER;--next shipment number to be inserted in po_lines_interface
ln_interface_header_id      PLS_INTEGER;--PO_HEADERS_INTERFACE_S.nextval
ln_indx_update_price        PLS_INTEGER:=0;--index to update price only
ln_indx_line_count          PLS_INTEGER:=0;--index of line interface table type
ln_indx_header_count        PLS_INTEGER:=0;--index of header interface table type
ln_interface_line_id        PLS_INTEGER;--PO_LINES_INTERFACE_S.nextval
ln_shipment_num             PLS_INTEGER:=0;--shipment NUMBER
ln_total_quantity           NUMBER:=0;--sum of quantities of new tiers
ln_existing_sum_quantity    NUMBER:=0;--sum of quantities of existing tiers
lc_delete_record_found_flag VARCHAR2(1):= 'Y';
lc_insert_flag              VARCHAR2(1):= 'N';
lc_currency_match           VARCHAR2(1):= 'N';
lc_currency_code            po_headers_all.currency_code%TYPE;
lc_no_del_rec_err_msg       VARCHAR2(240);--variable to store error message
lc_no_prior_rec_err_msg     VARCHAR2(240);--variable to store error message
lc_curr_mis_mtch_err_msg     VARCHAR2(240);--variable to store error message
lc_no_match_qty_err_msg      VARCHAR2(240);--variable to store error message

TYPE lt_create_copy_tbl IS TABLE OF  po_line_locations_all%ROWTYPE;
lt_create_copy  lt_create_copy_tbl;

TYPE lt_to_be_deleted_tbl_type IS TABLE OF  po_line_locations_all%ROWTYPE;
lt_to_be_deleted_tbl   lt_to_be_deleted_tbl_type;

TYPE po_headers_tbl_typ IS TABLE OF po_headers_interface%rowtype
INDEX bY BINARY_INTEGER;
lt_po_headers po_headers_tbl_typ;

TYPE po_lines_tbl_typ IS TABLE OF po_lines_interface%rowtype
INDEX bY BINARY_INTEGER;
lt_po_lines po_lines_tbl_typ;

------------------------------------------------------
--Cursor to fetch record which has come in for delete
------------------------------------------------------
CURSOR lcu_g_to_be_deleted(p_real_effective_date IN  DATE
                          ,p_po_line_id          IN  NUMBER
                          ,p_header_id           IN  NUMBER
                           )
IS
SELECT PLL.*
FROM   po_line_locations_all PLL
WHERE  PLL.po_header_id      = p_header_id
AND    PLL.po_line_id        = p_po_line_id
AND    TRUNC(PLL.start_date) = TRUNC(p_real_effective_date)
AND    TRUNC(PLL.end_date) IS NULL;--need to delete record,only if it does not have an end date.


-------------------------------------------------------------------
--Cursor to identify start_date of the immeadiate prior price-break
-------------------------------------------------------------------
CURSOR lcu_already_deleted (p_real_effective_date IN  DATE
                           ,p_po_line_id          IN  NUMBER
                           ,p_header_id           IN  NUMBER
                           )
IS
SELECT MAX(TRUNC(start_date)) start_date
FROM   po_line_locations_all PLL
WHERE  PLL.po_header_id = p_header_id
AND    PLL.po_line_id   = p_po_line_id
AND    TRUNC(end_date)  < TRUNC(p_real_effective_date)
GROUP  BY start_date
ORDER  BY start_date DESC;

-------------------------------------------------------------
--Cursor to fetch details of the immeadiate prior price-break
-------------------------------------------------------------
CURSOR lcu_create_copy (p_copy_date        IN  DATE
                       ,p_po_line_id       IN  NUMBER
                       ,p_header_id        IN  NUMBER
                        )
IS
SELECT *
FROM   po_line_locations_all PLL
WHERE  PLL.po_header_id  = p_header_id
AND    PLL.po_line_id    = p_po_line_id
AND    TRUNC(start_date) = TRUNC(p_copy_date);

-------------------------------------------------------------
--Cursor to fetch the record matching with the incoming record
-------------------------------------------------------------
CURSOR lcu_po_line_locns_update( p_header_id            IN  NUMBER
                                ,p_po_line_id           IN  NUMBER
                                ,p_real_effective_date  IN  DATE
                                )
IS
SELECT  PLL.*
FROM    po_line_locations_all PLL
WHERE   PLL.po_header_id  = p_header_id
AND     PLL.po_line_id    = p_po_line_id
AND     TRUNC(p_real_effective_date)
BETWEEN TRUNC(NVL(start_date,SYSDATE))
AND     NVL(end_date, SYSDATE+3650)
ORDER BY PLL.quantity;


-------------------------------------------------------------
--Cursor to find the SUM of Quantities of Same Effective Date
-------------------------------------------------------------
CURSOR lcu_qty_sum_same_eff_date( p_header_id            IN  NUMBER
                                 ,p_po_line_id           IN  NUMBER
                                 ,p_real_effective_date  IN  DATE
                                )
IS
SELECT  SUM(QUANTITY)
FROM    po_line_locations_all PLL
WHERE   PLL.po_header_id  = p_header_id
AND     PLL.po_line_id    = p_po_line_id
AND     TRUNC(start_date) = TRUNC(p_real_effective_date);
------------------------------------------------
--Cursor to fetch next line number for New Item
------------------------------------------------
CURSOR lcu_new_item_no(p_header_id IN NUMBER)
IS
SELECT MAX(line_num + 1)
FROM   po_lines_all PLL
WHERE  PLL.po_header_id = p_header_id;

BEGIN

    ln_line_num        := p_line_num;
    ln_po_line_id      := p_po_line_id;
    ln_po_line_type_id := p_po_line_type_id;
    ln_interface_header_id := p_interface_header_id;

    display_log('ln_line_id        '||ln_po_line_id);
    display_log('p_create_flag     '||p_create_flag);
    display_log('p_segment1        '||p_segment1 );
    display_log('p_header_id       '||p_header_id);
    display_log('p_currency_code   '||p_currency_code);
    display_log('p_agent_id        '||p_agent_id);
    display_log('p_supplier        '||p_supplier);
    display_log('p_vendor_site_id  '||p_vendor_site_id);
    display_log('p_organization_id '||p_organization_id);
    display_log('p_price_protection_flag '||p_price_protection_flag);
    display_log('Line details      '|| p_line_num||'='||p_po_line_id||'='||p_po_line_type_id);
    display_log('p_real_effective_date '||p_real_effective_date);

    ---------------------------
    -- Clear the table type data
    ---------------------------
    g_qty_price_tbl.DELETE;
    g_qty_price_tbl(1).price    :=  0;
    g_qty_price_tbl(2).price    :=  p_unit_cost;
    g_qty_price_tbl(3).price    :=  p_tier1_cost;
    g_qty_price_tbl(4).price    :=  p_tier2_cost;
    g_qty_price_tbl(5).price    :=  p_tier3_cost;
    g_qty_price_tbl(6).price    :=  p_tier4_cost;
    g_qty_price_tbl(7).price    :=  p_tier5_cost;
    g_qty_price_tbl(8).price    :=  p_tier6_cost;

    g_qty_price_tbl(1).quantity :=  NULL;
    g_qty_price_tbl(2).quantity :=  1;
    g_qty_price_tbl(3).quantity :=  p_tier1_qty;
    g_qty_price_tbl(4).quantity :=  p_tier2_qty;
    g_qty_price_tbl(5).quantity :=  p_tier3_qty;
    g_qty_price_tbl(6).quantity :=  p_tier4_qty;
    g_qty_price_tbl(7).quantity :=  p_tier5_qty;
    g_qty_price_tbl(8).quantity :=  p_tier6_qty;


    --Summing up the Quantities to be used for Same Eff Date case including the Unit Quantity

    ln_total_quantity :=    NVL(g_qty_price_tbl(2).quantity,0)
                         +  NVL(g_qty_price_tbl(3).quantity,0)
                         +  NVL(g_qty_price_tbl(4).quantity,0)
                         +  NVL(g_qty_price_tbl(5).quantity,0)
                         +  NVL(g_qty_price_tbl(6).quantity,0)
                         +  NVL(g_qty_price_tbl(7).quantity,0)
                         +  NVL(g_qty_price_tbl(8).quantity,0);
    ------------------------------------------------
    --This part handles creation of a new quotation.
    ------------------------------------------------

    IF p_create_flag ='ORIGINAL'  THEN

         --
         -- Insert all the eligibile records into PO Headers interface table
         --
           display_log('In To Insert Fresh Quot....');
           display_log('p_currency_code    '||p_currency_code);
           display_log('p_agent_id         '||p_agent_id);
           display_log('p_supplier         '||p_supplier);
           display_log('p_vendor_site_id   '||p_vendor_site_id);
           display_log('p_organization_id  '||p_organization_id);
           display_log('p_price_protection_flag '||p_price_protection_flag);

 
         -- SELECT  PO_HEADERS_INTERFACE_S.nextval
         -- INTO    ln_interface_header_id FROM DUAL;

          ln_indx_header_count:=ln_indx_header_count+1;

          lt_po_headers(ln_indx_header_count).interface_header_id   := ln_interface_header_id;
          lt_po_headers(ln_indx_header_count).interface_source_code := 'I1078-'||p_control_id;
          lt_po_headers(ln_indx_header_count).process_code          := 'PENDING';
          lt_po_headers(ln_indx_header_count).BATCH_ID              := G_BATCH_ID;
          lt_po_headers(ln_indx_header_count).ACTION                := 'ORIGINAL';
          lt_po_headers(ln_indx_header_count).DOCUMENT_TYPE_CODE    := 'QUOTATION';
          lt_po_headers(ln_indx_header_count).DOCUMENT_SUBTYPE      := 'CATALOG';
          lt_po_headers(ln_indx_header_count).CURRENCY_CODE         := p_currency_code;
          lt_po_headers(ln_indx_header_count).AGENT_ID              := p_agent_id;
          lt_po_headers(ln_indx_header_count).VENDOR_ID             := p_supplier;
          lt_po_headers(ln_indx_header_count).VENDOR_SITE_ID        := p_vendor_site_id;
          lt_po_headers(ln_indx_header_count).ORG_ID                := p_organization_id;
          lt_po_headers(ln_indx_header_count).QUOTE_WARNING_DELAY   := 0;
          lt_po_headers(ln_indx_header_count).ATTRIBUTE_CATEGORY    := 'Trade Quotation';
          lt_po_headers(ln_indx_header_count).CREATION_DATE         := NVL(p_creation_date,SYSDATE);
          lt_po_headers(ln_indx_header_count).CREATED_BY            := NVL(p_created_by,G_USER_ID);
          lt_po_headers(ln_indx_header_count).LAST_UPDATE_DATE      := NVL(p_last_update_date,SYSDATE);
          lt_po_headers(ln_indx_header_count).LAST_UPDATED_BY       := NVL(p_last_updated_by,G_USER_ID);

          display_log('interface_header_id);'||lt_po_headers(ln_indx_header_count).interface_header_id);
          display_log('interface_source_code'||lt_po_headers(ln_indx_header_count).interface_source_code);
          display_log('process_code         '||lt_po_headers(ln_indx_header_count).process_code         );
          display_log('BATCH_ID             '||lt_po_headers(ln_indx_header_count).BATCH_ID             );
          display_log('ACTION               '||lt_po_headers(ln_indx_header_count).ACTION               );
          display_log('DOCUMENT_TYPE_CODE   '||lt_po_headers(ln_indx_header_count).DOCUMENT_TYPE_CODE   );
          display_log('DOCUMENT_SUBTYPE     '||lt_po_headers(ln_indx_header_count).DOCUMENT_SUBTYPE     );
          display_log('CURRENCY_CODE        '||lt_po_headers(ln_indx_header_count).CURRENCY_CODE        );
          display_log('AGENT_ID             '||lt_po_headers(ln_indx_header_count).AGENT_ID             );
          display_log('VENDOR_ID            '||lt_po_headers(ln_indx_header_count).VENDOR_ID            );
          display_log('VENDOR_SITE_ID       '||lt_po_headers(ln_indx_header_count).VENDOR_SITE_ID       );
          display_log('ORG_ID               '||lt_po_headers(ln_indx_header_count).ORG_ID               );
          display_log('QUOTE_WARNING_DELAY  '||lt_po_headers(ln_indx_header_count).QUOTE_WARNING_DELAY  );
          display_log('ATTRIBUTE_CATEGORY   '||lt_po_headers(ln_indx_header_count).ATTRIBUTE_CATEGORY   );
          display_log('CREATION_DATE        '||lt_po_headers(ln_indx_header_count).CREATION_DATE        );
          display_log('CREATED_BY           '||lt_po_headers(ln_indx_header_count).CREATED_BY           );
          display_log('LAST_UPDATE_DATE     '||lt_po_headers(ln_indx_header_count).LAST_UPDATE_DATE     );
          display_log('LAST_UPDATED_BY      '||lt_po_headers(ln_indx_header_count).LAST_UPDATED_BY      );
           --
           -- Insert all the eligibile records into PO Lines interface table
           --

          FOR no_of_price_breaks IN 1..8
          LOOP

               lc_insert_flag := 'N';

               IF no_of_price_breaks = 1 THEN

                  lc_insert_flag := 'Y';

               ELSIF  NVL(g_qty_price_tbl(no_of_price_breaks).quantity,0) <> 0  AND
                        NVL(g_qty_price_tbl(no_of_price_breaks).price ,0) <> 0 THEN
                   lc_insert_flag := 'Y';
               ELSE
                   lc_insert_flag := 'N';
               END IF;

               IF lc_insert_flag = 'Y' THEN

                  ln_indx_line_count := ln_indx_line_count + 1;
                  SELECT  PO_LINES_INTERFACE_S.nextval
                         ,DECODE(no_of_price_breaks,1,NULL,(no_of_price_breaks-1))
                  INTO    ln_interface_line_id
                         ,ln_shipment_num
                  FROM DUAL;

                  lt_po_lines(ln_indx_line_count).INTERFACE_LINE_ID             := ln_interface_line_id;
                  lt_po_lines(ln_indx_line_count).INTERFACE_HEADER_ID           := ln_interface_header_id;
                  lt_po_lines(ln_indx_line_count).ACTION                        :=  'ORIGINAL';
                  lt_po_lines(ln_indx_line_count).LINE_NUM                      :=  ln_line_num;
                  lt_po_lines(ln_indx_line_count).SHIPMENT_NUM                  :=  ln_shipment_num;
                  lt_po_lines(ln_indx_line_count).LINE_TYPE                     :=  'Goods';
                  lt_po_lines(ln_indx_line_count).ITEM                          :=  p_item;
                  lt_po_lines(ln_indx_line_count).ITEM_ID                       :=  p_inventory_item_id;
                  lt_po_lines(ln_indx_line_count).QUANTITY                      :=  g_qty_price_tbl(no_of_price_breaks).quantity;
                  lt_po_lines(ln_indx_line_count).UNIT_PRICE                    :=  g_qty_price_tbl(no_of_price_breaks).price;
                  lt_po_lines(ln_indx_line_count).SHIPMENT_TYPE                 :=  'QUOTATION';
                  lt_po_lines(ln_indx_line_count).LINE_ATTRIBUTE_CATEGORY_LINES :=  'Trade Quotation';
                  lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE6           :=  to_char(p_total_cost);
                  lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE7           :=  p_price_protection_flag;
                  lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE8           :=  p_active_date;
                  lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE_CATEGORY   := 'Trade Quotation';
                  lt_po_lines(ln_indx_line_count).UNIT_OF_MEASURE               :=  p_uom;
                  lt_po_lines(ln_indx_line_count).EFFECTIVE_DATE                :=  p_real_effective_date;
                  lt_po_lines(ln_indx_line_count).CREATION_DATE                 :=  p_creation_date;
                  lt_po_lines(ln_indx_line_count).CREATED_BY                    :=  p_created_by;
                  lt_po_lines(ln_indx_line_count).LAST_UPDATE_DATE              :=  p_last_update_date;
                  lt_po_lines(ln_indx_line_count).LAST_UPDATED_BY               :=  p_last_updated_by;

               END IF;

          END LOOP;
    END IF; --END IF for p_create_flag ='ORIGINAL'


    IF  p_create_flag='UPDATE_DIFF_EFF_DATE' OR p_create_flag='UPDATE_SAME_EFF_DATE' THEN

        OPEN   lcu_po_line_locns_update(p_header_id,ln_po_line_id,p_real_effective_date );
        FETCH lcu_po_line_locns_update BULK COLLECT INTO g_po_line_locns_update_tbl;

              IF g_po_line_locns_update_tbl.COUNT = 0 THEN
              log_procedure(  p_program_name           => 'insert_into_po_interface'
                             ,p_error_location         => 'NO_DATA_FOUND'
                             ,p_error_message_code     =>  SQLCODE
                             ,p_error_message          =>  'The Record which needs to be updated not found'
                             ,p_error_message_severity =>  'MAJOR'
                             ,p_notify_flag            =>  'Y'
                             ,p_object_id              =>  NULL
                             ,p_attribute1             =>  NULL
                            );
              END IF;
        CLOSE lcu_po_line_locns_update;

    END IF;--p_create_flag='UPDATE_DIFF_EFF_DATE' OR p_create_flag='UPDATE_SAME_EFF_DATE' THEN

       --Validating the Currency of the Incoming Record

       IF  p_create_flag='UPDATE_DIFF_EFF_DATE' OR
           p_create_flag='UPDATE_SAME_EFF_DATE' OR
           p_create_flag='NEW_ITEM'             OR
           p_create_flag='DELETE' THEN
         BEGIN
             IF G_CURRENCY_CODE = p_currency_code THEN
                lc_currency_match := 'Y';
             ELSE
                lc_currency_match :='N';

                fnd_message.set_name('XXPTP','XX_PO_600011_CURRENCY_MISMATCH');
                lc_curr_mis_mtch_err_msg := SUBSTR(fnd_message.get,1,240);

                --Update the staging table as errored as no matching record for creating a copy was found
                UPDATE xx_po_price_from_rms_stg
                SET    error_code        = 'XX_PO_600011_CURRENCY_MISMATCH'
                      ,error_message     = lc_curr_mis_mtch_err_msg
                      ,status            = 2
                      ,last_update_date  = SYSDATE
                      ,last_updated_by   = G_USER_ID
                      ,last_update_login = fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
                WHERE  control_id        = p_control_id;
                COMMIT;

                --Adding error message to stack
                log_procedure(  p_program_name           => 'insert_into_po_interface'
                               ,p_error_location         => 'CURRENCY_MISMATCH'
                               ,p_error_message_code     =>  SQLCODE
                               ,p_error_message          =>  lc_curr_mis_mtch_err_msg
                               ,p_error_message_severity =>  'MAJOR'
                               ,p_notify_flag            =>  'Y'
                               ,p_object_id              =>  NULL
                               ,p_attribute1             =>  NULL
                              );
              END IF;

         EXCEPTION
          WHEN OTHERS THEN
             display_log('When Others Exception in  display_errors SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);
             lc_currency_match :='N';
         END;

       END IF;--End If After Validating the Currency.

     --------------------------------------------------------------------------------
     --This  handles for the case if the record is coming in with Same Effective Date
     -- as the one which is already open price needs to be updated in this case
     --------------------------------------------------------------------------------

     --For Same Eff Date,Quantity Check ln_total_quantity

     IF p_create_flag='UPDATE_SAME_EFF_DATE' AND lc_currency_match = 'Y' THEN

         display_log('In For UPDATE_SAME_EFF_DATE ');
         display_log('p_segment1        '||p_segment1);
         display_log('p_header_id       '||p_header_id);
         display_log('p_price_protection_flag '||p_price_protection_flag);
         display_log('p_currency_code   ' ||p_currency_code);
         display_log('p_agent_id        '||p_agent_id);
         display_log('p_supplier        '||p_supplier);
         display_log('p_vendor_site_id  '||p_vendor_site_id);
         display_log('p_organization_id '||p_organization_id);

         IF g_po_line_locns_update_tbl.COUNT > 0 THEN

            OPEN  lcu_qty_sum_same_eff_date(p_header_id,ln_po_line_id,p_real_effective_date );
            FETCH lcu_qty_sum_same_eff_date INTO ln_existing_sum_quantity;
                 IF lcu_qty_sum_same_eff_date%NOTFOUND THEN
                 log_procedure(   p_program_name           => 'insert_into_po_interface'
                                 ,p_error_location         => 'NO_DATA_FOUND'
                                 ,p_error_message_code     =>  SQLCODE
                                 ,p_error_message          =>  'The Sum of Quantities not found'
                                 ,p_error_message_severity =>  'MAJOR'
                                 ,p_notify_flag            =>  'Y'
                                 ,p_object_id              =>  NULL
                                 ,p_attribute1             =>  NULL
                                );
                  END IF;
            CLOSE lcu_qty_sum_same_eff_date;


            display_log('ln_existing_sum_quantity final  '||ln_existing_sum_quantity);
            display_log('ln_total_quantity               '||ln_total_quantity);

            IF ln_existing_sum_quantity =  ln_total_quantity THEN

                ln_indx_update_price := 2;--The value of price is stored in g_qty_price_tbl.price from index 2

                ---------------------------------------------------------
                --Call pre_process which retains already existing records
                -- and also makes insert in headers interface
                ---------------------------------------------------------
                pre_process ( p_control_id          => p_control_id
                             ,p_header_id           => p_header_id
                             ,p_real_effective_date => p_real_effective_date
                             ,p_line_id             => ln_po_line_id
                             ,p_line_num            => ln_line_num
                             ,p_line_type_id        => ln_line_type_id
                             ,p_start_date          => NULL
                             ,x_next_shipment_num   => ln_next_shipment_num
                             ,x_interface_header_id => ln_interface_header_id
                              );
                 FOR indx_update_price_retain in g_po_line_locns_update_tbl.FIRST..g_po_line_locns_update_tbl.LAST
                 LOOP

                    ln_indx_line_count:= ln_indx_line_count + 1;

                    SELECT   PO_LINES_INTERFACE_S.nextval
                    INTO    ln_interface_line_id FROM DUAL;

                    lt_po_lines(ln_indx_line_count).INTERFACE_LINE_ID             :=  ln_interface_line_id;
                    lt_po_lines(ln_indx_line_count).INTERFACE_HEADER_ID           :=  ln_interface_header_id;
                    lt_po_lines(ln_indx_line_count).ACTION                        :=  'UPDATE';
                    lt_po_lines(ln_indx_line_count).LINE_NUM                      :=  ln_line_num;
                    lt_po_lines(ln_indx_line_count).SHIPMENT_NUM                  :=  ln_next_shipment_num;
                    lt_po_lines(ln_indx_line_count).LINE_TYPE                     :=  'Goods';
                    lt_po_lines(ln_indx_line_count).ITEM                          :=  p_item;
                    lt_po_lines(ln_indx_line_count).ITEM_ID                       :=  p_inventory_item_id;
                    lt_po_lines(ln_indx_line_count).QUANTITY                      :=  g_qty_price_tbl(ln_indx_update_price).quantity;--Updating Quantity
                    lt_po_lines(ln_indx_line_count).UNIT_PRICE                    :=  g_qty_price_tbl(ln_indx_update_price).price;--Updating the price
                    lt_po_lines(ln_indx_line_count).SHIPMENT_TYPE                 :=  'QUOTATION';
                    lt_po_lines(ln_indx_line_count).LINE_ATTRIBUTE_CATEGORY_LINES :=  'Trade Quotation';
                    lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE6           :=  to_char(p_total_cost);
                    lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE7           :=  p_price_protection_flag;
                    lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE8           :=  p_active_date;
                    lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE_CATEGORY   := 'Trade Quotation';
                    lt_po_lines(ln_indx_line_count).UNIT_OF_MEASURE               :=  g_po_line_locns_update_tbl(indx_update_price_retain).unit_meas_lookup_code;
                    lt_po_lines(ln_indx_line_count).PO_HEADER_ID                  :=  p_header_id;
                    lt_po_lines(ln_indx_line_count).PO_LINE_ID                    :=  ln_po_line_id;
                    lt_po_lines(ln_indx_line_count).LINE_TYPE_ID                  :=  ln_line_type_id;
                    lt_po_lines(ln_indx_line_count).DOCUMENT_NUM                  :=  p_segment1;
                    lt_po_lines(ln_indx_line_count).EFFECTIVE_DATE                :=  TRUNC(g_po_line_locns_update_tbl(indx_update_price_retain).start_date);
                    lt_po_lines(ln_indx_line_count).EXPIRATION_DATE               :=  TRUNC(g_po_line_locns_update_tbl(indx_update_price_retain).end_date);
                    lt_po_lines(ln_indx_line_count).CREATION_DATE                 :=  g_po_line_locns_update_tbl(indx_update_price_retain).CREATION_DATE ;
                    lt_po_lines(ln_indx_line_count).CREATED_BY                    :=  g_po_line_locns_update_tbl(indx_update_price_retain).CREATED_BY;
                    lt_po_lines(ln_indx_line_count).LAST_UPDATE_DATE              :=  SYSDATE;
                    lt_po_lines(ln_indx_line_count).LAST_UPDATED_BY               :=  G_USER_ID;
                    lt_po_lines(ln_indx_line_count).LAST_UPDATE_LOGIN             :=  G_USER_ID;

                    ln_next_shipment_num := ln_next_shipment_num + 1;
                    ln_indx_update_price := ln_indx_update_price + 1;
                 END LOOP;
                 display_log('Inserted Lines for change of cost for Same Eff Date');

            ELSE --If the Sum of Quantities do not match,then Error the Record

               fnd_message.set_name('XXPTP','XX_PO_60009_NO_MATCHING_QTY');
               lc_no_match_qty_err_msg := SUBSTR(fnd_message.get,1,240);

               --Upadte the staging table as errored as no matching record for creating a copy was found
               UPDATE xx_po_price_from_rms_stg
               SET    error_code        = 'XX_PO_60009_NO_MATCHING_QTY'
                     ,error_message     = lc_no_match_qty_err_msg
                     ,status            = 2
                     ,last_update_date  = SYSDATE
                     ,last_updated_by   = G_USER_ID
                     ,last_update_login = fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
               WHERE  control_id        = p_control_id;
               COMMIT;

               --Adding error message to stack
               log_procedure(  p_program_name           => 'insert_into_po_interface'
                              ,p_error_location         => 'NO_MATCHING_QUANTITY'
                              ,p_error_message_code     =>  SQLCODE
                              ,p_error_message          =>  lc_no_match_qty_err_msg
                              ,p_error_message_severity =>  'MAJOR'
                              ,p_notify_flag            =>  'Y'
                              ,p_object_id              =>  NULL
                              ,p_attribute1             =>  NULL
                 );

            END IF; -- Sum of Quantities

         END IF; --IF g_po_line_locns_update_tbl.COUNT > 0

     END IF;--IF p_create_flag='UPDATE_SAME_EFF_DATE'

     -----------------------------------------------------------------------------------------------------------
     --This  handles for the case if the record is coming in with Different Effective Date
     --ie.,end dates the existing price break with incoming record's start_date - 1 and creates new set of tiers
     -----------------------------------------------------------------------------------------------------------
     IF p_create_flag='UPDATE_DIFF_EFF_DATE' AND lc_currency_match = 'Y' THEN

         display_log('Inside UPDATE_DIFF_EFF_DATE ');
         display_log('p_segment1        '|| p_segment1 );
         display_log('p_header_id       '|| p_header_id);
         display_log('ln_po_line_id     '|| ln_po_line_id);
         display_log('p_currency_code   '||p_currency_code);
         display_log('p_agent_id        '||p_agent_id);
         display_log('p_supplier        '||p_supplier);
         display_log('p_vendor_site_id  '||p_vendor_site_id);
         display_log('p_organization_id '||p_organization_id);
         display_log('p_price_protection_flag '||p_price_protection_flag);
         display_log('p_real_effective_date   '||p_real_effective_date);
         ---------------------------------------------------------
         --Call pre_process which retains already existing records
         -- and also makes insert in headers interface
         ---------------------------------------------------------
           pre_process ( p_control_id          => p_control_id
                        ,p_header_id           => p_header_id
                        ,p_real_effective_date => p_real_effective_date
                        ,p_line_id             => ln_po_line_id
                        ,p_line_num            => ln_line_num
                        ,p_line_type_id        => ln_line_type_id
                        ,p_start_date          => NULL
                        ,x_next_shipment_num   => ln_next_shipment_num
                        ,x_interface_header_id => ln_interface_header_id
                        );

          ---------------------------------------------------------------
          --Update for the existing lines's end date to incoming record's
          --eff_date - 1  and also makes insert in headers interface
          ---------------------------------------------------------------
          IF g_po_line_locns_update_tbl.COUNT > 0 THEN

              FOR indx_end_date_record in g_po_line_locns_update_tbl.FIRST..g_po_line_locns_update_tbl.LAST
              LOOP

                   ln_indx_line_count:=ln_indx_line_count+1;
                   SELECT   PO_LINES_INTERFACE_S.nextval
                   INTO     ln_interface_line_id FROM DUAL;

                   lt_po_lines(ln_indx_line_count).INTERFACE_LINE_ID                    :=  ln_interface_line_id;
                   lt_po_lines(ln_indx_line_count).INTERFACE_HEADER_ID                  :=  ln_interface_header_id;
                   lt_po_lines(ln_indx_line_count).ACTION                               :=  'UPDATE';
                   lt_po_lines(ln_indx_line_count).LINE_NUM                             :=  ln_line_num;
                   lt_po_lines(ln_indx_line_count).SHIPMENT_NUM                         :=  ln_next_shipment_num;
                   lt_po_lines(ln_indx_line_count).LINE_TYPE                            :=  'Goods';
                   lt_po_lines(ln_indx_line_count).ITEM                                 :=  p_item;
                   lt_po_lines(ln_indx_line_count).ITEM_ID                              :=  p_inventory_item_id;
                   lt_po_lines(ln_indx_line_count).QUANTITY                             :=  g_po_line_locns_update_tbl(indx_end_date_record).quantity;
                   lt_po_lines(ln_indx_line_count).UNIT_PRICE                           :=  g_po_line_locns_update_tbl(indx_end_date_record).price_override;
                   lt_po_lines(ln_indx_line_count).SHIPMENT_TYPE                        :=  'QUOTATION';
                   lt_po_lines(ln_indx_line_count).LINE_ATTRIBUTE_CATEGORY_LINES        :=  'Trade Quotation';
                   lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE6                  :=  g_po_line_locns_update_tbl(indx_end_date_record).attribute6;
                   lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE7                  :=  g_po_line_locns_update_tbl(indx_end_date_record).attribute7;
                   lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE8                  :=  g_po_line_locns_update_tbl(indx_end_date_record).attribute8;
                   lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE_CATEGORY          :=  'Trade Quotation';
                   lt_po_lines(ln_indx_line_count).UNIT_OF_MEASURE                      :=  g_po_line_locns_update_tbl(indx_end_date_record).unit_meas_lookup_code;
                   lt_po_lines(ln_indx_line_count).CREATION_DATE                        :=  g_po_line_locns_update_tbl(indx_end_date_record).creation_date;
                   lt_po_lines(ln_indx_line_count).CREATED_BY                           :=  g_po_line_locns_update_tbl(indx_end_date_record).created_by;
                   lt_po_lines(ln_indx_line_count).LAST_UPDATE_DATE                     :=  p_last_update_date ;
                   lt_po_lines(ln_indx_line_count).LAST_UPDATED_BY                      :=  G_USER_ID ;
                   lt_po_lines(ln_indx_line_count).LAST_UPDATE_LOGIN                    :=  G_USER_ID;
                   lt_po_lines(ln_indx_line_count).PO_HEADER_ID                         :=  p_header_id;
                   lt_po_lines(ln_indx_line_count).PO_LINE_ID                           :=  ln_po_line_id;
                   lt_po_lines(ln_indx_line_count).LINE_TYPE_ID                         :=  ln_line_type_id;
                   lt_po_lines(ln_indx_line_count).DOCUMENT_NUM                         :=  p_segment1;
                   lt_po_lines(ln_indx_line_count).EFFECTIVE_DATE                       :=  TRUNC(g_po_line_locns_update_tbl(indx_end_date_record).start_date);
                   lt_po_lines(ln_indx_line_count).EXPIRATION_DATE                      :=  TRUNC(TO_DATE(p_real_effective_date - 1));

                   ln_next_shipment_num  := ln_next_shipment_num + 1;

              END LOOP;


          END IF; --IF g_po_line_locns_update_tbl.COUNT > 0 THEN
            ---------------------------------------------------------------------------
            --Creating the new set of price breaks which has come in different eff date
            ---------------------------------------------------------------------------
              FOR no_of_price_breaks IN 2..8
              LOOP

                  lc_insert_flag := 'N';

                  IF  NVL(g_qty_price_tbl(no_of_price_breaks).quantity,0) <> 0
                      AND NVL(g_qty_price_tbl(no_of_price_breaks).price ,0) <> 0 THEN

                      lc_insert_flag := 'Y';

                  END IF;

                  IF lc_insert_flag = 'Y' THEN

                     ln_indx_line_count :=ln_indx_line_count+1;
                     SELECT   PO_LINES_INTERFACE_S.nextval
                     INTO    ln_interface_line_id FROM DUAL
                     ;
                     lt_po_lines(ln_indx_line_count).INTERFACE_LINE_ID                := ln_interface_line_id ;
                     lt_po_lines(ln_indx_line_count).INTERFACE_HEADER_ID              := ln_interface_header_id;
                     lt_po_lines(ln_indx_line_count).ACTION                           := 'ORIGINAL';
                     lt_po_lines(ln_indx_line_count).LINE_NUM                         := ln_line_num;
                     lt_po_lines(ln_indx_line_count).SHIPMENT_NUM                     := ln_next_shipment_num ;
                     lt_po_lines(ln_indx_line_count).LINE_TYPE                        := 'Goods';
                     lt_po_lines(ln_indx_line_count).ITEM                             := p_item;
                     lt_po_lines(ln_indx_line_count).ITEM_ID                          := p_inventory_item_id ;
                     lt_po_lines(ln_indx_line_count).QUANTITY                         := g_qty_price_tbl(no_of_price_breaks).quantity;
                     lt_po_lines(ln_indx_line_count).UNIT_PRICE                       := g_qty_price_tbl(no_of_price_breaks).price;
                     lt_po_lines(ln_indx_line_count).SHIPMENT_TYPE                    := 'QUOTATION';
                     lt_po_lines(ln_indx_line_count).LINE_ATTRIBUTE_CATEGORY_LINES    := 'Trade Quotation';
                     lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE6              := to_char(p_total_cost);
                     lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE7              := p_price_protection_flag;
                     lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE8              := p_active_date;
                     lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE_CATEGORY      := 'Trade Quotation';
                     lt_po_lines(ln_indx_line_count).UNIT_OF_MEASURE                  := p_uom;
                     lt_po_lines(ln_indx_line_count).DOCUMENT_NUM                     := p_segment1;
                     lt_po_lines(ln_indx_line_count).PO_HEADER_ID                     := p_header_id;
                     lt_po_lines(ln_indx_line_count).PO_LINE_ID                       :=  ln_po_line_id;
                     lt_po_lines(ln_indx_line_count).LINE_TYPE_ID                     := ln_line_type_id;
                     lt_po_lines(ln_indx_line_count).CREATION_DATE                    := SYSDATE;
                     lt_po_lines(ln_indx_line_count).CREATED_BY                       := G_USER_ID;
                     lt_po_lines(ln_indx_line_count).LAST_UPDATE_DATE                 := SYSDATE;
                     lt_po_lines(ln_indx_line_count).LAST_UPDATED_BY                  := G_USER_ID;
                     lt_po_lines(ln_indx_line_count).LAST_UPDATE_LOGIN                := G_USER_ID;
                     lt_po_lines(ln_indx_line_count).EFFECTIVE_DATE                   := p_real_effective_date;
                     lt_po_lines(ln_indx_line_count).EXPIRATION_DATE                  := p_end_date;

                     ln_next_shipment_num := ln_next_shipment_num + 1;

                  END IF;

              END LOOP;

     END IF; --End IF for p_create_flag='UPDATE_DIFF_EFF_DATE'

     ----------------------------------------------------------------
     --This is for creating a new item in the same existing quotation
     ----------------------------------------------------------------
     IF p_create_flag='NEW_ITEM' AND lc_currency_match = 'Y' THEN
          display_log( 'In for New Item Creation');
          --This is to fetch next line number in case of new item
          OPEN  lcu_new_item_no(p_header_id);
          FETCH lcu_new_item_no INTO ln_new_item_line_num;

              IF lcu_new_item_no%NOTFOUND THEN
              log_procedure(  p_program_name           => 'insert_into_po_interface'
                             ,p_error_location         => 'NO_DATA_FOUND'
                             ,p_error_message_code     =>  SQLCODE
                             ,p_error_message          =>  'The line number for new item was not found'
                             ,p_error_message_severity =>  'MAJOR'
                             ,p_notify_flag            =>  'Y'
                             ,p_object_id              =>  NULL
                             ,p_attribute1             =>  NULL
                            );
              END IF;
          CLOSE lcu_new_item_no;

          display_log('ln_new_item_line_num has been selected '||ln_new_item_line_num);


          --SELECT  PO_HEADERS_INTERFACE_S.nextval
          --INTO    ln_interface_header_id FROM DUAL;

          display_log( 'Before Headers for the New Item');

          ln_indx_header_count:=ln_indx_header_count+1;

          lt_po_headers(ln_indx_header_count).INTERFACE_HEADER_ID     := ln_interface_header_id;
          lt_po_headers(ln_indx_header_count).DOCUMENT_NUM            := p_segment1;
          lt_po_headers(ln_indx_header_count).INTERFACE_SOURCE_CODE   := 'I1078-'||p_control_id;
          lt_po_headers(ln_indx_header_count).PROCESS_CODE            := 'PENDING';
          lt_po_headers(ln_indx_header_count).BATCH_ID                :=  G_BATCH_ID;
          lt_po_headers(ln_indx_header_count).ACTION                  := 'UPDATE';
          lt_po_headers(ln_indx_header_count).DOCUMENT_TYPE_CODE      := 'QUOTATION';
          lt_po_headers(ln_indx_header_count).DOCUMENT_SUBTYPE        := 'CATALOG';
          lt_po_headers(ln_indx_header_count).CURRENCY_CODE           := p_currency_code;
          lt_po_headers(ln_indx_header_count).AGENT_ID                := p_agent_id;
          lt_po_headers(ln_indx_header_count).VENDOR_ID               := p_supplier;
          lt_po_headers(ln_indx_header_count).VENDOR_SITE_ID          := p_vendor_site_id;
          lt_po_headers(ln_indx_header_count).ORG_ID                  := p_organization_id;
          lt_po_headers(ln_indx_header_count).QUOTE_WARNING_DELAY     := 0;
          lt_po_headers(ln_indx_header_count).ATTRIBUTE_CATEGORY      := 'Trade Quotation';
          lt_po_headers(ln_indx_header_count).PO_HEADER_ID            := p_header_id;
          lt_po_headers(ln_indx_header_count).CREATION_DATE           := NVL(p_creation_date,SYSDATE);
          lt_po_headers(ln_indx_header_count).CREATED_BY              := NVL(p_created_by,G_USER_ID);
          lt_po_headers(ln_indx_header_count).LAST_UPDATE_DATE        := NVL(p_last_update_date,SYSDATE);
          lt_po_headers(ln_indx_header_count).LAST_UPDATED_BY         := NVL(p_last_updated_by,G_USER_ID);

          display_log('interface_header_id) '||lt_po_headers(ln_indx_header_count).interface_header_id);
          display_log('interface_source_code'||lt_po_headers(ln_indx_header_count).interface_source_code);
          display_log('process_code         '||lt_po_headers(ln_indx_header_count).process_code         );
          display_log('BATCH_ID             '||lt_po_headers(ln_indx_header_count).BATCH_ID             );
          display_log('ACTION               '||lt_po_headers(ln_indx_header_count).ACTION               );
          display_log('DOCUMENT_TYPE_CODE   '||lt_po_headers(ln_indx_header_count).DOCUMENT_TYPE_CODE   );
          display_log('DOCUMENT_SUBTYPE     '||lt_po_headers(ln_indx_header_count).DOCUMENT_SUBTYPE     );
          display_log('CURRENCY_CODE        '||lt_po_headers(ln_indx_header_count).CURRENCY_CODE        );
          display_log('AGENT_ID             '||lt_po_headers(ln_indx_header_count).AGENT_ID             );
          display_log('VENDOR_ID            '||lt_po_headers(ln_indx_header_count).VENDOR_ID            );
          display_log('VENDOR_SITE_ID       '||lt_po_headers(ln_indx_header_count).VENDOR_SITE_ID       );
          display_log('ORG_ID               '||lt_po_headers(ln_indx_header_count).ORG_ID               );
          display_log('QUOTE_WARNING_DELAY  '||lt_po_headers(ln_indx_header_count).QUOTE_WARNING_DELAY  );
          display_log('ATTRIBUTE_CATEGORY   '||lt_po_headers(ln_indx_header_count).ATTRIBUTE_CATEGORY   );
          display_log('CREATION_DATE        '||lt_po_headers(ln_indx_header_count).CREATION_DATE        );
          display_log('CREATED_BY           '||lt_po_headers(ln_indx_header_count).CREATED_BY           );
          display_log('LAST_UPDATE_DATE     '||lt_po_headers(ln_indx_header_count).LAST_UPDATE_DATE     );
          display_log('LAST_UPDATED_BY      '||lt_po_headers(ln_indx_header_count).LAST_UPDATED_BY      );
          display_log( 'Before Lines for the New Item...');

          FOR no_of_price_breaks IN 1..8
          LOOP
             lc_insert_flag := 'N';

             IF no_of_price_breaks = 1 THEN
                  lc_insert_flag := 'Y';
 
              ELSIF  NVL(g_qty_price_tbl(no_of_price_breaks).quantity ,0) <> 0  AND
                        NVL(g_qty_price_tbl(no_of_price_breaks).price ,0) <> 0  THEN
 
                  lc_insert_flag := 'Y';
              ELSE
                  lc_insert_flag := 'N';
              END IF;

             IF lc_insert_flag = 'Y' THEN
             ln_indx_line_count := ln_indx_line_count + 1;

             SELECT  PO_LINES_INTERFACE_S.nextval
                    ,DECODE(no_of_price_breaks,1,NULL,(no_of_price_breaks-1))
             INTO    ln_interface_line_id
                    ,ln_shipment_num
             FROM DUAL;

             lt_po_lines(ln_indx_line_count).INTERFACE_LINE_ID              := ln_interface_line_id;
             lt_po_lines(ln_indx_line_count).INTERFACE_HEADER_ID            := ln_interface_header_id;
             lt_po_lines(ln_indx_line_count).ACTION                         := 'ORIGINAL';
             lt_po_lines(ln_indx_line_count).LINE_NUM                       := ln_new_item_line_num ;
             lt_po_lines(ln_indx_line_count).SHIPMENT_NUM                   := ln_shipment_num;
             lt_po_lines(ln_indx_line_count).LINE_TYPE                      := 'Goods';
             lt_po_lines(ln_indx_line_count).ITEM                           := p_item ;
             lt_po_lines(ln_indx_line_count).ITEM_ID                        := p_inventory_item_id ;
             lt_po_lines(ln_indx_line_count).QUANTITY                       := g_qty_price_tbl(no_of_price_breaks).quantity;
             lt_po_lines(ln_indx_line_count).UNIT_PRICE                     := g_qty_price_tbl(no_of_price_breaks).price;
             lt_po_lines(ln_indx_line_count).SHIPMENT_TYPE                  := 'QUOTATION';
             lt_po_lines(ln_indx_line_count).LINE_ATTRIBUTE_CATEGORY_LINES  := 'Trade Quotation';
             lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE6            := to_char(p_total_cost);
             lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE7            := p_price_protection_flag;
             lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE8            := p_active_date;
             lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE_CATEGORY    := 'Trade Quotation';
             lt_po_lines(ln_indx_line_count).UNIT_OF_MEASURE                := p_uom ;
             lt_po_lines(ln_indx_line_count).CREATION_DATE                  := SYSDATE;
             lt_po_lines(ln_indx_line_count).CREATED_BY                     := G_USER_ID;
             lt_po_lines(ln_indx_line_count).LAST_UPDATE_DATE               := SYSDATE;
             lt_po_lines(ln_indx_line_count).LAST_UPDATED_BY                := G_USER_ID;
             lt_po_lines(ln_indx_line_count).LAST_UPDATE_LOGIN              := G_USER_ID;
             lt_po_lines(ln_indx_line_count).PO_HEADER_ID                   := p_header_id;
             lt_po_lines(ln_indx_line_count).LINE_TYPE_ID                   := ln_line_type_id;
             lt_po_lines(ln_indx_line_count).DOCUMENT_NUM                   := p_segment1;
             lt_po_lines(ln_indx_line_count).EFFECTIVE_DATE                 := p_real_effective_date;

            END IF;

          END LOOP;

     END IF; --END IF for p_create_flag='NEW_ITEM'

     --If operation_code is delete then,end date the record identified for delete with it's own start_date
     IF p_create_flag = 'DELETE' AND lc_currency_match = 'Y' THEN

          display_log('Entered for Delete operation');

          OPEN  lcu_g_to_be_deleted(p_real_effective_date,ln_po_line_id,p_header_id);
          FETCH lcu_g_to_be_deleted  BULK COLLECT INTO lt_to_be_deleted_tbl;

              IF lt_to_be_deleted_tbl.COUNT = 0  THEN
                 display_log('No matching record');
                 lc_delete_record_found_flag := 'N';

                 --Upadte the staging table as errored as no matching record for deletion found
                 fnd_message.set_name('XXPTP','XX_PO_60005_NO_DELETED_RECORD');
                 lc_no_del_rec_err_msg := SUBSTR(fnd_message.get,1,240);
 
                 UPDATE xx_po_price_from_rms_stg
                 SET error_code        = 'XX_PO_60005_NO_DELETED_RECORD'
                    ,error_message     = lc_no_del_rec_err_msg
                    ,status            = 2
                    ,last_update_date  = SYSDATE
                    ,last_updated_by   = G_USER_ID
                    ,last_update_login = fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
                 WHERE   control_id    = p_control_id;
                 COMMIT;

                 --Adding error message to stack
                 log_procedure(  p_program_name           => 'insert_into_po_interface'
                                ,p_error_location         => 'NO_DATA_FOUND'
                                ,p_error_message_code     =>  SQLCODE
                                ,p_error_message          =>  lc_no_del_rec_err_msg
                                ,p_error_message_severity => 'MAJOR'
                                ,p_notify_flag            => 'Y'
                                ,p_object_id              =>  NULL
                                ,p_attribute1             =>  NULL
                               );

                 --x_retcode := 1;
              ELSE
                lc_delete_record_found_flag := 'Y';
                display_log('Matching for the record to be deleted is found');

              END IF;

          CLOSE lcu_g_to_be_deleted;

     IF lc_delete_record_found_flag = 'Y'   THEN

         BEGIN
            display_log('After Finding record for delete');

            --Finding the Immediate prior Price Break whose end-date would be made NULL
            OPEN  lcu_already_deleted (p_real_effective_date ,ln_po_line_id,p_header_id );
            FETCH lcu_already_deleted INTO ld_copy_date;
            CLOSE lcu_already_deleted;

            OPEN  lcu_create_copy (ld_copy_date ,ln_po_line_id,p_header_id);
            FETCH lcu_create_copy BULK COLLECT INTO lt_create_copy;

              IF lt_create_copy.COUNT = 0 THEN

                   fnd_message.set_name('XXPTP','XX_PO_60006_NO_PRIOR_RECORD');
                   lc_no_prior_rec_err_msg := SUBSTR(fnd_message.get,1,240);

                   --Upadte the staging table as errored as no matching record for creating a copy was found
                   UPDATE xx_po_price_from_rms_stg
                   SET    error_code       = 'XX_PO_60006_NO_PRIOR_RECORD'
                         ,error_message    = lc_no_prior_rec_err_msg
                         ,status           = 2
                         ,last_update_date = SYSDATE
                         ,last_updated_by  = G_USER_ID
                         ,last_update_login = fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
                   WHERE  control_id       = p_control_id;

                   --Adding error message to stack
                   log_procedure(  p_program_name           => 'insert_into_po_interface'
                                  ,p_error_location         => 'NO_DATA_FOUND'
                                  ,p_error_message_code     =>  SQLCODE
                                  ,p_error_message          =>  lc_no_prior_rec_err_msg
                                  ,p_error_message_severity =>  'MAJOR'
                                  ,p_notify_flag            =>  'Y'
                                  ,p_object_id              =>  NULL
                                  ,p_attribute1             =>  NULL
                                 );
                   --x_retcode := 1;
                 END IF;

            CLOSE lcu_create_copy;


           IF lt_create_copy.count > 0 THEN --If no matching record whose copy is to be created is not found,then,stop here

                IF lt_to_be_deleted_tbl.COUNT > 0 THEN

                     display_log('before if lt_to_be_deleted_tbl.COUNT= '||lt_to_be_deleted_tbl.COUNT);

                      pre_process ( p_control_id          => p_control_id
                                   ,p_header_id           => p_header_id
                                   ,p_real_effective_date => p_real_effective_date
                                   ,p_line_id             => ln_po_line_id
                                   ,p_line_num            => ln_line_num
                                   ,p_line_type_id        => ln_line_type_id
                                   ,p_start_date          => lt_create_copy(1).start_date
                                   ,x_next_shipment_num   => ln_next_shipment_num
                                   ,x_interface_header_id => ln_interface_header_id
                                    );

                      display_log('ln_next_shipment_num After Pre-Processing is '||ln_next_shipment_num );

                      FOR  indx_to_be_deleted IN lt_to_be_deleted_tbl.FIRST..lt_to_be_deleted_tbl.LAST
                      LOOP
                          ln_indx_line_count := ln_indx_line_count + 1;

                          SELECT  PO_LINES_INTERFACE_S.nextval
                          INTO    ln_interface_line_id FROM DUAL;

                          lt_po_lines(ln_indx_line_count).INTERFACE_LINE_ID                   := ln_interface_line_id;
                          lt_po_lines(ln_indx_line_count).INTERFACE_HEADER_ID                 := ln_interface_header_id;
                          lt_po_lines(ln_indx_line_count).ACTION                              := 'UPDATE';
                          lt_po_lines(ln_indx_line_count).LINE_NUM                            := ln_line_num;
                          lt_po_lines(ln_indx_line_count).SHIPMENT_NUM                        := ln_next_shipment_num;
                          lt_po_lines(ln_indx_line_count).LINE_TYPE                           := 'Goods';
                          lt_po_lines(ln_indx_line_count).DOCUMENT_NUM                        := p_segment1;
                          lt_po_lines(ln_indx_line_count).ITEM                                := p_item;
                          lt_po_lines(ln_indx_line_count).ITEM_ID                             := p_inventory_item_id;
                          lt_po_lines(ln_indx_line_count).QUANTITY                            := lt_to_be_deleted_tbl(indx_to_be_deleted).quantity;
                          lt_po_lines(ln_indx_line_count).UNIT_PRICE                          := lt_to_be_deleted_tbl(indx_to_be_deleted).price_override;
                          lt_po_lines(ln_indx_line_count).SHIPMENT_TYPE                       := 'QUOTATION';
                          lt_po_lines(ln_indx_line_count).LINE_ATTRIBUTE_CATEGORY_LINES       := 'Trade Quotation';
                          lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE6                 := lt_to_be_deleted_tbl(indx_to_be_deleted).attribute6;
                          lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE7                 := lt_to_be_deleted_tbl(indx_to_be_deleted).attribute7;
                          lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE8                 := lt_to_be_deleted_tbl(indx_to_be_deleted).attribute8;
                          lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE_CATEGORY         := 'Trade Quotation';
                          lt_po_lines(ln_indx_line_count).UNIT_OF_MEASURE                     := lt_to_be_deleted_tbl(indx_to_be_deleted).unit_meas_lookup_code;
                          lt_po_lines(ln_indx_line_count).CREATION_DATE                       := lt_to_be_deleted_tbl(indx_to_be_deleted).creation_date;
                          lt_po_lines(ln_indx_line_count).CREATED_BY                          := lt_to_be_deleted_tbl(indx_to_be_deleted).created_by;
                          lt_po_lines(ln_indx_line_count).LAST_UPDATE_DATE                    := SYSDATE;
                          lt_po_lines(ln_indx_line_count).LAST_UPDATED_BY                     := G_USER_ID;
                          lt_po_lines(ln_indx_line_count).LAST_UPDATE_LOGIN                   := G_USER_ID;
                          lt_po_lines(ln_indx_line_count).LINE_TYPE_ID                        := ln_line_type_id;
                          lt_po_lines(ln_indx_line_count).EFFECTIVE_DATE                      := TRUNC(lt_to_be_deleted_tbl(indx_to_be_deleted).start_date);
                          lt_po_lines(ln_indx_line_count).EXPIRATION_DATE                     := TRUNC(lt_to_be_deleted_tbl(indx_to_be_deleted).start_date);

                          ln_next_shipment_num := ln_next_shipment_num + 1;

                      END LOOP;

                   END IF; --IF lt_to_be_deleted_tbl.COUNT > 0

                   --IF lt_create_copy.count > 0 THEN --Else Update error in staging as delete record not found
                    FOR indx_create_copy IN lt_create_copy.FIRST..lt_create_copy.LAST
                    LOOP

                       ln_indx_line_count := ln_indx_line_count + 1;

                       SELECT  PO_LINES_INTERFACE_S.nextval
                       INTO    ln_interface_line_id FROM DUAL;

                       lt_po_lines(ln_indx_line_count).INTERFACE_LINE_ID                := ln_interface_line_id;
                       lt_po_lines(ln_indx_line_count).INTERFACE_HEADER_ID              := ln_interface_header_id;
                       lt_po_lines(ln_indx_line_count).ACTION                           := 'ORIGINAL';
                       lt_po_lines(ln_indx_line_count).LINE_NUM                         := ln_line_num;
                       lt_po_lines(ln_indx_line_count).SHIPMENT_NUM                     := ln_next_shipment_num;
                       lt_po_lines(ln_indx_line_count).LINE_TYPE                        := 'Goods';
                       lt_po_lines(ln_indx_line_count).DOCUMENT_NUM                     := p_segment1;
                       lt_po_lines(ln_indx_line_count).ITEM                             := p_item;
                       lt_po_lines(ln_indx_line_count).ITEM_ID                          := p_inventory_item_id;
                       lt_po_lines(ln_indx_line_count).QUANTITY                         := lt_create_copy(indx_create_copy).quantity;
                       lt_po_lines(ln_indx_line_count).UNIT_PRICE                       := lt_create_copy(indx_create_copy).price_override;
                       lt_po_lines(ln_indx_line_count).SHIPMENT_TYPE                    := 'QUOTATION';
                       lt_po_lines(ln_indx_line_count).LINE_ATTRIBUTE_CATEGORY_LINES    := 'Trade Quotation' ;
                       lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE6              := to_char(p_total_cost);
                       lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE7              := p_price_protection_flag;
                       lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE8              := p_active_date ;
                       lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE_CATEGORY      := 'Trade Quotation' ;
                       lt_po_lines(ln_indx_line_count).UNIT_OF_MEASURE                  := p_uom;
                       lt_po_lines(ln_indx_line_count).CREATION_DATE                    := lt_create_copy(indx_create_copy).creation_date ;
                       lt_po_lines(ln_indx_line_count).CREATED_BY                       := lt_create_copy(indx_create_copy).created_by;
                       lt_po_lines(ln_indx_line_count).LAST_UPDATE_DATE                 := SYSDATE;
                       lt_po_lines(ln_indx_line_count).LAST_UPDATED_BY                  := G_USER_ID;
                       lt_po_lines(ln_indx_line_count).LAST_UPDATE_LOGIN                := G_USER_ID;
                       lt_po_lines(ln_indx_line_count).LINE_TYPE_ID                     := ln_line_type_id;
                       lt_po_lines(ln_indx_line_count).EFFECTIVE_DATE                   := TRUNC(lt_create_copy(indx_create_copy).start_date);
                       lt_po_lines(ln_indx_line_count).EXPIRATION_DATE                  := NULL;

                       ln_next_shipment_num := ln_next_shipment_num + 1;

                       END LOOP;

                END IF;--IF lt_create_copy.count > 0

       EXCEPTION
          WHEN OTHERS THEN
            log_procedure(  p_program_name           => 'insert_into_po_interface'
                           ,p_error_location         => 'WHEN OTHERS THEN of inserting into po_lines_interface for DELETE when making a copy of the deleted record'
                           ,p_error_message_code     =>  SQLCODE
                           ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                           ,p_error_message_severity =>  'MAJOR'
                           ,p_notify_flag            =>  'Y'
                           ,p_object_id              =>  NULL
                           ,p_attribute1             =>  NULL
                          );
            display_log('When OTHERS error For Delete Operation - '||SQLERRM);
            x_retcode := 2;
       END;

     END IF;--IF 'DELETE'

     END IF;--delete_record_found_flag = 'Y'

     display_log('lt_po_headers.first'||lt_po_headers.first);
     display_log('lt_po_headers.last '||lt_po_headers.last);
     display_log('lt_po_headers.count'||lt_po_headers.count);
     display_log('p_supplier_exists  '||p_supplier_exists);

     IF lt_po_headers.count > 0 THEN
          FOR ln_indx_header_count IN lt_po_headers.first..lt_po_headers.last
          LOOP
          BEGIN
              display_log('interface_header_id  '||lt_po_headers(ln_indx_header_count).INTERFACE_HEADER_ID  );
              display_log('interface_source_code'||lt_po_headers(ln_indx_header_count).INTERFACE_SOURCE_CODE);
              display_log('process_code         '||lt_po_headers(ln_indx_header_count).PROCESS_CODE         );
              display_log('BATCH_ID             '||lt_po_headers(ln_indx_header_count).BATCH_ID             );
              display_log('ACTION               '||lt_po_headers(ln_indx_header_count).ACTION               );
              display_log('DOCUMENT_TYPE_CODE   '||lt_po_headers(ln_indx_header_count).DOCUMENT_TYPE_CODE   );
              display_log('DOCUMENT_SUBTYPE     '||lt_po_headers(ln_indx_header_count).DOCUMENT_SUBTYPE     );
              display_log('CURRENCY_CODE        '||lt_po_headers(ln_indx_header_count).CURRENCY_CODE        );
              display_log('AGENT_ID             '||lt_po_headers(ln_indx_header_count).AGENT_ID             );
              display_log('VENDOR_ID            '||lt_po_headers(ln_indx_header_count).VENDOR_ID            );
              display_log('VENDOR_SITE_ID       '||lt_po_headers(ln_indx_header_count).VENDOR_SITE_ID       );
              display_log('ORG_ID               '||lt_po_headers(ln_indx_header_count).ORG_ID               );
              display_log('QUOTE_WARNING_DELAY  '||lt_po_headers(ln_indx_header_count).QUOTE_WARNING_DELAY  );
              display_log('ATTRIBUTE_CATEGORY   '||lt_po_headers(ln_indx_header_count).ATTRIBUTE_CATEGORY   );
              display_log('CREATION_DATE        '||lt_po_headers(ln_indx_header_count).CREATION_DATE        );
              display_log('CREATED_BY           '||lt_po_headers(ln_indx_header_count).CREATED_BY           );
              display_log('LAST_UPDATE_DATE     '||lt_po_headers(ln_indx_header_count).LAST_UPDATE_DATE     );
              display_log('LAST_UPDATED_BY      '||lt_po_headers(ln_indx_header_count).LAST_UPDATED_BY      );

       IF p_supplier_exists = 'Y' THEN
              INSERT INTO po_headers_interface
                           ( INTERFACE_HEADER_ID
                            ,INTERFACE_SOURCE_CODE
                            ,PROCESS_CODE
                            ,BATCH_ID
                            ,ACTION
                            ,REQUEST_ID
                            ,DOCUMENT_TYPE_CODE
                            ,DOCUMENT_SUBTYPE
                            ,CURRENCY_CODE
                            ,AGENT_ID
                            ,VENDOR_ID
                            ,VENDOR_SITE_ID
                            ,ORG_ID
                            ,QUOTE_WARNING_DELAY
                            ,ATTRIBUTE_CATEGORY
                            ,CREATION_DATE
                            ,CREATED_BY
                            ,LAST_UPDATE_DATE
                            ,LAST_UPDATED_BY
                            ,PO_HEADER_ID
                            ,DOCUMENT_NUM
                            ,ATTRIBUTE1
                           )
                           VALUES
                           (
                            lt_po_headers(ln_indx_header_count).INTERFACE_HEADER_ID
                           ,lt_po_headers(ln_indx_header_count).INTERFACE_SOURCE_CODE
                           ,lt_po_headers(ln_indx_header_count).PROCESS_CODE
                           ,lt_po_headers(ln_indx_header_count).BATCH_ID
                           ,lt_po_headers(ln_indx_header_count).ACTION
                           ,gn_master_request_id
                           ,lt_po_headers(ln_indx_header_count).DOCUMENT_TYPE_CODE
                           ,lt_po_headers(ln_indx_header_count).DOCUMENT_SUBTYPE
                           ,lt_po_headers(ln_indx_header_count).CURRENCY_CODE
                           ,lt_po_headers(ln_indx_header_count).AGENT_ID
                           ,lt_po_headers(ln_indx_header_count).VENDOR_ID
                           ,lt_po_headers(ln_indx_header_count).VENDOR_SITE_ID
                           ,lt_po_headers(ln_indx_header_count).ORG_ID
                           ,lt_po_headers(ln_indx_header_count).QUOTE_WARNING_DELAY
                           ,lt_po_headers(ln_indx_header_count).ATTRIBUTE_CATEGORY
                           ,lt_po_headers(ln_indx_header_count).CREATION_DATE
                           ,lt_po_headers(ln_indx_header_count).CREATED_BY
                           ,lt_po_headers(ln_indx_header_count).LAST_UPDATE_DATE
                           ,lt_po_headers(ln_indx_header_count).LAST_UPDATED_BY
                           ,lt_po_headers(ln_indx_header_count).PO_HEADER_ID
                           ,lt_po_headers(ln_indx_header_count).DOCUMENT_NUM
                           ,G_PO_SOURCE
                           );
         END IF; -- IF p_supplier_exists := 'Y' THEN
 
         EXCEPTION
            WHEN OTHERS THEN
             display_log('Unexpected errors when inserting in header loop '||SQLERRM);
         END;
       END LOOP;
     END IF;--lt_po_headers.count > 0

        display_log('lt_po_lines.first'||lt_po_lines.first);
        display_log('lt_po_lines.last' ||lt_po_lines.last);
        display_log('lt_po_lines.count'||lt_po_lines.count);

     IF lt_po_lines.COUNT > 0 THEN

         FOR ln_indx_line_count IN lt_po_lines.first..lt_po_lines.last
         LOOP
            BEGIN
               INSERT INTO po_lines_interface(
                                              INTERFACE_LINE_ID
                                             ,INTERFACE_HEADER_ID
                                             ,ACTION
                                             ,LINE_NUM
                                             ,SHIPMENT_NUM
                                             ,LINE_TYPE
                                             ,ITEM
                                             ,ITEM_ID
                                             ,QUANTITY
                                             ,UNIT_PRICE
                                             ,SHIPMENT_TYPE
                                             ,LINE_ATTRIBUTE_CATEGORY_LINES
                                             ,SHIPMENT_ATTRIBUTE6
                                             ,SHIPMENT_ATTRIBUTE7
                                             ,SHIPMENT_ATTRIBUTE8
                                             ,SHIPMENT_ATTRIBUTE_CATEGORY
                                             ,UNIT_OF_MEASURE
                                             ,DOCUMENT_NUM
                                             ,PO_HEADER_ID
                                             ,PO_LINE_ID
                                             ,LINE_TYPE_ID
                                             ,CREATION_DATE
                                             ,CREATED_BY
                                             ,LAST_UPDATE_DATE
                                             ,LAST_UPDATED_BY
                                             ,LAST_UPDATE_LOGIN
                                             ,EFFECTIVE_DATE
                                             ,EXPIRATION_DATE
                                              )
                                   VALUES
                                            (
                                             lt_po_lines(ln_indx_line_count).INTERFACE_LINE_ID
                                            ,lt_po_lines(ln_indx_line_count).INTERFACE_HEADER_ID
                                            ,lt_po_lines(ln_indx_line_count).ACTION
                                            ,lt_po_lines(ln_indx_line_count).LINE_NUM
                                            ,lt_po_lines(ln_indx_line_count).SHIPMENT_NUM
                                            ,lt_po_lines(ln_indx_line_count).LINE_TYPE
                                            ,lt_po_lines(ln_indx_line_count).ITEM
                                            ,lt_po_lines(ln_indx_line_count).ITEM_ID
                                            ,lt_po_lines(ln_indx_line_count).QUANTITY
                                            ,lt_po_lines(ln_indx_line_count).UNIT_PRICE
                                            ,lt_po_lines(ln_indx_line_count).SHIPMENT_TYPE
                                            ,lt_po_lines(ln_indx_line_count).LINE_ATTRIBUTE_CATEGORY_LINES
                                            ,lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE6
                                            ,lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE7
                                            ,lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE8
                                            ,lt_po_lines(ln_indx_line_count).SHIPMENT_ATTRIBUTE_CATEGORY
                                            ,lt_po_lines(ln_indx_line_count).UNIT_OF_MEASURE
                                            ,lt_po_lines(ln_indx_line_count).DOCUMENT_NUM
                                            ,lt_po_lines(ln_indx_line_count).PO_HEADER_ID
                                            ,lt_po_lines(ln_indx_line_count).PO_LINE_ID
                                            ,lt_po_lines(ln_indx_line_count).LINE_TYPE_ID
                                            ,lt_po_lines(ln_indx_line_count).CREATION_DATE
                                            ,lt_po_lines(ln_indx_line_count).CREATED_BY
                                            ,lt_po_lines(ln_indx_line_count).LAST_UPDATE_DATE
                                            ,lt_po_lines(ln_indx_line_count).LAST_UPDATED_BY
                                            ,lt_po_lines(ln_indx_line_count).LAST_UPDATE_LOGIN
                                            ,lt_po_lines(ln_indx_line_count).EFFECTIVE_DATE
                                            ,lt_po_lines(ln_indx_line_count).EXPIRATION_DATE
                                            );
            EXCEPTION
              WHEN OTHERS THEN
               display_log('Error when Inserting in line loop '||SQLERRM);
              END;

        END LOOP;

     END IF;--lt_po_lines.COUNT > 0

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        log_procedure(   p_program_name           => 'insert_into_po_interface'
                        ,p_error_location         => 'NO_DATA_FOUND in main block of insert_into_po_interface '
                        ,p_error_message_code     =>  SQLCODE
                        ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                        ,p_error_message_severity =>  'MAJOR'
                        ,p_notify_flag            =>  'Y'
                        ,p_object_id              =>  NULL
                        ,p_attribute1             =>  NULL
                        );
        x_retcode := 2;
        x_errbuf  := ('When No_data_Found  Exception in  procedure insert_into_po_interface SQLCODE  : ' || SQLCODE ||' SQLERRM  : '|| SQLERRM);
        display_log(x_errbuf);
    WHEN OTHERS THEN
        log_procedure(   p_program_name           => 'insert_into_po_interface'
                        ,p_error_location         => 'WHEN OTHERS THEN in main block of insert_into_po_interface '
                        ,p_error_message_code     =>  SQLCODE
                        ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                        ,p_error_message_severity =>  'MAJOR'
                        ,p_notify_flag            =>  'Y'
                        ,p_object_id              =>  NULL
                        ,p_attribute1             =>  NULL
                        );
        x_retcode := 2;
        x_errbuf  := ('When Others Excetion in procedure insert_into_po_interface SQLCODE  : ' || SQLCODE ||' SQLERRM  : ' ||SQLERRM);
      display_log(x_errbuf);
END insert_into_po_interface;
-- +=========================================================================+
-- | Name         : display_errors                                           |
-- |                                                                         |
-- | Description  : This procedure fetches the all the errors and displays   |
-- |                them as a report                                         |
-- |                                                                         |
-- |In Parameter  :                                                          |
-- |                                                                         |
-- |Out Parameter :                                                          |
-- +=========================================================================+
PROCEDURE display_errors
IS

BEGIN

    display_out('==============================================================================================================');
    display_out('Control ID    Supplier Name      Item Number    Line Number     Error  Message                         ');
    display_out('==============================================================================================================');


    FOR indx_err_disp in
              (SELECT XPPFRS.control_id control_id
                     ,XPPFRS.error_message error_message
                     ,NULL line_num
                     ,XPPFRS.item item
                     ,(SELECT vendor_name FROM po_vendors PV
                       WHERE PV.vendor_id = PVS.vendor_id) Supplier_name
              FROM   xx_po_price_from_rms_stg XPPFRS
                    ,po_vendor_sites_all      PVS
              WHERE  XPPFRS.error_message IS NOT NULL
              AND    XPPFRS.request_id    = gn_master_request_id
              AND    PVS.attribute9(+)    = XPPFRS.supplier
        UNION
               SELECT DISTINCT PIE.interface_header_id
                    ,PIE.error_message
                    ,PLI.line_num
                    ,PLI.item
                    ,(SELECT vendor_name FROM po_vendors PV
                      WHERE PV.vendor_id = PHI.vendor_id) Supplier_name
              FROM   po_interface_errors PIE
                    ,po_headers_interface PHI
                    ,po_lines_interface PLI
                    ,xx_po_price_from_rms_stg XPPFRS
              WHERE PIE.interface_header_id = PHI.interface_header_id
              AND   XPPFRS.request_id = gn_master_request_id
              AND  'I1078-'||XPPFRS.control_id = PHI.interface_source_code
              AND   PHI.interface_header_id = PLI.interface_header_id(+))

         LOOP

            display_out(RPAD(indx_err_disp.control_id,14,' ')||RPAD(NVL(TO_CHAR(indx_err_disp.Supplier_name),'-'),18,' ')||'  '||
                                    RPAD(NVL(TO_CHAR(indx_err_disp.item),'-'),14,' ') ||'  '||RPAD(NVL(TO_CHAR(indx_err_disp.line_num),'-'),12,' ') ||'  '||indx_err_disp.error_message);


         END LOOP;

       display_out('==============================================================================================================');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
      display_log('When No_data_Found Exception in display_errors SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);
    WHEN OTHERS THEN
      display_log('When Others Exception in  display_errors SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);
END display_errors;

-- +=========================================================================+
-- | Name         :  main                                                    |
-- |                                                                         |
-- | Description  :  This procedure is invoked from the OD: PO Quotations    |
-- |                 Interface Concurrent Request.This Procedure picks the   |
-- |                 records from the staging table,validates them and also  |
-- |                 makes a call to the  procedure INSERT INTO INTERFACE    |
-- |                 which inserts records into standard po interface tables |
-- |                                                                         |
-- |In Parameters :  p_debug_flag                                            |
-- |                                                                         |
-- |                                                                         |
-- |Out Parameters:  x_errbuf                                                |
-- |                 x_retcode                                               |
-- +=========================================================================+

PROCEDURE main
             (
               x_errbuf              OUT VARCHAR2
             , x_retcode             OUT NUMBER
             , p_debug_flag          IN  VARCHAR2
             , p_purge_days          IN  NUMBER
             )
IS
-- -----------------------------------------
-- Local Variable and Exceptions Declaration
-- -----------------------------------------
EX_PROCESS_PO_ERROR          EXCEPTION;

ln_inventory_item_id         mtl_system_items_b.inventory_item_id%TYPE;--derived inventory_item_id
lc_prim_unit_of_measure      mtl_system_items_b.primary_unit_of_measure%TYPE;--derived unit_of_measure
ln_organization_id           hr_all_organization_units.organization_id%TYPE;--derived organization_id
ln_line_num                  po_lines_all.line_num%TYPE;--line number of the quotation
ln_po_line_id                po_lines_all.po_line_id%TYPE;--line id of the quotation
ln_line_type_id              po_lines_all.line_type_id%TYPE;--line type id of the quotation
lc_new_supplier              xx_po_price_from_rms_stg.supplier%TYPE;
ld_start_date                DATE;--start_date of the currently open price break
ln_po_header_id              PLS_INTEGER;--derived po_header_id
ln_retcode_del               PLS_INTEGER;--retcode from call of delete procedure
ln_retcode_del1              PLS_INTEGER;--retcode from call of delete procedure
ln_retcode                   PLS_INTEGER;--retcode
--ln_agent_id                  PLS_INTEGER;--derived agent id
ln_vendor_site_id            PLS_INTEGER;--derived vendor_site_id
ln_vendor_id                 PLS_INTEGER;--derived vendor_id
ln_control_id                PLS_INTEGER;--record id of each record
ln_total_processed           PLS_INTEGER:=0;--Total No of records processed
ln_total_rejected            PLS_INTEGER:=0;--No of records rejected
ln_quotations_processed      PLS_INTEGER:=0;--No of new quotations created
ln_quotations_rejected       PLS_INTEGER:=0;--No of new quotations rejected
ln_no_of_hdrs_inserted       PLS_INTEGER:=0;--No of inserts into the interface table
ln_total_successful          PLS_INTEGER:=0;--No of records successful
ln_total_updated             PLS_INTEGER:=0;--No of Quotations Updated.
lc_return_status             VARCHAR2(1);--return status
lc_error_flag                VARCHAR2(1);--error flag.set when error
lc_org_id_exists             VARCHAR2(1);--flag to check existance of org_id
lc_inv_item_exists           VARCHAR2(1);--flag to check existance of item
lc_supplier_exists           VARCHAR2(1);--flag to check existance of supplier
lc_agent_id_exists           VARCHAR2(1);--flag to check existance of agent
lc_currency_exists           VARCHAR2(1);--flag to check valid currency
lc_validation_flag           VARCHAR2(1);--flag to check whether validated or not
lc_vendor_item_exists        VARCHAR2(1);--flag to check existance vendor-item  combination
lc_vendor_exists             VARCHAR2(1);--flag to check existance of vendor id
lc_create_flag               VARCHAR2(40);--parameter to identify which case
lc_segment1                  VARCHAR2(20);--document number
lc_uom                       VARCHAR2(25);--unit of measure
lc_org_id_err_msg            VARCHAR2(240);--error message if org_id does not exist
lc_itm_id_err_msg            VARCHAR2(240);--error message if item_id does not exist
lc_vendr_id_err_msg          VARCHAR2(240);--error message if vendor_id does not exist
lc_currency_err_msg          VARCHAR2(240);--error message if not a valid currency
lc_error_message             VARCHAR2(240);--concatenated error message
lc_agent_err_msg             VARCHAR2(240);--error message if agent Id does not exist
lc_rej_rec_err_msg           VARCHAR2(240);--error message for rejected records
lc_dup_rec_err_msg           VARCHAR2(240);--error message for duplicate records
lc_errbuf                    VARCHAR2(1000);--errbuf
lc_rowid                     VARCHAR2(100) ;
ln_quotation_approval_id     NUMBER   ;
--ln_approver_id               NUMBER   ;
ld_start_date_active         DATE     ;
ld_end_date_active           DATE     ;
ln_line_location_id          NUMBER   ;
ld_last_update_date          DATE     ;
ln_last_updated_by           NUMBER   ;
ln_last_update_login         NUMBER   ;
ld_creation_date             DATE     ;
ln_created_by                NUMBER   ;
lc_attribute_category        VARCHAR2(100) ;
lc_attribute1                VARCHAR2(100) ;
lc_attribute2                VARCHAR2(100) ;
lc_attribute3                VARCHAR2(100) ;
lc_attribute4                VARCHAR2(100) ;
lc_attribute5                VARCHAR2(100) ;
lc_attribute6                VARCHAR2(100) ;
lc_attribute7                VARCHAR2(100) ;
lc_attribute8                VARCHAR2(100) ;
lc_attribute9                VARCHAR2(100) ;
lc_attribute10               VARCHAR2(100) ;
lc_attribute11               VARCHAR2(100) ;
lc_attribute12               VARCHAR2(100) ;
lc_attribute13               VARCHAR2(100) ;
lc_attribute14               VARCHAR2(100) ;
lc_attribute15               VARCHAR2(100) ;
lc_new_header                VARCHAR2(1) := 'N' ;
ln_old_intfc_hdr_id          NUMBER;
ln_request_id                NUMBER   ;
ln_program_application_id    NUMBER   ;
ln_program_id                NUMBER   ;
ln_interface_header_id       NUMBER   ;
ld_program_update_date       DATE     ;

------------------------------------------
--Cursor to fetch all the eligible records
------------------------------------------
CURSOR lcu_main_cntrl_id
IS
SELECT XPPFRS.control_id
FROM  xx_po_price_from_rms_stg XPPFRS
WHERE XPPFRS.status IS NULL
ORDER BY control_id;
-------------------------------------------------------
--Cursor to fetch all the eligible records of that batch
--------------------------------------------------------
CURSOR lcu_main_cur
IS
SELECT XPPFRS.*
FROM   xx_po_price_from_rms_stg XPPFRS
WHERE  XPPFRS.status = 1
AND    XPPFRS.request_id = gn_master_request_id
ORDER BY supplier ;
---------------------------
--Cursor to derive Agent id
---------------------------
CURSOR lcu_agent
IS
SELECT PA.agent_id
FROM   po_agents PA
      ,per_all_people_f PAPF
WHERE  PA.agent_id = PAPF.person_id
AND    UPPER(PAPF.first_name) = 'BUYER'--'INTERFACE'
AND    UPPER(PAPF.last_name)  = 'INTERFACE';--'BUYER';
------------------------------------
--Cursor to validate Organization ID
------------------------------------
CURSOR lcu_organization_id (p_operating_unit IN VARCHAR2)
IS
SELECT HAOU.organization_id
FROM   hr_all_organization_units HAOU
WHERE  HAOU.name = p_operating_unit;
----------------------------------------------------------
--Cursor to fetch inventory_item_id,primary_unit_of_measure
-----------------------------------------------------------
CURSOR lcu_item(p_item IN VARCHAR2)
IS
SELECT inventory_item_id,primary_unit_of_measure
FROM   mtl_system_items_b MSIB
       ,mtl_parameters MP
WHERE  MSIB.segment1 = p_item
AND    MP.organization_id = MSIB.organization_id
AND    ROWNUM = 1;
-----------------------------------------------
--Cursor to fetch vendor_site_id and vendor_id
-----------------------------------------------
CURSOR lcu_supplier(p_supplier IN VARCHAR2)
IS

SELECT PVSA.vendor_site_id
      ,PVSA.vendor_id
FROM   po_vendor_sites_all PVSA
WHERE  PVSA.attribute9 = p_supplier
AND    PVSA.purchasing_site_flag = 'Y'
AND    SYSDATE < NVL(inactive_date, SYSDATE + 1);

------------------------------
--Cursor to Validate Currency
------------------------------
CURSOR lcu_currency(p_currency_code IN VARCHAR2)
IS
SELECT  'Y'
FROM    FND_CURRENCIES   FC
WHERE   FC.currency_code   = p_currency_code
AND     FC.enabled_flag    = 'Y'
AND     TRUNC(SYSDATE)
BETWEEN TRUNC(NVL(FC.start_date_active, SYSDATE))
AND     TRUNC(NVL(FC.end_Date_active,SYSDATE));

-----------------------------------------------------------------------------
--Cursor to select Selecting document number and po_header_id if item-vendor
--combination or vendor_site_id exists
-----------------------------------------------------------------------------
CURSOR lcu_hdr_id_doc_num(
                          p_vendor_site_id    IN NUMBER
                         )
IS
SELECT  PH.po_header_id
       ,PH.segment1
       ,PH.currency_code
       ,PL.line_num
       ,PL.po_line_id
       ,PL.line_type_id
       ,PL.item_id
FROM    po_lines_all PL
       ,po_headers_all PH
WHERE  PH.po_header_id = PL.po_header_id
AND    PH.quote_type_lookup_code = 'CATALOG'
AND    PH.type_lookup_code  = 'QUOTATION'
AND    PH.vendor_site_id  = p_vendor_site_id
AND    PH.status_lookup_code != 'C';

-----------------------------------------------------
--Derive start_date of the incoming record if exists
-----------------------------------------------------

CURSOR lcu_check_date( p_po_line_id    IN NUMBER
                      ,p_real_eff_date IN DATE
                      )
IS
SELECT DISTINCT start_date
FROM   po_line_locations_all
WHERE  po_line_id = p_po_line_id
AND    start_date = p_real_eff_date;

----------------------------------------------------
--Cursor to get the Count of quotations created
----------------------------------------------------
CURSOR lcu_line_info --(p_batch_id IN NUMBER)
IS
SELECT COUNT (CASE WHEN status ='2' THEN 1 END)
      ,COUNT (CASE WHEN status ='3' THEN 1 END)
FROM   xx_po_price_from_rms_stg XPPFRS
      ,po_headers_interface PHI
WHERE XPPFRS.request_id          = gn_master_request_id
AND   PHI.batch_id               = G_BATCH_ID --XPPFRS.request_id
AND  'I1078-'||XPPFRS.control_id = PHI.interface_source_code
AND   PHI.action                 = 'ORIGINAL';

-----------------------------------------------------------------
--Cursor to update status and error message back in staging table
-----------------------------------------------------------------
CURSOR lcu_update_succ_unsucc
IS
SELECT SUBSTR(interface_source_code,7) control_id
      ,error_message err_msg
      ,DECODE(error_message,NULL,3,2) process_code
      --,DECODE(process_code,'REJECTED',2,'ACCEPTED',3) process_code
FROM   po_headers_interface PHI
      ,po_interface_errors  PIE
WHERE  PHI.interface_source_code LIKE 'I1078-%'
AND    PHI.batch_id = G_BATCH_ID --gn_master_request_id
AND    PHI.interface_header_id = PIE.interface_header_id(+);

TYPE lcu_update_succ_unsucc_tbl IS TABLE OF lcu_update_succ_unsucc%ROWTYPE;
lt_update_succ_unsucc lcu_update_succ_unsucc_tbl;

BEGIN

     display_log('Main Program Begins..');
     display_out('==============================================================================');
     display_out(' Office Depot                                    Date : '||TO_CHAR(SYSDATE,'dd-Mon-yy hh24:mi:ss'));
     display_out(' ');
     display_out('                        OD: PO Purchase Price From RMS Inbound                ');
     display_out(' ');
     display_out('==============================================================================');
 
     gc_debug_flag := p_debug_flag;
     gn_master_request_id := FND_GLOBAL.conc_request_id;
 
     BEGIN
 
        SELECT  XX_PO_QUOT_INTERFACE_BAT_S.nextval
        INTO    G_BATCH_ID FROM DUAL;
 
     EXCEPTION
         WHEN OTHERS THEN
            log_procedure(  p_program_name           => 'main'
                           ,p_error_location         => 'WHEN OTHERS THEN when finding Nextval for the sequence XX_PO_QUOT_INTERFACE_BAT_S'
                           ,p_error_message_code     =>  SQLCODE
                           ,p_error_message          =>  SQLERRM
                           ,p_error_message_severity =>  'MAJOR'
                           ,p_notify_flag            =>  'Y'
                           ,p_object_id              =>  NULL
                           ,p_attribute1             =>  NULL
                          );
            x_retcode := 1;
            x_retcode := 1;
           display_log('Unexpected Errors when finding Nextval for the sequence XX_PO_QUOT_INTERFACE_BAT_S');
     END;
 
     BEGIN
          -------------------------------------------------------------------------------------
          --Update the records with status as 2 for those which have same supplier and item
          --and already have been rejected.
          --If exists then Dont process the record any further till the original record is fixed.
          ---------------------------------------------------------------------------------------
           display_log('Error the rejected records,if any');
           fnd_message.set_name('XXPTP','XX_PO_60004_REJECTED_RECORD');
           lc_rej_rec_err_msg := SUBSTR(fnd_message.get,1,240);

           UPDATE xx_po_price_from_rms_stg XPPFRS
           SET    XPPFRS.status           =  2
                 ,XPPFRS.error_code       =  'XX_PO_60004_REJECTED_RECORD'
                 ,XPPFRS.error_message    =  lc_rej_rec_err_msg
                 ,XPPFRS.request_id       =  gn_master_request_id
                 ,XPPFRS.last_update_date =  SYSDATE
                 ,XPPFRS.last_updated_by  =  G_USER_ID
                 ,last_update_login = fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
           WHERE  XPPFRS.status IS NULL
           AND    XPPFRS.control_id IN
                                      (SELECT XPPFRS.control_id
                                       FROM   xx_po_price_from_rms_stg XPPFRS1
                                       WHERE  XPPFRS1.item       =  XPPFRS.item
                                       AND    XPPFRS1.supplier   =  XPPFRS.supplier
                                       AND    XPPFRS1.control_id <> XPPFRS.control_id
                                       AND    XPPFRS1.status     = 2
                                      );
     EXCEPTION
         WHEN OTHERS THEN
           log_procedure(  p_program_name           => 'main'
                          ,p_error_location         => 'WHEN OTHERS THEN when updating xx_po_price_from_rms_stg'
                          ,p_error_message_code     =>  SQLCODE
                          ,p_error_message          =>  SQLERRM
                          ,p_error_message_severity =>  'MAJOR'
                          ,p_notify_flag            =>  'Y'
                          ,p_object_id              =>  NULL
                          ,p_attribute1             =>  NULL
                         );
         x_retcode := 1;
         x_retcode := 1;
         display_log('Unexpected Errors when updating xx_po_price_from_rms_stg for rejected records');
     END;

     BEGIN
          -------------------------------------------------------------------------------------
          --Update the records with status as 2 for those which have same supplier and item and
          --have their statuses NULL
          ---------------------------------------------------------------------------------------
           display_log('Error the duplicate records,if any');
           fnd_message.set_name('XXPTP','XX_PO_600010_DUPLICATE_RECORD');
           lc_dup_rec_err_msg := SUBSTR(fnd_message.get,1,240);

           UPDATE xx_po_price_from_rms_stg XPPFRS
           SET    XPPFRS.status           =  2
                 ,XPPFRS.error_code       =  'XX_PO_600010_DUPLICATE_RECORD'
                 ,XPPFRS.error_message    =  lc_dup_rec_err_msg
                 ,XPPFRS.request_id       =  gn_master_request_id
                 ,XPPFRS.last_update_date =  SYSDATE
                 ,XPPFRS.last_updated_by  =  G_USER_ID
           WHERE  XPPFRS.status     IS NULL
           AND    XPPFRS.control_id IN
                                      (SELECT XPPFRS.control_id
                                       FROM   xx_po_price_from_rms_stg XPPFRS1
                                       WHERE  XPPFRS1.item       =  XPPFRS.item
                                       AND    XPPFRS1.supplier   =  XPPFRS.supplier
                                       AND    XPPFRS1.control_id <> XPPFRS.control_id
                                       AND    XPPFRS1.status     IS NULL
                                      );
     EXCEPTION
         WHEN OTHERS THEN
           log_procedure(  p_program_name           => 'main'
                          ,p_error_location         => 'WHEN OTHERS THEN when updating xx_po_price_from_rms_stg'
                          ,p_error_message_code     =>  SQLCODE
                          ,p_error_message          =>  SQLERRM
                          ,p_error_message_severity =>  'MAJOR'
                          ,p_notify_flag            =>  'Y'
                          ,p_object_id              =>  NULL
                          ,p_attribute1             =>  NULL
                         );
         x_retcode := 1;
         x_retcode := 1;
         display_log('Unexpected Errors when updating xx_po_price_from_rms_stg for duplicate records');
     END;

     BEGIN
          ------------------------------------------------------------------------------
          --Update the records with status as 2 for those which have same supplier and
          --have different currencies with their statuses NULL
          ------------------------------------------------------------------------------
           display_log('Error the multiple currency for a vendor,if any');
           fnd_message.set_name('XXPTP','XX_PO_600012_MULTIPLE_CURRENCY');
           lc_dup_rec_err_msg := SUBSTR(fnd_message.get,1,240);

           UPDATE xx_po_price_from_rms_stg XPPFRS
           SET    XPPFRS.status           =  2
                 ,XPPFRS.error_code       =  'XX_PO_600012_MULTIPLE_CURRENCY'
                 ,XPPFRS.error_message    =  lc_dup_rec_err_msg
                 ,XPPFRS.request_id       =  gn_master_request_id
                 ,XPPFRS.last_update_date =  SYSDATE
                 ,XPPFRS.last_updated_by  =  G_USER_ID
                 ,last_update_login = fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
           WHERE  XPPFRS.status     IS NULL
           AND    XPPFRS.control_id IN
                                      (SELECT XPPFRS.control_id
                                       FROM   xx_po_price_from_rms_stg XPPFRS1
                                       WHERE  XPPFRS1.supplier      =  XPPFRS.supplier
                                       AND    XPPFRS1.currency_code <> XPPFRS.currency_code
                                       AND    XPPFRS1.control_id    <> XPPFRS.control_id
                                       AND    XPPFRS1.status        IS NULL
                                      );
     EXCEPTION
         WHEN OTHERS THEN
           log_procedure(  p_program_name           => 'main'
                          ,p_error_location         => 'WHEN OTHERS THEN when updating xx_po_price_from_rms_stg'
                          ,p_error_message_code     =>  SQLCODE
                          ,p_error_message          =>  SQLERRM
                          ,p_error_message_severity =>  'MAJOR'
                          ,p_notify_flag            =>  'Y'
                          ,p_object_id              =>  NULL
                          ,p_attribute1             =>  NULL
                         );
         x_retcode := 1;
         x_retcode := 1;
         display_log('Unexpected Errors when updating xx_po_price_from_rms_stg for duplicate records');
     END;


     OPEN  lcu_main_cntrl_id;
     FETCH lcu_main_cntrl_id BULK COLLECT INTO g_main_cntrl_id_tbl;
     CLOSE lcu_main_cntrl_id;

     FORALL indx_set_status IN 1 .. g_main_cntrl_id_tbl.LAST
     UPDATE  xx_po_price_from_rms_stg XPPFRS
     SET     XPPFRS.status           =  1
            ,XPPFRS.last_update_date =  SYSDATE
            ,XPPFRS.last_updated_by  =  G_USER_ID
            ,last_update_login       = fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
            ,XPPFRS.request_id       =  gn_master_request_id
     WHERE   XPPFRS.control_id       =  g_main_cntrl_id_tbl(indx_set_status);
     COMMIT;

     OPEN  lcu_main_cur;
     FETCH lcu_main_cur BULK COLLECT INTO g_main_cur_tbl;
     CLOSE lcu_main_cur;
     -------------------------------------------
     --Check for the Agent ID Definition in EBS
     -------------------------------------------
     display_log('Validating Agent ID... ');
     OPEN lcu_agent;
     FETCH lcu_agent INTO G_AGENT_ID;
         IF lcu_agent%NOTFOUND THEN

             lc_agent_id_exists :='N';
             fnd_message.set_name('XXPTP','XX_PO_60007_INVALID_AGENT_ID');
             lc_agent_err_msg := SUBSTR(fnd_message.get,1,240);
           --Adding error message to stack
             log_procedure(  p_program_name           => 'main'
                            ,p_error_location         => 'NO_DATA_FOUND'
                            ,p_error_message_code     =>  SQLCODE
                            ,p_error_message          =>  lc_agent_err_msg
                            ,p_error_message_severity =>  'MAJOR'
                            ,p_notify_flag            =>  'Y'
                            ,p_object_id              =>  NULL
                            ,p_attribute1             =>  NULL
                          );
         ELSE
             lc_agent_id_exists := 'Y';
             display_log('Agent ID exists :'||G_AGENT_ID);
         END IF;
      CLOSE lcu_agent;
      IF  g_main_cur_tbl.COUNT > 0 THEN

         display_log('Number of records eligible for validation :'||g_main_cur_tbl.COUNT);
         FOR i IN g_main_cur_tbl.FIRST .. g_main_cur_tbl.LAST
         LOOP
            lc_org_id_err_msg   := NULL;
            lc_itm_id_err_msg   := NULL;
            lc_vendr_id_err_msg := NULL;
            lc_new_header       :='N';

            ----------------------------
            -- Validate Organization Id
            ----------------------------
            display_log('Validating Organization Id..');
            OPEN lcu_organization_id(g_main_cur_tbl(i).operating_unit);
            FETCH lcu_organization_id INTO ln_organization_id;

                IF  lcu_organization_id%NOTFOUND THEN
                    lc_org_id_exists :='N';
                    fnd_message.set_name('XXPTP','XX_PO_60003_INVLD_ORG');
                    fnd_message.set_token('OPERATING_UNIT',g_main_cur_tbl(i).operating_unit);
                    lc_org_id_err_msg := SUBSTR(fnd_message.get,1,240);
                    --Adding error message to stack
                    log_procedure(  p_program_name           => 'main'
                                   ,p_error_location         => 'NO_DATA_FOUND'
                                   ,p_error_message_code     =>  SQLCODE
                                   ,p_error_message          =>  lc_org_id_err_msg
                                   ,p_error_message_severity =>  'MAJOR'
                                   ,p_notify_flag            =>  'Y'
                                   ,p_object_id              =>  NULL
                                   ,p_attribute1             =>  NULL
                                 );

                ELSE
                  lc_org_id_exists := 'Y';
                  display_log('Organization Exists :' ||ln_organization_id);
                END IF;
            CLOSE lcu_organization_id;
            ----------------------------
            -- Validate item
            ----------------------------
            display_log('Validating item..');
            OPEN lcu_item(g_main_cur_tbl(i).item);
            FETCH lcu_item INTO ln_inventory_item_id,lc_uom;

                IF  lcu_item%NOTFOUND THEN
                    lc_inv_item_exists :='N';
                    fnd_message.set_name('XXPTP','XX_PO_60002_INVLD_ITEM');
                    fnd_message.set_token('ITEM',g_main_cur_tbl(i).item);
                    lc_itm_id_err_msg  := SUBSTR(fnd_message.get,1,240);
                    --Adding error message to stack
                    log_procedure(  p_program_name           => 'main'
                                   ,p_error_location         => 'NO_DATA_FOUND'
                                   ,p_error_message_code     =>  SQLCODE
                                   ,p_error_message          =>  lc_itm_id_err_msg
                                   ,p_error_message_severity =>  'MAJOR'
                                   ,p_notify_flag            =>  'Y'
                                   ,p_object_id              =>  NULL
                                   ,p_attribute1             =>  NULL
                                 );
                ELSE
                    lc_inv_item_exists := 'Y';
                    display_log('Item Exists :' ||lc_inv_item_exists);
                END IF;
            CLOSE lcu_item;

            --------------------------
            -- Validate Vendor Site Id
            --------------------------
            display_log('Validating Supplier..');
            OPEN lcu_supplier(g_main_cur_tbl(i).supplier);
            FETCH lcu_supplier INTO ln_vendor_site_id,ln_vendor_id;

                IF lcu_supplier%NOTFOUND THEN
                    lc_supplier_exists :='N';
                    fnd_message.set_name('XXPTP','XX_PO_60001_INVLD_SUPPLIER');
                    fnd_message.set_token('SUPPLIER',g_main_cur_tbl(i).supplier);
                    lc_vendr_id_err_msg := SUBSTR(fnd_message.get,1,240);
                    --Adding error message to stack
                    log_procedure(  p_program_name            => 'main'
                                    ,p_error_location         => 'NO_DATA_FOUND'
                                    ,p_error_message_code     =>  SQLCODE
                                    ,p_error_message          =>  lc_vendr_id_err_msg
                                    ,p_error_message_severity =>  'MAJOR'
                                    ,p_notify_flag            =>  'Y'
                                    ,p_object_id              =>  NULL
                                    ,p_attribute1             =>  NULL
                                  );

                 ELSE
                    lc_supplier_exists := 'Y';
                    display_log('Supplier Exists, Vendor Id :' ||ln_vendor_id||'Vendor Site Id :'||ln_vendor_site_id);
                END IF;
            CLOSE lcu_supplier;

            --------------------------
            -- Validate Currency Code
            --------------------------
            display_log('Validating Currency..');
            OPEN lcu_currency(g_main_cur_tbl(i).currency_code);
            FETCH lcu_currency INTO lc_currency_exists;

                IF lcu_currency%NOTFOUND THEN
                    lc_currency_exists :='N';
                    fnd_message.set_name('XXPTP','XX_PO_60008_INVALID_CURRENCY');
                    fnd_message.set_token('CURRENCY',g_main_cur_tbl(i).currency_code);
                    lc_currency_err_msg := SUBSTR(fnd_message.get,1,240);
                    --Adding error message to stack
                    log_procedure(  p_program_name            => 'main'
                                    ,p_error_location         => 'NO_DATA_FOUND'
                                    ,p_error_message_code     =>  SQLCODE
                                    ,p_error_message          =>  lc_currency_err_msg
                                    ,p_error_message_severity =>  'MAJOR'
                                    ,p_notify_flag            =>  'Y'
                                    ,p_object_id              =>  NULL
                                    ,p_attribute1             =>  NULL
                                  );
                END IF;
            CLOSE lcu_currency;

            -------------------------------------------------------------------------
            --If the validation is successful,set lc_validation_flag to  'S' else 'F'
            --------------------------------------------------------------------------

            IF lc_org_id_exists = 'Y' AND lc_supplier_exists = 'Y'
                                      AND lc_inv_item_exists = 'Y'
                                      AND lc_agent_id_exists = 'Y'
                                      AND lc_currency_exists = 'Y' THEN
               lc_validation_flag := 'S';
               display_log('The Validation is successfull..');
            ELSE
              -----------------------------------------------------------
              --Also SET the error reason ,WHEN the validation has failed
              -----------------------------------------------------------
               lc_validation_flag := 'F';
               lc_error_message :=  SUBSTR(lc_agent_err_msg ||'  '|| lc_org_id_err_msg||'  '||
               lc_vendr_id_err_msg||'  '||lc_itm_id_err_msg,1,240);
               display_log('Validation Failed,for control_id ' || g_main_cur_tbl(i).control_id|| ' reason being '||lc_error_message);

               BEGIN
                  UPDATE xx_po_price_from_rms_stg
                  SET  error_code       = 'Error'
                     , error_message    = SUBSTR(lc_error_message,1,240)
                     , status           = 2
                     , last_update_date = SYSDATE
                     , last_updated_by  = G_USER_ID
                     , last_update_login= fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
                  WHERE   control_id    = g_main_cur_tbl(i).control_id;
                  COMMIT;

               EXCEPTION
                  WHEN OTHERS THEN
                  log_procedure(  p_program_name           => 'main'
                                 ,p_error_location         => 'WHEN OTHERS THEN when Updating the Stage Table for Errors'
                                 ,p_error_message_code     =>  SQLCODE
                                 ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                                 ,p_error_message_severity =>  'MAJOR'
                                 ,p_notify_flag            =>  'Y'
                                 ,p_object_id              =>  NULL
                                 ,p_attribute1             =>  NULL
                                );
                  x_retcode := 1;
                  display_log('Unexpected errors raised when updating staging table status to 2');
               END;

            END IF;--lc_org_id_exists = 'Y' AND lc_supplier_exists = 'Y'

            -------------------------------------------
            --Proceed Only if validation is successful
            -------------------------------------------
            IF  lc_validation_flag = 'S' THEN

               display_log('Further Processing after Sucessfull validation..');
               ---------------------------------------------------------
               --Derive po_header_id and document number(segment1) if it
               --exists for the same item and vendor_site_id combination
               ---------------------------------------------------------
               display_log('Selecting document number and po_header_id if item-vendor combination exists');

               --Initialise the flags to N
               lc_vendor_exists      := 'N';
               lc_vendor_item_exists := 'N';
               G_CURRENCY_CODE       := NULL;

               FOR indx_hdr_id_doc_num IN lcu_hdr_id_doc_num(ln_vendor_site_id)
               LOOP
                   IF lcu_hdr_id_doc_num%NOTFOUND THEN
                      lc_vendor_exists  :='N';
                   ELSE
                       IF  indx_hdr_id_doc_num.item_id = ln_inventory_item_id  THEN

                            G_CURRENCY_CODE       := indx_hdr_id_doc_num.currency_code;
                            ln_po_header_id       := indx_hdr_id_doc_num.po_header_id;
                            lc_segment1           := indx_hdr_id_doc_num.segment1;
                            ln_line_num           := indx_hdr_id_doc_num.line_num;
                            ln_po_line_id         := indx_hdr_id_doc_num.po_line_id;
                            ln_line_type_id       := indx_hdr_id_doc_num.line_type_id;
                            lc_vendor_item_exists := 'Y';
                            EXIT;
                       ELSE
                            G_CURRENCY_CODE       := indx_hdr_id_doc_num.currency_code;
                            ln_po_header_id       := indx_hdr_id_doc_num.po_header_id;
                            lc_segment1           := indx_hdr_id_doc_num.segment1;
                            ln_line_num           := indx_hdr_id_doc_num.line_num;
                            ln_po_line_id         := indx_hdr_id_doc_num.po_line_id;
                            ln_line_type_id       := indx_hdr_id_doc_num.line_type_id;
                            lc_vendor_item_exists := 'N';
                            lc_vendor_exists      := 'Y';
                       END IF;
                   END IF;
               END LOOP;

                display_log('Document Number found  :'||lc_segment1 );

              --CLOSE lcu_hdr_id_doc_num;

               lc_create_flag := NULL;--initialise lc_create_flag to NULL

               ------------------------------------------------------------------
               --If real_eff_date is Null then,use active_date(Except for Delete)
               -------------------------------------------------------------------
               IF g_main_cur_tbl(i).real_eff_date IS NULL
                  AND g_main_cur_tbl(i).operation_code = 'CREATE' THEN
                  g_main_cur_tbl(i).real_eff_date := g_main_cur_tbl(i).active_date;
               END IF;

               ----------------------------------------------------------------------------
               --If a quotation exists against the same vendor_site_id and item combination
               ----------------------------------------------------------------------------
               IF lc_vendor_item_exists = 'Y' THEN
                  -----------------------------------------------------
                  --Derive start_date of the incoming record if exists
                  -----------------------------------------------------
                  display_log('Before Deriving start_date of the of the incoming record if exists');

                  OPEN   lcu_check_date(ln_po_line_id,g_main_cur_tbl(i).real_eff_date);
                  FETCH  lcu_check_date INTO ld_start_date;
                  CLOSE  lcu_check_date;

                  display_log('The date of the incoming price break is :'||ld_start_date||'and real eff date of incoming record :'||g_main_cur_tbl(i).real_eff_date);

                  IF g_main_cur_tbl(i).operation_code = 'CREATE'  THEN --check for the operation code
                      IF TRUNC(ld_start_date) = TRUNC(g_main_cur_tbl(i).real_eff_date) THEN

                        --If same date then,update price only,set lc_create_flag to 'UPDATE_SAME_EFF_DATE'
                        display_log('The date of the open price break is :'||ld_start_date||'and real eff date of incoming record :'||g_main_cur_tbl(i).real_eff_date);
                        lc_create_flag := 'UPDATE_SAME_EFF_DATE';

                      ELSE
                        --If different date then,update price only,set lc_create_flag to 'UPDATE_DIFF_EFF_DATE'
                        display_log('Calling procedure insert_into_po_interface for UPDATE_DIFF_EFF_DATE case and po_line_id is :' ||ln_po_line_id);
                        lc_create_flag := 'UPDATE_DIFF_EFF_DATE';

                      END IF;--Ending the IF TRUNC(ld_start_date) = TRUNC(g_main_cur_tbl(i).real_eff_date)

                  --If the opeation code is delete,then set  lc_create_flag to 'DELETE';
                  ELSIF g_main_cur_tbl(i).operation_code = 'DELETE' THEN

                      lc_create_flag := 'DELETE';

                  ELSE
                      display_log('Invalid operation_code ' ||g_main_cur_tbl(i).operation_code );
                  END IF;--IF operation_code

               END IF;--lc_vendor_item_exists = 'Y'
               display_log('lc_create_flag '||lc_create_flag);
 
	
	
	        SELECT  PO_HEADERS_INTERFACE_S.nextval
                INTO    ln_interface_header_id FROM DUAL;
 
	      -- Check if this is the same supplier
	         IF g_main_cur_tbl(i).supplier <> NVL(lc_new_supplier,-1) THEN
		    lc_new_header       := 'Y';
		    ln_old_intfc_hdr_id := ln_interface_header_id  ;
		    display_log('Interface_header_id '||ln_interface_header_id);
	         END IF;


                  IF lc_create_flag IS NOT NULL THEN

                        insert_into_po_interface(
                                                  x_retcode               =>  x_retcode
                                                 ,x_errbuf                =>  x_errbuf
                                                 ,p_control_id            =>  g_main_cur_tbl(i).control_id
                                                 ,p_create_flag           =>  lc_create_flag
                                                 ,p_header_id             =>  ln_po_header_id
                                                 ,p_segment1              =>  lc_segment1
                                                 ,p_line_num              =>  ln_line_num
                                                 ,p_po_line_id            =>  ln_po_line_id
                                                 ,p_po_line_type_id       =>  ln_line_type_id
                                                 ,p_inventory_item_id     =>  ln_inventory_item_id
                                                 ,p_currency_code         =>  g_main_cur_tbl(i).currency_code
                                                 ,p_item                  =>  g_main_cur_tbl(i).item
                                                 ,p_uom                   =>  lc_uom
                                                 ,p_supplier              =>  ln_vendor_id
                                                 ,p_vendor_site_id        =>  ln_vendor_site_id
                                                 ,p_organization_id       =>  ln_organization_id
                                                 ,p_agent_id              =>  G_AGENT_ID
                                                 ,p_unit_cost             =>  g_main_cur_tbl(i).unit_cost
                                                 ,p_tier1_cost            =>  g_main_cur_tbl(i).tier1_cost
                                                 ,p_tier2_cost            =>  g_main_cur_tbl(i).tier2_cost
                                                 ,p_tier3_cost            =>  g_main_cur_tbl(i).tier3_cost
                                                 ,p_tier4_cost            =>  g_main_cur_tbl(i).tier4_cost
                                                 ,p_tier5_cost            =>  g_main_cur_tbl(i).tier5_cost
                                                 ,p_tier6_cost            =>  g_main_cur_tbl(i).tier6_cost
                                                 ,p_total_cost            =>  g_main_cur_tbl(i).total_cost
                                                 ,p_unit_qty              =>  g_main_cur_tbl(i).unit_qty
                                                 ,p_tier1_qty             =>  g_main_cur_tbl(i).tier1_qty
                                                 ,p_tier2_qty             =>  g_main_cur_tbl(i).tier2_qty
                                                 ,p_tier3_qty             =>  g_main_cur_tbl(i).tier3_qty
                                                 ,p_tier4_qty             =>  g_main_cur_tbl(i).tier4_qty
                                                 ,p_tier5_qty             =>  g_main_cur_tbl(i).tier5_qty
                                                 ,p_tier6_qty             =>  g_main_cur_tbl(i).tier6_qty
                                                 ,p_price_protection_flag =>  g_main_cur_tbl(i).price_protection_flag
                                                 ,p_active_date           =>  TRUNC(g_main_cur_tbl(i).active_date)
                                                 ,p_real_effective_date   =>  TRUNC(g_main_cur_tbl(i).real_eff_date)
                                                 ,p_end_date              =>  NULL
                                                 ,p_creation_date         =>  g_main_cur_tbl(i).creation_date
                                                 ,p_created_by            =>  g_main_cur_tbl(i).created_by
                                                 ,p_last_update_date      =>  g_main_cur_tbl(i).last_update_date
                                                 ,p_last_updated_by       =>  g_main_cur_tbl(i).last_updated_by
                                                 ,p_start_date            =>  ld_start_date
                                                 ,p_supplier_exists       =>  'Y'
                                                 ,p_interface_header_id   =>  ln_interface_header_id
                                                 );
               END IF;--IF lc_create_flag IS NOT NULL

               ----------------------------------------------------------------------------------
               --If a quotation does not exist for  the same vendor_site_id and item combination,
               --check if quotation with the same vendor exists
               ----------------------------------------------------------------------------------
               IF lc_vendor_item_exists  = 'N' THEN
                  display_log('Inside to check whether Vendor and Quotation exists');
                   ---------------------------------------------------------
                   --Derive po_header_id and document number(segment1),
                   --if it exists for the given vendor_site_id
                   ---------------------------------------------------------
                   display_log('Before Selecting document number and po_header_id if vendor_site_id exists');

                   display_log('Vendor exists :'||lc_vendor_exists);
                   IF g_main_cur_tbl(i).operation_code = 'CREATE' AND lc_vendor_exists = 'Y' THEN
                       display_log('operation_code = '||g_main_cur_tbl(i).operation_code );
                       insert_into_po_interface(
                                                  x_retcode                =>  x_retcode
                                                 ,x_errbuf                 =>  x_errbuf
                                                 ,p_control_id             =>  g_main_cur_tbl(i).control_id
                                                 ,p_create_flag            =>  'NEW_ITEM'
                                                 ,p_header_id              =>  ln_po_header_id
                                                 ,p_segment1               =>  lc_segment1
                                                 ,p_line_num               =>  ln_line_num
                                                 ,p_po_line_id             =>  ln_po_line_id
                                                 ,p_po_line_type_id        =>  ln_line_type_id
                                                 ,p_inventory_item_id      =>  ln_inventory_item_id
                                                 ,p_currency_code          =>  g_main_cur_tbl(i).currency_code
                                                 ,p_item                   =>  g_main_cur_tbl(i).item
                                                 ,p_uom                    =>  lc_uom
                                                 ,p_supplier               =>  ln_vendor_id
                                                 ,p_vendor_site_id         =>  ln_vendor_site_id
                                                 ,p_organization_id        =>  ln_organization_id
                                                 ,p_agent_id               =>  G_AGENT_ID
                                                 ,p_unit_cost              =>  g_main_cur_tbl(i).unit_cost
                                                 ,p_tier1_cost             =>  g_main_cur_tbl(i).tier1_cost
                                                 ,p_tier2_cost             =>  g_main_cur_tbl(i).tier2_cost
                                                 ,p_tier3_cost             =>  g_main_cur_tbl(i).tier3_cost
                                                 ,p_tier4_cost             =>  g_main_cur_tbl(i).tier4_cost
                                                 ,p_tier5_cost             =>  g_main_cur_tbl(i).tier5_cost
                                                 ,p_tier6_cost             =>  g_main_cur_tbl(i).tier6_cost
                                                 ,p_total_cost             =>  g_main_cur_tbl(i).total_cost
                                                 ,p_unit_qty               =>  g_main_cur_tbl(i).unit_qty
                                                 ,p_tier1_qty              =>  g_main_cur_tbl(i).tier1_qty
                                                 ,p_tier2_qty              =>  g_main_cur_tbl(i).tier2_qty
                                                 ,p_tier3_qty              =>  g_main_cur_tbl(i).tier3_qty
                                                 ,p_tier4_qty              =>  g_main_cur_tbl(i).tier4_qty
                                                 ,p_tier5_qty              =>  g_main_cur_tbl(i).tier5_qty
                                                 ,p_tier6_qty              =>  g_main_cur_tbl(i).tier6_qty
                                                 ,p_price_protection_flag  =>  g_main_cur_tbl(i).price_protection_flag
                                                 ,p_active_date            =>  TRUNC(g_main_cur_tbl(i).active_date)
                                                 ,p_real_effective_date    =>  TRUNC(g_main_cur_tbl(i).real_eff_date)
                                                 ,p_end_date               =>  NULL
                                                 ,p_creation_date          =>  g_main_cur_tbl(i).creation_date
                                                 ,p_created_by             =>  g_main_cur_tbl(i).created_by
                                                 ,p_last_update_date       =>  g_main_cur_tbl(i).last_update_date
                                                 ,p_last_updated_by        =>  g_main_cur_tbl(i).last_updated_by
                                                 ,p_start_date             =>  ld_start_date
                                                 ,p_supplier_exists        =>  'Y'
                                                 ,p_interface_header_id   =>  ln_interface_header_id
                                                 );
                   END IF;-- END IF for g_main_cur_tbl(i).operation_code = 'CREATE'

               END IF;--END IF for lc_vendor_item_exists  = 'N'

            display_log('lc_vendor_item_exists =' ||lc_vendor_item_exists ||'lc_vendor_exists ='||lc_vendor_exists);

            IF lc_vendor_item_exists  = 'N' AND lc_vendor_exists = 'N' THEN
                  display_log('Call for creation of new Quotation ');
 
                  IF g_main_cur_tbl(i).operation_code = 'CREATE' THEN
                         insert_into_po_interface(
                                                  x_retcode                =>  x_retcode
                                                 ,x_errbuf                 =>  x_errbuf
                                                 ,p_control_id             =>  g_main_cur_tbl(i).control_id
                                                 ,p_create_flag            =>  'ORIGINAL'
                                                 ,p_header_id              =>  NULL
                                                 ,p_segment1               =>  NULL
                                                 ,p_line_num               =>  NULL -- ln_line_num
                                                 ,p_po_line_id             =>  ln_po_line_id
                                                 ,p_po_line_type_id        =>  ln_line_type_id
                                                 ,p_inventory_item_id      =>  ln_inventory_item_id
                                                 ,p_currency_code          =>  g_main_cur_tbl(i).currency_code
                                                 ,p_item                   =>  g_main_cur_tbl(i).item
                                                 ,p_uom                    =>  lc_uom
                                                 ,p_supplier               =>  ln_vendor_id
                                                 ,p_organization_id        =>  ln_organization_id
                                                 ,p_vendor_site_id         =>  ln_vendor_site_id
                                                 ,p_agent_id               =>  G_AGENT_ID
                                                 ,p_unit_cost              =>  g_main_cur_tbl(i).unit_cost
                                                 ,p_tier1_cost             =>  g_main_cur_tbl(i).tier1_cost
                                                 ,p_tier2_cost             =>  g_main_cur_tbl(i).tier2_cost
                                                 ,p_tier3_cost             =>  g_main_cur_tbl(i).tier3_cost
                                                 ,p_tier4_cost             =>  g_main_cur_tbl(i).tier4_cost
                                                 ,p_tier5_cost             =>  g_main_cur_tbl(i).tier5_cost
                                                 ,p_tier6_cost             =>  g_main_cur_tbl(i).tier6_cost
                                                 ,p_total_cost             =>  g_main_cur_tbl(i).total_cost
                                                 ,p_unit_qty               =>  g_main_cur_tbl(i).unit_qty
                                                 ,p_tier1_qty              =>  g_main_cur_tbl(i).tier1_qty
                                                 ,p_tier2_qty              =>  g_main_cur_tbl(i).tier2_qty
                                                 ,p_tier3_qty              =>  g_main_cur_tbl(i).tier3_qty
                                                 ,p_tier4_qty              =>  g_main_cur_tbl(i).tier4_qty
                                                 ,p_tier5_qty              =>  g_main_cur_tbl(i).tier5_qty
                                                 ,p_tier6_qty              =>  g_main_cur_tbl(i).tier6_qty
                                                 ,p_price_protection_flag  =>  g_main_cur_tbl(i).price_protection_flag
                                                 ,p_active_date            =>  TRUNC(g_main_cur_tbl(i).active_date)
                                                 ,p_real_effective_date    =>  TRUNC(g_main_cur_tbl(i).real_eff_date)
                                                 ,p_end_date               =>  NULL
                                                 ,p_creation_date          =>  g_main_cur_tbl(i).creation_date
                                                 ,p_created_by             =>  g_main_cur_tbl(i).created_by
                                                 ,p_last_update_date       =>  g_main_cur_tbl(i).last_update_date
                                                 ,p_last_updated_by        =>  g_main_cur_tbl(i).last_updated_by
                                                 ,p_start_date             =>  ld_start_date
                                                 ,p_supplier_exists        =>  lc_new_header
                                                 ,p_interface_header_id    =>  ln_old_intfc_hdr_id
                                                 );

                  END IF; --End IF for operation_code = 'CREATE'

            END IF;--END  IF for lc_vendor_item_exists  = 'N' AND lc_vendor_exists = 'N'

            END IF;--IF  lc_validation_flag = 'S'
            -- Re-initialize the supplier variable
            lc_new_supplier  := g_main_cur_tbl(i).supplier ;
 
         END LOOP;

         --Take a count of records inserted in the interface table
         BEGIN
            SELECT COUNT(1)
            INTO   ln_no_of_hdrs_inserted
            FROM   po_headers_interface PHI
            WHERE  PHI.batch_id = G_BATCH_ID --gn_master_request_id
            AND    PHI.interface_source_code LIKE 'I1078-%';
         EXCEPTION
             WHEN OTHERS THEN
                log_procedure(  p_program_name           => 'main'
                               ,p_error_location         => 'WHEN OTHERS THEN when selecting count from po_headers_interface'
                               ,p_error_message_code     =>  SQLCODE
                               ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                               ,p_error_message_severity =>  'MAJOR'
                               ,p_notify_flag            =>  'Y'
                               ,p_object_id              =>  NULL
                               ,p_attribute1             =>  NULL
                                 );
                x_retcode := 1;
                display_log('WHEN OTHERS THEN when selecting count from po_headers_interface');
         END;

         --Launch Import price catalog if any record is inserted in the interface table
         IF ln_no_of_hdrs_inserted > 0 THEN
             --Making a commit here,not in the called procedures
             COMMIT;
             process_po(
                         x_errbuf     => lc_errbuf
                        ,x_retcode    => ln_retcode
                        ,p_batch_id   => G_BATCH_ID
                        ,p_debug_flag => p_debug_flag
                        );
             IF ln_retcode <> 0 THEN
                x_errbuf := lc_errbuf;
                display_log('Error in Calling Process_PO procedure :- ');
                RAISE EX_PROCESS_PO_ERROR;
             END IF;
         END IF;--ln_no_of_hdrs_inserted > 0

      ELSE
         display_log('No eligible records found in staging table' );
      END IF; --g_main_cur_tbl.COUNT > 0 which is checked in the begining

      -------------------------------------------------------------
      --To Delete Records from the staging table after p_purge_days
      -------------------------------------------------------------
      delete_from_stg (
                        p_purge_days => p_purge_days
                       ,x_retcode    => ln_retcode_del
                      );

      IF ln_retcode_del <> 0 THEN
         x_retcode := ln_retcode_del;
      END IF;


      OPEN  lcu_update_succ_unsucc;
      FETCH lcu_update_succ_unsucc BULK COLLECT INTO lt_update_succ_unsucc;
      CLOSE lcu_update_succ_unsucc;

      IF lt_update_succ_unsucc.COUNT > 0 THEN

         FOR idx_succ_unsucc in 1..lt_update_succ_unsucc.LAST
         LOOP
           IF lt_update_succ_unsucc(idx_succ_unsucc).process_code = 2 THEN
            UPDATE  xx_po_price_from_rms_stg XPPFRS
                       SET     XPPFRS.status           = lt_update_succ_unsucc(idx_succ_unsucc).process_code
                              ,XPPFRS.error_message    = SUBSTR(lt_update_succ_unsucc(idx_succ_unsucc).err_msg||XPPFRS.error_message,1,240)
                              ,XPPFRS.last_update_date = SYSDATE
                              ,XPPFRS.last_updated_by  = G_USER_ID
                              ,last_update_login       = fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
            WHERE   XPPFRS.control_id    = lt_update_succ_unsucc(idx_succ_unsucc).control_id;

           ELSE
            UPDATE  xx_po_price_from_rms_stg XPPFRS
            SET     XPPFRS.status           = lt_update_succ_unsucc(idx_succ_unsucc).process_code
                   ,XPPFRS.error_message    = NULL
                   ,XPPFRS.error_code       = NULL
                   ,XPPFRS.last_update_date = SYSDATE
                   ,XPPFRS.last_updated_by  = G_USER_ID
                   ,last_update_login = fnd_profile.VALUE('LOGIN_ID')  -- Added by Lalitha Budithi On 18DEC07
            WHERE   XPPFRS.control_id       = lt_update_succ_unsucc(idx_succ_unsucc).control_id;
           END IF;

        END LOOP;


      END IF;

      -----------------------------
      --To display all the errors
      -----------------------------
      display_errors;
      ----------------------------------------------------
      --Cursor to get the Count of quotations created
      ----------------------------------------------------

      SELECT COUNT (CASE WHEN status ='2' THEN 1 END)
            ,COUNT (CASE WHEN status ='3' THEN 1 END)
      INTO   ln_total_rejected
            ,ln_total_successful
      FROM  xx_po_price_from_rms_stg XPPFRS
      WHERE XPPFRS.request_id = gn_master_request_id;

      ln_total_processed := ln_total_rejected + ln_total_successful;

      ----------------------------------------------------------------------
      --Fetching Number of Invalid, Processing Failed and Processed PO Lines
      ----------------------------------------------------------------------
      OPEN  lcu_line_info;--(p_batch_id);
      FETCH lcu_line_info INTO ln_quotations_rejected,ln_quotations_processed;
      CLOSE lcu_line_info;

     ln_total_updated := ln_total_successful - ln_quotations_processed;

     display_out(' ');
     display_out('------------------------------------------------------------------------------');
     display_out('                   --------------------------------');
     display_out('                   Purchase Price From RMS Summary ');
     display_out('                   --------------------------------');
     display_out('------------------------------------------------------------------------------');
     display_out(' ');
     display_out('Total number of Records Processed:                       '||ln_total_processed);
     display_out('Total number of Records Rejected:                        '||ln_total_rejected);
     display_out('Total number of Quotations that were updated             '||ln_total_updated);
     display_out('Total number of New Quotations created:                  '||ln_quotations_processed);
     display_out('Total number of New Quotations failed to get created:    '||ln_quotations_rejected);
     display_out(' ');

     display_log('Calling the Program to approve the Quotation Lines');

     approve_quotation_lines
                       (
                           p_rowid                    =>     lc_rowid
                          ,p_Quotation_Approval_ID    =>     ln_quotation_approval_id
                          ,p_Approval_Type            =>     GC_APPROVAL_TYPE
                          ,p_Approval_Reason          =>     GC_APPROVAL_REASON
                          ,p_Comments                 =>     GC_COMMENTS
                          ,p_Approver_ID              =>     G_AGENT_ID --ln_approver_id
                          ,p_Start_Date_Active        =>     ld_start_date_active
                          ,p_End_Date_Active          =>     ld_end_date_active
                          ,p_Line_Location_ID         =>     ln_line_location_id
                          ,p_Last_Update_Date         =>     SYSDATE
                          ,p_Last_Updated_By          =>     G_USER_ID
                          ,p_Last_Update_Login        =>     ln_last_update_login
                          ,p_Creation_Date            =>     SYSDATE
                          ,p_Created_By               =>     G_USER_ID
                          ,p_Attribute_Category       =>     lc_attribute_category
                          ,p_Attribute1               =>     lc_attribute1
                          ,p_Attribute2               =>     lc_attribute2
                          ,p_Attribute3               =>     lc_attribute3
                          ,p_Attribute4               =>     lc_attribute4
                          ,p_Attribute5               =>     lc_attribute5
                          ,p_Attribute6               =>     lc_attribute6
                          ,p_Attribute7               =>     lc_attribute7
                          ,p_Attribute8               =>     lc_attribute8
                          ,p_Attribute9               =>     lc_attribute9
                          ,p_Attribute10              =>     lc_attribute10
                          ,p_Attribute11              =>     lc_attribute11
                          ,p_Attribute12              =>     lc_attribute12
                          ,p_Attribute13              =>     lc_attribute13
                          ,p_Attribute14              =>     lc_attribute14
                          ,p_Attribute15              =>     lc_attribute15
                          ,p_Request_ID               =>     ln_request_id
                          ,p_Program_Application_ID   =>     ln_program_application_id
                          ,p_Program_ID               =>     ln_program_id
                          ,p_Program_Update_Date      =>     ld_program_update_date
                       );

display_out(LPAD('The Program Completed Successfully',60));

EXCEPTION
    WHEN EX_PROCESS_PO_ERROR THEN
         log_procedure(  p_program_name           => 'main'
                        ,p_error_location         => 'EX_PROCESS_PO_ERROR'
                        ,p_error_message_code     =>  SQLCODE
                        ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                        ,p_error_message_severity =>  'MAJOR'
                        ,p_notify_flag            =>  'Y'
                        ,p_object_id              =>  NULL
                        ,p_attribute1             =>  NULL
                       );
         x_errbuf  := 'Unexpected Exception is raised while calling Procedure PROCESS_PO ';
         x_retcode := 2;
    WHEN NO_DATA_FOUND THEN
         log_procedure(  p_program_name           => 'main'
                        ,p_error_location         => 'NO_DATA_FOUND'
                        ,p_error_message_code     =>  SQLCODE
                        ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                        ,p_error_message_severity =>  'MAJOR'
                        ,p_notify_flag            =>  'Y'
                        ,p_object_id              =>  NULL
                        ,p_attribute1             =>  NULL
                       );
         x_retcode := 2;
         x_errbuf  := ('When No_data_Found  Exception in  Main SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);
         display_log(x_errbuf);
    WHEN OTHERS THEN
         log_procedure(  p_program_name           => 'main'
                        ,p_error_location         => 'WHEN OTHERS THEN'
                        ,p_error_message_code     =>  SQLCODE
                        ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                        ,p_error_message_severity =>  'MAJOR'
                        ,p_notify_flag            =>  'Y'
                        ,p_object_id              =>  NULL
                        ,p_attribute1             =>  NULL
                       );
         x_retcode := 2;
         x_errbuf  := ('When Others Exception in  Main SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);
         display_log(x_errbuf);
END main;

END XX_PO_PURCHPRCFRMRMS_PKG;
/
SHOW ERRORS

EXIT;

--------------------------------------------------------------------------------

