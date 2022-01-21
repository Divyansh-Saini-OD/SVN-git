SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_GI_SUBINVXFR_PKG
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
-- | XX_GI_RCC_TRANSFER_STG       : I, S, U, D                                   |
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
-- |Draft1A  26-Feb-2008   Arun Andavar     Draft version                        |
-- |Draft1B  28-Feb-2008   Arun Andavar     Updated as table structure is        |
-- |                                         modified by onsite team.            |
-- |Draft1C  28-Feb-2008   Suresh Ponamblam Minor updations                      |
-- |1.0      29-Feb-2008   Vikas Raina      Baselined                            |
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
 -- +===================================================================+
 -- | Name             : VALIDATE_SUBINV_XFR_DATA                       |
 -- | Description      : This procedure validates the records from      |
 -- |                    POPULATE_SUBINV_XFR_DATA procedure and inserts |
 -- |                    into staging table mtl_material_transactions   |
 -- |                    table with updated values                      |
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
      ln_transaction_type_id PLS_INTEGER    := NULL;
      ln_organization_id     PLS_INTEGER    := NULL;

      ------------------------------------------------------------------
      --Cursor to get the EBS org id for the corresponding legacy org id
      ------------------------------------------------------------------
      CURSOR lcu_get_org_id(p_legacy_loc_id IN VARCHAR2)
      IS
      SELECT organization_id
      FROM   hr_all_organization_units 
      WHERE  attribute1 = p_legacy_loc_id
         ;
      -----------------------------------------------------------------------
      -- Cursor to derive transaction type id from the given transaction_type
      -----------------------------------------------------------------------
      CURSOR lcu_get_transaction_type
      IS
      SELECT MTT.transaction_type_id
      FROM   mtl_transaction_types MTT
      WHERE  UPPER(MTT.transaction_type_name) = G_SUBINV_XFR_TYPE
      ;
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
     lc_concat_hdr_err := NULL;
     lc_header_error_flag := G_NO;
     -------------------------------------
     -- Source System Type Mandatory check
     -------------------------------------
     IF x_detail_tbl(x_detail_tbl.FIRST).source_system IS NULL THEN

        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
        FND_MESSAGE.SET_TOKEN('COLUMN','source_system');
        lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
        lc_header_error_flag := G_YES;
     
     END IF;
    
     --------------------------
     -- Loc_nbr Mandatory check
     --------------------------
     IF x_detail_tbl(x_detail_tbl.FIRST).loc_nbr IS NULL THEN

        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
        FND_MESSAGE.SET_TOKEN('COLUMN','loc_nbr');
        lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
        lc_header_error_flag := G_YES;
     ELSE
        OPEN lcu_get_org_id(x_detail_tbl(x_detail_tbl.FIRST).loc_nbr);
        FETCH lcu_get_org_id INTO ln_organization_id;
        CLOSE lcu_get_org_id;

        IF ln_organization_id IS NULL THEN

           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62902_INVALID_LOC_ID');
           FND_MESSAGE.SET_TOKEN('LOC_ID',x_detail_tbl(x_detail_tbl.FIRST).loc_nbr);
           lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
           lc_header_error_flag := G_YES;

        END IF;
     END IF;
     ---------------------------------------------------
     -- Derive Subinventory transfer Transaction type id
     ---------------------------------------------------
      OPEN lcu_get_transaction_type;
      FETCH lcu_get_transaction_type INTO ln_transaction_type_id;
      CLOSE lcu_get_transaction_type;

      IF ln_transaction_type_id IS NULL THEN

        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62906_SUBINVXFR_TYP_ERR');
        lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
        lc_header_error_flag := G_YES;

      END IF;
     --------------------------------
     --Detail validations starts here
     --------------------------------
     FOR i IN x_detail_tbl.FIRST..x_detail_tbl.LAST
     LOOP
        lc_detail_error_flag                 := G_NO;
        lc_concat_dtl_err                    := NULL;
      -- x_detail_tbl(i).error_message        := lc_concat_hdr_err;
        x_detail_tbl(i).organization_id      := ln_organization_id;
     --------------------------------
     -- trans_type_cd Mandatory check
     --------------------------------
     IF x_detail_tbl(i).target_trans_type_cd IS NULL THEN

        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
        FND_MESSAGE.SET_TOKEN('COLUMN','trans_type_cd');
        lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
        lc_detail_error_flag := G_YES;
     ELSE

        IF SUBSTR(x_detail_tbl(i).target_trans_type_cd,6,2) NOT IN ('RT') THEN

           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62903_INVALID_DOC_TYPE');
           FND_MESSAGE.SET_TOKEN('DOC_TYPE',SUBSTR(x_detail_tbl(i).target_trans_type_cd,6,2));
           lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;

        END IF;
        
        IF SUBSTR(x_detail_tbl(i).target_trans_type_cd,1,4) NOT IN ('RVDD','RVSC') THEN
           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62904_INVLD_TRANS_TYPE');
           FND_MESSAGE.SET_TOKEN('TRANS_TYPE',SUBSTR(x_detail_tbl(i).target_trans_type_cd,6,2));
           lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;
        END IF;
        x_detail_tbl(i).from_subinventory := G_FROM_SUB_INVENTORY;
        -------------------------
        -- Derive to_subinventory
        -------------------------
        IF SUBSTR(x_detail_tbl(i).target_trans_type_cd,9,2) IS NOT NULL THEN
   
           IF SUBSTR(x_detail_tbl(i).target_trans_type_cd,9,2) NOT IN (G_DAMAGED_CODE,G_BUY_BACK_CODE) 
           THEN
   
              FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62908_INVALID_VALUE');
              FND_MESSAGE.SET_TOKEN('COLUMN','target_trans_type_cd(nineth and tenth characters)');
   
              lc_concat_dtl_err     := lc_concat_dtl_err||FND_MESSAGE.GET;
              lc_detail_error_flag := 'Y';
   
           ELSIF SUBSTR(x_detail_tbl(i).target_trans_type_cd,9,2) = G_BUY_BACK_CODE 
           THEN
   
              x_detail_tbl(i).to_subinventory := G_BUY_BACK;
   
           ELSIF SUBSTR(x_detail_tbl(i).target_trans_type_cd,9,2) = G_DAMAGED_CODE 
           THEN
   
              x_detail_tbl(i).to_subinventory := G_DAMAGED;
           END IF;
   
        ELSE
           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62909_SUBINV_SAME');
           lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;   
        END IF;
      
     END IF;
        
        ------------------------------------
        -- Transaction date Mandatory check
        ------------------------------------
        IF x_detail_tbl(i).transaction_date IS NULL THEN

           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
           FND_MESSAGE.SET_TOKEN('COLUMN','transaction_date');
           lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;
        
        END IF;
        ---------------------------------------
        -- Transaction Quantity Mandatory check
        ---------------------------------------
        IF x_detail_tbl(i).quantity IS NULL THEN

           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
           FND_MESSAGE.SET_TOKEN('COLUMN','quantity');
           lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;
        
        END IF;

        ------------------------------
        -- Item Number Mandatory check
        ------------------------------
        IF x_detail_tbl(i).sku IS NULL THEN

           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62901_MANDATORY_COLUMN');
           FND_MESSAGE.SET_TOKEN('COLUMN','sku');
           lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
           lc_detail_error_flag := G_YES;

        ELSE

           IF x_detail_tbl(x_detail_tbl.FIRST).organization_id IS NOT NULL THEN

              ---------------------------------------------------------------------
              -- Check if the item is vaild and transactable in given receiving org
              ---------------------------------------------------------------------
              OPEN  lcu_is_item_transactable(x_detail_tbl(i).sku,x_detail_tbl(x_detail_tbl.FIRST).organization_id);
              FETCH lcu_is_item_transactable INTO x_detail_tbl(i).item_id
                                                 ,x_detail_tbl(i).item_description
                                                 ,x_detail_tbl(i).primary_uom_cd
                                                 ;
              CLOSE lcu_is_item_transactable;
              
              IF x_detail_tbl(i).item_id IS NULL THEN

                 FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62905_INVALID_ITEM');
                 FND_MESSAGE.SET_TOKEN('SKU',x_detail_tbl(i).sku);
                 lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
                 lc_detail_error_flag := G_YES;

              END IF;

           END IF;

        END IF;
        x_detail_tbl(i).last_update_date        := SYSDATE;
        x_detail_tbl(i).last_update_login       := FND_GLOBAL.login_id;      
        x_detail_tbl(i).last_updated_by         := FND_GLOBAL.user_id;
        x_detail_tbl(i).created_by              := FND_GLOBAL.user_id;
        x_detail_tbl(i).creation_date           := SYSDATE;
        ----------------------------------------------------------------------------------
        -- After all validations. Check if no error then generate interface transaction id
        ----------------------------------------------------------------------------------
        IF lc_detail_error_flag = G_NO AND lc_header_error_flag = G_NO THEN
           ------------------------------------
           -- Generate transaction_interface_id
           ------------------------------------
      
            BEGIN
               SELECT mtl_material_transactions_s.nextval
               INTO   x_detail_tbl(i).transaction_interface_id
               FROM   DUAL;
            EXCEPTION
            WHEN OTHERS THEN
               x_return_status := G_UNEXPECTED_ERROR;
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62907_MTI_SEQ_ERR');
               FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
               x_return_message := FND_MESSAGE.GET;
               RETURN;
           END;

           BEGIN

              BEGIN
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
                 )
                 VALUES
                 (x_detail_tbl(i).transaction_interface_id
                 ,x_detail_tbl(i).source_system
                 ,x_detail_tbl(i).transaction_interface_id
                 ,x_detail_tbl(i).transaction_interface_id
                 ,1 --process flag
                 ,3 -- Transaction mode
                 ,2 --Lock flag
                 ,SYSDATE
                 ,FND_GLOBAL.user_id
                 ,SYSDATE
                 ,FND_GLOBAL.user_id
                 ,FND_GLOBAL.login_id
                 ,x_detail_tbl(i).organization_id
                 ,x_detail_tbl(i).quantity
                 ,x_detail_tbl(i).primary_uom_cd
                 ,x_detail_tbl(i).transaction_date
                 ,ln_transaction_type_id
                 ,x_detail_tbl(i).item_id
                 ,x_detail_tbl(i).from_subinventory
                 ,x_detail_tbl(i).to_subinventory
                 ,x_detail_tbl(i).organization_id
                 );
              EXCEPTION
                 WHEN OTHERS THEN
                    x_return_status := G_UNEXPECTED_ERROR;
                    FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62907_UNEXP_ERR');
                    FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
                    x_return_message := FND_MESSAGE.GET;
                    RETURN;
                 
              END;
           EXCEPTION
              WHEN OTHERS THEN
                 x_return_status := G_UNEXPECTED_ERROR;
                 FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62907_UNEXP_ERR');
                 FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
                 x_return_message := FND_MESSAGE.GET;
                 RETURN;
           END;
  

           x_detail_tbl(i).error_message := NULL;
           x_detail_tbl(i).status        := G_STG_LOCK_STATUS;
        ELSE
           x_detail_tbl(i).error_message := x_detail_tbl(i).error_message||lc_concat_dtl_err;
           x_detail_tbl(i).status        := G_STG_ERROR_STATUS;
           
        END IF;

        IF NVL(gc_no_insert_flag,G_NO) = G_NO THEN

           INSERT
           INTO xx_gi_rcc_transfer_stg
           VALUES x_detail_tbl(i);

        ELSIF gc_no_insert_flag = G_YES THEN

           FOR i IN x_detail_tbl.FIRST..x_detail_tbl.LAST
           LOOP

              UPDATE xx_gi_rcc_transfer_stg
              SET    transaction_interface_id =  x_detail_tbl(i).transaction_interface_id
                    ,loc_nbr                  = x_detail_tbl(i).loc_nbr               
                    ,organization_id          = x_detail_tbl(i).organization_id      
                    ,target_trans_type_cd     = x_detail_tbl(i).target_trans_type_cd 
                    ,sku                      = x_detail_tbl(i).sku             
                    ,item_description         = x_detail_tbl(i).item_description     
                    ,primary_uom_cd           = x_detail_tbl(i).primary_uom_cd       
                    ,item_id                  = x_detail_tbl(i).item_id              
                    ,from_subinventory        = x_detail_tbl(i).from_subinventory    
                    ,to_subinventory          = x_detail_tbl(i).to_subinventory      
                    ,source_system            = x_detail_tbl(i).source_system        
                    ,transaction_date         = x_detail_tbl(i).transaction_date     
                    ,country_cd               = x_detail_tbl(i).country_cd           
                    ,vendor_id                = x_detail_tbl(i).vendor_id            
                    ,ebs_vendor_id            = x_detail_tbl(i).ebs_vendor_id        
                    ,tm_stamp                 = x_detail_tbl(i).tm_stamp             
                    ,quantity                 = x_detail_tbl(i).quantity             
                    ,reason_cd                = x_detail_tbl(i).reason_cd            
                    ,status_cd                = x_detail_tbl(i).status_cd            
                    ,comments                 = x_detail_tbl(i).comments             
                    ,unit_cost                = x_detail_tbl(i).unit_cost            
                    ,extended_cost            = x_detail_tbl(i).extended_cost        
                    ,uom_cd                   = x_detail_tbl(i).uom_cd               
                    ,rtv_nbr                  = x_detail_tbl(i).rtv_nbr              
                    ,buyback_nbr              = x_detail_tbl(i).buyback_nbr          
                    ,worksheet_nbr            = x_detail_tbl(i).worksheet_nbr        
                    ,po_nbr                   = x_detail_tbl(i).po_nbr               
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
                    ,error_message            = x_detail_tbl(i).error_message   
               WHERE  ROWID                   = gt_rowid(i)
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


 -- +===================================================================+
 -- | Name             : POPULATE_SUBINV_XFR_DATA                       |
 -- | Description      : This process invokeds VALIDATE_SUBINV_XFR_DATA |
 -- | Parameters       : procedure.                                     |
 -- |                                                                   |
 -- | Returns          : x_retcode                                      |
 -- |                  : x_return_message                               |
 -- |                  : x_detail_tbl                                   |
 -- +===================================================================+
 
   PROCEDURE POPULATE_SUBINV_XFR_DATA(
                                       p_calling_pgm     IN      VARCHAR2     DEFAULT NULL
                                      ,x_detail_tbl      IN OUT  detail_tbl_type    
                                      ,x_return_status      OUT  VARCHAR2                    
                                      ,x_return_message     OUT  VARCHAR2                    
                                     )
   IS
   BEGIN


     IF NVL(p_calling_pgm,'API') = 'API' THEN

        VALIDATE_SUBINV_XFR_DATA(
                                  x_detail_tbl     => x_detail_tbl     -- IN OUT  detail_tbl_type    
                                 ,x_return_status  => x_return_status  --    OUT  VARCHAR2                    
                                 ,x_return_message => x_return_message --    OUT  VARCHAR2                    
                                );
-- If the records are being re-processed via concurrent program then                                
     ELSIF p_calling_pgm = 'CP' THEN

        SELECT STG.* 
        BULK COLLECT 
        INTO x_detail_tbl 
        FROM XX_GI_RCC_TRANSFER_STG STG
        WHERE STG.status = G_STG_ERROR_STATUS;
        
        SELECT ROWID
        BULK COLLECT 
        INTO gt_rowid 
        FROM XX_GI_RCC_TRANSFER_STG STG
        WHERE STG.status = G_STG_ERROR_STATUS;

        VALIDATE_SUBINV_XFR_DATA(
                                  x_detail_tbl     => x_detail_tbl     -- IN OUT  detail_tbl_type    
                                 ,x_return_status  => x_return_status  --    OUT  VARCHAR2                    
                                 ,x_return_message => x_return_message --    OUT  VARCHAR2                    
                                );

     END IF;
     
     COMMIT;
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
ln_err_rec_count NUMBER := 0;
ln_suc_rec_count NUMBER := 0;

BEGIN
FOR ln_upd_rec IN
(
 SELECT  STG.rowid 
        ,NULL err_exp
        ,'CL' STATUS
   FROM  xx_gi_rcc_transfer_stg STG
        ,mtl_material_transactions MMT
   WHERE STG.status             =  'LO'
   AND   MMT.source_line_id     = STG.Transaction_interface_id
   AND   MMT.rcv_transaction_id IS NULL
   UNION
   SELECT STG.rowid
        , MTI.error_explanation err_exp
        ,'EE' STATUS
   FROM   xx_gi_rcc_transfer_stg STG,
          mtl_transactions_interface MTI
   WHERE  STG.status                   =  'LO'
   AND    MTI.Transaction_interface_id = STG.Transaction_interface_id
   AND    MTI.process_flag             = 3 
)

LOOP

  IF ln_upd_rec.status = 'EE' THEN
    ln_err_rec_count := ln_err_rec_count +1 ;   
  ELSE
    ln_suc_rec_count := ln_suc_rec_count +1 ;   
  END IF;

  UPDATE xx_gi_rcc_transfer_stg
  SET    status          = ln_upd_rec.status
        ,error_message   = ln_upd_rec.err_exp
  WHERE ROWID            = ln_upd_rec.rowid;

END LOOP;
  FND_FILE>PUT_LINE(FND_FILE.OUTPUT,'Total records updated to Error status:  '||ln_err_rec_count );
  FND_FILE>PUT_LINE(FND_FILE.OUTPUT,'  ');
  FND_FILE>PUT_LINE(FND_FILE.OUTPUT,'Total records updated to Closed status: '||ln_suc_rec_count );
COMMIT;

EXCEPTION

WHEN OTHERS THEN
  ROLLBACK;
  x_return_message := SQLERRM;
  x_retcode  := 2;

END RECONCILE_SUBINV_XFR_DATA;

 -- +===================================================================+
 -- | Name             : REPROCESS_SUBINV_XFR_DATA                      |
 -- | Description      : This procedure retrieves all the records from  |
 -- |                    stage table in error status 'EE', which were   |
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
gc_no_insert_flag := G_YES;
-- Delete data which was processed and rejected by Material Transaction Processor.

DELETE from MTL_TRANSACTIONS_INTERFACE
WHERE process_flag = 3 
AND transaction_interface_id IN (SELECT transaction_interface_id 
                                 FROM xx_gi_rcc_transfer_stg
                                 WHERE status = 'EE'
                                );

-- Invoke POPULATE_SUBINV_XFR_DATA and pass the calling pgm parameter as 'CP' 
-- ensure that it picks error data from stage table.
             
   POPULATE_SUBINV_XFR_DATA (p_calling_pgm    => 'CP'
                            ,x_detail_tbl     => lt_detail_tbl
                            ,x_return_status  => lc_return_status
                            ,x_return_message => lc_return_message
                            );

   IF NVL(lc_return_status,'E') <> 'S' THEN
      RAISE EX_API_FAIL ; 
   END IF;

COMMIT;

EXCEPTION

WHEN OTHERS THEN
  ROLLBACK;
  x_return_message := lc_return_message||SQLERRM;
  x_retcode  := 2;

END REPROCESS_SUBINV_XFR_DATA;
END XX_GI_SUBINVXFR_PKG;
/
SHOW ERRORS;
EXIT