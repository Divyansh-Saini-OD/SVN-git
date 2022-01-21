CREATE OR REPLACE PACKAGE BODY APPS.XX_GI_SUBINVXFR_PKG1
--Version Draft 1A
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_SUBINVXFR_PKG                                           |
-- |Purpose      : This package contains procedures that validates the message   |
-- |                passed by Rice element I1106 and populates the EBS custom    |
-- |                table XX_GI_RCC_TRANSFER_STG and interface table             |
-- |                MTL_TRANSACTIONS_INTERFACE.                                  |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- | XX_GI_SUBINV_XFR             : I, S, U, D                                   |
-- | MTL_TRANSACTIONS_INTERFACE   : I                                            |
-- | MTL_SYSTEM_ITEMS_B           : S                                            |
-- | MTL_INTERORG_PARAMETERS      : S                                            |
-- | HR_ALL_ORGANIZATION_UNITS    : S                                            |
-- |                                                                             |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  25-Mar-2008   Ramesh Kurapati  Draft version                          |
-- +=============================================================================+
IS
   G_INV_ITEM_STATUS               CONSTANT VARCHAR2(15)  := 'A';
   G_SUBINV_XFR_TYPE               CONSTANT VARCHAR2(25)  := 'SUBINVENTORY TRANSFER';
   G_STG_ERROR_STATUS              CONSTANT VARCHAR2(5)   := 'EE';
   G_STG_LOCK_STATUS               CONSTANT VARCHAR2(5)   := 'LO';
   G_UNEXPECTED_ERROR              CONSTANT VARCHAR2(1)   := 'U';
   G_FROM_SUB_INVENTORY            CONSTANT VARCHAR2(10)   := 'STOCK';
   G_BUY_BACK                      CONSTANT VARCHAR2(20)  := 'BUYBACK';
   G_DAMAGED                       CONSTANT VARCHAR2(20)  := 'DAMAGED';
   G_STOCK                         CONSTANT VARCHAR2(20)  := 'STOCK';
   G_BUY_BACK_CODE                 CONSTANT VARCHAR2(20)  := 'BB';
   G_DAMAGED_CODE                  CONSTANT VARCHAR2(20)  := 'DD';
   G_YES                           CONSTANT VARCHAR2(1)   := 'Y';
   G_NO                            CONSTANT VARCHAR2(1)   := 'N';
   gc_no_insert_flag               VARCHAR2(1)            := NULL;
   TYPE gt_rowid_type IS TABLE OF VARCHAR2(200)
   INDEX BY BINARY_INTEGER;
   gt_rowid gt_rowid_type;

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

 -- +===================================================================+
 -- | Name             : VALIDATE_SUBINV_XFR_DATA                       |
 -- | Description      : This procedure validates the records from      |
 -- |                    POPULATE_SUBINV_XFR_DATA procedure and inserts |
 -- |                    into staging table       mtl_material_transactions table with updated   |
 -- |                    values                                         |
 -- |                                                                   |
 -- | Returns          : x_retcode                                      |
 -- |                  : x_return_message                               |
 -- +===================================================================+
   PROCEDURE VALIDATE_SUBINV_XFR_DATA(
                                      x_detail_tbl      IN OUT  detail_tbl_type
                                     ,x_return_status      OUT  VARCHAR2
                                     ,x_return_message     OUT  VARCHAR2
                                     )
   IS
      -------------------------
      -- Local Scalar Variables
      -------------------------
      lc_header_error_flag   VARCHAR2(1)    := NULL;
      lc_detail_error_flag   VARCHAR2(1)    := NULL;
      lc_concat_hdr_err      VARCHAR2(1000) := NULL;
      lc_concat_dtl_err      VARCHAR2(1000) := NULL;
      ln_transaction_type_id PLS_INTEGER := NULL;
      ln_organization_id     PLS_INTEGER := NULL;      
      ln_organization_code  mtl_parameters.organization_code%TYPE;
      ln_organization_name  hr_all_organization_units.name%TYPE;
      lc_error_code         xx_gi_subinv_xfr.error_code%TYPE := NULL;
      lc_error_message      xx_gi_subinv_xfr.error_message%TYPE;
      
      lc_return_status     VARCHAR2(1000);
      lc_return_message    VARCHAR2(1000);
      ln_sign   NUMBER;
      
      ------------------------------------------------------------------
      --Cursor to get the EBS org id for the corresponding legacy org id
      ------------------------------------------------------------------
      /*
      CURSOR lcu_get_org_id(p_legacy_loc_id IN VARCHAR2)
      IS
      SELECT organization_id
      FROM   hr_all_organization_units
      WHERE  attribute1 = p_legacy_loc_id        ;
      */
         
      CURSOR lcu_get_org_id(p_legacy_loc_id IN VARCHAR2)
      IS 
      SELECT HAOU.organization_id
            ,mp.organization_code
            ,HAOU.name
      FROM   hr_all_organization_units HAOU
            ,mtl_parameters mp
      WHERE  haou.organization_id = mp.organization_id 
      AND    HAOU.attribute1 =p_legacy_loc_id
      AND    SYSDATE BETWEEN NVL(HAOU.date_from,SYSDATE-1) AND NVL(HAOU.date_to,SYSDATE+1)
      ;
      -----------------------------------------------------------------------
      -- Cursor to derive transaction type id from the given transaction_type
      -----------------------------------------------------------------------
      /*
      CURSOR lcu_get_transaction_type
      IS
      SELECT MTT.transaction_type_id
      FROM   mtl_transaction_types MTT
      WHERE  UPPER(MTT.transaction_type_name) = G_SUBINV_XFR_TYPE
      ;*/
      ------------------------------------------------------------------------------
      -- Cursor to check if the item is transactable and serialized in the given org
      ------------------------------------------------------------------------------
      CURSOR lcu_is_item_transactable(p_item   IN mtl_system_items_b.segment1%TYPE
                                     ,p_org_id IN hr_all_organization_units.organization_id%TYPE
                                     )
      IS
      SELECT MSI.inventory_item_id
            ,MSI.description
            ,MSI.primary_uom_code
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
      
  
   BEGIN  
    display_log('---------------------------------');
    display_log('Starting validate_subinv_xfr_data');
    display_log('---------------------------------');    
    display_out('---------------------------------');
    display_out('Starting validate_subinv_xfr_data');
    display_out('---------------------------------');    
    DBMS_OUTPUT.PUT_LINE('---------------------------------');
    DBMS_OUTPUT.PUT_LINE('Starting validate_subinv_xfr_data');
    DBMS_OUTPUT.PUT_LINE('---------------------------------');            
    lc_concat_hdr_err := NULL;
    lc_header_error_flag := G_NO;     
     -------------------------------------
     -- Source System Type Mandatory check
     -------------------------------------
     /*
     IF x_detail_tbl(x_detail_tbl.FIRST).source_system IS NULL THEN
        --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
        --FND_MESSAGE.SET_TOKEN('COLUMN','source_system');
        --lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
        
        lc_header_error_flag := G_YES;
        lc_error_code := 'XX_GI_SUBINV_SOURCE_NULL';
        lc_error_message := 'Source System Null';
        lc_concat_hdr_err := lc_concat_hdr_err||lc_error_message;
     END IF;
     */
     --------------------------
     -- Loc_nbr Mandatory check
     --------------------------
     /*
     IF x_detail_tbl(x_detail_tbl.FIRST).loc_nbr IS NULL THEN
        --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
        --FND_MESSAGE.SET_TOKEN('COLUMN','loc_nbr');
        --lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
        lc_header_error_flag := G_YES;
        lc_error_code := 'XX_GI_SUBINV_LOC_NBR_NULL';
        lc_error_message := 'Loc Nbr Null';
        lc_concat_hdr_err := lc_concat_hdr_err||lc_error_message;
     ELSE
        OPEN lcu_get_org_id(x_detail_tbl(x_detail_tbl.FIRST).loc_nbr);
        FETCH lcu_get_org_id INTO ln_organization_id,ln_organization_code,ln_organization_name;
        CLOSE lcu_get_org_id;
        IF ln_organization_id IS NULL THEN
           --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62902_INVALID_LOC_ID');
           --FND_MESSAGE.SET_TOKEN('LOC_ID',x_detail_tbl(x_detail_tbl.FIRST).loc_nbr);
           --lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
           lc_header_error_flag := G_YES;
           lc_error_message := 'Org ID Null';
           lc_concat_hdr_err := lc_concat_hdr_err||lc_error_message;
        END IF;
     END IF;
     */
     /*
      IF x_detail_tbl(x_detail_tbl.FIRST).trans_type_cd IS NULL THEN
        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
        FND_MESSAGE.SET_TOKEN('COLUMN','trans_type_cd');
        lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
        lc_header_error_flag := G_YES;
        lc_error_code := 'XX_GI_SUBINV_TRANS_TYP_CD_NULL';
        lc_error_message := 'Trans Type CD Null';
     END IF;*/
          
     ---------------------------------------------------
     -- Derive Subinventory transfer Transaction type id
     ---------------------------------------------------
     /*
      OPEN lcu_get_transaction_type;
      FETCH lcu_get_transaction_type INTO ln_transaction_type_id;
      CLOSE lcu_get_transaction_type;
      IF ln_transaction_type_id IS NULL THEN
        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62906_SUBINVXFR_TYP_ERR');
        lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
        lc_header_error_flag := G_YES;
      END IF;
      */
     --------------------------------
     --Detail validations starts here
     --------------------------------
     FOR i IN x_detail_tbl.FIRST..x_detail_tbl.LAST
     LOOP     
        lc_detail_error_flag                 := G_NO;
        lc_concat_dtl_err                    := NULL;        
        --x_detail_tbl(i).error_message        := lc_concat_hdr_err;
        --x_detail_tbl(i).error_code           := lc_error_code;
        --x_detail_tbl(i).organization_id      := ln_organization_id;
        --x_detail_tbl(i).organization_code    := ln_organization_code;
        --x_detail_tbl(i).organization_name    := ln_organization_name;      
        
     -------------------------------------
     -- Source System Type Mandatory check
     -------------------------------------     
     IF x_detail_tbl(i).source_system IS NULL THEN
        --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
        --FND_MESSAGE.SET_TOKEN('COLUMN','source_system');
        --lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
        --lc_header_error_flag := G_YES;
        lc_detail_error_flag := G_YES;
        lc_error_code := 'XX_GI_SUBINV_SOURCE_NULL';
        lc_error_message := 'Source System Null';
        lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
     END IF;     
     --------------------------
     -- Loc_nbr Mandatory check
     --------------------------     
     IF x_detail_tbl(i).loc_nbr IS NULL THEN
        --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
        --FND_MESSAGE.SET_TOKEN('COLUMN','loc_nbr');
        --lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
        --lc_header_error_flag := G_YES;
        lc_detail_error_flag := G_YES;
        lc_error_code := 'XX_GI_SUBINV_LOC_NBR_NULL';
        lc_error_message := 'Loc Nbr Null';
        lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
     ELSE
        OPEN lcu_get_org_id(x_detail_tbl(i).loc_nbr);
        --DBMS_OUTPUT.PUT_LINE('In else loc_nbr is-'||x_detail_tbl(i).loc_nbr);
        FETCH lcu_get_org_id INTO ln_organization_id,ln_organization_code,ln_organization_name;
        CLOSE lcu_get_org_id;
        --lc_detail_error_flag := G_NO;
        IF ln_organization_id IS NULL THEN
           --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62902_INVALID_LOC_ID');
           --FND_MESSAGE.SET_TOKEN('LOC_ID',x_detail_tbl(i).loc_nbr);
           --lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
           --lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           --lc_header_error_flag := G_YES;
           lc_detail_error_flag := G_YES;
           lc_error_code := 'XX_GI_SUBINV_ORG_ID_NULL';
           lc_error_message := 'Org ID Null';
           lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
           ELSE
        x_detail_tbl(i).organization_id      := ln_organization_id;
        x_detail_tbl(i).organization_code    := ln_organization_code;
        x_detail_tbl(i).organization_name    := ln_organization_name;
        END IF;
     END IF;            
     --------------------------------
     -- trans_type_cd Mandatory check
     --------------------------------
     IF x_detail_tbl(i).trans_type_cd IS NULL THEN
        --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
        --FND_MESSAGE.SET_TOKEN('COLUMN','trans_type_cd');
        --lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
        lc_detail_error_flag := G_YES;
        lc_error_code := 'XX_GI_SUBINV_TRANS_TYP_CD_NULL';
        lc_error_message := 'Trans Type CD Null';
        lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
     ELSE
        IF SUBSTR(x_detail_tbl(i).trans_type_cd,6,2) NOT IN ('RT') THEN
           --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62903_INVALID_DOC_TYPE');
           --FND_MESSAGE.SET_TOKEN('DOC_TYPE',SUBSTR(x_detail_tbl(i).trans_type_cd,6,2));
           --lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;
           lc_error_code := 'XX_GI_SUBINV_TRANS_TYP_CD_INVL';
           lc_error_message := 'Invalid Trans Type/Doc Type CD';
           lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
        END IF;
        IF SUBSTR(x_detail_tbl(i).trans_type_cd,1,4) NOT IN ('RVDD','RVSC') THEN
           --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62904_INVLD_TRANS_TYPE');
           --FND_MESSAGE.SET_TOKEN('TRANS_TYPE',SUBSTR(x_detail_tbl(i).trans_type_cd,6,2));
           --lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;
           lc_error_code := 'XX_GI_SUBINV_TRANS_TYP_CD_INVL';
           lc_error_message := 'Invalid Trans Type CD';
           lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
        END IF;
                
        SELECT SIGN(x_detail_tbl(i).quantity) INTO ln_sign FROM DUAL;        
        
        IF ln_sign = 1 THEN        
        x_detail_tbl(i).from_subinventory := G_FROM_SUB_INVENTORY;        
        END IF;        
        -------------------------
        -- Derive to_subinventory
        -------------------------
        IF SUBSTR(x_detail_tbl(i).trans_type_cd,9,2) IS NOT NULL THEN
           IF SUBSTR(x_detail_tbl(i).trans_type_cd,9,2) NOT IN (G_DAMAGED_CODE,G_BUY_BACK_CODE)
           THEN
              --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62908_INVALID_VALUE');
              --FND_MESSAGE.SET_TOKEN('COLUMN','target_trans_type_cd(nineth and tenth characters)');
              --lc_concat_dtl_err     := lc_concat_dtl_err||FND_MESSAGE.GET;
              lc_detail_error_flag := G_YES;--'Y';
              lc_error_code := 'XX_GI_SUBINV_SUB_CD_INVL';
              lc_error_message := 'Invalid Sub Inventory CD';
              lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;              
           ELSIF SUBSTR(x_detail_tbl(i).trans_type_cd,9,2) = G_BUY_BACK_CODE
           THEN
              IF ln_sign = -1 THEN
              x_detail_tbl(i).from_subinventory := G_BUY_BACK;
              x_detail_tbl(i).to_subinventory := G_STOCK;
              ELSE
              x_detail_tbl(i).to_subinventory := G_BUY_BACK;
              END IF;
           ELSIF SUBSTR(x_detail_tbl(i).trans_type_cd,9,2) = G_DAMAGED_CODE
           THEN           
              IF ln_sign = -1 THEN
              x_detail_tbl(i).from_subinventory := G_DAMAGED;
              x_detail_tbl(i).to_subinventory := G_STOCK;
              ELSE
              x_detail_tbl(i).to_subinventory := G_DAMAGED;
              END IF;              
           END IF;
        ELSE
           --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62909_SUBINV_SAME');
           --lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;
           lc_error_code := 'XX_GI_SUBINV_SUB_CD_NULL';
           lc_error_message := 'Sub Inventory CD Null';
           lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
        END IF;
     END IF;     
        ---------------------------------------------------
        -- Derive Subinventory transfer Transaction type id
        ---------------------------------------------------
        --OPEN lcu_get_transaction_type;
        --FETCH lcu_get_transaction_type INTO ln_transaction_type_id;
        --CLOSE lcu_get_transaction_type;        
          BEGIN     
            XX_GI_COMN_UTILS_PKG.get_gi_trx_type_id ( p_legacy_trx =>SUBSTR(x_detail_tbl(i).trans_type_cd,1,4)
                               ,p_legacy_trx_type =>SUBSTR(x_detail_tbl(i).trans_type_cd,9,2)
                               ,p_trx_action  =>'Subinventory'
                               ,x_trx_type_id =>ln_transaction_type_id
                               ,x_return_status =>lc_return_status
                               ,x_error_message =>lc_return_message
                         );                         
                    display_log('In validate_subinv_xfr_data xx_gi_comn_utils_pkg x_return_status -'||lc_return_status);
                    DBMS_OUTPUT.PUT_LINE('In validate_subinv_xfr_data xx_gi_comn_utils_pkg x_return_status -'||lc_return_status);
                         
                    IF ln_transaction_type_id IS NULL THEN
                    --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62906_SUBINVXFR_TYP_ERR');
                    --lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
                    --lc_header_error_flag := G_YES;
                    lc_detail_error_flag := G_YES;
                    lc_error_code := 'XX_GI_SUBINV_TRANS_ID_NULL';
                    lc_error_message := 'Transaction Type ID Null';
                    lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;                
                    ELSE
                    x_detail_tbl(i).transaction_type_id      := ln_transaction_type_id;
                    END IF;
          
            EXCEPTION WHEN OTHERS THEN
            lc_detail_error_flag := G_YES;
            lc_error_code := 'XX_GI_SUBINV_TRANS_ID_INVALID';
            lc_error_message := 'Exception at Transaction Type ID';
            lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
          END;
        ------------------------------------
        -- Transaction date Mandatory check
        ------------------------------------
        IF x_detail_tbl(i).transaction_date IS NULL THEN
           --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
           --FND_MESSAGE.SET_TOKEN('COLUMN','transaction_date');
           --lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;
           lc_error_code := 'XX_GI_SUBINV_TRANS_DT_NULL';
           lc_error_message := 'Transaction Date Null';
           lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
        END IF;
        ---------------------------------------
        -- Transaction Quantity Mandatory check
        ---------------------------------------
        IF x_detail_tbl(i).quantity IS NULL THEN
           --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
           --FND_MESSAGE.SET_TOKEN('COLUMN','quantity');
           --lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;
           lc_error_code := 'XX_GI_SUBINV_QTY_NULL';
           lc_error_message := 'Qty Null';
           lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
        END IF;
        ------------------------------
        -- Item Number Mandatory check
        ------------------------------
        IF x_detail_tbl(i).item IS NULL THEN
           --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
           --FND_MESSAGE.SET_TOKEN('COLUMN','item');
           --lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;
           lc_error_code := 'XX_GI_SUBINV_ITEM_NULL';
           lc_error_message := 'Item Null';
           lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
        ELSE        
           IF x_detail_tbl(i).organization_id IS NOT NULL THEN
              ---------------------------------------------------------------------
              -- Check if the item is vaild and transactable in given receiving org
              ---------------------------------------------------------------------
              OPEN  lcu_is_item_transactable(x_detail_tbl(i).item,x_detail_tbl(i).organization_id);
              FETCH lcu_is_item_transactable INTO x_detail_tbl(i).inventory_item_id
                                                 ,x_detail_tbl(i).item_description
                                                 ,x_detail_tbl(i).primary_uom_code
                                                 ;
              CLOSE lcu_is_item_transactable;              
              IF x_detail_tbl(i).inventory_item_id IS NULL THEN
                 --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62905_INVALID_ITEM');
                 --FND_MESSAGE.SET_TOKEN('ITEM',x_detail_tbl(i).item);
                 --lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
                 lc_detail_error_flag := G_YES;
                 lc_error_code := 'XX_GI_SUBINV_INV_ITEM_ID_NULL';
                 lc_error_message := 'Inventory Item ID Null';
                 lc_concat_dtl_err := lc_concat_dtl_err||lc_error_message;
              END IF;
           END IF;
        END IF;        
        --Set up standard who column values        
        x_detail_tbl(i).last_update_date        := SYSDATE;
        x_detail_tbl(i).last_update_login       := FND_GLOBAL.login_id;
        x_detail_tbl(i).last_updated_by         := FND_GLOBAL.user_id;
        x_detail_tbl(i).created_by              := FND_GLOBAL.user_id;
        x_detail_tbl(i).creation_date           := SYSDATE;
        ----------------------------------------------------------------------------------
        -- After all validations. Check if no error then generate interface transaction id
        ----------------------------------------------------------------------------------
        IF lc_detail_error_flag = G_NO AND lc_header_error_flag = G_NO
         THEN
           ------------------------------------
           -- Generate transaction_interface_id
           ------------------------------------
           /*
            BEGIN
               SELECT mtl_material_transactions_s.nextval
               INTO   x_detail_tbl(i).transaction_interface_id
               FROM   DUAL;
            EXCEPTION
            WHEN OTHERS THEN
               x_return_status := G_UNEXPECTED_ERROR;
               --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62907_MTI_SEQ_ERR');
               --FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
               --x_return_message := FND_MESSAGE.GET;
               x_return_message :=SQLCODE||SQLERRM;
               
               x_detail_tbl(i).error_message := SQLERRM;  
               x_detail_tbl(i).error_code    := 'XX_GI_SUBINV_MTI_INS_ERR';           
               x_detail_tbl(i).status        := G_STG_ERROR_STATUS;
                    
               INSERT
               --INTO xx_gi_rcc_transfer_stg
               INTO xx_gi_subinv_xfr
               VALUES x_detail_tbl(i);
               --RETURN;
            END;
            */                       
              BEGIN              
                SELECT mtl_material_transactions_s.nextval
                INTO   x_detail_tbl(i).transaction_interface_id
                FROM   DUAL;
               
                 INSERT
                 INTO  MTL_TRANSACTIONS_INTERFACE
                 (transaction_interface_id
                 ,source_code
                 ,source_line_id
                 ,source_header_id
                 ,process_flag
                 ,transaction_mode
                 ,lock_flag
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
                 ,transfer_subinventory
                 ,transfer_organization
                 ,attribute1
                 ,attribute2
                 ,attribute3
                 ,attribute4
                 ,attribute5
                 )
                 VALUES
                 (x_detail_tbl(i).transaction_interface_id --transaction_interface_id
                 ,SUBSTR('XX_GI_SUBINV_'||x_detail_tbl(i).source_system,1,30)--source_code
                 ,x_detail_tbl(i).transaction_interface_id--source_line_id
                 ,x_detail_tbl(i).transaction_interface_id--source_header_id
                 ,1 --process flag
                 ,3 -- Transaction mode
                 ,2 --Lock flag
                 ,SYSDATE--last_update_date
                 ,FND_GLOBAL.user_id--last_updated_by
                 ,SYSDATE--creation_date
                 ,FND_GLOBAL.user_id--created_by
                 ,FND_GLOBAL.login_id--last_update_login
                 ,x_detail_tbl(i).organization_id--organization_id
                 ,x_detail_tbl(i).quantity--transaction_quantity
                 ,x_detail_tbl(i).primary_uom_code--transaction_uom
                 ,x_detail_tbl(i).transaction_date--transaction_date
                 ,x_detail_tbl(i).transaction_type_id --transaction_type_id
                 ,x_detail_tbl(i).inventory_item_id--inventory_item_id
                 ,x_detail_tbl(i).from_subinventory--subinventory_code
                 ,x_detail_tbl(i).to_subinventory--transfer_subinventory
                 ,x_detail_tbl(i).organization_id--transfer_organization
                 ,x_detail_tbl(i).loc_nbr--attribute1
                 ,x_detail_tbl(i).loc_nbr--attribute2
                 ,x_detail_tbl(i).item--attribute3
                 ,x_detail_tbl(i).trans_type_cd--attribute4
                 ,x_detail_tbl(i).document_nbr--attribute5
                 );                 
              EXCEPTION
                 WHEN OTHERS THEN
                    x_return_status := G_UNEXPECTED_ERROR;
                    --FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62907_UNEXP_ERR');
                    --FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
                    --x_return_message := FND_MESSAGE.GET;
                    x_return_message := SQLERRM;                    
                    x_detail_tbl(i).error_message := SQLERRM;  
                    x_detail_tbl(i).error_code    := 'XX_GI_SUBINV_MTI_INS_ERR';           
                    x_detail_tbl(i).status        := G_STG_ERROR_STATUS;                    
                    INSERT           
                    INTO xx_gi_subinv_xfr
                    VALUES x_detail_tbl(i);
                    --RETURN;
              END;              
                      
           x_detail_tbl(i).error_code := NULL;
           x_detail_tbl(i).error_message := NULL;
           x_detail_tbl(i).status        := G_STG_LOCK_STATUS;           
        ELSE        
           x_detail_tbl(i).error_message := x_detail_tbl(i).error_message||lc_concat_dtl_err;  
           x_detail_tbl(i).error_code    := lc_error_code;           
           x_detail_tbl(i).status        := G_STG_ERROR_STATUS;           
        END IF;
        
        IF NVL(gc_no_insert_flag,G_NO) = G_NO THEN           
           INSERT           
           INTO xx_gi_subinv_xfr
           VALUES x_detail_tbl(i);                      
        ELSIF gc_no_insert_flag = G_YES THEN -- In case of reprocess data        
           FOR i IN x_detail_tbl.FIRST..x_detail_tbl.LAST           
           LOOP              
              UPDATE xx_gi_subinv_xfr
              SET    transaction_interface_id =  x_detail_tbl(i).transaction_interface_id
                    ,loc_nbr                  = x_detail_tbl(i).loc_nbr
                    ,organization_id          = x_detail_tbl(i).organization_id
                    ,organization_code        = x_detail_tbl(i).organization_code
                    ,organization_name        = x_detail_tbl(i).organization_name
                    ,trans_type_cd            = x_detail_tbl(i).trans_type_cd
                    ,transaction_type_id      = ln_transaction_type_id
                    ,item                     = x_detail_tbl(i).item
                    ,item_description         = x_detail_tbl(i).item_description
                    ,primary_uom_code         = x_detail_tbl(i).primary_uom_code
                    ,inventory_item_id        = x_detail_tbl(i).inventory_item_id
                    ,from_subinventory        = x_detail_tbl(i).from_subinventory
                    ,to_subinventory          = x_detail_tbl(i).to_subinventory
                    ,source_system            = x_detail_tbl(i).source_system
                    ,transaction_date         = x_detail_tbl(i).transaction_date
                    ,country_cd               = x_detail_tbl(i).country_cd
                    ,source_vendor_id         = x_detail_tbl(i).source_vendor_id
                    ,vendor_id                = x_detail_tbl(i).vendor_id
                    ,tm_stamp                 = x_detail_tbl(i).tm_stamp
                    ,quantity                 = x_detail_tbl(i).quantity
                    ,reason_cd                = x_detail_tbl(i).reason_cd
                    ,source_status_cd         = x_detail_tbl(i).source_status_cd
                    ,comments                 = x_detail_tbl(i).comments
                    ,unit_cost                = x_detail_tbl(i).unit_cost
                    ,extended_cost            = x_detail_tbl(i).extended_cost
                    ,uom_cd                   = x_detail_tbl(i).uom_cd
                    --,rtv_nbr                  = x_detail_tbl(i).rtv_nbr
                    ,buyback_nbr              = x_detail_tbl(i).buyback_nbr
                    ,worksheet_nbr            = x_detail_tbl(i).worksheet_nbr
                    ,document_nbr             = x_detail_tbl(i).document_nbr
                    ,keyrec_nbr               = x_detail_tbl(i).keyrec_nbr
                    ,vendor_product_cd        = x_detail_tbl(i).vendor_product_cd
                    ,misship_descr            = x_detail_tbl(i).misship_descr
                    ,po_cost                  = x_detail_tbl(i).po_cost
                    ,user_id_ent_by           = x_detail_tbl(i).user_id_ent_by
                    ,pgm_ent                  = x_detail_tbl(i).pgm_ent
                    ,license_plate            = x_detail_tbl(i).license_plate
                    ,rtv_attr                 = x_detail_tbl(i).rtv_attr
                    ,cashier_id               = x_detail_tbl(i).cashier_id
                    ,weight_ship              = x_detail_tbl(i).weight_ship
                    ,created_by               = x_detail_tbl(i).created_by
                    ,creation_date            = x_detail_tbl(i).creation_date
                    ,last_updated_by          = x_detail_tbl(i).last_updated_by
                    ,last_update_date         = x_detail_tbl(i).last_update_date
                    ,last_update_login        = x_detail_tbl(i).last_update_login
                    ,status                   = x_detail_tbl(i).status
                    ,attribute_category       = x_detail_tbl(i).attribute_category
                    ,attribute1               = x_detail_tbl(i).attribute1
                    ,attribute2               = x_detail_tbl(i).attribute2
                    ,attribute3               = x_detail_tbl(i).attribute3
                    ,attribute4               = x_detail_tbl(i).attribute4
                    ,attribute5               = x_detail_tbl(i).attribute5
                    ,attribute6               = x_detail_tbl(i).attribute6
                    ,attribute7               = x_detail_tbl(i).attribute7
                    ,attribute8               = x_detail_tbl(i).attribute8
                    ,attribute9               = x_detail_tbl(i).attribute9
                    ,attribute10              = x_detail_tbl(i).attribute10
                    ,attribute11              = x_detail_tbl(i).attribute11
                    ,attribute12              = x_detail_tbl(i).attribute12
                    ,attribute13              = x_detail_tbl(i).attribute13
                    ,attribute14              = x_detail_tbl(i).attribute14
                    ,attribute15              = x_detail_tbl(i).attribute15
                    ,error_code               = x_detail_tbl(i).error_code
                    ,error_message            = x_detail_tbl(i).error_message
               WHERE  ROWID = gt_rowid(i)
               ;
            END LOOP;
        END IF;
     END LOOP;
     x_return_status := 'S';
     x_return_message := NULL;
   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END VALIDATE_SUBINV_XFR_DATA;   
   PROCEDURE POPULATE_SUBINV_XFR_DATA(
                                       p_calling_pgm     IN      VARCHAR2     DEFAULT NULL
                                      ,x_detail_tbl      IN OUT  detail_tbl_type
                                      ,x_return_status      OUT  VARCHAR2
                                      ,x_return_message     OUT  VARCHAR2
                                     )
   IS
   BEGIN    
        display_log('---------------------------------');
        display_log('Starting populate_subinv_xfr_data');
        display_log('---------------------------------');
        display_out('---------------------------------');
        display_out('Starting populate_subinv_xfr_data');
        display_out('---------------------------------');
        DBMS_OUTPUT.PUT_LINE('---------------------------------');
        DBMS_OUTPUT.PUT_LINE('Starting populate_subinv_xfr_data');
        DBMS_OUTPUT.PUT_LINE('---------------------------------');    
     IF NVL(p_calling_pgm,'API') = 'API' THEN        
       BEGIN         
            VALIDATE_SUBINV_XFR_DATA(
                                  x_detail_tbl     => x_detail_tbl     -- IN OUT  detail_tbl_type
                                 ,x_return_status  => x_return_status  --    OUT  VARCHAR2
                                 ,x_return_message => x_return_message --    OUT  VARCHAR2
                                );
                                
                   display_log('In populate_subinv_xfr_data validate_subinv_xfr_data x_return_status -'||x_return_status);
                  DBMS_OUTPUT.PUT_LINE('In populate_subinv_xfr_data validate_subinv_xfr_data x_return_status -'||x_return_status);
       
        EXCEPTION 
        WHEN OTHERS THEN
        x_return_message := '(POPULATE_SUBINV_XFR_DATA): '||SQLERRM;
        x_return_status := G_UNEXPECTED_ERROR;
        display_log('Exception occured in populate_subinv_xfr_data while calling Validate_subinv_xfr_data -'||SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Exception occured in populate_subinv_xfr_data while calling Validate_subinv_xfr_data -'||SQLERRM);
        END;
     ELSIF p_calling_pgm = 'CP' THEN   
        SELECT STG.*
        BULK COLLECT
        INTO x_detail_tbl        
        FROM xx_gi_subinv_xfr stg
        WHERE STG.status = G_STG_ERROR_STATUS;
        SELECT ROWID
        BULK COLLECT
        INTO gt_rowid        
        FROM XX_GI_SUBINV_XFR STG
        WHERE STG.status = G_STG_ERROR_STATUS;
        
        BEGIN
        
            VALIDATE_SUBINV_XFR_DATA(
                                  x_detail_tbl     => x_detail_tbl     -- IN OUT  detail_tbl_type
                                 ,x_return_status  => x_return_status  --    OUT  VARCHAR2
                                 ,x_return_message => x_return_message --    OUT  VARCHAR2
                                    );
                                
                   display_log('In populate_subinv_xfr_data validate_subinv_xfr_data x_return_status -'||x_return_status);
                  DBMS_OUTPUT.PUT_LINE('In populate_subinv_xfr_data validate_subinv_xfr_data x_return_status -'||x_return_status);
                  
         EXCEPTION 
            WHEN OTHERS THEN
            x_return_message := '(POPULATE_SUBINV_XFR_DATA): '||SQLERRM;
            x_return_status := G_UNEXPECTED_ERROR;
            display_log('Exception occured in populate_subinv_xfr_data while calling Validate_subinv_xfr_data -'||SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Exception occured in populate_subinv_xfr_data while calling Validate_subinv_xfr_data -'||SQLERRM);
         END;
       
     END IF;
     --COMMIT;
   END POPULATE_SUBINV_XFR_DATA;
 -- +===================================================================+
 -- | Name             : RECONCILE_SUBINV_XFR_DATA                      |
 -- | Description      : This process updates the stage table to status |
 -- | Parameters       : 'EE' or 'LO' based upon the MTP result.        |
 -- |                                                                   |
 -- | Returns          : x_retcode                                      |
 -- |                  : x_return_message                               |
 -- +===================================================================+
 PROCEDURE RECONCILE_SUBINV_XFR_DATA (x_retcode        OUT NUMBER
                                     ,x_return_message OUT VARCHAR2
                                     )
IS
    BEGIN
        display_log('---------------------------------');
        display_log('Starting reconcile_subinv_xfr_data');
        display_log('---------------------------------');
        display_out('---------------------------------');
        display_out('Starting reconcile_subinv_xfr_data');
        display_out('---------------------------------');    
        DBMS_OUTPUT.PUT_LINE('---------------------------------');
        DBMS_OUTPUT.PUT_LINE('Starting reconcile_subinv_xfr_data');
        DBMS_OUTPUT.PUT_LINE('---------------------------------');
    
        FOR ln_upd_rec IN
        (
            SELECT  STG.rowid
                    ,STG.transaction_interface_id
                    ,NULL err_exp
                    ,NULL err_code
                    ,'CL' STATUS    
        FROM  xx_gi_subinv_xfr STG
              ,mtl_material_transactions MMT
        WHERE STG.status =  'LO'
        AND   MMT.source_line_id     = STG.Transaction_interface_id
        AND   MMT.source_code = 'XX_GI_SUBINV_'||STG.source_system
        AND   MMT.rcv_transaction_id IS NULL
        UNION
        SELECT STG.rowid
               ,MTI.transaction_interface_id
               ,MTI.error_explanation err_exp
               ,MTI.error_code err_code
               ,'EE' STATUS    
        FROM   xx_gi_subinv_xfr STG,
               mtl_transactions_interface MTI
        WHERE  STG.status                   =  'LO'
        AND    MTI.Transaction_interface_id = STG.Transaction_interface_id
        AND    MTI.source_code = 'XX_GI_SUBINV_'||STG.source_system
        AND    MTI.process_flag             = 3
        )

       LOOP
            UPDATE xx_gi_subinv_xfr 
            SET    status          = ln_upd_rec.status
                ,error_message   = ln_upd_rec.err_exp
                ,error_code      = ln_upd_rec.err_code
            WHERE ROWID            = ln_upd_rec.rowid;
  
           DELETE FROM mtl_transactions_interface MTI
            WHERE MTI.transaction_interface_id = ln_upd_rec.transaction_interface_id
             AND   MTI.process_flag=3;
        END LOOP;
    
        display_log('---------------------------------');
        display_log('End of reconcile_subinv_xfr_data');
        display_log('---------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
        display_log('Exception occured in reconcile_subinv_xfr_data');
        x_return_message := SQLERRM;
        x_retcode  := 2;
    END RECONCILE_SUBINV_XFR_DATA;
 -- +===================================================================+
 -- | Name             : REPROCESS_SUBINV_XFR_DATA                      |
 -- | Description      : This procedure retrieves all the records from  |
 -- |                    stage table in error status `EE¿, which were   |
 -- |                    rejected in previous runs, re-validates the    |
 -- |                    records and updates the stage table and        |
 -- |                    mtl_material_transactions table with updated   |
 -- |                    values                                         |
 -- |                                                                   |
 -- | Returns          : x_retcode                                      |
 -- |                  : x_return_message                               |
 -- +===================================================================+
PROCEDURE REPROCESS_SUBINV_XFR_DATA ( x_retcode        OUT NUMBER
                                     ,x_return_message OUT VARCHAR2
                                     )
IS
    lt_detail_tbl detail_tbl_type;
    lc_return_status      VARCHAR2(2);
    lc_return_message     VARCHAR2(500);
    EX_API_FAIL   EXCEPTION;

    BEGIN
        display_log('---------------------------------');
        display_log('Starting reprocess_subinv_xfr_data');
        display_log('---------------------------------');
        display_out('---------------------------------');
        display_out('Starting reprocess_subinv_xfr_data');
        display_out('---------------------------------');    
        DBMS_OUTPUT.PUT_LINE('---------------------------------');
        DBMS_OUTPUT.PUT_LINE('Starting reprocess_subinv_xfr_data');
        DBMS_OUTPUT.PUT_LINE('---------------------------------');
    
    
        gc_no_insert_flag := G_YES;

        -- Delete data which was processed and rejected by Material Transaction Processor.
        /*
        DELETE from MTL_TRANSACTIONS_INTERFACE
        WHERE process_flag = 3
        AND transaction_interface_id IN (SELECT transaction_interface_id
                                 --FROM xx_gi_rcc_transfer_stg
                                 FROM xx_gi_subinv_xfr
                                 WHERE status = 'EE'
                                );
                                */
        -- Invoke POPULATE_SUBINV_XFR_DATA and pass the calling pgm parameter as 'CP'
        -- ensure that it picks error data from stage table.

       POPULATE_SUBINV_XFR_DATA (p_calling_pgm    => 'CP'
                                ,x_detail_tbl     => lt_detail_tbl
                                ,x_return_status  => lc_return_status
                                ,x_return_message => lc_return_message
                                );
             display_log('In reprocess_subinv_xfr_data called populate_subinv_xfr_data x_return_status -'||lc_return_status);
             DBMS_OUTPUT.PUT_LINE('In reprocess_subinv_xfr_data called populate_subinv_xfr_data x_return_status -'||lc_return_status);

       IF NVL(lc_return_status,'E') <> 'S' THEN
          --RAISE EX_API_FAIL ;
        display_log('Error status in reprocess_subinv_xfr_data');
        x_return_message := lc_return_message||SQLERRM;
        x_retcode  := 2;      
       END IF;    
        display_log('---------------------------------');
        display_log('End of reprocess_subinv_xfr_data');
        display_log('---------------------------------');
    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    display_log('Exception occured in reprocess_subinv_xfr_data');
    x_return_message := lc_return_message||SQLERRM;
    x_retcode  := 2;
    END REPROCESS_SUBINV_XFR_DATA;
END XX_GI_SUBINVXFR_PKG1;
/
