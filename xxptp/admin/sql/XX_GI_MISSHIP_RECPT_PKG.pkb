CREATE OR REPLACE PACKAGE BODY XX_GI_MISSHIP_RECPT_PKG
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- | Name        :  XX_GI_MISSHIP_RECPT_PKG.pkb                                  |
-- | Description :  Matches and Validated the PO from staging table and Standard |
-- |                Table                                                        |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |  Version      Date         Author             Remarks                       |
-- | =========  =========== =============== ==================================== |
-- |  DRAFT 1a  24-Oct-2007   Meenu Goyal     Initial draft version              |
-- +=============================================================================+

AS

G_FAILED                 CONSTANT VARCHAR2(10)                                        :=  'FAILED';
G_SUCCESS                CONSTANT VARCHAR2(10)                                        :=  'SUCCESS';
G_NONTRADE               CONSTANT VARCHAR2(10)                                        :=  'NON-TRADE';

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

TYPE rcv_status_tbl_type IS TABLE OF xx_gi_rcv_po_dtl.od_rcv_status_flag%type
INDEX BY BINARY_INTEGER;
gt_od_rcv_status_flag    rcv_status_tbl_type;

TYPE rvc_correction_tbl_type IS TABLE OF xx_gi_rcv_po_dtl.od_rvc_correction_flag%type
INDEX BY BINARY_INTEGER;
gt_od_rvc_correction_flag    rvc_correction_tbl_type;


TYPE error_message_tbl_type IS TABLE OF VARCHAR2(4000)
INDEX BY BINARY_INTEGER;
gt_error_message    error_message_tbl_type;

gt_item_details    XX_GI_MISSHIP_COMM_PKG.ITEM_DETAILS_REC_TBL_TYPE;


TYPE rowid_tbl_type IS TABLE OF rowid
INDEX BY BINARY_INTEGER;
gt_rowid     rowid_tbl_type;

TYPE item_num_tbl_type IS TABLE OF xx_gi_rcv_po_dtl.item_num%type
INDEX BY BINARY_INTEGER;
gt_item_num    item_num_tbl_type;

TYPE attribute9_tbl_type IS TABLE OF rcv_transactions_interface.attribute9%type
INDEX BY BINARY_INTEGER;
gt_attribute9    attribute9_tbl_type;

TYPE error_status_tbl_type IS TABLE OF VARCHAR2(10)
INDEX BY BINARY_INTEGER;
gt_error_status     error_status_tbl_type;

-- +======================================================================+
-- | Name        :  check_po_line                                         |
-- | Description :  This procedure checks if item exits in PO Line. Also  |
-- |                derives the status of PO                              |
-- |                                                                      |
-- | Parameters  :  p_header_id                                           |
-- |                p_item_id                                             |
-- |                                                                      |
-- | Returns     :  x_authorization_status                                |
-- |                x_line_id                                             |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+

PROCEDURE check_po_line (  p_header_id              IN         NUMBER
                          ,p_item_num               IN         VARCHAR2
                          ,x_authorization_status   OUT NOCOPY VARCHAR2
                          ,x_line_id                OUT NOCOPY NUMBER
                          ,x_status                 OUT NOCOPY VARCHAR2
                          ,x_message                OUT NOCOPY VARCHAR2
                        )
IS
    lc_authorization_status                 po_headers_all.authorization_status%type;
    ln_line_id                              po_lines_all.po_line_id%type;
    
BEGIN

    SELECT  POH.authorization_status, (SELECT POL.po_line_id
                                       FROM   po_lines_all POL
                                             ,mtl_system_items_b MSIB
                                       WHERE  POL.po_header_id      = POH.po_header_id
                                       AND    POL.item_id           = MSIB.inventory_item_id
                                       AND    MSIB.segment1         = p_item_num
                                       AND    MSIB.organization_id  = gn_master_organization
                                       AND    ROWNUM=1 ---In case more than one line has same item
                                      ) line_id
    INTO    lc_authorization_status,ln_line_id
    FROM    po_headers_all POH
    WHERE   POH.po_header_id     = p_header_id;

    x_status               := 'S';
    x_authorization_status := lc_authorization_status;
    x_line_id              := ln_line_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_authorization_status := NULL;
        x_line_id              := NULL;
        x_status               := 'E';
        x_message              := 'Purchase Order does not exist';
    WHEN OTHERS THEN
        x_authorization_status := NULL;
        x_line_id              := NULL;
        x_status               := 'E';
        x_message              := 'Error while finding item in Purchase Order. Error: '||SUBSTR(SQLERRM,1,500);
END check_po_line;


PROCEDURE LOG_ERROR(p_exception      IN VARCHAR2
                   ,p_message        IN VARCHAR2
                   ,p_code           IN VARCHAR2
                   )
-- +======================================================================+
-- | Name        :  LOG_ERROR                                             |
-- | Description :  This is a wrapper api to log error                    |
-- |                                                                      |
-- | Parameters  :  p_exception                                           |
-- |                p_message                                             |
-- |                p_code                                                |
-- +======================================================================+                   
IS

lc_err_code         VARCHAR2(100);
lc_errbuf           VARCHAR2(5000);
lc_error_location   VARCHAR2(50) ;

BEGIN 

   lc_error_location  := 'XX_GI_MISSHIP_RECPT_PKG.LOG_ERROR';
   
   XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                    P_PROGRAM_TYPE            => GC_PROGRAM_TYPE    ,
                                    P_PROGRAM_NAME            => GC_PROGRAM_NAME    ,
                                    P_MODULE_NAME             => GC_MODULE_NAME     ,
                                    P_ERROR_LOCATION          => p_exception        ,
                                    P_ERROR_MESSAGE_CODE      => p_code             ,
                                    P_ERROR_MESSAGE           => p_message          ,
                                    P_NOTIFY_FLAG             => GC_NOTIFY          ,
                                    P_ERROR_MESSAGE_SEVERITY  => GC_MAJOR                 
                                    ); 

   
EXCEPTION

    WHEN OTHERS THEN
    
         lc_err_code       := 'XX_INV_6000_UNEXP_ERR_LOG_ERR';
         lc_errbuf         :=  FND_MESSAGE.GET;         
       
         LOG_ERROR(p_exception      =>lc_error_location
                  ,p_message        =>lc_errbuf
                  ,p_code           =>lc_err_code
                  ) ; 

END LOG_ERROR;



PROCEDURE RESET_PROCESS_FLAG(
                             p_index                       IN    NUMBER
                            ,p_rowid                       IN    ROWID
                            ,p_od_rcv_status_flag          IN    VARCHAR2
                            ,p_od_rvc_correction_flag      IN    VARCHAR2
                            ,p_error_message               IN    VARCHAR2
                            ,p_error_status                IN    VARCHAR2
                            ,p_item_num                    IN    VARCHAR2
                            ,p_attribute9                  IN    VARCHAR2 
                            )
                            
-- +======================================================================+
-- | Name        :  reset_process_flags                                   |
-- | Description :  This procedure will update the status of the record   |
-- |                based on the validation.                              |
-- |                receiving org                                         |
-- |                                                                      |
-- | Parameters  :  p_index                                               |
-- |                p_od_rcv_status_flag                                  |
-- |                p_od_rvc_correction_flag                              |
-- |                p_error_message                                       |
-- | Returns     :  x_status                                              |
-- |                x_message                                             |
-- +======================================================================+                            

IS

lc_err_code         VARCHAR2(100);
lc_errbuf           VARCHAR2(5000);
lc_error_location   VARCHAR2(50) ;

BEGIN

    lc_error_location  := 'RESET_PROCESS_FLAG';
    
    gt_rowid(p_index)                                   :=  p_rowid;
    gt_od_rcv_status_flag(p_index)                      :=  p_od_rcv_status_flag;
    gt_od_rvc_correction_flag(p_index)                  :=  p_od_rvc_correction_flag ;
    gt_error_message(p_index)                           :=  p_error_message;
    gt_item_num(p_index)                                :=  p_item_num;
    gt_attribute9(p_index)                              :=  p_attribute9;
    gt_error_status(p_index)                            :=  p_error_status;
    
EXCEPTION

    WHEN OTHERS THEN
    
         lc_err_code       := 'XX_INV_6001_UNEXP_ERR_RESET';
         lc_errbuf         :=  FND_MESSAGE.GET;
         
         LOG_ERROR(p_exception      =>lc_error_location
                  ,p_message        =>lc_errbuf
                  ,p_code           =>lc_err_code
                  ) ; 
                  
END RESET_PROCESS_FLAG;


-- +======================================================================+
-- | Name        :  is_item_trade_nontrade                                |
-- | Description :  This procedure checks if item exist in master and     |
-- |                receiving org                                         |
-- |                                                                      |
-- | Parameters  :  p_organizaion_id                                      |
-- |                p_item_num                                            |
-- |                                                                      |
-- | Returns     :  x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE IS_ITEM_TRADE_NONTRADE (  p_organization_id         IN         NUMBER
                                   ,p_inventory_item_id       IN         VARCHAR2
                                   ,p_item_num                IN         VARCHAR2
                                   ,p_index                   IN         NUMBER
                                   ,p_rowid                   IN         ROWID
                                   ,x_trade_nontrade          OUT NOCOPY VARCHAR2
                                   ,x_status                  OUT NOCOPY VARCHAR2
                                   ,x_message                 OUT NOCOPY VARCHAR2
                                   )
IS
    lc_item_type                    VARCHAR2(10);
    ln_item_ix                      PLS_INTEGER;
    lc_err_code                     VARCHAR2(100);
    lc_errbuf                       VARCHAR2(5000);
    lc_error_location               VARCHAR2(50) ;

BEGIN

    lc_error_location   := 'IS_ITEM_TRADE_NONTRADE';
    
   
    ----------------------------------------------------
    --Derive if the item is Trade Item or Non-Trade Item
    ----------------------------------------------------
    lc_item_type := XX_INV_ITEM_FORM_PER_PKG.IS_TRADE_ITEM(
                                                            p_inventory_item_id
                                                           ,p_organization_id
                                                           );
                                                           
                                              
    IF lc_item_type = 'Y' THEN        
        
        --Call BEPL process to assign item to receiving Org (Calling Logic TBD)
        --This is handled in I1286_ItemLocAutoModPO
        NULL;
        
    ELSIF lc_item_type = 'N' THEN
    
          ln_item_ix                               :=  gt_item_details.count + 1;
          gt_item_details(ln_item_ix).item_type    :=  G_NONTRADE;
          gt_item_details(ln_item_ix).sku          :=  p_item_num;

    
    END IF; --Trade/Non Trade
    
      x_status                   :=  'S';
      x_trade_nontrade           :=  lc_item_type;
    
   
EXCEPTION

    WHEN OTHERS THEN        
       
        x_status               :=  'E';
        x_message              :=  SQLERRM;
        
        lc_err_code       := 'XX_INV_6002_UNEXP_ERR_TRAD_NON';
        lc_errbuf         :=  FND_MESSAGE.GET;
                 
        LOG_ERROR(p_exception      =>lc_error_location
                 ,p_message        =>lc_errbuf
                 ,p_code           =>lc_err_code
                  ) ; 
        
END IS_ITEM_TRADE_NONTRADE;



PROCEDURE VALIDATE_SKU_RECPT_PROC(
                                  x_errbuf    OUT NOCOPY VARCHAR2
                                 ,x_retcode   OUT NOCOPY VARCHAR2
                                  )
                                  
-- +======================================================================+
-- | Name        :  VALIDATE_SKU_RECPT_PROC                               |
-- | Description :  This procedure is called by concurrent program        |
-- |                'OD: GI Item Validation For RST Data'                 |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_errbuf                                              |
-- |                x_retcode                                             |
-- +======================================================================+                                  
IS

lc_err_code         VARCHAR2(100);
lc_errbuf           VARCHAR2(5000);
lc_error_location   VARCHAR2(50) ;


ln_success_record NUMBER :=0;
ln_errored_record NUMBER :=0;
ln_total_count    NUMBER :=0;
lc_header         VARCHAR2(4000);
lc_details        VARCHAR2(5000);
lc_footer         VARCHAR2(5000);

---------------------------------------------------------------------------------
--Cursor to fetch all the errored records from xx_gi_rcv_po_hdr ,xx_gi_rcv_po_dtl 
---------------------------------------------------------------------------------

CURSOR   lcu_rcv_po_dtl_cur
IS 
SELECT   DTL.rowid
       , HDR.expected_receipt_date
       , DTL.quantity
       , DTL.interface_transaction_id
       , DTL.item_num
       , DTL.to_organization_id
       , DTL.document_num
       , DTL.vendor_id
       , DTL.vendor_site_id
       , DTL.po_header_id
       , DTL.po_line_id
       , DTL.header_interface_id
       , DTL.amount
       , DTL.document_line_num
       , DTL.org_id
       , DTL.attribute9
      ,  DTL.od_rcv_status_flag    
      ,  DTL.od_rvc_correction_flag
      
FROM     xx_gi_rcv_po_hdr HDR   
       , xx_gi_rcv_po_dtl DTL
WHERE    HDR.header_interface_id = DTL.header_interface_id
AND      DTL.od_rcv_status_flag                     = 'E'
AND   (   TRUNC((SYSDATE - to_date(DTL.attribute9,'DD-MON-RRRR HH24:MI:SS'))*24) > 24 OR DTL.attribute9 is NULL)
AND     (DTL.od_rvc_correction_flag   = 'N' OR   DTL.od_rvc_correction_flag IS NULL);

--Declaring plsql tables

TYPE errored_rcv_tbl_type  IS TABLE OF lcu_rcv_po_dtl_cur%rowtype
INDEX BY BINARY_INTEGER;

lt_rcv_po_dtl     errored_rcv_tbl_type;


TYPE timestamp_tbl_type IS TABLE OF VARCHAR2(50)
INDEX BY BINARY_INTEGER;

GT_TIMESTAMP       timestamp_tbl_type;
 
lt_po_details                  XX_GI_MISSHIP_COMM_PKG.PO_ADD_LINE_REC_TBL_TYPE;
lc_attribute9                  rcv_transactions_interface.attribute9%type;
lc_trade_nontrade              VARCHAR2(10);
lc_timestamp                   VARCHAR2(50);

--Cursor to validate the generic item

CURSOR   lcu_validate_generic_item(p_to_organization_id NUMBER,
                                   p_vendor_site_id     VARCHAR2,
                                   p_vendor_id          VARCHAR2
                                   )
IS
SELECT   MSI.SEGMENT1 
FROM     po_approved_supplier_list PASL
       , Mtl_system_items_b MSI 
WHERE    PASL.using_organization_id     = p_to_organization_id
AND      PASL.vendor_site_id            = p_vendor_site_id
AND      PASL.vendor_id                 = p_vendor_id
AND      PASL.item_id                   = MSI.inventory_item_id 
AND      PASL.using_organization_id     = MSI.organization_id  
AND      MSI.item_type                  = '05';

---------------------------
--Declaring Local Varibales
---------------------------
lc_status                      VARCHAR2(1);
lc_message                     VARCHAR2(4000);
lc_authorization_status        po_headers_all.authorization_status%type;
ln_line_id1                     po_lines_all.po_line_id%type;
lc_primary_uom_code            mtl_system_items_b.primary_uom_code%type;
ln_inventory_item_id           mtl_system_items_b.inventory_item_id%type;
lc_item_description            mtl_system_items_b.description%type;
lc_inv_item_num                mtl_system_items_b.segment1%type;
ln_count                       PLS_INTEGER;
lc_item_cost                   NUMBER;
ln_po_ix                       PLS_INTEGER  :=0;
ln_item_ix                     PLS_INTEGER  :=0;

-------------------------
--Declaring the exception
-------------------------

EX_MISSING_SETUP               EXCEPTION;
EX_TRANSACTION                 EXCEPTION;

BEGIN
    
      
    lc_error_location  := 'VALIDATE_SKU_RECPT_PROC';
    
    lc_status  := NULL;
    lc_message := NULL;
       
    ------------------------------
    --Derive Mater Organization id
    ------------------------------
    
    
     XX_GI_MISSHIP_ASN_PKG.DERIVE_MASTER_ORGANIZATION(
                                                     x_master_organization =>  GN_MASTER_ORGANIZATION
                                                    ,x_status              =>  lc_status
                                                    ,x_message             =>  lc_message
                                                    );
    
   
    IF (lc_status = 'E') THEN  
    
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lc_message );       
        
    END IF;
    
   -----------------------------------------
   --Raise exception if any setup is missing
   -----------------------------------------

    IF   GN_REPROCESSING_FREQUENCY = NULL
      OR GC_TRADE_EMAIL            = NULL
      OR GC_NON_TRADE_EMAIL        = NULL
      OR GN_MASTER_ORGANIZATION    = NULL
    THEN
      RAISE EX_MISSING_SETUP;  
    END IF;
  
        
    ------------------------------------------
    --Fetch all the errored asn in PLSQL Table
    ------------------------------------------
    OPEN  lcu_rcv_po_dtl_cur;
    FETCH lcu_rcv_po_dtl_cur BULK COLLECT INTO lt_rcv_po_dtl;    
    CLOSE lcu_rcv_po_dtl_cur;
    
    IF lt_rcv_po_dtl.COUNT <> 0 THEN
       
       --Open the loop for each record
       
       FOR i in lt_rcv_po_dtl.FIRST..lt_rcv_po_dtl.LAST
       LOOP
       
          BEGIN    
          
            
          ----------------------------------------------------------------
          --Validate if ASN item matches PO Line Item and derive PO status
          ----------------------------------------------------------------
            
          check_po_line( p_header_id              =>  lt_rcv_po_dtl(i).po_header_id
                                              ,p_item_num               =>  lt_rcv_po_dtl(i).item_num
                                              ,x_authorization_status   =>  lc_authorization_status
                                              ,x_line_id                =>  ln_line_id1
                                              ,x_status                 =>  lc_status
                                              ,x_message                =>  lc_message
                                               ); 
                                            
               
          --Raise an exception in case procedure errors out
          
          IF lc_status = 'E' THEN
          
             RAISE EX_TRANSACTION;
             
          ELSE  
             
             IF (ln_line_id1 IS NOT NULL AND lc_authorization_status = 'APPROVED') THEN
                 
                                 
                 -------------------
                 --Reset status flag
                 -------------------
                 
                 RESET_PROCESS_FLAG(
                                    p_index                       =>  i
                                   ,p_rowid                       =>  lt_rcv_po_dtl(i).rowid
                                   ,p_od_rcv_status_flag          => 'PRCP'
                                   ,p_od_rvc_correction_flag      => 'Y'
                                   ,p_error_message               =>  NULL
                                   ,p_error_status                =>  G_SUCCESS
                                   ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                   ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9
                                   );
                   
             ELSIF ln_line_id1 IS NOT NULL AND lc_authorization_status <> 'APPROVED' THEN
                 
                                  
                  --Logging the error
                  
                  FND_MESSAGE.SET_NAME('XXPTP','XX_GI_6008_PO_NOT_VALID');
                  FND_MESSAGE.SET_TOKEN('PONUM',lt_rcv_po_dtl(i).document_num ); 
         
                  lc_err_code       := 'XX_GI_6008_PO_NOT_VALID';
                  lc_errbuf         :=  FND_MESSAGE.GET;      

               
                 -------------------
                 --Reset status flag
                 -------------------
                 
                 RESET_PROCESS_FLAG(
                                    p_index                       =>  i
                                   ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                   ,p_od_rcv_status_flag          => 'E'
                                   ,p_od_rvc_correction_flag      => 'N'
                                   ,p_error_message               =>  'Item exists in PO but PO is not in Approved Status'
                                   ,p_error_status                =>  G_FAILED 
                                   ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                   ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9); 
                                   
                  
             
             ELSE   -- po is approved but item is not there on line           
                  -----------------------------------
                  --Validate if item matches UPC Code
                  -----------------------------------
                                 
                  XX_GI_MISSHIP_ASN_PKG.UPC_VALIDATION(  p_organization_id        =>  lt_rcv_po_dtl(i).to_organization_id
                                                        ,p_item_num               =>  lt_rcv_po_dtl(i).item_num
                                                        ,x_inv_item_num           =>  lc_inv_item_num
                                                        ,x_inventory_item_id      =>  ln_inventory_item_id
                                                        ,x_primary_uom_code       =>  lc_primary_uom_code
                                                        ,x_count                  =>  ln_count
                                                        ,x_status                 =>  lc_status
                                                        ,x_message                =>  lc_message
                                                        );
                 
                 
                 --In case the procedure errors out raise an exception
                 
                IF lc_status = 'E' THEN 
                 
                    RAISE EX_TRANSACTION;
                 
                 ELSE
                    
                    IF ln_count = 2 THEN --Validate if item matches UPC Code                       
                        ---------------------------------------------
                        --Item exist in both master and receiving org
                        ---------------------------------------------
                                               
                        RESET_PROCESS_FLAG(
                                            p_index                       => i
                                           ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                           ,p_od_rcv_status_flag          => 'PRCP'
                                           ,p_od_rvc_correction_flag      => 'Y'
                                           ,p_error_message               =>  NULL
                                           ,p_error_status                =>  G_SUCCESS
                                           ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                           ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9);                        
                    
                       --RESET RST ITEM WITH SYSTEM ITEM  
                       
                        lt_rcv_po_dtl(i).item_num := lc_inv_item_num;
                    
                    ELSIF ln_count = 1 THEN                         

                           ----------------------
                           --Call Trade non trade
                           ----------------------
                           IS_ITEM_TRADE_NONTRADE (  p_organization_id         =>  lt_rcv_po_dtl(i).to_organization_id
                                                    ,p_inventory_item_id       =>  ln_inventory_item_id
                                                    ,p_item_num                =>  lt_rcv_po_dtl(i).item_num
                                                    ,p_index                   =>  i  
                                                    ,p_rowid                   =>  lt_rcv_po_dtl(i).rowid
                                                    ,x_trade_nontrade          =>  lc_trade_nontrade
                                                    ,x_status                  =>  lc_status
                                                    ,x_message                 =>  lc_message
                                                   );
                                                   
                            lc_attribute9 := NULL;
                           
                            IF lc_trade_nontrade = 'Y' THEN
                                lc_attribute9 := lc_timestamp;
                            ELSE
                                lc_attribute9 := lt_rcv_po_dtl(i).attribute9;
                            END IF;                           
                           
                                                    
                            fnd_message.set_name('XXPTP','XX_GI_6009_UPC_NOTIN_ORG');
                            fnd_message.set_token('ITEM',lt_rcv_po_dtl(i).item_num);
                            fnd_message.set_token('ORGANIZATION',lt_rcv_po_dtl(i).to_organization_id);
                           
                            lc_err_code     := 'XX_GI_6009_UPC_NOTIN_ORG';
                            lc_errbuf       := fnd_message.get;                            
                                     
                            -------------------------------
                            --Item exist only in master org
                            -------------------------------
                           RESET_PROCESS_FLAG(
                                             p_index                       =>  i
                                            ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                            ,p_od_rcv_status_flag          => 'E'
                                            ,p_od_rvc_correction_flag      => 'N'
                                            ,p_error_message               => 'UPC Item does not exist in receiving Organization'
                                            ,p_error_status                =>  G_FAILED
                                            ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                            ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9);                                      
                                     

                           --In case procedure errors out raise an exception
                           
                           IF lc_status = 'E' THEN
                           
                               RAISE EX_TRANSACTION;
                               
                           END IF;
                           
                    ELSIF  ln_count = 0 THEN  
                    
                            -----------------------------------------------------------
                            --Item is not a UPC Code. Validate if item matches VPC Code
                            -----------------------------------------------------------
                                                        
                            XX_GI_MISSHIP_ASN_PKG.VPC_VALIDATION(  p_organization_id         =>  lt_rcv_po_dtl(i).to_organization_id
                                                                  ,p_item_num                =>  lt_rcv_po_dtl(i).item_num
                                                                  ,p_vendor_id               =>  lt_rcv_po_dtl(i).vendor_id
                                                                  ,x_inv_item_num            =>  lc_inv_item_num
                                                                  ,x_inventory_item_id       =>  ln_inventory_item_id
                                                                  ,x_primary_uom_code        =>  lc_primary_uom_code
                                                                  ,x_count                   =>  ln_count
                                                                  ,x_status                  =>  lc_status
                                                                  ,x_message                 =>  lc_message
                                                                 );   
                                                                 
                                                             
                            --In case procedure errors out raise an exception                            
                            IF lc_status = 'E' THEN
                            
                               RAISE EX_TRANSACTION;
                               
                            ELSE   
                               
                               IF ln_count=2 THEN                               
                                   
                                                                         
                                    -- Replace RST item with System Item. 
                                    lt_rcv_po_dtl(i).item_num := lc_inv_item_num;
                                    
                                                                       
                                    ---------------------------------------------
                                    --Item exist in both master and receiving org
                                    ---------------------------------------------
                                    RESET_PROCESS_FLAG(
                                                        p_index                       => i
                                                       ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                                       ,p_od_rcv_status_flag          => 'PRCP'
                                                       ,p_od_rvc_correction_flag      => 'Y'
                                                       ,p_error_message               =>  NULL
                                                       ,p_error_status                =>  G_SUCCESS
                                                       ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                                       ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9);    
                                                       
                                   
                               ELSIF ln_count = 1 THEN
                               
                                     ----------------------
                                     --Call Trade non trade
                                     ----------------------
                                     
                                     IS_ITEM_TRADE_NONTRADE (  p_organization_id         =>  lt_rcv_po_dtl(i).to_organization_id
                                                              ,p_inventory_item_id       =>  ln_inventory_item_id
                                                              ,p_item_num                =>  lt_rcv_po_dtl(i).item_num
                                                              ,p_index                   =>  i  
                                                              ,p_rowid                   =>  lt_rcv_po_dtl(i).rowid
                                                              ,x_trade_nontrade          =>  lc_trade_nontrade
                                                              ,x_status                  =>  lc_status
                                                              ,x_message                 =>  lc_message
                                                            );   
                                                            
                                     lc_attribute9 := NULL;

                                     IF lc_trade_nontrade = 'Y' THEN
                                         lc_attribute9 := lc_timestamp;
                                     ELSE
                                         lc_attribute9 := lt_rcv_po_dtl(i).attribute9;
                                     END IF;                                                                
                                                            
                                    --Logging the error

                                    FND_MESSAGE.SET_NAME('XXPTP','XX_GI_6007_VPC_ITEM_REC_ORG');
                                    FND_MESSAGE.SET_TOKEN('ITEMNUM',lt_rcv_po_dtl(i).item_num ); 

                                    lc_err_code       := 'XX_GI_60001_ITEM_REC_ORG';
                                    lc_errbuf         :=  FND_MESSAGE.GET;      

                                     -------------------------------
                                     --Item exist only in master org
                                     -------------------------------
                                     
                                    RESET_PROCESS_FLAG(
                                                       p_index                       =>  i
                                                      ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                                      ,p_od_rcv_status_flag          => 'E'
                                                      ,p_od_rvc_correction_flag      => 'N'
                                                      ,p_error_message               =>  lc_errbuf
                                                      ,p_error_status                =>  G_FAILED
                                                      ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                                      ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9);      
                                                      

                                     IF lc_status = 'E' THEN
                                     
                                        RAISE EX_TRANSACTION;
                                     
                                     END IF;
                                     
                               ELSIF ln_count = 0 THEN
                                     
                                     ------------------------------------------------------
                                     --Validate if ASN Item exist in Master Org and rec org
                                     ------------------------------------------------------
                                     
                                     XX_GI_MISSHIP_ASN_PKG.ITEM_IN_MASTER_AND_RECV(p_organization_id         =>  lt_rcv_po_dtl(i).to_organization_id
                                                                                  ,p_item_num                =>  lt_rcv_po_dtl(i).item_num
                                                                                  ,x_inventory_item_id       =>  ln_inventory_item_id
                                                                                  ,x_primary_uom_code        =>  lc_primary_uom_code
                                                                                  ,x_item_description        =>  lc_item_description
                                                                                  ,x_count                   =>  ln_count
                                                                                  ,x_status                  =>  lc_status
                                                                                  ,x_message                 =>  lc_message
                                                                                   );
                                     
                                                                     
                                     IF lc_status = 'E' THEN
                                         RAISE EX_TRANSACTION;
                                         
                                     ELSE                                     
                                     
                                         IF ln_count= 2 THEN   
                                         
                                                                                   
                                            ---------------------------------------------
                                            --Item exist in both master and receiving org
                                            ---------------------------------------------
                                            RESET_PROCESS_FLAG(
                                                               p_index                       => i
                                                              ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                                              ,p_od_rcv_status_flag          => 'PRCP'
                                                              ,p_od_rvc_correction_flag      => 'Y'
                                                              ,p_error_message               =>  NULL
                                                              ,p_error_status                =>  G_SUCCESS
                                                              ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                                              ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9);  
                                                              
                                                                                            
                                             ---------------------
                                             --Derive price for PO
                                             ---------------------
                                             XX_GI_MISSHIP_COMM_PKG.PO_GET_ITEM_PRICE(  p_vendor_id          =>  lt_rcv_po_dtl(i).vendor_id
                                                                                       ,p_item_id            =>  ln_inventory_item_id
                                                                                       ,p_order_qty          =>  lt_rcv_po_dtl(i).quantity
                                                                                       ,p_vendor_site_id     =>  lt_rcv_po_dtl(i).vendor_site_id
                                                                                       ,x_item_cost          =>  lc_item_cost
                                                                                       ,x_return_message     =>  lc_message
                                                                                     );  
                                            
                                                                                     
                                            IF lc_item_cost = -1 OR lc_item_cost IS NULL THEN
                                             
                                                 RAISE EX_TRANSACTION;
                                                 
                                                                                            
                                             ELSE
                                                 
                                                                                              
                                                 -- Replace RST item with System Item. 
                                                
                                                 lt_rcv_po_dtl(i).item_num := lc_inv_item_num;
                                                 
                                                                                                
                                                 ---------------------------------------
                                                 --Add line to lt_po_details Plsql table
                                                 ---------------------------------------
                                                 ln_po_ix := ln_po_ix + 1;
                                                 
                                                 lt_po_details(ln_po_ix).header_po_number          :=  lt_rcv_po_dtl(i).document_num;
                                                 lt_po_details(ln_po_ix).header_vendor_id          :=  lt_rcv_po_dtl(i).vendor_id;
                                                 lt_po_details(ln_po_ix).header_vendor_site_id     :=  lt_rcv_po_dtl(i).vendor_site_id;
                                                 lt_po_details(ln_po_ix).line_item                 :=  lt_rcv_po_dtl(i).item_num;
                                                 lt_po_details(ln_po_ix).line_quantity             :=  lt_rcv_po_dtl(i).quantity;
                                                 lt_po_details(ln_po_ix).line_unit_price           :=  lc_item_cost;
                                                 lt_po_details(ln_po_ix).line_ship_to_org_id       :=  lt_rcv_po_dtl(i).to_organization_id;
                                                 lt_po_details(ln_po_ix).rowid_reference           :=  lt_rcv_po_dtl(i).rowid;
                                                 lt_po_details(ln_po_ix).interface_header_id       :=  lt_rcv_po_dtl(i).header_interface_id;

                                             
                                             END IF;
                                             
                                         ELSIF ln_count=1 THEN --Validate if  Item exist in Master Org and rec org
                                              ----------------------
                                              --Call Trade non trade
                                              ----------------------
                                                                                           

                                              IS_ITEM_TRADE_NONTRADE (  p_organization_id         =>  lt_rcv_po_dtl(i).to_organization_id
                                                                       ,p_inventory_item_id       =>  ln_inventory_item_id
                                                                       ,p_item_num                =>  lt_rcv_po_dtl(i).item_num
                                                                       ,p_index                   =>  i  --confirm
                                                                       ,p_rowid                   =>  lt_rcv_po_dtl(i).rowid
                                                                       ,x_trade_nontrade          =>  lc_trade_nontrade
                                                                       ,x_status                  =>  lc_status
                                                                       ,x_message                 =>  lc_message
                                                                     );  
                                                                     
                                                                     
                                              lc_attribute9 := NULL;

                                              IF lc_trade_nontrade = 'Y' THEN
                                                  lc_attribute9 := lc_timestamp;
                                              ELSE
                                                  lc_attribute9 := lt_rcv_po_dtl(i).attribute9;
                                              END IF;                                                                

                                              --Logging the error

                                              FND_MESSAGE.SET_NAME('XXPTP','XX_GI_6007_VPC_ITEM_REC_ORG');
                                              FND_MESSAGE.SET_TOKEN('ITEMNUM',lt_rcv_po_dtl(i).item_num ); 

                                              lc_err_code       := 'XX_GI_60001_ITEM_REC_ORG';
                                              lc_errbuf         :=  FND_MESSAGE.GET;    
                                    
                                             
                                              -------------------------------
                                              --Item exist only in master org
                                              -------------------------------

                                              RESET_PROCESS_FLAG(
                                                                p_index                       =>  i
                                                               ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                                               ,p_od_rcv_status_flag          => 'E'
                                                               ,p_od_rvc_correction_flag      => 'N'
                                                               ,p_error_message               => 'Item does not exist in receiving Organization'
                                                               ,p_error_status                =>  G_FAILED
                                                               ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                                               ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9); 
                                                      

                                                                     
                                              IF lc_status = 'E' THEN                                                                              
                                                 
                                                 RAISE EX_TRANSACTION;
                                                 
                                              END IF;  
                                              
                                         ELSIF ln_count= 0 THEN
                                          
                                                                                                
                                                --------------------------------------------------------
                                                --Store the items in PLSQL table to send the notfication
                                                --------------------------------------------------------
                                                ln_item_ix := ln_item_ix + 1;
                                              --  gt_item_details(ln_item_ix).loc          :=  lt_rcv_po_dtl(i).location_id;
                                                gt_item_details(ln_item_ix).po_number    :=  lt_rcv_po_dtl(i).document_num;
                                                gt_item_details(ln_item_ix).sku          :=  lt_rcv_po_dtl(i).item_num;
                                                gt_item_details(ln_item_ix).upc_vpc      :=  null;
                                                gt_item_details(ln_item_ix).asnref       :=  null;                                         
                                         
                                                -------------------------------
                                                --Item exist only in master org
                                                -------------------------------

                                                RESET_PROCESS_FLAG(
                                                                  p_index                       =>  i
                                                                 ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                                                 ,p_od_rcv_status_flag          => 'E'
                                                                 ,p_od_rvc_correction_flag      => 'N'
                                                                 ,p_error_message               => 'Item does not exist in master Organization'
                                                                 ,p_error_status                =>  G_FAILED
                                                                 ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num 
                                                                 ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9)
                                                                 ;                                                                         
                                                                  
                                                                  
                                               --validate if any generic items are available for the item in ASL

                                              FOR lcr_validate_generic_item IN lcu_validate_generic_item(lt_rcv_po_dtl(i).to_organization_id,
                                                                                                         lt_rcv_po_dtl(i).vendor_site_id,
                                                                                                         lt_rcv_po_dtl(i).vendor_id)
                                              LOOP
                                                 
                                                 IF lt_rcv_po_dtl(i).Item_num <> lcr_validate_generic_item.segment1  THEN
                                                     
                                                
                                                      RESET_PROCESS_FLAG(
                                                                        p_index                       => i
                                                                       ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                                                       ,p_od_rcv_status_flag          => 'PRCP'
                                                                       ,p_od_rvc_correction_flag      => 'Y'
                                                                       ,p_error_message               =>  NULL
                                                                       ,p_error_status                =>  G_SUCCESS
                                                                       ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num 
                                                                       ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9); 
                                                 
                                                                                                          
                                                       ---------------------
                                                       --Derive price for PO
                                                       ---------------------
                                                       
                                                        XX_GI_MISSHIP_COMM_PKG.PO_GET_ITEM_PRICE(  p_vendor_id          =>  lt_rcv_po_dtl(i).vendor_id
                                                                                                  ,p_item_id            =>  ln_inventory_item_id
                                                                                                  ,p_order_qty          =>  lt_rcv_po_dtl(i).quantity
                                                                                                  ,p_vendor_site_id     =>  lt_rcv_po_dtl(i).vendor_site_id
                                                                                                  ,x_item_cost          =>  lc_item_cost
                                                                                                  ,x_return_message     =>  lc_message
                                                                                                  ); 
                                                                                                  
                                                                                                             
                                                       IF lc_item_cost IS NULL  THEN     
                                                        
                                                           lc_item_cost  := 0.01;
                                                            
                                                       END IF;
                                                       
                                                  
                                                       ---------------------------------------
                                                       --Add line to lt_po_details Plsql table
                                                       ---------------------------------------
                                                       ln_po_ix := ln_po_ix + 1;

                                                       lt_po_details(ln_po_ix).header_po_number          :=  lt_rcv_po_dtl(i).document_num;
                                                       lt_po_details(ln_po_ix).header_vendor_id          :=  lt_rcv_po_dtl(i).vendor_id;
                                                       lt_po_details(ln_po_ix).header_vendor_site_id     :=  lt_rcv_po_dtl(i).vendor_site_id;
                                                       lt_po_details(ln_po_ix).line_item                 :=  lt_rcv_po_dtl(i).item_num;
                                                       lt_po_details(ln_po_ix).line_quantity             :=  lt_rcv_po_dtl(i).quantity;
                                                       lt_po_details(ln_po_ix).line_unit_price           :=  lc_item_cost;
                                                       lt_po_details(ln_po_ix).line_ship_to_org_id       :=  lt_rcv_po_dtl(i).to_organization_id;
                                                       lt_po_details(ln_po_ix).rowid_reference           :=  lt_rcv_po_dtl(i).rowid;
                                                       lt_po_details(ln_po_ix).interface_header_id       :=  lt_rcv_po_dtl(i).header_interface_id;                                                  
                                                 
                                                 ELSE
                                                 
                                                     
                                                        
                                                        RESET_PROCESS_FLAG(
                                                                           p_index                       =>  i
                                                                          ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                                                          ,p_od_rcv_status_flag          => 'E'
                                                                          ,p_od_rvc_correction_flag      => 'N'
                                                                          ,p_error_message               => 'Item does not exist in masters for the item in RSL'
                                                                          ,p_error_status                =>  G_FAILED
                                                                          ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                                                          ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9); 
                                                                          
                                                                          
                                                   --Logging the error

                                                   FND_MESSAGE.SET_NAME('XXPTP','XX_GI_6009_ITEM_RSL');
                                                   FND_MESSAGE.SET_TOKEN('ITEMNUM',lt_rcv_po_dtl(i).item_num ); 

                                                   lc_err_code       := 'XX_GI_6009_ITEM_RSL';
                                                   lc_errbuf         :=  FND_MESSAGE.GET;      

                                                                                    
                                                 
                                                 END IF;
                                                 
                                              END LOOP;
                                  
                                                            
                                         END IF;                                         
                                     END IF;                                     
                               END IF;                               
                            END IF;                            
                    END IF;                    
                 END IF;
             END IF;             
          END IF;          
       EXCEPTION
          
       WHEN EX_TRANSACTION THEN
            
            
            lc_err_code       := 'XX_INV_6003_PROC_ERR';
            lc_errbuf         :=  FND_MESSAGE.GET;      
         
            LOG_ERROR(p_exception      =>lc_error_location
                     ,p_message        =>lc_errbuf
                     ,p_code           =>lc_err_code
                     ) ; 
                     
            RESET_PROCESS_FLAG(
                              p_index                       =>  i
                             ,p_rowid                       =>  lt_rcv_po_dtl(i).rowid
                             ,p_od_rcv_status_flag          => 'E'
                             ,p_od_rvc_correction_flag      => 'N'
                             ,p_error_message               =>  lc_message
                             ,p_error_status                =>  G_FAILED
                             ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num 
                             ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9); 
       WHEN OTHERS THEN
       
            
            lc_err_code       := 'XX_INV_6004_UNEXC_ERR';
            lc_errbuf         :=  FND_MESSAGE.GET;      
         
            LOG_ERROR(p_exception      =>lc_error_location
                     ,p_message        =>lc_errbuf
                     ,p_code           =>lc_err_code
                     ) ; 
                     
            RESET_PROCESS_FLAG(
                              p_index                       =>  i
                             ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                             ,p_od_rcv_status_flag          => 'E'
                             ,p_od_rvc_correction_flag      => 'N'
                             ,p_error_message               =>  SQLERRM
                             ,p_error_status                =>  G_FAILED
                             ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                             ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9
                             );        
       
       
       END;    
       END LOOP;
      
    END IF;  
    
    
   --Call the procedure to add line to PO
   -- display_log('XX_GI_MISSHIP_COMM_PKG.CREATE_PO_LINE');
   
    IF lt_po_details.COUNT <> 0 THEN
      
      
       XX_GI_MISSHIP_COMM_PKG.CREATE_PO_LINE (
                                             p_add_po_line_tbl   =>  lt_po_details
                                            ,x_return_status     =>  lc_message
                                            ,x_return_message    =>  lc_status
                                            );       
    
       FOR  i in lt_rcv_po_dtl.FIRST .. lt_rcv_po_dtl.LAST
       LOOP
          
            
           FOR j IN lt_po_details.FIRST .. lt_po_details.LAST
           LOOP
              
              
              IF lt_rcv_po_dtl(i).rowid = lt_po_details(j).rowid_reference THEN
                 
                 
                 IF lt_po_details(j).error_message IS NOT NULL THEN

                    
                    RESET_PROCESS_FLAG(
                                      p_index                       =>  i
                                     ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                     ,p_od_rcv_status_flag          => 'E'
                                     ,p_od_rvc_correction_flag      => 'N'
                                     ,p_error_message               =>  lt_po_details(j).error_message
                                     ,p_error_status                =>  G_FAILED
                                     ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num 
                                     ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9); 
                 
                 ELSE
                    
                    
                    RESET_PROCESS_FLAG(
                                        p_index                       => i
                                       ,p_rowid                       => lt_rcv_po_dtl(i).rowid
                                       ,p_od_rcv_status_flag          => 'PRCP'
                                       ,p_od_rvc_correction_flag      => 'Y'
                                       ,p_error_message               =>  NULL
                                       ,p_error_status                =>  G_SUCCESS
                                       ,p_item_num                    =>  lt_rcv_po_dtl(i).item_num
                                       ,p_attribute9                  =>  lt_rcv_po_dtl(i).attribute9);                  
        
                 END IF; 
              END IF;
           END LOOP;           
       END LOOP;       
    END IF;
    
    -----------------------------------------
     --Call the procedure to send notification
    -----------------------------------------
    
    IF gt_item_details.COUNT <> 0 THEN
    
        XX_GI_MISSHIP_COMM_PKG.SEND_NOTIFICATION (
                                                  p_item_details   => gt_item_details
                                                , x_return_status  => lc_message
                                                , x_return_message => lc_status
                                                 );
        NULL;                                         
        
    END IF;
    
     
     
     -----------------------------------------------------
     --Bulk update processing statuses for all the records
     -----------------------------------------------------
    
     FORALL i IN lt_rcv_po_dtl.FIRST .. lt_rcv_po_dtl.LAST
     UPDATE XX_GI_RCV_PO_DTL DTL
     SET       DTL.od_rcv_status_flag           =    gt_od_rcv_status_flag(i)   
             , DTL.od_rvc_correction_flag       =    gt_od_rvc_correction_flag(i)               
             , DTL.item_num                     =    gt_item_num(i)
             , DTL.attribute9                   =    gt_attribute9(i)
     WHERE     DTL.ROWID                        =    gt_rowid(i);
   

   
    --------------
    --Print Output
    --------------
    
    IF lt_rcv_po_dtl.COUNT <> 0
    THEN
       
       
       --Writing the Header of the File
           
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,  '-----------------------------------------------------------------------------------');
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,RPAD('Office Depo',70,' ')|| 'Date' || SYSDATE);
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,  '-----------------------------------------------------------------------------------');   
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,  '                                                                              ');          
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,LPAD('OD GI Receipts Validation' ,50,' '));
       
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,  '                                                                              ');    
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,  '                                                                              ');    
       
           
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,RPAD('Trans_id',15,' ')
                                           ||RPAD('PO Number',15,' ')
                                           ||RPAD('SKU',15,' ')
                                           ||RPAD('Qty',15,' ')
                                           ||RPAD('Processed',15,' ')
                                           ||RPAD('Failed reason if any',30,' '));
                                      
           
       --Open the table to print the detail part
           
       FOR i in lt_rcv_po_dtl.first.. lt_rcv_po_dtl.Last
       LOOP  
       
  
        --Writing the header
        
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,RPAD(lt_rcv_po_dtl(i).interface_transaction_id,15,' ') 
                                          || RPAD(NVL(lt_rcv_po_dtl(i).document_num,' '),15,' ')  
                                          || RPAD(NVL(lt_rcv_po_dtl(i).item_num,' '),15,' ')  
                                          || RPAD(NVL(TO_CHAR(lt_rcv_po_dtl(i).quantity),' '),15,' ') 
                                          || RPAD(NVL(gt_error_status(i),' '),15,' ')
                                          || RPAD(NVL(gt_error_message(i),' '),100,' ') 
                                            );               
                                          
                                       
       --Derive the number of error and successful records
              
          IF  gt_error_status(i) = G_SUCCESS  THEN 
          
              ln_success_record := ln_success_record+1;
              
          ELSIF gt_error_status(i) = G_FAILED  THEN 
          
              ln_errored_record := ln_errored_record+1; 
             
          END IF;
              
       END LOOP;  --Close the loop  
               
       --Writing the footer               
       ln_total_count :=  lt_rcv_po_dtl.COUNT;    

       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,  '                                                                              ');     
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,  '                                                                              ');     
              
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT , 'No of records processed        :  '||ln_total_count);
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT , 'No of records validation passed:  '||ln_success_record);
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT , 'No of records validation failed:  '||ln_errored_record);

       FND_FILE.PUT_LINE (FND_FILE.OUTPUT ,  '                                                                              ');     
       
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT , '*** End of Report - < OD GI Receipts Validation > ***');               


        
    ELSE
       
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'No errored records found in xx_gi_rcv_po_hdr and xx_gi_rcv_po_dtl tables' ); 
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '*** End of Report - < OD GI Receipts Validation > ***')                    ;
      
    END IF;


EXCEPTION

    WHEN EX_MISSING_SETUP THEN    
    
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Required setups are missing, Profile options are not configured OR Master Organization is not setup.');

       lc_err_code       := 'XX_INV_6005_MISS_SETUP';
       lc_errbuf         :=  FND_MESSAGE.GET;      

       LOG_ERROR(p_exception      =>lc_error_location
                ,p_message        =>lc_errbuf
                ,p_code           =>lc_err_code
                ) ; 
    
   
    WHEN OTHERS THEN
    
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Unhandled Exception in VALIDATE_SKU_ASN_PROC '||SQLERRM );

        lc_err_code       := 'XX_INV_6006_UNEX_ERR';
        lc_errbuf         :=  FND_MESSAGE.GET;      

        LOG_ERROR(p_exception      =>lc_error_location
                 ,p_message        =>lc_errbuf
                 ,p_code           =>lc_err_code
                 ) ; 

END  VALIDATE_SKU_RECPT_PROC;


END  XX_GI_MISSHIP_RECPT_PKG;
/
