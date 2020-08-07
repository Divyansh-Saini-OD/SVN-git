SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_GI_RECEIVING_PKG
--Version 1.0
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_RECEIVING_PKG                                           |
-- |Purpose      : This package contains procedures that are used to validate and|
-- |                populate the receiving information  on custom tables,        |
-- |                populate the Open interface tables                           |
-- |                                                                             |
-- |                                                                             |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- | XX_GI_RCV_KEYREC             : I, S, U                                      |
-- | XX_GI_RCV_PO_HDR             : I, S, U, D                                   |
-- | XX_GI_RCV_PO_DTL             : I, S, U, D                                   |
-- | RCV_TRANSACTIONS_INTERFACE   : I                                            |
-- | RCV_HEADERS_TERFACE          : I                                            |
-- | MTL_SYSTEM_ITEMS_B           : S                                            |
-- | HR_ALL_ORGANIZATION_UNITS    : S                                            |
-- |                                                                             |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  08-Jan-2008   Arun Andavar     Draft version                        |
-- |Draft1B  27-Jan-2008   Vikas Raina      Updated for updated MD050            |
-- |1.0      07-Feb-2008   Vikas Raina      Baselined                            |
-- |1.1      15-Feb-2008   Vikas Raina      Updated after testing with onsite    |
-- |1.2      18-Feb-2008   Vikas Raina      Updated for partial receiving        |
-- |1.3      28-Feb-08     Vikas Raina      Added procedures to CORRECT for      |
-- |                                        DELIVER and RECEIVE the Receipt      |
-- +=============================================================================+
IS
   -- ----------------------------------------
   -- Global constants used for error handling
   -- ----------------------------------------
   G_PROG_NAME                     CONSTANT VARCHAR2(50)  := 'XX_GI_RECEIVING_PKG';
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
   G_INV_ITEM_STATUS               CONSTANT VARCHAR2(15)  := 'A';
   G_BUY_BACK                      CONSTANT VARCHAR2(20)  := 'BUYBACK';
   G_DAMAGED                       CONSTANT VARCHAR2(20)  := 'DAMAGED';
   G_STOCK                         CONSTANT VARCHAR2(20)  := 'STOCK';
   G_BUY_BACK_CODE                 CONSTANT VARCHAR2(20)  := 'BB';
   G_DAMAGED_CODE                  CONSTANT VARCHAR2(20)  := 'DD';
   G_ADJUSTMENT_OR_ADD             CONSTANT VARCHAR2(20)  := 'OHDR';
   G_CORRECTION                    CONSTANT VARCHAR2(20)  := 'OHRE';   
   G_OPERATING_UNIT                CONSTANT VARCHAR2(10)  := 'org_id';
   G_OPEN_STATUS                   CONSTANT VARCHAR2(10)  := 'PRCP';
   G_CLOSED_STATUS                 CONSTANT VARCHAR2(10)  := 'CLOSED';
   G_RTI_ERROR_STATUS              CONSTANT VARCHAR2(10)  := 'E';
   G_VALIDATION_ERROR_STATUS       CONSTANT VARCHAR2(10)  := 'VE';
   G_LOCK_STATUS                   CONSTANT VARCHAR2(10)  := 'PL';
   G_PENDING                       CONSTANT VARCHAR2(10)  := 'PENDING';
   G_NEW                           CONSTANT VARCHAR2(10)  := 'NEW';
   G_DELIVER                       CONSTANT VARCHAR2(10)  := 'DELIVER';
   G_RECEIVE                       CONSTANT VARCHAR2(10)  := 'RECEIVE';
   G_CORRECT                       CONSTANT VARCHAR2(10)  := 'CORRECT';
   G_INVENTORY                     CONSTANT VARCHAR2(10)  := 'INVENTORY';
   G_VENDOR                        CONSTANT VARCHAR2(10)  := 'VENDOR';
   G_INTF_SRC                      CONSTANT VARCHAR2(10)  := 'RCV';
   G_BATCH                         CONSTANT VARCHAR2(10)  := 'BATCH';
   G_EMPLOYEE_ID                   CONSTANT NUMBER        := FND_GLOBAL.employee_id;
   G_INTERFACE_ERROR_FLAG          CONSTANT PLS_INTEGER   := 3;
   ------------------
   -- Other constants
   ------------------
   G_YES                           CONSTANT VARCHAR2(1)   := 'Y';
   G_NO                            CONSTANT VARCHAR2(1)   := 'N';
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
   gc_from_org_name                hr_all_organization_units.name%TYPE := NULL;
   -----------------
   -- Global cursors
   -----------------
   ------------------------------------------------------------------
   --Cursor to get the EBS org id for the corresponding legacy org id
   ------------------------------------------------------------------
   CURSOR gcu_get_org_id(p_legacy_loc_id IN VARCHAR2)
   IS
   SELECT organization_id
   FROM   hr_all_organization_units 
   WHERE  attribute1 = p_legacy_loc_id
   ;
   
   CURSOR gcu_get_item_id(p_item_number IN VARCHAR2
                         ,p_org_id IN NUMBER
                         )
   IS
    SELECT  MSIB.description
           ,MSIB.inventory_item_id
           ,MSIB.primary_uom_code
    FROM    mtl_system_items_b MSIB
    WHERE   MSIB.segment1 = p_item_number
    AND     MSIB.enabled_flag = 'Y'
    --AND     MSIB.inventory_item_status_code   = 'A' -- (Remove this comment when release)
    AND     SYSDATE 
    BETWEEN NVL (MSIB.start_date_active,SYSDATE-1) 
    AND     NVL(MSIB.end_date_active,SYSDATE)   
    AND     MSIB.organization_id = p_org_id
    ;

-- +===================================================================+
-- | Name             : VALIDATE_STG_PO_RECEIVING_DATA                 |
-- | Description      :                                                |
-- | Parameters       :       p_calling_pgm                            |
-- |                          x_header_rec                             |
-- |                          x_detail_tbl                             |
-- |                                                                   |
-- | Returns :                x_return_status                          |
-- |                          x_return_message                         |
-- +===================================================================+

PROCEDURE VALIDATE_STG_PO_RECEIVING_DATA(   p_calling_pgm     IN      VARCHAR2     DEFAULT NULL
                                           ,x_header_rec      IN OUT  xx_gi_rcv_po_hdr%ROWTYPE    
                                           ,x_detail_tbl      IN OUT  detail_tbl_type    
                                           ,x_return_status      OUT  VARCHAR2                    
                                           ,x_return_message     OUT  VARCHAR2                    
                                           )
   IS
      -------------------------
      -- Local Scalar Variables
      -------------------------
      ln_header_interface_id PLS_INTEGER    := NULL;
      lc_header_error_flag   VARCHAR2(1)    := NULL;
      lc_detail_error_flag   VARCHAR2(1)    := NULL;
      lc_concat_hdr_err      VARCHAR2(2000) := NULL;
      lc_concat_dtl_err      VARCHAR2(2000) := NULL;
      -------------
      --Record type
      -------------
     
      CURSOR lcu_po_information(p_item_id IN NUMBER
                               ,p_po_num IN VARCHAR2
                               ,p_po_line_num IN VARCHAR2
                               )
      IS
      SELECT PHA.po_header_id
            ,PLA.po_line_id
            ,PLA.unit_meas_lookup_code
            ,PLL.line_location_id
            ,PDA.po_distribution_id
            ,PHA.vendor_id
            ,PHA.vendor_site_id
            ,PLL.ship_to_location_id
            ,PLL.quantity - NVL(PLL.quantity_received,0) 
            ,PLA.unit_price
      FROM  po_headers_all        PHA
           ,po_lines_all          PLA
           ,po_line_locations_all PLL
           ,po_distributions_all  PDA
      WHERE PHA.segment1         = p_po_num
      AND   PHA.type_lookup_code = 'STANDARD'
      AND   NVL(PHA.closed_code,'OPEN')   <> 'CLOSED'
      AND   PHA.org_id           = FND_PROFILE.VALUE('org_id')
      AND   PHA.po_header_id     = PLA.po_header_id
      AND   PLA.line_num         = p_po_line_num
      AND   PLA.po_line_id       = PLL.po_line_id
      AND   PLL.line_location_id = PDA.line_location_id
      AND   PLA.item_id          = p_item_id
      ;
      
      CURSOR lcu_parent_transaction_id(p_po_line_id IN NUMBER
                                     , p_keyrec_nbr IN VARCHAR2
                                     , p_document_nbr IN VARCHAR2
                                     , p_loc_nbr IN NUMBER)
      IS 
      SELECT RT.transaction_id
            ,RSL.shipment_header_id
            ,RSL.shipment_line_id
      FROM   rcv_shipment_lines RSL
            ,rcv_transactions RT
      WHERE  RSL.po_line_id       = p_po_line_id
      AND    RSL.shipment_line_id = RT.shipment_line_id
      AND    RT.transaction_type  = G_DELIVER 
      AND    RSL.attribute8 = p_keyrec_nbr
      AND    RSL.attribute5 = p_document_nbr
      AND    RSL.attribute2 = p_loc_nbr;
      
      CURSOR lcu_existing_receipt(p_po_header_id IN NUMBER --                                
                                , p_keyrec_nbr IN VARCHAR2
                                , p_document_nbr IN VARCHAR2
                                , p_loc_nbr IN NUMBER)
      IS 
      SELECT RSL.shipment_header_id
      FROM   rcv_shipment_lines RSL
      WHERE  RSL.po_header_id     = p_po_header_id
      AND   attribute8 = p_keyrec_nbr
      AND   attribute5 = p_document_nbr
      AND   attribute2 = p_loc_nbr ;
      
   BEGIN
      lc_header_error_flag := 'N';
      lc_concat_hdr_err := NULL;
--      DBMS_OUTPUT.PUT_LINE('INSIDE VALIDATE 1');
      
      ---------------------------------------------------------------
      -- Check the Mandatory fields in the header record P_header_rec
      ---------------------------------------------------------------
      -------------------------------------
      -- Vendor information Mandatory check
      -------------------------------------
  /*    IF x_header_rec.vendor_num IS NULL OR x_header_rec.vendor_name IS NULL THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','vendor_num/vendor_name');
         lc_concat_hdr_err := FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;*/
      --------------------------------------------
      -- ship_to_organization_code Mandatory check
      --------------------------------------------
      IF x_header_rec.attribute2 IS NULL THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute2(legacy To org id)');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      ELSE
         --------------------------------
         -- Derive EBS to_organization_id
         --------------------------------
         OPEN gcu_get_org_id(x_header_rec.attribute2);
         FETCH gcu_get_org_id INTO x_header_rec.ship_to_organization_id;
         CLOSE gcu_get_org_id;
      END IF;
      ------------------------------------
      -- num_of_containers Mandatory check
      ------------------------------------
  /*    IF x_header_rec.num_of_containers IS NULL THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','num_of_containers');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;*/
      ------------------------------------------
      -- Legacy Transaction Type Mandatory check
      ------------------------------------------
      IF x_header_rec.attribute4 IS NULL THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(Legacy Transaction Type)');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;
      ------------------------------------------
      -- Legacy PO Number Mandatory check
      ------------------------------------------
      IF x_header_rec.attribute5 IS NULL THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute5(Legacy PO Number)');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;
      ------------------------------------------
      -- Legacy Created by Mandatory check
      ------------------------------------------
      IF x_header_rec.attribute6 IS NULL THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute6(Legacy Created by)');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;
      ------------------------------------------
      -- Legacy Creation Date Mandatory check
      ------------------------------------------
      IF x_header_rec.attribute7 IS NULL THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute7(Legacy Creation Date)');
         lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;
      -----------------------------
      -- Validate attribute4 values
      -----------------------------
      IF SUBSTR (NVL(x_header_rec.attribute4,'#'), 6,2) NOT IN ('PO') THEN
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(Sixth and Seventh characters)');
         lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      END IF;
      
      IF SUBSTR(NVL(x_header_rec.attribute4,'#'),1,4)NOT IN(G_ADJUSTMENT_OR_ADD,G_CORRECTION)THEN
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(first four characters)');
         lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      END IF;

      IF SUBSTR(x_header_rec.attribute4,9,2) IS NOT NULL THEN

         IF SUBSTR(x_header_rec.attribute4,9,2) NOT IN (G_DAMAGED_CODE,G_BUY_BACK_CODE) 
         THEN

            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
            FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(nineth and tenth characters)');
            lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
            lc_header_error_flag := 'Y';
         END IF;

      END IF;
--            DBMS_OUTPUT.PUT_LINE('INSIDE VALIDATE 2');
      --------------------------
      -- Default values required
      --------------------------
      x_header_rec.processing_status_code := G_PENDING;
      x_header_rec.validation_flag        := NULL; --G_YES;
      x_header_rec.receipt_source_code    := G_VENDOR;
      x_header_rec.transaction_type       := G_NEW;
      x_header_rec.auto_transact_code     := G_DELIVER;      
      
      x_header_rec.last_update_date       := SYSDATE;
      x_header_rec.last_updated_by        := FND_GLOBAL.user_id; 
      x_header_rec.last_update_login      := FND_GLOBAL.login_id;
      x_header_rec.created_by             := FND_GLOBAL.user_id;
      x_header_rec.creation_date          := SYSDATE;      

      -----------------------------------------------------------------------
      -- If there is any error in header validation then mark record as error
      -----------------------------------------------------------------------
      ---------------------
      -- Generate group id
      ---------------------
      BEGIN
         SELECT DECODE(x_header_rec.od_rcv_status_flag,NULL
                                                      ,rcv_interface_groups_s.NEXTVAL
                                                      ,x_header_rec.group_id
                      )
         INTO   x_header_rec.group_id
         FROM   DUAL;
      EXCEPTION
         WHEN OTHERS THEN
            x_return_status := G_UNEXPECTED_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62803_SEQ_ERR');
            FND_MESSAGE.SET_TOKEN('SEQ_NAME','RCV_INTERFACE_GROUP_S');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
            x_return_message := FND_MESSAGE.GET;
            RETURN;
      END;
      ---------------------
      -- Generate header id
      ---------------------
      BEGIN
         SELECT DECODE(x_header_rec.od_rcv_status_flag,NULL
                                                      ,rcv_headers_interface_s.NEXTVAL
                                                      ,x_header_rec.header_interface_id
                      )
         INTO   x_header_rec.header_interface_id
         FROM   DUAL;
      EXCEPTION
         WHEN OTHERS THEN
            x_return_status := G_UNEXPECTED_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62803_SEQ_ERR');
            FND_MESSAGE.SET_TOKEN('SEQ_NAME','RCV_HEADERS_INTERFACE_S');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
            x_return_message := FND_MESSAGE.GET;
            RETURN;
      END;

      IF lc_header_error_flag = G_YES THEN 

         x_header_rec.od_rcv_status_flag       := G_VALIDATION_ERROR_STATUS;
         x_header_rec.od_rcv_error_description := lc_concat_hdr_err;

      ELSE
         x_header_rec.od_rcv_status_flag       := G_OPEN_STATUS;
         x_header_rec.od_rcv_error_description := NULL;
      END IF;
      
     -- x_header_rec.od_rcv_status_flag       := G_OPEN_STATUS;
     -- x_header_rec.od_rcv_error_description := NULL;
--      DBMS_OUTPUT.PUT_LINE('INSIDE VALIDATE 3');
      ----------------------------------------
      --Validate and insert detail information
      ----------------------------------------
      IF x_detail_tbl.COUNT <> 0 THEN

         FOR i IN x_detail_tbl.FIRST..x_detail_tbl.LAST
         LOOP
            ------------------------------
            -- Re-initialize the variables
            ------------------------------
            lc_concat_dtl_err                       := NULL;
            lc_detail_error_flag                    := 'N';
            --------------------------
            -- Default values required
            --------------------------
            x_detail_tbl(i).processing_status_code  := G_PENDING;
            x_detail_tbl(i).transaction_status_code := G_PENDING;
            x_detail_tbl(i).validation_flag         := NULL;--G_YES;
            x_detail_tbl(i).interface_source_code   := G_INTF_SRC;
            x_detail_tbl(i).receipt_source_code     := G_VENDOR;
            x_detail_tbl(i).auto_transact_code      := G_DELIVER;
            x_detail_tbl(i).destination_type_code   := G_INVENTORY;  
            x_detail_tbl(i).processing_mode_code    := G_BATCH;
            x_detail_tbl(i).group_id                := x_header_rec.group_id;
            x_detail_tbl(i).header_interface_id     := x_header_rec.header_interface_id;
            x_detail_tbl(i).last_update_date        := SYSDATE;
            x_detail_tbl(i).last_update_login       := FND_GLOBAL.login_id;      
            x_detail_tbl(i).last_updated_by         := FND_GLOBAL.user_id;
            x_detail_tbl(i).created_by              := FND_GLOBAL.user_id;
            x_detail_tbl(i).creation_date           := SYSDATE;
            x_detail_tbl(i).employee_id             := x_header_rec.employee_id;

            ------------------------------------
            -- Transaction date Mandatory check
            ------------------------------------
            IF x_detail_tbl(i).transaction_date IS NULL THEN

               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
               FND_MESSAGE.SET_TOKEN('COLUMN','transaction_date');
               lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
            
            END IF;
            
            ------------------------------------
            -- document_num Mandatory check
            ------------------------------------
            IF x_detail_tbl(i).document_num IS NULL THEN
            
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
               FND_MESSAGE.SET_TOKEN('COLUMN','document_num');
               lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
               
            ELSE
               ------------------------------------
               -- document_line_num Mandatory check
               ------------------------------------
               IF x_detail_tbl(i).document_line_num IS NULL THEN
               
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
                  FND_MESSAGE.SET_TOKEN('COLUMN','document_line_num');
                  lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
                  lc_detail_error_flag := 'Y';

               ELSE
                  ------------------------------------
                  -- item_num Mandatory check
                  ------------------------------------
                  IF x_detail_tbl(i).item_num IS NULL THEN

                     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
                     FND_MESSAGE.SET_TOKEN('COLUMN','item_num');
                     lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
                     lc_detail_error_flag := 'Y';

                  ELSE

                     OPEN gcu_get_item_id(x_detail_tbl(i).item_num,x_header_rec.ship_to_organization_id);
                     FETCH gcu_get_item_id INTO x_detail_tbl(i).item_description
                                               ,x_detail_tbl(i).item_id
                                               ,x_detail_tbl(i).uom_code ;
                     CLOSE gcu_get_item_id;
                     
                     IF    x_detail_tbl(i).item_id IS NULL 
                        OR x_detail_tbl(i).item_description IS NULL 
                     THEN

                        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62807_INVALID_ITEM');
                        lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
                        lc_detail_error_flag := 'Y';

                     ELSE
                        ------------------------
                        -- Derive PO information
                        ------------------------
                        OPEN lcu_po_information(x_detail_tbl(i).item_id
                                               ,x_detail_tbl(i).document_num
                                               ,x_detail_tbl(i).document_line_num
                                               );
                        FETCH lcu_po_information INTO x_detail_tbl(i).po_header_id
                                                     ,x_detail_tbl(i).po_line_id
                                                     ,x_detail_tbl(i).unit_of_measure
                                                     ,x_detail_tbl(i).po_line_location_id
                                                     ,x_detail_tbl(i).po_distribution_id
                                                     ,x_detail_tbl(i).vendor_id
                                                     ,x_detail_tbl(i).vendor_site_id
                                                     ,x_detail_tbl(i).ship_to_location_id
                                                     ,x_detail_tbl(i).primary_quantity
                                                     ,x_detail_tbl(i).po_unit_price
                                                     ;
                        CLOSE lcu_po_information;
                        
                        x_header_rec.vendor_id :=  x_detail_tbl(i).vendor_id ;
                        
                        IF x_detail_tbl(i).po_header_id IS NULL THEN
                           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62810_INVLD_PO_FOR_RCV');
                           lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
                           lc_detail_error_flag := 'Y';
                        END IF;
                     END IF;
                  END IF;           
               END IF;
            END IF;
            
--      DBMS_OUTPUT.PUT_LINE('INSIDE VALIDATE 4');

            --------------------------------------------------------
            -- attribute2(Legacy to organization id) Mandatory check
            --------------------------------------------------------
            IF x_detail_tbl(i).attribute2 IS NULL THEN
            
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
               FND_MESSAGE.SET_TOKEN('COLUMN','attribute2(Legacy to organization_id)');
               lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
            ELSE
               --------------------------------
               -- Derive EBS to_organization_id
               --------------------------------
               OPEN gcu_get_org_id(x_detail_tbl(i).attribute2);
               FETCH gcu_get_org_id INTO x_detail_tbl(i).to_organization_id;
               CLOSE gcu_get_org_id;
            END IF;
            
            ---------------------------
            -- Quantity Mandatory check
            ---------------------------
            IF x_detail_tbl(i).attribute2 IS NULL THEN
            
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
               FND_MESSAGE.SET_TOKEN('COLUMN','Quantity');
               lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
            
            END IF;

            -----------------------------
            -- Validate attribute4 values
            -----------------------------
            IF SUBSTR (NVL(x_detail_tbl(i).attribute4,'#'), 6,2) NOT IN ('PO') THEN
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
               FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(Sixth and Seventh characters)');
               lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
            END IF;

            ---------------------------------------------------------------------------------
            -- Decide which transaction type to use based on legacy transaction type
            -- If transaction type is going to be correction then derive shipment information 
            -- and parent transaction id also
            ---------------------------------------------------------------------------------
            IF SUBSTR(NVL(x_detail_tbl(i).attribute4,'#'),1,4)NOT IN(G_ADJUSTMENT_OR_ADD,G_CORRECTION)THEN

               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
               FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(first four characters)');
               lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';

            ELSIF SUBSTR(NVL(x_detail_tbl(i).attribute4,'#'),1,4) = G_CORRECTION THEN
            
               x_detail_tbl(i).legacy_transaction_type := SUBSTR(x_detail_tbl(i).attribute4,1,4);

               OPEN lcu_parent_transaction_id(x_detail_tbl(i).po_line_id
                                             ,x_header_rec.attribute8 
                                             ,x_header_rec.attribute5
                                             ,x_detail_tbl(i).attribute2
                                             );
               FETCH lcu_parent_transaction_id INTO x_detail_tbl(i).parent_transaction_id
                                                   ,x_detail_tbl(i).shipment_header_id
                                                   ,x_detail_tbl(i).shipment_line_id;
               CLOSE lcu_parent_transaction_id;
               
               IF x_detail_tbl(i).parent_transaction_id IS NULL THEN
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62811_PARENT_TRNS_ID');
                  lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
                  lc_detail_error_flag := 'Y';
               END IF;

               x_detail_tbl(i).transaction_type :=  G_CORRECT;

            ELSE
               OPEN lcu_existing_receipt(x_detail_tbl(i).po_header_id                                      
                                        ,x_header_rec.attribute8 
                                        ,x_header_rec.attribute5
                                        ,x_detail_tbl(i).attribute2
                                        );
                                        
               FETCH lcu_existing_receipt 
               INTO x_detail_tbl(i).shipment_header_id; --,x_detail_tbl(i).shipment_line_id;
               
               IF lcu_existing_receipt%FOUND THEN
                  BEGIN
                     SELECT RSL.shipment_line_id
                     INTO   x_detail_tbl(i).shipment_line_id
		     FROM   rcv_shipment_lines RSL
		     WHERE  RSL.shipment_header_id  = x_detail_tbl(i).shipment_header_id
                     AND    RSL.item_id             = x_detail_tbl(i).item_id;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                         x_detail_tbl(i).shipment_line_id := NULL;
                  END;
                 
               END IF;
               
               CLOSE lcu_existing_receipt;
               x_detail_tbl(i).transaction_type :=  G_RECEIVE;
         
            END IF;
            ---------------------------------------
            -- Validate and store subinventory type
            ---------------------------------------
            IF SUBSTR(x_detail_tbl(i).attribute4,9,2) IS NOT NULL THEN

               IF SUBSTR(x_detail_tbl(i).attribute4,9,2) NOT IN (G_DAMAGED_CODE,G_BUY_BACK_CODE) 
               THEN

                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
                  FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(nineth and tenth characters)');

                  lc_concat_dtl_err     := lc_concat_dtl_err||FND_MESSAGE.GET;
                  lc_detail_error_flag := 'Y';

               ELSIF SUBSTR(x_detail_tbl(i).attribute4,9,2) = G_BUY_BACK_CODE 
               THEN

                  x_detail_tbl(i).subinventory := G_BUY_BACK;

               ELSIF SUBSTR(x_detail_tbl(i).attribute4,9,2) = G_DAMAGED_CODE 
               THEN

                  x_detail_tbl(i).subinventory := G_DAMAGED;
               END IF;

            ELSE

                  x_detail_tbl(i).subinventory := G_STOCK;

            END IF;
            ------------------------------------
            -- Generate interface transaction id
            ------------------------------------
            BEGIN
              SELECT DECODE(x_detail_tbl(i).od_rcv_status_flag,NULL
                                                              ,rcv_transactions_interface_s.nextval
                                                              ,x_detail_tbl(i).interface_transaction_id
                           )
              INTO   x_detail_tbl(i).interface_transaction_id
              FROM   DUAL;
            EXCEPTION
               WHEN OTHERS THEN
                  x_return_status := G_UNEXPECTED_ERROR;
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62803_SEQ_ERR');
                  FND_MESSAGE.SET_TOKEN('SEQ_NAME','RCV_TRANSACTIONS_INTERFACE_S');
                  FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
                  x_return_message := FND_MESSAGE.GET;
                  RETURN;
            END;

            IF lc_detail_error_flag = G_YES THEN

               x_detail_tbl(i).od_rcv_status_flag       := G_VALIDATION_ERROR_STATUS;
               x_detail_tbl(i).od_rcv_error_description := lc_concat_dtl_err;               
            ELSE
               x_detail_tbl(i).od_rcv_status_flag       := G_OPEN_STATUS;
               x_detail_tbl(i).od_rcv_error_description := NULL;

            END IF;

         END LOOP;         
         
      END IF;
--      DBMS_OUTPUT.PUT_LINE('INSIDE VALIDATE END');

   END VALIDATE_STG_PO_RECEIVING_DATA;
   
   -- +===================================================================+
   -- | Name             : VALIDATE_STG_XFR_RCV_DATA                      |
   -- | Description      :                                                |
   -- | Parameters       :                                                |
   -- |                                                                   |
   -- | Returns :          x_errbuf                                       |
   -- |                    x_retcode                                      |                                                      |
   -- |                                                                   |
   -- +===================================================================+
   
   PROCEDURE VALIDATE_STG_XFR_RCV_DATA(p_calling_pgm     IN      VARCHAR2     DEFAULT NULL
                                      ,x_header_rec      IN OUT  xx_gi_rcv_xfr_hdr%ROWTYPE    
                                      ,x_detail_tbl      IN OUT  detail_tbl_type    
                                      ,x_return_status      OUT  VARCHAR2                    
                                      ,x_return_message     OUT  VARCHAR2                    
                                      )
   IS
      -------------------------
      -- Local Scalar Variables
      -------------------------
      ln_header_interface_id PLS_INTEGER := NULL;
      lc_header_error_flag VARCHAR2(1) := NULL;
      lc_shipment_num_exists VARCHAR2(1) := NULL;
      lc_shipment_exists VARCHAR2(1) := NULL;
      lc_detail_error_flag VARCHAR2(1) := NULL;
      lc_concat_hdr_err VARCHAR2(2000) := NULL;
      lc_concat_dtl_err VARCHAR2(2000) := NULL;
      -------------
      --Record type
      -------------
      CURSOR lcu_parent_transaction_id(p_shipment_line_id IN NUMBER)
      IS 
      SELECT RT.parent_transaction_id
      FROM   rcv_transactions RT
      WHERE  RT.shipment_line_id = p_shipment_line_id
      AND    RT.transaction_type = G_DELIVER
      ;
      --------------------------------------------------------
      -- Cursor to check if the shipment number already exists
      --------------------------------------------------------
      CURSOR lcu_shipment_num_exists(p_shipment_number IN VARCHAR2
                                    )
      IS
      SELECT  'Y'
             ,shipment_header_id
      FROM    rcv_shipment_headers
      WHERE   shipment_num = p_shipment_number
      ;
      -------------------------------------------------
      -- Cursor to check if the shipment already exists
      -------------------------------------------------
      CURSOR lcu_shipment_exists(p_receipt_header_id IN NUMBER
                                ,p_item_id           IN NUMBER
                                )
      IS
      SELECT  'Y'
             ,shipment_line_id
             ,unit_of_measure
      FROM    rcv_shipment_lines                                                                 
      WHERE   shipment_header_id = p_receipt_header_id
      AND     item_id            = p_item_id
      ;

      
   BEGIN
      lc_header_error_flag := 'N';
      lc_concat_hdr_err := NULL;
--      DBMS_OUTPUT.PUT_LINE('INSIDE VALIDATE 1');

      ---------------------------------------------------------------
      -- Check the Mandatory fields in the header record P_header_rec
      ---------------------------------------------------------------
      -------------------------------------
      -- Legacy from org id Mandatory check
      -------------------------------------
      IF x_header_rec.attribute1 IS NULL THEN
   
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute2(legacy From org id)');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      ELSE
         ----------------------------------
         -- Derive EBS from_organization_id
         ----------------------------------
         OPEN gcu_get_org_id(x_header_rec.attribute1);
         FETCH gcu_get_org_id INTO x_header_rec.from_organization_id;
         CLOSE gcu_get_org_id;
      END IF;
      -----------------------------------
      -- Legacy to org id Mandatory check
      -----------------------------------
      IF x_header_rec.attribute2 IS NULL THEN
   
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute2(legacy To org id)');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      ELSE
         --------------------------------
         -- Derive EBS to_organization_id
         --------------------------------
         OPEN gcu_get_org_id(x_header_rec.attribute2);
         FETCH gcu_get_org_id INTO x_header_rec.ship_to_organization_id;
         CLOSE gcu_get_org_id;
      END IF;
      ------------------------------------
      -- num_of_containers Mandatory check
      ------------------------------------
   /*   IF x_header_rec.num_of_containers IS NULL THEN
   
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','num_of_containers');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;*/
      ------------------------------------------
      -- Legacy Transaction Type Mandatory check
      ------------------------------------------
      IF x_header_rec.attribute4 IS NULL THEN
   
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(Legacy Transaction Type)');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;
      ------------------------------------------
      -- Legacy Shipment Number Mandatory check
      ------------------------------------------
      IF x_header_rec.attribute5 IS NULL THEN
   
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute5(Legacy Shipment Number)');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      ELSE
         lc_shipment_num_exists := G_NO;
         -----------------------------------------------------------------------
         -- Check if shipment numbers exists if exists derive shipment header id
         -----------------------------------------------------------------------
         OPEN lcu_shipment_num_exists(x_header_rec.attribute5);
         FETCH lcu_shipment_num_exists INTO lc_shipment_num_exists
                                           ,x_header_rec.receipt_header_id;
         CLOSE lcu_shipment_num_exists;
         x_header_rec.shipment_num := x_header_rec.attribute5;
         
         IF lc_shipment_num_exists = G_NO THEN

            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62808_NO_SHIPMENT_NUM');
            lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
            lc_header_error_flag := 'Y';

         END IF;
      END IF;
      ------------------------------------------
      -- Legacy Created by Mandatory check
      ------------------------------------------
      IF x_header_rec.attribute6 IS NULL THEN
   
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute6(Legacy Created by)');
         lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;
      ------------------------------------------
      -- Legacy Creation Date Mandatory check
      ------------------------------------------
      IF x_header_rec.attribute7 IS NULL THEN
   
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute7(Legacy Creation Date)');
         lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      
      END IF;
      -----------------------------
      -- Validate attribute4 values
      -----------------------------
      IF SUBSTR (NVL(x_header_rec.attribute4,'#'), 6,2) NOT IN ('ST') THEN
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(Sixth and Seventh characters)');
         lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      END IF;
      
      IF SUBSTR(NVL(x_header_rec.attribute4,'#'),1,4)NOT IN(G_ADJUSTMENT_OR_ADD,G_CORRECTION)THEN
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
         FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(first four characters)');
         lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
         lc_header_error_flag := 'Y';
      ELSE
         x_header_rec.legacy_transaction_type := SUBSTR(x_header_rec.attribute4,1,4);
      END IF;
   
      IF SUBSTR(x_header_rec.attribute4,9,2) IS NOT NULL THEN
   
         IF SUBSTR(x_header_rec.attribute4,9,2) NOT IN (G_DAMAGED_CODE,G_BUY_BACK_CODE) 
         THEN
   
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
            FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(nineth and tenth characters)');
            lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
            lc_header_error_flag := 'Y';
         END IF;
   
      END IF;
      --------------------------
      -- Default values required
      --------------------------
      x_header_rec.processing_status_code := G_PENDING;
      x_header_rec.validation_flag        := G_YES;
      x_header_rec.receipt_source_code    := G_INVENTORY;
      x_header_rec.transaction_type       := G_NEW;
      x_header_rec.auto_transact_code     := G_DELIVER;  
      x_header_rec.last_update_date       := SYSDATE;
      x_header_rec.last_updated_by        := FND_GLOBAL.user_id; 
      x_header_rec.last_update_login      := FND_GLOBAL.login_id;
      x_header_rec.created_by             := FND_GLOBAL.user_id;
      x_header_rec.creation_date          := SYSDATE;  
      
      ---------------------
      -- Generate header id
      ---------------------
      
      BEGIN
         SELECT DECODE(x_header_rec.od_rcv_status_flag,NULL
                                                      ,rcv_headers_interface_s.NEXTVAL
                                                      ,x_header_rec.header_interface_id
                      )
         INTO   x_header_rec.header_interface_id
         FROM   DUAL;
      EXCEPTION
         WHEN OTHERS THEN
            x_return_status := G_UNEXPECTED_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62803_SEQ_ERR');
            FND_MESSAGE.SET_TOKEN('SEQ_NAME','RCV_HEADERS_INTERFACE_S');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
            x_return_message := FND_MESSAGE.GET;
            RETURN;
      END;
      ---------------------
      -- Generate group id
      ---------------------
      BEGIN
         SELECT DECODE(x_header_rec.od_rcv_status_flag,NULL
                                                      ,rcv_interface_groups_s.NEXTVAL
                                                      ,x_header_rec.group_id
                      )
         INTO   x_header_rec.group_id
         FROM   DUAL;

      EXCEPTION
         WHEN OTHERS THEN
            x_return_status := G_UNEXPECTED_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62803_SEQ_ERR');
            FND_MESSAGE.SET_TOKEN('SEQ_NAME','RCV_INTERFACE_GROUP_S');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
            x_return_message := FND_MESSAGE.GET;
            RETURN;
      END;

      -----------------------------------------------------------------------
      -- If there is any error in header validation then mark record as error
      -----------------------------------------------------------------------
      IF lc_header_error_flag = G_YES THEN 
   
         x_header_rec.od_rcv_status_flag       := G_VALIDATION_ERROR_STATUS;
         x_header_rec.od_rcv_error_description := lc_concat_hdr_err;
   
      ELSE
         x_header_rec.od_rcv_status_flag       := G_OPEN_STATUS;
         x_header_rec.od_rcv_error_description := NULL;
   
      END IF;
   
      ----------------------------------------
      --Validate and insert detail information
      ----------------------------------------
      IF x_detail_tbl.COUNT <> 0 THEN
   
         FOR i IN x_detail_tbl.FIRST..x_detail_tbl.LAST
         LOOP
            ------------------------------
            -- Re-initialize the variables
            ------------------------------
             fnd_file.put_line(fnd_file.log,'inside detail loop for header id: '||x_header_rec.header_interface_id);
            
            lc_concat_dtl_err                       := NULL;
            lc_detail_error_flag                    := 'N';
            --------------------------
            -- Default values required
            --------------------------
            x_detail_tbl(i).processing_status_code  := G_PENDING;
            x_detail_tbl(i).transaction_status_code := G_PENDING;
            x_detail_tbl(i).validation_flag         := G_YES;
            x_detail_tbl(i).interface_source_code   := G_INTF_SRC;
            x_detail_tbl(i).receipt_source_code     := G_INVENTORY;
            x_detail_tbl(i).destination_type_code   := G_INVENTORY;
            x_detail_tbl(i).auto_transact_code      := G_DELIVER;      
            x_detail_tbl(i).source_document_code    := G_INVENTORY;
            x_detail_tbl(i).processing_mode_code    := G_BATCH;
            x_detail_tbl(i).group_id                := x_header_rec.group_id;
            x_detail_tbl(i).header_interface_id     := x_header_rec.header_interface_id;
            x_detail_tbl(i).last_update_date        := SYSDATE;
            x_detail_tbl(i).last_update_login       := FND_GLOBAL.login_id;      
            x_detail_tbl(i).last_updated_by         := FND_GLOBAL.user_id;
            x_detail_tbl(i).created_by              := FND_GLOBAL.user_id;
            x_detail_tbl(i).creation_date           := SYSDATE;
            x_detail_tbl(i).employee_id             := x_header_rec.employee_id;
            ------------------------------------
            -- Transaction date Mandatory check
            ------------------------------------
            IF x_detail_tbl(i).transaction_date IS NULL THEN
   
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
               FND_MESSAGE.SET_TOKEN('COLUMN','transaction_date');
               lc_concat_dtl_err := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
            
            END IF;
            
            ------------------------------------
            -- item_num Mandatory check
            ------------------------------------
            IF x_detail_tbl(i).item_num IS NULL THEN
   
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
               FND_MESSAGE.SET_TOKEN('COLUMN','item_num');
               lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
   
            ELSE
   
               OPEN gcu_get_item_id(x_detail_tbl(i).item_num,x_header_rec.ship_to_organization_id);
               FETCH gcu_get_item_id INTO x_detail_tbl(i).item_description
                                         ,x_detail_tbl(i).item_id
                                         ,x_detail_tbl(i).uom_code ;
               CLOSE gcu_get_item_id;
           
               fnd_file.put_line(fnd_file.log,'item num not null');

               IF    x_detail_tbl(i).item_id IS NULL 
                  OR x_detail_tbl(i).item_description IS NULL 
               THEN
   
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62807_INVALID_ITEM');
                  lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
                  lc_detail_error_flag := 'Y';
   
               ELSE
                  lc_shipment_exists := G_NO;
                  fnd_file.put_line(fnd_file.log,'item_id '||x_detail_tbl(i).item_id);
                  ---------------------------------------------------------
                  -- Check if the shipment exist so that it can be received
                  ---------------------------------------------------------
                  OPEN lcu_shipment_exists(x_header_rec.receipt_header_id
                                          ,x_detail_tbl(i).item_id
                                          );
                  FETCH lcu_shipment_exists INTO lc_shipment_exists
                                                ,x_detail_tbl(i).shipment_line_id
                                                ,x_detail_tbl(i).unit_of_measure;
                  CLOSE lcu_shipment_exists;
                  
                  x_detail_tbl(i).shipment_header_id := x_header_rec.receipt_header_id;
                  
                  IF lc_shipment_exists = G_NO THEN
                     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62809_NO_SHIPMENT_EXIST');
                     lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
                     lc_detail_error_flag := 'Y';
                  END IF;
               END IF;
            END IF;           
       
            -------------------------------------
            -- Legacy from org id Mandatory check
            -------------------------------------
            IF x_detail_tbl(i).attribute1 IS NULL THEN
   
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
               FND_MESSAGE.SET_TOKEN('COLUMN','attribute2(legacy From org id)');
               lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
               lc_header_error_flag := 'Y';
            ELSE
               ----------------------------------
               -- Derive EBS from_organization_id
               ----------------------------------
               OPEN gcu_get_org_id(x_detail_tbl(i).attribute1);
               FETCH gcu_get_org_id INTO x_detail_tbl(i).from_organization_id;
               CLOSE gcu_get_org_id;
               
               IF x_detail_tbl(i).from_organization_id IS NULL THEN

                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
                  FND_MESSAGE.SET_TOKEN('COLUMN','attribute1');
                  lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
                  lc_header_error_flag := 'Y';

               END IF;
            END IF;
            -----------------------------------
            -- Legacy to org id Mandatory check
            -----------------------------------
            IF x_detail_tbl(i).attribute2 IS NULL THEN
   
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
               FND_MESSAGE.SET_TOKEN('COLUMN','attribute2(legacy To org id)');
               lc_concat_hdr_err := lc_concat_hdr_err||FND_MESSAGE.GET;
               lc_header_error_flag := 'Y';
            ELSE
               --------------------------------
               -- Derive EBS to_organization_id
               --------------------------------
               OPEN gcu_get_org_id(x_detail_tbl(i).attribute2);
               FETCH gcu_get_org_id INTO x_detail_tbl(i).to_organization_id;
               CLOSE gcu_get_org_id;

               IF x_detail_tbl(i).to_organization_id IS NULL THEN

                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
                  FND_MESSAGE.SET_TOKEN('COLUMN','attribute2');
                  lc_concat_hdr_err     := lc_concat_hdr_err||FND_MESSAGE.GET;
                  lc_header_error_flag := 'Y';

               END IF;
            END IF;
            
            ---------------------------
            -- Quantity Mandatory check
            ---------------------------
            IF x_detail_tbl(i).quantity IS NULL THEN
            
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62804_MANDATORY_COLUMN');
               FND_MESSAGE.SET_TOKEN('COLUMN','Quantity');
               lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
            
            END IF;
   
            -----------------------------
            -- Validate attribute4 values
            -----------------------------
            IF SUBSTR (NVL(x_detail_tbl(i).attribute4,'#'), 6,2) NOT IN ('ST') THEN
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
               FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(Sixth and Seventh characters)');
               lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
            END IF;
   
            ---------------------------------------------------------------------------------
            -- Decide which transaction type to use based on legacy transaction type
            -- If transaction type is going to be correction then derive shipment information 
            -- and parent transaction id also
            ---------------------------------------------------------------------------------
            IF SUBSTR(NVL(x_detail_tbl(i).attribute4,'#'),1,4)NOT IN(G_ADJUSTMENT_OR_ADD,G_CORRECTION)THEN
   
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
               FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(first four characters)');
               lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
               lc_detail_error_flag := 'Y';
   
            ELSIF SUBSTR(NVL(x_detail_tbl(i).attribute4,'#'),1,4) = G_CORRECTION THEN
            
               x_detail_tbl(i).legacy_transaction_type := SUBSTR(x_detail_tbl(i).attribute4,1,4);
   
               OPEN lcu_parent_transaction_id(x_detail_tbl(i).shipment_line_id);
               FETCH lcu_parent_transaction_id INTO x_detail_tbl(i).parent_transaction_id;
               CLOSE lcu_parent_transaction_id;
               
               IF x_detail_tbl(i).parent_transaction_id IS NULL THEN
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62811_PARENT_TRNS_ID');
                  lc_concat_dtl_err    := lc_concat_dtl_err||FND_MESSAGE.GET;
                  lc_detail_error_flag := 'Y';
               END IF;
   
               x_detail_tbl(i).transaction_type :=  G_CORRECT;
   
            ELSE
   
               x_detail_tbl(i).transaction_type :=  G_RECEIVE;
         
            END IF;
            ---------------------------------------
            -- Validate and store subinventory type
            ---------------------------------------
            IF SUBSTR(x_detail_tbl(i).attribute4,9,2) IS NOT NULL THEN
   
               IF SUBSTR(x_detail_tbl(i).attribute4,9,2) NOT IN (G_DAMAGED_CODE,G_BUY_BACK_CODE) 
               THEN
   
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62805_INVALID_VALUE');
                  FND_MESSAGE.SET_TOKEN('COLUMN','attribute4(nineth and tenth characters)');
   
                  lc_concat_dtl_err     := lc_concat_dtl_err||FND_MESSAGE.GET;
                  lc_detail_error_flag := 'Y';
   
               ELSIF SUBSTR(x_detail_tbl(i).attribute4,9,2) = G_BUY_BACK_CODE 
               THEN
   
                  x_detail_tbl(i).subinventory := G_BUY_BACK;
   
               ELSIF SUBSTR(x_detail_tbl(i).attribute4,9,2) = G_DAMAGED_CODE 
               THEN
   
                  x_detail_tbl(i).subinventory := G_DAMAGED;
               END IF;
   
           ELSE
              x_detail_tbl(i).subinventory := G_STOCK;
   
           END IF;
           ------------------------------------
           -- Generate interface transaction id
           ------------------------------------
           BEGIN
              SELECT DECODE(x_detail_tbl(i).od_rcv_status_flag,NULL
                                                              ,rcv_transactions_interface_s.nextval
                                                              ,x_detail_tbl(i).interface_transaction_id
                           )
              INTO   x_detail_tbl(i).interface_transaction_id
              FROM   DUAL;
           EXCEPTION
              WHEN OTHERS THEN
                 x_return_status := G_UNEXPECTED_ERROR;
                 FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62803_SEQ_ERR');
                 FND_MESSAGE.SET_TOKEN('SEQ_NAME','RCV_TRANSACTIONS_INTERFACE_S');
                 FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
                 x_return_message := FND_MESSAGE.GET;
                 RETURN;
           END;
   
            IF lc_detail_error_flag = G_YES THEN
                fnd_file.put_line(fnd_file.log,'Inside  IF lc_detail_error_flag = G_YES THEN');

               x_detail_tbl(i).od_rcv_status_flag       := G_VALIDATION_ERROR_STATUS;
               x_detail_tbl(i).od_rcv_error_description := lc_concat_dtl_err;
            ELSE         
               fnd_file.put_line(fnd_file.log,'Inside IF lc_detail_error_flag = G_OPEN_STATUS THEN');
               x_detail_tbl(i).od_rcv_status_flag       := G_OPEN_STATUS;
               x_detail_tbl(i).od_rcv_error_description := NULL;   
            END IF;
         END LOOP;
      END IF;
   END VALIDATE_STG_XFR_RCV_DATA;
   
   -- +===================================================================+
   -- | Name             : COMMON_KEYREC_LOGIC                            |
   -- | Description      :                                                |
   -- | Parameters       :       x_keyrec_rec                             |
   -- |                                                                   |
   -- | Returns :                x_return_status                          |
   -- |                          x_return_message                         |
   -- +===================================================================+

   PROCEDURE COMMON_KEYREC_LOGIC(x_keyrec_rec IN xx_gi_rcv_keyrec%ROWTYPE
                                ,x_return_status   OUT  VARCHAR2                    
                                ,x_return_message  OUT  VARCHAR2  
                                ) 
   IS
      -------------------------
      -- Local Scalar Variables
      -------------------------
      lc_keyrec_exists       VARCHAR2(1) := NULL;
      ln_keyrec_number       PLS_INTEGER := NULL;
      lr_keyrec_rec          xx_gi_rcv_keyrec%ROWTYPE := NULL;
      ----------------------------------------------------------------
      -- Cursor to check whether the keyrec exists in the keyrec table
      ----------------------------------------------------------------
      CURSOR lcu_keyrec_exists
      IS
      SELECT  'Y'
      FROM    xx_gi_rcv_keyrec XGRK
      WHERE   XGRK.keyrec_nbr = x_keyrec_rec.keyrec_nbr
      AND     XGRK.loc_nbr    = x_keyrec_rec.loc_nbr
      ;
   BEGIN
      lr_keyrec_rec := x_keyrec_rec;
      lr_keyrec_rec.status_cd :=  G_OPEN_STATUS;
            lr_keyrec_rec.last_update_date        := SYSDATE;
            lr_keyrec_rec.last_update_login       := FND_GLOBAL.login_id;      
            lr_keyrec_rec.last_updated_by         := FND_GLOBAL.user_id;
            lr_keyrec_rec.created_by              := FND_GLOBAL.user_id;
            lr_keyrec_rec.creation_date           := SYSDATE;

                 
      IF lr_keyrec_rec.keyrec_nbr IS NOT NULL THEN
   
         OPEN  lcu_keyrec_exists;
         FETCH lcu_keyrec_exists INTO lc_keyrec_exists;
         CLOSE lcu_keyrec_exists;
   
         IF lc_keyrec_exists = G_YES THEN

            UPDATE xx_gi_rcv_keyrec
            SET carton_cnt          = lr_keyrec_rec.carton_cnt
               ,status_cd           = G_OPEN_STATUS
               ,comments            = lr_keyrec_rec.comments
               ,freight_cd          = lr_keyrec_rec.freight_cd
               ,fob_cd              = lr_keyrec_rec.fob_cd
               ,freight_bill_nbr    = lr_keyrec_rec.freight_bill_nbr
               ,carrier_nbr         = lr_keyrec_rec.carrier_nbr
               ,proforma_nbr        = lr_keyrec_rec.proforma_nbr
               ,total_weight        = lr_keyrec_rec.total_weight
            WHERE keyrec_nbr        = lr_keyrec_rec.keyrec_nbr
            AND   loc_nbr           = lr_keyrec_rec.loc_nbr
            ;
   
         ELSE
            -------------------------------
            -- Insert the new keyrec number
            -------------------------------
            BEGIN
               INSERT 
               INTO xx_gi_rcv_keyrec
               VALUES lr_keyrec_rec;      
            EXCEPTION
               WHEN OTHERS THEN
                  x_return_status := G_UNEXPECTED_ERROR;
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62802_KEYREC_INSRT_ERR');
                  FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
                  x_return_message := FND_MESSAGE.GET;
                  ROLLBACK;
                  RETURN;
            END;
         END IF;
      ELSE
         -------------------------
         -- Generate KEYREC number
         -------------------------
         BEGIN
            SELECT xx_gi_rcv_keyrec_s.NEXTVAL
            INTO   ln_keyrec_number
            FROM   DUAL;
         EXCEPTION
            WHEN OTHERS THEN
               x_return_status := G_UNEXPECTED_ERROR;
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62801_KEYREC_NUM_ERR');
               FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
               x_return_message := FND_MESSAGE.GET;
               RETURN;
         END;
         -------------------------------
         -- Insert the new keyrec number
         -------------------------------
         INSERT 
         INTO xx_gi_rcv_keyrec
         VALUES lr_keyrec_rec
         ;
   
      END IF;
   END COMMON_KEYREC_LOGIC;
   
   -- +===================================================================+
   -- | Name             : POPULATE_STG_PO_RECEIVING_DATA                 |
   -- | Description      :                                                |
   -- |                                                                   |
   -- | Parameters :       x_keyrec_rec                                   |
   -- |                    x_header_rec                                   | 
   -- |                    x_detail_tbl                                   |
   -- | Returns :          x_errbuf                                       |
   -- |                    x_retcode                                      |
   -- +===================================================================+

   PROCEDURE POPULATE_STG_PO_RECEIVING_DATA(x_keyrec_rec      IN OUT  xx_gi_rcv_keyrec%ROWTYPE    
                                           ,x_header_rec      IN OUT  xx_gi_rcv_po_hdr%ROWTYPE    
                                           ,x_detail_tbl      IN OUT  detail_tbl_type    
                                           ,x_return_status   OUT  VARCHAR2                    
                                           ,x_return_message  OUT  VARCHAR2                    
                                           )
   IS

      ---------------------------
      -- Local user defined types
      ---------------------------
      lr_detail_rec          xx_gi_rcv_po_dtl%ROWTYPE;

   BEGIN      
      VALIDATE_STG_PO_RECEIVING_DATA
                           (x_header_rec     => x_header_rec
                           ,x_detail_tbl     => x_detail_tbl
                           ,x_return_status  => x_return_status
                           ,x_return_message => x_return_message
                           );
                           
      IF x_return_status = 'U' THEN
      
         RETURN;

      ELSE
        --dbms_output.put_line('after successful validation');
         ----------------------------------------
         -- Insert (or) Update keyrec information
         ----------------------------------------

         COMMON_KEYREC_LOGIC(x_keyrec_rec     => x_keyrec_rec
                            ,x_return_status  => x_return_status  -- OUT  VARCHAR2                    
                            ,x_return_message => x_return_message --  OUT  VARCHAR2  
                            );
         IF x_return_status = 'U' THEN
            RETURN;            
         END IF;
         x_header_rec.attribute8 := x_keyrec_rec.keyrec_nbr;
         x_header_rec.loc_nbr    := x_keyrec_rec.loc_nbr;
         
         -----------------------------------------------------
         -- Insert the header record into header Staging table
         -----------------------------------------------------
         INSERT 
         INTO xx_gi_rcv_po_hdr
         VALUES x_header_rec
         ;
         ------------------------------------------------------
         -- Insert the detail records into header Staging table
         ------------------------------------------------------
         FORALL i IN x_detail_tbl.FIRST..x_detail_tbl.LAST
         INSERT 
         INTO   xx_gi_rcv_po_dtl 
         VALUES x_detail_tbl(i)
         ;
      END IF;

      COMMIT;
      
   EXCEPTION
      WHEN OTHERS THEN
      ROLLBACK;
      x_return_status := 'U';
      x_return_message := SUBSTR(SQLERRM,1,240);
   END POPULATE_STG_PO_RECEIVING_DATA;
   
      -- +===================================================================+
      -- | Name             : POPULATE_STG_XFR_RCV_DATA                      |
      -- | Description      :                                                |
      -- |                                                                   |
      -- | Parameters :       x_keyrec_rec                                   |
      -- |                    x_header_rec                                   | 
      -- |                    x_detail_tbl                                   |
      -- | Returns :          x_errbuf                                       |
      -- |                    x_retcode                                      |
   -- +===================================================================+
   
   PROCEDURE POPULATE_STG_XFR_RCV_DATA(x_keyrec_rec      IN OUT  xx_gi_rcv_keyrec%ROWTYPE    
                                       ,x_header_rec      IN OUT  xx_gi_rcv_xfr_hdr%ROWTYPE    
                                       ,x_detail_tbl      IN OUT  detail_tbl_type    
                                       ,x_return_status   OUT  VARCHAR2                    
                                       ,x_return_message  OUT  VARCHAR2                    
                                       )
   IS
      -------------------------
      -- Local Scalar Variables
      -------------------------
      lc_keyrec_exists       VARCHAR2(1) := NULL;
      ---------------------------
      -- Local user defined types
      ---------------------------
      lr_detail_rec          xx_gi_rcv_po_dtl%ROWTYPE;
      -------------------
      -- Local exceptions
      -------------------
   BEGIN
      VALIDATE_STG_XFR_RCV_DATA
                           (x_header_rec     => x_header_rec
                           ,x_detail_tbl     => x_detail_tbl
                           ,x_return_status  => x_return_status
                           ,x_return_message => x_return_message
                           );
                           
      IF x_return_status = 'U' THEN
      
         RETURN;
   
      ELSE
         ----------------------------------------
         -- Insert (or) Update keyrec information
         ----------------------------------------

         COMMON_KEYREC_LOGIC(x_keyrec_rec     => x_keyrec_rec
                            ,x_return_status  => x_return_status  -- OUT  VARCHAR2                    
                            ,x_return_message => x_return_message --  OUT  VARCHAR2  
                            );
         IF x_return_status = 'U' THEN
            RETURN;
         END IF;
         x_header_rec.attribute8 := x_keyrec_rec.keyrec_nbr;
         x_header_rec.loc_nbr    := x_keyrec_rec.loc_nbr;
         -----------------------------------------------------
         -- Insert the header record into header Staging table
         -----------------------------------------------------
         INSERT 
         INTO xx_gi_rcv_xfr_hdr
         VALUES x_header_rec
         ;
         ------------------------------------------------------
         -- Insert the detail records into header Staging table
         ------------------------------------------------------
         FORALL i IN x_detail_tbl.FIRST..x_detail_tbl.LAST
         INSERT 
         INTO   xx_gi_rcv_xfr_dtl 
         VALUES x_detail_tbl(i)
         ;
      END IF;
   
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
      ROLLBACK;
      x_return_message := SUBSTR(SQLERRM,1,240);
      x_return_status  := 'U';
   END POPULATE_STG_XFR_RCV_DATA;
   
-- +===================================================================+
-- | Name             : XFR_RCV_PURGE                                  |
-- | Description      : Procedure to purge the data from stage tables  |
-- |                    based upon quick code which stores number of   | 
-- |                    days after which the successfully processed    |
-- |                    records are to be deleted.                     |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |                                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE XFR_RCV_PURGE       ( x_errbuf    OUT NOCOPY VARCHAR2
                               ,x_retcode   OUT NOCOPY NUMBER
                              )
IS

------------------------------------------------------
-- Cursor to fetch Store data elligible for deletion
------------------------------------------------------

CURSOR lcu_delete_str_hdr_id 
IS
SELECT XGRSH.header_interface_id
                    FROM   xx_gi_rcv_xfr_hdr XGRSH
                          ,xx_gi_rcv_keyrec  XGRK
                          ,xx_gi_rcv_xfr_dtl XGRSD 
                    WHERE  XGRSH.loc_nbr = XGRK.loc_nbr
                    AND    XGRSH.attribute8 = XGRK.keyrec_nbr
                    AND    XGRSH.header_interface_id = XGRSD.header_interface_id
                    AND    TRUNC(SYSDATE - XGRSH.creation_date) > (SELECT description  FROM FND_LOOKUP_VALUES_VL 
                                                                WHERE lookup_type = 'ODRCV_RECORDS_AGE'
                                                                 AND   lookup_code = XGRK.type_cd)
                    AND    XGRSH.od_rcv_status_flag = 'CH'                                        
                    AND    XGRSD.od_rcv_status_flag = 'CH';                   
                    
--------------------------------------------------
-- Declaring local Exceptions and local Variables
--------------------------------------------------  

lc_debug            VARCHAR2(500);
ln_line_purge       NUMBER := 0;

--------------------------------------------------
-- Declaring pl/sql table Variable
--------------------------------------------------  

TYPE header_intfc_id_tbl_typ IS TABLE OF xx_gi_rcv_po_hdr.header_interface_id%type
INDEX BY BINARY_INTEGER;
lt_hdr_intfc_id header_intfc_id_tbl_typ;

BEGIN


    fnd_file.put_line(fnd_file.log,'Store Purge Program');
    fnd_file.put_line(fnd_file.log,'_____________________________');       
    
  
    -- Fetch header interface id of the records to be deleted.
  
    lc_debug := 'Open Cursor lcu_delete_str_hdr_id';
    
    OPEN  lcu_delete_str_hdr_id;
    FETCH lcu_delete_str_hdr_id BULK COLLECT INTO lt_hdr_intfc_id;
    CLOSE lcu_delete_str_hdr_id;
    
    lc_debug := 'Before Delete of aged records from xx_gi_rcv_xfr_hdr'; 
      
 -- Delete aged header records. 
    FORALL i IN 1..lt_hdr_intfc_id.COUNT
    DELETE 
    FROM xx_gi_rcv_xfr_hdr XGRSH
    WHERE XGRSH.header_interface_id = lt_hdr_intfc_id(i);
    
    
    fnd_file.put_line(fnd_file.log,'Number of records Purged from xx_gi_rcv_xfr_hdr: '|| lt_hdr_intfc_id.COUNT);
    lc_debug := 'Before Delete of aged records from xx_gi_rcv_xfr_dtl'; 
    
 -- Delete aged Detail records. 
    FORALL i IN 1..lt_hdr_intfc_id.COUNT
    DELETE 
    FROM  xx_gi_rcv_xfr_dtl XGRSD
    WHERE XGRSD.header_interface_id =  lt_hdr_intfc_id(i);
    
    lc_debug := 'After Delete of aged records from xx_gi_rcv_xfr_dtl'; 
    ln_line_purge := NVL(SQL%ROWCOUNT,0) ;
    fnd_file.put_line(fnd_file.log,'Number of records Purged from xx_gi_rcv_xfr_dtl: '|| ln_line_purge);
    lc_debug := 'While Printing output Report';

    fnd_file.put_line(fnd_file.output,' Office Depot                             Date: '||to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    fnd_file.put_line(fnd_file.output,'  ');
    fnd_file.put_line(fnd_file.output,'              OD Inventory XFR Purge Receiving Summary ');
    
    fnd_file.put_line(fnd_file.output,' ');

    fnd_file.put_line(fnd_file.output,'Number of Store Header records deleted: '||lt_hdr_intfc_id.COUNT);
    fnd_file.put_line(fnd_file.output,'Number of Store detail records deleted: '||ln_line_purge );
    
    fnd_file.put_line(fnd_file.output,' ');
    fnd_file.put_line(fnd_file.output,' **********************************************************');
        
    COMMIT;
    
 EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      fnd_file.put_line(fnd_file.log,'Unexpected error: '||lc_debug);
      fnd_file.put_line(fnd_file.log,'Oracle Error is: '||SQLERRM);
      x_errbuf  := SUBSTR(sqlerrm,1,240);
      x_retcode := 2;
      
END XFR_RCV_PURGE;

-- +===================================================================+
-- | Name             : XFR_RCV_UPDATE                                 |
-- | Description      : Procedure to update status of stage table based|
-- |                    upon the status of processing                  |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |                                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE XFR_RCV_UPDATE ( x_errbuf    OUT NOCOPY VARCHAR2
                          ,x_retcode   OUT NOCOPY NUMBER
                         )
IS

--------------------------------------------------
-- Declaring local Exceptions and local Variables
--------------------------------------------------  

lc_debug            VARCHAR2(240);
lc_hdr_error_msg    xx_gi_rcv_xfr_hdr.od_rcv_error_description%TYPE;
lc_line_error_msg   xx_gi_rcv_xfr_hdr.od_rcv_error_description%TYPE;
ln_hdr_interface_id xx_gi_rcv_xfr_hdr.header_interface_id %TYPE;
lb_data_flag        BOOLEAN     := FALSE; 
ln_suc_rec          PLS_INTEGER := 0;

--------------------------------------------------
-- Declaring local PL/SQL Table Variables
-------------------------------------------------- 
TYPE line_intfc_id_tbl_typ IS TABLE OF xx_gi_rcv_xfr_dtl.interface_transaction_id%type
INDEX BY BINARY_INTEGER;
lt_line_intfc_id  line_intfc_id_tbl_typ;

TYPE error_msg_tbl_typ IS TABLE OF po_interface_errors.error_message%type
INDEX BY BINARY_INTEGER;
lt_err_msg  error_msg_tbl_typ;

BEGIN


    fnd_file.put_line(fnd_file.log,'Transfer Receiving update Program');
    fnd_file.put_line(fnd_file.log,'_______________________________');    
        
    -- Generating Output Reports for Errored and Successfully created receipts
    -- Before any delete or update operation is performed.
    
    lc_debug := 'Before displaying output summary ';
    fnd_file.put_line(fnd_file.output,' Office Depot                             Date: '||to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    fnd_file.put_line(fnd_file.output,'  ');
    fnd_file.put_line(fnd_file.output,'              OD Inventory Transfer Receiving Summary ');
    
    fnd_file.put_line(fnd_file.output,' ');
    
    fnd_file.put_line(fnd_file.output,'From org name        To org name          Item name            UOM  Quantity  EBS Receipt number   Transaction Date  Status');
    fnd_file.put_line(fnd_file.output,'_____________________________________________________________________________________________________________________________');

    FOR lcu_proc_records IN (SELECT   XGRXD.interface_transaction_id INTERFACE_TRANSACTION_ID
                                     ,'' VENDOR_NAME
                                      ,(SELECT  name FROM hr_all_organization_units 
                        WHERE organization_id=RSL.TO_ORGANIZATION_ID) TO_ORG_NAME
                      ,(SELECT  name FROM hr_all_organization_units 
                                        WHERE organization_id=RSL.FROM_ORGANIZATION_ID) FROM_ORG_NAME
                                     ,'' DOC_NUM                              
                                     ,'' LINE_NUM
                                     ,XGRXD.item_num ITEM_NAME
                                     ,RT.unit_of_measure            UOM
                                     ,RT.quantity                   QUANTITY
                                     ,(SELECT receipt_num 
                                       FROM rcv_shipment_headers RSH 
                                       WHERE RSH.shipment_header_id=RT.shipment_header_id) RECEIPT_NUM
                                     ,RT.transaction_date   TRANSACTION_DATE
                              FROM    rcv_transactions      RT
                                     ,xx_gi_rcv_xfr_dtl     XGRXD
                                     ,rcv_shipment_lines    RSL
                              WHERE XGRXD.interface_transaction_id = RT.attribute15
                              AND   XGRXD.od_rcv_status_flag       = 'PL'
                              AND   RSL.shipment_line_id           = RT.shipment_line_id
                              AND   RT.transaction_type           IN (G_DELIVER,G_CORRECT)
                            )
    LOOP
      lb_data_flag := TRUE ;
      lc_debug := 'Before getting successful records in a pl/sql table';
      lt_line_intfc_id(ln_suc_rec) := lcu_proc_records.interface_transaction_id;
      ln_suc_rec  := ln_suc_rec +1 ;
            
      fnd_file.put_line(fnd_file.output, rpad(lcu_proc_records.FROM_ORG_NAME,20)||' '||rpad(lcu_proc_records.TO_ORG_NAME,20)||' '||rpad(lcu_proc_records.ITEM_NAME,20)||' '||rpad(lcu_proc_records.UOM,4)
                        ||' '||rpad(lcu_proc_records.quantity,9)||' '||rpad(NVL(lcu_proc_records.receipt_num,'***********'),20)||' '||lcu_proc_records.transaction_date||'     CH');
    END LOOP;
    fnd_file.put_line(fnd_file.output,' ');
    lc_debug := 'After displaying output summary ';
    
    IF NOT lb_data_flag THEN
       fnd_file.put_line(fnd_file.output,'***************** No Transfer Receiving was processed successfully ***********');
    END IF;
    lb_data_flag := FALSE ;
    
    lc_debug := 'Before displaying output summary for error records ';
    fnd_file.put_line(fnd_file.output,'            ');
    fnd_file.put_line(fnd_file.output, '----------------------------------------------------------------------------------------------------------  ');                                 

    fnd_file.put_line(fnd_file.output,'  ');
    fnd_file.put_line(fnd_file.output,'              OD Inventory Transfer Receiving Errors ');
    
    fnd_file.put_line(fnd_file.output,' ');
    
    -- Updating all the lines which were successfully processed
    FORALL i in lt_line_intfc_id.FIRST..lt_line_intfc_id.LAST
    UPDATE xx_gi_rcv_xfr_dtl
    SET    od_rcv_status_flag  = 'CH'   
    WHERE  interface_transaction_id   = lt_line_intfc_id(i);
    
    fnd_file.put_line(fnd_file.log,'The number of Line records successfully updated to CH: '||NVL(SQL%ROWCOUNT,0));
    ln_suc_rec := 0;
    lt_line_intfc_id.DELETE;
    -- Displaying errored records in the Output file
    lc_debug := 'After update of xx_gi_rcv_xfr_dtl to CH';
    fnd_file.put_line(fnd_file.output,'       ');    
    
    fnd_file.put_line(fnd_file.output,'From org name        To org name          Item name       UOM  Quantity  Transaction interface ID   Error message ');   
    fnd_file.put_line(fnd_file.output,'------------------------------------------------------------------------------------------------------------------');
    FOR lcu_fail_records IN (SELECT XGRXD.interface_transaction_id   INTERFACE_TXN_ID
                                        ,''                          VENDOR_NAME
                                        ,(SELECT  HOU.name FROM hr_all_organization_units HOU 
                                          WHERE HOU.organization_id=RTI.to_organization_id) TO_ORG_NAME
                    ,(SELECT  HOU.name FROM hr_all_organization_units HOU 
                                          WHERE HOU.organization_id=RTI.from_organization_id) FROM_ORG_NAME
                                          ,'' DOC_NUM                              
                                        ,(SELECT line_num FROM po_lines 
                                          WHERE po_line_id=RTI.po_line_id) LINE_NUM
                                        ,XGRXD.item_num        ITEM_NAME
                                        ,RTI.unit_of_measure               UOM
                                        ,RTI.quantity                      QUANTITY
                                        ,RTI.interface_transaction_id      INTERFACE_TRANSACTION_ID
                                        ,RTI.transaction_date              TRANSACTION_DATE
                                        ,SUBSTR(PIE.error_message,1,150)          ERROR_MESSAGE
                                  FROM rcv_transactions_interface  RTI
                                      ,xx_gi_rcv_xfr_dtl           XGRXD
                                      ,po_interface_errors         PIE
                                  WHERE XGRXD.interface_transaction_id  = RTI.attribute15
                                  AND   XGRXD.od_rcv_status_flag  = 'PL'
                                  AND   PIE.interface_type        = 'RCV-856'
                                  AND  ( ( PIE.interface_line_id = RTI.interface_transaction_id 
                                          AND NVL(PIE.interface_header_id,-999) = -999)
                                  OR ( PIE.interface_header_id  = RTI.header_interface_id 
                                       AND NVL(PIE.interface_line_id,-999) = -999)
                                  OR ( PIE.interface_line_id       = RTI.interface_transaction_id 
                                       AND PIE.interface_header_id = RTI.header_interface_id)
                                  )
                                )
        LOOP
        
          fnd_file.put_line(fnd_file.output,rpad(lcu_fail_records.TO_ORG_NAME,20)||' '||rpad(lcu_fail_records.FROM_ORG_NAME,20)||' '||rpad(lcu_fail_records.ITEM_NAME,15)||' '|| rpad(lcu_fail_records.UOM,5)
                            ||''||rpad(lcu_fail_records.quantity,9)||' '||rpad( lcu_fail_records.interface_transaction_id,26)||' '|| lcu_fail_records.error_message||' '||lcu_fail_records.error_message);
          lt_line_intfc_id(ln_suc_rec) := lcu_fail_records.interface_txn_id;
          lt_err_msg(ln_suc_rec)       := lcu_fail_records.error_message;
          ln_suc_rec                   := ln_suc_rec +1 ;
          lb_data_flag := TRUE ;

        END LOOP;
        fnd_file.put_line(fnd_file.output,'            ');
        IF NOT lb_data_flag THEN           
            fnd_file.put_line(fnd_file.output,'*************** No Transfer Receiving Failed *************');
        END IF;
    
    lc_debug := 'After displaying output summary for Error records';
    fnd_file.put_line(fnd_file.output,'__________________________________________________________________________________________________________________________________________________ ');
    
     -- Updating all the lines which were successfully processed
    FORALL i in lt_line_intfc_id.FIRST..lt_line_intfc_id.LAST
    UPDATE xx_gi_rcv_xfr_dtl
    SET    od_rcv_status_flag  = 'E'
          ,od_rcv_error_description        = lt_err_msg(i)
    WHERE  interface_transaction_id        = lt_line_intfc_id(i);
          
    fnd_file.put_line(fnd_file.log,'The number of Line records successfully updated to status E: '||NVL(SQL%ROWCOUNT,0));
    ln_suc_rec := 0;
    lt_line_intfc_id.DELETE;
    lc_debug := 'After updating records in xx_gi_rcv_xfr_dtl to CH';  
    
    -- Set status to ‘CH’ for header records for which all the line records are 
    -- successfully processed.

        UPDATE xx_gi_rcv_xfr_hdr XGRXH
        SET    XGRXH.od_rcv_status_flag  = NVL((SELECT DISTINCT XGRXD.od_rcv_status_flag 
                                                FROM   xx_gi_rcv_xfr_dtl XGRXD 
                                                WHERE  XGRXD.header_interface_id  = XGRXH.header_interface_id
                                                AND    XGRXD.od_rcv_status_flag   IN ('CH')
                                                )
                                                ,XGRXH.od_rcv_status_flag
                                              )
              ,XGRXH.od_rcv_error_description = NULL
        WHERE XGRXH.od_rcv_status_flag  IN  ('E','PL');                                      
        
       -- Set status to ‘E’ for line records for which atleast one line record is 
       -- in error status.
 
        UPDATE xx_gi_rcv_xfr_hdr XGRXH
        SET    XGRXH.od_rcv_status_flag  = NVL((SELECT DISTINCT XGRXD.od_rcv_status_flag 
                                                FROM   xx_gi_rcv_xfr_dtl XGRXD 
                                                WHERE  XGRXD.header_interface_id  = XGRXH.header_interface_id
                                                AND    XGRXD.od_rcv_status_flag   IN ('E')
                                                )
                                                ,XGRXH.od_rcv_status_flag
                                              )
        WHERE XGRXH.od_rcv_status_flag  IN  ('E','PL','CH');
                         

       lc_debug := 'After updating xx_gi_rcv_xfr_hdr to E';
     
  -- Set status to ‘CH’ for keyrec records for which all the line records are success
  -- If all the lines of a particular keyrec number were successfully processed then update 
  -- the corresponding keyrec record status to ‘CH’ (Closed)
  
        UPDATE xx_gi_rcv_xfr_hdr XGRXH
        SET    XGRXH.od_rcv_status_flag  = NVL((SELECT DISTINCT XGRXD.od_rcv_status_flag 
                                                FROM   xx_gi_rcv_xfr_dtl XGRXD 
                                                WHERE  XGRXD.header_interface_id  = XGRXH.header_interface_id
                                                AND    XGRXD.od_rcv_status_flag   IN ('VE')
                                                )
                                                ,XGRXH.od_rcv_status_flag
                                              )
        WHERE XGRXH.od_rcv_status_flag  IN  ('E','PL','CH','PRCP');
        
        -- If all the lines of a particular keyrec number were successfully processed then update 
    -- the corresponding keyrec record status to ‘CH’ (Closed)
      
     --****************************arun added
       lc_debug := 'Update keyrec records to status E';

     UPDATE xx_gi_rcv_keyrec XGRK
     SET    XGRK.status_cd    = NVL(( SELECT DISTINCT od_rcv_status_flag
                                     FROM xx_gi_rcv_xfr_hdr  XGRXH
                                     WHERE  XGRK.keyrec_nbr = XGRXH.attribute8
                                     AND   XGRK.loc_nbr = XGRXH.loc_nbr
                                     AND   XGRXH.od_rcv_status_flag   IN ('CH')
                                    ),XGRK.status_cd
                                  )
        WHERE status_cd   IN  ('E','PL');                                      
        
        lc_debug := 'Update keyrec records to status CH';
       -- Set status to ‘E’ for line records for which atleast one line record is 
       -- in error status.
 
     UPDATE xx_gi_rcv_keyrec XGRK
     SET    XGRK.status_cd   = NVL(( SELECT DISTINCT od_rcv_status_flag
                                     FROM xx_gi_rcv_xfr_hdr  XGRXH
                                     WHERE  XGRK.keyrec_nbr = XGRXH.attribute8
                                     AND   XGRK.loc_nbr = XGRXH.loc_nbr
                                     AND   XGRXH.od_rcv_status_flag   IN ('E')
                                    ),XGRK.status_cd
                                  )
       WHERE  status_cd   IN ('E','PL','CH');
       
      lc_debug := 'Update keyrec records to status CH';
      -- Set status to ‘E’ for line records for which atleast one line record is 
      -- in error status.
     UPDATE xx_gi_rcv_keyrec XGRK
     SET    XGRK.status_cd   = NVL(( SELECT DISTINCT od_rcv_status_flag
                                     FROM xx_gi_rcv_xfr_hdr  XGRXH
                                     WHERE  XGRK.keyrec_nbr = XGRXH.attribute8
                                     AND   XGRK.loc_nbr = XGRXH.loc_nbr
                                     AND   XGRXH.od_rcv_status_flag   IN ('VE')
                                    ),XGRK.status_cd
                                  )
      WHERE  status_cd   IN ('E','PL','CH','PRCP');

       lc_debug := 'After updating xx_gi_rcv_keyrec';
     --********************************end
              
     fnd_file.put_line(fnd_file.log,'Number of records upated in xx_gi_rcv_keyrec: '|| NVL(SQL%ROWCOUNT,0));
     
     
     lc_debug := 'After updating xx_gi_rcv_keyrec to E or CH';
     fnd_file.put_line(fnd_file.log,'Number of records upated in xx_gi_rcv_keyrec: '|| NVL(SQL%ROWCOUNT,0));     
    
    COMMIT;
    
 EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      fnd_file.put_line(fnd_file.log,'Unexpected error '||lc_debug);
      fnd_file.put_line(fnd_file.log,'Oracle Error is '||SQLERRM);
      x_errbuf := SUBSTR(sqlerrm,1,240);
      x_retcode := 2;
      
END XFR_RCV_UPDATE;

-- +===================================================================+
-- | Name             : INSERT_INTO_XFR_RCVING_TBLS                    |
-- | Description      : This procedure populates the xfr receiving info|
-- |                    into ROI interface tables as well locks the    |
-- |                    records to PL to avoid any further DML operation|
-- |                    on these records unless processed.             |
-- | Parameters :       p_header_interface_id IN NUMBER                |
-- |                                                                   |
-- | Returns :          x_ret_status          PLS_INTEGER              |
-- |                    x_ret_message         VARCHAR2                 |
-- |                                                                   |
-- +===================================================================+

PROCEDURE INSERT_INTO_XFR_RCVING_TBLS(p_header_interface_id IN NUMBER                                
                                     ,p_keyrec_nbr          IN VARCHAR2
                                     ,p_loc_nbr             IN VARCHAR2                                     
                                     ,x_ret_status          OUT PLS_INTEGER
                                     ,x_ret_message         OUT VARCHAR2
                                     )
IS

-- CURSOR to fetch Receiving transaction data for corrections

CURSOR lcu_txn_line (p_shipment_line_id IN NUMBER
                    ,p_adj_qty          IN NUMBER
                    )
IS
SELECT transaction_id
      ,quantity
FROM  rcv_transactions 
WHERE shipment_line_id = p_shipment_line_id
AND   transaction_type  = DECODE(SIGN(p_adj_qty),-1,'DELIVER','RECEIVE')  
ORDER BY quantity desc;

ln_user_id             NUMBER := FND_GLOBAL.user_id;
ln_existing_quantity   NUMBER;
ln_rcv_quantity        NUMBER;
ln_curr_quantity       NUMBER;
ln_lcu_txn_line_count  NUMBER := 0;
lc_error_level         VARCHAR2(150);

-- PL/SQL table type declarations
TYPE Line_txn_id_tbl_typ IS TABLE OF RCV_TRANSACTIONS.transaction_id%type 
INDEX BY BINARY_INTEGER;
lt_line_txn_id  line_txn_id_tbl_typ;

TYPE Line_txn_qty_tbl_typ IS TABLE OF RCV_TRANSACTIONS.quantity%type 
INDEX BY BINARY_INTEGER;
lt_line_qty  line_txn_qty_tbl_typ;

BEGIN

lc_error_level :=  'While inserting in rcv_headers_interface,error for header interface id: '||p_header_interface_id;
FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserting into RCV Headers Interface Table for header interface id: '||p_header_interface_id);
-- Inserting in the rcv_headers_interface table.

INSERT 
INTO rcv_headers_interface
    (HEADER_INTERFACE_ID        
    ,GROUP_ID            
    ,PROCESSING_STATUS_CODE      
    ,RECEIPT_SOURCE_CODE         
    ,ASN_TYPE            
    ,TRANSACTION_TYPE        
    ,LAST_UPDATE_DATE        
    ,LAST_UPDATED_BY         
    ,LAST_UPDATE_LOGIN       
    ,CREATION_DATE           
    ,CREATED_BY     
    ,EDI_CONTROL_NUM          
    ,AUTO_TRANSACT_CODE       
    ,TEST_FLAG                
    ,NOTICE_CREATION_DATE     
    ,SHIPMENT_NUM             
    ,RECEIPT_NUM              
    ,RECEIPT_HEADER_ID        
    ,VENDOR_NAME              
    ,VENDOR_NUM               
    ,VENDOR_ID                
    ,VENDOR_SITE_CODE         
    ,VENDOR_SITE_ID           
    ,FROM_ORGANIZATION_ID     
    ,SHIP_TO_ORGANIZATION_ID  
    ,LOCATION_CODE            
    ,LOCATION_ID              
    ,BILL_OF_LADING           
    ,PACKING_SLIP             
    ,SHIPPED_DATE             
    ,FREIGHT_CARRIER_CODE     
    ,EXPECTED_RECEIPT_DATE    
    ,RECEIVER_ID              
    ,NUM_OF_CONTAINERS        
    ,WAYBILL_AIRBILL_NUM      
    ,COMMENTS                 
    ,GROSS_WEIGHT             
    ,GROSS_WEIGHT_UOM_CODE    
    ,NET_WEIGHT               
    ,NET_WEIGHT_UOM_CODE      
    ,TAR_WEIGHT               
    ,TAR_WEIGHT_UOM_CODE      
    ,PACKAGING_CODE           
    ,CARRIER_METHOD           
    ,CARRIER_EQUIPMENT        
    ,SPECIAL_HANDLING_CODE    
    ,HAZARD_CODE              
    ,HAZARD_CLASS             
    ,HAZARD_DESCRIPTION       
    ,FREIGHT_TERMS            
    ,FREIGHT_BILL_NUMBER      
    ,INVOICE_NUM              
    ,INVOICE_DATE             
    ,TOTAL_INVOICE_AMOUNT     
    ,TAX_NAME                 
    ,TAX_AMOUNT               
    ,FREIGHT_AMOUNT           
    ,CURRENCY_CODE            
    ,CONVERSION_RATE_TYPE     
    ,CONVERSION_RATE          
    ,CONVERSION_RATE_DATE     
    ,PAYMENT_TERMS_NAME       
    ,PAYMENT_TERMS_ID         
    ,ATTRIBUTE_CATEGORY       
    ,ATTRIBUTE1               
    ,ATTRIBUTE2               
    ,ATTRIBUTE3               
    ,ATTRIBUTE4               
    ,ATTRIBUTE5               
    ,ATTRIBUTE6               
    ,ATTRIBUTE7               
    ,ATTRIBUTE8               
    ,ATTRIBUTE9               
    ,ATTRIBUTE10              
    ,ATTRIBUTE11              
    ,ATTRIBUTE12              
    ,ATTRIBUTE13              
    ,ATTRIBUTE14              
    ,ATTRIBUTE15              
    ,USGGL_TRANSACTION_CODE   
    ,EMPLOYEE_NAME            
    ,EMPLOYEE_ID              
    ,INVOICE_STATUS_CODE      
    ,VALIDATION_FLAG          
    ,PROCESSING_REQUEST_ID    
    ,CUSTOMER_ACCOUNT_NUMBER  
    ,CUSTOMER_ID              
    ,CUSTOMER_SITE_ID         
    ,CUSTOMER_PARTY_NAME      
    ,REMIT_TO_SITE_ID
    )
SELECT  header_interface_id        
      , group_id
      , 'PENDING'                            
      , 'INVENTORY'                            
      , NULL                                 
      , 'NEW'                               
      , SYSDATE                              
      , ln_user_id                   
      , ln_user_id                
      , SYSDATE                              
      , ln_user_id                   
      , edi_control_num                 
      , DECODE(transaction_type,G_CORRECT,auto_transact_code,'RECEIVE')              
      , test_flag                       
      , notice_creation_date            
      , shipment_num                    
      , receipt_num                     
      , receipt_header_id               
      , vendor_name                     
      , vendor_num                      
      , vendor_id                       
      , vendor_site_code                
      , vendor_site_id                  
      , from_organization_id            
      , ship_to_organization_id         
      , location_code                   
      , location_id                     
      , bill_of_lading                  
      , packing_slip                    
      , shipped_date                    
      , freight_carrier_code            
      , expected_receipt_date           
      , receiver_id                     
      , num_of_containers               
      , waybill_airbill_num             
      , comments                        
      , gross_weight                    
      , gross_weight_uom_code           
      , net_weight                      
      , net_weight_uom_code             
      , tar_weight                      
      , tar_weight_uom_code             
      , packaging_code                  
      , carrier_method                  
      , carrier_equipment               
      , special_handling_code           
      , hazard_code                     
      , hazard_class                    
      , hazard_description              
      , freight_terms                   
      , freight_bill_number             
      , invoice_num                     
      , invoice_date                    
      , total_invoice_amount            
      , tax_name                        
      , tax_amount                      
      , freight_amount                  
      , currency_code                   
      , conversion_rate_type            
      , conversion_rate                 
      , conversion_rate_date            
      , payment_terms_name              
      , payment_terms_id                
      , attribute_category              
      , attribute1                      
      , attribute2                      
      , attribute3                      
      , attribute4                      
      , attribute5                      
      , attribute6                      
      , attribute7                      
      , attribute8                      
      , attribute9                      
      , attribute10                     
      , attribute11                     
      , attribute12                     
      , attribute13                     
      , attribute14                     
      , attribute15                     
      , usggl_transaction_code          
      , employee_name                   
      , G_EMPLOYEE_ID                     
      , invoice_status_code             
      , validation_flag                 
      , processing_request_id           
      , customer_account_number         
      , customer_id                     
      , customer_site_id                
      , customer_party_name             
      , remit_to_site_id                      
FROM  xx_gi_rcv_xfr_hdr XGRXH
WHERE XGRXH.header_interface_id = p_header_interface_id
AND   legacy_transaction_type = G_ADJUSTMENT_OR_ADD;

lc_error_level :=  'After inserting in rcv_headers_interface,error for header interface id: '||p_header_interface_id;

FOR lcu_dtl_cur IN 
(  SELECT * FROM xx_gi_rcv_xfr_dtl 
   WHERE header_interface_id = p_header_interface_id 
   AND   od_rcv_status_flag IN ('PRCP','E')  
)

LOOP
  
  IF SUBSTR(NVL(lcu_dtl_cur.attribute4,'#'),1,4) = G_CORRECTION THEN --  'OHRE'
     lc_error_level :=  'While fetching data from rcv_shipment_lines for Correction,error for line record: '||lcu_dtl_cur.interface_transaction_id;
     -- Fetch Quantity already recieved from RCV_SHIPMENT_LINES
     -- in case of correction.
     SELECT quantity_received
     INTO   ln_existing_quantity
     FROM   rcv_shipment_lines
     WHERE  shipment_line_id = lcu_dtl_cur.shipment_line_id;
     
     ln_rcv_quantity  := lcu_dtl_cur.quantity - ln_existing_quantity ;

     -- Get rcv transactions details only for Corrections     
     OPEN  lcu_txn_line (lcu_dtl_cur.shipment_line_id , ln_rcv_quantity);
     FETCH lcu_txn_line BULK COLLECT INTO lt_line_txn_id,lt_line_qty;
     CLOSE lcu_txn_line;
   ELSE -- IF it is 'OHDR'
     ln_rcv_quantity  := lcu_dtl_cur.quantity ;
  END IF;

  -- This is to make sure that loop executes once definately
  IF lt_line_txn_id.COUNT = 0 THEN
     lt_line_txn_id(0)   := -1;
     lt_line_qty(0)      := 0;
  END IF;

  ln_lcu_txn_line_count := lt_line_txn_id.COUNT;
  lc_error_level :=  'While inserting in rcv_lines_interface,error for line record: '||lcu_dtl_cur.interface_transaction_id;
  
  -- Inserting in the rcv_transactions_interface table.
  -- In case of Corrections i.e OHRE Txns, we need to split the correction quantity
  -- amont different DELIVER transactions.
  FOR ln_loop_indx IN lt_line_txn_id.FIRST..lt_line_txn_id.LAST
  LOOP
  IF SUBSTR(NVL(lcu_dtl_cur.attribute4,'#'),1,4) = G_CORRECTION THEN --  'OHRE'
     IF ABS(lt_line_qty(ln_loop_indx)) <=  ABS(ln_rcv_quantity)  THEN        
        ln_curr_quantity := lt_line_qty(ln_loop_indx) * -1 ;  
        ln_rcv_quantity  := ln_rcv_quantity - ln_curr_quantity ;     
     ELSE
        ln_curr_quantity := ln_rcv_quantity ;     
     END IF;
  END IF;
    
  INSERT INTO rcv_transactions_interface
     ( INTERFACE_TRANSACTION_ID
      ,HEADER_INTERFACE_ID     
      ,GROUP_ID                
      ,LAST_UPDATE_DATE        
      ,LAST_UPDATED_BY         
      ,CREATION_DATE           
      ,CREATED_BY              
      ,LAST_UPDATE_LOGIN       
      ,TRANSACTION_TYPE        
      ,TRANSACTION_DATE        
      ,PROCESSING_STATUS_CODE  
      ,PROCESSING_MODE_CODE    
      ,TRANSACTION_STATUS_CODE 
      ,QUANTITY                
      ,UNIT_OF_MEASURE         
      ,AUTO_TRANSACT_CODE      
      ,RECEIPT_SOURCE_CODE     
      ,SOURCE_DOCUMENT_CODE    
      ,REQUEST_ID                   
      ,PROGRAM_APPLICATION_ID       
      ,PROGRAM_ID                   
      ,PROGRAM_UPDATE_DATE          
      ,PROCESSING_REQUEST_ID        
      ,CATEGORY_ID                  
      ,INTERFACE_SOURCE_CODE        
      ,INTERFACE_SOURCE_LINE_ID     
      ,INV_TRANSACTION_ID           
      ,ITEM_ID                      
      ,ITEM_DESCRIPTION             
      ,ITEM_REVISION                
      ,UOM_CODE                     
      ,EMPLOYEE_ID                  
      ,SHIPMENT_HEADER_ID           
      ,SHIPMENT_LINE_ID             
      ,SHIP_TO_LOCATION_ID          
      ,PRIMARY_QUANTITY             
      ,PRIMARY_UNIT_OF_MEASURE      
      ,VENDOR_ID                    
      ,VENDOR_SITE_ID               
      ,FROM_ORGANIZATION_ID         
      ,FROM_SUBINVENTORY            
      ,TO_ORGANIZATION_ID           
      ,INTRANSIT_OWNING_ORG_ID      
      ,ROUTING_HEADER_ID            
      ,ROUTING_STEP_ID              
      ,PARENT_TRANSACTION_ID        
      ,PO_HEADER_ID                 
      ,PO_REVISION_NUM              
      ,PO_RELEASE_ID                
      ,PO_LINE_ID                   
      ,PO_LINE_LOCATION_ID          
      ,PO_UNIT_PRICE                
      ,CURRENCY_CODE                
      ,CURRENCY_CONVERSION_TYPE     
      ,CURRENCY_CONVERSION_RATE     
      ,CURRENCY_CONVERSION_DATE     
      ,PO_DISTRIBUTION_ID           
      ,REQUISITION_LINE_ID          
      ,REQ_DISTRIBUTION_ID          
      ,CHARGE_ACCOUNT_ID            
      ,SUBSTITUTE_UNORDERED_CODE    
      ,RECEIPT_EXCEPTION_FLAG       
      ,ACCRUAL_STATUS_CODE          
      ,INSPECTION_STATUS_CODE       
      ,INSPECTION_QUALITY_CODE      
      ,DESTINATION_TYPE_CODE        
      ,DELIVER_TO_PERSON_ID         
      ,LOCATION_ID                  
      ,DELIVER_TO_LOCATION_ID       
      ,SUBINVENTORY                 
      ,LOCATOR_ID                   
      ,WIP_ENTITY_ID                
      ,WIP_LINE_ID                  
      ,DEPARTMENT_CODE              
      ,WIP_REPETITIVE_SCHEDULE_ID   
      ,WIP_OPERATION_SEQ_NUM        
      ,WIP_RESOURCE_SEQ_NUM         
      ,BOM_RESOURCE_ID              
      ,SHIPMENT_NUM                 
      ,FREIGHT_CARRIER_CODE         
      ,BILL_OF_LADING               
      ,PACKING_SLIP                 
      ,SHIPPED_DATE                 
      ,EXPECTED_RECEIPT_DATE        
      ,ACTUAL_COST                  
      ,TRANSFER_COST                
      ,TRANSPORTATION_COST          
      ,TRANSPORTATION_ACCOUNT_ID    
      ,NUM_OF_CONTAINERS            
      ,WAYBILL_AIRBILL_NUM          
      ,VENDOR_ITEM_NUM              
      ,VENDOR_LOT_NUM               
      ,RMA_REFERENCE                
      ,COMMENTS                     
      ,ATTRIBUTE_CATEGORY           
      ,ATTRIBUTE1                   
      ,ATTRIBUTE2                   
      ,ATTRIBUTE3                   
      ,ATTRIBUTE4                   
      ,ATTRIBUTE5                   
      ,ATTRIBUTE6                   
      ,ATTRIBUTE7                   
      ,ATTRIBUTE8                   
      ,ATTRIBUTE9                   
      ,ATTRIBUTE10                  
      ,ATTRIBUTE11                  
      ,ATTRIBUTE12                  
      ,ATTRIBUTE13                  
      ,ATTRIBUTE14                  
      ,ATTRIBUTE15                  
      ,SHIP_HEAD_ATTRIBUTE_CATEGORY 
      ,SHIP_HEAD_ATTRIBUTE1         
      ,SHIP_HEAD_ATTRIBUTE2         
      ,SHIP_HEAD_ATTRIBUTE3         
      ,SHIP_HEAD_ATTRIBUTE4         
      ,SHIP_HEAD_ATTRIBUTE5         
      ,SHIP_HEAD_ATTRIBUTE6         
      ,SHIP_HEAD_ATTRIBUTE7         
      ,SHIP_HEAD_ATTRIBUTE8         
      ,SHIP_HEAD_ATTRIBUTE9         
      ,SHIP_HEAD_ATTRIBUTE10        
      ,SHIP_HEAD_ATTRIBUTE11        
      ,SHIP_HEAD_ATTRIBUTE12        
      ,SHIP_HEAD_ATTRIBUTE13        
      ,SHIP_HEAD_ATTRIBUTE14        
      ,SHIP_HEAD_ATTRIBUTE15        
      ,SHIP_LINE_ATTRIBUTE_CATEGORY 
      ,SHIP_LINE_ATTRIBUTE1         
      ,SHIP_LINE_ATTRIBUTE2         
      ,SHIP_LINE_ATTRIBUTE3         
      ,SHIP_LINE_ATTRIBUTE4         
      ,SHIP_LINE_ATTRIBUTE5         
      ,SHIP_LINE_ATTRIBUTE6         
      ,SHIP_LINE_ATTRIBUTE7         
      ,SHIP_LINE_ATTRIBUTE8         
      ,SHIP_LINE_ATTRIBUTE9         
      ,SHIP_LINE_ATTRIBUTE10        
      ,SHIP_LINE_ATTRIBUTE11        
      ,SHIP_LINE_ATTRIBUTE12        
      ,SHIP_LINE_ATTRIBUTE13        
      ,SHIP_LINE_ATTRIBUTE14        
      ,SHIP_LINE_ATTRIBUTE15        
      ,USSGL_TRANSACTION_CODE       
      ,GOVERNMENT_CONTEXT           
      ,REASON_ID                    
      ,DESTINATION_CONTEXT          
      ,SOURCE_DOC_QUANTITY          
      ,SOURCE_DOC_UNIT_OF_MEASURE   
      ,MOVEMENT_ID                  
      ,USE_MTL_LOT                  
      ,USE_MTL_SERIAL               
      ,VENDOR_CUM_SHIPPED_QTY       
      ,ITEM_NUM                     
      ,DOCUMENT_NUM                 
      ,DOCUMENT_LINE_NUM            
      ,TRUCK_NUM                    
      ,SHIP_TO_LOCATION_CODE        
      ,CONTAINER_NUM                
      ,SUBSTITUTE_ITEM_NUM          
      ,NOTICE_UNIT_PRICE            
      ,ITEM_CATEGORY                
      ,LOCATION_CODE                
      ,VENDOR_NAME                  
      ,VENDOR_NUM                   
      ,VENDOR_SITE_CODE             
      ,INTRANSIT_OWNING_ORG_CODE    
      ,ROUTING_CODE                 
      ,ROUTING_STEP                 
      ,RELEASE_NUM                  
      ,DOCUMENT_SHIPMENT_LINE_NUM   
      ,DOCUMENT_DISTRIBUTION_NUM    
      ,DELIVER_TO_PERSON_NAME       
      ,DELIVER_TO_LOCATION_CODE     
      ,LOCATOR                      
      ,REASON_NAME                  
      ,VALIDATION_FLAG              
      ,SUBSTITUTE_ITEM_ID           
      ,QUANTITY_SHIPPED             
      ,QUANTITY_INVOICED            
      ,TAX_NAME                     
      ,TAX_AMOUNT                   
      ,REQ_NUM                      
      ,REQ_LINE_NUM                 
      ,REQ_DISTRIBUTION_NUM         
      ,WIP_ENTITY_NAME              
      ,WIP_LINE_CODE                
      ,RESOURCE_CODE                
      ,SHIPMENT_LINE_STATUS_CODE    
      ,BARCODE_LABEL                
      ,TRANSFER_PERCENTAGE          
      ,QA_COLLECTION_ID             
      ,COUNTRY_OF_ORIGIN_CODE       
      ,OE_ORDER_HEADER_ID           
      ,OE_ORDER_LINE_ID             
      ,CUSTOMER_ID                  
      ,CUSTOMER_SITE_ID             
      ,CUSTOMER_ITEM_NUM            
      ,CREATE_DEBIT_MEMO_FLAG       
      ,PUT_AWAY_RULE_ID             
      ,PUT_AWAY_STRATEGY_ID         
      ,LPN_ID                       
      ,TRANSFER_LPN_ID              
      ,COST_GROUP_ID                
      ,MOBILE_TXN                   
      ,MMTT_TEMP_ID                 
      ,TRANSFER_COST_GROUP_ID       
      ,SECONDARY_QUANTITY           
      ,SECONDARY_UNIT_OF_MEASURE    
      ,SECONDARY_UOM_CODE           
      ,QC_GRADE                     
      ,FROM_LOCATOR                 
      ,FROM_LOCATOR_ID              
      ,PARENT_SOURCE_TRANSACTION_NUM
      ,INTERFACE_AVAILABLE_QTY      
      ,INTERFACE_TRANSACTION_QTY    
      ,INTERFACE_AVAILABLE_AMT      
      ,INTERFACE_TRANSACTION_AMT    
      ,LICENSE_PLATE_NUMBER         
      ,SOURCE_TRANSACTION_NUM       
      ,TRANSFER_LICENSE_PLATE_NUMBER
      ,LPN_GROUP_ID                 
      ,ORDER_TRANSACTION_ID         
      ,CUSTOMER_ACCOUNT_NUMBER      
      ,CUSTOMER_PARTY_NAME          
      ,OE_ORDER_LINE_NUM            
      ,OE_ORDER_NUM                 
      ,PARENT_INTERFACE_TXN_ID      
      ,CUSTOMER_ITEM_ID             
      ,AMOUNT                       
      ,JOB_ID                       
      ,TIMECARD_ID                  
      ,TIMECARD_OVN                 
      ,ERECORD_ID                   
      ,PROJECT_ID                   
      ,TASK_ID                      
      ,ASN_ATTACH_ID
          )
   SELECT        
        DECODE(ln_lcu_txn_line_count,1,interface_transaction_id,rcv_transactions_interface_s.nextval)
       ,DECODE(transaction_type,G_CORRECT,NULL,header_interface_id)
       ,group_id                                     
       ,SYSDATE                                      
       ,ln_user_id                                   
       ,SYSDATE                                      
       ,ln_user_id                                   
       ,ln_user_id                                   
       ,transaction_type                           
       ,transaction_date                           
       ,processing_status_code                     
       ,processing_mode_code    
       ,transaction_status_code 
       ,DECODE(transaction_type,G_CORRECT,ln_curr_quantity,ln_rcv_quantity)   -- quantity                                  
       ,unit_of_measure                           
       ,auto_transact_code      
       ,receipt_source_code     
       ,source_document_code                       
       ,request_id                                
       ,program_application_id                    
       ,program_id                                
       ,program_update_date                       
       ,processing_request_id                     
       ,category_id                               
       ,interface_source_code                     
       ,interface_source_line_id                  
       ,inv_transaction_id                        
       ,item_id                                     
       ,item_description                            
       ,item_revision                               
       ,uom_code                                    
       ,G_EMPLOYEE_ID                                 
       ,shipment_header_id                          
       ,shipment_line_id                            
       ,ship_to_location_id                         
       ,DECODE(transaction_type,G_CORRECT,ln_curr_quantity, primary_quantity)
       ,primary_unit_of_measure                     
       ,vendor_id                                   
       ,vendor_site_id                              
       ,from_organization_id                        
       ,DECODE(transaction_type,G_CORRECT,subinventory,from_subinventory)                           
       ,to_organization_id                          
       ,intransit_owning_org_id                     
       ,3  -- routing_header_id                           
       ,1  -- routing_step_id                             
       ,DECODE(transaction_type,G_CORRECT,lt_line_txn_id(ln_loop_indx),parent_transaction_id) -- parent_transaction_id                       
       ,po_header_id                                
       ,po_revision_num                             
       ,po_release_id                               
       ,po_line_id                                  
       ,po_line_location_id                         
       ,po_unit_price                               
       ,currency_code                               
       ,currency_conversion_type                    
       ,currency_conversion_rate                    
       ,currency_conversion_date                    
       ,po_distribution_id                          
       ,requisition_line_id                         
       ,req_distribution_id                         
       ,charge_account_id                           
       ,substitute_unordered_code                   
       ,receipt_exception_flag                      
       ,accrual_status_code                         
       ,inspection_status_code                      
       ,inspection_quality_code                     
       ,DECODE(transaction_type,G_CORRECT,DECODE(SIGN(ln_curr_quantity),-1,'INVENTORY','RECEIVING'),destination_type_code)  --DESTINATION_TYPE_CODE 
       ,deliver_to_person_id                        
       ,ship_to_location_id                         
       ,deliver_to_location_id                      
       ,subinventory                                
       ,locator_id                                  
       ,wip_entity_id                               
       ,wip_line_id                                 
       ,department_code                             
       ,wip_repetitive_schedule_id                  
       ,wip_operation_seq_num                       
       ,wip_resource_seq_num                        
       ,bom_resource_id                             
       ,attribute5                                  
       ,freight_carrier_code                        
       ,bill_of_lading                              
       ,packing_slip                                
       ,shipped_date                                
       ,expected_receipt_date                       
       ,actual_cost                                 
       ,transfer_cost                               
       ,transportation_cost                         
       ,transportation_account_id                   
       ,num_of_containers                           
       ,waybill_airbill_num                         
       ,vendor_item_num                             
       ,vendor_lot_num                              
       ,rma_reference                               
       ,comments                                    
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
       ,interface_transaction_id             -- attribute15                                 
       ,ship_head_attribute_category                
       ,ship_head_attribute1                        
       ,ship_head_attribute2                        
       ,ship_head_attribute3                        
       ,ship_head_attribute4                        
       ,ship_head_attribute5                        
       ,ship_head_attribute6                        
       ,ship_head_attribute7                        
       ,ship_head_attribute8                        
       ,ship_head_attribute9                        
       ,ship_head_attribute10                       
       ,ship_head_attribute11                       
       ,ship_head_attribute12                       
       ,ship_head_attribute13                       
       ,ship_head_attribute14                       
       ,ship_head_attribute15                       
       ,attribute_category  --     ship_line_attribute_category                
       ,attribute1          --     ship_line_attribute1 
       ,attribute2          --     ship_line_attribute2 
       ,attribute3          --     ship_line_attribute3 
       ,attribute4          --     ship_line_attribute4 
       ,attribute5          --     ship_line_attribute5 
       ,attribute6          --     ship_line_attribute6 
       ,attribute7          --     ship_line_attribute7 
       ,attribute8          --     ship_line_attribute8 
       ,attribute9          --     ship_line_attribute9 
       ,attribute10         --     ship_line_attribute10
       ,attribute11         --     ship_line_attribute11
       ,attribute12         --     ship_line_attribute12
       ,attribute13         --     ship_line_attribute13
       ,attribute14         --     ship_line_attribute14
       ,attribute15         --     ship_line_attribute15                                  
       ,ussgl_transaction_code                      
       ,government_context                          
       ,reason_id                                   
       ,DECODE(transaction_type,G_CORRECT,DECODE(SIGN(ln_curr_quantity),-1,NULL,'RECEIVING'),destination_context) -- destination_context
       ,source_doc_quantity                         
       ,source_doc_unit_of_measure                  
       ,movement_id                                 
       ,1--use_mtl_lot                                 
       ,1--use_mtl_serial                              
       ,vendor_cum_shipped_qty                      
       ,item_num                                    
       ,document_num                                
       ,document_line_num                           
       ,truck_num                                   
       ,ship_to_location_code                       
       ,container_num                               
       ,substitute_item_num                         
       ,notice_unit_price                           
       ,item_category                               
       ,location_code                               
       ,vendor_name                                 
       ,vendor_num                                  
       ,vendor_site_code                            
       ,intransit_owning_org_code                   
       ,routing_code                                
       ,routing_step                                
       ,release_num                                 
       ,document_shipment_line_num                  
       ,document_distribution_num                   
       ,deliver_to_person_name                      
       ,deliver_to_location_code                    
       ,locator                                     
       ,reason_name                                 
       ,DECODE(transaction_type,G_CORRECT,NULL,validation_flag)
       ,substitute_item_id                          
       ,quantity_shipped                            
       ,quantity_invoiced                           
       ,tax_name                                    
       ,tax_amount                                  
       ,req_num                                     
       ,req_line_num                                
       ,req_distribution_num                        
       ,wip_entity_name                             
       ,wip_line_code                               
       ,resource_code                               
       ,shipment_line_status_code                   
       ,barcode_label                               
       ,transfer_percentage                         
       ,qa_collection_id                            
       ,country_of_origin_code                      
       ,oe_order_header_id                          
       ,oe_order_line_id                            
       ,customer_id                                 
       ,customer_site_id                            
       ,customer_item_num                           
       ,create_debit_memo_flag                      
       ,put_away_rule_id                            
       ,put_away_strategy_id                        
       ,lpn_id                                      
       ,transfer_lpn_id                             
       ,cost_group_id                               
       ,mobile_txn                                  
       ,mmtt_temp_id                                
       ,transfer_cost_group_id                      
       ,secondary_quantity                          
       ,secondary_unit_of_measure                   
       ,secondary_uom_code                          
       ,qc_grade                                    
       ,from_locator                                
       ,from_locator_id                             
       ,parent_source_transaction_num               
       ,interface_available_qty                     
       ,interface_transaction_qty                   
       ,interface_available_amt                     
       ,interface_transaction_amt                   
       ,license_plate_number                        
       ,source_transaction_num                      
       ,transfer_license_plate_number               
       ,lpn_group_id                                
       ,order_transaction_id                        
       ,customer_account_number                     
       ,customer_party_name                         
       ,oe_order_line_num                           
       ,oe_order_num                                
       ,parent_interface_txn_id                     
       ,customer_item_id                            
       ,amount                                      
       ,job_id                                      
       ,timecard_id                                 
       ,timecard_ovn                                
       ,erecord_id                                  
       ,project_id                                  
       ,task_id                                     
       ,asn_attach_id                               
 FROM  xx_gi_rcv_xfr_dtl
 WHERE interface_transaction_id = lcu_dtl_cur.interface_transaction_id;
 
 fnd_file.put_line(fnd_file.log,ln_curr_quantity||'   '|| ln_rcv_quantity);
 IF ln_curr_quantity = ln_rcv_quantity THEN
    EXIT;  -- Exit out of the loop
 END IF;
 END LOOP;

   lc_error_level :=  'After inserting in rcv_transactions_interface,error for Txn interface id: '||lcu_dtl_cur.interface_transaction_id;
   --- Update line status to 'PL'
   UPDATE xx_gi_rcv_xfr_dtl
   SET    od_rcv_status_flag = DECODE(SUBSTR(NVL(attribute4,'#'),1,4),'OHDR','PL','PL1')
   WHERE  interface_transaction_id = lcu_dtl_cur.interface_transaction_id;

 END LOOP;

  -- Update header status to 'PL' of the records successfully passed onto
  -- Interface table for processing.

   lc_error_level :=  'Before update of xx_gi_rcv_xfr_hdr table record to PL for header_interface_id: '|| p_header_interface_id;
   UPDATE xx_gi_rcv_xfr_hdr
   SET    od_rcv_status_flag = DECODE(SUBSTR(NVL(attribute4,'#'),1,4),'OHDR','PL','PL1')
   WHERE  header_interface_id = p_header_interface_id;

  -- Update keyrec status to 'PL' of the records successfully passed onto
  -- Interface table for processing.
   lc_error_level :=  'Before update of xx_gi_rcv_keyrec table record to PL for header_interface_id: '|| p_header_interface_id;
   
   UPDATE xx_gi_rcv_keyrec
   SET    status_cd = 'PL'
   WHERE  keyrec_nbr = p_keyrec_nbr
   AND    loc_nbr    = p_loc_nbr;

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      x_ret_status  := 1;
      x_ret_message := lc_error_level;
      x_ret_message := SUBSTR(x_ret_message||'. '||SQLERRM,1,450);
      fnd_file.put_line(fnd_file.log,'oracle error in INSERT_INTO_XFR_RCVING_TBLS. '||x_ret_message); 
END INSERT_INTO_XFR_RCVING_TBLS ;

-- +===================================================================+
-- | Name             : POPULATE_INTF_XFR_RECEIVING_DATA               |
-- | Description      : This procedure validates the PO receiving info,|
-- |                    derives required values and then populates the |
-- |                    custom table XX_GI_RCV_KEYREC and staging      |
-- |                    tables XX_GI_RCV_PO_HDR, XX_GI_RCV_PO_DTL with |
-- |                    respective information.                        |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns            x_errbuf                                       |
-- |                    x_retcode                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE POPULATE_INT_XFR_RCVING_DATA ( x_errbuf   OUT NOCOPY VARCHAR2
                                        ,x_retcode  OUT NOCOPY NUMBER
                                       )
IS

ln_return_error   NUMBER ;
lc_return_err_msg VARCHAR2(500);

-- Cursor to fetch all the ROI rejected records and valid records for processing
-- for which there exists atlease one item line.

CURSOR lcu_load_hdr_rec IS
SELECT  *
FROM    xx_gi_rcv_xfr_hdr   XGRXH 
WHERE   od_rcv_status_flag IN ('PRCP','E')
AND EXISTS (SELECT '1' FROM xx_gi_rcv_xfr_dtl XGRXD 
            WHERE XGRXH.header_interface_id=XGRXD.header_interface_id 
            AND XGRXD.od_rcv_status_flag IN ('PRCP','E')
            );

BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoking API POPULATE_INTF_XFR_RECEIVING_DATA');
-- Delete RTI records that are in error with same receipt number/keyrec 
-- that are going to be reprocessed.

DELETE 
FROM rcv_transactions_interface RTI
WHERE RTI.attribute8 
IN (SELECT XGRXD.attribute8
    FROM   xx_gi_rcv_xfr_dtl XGRXD
    WHERE  RTI.attribute8             = XGRXD.attribute8
    AND    XGRXD.od_rcv_status_flag   IN ('PRCP','E')
   )
AND   RTI.transaction_status_code = 'ERROR';

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of error records deleted from rcv_transactions_interface: '||NVL(SQL%ROWCOUNT,0)) ;
FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of error records deleted from rcv_transactions_interface: '||NVL(SQL%ROWCOUNT,0)) ;

DELETE FROM 
rcv_headers_interface RHI
WHERE RHI.attribute8
IN (SELECT XGRXH.attribute8
    FROM   xx_gi_rcv_xfr_hdr   XGRXH 
    WHERE  RHI.attribute8             = XGRXH.attribute8
--    AND    XGRXH.od_rcv_status_flag   IN ('PRCP','E')
    )
AND   RHI.processing_status_code IN ('ERROR','SUCCESS');

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of error records deleted from rcv_headers_interface: '||NVL(SQL%ROWCOUNT,0)) ;
FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of error records deleted from rcv_headers_interface: '||NVL(SQL%ROWCOUNT,0)) ;

COMMIT;

-- ******************************************************************
-- Cursor to populate records from PO stage table to Interface table
-- ******************************************************************
FOR lcr_load_hdr_rec IN lcu_load_hdr_rec
LOOP
  insert_into_xfr_rcving_tbls(lcr_load_hdr_rec.header_interface_id
                             ,lcr_load_hdr_rec.attribute8
                             ,lcr_load_hdr_rec.loc_nbr
                             ,ln_return_error
                             ,lc_return_err_msg
                             );
END LOOP;

IF NVL(ln_return_error,0) <> 0 THEN
   x_retcode := 2;
END IF;

EXCEPTION
  WHEN OTHERS THEN
      ROLLBACK;
      x_errbuf  := 'Unexpected error in POPULATE_INT_XFR_RCVING_DATA. '||SQLERRM;
      x_retcode := 2;
      
END POPULATE_INT_XFR_RCVING_DATA ;

-- +===================================================================+
-- | Name             : insert_into_rcving_tbls                        |
-- | Description      : This procedure populates the PO receiving info,|
-- |                    into ROI interface tables as well locks the    |
-- |                    records to PL to avoid any further DML operation|
-- |                    on these records unless processed.             |
-- | Parameters :       p_header_interface_id IN NUMBER                |
-- |                                                                   |
-- | Returns :          x_errbuf              PLS_INTEGER              |
-- |                    x_retcode             VARCHAR2                 |
-- |                                                                   |
-- +===================================================================+

PROCEDURE INSERT_INTO_RCVING_TBLS(p_header_interface_id IN NUMBER                                
                                 ,p_keyrec_nbr          IN VARCHAR2
                                 ,p_loc_nbr             IN VARCHAR2
                                 ,x_ret_status          OUT PLS_INTEGER
                                 ,x_ret_message         OUT VARCHAR2
                                 )
IS

CURSOR lcu_txn_line (p_shipment_line_id IN NUMBER
                    ,p_adj_qty          IN NUMBER)
IS
SELECT transaction_id
      ,quantity
FROM  rcv_transactions 
WHERE shipment_line_id  = p_shipment_line_id
AND   transaction_type  = DECODE(SIGN(p_adj_qty),-1,'DELIVER','RECEIVE') 
ORDER BY quantity desc;

ln_user_id             NUMBER := FND_GLOBAL.user_id;
ln_existing_quantity   NUMBER;
ln_rcv_quantity        NUMBER;
ln_curr_quantity       NUMBER;
lc_error_level         VARCHAR2(150);
ln_lcu_txn_line_count  NUMBER := 0;

-- PL/SQL table type declarations
TYPE Line_txn_id_tbl_typ IS TABLE OF RCV_TRANSACTIONS.transaction_id%type 
INDEX BY BINARY_INTEGER;
lt_line_txn_id  line_txn_id_tbl_typ;

TYPE Line_txn_qty_tbl_typ IS TABLE OF RCV_TRANSACTIONS.quantity%type 
INDEX BY BINARY_INTEGER;
lt_line_qty  line_txn_qty_tbl_typ;

BEGIN

lc_error_level :=  'While inserting in rcv_headers_interface,error for header interface id: '||p_header_interface_id;
FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Inserting into RCV Headers table');
INSERT 
INTO rcv_headers_interface
    (HEADER_INTERFACE_ID        
    ,GROUP_ID            
    ,PROCESSING_STATUS_CODE      
    ,RECEIPT_SOURCE_CODE         
    ,ASN_TYPE            
    ,TRANSACTION_TYPE        
    ,LAST_UPDATE_DATE        
    ,LAST_UPDATED_BY         
    ,LAST_UPDATE_LOGIN       
    ,CREATION_DATE           
    ,CREATED_BY     
    ,EDI_CONTROL_NUM          
    ,AUTO_TRANSACT_CODE       
    ,TEST_FLAG                
    ,NOTICE_CREATION_DATE     
    ,SHIPMENT_NUM             
    ,RECEIPT_NUM              
    ,RECEIPT_HEADER_ID        
    ,VENDOR_NAME              
    ,VENDOR_NUM               
    ,VENDOR_ID                
    ,VENDOR_SITE_CODE         
    ,VENDOR_SITE_ID           
    ,FROM_ORGANIZATION_ID     
    ,SHIP_TO_ORGANIZATION_ID  
    ,LOCATION_CODE            
    ,LOCATION_ID              
    ,BILL_OF_LADING           
    ,PACKING_SLIP             
    ,SHIPPED_DATE             
    ,FREIGHT_CARRIER_CODE     
    ,EXPECTED_RECEIPT_DATE    
    ,RECEIVER_ID              
    ,NUM_OF_CONTAINERS        
    ,WAYBILL_AIRBILL_NUM      
    ,COMMENTS                 
    ,GROSS_WEIGHT             
    ,GROSS_WEIGHT_UOM_CODE    
    ,NET_WEIGHT               
    ,NET_WEIGHT_UOM_CODE      
    ,TAR_WEIGHT               
    ,TAR_WEIGHT_UOM_CODE      
    ,PACKAGING_CODE           
    ,CARRIER_METHOD           
    ,CARRIER_EQUIPMENT        
    ,SPECIAL_HANDLING_CODE    
    ,HAZARD_CODE              
    ,HAZARD_CLASS             
    ,HAZARD_DESCRIPTION       
    ,FREIGHT_TERMS            
    ,FREIGHT_BILL_NUMBER      
    ,INVOICE_NUM              
    ,INVOICE_DATE             
    ,TOTAL_INVOICE_AMOUNT     
    ,TAX_NAME                 
    ,TAX_AMOUNT               
    ,FREIGHT_AMOUNT           
    ,CURRENCY_CODE            
    ,CONVERSION_RATE_TYPE     
    ,CONVERSION_RATE          
    ,CONVERSION_RATE_DATE     
    ,PAYMENT_TERMS_NAME       
    ,PAYMENT_TERMS_ID         
    ,ATTRIBUTE_CATEGORY       
    ,ATTRIBUTE1               
    ,ATTRIBUTE2               
    ,ATTRIBUTE3               
    ,ATTRIBUTE4               
    ,ATTRIBUTE5               
    ,ATTRIBUTE6               
    ,ATTRIBUTE7               
    ,ATTRIBUTE8               
    ,ATTRIBUTE9               
    ,ATTRIBUTE10              
    ,ATTRIBUTE11              
    ,ATTRIBUTE12              
    ,ATTRIBUTE13              
    ,ATTRIBUTE14              
    ,ATTRIBUTE15              
    ,USGGL_TRANSACTION_CODE   
    ,EMPLOYEE_NAME            
    ,EMPLOYEE_ID              
    ,INVOICE_STATUS_CODE      
    ,VALIDATION_FLAG          
    ,PROCESSING_REQUEST_ID    
    ,CUSTOMER_ACCOUNT_NUMBER  
    ,CUSTOMER_ID              
    ,CUSTOMER_SITE_ID         
    ,CUSTOMER_PARTY_NAME      
    ,REMIT_TO_SITE_ID
    )
SELECT  header_interface_id        
      , group_id       
      , 'PENDING'                            
      , 'VENDOR'                             
      , NULL                                 
      , 'NEW'                              
      , SYSDATE                              
      , ln_user_id                   
      , ln_user_id                
      , SYSDATE                              
      , ln_user_id                   
      , edi_control_num                 
      , DECODE(transaction_type,G_CORRECT,auto_transact_code,G_RECEIVE)
      , test_flag                       
      , notice_creation_date            
      , shipment_num                    
      , receipt_num                     
      , receipt_header_id               
      , vendor_name                     
      , vendor_num                      
      , vendor_id                       
      , vendor_site_code                
      , vendor_site_id                  
      , from_organization_id            
      , ship_to_organization_id         
      , location_code                   
      , location_id                     
      , bill_of_lading                  
      , packing_slip                    
      , shipped_date                    
      , freight_carrier_code            
      , expected_receipt_date           
      , receiver_id                     
      , num_of_containers               
      , waybill_airbill_num             
      , comments                        
      , gross_weight                    
      , gross_weight_uom_code           
      , net_weight                      
      , net_weight_uom_code             
      , tar_weight                      
      , tar_weight_uom_code             
      , packaging_code                  
      , carrier_method                  
      , carrier_equipment               
      , special_handling_code           
      , hazard_code                     
      , hazard_class                    
      , hazard_description              
      , freight_terms                   
      , freight_bill_number             
      , invoice_num                     
      , invoice_date                    
      , total_invoice_amount            
      , tax_name                        
      , tax_amount                      
      , freight_amount                  
      , currency_code                   
      , conversion_rate_type            
      , conversion_rate                 
      , conversion_rate_date            
      , payment_terms_name              
      , payment_terms_id                
      , attribute_category              
      , attribute1                      
      , attribute2                      
      , attribute3                      
      , attribute4                      
      , attribute5                      
      , attribute6                      
      , attribute7                      
      , attribute8                      
      , attribute9                      
      , attribute10                     
      , attribute11                     
      , attribute12                     
      , attribute13                     
      , attribute14                     
      , attribute15                     
      , usggl_transaction_code          
      , employee_name                   
      , G_EMPLOYEE_ID                     
      , invoice_status_code             
      , DECODE(transaction_type,G_CORRECT,NULL,'Y')                 
      , processing_request_id           
      , customer_account_number         
      , customer_id                     
      , customer_site_id                
      , customer_party_name             
      , remit_to_site_id                      
FROM  xx_gi_rcv_po_hdr
WHERE header_interface_id = p_header_interface_id;
--AND   legacy_transaction_type = G_ADJUSTMENT_OR_ADD;

FND_FILE.PUT_LINE(FND_FILE.LOG,'After Inserting into RCV Headers Interface table for header id: '||p_header_interface_id);

FOR lcu_dtl_cur IN 
(  SELECT * 
   FROM  xx_gi_rcv_po_dtl
   WHERE header_interface_id = p_header_interface_id 
   AND   od_rcv_status_flag IN ('PRCP','E') 
   ORDER BY quantity desc
)

LOOP
  
  IF SUBSTR(NVL(lcu_dtl_cur.attribute4,'#'),1,4) = G_CORRECTION THEN --  'OHRE'
     lc_error_level :=  'While fetching data from rcv_shipment_lines,error for line record: '||lcu_dtl_cur.interface_transaction_id;
     -- Fetch Quantity already recieved from RCV_SHIPMENT_LINES
     -- in case of correction.
     SELECT quantity_received
     INTO   ln_existing_quantity
     FROM   rcv_shipment_lines
     WHERE  shipment_line_id = lcu_dtl_cur.shipment_line_id;
     
     ln_rcv_quantity  := lcu_dtl_cur.quantity - ln_existing_quantity ;
  -- Get rcv transactions details only for Corrections       
     OPEN  lcu_txn_line (lcu_dtl_cur.shipment_line_id , ln_rcv_quantity);
     FETCH lcu_txn_line BULK COLLECT INTO lt_line_txn_id,lt_line_qty;
     CLOSE lcu_txn_line;
   ELSE -- IF it is 'OHDR'
     ln_rcv_quantity  := lcu_dtl_cur.quantity ;
  END IF;

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Inserting into rcv_transactions_interface table');
  
  -- This is to make sure that loop executes once definately
  IF lt_line_txn_id.COUNT = 0 THEN
     lt_line_txn_id(0)   := -1;
     lt_line_qty(0)      := 0;
  END IF;
  
  ln_lcu_txn_line_count := lt_line_txn_id.COUNT;
  
  lc_error_level :=  'While inserting in rcv_lines_interface,error for line record: '||lcu_dtl_cur.interface_transaction_id;

    -- Inserting in the rcv_transactions_interface table.
    -- In case of Corrections i.e OHRE Txns, we need to split the correction quantity
    -- amont different DELIVER transactions.
 FOR ln_loop_indx IN lt_line_txn_id.FIRST..lt_line_txn_id.LAST
 LOOP
  IF SUBSTR(NVL(lcu_dtl_cur.attribute4,'#'),1,4) = G_CORRECTION THEN --  'OHRE'
    IF ABS(lt_line_qty(ln_loop_indx)) <=  ABS(ln_rcv_quantity) AND (ln_rcv_quantity < 0)  THEN        
          ln_curr_quantity := lt_line_qty(ln_loop_indx) * -1 ;  
          ln_rcv_quantity  := ln_rcv_quantity - ln_curr_quantity ;     
    ELSE
          ln_curr_quantity := ln_rcv_quantity ;     
    END IF;
  END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Qty : ln_curr_quantity : '||ln_curr_quantity ||' ln_rcv_quantity: '||ln_rcv_quantity);
  INSERT INTO rcv_transactions_interface
    (  INTERFACE_TRANSACTION_ID
      ,HEADER_INTERFACE_ID     
      ,GROUP_ID                
      ,LAST_UPDATE_DATE        
      ,LAST_UPDATED_BY         
      ,CREATION_DATE           
      ,CREATED_BY              
      ,LAST_UPDATE_LOGIN       
      ,TRANSACTION_TYPE        
      ,TRANSACTION_DATE        
      ,PROCESSING_STATUS_CODE  
      ,PROCESSING_MODE_CODE    
      ,TRANSACTION_STATUS_CODE 
      ,QUANTITY                
      ,UNIT_OF_MEASURE         
      ,AUTO_TRANSACT_CODE      
      ,RECEIPT_SOURCE_CODE     
      ,SOURCE_DOCUMENT_CODE    
      ,REQUEST_ID                   
      ,PROGRAM_APPLICATION_ID       
      ,PROGRAM_ID                   
      ,PROGRAM_UPDATE_DATE          
      ,PROCESSING_REQUEST_ID        
      ,CATEGORY_ID                  
      ,INTERFACE_SOURCE_CODE        
      ,INTERFACE_SOURCE_LINE_ID     
      ,INV_TRANSACTION_ID           
      ,ITEM_ID                      
      ,ITEM_DESCRIPTION             
      ,ITEM_REVISION                
      ,UOM_CODE                     
      ,EMPLOYEE_ID                  
      ,SHIPMENT_HEADER_ID           
      ,SHIPMENT_LINE_ID             
      ,SHIP_TO_LOCATION_ID          
      ,PRIMARY_QUANTITY             
      ,PRIMARY_UNIT_OF_MEASURE      
      ,VENDOR_ID                    
      ,VENDOR_SITE_ID               
      ,FROM_ORGANIZATION_ID         
      ,FROM_SUBINVENTORY            
      ,TO_ORGANIZATION_ID           
      ,INTRANSIT_OWNING_ORG_ID      
      ,ROUTING_HEADER_ID            
      ,ROUTING_STEP_ID              
      ,PARENT_TRANSACTION_ID        
      ,PO_HEADER_ID                 
      ,PO_REVISION_NUM              
      ,PO_RELEASE_ID                
      ,PO_LINE_ID                   
      ,PO_LINE_LOCATION_ID          
      ,PO_UNIT_PRICE                
      ,CURRENCY_CODE                
      ,CURRENCY_CONVERSION_TYPE     
      ,CURRENCY_CONVERSION_RATE     
      ,CURRENCY_CONVERSION_DATE     
      ,PO_DISTRIBUTION_ID           
      ,REQUISITION_LINE_ID          
      ,REQ_DISTRIBUTION_ID          
      ,CHARGE_ACCOUNT_ID            
      ,SUBSTITUTE_UNORDERED_CODE    
      ,RECEIPT_EXCEPTION_FLAG       
      ,ACCRUAL_STATUS_CODE          
      ,INSPECTION_STATUS_CODE       
      ,INSPECTION_QUALITY_CODE      
      ,DESTINATION_TYPE_CODE        
      ,DELIVER_TO_PERSON_ID         
      ,LOCATION_ID                  
      ,DELIVER_TO_LOCATION_ID       
      ,SUBINVENTORY                 
      ,LOCATOR_ID                   
      ,WIP_ENTITY_ID                
      ,WIP_LINE_ID                  
      ,DEPARTMENT_CODE              
      ,WIP_REPETITIVE_SCHEDULE_ID   
      ,WIP_OPERATION_SEQ_NUM        
      ,WIP_RESOURCE_SEQ_NUM         
      ,BOM_RESOURCE_ID              
      ,SHIPMENT_NUM                 
      ,FREIGHT_CARRIER_CODE         
      ,BILL_OF_LADING               
      ,PACKING_SLIP                 
      ,SHIPPED_DATE                 
      ,EXPECTED_RECEIPT_DATE        
      ,ACTUAL_COST                  
      ,TRANSFER_COST                
      ,TRANSPORTATION_COST          
      ,TRANSPORTATION_ACCOUNT_ID    
      ,NUM_OF_CONTAINERS            
      ,WAYBILL_AIRBILL_NUM          
      ,VENDOR_ITEM_NUM              
      ,VENDOR_LOT_NUM               
      ,RMA_REFERENCE                
      ,COMMENTS                     
      ,ATTRIBUTE_CATEGORY           
      ,ATTRIBUTE1                   
      ,ATTRIBUTE2                   
      ,ATTRIBUTE3                   
      ,ATTRIBUTE4                   
      ,ATTRIBUTE5                   
      ,ATTRIBUTE6                   
      ,ATTRIBUTE7                   
      ,ATTRIBUTE8                   
      ,ATTRIBUTE9                   
      ,ATTRIBUTE10                  
      ,ATTRIBUTE11                  
      ,ATTRIBUTE12                  
      ,ATTRIBUTE13                  
      ,ATTRIBUTE14                  
      ,ATTRIBUTE15                  
      ,SHIP_HEAD_ATTRIBUTE_CATEGORY 
      ,SHIP_HEAD_ATTRIBUTE1         
      ,SHIP_HEAD_ATTRIBUTE2         
      ,SHIP_HEAD_ATTRIBUTE3         
      ,SHIP_HEAD_ATTRIBUTE4         
      ,SHIP_HEAD_ATTRIBUTE5         
      ,SHIP_HEAD_ATTRIBUTE6         
      ,SHIP_HEAD_ATTRIBUTE7         
      ,SHIP_HEAD_ATTRIBUTE8         
      ,SHIP_HEAD_ATTRIBUTE9         
      ,SHIP_HEAD_ATTRIBUTE10        
      ,SHIP_HEAD_ATTRIBUTE11        
      ,SHIP_HEAD_ATTRIBUTE12        
      ,SHIP_HEAD_ATTRIBUTE13        
      ,SHIP_HEAD_ATTRIBUTE14        
      ,SHIP_HEAD_ATTRIBUTE15        
      ,SHIP_LINE_ATTRIBUTE_CATEGORY 
      ,SHIP_LINE_ATTRIBUTE1         
      ,SHIP_LINE_ATTRIBUTE2         
      ,SHIP_LINE_ATTRIBUTE3         
      ,SHIP_LINE_ATTRIBUTE4         
      ,SHIP_LINE_ATTRIBUTE5         
      ,SHIP_LINE_ATTRIBUTE6         
      ,SHIP_LINE_ATTRIBUTE7         
      ,SHIP_LINE_ATTRIBUTE8         
      ,SHIP_LINE_ATTRIBUTE9         
      ,SHIP_LINE_ATTRIBUTE10        
      ,SHIP_LINE_ATTRIBUTE11        
      ,SHIP_LINE_ATTRIBUTE12        
      ,SHIP_LINE_ATTRIBUTE13        
      ,SHIP_LINE_ATTRIBUTE14        
      ,SHIP_LINE_ATTRIBUTE15        
      ,USSGL_TRANSACTION_CODE       
      ,GOVERNMENT_CONTEXT           
      ,REASON_ID                    
      ,DESTINATION_CONTEXT          
      ,SOURCE_DOC_QUANTITY          
      ,SOURCE_DOC_UNIT_OF_MEASURE   
      ,MOVEMENT_ID                  
      ,USE_MTL_LOT                  
      ,USE_MTL_SERIAL               
      ,VENDOR_CUM_SHIPPED_QTY       
      ,ITEM_NUM                     
      ,DOCUMENT_NUM                 
      ,DOCUMENT_LINE_NUM            
      ,TRUCK_NUM                    
      ,SHIP_TO_LOCATION_CODE        
      ,CONTAINER_NUM                
      ,SUBSTITUTE_ITEM_NUM          
      ,NOTICE_UNIT_PRICE            
      ,ITEM_CATEGORY                
      ,LOCATION_CODE                
      ,VENDOR_NAME                  
      ,VENDOR_NUM                   
      ,VENDOR_SITE_CODE             
      ,INTRANSIT_OWNING_ORG_CODE    
      ,ROUTING_CODE                 
      ,ROUTING_STEP                 
      ,RELEASE_NUM                  
      ,DOCUMENT_SHIPMENT_LINE_NUM   
      ,DOCUMENT_DISTRIBUTION_NUM    
      ,DELIVER_TO_PERSON_NAME       
      ,DELIVER_TO_LOCATION_CODE     
      ,LOCATOR                      
      ,REASON_NAME                  
      ,VALIDATION_FLAG              
      ,SUBSTITUTE_ITEM_ID           
      ,QUANTITY_SHIPPED             
      ,QUANTITY_INVOICED            
      ,TAX_NAME                     
      ,TAX_AMOUNT                   
      ,REQ_NUM                      
      ,REQ_LINE_NUM                 
      ,REQ_DISTRIBUTION_NUM         
      ,WIP_ENTITY_NAME              
      ,WIP_LINE_CODE                
      ,RESOURCE_CODE                
      ,SHIPMENT_LINE_STATUS_CODE    
      ,BARCODE_LABEL                
      ,TRANSFER_PERCENTAGE          
      ,QA_COLLECTION_ID             
      ,COUNTRY_OF_ORIGIN_CODE       
      ,OE_ORDER_HEADER_ID           
      ,OE_ORDER_LINE_ID             
      ,CUSTOMER_ID                  
      ,CUSTOMER_SITE_ID             
      ,CUSTOMER_ITEM_NUM            
      ,CREATE_DEBIT_MEMO_FLAG       
      ,PUT_AWAY_RULE_ID             
      ,PUT_AWAY_STRATEGY_ID         
      ,LPN_ID                       
      ,TRANSFER_LPN_ID              
      ,COST_GROUP_ID                
      ,MOBILE_TXN                   
      ,MMTT_TEMP_ID                 
      ,TRANSFER_COST_GROUP_ID       
      ,SECONDARY_QUANTITY           
      ,SECONDARY_UNIT_OF_MEASURE    
      ,SECONDARY_UOM_CODE           
      ,QC_GRADE                     
      ,FROM_LOCATOR                 
      ,FROM_LOCATOR_ID              
      ,PARENT_SOURCE_TRANSACTION_NUM
      ,INTERFACE_AVAILABLE_QTY      
      ,INTERFACE_TRANSACTION_QTY    
      ,INTERFACE_AVAILABLE_AMT      
      ,INTERFACE_TRANSACTION_AMT    
      ,LICENSE_PLATE_NUMBER         
      ,SOURCE_TRANSACTION_NUM       
      ,TRANSFER_LICENSE_PLATE_NUMBER
      ,LPN_GROUP_ID                 
      ,ORDER_TRANSACTION_ID         
      ,CUSTOMER_ACCOUNT_NUMBER      
      ,CUSTOMER_PARTY_NAME          
      ,OE_ORDER_LINE_NUM            
      ,OE_ORDER_NUM                 
      ,PARENT_INTERFACE_TXN_ID      
      ,CUSTOMER_ITEM_ID             
      ,AMOUNT                       
      ,JOB_ID                       
      ,TIMECARD_ID                  
      ,TIMECARD_OVN                 
      ,ERECORD_ID                   
      ,PROJECT_ID                   
      ,TASK_ID                      
      ,ASN_ATTACH_ID 
      )
     SELECT
        DECODE(ln_lcu_txn_line_count,1,interface_transaction_id,rcv_transactions_interface_s.nextval)
       ,DECODE(shipment_header_id,NULL,header_interface_id,NULL)
       ,group_id
       ,SYSDATE
       ,ln_user_id
       ,SYSDATE
       ,ln_user_id
       ,ln_user_id
       ,transaction_type
       ,transaction_date
       ,'PENDING'
       ,'BATCH'
       ,'PENDING'
       , DECODE(transaction_type,G_CORRECT,ln_curr_quantity,ln_rcv_quantity)   -- quantity   
       , unit_of_measure
       , DECODE(transaction_type,G_CORRECT,NULL,G_DELIVER)
       ,'VENDOR'
       ,'PO'
       , request_id
       , program_application_id
       , program_id
       , program_update_date
       , processing_request_id
       , category_id
       , interface_source_code
       , interface_source_line_id
       , inv_transaction_id
       , item_id
       , item_description
       , item_revision
       , uom_code
       , G_EMPLOYEE_ID
       , shipment_header_id
       , shipment_line_id
       , DECODE(transaction_type,G_CORRECT,NULL,ship_to_location_id)
       , DECODE(transaction_type,G_CORRECT,ln_curr_quantity,primary_quantity)
       , unit_of_measure    --  primary_unit_of_measure
       , vendor_id
       , vendor_site_id
       , DECODE(transaction_type,G_CORRECT,to_organization_id, from_organization_id) ----from_organization_id
       , DECODE(transaction_type,G_CORRECT,subinventory,NULL)  -- From_Subinventory
       , to_organization_id
       , intransit_owning_org_id
       , 3  --routing_header_id
       , 1  --routing_step_id
       , DECODE(transaction_type,G_CORRECT,lt_line_txn_id(ln_loop_indx),parent_transaction_id) -- parent_transaction_id                       
       , po_header_id
       , po_revision_num
       , po_release_id
       , po_line_id
       , po_line_location_id
       , po_unit_price
       , currency_code
       , currency_conversion_type
       , currency_conversion_rate
       , currency_conversion_date
       , po_distribution_id
       , requisition_line_id
       , req_distribution_id
       , charge_account_id
       , substitute_unordered_code
       , receipt_exception_flag
       , accrual_status_code
       , inspection_status_code
       , inspection_quality_code
       , DECODE(transaction_type,G_CORRECT,DECODE(SIGN(ln_curr_quantity),-1,'INVENTORY','RECEIVING'),destination_type_code)  --DESTINATION_TYPE_CODE  
       , deliver_to_person_id
       , NULL-- DECODE(shipment_header_id,NULL,ship_to_location_id,NULL)
       , deliver_to_location_id
       , DECODE(transaction_type,G_CORRECT,NULL,subinventory)
       , locator_id
       , wip_entity_id
       , wip_line_id
       , department_code
       , wip_repetitive_schedule_id
       , wip_operation_seq_num
       , wip_resource_seq_num
       , bom_resource_id
       , shipment_num
       , freight_carrier_code
       , bill_of_lading
       , packing_slip
       , shipped_date
       , DECODE(transaction_type,G_CORRECT,NULL,expected_receipt_date)
       , actual_cost
       , transfer_cost
       , transportation_cost
       , transportation_account_id
       , num_of_containers
       , waybill_airbill_num
       , vendor_item_num
       , vendor_lot_num
       , rma_reference
       , comments
       , attribute_category
       , attribute1
       , attribute2
       , attribute3
       , attribute4
       , attribute5
       , attribute6
       , attribute7
       , attribute8
       , attribute9
       , attribute10
       , attribute11
       , attribute12
       , attribute13
       , attribute14
       , interface_transaction_id                 -- attribute15
       , ship_head_attribute_category
       , ship_head_attribute1
       , ship_head_attribute2
       , ship_head_attribute3
       , ship_head_attribute4
       , ship_head_attribute5
       , ship_head_attribute6
       , ship_head_attribute7
       , ship_head_attribute8
       , ship_head_attribute9
       , ship_head_attribute10
       , ship_head_attribute11
       , ship_head_attribute12
       , ship_head_attribute13
       , ship_head_attribute14
       , ship_head_attribute15
       , attribute_category  --     ship_line_attribute_category                
       , attribute1          --     ship_line_attribute1 
       , attribute2          --     ship_line_attribute2 
       , attribute3          --     ship_line_attribute3 
       , attribute4          --     ship_line_attribute4 
       , attribute5          --     ship_line_attribute5 
       , attribute6          --     ship_line_attribute6 
       , attribute7          --     ship_line_attribute7 
       , attribute8          --     ship_line_attribute8 
       , attribute9          --     ship_line_attribute9 
       , attribute10         --     ship_line_attribute10
       , attribute11         --     ship_line_attribute11
       , attribute12         --     ship_line_attribute12
       , attribute13         --     ship_line_attribute13
       , attribute14         --     ship_line_attribute14
       , attribute15         --     ship_line_attribute15            
       , ussgl_transaction_code
       , government_context
       , reason_id
       , DECODE(transaction_type,G_CORRECT,DECODE(SIGN(ln_curr_quantity),-1,NULL,'RECEIVING'),destination_context) -- destination_context       
       , source_doc_quantity
       , source_doc_unit_of_measure
       , movement_id
       , 1--use_mtl_lot
       , 1--use_mtl_serial
       , vendor_cum_shipped_qty
       , item_num
       , document_num
       , DECODE(shipment_line_id,NULL,document_line_num,NULL) 
       , truck_num
       , ship_to_location_code
       , container_num
       , substitute_item_num
       , notice_unit_price
       , item_category
       , location_code
       , vendor_name
       , vendor_num
       , vendor_site_code
       , intransit_owning_org_code
       , routing_code
       , routing_step
       , release_num
       , DECODE(shipment_header_id,NULL,document_shipment_line_num,NULL) 
       , document_distribution_num
       , deliver_to_person_name
       , deliver_to_location_code
       , locator
       , reason_name
       , DECODE(shipment_header_id,NULL,'Y') 
       , substitute_item_id
       , quantity_shipped
       , quantity_invoiced
       , tax_name
       , tax_amount
       , req_num
       , req_line_num
       , req_distribution_num
       , wip_entity_name
       , wip_line_code
       , resource_code
       , shipment_line_status_code
       , barcode_label
       , transfer_percentage
       , qa_collection_id
       , country_of_origin_code
       , oe_order_header_id
       , oe_order_line_id
       , customer_id
       , customer_site_id
       , customer_item_num
       , create_debit_memo_flag
       , put_away_rule_id
       , put_away_strategy_id
       , lpn_id
       , transfer_lpn_id
       , cost_group_id
       , mobile_txn
       , mmtt_temp_id
       , transfer_cost_group_id
       , secondary_quantity
       , secondary_unit_of_measure
       , secondary_uom_code
       , qc_grade
       , from_locator
       , from_locator_id
       , parent_source_transaction_num
       , interface_available_qty
       , interface_transaction_qty
       , interface_available_amt
       , interface_transaction_amt
       , license_plate_number
       , source_transaction_num
       , transfer_license_plate_number
       , lpn_group_id
       , order_transaction_id
       , customer_account_number
       , customer_party_name
       , oe_order_line_num
       , oe_order_num
       , parent_interface_txn_id
       , customer_item_id
       , amount
       , job_id
       , timecard_id
       , timecard_ovn
       , erecord_id
       , project_id
       , task_id
       , asn_attach_id
   FROM  xx_gi_rcv_po_dtl
   WHERE interface_transaction_id = lcu_dtl_cur.interface_transaction_id;

   fnd_file.put_line(fnd_file.log,ln_curr_quantity||'   '|| ln_rcv_quantity);
   IF ln_curr_quantity = ln_rcv_quantity THEN
      EXIT;  -- Exit out of the loop when all the quantities are matched
   END IF;
 
  END LOOP;
 --- Update line status
   UPDATE xx_gi_rcv_po_dtl
   SET    od_rcv_status_flag       = DECODE(SUBSTR(NVL(lcu_dtl_cur.attribute4,'#'),1,4),'OHDR','PL','PL1')
   WHERE  interface_transaction_id = lcu_dtl_cur.interface_transaction_id;
   
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Update table at line for Transaction Id: ' ||lcu_dtl_cur.interface_transaction_id);
 
 END LOOP;

  -- Update header status of the records successfilly passed onto
  -- Interface table for processing.
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Update table at header');
   UPDATE xx_gi_rcv_po_hdr
   SET    od_rcv_status_flag  = DECODE(SUBSTR(NVL(attribute4,'#'),1,4),'OHDR','PL','PL1')
   WHERE  header_interface_id = p_header_interface_id;
   
   FND_FILE.PUT_LINE(FND_FILE.LOG,'After Update table at header for header id: ' || p_header_interface_id);
   
   UPDATE xx_gi_rcv_keyrec
   SET    status_cd = 'PL'
   WHERE  keyrec_nbr = p_keyrec_nbr
   AND    loc_nbr    = p_loc_nbr;

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      x_ret_status  := 1;
      x_ret_message := lc_error_level;
      x_ret_message :=  SUBSTR(x_ret_message||'. '||SQLERRM,1,450);
      FND_FILE.PUT_LINE(FND_FILE.LOG,x_ret_message);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'oracle error in INSERT_INTO_RCVING_TBLS. '||SQLERRM);   
END INSERT_INTO_RCVING_TBLS ;

-- +===================================================================+
-- | Name             : POPULATE_INTF_PO_RECEIVING_DATA                |
-- | Description      : This procedure validates the PO receiving info,|
-- |                    derives required values and then populates the |
-- |                    custom table XX_GI_RCV_KEYREC and staging      |
-- |                    tables XX_GI_RCV_PO_HDR, XX_GI_RCV_PO_DTL with |
-- |                    respective information.                        |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns            x_errbuf                                       |
-- |                    x_retcode                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE POPULATE_INT_PO_RCVING_DATA ( x_errbuf   OUT NOCOPY VARCHAR2
                                       ,x_retcode  OUT NOCOPY NUMBER
                                      )
IS

--
-- Local variable declaration
--

ln_return_error   NUMBER ;
lc_return_err_msg VARCHAR2(500);

-- ******************************************************************************
-- Cursor to fetch all the ROI rejected records and valid records for processing
-- for which there exists atleast one valid item line.
-- ******************************************************************************
CURSOR lcu_load_hdr_rec 
IS
SELECT  *
FROM    xx_gi_rcv_po_hdr XGRPH
WHERE   od_rcv_status_flag IN ('PRCP','E')
AND EXISTS (SELECT '1' FROM xx_gi_rcv_po_dtl XGRPD 
            WHERE XGRPH.header_interface_id=XGRPD.header_interface_id 
            AND XGRPD.od_rcv_status_flag IN ('PRCP','E'));

BEGIN

--  Delete ASN Error Records

DELETE
FROM  rcv_transactions_interface 
WHERE interface_transaction_id IN
     (  SELECT RTI.interface_transaction_id
        FROM   rcv_headers_interface      RHI
              ,rcv_transactions_interface RTI
              ,xx_gi_rcv_po_dtl           XGRPD 
        WHERE RHI.asn_type               = 'ASN'
        AND   RHI.header_interface_id    = RTI.header_interface_id 
    AND   RTI.processing_status_code = 'ERROR' 
    AND   RTI.document_num           = XGRPD.document_num
    AND   RTI.document_line_num      = XGRPD.document_line_num
    AND   XGRPD.od_rcv_status_flag   IN ('PRCP','E')
      );

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of error ASN records deleted from rcv_transactions_interface: '||SQL%ROWCOUNT); 

DELETE
FROM rcv_headers_interface
WHERE header_interface_id = 
            (SELECT RHI.header_interface_id
             FROM   rcv_headers_interface      RHI
                   ,rcv_transactions_interface RTI
                   ,xx_gi_rcv_po_dtl           XGRPD 
            WHERE RHI.asn_type               = 'ASN'
            AND   RHI.header_interface_id    = RTI.header_interface_id 
            AND   RHI.processing_status_code = 'ERROR' 
            AND   RTI.document_num           = XGRPD.document_num
            AND   RTI.document_line_num      = XGRPD.document_line_num
            AND   XGRPD.od_rcv_status_flag   IN ('PRCP','E')
            );

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of error ASN records deleted from rcv_headers_interface: '||SQL%ROWCOUNT);

-- Delete RTI records that are in error with same receipt number/keyrec 
-- that are going to be reprocessed.

DELETE 
FROM rcv_transactions_interface RTI
WHERE RTI.attribute8 
IN (SELECT XGRPD.attribute8
    FROM   xx_gi_rcv_po_dtl XGRPD
    WHERE  RTI.attribute8             = XGRPD.attribute8
    AND    XGRPD.od_rcv_status_flag   IN ('PRCP','E')
   )
AND   RTI.transaction_status_code IN ('ERROR');

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of error records deleted from rcv_transactions_interface: '||SQL%ROWCOUNT) ;
FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of error records deleted from rcv_transactions_interface: '||SQL%ROWCOUNT) ;

DELETE FROM 
rcv_headers_interface RHI
WHERE RHI.attribute8
IN (SELECT XGRPH.attribute8
    FROM   xx_gi_rcv_po_hdr   XGRPH 
    WHERE  RHI.attribute8             = XGRPH.attribute8
--    AND    XGRPH.od_rcv_status_flag   IN ('PRCP','E')
    )
AND   RHI.processing_status_code IN ('ERROR','SUCCESS');

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of error records deleted from rcv_headers_interface: '||SQL%ROWCOUNT) ;
FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of error records deleted from rcv_headers_interface: '||SQL%ROWCOUNT) ;

COMMIT;
-- ***************************************************************
-- Cursor to populate records from PO stage table to Interface table
-- ***************************************************************
FOR lcr_load_hdr_rec IN lcu_load_hdr_rec
LOOP
  insert_into_rcving_tbls(lcr_load_hdr_rec.header_interface_id
                         ,lcr_load_hdr_rec.attribute8
                         ,lcr_load_hdr_rec.loc_nbr
                         ,ln_return_error
                         ,lc_return_err_msg
                         );
END LOOP;

IF NVL(ln_return_error,0) <> 0 THEN
   x_retcode := 2;
END IF;

EXCEPTION
  WHEN OTHERS THEN
      ROLLBACK;
      x_errbuf  := 'Unexpected error in POPULATE_INT_PO_RCVING_DATA. '||SQLERRM;
      x_retcode := 2;
      
END POPULATE_INT_PO_RCVING_DATA ;

-- +===================================================================+
-- | Name             : PO_RCV_UPDATE                                  |
-- | Description      : Procedure to update status of stage table based|
-- |                    upon the status of processing                  |
-- |                                                                   |
-- | Parameters :                                                      |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |                                               |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PO_RCV_UPDATE  ( x_errbuf    OUT NOCOPY VARCHAR2
                          ,x_retcode   OUT NOCOPY NUMBER
                         )
IS

--------------------------------------------------
-- Declaring local Exceptions and local Variables
--------------------------------------------------  
lc_debug            VARCHAR2(240);
lc_hdr_error_msg    xx_gi_rcv_po_hdr.od_rcv_error_description%TYPE;
lc_line_error_msg   xx_gi_rcv_po_hdr.od_rcv_error_description%TYPE;
ln_hdr_interface_id xx_gi_rcv_po_hdr.header_interface_id %TYPE;
ln_data_flag        NUMBER      := 0 ; 
ln_suc_rec          PLS_INTEGER := 0;
lb_temp             BOOLEAN := FALSE ;
-- Declaring PL/SQL table type Variables

TYPE line_intfc_id_tbl_typ IS TABLE OF xx_gi_rcv_po_dtl.interface_transaction_id%type
INDEX BY BINARY_INTEGER;
lt_line_intfc_id  line_intfc_id_tbl_typ;

TYPE error_msg_tbl_typ IS TABLE OF po_interface_errors.error_message%type
INDEX BY BINARY_INTEGER;
lt_err_msg  error_msg_tbl_typ;

BEGIN


    fnd_file.put_line(fnd_file.log,'Receiving PO Update status Program');
    fnd_file.put_line(fnd_file.log,'___________________________________');    
          
    -- Generating Output Reports for Errored and Successfully created receipts
    -- Before any delete or update operation is performed.
    
    lc_debug := 'Before displaying output summary ';
    fnd_file.put_line(fnd_file.output,' Office Depot                             Date: '||to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    fnd_file.put_line(fnd_file.output,'  ');
    fnd_file.put_line(fnd_file.output,'              OD Inventory PO Receiving Summary ');
    
    fnd_file.put_line(fnd_file.output,' ');

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Vendor name          To org name       PO num    PO Line num  Item name            UOM    Quantity   EBS Receipt number     Receipt date  Status');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'________________________________________________________________________________________________________________________________________________');
    FOR lcu_proc_records IN (SELECT XGRPD.interface_transaction_id LINE_INTERFACE_ID
                            , (SELECT vendor_name FROM po_vendors PV 
                               WHERE PV.vendor_id=XGRPD.vendor_id) VENDOR_NAME
                            ,(SELECT  name FROM hr_all_organization_units 
                              WHERE organization_id=RT.organization_id) TO_ORG_NAME
                            ,XGRPD.document_num  DOC_NUM                              
                            ,(SELECT line_num FROM po_lines_all 
                              WHERE po_line_id=RT.po_line_id) LINE_NUM
                            ,XGRPD.item_num     ITEM_NAME
                            ,RT.unit_of_measure UOM
                            ,RT.quantity        QUANTITY
                            ,(SELECT receipt_num 
                              FROM rcv_shipment_headers RSH
                              WHERE RSH.shipment_header_id=RT.shipment_header_id) RECEIPT_NUM
                            ,RT.transaction_date TRANSACTION_DATE
                            FROM rcv_transactions     RT
                                ,xx_gi_rcv_po_dtl     XGRPD              
                            WHERE XGRPD.interface_transaction_id    = RT.attribute15
                            AND   XGRPD.od_rcv_status_flag    = 'PL'  
                            AND   RT.transaction_type IN (G_DELIVER,G_CORRECT)
                            )
    LOOP
      ln_data_flag                 := 1 ;
      lc_debug                     := 'Before getting successful records in a pl/sql table';
      lt_line_intfc_id(ln_suc_rec) := lcu_proc_records.line_interface_id;
      ln_suc_rec                   := ln_suc_rec +1 ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, rpad(lcu_proc_records.vendor_name,20) ||' '||rpad(lcu_proc_records.TO_ORG_NAME,17)||' '||rpad(lcu_proc_records.DOC_NUM,9)   ||' '||rpad(lcu_proc_records.LINE_NUM,12)||' '||rpad(lcu_proc_records.ITEM_NAME,20)||' '||RPAD(lcu_proc_records.UOM,6)
                              ||' '||RPAD(lcu_proc_records.quantity,10)||' '||RPAD(NVL(lcu_proc_records.receipt_num,'***********'),11)||'            '||lcu_proc_records.transaction_date||'     CH');

    
    END LOOP;
    
    lc_debug := 'After displaying output summary ';
    fnd_file.put_line(fnd_file.output,'            ');
    
    IF ln_data_flag = 0 THEN
      fnd_file.put_line(fnd_file.output,'****************** No PO Receipt was processed successfully by ROI ****************');
    END IF;
    
    
    fnd_file.put_line(fnd_file.output,'            ');
    lc_debug := 'Before displaying output summary for error records ';
    fnd_file.put_line(fnd_file.output, '----------------------------------------------------------------------------------------------------------  ');                                 

    fnd_file.put_line(fnd_file.output,'  ');
    fnd_file.put_line(fnd_file.output,'              OD Inventory PO Receiving Errors ');
    
    fnd_file.put_line(fnd_file.output,' ');
    
    -- Updating all the lines which were successfully processed
    FORALL i in lt_line_intfc_id.FIRST..lt_line_intfc_id.LAST
    UPDATE xx_gi_rcv_po_dtl
    SET    od_rcv_status_flag  = 'CH'   
    WHERE  interface_transaction_id   = lt_line_intfc_id(i);
    
    fnd_file.put_line(fnd_file.log,'The number of Line records successfully updated to CH: '||NVL(SQL%ROWCOUNT,0));
    ln_suc_rec := 0;
    lt_line_intfc_id.DELETE;
    -- Displaying errored records in the Output file
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Vendor name          To org name        PO num     PO Line num  Item name       UOM    Quantity   Interface Transaction Id  Error message  ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '______________________________________________________________________________________________________________________________________________');
          
    FOR lcu_fail_records IN (SELECT XGRPD.interface_transaction_id LINE_INTERFACE_ID
                                        ,(SELECT vendor_name FROM po_vendors PV 
                                          WHERE PV.vendor_id = XGRPD.vendor_id) VENDOR_NAME
                                        ,(SELECT  HOU.name FROM hr_all_organization_units HOU 
                                          WHERE HOU.organization_id=RTI.to_organization_id) TO_ORG_NAME
                                        ,XGRPD.document_num  DOC_NUM                              
                                        ,(SELECT line_num FROM po_lines_all 
                                          WHERE po_line_id=RTI.po_line_id) LINE_NUM
                                        ,XGRPD.item_num ITEM_NAME
                                        ,RTI.unit_of_measure             UOM
                                        ,RTI.quantity                    QUANTITY
                                        ,RTI.interface_transaction_id    INTERFACE_TRANSACTION_ID
                                        ,RTI.transaction_date            TRANSACTION_DATE
                                        ,SUBSTR(PIE.error_message,1,150)  ERROR_MESSAGE
                                  FROM rcv_transactions_interface RTI
                                      ,xx_gi_rcv_po_dtl           XGRPD
                                      ,po_interface_errors        PIE
                                  WHERE XGRPD.interface_transaction_id    = RTI.attribute15
                                  AND   XGRPD.od_rcv_status_flag  = 'PL'
                                  AND   PIE.interface_type        = 'RCV-856'
                                  AND  ( ( PIE.interface_line_id = RTI.interface_transaction_id 
                                          AND NVL(PIE.interface_header_id,-999) = -999)
                                  OR ( PIE.interface_header_id  = RTI.header_interface_id 
                                       AND NVL(PIE.interface_line_id,-999) = -999)
                                  OR ( PIE.interface_line_id       = RTI.interface_transaction_id 
                                       AND PIE.interface_header_id = RTI.header_interface_id)
                                      )
                                )
        LOOP
                  
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,  rpad(lcu_fail_records.vendor_name ,20)||' '|| rpad(lcu_fail_records.TO_ORG_NAME,18)||' '||rpad( lcu_fail_records.DOC_NUM,10)||' '|| rpad(lcu_fail_records.LINE_NUM,12)||' '||rpad( lcu_fail_records.ITEM_NAME,15)||' '||rpad(lcu_fail_records.UOM,6)
      ||' '|| rpad(lcu_fail_records.quantity,10)||' '||rpad(lcu_fail_records.interface_transaction_id,25)||' '||lcu_fail_records.error_message);
          lt_line_intfc_id(ln_suc_rec) := lcu_fail_records.line_interface_id;
          lt_err_msg(ln_suc_rec)       := lcu_fail_records.error_message;
          ln_suc_rec                   := ln_suc_rec + 1 ;
          ln_data_flag                 := 2 ;
        END LOOP;
        
       fnd_file.put_line(fnd_file.output,' ');
       IF ln_data_flag < 2 THEN
          fnd_file.put_line(fnd_file.output,'****************** No PO Receipt Failed ROI processing ****************** ');
       END IF;
       
       lc_debug := 'After displaying output summary for Error records';
    
     -- Updating all the lines which were rejected by ROI
     -- 
    FORALL i IN lt_line_intfc_id.FIRST..lt_line_intfc_id.LAST
    UPDATE xx_gi_rcv_po_dtl
    SET    od_rcv_status_flag         = 'E'
          ,od_rcv_error_description   = lt_err_msg(i)
    WHERE  interface_transaction_id   = lt_line_intfc_id(i);
        
    fnd_file.put_line(fnd_file.log,'The number of Line records successfully updated to status E: '||NVL(SQL%ROWCOUNT,0));
    
    ln_suc_rec := 0;
    lt_line_intfc_id.DELETE;
   
        -- Set status to ‘CH’ for header records for which all the line records are 
        -- successfully processed.
        lc_debug := 'Update header records to status E';

        UPDATE xx_gi_rcv_po_hdr XGRPH
        SET    od_rcv_status_flag  = NVL((SELECT DISTINCT od_rcv_status_flag 
                                      FROM xx_gi_rcv_po_dtl XGRPD 
                                      WHERE XGRPD.header_interface_id  = XGRPH.header_interface_id
                                      AND   XGRPD.od_rcv_status_flag   IN ('CH')
                                      ),XGRPH.od_rcv_status_flag)
              ,XGRPH.od_rcv_error_description = NULL
        WHERE XGRPH.od_rcv_status_flag  IN  ('E','PL');                                      
        
        lc_debug := 'Update header records to status CH';
       -- Set status to ‘E’ for line records for which atleast one line record is 
       -- in error status.
 
       UPDATE xx_gi_rcv_po_hdr XGRPH
       SET    XGRPH.od_rcv_status_flag = NVL(( SELECT DISTINCT od_rcv_status_flag 
                                      FROM xx_gi_rcv_po_dtl XGRPD
                                      WHERE XGRPD.header_interface_id = XGRPH.header_interface_id
                                      AND   XGRPD.od_rcv_status_flag   IN ('E')
                                      ),XGRPH.od_rcv_status_flag)
       WHERE  od_rcv_status_flag  IN  ('E','PL','CH');
       
      lc_debug := 'Update header records to status CH';
      -- Set status to ‘E’ for line records for which atleast one line record is 
      -- in error status.

      UPDATE xx_gi_rcv_po_hdr XGRPH
      SET    XGRPH.od_rcv_status_flag  = NVL(( SELECT DISTINCT od_rcv_status_flag 
                     FROM xx_gi_rcv_po_dtl XGRPD
                     WHERE XGRPD.header_interface_id = XGRPH.header_interface_id
                     AND   XGRPD.od_rcv_status_flag   IN ('VE')
                     ),XGRPH.od_rcv_status_flag)
      WHERE  od_rcv_status_flag  IN  ('E','PL','CH','PRCP');

       lc_debug := 'After updating xx_gi_rcv_po_hdr to E';
       
     -- If all the lines of a particular keyrec number were successfully processed then update 
     -- the corresponding keyrec record status to ‘CH’ (Closed)
  
     
     --****************************arun added
       lc_debug := 'Update keyrec records to status E';

     UPDATE xx_gi_rcv_keyrec XGRK
     SET    XGRK.status_cd    = NVL(( SELECT DISTINCT od_rcv_status_flag
                                     FROM xx_gi_rcv_po_hdr  XGRPH
                                     WHERE  XGRK.keyrec_nbr = XGRPH.attribute8
                                     AND   XGRK.loc_nbr = XGRPH.loc_nbr
                                     AND   XGRPH.od_rcv_status_flag   IN ('CH')
                                    ),XGRK.status_cd
                                  )
     WHERE status_cd   IN  ('E','PL');                                      
        
        lc_debug := 'Update keyrec records to status CH';
       -- Set status to ‘E’ for line records for which atleast one line record is 
       -- in error status.
 
     UPDATE xx_gi_rcv_keyrec XGRK
     SET    XGRK.status_cd   = NVL(( SELECT DISTINCT od_rcv_status_flag
                                     FROM xx_gi_rcv_po_hdr  XGRPH
                                     WHERE  XGRK.keyrec_nbr = XGRPH.attribute8
                                     AND   XGRK.loc_nbr = XGRPH.loc_nbr
                                     AND   XGRPH.od_rcv_status_flag   IN ('E')
                                    ),XGRK.status_cd
                                  )
       WHERE  status_cd   IN ('E','PL','CH');
       
      lc_debug := 'Update keyrec records to status CH';
      -- Set status to ‘E’ for line records for which atleast one line record is 
      -- in error status.
     UPDATE xx_gi_rcv_keyrec XGRK
     SET    XGRK.status_cd   = NVL(( SELECT DISTINCT od_rcv_status_flag
                                     FROM xx_gi_rcv_po_hdr  XGRPH
                                     WHERE  XGRK.keyrec_nbr = XGRPH.attribute8
                                     AND   XGRK.loc_nbr = XGRPH.loc_nbr
                                     AND   XGRPH.od_rcv_status_flag   IN ('VE')
                                    ),XGRK.status_cd
                                  )
      WHERE  status_cd   IN ('E','PL','CH','PRCP');

       lc_debug := 'After updating xx_gi_rcv_keyrec';
     --********************************end
          
     fnd_file.put_line(fnd_file.log,'Number of records upated in xx_gi_rcv_keyrec: '|| NVL(SQL%ROWCOUNT,0));
     lc_debug := 'After updating xx_gi_rcv_keyrec to E or CH';       
     
     COMMIT;
    
 EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      fnd_file.put_line(fnd_file.log,'Rolling back....Unexpected error '||lc_debug);
      fnd_file.put_line(fnd_file.log,'Oracle Error is '||SQLERRM);
      x_errbuf := SUBSTR(sqlerrm,1,240);
      x_retcode := 2;
      
END PO_RCV_UPDATE;

-- +===================================================================+
-- | Name             : PO_RCV_PURGE                                   |
-- | Description      : Procedure to purge the data from stage tables  |
-- |                    based upon quick code which stores number of   | 
-- |                    days after which the successfully processed    |
-- |                    records are to be deleted.                     |
-- |                                                                   |
-- | Parameters :                                                      |
-- | Returns :         x_errbuf                                        |
-- |                   x_retcode                                       |                                                    |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PO_RCV_PURGE        ( x_errbuf    OUT NOCOPY VARCHAR2
                               ,x_retcode   OUT NOCOPY NUMBER
                              )
IS

------------------------------------------------------
-- Cursor to fetch data elligible for deletion
------------------------------------------------------
CURSOR lcu_delete_hdr_id 
IS
SELECT XGRPH.header_interface_id
                    FROM   xx_gi_rcv_po_hdr XGRPH
                          ,xx_gi_rcv_keyrec XGRK
                          ,xx_gi_rcv_po_dtl XGRPD 
                    WHERE XGRPH.loc_nbr = XGRK.loc_nbr
                    AND   XGRPH.attribute8 = XGRK.keyrec_nbr
                    AND   XGRPH.header_interface_id = XGRPD.header_interface_id
                    AND   TRUNC(SYSDATE - XGRPH.creation_date) > (SELECT description  FROM fnd_lookup_values_vl 
                                                                  WHERE  lookup_type = 'ODRCV_RECORDS_AGE'
                                                                  AND    lookup_code = XGRK.type_cd)
                    AND XGRPH.od_rcv_status_flag = 'CH'                                        
                    AND XGRPD.od_rcv_status_flag = 'CH';
 
--------------------------------------------------
-- Declaring local Exceptions and local Variables
--------------------------------------------------  

lc_debug            VARCHAR2(240);
ln_line_purge       NUMBER := 0;

TYPE header_intfc_id_tbl_typ IS TABLE OF xx_gi_rcv_po_hdr.header_interface_id%type
INDEX BY BINARY_INTEGER;
lt_hdr_intfc_id  header_intfc_id_tbl_typ;

BEGIN


    fnd_file.put_line(fnd_file.log,'PO Purge Program');
    fnd_file.put_line(fnd_file.log,'__________________________');        
    
  
  -- Fetch header interface id of the records to be deleted.
    lc_debug := 'While Opening Cursor lcu_delete_hdr_id';
    
    OPEN  lcu_delete_hdr_id;
    FETCH lcu_delete_hdr_id BULK COLLECT INTO lt_hdr_intfc_id;
    CLOSE lcu_delete_hdr_id;

    lc_debug := 'While closing cursor'; 
    
    -- Delete aged header records. 
    FORALL i IN 1..lt_hdr_intfc_id.COUNT
    DELETE 
    FROM xx_gi_rcv_po_hdr XGRPH
    WHERE XGRPH.header_interface_id =  lt_hdr_intfc_id(i);
    
    lc_debug := 'After Deleting of aged records from xx_gi_rcv_po_hdr'; 
    fnd_file.put_line(fnd_file.log,'Number of records Purged from xx_gi_rcv_po_hdr: '|| lt_hdr_intfc_id.COUNT);
    lc_debug := 'While Deleting line records';
    -- Delete aged Detail records. 
    
    FORALL i IN 1..lt_hdr_intfc_id.COUNT
    DELETE 
    FROM  xx_gi_rcv_po_dtl XGRPD
    WHERE XGRPD.header_interface_id =  lt_hdr_intfc_id(i);
    
    ln_line_purge := NVL(SQL%ROWCOUNT,0);
    lc_debug := 'After Deleting of aged records from xx_gi_rcv_po_dtl'; 
    fnd_file.put_line(fnd_file.log,'Number of records Purged from xx_gi_rcv_po_dtl: '|| ln_line_purge);

    lc_debug := 'Print output Report';
    fnd_file.put_line(fnd_file.output,' Office Depot                             Date: '||to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    fnd_file.put_line(fnd_file.output,'  ');
    fnd_file.put_line(fnd_file.output,'              OD Inventory PO Purge Receiving Summary ');
    
    fnd_file.put_line(fnd_file.output,' ');
    lc_debug := 'While printing the statistics report'; 
    fnd_file.put_line(fnd_file.output,'Number of PO Header records deleted: '||lt_hdr_intfc_id.COUNT);
    fnd_file.put_line(fnd_file.output,'Number of PO detail records deleted: '||ln_line_purge);
   
    fnd_file.put_line(fnd_file.output,' ');
    fnd_file.put_line(fnd_file.output,' **********************************************************');
    
    lc_debug := 'Before commit'; 
    COMMIT;
    
 EXCEPTION
   WHEN OTHERS THEN

      ROLLBACK;

      fnd_file.put_line(fnd_file.log,'Unexpected error: '||lc_debug);
      fnd_file.put_line(fnd_file.log,'Oracle Error is '||SQLERRM);
      x_errbuf  := SUBSTR(sqlerrm,1,240);
      x_retcode := 2;
      
END PO_RCV_PURGE;

-- +===================================================================+
-- | Name             : PO_RCV_REPROCESS                               |
-- | Description      :                                                |
-- | Parameters       :                                                |
-- | Returns :                x_errbuf                                 |
-- |                          x_retcode                                |
-- +===================================================================+

PROCEDURE PO_RCV_REPROCESS(x_errbuf    OUT NOCOPY VARCHAR2
                          ,x_retcode   OUT NOCOPY NUMBER
                          )
IS
   lr_header_rec     xx_gi_rcv_po_hdr%ROWTYPE ;
   lt_detail_tbl     detail_tbl_type;
   lc_return_status  VARCHAR2(1)    := NULL;
   lc_return_message VARCHAR2(1000) := NULL;
   indx              NUMBER         := NULL;
   ---------------------------------------------------
   --Cursor to Select header records for re-validation
   ---------------------------------------------------
   CURSOR lcu_header_recds
   IS
   SELECT * 
   FROM  xx_gi_rcv_po_hdr XGRPH
   WHERE XGRPH.od_rcv_status_flag IN ('VE','PRCP')
   ;
   -------------------------------------------------
   --Cursor to Select line records for re-validation
   -------------------------------------------------
   CURSOR lcu_line_recds(p_header_interface_id IN NUMBER)
   IS
   SELECT * 
   FROM  xx_gi_rcv_po_dtl XGRPD
   WHERE XGRPD.od_rcv_status_flag IN ('VE','PRCP')
   AND   XGRPD.header_interface_id = p_header_interface_id
   ;

BEGIN
   
   FOR i IN lcu_header_recds
   LOOP
      lr_header_rec := NULL;
      -----------------------------------------
      -- Populate header records for validation
      -----------------------------------------

      lr_header_rec := i;
      -------------------------------------
      --Initialize the index and line table
      -------------------------------------
      indx          := 0;
      lt_detail_tbl.DELETE;
      ---------------------------------------
      -- Populate line records for validation
      ---------------------------------------
      FOR j IN lcu_line_recds(i.header_interface_id)
      LOOP
         lt_detail_tbl(indx) := j;
         indx                := indx + 1;     
         
      END LOOP;
    
      VALIDATE_STG_PO_RECEIVING_DATA
                        (x_header_rec     => lr_header_rec
                        ,x_detail_tbl     => lt_detail_tbl
                        ,x_return_status  => lc_return_status
                        ,x_return_message => lc_return_message
                        );
         fnd_file.put_line(fnd_file.log,'lc_return_message '||lc_return_message);

         fnd_file.put_line(fnd_file.log,'lt_detail_tbl.COUNT: '||lt_detail_tbl.COUNT);
         fnd_file.put_line(fnd_file.log,'lr_header_rec.header_interface_id: '||lr_header_rec.header_interface_id);
--       fnd_file.put_line(fnd_file.log,'lt_detail_tbl(0).interface_transaction_id '||lt_detail_tbl(0).interface_transaction_id);
         
                        
      IF NVL(lc_return_status,'S') <> 'U' THEN
         -----------------------------------------
         -- Update re-validated header information 
         -----------------------------------------
         UPDATE xx_gi_rcv_po_hdr
         SET  last_update_date          = SYSDATE        
             ,last_updated_by           = FND_GLOBAL.user_id
             ,last_update_login         = FND_GLOBAL.login_id
             ,notice_creation_date      = lr_header_rec.notice_creation_date    
             ,shipment_num              = lr_header_rec.attribute5            
             ,receipt_num               = lr_header_rec.receipt_num             
             ,receipt_header_id         = lr_header_rec.receipt_header_id       
             ,vendor_name               = lr_header_rec.vendor_name             
             ,vendor_num                = lr_header_rec.vendor_num              
             ,vendor_id                 = lr_header_rec.vendor_id               
             ,vendor_site_code          = lr_header_rec.vendor_site_code        
             ,vendor_site_id            = lr_header_rec.vendor_site_id          
             ,from_organization_code    = lr_header_rec.from_organization_code  
             ,from_organization_id      = lr_header_rec.from_organization_id    
             ,ship_to_organization_code = lr_header_rec.ship_to_organization_code
             ,ship_to_organization_id   = lr_header_rec.ship_to_organization_id 
             ,location_code             = lr_header_rec.location_code           
             ,location_id               = lr_header_rec.location_id             
             ,bill_of_lading            = lr_header_rec.bill_of_lading          
             ,packing_slip              = lr_header_rec.packing_slip            
             ,shipped_date              = lr_header_rec.shipped_date            
             ,freight_carrier_code      = lr_header_rec.freight_carrier_code    
             ,expected_receipt_date     = lr_header_rec.expected_receipt_date   
             ,receiver_id               = lr_header_rec.receiver_id             
             ,num_of_containers         = lr_header_rec.num_of_containers       
             ,waybill_airbill_num       = lr_header_rec.waybill_airbill_num     
             ,comments                  = lr_header_rec.comments                
             ,gross_weight              = lr_header_rec.gross_weight            
             ,gross_weight_uom_code     = lr_header_rec.gross_weight_uom_code   
             ,net_weight                = lr_header_rec.net_weight              
             ,net_weight_uom_code       = lr_header_rec.net_weight_uom_code     
             ,tar_weight                = lr_header_rec.tar_weight              
             ,tar_weight_uom_code       = lr_header_rec.tar_weight_uom_code     
             ,packaging_code            = lr_header_rec.packaging_code          
             ,carrier_method            = lr_header_rec.carrier_method          
             ,carrier_equipment         = lr_header_rec.carrier_equipment       
             ,special_handling_code     = lr_header_rec.special_handling_code   
             ,hazard_code               = lr_header_rec.hazard_code             
             ,hazard_class              = lr_header_rec.hazard_class            
             ,hazard_description        = lr_header_rec.hazard_description      
             ,freight_terms             = lr_header_rec.freight_terms           
             ,freight_bill_number       = lr_header_rec.freight_bill_number     
             ,invoice_num               = lr_header_rec.invoice_num             
             ,invoice_date              = lr_header_rec.invoice_date            
             ,total_invoice_amount      = lr_header_rec.total_invoice_amount    
             ,tax_name                  = lr_header_rec.tax_name                
             ,tax_amount                = lr_header_rec.tax_amount              
             ,freight_amount            = lr_header_rec.freight_amount          
             ,currency_code             = lr_header_rec.currency_code           
             ,conversion_rate_type      = lr_header_rec.conversion_rate_type    
             ,conversion_rate           = lr_header_rec.conversion_rate         
             ,conversion_rate_date      = lr_header_rec.conversion_rate_date    
             ,payment_terms_name        = lr_header_rec.payment_terms_name      
             ,payment_terms_id          = lr_header_rec.payment_terms_id        
             ,attribute_category        = lr_header_rec.attribute_category      
             ,attribute1                = lr_header_rec.attribute1              
             ,attribute2                = lr_header_rec.attribute2              
             ,attribute3                = lr_header_rec.attribute3              
             ,attribute4                = lr_header_rec.attribute4              
             ,attribute5                = lr_header_rec.attribute5              
             ,attribute6                = lr_header_rec.attribute6              
             ,attribute7                = lr_header_rec.attribute7              
             ,attribute8                = lr_header_rec.attribute8              
             ,attribute9                = lr_header_rec.attribute9              
             ,attribute10               = lr_header_rec.attribute10             
             ,attribute11               = lr_header_rec.attribute11             
             ,attribute12               = lr_header_rec.attribute12             
             ,attribute13               = lr_header_rec.attribute13             
             ,attribute14               = lr_header_rec.attribute14             
             ,attribute15               = lr_header_rec.attribute15             
             ,usggl_transaction_code    = lr_header_rec.usggl_transaction_code  
             ,employee_name             = lr_header_rec.employee_name           
             ,employee_id               = lr_header_rec.employee_id             
             ,invoice_status_code       = lr_header_rec.invoice_status_code     
             ,validation_flag           = lr_header_rec.validation_flag         
             ,processing_request_id     = lr_header_rec.processing_request_id   
             ,customer_account_number   = lr_header_rec.customer_account_number 
             ,customer_id               = lr_header_rec.customer_id             
             ,customer_site_id          = lr_header_rec.customer_site_id        
             ,customer_party_name       = lr_header_rec.customer_party_name     
             ,remit_to_site_id          = lr_header_rec.remit_to_site_id        
             ,transaction_date          = lr_header_rec.transaction_date        
             ,org_id                    = lr_header_rec.org_id                  
             ,operating_unit            = lr_header_rec.operating_unit          
             ,ship_from_location_id     = lr_header_rec.ship_from_location_id   
             ,performance_period_from   = lr_header_rec.performance_period_from 
             ,performance_period_to     = lr_header_rec.performance_period_to   
             ,request_date              = lr_header_rec.request_date            
             ,ship_from_location_code   = lr_header_rec.ship_from_location_code 
             ,od_rcv_status_flag        = lr_header_rec.od_rcv_status_flag      
         WHERE header_interface_id      = lr_header_rec.header_interface_id
         ;
         fnd_file.put_line(fnd_file.log,'lr_header_rec.header_interface_id '||lr_header_rec.header_interface_id);
         IF lt_detail_tbl.COUNT > 0 THEN
           FOR i IN lt_detail_tbl.FIRST..lt_detail_tbl.LAST
           LOOP
            ---------------------------------------------------
            -- Update the re-validate transfer line information
            ---------------------------------------------------
            UPDATE xx_gi_rcv_po_dtl
            SET last_update_date              = SYSDATE
               ,last_updated_by               = FND_GLOBAL.user_id
               ,last_update_login             = FND_GLOBAL.login_id
               ,program_update_date           = lt_detail_tbl(i).program_update_date             
               ,transaction_date              = lt_detail_tbl(i).transaction_date                
               ,transaction_status_code       = lt_detail_tbl(i).transaction_status_code         
               ,category_id                   = lt_detail_tbl(i).category_id                     
               ,quantity                      = lt_detail_tbl(i).quantity                        
               ,unit_of_measure               = lt_detail_tbl(i).unit_of_measure                 
               ,interface_source_code         = lt_detail_tbl(i).interface_source_code           
               ,interface_source_line_id      = lt_detail_tbl(i).interface_source_line_id        
               ,inv_transaction_id            = lt_detail_tbl(i).inv_transaction_id              
               ,item_id                       = lt_detail_tbl(i).item_id                         
               ,item_description              = lt_detail_tbl(i).item_description                
               ,item_revision                 = lt_detail_tbl(i).item_revision                   
               ,uom_code                      = lt_detail_tbl(i).uom_code                        
               ,employee_id                   = lt_detail_tbl(i).employee_id                     
               ,auto_transact_code            = lt_detail_tbl(i).auto_transact_code              
               ,shipment_header_id            = lt_detail_tbl(i).shipment_header_id              
               ,shipment_line_id              = lt_detail_tbl(i).shipment_line_id                
               ,ship_to_location_id           = lt_detail_tbl(i).ship_to_location_id             
               ,primary_quantity              = lt_detail_tbl(i).primary_quantity                
               ,primary_unit_of_measure       = lt_detail_tbl(i).primary_unit_of_measure         
               ,receipt_source_code           = lt_detail_tbl(i).receipt_source_code             
               ,vendor_id                     = lt_detail_tbl(i).vendor_id                       
               ,vendor_site_id                = lt_detail_tbl(i).vendor_site_id                  
               ,from_organization_id          = lt_detail_tbl(i).from_organization_id            
               ,from_subinventory             = lt_detail_tbl(i).from_subinventory               
               ,to_organization_id            = lt_detail_tbl(i).to_organization_id              
               ,intransit_owning_org_id       = lt_detail_tbl(i).intransit_owning_org_id         
               ,routing_header_id             = lt_detail_tbl(i).routing_header_id               
               ,routing_step_id               = lt_detail_tbl(i).routing_step_id                 
               ,source_document_code          = lt_detail_tbl(i).source_document_code            
               ,parent_transaction_id         = lt_detail_tbl(i).parent_transaction_id           
               ,po_header_id                  = lt_detail_tbl(i).po_header_id                    
               ,po_revision_num               = lt_detail_tbl(i).po_revision_num                 
               ,po_release_id                 = lt_detail_tbl(i).po_release_id                   
               ,po_line_id                    = lt_detail_tbl(i).po_line_id                      
               ,po_line_location_id           = lt_detail_tbl(i).po_line_location_id             
               ,po_unit_price                 = lt_detail_tbl(i).po_unit_price                   
               ,currency_code                 = lt_detail_tbl(i).currency_code                   
               ,currency_conversion_type      = lt_detail_tbl(i).currency_conversion_type        
               ,currency_conversion_rate      = lt_detail_tbl(i).currency_conversion_rate        
               ,currency_conversion_date      = lt_detail_tbl(i).currency_conversion_date        
               ,po_distribution_id            = lt_detail_tbl(i).po_distribution_id              
               ,requisition_line_id           = lt_detail_tbl(i).requisition_line_id             
               ,req_distribution_id           = lt_detail_tbl(i).req_distribution_id             
               ,charge_account_id             = lt_detail_tbl(i).charge_account_id               
               ,substitute_unordered_code     = lt_detail_tbl(i).substitute_unordered_code       
               ,receipt_exception_flag        = lt_detail_tbl(i).receipt_exception_flag          
               ,accrual_status_code           = lt_detail_tbl(i).accrual_status_code             
               ,inspection_status_code        = lt_detail_tbl(i).inspection_status_code          
               ,inspection_quality_code       = lt_detail_tbl(i).inspection_quality_code         
               ,destination_type_code         = lt_detail_tbl(i).destination_type_code           
               ,deliver_to_person_id          = lt_detail_tbl(i).deliver_to_person_id            
               ,location_id                   = lt_detail_tbl(i).location_id                     
               ,deliver_to_location_id        = lt_detail_tbl(i).deliver_to_location_id          
               ,subinventory                  = lt_detail_tbl(i).subinventory                    
               ,locator_id                    = lt_detail_tbl(i).locator_id                      
               ,wip_entity_id                 = lt_detail_tbl(i).wip_entity_id                   
               ,wip_line_id                   = lt_detail_tbl(i).wip_line_id                     
               ,department_code               = lt_detail_tbl(i).department_code                 
               ,wip_repetitive_schedule_id    = lt_detail_tbl(i).wip_repetitive_schedule_id      
               ,wip_operation_seq_num         = lt_detail_tbl(i).wip_operation_seq_num           
               ,wip_resource_seq_num          = lt_detail_tbl(i).wip_resource_seq_num            
               ,bom_resource_id               = lt_detail_tbl(i).bom_resource_id                 
               ,shipment_num                  = lt_detail_tbl(i).attribute5                   
               ,freight_carrier_code          = lt_detail_tbl(i).freight_carrier_code            
               ,bill_of_lading                = lt_detail_tbl(i).bill_of_lading                  
               ,packing_slip                  = lt_detail_tbl(i).packing_slip                    
               ,shipped_date                  = lt_detail_tbl(i).shipped_date                    
               ,expected_receipt_date         = lt_detail_tbl(i).expected_receipt_date           
               ,actual_cost                   = lt_detail_tbl(i).actual_cost                     
               ,transfer_cost                 = lt_detail_tbl(i).transfer_cost                   
               ,transportation_cost           = lt_detail_tbl(i).transportation_cost             
               ,transportation_account_id     = lt_detail_tbl(i).transportation_account_id       
               ,num_of_containers             = lt_detail_tbl(i).num_of_containers               
               ,waybill_airbill_num           = lt_detail_tbl(i).waybill_airbill_num             
               ,vendor_item_num               = lt_detail_tbl(i).vendor_item_num                 
               ,vendor_lot_num                = lt_detail_tbl(i).vendor_lot_num                  
               ,rma_reference                 = lt_detail_tbl(i).rma_reference                   
               ,comments                      = lt_detail_tbl(i).comments                        
               ,attribute_category            = lt_detail_tbl(i).attribute_category              
               ,attribute1                    = lt_detail_tbl(i).attribute1                      
               ,attribute2                    = lt_detail_tbl(i).attribute2                      
               ,attribute3                    = lt_detail_tbl(i).attribute3                      
               ,attribute4                    = lt_detail_tbl(i).attribute4                      
               ,attribute5                    = lt_detail_tbl(i).attribute5                      
               ,attribute6                    = lt_detail_tbl(i).attribute6                      
               ,attribute7                    = lt_detail_tbl(i).attribute7                      
               ,attribute8                    = lt_detail_tbl(i).attribute8                      
               ,attribute9                    = lt_detail_tbl(i).attribute9                      
               ,attribute10                   = lt_detail_tbl(i).attribute10                     
               ,attribute11                   = lt_detail_tbl(i).attribute11                     
               ,attribute12                   = lt_detail_tbl(i).attribute12                     
               ,attribute13                   = lt_detail_tbl(i).attribute13                     
               ,attribute14                   = lt_detail_tbl(i).attribute14                     
               ,attribute15                   = lt_detail_tbl(i).attribute15                     
               ,ship_head_attribute_category  = lt_detail_tbl(i).ship_head_attribute_category    
               ,ship_head_attribute1          = lt_detail_tbl(i).ship_head_attribute1            
               ,ship_head_attribute2          = lt_detail_tbl(i).ship_head_attribute2            
               ,ship_head_attribute3          = lt_detail_tbl(i).ship_head_attribute3            
               ,ship_head_attribute4          = lt_detail_tbl(i).ship_head_attribute4            
               ,ship_head_attribute5          = lt_detail_tbl(i).ship_head_attribute5            
               ,ship_head_attribute6          = lt_detail_tbl(i).ship_head_attribute6            
               ,ship_head_attribute7          = lt_detail_tbl(i).ship_head_attribute7            
               ,ship_head_attribute8          = lt_detail_tbl(i).ship_head_attribute8            
               ,ship_head_attribute9          = lt_detail_tbl(i).ship_head_attribute9            
               ,ship_head_attribute10         = lt_detail_tbl(i).ship_head_attribute10           
               ,ship_head_attribute11         = lt_detail_tbl(i).ship_head_attribute11           
               ,ship_head_attribute12         = lt_detail_tbl(i).ship_head_attribute12           
               ,ship_head_attribute13         = lt_detail_tbl(i).ship_head_attribute13           
               ,ship_head_attribute14         = lt_detail_tbl(i).ship_head_attribute14           
               ,ship_head_attribute15         = lt_detail_tbl(i).ship_head_attribute15           
               ,ship_line_attribute_category  = lt_detail_tbl(i).attribute_category           
               ,ship_line_attribute1          = lt_detail_tbl(i).attribute1                   
               ,ship_line_attribute2          = lt_detail_tbl(i).attribute2                   
               ,ship_line_attribute3          = lt_detail_tbl(i).attribute3                   
               ,ship_line_attribute4          = lt_detail_tbl(i).attribute4                   
               ,ship_line_attribute5          = lt_detail_tbl(i).attribute5                   
               ,ship_line_attribute6          = lt_detail_tbl(i).attribute6                   
               ,ship_line_attribute7          = lt_detail_tbl(i).attribute7                   
               ,ship_line_attribute8          = lt_detail_tbl(i).attribute8                   
               ,ship_line_attribute9          = lt_detail_tbl(i).attribute9                   
               ,ship_line_attribute10         = lt_detail_tbl(i).attribute10                  
               ,ship_line_attribute11         = lt_detail_tbl(i).attribute11                  
               ,ship_line_attribute12         = lt_detail_tbl(i).attribute12                  
               ,ship_line_attribute13         = lt_detail_tbl(i).attribute13                  
               ,ship_line_attribute14         = lt_detail_tbl(i).attribute14                  
               ,ship_line_attribute15         = lt_detail_tbl(i).attribute15                  
               ,ussgl_transaction_code        = lt_detail_tbl(i).ussgl_transaction_code          
               ,government_context            = lt_detail_tbl(i).government_context              
               ,reason_id                     = lt_detail_tbl(i).reason_id                       
               ,destination_context           = lt_detail_tbl(i).destination_context             
               ,source_doc_quantity           = lt_detail_tbl(i).source_doc_quantity             
               ,source_doc_unit_of_measure    = lt_detail_tbl(i).source_doc_unit_of_measure      
               ,movement_id                   = lt_detail_tbl(i).movement_id                     
               ,header_interface_id           = lt_detail_tbl(i).header_interface_id             
               ,vendor_cum_shipped_qty        = lt_detail_tbl(i).vendor_cum_shipped_qty          
               ,item_num                      = lt_detail_tbl(i).item_num                        
               ,document_num                  = lt_detail_tbl(i).document_num                    
               ,document_line_num             = lt_detail_tbl(i).document_line_num               
               ,truck_num                     = lt_detail_tbl(i).truck_num                       
               ,ship_to_location_code         = lt_detail_tbl(i).ship_to_location_code           
               ,container_num                 = lt_detail_tbl(i).container_num                   
               ,substitute_item_num           = lt_detail_tbl(i).substitute_item_num             
               ,notice_unit_price             = lt_detail_tbl(i).notice_unit_price               
               ,item_category                 = lt_detail_tbl(i).item_category                   
               ,location_code                 = lt_detail_tbl(i).location_code                   
               ,vendor_name                   = lt_detail_tbl(i).vendor_name                     
               ,vendor_num                    = lt_detail_tbl(i).vendor_num                      
               ,vendor_site_code              = lt_detail_tbl(i).vendor_site_code                
               ,from_organization_code        = lt_detail_tbl(i).from_organization_code          
               ,to_organization_code          = lt_detail_tbl(i).to_organization_code            
               ,intransit_owning_org_code     = lt_detail_tbl(i).intransit_owning_org_code       
               ,routing_code                  = lt_detail_tbl(i).routing_code                    
               ,routing_step                  = lt_detail_tbl(i).routing_step                    
               ,release_num                   = lt_detail_tbl(i).release_num                     
               ,document_shipment_line_num    = lt_detail_tbl(i).document_shipment_line_num      
               ,document_distribution_num     = lt_detail_tbl(i).document_distribution_num       
               ,deliver_to_person_name        = lt_detail_tbl(i).deliver_to_person_name          
               ,deliver_to_location_code      = lt_detail_tbl(i).deliver_to_location_code        
               ,use_mtl_lot                   = lt_detail_tbl(i).use_mtl_lot                     
               ,use_mtl_serial                = lt_detail_tbl(i).use_mtl_serial                  
               ,locator                       = lt_detail_tbl(i).locator                         
               ,reason_name                   = lt_detail_tbl(i).reason_name                     
               ,validation_flag               = lt_detail_tbl(i).validation_flag                 
               ,substitute_item_id            = lt_detail_tbl(i).substitute_item_id              
               ,quantity_shipped              = lt_detail_tbl(i).quantity_shipped                
               ,quantity_invoiced             = lt_detail_tbl(i).quantity_invoiced               
               ,tax_name                      = lt_detail_tbl(i).tax_name                        
               ,tax_amount                    = lt_detail_tbl(i).tax_amount                      
               ,req_num                       = lt_detail_tbl(i).req_num                         
               ,req_line_num                  = lt_detail_tbl(i).req_line_num                    
               ,req_distribution_num          = lt_detail_tbl(i).req_distribution_num            
               ,wip_entity_name               = lt_detail_tbl(i).wip_entity_name                 
               ,wip_line_code                 = lt_detail_tbl(i).wip_line_code                   
               ,resource_code                 = lt_detail_tbl(i).resource_code                   
               ,shipment_line_status_code     = lt_detail_tbl(i).shipment_line_status_code       
               ,barcode_label                 = lt_detail_tbl(i).barcode_label                   
               ,transfer_percentage           = lt_detail_tbl(i).transfer_percentage             
               ,qa_collection_id              = lt_detail_tbl(i).qa_collection_id                
               ,country_of_origin_code        = lt_detail_tbl(i).country_of_origin_code          
               ,oe_order_header_id            = lt_detail_tbl(i).oe_order_header_id              
               ,oe_order_line_id              = lt_detail_tbl(i).oe_order_line_id                
               ,customer_id                   = lt_detail_tbl(i).customer_id                     
               ,customer_site_id              = lt_detail_tbl(i).customer_site_id                
               ,customer_item_num             = lt_detail_tbl(i).customer_item_num               
               ,create_debit_memo_flag        = lt_detail_tbl(i).create_debit_memo_flag          
               ,put_away_rule_id              = lt_detail_tbl(i).put_away_rule_id                
               ,put_away_strategy_id          = lt_detail_tbl(i).put_away_strategy_id            
               ,lpn_id                        = lt_detail_tbl(i).lpn_id                          
               ,transfer_lpn_id               = lt_detail_tbl(i).transfer_lpn_id                 
               ,cost_group_id                 = lt_detail_tbl(i).cost_group_id                   
               ,mobile_txn                    = lt_detail_tbl(i).mobile_txn                      
               ,mmtt_temp_id                  = lt_detail_tbl(i).mmtt_temp_id                    
               ,transfer_cost_group_id        = lt_detail_tbl(i).transfer_cost_group_id          
               ,secondary_quantity            = lt_detail_tbl(i).secondary_quantity              
               ,secondary_unit_of_measure     = lt_detail_tbl(i).secondary_unit_of_measure       
               ,secondary_uom_code            = lt_detail_tbl(i).secondary_uom_code              
               ,qc_grade                      = lt_detail_tbl(i).qc_grade                        
               ,from_locator                  = lt_detail_tbl(i).from_locator                    
               ,from_locator_id               = lt_detail_tbl(i).from_locator_id                 
               ,parent_source_transaction_num = lt_detail_tbl(i).parent_source_transaction_num   
               ,interface_available_qty       = lt_detail_tbl(i).interface_available_qty         
               ,interface_transaction_qty     = lt_detail_tbl(i).interface_transaction_qty       
               ,interface_available_amt       = lt_detail_tbl(i).interface_available_amt         
               ,interface_transaction_amt     = lt_detail_tbl(i).interface_transaction_amt       
               ,license_plate_number          = lt_detail_tbl(i).license_plate_number            
               ,source_transaction_num        = lt_detail_tbl(i).source_transaction_num          
               ,transfer_license_plate_number = lt_detail_tbl(i).transfer_license_plate_number   
               ,lpn_group_id                  = lt_detail_tbl(i).lpn_group_id                    
               ,order_transaction_id          = lt_detail_tbl(i).order_transaction_id            
               ,customer_account_number       = lt_detail_tbl(i).customer_account_number         
               ,customer_party_name           = lt_detail_tbl(i).customer_party_name             
               ,oe_order_line_num             = lt_detail_tbl(i).oe_order_line_num               
               ,oe_order_num                  = lt_detail_tbl(i).oe_order_num                    
               ,parent_interface_txn_id       = lt_detail_tbl(i).parent_interface_txn_id         
               ,customer_item_id              = lt_detail_tbl(i).customer_item_id                
               ,amount                        = lt_detail_tbl(i).amount                          
               ,job_id                        = lt_detail_tbl(i).job_id                          
               ,timecard_id                   = lt_detail_tbl(i).timecard_id                     
               ,timecard_ovn                  = lt_detail_tbl(i).timecard_ovn                    
               ,erecord_id                    = lt_detail_tbl(i).erecord_id                      
               ,project_id                    = lt_detail_tbl(i).project_id                      
               ,task_id                       = lt_detail_tbl(i).task_id                         
               ,asn_attach_id                 = lt_detail_tbl(i).asn_attach_id                   
               ,org_id                        = lt_detail_tbl(i).org_id                          
               ,operating_unit                = lt_detail_tbl(i).operating_unit                  
               ,requested_amount              = lt_detail_tbl(i).requested_amount                
               ,material_stored_amount        = lt_detail_tbl(i).material_stored_amount          
               ,amount_shipped                = lt_detail_tbl(i).amount_shipped                  
               ,matching_basis                = lt_detail_tbl(i).matching_basis                  
               ,replenish_order_line_id       = lt_detail_tbl(i).replenish_order_line_id         
               ,od_rcv_status_flag            = lt_detail_tbl(i).od_rcv_status_flag              
               ,od_rcv_error_description      = lt_detail_tbl(i).od_rcv_error_description        
            WHERE   interface_transaction_id  = lt_detail_tbl(i).interface_transaction_id
            ;
         fnd_file.put_line(fnd_file.log,'lt_detail_tbl(i).interface_transaction_id '||lt_detail_tbl(i).interface_transaction_id);

         END LOOP;
       
       END IF; -- IF lt_detail_tbl.COUNT > 0 THEN

      END IF;

   END LOOP;
  
  COMMIT;
   
EXCEPTION
   WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Procedure PO_RCV_REPROCESS: '||SQLERRM);
     x_errbuf    := SQLERRM ;
     x_retcode   := 2       ;
   
END PO_RCV_REPROCESS;

-- +===================================================================+
-- | Name             : XFR_RCV_REPROCESS                              |
-- | Description      :                                                |
-- | Parameters       :                                                |
-- | Returns :                x_errbuf                                 |
-- |                          x_retcode                                |
-- +===================================================================+

PROCEDURE XFR_RCV_REPROCESS(x_errbuf    OUT NOCOPY VARCHAR2
                           ,x_retcode   OUT NOCOPY NUMBER
                           )
IS
   lr_header_rec     xx_gi_rcv_xfr_hdr%ROWTYPE ;
   lt_detail_tbl     detail_tbl_type;
   lc_return_status  VARCHAR2(1)    := NULL;
   lc_return_message VARCHAR2(1000) := NULL;
   indx              NUMBER         := NULL;
   ---------------------------------------------------
   --Cursor to Select header records for re-validation
   ---------------------------------------------------
   CURSOR lcu_header_recds
   IS
   SELECT * 
   FROM  xx_gi_rcv_xfr_hdr XGRXH
   WHERE XGRXH.od_rcv_status_flag IN ('VE','PRCP')
   ;
   -------------------------------------------------
   --Cursor to Select line records for re-validation
   -------------------------------------------------
   CURSOR lcu_line_recds(p_header_interface_id IN NUMBER)
   IS
   SELECT * 
   FROM  xx_gi_rcv_xfr_dtl XGRXD
   WHERE XGRXD.od_rcv_status_flag IN ('VE','PRCP')
   AND   XGRXD.header_interface_id = p_header_interface_id
   ;

BEGIN
   
   FOR i IN lcu_header_recds
   LOOP
      lr_header_rec := NULL;
      -----------------------------------------
      -- Populate header records for validation
      -----------------------------------------

      lr_header_rec := i;
      -------------------------------------
      --Initialize the index and line table
      -------------------------------------
      indx          := 0;
      lt_detail_tbl.DELETE;
      ---------------------------------------
      -- Populate line records for validation
      ---------------------------------------
      FOR j IN lcu_line_recds(i.header_interface_id)
      LOOP
         lt_detail_tbl(indx) := j;
         indx                := indx + 1;              
      END LOOP;
      fnd_file.put_line(fnd_file.log,'Header interface id: '|| i.header_interface_id);
      fnd_file.put_line(fnd_file.log,'DETAIL COUNT: '||lt_detail_tbl.COUNT);
      
      VALIDATE_STG_XFR_RCV_DATA
                        (x_header_rec     => lr_header_rec
                        ,x_detail_tbl     => lt_detail_tbl
                        ,x_return_status  => lc_return_status
                        ,x_return_message => lc_return_message
                        );
      fnd_file.put_line(fnd_file.log,'Line Count: '||lt_detail_tbl.COUNT);      
                        
      IF NVL(lc_return_status,'S') <> 'U' THEN
         -----------------------------------------
         -- Update re-validated header information 
         -----------------------------------------
         UPDATE xx_gi_rcv_xfr_hdr
         SET  last_update_date          = SYSDATE        
             ,last_updated_by           = FND_GLOBAL.user_id
             ,last_update_login         = FND_GLOBAL.login_id
             ,notice_creation_date      = lr_header_rec.notice_creation_date    
             ,shipment_num              = lr_header_rec.attribute5            
             ,receipt_num               = lr_header_rec.receipt_num             
             ,receipt_header_id         = lr_header_rec.receipt_header_id       
             ,vendor_name               = lr_header_rec.vendor_name             
             ,vendor_num                = lr_header_rec.vendor_num              
             ,vendor_id                 = lr_header_rec.vendor_id               
             ,vendor_site_code          = lr_header_rec.vendor_site_code        
             ,vendor_site_id            = lr_header_rec.vendor_site_id          
             ,from_organization_code    = lr_header_rec.from_organization_code  
             ,from_organization_id      = lr_header_rec.from_organization_id    
             ,ship_to_organization_code = lr_header_rec.ship_to_organization_code
             ,ship_to_organization_id   = lr_header_rec.ship_to_organization_id 
             ,location_code             = lr_header_rec.location_code           
             ,location_id               = lr_header_rec.location_id             
             ,bill_of_lading            = lr_header_rec.bill_of_lading          
             ,packing_slip              = lr_header_rec.packing_slip            
             ,shipped_date              = lr_header_rec.shipped_date            
             ,freight_carrier_code      = lr_header_rec.freight_carrier_code    
             ,expected_receipt_date     = lr_header_rec.expected_receipt_date   
             ,receiver_id               = lr_header_rec.receiver_id             
             ,num_of_containers         = lr_header_rec.num_of_containers       
             ,waybill_airbill_num       = lr_header_rec.waybill_airbill_num     
             ,comments                  = lr_header_rec.comments                
             ,gross_weight              = lr_header_rec.gross_weight            
             ,gross_weight_uom_code     = lr_header_rec.gross_weight_uom_code   
             ,net_weight                = lr_header_rec.net_weight              
             ,net_weight_uom_code       = lr_header_rec.net_weight_uom_code     
             ,tar_weight                = lr_header_rec.tar_weight              
             ,tar_weight_uom_code       = lr_header_rec.tar_weight_uom_code     
             ,packaging_code            = lr_header_rec.packaging_code          
             ,carrier_method            = lr_header_rec.carrier_method          
             ,carrier_equipment         = lr_header_rec.carrier_equipment       
             ,special_handling_code     = lr_header_rec.special_handling_code   
             ,hazard_code               = lr_header_rec.hazard_code             
             ,hazard_class              = lr_header_rec.hazard_class            
             ,hazard_description        = lr_header_rec.hazard_description      
             ,freight_terms             = lr_header_rec.freight_terms           
             ,freight_bill_number       = lr_header_rec.freight_bill_number     
             ,invoice_num               = lr_header_rec.invoice_num             
             ,invoice_date              = lr_header_rec.invoice_date            
             ,total_invoice_amount      = lr_header_rec.total_invoice_amount    
             ,tax_name                  = lr_header_rec.tax_name                
             ,tax_amount                = lr_header_rec.tax_amount              
             ,freight_amount            = lr_header_rec.freight_amount          
             ,currency_code             = lr_header_rec.currency_code           
             ,conversion_rate_type      = lr_header_rec.conversion_rate_type    
             ,conversion_rate           = lr_header_rec.conversion_rate         
             ,conversion_rate_date      = lr_header_rec.conversion_rate_date    
             ,payment_terms_name        = lr_header_rec.payment_terms_name      
             ,payment_terms_id          = lr_header_rec.payment_terms_id        
             ,attribute_category        = lr_header_rec.attribute_category      
             ,attribute1                = lr_header_rec.attribute1              
             ,attribute2                = lr_header_rec.attribute2              
             ,attribute3                = lr_header_rec.attribute3              
             ,attribute4                = lr_header_rec.attribute4              
             ,attribute5                = lr_header_rec.attribute5              
             ,attribute6                = lr_header_rec.attribute6              
             ,attribute7                = lr_header_rec.attribute7              
             ,attribute8                = lr_header_rec.attribute8              
             ,attribute9                = lr_header_rec.attribute9              
             ,attribute10               = lr_header_rec.attribute10             
             ,attribute11               = lr_header_rec.attribute11             
             ,attribute12               = lr_header_rec.attribute12             
             ,attribute13               = lr_header_rec.attribute13             
             ,attribute14               = lr_header_rec.attribute14             
             ,attribute15               = lr_header_rec.attribute15             
             ,usggl_transaction_code    = lr_header_rec.usggl_transaction_code  
             ,employee_name             = lr_header_rec.employee_name           
             ,employee_id               = lr_header_rec.employee_id             
             ,invoice_status_code       = lr_header_rec.invoice_status_code     
             ,validation_flag           = lr_header_rec.validation_flag         
             ,processing_request_id     = lr_header_rec.processing_request_id   
             ,customer_account_number   = lr_header_rec.customer_account_number 
             ,customer_id               = lr_header_rec.customer_id             
             ,customer_site_id          = lr_header_rec.customer_site_id        
             ,customer_party_name       = lr_header_rec.customer_party_name     
             ,remit_to_site_id          = lr_header_rec.remit_to_site_id        
             ,transaction_date          = lr_header_rec.transaction_date        
             ,org_id                    = lr_header_rec.org_id                  
             ,operating_unit            = lr_header_rec.operating_unit          
             ,ship_from_location_id     = lr_header_rec.ship_from_location_id   
             ,performance_period_from   = lr_header_rec.performance_period_from 
             ,performance_period_to     = lr_header_rec.performance_period_to   
             ,request_date              = lr_header_rec.request_date            
             ,ship_from_location_code   = lr_header_rec.ship_from_location_code 
             ,od_rcv_status_flag        = lr_header_rec.od_rcv_status_flag      
         WHERE header_interface_id      = lr_header_rec.header_interface_id
         ;
         fnd_file.put_line(fnd_file.log,'lr_header_rec.header_interface_id: '||lr_header_rec.header_interface_id);
         IF lt_detail_tbl.COUNT > 0 THEN
           FOR i IN lt_detail_tbl.FIRST..lt_detail_tbl.LAST
           LOOP
            ---------------------------------------------------
            -- Update the re-validate transfer line information
            ---------------------------------------------------
            UPDATE xx_gi_rcv_xfr_dtl
            SET last_update_date              = SYSDATE
               ,last_updated_by               = FND_GLOBAL.user_id
               ,last_update_login             = FND_GLOBAL.login_id
               ,program_update_date           = lt_detail_tbl(i).program_update_date             
               ,transaction_date              = lt_detail_tbl(i).transaction_date                
               ,transaction_status_code       = lt_detail_tbl(i).transaction_status_code         
               ,category_id                   = lt_detail_tbl(i).category_id                     
               ,quantity                      = lt_detail_tbl(i).quantity                        
               ,unit_of_measure               = lt_detail_tbl(i).unit_of_measure                 
               ,interface_source_code         = lt_detail_tbl(i).interface_source_code           
               ,interface_source_line_id      = lt_detail_tbl(i).interface_source_line_id        
               ,inv_transaction_id            = lt_detail_tbl(i).inv_transaction_id              
               ,item_id                       = lt_detail_tbl(i).item_id                         
               ,item_description              = lt_detail_tbl(i).item_description                
               ,item_revision                 = lt_detail_tbl(i).item_revision                   
               ,uom_code                      = lt_detail_tbl(i).uom_code                        
               ,employee_id                   = lt_detail_tbl(i).employee_id                     
               ,auto_transact_code            = lt_detail_tbl(i).auto_transact_code              
               ,shipment_header_id            = lt_detail_tbl(i).shipment_header_id              
               ,shipment_line_id              = lt_detail_tbl(i).shipment_line_id                
               ,ship_to_location_id           = lt_detail_tbl(i).ship_to_location_id             
               ,primary_quantity              = lt_detail_tbl(i).primary_quantity                
               ,primary_unit_of_measure       = lt_detail_tbl(i).primary_unit_of_measure         
               ,receipt_source_code           = lt_detail_tbl(i).receipt_source_code             
               ,vendor_id                     = lt_detail_tbl(i).vendor_id                       
               ,vendor_site_id                = lt_detail_tbl(i).vendor_site_id                  
               ,from_organization_id          = lt_detail_tbl(i).from_organization_id            
               ,from_subinventory             = lt_detail_tbl(i).from_subinventory               
               ,to_organization_id            = lt_detail_tbl(i).to_organization_id              
               ,intransit_owning_org_id       = lt_detail_tbl(i).intransit_owning_org_id         
               ,routing_header_id             = lt_detail_tbl(i).routing_header_id               
               ,routing_step_id               = lt_detail_tbl(i).routing_step_id                 
               ,source_document_code          = lt_detail_tbl(i).source_document_code            
               ,parent_transaction_id         = lt_detail_tbl(i).parent_transaction_id           
               ,po_header_id                  = lt_detail_tbl(i).po_header_id                    
               ,po_revision_num               = lt_detail_tbl(i).po_revision_num                 
               ,po_release_id                 = lt_detail_tbl(i).po_release_id                   
               ,po_line_id                    = lt_detail_tbl(i).po_line_id                      
               ,po_line_location_id           = lt_detail_tbl(i).po_line_location_id             
               ,po_unit_price                 = lt_detail_tbl(i).po_unit_price                   
               ,currency_code                 = lt_detail_tbl(i).currency_code                   
               ,currency_conversion_type      = lt_detail_tbl(i).currency_conversion_type        
               ,currency_conversion_rate      = lt_detail_tbl(i).currency_conversion_rate        
               ,currency_conversion_date      = lt_detail_tbl(i).currency_conversion_date        
               ,po_distribution_id            = lt_detail_tbl(i).po_distribution_id              
               ,requisition_line_id           = lt_detail_tbl(i).requisition_line_id             
               ,req_distribution_id           = lt_detail_tbl(i).req_distribution_id             
               ,charge_account_id             = lt_detail_tbl(i).charge_account_id               
               ,substitute_unordered_code     = lt_detail_tbl(i).substitute_unordered_code       
               ,receipt_exception_flag        = lt_detail_tbl(i).receipt_exception_flag          
               ,accrual_status_code           = lt_detail_tbl(i).accrual_status_code             
               ,inspection_status_code        = lt_detail_tbl(i).inspection_status_code          
               ,inspection_quality_code       = lt_detail_tbl(i).inspection_quality_code         
               ,destination_type_code         = lt_detail_tbl(i).destination_type_code           
               ,deliver_to_person_id          = lt_detail_tbl(i).deliver_to_person_id            
               ,location_id                   = lt_detail_tbl(i).location_id                     
               ,deliver_to_location_id        = lt_detail_tbl(i).deliver_to_location_id          
               ,subinventory                  = lt_detail_tbl(i).subinventory                    
               ,locator_id                    = lt_detail_tbl(i).locator_id                      
               ,wip_entity_id                 = lt_detail_tbl(i).wip_entity_id                   
               ,wip_line_id                   = lt_detail_tbl(i).wip_line_id                     
               ,department_code               = lt_detail_tbl(i).department_code                 
               ,wip_repetitive_schedule_id    = lt_detail_tbl(i).wip_repetitive_schedule_id      
               ,wip_operation_seq_num         = lt_detail_tbl(i).wip_operation_seq_num           
               ,wip_resource_seq_num          = lt_detail_tbl(i).wip_resource_seq_num            
               ,bom_resource_id               = lt_detail_tbl(i).bom_resource_id                 
               ,shipment_num                  = lt_detail_tbl(i).attribute5                   
               ,freight_carrier_code          = lt_detail_tbl(i).freight_carrier_code            
               ,bill_of_lading                = lt_detail_tbl(i).bill_of_lading                  
               ,packing_slip                  = lt_detail_tbl(i).packing_slip                    
               ,shipped_date                  = lt_detail_tbl(i).shipped_date                    
               ,expected_receipt_date         = lt_detail_tbl(i).expected_receipt_date           
               ,actual_cost                   = lt_detail_tbl(i).actual_cost                     
               ,transfer_cost                 = lt_detail_tbl(i).transfer_cost                   
               ,transportation_cost           = lt_detail_tbl(i).transportation_cost             
               ,transportation_account_id     = lt_detail_tbl(i).transportation_account_id       
               ,num_of_containers             = lt_detail_tbl(i).num_of_containers               
               ,waybill_airbill_num           = lt_detail_tbl(i).waybill_airbill_num             
               ,vendor_item_num               = lt_detail_tbl(i).vendor_item_num                 
               ,vendor_lot_num                = lt_detail_tbl(i).vendor_lot_num                  
               ,rma_reference                 = lt_detail_tbl(i).rma_reference                   
               ,comments                      = lt_detail_tbl(i).comments                        
               ,attribute_category            = lt_detail_tbl(i).attribute_category              
               ,attribute1                    = lt_detail_tbl(i).attribute1                      
               ,attribute2                    = lt_detail_tbl(i).attribute2                      
               ,attribute3                    = lt_detail_tbl(i).attribute3                      
               ,attribute4                    = lt_detail_tbl(i).attribute4                      
               ,attribute5                    = lt_detail_tbl(i).attribute5                      
               ,attribute6                    = lt_detail_tbl(i).attribute6                      
               ,attribute7                    = lt_detail_tbl(i).attribute7                      
               ,attribute8                    = lt_detail_tbl(i).attribute8                      
               ,attribute9                    = lt_detail_tbl(i).attribute9                      
               ,attribute10                   = lt_detail_tbl(i).attribute10                     
               ,attribute11                   = lt_detail_tbl(i).attribute11                     
               ,attribute12                   = lt_detail_tbl(i).attribute12                     
               ,attribute13                   = lt_detail_tbl(i).attribute13                     
               ,attribute14                   = lt_detail_tbl(i).attribute14                     
               ,attribute15                   = lt_detail_tbl(i).attribute15                     
               ,ship_head_attribute_category  = lt_detail_tbl(i).ship_head_attribute_category    
               ,ship_head_attribute1          = lt_detail_tbl(i).ship_head_attribute1            
               ,ship_head_attribute2          = lt_detail_tbl(i).ship_head_attribute2            
               ,ship_head_attribute3          = lt_detail_tbl(i).ship_head_attribute3            
               ,ship_head_attribute4          = lt_detail_tbl(i).ship_head_attribute4            
               ,ship_head_attribute5          = lt_detail_tbl(i).ship_head_attribute5            
               ,ship_head_attribute6          = lt_detail_tbl(i).ship_head_attribute6            
               ,ship_head_attribute7          = lt_detail_tbl(i).ship_head_attribute7            
               ,ship_head_attribute8          = lt_detail_tbl(i).ship_head_attribute8            
               ,ship_head_attribute9          = lt_detail_tbl(i).ship_head_attribute9            
               ,ship_head_attribute10         = lt_detail_tbl(i).ship_head_attribute10           
               ,ship_head_attribute11         = lt_detail_tbl(i).ship_head_attribute11           
               ,ship_head_attribute12         = lt_detail_tbl(i).ship_head_attribute12           
               ,ship_head_attribute13         = lt_detail_tbl(i).ship_head_attribute13           
               ,ship_head_attribute14         = lt_detail_tbl(i).ship_head_attribute14           
               ,ship_head_attribute15         = lt_detail_tbl(i).ship_head_attribute15           
               ,ship_line_attribute_category  = lt_detail_tbl(i).attribute_category           
               ,ship_line_attribute1          = lt_detail_tbl(i).attribute1                   
               ,ship_line_attribute2          = lt_detail_tbl(i).attribute2                   
               ,ship_line_attribute3          = lt_detail_tbl(i).attribute3                   
               ,ship_line_attribute4          = lt_detail_tbl(i).attribute4                   
               ,ship_line_attribute5          = lt_detail_tbl(i).attribute5                   
               ,ship_line_attribute6          = lt_detail_tbl(i).attribute6                   
               ,ship_line_attribute7          = lt_detail_tbl(i).attribute7                   
               ,ship_line_attribute8          = lt_detail_tbl(i).attribute8                   
               ,ship_line_attribute9          = lt_detail_tbl(i).attribute9                   
               ,ship_line_attribute10         = lt_detail_tbl(i).attribute10                  
               ,ship_line_attribute11         = lt_detail_tbl(i).attribute11                  
               ,ship_line_attribute12         = lt_detail_tbl(i).attribute12                  
               ,ship_line_attribute13         = lt_detail_tbl(i).attribute13                  
               ,ship_line_attribute14         = lt_detail_tbl(i).attribute14                  
               ,ship_line_attribute15         = lt_detail_tbl(i).attribute15                  
               ,ussgl_transaction_code        = lt_detail_tbl(i).ussgl_transaction_code          
               ,government_context            = lt_detail_tbl(i).government_context              
               ,reason_id                     = lt_detail_tbl(i).reason_id                       
               ,destination_context           = lt_detail_tbl(i).destination_context             
               ,source_doc_quantity           = lt_detail_tbl(i).source_doc_quantity             
               ,source_doc_unit_of_measure    = lt_detail_tbl(i).source_doc_unit_of_measure      
               ,movement_id                   = lt_detail_tbl(i).movement_id                     
               ,header_interface_id           = lt_detail_tbl(i).header_interface_id             
               ,vendor_cum_shipped_qty        = lt_detail_tbl(i).vendor_cum_shipped_qty          
               ,item_num                      = lt_detail_tbl(i).item_num                        
               ,document_num                  = lt_detail_tbl(i).document_num                    
               ,document_line_num             = lt_detail_tbl(i).document_line_num               
               ,truck_num                     = lt_detail_tbl(i).truck_num                       
               ,ship_to_location_code         = lt_detail_tbl(i).ship_to_location_code           
               ,container_num                 = lt_detail_tbl(i).container_num                   
               ,substitute_item_num           = lt_detail_tbl(i).substitute_item_num             
               ,notice_unit_price             = lt_detail_tbl(i).notice_unit_price               
               ,item_category                 = lt_detail_tbl(i).item_category                   
               ,location_code                 = lt_detail_tbl(i).location_code                   
               ,vendor_name                   = lt_detail_tbl(i).vendor_name                     
               ,vendor_num                    = lt_detail_tbl(i).vendor_num                      
               ,vendor_site_code              = lt_detail_tbl(i).vendor_site_code                
               ,from_organization_code        = lt_detail_tbl(i).from_organization_code          
               ,to_organization_code          = lt_detail_tbl(i).to_organization_code            
               ,intransit_owning_org_code     = lt_detail_tbl(i).intransit_owning_org_code       
               ,routing_code                  = lt_detail_tbl(i).routing_code                    
               ,routing_step                  = lt_detail_tbl(i).routing_step                    
               ,release_num                   = lt_detail_tbl(i).release_num                     
               ,document_shipment_line_num    = lt_detail_tbl(i).document_shipment_line_num      
               ,document_distribution_num     = lt_detail_tbl(i).document_distribution_num       
               ,deliver_to_person_name        = lt_detail_tbl(i).deliver_to_person_name          
               ,deliver_to_location_code      = lt_detail_tbl(i).deliver_to_location_code        
               ,use_mtl_lot                   = lt_detail_tbl(i).use_mtl_lot                     
               ,use_mtl_serial                = lt_detail_tbl(i).use_mtl_serial                  
               ,locator                       = lt_detail_tbl(i).locator                         
               ,reason_name                   = lt_detail_tbl(i).reason_name                     
               ,validation_flag               = lt_detail_tbl(i).validation_flag                 
               ,substitute_item_id            = lt_detail_tbl(i).substitute_item_id              
               ,quantity_shipped              = lt_detail_tbl(i).quantity_shipped                
               ,quantity_invoiced             = lt_detail_tbl(i).quantity_invoiced               
               ,tax_name                      = lt_detail_tbl(i).tax_name                        
               ,tax_amount                    = lt_detail_tbl(i).tax_amount                      
               ,req_num                       = lt_detail_tbl(i).req_num                         
               ,req_line_num                  = lt_detail_tbl(i).req_line_num                    
               ,req_distribution_num          = lt_detail_tbl(i).req_distribution_num            
               ,wip_entity_name               = lt_detail_tbl(i).wip_entity_name                 
               ,wip_line_code                 = lt_detail_tbl(i).wip_line_code                   
               ,resource_code                 = lt_detail_tbl(i).resource_code                   
               ,shipment_line_status_code     = lt_detail_tbl(i).shipment_line_status_code       
               ,barcode_label                 = lt_detail_tbl(i).barcode_label                   
               ,transfer_percentage           = lt_detail_tbl(i).transfer_percentage             
               ,qa_collection_id              = lt_detail_tbl(i).qa_collection_id                
               ,country_of_origin_code        = lt_detail_tbl(i).country_of_origin_code          
               ,oe_order_header_id            = lt_detail_tbl(i).oe_order_header_id              
               ,oe_order_line_id              = lt_detail_tbl(i).oe_order_line_id                
               ,customer_id                   = lt_detail_tbl(i).customer_id                     
               ,customer_site_id              = lt_detail_tbl(i).customer_site_id                
               ,customer_item_num             = lt_detail_tbl(i).customer_item_num               
               ,create_debit_memo_flag        = lt_detail_tbl(i).create_debit_memo_flag          
               ,put_away_rule_id              = lt_detail_tbl(i).put_away_rule_id                
               ,put_away_strategy_id          = lt_detail_tbl(i).put_away_strategy_id            
               ,lpn_id                        = lt_detail_tbl(i).lpn_id                          
               ,transfer_lpn_id               = lt_detail_tbl(i).transfer_lpn_id                 
               ,cost_group_id                 = lt_detail_tbl(i).cost_group_id                   
               ,mobile_txn                    = lt_detail_tbl(i).mobile_txn                      
               ,mmtt_temp_id                  = lt_detail_tbl(i).mmtt_temp_id                    
               ,transfer_cost_group_id        = lt_detail_tbl(i).transfer_cost_group_id          
               ,secondary_quantity            = lt_detail_tbl(i).secondary_quantity              
               ,secondary_unit_of_measure     = lt_detail_tbl(i).secondary_unit_of_measure       
               ,secondary_uom_code            = lt_detail_tbl(i).secondary_uom_code              
               ,qc_grade                      = lt_detail_tbl(i).qc_grade                        
               ,from_locator                  = lt_detail_tbl(i).from_locator                    
               ,from_locator_id               = lt_detail_tbl(i).from_locator_id                 
               ,parent_source_transaction_num = lt_detail_tbl(i).parent_source_transaction_num   
               ,interface_available_qty       = lt_detail_tbl(i).interface_available_qty         
               ,interface_transaction_qty     = lt_detail_tbl(i).interface_transaction_qty       
               ,interface_available_amt       = lt_detail_tbl(i).interface_available_amt         
               ,interface_transaction_amt     = lt_detail_tbl(i).interface_transaction_amt       
               ,license_plate_number          = lt_detail_tbl(i).license_plate_number            
               ,source_transaction_num        = lt_detail_tbl(i).source_transaction_num          
               ,transfer_license_plate_number = lt_detail_tbl(i).transfer_license_plate_number   
               ,lpn_group_id                  = lt_detail_tbl(i).lpn_group_id                    
               ,order_transaction_id          = lt_detail_tbl(i).order_transaction_id            
               ,customer_account_number       = lt_detail_tbl(i).customer_account_number         
               ,customer_party_name           = lt_detail_tbl(i).customer_party_name             
               ,oe_order_line_num             = lt_detail_tbl(i).oe_order_line_num               
               ,oe_order_num                  = lt_detail_tbl(i).oe_order_num                    
               ,parent_interface_txn_id       = lt_detail_tbl(i).parent_interface_txn_id         
               ,customer_item_id              = lt_detail_tbl(i).customer_item_id                
               ,amount                        = lt_detail_tbl(i).amount                          
               ,job_id                        = lt_detail_tbl(i).job_id                          
               ,timecard_id                   = lt_detail_tbl(i).timecard_id                     
               ,timecard_ovn                  = lt_detail_tbl(i).timecard_ovn                    
               ,erecord_id                    = lt_detail_tbl(i).erecord_id                      
               ,project_id                    = lt_detail_tbl(i).project_id                      
               ,task_id                       = lt_detail_tbl(i).task_id                         
               ,asn_attach_id                 = lt_detail_tbl(i).asn_attach_id                   
               ,org_id                        = lt_detail_tbl(i).org_id                          
               ,operating_unit                = lt_detail_tbl(i).operating_unit                  
               ,requested_amount              = lt_detail_tbl(i).requested_amount                
               ,material_stored_amount        = lt_detail_tbl(i).material_stored_amount          
               ,amount_shipped                = lt_detail_tbl(i).amount_shipped                  
               ,matching_basis                = lt_detail_tbl(i).matching_basis                  
               ,replenish_order_line_id       = lt_detail_tbl(i).replenish_order_line_id         
               ,od_rcv_status_flag            = lt_detail_tbl(i).od_rcv_status_flag              
               ,od_rcv_error_description      = lt_detail_tbl(i).od_rcv_error_description        
            WHERE   interface_transaction_id  = lt_detail_tbl(i).interface_transaction_id
            ;
           fnd_file.put_line(fnd_file.log,'lt_detail_tbl(i).interface_transaction_id: '||lt_detail_tbl(i).interface_transaction_id);

         END LOOP;
         
        END IF;  -- IF lt_detail_tbl.COUNT > 0 THEN

      END IF;

   END LOOP;
   
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Procedure XFR_RCV_REPROCESS: '||SQLERRM);
     x_errbuf    := SQLERRM ;
     x_retcode   := 2;   
END XFR_RCV_REPROCESS;

-- +===================================================================+
-- | Name             : DELIVER_TO_RCV_ROI_TBLS                        |
-- | Description      : This procedure populates the PO receiving info,|
-- |                    into ROI interface tables as well locks the    |
-- |                    records to PL to avoid any further DML operation|
-- |                    on these records unless processed.             |
-- | Parameters :       p_header_interface_id IN NUMBER                |
-- |                                                                   |
-- | Returns :          x_errbuf              PLS_INTEGER              |
-- |                    x_ret_message         VARCHAR2                 |
-- |                                                                   |
-- +===================================================================+

PROCEDURE CORRECT_PO_RCVING(x_ret_status          OUT PLS_INTEGER
                                 ,x_ret_message         OUT VARCHAR2
                                 )
IS

CURSOR lcu_txn_line (p_shipment_line_id IN NUMBER
                    ,p_adj_qty IN NUMBER
                    )
IS
SELECT RT.transaction_id
      ,RT.quantity
      ,DECODE(SIGN(p_adj_qty),1,RT.quantity,RSL.quantity_received) quantity_received
FROM  rcv_transactions  RT
     ,rcv_shipment_lines RSL
WHERE RSL.shipment_line_id    = p_shipment_line_id
AND   RT.transaction_type     = DECODE(SIGN(p_adj_qty),1,'DELIVER','RECEIVE')
AND   RT.shipment_line_id     = p_shipment_line_id
ORDER BY quantity DESC;

CURSOR lcu_load_line_rec 
IS
SELECT XGRPD.*  , RT.quantity RT_quantity
FROM  xx_gi_rcv_po_dtl XGRPD 
     ,rcv_transactions RT
WHERE XGRPD.od_rcv_status_flag IN ('PL1')
AND   XGRPD.interface_transaction_id  = RT.attribute15 -- i.e the First part of Rcving is done
AND   SUBSTR(NVL(XGRPD.attribute4,'#'),1,4) = G_CORRECTION
ORDER BY XGRPD.quantity DESC ;

ln_user_id             NUMBER := FND_GLOBAL.user_id;
ln_existing_quantity   NUMBER;
ln_rcv_quantity        NUMBER;
ln_curr_quantity       NUMBER;
lc_error_level         VARCHAR2(150);
ln_lcu_txn_line_count  NUMBER := 0;

-- PL/SQL table type declarations
TYPE Line_txn_id_tbl_typ IS TABLE OF RCV_TRANSACTIONS.transaction_id%type 
INDEX BY BINARY_INTEGER;
lt_line_txn_id  line_txn_id_tbl_typ;

TYPE Line_txn_qty_tbl_typ IS TABLE OF RCV_TRANSACTIONS.quantity%type 
INDEX BY BINARY_INTEGER;
lt_line_qty  line_txn_qty_tbl_typ;

TYPE Line_qty_rcvd_tbl_typ IS TABLE OF RCV_SHIPMENT_LINES.quantity_received%type 
INDEX BY BINARY_INTEGER;
lt_line_qty_rcvd  Line_qty_rcvd_tbl_typ;

BEGIN

FOR lcu_dtl_cur IN lcu_load_line_rec
LOOP

     lc_error_level :=  'While fetching data from rcv_shipment_lines,error for line record: '||lcu_dtl_cur.interface_transaction_id;
     -- Fetch Quantity already recieved from RCV_SHIPMENT_LINES
     -- in case of correction.Get rcv transactions details only for Corrections       
     OPEN  lcu_txn_line (lcu_dtl_cur.shipment_line_id , lcu_dtl_cur.RT_quantity);
     FETCH lcu_txn_line BULK COLLECT INTO lt_line_txn_id,lt_line_qty,lt_line_qty_rcvd;
     CLOSE lcu_txn_line;     
     
     lc_error_level :=  'While fetching data from rcv_shipment_lines,error for ship line record: '||lcu_dtl_cur.shipment_line_id;
     FND_FILE.PUT_LINE(FND_FILE.LOG,'The quantity is '||lt_line_txn_id.COUNT||' And the ship quantity '|| lt_line_qty_rcvd(1));
     
     ln_rcv_quantity       := lcu_dtl_cur.RT_quantity;  
     ln_lcu_txn_line_count := lt_line_txn_id.COUNT;
     
     lc_error_level        :=  'While inserting in rcv_lines_interface,error for line record: '||lcu_dtl_cur.interface_transaction_id;

    -- Inserting in the rcv_transactions_interface table.
    -- In case of Corrections i.e OHRE Txns, we need to split the correction quantity
    -- amont different DELIVER transactions.
   FOR ln_loop_indx IN lt_line_txn_id.FIRST..lt_line_txn_id.LAST
   LOOP
     lc_error_level :=  'While calculating for Adjustment for line record: '||lcu_dtl_cur.interface_transaction_id;
     ln_curr_quantity := ln_rcv_quantity ;        
     FND_FILE.PUT_LINE(FND_FILE.LOG,'The shipment line: '|| lt_line_txn_id(ln_loop_indx));
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Qty : ln_curr_quantity : '||ln_curr_quantity ||' ln_rcv_quantity: '||ln_rcv_quantity);
     lc_error_level :=  'Before Inserting into rcv_transactions_interface table';
     INSERT INTO rcv_transactions_interface
     ( INTERFACE_TRANSACTION_ID
      ,HEADER_INTERFACE_ID     
      ,GROUP_ID                
      ,LAST_UPDATE_DATE        
      ,LAST_UPDATED_BY         
      ,CREATION_DATE           
      ,CREATED_BY              
      ,LAST_UPDATE_LOGIN       
      ,TRANSACTION_TYPE        
      ,TRANSACTION_DATE        
      ,PROCESSING_STATUS_CODE  
      ,PROCESSING_MODE_CODE    
      ,TRANSACTION_STATUS_CODE 
      ,QUANTITY                
      ,UNIT_OF_MEASURE         
      ,AUTO_TRANSACT_CODE      
      ,RECEIPT_SOURCE_CODE     
      ,SOURCE_DOCUMENT_CODE    
      ,REQUEST_ID                   
      ,PROGRAM_APPLICATION_ID       
      ,PROGRAM_ID                   
      ,PROGRAM_UPDATE_DATE          
      ,PROCESSING_REQUEST_ID        
      ,CATEGORY_ID                  
      ,INTERFACE_SOURCE_CODE        
      ,INTERFACE_SOURCE_LINE_ID     
      ,INV_TRANSACTION_ID           
      ,ITEM_ID                      
      ,ITEM_DESCRIPTION             
      ,ITEM_REVISION                
      ,UOM_CODE                     
      ,EMPLOYEE_ID                  
      ,SHIPMENT_HEADER_ID           
      ,SHIPMENT_LINE_ID             
      ,SHIP_TO_LOCATION_ID          
      ,PRIMARY_QUANTITY             
      ,PRIMARY_UNIT_OF_MEASURE      
      ,VENDOR_ID                    
      ,VENDOR_SITE_ID               
      ,FROM_ORGANIZATION_ID         
      ,FROM_SUBINVENTORY            
      ,TO_ORGANIZATION_ID           
      ,INTRANSIT_OWNING_ORG_ID      
      ,ROUTING_HEADER_ID            
      ,ROUTING_STEP_ID              
      ,PARENT_TRANSACTION_ID        
      ,PO_HEADER_ID                 
      ,PO_REVISION_NUM              
      ,PO_RELEASE_ID                
      ,PO_LINE_ID                   
      ,PO_LINE_LOCATION_ID          
      ,PO_UNIT_PRICE                
      ,CURRENCY_CODE                
      ,CURRENCY_CONVERSION_TYPE     
      ,CURRENCY_CONVERSION_RATE     
      ,CURRENCY_CONVERSION_DATE     
      ,PO_DISTRIBUTION_ID           
      ,REQUISITION_LINE_ID          
      ,REQ_DISTRIBUTION_ID          
      ,CHARGE_ACCOUNT_ID            
      ,SUBSTITUTE_UNORDERED_CODE    
      ,RECEIPT_EXCEPTION_FLAG       
      ,ACCRUAL_STATUS_CODE          
      ,INSPECTION_STATUS_CODE       
      ,INSPECTION_QUALITY_CODE      
      ,DESTINATION_TYPE_CODE        
      ,DELIVER_TO_PERSON_ID         
      ,LOCATION_ID                  
      ,DELIVER_TO_LOCATION_ID       
      ,SUBINVENTORY                 
      ,LOCATOR_ID                   
      ,WIP_ENTITY_ID                
      ,WIP_LINE_ID                  
      ,DEPARTMENT_CODE              
      ,WIP_REPETITIVE_SCHEDULE_ID   
      ,WIP_OPERATION_SEQ_NUM        
      ,WIP_RESOURCE_SEQ_NUM         
      ,BOM_RESOURCE_ID              
      ,SHIPMENT_NUM                 
      ,FREIGHT_CARRIER_CODE         
      ,BILL_OF_LADING               
      ,PACKING_SLIP                 
      ,SHIPPED_DATE                 
      ,EXPECTED_RECEIPT_DATE        
      ,ACTUAL_COST                  
      ,TRANSFER_COST                
      ,TRANSPORTATION_COST          
      ,TRANSPORTATION_ACCOUNT_ID    
      ,NUM_OF_CONTAINERS            
      ,WAYBILL_AIRBILL_NUM          
      ,VENDOR_ITEM_NUM              
      ,VENDOR_LOT_NUM               
      ,RMA_REFERENCE                
      ,COMMENTS                     
      ,ATTRIBUTE_CATEGORY           
      ,ATTRIBUTE1                   
      ,ATTRIBUTE2                   
      ,ATTRIBUTE3                   
      ,ATTRIBUTE4                   
      ,ATTRIBUTE5                   
      ,ATTRIBUTE6                   
      ,ATTRIBUTE7                   
      ,ATTRIBUTE8                   
      ,ATTRIBUTE9                   
      ,ATTRIBUTE10                  
      ,ATTRIBUTE11                  
      ,ATTRIBUTE12                  
      ,ATTRIBUTE13                  
      ,ATTRIBUTE14                  
      ,ATTRIBUTE15                  
      ,SHIP_HEAD_ATTRIBUTE_CATEGORY 
      ,SHIP_HEAD_ATTRIBUTE1         
      ,SHIP_HEAD_ATTRIBUTE2         
      ,SHIP_HEAD_ATTRIBUTE3         
      ,SHIP_HEAD_ATTRIBUTE4         
      ,SHIP_HEAD_ATTRIBUTE5         
      ,SHIP_HEAD_ATTRIBUTE6         
      ,SHIP_HEAD_ATTRIBUTE7         
      ,SHIP_HEAD_ATTRIBUTE8         
      ,SHIP_HEAD_ATTRIBUTE9         
      ,SHIP_HEAD_ATTRIBUTE10        
      ,SHIP_HEAD_ATTRIBUTE11        
      ,SHIP_HEAD_ATTRIBUTE12        
      ,SHIP_HEAD_ATTRIBUTE13        
      ,SHIP_HEAD_ATTRIBUTE14        
      ,SHIP_HEAD_ATTRIBUTE15        
      ,SHIP_LINE_ATTRIBUTE_CATEGORY 
      ,SHIP_LINE_ATTRIBUTE1         
      ,SHIP_LINE_ATTRIBUTE2         
      ,SHIP_LINE_ATTRIBUTE3         
      ,SHIP_LINE_ATTRIBUTE4         
      ,SHIP_LINE_ATTRIBUTE5         
      ,SHIP_LINE_ATTRIBUTE6         
      ,SHIP_LINE_ATTRIBUTE7         
      ,SHIP_LINE_ATTRIBUTE8         
      ,SHIP_LINE_ATTRIBUTE9         
      ,SHIP_LINE_ATTRIBUTE10        
      ,SHIP_LINE_ATTRIBUTE11        
      ,SHIP_LINE_ATTRIBUTE12        
      ,SHIP_LINE_ATTRIBUTE13        
      ,SHIP_LINE_ATTRIBUTE14        
      ,SHIP_LINE_ATTRIBUTE15        
      ,USSGL_TRANSACTION_CODE       
      ,GOVERNMENT_CONTEXT           
      ,REASON_ID                    
      ,DESTINATION_CONTEXT          
      ,SOURCE_DOC_QUANTITY          
      ,SOURCE_DOC_UNIT_OF_MEASURE   
      ,MOVEMENT_ID                  
      ,USE_MTL_LOT                  
      ,USE_MTL_SERIAL               
      ,VENDOR_CUM_SHIPPED_QTY       
      ,ITEM_NUM                     
      ,DOCUMENT_NUM                 
      ,DOCUMENT_LINE_NUM            
      ,TRUCK_NUM                    
      ,SHIP_TO_LOCATION_CODE        
      ,CONTAINER_NUM                
      ,SUBSTITUTE_ITEM_NUM          
      ,NOTICE_UNIT_PRICE            
      ,ITEM_CATEGORY                
      ,LOCATION_CODE                
      ,VENDOR_NAME                  
      ,VENDOR_NUM                   
      ,VENDOR_SITE_CODE             
      ,INTRANSIT_OWNING_ORG_CODE    
      ,ROUTING_CODE                 
      ,ROUTING_STEP                 
      ,RELEASE_NUM                  
      ,DOCUMENT_SHIPMENT_LINE_NUM   
      ,DOCUMENT_DISTRIBUTION_NUM    
      ,DELIVER_TO_PERSON_NAME       
      ,DELIVER_TO_LOCATION_CODE     
      ,LOCATOR                      
      ,REASON_NAME                  
      ,VALIDATION_FLAG              
      ,SUBSTITUTE_ITEM_ID           
      ,QUANTITY_SHIPPED             
      ,QUANTITY_INVOICED            
      ,TAX_NAME                     
      ,TAX_AMOUNT                   
      ,REQ_NUM                      
      ,REQ_LINE_NUM                 
      ,REQ_DISTRIBUTION_NUM         
      ,WIP_ENTITY_NAME              
      ,WIP_LINE_CODE                
      ,RESOURCE_CODE                
      ,SHIPMENT_LINE_STATUS_CODE    
      ,BARCODE_LABEL                
      ,TRANSFER_PERCENTAGE          
      ,QA_COLLECTION_ID             
      ,COUNTRY_OF_ORIGIN_CODE       
      ,OE_ORDER_HEADER_ID           
      ,OE_ORDER_LINE_ID             
      ,CUSTOMER_ID                  
      ,CUSTOMER_SITE_ID             
      ,CUSTOMER_ITEM_NUM            
      ,CREATE_DEBIT_MEMO_FLAG       
      ,PUT_AWAY_RULE_ID             
      ,PUT_AWAY_STRATEGY_ID         
      ,LPN_ID                       
      ,TRANSFER_LPN_ID              
      ,COST_GROUP_ID                
      ,MOBILE_TXN                   
      ,MMTT_TEMP_ID                 
      ,TRANSFER_COST_GROUP_ID       
      ,SECONDARY_QUANTITY           
      ,SECONDARY_UNIT_OF_MEASURE    
      ,SECONDARY_UOM_CODE           
      ,QC_GRADE                     
      ,FROM_LOCATOR                 
      ,FROM_LOCATOR_ID              
      ,PARENT_SOURCE_TRANSACTION_NUM
      ,INTERFACE_AVAILABLE_QTY      
      ,INTERFACE_TRANSACTION_QTY    
      ,INTERFACE_AVAILABLE_AMT      
      ,INTERFACE_TRANSACTION_AMT    
      ,LICENSE_PLATE_NUMBER         
      ,SOURCE_TRANSACTION_NUM       
      ,TRANSFER_LICENSE_PLATE_NUMBER
      ,LPN_GROUP_ID                 
      ,ORDER_TRANSACTION_ID         
      ,CUSTOMER_ACCOUNT_NUMBER      
      ,CUSTOMER_PARTY_NAME          
      ,OE_ORDER_LINE_NUM            
      ,OE_ORDER_NUM                 
      ,PARENT_INTERFACE_TXN_ID      
      ,CUSTOMER_ITEM_ID             
      ,AMOUNT                       
      ,JOB_ID                       
      ,TIMECARD_ID                  
      ,TIMECARD_OVN                 
      ,ERECORD_ID                   
      ,PROJECT_ID                   
      ,TASK_ID                      
      ,ASN_ATTACH_ID 
      )
     SELECT
        rcv_transactions_interface_s.nextval
       ,DECODE(shipment_header_id,NULL,header_interface_id,NULL)
       ,group_id
       ,SYSDATE
       ,ln_user_id
       ,SYSDATE
       ,ln_user_id
       ,ln_user_id
       ,transaction_type
       ,transaction_date
       ,'PENDING'
       ,'BATCH'
       ,'PENDING'
       , DECODE(transaction_type,G_CORRECT,ln_curr_quantity,ln_rcv_quantity)   -- quantity   
       , unit_of_measure
       , DECODE(transaction_type,G_CORRECT,NULL,G_DELIVER)
       ,'VENDOR'
       ,'PO'
       , request_id
       , program_application_id
       , program_id
       , program_update_date
       , processing_request_id
       , category_id
       , interface_source_code
       , interface_source_line_id
       , inv_transaction_id
       , item_id
       , item_description
       , item_revision
       , uom_code
       , G_EMPLOYEE_ID
       , shipment_header_id
       , shipment_line_id
       , DECODE(transaction_type,G_CORRECT,NULL,ship_to_location_id)
       , DECODE(transaction_type,G_CORRECT,ln_curr_quantity,primary_quantity)
       , unit_of_measure    --  primary_unit_of_measure
       , vendor_id
       , vendor_site_id
       , DECODE(transaction_type,G_CORRECT,to_organization_id, from_organization_id) ----from_organization_id
       , DECODE(transaction_type,G_CORRECT,subinventory,NULL)  -- From_Subinventory
       , to_organization_id
       , intransit_owning_org_id
       , 3  --routing_header_id
       , 1  --routing_step_id
       , DECODE(transaction_type,G_CORRECT,lt_line_txn_id(ln_loop_indx),parent_transaction_id) -- parent_transaction_id                       
       , po_header_id
       , po_revision_num
       , po_release_id
       , po_line_id
       , po_line_location_id
       , po_unit_price
       , currency_code
       , currency_conversion_type
       , currency_conversion_rate
       , currency_conversion_date
       , po_distribution_id
       , requisition_line_id
       , req_distribution_id
       , charge_account_id
       , substitute_unordered_code
       , receipt_exception_flag
       , accrual_status_code
       , inspection_status_code
       , inspection_quality_code
       , DECODE(SIGN(ln_curr_quantity),-1,'RECEIVING','INVENTORY')  --DESTINATION_TYPE_CODE
       , deliver_to_person_id
       , NULL-- DECODE(shipment_header_id,NULL,ship_to_location_id,NULL)
       , deliver_to_location_id
       , DECODE(SIGN(ln_curr_quantity),-1,NULL,subinventory)
       , locator_id
       , wip_entity_id
       , wip_line_id
       , department_code
       , wip_repetitive_schedule_id
       , wip_operation_seq_num
       , wip_resource_seq_num
       , bom_resource_id
       , shipment_num
       , freight_carrier_code
       , bill_of_lading
       , packing_slip
       , shipped_date
       , DECODE(transaction_type,G_CORRECT,NULL,expected_receipt_date)
       , actual_cost
       , transfer_cost
       , transportation_cost
       , transportation_account_id
       , num_of_containers
       , waybill_airbill_num
       , vendor_item_num
       , vendor_lot_num
       , rma_reference
       , comments
       , attribute_category
       , attribute1
       , attribute2
       , attribute3
       , attribute4
       , attribute5
       , attribute6
       , attribute7
       , attribute8
       , attribute9
       , attribute10
       , attribute11
       , attribute12
       , attribute13
       , attribute14
       , interface_transaction_id                 -- attribute15
       , ship_head_attribute_category
       , ship_head_attribute1
       , ship_head_attribute2
       , ship_head_attribute3
       , ship_head_attribute4
       , ship_head_attribute5
       , ship_head_attribute6
       , ship_head_attribute7
       , ship_head_attribute8
       , ship_head_attribute9
       , ship_head_attribute10
       , ship_head_attribute11
       , ship_head_attribute12
       , ship_head_attribute13
       , ship_head_attribute14
       , ship_head_attribute15
       , attribute_category  --     ship_line_attribute_category                
       , attribute1          --     ship_line_attribute1 
       , attribute2          --     ship_line_attribute2 
       , attribute3          --     ship_line_attribute3 
       , attribute4          --     ship_line_attribute4 
       , attribute5          --     ship_line_attribute5 
       , attribute6          --     ship_line_attribute6 
       , attribute7          --     ship_line_attribute7 
       , attribute8          --     ship_line_attribute8 
       , attribute9          --     ship_line_attribute9 
       , attribute10         --     ship_line_attribute10
       , attribute11         --     ship_line_attribute11
       , attribute12         --     ship_line_attribute12
       , attribute13         --     ship_line_attribute13
       , attribute14         --     ship_line_attribute14
       , attribute15         --     ship_line_attribute15            
       , ussgl_transaction_code
       , government_context
       , reason_id
       , DECODE(SIGN(ln_curr_quantity),1,NULL,'RECEIVING') -- destination_context
       , source_doc_quantity
       , source_doc_unit_of_measure
       , movement_id
       , 1--use_mtl_lot
       , 1--use_mtl_serial
       , vendor_cum_shipped_qty
       , item_num
       , document_num
       , DECODE(shipment_line_id,NULL,document_line_num,NULL) 
       , truck_num
       , ship_to_location_code
       , container_num
       , substitute_item_num
       , notice_unit_price
       , item_category
       , location_code
       , vendor_name
       , vendor_num
       , vendor_site_code
       , intransit_owning_org_code
       , routing_code
       , routing_step
       , release_num
       , DECODE(shipment_header_id,NULL,document_shipment_line_num,NULL)  
       , document_distribution_num
       , deliver_to_person_name
       , deliver_to_location_code
       , locator
       , reason_name
       , DECODE(shipment_header_id,NULL,'Y') 
       , substitute_item_id
       , quantity_shipped
       , quantity_invoiced
       , tax_name
       , tax_amount
       , req_num
       , req_line_num
       , req_distribution_num
       , wip_entity_name
       , wip_line_code
       , resource_code
       , shipment_line_status_code
       , barcode_label
       , transfer_percentage
       , qa_collection_id
       , country_of_origin_code
       , oe_order_header_id
       , oe_order_line_id
       , customer_id
       , customer_site_id
       , customer_item_num
       , create_debit_memo_flag
       , put_away_rule_id
       , put_away_strategy_id
       , lpn_id
       , transfer_lpn_id
       , cost_group_id
       , mobile_txn
       , mmtt_temp_id
       , transfer_cost_group_id
       , secondary_quantity
       , secondary_unit_of_measure
       , secondary_uom_code
       , qc_grade
       , from_locator
       , from_locator_id
       , parent_source_transaction_num
       , interface_available_qty
       , interface_transaction_qty
       , interface_available_amt
       , interface_transaction_amt
       , license_plate_number
       , source_transaction_num
       , transfer_license_plate_number
       , lpn_group_id
       , order_transaction_id
       , customer_account_number
       , customer_party_name
       , oe_order_line_num
       , oe_order_num
       , parent_interface_txn_id
       , customer_item_id
       , amount
       , job_id
       , timecard_id
       , timecard_ovn
       , erecord_id
       , project_id
       , task_id
       , asn_attach_id
   FROM  xx_gi_rcv_po_dtl
   WHERE interface_transaction_id = lcu_dtl_cur.interface_transaction_id;

  lc_error_level:= 'After insert into table at line for Interface Transaction Id: ' ||lcu_dtl_cur.interface_transaction_id;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'After insert into table at line for Interface Transaction Id: ' ||lcu_dtl_cur.interface_transaction_id);
  --- Update line status to PL
   UPDATE xx_gi_rcv_po_dtl
   SET    od_rcv_status_flag = 'PL'
   WHERE  interface_transaction_id = lcu_dtl_cur.interface_transaction_id;
   
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Update table at line for Transaction Id: ' ||lcu_dtl_cur.interface_transaction_id);
 
  -- Update header status of the records successfilly passed onto
  -- Interface table for processing.
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Update table at header: '||lcu_dtl_cur.header_interface_id);
   UPDATE xx_gi_rcv_po_hdr
   SET    od_rcv_status_flag = 'PL'
   WHERE  header_interface_id = lcu_dtl_cur.header_interface_id;
   
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Update xx_gi_rcv_keyrec table at header for header id: ' || lcu_dtl_cur.header_interface_id);
   lc_error_level := 'While updating keyrec table: '||lcu_dtl_cur.interface_transaction_id;  
   UPDATE xx_gi_rcv_keyrec
   SET    status_cd = 'PL'
   WHERE  keyrec_nbr = lcu_dtl_cur.attribute8
   AND    loc_nbr    = lcu_dtl_cur.attribute5;

   fnd_file.put_line(fnd_file.log,'Curr Quantity: '|| ln_curr_quantity||' and  '|| ln_rcv_quantity);
   
   IF ln_curr_quantity = ln_rcv_quantity THEN
      EXIT;  -- Exit out of the loop
   END IF;
   
   END LOOP;
   
  END LOOP;

 COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      x_ret_status  := 2;
      x_ret_message := lc_error_level;
      x_ret_message :=  SUBSTR(x_ret_message||'. '||SQLERRM,1,450);
      FND_FILE.PUT_LINE(FND_FILE.LOG,x_ret_message);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'oracle error in DELIVER_TO_RCV_ROI_TBLS. '||SQLERRM);   
END CORRECT_PO_RCVING;


-- +===================================================================+
-- | Name             : CORRECT_INTO_XFR_RCVING_TBLS                   |
-- | Description      : This procedure populates the xfr receiving info|
-- |                    into ROI interface tables as well locks the    |
-- |                    records to PL1 to avoid any further DML        |
-- |                    operation on these records unless processed.   |
-- | Parameters :       p_header_interface_id IN NUMBER                |
-- |                                                                   |
-- | Returns :          x_ret_status          PLS_INTEGER              |
-- |                    x_ret_message         VARCHAR2                 |
-- |                                                                   |
-- +===================================================================+

PROCEDURE CORRECT_XFR_RCVING(  x_ret_status          OUT PLS_INTEGER
                              ,x_ret_message         OUT VARCHAR2
                            )
IS

-- CURSOR to fetch Receiving transaction data for corrections

CURSOR lcu_txn_line (p_shipment_line_id IN NUMBER
                    ,p_adj_qty IN NUMBER
                    )
IS
SELECT RT.transaction_id
      ,RT.quantity
      ,DECODE(SIGN(p_adj_qty),1,RT.quantity,RSL.quantity_received) quantity_received
FROM  rcv_transactions  RT
     ,rcv_shipment_lines RSL
WHERE RSL.shipment_line_id    = p_shipment_line_id
AND   RT.transaction_type     = DECODE(SIGN(p_adj_qty),1,'DELIVER','RECEIVE')
AND   RT.shipment_line_id     = p_shipment_line_id
ORDER BY quantity DESC;

CURSOR lcu_load_line_rec
IS
SELECT XGRXD.* , RT.quantity RT_quantity
FROM   xx_gi_rcv_xfr_dtl XGRXD
      ,rcv_transactions RT
WHERE XGRXD.od_rcv_status_flag IN ('PL1')
AND   SUBSTR(NVL(XGRXD.attribute4,'#'),1,4) = G_CORRECTION
AND   XGRXD.interface_transaction_id        = RT.attribute15 -- i.e the IInd part of Rcving is done
ORDER BY XGRXD.quantity DESC ;

ln_user_id             NUMBER := FND_GLOBAL.user_id;
ln_existing_quantity   NUMBER;
ln_rcv_quantity        NUMBER;
ln_curr_quantity       NUMBER;
ln_lcu_txn_line_count  NUMBER := 0;
lc_error_level         VARCHAR2(150);

-- PL/SQL table type declarations
TYPE Line_txn_id_tbl_typ IS TABLE OF RCV_TRANSACTIONS.transaction_id%type 
INDEX BY BINARY_INTEGER;
lt_line_txn_id  line_txn_id_tbl_typ;

TYPE Line_txn_qty_tbl_typ IS TABLE OF RCV_TRANSACTIONS.quantity%type 
INDEX BY BINARY_INTEGER;
lt_line_qty  line_txn_qty_tbl_typ;

TYPE Line_qty_rcvd_tbl_typ IS TABLE OF RCV_SHIPMENT_LINES.quantity_received%type 
INDEX BY BINARY_INTEGER;
lt_line_qty_rcvd  Line_qty_rcvd_tbl_typ;

BEGIN

lc_error_level :=  'Inside the API ';


FOR lcu_dtl_cur IN lcu_load_line_rec
LOOP

     lc_error_level :=  'While fetching data from rcv_shipment_lines for Correction,error for line record: '||lcu_dtl_cur.interface_transaction_id;

     -- Get rcv transactions details only for Corrections
     OPEN  lcu_txn_line (lcu_dtl_cur.shipment_line_id, lcu_dtl_cur.RT_quantity);
     FETCH lcu_txn_line BULK COLLECT INTO lt_line_txn_id,lt_line_qty,lt_line_qty_rcvd;
     CLOSE lcu_txn_line;

     FND_FILE.PUT_LINE(FND_FILE.LOG,'The ship line is: '|| lcu_dtl_cur.shipment_line_id);
     ln_rcv_quantity       := lcu_dtl_cur.RT_quantity ;

     FND_FILE.PUT_LINE(FND_FILE.LOG,'The Received quantity '|| lt_line_qty_rcvd(1)|| 'and incoming qty: '||lcu_dtl_cur.RT_quantity);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'The Adjustment quantity '|| ln_rcv_quantity);

  -- This is to make sure that loop executes once definately
     IF lt_line_txn_id.COUNT = 0 THEN
        lt_line_txn_id(0)   := -1;
        lt_line_qty(0)      := 0;
     END IF;

  ln_lcu_txn_line_count := lt_line_txn_id.COUNT;
  lc_error_level :=  'While invoking loop for PL1 type of records';

  -- Inserting in the rcv_transactions_interface table.
  -- In case of Corrections i.e OHRE Txns, we need to split the correction quantity
  -- amont different DELIVER transactions.
  FOR ln_loop_indx IN lt_line_txn_id.FIRST..lt_line_txn_id.LAST
  LOOP
    lc_error_level :=  'While calculating for Adjustment for line record: '||lcu_dtl_cur.interface_transaction_id;

          ln_curr_quantity := ln_rcv_quantity ;

  FND_FILE.PUT_LINE(FND_FILE.LOG,'RT Correct Qty : ln_curr_quantity : '||ln_curr_quantity ||' ln_rcv_quantity: '||ln_rcv_quantity||' and parent transaction Id: '||lt_line_txn_id(ln_loop_indx));
  lc_error_level :=  'Before Inserting into rcv_transactions_interface table';

  INSERT INTO rcv_transactions_interface
     ( INTERFACE_TRANSACTION_ID
      ,HEADER_INTERFACE_ID
      ,GROUP_ID
      ,LAST_UPDATE_DATE
      ,LAST_UPDATED_BY
      ,CREATION_DATE
      ,CREATED_BY
      ,LAST_UPDATE_LOGIN
      ,TRANSACTION_TYPE
      ,TRANSACTION_DATE
      ,PROCESSING_STATUS_CODE
      ,PROCESSING_MODE_CODE
      ,TRANSACTION_STATUS_CODE
      ,QUANTITY
      ,UNIT_OF_MEASURE
      ,AUTO_TRANSACT_CODE
      ,RECEIPT_SOURCE_CODE
      ,SOURCE_DOCUMENT_CODE
      ,REQUEST_ID
      ,PROGRAM_APPLICATION_ID
      ,PROGRAM_ID
      ,PROGRAM_UPDATE_DATE
      ,PROCESSING_REQUEST_ID
      ,CATEGORY_ID
      ,INTERFACE_SOURCE_CODE
      ,INTERFACE_SOURCE_LINE_ID
      ,INV_TRANSACTION_ID
      ,ITEM_ID
      ,ITEM_DESCRIPTION
      ,ITEM_REVISION
      ,UOM_CODE
      ,EMPLOYEE_ID
      ,SHIPMENT_HEADER_ID
      ,SHIPMENT_LINE_ID
      ,SHIP_TO_LOCATION_ID
      ,PRIMARY_QUANTITY
      ,PRIMARY_UNIT_OF_MEASURE
      ,VENDOR_ID
      ,VENDOR_SITE_ID
      ,FROM_ORGANIZATION_ID
      ,FROM_SUBINVENTORY
      ,TO_ORGANIZATION_ID
      ,INTRANSIT_OWNING_ORG_ID
      ,ROUTING_HEADER_ID
      ,ROUTING_STEP_ID
      ,PARENT_TRANSACTION_ID
      ,PO_HEADER_ID
      ,PO_REVISION_NUM
      ,PO_RELEASE_ID
      ,PO_LINE_ID
      ,PO_LINE_LOCATION_ID
      ,PO_UNIT_PRICE
      ,CURRENCY_CODE
      ,CURRENCY_CONVERSION_TYPE
      ,CURRENCY_CONVERSION_RATE
      ,CURRENCY_CONVERSION_DATE
      ,PO_DISTRIBUTION_ID
      ,REQUISITION_LINE_ID
      ,REQ_DISTRIBUTION_ID
      ,CHARGE_ACCOUNT_ID
      ,SUBSTITUTE_UNORDERED_CODE
      ,RECEIPT_EXCEPTION_FLAG
      ,ACCRUAL_STATUS_CODE
      ,INSPECTION_STATUS_CODE
      ,INSPECTION_QUALITY_CODE
      ,DESTINATION_TYPE_CODE
      ,DELIVER_TO_PERSON_ID
      ,LOCATION_ID
      ,DELIVER_TO_LOCATION_ID
      ,SUBINVENTORY
      ,LOCATOR_ID
      ,WIP_ENTITY_ID
      ,WIP_LINE_ID
      ,DEPARTMENT_CODE
      ,WIP_REPETITIVE_SCHEDULE_ID
      ,WIP_OPERATION_SEQ_NUM
      ,WIP_RESOURCE_SEQ_NUM
      ,BOM_RESOURCE_ID
      ,SHIPMENT_NUM
      ,FREIGHT_CARRIER_CODE
      ,BILL_OF_LADING
      ,PACKING_SLIP
      ,SHIPPED_DATE
      ,EXPECTED_RECEIPT_DATE
      ,ACTUAL_COST
      ,TRANSFER_COST
      ,TRANSPORTATION_COST
      ,TRANSPORTATION_ACCOUNT_ID
      ,NUM_OF_CONTAINERS
      ,WAYBILL_AIRBILL_NUM
      ,VENDOR_ITEM_NUM
      ,VENDOR_LOT_NUM
      ,RMA_REFERENCE
      ,COMMENTS
      ,ATTRIBUTE_CATEGORY
      ,ATTRIBUTE1
      ,ATTRIBUTE2
      ,ATTRIBUTE3
      ,ATTRIBUTE4
      ,ATTRIBUTE5
      ,ATTRIBUTE6
      ,ATTRIBUTE7
      ,ATTRIBUTE8
      ,ATTRIBUTE9
      ,ATTRIBUTE10
      ,ATTRIBUTE11
      ,ATTRIBUTE12
      ,ATTRIBUTE13
      ,ATTRIBUTE14
      ,ATTRIBUTE15
      ,SHIP_HEAD_ATTRIBUTE_CATEGORY
      ,SHIP_HEAD_ATTRIBUTE1
      ,SHIP_HEAD_ATTRIBUTE2
      ,SHIP_HEAD_ATTRIBUTE3
      ,SHIP_HEAD_ATTRIBUTE4
      ,SHIP_HEAD_ATTRIBUTE5
      ,SHIP_HEAD_ATTRIBUTE6
      ,SHIP_HEAD_ATTRIBUTE7
      ,SHIP_HEAD_ATTRIBUTE8
      ,SHIP_HEAD_ATTRIBUTE9
      ,SHIP_HEAD_ATTRIBUTE10
      ,SHIP_HEAD_ATTRIBUTE11
      ,SHIP_HEAD_ATTRIBUTE12
      ,SHIP_HEAD_ATTRIBUTE13
      ,SHIP_HEAD_ATTRIBUTE14
      ,SHIP_HEAD_ATTRIBUTE15
      ,SHIP_LINE_ATTRIBUTE_CATEGORY
      ,SHIP_LINE_ATTRIBUTE1
      ,SHIP_LINE_ATTRIBUTE2
      ,SHIP_LINE_ATTRIBUTE3
      ,SHIP_LINE_ATTRIBUTE4
      ,SHIP_LINE_ATTRIBUTE5
      ,SHIP_LINE_ATTRIBUTE6
      ,SHIP_LINE_ATTRIBUTE7
      ,SHIP_LINE_ATTRIBUTE8
      ,SHIP_LINE_ATTRIBUTE9
      ,SHIP_LINE_ATTRIBUTE10
      ,SHIP_LINE_ATTRIBUTE11
      ,SHIP_LINE_ATTRIBUTE12
      ,SHIP_LINE_ATTRIBUTE13
      ,SHIP_LINE_ATTRIBUTE14
      ,SHIP_LINE_ATTRIBUTE15
      ,USSGL_TRANSACTION_CODE
      ,GOVERNMENT_CONTEXT
      ,REASON_ID
      ,DESTINATION_CONTEXT
      ,SOURCE_DOC_QUANTITY
      ,SOURCE_DOC_UNIT_OF_MEASURE
      ,MOVEMENT_ID
      ,USE_MTL_LOT
      ,USE_MTL_SERIAL
      ,VENDOR_CUM_SHIPPED_QTY
      ,ITEM_NUM
      ,DOCUMENT_NUM
      ,DOCUMENT_LINE_NUM
      ,TRUCK_NUM
      ,SHIP_TO_LOCATION_CODE
      ,CONTAINER_NUM
      ,SUBSTITUTE_ITEM_NUM
      ,NOTICE_UNIT_PRICE
      ,ITEM_CATEGORY
      ,LOCATION_CODE
      ,VENDOR_NAME
      ,VENDOR_NUM
      ,VENDOR_SITE_CODE
      ,INTRANSIT_OWNING_ORG_CODE
      ,ROUTING_CODE
      ,ROUTING_STEP
      ,RELEASE_NUM
      ,DOCUMENT_SHIPMENT_LINE_NUM
      ,DOCUMENT_DISTRIBUTION_NUM
      ,DELIVER_TO_PERSON_NAME
      ,DELIVER_TO_LOCATION_CODE
      ,LOCATOR
      ,REASON_NAME
      ,VALIDATION_FLAG
      ,SUBSTITUTE_ITEM_ID
      ,QUANTITY_SHIPPED
      ,QUANTITY_INVOICED
      ,TAX_NAME
      ,TAX_AMOUNT
      ,REQ_NUM
      ,REQ_LINE_NUM
      ,REQ_DISTRIBUTION_NUM
      ,WIP_ENTITY_NAME
      ,WIP_LINE_CODE
      ,RESOURCE_CODE
      ,SHIPMENT_LINE_STATUS_CODE
      ,BARCODE_LABEL
      ,TRANSFER_PERCENTAGE
      ,QA_COLLECTION_ID
      ,COUNTRY_OF_ORIGIN_CODE
      ,OE_ORDER_HEADER_ID
      ,OE_ORDER_LINE_ID
      ,CUSTOMER_ID
      ,CUSTOMER_SITE_ID
      ,CUSTOMER_ITEM_NUM
      ,CREATE_DEBIT_MEMO_FLAG
      ,PUT_AWAY_RULE_ID
      ,PUT_AWAY_STRATEGY_ID
      ,LPN_ID
      ,TRANSFER_LPN_ID
      ,COST_GROUP_ID
      ,MOBILE_TXN
      ,MMTT_TEMP_ID
      ,TRANSFER_COST_GROUP_ID
      ,SECONDARY_QUANTITY
      ,SECONDARY_UNIT_OF_MEASURE
      ,SECONDARY_UOM_CODE
      ,QC_GRADE
      ,FROM_LOCATOR
      ,FROM_LOCATOR_ID
      ,PARENT_SOURCE_TRANSACTION_NUM
      ,INTERFACE_AVAILABLE_QTY
      ,INTERFACE_TRANSACTION_QTY
      ,INTERFACE_AVAILABLE_AMT
      ,INTERFACE_TRANSACTION_AMT
      ,LICENSE_PLATE_NUMBER
      ,SOURCE_TRANSACTION_NUM
      ,TRANSFER_LICENSE_PLATE_NUMBER
      ,LPN_GROUP_ID
      ,ORDER_TRANSACTION_ID
      ,CUSTOMER_ACCOUNT_NUMBER
      ,CUSTOMER_PARTY_NAME
      ,OE_ORDER_LINE_NUM
      ,OE_ORDER_NUM
      ,PARENT_INTERFACE_TXN_ID
      ,CUSTOMER_ITEM_ID
      ,AMOUNT
      ,JOB_ID
      ,TIMECARD_ID
      ,TIMECARD_OVN
      ,ERECORD_ID
      ,PROJECT_ID
      ,TASK_ID
      ,ASN_ATTACH_ID
          )
   SELECT
        rcv_transactions_interface_s.nextval
       ,DECODE(transaction_type,G_CORRECT,NULL,header_interface_id)
       ,group_id
       ,SYSDATE
       ,ln_user_id
       ,SYSDATE
       ,ln_user_id
       ,ln_user_id
       ,transaction_type
       ,transaction_date
       ,processing_status_code
       ,processing_mode_code
       ,transaction_status_code
       ,DECODE(transaction_type,G_CORRECT,ln_curr_quantity,ln_rcv_quantity)   -- quantity
       ,unit_of_measure
       ,auto_transact_code
       ,receipt_source_code
       ,source_document_code
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
       ,processing_request_id
       ,category_id
       ,interface_source_code
       ,interface_source_line_id
       ,inv_transaction_id
       ,item_id
       ,item_description
       ,item_revision
       ,uom_code
       ,G_EMPLOYEE_ID
       ,shipment_header_id
       ,shipment_line_id
       ,ship_to_location_id
       ,ln_curr_quantity                 -- primary_quantity
       ,primary_unit_of_measure
       ,vendor_id
       ,vendor_site_id
       ,from_organization_id
       ,DECODE(transaction_type,G_CORRECT,subinventory,from_subinventory)
       ,to_organization_id
       ,intransit_owning_org_id
       ,3  -- routing_header_id
       ,1  -- routing_step_id
       ,DECODE(transaction_type,G_CORRECT,lt_line_txn_id(ln_loop_indx),parent_transaction_id) -- parent_transaction_id
       ,po_header_id
       ,po_revision_num
       ,po_release_id
       ,po_line_id
       ,po_line_location_id
       ,po_unit_price
       ,currency_code
       ,currency_conversion_type
       ,currency_conversion_rate
       ,currency_conversion_date
       ,po_distribution_id
       ,requisition_line_id
       ,req_distribution_id
       ,charge_account_id
       ,substitute_unordered_code
       ,receipt_exception_flag
       ,accrual_status_code
       ,inspection_status_code
       ,inspection_quality_code
       ,DECODE(SIGN(ln_curr_quantity),-1,'RECEIVING','INVENTORY')  --DESTINATION_TYPE_CODE
       ,deliver_to_person_id
       ,ship_to_location_id
       ,deliver_to_location_id
       ,subinventory
       ,locator_id
       ,wip_entity_id
       ,wip_line_id
       ,department_code
       ,wip_repetitive_schedule_id
       ,wip_operation_seq_num
       ,wip_resource_seq_num
       ,bom_resource_id
       ,attribute5
       ,freight_carrier_code
       ,bill_of_lading
       ,packing_slip
       ,shipped_date
       ,expected_receipt_date
       ,actual_cost
       ,transfer_cost
       ,transportation_cost
       ,transportation_account_id
       ,num_of_containers
       ,waybill_airbill_num
       ,vendor_item_num
       ,vendor_lot_num
       ,rma_reference
       ,comments
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
       ,interface_transaction_id             -- attribute15
       ,ship_head_attribute_category
       ,ship_head_attribute1
       ,ship_head_attribute2
       ,ship_head_attribute3
       ,ship_head_attribute4
       ,ship_head_attribute5
       ,ship_head_attribute6
       ,ship_head_attribute7
       ,ship_head_attribute8
       ,ship_head_attribute9
       ,ship_head_attribute10
       ,ship_head_attribute11
       ,ship_head_attribute12
       ,ship_head_attribute13
       ,ship_head_attribute14
       ,ship_head_attribute15
       ,attribute_category  --     ship_line_attribute_category
       ,attribute1          --     ship_line_attribute1
       ,attribute2          --     ship_line_attribute2
       ,attribute3          --     ship_line_attribute3
       ,attribute4          --     ship_line_attribute4
       ,attribute5          --     ship_line_attribute5
       ,attribute6          --     ship_line_attribute6
       ,attribute7          --     ship_line_attribute7
       ,attribute8          --     ship_line_attribute8
       ,attribute9          --     ship_line_attribute9
       ,attribute10         --     ship_line_attribute10
       ,attribute11         --     ship_line_attribute11
       ,attribute12         --     ship_line_attribute12
       ,attribute13         --     ship_line_attribute13
       ,attribute14         --     ship_line_attribute14
       ,attribute15         --     ship_line_attribute15
       ,ussgl_transaction_code
       ,government_context
       ,reason_id
       ,DECODE(SIGN(ln_curr_quantity),1,NULL,'RECEIVING') -- destination_context
       ,source_doc_quantity
       ,source_doc_unit_of_measure
       ,movement_id
       ,1--use_mtl_lot
       ,1--use_mtl_serial
       ,vendor_cum_shipped_qty
       ,item_num
       ,document_num
       ,document_line_num
       ,truck_num
       ,ship_to_location_code
       ,container_num
       ,substitute_item_num
       ,notice_unit_price
       ,item_category
       ,location_code
       ,vendor_name
       ,vendor_num
       ,vendor_site_code
       ,intransit_owning_org_code
       ,routing_code
       ,routing_step
       ,release_num
       ,document_shipment_line_num
       ,document_distribution_num
       ,deliver_to_person_name
       ,deliver_to_location_code
       ,locator
       ,reason_name
       ,DECODE(transaction_type,G_CORRECT,NULL,validation_flag)
       ,substitute_item_id
       ,quantity_shipped
       ,quantity_invoiced
       ,tax_name
       ,tax_amount
       ,req_num
       ,req_line_num
       ,req_distribution_num
       ,wip_entity_name
       ,wip_line_code
       ,resource_code
       ,shipment_line_status_code
       ,barcode_label
       ,transfer_percentage
       ,qa_collection_id
       ,country_of_origin_code
       ,oe_order_header_id
       ,oe_order_line_id
       ,customer_id
       ,customer_site_id
       ,customer_item_num
       ,create_debit_memo_flag
       ,put_away_rule_id
       ,put_away_strategy_id
       ,lpn_id
       ,transfer_lpn_id
       ,cost_group_id
       ,mobile_txn
       ,mmtt_temp_id
       ,transfer_cost_group_id
       ,secondary_quantity
       ,secondary_unit_of_measure
       ,secondary_uom_code
       ,qc_grade
       ,from_locator
       ,from_locator_id
       ,parent_source_transaction_num
       ,interface_available_qty
       ,interface_transaction_qty
       ,interface_available_amt
       ,interface_transaction_amt
       ,license_plate_number
       ,source_transaction_num
       ,transfer_license_plate_number
       ,lpn_group_id
       ,order_transaction_id
       ,customer_account_number
       ,customer_party_name
       ,oe_order_line_num
       ,oe_order_num
       ,parent_interface_txn_id
       ,customer_item_id
       ,amount
       ,job_id
       ,timecard_id
       ,timecard_ovn
       ,erecord_id
       ,project_id
       ,task_id
       ,asn_attach_id
 FROM  xx_gi_rcv_xfr_dtl
 WHERE interface_transaction_id = lcu_dtl_cur.interface_transaction_id;
 
 lc_error_level :=  'Before Updating Tables after insert into RTI table, error for Txn interface id: '||lcu_dtl_cur.interface_transaction_id;
   --- Update line status to 'PL'
   UPDATE xx_gi_rcv_xfr_dtl
   SET    od_rcv_status_flag = 'PL'
   WHERE  interface_transaction_id = lcu_dtl_cur.interface_transaction_id;

  -- Update header status to 'PL' of the records successfully passed onto
  -- Interface table for processing.

   lc_error_level :=  'Before update of xx_gi_rcv_xfr_hdr table record to PL for header_interface_id ';
   UPDATE xx_gi_rcv_xfr_hdr
   SET    od_rcv_status_flag = 'PL'
   WHERE  header_interface_id = lcu_dtl_cur.header_interface_id;

  -- Update keyrec status to 'PL' of the records successfully passed onto
  -- Interface table for processing.
   lc_error_level :=  'Before update of xx_gi_rcv_keyrec table record to PL for header_interface_id';
   
   UPDATE xx_gi_rcv_keyrec
   SET    status_cd  = 'PL'
   WHERE  keyrec_nbr = lcu_dtl_cur.attribute8   
   AND    loc_nbr    = lcu_dtl_cur.attribute2;

   lc_error_level :=  'After Updating Tables after insert into RTI table, error for Txn interface id: '||lcu_dtl_cur.interface_transaction_id;
   IF ln_curr_quantity = ln_rcv_quantity THEN
     EXIT;  -- Exit out of the loop
   END IF;

  END LOOP;

 END LOOP;

 COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      x_ret_status  := 1;
      x_ret_message := lc_error_level;
      x_ret_message := SUBSTR(x_ret_message||'. '||SQLERRM,1,450);
      fnd_file.put_line(fnd_file.log,'oracle error in INSERT_INTO_XFR_RCVING_TBLS. '||x_ret_message); 
END CORRECT_XFR_RCVING ;

END XX_GI_RECEIVING_PKG;
/

SHOW ERRORS;

EXIT
