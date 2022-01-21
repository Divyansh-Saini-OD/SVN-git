CREATE OR REPLACE PACKAGE BODY APPS.XX_GI_TRANSFER_PKG
--Version Draft 1.3
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_TRANSFER_PKG                                            |
-- |Purpose      : This package contains procedures that is used for lite version |
-- |                for the RICE ID E0341 Interorg transfers                     |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  16-JAN-2008   Ramesh Kurapati  Initial version                      |
-- +=============================================================================+
IS
   -- ----------------------------------------
   -- Global constants used for error handling
   -- ----------------------------------------
   G_PROG_NAME                     CONSTANT VARCHAR2(50)  := 'XX_GI_TRNSFR_PKG';
   G_MODULE_NAME                   CONSTANT VARCHAR2(50)  := 'INV';
   G_PROG_TYPE                     CONSTANT VARCHAR2(50)  := 'CUSTOM API';
   G_NOTIFY                        CONSTANT VARCHAR2(1)   := 'Y';
   G_MAJOR                         CONSTANT VARCHAR2(15)  := 'MAJOR';
   G_MINOR                         CONSTANT VARCHAR2(15)  := 'MINOR';
   G_989                           CONSTANT VARCHAR2(5)   := '-989';
   G_989_N                         CONSTANT PLS_INTEGER   := -989;
   G_APPL_PTP_SHORT_NAME           CONSTANT VARCHAR2(6)   := 'XXPTP';
   G_TIME_FORMAT                   CONSTANT VARCHAR2(10)  := 'hh:mi:ss';
   G_PGM_STRT_END_FORMAT           CONSTANT VARCHAR2(25)  := 'DD-Mon-RRRR '||G_TIME_FORMAT||' AM';
   G_SUCCESS                       CONSTANT VARCHAR2(1)   := 'S';
   G_VALIDATION_ERROR              CONSTANT VARCHAR2(1)   := 'E';
   G_UNEXPECTED_ERROR              CONSTANT VARCHAR2(1)   := 'U';
   G_UPDATE                        CONSTANT VARCHAR2(1)   := 'U';
   G_ADD                           CONSTANT VARCHAR2(1)   := 'A';
   G_DELETE                        CONSTANT VARCHAR2(1)   := 'D';
   G_INV_ITEM_STATUS               CONSTANT VARCHAR2(15)  := 'A';
   G_OPERATING_UNIT                CONSTANT VARCHAR2(10)  := 'org_id';
   
   G_SHIP_INITIATED_STATUS         CONSTANT VARCHAR2(20)  := 'SHIPPING-INITIATED';
   G_SHIPPED_STATUS                CONSTANT VARCHAR2(20)  := 'SHIPPED';
   G_INTERFACE_ERROR_FLAG          CONSTANT PLS_INTEGER   := 3;
   
   G_PROCEDURE_NAME                VARCHAR2(30);
   
   ------------------
   -- Other constants
   ------------------
   G_YES                                  CONSTANT VARCHAR2(1)   := 'Y';
   G_NO                                   CONSTANT VARCHAR2(1)   := 'N';
   G_PENDING_STATUS                       CONSTANT VARCHAR2(2) := 'PE';
   G_PARTIAL_STATUS                       CONSTANT VARCHAR2(2) := 'PP';
   G_ERROR_STATUS                         CONSTANT VARCHAR2(2) := 'EE';
   G_LOCKED_STATUS                        CONSTANT VARCHAR2(2) := 'LO';
   G_CLOSED_STATUS                        CONSTANT VARCHAR2(2) := 'CL';
   
   -------------------
   --Global exceptions
   -------------------
   EX_ON_HAND_QNTY_ERR             EXCEPTION;
   
   -- -----------------------
   -- Global scalar variables
   -- -----------------------
   gn_from_org_id                  hr_all_organization_units.organization_id%TYPE := NULL;
   gn_to_org_id                    hr_all_organization_units.organization_id%TYPE := NULL;
   gc_to_org_name                  hr_all_organization_units.name%TYPE := NULL;
   gc_to_org_code                  mtl_parameters.organization_code%TYPE;
   gc_from_org_name                hr_all_organization_units.name%TYPE := NULL;
   gc_from_org_code                mtl_parameters.organization_code%TYPE := NULL;
   gn_ship_to_location_id          mtl_material_transactions.ship_to_location_id%TYPE :=NULL;
   gn_transaction_type_id          xx_gi_transfer_headers.transaction_type_id%TYPE :=NULL;

  
   -- +====================================================================+
   -- | Name        :  display_out                                         |
   -- | Description :  This procedure is invoked to print in the out file  |
   -- |                                                                    |
   -- | Parameters  :  Output Message                                      |
   -- +====================================================================+
   PROCEDURE display_out(
                         p_message IN VARCHAR2
                        )
   IS
   BEGIN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
   END;


   -- +====================================================================+
   -- | Name        :  display_log                                         |
   -- | Description :  This procedure is invoked to print in the log file  |
   -- |                                                                    |
   -- | Parameters  :  Output Message                                      |
   -- +====================================================================+
   PROCEDURE display_log(
                         p_message IN VARCHAR2
                        )
   IS
   BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
   END;

   -- +==========================================================================================+
   -- | Name        :  GET_ON_HAND_QUANTITY                                                      |
   -- |                                                                                          |
   -- | Description :  This procedure gets the quantity on-hand of the given organization        |
   -- |                 item.                                                                    |
   -- |                 returns  NULL     => On error.                                           |
   -- |                 returns  quantity => On success.                                         |
   -- +==========================================================================================+
   FUNCTION GET_ON_HAND_QUANTITY(p_item_id       IN mtl_system_items_b.inventory_item_id%TYPE
                                ,p_org_id        IN hr_all_organization_units.organization_id%TYPE
                                ,x_error_message OUT NOCOPY VARCHAR2
                                )
   RETURN PLS_INTEGER
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
      ln_count         PLS_INTEGER := NULL;
      lc_ret_status    VARCHAR2(10) := NULL;
      lc_msg_data      VARCHAR2(500) := NULL;
      ln_qty_onhand    PLS_INTEGER := NULL;
      ln_rqoh          PLS_INTEGER := NULL;
      ln_qr            PLS_INTEGER := NULL;
      ln_qs            PLS_INTEGER := NULL;
      ln_att           PLS_INTEGER := NULL;
      ln_atr           PLS_INTEGER := NULL;
      lc_error_message VARCHAR2(500) := NULL;
      lc_msg_data_pub  VARCHAR2(500) := NULL;
      ln_msg_index_out PLS_INTEGER := NULL;

   BEGIN

      INV_QUANTITY_TREE_PUB.QUERY_QUANTITIES
                 (p_api_version_number  => 1.0
                 ,p_init_msg_lst        => FND_API.g_false
                 ,x_return_status       => lc_ret_status
                 ,x_msg_count           => ln_count
                 ,x_msg_data            => lc_msg_data
                 ,p_organization_id     => p_org_id
                 ,p_inventory_item_id   => p_item_id
                 ,p_tree_mode           => INV_QUANTITY_TREE_PVT.G_TRANSACTION_MODE
                 ,p_is_revision_control => FALSE
                 ,p_is_lot_control      => FALSE
                 ,p_is_serial_control   => TRUE
                 ,p_revision            => NULL
                 ,p_subinventory_code   => NULL
                 ,p_locator_id          => NULL
                 ,p_lot_number          => NULL
                 ,p_onhand_source       => INV_QUANTITY_TREE_PVT.G_ALL_SUBS
                 ,x_qoh                 => ln_qty_onhand
                 ,x_rqoh                => ln_rqoh
                 ,x_qr                  => ln_qr
                 ,x_qs                  => ln_qs
                 ,x_att                 => ln_att
                 ,x_atr                 => ln_atr
                 ,p_transfer_locator_id => NULL
                 );
      -------------------------
      --If more than one errors
      -------------------------
      IF (FND_MSG_PUB.COUNT_MSG > 1) THEN

          FOR j IN 1..FND_MSG_PUB.COUNT_MSG
          LOOP
             FND_MSG_PUB.GET(p_msg_index     => j,
                             p_encoded       => 'F',
                             p_data          => lc_msg_data_pub,
                             p_msg_index_out => ln_msg_index_out
                             );

             x_error_message := x_error_message||'. '||lc_msg_data_pub;
          END LOOP;
      ----------------
      --Only one error
      ----------------
      ELSE

         FND_MSG_PUB.GET(p_msg_index     => 1,
                         p_encoded       => 'F',
                         p_data          => lc_msg_data_pub,
                         p_msg_index_out => ln_msg_index_out
                         );
         x_error_message := lc_msg_data_pub;

      END IF;

      IF x_error_message IS NOT NULL THEN

         RAISE EX_ON_HAND_QNTY_ERR;

      END IF;

      RETURN ln_qty_onhand;

   END GET_ON_HAND_QUANTITY;

  -- +========================================================================+
  -- | Name        : valid_transaction_type_id                                |
  -- |                                                                        |
  -- | Description :                                                          |
  -- |                                                                        |
  -- |                                                                        |
  -- | Parameters  :                                                          |
  -- |                                                                        |
  -- +========================================================================+
   FUNCTION valid_transaction_type_id(p_legacy_trx      IN  VARCHAR2
                                     ,p_legacy_trx_type IN VARCHAR2
                                     ,p_trx_action      IN VARCHAR2
                                     ,x_trx_type_id     OUT PLS_INTEGER
                                     ,x_error_message   OUT VARCHAR2
                                     ) RETURN BOOLEAN
   IS
      l_return_status VARCHAR2(1);
      l_error_message VARCHAR2(2000);
      l_legacy_trx    VARCHAR2(4);
      l_legacy_trx_type    VARCHAR2(2);      
      l_trx_type_id   PLS_INTEGER;
      l_trx_action    VARCHAR2(10);
   BEGIN
      G_PROCEDURE_NAME := 'valid_transaction_type_id';

      l_legacy_trx      := p_legacy_trx;
      l_legacy_trx_type := p_legacy_trx_type;
      l_trx_action      := p_trx_action;

                                               
      XX_GI_COMN_UTILS_PKG.get_gi_trx_type_id ( p_legacy_trx =>l_legacy_trx
                               ,p_legacy_trx_type =>l_legacy_trx_type
                               ,p_trx_action  =>l_trx_action
                               ,x_trx_type_id =>l_trx_type_id
                               ,x_return_status =>l_return_status
                               ,x_error_message =>l_error_message
                         );
      IF l_return_status = fnd_api.g_ret_sts_success THEN
         DBMS_OUTPUT.PUT_LINE ( '>>valid_transaction_type_id<< EXIT');
         x_trx_type_id :=l_trx_type_id;
         x_error_message :=l_error_message;
         RETURN TRUE;
      ELSE
         l_trx_type_id := -1;
         DBMS_OUTPUT.PUT_LINE ( '>>valid_transaction_type_id<< EXIT');
         RETURN FALSE;
      END IF;


   EXCEPTION
      WHEN OTHERS
      THEN
         l_trx_type_id := -1;
         l_return_status := fnd_api.g_ret_sts_error;
         DBMS_OUTPUT.put_line (SQLERRM);
         RETURN FALSE;
   END valid_transaction_type_id;

  -- +========================================================================+
  -- | Name        : Validate_Header Procedure                                |
  -- |                                                                        |
  -- | Description : To validate the transfer header                          |
  -- |                                                                        |
  -- |                                                                        |
  -- | Parameters  :                                                          |
  -- |                                                                        |
  -- +========================================================================+

   
   PROCEDURE VALIDATE_HEADER
                        ( 
                          p_in_hdr_rec IN xx_gi_transfer_headers%ROWTYPE                         
                         ,x_out_hdr_rec   OUT NOCOPY xx_gi_xfer_out_hdr_type                         
                         ,x_return_status OUT NOCOPY VARCHAR2
                         ,x_error_message OUT NOCOPY VARCHAR2)
   IS
   
 
      ln_vendor_id                    PLS_INTEGER;
      ln_vendor_site_id               PLS_INTEGER;
      lc_return_status                VARCHAR2(10) := NULL;
      lc_return_message               VARCHAR2(500) := NULL;
      lc_error_flag                   VARCHAR2(1) := NULL;
      
            
      --lt_line_in_dtl xx_gi_xfer_in_line_tbl_type := xx_gi_xfer_in_line_tbl_type();

      lc_currency_code             VARCHAR2(15)  := NULL;
      lc_trx_action                VARCHAR2(30)  := 'Intransit';      
      lc_transfer_exists           VARCHAR2(1) := NULL;      
      lc_check_dup_transfer        VARCHAR2(1) := 'N'; -- Need to handle in future
      
      lc_trans_type_cd             xx_gi_transfer_headers.trans_type_cd%TYPE := NULL;
      ln_header_id                 xx_gi_transfer_headers.header_id%TYPE := NULL;
      lc_doc_type_cd               xx_gi_transfer_headers.doc_type_cd%TYPE := NULL;
      lc_source_subinv_cd          xx_gi_transfer_headers.source_subinv_cd%TYPE :=NULL;
      lc_ebs_subinventory_code     xx_gi_transfer_lines.ebs_subinventory_code%TYPE :=NULL;

      lc_hdr_status                 xx_gi_transfer_headers.status%TYPE := G_PENDING_STATUS;
      lc_hdr_err_code               xx_gi_transfer_headers.error_code%TYPE;
      lc_hdr_err_msg                xx_gi_transfer_headers.error_message%TYPE;
      
      lb_header_has_error           BOOLEAN := FALSE;
     
      ------------------------------------------------
      --Cursor to check if from organization is active
      ------------------------------------------------
            
      CURSOR lcu_is_from_org_active(p_from_loc_nbr IN VARCHAR2)
      IS 
      SELECT HAOU.organization_id
            ,mp.organization_code
            ,HAOU.name
      FROM   hr_all_organization_units HAOU
            ,mtl_parameters mp
      WHERE  haou.organization_id = mp.organization_id 
      AND    HAOU.attribute1 =p_from_loc_nbr
      AND    SYSDATE BETWEEN NVL(HAOU.date_from,SYSDATE-1) AND NVL(HAOU.date_to,SYSDATE+1)
      ;
      
            
      CURSOR lcu_is_to_org_active(p_to_loc_nbr IN VARCHAR2)
      IS
      SELECT haou.organization_id
             ,mp.organization_code
             ,haou.name
             ,haou.location_id
      FROM hr_all_organization_units haou
            ,hr_organization_information hoi
            ,mtl_parameters mp
      WHERE  haou.organization_id=hoi.organization_id
      AND    haou.organization_id = mp.organization_id
      AND    hoi.org_information_context = 'CLASS'
      AND    hoi.org_information1        = 'INV'
      AND    hoi.org_information2        = 'Y'
      AND    haou.attribute1             = p_to_loc_nbr
      AND    SYSDATE BETWEEN NVL(haou.date_from,SYSDATE-1) AND NVL(haou.date_to,SYSDATE+1)
      ;

      
      
      CURSOR lcu_transfer_number_exists (p_transfer_number in VARCHAR2
                                        ,p_from_loc_nbr IN VARCHAR2
                                        ,p_source_code IN VARCHAR2)
      IS
      SELECT 'Y'
      FROM   mtl_material_transactions mmt
      WHERE  mmt.attribute5 IS NOT NULL
      AND    mmt.source_code = 'XX_GI_XFER_'||p_source_code
      AND    mmt.attribute5 = p_transfer_number
      AND    mmt.attribute1 = p_from_loc_nbr      
      UNION
      SELECT 'Y'
      FROM   xx_gi_transfer_headers xgth
      WHERE  xgth.transfer_number = p_transfer_number
      AND    xgth.source_system = p_source_code
      AND    xgth.from_loc_nbr = p_from_loc_nbr      
      ;
      

   BEGIN
    
    display_log('------------------------');
    display_log('Starting validate_header');
    display_log('------------------------');
    
    DBMS_OUTPUT.PUT_LINE('------------------------');
    DBMS_OUTPUT.PUT_LINE('Starting Validate_Header');
    DBMS_OUTPUT.PUT_LINE('------------------------');
      
      x_out_hdr_rec := xx_gi_xfer_out_hdr_type();
      gn_from_org_id              := NULL;
      --lt_line_in_dtl           := p_in_line_tbl;
      lc_error_flag              := G_NO;
      --x_out_line_tbl := xx_gi_xfer_out_line_tbl_type();
      lc_trans_type_cd           := p_in_hdr_rec.trans_type_cd;
      lc_doc_type_cd             := p_in_hdr_rec.doc_type_cd;
      
      x_return_status := G_SUCCESS;
      
      -- Check mandatory columns are NULL or not
      
      IF p_in_hdr_rec.source_system IS NULL 
        
        THEN
         DBMS_OUTPUT.PUT_LINE('Source System NULL');
         x_return_status    :=  G_VALIDATION_ERROR;
         lc_hdr_status      :=  G_ERROR_STATUS;
         lc_hdr_err_code    := 'XX_GI_XFER_HDR_SOURCE_NULL';
         lc_hdr_err_msg     := 'Source System NULL';
         x_error_message    := 'Source System NULL';
         lb_header_has_error:= TRUE;
                            
         ELSIF p_in_hdr_rec.transfer_number IS NULL
         
         THEN
         
         DBMS_OUTPUT.PUT_LINE('Transfer Number NULL');
         x_return_status    :=  G_VALIDATION_ERROR;
         lc_hdr_status      :=  G_ERROR_STATUS;
         lc_hdr_err_code    := 'XX_GI_XFER_HDR_TRFR_NBR_NULL';
         lc_hdr_err_msg     := 'Transfer Number NULL';         
         x_error_message    :='Transfer Number NULL';
         lb_header_has_error:= TRUE;
         
         ELSIF p_in_hdr_rec.from_loc_nbr IS NULL
         
         THEN
         
         DBMS_OUTPUT.PUT_LINE('From Loc ID NULL');         
         x_return_status    :=  G_VALIDATION_ERROR;
         lc_hdr_status      :=  G_ERROR_STATUS;
         lc_hdr_err_code    :='XX_GI_XFER_HDR_FRM_LOC_ID_NULL';
         lc_hdr_err_msg     :=  'From Loc Id NULL';        
         x_error_message    := 'From Loc Id NULL';
         lb_header_has_error := TRUE;
         
         ELSIF p_in_hdr_rec.to_loc_nbr IS NULL
         THEN
         
         DBMS_OUTPUT.PUT_LINE('To Loc Id NULL');         
         x_return_status    := G_VALIDATION_ERROR;
         lc_hdr_status      :=   G_ERROR_STATUS;
         lc_hdr_err_code    := 'XX_GI_XFER_HDR_TO_LOC_ID_NULL';
         lc_hdr_err_msg     :=  'To Loc Id NULL';         
         x_error_message    := 'To Loc Id NULL';
         lb_header_has_error:= TRUE;
         
         ELSIF p_in_hdr_rec.trans_type_cd IS NULL
         THEN
         
         DBMS_OUTPUT.PUT_LINE('Trans Type Cd NULL');
         x_return_status    :=  G_VALIDATION_ERROR;
         lc_hdr_status      :=  G_ERROR_STATUS;
         lc_hdr_err_code    :=  'XX_GI_XFER_HDR_TRAN_CODE_NULL';
         lc_hdr_err_msg     :=  'Transaction Type CD NULL';
         x_error_message    :=  'Transaction Type CD NULL';
         lb_header_has_error:=  TRUE;
         
         ELSIF p_in_hdr_rec.trans_type_cd NOT IN ('OHWR','STIR','RVST')
         THEN
         
         DBMS_OUTPUT.PUT_LINE('Invalid Trans Type CD');
         x_return_status    := G_VALIDATION_ERROR;
         lc_hdr_status      :=   G_ERROR_STATUS;
         lc_hdr_err_code    := 'XX_GI_XFER_HDR_INVLD_TRAN_CODE';
         lc_hdr_err_msg     :=  'Invalid Transaction Type Code';
         x_error_message    :=    'Invalid Transaction Type Code';
         lb_header_has_error:= TRUE;
         
         
         ELSIF p_in_hdr_rec.doc_type_cd IS NULL
         THEN
         
         DBMS_OUTPUT.PUT_LINE('Doc Type CD NULL');
         x_return_status    :=  G_VALIDATION_ERROR;
         lc_hdr_status      :=  G_ERROR_STATUS;
         lc_hdr_err_code    :=  'XX_GI_XFER_HDR_DOC_TYP_CD_NULL';
         lc_hdr_err_msg     :=  'Doc Type Code NULL';
         x_error_message    :=  'Doc Type Code NULL';
         lb_header_has_error:=  TRUE;
         
         ELSIF p_in_hdr_rec.source_creation_date IS NULL
         THEN
         
         DBMS_OUTPUT.PUT_LINE('Source Creation Date NULL');
         x_return_status    :=  G_VALIDATION_ERROR;
         lc_hdr_status      :=  G_ERROR_STATUS;
         lc_hdr_err_code    :=  'XX_GI_XFER_HDR_SRC_CRE_DT_NULL';
         lc_hdr_err_msg     :=  'Source Creation Date NULL';
         x_error_message    :=  'Source Creation Date NULL';
         lb_header_has_error:=TRUE;
         
         ELSIF p_in_hdr_rec.ship_date IS NULL
         THEN
         
         DBMS_OUTPUT.PUT_LINE('Ship Date NULL');
         x_return_status    :=  G_VALIDATION_ERROR;
         lc_hdr_status      :=  G_ERROR_STATUS;
         lc_hdr_err_code    :=  'XX_GI_XFER_HDR_SHIP_DT_NULL';
         lc_hdr_err_msg     :=  'Ship Date NULL';
         x_error_message    :=  'Ship Date NULL';
         lb_header_has_error:=  TRUE;
         
      END IF;
      
         DBMS_OUTPUT.PUT_LINE('In validate_header lc_hdr_status -'||lc_hdr_status);
         DBMS_OUTPUT.PUT_LINE('In validate_header lc_hdr_err_code -'||lc_hdr_err_code);
         DBMS_OUTPUT.PUT_LINE('In validate_header lc_hdr_err_msg -'||lc_hdr_err_msg);
      
      
      
      --IF lc_hdr_status = G_ERROR_STATUS THEN
      
      IF lb_header_has_error THEN
      
          -- If header has errors then set the input values
             
            x_out_hdr_rec.EXTEND;
      
           DBMS_OUTPUT.PUT_LINE('In validate_header before setting input header values');
           display_log('In validate_header before setting input header values');
           
           --x_out_hdr_rec(x_out_hdr_rec.LAST).header_id :=p_in_hdr_rec.header_id;
           
           IF p_in_hdr_rec.header_id IS NOT NULL THEN
            
            x_out_hdr_rec(x_out_hdr_rec.LAST).header_id :=p_in_hdr_rec.header_id;
            
            ELSE
            
                SELECT XX_GI_TRANSFER_HEADERS_S.NEXTVAL
                INTO
                ln_header_id
                FROM DUAL;            
            
            x_out_hdr_rec(x_out_hdr_rec.LAST).header_id := ln_header_id;
            
            END IF;
            
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_system :=p_in_hdr_rec.source_system;
           x_out_hdr_rec(x_out_hdr_rec.LAST).transfer_number := p_in_hdr_rec.transfer_number;
           x_out_hdr_rec(x_out_hdr_rec.LAST).from_loc_nbr := p_in_hdr_rec.from_loc_nbr;  
           x_out_hdr_rec(x_out_hdr_rec.LAST).to_loc_nbr := p_in_hdr_rec.to_loc_nbr;
           x_out_hdr_rec(x_out_hdr_rec.LAST).trans_type_cd := p_in_hdr_rec.trans_type_cd;
           x_out_hdr_rec(x_out_hdr_rec.LAST).doc_type_cd := p_in_hdr_rec.doc_type_cd;
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_creation_date := p_in_hdr_rec.source_creation_date;
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_created_by :=p_in_hdr_rec.source_created_by;
           x_out_hdr_rec(x_out_hdr_rec.LAST).buyback_number := p_in_hdr_rec.buyback_number;
           x_out_hdr_rec(x_out_hdr_rec.LAST).carton_count := p_in_hdr_rec.carton_count;
           x_out_hdr_rec(x_out_hdr_rec.LAST).transfer_cost := p_in_hdr_rec.transfer_cost;
           x_out_hdr_rec(x_out_hdr_rec.LAST).ship_date := p_in_hdr_rec.ship_date;
           x_out_hdr_rec(x_out_hdr_rec.LAST).shipped_qty := p_in_hdr_rec.shipped_qty;           
           x_out_hdr_rec(x_out_hdr_rec.LAST).status := G_ERROR_STATUS;
           x_out_hdr_rec(x_out_hdr_rec.LAST).comments := p_in_hdr_rec.comments;
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_subinv_cd := p_in_hdr_rec.source_subinv_cd;
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_vendor_id := p_in_hdr_rec.source_vendor_id;
           x_out_hdr_rec(x_out_hdr_rec.LAST).error_code :=lc_hdr_err_code;
           x_out_hdr_rec(x_out_hdr_rec.LAST).error_message :=lc_hdr_err_msg;
            
           DBMS_OUTPUT.PUT_LINE('In validate_header after setting input header values');
           
        ELSE
        
        -- If header contain all mandatory values

        DBMS_OUTPUT.PUT_LINE('In validate_header starting validations and derivations part1');
        display_log('In validate_header starting validations and derivations part1');
        
           --lc_hdr_status := G_PENDING_STATUS;
        
            --IF lc_hdr_status <> G_ERROR_STATUS THEN 
            
              IF NOT lb_header_has_error THEN
            
               IF lc_check_dup_transfer = 'Y' THEN     
        
                -- Check duplicate transer number
        
                OPEN lcu_transfer_number_exists(
                p_in_hdr_rec.transfer_number
                ,p_in_hdr_rec.from_loc_nbr
                ,p_in_hdr_rec.source_system
                    );

                FETCH lcu_transfer_number_exists INTO lc_transfer_exists;
      
                CLOSE  lcu_transfer_number_exists;
      
                    IF lc_transfer_exists = 'Y' THEN
                     
                    x_return_status :=  G_VALIDATION_ERROR;
                    lc_hdr_status   :=  G_ERROR_STATUS;
                    lc_hdr_err_code :=  'XX_GI_XFER_HDR_DUP_TRFR_NBR';
                    lc_hdr_err_msg  :=  'Duplicate Transfer Number';
                    x_error_message :=  'Duplicate Transfer Number';
                    lb_header_has_error:=   TRUE;
                  
                     END IF;
                     
                END IF;     
            END IF;         
      
            --IF lc_hdr_status <> G_ERROR_STATUS THEN
            IF NOT lb_header_has_error THEN
      
            
            -- Check from organization is active
            
      
            OPEN lcu_is_from_org_active(p_in_hdr_rec.from_loc_nbr);
            FETCH lcu_is_from_org_active INTO gn_from_org_id,gc_from_org_code,gc_from_org_name;
      
            CLOSE lcu_is_from_org_active;

              IF gn_from_org_id IS NULL THEN

                x_return_status     :=  G_VALIDATION_ERROR;
                lc_hdr_status       :=  G_ERROR_STATUS;
                lc_hdr_err_code     :=  'XX_GI_XFER_HDR_FROM_ORG_ID';
                lc_hdr_err_msg      :=  'Invalid From Org ID';
                x_error_message     :=  'Invalid From Org ID';
                lb_header_has_error :=TRUE;
          
               END IF;
               
            END IF;

      
            -- Initialize to org id      
            gn_to_org_id := NULL;
            
            --IF lc_hdr_status <> G_ERROR_STATUS THEN
            IF NOT lb_header_has_error THEN
      
                
                DBMS_OUTPUT.PUT_LINE('In validate_header starting validations and derivations part2');
                display_log('In validate_header starting validations and derivations part2');
                
                -------------------------------------
                -- Check if to organization is active
                -------------------------------------
                
                OPEN lcu_is_to_org_active(p_in_hdr_rec.to_loc_nbr);
      
                FETCH lcu_is_to_org_active INTO gn_to_org_id,gc_to_org_code,gc_to_org_name,gn_ship_to_location_id;
                CLOSE lcu_is_to_org_active;

                
                IF gn_to_org_id IS NULL THEN
         
                    x_return_status     :=G_VALIDATION_ERROR;
                    lc_hdr_status       :=    G_ERROR_STATUS;
                    lc_hdr_err_code     :='XX_GI_XFER_HDR_TO_ORG_ID';
                    lc_hdr_err_msg      :='Invalid To Org ID';
                    x_error_message     := 'Invalid To Org ID';
                    lb_header_has_error :=  TRUE;
         
                    --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62704_INVLD_ORG');
                    --FND_MESSAGE.SET_TOKEN('ORGTYPE','receiving');
                    --x_error_message := FND_MESSAGE.GET;

                END IF;
            
            END IF;
      
      
      
                DBMS_OUTPUT.PUT_LINE('In validate_header before calling common util to get trx_type_id');
                display_log('In validate_header before calling common util to get trx_type_id');
            
            --IF lc_hdr_status <> G_ERROR_STATUS THEN      
            
            IF NOT lb_header_has_error THEN

                XX_GI_COMN_UTILS_PKG.get_gi_trx_type_id ( p_legacy_trx =>p_in_hdr_rec.trans_type_cd
                               ,p_legacy_trx_type =>p_in_hdr_rec.doc_type_cd
                               ,p_trx_action  =>lc_trx_action --'Intransit'
                               ,x_trx_type_id =>gn_transaction_type_id
                               ,x_return_status =>lc_return_status
                               ,x_error_message =>lc_return_message
                         );
                         
                DBMS_OUTPUT.PUT_LINE('In validate_header after calling common util to get trx_type_id');
                display_log('In validate_header after calling common util to get trx_type_id');
                         
                         IF lc_return_status <> G_SUCCESS THEN

                             x_return_status    :=  G_VALIDATION_ERROR;
                             lc_hdr_status      :=  G_ERROR_STATUS;
                             lc_hdr_err_code    :=  'XX_GI_XFER_HDR_TRAN_TYPE_ID';
                             lc_hdr_err_msg     :=  'Invalid Transation Type Id';         
                             x_error_message    :=  'Invalid Transaction Type Id';
                             lb_header_has_error:=TRUE;

                         END IF;
                         
             END IF;
                         
                         
                         --DBMS_OUTPUT.PUT_LINE('After IF - After calling common in validate_header');                         
                         --DBMS_OUTPUT.PUT_LINE('Header status'||lc_hdr_status);                         
                         --DBMS_OUTPUT.PUT_LINE('Header err code'||lc_hdr_err_code);                         
                         --DBMS_OUTPUT.PUT_LINE('Header err msg'||lc_hdr_err_msg);
          
        
          --IF lc_hdr_status <> G_ERROR_STATUS THEN               
          IF NOT lb_header_has_error THEN
            x_out_hdr_rec.EXTEND;
           
            DBMS_OUTPUT.PUT_LINE('In validate_header before set hdr values after successful derivations');
            display_log('In validate_header before set hdr values after successful derivations');
           
            IF p_in_hdr_rec.header_id IS NOT NULL THEN            
                x_out_hdr_rec(x_out_hdr_rec.LAST).header_id :=p_in_hdr_rec.header_id;            
            ELSE            
                SELECT XX_GI_TRANSFER_HEADERS_S.NEXTVAL
                INTO
                ln_header_id
                FROM DUAL;
            x_out_hdr_rec(x_out_hdr_rec.LAST).header_id := ln_header_id;            
            END IF;
            
            x_out_hdr_rec(x_out_hdr_rec.LAST).source_system :=p_in_hdr_rec.source_system;
            x_out_hdr_rec(x_out_hdr_rec.LAST).transfer_number := p_in_hdr_rec.transfer_number;
            x_out_hdr_rec(x_out_hdr_rec.LAST).from_loc_nbr := p_in_hdr_rec.from_loc_nbr;         
            x_out_hdr_rec(x_out_hdr_rec.LAST).from_org_id :=  gn_from_org_id; 
            x_out_hdr_rec(x_out_hdr_rec.LAST).from_org_code :=gc_from_org_code;
            x_out_hdr_rec(x_out_hdr_rec.LAST).from_org_name :=gc_from_org_name;
            x_out_hdr_rec(x_out_hdr_rec.LAST).to_loc_nbr := p_in_hdr_rec.to_loc_nbr;
            x_out_hdr_rec(x_out_hdr_rec.LAST).to_org_id := gn_to_org_id;
            x_out_hdr_rec(x_out_hdr_rec.LAST).to_org_code := gc_to_org_code;
            x_out_hdr_rec(x_out_hdr_rec.LAST).to_org_name := gc_to_org_name;            
            x_out_hdr_rec(x_out_hdr_rec.LAST).ship_to_location_id := gn_ship_to_location_id;
            x_out_hdr_rec(x_out_hdr_rec.LAST).trans_type_cd := p_in_hdr_rec.trans_type_cd;
            x_out_hdr_rec(x_out_hdr_rec.LAST).transaction_type_id := gn_transaction_type_id;
            x_out_hdr_rec(x_out_hdr_rec.LAST).doc_type_cd := p_in_hdr_rec.doc_type_cd;
            x_out_hdr_rec(x_out_hdr_rec.LAST).source_creation_date := p_in_hdr_rec.source_creation_date;
            x_out_hdr_rec(x_out_hdr_rec.LAST).source_created_by :=p_in_hdr_rec.source_created_by;
            x_out_hdr_rec(x_out_hdr_rec.LAST).buyback_number := p_in_hdr_rec.buyback_number;
            x_out_hdr_rec(x_out_hdr_rec.LAST).carton_count := p_in_hdr_rec.carton_count;
            x_out_hdr_rec(x_out_hdr_rec.LAST).transfer_cost := p_in_hdr_rec.transfer_cost;
            x_out_hdr_rec(x_out_hdr_rec.LAST).ship_date := p_in_hdr_rec.ship_date;
            x_out_hdr_rec(x_out_hdr_rec.LAST).shipped_qty := p_in_hdr_rec.shipped_qty;
            
           
            IF lc_hdr_status IS NULL THEN           
                x_out_hdr_rec(x_out_hdr_rec.LAST).status := G_PENDING_STATUS;
            ELSE
                x_out_hdr_rec(x_out_hdr_rec.LAST).status := lc_hdr_status;
            END IF;
            
            x_out_hdr_rec(x_out_hdr_rec.LAST).rcv_shipment_header_id := NULL;
            x_out_hdr_rec(x_out_hdr_rec.LAST).transaction_date := SYSDATE;
            x_out_hdr_rec(x_out_hdr_rec.LAST).comments := p_in_hdr_rec.comments;
            x_out_hdr_rec(x_out_hdr_rec.LAST).created_by := FND_GLOBAL.USER_ID;
            x_out_hdr_rec(x_out_hdr_rec.LAST).creation_date := SYSDATE;
            x_out_hdr_rec(x_out_hdr_rec.LAST).last_updated_by := FND_GLOBAL.USER_ID;
            x_out_hdr_rec(x_out_hdr_rec.LAST).last_update_date := SYSDATE;
            x_out_hdr_rec(x_out_hdr_rec.LAST).last_update_login := FND_GLOBAL.LOGIN_ID;
            --DBMS_OUTPUT.PUT_LINE('Before set hdr values -3 in validate_header');
            x_out_hdr_rec(x_out_hdr_rec.LAST).source_subinv_cd := p_in_hdr_rec.source_subinv_cd;
            x_out_hdr_rec(x_out_hdr_rec.LAST).source_vendor_id := p_in_hdr_rec.source_vendor_id;
            x_out_hdr_rec(x_out_hdr_rec.LAST).no_of_detail_lines := NULL;         
            x_out_hdr_rec(x_out_hdr_rec.LAST).error_code :=lc_hdr_err_code;
            x_out_hdr_rec(x_out_hdr_rec.LAST).error_message :=lc_hdr_err_msg;           
            --DBMS_OUTPUT.PUT_LINE('Before set hdr values -4 in validate_header');           
            lc_trans_type_cd := p_in_hdr_rec.trans_type_cd;
            lc_source_subinv_cd := p_in_hdr_rec.source_subinv_cd;           
        
            DBMS_OUTPUT.PUT_LINE('In validate_header after set hdr values after derivations');
            display_log('In validate_header after set hdr values after derivations');
        
           
           ELSE
           
            DBMS_OUTPUT.PUT_LINE('In validate_header before set hdr values after failed derivations');
            display_log('In validate_header before set hdr values after failed derivations');

           
            x_out_hdr_rec.EXTEND;
           
            IF p_in_hdr_rec.header_id IS NOT NULL THEN
                x_out_hdr_rec(x_out_hdr_rec.LAST).header_id :=p_in_hdr_rec.header_id;
                ELSE
                    SELECT XX_GI_TRANSFER_HEADERS_S.NEXTVAL
                    INTO
                    ln_header_id
                    FROM DUAL;            
                x_out_hdr_rec(x_out_hdr_rec.LAST).header_id := ln_header_id;
            END IF;
            
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_system :=p_in_hdr_rec.source_system;
           x_out_hdr_rec(x_out_hdr_rec.LAST).transfer_number := p_in_hdr_rec.transfer_number;
           x_out_hdr_rec(x_out_hdr_rec.LAST).from_loc_nbr := p_in_hdr_rec.from_loc_nbr;  
           x_out_hdr_rec(x_out_hdr_rec.LAST).to_loc_nbr := p_in_hdr_rec.to_loc_nbr;
           x_out_hdr_rec(x_out_hdr_rec.LAST).trans_type_cd := p_in_hdr_rec.trans_type_cd;
           x_out_hdr_rec(x_out_hdr_rec.LAST).doc_type_cd := p_in_hdr_rec.doc_type_cd;
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_creation_date := p_in_hdr_rec.source_creation_date;
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_created_by :=p_in_hdr_rec.source_created_by;
           x_out_hdr_rec(x_out_hdr_rec.LAST).buyback_number := p_in_hdr_rec.buyback_number;
           x_out_hdr_rec(x_out_hdr_rec.LAST).carton_count := p_in_hdr_rec.carton_count;
           x_out_hdr_rec(x_out_hdr_rec.LAST).transfer_cost := p_in_hdr_rec.transfer_cost;
           x_out_hdr_rec(x_out_hdr_rec.LAST).ship_date := p_in_hdr_rec.ship_date;
           x_out_hdr_rec(x_out_hdr_rec.LAST).shipped_qty := p_in_hdr_rec.shipped_qty;           
           x_out_hdr_rec(x_out_hdr_rec.LAST).status := G_ERROR_STATUS;
           x_out_hdr_rec(x_out_hdr_rec.LAST).comments := p_in_hdr_rec.comments;
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_subinv_cd := p_in_hdr_rec.source_subinv_cd;
           x_out_hdr_rec(x_out_hdr_rec.LAST).source_vendor_id := p_in_hdr_rec.source_vendor_id;
           x_out_hdr_rec(x_out_hdr_rec.LAST).error_code :=lc_hdr_err_code;
           x_out_hdr_rec(x_out_hdr_rec.LAST).error_message :=lc_hdr_err_msg;
            
            DBMS_OUTPUT.PUT_LINE('In validate_header after set hdr values after failed derivations');
            display_log('In validate_header after set hdr values after failed derivations');

           
           END IF;
        
       END IF;
          
 
END VALIDATE_HEADER;


  -- +========================================================================+
  -- | Name        : Validate_Lines Procedure                                 |
  -- |                                                                        |
  -- | Description : To validate the transfer lines for a given header        |
  -- |                                                                        |
  -- |                                                                        |
  -- | Parameters  :                                                          |
  -- |                                                                        |
  -- +========================================================================+

PROCEDURE VALIDATE_LINES
                        ( 
                          --p_in_hdr_rec IN xx_gi_transfer_headers%ROWTYPE
                          p_in_hdr_rec    IN xx_gi_xfer_out_hdr_type
                         ,p_in_line_tbl   IN         xx_gi_xfer_in_line_tbl_type                         
                         ,x_out_line_tbl  OUT NOCOPY xx_gi_xfer_out_line_tbl_type
                         ,x_return_status OUT NOCOPY VARCHAR2
                         ,x_error_message OUT NOCOPY VARCHAR2)
   IS
     
      lc_item                         mtl_system_items_b.segment1%TYPE := NULL;
      ln_line_id                      xx_gi_transfer_lines.line_id%TYPE := NULL;
      ln_header_id                    xx_gi_transfer_headers.header_id%TYPE := NULL;
      lc_shipped_qty                  xx_gi_transfer_lines.shipped_qty%TYPE := NULL;
      lc_requested_qty                xx_gi_transfer_lines.requested_qty%TYPE :=NULL;
      
      lc_from_loc_nbr                 xx_gi_transfer_headers.from_loc_nbr%TYPE := NULL;
      ln_from_org_item_id             mtl_system_items_b.inventory_item_id%TYPE := NULL;
      lc_from_org_item_desc           mtl_system_items_b.description%TYPE := NULL;
      lc_from_org_uom_code            mtl_system_items_b.primary_uom_code%TYPE := NULL;
      ln_from_org_item_cost_group_id  mtl_parameters.default_cost_group_id%TYPE := NULL;
      ln_from_org_item_unit_cost      PLS_INTEGER        := NULL;
      ln_from_org_id                  xx_gi_transfer_headers.from_org_id%TYPE := NULL;
      
      ln_to_org_item_id               mtl_system_items_b.inventory_item_id%TYPE := NULL;
      ln_to_org_id                    xx_gi_transfer_headers.to_org_id%TYPE := NULL;
      lc_to_org_item_desc             mtl_system_items_b.description%TYPE := NULL;
      lc_to_org_uom_code              mtl_system_items_b.primary_uom_code%TYPE := NULL;
      ln_to_org_item_cost_group_id    mtl_parameters.default_cost_group_id%TYPE := NULL;
      ln_to_org_item_unit_cost        PLS_INTEGER        := NULL;
      
      --lc_description                  mtl_system_items_b.description%TYPE := NULL;
      lc_to_consignment_flag          VARCHAR2(2) := NULL;
      lc_from_consignment_flag        VARCHAR2(2) := NULL;
      ln_vendor_id                    PLS_INTEGER;
      ln_vendor_site_id               PLS_INTEGER;
      lc_return_status                VARCHAR2(10) := NULL;
      lc_return_message               VARCHAR2(500) := NULL;
      lc_error_flag                   VARCHAR2(1) := NULL;
      ln_qty_onhand                   PLS_INTEGER := NULL;
      --lc_uom_code                     mtl_system_items_b.primary_uom_code%TYPE := NULL;
      ln_cost_group_id                mtl_parameters.default_cost_group_id%TYPE := NULL;
      
      lt_line_in_dtl xx_gi_xfer_in_line_tbl_type := xx_gi_xfer_in_line_tbl_type();      
      lt_hdr_in_rec xx_gi_xfer_out_hdr_type := xx_gi_xfer_out_hdr_type();
      
      lc_on_hand_qnty_err             VARCHAR2(500) := NULL;
      --ln_unit_cost                    PLS_INTEGER        := NULL;
      lc_currency_code                VARCHAR2(15)  := NULL;
      lc_trx_action                   VARCHAR2(30)  := 'Intransit';
      
      lc_transfer_exists           VARCHAR2(1) := NULL;      
      lc_trans_type_cd             xx_gi_transfer_headers.trans_type_cd%TYPE := NULL;
      lc_doc_type_cd               xx_gi_transfer_headers.doc_type_cd%TYPE := NULL;
      lc_source_subinv_cd          xx_gi_transfer_headers.source_subinv_cd%TYPE :=NULL;
      lc_ebs_subinventory_code     xx_gi_transfer_lines.ebs_subinventory_code%TYPE :=NULL;

      lc_hdr_status      xx_gi_transfer_headers.status%TYPE := NULL;
      lc_hdr_err_code    xx_gi_transfer_headers.error_code%TYPE;
      lc_hdr_err_msg     xx_gi_transfer_headers.error_message%TYPE;
      
      
      lc_line_status     xx_gi_transfer_lines.status%TYPE := NULL;
      lc_line_err_code   xx_gi_transfer_lines.error_code%TYPE := NULL;
      lc_line_err_msg    xx_gi_transfer_lines.error_message%TYPE := NULL;

      lb_line_has_error BOOLEAN := FALSE;
   
   
      ---------------------------------------
      -- Cursor to check item is transactable
      ---------------------------------------
      
      CURSOR lcu_is_item_transactable(p_item   IN mtl_system_items_b.segment1%TYPE
                                     ,p_org_id IN hr_all_organization_units.organization_id%TYPE
                                     )
      IS
      SELECT MSI.inventory_item_id
            ,MSI.description
            ,MSI.primary_uom_code
            ,MP.default_cost_group_id
      FROM   mtl_system_items_b MSI
            ,mtl_parameters     MP
      WHERE  MSI.segment1                      = p_item
      AND    MSI.mtl_transactions_enabled_flag = G_YES
      AND    MSI.organization_id               = p_org_id
      AND    MP.organization_id                = MSI.organization_id
      AND    MSI.enabled_flag                  = G_YES
      AND    MSI.inventory_item_status_code    = G_INV_ITEM_STATUS
      AND    SYSDATE BETWEEN NVL (MSI.start_date_active,SYSDATE-1) AND NVL(MSI.end_date_active,SYSDATE)
      ;
      
      
      ---------------------------------------------------------
      -- Cursor to derive the base currency from operating unit
      ---------------------------------------------------------
           
      CURSOR lcu_get_base_currency_code(p_to_location IN VARCHAR2)
      IS
      SELECT gsob.currency_code 
      FROM  hr_all_organization_units hou,
            hr_organization_information hoi1,
            hr_organization_information hoi2,
            mtl_parameters mp,
            gl_sets_of_books gsob,
            fnd_product_groups fpg
      WHERE hou.organization_id = hoi1.organization_id
      AND   hou.organization_id = hoi2.organization_id
      AND   hou.organization_id = mp.organization_id
      AND   hoi1.org_information1 = 'INV'
      AND   hoi1.org_information2 = 'Y'
      AND   (hoi1.org_information_context || '') = 'CLASS'
      AND   (hoi2.org_information_context || '') = 'Accounting Information'
      AND   hoi2.org_information1 = TO_CHAR (gsob.set_of_books_id)
      and   hou.attribute1=p_to_location
      ;
      
      
   BEGIN
   
      DBMS_OUTPUT.PUT_LINE('-----------------------');  
      DBMS_OUTPUT.PUT_LINE('Starting validate_lines');
      DBMS_OUTPUT.PUT_LINE('-----------------------');
      
      display_log('-----------------------');
      display_log('Starting validate_lines');
      display_log('-----------------------');
      
      -- Assigning header values
      
      lt_hdr_in_rec := p_in_hdr_rec;
      ln_header_id  := lt_hdr_in_rec(lt_hdr_in_rec.last).header_id;
      lc_hdr_status := lt_hdr_in_rec(lt_hdr_in_rec.last).status;
      lc_hdr_err_code := lt_hdr_in_rec(lt_hdr_in_rec.last).error_code;
      lc_hdr_err_msg := lt_hdr_in_rec(lt_hdr_in_rec.last).error_message;
      ln_from_org_id := lt_hdr_in_rec(lt_hdr_in_rec.last).from_org_id;
      lc_from_loc_nbr := lt_hdr_in_rec(lt_hdr_in_rec.last).from_loc_nbr;
      ln_to_org_id := lt_hdr_in_rec(lt_hdr_in_rec.last).to_org_id;
      lc_source_subinv_cd := lt_hdr_in_rec(lt_hdr_in_rec.last).source_subinv_cd;
      lc_trans_type_cd := lt_hdr_in_rec(lt_hdr_in_rec.last).trans_type_cd;
      
      --lc_hdr_status := p_in_hdr_rec.status;
      
      lt_line_in_dtl                := p_in_line_tbl;      
      x_out_line_tbl := xx_gi_xfer_out_line_tbl_type();      
      x_return_status := G_SUCCESS;
   
        IF lc_hdr_status <> G_PENDING_STATUS THEN
          
          
            DBMS_OUTPUT.PUT_LINE(' In validate_lines header has error');
            display_log(' In validate_lines header has error');
          
            lc_line_status      :=  G_ERROR_STATUS;
            lc_line_err_code    :=  lc_hdr_err_code;
            lc_line_err_msg     :=  lc_hdr_err_msg;
            
            lb_line_has_error   :=  TRUE;
          
            -- Since the header failed then mark all the lines with error status
            -- Then skip all the line validations and derivations
          
            DBMS_OUTPUT.PUT_LINE('In validate_lines lines table count - '||lt_line_in_dtl.count);
            display_log('In validate_lines lines table count - '||lt_line_in_dtl.count);
          
            FOR i IN lt_line_in_dtl.FIRST..lt_line_in_dtl.LAST
            LOOP
          
            x_out_line_tbl.EXTEND;
            
            IF lt_line_in_dtl(i).header_id IS NOT NULL THEN
            x_out_line_tbl(x_out_line_tbl.LAST).header_id         := lt_line_in_dtl(i).header_id;
            ELSE
            x_out_line_tbl(x_out_line_tbl.LAST).header_id         := ln_header_id;
            END IF;
            
            IF lt_line_in_dtl(i).line_id IS NOT NULL THEN
            x_out_line_tbl(x_out_line_tbl.LAST).line_id         := lt_line_in_dtl(i).line_id;
            ELSE
            SELECT XX_GI_TRANSFER_LINES_S.nextval
            INTO ln_line_id
            FROM DUAL;            
            x_out_line_tbl(x_out_line_tbl.LAST).line_id         := ln_line_id;
            END IF;
            
            x_out_line_tbl(x_out_line_tbl.LAST).item         := lt_line_in_dtl(i).item;
            x_out_line_tbl(x_out_line_tbl.LAST).shipped_qty := lt_line_in_dtl(i).shipped_qty;
            x_out_line_tbl(x_out_line_tbl.LAST).requested_qty := lt_line_in_dtl(i).requested_qty;
            x_out_line_tbl(x_out_line_tbl.LAST).from_loc_uom := lt_line_in_dtl(i).from_loc_uom;
            x_out_line_tbl(x_out_line_tbl.LAST).from_loc_unit_cost := lt_line_in_dtl(i).from_loc_unit_cost;          
            x_out_line_tbl(x_out_line_tbl.LAST).status := G_ERROR_STATUS;
            x_out_line_tbl(x_out_line_tbl.LAST).error_code := lc_hdr_err_code;
            x_out_line_tbl(x_out_line_tbl.LAST).error_message :=lc_hdr_err_msg;
                 
            END LOOP;
          
        ELSE
         
         -- If the header is success then do the line level validations and derivations
         
         DBMS_OUTPUT.PUT_LINE(' In validate_lines header status is PE then starting line validations');
         display_log(' In validate_lines header status is PE then starting line validations');
         
         FOR i in lt_line_in_dtl.FIRST..lt_line_in_dtl.LAST
         LOOP
                         
            lc_item   := lt_line_in_dtl(i).item;
            lc_shipped_qty := lt_line_in_dtl(i).shipped_qty;
            lc_requested_qty := lt_line_in_dtl(i).requested_qty;
         
            IF lc_item IS NULL THEN
                     
                x_return_status     :=  G_VALIDATION_ERROR;
                lc_hdr_status       :=  G_PARTIAL_STATUS;
                x_error_message     :=  'Item is Null';
                lc_line_status      :=  G_ERROR_STATUS;
                lc_line_err_code    :=  'XX_GI_XFER_LINE_ITEM_NULL';
                lc_line_err_msg     :=  'Item is Null';
                lb_line_has_error   :=  TRUE; 
         
                ELSIF lc_shipped_qty IS NULL THEN
         
                x_return_status     :=  G_VALIDATION_ERROR;
                lc_hdr_status       :=  G_PARTIAL_STATUS;
                x_error_message     :=  'Shipped qty is Null';
                lc_line_status      :=  G_ERROR_STATUS;
                lc_line_err_code    :=  'XX_GI_XFER_LINE_SHIP_QTY_NULL';
                lc_line_err_msg     :=  'Shipped qty is Null'; 
                lb_line_has_error   :=  TRUE;       
         
                ELSIF lc_requested_qty IS NULL THEN
         
                x_return_status     :=  G_VALIDATION_ERROR;
                lc_hdr_status       :=  G_PARTIAL_STATUS;
                x_error_message     :=  'Requested qty is Null';
                lc_line_status      :=  G_ERROR_STATUS;
                lc_line_err_code    :=  'XX_GI_XFER_LINE_REQ_QTY_NULL';
                lc_line_err_msg     :=  'Requested qty is Null';
                lb_line_has_error   :=  TRUE;         
                         
            END IF;
            
            DBMS_OUTPUT.PUT_LINE('In validate_lines Line Err Code-'||lc_line_err_code||'for Sku'||lc_item);
            DBMS_OUTPUT.PUT_LINE('In validate_lines Line Err Msg -'||lc_line_err_msg||'for Sku'||lc_item);
            
            display_log('In validate_lines Line Err Code-'||lc_line_err_code||'for Sku'||lc_item);
            display_log('In validate_lines Line Err Msg -'||lc_line_err_msg||'for Sku'||lc_item);
            
            --IF lc_line_status = G_ERROR_STATUS THEN            
            IF lb_line_has_error THEN
            
                    DBMS_OUTPUT.PUT_LINE('In validate_lines line has null values for required columns');
                    display_log('In validate_lines line has null values for required columns');
                    
                    x_out_line_tbl.EXTEND;
                    --x_out_line_tbl(x_out_line_tbl.LAST).header_id      := lt_line_in_dtl(i).header_id;
                    --x_out_line_tbl(x_out_line_tbl.LAST).line_id      := lt_line_in_dtl(i).line_id;
                    
                    IF lt_line_in_dtl(i).header_id IS NOT NULL THEN
                    x_out_line_tbl(x_out_line_tbl.LAST).header_id         := lt_line_in_dtl(i).header_id;
                    ELSE
                    x_out_line_tbl(x_out_line_tbl.LAST).header_id         := ln_header_id;
                    END IF;
            
                    IF lt_line_in_dtl(i).line_id IS NOT NULL THEN
                    x_out_line_tbl(x_out_line_tbl.LAST).line_id         := lt_line_in_dtl(i).line_id;
                    
                    ELSE
                        SELECT XX_GI_TRANSFER_LINES_S.nextval
                        INTO ln_line_id
                        FROM DUAL;            
                    x_out_line_tbl(x_out_line_tbl.LAST).line_id         := ln_line_id;
                    END IF;
                    
                    x_out_line_tbl(x_out_line_tbl.LAST).item         := lt_line_in_dtl(i).item;
                    x_out_line_tbl(x_out_line_tbl.LAST).shipped_qty := lt_line_in_dtl(i).shipped_qty;
                    x_out_line_tbl(x_out_line_tbl.LAST).requested_qty := lt_line_in_dtl(i).requested_qty;
                    x_out_line_tbl(x_out_line_tbl.LAST).from_loc_uom := lt_line_in_dtl(i).from_loc_uom;
                    x_out_line_tbl(x_out_line_tbl.LAST).from_loc_unit_cost := lt_line_in_dtl(i).from_loc_unit_cost;
                    x_out_line_tbl(x_out_line_tbl.LAST).status  := lc_line_status;
                    x_out_line_tbl(x_out_line_tbl.LAST).created_by  := FND_GLOBAL.USER_ID;
                    x_out_line_tbl(x_out_line_tbl.LAST).creation_date  := SYSDATE;
                    x_out_line_tbl(x_out_line_tbl.LAST).last_updated_by := FND_GLOBAL.USER_ID;
                    x_out_line_tbl(x_out_line_tbl.LAST).last_update_date := SYSDATE;
                    x_out_line_tbl(x_out_line_tbl.LAST).last_update_login := FND_GLOBAL.LOGIN_ID;
                   
                    x_out_line_tbl(x_out_line_tbl.LAST).error_code := lc_line_err_code;
                    x_out_line_tbl(x_out_line_tbl.LAST).error_message := lc_line_err_msg;
                    
             ELSE       
            
                   DBMS_OUTPUT.PUT_LINE('In validate_lines start derivations for sku - '||lc_item);
                   display_log('In validate_lines start derivations for sku - '||lc_item);
                   DBMS_OUTPUT.PUT_LINE('validate_lines lc_line_status - '||lc_line_status);
            BEGIN
            
               lc_line_status := G_PENDING_STATUS;               
               ln_to_org_item_id := NULL;
               lc_to_org_item_desc := NULL;
               lc_to_org_uom_code := NULL;
               ln_to_org_item_cost_group_id := NULL;
                
                            
            OPEN  lcu_is_item_transactable(lc_item,ln_to_org_id);
                                                     
                  FETCH lcu_is_item_transactable INTO ln_to_org_item_id
                                                     ,lc_to_org_item_desc                                                    
                                                     ,lc_to_org_uom_code
                                                     ,ln_to_org_item_cost_group_id;
                                                     
                   CLOSE lcu_is_item_transactable;
                   
                   DBMS_OUTPUT.PUT_LINE('In validate_lines lc_to_org_item_desc -'||lc_to_org_item_desc||ln_to_org_item_id);
                  
                  IF ln_to_org_item_id IS NULL THEN                  
                  
                     
                    x_return_status     :=G_VALIDATION_ERROR;
                    lc_hdr_status       :=G_PARTIAL_STATUS;
                    x_error_message     :='Invalid To Org Inventory Item Id';
                    lc_line_status      :=G_ERROR_STATUS;
                    lc_line_err_code    :='XX_GI_XFER_TO_ORG_ITEM_ID';
                    lc_line_err_msg     :='Invalid To Org Inventory Item Id';                    
                    lb_line_has_error   := TRUE;
                    
                  
                  END IF;
                                 
                                    
                --IF lc_line_status <> G_ERROR_STATUS THEN
                
                IF NOT lb_line_has_error THEN
                
                ln_from_org_item_id := NULL;
                lc_from_org_item_desc := NULL;
                lc_from_org_uom_code := NULL;
                ln_from_org_item_cost_group_id := NULL;
                
                
                  DBMS_OUTPUT.PUT_LINE('In validate_lines inside from org id transactable'||lc_item||'-ln_from_org_id-'||ln_from_org_id);
                  
                  OPEN  lcu_is_item_transactable(lc_item,ln_from_org_id);
                  
                  FETCH lcu_is_item_transactable INTO ln_from_org_item_id
                                                     ,lc_from_org_item_desc                                                    
                                                     ,lc_from_org_uom_code
                                                     ,ln_from_org_item_cost_group_id;    
            
                  CLOSE lcu_is_item_transactable;    
                  
                  DBMS_OUTPUT.PUT_LINE('In validate_lines lc_from_org_item_desc -'||lc_from_org_item_desc);
                  
                  IF ln_from_org_item_id IS NULL THEN
                  
                                   
                    x_return_status     :=  G_VALIDATION_ERROR;
                    lc_hdr_status       :=  G_PARTIAL_STATUS;
                    x_error_message     :=  'From Org Inventory Item Id Null';
                    lc_line_status      :=  G_ERROR_STATUS;
                    lc_line_err_code    :=  'XX_GI_XFER_FROM_ORG_ITEM_ID';
                    lc_line_err_msg     :=  'From Org Inventory Item Id Null';
                    
                    lb_line_has_error := TRUE;
                  
                  END IF;
                
                END IF;
                  
                
                --IF   lc_line_status  <> G_ERROR_STATUS THEN
                
                IF NOT lb_line_has_error THEN
                                      
                     IF ln_from_org_item_cost_group_id IS NOT NULL THEN

                        ---------------------------------------------------------
                        -- Derive Unit cost using the cost group id derived above
                        -- The below API returns null for all errors
                        ---------------------------------------------------------
                        
                        --ln_unit_cost := CST_COST_API.GET_ITEM_COST

                        ln_from_org_item_unit_cost := CST_COST_API.GET_ITEM_COST
                                                                (p_api_version       => 1
                                                                ,p_inventory_item_id => ln_from_org_item_id
                                                                ,p_organization_id   => ln_from_org_id--gn_from_org_id
                                                                ,p_cost_group_id     => ln_from_org_item_cost_group_id--ln_cost_group_id
                                                                ,p_cost_type_id      => NULL
                                                                );
                                                                
                         DBMS_OUTPUT.PUT_LINE('In validate_lines ln_from_org_item_unit_cost -'||ln_from_org_item_unit_cost);                                       
                              
                              ELSE
                              
                            x_return_status := G_VALIDATION_ERROR;
                            lc_hdr_status   :=G_PARTIAL_STATUS;
                            x_error_message := 'Invalid Cost group id';
                            lc_line_status  := G_ERROR_STATUS;
                            lc_line_err_code := 'XX_GI_XFER_COST_GRP';
                            lc_line_err_msg := 'Invalid Cost group id';
                            
                            lb_line_has_error := TRUE;
                    
                              
                     END IF;
                     
                  END IF;
                  
                  
                        --IF   lc_line_status  <> G_ERROR_STATUS THEN
                        
                        IF NOT lb_line_has_error THEN
                  
                            OPEN lcu_get_base_currency_code(lc_from_loc_nbr);
                            FETCH lcu_get_base_currency_code INTO lc_currency_code;
                            CLOSE lcu_get_base_currency_code;

                             IF lc_currency_code IS NULL THEN

                             x_return_status := G_VALIDATION_ERROR;
                             lc_line_status :=G_ERROR_STATUS;
                             lc_line_err_code := 'XX_GI_XFER_CURR_CODE';
                             lc_line_err_msg := 'Currency Code Error';         
                             x_error_message := 'Currency Code Error';
                             
                             lb_line_has_error := TRUE;

                             END IF;
                             
                         END IF;
                         
                         
                         --IF lc_line_status <> G_ERROR_STATUS THEN
                         
                         IF NOT lb_line_has_error THEN
       
                            /*
                            IF (lc_trans_type_cd='OHWR' AND lc_source_subinv_cd IN (NULL,'STOCK')) THEN
                            lc_ebs_subinventory_code := 'STOCK';
      
                            ELSIF (lc_trans_type_cd='STIR' AND lc_source_subinv_cd IN (NULL,'STOCK')) THEN
                            lc_ebs_subinventory_code := 'STOCK';
      
                            ELSIF (lc_trans_type_cd='RVST' AND lc_source_subinv_cd IN ('BB')) THEN
                            lc_ebs_subinventory_code := 'BUYBACK';
      
                            ELSIF (lc_trans_type_cd='RVST' AND lc_source_subinv_cd IN ('DD')) THEN
                            lc_ebs_subinventory_code := 'DAMAGED';
                            ELSE
                            lc_ebs_subinventory_code := NULL;
                            x_return_status := G_VALIDATION_ERROR;
                            x_error_message  := 'EBS Subinventory code error';                            
                            lc_line_status  := G_ERROR_STATUS;
                            lc_line_err_code := 'XX_GI_XFER_EBS_SUB_INV_CD';
                            lc_line_err_msg := 'EBS Subinventory code error';
                            
                            lb_line_has_error := TRUE;
                           END IF;*/
                           
                           IF SUBSTR(lc_source_subinv_cd,9,10) IS NULL THEN
                            lc_ebs_subinventory_code := 'STOCK';
      
                            ELSIF SUBSTR(lc_source_subinv_cd,9,10)='DD' THEN
                            lc_ebs_subinventory_code := 'DAMAGED';
      
                            ELSIF SUBSTR(lc_source_subinv_cd,9,10)='BB' THEN
                            lc_ebs_subinventory_code := 'BUYBACK';
      
                            ELSE
                            lc_ebs_subinventory_code := NULL;
                            x_return_status := G_VALIDATION_ERROR;
                            x_error_message  := 'EBS Subinventory code error';                            
                            lc_line_status  := G_ERROR_STATUS;
                            lc_line_err_code := 'XX_GI_XFER_EBS_SUB_INV_CD';
                            lc_line_err_msg := 'EBS Subinventory code error';
                            
                            lb_line_has_error := TRUE;
                           END IF;
                               
                           END IF;
      
                        
                   --IF lc_line_status = G_ERROR_STATUS THEN
                   
                   IF    lb_line_has_error THEN
                         lc_line_status := G_ERROR_STATUS;
                    
                            
                    x_out_line_tbl.EXTEND;
                    --x_out_line_tbl(x_out_line_tbl.LAST).header_id      := lt_line_in_dtl(i).header_id;
                    --x_out_line_tbl(x_out_line_tbl.LAST).line_id      := lt_line_in_dtl(i).line_id;
                    
                    IF lt_line_in_dtl(i).header_id IS NOT NULL THEN
                    x_out_line_tbl(x_out_line_tbl.LAST).header_id         := lt_line_in_dtl(i).header_id;
                    ELSE
                    x_out_line_tbl(x_out_line_tbl.LAST).header_id         := ln_header_id;
                    END IF;
            
                    IF lt_line_in_dtl(i).line_id IS NOT NULL THEN
                    x_out_line_tbl(x_out_line_tbl.LAST).line_id         := lt_line_in_dtl(i).line_id;
                    ELSE
                    SELECT XX_GI_TRANSFER_LINES_S.nextval
                    INTO ln_line_id
                    FROM DUAL;            
                    x_out_line_tbl(x_out_line_tbl.LAST).line_id         := ln_line_id;
                    END IF;
            
                    x_out_line_tbl(x_out_line_tbl.LAST).item         := lt_line_in_dtl(i).item;
                    x_out_line_tbl(x_out_line_tbl.LAST).shipped_qty := lt_line_in_dtl(i).shipped_qty;
                    x_out_line_tbl(x_out_line_tbl.LAST).requested_qty := lt_line_in_dtl(i).requested_qty;
                    x_out_line_tbl(x_out_line_tbl.LAST).from_loc_uom := lt_line_in_dtl(i).from_loc_uom;
                    x_out_line_tbl(x_out_line_tbl.LAST).from_loc_unit_cost := lt_line_in_dtl(i).from_loc_unit_cost;
                    x_out_line_tbl(x_out_line_tbl.LAST).status  := lc_line_status;
                    x_out_line_tbl(x_out_line_tbl.LAST).created_by  := FND_GLOBAL.USER_ID;
                    x_out_line_tbl(x_out_line_tbl.LAST).creation_date  := SYSDATE;
                    x_out_line_tbl(x_out_line_tbl.LAST).last_updated_by := FND_GLOBAL.USER_ID;
                    x_out_line_tbl(x_out_line_tbl.LAST).last_update_date := SYSDATE;
                    x_out_line_tbl(x_out_line_tbl.LAST).last_update_login := FND_GLOBAL.LOGIN_ID;
                   
                    x_out_line_tbl(x_out_line_tbl.LAST).error_code := lc_line_err_code;
                    x_out_line_tbl(x_out_line_tbl.LAST).error_message := lc_line_err_msg;
                    
                   ELSE
                         lc_line_status := G_PENDING_STATUS;
                         DBMS_OUTPUT.PUT_LINE(' In validate_lines before setting final values');
                    x_out_line_tbl.EXTEND;
                    
                    IF lt_line_in_dtl(i).line_id IS NULL THEN
                    
                    SELECT XX_GI_TRANSFER_LINES_S.nextval
                    INTO ln_line_id
                    FROM DUAL;                    
                    x_out_line_tbl(x_out_line_tbl.LAST).line_id      := ln_line_id;
                    ELSE
                    x_out_line_tbl(x_out_line_tbl.LAST).line_id      := lt_line_in_dtl(i).line_id;
                    END IF;
                    
                    IF lt_line_in_dtl(i).header_id IS NULL THEN
                    x_out_line_tbl(x_out_line_tbl.LAST).header_id      := ln_header_id;
                    ELSE
                    x_out_line_tbl(x_out_line_tbl.LAST).header_id      := lt_line_in_dtl(i).header_id;
                    END IF;
                    
                    x_out_line_tbl(x_out_line_tbl.LAST).item         := lt_line_in_dtl(i).item;
                    x_out_line_tbl(x_out_line_tbl.LAST).inventory_item_id      := ln_from_org_item_id;                    
                    x_out_line_tbl(x_out_line_tbl.LAST).item_description         := lc_from_org_item_desc;
                    x_out_line_tbl(x_out_line_tbl.LAST).shipped_qty := lt_line_in_dtl(i).shipped_qty;
                    x_out_line_tbl(x_out_line_tbl.LAST).requested_qty := lt_line_in_dtl(i).requested_qty;
                    x_out_line_tbl(x_out_line_tbl.LAST).from_loc_uom := lt_line_in_dtl(i).from_loc_uom;
                    x_out_line_tbl(x_out_line_tbl.LAST).uom := lc_from_org_uom_code;
                    x_out_line_tbl(x_out_line_tbl.LAST).from_loc_unit_cost := lt_line_in_dtl(i).from_loc_unit_cost;
                    x_out_line_tbl(x_out_line_tbl.LAST).from_org_unit_cost := ln_from_org_item_unit_cost;
                    x_out_line_tbl(x_out_line_tbl.LAST).currency_code := lc_currency_code;
                    x_out_line_tbl(x_out_line_tbl.LAST).status  := lc_line_status;
                    x_out_line_tbl(x_out_line_tbl.LAST).transaction_header_id  := lt_line_in_dtl(i).transaction_header_id;
                    x_out_line_tbl(x_out_line_tbl.LAST).mtl_transaction_id  := lt_line_in_dtl(i).mtl_transaction_id;
                    x_out_line_tbl(x_out_line_tbl.LAST).created_by  := FND_GLOBAL.USER_ID;
                    x_out_line_tbl(x_out_line_tbl.LAST).creation_date  := SYSDATE;
                    x_out_line_tbl(x_out_line_tbl.LAST).last_updated_by := FND_GLOBAL.USER_ID;
                    x_out_line_tbl(x_out_line_tbl.LAST).last_update_date := SYSDATE;
                    x_out_line_tbl(x_out_line_tbl.LAST).last_update_login := FND_GLOBAL.LOGIN_ID;
                    x_out_line_tbl(x_out_line_tbl.LAST).ebs_subinventory_code  := lc_ebs_subinventory_code;
                    x_out_line_tbl(x_out_line_tbl.LAST).error_code := lc_line_err_code;
                    x_out_line_tbl(x_out_line_tbl.LAST).error_message := lc_line_err_msg;
                    
                    END IF;
                        
                    END;         
                         
            END IF;
            
            lc_line_status := G_PENDING_STATUS;
            lc_line_err_code := NULL;
            lc_line_err_msg := NULL;
            
            lb_line_has_error := FALSE;
         
         END LOOP;       
         
         
         END IF;
       
               
   END VALIDATE_LINES;
   
   
   -- +==========================================================================================+
   -- | Name        :  VALIDATE_TRANSFER                                                             |
   -- |                                                                                          |
   -- | Description :  This procedure validates the given transactions and returns               |
   -- |                 PL/SQL table with derived information. This program                      |
   -- |                 returns  E => On validation/Derivation error.                            |
   -- |                 returns  S => On complete success.                                       |
   -- |                 returns  U => On unexpected error.                                       |
   -- |                                                                                          |
   -- +==========================================================================================+
                         
 PROCEDURE VALIDATE_TRANSFER
                        ( 
                          p_in_hdr_rec IN xx_gi_transfer_headers%ROWTYPE
                         ,p_in_line_tbl   IN         xx_gi_xfer_in_line_tbl_type
                         ,x_out_hdr_rec   OUT NOCOPY xx_gi_xfer_out_hdr_type
                         ,x_out_line_tbl  OUT NOCOPY xx_gi_xfer_out_line_tbl_type
                         ,x_return_status OUT NOCOPY VARCHAR2
                         ,x_error_message OUT NOCOPY VARCHAR2)
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
      
      lc_item                         mtl_system_items_b.segment1%TYPE := NULL;
      lc_shipped_qty                  xx_gi_transfer_lines.shipped_qty%TYPE := NULL;
      lc_requested_qty                xx_gi_transfer_lines.requested_qty%TYPE :=NULL;
      ln_from_org_item_id             mtl_system_items_b.inventory_item_id%TYPE := NULL;
      ln_to_org_item_id               mtl_system_items_b.inventory_item_id%TYPE := NULL;
      lc_description                  mtl_system_items_b.description%TYPE := NULL;
      lc_to_consignment_flag          VARCHAR2(2) := NULL;
      lc_from_consignment_flag        VARCHAR2(2) := NULL;
      ln_vendor_id                    PLS_INTEGER;
      ln_vendor_site_id               PLS_INTEGER;
      lc_return_status                VARCHAR2(10) := NULL;
      lc_return_message               VARCHAR2(500) := NULL;
      lc_error_flag                   VARCHAR2(1) := NULL;
      ln_qty_onhand                   PLS_INTEGER := NULL;
      lc_uom_code                     mtl_system_items_b.primary_uom_code%TYPE := NULL;
      ln_cost_group_id                mtl_parameters.default_cost_group_id%TYPE := NULL;
      --lt_line_in_dtl                  xx_gi_validate_item_tab_t := xx_gi_validate_item_tab_t() ;
      --lt_line_in_dtl                  validate_output_tbl_type := validate_output_tbl_type() ;
      
      lt_line_in_dtl xx_gi_xfer_in_line_tbl_type := xx_gi_xfer_in_line_tbl_type();
      
      l_out_line_tbl xx_gi_xfer_out_line_tbl_type := xx_gi_xfer_out_line_tbl_type();
      
      lt_hdr_out_rec xx_gi_xfer_out_hdr_type := xx_gi_xfer_out_hdr_type();
      
            --lt_hdr_out_rec xx_gi_transfer_headers%rowtype;
      
      
                  
      lc_on_hand_qnty_err             VARCHAR2(500) := NULL;
      ln_unit_cost                    PLS_INTEGER        := NULL;
      lc_currency_code                VARCHAR2(15)  := NULL;
      lc_trx_action                   VARCHAR2(30)  := 'Intransit';
      
      
      
      lc_transfer_exists           VARCHAR2(1) := NULL;
      
      lc_trans_type_cd             xx_gi_transfer_headers.trans_type_cd%TYPE := NULL;
      lc_doc_type_cd               xx_gi_transfer_headers.doc_type_cd%TYPE := NULL;
      lc_source_subinv_cd          xx_gi_transfer_headers.source_subinv_cd%TYPE :=NULL;
      lc_ebs_subinventory_code     xx_gi_transfer_lines.ebs_subinventory_code%TYPE :=NULL;

      lc_hdr_status      xx_gi_transfer_headers.status%TYPE := NULL;
      
      lc_header_status   xx_gi_transfer_headers.status%TYPE := NULL;
      
      lc_hdr_err_code    xx_gi_transfer_headers.error_code%TYPE;
      lc_hdr_err_msg     xx_gi_transfer_headers.error_message%TYPE;
      
      
      lc_line_status     xx_gi_transfer_lines.status%TYPE;
      lc_line_err_code   xx_gi_transfer_lines.error_code%TYPE;
      lc_line_err_msg    xx_gi_transfer_lines.error_message%TYPE;
      
         
            

   BEGIN
   
    display_log('--------------------------');
    display_log('Starting validate_transfer');
    display_log('--------------------------');
    
    DBMS_OUTPUT.PUT_LINE('--------------------------');
    DBMS_OUTPUT.PUT_LINE('Starting Validate_Transfer');
    DBMS_OUTPUT.PUT_LINE('--------------------------');
    
      --x_out_hdr_rec := validate_output_hdr_tbl_type();
      x_out_hdr_rec := xx_gi_xfer_out_hdr_type();
      
      --lc_hdr_status := NULL;
      
      gn_from_org_id                := NULL;
      --lt_line_in_dtl                := p_item_in_dtl;
      --lt_line_in_dtl                := p_in_line_tbl;
      lt_line_in_dtl                := p_in_line_tbl;
       
      lc_error_flag                 := G_NO;
      --x_out_line_tbl                := validate_output_tbl_type();
      x_out_line_tbl := xx_gi_xfer_out_line_tbl_type();
      
     --l_out_line_tbl := xx_gi_xfer_out_line_tbl_type();
            
      lc_trans_type_cd           := p_in_hdr_rec.trans_type_cd;
      lc_doc_type_cd    := p_in_hdr_rec.doc_type_cd;
      
      
      -- Call validate_header 
      
      BEGIN
      
         VALIDATE_HEADER
                        ( 
                          p_in_hdr_rec => p_in_hdr_rec                         
                         ,x_out_hdr_rec =>  x_out_hdr_rec                         
                         ,x_return_status => lc_header_status
                         ,x_error_message =>lc_hdr_err_msg--x_error_message
                         );
                            
                        lt_hdr_out_rec := x_out_hdr_rec;
                   
                   display_log('In Validate_Transfer validate_header x_return_status -'||lc_header_status);
                  DBMS_OUTPUT.PUT_LINE('In Validate_Transfer validate_header x_error_message -'||lc_hdr_err_msg);

                    
        EXCEPTION 
        WHEN OTHERS THEN
        x_error_message := '(VALIDATE_TRANSFER): '||SQLERRM;
        x_return_status := G_UNEXPECTED_ERROR;
        display_log('Exception occured in Validate_Transfer Validate_Header -'||SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Exception occured in Validate_Transfer Validate_Header -'||SQLERRM);
        END;
        
                    
           
            BEGIN         
       
             VALIDATE_LINES
                        ( 
                          p_in_hdr_rec =>lt_hdr_out_rec--lt_hdr_out_rec --IN xx_gi_transfer_headers%ROWTYPE
                         ,p_in_line_tbl =>lt_line_in_dtl--  IN         xx_gi_xfer_in_line_tbl_type                         
                         ,x_out_line_tbl => x_out_line_tbl--OUT NOCOPY xx_gi_xfer_out_line_tbl_type
                         ,x_return_status =>lc_line_status --OUT NOCOPY VARCHAR2
                         ,x_error_message =>lc_line_err_msg --OUT NOCOPY VARCHAR2)
                         );

                   display_log('In Validate_Transfer validate_lines x_return_status -'||lc_line_status);
                  DBMS_OUTPUT.PUT_LINE('In Validate_Transfer validate_lines x_error_message -'||lc_line_err_msg);
                  
            EXCEPTION 
            WHEN OTHERS THEN
            x_error_message := '(VALIDATE_TRANSFER): '||SQLERRM;
            x_return_status := G_UNEXPECTED_ERROR;
            display_log('Exception occured in Validate_Transfer Validate_Lines -'||SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Exception occured in Validate_Transfer Validate_Lines -'||SQLERRM);
            END; 
        
                             
      -- If one line has error change the header status to Partial (PP) 
      
      IF lc_header_status=G_VALIDATION_ERROR THEN 
      --lc_error_flag = G_YES THEN
         x_return_status := G_VALIDATION_ERROR;
         x_error_message := lc_hdr_err_msg;
      
      ELSIF lc_line_status =G_VALIDATION_ERROR THEN   
         x_return_status := G_VALIDATION_ERROR;
         x_error_message := lc_line_err_msg;
         
      ELSE
         x_return_status := G_SUCCESS;
      END IF;
      
      IF lc_header_status = G_SUCCESS AND lc_line_status <> G_SUCCESS THEN
            x_out_hdr_rec(x_out_hdr_rec.LAST).status := 'PP';
      END IF;
      

   EXCEPTION
      
      WHEN OTHERS THEN
         x_error_message := '(VALIDATE_TRANSFER): '||SQLERRM;
         x_return_status := G_UNEXPECTED_ERROR;
         display_log('Exception occured in Validate_Transfer-'||SQLERRM);
         DBMS_OUTPUT.PUT_LINE('Exception occured in Validate_Transfer-'||SQLERRM);

         
   END VALIDATE_TRANSFER;
   
   -- +==========================================================================================+
   -- | Name        :  INSERT_INTO_STAGING                                                       |
   -- |                                                                                          |
   -- | Description :  This procedure inserts data into transfer staging table                   |
   -- |                 validated data into custom transfer headers and lines tables.            |
   -- |                 
   -- |                 returns  S => On complete success.                                       |
   -- |                 returns  U => On unexpected error.                                       |
   -- |                                                                                          |
   -- |                                                                                          |
   -- +==========================================================================================+
   
    PROCEDURE INSERT_INTO_STAGING
                        ( 
                          --p_in_hdr_rec IN xx_gi_transfer_headers%rowtype
                         --,p_in_line_tbl   IN         xx_gi_xfer_in_line_tbl_type 
                         p_in_hdr_rec IN xx_gi_xfer_out_hdr_type
                         ,p_in_line_tbl   IN xx_gi_xfer_out_line_tbl_type
                         ,x_return_status OUT NOCOPY VARCHAR2
                         ,x_error_message OUT NOCOPY VARCHAR2
                         )
  IS
  BEGIN
    
    display_log('----------------------------');
    display_log('Starting insert_into_staging');
    display_log('----------------------------');
    
    DBMS_OUTPUT.PUT_LINE('----------------------------');
    DBMS_OUTPUT.PUT_LINE('Starting insert_into_staging');
    DBMS_OUTPUT.PUT_LINE('----------------------------');
  
    BEGIN
   
      FORALL i IN p_in_hdr_rec.FIRST .. p_in_hdr_rec.LAST
        
        INSERT INTO xx_gi_transfer_headers
        VALUES p_in_hdr_rec(i) ;
        
        x_return_status := G_SUCCESS;
      
      EXCEPTION 
      WHEN OTHERS THEN
        x_error_message := '(INSERT_INTO_STAGING Header Error-): '||SQLERRM;
        x_return_status := G_UNEXPECTED_ERROR;
         
        display_log('Exception in insert_staging header insert');
        DBMS_OUTPUT.PUT_LINE('Exception in insert_staging header insert');
    END;
   
    BEGIN
    
      FORALL i IN p_in_line_tbl.FIRST .. p_in_line_tbl.LAST
   
       INSERT INTO xx_gi_transfer_lines
        VALUES p_in_line_tbl(i) ;
        
        x_return_status := G_SUCCESS;
      
      EXCEPTION 
      WHEN OTHERS THEN
        x_error_message := '(INSERT_INTO_STAGING Lines Error): '||SQLERRM;
        x_return_status := G_UNEXPECTED_ERROR;
        display_log('Exception in insert_into_staging lines insert');
        DBMS_OUTPUT.PUT_LINE('Exception in insert_into_staging lines insert');
    
    END;
    x_return_status := G_SUCCESS;
    
  END INSERT_INTO_STAGING;
  
   -- +==========================================================================================+
   -- | Name        :  CREATE_MAINTAIN_TRANSFER                                                               |
   -- |                                                                                          |
   -- | Description :  This procedure validates the given transactions and then inserts the      |
   -- |                 validated data into custom transfer headers and lines tables.            |
   -- |                 returns  E => On validation/Derivation error.                            |
   -- |                 returns  S => On complete success.                                       |
   -- |                 returns  U => On unexpected error.                                       |
   -- |                                                                                          |
   -- |                                                                                          |
   -- +==========================================================================================+
                         
                        
                        PROCEDURE CREATE_MAINTAIN_TRANSFER
                        (                                                
                          p_in_hdr_rec    IN         xx_gi_xfer_input_hdr_type
                         ,p_in_line_tbl   IN         xx_gi_xfer_input_line_tbl_type 
                         ,x_return_status OUT NOCOPY VARCHAR2
                         ,x_error_message OUT NOCOPY VARCHAR2
                         )                    
                         IS
      -------------------------
      -- Local scalar variables
      -------------------------
      ln_number                 PLS_INTEGER   := NULL;
      lc_err_msg                VARCHAR2(500) := NULL;
      lc_status                 VARCHAR2(1)   := NULL;
      lc_is_shipnet_exists      VARCHAR2(1)   := NULL;
      lc_first_record           VARCHAR2(1)   := NULL;
      lc_transfer_number_exists VARCHAR2(1)   := NULL;
      lc_transaction_type_id    mtl_transaction_types.transaction_type_id%TYPE;

      l_hdr_rec             xx_gi_transfer_headers%rowtype;
      line_in_dtl           xx_gi_xfer_in_line_tbl_type := xx_gi_xfer_in_line_tbl_type();
      l_out_line_tbl        xx_gi_xfer_out_line_tbl_type := xx_gi_xfer_out_line_tbl_type();
      l_out_hdr_rec         xx_gi_xfer_out_hdr_type := xx_gi_xfer_out_hdr_type();
        
      ---------------------------------------------------------
      -- Cursor to check if shipping network exists between the
      -- from and to org.
      ---------------------------------------------------------
      CURSOR lcu_shipnet_exists
      IS
      SELECT G_YES
      FROM   mtl_interorg_parameters MIP
      WHERE  MIP.from_organization_id = gn_from_org_id
      AND    MIP.to_organization_id   = gn_to_org_id;
      
      
      
   BEGIN
      
    display_log('---------------------------------');
    display_log('Starting create_maintain_transfer');
    display_log('---------------------------------');
    
    display_out('---------------------------------');
    display_out('Starting create_maintain_transfer');
    display_out('---------------------------------');
    
    DBMS_OUTPUT.PUT_LINE('---------------------------------');
    DBMS_OUTPUT.PUT_LINE('Starting create_maintain_transfer');
    DBMS_OUTPUT.PUT_LINE('---------------------------------');
    
    
    display_log('Assigning header record values create_maintain_transfer');
    DBMS_OUTPUT.PUT_LINE('Assigning header record values create_maintain_transfer');
     
    -- Assigning header input values to variables
       
        BEGIN            
            l_hdr_rec.header_id            := p_in_hdr_rec.header_id;
            l_hdr_rec.source_system        :=p_in_hdr_rec.source_system;
            l_hdr_rec.transfer_number      :=p_in_hdr_rec.transfer_number;
            l_hdr_rec.from_loc_nbr         :=p_in_hdr_rec.from_loc_nbr;
            l_hdr_rec.to_loc_nbr           := p_in_hdr_rec.to_loc_nbr;
            l_hdr_rec.trans_type_cd        :=p_in_hdr_rec.trans_type_cd;
            l_hdr_rec.doc_type_cd          :=p_in_hdr_rec.doc_type_cd;
            l_hdr_rec.source_creation_date :=p_in_hdr_rec.source_creation_date;
            l_hdr_rec.source_created_by    :=p_in_hdr_rec.source_created_by;
            l_hdr_rec.buyback_number        := p_in_hdr_rec.buyback_number;
            l_hdr_rec.carton_count         := p_in_hdr_rec.carton_count;
            l_hdr_rec.transfer_cost         :=p_in_hdr_rec.transfer_cost;
            l_hdr_rec.ship_date            :=p_in_hdr_rec.ship_date;
            l_hdr_rec.shipped_qty          :=p_in_hdr_rec.shipped_qty;
            l_hdr_rec.comments             :=p_in_hdr_rec.comments;
            l_hdr_rec.source_subinv_cd     :=p_in_hdr_rec.source_subinv_cd;
            l_hdr_rec.source_vendor_id     :=p_in_hdr_rec.source_vendor_id;
     
            EXCEPTION
                  WHEN OTHERS THEN                     
                     x_error_message := '(CREATE_MAINTAIN_TRANSFER Header value assign error): '||SQLERRM;
                     x_return_status := G_UNEXPECTED_ERROR;
                     display_log('CREATE_MAINTAIN_TRANSFER Header value assign error: '||SQLERRM);
                     DBMS_OUTPUT.PUT_LINE('CREATE_MAINTAIN_TRANSFER Header value assign error: '||SQLERRM);
            END;
                  
      
        BEGIN  
            -- Assigning line input values  
   
            FOR i in p_in_line_tbl.FIRST..p_in_line_tbl.LAST
             LOOP
                line_in_dtl.EXTEND;
                DBMS_OUTPUT.PUT_LINE('In create_maintain_transfer input item value is-'||p_in_line_tbl(i).item);
                display_log('In create_maintain_transfer input item value is-'||p_in_line_tbl(i).item);
                --insert into XX_GI_TRANSFER_DEBUG(msg) values('Item value-'||p_in_line_tbl(i).item);
                line_in_dtl(line_in_dtl.LAST).item := p_in_line_tbl(i).item;
                line_in_dtl(line_in_dtl.LAST).shipped_qty := p_in_line_tbl(i).shipped_qty;
                line_in_dtl(line_in_dtl.LAST).requested_qty := p_in_line_tbl(i).requested_qty;
                line_in_dtl(line_in_dtl.LAST).from_loc_uom := p_in_line_tbl(i).from_loc_uom;
                line_in_dtl(line_in_dtl.LAST).from_loc_unit_cost := p_in_line_tbl(i).from_loc_unit_cost;
            END LOOP;
            
   
            
            EXCEPTION
                  WHEN OTHERS THEN                     
                     x_error_message := '(CREATE_MAINTAIN_TRANSFER Line values assign error): '||SQLERRM;
                     x_return_status := G_UNEXPECTED_ERROR;
                     display_log('CREATE_MAINTAIN_TRANSFER Line values assign error: '||SQLERRM);
                     DBMS_OUTPUT.PUT_LINE('CREATE_MAINTAIN_TRANSFER Line values assign error: '||SQLERRM);
        END;
        
        
        BEGIN
                         
            -- Call validate procedure  
   
              VALIDATE_TRANSFER
                   (
                   p_in_hdr_rec    =>l_hdr_rec     -- IN xx_gi_transfer_headers%rowtype
                  ,p_in_line_tbl   =>line_in_dtl     -- IN         xx_gi_xfer_in_line_tbl_type
                  ,x_out_hdr_rec   =>l_out_hdr_rec     -- OUT NOCOPY xx_gi_xfer_out_hdr_type
                  ,x_out_line_tbl  =>l_out_line_tbl  -- OUT NOCOPY xx_gi_xfer_out_line_tbl_type
                  ,x_return_status =>x_return_status --OUT NOCOPY VARCHAR2
                  ,x_error_message =>x_error_message --OUT NOCOPY VARCHAR2
                   );
                   
          EXCEPTION
                  WHEN OTHERS THEN                     
                     x_error_message := '(CREATE_MAINTAIN_TRANSFER Validate_Transfer call error): '||SQLERRM;
                     x_return_status := G_UNEXPECTED_ERROR;
                     display_log('CREATE_MAINTAIN_TRANSFER Validate_Transfer call error: '||SQLERRM);
                     DBMS_OUTPUT.PUT_LINE('CREATE_MAINTAIN_TRANSFER Validate_Transfer call error: '||SQLERRM);
                     
        END;         
                         
                        
               display_log('In create_maintain_transfer validate_transfer - x_return_status'||x_return_status);
               display_out('In create_maintain_transfer validate_transfer - x_return_status'||x_return_status);              
              DBMS_OUTPUT.PUT_LINE('In create_maintain_transfer validate_transfer - x_return_status'||x_return_status);
              
               display_log('In create_maintain_transfer validate_transfer - x_error_message'||x_error_message);
               display_out('In create_maintain_transfer validate_transfer - x_error_message'||x_error_message);
               dbms_output.put_line('In create_maintain_transfer validate_transfer - x_error_message'||x_error_message);
     
        -- Check validate transfer status
   
        IF (x_return_status = G_SUCCESS OR x_return_status <> G_SUCCESS) THEN
      
            display_log('In create_maintain_transfer IF condition - Validate succeed');  
            DBMS_OUTPUT.PUT_LINE('In create_maintain_transfer IF condition - Validate succeed');      

         -----------------------------------------------------------------------
         -- Check if shipping network exists between "From" and "To" org
         --  else create one.
         -----------------------------------------------------------------------

         lc_is_shipnet_exists := G_NO;

         OPEN lcu_shipnet_exists;
         FETCH lcu_shipnet_exists INTO lc_is_shipnet_exists;
         CLOSE lcu_shipnet_exists;

         IF lc_is_shipnet_exists = G_NO THEN
            ------------------------------------------------------------------
            -- If shipping network does not exists then create it dynamically.
            ------------------------------------------------------------------

            XX_GI_SHIPNET_CREATION_PKG.DYNAMIC_BUILD
                                  (p_from_organization_id          => gn_from_org_id   -- IN  PLS_INTEGER
                                  ,p_to_organization_id            => gn_to_org_id     -- IN  PLS_INTEGER
                                  ,p_transfer_type                 => NULL             -- IN  VARCHAR2
                                  ,p_fob_point                     => NULL             -- IN  VARCHAR2
                                  ,p_interorg_transfer_code        => NULL             -- IN  VARCHAR2
                                  ,p_receipt_routing_id            => NULL             -- IN  VARCHAR2
                                  ,p_internal_order_required_flag  => NULL             -- IN  VARCHAR2
                                  ,p_intransit_inv_account         => NULL             -- IN  PLS_INTEGER
                                  ,p_interorg_transfer_cr_account  => NULL             -- IN  PLS_INTEGER
                                  ,p_interorg_receivables_account  => NULL             -- IN  PLS_INTEGER
                                  ,p_interorg_payables_account     => NULL             -- IN  PLS_INTEGER
                                  ,p_interorg_price_var_account    => NULL             -- IN  PLS_INTEGER
                                  ,p_elemental_visibility_enabled  => NULL             -- IN  VARCHAR2
                                  ,p_manual_receipt_expense        => NULL             -- IN  VARCHAR2
                                  ,x_status                        => lc_status        -- OUT VARCHAR2
                                  ,x_error_code                    => ln_number        -- OUT PLS_INTEGER
                                  ,x_error_message                 => lc_err_msg       -- OUT VARCHAR2
                                  );
           /*
            IF lc_status = G_VALIDATION_ERROR THEN

               x_return_status := G_VALIDATION_ERROR;
               x_error_message := lc_err_msg;
               RETURN;
            END IF;*/
         END IF;
              
               display_log('In create_maintain_transfer after calling the DYNAMIC BUILD');
              DBMS_OUTPUT.PUT_LINE('In create_maintain_transfer after calling the DYNAMIC BUILD');
              
              DBMS_OUTPUT.PUT_LINE('l_out_line_tbl count - '||l_out_line_tbl.count);
         
         lc_first_record := G_YES;
         
         /*
         FOR i IN l_out_hdr_rec.FIRST .. l_out_hdr_rec.LAST
         LOOP
          
           display_log('In create_maintain_transfer before header insert');                 
          DBMS_OUTPUT.PUT_LINE ('In create_maintain_transfer before header insert');

                  -----------------------------------------------------------------------------------------
                  -- Insert transfer header information into the custom header table XX_GI_TRANSFER_HEADERS
                  -----------------------------------------------------------------------------------------
                  BEGIN
                     
                     INSERT INTO XX_GI_TRANSFER_HEADERS
                     (  
                         source_system
                        ,header_id
                        ,transfer_number
                        ,from_loc_nbr
                        ,from_org_id
                        ,from_org_code
                        ,from_org_name
                        ,to_loc_nbr
                        ,to_org_id
                        ,to_org_code
                        ,to_org_name
                        ,ship_to_location_id
                        ,trans_type_cd
                        ,transaction_type_id
                        ,doc_type_cd
                        ,source_creation_date
                        ,source_created_by
                        ,buyback_number
                        ,carton_count
                        ,transfer_cost
                        ,ship_date
                        ,shipped_qty
                        ,status
                        ,rcv_shipment_header_id
                        ,transaction_date
                        ,comments
                        ,created_by
                        ,creation_date
                        ,last_updated_by
                        ,last_update_date
                        ,last_update_login
                        ,source_subinv_cd
                        ,source_vendor_id
                        ,no_of_detail_lines
                        ,attribute_category
                        ,attribute1
                        ,attribute2
                        ,attribute3
                        ,attribute4
                        ,attribute5
                        ,attribute6
                        ,attribute7
                        ,attribute8
                        ,attribute9
                        ,attribute10
                        ,attribute11
                        ,attribute12
                        ,attribute13
                        ,attribute14
                        ,attribute15
                        ,error_code
                        ,error_message
                         )
                         VALUES
                         (
                         l_out_hdr_rec(i).source_system --source_system
                        ,XX_GI_TRANSFER_HEADERS_S.NEXTVAL --header_id
                        ,l_out_hdr_rec(i).transfer_number --transfer_number
                        ,l_out_hdr_rec(i).from_loc_nbr --from_location
                        ,l_out_hdr_rec(i).from_org_id --gn_from_org_id --from_org_id
                        ,l_out_hdr_rec(i).from_org_code --gc_from_org_code --from_org_code
                        ,l_out_hdr_rec(i).from_org_name --gc_from_org_name --from_org_name
                        ,l_out_hdr_rec(i).to_loc_nbr --p_in_hdr_rec.to_loc_nbr --to_location
                        ,l_out_hdr_rec(i).to_org_id --gn_to_org_id --to_org_id
                        ,l_out_hdr_rec(i).to_org_code --gc_to_org_code --to_org_code
                        ,l_out_hdr_rec(i).to_org_name --gc_to_org_name --to_org_name
                        ,l_out_hdr_rec(i).ship_to_location_id --gn_ship_to_location_id --ship_to_location_id
                        ,l_out_hdr_rec(i).trans_type_cd --p_in_hdr_rec.trans_type_cd --transaction_code
                        ,l_out_hdr_rec(i).transaction_type_id --gn_transaction_type_id--transaction_type_id
                        ,l_out_hdr_rec(i).doc_type_cd --p_in_hdr_rec.doc_type_cd --transaction_sub_type_code
                        ,l_out_hdr_rec(i).source_creation_date --p_in_hdr_rec.source_creation_date --source_creation_date
                        ,l_out_hdr_rec(i).source_created_by --p_in_hdr_rec.source_created_by --source_created_by
                        ,l_out_hdr_rec(i).buyback_number --p_in_hdr_rec.buyback_number --buyback_number
                        ,l_out_hdr_rec(i).carton_count --p_in_hdr_rec.carton_count --carton_count
                        ,l_out_hdr_rec(i).transfer_cost --p_in_hdr_rec.transfer_cost --transfer_cost
                        ,l_out_hdr_rec(i).ship_date --p_in_hdr_rec.ship_date --ship_date
                        ,l_out_hdr_rec(i).shipped_qty --p_in_hdr_rec.shipped_qty --shipped_qty
                        ,l_out_hdr_rec(i).status --'XX' --status
                        ,NULL --rcv_shipment_header_id
                        ,SYSDATE --transaction_date
                        ,l_out_hdr_rec(i).comments --p_in_hdr_rec.comments --comments
                        ,1--p_created_by --created_by
                        ,SYSDATE --p_creation_date --creation_date
                        ,1--p_created_by --last_updated_by
                        ,SYSDATE--p_creation_date --last_update_date
                        ,FND_GLOBAL.login_id --last_update_login
                        ,l_out_hdr_rec(i).source_subinv_cd --p_in_hdr_rec.source_subinv_cd --source_subinventory_code
                        ,l_out_hdr_rec(i).source_vendor_id --p_in_hdr_rec.source_vendor_id --source_vendor_id
                        ,NULL --no_of_detail_lines
                        ,NULL --attribute_category
                        ,NULL --attribute1
                        ,NULL --attribute2
                        ,NULL --attribute3
                        ,NULL --attribute4
                        ,NULL --attribute5
                        ,NULL --attribute6
                        ,NULL --attribute7
                        ,NULL --attribute8
                        ,NULL --attribute9
                        ,NULL --attribute10
                        ,NULL --attribute11
                        ,NULL --attribute12
                        ,NULL --attribute13
                        ,NULL --attribute14
                        ,NULL --attribute15
                        ,l_out_hdr_rec(i).error_code --error_code
                        ,l_out_hdr_rec(i).error_message --error_message
                         );
                     
                  EXCEPTION
                     WHEN OTHERS THEN

                        --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62706_TRNS_HDR_INS_ERR');
                        x_error_message := '(CREATE_MAINTAIN_TRANSFER Header Insert Error -): '||SQLERRM;
                        x_return_status := G_UNEXPECTED_ERROR;
                        display_log('CREATE_MAINTAIN_TRANSFER Header Insert Error -): '||SQLERRM);
                        DBMS_OUTPUT.PUT_LINE('CREATE_MAINTAIN_TRANSFER Header Insert Error -): '||SQLERRM);
                  END;

         END LOOP;*/
         
        /*
         FOR i IN l_out_line_tbl.FIRST..l_out_line_tbl.LAST
         LOOP
         
           display_log('In create_maintain_transfer before lines insert');         
           DBMS_OUTPUT.PUT_LINE('In create_maintain_transfer before lines insert');
                      

               BEGIN

                  ---------------------------------------------------
                  -- Insert transfer lines into XX_GI_TRANSFER_LINES
                  ---------------------------------------------------
                  
                  INSERT INTO XX_GI_TRANSFER_LINES
                (
                line_id
                ,header_id                
                ,item
                ,inventory_item_id
                ,item_description
                ,shipped_qty
                ,requested_qty
                ,received_qty
                ,from_loc_uom
                ,uom
                ,from_loc_unit_cost
                ,from_org_unit_cost
                ,currency_code 
                ,status
                ,receipt_date
                ,received_by
                ,transaction_header_id
                ,rcv_shipment_line_id
                ,mtl_transaction_id
                ,ebs_receipt_number
                ,from_org_item_serialized
                ,to_org_item_serialized
                ,keyrec
                ,created_by
                ,creation_date  
                ,last_updated_by
                ,last_update_date
                ,last_update_login
                ,request_id
                ,program_id
                ,program_application_id
                ,ebs_subinventory_code
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,error_code
                ,error_message
                )
                VALUES
                (
                 XX_GI_TRANSFER_LINES_S.nextval --line_id
                ,XX_GI_TRANSFER_HEADERS_S.currval --header_id                
                ,l_out_line_tbl(i).item --item
                ,l_out_line_tbl(i).inventory_item_id --inventory_item_id
                ,l_out_line_tbl(i).item_description --item_description
                ,l_out_line_tbl(i).shipped_qty --shipped_qty
                ,l_out_line_tbl(i).requested_qty  --requested_qty
                ,NULL --received_qty
                ,l_out_line_tbl(i).from_loc_uom --from_location_uom
                ,l_out_line_tbl(i).uom --uom
                ,l_out_line_tbl(i).from_loc_unit_cost --from_location_unit_cost
                ,l_out_line_tbl(i).from_org_unit_cost --from_org_unit_cost
                ,l_out_line_tbl(i).currency_code --currency_code 
                ,l_out_line_tbl(i).status --'XX' --status
                ,NULL --receipt_date
                ,NULL --received_by
                ,NULL --transaction_header_id
                ,NULL --rcv_shipment_line_id
                ,NULL --mtl_transaction_id
                ,NULL --ebs_receipt_number
                ,NULL --from_org_item_serialized
                ,NULL --to_org_item_serialized
                ,NULL --keyrec
                ,1--p_created_by --created_by
                ,SYSDATE--p_creation_date --creation_date  
                ,1--p_created_by --last_updated_by
                ,SYSDATE--p_creation_date --last_update_date
                ,FND_GLOBAL.login_id --last_update_login
                ,NULL --request_id
                ,NULL --program_id
                ,NULL --program_application_id
                ,l_out_line_tbl(i).ebs_subinventory_code --ebs_subinventory_code
                ,NULL --attribute_category
                ,NULL --attribute1
                ,NULL --attribute2
                ,NULL --attribute3
                ,NULL --attribute4
                ,NULL --attribute5
                ,NULL --attribute6
                ,NULL --attribute7
                ,NULL --attribute8
                ,NULL --attribute9
                ,NULL --attribute10
                ,NULL --attribute11
                ,NULL --attribute12
                ,NULL --attribute13
                ,NULL --attribute14
                ,NULL --attribute15
                ,l_out_line_tbl(i).error_code --NULL --error_code
                ,l_out_line_tbl(i).error_message --NULL --error_message
                );               
                  
               EXCEPTION
                  WHEN OTHERS THEN
                     --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62707_INSERT_ERR');
                     --FND_MESSAGE.SET_TOKEN('OBJ','transfer lines');
                     x_error_message := '(CREATE_MAINTAIN_TRANSFER Line Insert Error): '||SQLERRM;
                     x_return_status := G_UNEXPECTED_ERROR;
                    display_log('CREATE_MAINTAIN_TRANSFER Line Insert Error: '||SQLERRM);
                    DBMS_OUTPUT.PUT_LINE('CREATE_MAINTAIN_TRANSFER Line Insert Error: '||SQLERRM);
               END;

               
         END LOOP;*/
         
         -- Call procedure to insert into staging
              
              INSERT_INTO_STAGING
                        ( 
                         p_in_hdr_rec =>l_out_hdr_rec
                         ,p_in_line_tbl =>l_out_line_tbl
                         ,x_return_status =>x_return_status
                         ,x_error_message =>x_error_message
                         );
         
      ELSE
         
         x_return_status := G_VALIDATION_ERROR;
         x_error_message := x_error_message;
         display_log('In create_maintain_transfer else condition');
         
      END IF;

      x_return_status := G_SUCCESS;

   EXCEPTION
      WHEN OTHERS THEN
         x_error_message := '(CREATE_MAINTAIN_TRANSFER): '||SQLERRM;
         x_return_status := G_UNEXPECTED_ERROR;
         display_log('CREATE_MAINTAIN_TRANSFER: '||SQLERRM);
         DBMS_OUTPUT.PUT_LINE('CREATE_MAINTAIN_TRANSFER: '||SQLERRM);

       
   END CREATE_MAINTAIN_TRANSFER;
   -- +==========================================================================================+
   -- | Name        :  CREATE_EBS_SHIPMENT                                                           |
   -- |                                                                                          |
   -- | Description :  This procedure picks up the header and lines passed to this program which |
   -- |                 are in "OPEN" status and loads it into Open interface tables for the     |
   -- |                 standard program to pick up and updates the status in custom table to    |
   -- |                 "SHIP-INITIATED".                                                        |
   -- |                 returns  E => On validation/Derivation error.                            |
   -- |                 returns  S => On complete success.                                       |
   -- |                 returns  U => On unexpected error.                                       |
   -- +==========================================================================================+
   PROCEDURE CREATE_EBS_SHIPMENT
                       (
                        x_return_status     OUT NOCOPY VARCHAR2
                       ,x_error_message     OUT NOCOPY VARCHAR2
                       ,p_header_id         IN NUMBER                       
                       )
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
    EX_TRANS_WORK                  EXCEPTION;
    ln_request_count               PLS_INTEGER   :=0;
    gc_sqlerrm                  VARCHAR2(5000);
    gc_sqlcode                  VARCHAR2(20);

    ln_trans_work_request_id       fnd_concurrent_requests.request_id%type;
    --lc_msg varchar2(30) := 'Testing';
    lc_phase                       fnd_concurrent_requests.phase_code%type;
    gn_sleep                    PLS_INTEGER :=5;
    
    lc_call_worker      VARCHAR2(1) := 'N';

    -------------------
    --Declaring table types for bulk insert
    -------------------

    TYPE transaction_record_tbl_typ IS TABLE OF shipment_rec_type
    INDEX BY BINARY_INTEGER;
    lt_transaction_record transaction_record_tbl_typ;

    TYPE header_id_tbl_type IS TABLE OF xx_gi_transfer_headers.header_id%TYPE
    INDEX BY BINARY_INTEGER;
    lt_header_id_tbl_type header_id_tbl_type;

    TYPE source_system_tbl_type IS TABLE OF xx_gi_transfer_headers.source_system%TYPE
    INDEX BY BINARY_INTEGER;
    lt_source_system_tbl_type source_system_tbl_type;
     
    TYPE transfer_number_tbl_type IS TABLE OF xx_gi_transfer_headers.transfer_number%TYPE
    INDEX BY BINARY_INTEGER;
    lt_transfer_number_tbl_type transfer_number_tbl_type;
     
    TYPE from_org_id_tbl_type IS TABLE OF xx_gi_transfer_headers.from_org_id%TYPE
    INDEX BY BINARY_INTEGER;
    lt_from_org_id_tbl_type from_org_id_tbl_type;
     
    TYPE to_org_id_tbl_type IS TABLE OF  xx_gi_transfer_headers.to_org_id%TYPE
    INDEX BY BINARY_INTEGER;
    lt_to_org_id_tbl_type to_org_id_tbl_type;
     
    TYPE tran_type_id_tbl_type IS TABLE OF  xx_gi_transfer_headers.transaction_type_id%TYPE
    INDEX BY BINARY_INTEGER;
    lt_tran_type_id_tbl_type tran_type_id_tbl_type;
     
    TYPE from_loc_nbr_tbl_type IS TABLE OF                xx_gi_transfer_headers.from_loc_nbr%TYPE
    INDEX BY BINARY_INTEGER;
    lt_from_loc_nbr_tbl_type from_loc_nbr_tbl_type;
     
    TYPE to_loc_nbr_tbl_type IS TABLE OF                  xx_gi_transfer_headers.to_loc_nbr%TYPE
    INDEX BY BINARY_INTEGER;
    lt_to_loc_nbr_tbl_type to_loc_nbr_tbl_type;
     
    TYPE trans_type_cd_tbl_type IS TABLE OF   xx_gi_transfer_headers.trans_type_cd%TYPE
    INDEX BY BINARY_INTEGER;
    lt_trans_type_cd_tbl_type trans_type_cd_tbl_type;
     
    TYPE doc_type_cd_tbl_type IS TABLE OF xx_gi_transfer_headers.doc_type_cd%TYPE
    INDEX BY BINARY_INTEGER;
    lt_doc_type_cd_tbl_type doc_type_cd_tbl_type;
     
    TYPE source_created_by_tbl_type IS TABLE OF          xx_gi_transfer_headers.source_created_by%TYPE
    INDEX BY BINARY_INTEGER;
    lt_source_created_by_tbl_type source_created_by_tbl_type;
     
    TYPE source_creat_dt_tbl_type IS TABLE OF      xx_gi_transfer_headers.source_creation_date%TYPE
    INDEX BY BINARY_INTEGER;
    lt_source_creat_dt_tbl_type source_creat_dt_tbl_type;
     
    TYPE source_subinv_cd_tbl_type IS TABLE OF xx_gi_transfer_headers.source_subinv_cd%TYPE
    INDEX BY BINARY_INTEGER;
    lt_source_subinv_cd_tbl_type source_subinv_cd_tbl_type;
     
    TYPE carton_count_tbl_type IS TABLE OF  xx_gi_transfer_headers.carton_count%TYPE
    INDEX BY BINARY_INTEGER;     
    lt_carton_count_tbl_type carton_count_tbl_type;
     
    TYPE source_vendor_id_tbl_type IS TABLE OF    xx_gi_transfer_headers.source_vendor_id%TYPE
    INDEX BY BINARY_INTEGER;     
    lt_source_vendor_id_tbl_type source_vendor_id_tbl_type;
     
    TYPE ship_to_loc_id_tbl_type IS TABLE OF xx_gi_transfer_headers.ship_to_location_id%TYPE
    INDEX BY BINARY_INTEGER;
    lt_ship_to_loc_id_tbl_type ship_to_loc_id_tbl_type;
     
    TYPE buyback_number_tbl_type  IS TABLE OF xx_gi_transfer_headers.buyback_number%TYPE
    INDEX BY BINARY_INTEGER;
    lt_buyback_number_tbl_type buyback_number_tbl_type;
     
    TYPE line_id_tbl_type IS TABLE OF xx_gi_transfer_lines.line_id%TYPE
    INDEX BY BINARY_INTEGER;
    lt_line_id_tbl_type line_id_tbl_type;
     
    TYPE inventory_item_id_tbl_type  IS TABLE OF xx_gi_transfer_lines.inventory_item_id%TYPE
    INDEX BY BINARY_INTEGER;     
    lt_inventory_item_id_tbl_type inventory_item_id_tbl_type;
     
    TYPE shipped_qty_tbl_type IS TABLE OF xx_gi_transfer_lines.shipped_qty%TYPE
    INDEX BY BINARY_INTEGER;     
    lt_shipped_qty_tbl_type shipped_qty_tbl_type;
     
    TYPE item_tbl_type  IS TABLE OF xx_gi_transfer_lines.item%TYPE
    INDEX BY BINARY_INTEGER;
    lt_item_tbl_type item_tbl_type;
     
    TYPE uom_tbl_type IS TABLE OF xx_gi_transfer_lines.uom%TYPE
    INDEX BY BINARY_INTEGER;
    lt_uom_tbl_type uom_tbl_type;
     
    TYPE ebs_subinv_code_tbl_type IS TABLE OF    xx_gi_transfer_lines.ebs_subinventory_code%TYPE
    INDEX BY BINARY_INTEGER;     
    lt_ebs_subinv_code_tbl_type ebs_subinv_code_tbl_type;
     
    TYPE tran_header_id_tbl_type IS TABLE OF  xx_gi_transfer_lines.transaction_header_id%TYPE
    INDEX BY BINARY_INTEGER;
    lt_tran_header_id_tbl_type tran_header_id_tbl_type;

    
    TYPE trans_work_request_id_tbl_typ IS TABLE OF mtl_transactions_interface.request_id%type
    INDEX BY BINARY_INTEGER;
    lt_trans_work_request_id trans_work_request_id_tbl_typ;

    TYPE rowid_tbl_typ IS TABLE OF ROWID
    INDEX BY BINARY_INTEGER;
    lt_success_rowid      rowid_tbl_typ;
    lt_error_rowid        rowid_tbl_typ;

    G_LIMIT_SIZE          CONSTANT PLS_INTEGER :=  500;

    ln_load_batch_id               NUMBER;     
    
    -----------------------------------------------------------------
    -- Cursor to select transaction information for the given line id
    -----------------------------------------------------------------

    CURSOR lcu_transfer_dtls IS
    SELECT 
    xgth.header_id
    --,'XX_GI_XFER_'||xgth.source_system source_system    
    ,SUBSTR('XX_GI_XFER_'||xgth.source_system,1,30) source_system -- Need to handle in future
    ,xgth.transfer_number
    ,xgth.from_org_id
    ,xgth.to_org_id
    ,xgth.transaction_type_id
    ,xgth.from_loc_nbr
    ,xgth.to_loc_nbr
    ,xgth.trans_type_cd
    ,xgth.doc_type_cd
    ,xgth.source_created_by
    ,xgth.source_creation_date
    ,xgth.source_subinv_cd
    ,xgth.carton_count 
    ,xgth.source_vendor_id
    ,xgth.ship_to_location_id
    ,xgth.buyback_number
    ,xgtl.line_id
    ,xgtl.inventory_item_id
    ,xgtl.shipped_qty
    ,xgtl.item
    ,xgtl.uom
    ,xgtl.ebs_subinventory_code
    ,xgtl.transaction_header_id
    FROM    XX_GI_TRANSFER_HEADERS xgth
            ,XX_GI_TRANSFER_LINES xgtl
    WHERE 1=1
    AND xgth.header_id = xgtl.header_id
    AND xgth.header_id=NVL(p_header_id,xgth.header_id)
    AND xgth.status IN (G_PENDING_STATUS,G_PARTIAL_STATUS)
    AND xgtl.status=G_PENDING_STATUS;
    --AND xgth.source_created_by='SIV MQ';


    BEGIN

        display_log('----------------------------');        
        display_log('Starting create_ebs_shipment');
        display_log('----------------------------');
        
        display_out('----------------------------');    
        display_out('Starting create_ebs_shipment');
        display_out('----------------------------');
    
        display_log('In create_ebs_shipment p_header_id is-'||p_header_id);
        display_out('In create_ebs_shipment p_header_id is-'||p_header_id);


    OPEN lcu_transfer_dtls;

        LOOP
        
        BEGIN

        display_log('In create_ebs_shipment before fetching');
        dbms_output.put_line('In create_ebs_shipment before fetching');
        
        FETCH lcu_transfer_dtls BULK COLLECT INTO lt_transaction_record LIMIT G_LIMIT_SIZE;
        
        EXIT WHEN lt_transaction_record.count =0;
        
        IF lt_transaction_record.count<>0 THEN
                
        display_log('In create_ebs_shipment Loop');
        dbms_output.put_line('In create_ebs_shipment Loop');
        
            FOR i IN lt_transaction_record.first..lt_transaction_record.count
            
            LOOP
                
                lt_header_id_tbl_type(i)          :=    lt_transaction_record(i).header_id;
                lt_source_system_tbl_type(i)      :=    lt_transaction_record(i).source_system;
                lt_transfer_number_tbl_type(i)    :=    lt_transaction_record(i).transfer_number;
                lt_transfer_number_tbl_type(i)    :=    lt_transaction_record(i).transfer_number;
                lt_from_org_id_tbl_type(i)        :=    lt_transaction_record(i).from_org_id;
                lt_to_org_id_tbl_type(i)          :=    lt_transaction_record(i).to_org_id;
                lt_tran_type_id_tbl_type(i)       :=    lt_transaction_record(i).transaction_type_id;
                lt_from_loc_nbr_tbl_type(i)         :=    lt_transaction_record(i).from_loc_nbr;
                lt_to_loc_nbr_tbl_type(i)           :=    lt_transaction_record(i).to_loc_nbr;
                lt_trans_type_cd_tbl_type(i)   :=    lt_transaction_record(i).trans_type_cd;
                lt_doc_type_cd_tbl_type(i) :=    lt_transaction_record(i).doc_type_cd;
                lt_source_created_by_tbl_type(i)  :=    lt_transaction_record(i).source_created_by;
                lt_source_creat_dt_tbl_type(i)    :=    lt_transaction_record(i).source_creation_date;
                lt_source_subinv_cd_tbl_type(i) :=    lt_transaction_record(i).source_subinv_cd;
                lt_carton_count_tbl_type(i)       :=    lt_transaction_record(i).carton_count;
                lt_source_vendor_id_tbl_type(i)   :=    lt_transaction_record(i).source_vendor_id;
                lt_ship_to_loc_id_tbl_type(i)     :=    lt_transaction_record(i).ship_to_location_id;
                lt_buyback_number_tbl_type(i)     :=    lt_transaction_record(i).buyback_number;
                lt_line_id_tbl_type(i)            :=    lt_transaction_record(i).line_id;
                lt_inventory_item_id_tbl_type(i)  :=    lt_transaction_record(i).inventory_item_id;
                lt_shipped_qty_tbl_type(i)        :=    lt_transaction_record(i).shipped_qty*-1;
                lt_item_tbl_type(i)                :=    lt_transaction_record(i).item;
                lt_uom_tbl_type(i)                :=    lt_transaction_record(i).uom;
                lt_ebs_subinv_code_tbl_type(i)    :=    lt_transaction_record(i).ebs_subinventory_code;
                lt_tran_header_id_tbl_type(i)     :=    lt_transaction_record(i).transaction_header_id;

                UPDATE xx_gi_transfer_headers
                SET status = G_LOCKED_STATUS
                WHERE header_id = lt_header_id_tbl_type(i)
                AND   transfer_number = lt_transfer_number_tbl_type(i)
                AND   from_loc_nbr = lt_from_loc_nbr_tbl_type(i);
                
                UPDATE xx_gi_transfer_lines
                SET status = G_LOCKED_STATUS
                WHERE header_id = lt_header_id_tbl_type(i)
                AND   line_id = lt_line_id_tbl_type(i);
                
                
            END LOOP;
            
            ---------------------------------------------------------------
            --Deriving batch id to invoke transaction worker in sub batches
            ---------------------------------------------------------------
            
            SELECT xx_gi_transfer_batch_s.NEXTVAL
            INTO   ln_load_batch_id
            FROM   dual;

            display_log('In create_ebs_shipment before MTI Insert');  
            DBMS_OUTPUT.PUT_LINE('In create_ebs_shipment before MTI Insert');            

            FORALL i in 1..lt_transaction_record.COUNT
            
            INSERT INTO MTL_TRANSACTIONS_INTERFACE
                (
                transaction_interface_id
                ,transaction_header_id
                ,source_code                     
                ,source_header_id
                ,source_line_id
                ,process_flag
                ,validation_required
                ,transaction_mode
                ,last_update_date
                ,last_updated_by
                ,creation_date
                ,created_by
                ,last_update_login
                ,organization_id
                ,transaction_quantity
                ,transaction_uom
                ,transaction_date
                ,transaction_type_id
                ,inventory_item_id
                ,subinventory_code
                ,transfer_organization
                ,ship_to_location_id
                ,shipment_number
                ,transaction_reference
                ,attribute1
                ,attribute2            
                ,attribute3            
                ,attribute4            
                ,attribute5            
                ,attribute6 
                ,attribute7           
                ,attribute8
                ,attribute9
                ,attribute10
                )
            VALUES
                (
                MTL_MATERIAL_TRANSACTIONS_S.nextval --transaction_interface_id
                ,ln_load_batch_id                   --transaction_header_id
                ,lt_source_system_tbl_type(i)               --source_code
                ,lt_header_id_tbl_type(i)                    --source_header_id
                ,lt_line_id_tbl_type(i)                      --source_line_id
                ,1                                   --process_flag
                ,1                                   --validation_required
                ,DECODE(lc_call_worker,'Y',2,3)                                   --transaction_mode
                ,SYSDATE                             --last_update_date
                ,1                                   --last_updated_by
                ,SYSDATE                             --creation_date
                ,1                                   --created_by
                ,1                                   --last_update_login
                ,lt_from_org_id_tbl_type(i)                  --organization_id
                ,lt_shipped_qty_tbl_type(i)                  ---transaction_quantity
                ,lt_uom_tbl_type(i)                          --transaction_uom    
                ,SYSDATE                             --transaction_date
                ,lt_tran_type_id_tbl_type(i)                 --transaction_type_id
                ,lt_inventory_item_id_tbl_type(i)            --inventory_item_id
                ,lt_ebs_subinv_code_tbl_type(i)        --subinventory_code    
                ,lt_to_org_id_tbl_type(i)                    --transfer_organization
                ,lt_ship_to_loc_id_tbl_type(i)          --ship_to_location_id
                ,lt_transfer_number_tbl_type(i)              --shipment_number
                ,lt_header_id_tbl_type(i)                    --transaction_reference
                ,lt_from_loc_nbr_tbl_type(i)                   --attribute1    
                ,lt_to_loc_nbr_tbl_type(i)                     --attribute2
                ,lt_item_tbl_type(i)                          --attribute3
                ,lt_trans_type_cd_tbl_type(i)
                 ||'_'
                 ||lt_doc_type_cd_tbl_type(i)
                 ||'_'
                 ||lt_source_subinv_cd_tbl_type(i)           --attribute4
                ,lt_transfer_number_tbl_type(i)              --attribute5
                ,lt_source_created_by_tbl_type(i)            --attribute6           
                ,lt_source_creat_dt_tbl_type(i)         --attribute7            
                ,lt_carton_count_tbl_type(i)                 --attribute8
                ,lt_source_vendor_id_tbl_type(i)             --attribute9
                ,lt_buyback_number_tbl_type(i)               --attribute10    
                );
                
                                
         END IF;
         
         COMMIT;

            IF lc_call_worker = 'Y' THEN -- Added by krb
                -------------------------------
                --Submitting Transaction Worker
                -------------------------------
                ln_trans_work_request_id:= fnd_request.submit_request (application       => 'INV'
                                                              ,program           => 'INCTCW'
                                                              ,description       => NULL
                                                              ,start_time        => NULL
                                                              ,sub_request       => FALSE
                                                              ,argument1         => ln_load_batch_id
                                                              ,argument2         => 1 --Interface Table
                                                              ,argument3         => NULL
                                                              ,argument4         => NULL
                                                              );
                display_log('Transaction Worker Submitted for Sub Batch '||ln_load_batch_id||' with request id '||ln_trans_work_request_id);

                    IF ln_trans_work_request_id = 0 THEN
                        RAISE EX_TRANS_WORK;
                    END IF;

                ln_request_count:=ln_request_count+1;
                lt_trans_work_request_id(ln_request_count):=ln_trans_work_request_id;

                COMMIT;
         
            END IF; 
        
        EXCEPTION
                
        WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_error_message  := 'Unexpected error in create_ebs_shipment - '||gc_sqlerrm;
        display_log('Unexpected error in create_ebs_shipment - '||gc_sqlerrm);
        x_return_status := 2;
    
         
         END;
    
    END LOOP;
    
    CLOSE lcu_transfer_dtls;
    
        -------------------------------------------------------------------
        --Wait till all the Transaction Workers are complete for this Batch
        -------------------------------------------------------------------

           IF lc_call_worker = 'Y' THEN --Added by krb 
                IF lt_trans_work_request_id.count <>0 THEN
                    FOR i IN lt_trans_work_request_id.FIRST .. lt_trans_work_request_id.LAST
                        LOOP
            
                            LOOP
            
                                SELECT FCR.phase_code
                                INTO   lc_phase
                                FROM   FND_CONCURRENT_REQUESTS FCR
                                WHERE  FCR.request_id = lt_trans_work_request_id(i);
            
                                IF  lc_phase = 'C' THEN
                                EXIT;
                                ELSE
                                DBMS_LOCK.SLEEP(gn_sleep);
                                END IF;
            
                            END LOOP;
     
                        END LOOP;
     
               END IF;
            END IF; -- Added by krb

        EXCEPTION
        WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_error_message  := 'Unexpected error in create_ebs_shipment at request id status - '||gc_sqlerrm;
        display_log('Unexpected error in create_ebs_shipment at request id status - '||gc_sqlerrm);
        x_return_status := 2;


  END CREATE_EBS_SHIPMENT;
  

PROCEDURE RECONCILE_TRANSFER_SHIPMENT
                        (
                           x_error_code           OUT VARCHAR2--PLS_INTEGER
                           ,x_error_message        OUT VARCHAR2
                           )
    IS
    
    lc_delete_stg_line VARCHAR2(1) := 'N';
    lc_delete_mti_line VARCHAR2(1) := 'N';
    
    ln_header_id   xx_gi_transfer_headers.header_id%TYPE;
    ln_err_count NUMBER :=0;
    
    
    -- Cursor to select all the locked header records to compare with MMT and MTI
    
    CURSOR lcu_stg_hdr_lo_records
    IS
    SELECT  xgth.header_id
            ,xgth.transfer_number
            ,xgth.status
    FROM    xx_gi_transfer_headers xgth
    WHERE   xgth.status ='LO';
    --AND  xgth.source_created_by='SIV MQ';-- To be Removed
    
    
    -- Cursor to select the successful records from MMT
        
    CURSOR lcu_mmt_success_records(p_header_id IN NUMBER)
    IS    
    SELECT  xgth.header_id
            ,xgth.transfer_number
            ,xgtl.line_id
            ,mmt.shipment_number 
            ,xgth.from_loc_nbr
            ,xgth.to_loc_nbr
    FROM    mtl_material_transactions mmt
            ,xx_gi_transfer_headers xgth
            ,xx_gi_transfer_lines xgtl
    WHERE   xgth.header_id = xgtl.header_id
    AND     xgth.header_id = p_header_id
    AND     mmt.shipment_number = xgth.transfer_number
    AND     mmt.source_code = 'XX_GI_XFER_'||xgth.source_system
    AND     TO_CHAR(xgth.header_id) = mmt.transaction_reference
    AND     xgtl.line_id = mmt.source_line_id
    AND     mmt.attribute1 = xgth.from_loc_nbr
    AND     mmt.attribute2 = xgth.to_loc_nbr
    AND     xgth.status IN (G_LOCKED_STATUS,G_PARTIAL_STATUS) 
    AND     xgtl.status = G_LOCKED_STATUS;
    --AND     xgth.source_created_by='SIV MQ'; -- Need to be removed
     
    -- Cursor to select MTI interface error records
    
    CURSOR lcu_mti_error_records(p_header_id IN NUMBER)
    IS
    SELECT  mti.transaction_interface_id
            ,mti.transaction_header_id
            ,xgth.header_id
            ,xgth.transfer_number
            ,xgtl.line_id
            ,mti.shipment_number 
            ,xgth.from_loc_nbr
            ,xgth.to_loc_nbr
            ,mti.error_code
            ,mti.error_explanation
    FROM    mtl_transactions_interface mti
            ,xx_gi_transfer_headers xgth
            ,xx_gi_transfer_lines xgtl
    WHERE   xgth.header_id = xgtl.header_id
    AND     xgth.header_id = p_header_id
    AND     mti.shipment_number = xgth.transfer_number
    AND     mti.source_code = 'XX_GI_XFER_'||xgth.source_system  
    AND     TO_CHAR(xgth.header_id) = mti.transaction_reference
    AND     xgtl.line_id = mti.source_line_id
    AND     mti.attribute1 = xgth.from_loc_nbr
    AND     mti.attribute2 = xgth.to_loc_nbr
    AND     mti.process_flag     = G_INTERFACE_ERROR_FLAG
    AND     xgth.status IN (G_LOCKED_STATUS,G_PARTIAL_STATUS) 
    AND     xgtl.status = G_LOCKED_STATUS;
    --AND     xgth.source_created_by='SIV MQ'; -- Need to be removed 
    
    -- Cursor to select number of error records for given header id    
    
    CURSOR lcu_line_err_count(p_header_id IN NUMBER)
    IS
    SELECT  count(*) no_of_line_err_count
    FROM    xx_gi_transfer_lines xgtl
    WHERE   header_id=p_header_id
    AND     xgtl.status = G_ERROR_STATUS;
   


    BEGIN

              DBMS_OUTPUT.PUT_LINE('------------------------------------');
              DBMS_OUTPUT.PUT_LINE('Starting reconcile_transfer_shipment');
              DBMS_OUTPUT.PUT_LINE('------------------------------------');              
            
              display_log('-------------------------------------');
              display_log(' Starting reconcile_transfer_shipment');
              display_log('-------------------------------------');              
            
              display_out('------------------------------------');
              display_out('Starting reconcile_transfer_shipment');
              display_out('------------------------------------');

        FOR lcr_stg_hdr_lo_records IN lcu_stg_hdr_lo_records
        
            LOOP
    
  
              ln_header_id := lcr_stg_hdr_lo_records.header_id;
                
                
                DBMS_OUTPUT.PUT_LINE('In reconcile_transfer_shipment header loop ln_header_id - '|| ln_header_id);
                display_log('In reconcile_transfer_shipment header loop ln_header_id - '|| ln_header_id);
    
                    BEGIN
        
           
                    FOR lcr_mmt_success_records IN lcu_mmt_success_records(ln_header_id)
        
                    LOOP
                
                        DBMS_OUTPUT.PUT_LINE('  In reconcile_transfer_shipment success records loop line_id -'||lcr_mmt_success_records.line_id);                
                        display_log('   In reconcile_transfer_shipment success records loop line_id -'||lcr_mmt_success_records.line_id);
     
                        UPDATE  xx_gi_transfer_lines xgtl
                        SET     xgtl.status=G_CLOSED_STATUS
                                ,xgtl.last_updated_by      = FND_GLOBAL.user_id
                                ,xgtl.last_update_login    = FND_GLOBAL.login_id
                                ,xgtl.last_update_date     = SYSDATE
                        WHERE   xgtl.line_id = lcr_mmt_success_records.line_id
                        AND     xgtl.header_id = lcr_mmt_success_records.header_id;
     
                          IF lc_delete_stg_line = G_YES THEN
     
                            DELETE FROM xx_gi_transfer_lines
                            WHERE   line_id = lcr_mmt_success_records.line_id
                            AND     header_id = lcr_mmt_success_records.header_id
                            AND     status = G_CLOSED_STATUS;
     
                          END IF;
     
     
                      END LOOP;
     
                     EXCEPTION
                     WHEN OTHERS THEN
                     x_error_message := '(RECONCILE_TRANSFER_SHIPMENT Exception for mmt records): '||SQLERRM;
                     x_error_code := 2;--G_UNEXPECTED_ERROR;
                     display_log('Exception occured in reconcilation_transfer_shipment for mmt success records'||SQLERRM);
                    END ;
                                
     
           BEGIN
          
                FOR lcr_mti_error_records IN lcu_mti_error_records(ln_header_id)
                   LOOP
         
                       DBMS_OUTPUT.PUT_LINE('  In reconcile_transfer_shipment interface error records line_id'||lcr_mti_error_records.line_id);
                        display_log('   In reconcile_transfer_shipment interface error records line_id'||lcr_mti_error_records.line_id);
     
                        UPDATE  xx_gi_transfer_lines xgtl
                        SET     xgtl.status=G_ERROR_STATUS
                                ,xgtl.error_code =lcr_mti_error_records.error_code
                                ,xgtl.error_message = lcr_mti_error_records.error_explanation
                                ,xgtl.attribute15   = lcr_mti_error_records.transaction_interface_id
                                ,xgtl.last_updated_by      = FND_GLOBAL.user_id
                                ,xgtl.last_update_login    = FND_GLOBAL.login_id
                                ,xgtl.last_update_date     = SYSDATE
                        WHERE   xgtl.line_id = lcr_mti_error_records.line_id
                        AND     xgtl.header_id = lcr_mti_error_records.header_id;
     
                     IF lc_delete_mti_line = G_YES THEN
        
                        DELETE FROM mtl_transactions_interface 
                        WHERE transaction_interface_id = lcr_mti_error_records.transaction_interface_id
                        AND   process_flag = G_INTERFACE_ERROR_FLAG;
        
                        END IF;
                
                
     
                   END LOOP;
     
            EXCEPTION
            WHEN OTHERS THEN
            x_error_message := '(RECONCILE_TRANSFER_SHIPMENT Exception for mti records): '||SQLERRM;
            x_error_code := 2;--G_UNEXPECTED_ERROR;
            display_log('Exception occured in reconcile_transfer_shipment for mti records'||SQLERRM);
            END;
     
     
        OPEN lcu_line_err_count(ln_header_id);
     
        FETCH lcu_line_err_count INTO ln_err_count;
     
        CLOSE lcu_line_err_count;
        
        dbms_output.put_line('In reconcile_transfer_shipment error record count for the header_id-'||ln_header_id||'is - '||ln_err_count);
        display_log('In reconcile_transfer_shipment error record count for the header_id-'||ln_header_id||'is - '||ln_err_count);
     
               IF ln_err_count >0 THEN
     
               UPDATE xx_gi_transfer_headers xgth
                SET xgth.status=G_PARTIAL_STATUS
                    ,xgth.last_updated_by      = FND_GLOBAL.user_id
                    ,xgth.last_update_login    = FND_GLOBAL.login_id
                    ,xgth.last_update_date     = SYSDATE
                WHERE xgth.header_id = ln_header_id
                AND   xgth.status = G_LOCKED_STATUS;
     
               ELSE
     
              UPDATE xx_gi_transfer_headers xgth
                SET xgth.status=G_CLOSED_STATUS
                    ,xgth.last_updated_by      = FND_GLOBAL.user_id
                    ,xgth.last_update_login    = FND_GLOBAL.login_id
                    ,xgth.last_update_date     = SYSDATE
                WHERE xgth.header_id = ln_header_id
                AND   xgth.status = G_LOCKED_STATUS;
     
              END IF;
     

          END LOOP;
          
            EXCEPTION
            WHEN OTHERS THEN
             x_error_message := '(RECONCILE_TRANSFER_SHIPMENT Exception): '||SQLERRM;
             x_error_code := 2;--G_UNEXPECTED_ERROR;            
            display_log('Exception occured in reconcile_transfer_shipment header loop'||SQLERRM);
                
       
     END RECONCILE_TRANSFER_SHIPMENT;
 
PROCEDURE REPROCESS_TRANSFER
                        (
                           x_error_code           OUT VARCHAR2
                           ,x_error_message        OUT VARCHAR2
                           )
                           
IS

    l_hdr_rec xx_gi_transfer_headers%rowtype;
   
   --lt_hdr_tbl l_hdr_rec := l_hdr_rec();
   
    line_in_dtl           xx_gi_xfer_in_line_tbl_type := xx_gi_xfer_in_line_tbl_type();
   
    l_out_line_tbl        xx_gi_xfer_out_line_tbl_type := xx_gi_xfer_out_line_tbl_type();
    l_out_hdr_rec         xx_gi_xfer_out_hdr_type := xx_gi_xfer_out_hdr_type();
      
      

    CURSOR lcu_header_records
    IS
    SELECT * FROM
    xx_gi_transfer_headers xgth
    WHERE xgth.status in (G_ERROR_STATUS,G_PARTIAL_STATUS);
    --AND     xgth.source_created_by='SIV MQ'; -- Need to be removed
    
    CURSOR lcu_line_details(p_header_id IN NUMBER)
    IS
    SELECT * FROM
        xx_gi_transfer_lines xgtl
    WHERE xgtl.header_id=p_header_id
    AND   xgtl.status = G_ERROR_STATUS;
    


    BEGIN
    
        display_log('---------------------------');
        display_log('Starting reprocess_transfer');
        display_log('---------------------------');
        
        display_out('--------------------------');
        display_out('Starting reprocess_transfer');
        display_out('--------------------------');
        
        DBMS_OUTPUT.PUT_LINE('---------------------------');
        DBMS_OUTPUT.PUT_LINE('Starting reprocess_transfer');
        DBMS_OUTPUT.PUT_LINE('---------------------------');
        
    
    FOR lcr_header_record IN lcu_header_records
    
         LOOP
            l_hdr_rec := lcr_header_record;
                  
           
            DBMS_OUTPUT.PUT_LINE('In reprocess_transfer loop l_hdr_rec.header_id is '||l_hdr_rec.header_id||' Transfer Num -'||l_hdr_rec.transfer_number);          
            display_log('In reprocess_transfer loop l_hdr_rec.header_id is '||l_hdr_rec.header_id||' Transfer Num -'||l_hdr_rec.transfer_number);
            
                BEGIN
            
                    SELECT *
                    BULK COLLECT INTO 
                    line_in_dtl
                    FROM xx_gi_transfer_lines xgtl            
                    WHERE xgtl.header_id=l_hdr_rec.header_id
                    AND   xgtl.status = G_ERROR_STATUS;
                    
                    EXCEPTION
                    WHEN OTHERS THEN
                    display_log('Exception in reprocess_transfer bulk insert');
                    DBMS_OUTPUT.PUT_LINE('Exception in reprocess_transfer bulk insert');
                    x_error_message := 'Exception in reprocess_transfer bulk insert '||SQLERRM;
                    x_error_code := G_UNEXPECTED_ERROR;
                        
                
                END;
                
            /*         
            FOR i in line_in_dtl.FIRST..line_in_dtl.LAST
            LOOP
            
            DBMS_OUTPUT.PUT_LINE('In reprocess_transfer lines loop line_id is -'||line_in_dtl(i).line_id||'SKU-'||line_in_dtl(i).item);
            display_log('In reprocess_transfer lines loop line_id is -'||line_in_dtl(i).line_id||'SKU-'||line_in_dtl(i).item);
            
            END LOOP;*/
            
            IF line_in_dtl.COUNT>0 THEN
            
                BEGIN
                
                    display_log('In reprocess_transfer before calling validate_transfer');
                    DBMS_OUTPUT.PUT_LINE('In reprocess_transfer before calling validate_transfer');
                    
                    VALIDATE_TRANSFER
                    (
                    p_in_hdr_rec    =>l_hdr_rec     -- IN xx_gi_transfer_headers%rowtype
                    ,p_in_line_tbl   =>line_in_dtl     -- IN         xx_gi_xfer_in_line_tbl_type
                    ,x_out_hdr_rec   =>l_out_hdr_rec     -- OUT NOCOPY xx_gi_xfer_out_hdr_type
                    ,x_out_line_tbl  =>l_out_line_tbl  -- OUT NOCOPY xx_gi_xfer_out_line_tbl_type
                    ,x_return_status =>x_error_code --OUT NOCOPY VARCHAR2
                    ,x_error_message =>x_error_message --OUT NOCOPY VARCHAR2
                     );
            
                    display_log('In reprocess_transfer after calling validate_transfer');
                    DBMS_OUTPUT.PUT_LINE('In reprocess_transfer after calling validate_transfer');
                    
                    
                     
                     FOR i in l_out_hdr_rec.FIRST..l_out_hdr_rec.LAST
                     LOOP
                     
                     --l_out_hdr_rec(i).attribute14 := 'Ramesh Update'||SYSDATE;
                                         
                     display_log('In reprocess_transfer l_out_hdr_rec.header id is -'||l_out_hdr_rec(i).header_id||'Status'||l_out_hdr_rec(i).status||'Error code-'||l_out_hdr_rec(i).error_code);
                     
                     UPDATE xx_gi_transfer_headers
                     SET row = l_out_hdr_rec(i)
                     WHERE header_id = l_out_hdr_rec(i).header_id;
                     
                     END LOOP;
                     
                     
                     FOR i in l_out_line_tbl.FIRST..l_out_line_tbl.LAST
                     LOOP
                     display_log('In reprocess_transfer output table line_id value is -'||l_out_line_tbl(i).line_id||'SKU-'||l_out_line_tbl(i).item||'Status-'||l_out_line_tbl(i).status||' Error Code-'||l_out_line_tbl(i).error_code);
                     
                     --l_out_line_tbl(i).attribute14 := 'Ramesh Line Update'||SYSDATE;
                     
                     UPDATE xx_gi_transfer_lines
                     SET row = l_out_line_tbl(i)
                     WHERE line_id = l_out_line_tbl(i).line_id
                     AND   header_id = l_out_line_tbl(i).header_id;
                     
                     END LOOP;
                     
                   
                    EXCEPTION
                        WHEN OTHERS THEN                     
                        x_error_message := '(REPROCESS_TRANSFER Validate_Transfer call error): '||SQLERRM;
                        x_error_code := G_UNEXPECTED_ERROR;
                        display_log('REPROCESS_TRANSFER Validate_Transfer call error: '||SQLERRM);
                  END;
                  
            END IF;
            
          
            END LOOP;
    
    
    
    END REPROCESS_TRANSFER;
                           
    

END XX_GI_TRANSFER_PKG;
/
