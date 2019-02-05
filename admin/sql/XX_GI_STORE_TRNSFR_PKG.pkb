SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_GI_STORE_TRNSFR_PKG
--Version Draft 1.3
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_STORE_TRNSFR_PKG                                        |
-- |Purpose      : This package contains procedures that is used the other RICE  |
-- |                elements to create/update/delete/search/display store        |
-- |                transfer information in EBS custom tables. Also moves these  |
-- |                information to MTL_TRANSACTIONS_INTERFACE                    |
-- |               ,MTL_SERIAL_NUMBERS_INTERFACE tables.                         |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- | XX_GI_TRANSFER_HEADERS       : I, S, U, D                                   |
-- | XX_GI_TRANSFER_LINES         : I, S, U, D                                   |
-- | XX_GI_SERIAL_NUMBERS         : I, S, U, D                                   |
-- | MTL_TRANSACTIONS_INTERFACE   : I                                            |
-- | MTL_SERIAL_NUMBERS_INTERFACE : I                                            |
-- | MTL_SYSTEM_ITEMS_B           : S                                            |
-- | MTL_INTERORG_PARAMETERS      : S                                            |
-- | HR_ALL_ORGANIZATION_UNITS    : S                                            |
-- | XX_GI_SHIPMENT_TRACKING      : S                                            |
-- | RCV_SHIPMENT_LINES           : S                                            |
-- | RCV_SHIPMENT_HEADERS         : S                                            |
-- | RCV_TRANSACTIONS             : S                                            |
-- |                                                                             |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  26-Oct-2007   Arun Andavar     Draft version                        |
-- |                                                                             |
-- |1.0      29-Nov-2007   Arun Andavar     After freezing error handling        |
-- |                                         strategy                            |
-- |                                                                             |
-- |1.1      05-Dec-2007   Arun Andavar     a)After adding subinventory parameter|
-- |                                         in create_shipment API              |
-- |                                        b)Individual parameter p_new item    |
-- |                                          is ignored and the pl/sql item is  |
-- |                                          considered for update_data API     |
-- |                                          (A)dd new line items scenario      |
-- |                                                                             |
-- |1.2      07-Dec-2007   Arun Andavar     a)After populating shipment_number   |
-- |                                           in MTL_MATERIAL_TRANSACTIONS      |
-- |                                                                             |
-- |1.3      18-Dec-2007   Arun Andavar     a)Merged cursors.                    |
-- |                                        b)Capturing subinventory code in     |
-- |                                          line tables.                       |
-- |                                        c)Lines cannot be added to the header|
-- |                                          which has one or more lines with   |
-- |                                          status other than 'OPEN'.          | 
-- |                                        d)Corrected cursor that takes org id |
-- |                                          and compares it to attribute1.     |
-- |                                        e)Added shipment number validation   |
-- +=============================================================================+
IS
   -- ----------------------------------------
   -- Global constants used for error handling
   -- ----------------------------------------
   G_PROG_NAME                     CONSTANT VARCHAR2(50)  := 'XX_GI_STORE_TRNSFR_PKG';
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
   G_OPEN_STATUS                   CONSTANT VARCHAR2(10)  := 'OPEN';
   G_CLOSED_STATUS                 CONSTANT VARCHAR2(10)  := 'CLOSED';
   G_ERROR_STATUS                  CONSTANT VARCHAR2(10)  := 'ERROR';
   G_SHIP_INITIATED_STATUS         CONSTANT VARCHAR2(20)  := 'SHIPPING-INITIATED';
   G_SHIPPED_STATUS                CONSTANT VARCHAR2(20)  := 'SHIPPED';
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
   
   -- +========================================================================+
   -- | Name        :  LOG_ERROR                                               |
   -- |                                                                        |
   -- | Description :  This wrapper procedure calls the custom common error api|
   -- |                 with relevant parameters.                              |
   -- |                                                                        |
   -- | Parameters  :                                                          |
   -- |                p_exception IN VARCHAR2                                 |
   -- |                p_message   IN VARCHAR2                                 |
   -- |                p_code      IN PLS_INTEGER                              |
   -- |                                                                        |
   -- +========================================================================+
   PROCEDURE LOG_ERROR(p_exception IN VARCHAR2
                      ,p_message   IN VARCHAR2
                      ,p_code      IN PLS_INTEGER
                      )
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
      lc_severity VARCHAR2(15) := NULL;
   BEGIN

      IF p_code = -1 THEN

         lc_severity := G_MAJOR;

      ELSIF p_code = 1 THEN

         lc_severity := G_MINOR;

      END IF;

      XX_COM_ERROR_LOG_PUB.LOG_ERROR
                           (
                            p_program_type            => G_PROG_TYPE     --IN VARCHAR2  DEFAULT NULL
                           ,p_program_name            => G_PROG_NAME     --IN VARCHAR2  DEFAULT NULL
                           ,p_module_name             => G_MODULE_NAME   --IN VARCHAR2  DEFAULT NULL
                           ,p_error_location          => p_exception     --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_code      => p_code          --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message           => p_message       --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_severity  => lc_severity     --IN VARCHAR2  DEFAULT NULL
                           ,p_notify_flag             => G_NOTIFY        --IN VARHCAR2  DEFAULT NULL
                           );

   END LOG_ERROR;
 
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
   -- | Name        :  display_out                                         |
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
   -- +=================================================================================+
   -- | Name        :  SEARCH_DATA                                                      |
   -- |                                                                                 |
   -- | Description :  This procedure search the records that meets the given criteria  |
   -- |                 and return those records as a PL/SQL table. This program        |
   -- |                 returns  E => On validation/Derivation error.                   |
   -- |                 returns  S => On complete success.                              |
   -- |                 returns  U => On unexpected error.                              |
   -- |                                                                                 |
   -- |                                                                                 |
   -- | Parameters  :  p_source_system         IN    VARCHAR2                           |
   -- |                p_start_transfer_number IN    VARCHAR2                           | 
   -- |                p_start_date            IN    DATE                               |
   -- |                p_end_date              IN    DATE                               |
   -- |                p_from_store            IN    VARCHAR2                           |
   -- |                p_to_store              IN    VARCHAR2                           |
   -- |                p_status                IN    VARCHAR2                           |
   -- |                p_item                  IN    VARCHAR2                           |
   -- |                x_search_out_dtl        OUT   NOCOPY   search_output_tbl_type    |
   -- |                x_error_code            OUT   NOCOPY   VARCHAR2                  |
   -- |                x_error_message         OUT   NOCOPY   VARCHAR2                  |
   -- |                                                                                 |
   -- +=================================================================================+
   PROCEDURE SEARCH_DATA(
                         p_source_system         IN    VARCHAR2
                        ,p_start_transfer_number IN    VARCHAR2 
                        ,p_start_date            IN    DATE     
                        ,p_end_date              IN    DATE     
                        ,p_from_store            IN    VARCHAR2 
                        ,p_to_store              IN    VARCHAR2 
                        ,p_status                IN    VARCHAR2 
                        ,p_item                  IN    VARCHAR2 
                        ,x_search_out_dtl        OUT   NOCOPY   search_output_tbl_type
                        ,x_return_status         OUT   NOCOPY   VARCHAR2
                        ,x_error_message         OUT   NOCOPY   VARCHAR2
                       )
   IS
   ---------------------------------------------------------------------------
   -- Cursor to get the information that met the criteria passed as parameters
   ---------------------------------------------------------------------------
   CURSOR lcu_searched_data
   IS
   SELECT  XXTH.transfer_number
          ,XXTH.from_store
          ,XXTH.to_store
          ,XXTH.created_by
          ,XXTH.creation_date
          ,XGTL.status
          ,XGTL.from_store_unit_cost
          ,XGTL.item
          ,XXTH.comments
   FROM    xx_gi_transfer_headers XXTH
          ,xx_gi_transfer_lines XGTL
   WHERE   XXTH.header_id         = XGTL.header_id
   AND     XXTH.transfer_number  >= TO_NUMBER(NVL(p_start_transfer_number,XXTH.transfer_number))
   AND     XXTH.from_store        = NVL(p_from_store, XXTH.from_store)
   AND     XXTH.to_store          = NVL(p_to_store,XXTH.to_store)
   AND     XGTL.item              = NVL (p_item, XGTL.item)
   AND     XXTH.creation_date BETWEEN NVL(p_start_date,XXTH.creation_date - 1) AND NVL(p_end_date,XXTH.creation_date + 1)
   AND     XGTL.status            = NVL (p_status, XGTL.status)
   AND     XXTH.source_system     = NVL (p_source_system,XXTH.source_system)
   ;
   BEGIN
      x_search_out_dtl := search_output_tbl_type();
      
      IF p_source_system IS NULL THEN

         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
         FND_MESSAGE.SET_TOKEN('PARAMS','Source system');
         x_error_message := FND_MESSAGE.GET;
         RETURN;

      END IF;

      FOR lr_data IN lcu_searched_data
      LOOP
         x_search_out_dtl.EXTEND;
         x_search_out_dtl(x_search_out_dtl.LAST).transfer_number     := lr_data.transfer_number;
         x_search_out_dtl(x_search_out_dtl.LAST).from_store          := lr_data.from_store;
         x_search_out_dtl(x_search_out_dtl.LAST).to_store            := lr_data.to_store;
         x_search_out_dtl(x_search_out_dtl.LAST).transfer_created_by := lr_data.created_by;
         x_search_out_dtl(x_search_out_dtl.LAST).creation_date       := lr_data.creation_date;
         x_search_out_dtl(x_search_out_dtl.LAST).transfer_cost       := lr_data.from_store_unit_cost;
         x_search_out_dtl(x_search_out_dtl.LAST).status              := lr_data.status;
         x_search_out_dtl(x_search_out_dtl.LAST).comments            := lr_data.comments;
         x_search_out_dtl(x_search_out_dtl.LAST).item                := lr_data.item;
      END LOOP;
      x_return_status := G_SUCCESS;
      x_error_message := NULL;

   EXCEPTION
      WHEN OTHERS THEN
         x_error_message := '(SEARCH_DATA): '||SQLERRM;
         x_return_status := G_UNEXPECTED_ERROR;

         LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                  ,p_message   => x_error_message --IN VARCHAR2
                  ,p_code      => -1              --IN PLS_INTEGER
                  );

   END SEARCH_DATA;
   -- +=================================================================================+
   -- | Name        :  INQUIRY_DATA                                                     |
   -- |                                                                                 |
   -- | Description :  This procedure search the records that meets the given criteria  |
   -- |                 and return those records as a PL/SQL table. This program        |
   -- |                 returns  E => On validation/Derivation error.                   |
   -- |                 returns  S => On complete success.                              |
   -- |                 returns  U => On unexpected error.                              |
   -- |                                                                                 |
   -- |                                                                                 |
   -- | Parameters  :  p_source_system          IN             VARCHAR2                 |
   -- |                p_transfer_number        IN  OUT NOCOPY VARCHAR2                 | 
   -- |                p_from_store             IN  OUT NOCOPY VARCHAR2                 |
   -- |                x_to_store               OUT            VARCHAR2                 |
   -- |                x_status                 OUT            VARCHAR2                 |
   -- |                x_transfer_created_by    OUT            VARCHAR2                 |
   -- |                x_transfer_creation_date OUT            DATE                     |
   -- |                x_keyrec                 OUT            VARCHAR2                 |
   -- |                x_ebs_receipt_number     OUT            VARCHAR2                 |
   -- |                x_receipt_date           OUT            DATE                     |
   -- |                x_received_by            OUT            VARCHAR2                 |
   -- |                x_inq_out_dtl            OUT NOCOPY     inquiry_output_tbl_type  |
   -- |                x_error_code             OUT NOCOPY     VARCHAR2                 |
   -- |                x_error_message          OUT NOCOPY     VARCHAR2                 |
   -- |                                                                                 |
   -- +=================================================================================+
   PROCEDURE INQUIRY_DATA(
                           p_source_system          IN             VARCHAR2
                          ,p_transfer_number        IN  OUT NOCOPY VARCHAR2
                          ,p_from_store             IN  OUT NOCOPY VARCHAR2
                          ,x_to_store               OUT            VARCHAR2
                          ,x_status                 OUT            VARCHAR2
                          ,x_transfer_created_by    OUT            VARCHAR2
                          ,x_transfer_creation_date OUT            DATE
                          ,x_keyrec                 OUT            VARCHAR2
                          ,x_ebs_receipt_number     OUT            VARCHAR2
                          ,x_receipt_date           OUT            DATE
                          ,x_received_by            OUT            VARCHAR2
                          ,x_inq_out_dtl            OUT NOCOPY     inquiry_output_tbl_type
                          ,x_return_status          OUT NOCOPY     VARCHAR2
                          ,x_error_message          OUT NOCOPY     VARCHAR2
                      )
   IS
      ---------------------------------------------------------------------------
      -- Cursor to get the information that met the criteria passed as parameters
      ---------------------------------------------------------------------------
      CURSOR lcu_inquired_data
      IS
      SELECT XXTH.transfer_number
            ,XXTH.from_store
            ,XXTH.to_store
            ,XGTL.status
            ,XXTH.created_by
            ,XXTH.creation_date
            ,XGTL.item
            ,XGTL.item_desc 
            ,XGTL.transfer_qty
            ,XGTL.shipped_qty
            ,XGTL.received_qty
            ,XGTL.from_store_uom
            ,XGTL.from_store_unit_cost
            ,XGTL.keyrec
            ,XGTL.ebs_receipt_number
            ,XGTL.receipt_date
            ,XGTL.received_by
      FROM   xx_gi_transfer_headers       XXTH
            ,xx_gi_transfer_lines         XGTL
      WHERE  XXTH.header_id                 = XGTL.header_id
      AND    XXTH.transfer_number           = p_transfer_number
      AND    XXTH.from_store                = NVL (p_from_store, XXTH.from_store)
      AND    XXTH.source_system             = p_source_system
      ;
   BEGIN

      IF p_source_system IS NULL 
         OR
         p_transfer_number IS NULL
      THEN
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
         FND_MESSAGE.SET_TOKEN('PARAMS','Source system/Transfer number');
         x_error_message := FND_MESSAGE.GET;
         RETURN;
      END IF;
      x_inq_out_dtl := inquiry_output_tbl_type();
      
      FOR lr_data IN lcu_inquired_data
      LOOP
         x_inq_out_dtl.EXTEND;
         x_inq_out_dtl(x_inq_out_dtl.LAST).item              := lr_data.item;
         x_inq_out_dtl(x_inq_out_dtl.LAST).item_description  := lr_data.item_desc;
         x_inq_out_dtl(x_inq_out_dtl.LAST).transfer_qty      := lr_data.transfer_qty;
         x_inq_out_dtl(x_inq_out_dtl.LAST).shipped_quantity  := lr_data.shipped_qty;
         x_inq_out_dtl(x_inq_out_dtl.LAST).received_quantity := lr_data.received_qty;
         x_inq_out_dtl(x_inq_out_dtl.LAST).uom               := lr_data.from_store_uom;
         x_inq_out_dtl(x_inq_out_dtl.LAST).unit_cost         := lr_data.from_store_unit_cost;
         p_from_store                                        := lr_data.from_store;
         x_to_store                                          := lr_data.to_store;
         x_status                                            := lr_data.status;
         x_transfer_created_by                               := lr_data.created_by;
         x_transfer_creation_date                            := lr_data.creation_date;
         x_keyrec                                            := lr_data.keyrec;
         x_ebs_receipt_number                                := lr_data.ebs_receipt_number;
         x_receipt_date                                      := lr_data.receipt_date;
         x_received_by                                       := lr_data.received_by;        
         
      END LOOP;

      x_return_status := G_SUCCESS;
      x_error_message := NULL;

   EXCEPTION
      WHEN OTHERS THEN
         x_error_message := '(INQUIRY_DATA): '||SQLERRM;
         x_return_status := G_UNEXPECTED_ERROR;

         LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                  ,p_message   => x_error_message --IN VARCHAR2
                  ,p_code      => -1              --IN PLS_INTEGER
                  );

   END INQUIRY_DATA;
   -- +==========================================================================================+
   -- | Name        :  GET_ON_HAND_QUANTITY                                                      |
   -- |                                                                                          |
   -- | Description :  This procedure gets the quantity on-hand of the given organization        |
   -- |                 item.                                                                    |
   -- |                 returns  NULL     => On error.                                           |
   -- |                 returns  quantity => On success.                                         |
   -- |                                                                                          |
   -- | Parameters  :  p_item_id       IN mtl_system_items_b.inventory_item_id%TYPE              |
   -- |                p_org_id        IN hr_all_organization_units.organization_id%TYPE         | 
   -- |                x_error_message OUT NOCOPY VARCHAR2                                       |
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
   -- +==========================================================================================+
   -- | Name        :  DISPLAY_DATA                                                              |
   -- |                                                                                          |
   -- | Description :  This procedure search the records that meets the given criteria           |
   -- |                 and return those records as a PL/SQL table. This program                 |
   -- |                 returns  E => On validation/Derivation error.                            |
   -- |                 returns  S => On complete success.                                       |
   -- |                 returns  U => On unexpected error.                                       |
   -- |                                                                                          |
   -- | Parameters  :  p_source_system          IN             VARCHAR2                          |
   -- |                p_transfer_number        IN             VARCHAR2                          | 
   -- |                x_from_store             IN  OUT NOCOPY VARCHAR2                          |
   -- |                x_to_store               IN  OUT NOCOPY VARCHAR2                          |
   -- |                x_header_id              OUT NOCOPY     VARCHAR2                          |
   -- |                x_disp_out_dtl           OUT NOCOPY     display_output_tbl_type           |
   -- |                x_comments               OUT            VARCHAR2                          |
   -- |                x_return_status          OUT NOCOPY     VARCHAR2                          |
   -- |                x_error_message          OUT NOCOPY     VARCHAR2                          |
   -- +==========================================================================================+
   PROCEDURE DISPLAY_DATA(
                           p_source_system          IN             VARCHAR2
                          ,p_transfer_number        IN             VARCHAR2
                          ,x_from_store             IN  OUT NOCOPY VARCHAR2
                          ,x_to_store               IN  OUT NOCOPY VARCHAR2
                          ,x_header_id              OUT NOCOPY     VARCHAR2
                          ,x_disp_out_dtl           OUT NOCOPY     display_output_tbl_type
                          ,x_comments               OUT NOCOPY     VARCHAR2
                          ,x_return_status          OUT NOCOPY     VARCHAR2
                          ,x_error_message          OUT NOCOPY     VARCHAR2
                         )
   IS
   -------------------------
   -- Local scalar variables
   -------------------------
   ln_qty_onhand    PLS_INTEGER := NULL;
   i                PLS_INTEGER := NULL;
   lc_error_message VARCHAR2(500) := NULL;
   lc_error_flag    VARCHAR2(1) := NULL;
   
   ---------------------------------------------------------------------------
   -- Cursor to get the information that met the criteria passed as parameters
   ---------------------------------------------------------------------------
   CURSOR lcu_displayable_data
   IS
   SELECT XXTH.from_store
         ,XXTH.to_store
         ,XXTH.ebs_from_org_id
         ,XXTH.comments
         ,XGTL.item
         ,XGTL.item_id
         ,XGTL.transfer_qty
         ,XGTL.item_desc
         ,XGTL.from_store_uom
         ,XGTL.from_store_unit_cost
         ,XXTH.created_by
         ,XXTH.creation_date
         ,XGTL.status
         ,XXTH.header_id
         ,XGTL.line_id
   FROM   xx_gi_transfer_headers         XXTH
         ,xx_gi_transfer_lines           XGTL
   WHERE  XXTH.header_id                 = XGTL.header_id
   AND    XXTH.transfer_number           = NVL(p_transfer_number,XXTH.transfer_number)
   AND    XXTH.from_store                = NVL(x_from_store,XXTH.from_store)
   AND    XXTH.to_store                  = NVL(x_to_store,XXTH.to_store)
  ;
   BEGIN
      IF p_source_system IS NULL 
         OR
         p_transfer_number IS NULL
      THEN
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
         FND_MESSAGE.SET_TOKEN('PARAMS','Source system/Transfer number');
         x_error_message := FND_MESSAGE.GET;
         RETURN;
      END IF;
      x_disp_out_dtl :=  display_output_tbl_type();
      lc_error_flag := G_NO;

      FOR lr_data IN lcu_displayable_data
      LOOP
         BEGIN
            x_disp_out_dtl.EXTEND;
            ln_qty_onhand := GET_ON_HAND_QUANTITY(p_item_id       => lr_data.ebs_from_org_id       -- IN mtl_system_items_b.inventory_item_id%TYPE
                                                 ,p_org_id        => lr_data.item_id -- IN hr_all_organization_units.organization_id%TYPE
                                                 ,x_error_message => lc_error_message          --OUT NOCOPY VARCHAR2
                                                 );

            x_disp_out_dtl(x_disp_out_dtl.LAST).item             := lr_data.item;
            x_disp_out_dtl(x_disp_out_dtl.LAST).item_description := lr_data.item_desc;
            x_disp_out_dtl(x_disp_out_dtl.LAST).uom              := lr_data.from_store_uom;
            x_disp_out_dtl(x_disp_out_dtl.LAST).unit_cost        := lr_data.from_store_unit_cost;
            x_disp_out_dtl(x_disp_out_dtl.LAST).transfer_qty     := lr_data.transfer_qty;
            x_disp_out_dtl(x_disp_out_dtl.LAST).qty_onhand       := ln_qty_onhand;
            x_disp_out_dtl(x_disp_out_dtl.LAST).created_by       := lr_data.created_by;
            x_disp_out_dtl(x_disp_out_dtl.LAST).creation_date    := lr_data.creation_date;
            x_disp_out_dtl(x_disp_out_dtl.LAST).status           := lr_data.status;
            x_disp_out_dtl(x_disp_out_dtl.LAST).line_id          := lr_data.line_id;
            x_disp_out_dtl(x_disp_out_dtl.LAST).header_id        := lr_data.header_id;
            x_from_store                                         := lr_data.from_store;
            x_to_store                                           := lr_data.to_store;
            x_header_id                                          := lr_data.header_id;
            x_comments                                           := lr_data.comments;

         EXCEPTION
            WHEN EX_ON_HAND_QNTY_ERR THEN

               x_disp_out_dtl(x_disp_out_dtl.LAST).error_message := lc_error_message;
               lc_error_flag := G_YES;
         END;

      END LOOP;

      IF lc_error_flag = G_NO THEN
         x_return_status := G_SUCCESS;
      ELSE
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62701_DISP_VALIDATN_ERR');
         x_error_message := FND_MESSAGE.GET;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN

         x_error_message := '(DISPLAY_DATA): '||SQLERRM;
         x_return_status := G_UNEXPECTED_ERROR;

         LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                  ,p_message   => x_error_message --IN VARCHAR2
                  ,p_code      => -1              --IN PLS_INTEGER
                  );

   END DISPLAY_DATA;

   -- +==========================================================================================+
   -- | Name        :  VALIDATE_DATA                                                             |
   -- |                                                                                          |
   -- | Description :  This procedure validates the given transactions and returns               |
   -- |                 PL/SQL table with derived information. This program                      |
   -- |                 returns  E => On validation/Derivation error.                            |
   -- |                 returns  S => On complete success.                                       |
   -- |                 returns  U => On unexpected error.                                       |
   -- |                                                                                          |
   -- | Parameters  :  p_source_system IN         VARCHAR2                                       |
   -- |                p_from_location IN         VARCHAR2                                       | 
   -- |                p_to_location   IN         VARCHAR2                                       |
   -- |                p_creation_date IN         DATE                                           |
   -- |                p_created_by    IN         VARCHAR2                                       |
   -- |                p_comments      IN         VARCHAR2                                       |
   -- |                p_item_in_dtl   IN         xx_gi_validate_item_tab_t                      |
   -- |                x_item_out_dtl  OUT NOCOPY validate_output_tbl_type                       |
   -- |                x_return_status OUT NOCOPY VARCHAR2                                       |
   -- |                x_error_message OUT NOCOPY VARCHAR2                                       |
   -- |                                                                                          |
   -- +==========================================================================================+

   PROCEDURE VALIDATE_DATA
                        ( p_source_system IN         VARCHAR2
                         ,p_from_location IN         VARCHAR2
                         ,p_to_location   IN         VARCHAR2
                         ,p_creation_date IN         DATE
                         ,p_created_by    IN         VARCHAR2    
                         ,p_comments      IN         VARCHAR2    
                         ,p_item_in_dtl   IN         xx_gi_validate_item_tab_t
                         ,x_item_out_dtl  OUT NOCOPY validate_output_tbl_type
                         ,x_return_status OUT NOCOPY VARCHAR2
                         ,x_error_message OUT NOCOPY VARCHAR2
                         )
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
      lc_is_item_to_org_serialized    VARCHAR2(1) := NULL;
      lc_is_item_from_org_serialized  VARCHAR2(1) := NULL;
      lc_is_sno_exists                VARCHAR2(1) := NULL;
      lc_item                         mtl_system_items_b.segment1%TYPE := NULL;
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
      lt_item_in_dtl                  xx_gi_validate_item_tab_t := xx_gi_validate_item_tab_t() ;
      lc_on_hand_qnty_err             VARCHAR2(500) := NULL;
      ln_unit_cost                    PLS_INTEGER        := NULL;
      lc_currency_code                VARCHAR2(15)  := NULL;

    
      -- ------------------------------
      -- Local user defined exceptions
      -- ------------------------------
      EX_INVALID_FROM_ORG     EXCEPTION;
      EX_INVALID_TO_ORG       EXCEPTION;
      EX_VENDOR_CONSIGN_ERROR EXCEPTION;
      EX_SORTING_PLSQL_TBL    EXCEPTION;
      EX_SERIAL_NUM_NOT_FOUND EXCEPTION;
      ------------------------------------------------
      --Cursor to check if from organization is active
      ------------------------------------------------
      CURSOR lcu_is_org_active(p_rms_org_number IN VARCHAR2)
      IS
      SELECT HAOU.organization_id
            ,HAOU.name
      FROM   hr_all_organization_units HAOU
      WHERE  HAOU.attribute1 = p_rms_org_number
      AND    SYSDATE BETWEEN NVL(HAOU.date_from,SYSDATE-1) AND NVL(HAOU.date_to,SYSDATE+1)
      ;

      ---------------------------------------------------------
      -- Cursor to derive the base currency from operating unit
      ---------------------------------------------------------
      CURSOR lcu_get_base_currency_code
      IS
      SELECT GSOB.currency_code
      FROM   hr_operating_units HOU
            ,gl_sets_of_books   GSOB
      WHERE  HOU.organization_id = FND_PROFILE.VALUE(G_OPERATING_UNIT)
      AND    HOU.set_of_books_id = GSOB.set_of_books_id
      ;
      ------------------------------------------------------
      --Cursor to check if the serial number is valid or not
      ------------------------------------------------------
      CURSOR lcu_is_sno_exists(p_item_id       IN PLS_INTEGER
                              ,p_serial_number IN VARCHAR2
                              ,p_from_org_id   IN hr_all_organization_units.organization_id%TYPE
                              )
      IS
      SELECT G_YES
      FROM  mtl_serial_numbers MSN
      WHERE MSN.inventory_item_id       = p_item_id
      AND   MSN.serial_number           = p_serial_number
      AND   MSN.current_organization_id = p_from_org_id
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
            ,NVL(MSI.serial_status_enabled,G_NO) serial_status
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

   BEGIN
      IF p_source_system IS NULL 
         OR
         p_from_location IS NULL
         OR
         p_to_location IS NULL
      THEN
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
         FND_MESSAGE.SET_TOKEN('PARAMS','Source system/From location/To location');
         x_error_message := FND_MESSAGE.GET;
         RETURN;
      END IF;
      gn_from_org_id                := NULL;
      lt_item_in_dtl                := p_item_in_dtl;
      lc_error_flag                 := G_NO;
      x_item_out_dtl                := validate_output_tbl_type();
      ---------------------------------------
      -- Check if from organization is active
      ---------------------------------------
      OPEN lcu_is_org_active(p_from_location);
      FETCH lcu_is_org_active INTO gn_from_org_id,gc_from_org_name;
      CLOSE lcu_is_org_active;

      IF gn_from_org_id IS NULL THEN
         RAISE EX_INVALID_FROM_ORG;
      END IF;
      
      gn_to_org_id := NULL;
      -------------------------------------
      -- Check if to organization is active
      -------------------------------------
      OPEN lcu_is_org_active(p_to_location);
      FETCH lcu_is_org_active INTO gn_to_org_id,gc_to_org_name;
      CLOSE lcu_is_org_active;

      IF gn_to_org_id IS NULL THEN
         RAISE EX_INVALID_TO_ORG;
      END IF;

      ------------------------------------  
      -- For every record do the following
      ------------------------------------
      IF lt_item_in_dtl.COUNT > 0 THEN
         ------------------------------------------------------------
         -- Derive base currency code from the current Operating unit
         ------------------------------------------------------------
         OPEN lcu_get_base_currency_code;
         FETCH lcu_get_base_currency_code INTO lc_currency_code;
         CLOSE lcu_get_base_currency_code;

         IF lc_currency_code IS NULL THEN

            x_return_status := G_VALIDATION_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
            FND_MESSAGE.SET_TOKEN('PARAMS','Currency code');
            x_error_message := FND_MESSAGE.GET;
            RETURN;

         END IF;

         FOR indx IN lt_item_in_dtl.FIRST..lt_item_in_dtl.LAST
         LOOP
            x_item_out_dtl.EXTEND;

            IF lt_item_in_dtl(indx).item IS NOT NULL THEN

               BEGIN
                  x_item_out_dtl(x_item_out_dtl.LAST).item         := lt_item_in_dtl(indx).item;
                  x_item_out_dtl(x_item_out_dtl.LAST).transfer_qty := lt_item_in_dtl(indx).transfer_qty;

                  -------------------------------------------------------------------
                  -- For every change in item number derive item specific information
                  -------------------------------------------------------------------
                  lc_item                        := lt_item_in_dtl(indx).item;
                  ln_qty_onhand                  := NULL;
                  lc_description                 := NULL;
                  ln_from_org_item_id            := NULL;
                  ln_to_org_item_id              := NULL;
                  lc_uom_code                    := NULL;
                  lc_is_item_from_org_serialized := NULL;
                  lc_is_item_to_org_serialized   := NULL;
                  ln_cost_group_id               := NULL;
                  ln_unit_cost                   := NULL;
                  lc_on_hand_qnty_err            := NULL;
                  lc_return_status               := NULL;
                  lc_return_message              := NULL;
                  ------------------------------------------------------------------------------------
                  -- Check if the item is vaild and transactable and serialized in given receiving org
                  ------------------------------------------------------------------------------------
                  OPEN  lcu_is_item_transactable(lc_item,gn_to_org_id);
                  FETCH lcu_is_item_transactable INTO ln_to_org_item_id
                                                     ,lc_description
                                                     ,lc_is_item_to_org_serialized
                                                     ,lc_uom_code
                                                     ,ln_cost_group_id;
                  CLOSE lcu_is_item_transactable;
                  ----------------------------------------------------------------------------
                  -- We need UOM and cost group id of shipping org so re-initialize it to null
                  ----------------------------------------------------------------------------
                  lc_uom_code                    := NULL;
                  ln_cost_group_id               := NULL;

                  -----------------------------------------------------------------------------------
                  -- Check if the item is vaild and transactable and serialized in given shipping org
                  --  Get UOM and Unit cost id
                  -----------------------------------------------------------------------------------
                  OPEN  lcu_is_item_transactable(lc_item,gn_from_org_id);
                  FETCH lcu_is_item_transactable INTO ln_from_org_item_id
                                                     ,lc_description
                                                     ,lc_is_item_from_org_serialized
                                                     ,lc_uom_code
                                                     ,ln_cost_group_id;
                  CLOSE lcu_is_item_transactable;
            
                  IF ln_from_org_item_id IS NOT NULL AND ln_to_org_item_id IS NOT NULL THEN

                     IF ln_cost_group_id IS NOT NULL THEN

                        ---------------------------------------------------------
                        -- Derive Unit cost using the cost group id derived above
                        -- The below API returns null for all errors
                        ---------------------------------------------------------
                        ln_unit_cost := CST_COST_API.GET_ITEM_COST 
                                                                (p_api_version       => 1
                                                                ,p_inventory_item_id => ln_from_org_item_id
                                                                ,p_organization_id   => gn_from_org_id
                                                                ,p_cost_group_id     => ln_cost_group_id
                                                                ,p_cost_type_id      => NULL
                                                                );
                     END IF;

                     --------------------------------------------------
                     -- Derive consigment flag for the item in From org
                     --------------------------------------------------
                     XX_GI_CONSIGNMENT_DTLS_PKG.XX_GI_IS_CONSIGNED
                                         ( p_item_id           => ln_from_org_item_id      -- IN    PLS_INTEGER
                                          ,p_organization_id   => gn_from_org_id           -- IN    PLS_INTEGER
                                          ,x_consignment_flag  => lc_from_consignment_flag -- OUT   NOCOPY  VARCHAR2
                                          ,x_vendor_id         => ln_vendor_id             -- OUT   NOCOPY  PLS_INTEGER
                                          ,x_vendor_site_id    => ln_vendor_site_id        -- OUT   NOCOPY  PLS_INTEGER
                                          ,x_return_status     => lc_return_status         -- OUT   NOCOPY  VARCHAR2
                                          ,x_return_message    => lc_return_message        -- OUT   NOCOPY  VARCHAR2
                                         );

                     IF lc_return_status <> G_VALIDATION_ERROR THEN
                        ------------------------------------------------
                        -- Derive consigment flag for the item in To org
                        ------------------------------------------------                                     
                        XX_GI_CONSIGNMENT_DTLS_PKG.XX_GI_IS_CONSIGNED
                                            ( p_item_id           => ln_from_org_item_id    -- IN    PLS_INTEGER
                                             ,p_organization_id   => gn_to_org_id           -- IN    PLS_INTEGER
                                             ,x_consignment_flag  => lc_to_consignment_flag -- OUT   NOCOPY  VARCHAR2
                                             ,x_vendor_id         => ln_vendor_id           -- OUT   NOCOPY  PLS_INTEGER
                                             ,x_vendor_site_id    => ln_vendor_site_id      -- OUT   NOCOPY  PLS_INTEGER
                                             ,x_return_status     => lc_return_status       -- OUT   NOCOPY  VARCHAR2
                                             ,x_return_message    => lc_return_message      -- OUT   NOCOPY  VARCHAR2
                                            );
                                            
                        IF lc_return_status <> G_VALIDATION_ERROR THEN

                           IF   (lc_to_consignment_flag <> lc_from_consignment_flag)
                           THEN
                              ----------------------------------------------------------------------
                              -- If consignment flag of From and To are not same then raise an error
                              ----------------------------------------------------------------------

                              RAISE EX_VENDOR_CONSIGN_ERROR;

                           ELSE
                              --------------------------
                              -- Derive On-Hand Quantity
                              --------------------------
                              ln_qty_onhand := GET_ON_HAND_QUANTITY(p_item_id       => ln_from_org_item_id -- IN mtl_system_items_b.inventory_item_id%TYPE
                                                                   ,p_org_id        => gn_from_org_id      -- IN hr_all_organization_units.organization_id%TYPE
                                                                   ,x_error_message => lc_on_hand_qnty_err --OUT NOCOPY VARCHAR2
                                                                   );

                           END IF;
                        ELSE
                           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62702_CONSGN_STATUS_ERR');
                           FND_MESSAGE.SET_TOKEN('ORG','To');
                           lc_on_hand_qnty_err := FND_MESSAGE.GET||lc_return_message;

                        END IF; -- TO IF lc_return_status = G_SUCCESS THEN
                     ELSE
                           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62702_CONSGN_STATUS_ERR');
                           FND_MESSAGE.SET_TOKEN('ORG','From');
                           lc_on_hand_qnty_err := FND_MESSAGE.GET||lc_return_message;

                     END IF;--FROM IF lc_return_status = G_SUCCESS THEN
                  END IF;--IF ln_from_org_item_id IS NOT NULL THEN
                 
               EXCEPTION
                  WHEN EX_VENDOR_CONSIGN_ERROR THEN
                     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62703_CONSGN_VENDOR_ERR');
                     lc_on_hand_qnty_err := FND_MESSAGE.GET;

                  WHEN EX_ON_HAND_QNTY_ERR THEN

                     lc_on_hand_qnty_err := lc_on_hand_qnty_err;
                   
               END;
               ----------------------------------------------------------------------------------
               -- Following information are derive once of every item and used for all such items
               ----------------------------------------------------------------------------------
               x_item_out_dtl(x_item_out_dtl.LAST).item_description := lc_description;
               x_item_out_dtl(x_item_out_dtl.LAST).currency_code    := lc_currency_code;
               x_item_out_dtl(x_item_out_dtl.LAST).unit_cost        := ln_unit_cost;

               IF ln_from_org_item_id IS NOT NULL THEN
                  x_item_out_dtl(x_item_out_dtl.LAST).item_id := ln_from_org_item_id;

                  IF lc_uom_code IS NOT NULL THEN

                     x_item_out_dtl(x_item_out_dtl.LAST).uom := lc_uom_code;

                  ELSE

                     x_item_out_dtl(x_item_out_dtl.LAST).error_message := x_item_out_dtl(x_item_out_dtl.LAST).error_message||' UOM.';
                     lc_error_flag := G_YES;

                  END IF;

                  IF lc_on_hand_qnty_err IS NOT NULL THEN

                     x_item_out_dtl(x_item_out_dtl.LAST).error_message := x_item_out_dtl(x_item_out_dtl.LAST).error_message ||lc_on_hand_qnty_err;
                     lc_error_flag := G_YES;
                  ELSE

                     x_item_out_dtl(x_item_out_dtl.LAST).qty_onhand := ln_qty_onhand;

                  END IF;

                  IF lc_is_item_from_org_serialized = G_YES OR lc_is_item_to_org_serialized = G_YES THEN

                     x_item_out_dtl(x_item_out_dtl.LAST).item_from_org_serialized := lc_is_item_from_org_serialized;
                     x_item_out_dtl(x_item_out_dtl.LAST).item_to_org_serialized := lc_is_item_to_org_serialized;
                     -----------------------------------------------------------------------------------
                     -- Since the item is serialized in From (or) To org, there should be serial numbers
                     --   if there are no serial numbers then Raise an error
                     -----------------------------------------------------------------------------------
                     IF lt_item_in_dtl(indx).serial_numbers.COUNT <> 0 THEN

                        FOR sub_indx IN lt_item_in_dtl(indx).serial_numbers.FIRST..lt_item_in_dtl(indx).serial_numbers.LAST
                        LOOP
                           -------------------------------------------------------------------------------
                           -- Check to ensure that these serial numbers are not already used in Oracle EBS
                           -------------------------------------------------------------------------------

                           OPEN lcu_is_sno_exists(ln_from_org_item_id
                                                 ,lt_item_in_dtl(indx).serial_numbers(sub_indx).serial_number
                                                 ,gn_from_org_id
                                                 );
                           FETCH lcu_is_sno_exists INTO lc_is_sno_exists;
                           CLOSE lcu_is_sno_exists;
                           
                           IF lc_is_sno_exists = G_YES THEN
                              --------------------------------------------------------------
                              -- If serial numbers are already used in EBS then log an error
                              --------------------------------------------------------------
                              FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62721_SERIAL_EXISTS');
                              FND_MESSAGE.SET_TOKEN('SERIAL_NUM',lt_item_in_dtl(indx).serial_numbers(sub_indx).serial_number);
                              x_item_out_dtl(x_item_out_dtl.LAST).error_message := x_item_out_dtl(x_item_out_dtl.LAST).error_message ||FND_MESSAGE.GET;
                              lc_error_flag := G_YES;
                              
                           END IF;
                           
                        END LOOP;
                     ELSE
                        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62720_SERIAL_REQUIRED');
                        x_item_out_dtl(x_item_out_dtl.LAST).error_message := x_item_out_dtl(x_item_out_dtl.LAST).error_message ||FND_MESSAGE.GET;
                        lc_error_flag := G_YES;
                     END IF;
                  ELSE

                     x_item_out_dtl(x_item_out_dtl.LAST).item_from_org_serialized := G_NO;
                     x_item_out_dtl(x_item_out_dtl.LAST).item_to_org_serialized := G_NO;

                  END IF;
               ELSE
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62708_INVALID_OBJ');
                  FND_MESSAGE.SET_TOKEN('OBJ','item for the given organization');
                  x_item_out_dtl(x_item_out_dtl.LAST).error_message := x_item_out_dtl(x_item_out_dtl.LAST).error_message ||FND_MESSAGE.GET;
                  lc_error_flag := G_YES;
               END IF;
               
            ELSE
               x_return_status := G_VALIDATION_ERROR;
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
               FND_MESSAGE.SET_TOKEN('PARAMS','Item');
               x_error_message := FND_MESSAGE.GET;
               RETURN;
            END IF;
            IF lc_error_flag = G_YES THEN
               x_item_out_dtl(x_item_out_dtl.LAST).error_message := 'Reason for failure:'||x_item_out_dtl(x_item_out_dtl.LAST).error_message;
            END IF;

         END LOOP;
      END IF;

      IF lc_error_flag = G_YES THEN

         x_return_status := G_VALIDATION_ERROR;

      ELSE
         x_return_status := G_SUCCESS;
      END IF;

   EXCEPTION
      WHEN EX_INVALID_FROM_ORG THEN
          x_return_status := G_VALIDATION_ERROR;
          FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62704_INVLD_ORG');
          FND_MESSAGE.SET_TOKEN('ORGTYPE','shipping');
          x_error_message := FND_MESSAGE.GET;
      WHEN EX_INVALID_TO_ORG THEN
          x_return_status := G_VALIDATION_ERROR;
          FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62704_INVLD_ORG');
          FND_MESSAGE.SET_TOKEN('ORGTYPE','receiving');
          x_error_message := FND_MESSAGE.GET;
      WHEN EX_SORTING_PLSQL_TBL THEN
          x_return_status := G_UNEXPECTED_ERROR;
          FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62705_ERR_SORTING');
          x_error_message := FND_MESSAGE.GET||SQLERRM;
      WHEN OTHERS THEN
         x_error_message := '(VALIDATE_DATA): '||SQLERRM;
         x_return_status := G_UNEXPECTED_ERROR;

         LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                  ,p_message   => x_error_message --IN VARCHAR2
                  ,p_code      => -1              --IN PLS_INTEGER
                  );
   END VALIDATE_DATA;
   -- +==========================================================================================+
   -- | Name        :  CREATE_DATA                                                               |
   -- |                                                                                          |
   -- | Description :  This procedure validates the given transactions and then inserts the      |
   -- |                 validated data into custom transfer headers and lines tables.            |
   -- |                 returns  E => On validation/Derivation error.                            |
   -- |                 returns  S => On complete success.                                       |
   -- |                 returns  U => On unexpected error.                                       |
   -- |                                                                                          |
   -- | Parameters  :  p_source_system    IN         VARCHAR2                                    |
   -- |                p_from_store       IN         VARCHAR2                                    | 
   -- |                p_to_store         IN         VARCHAR2                                    |
   -- |                p_creation_date    IN         DATE                                        |
   -- |                p_created_by       IN         VARCHAR2                                    |
   -- |                p_transfer_number  IN         VARCHAR2                                    |
   -- |                p_transaction_type IN         VARCHAR2                                    |
   -- |                p_comments         IN         VARCHAR2                                    |
   -- |                p_item_in_dtl      IN         xx_gi_validate_item_tab_t                   |
   -- |                x_item_out_dtl     OUT NOCOPY validate_output_tbl_type                    |
   -- |                x_error_message    OUT NOCOPY VARCHAR2                                    |
   -- |                x_return_status    OUT NOCOPY VARCHAR2                                    |
   -- |                                                                                          |
   -- +==========================================================================================+
   PROCEDURE CREATE_DATA
                        (
                         p_source_system    IN         VARCHAR2
                        ,p_from_store       IN         VARCHAR2
                        ,p_to_store         IN         VARCHAR2
                        ,p_creation_date    IN         DATE
                        ,p_created_by       IN         VARCHAR2
                        ,p_transfer_number  IN         VARCHAR2
                        ,p_transaction_type IN         VARCHAR2
                        ,p_comments         IN         VARCHAR2
                        ,p_item_in_dtl      IN         xx_gi_validate_item_tab_t
                        ,x_item_out_dtl     OUT NOCOPY validate_output_tbl_type
                        ,x_error_message    OUT NOCOPY VARCHAR2
                        ,x_return_status    OUT NOCOPY VARCHAR2
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

      ---------------------------------------------------------
      -- Cursor to check if shipping network exists between the 
      --  given from and to org.
      ---------------------------------------------------------
      CURSOR lcu_shipnet_exists
      IS
      SELECT G_YES 
      FROM   mtl_interorg_parameters MIP 
      WHERE  MIP.from_organization_id = gn_from_org_id
      AND    MIP.to_organization_id   = gn_to_org_id
      ;
      -----------------------------------------------------------------------
      -- Cursor to derive transaction type id from the given transaction_type
      -----------------------------------------------------------------------
      CURSOR lcu_get_transaction_type
      IS
      SELECT MTT.transaction_type_id
      FROM   mtl_transaction_types MTT
      WHERE  MTT.transaction_type_name = p_transaction_type
      ;
      ----------------------------------------------------------------------------------------
      --Cursor to Check if the transfer number already exists in EBS tables and staging tables.
      ----------------------------------------------------------------------------------------
      CURSOR lcu_transfer_number_exists
      IS
      SELECT 'Y' 
      FROM   mtl_material_transactions MMT 
      WHERE  MMT.attribute5 IS NOT NULL 
      AND    MMT.attribute5 = p_transfer_number
      UNION 
      SELECT 'Y' 
      FROM   xx_gi_transfer_headers XGTH 
      WHERE  XGTH.transfer_number = p_transfer_number   
      ;
   BEGIN
      IF p_source_system IS NULL 
         OR
         p_from_store IS NULL
         OR
         p_to_store IS NULL
         OR
         p_transfer_number IS NULL
         OR
         p_transaction_type IS NULL
         OR
         p_creation_date IS NULL
         OR
         p_created_by IS NULL
      THEN
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
         FND_MESSAGE.SET_TOKEN('PARAMS','Source system/From store/To store/Transfer number/Transaction type/Creation date/Created by');
         x_error_message := FND_MESSAGE.GET;
         RETURN;
      END IF;
      lc_transfer_number_exists := G_NO;
      -------------------------------------------------------------------------------
      --Check if the transfer number already exists in EBS tables and staging tables.
      -------------------------------------------------------------------------------
      OPEN lcu_transfer_number_exists;
      FETCH lcu_transfer_number_exists INTO lc_transfer_number_exists;
      CLOSE lcu_transfer_number_exists;
      
      IF lc_transfer_number_exists = G_YES THEN

         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62723_DUP_TRNS_NUM');
         x_error_message := FND_MESSAGE.GET;
         RETURN;

      END IF;
      x_item_out_dtl := validate_output_tbl_type();

      gc_from_org_name := NULL;
      gc_to_org_name := NULL;

      OPEN lcu_get_transaction_type;
      FETCH lcu_get_transaction_type INTO lc_transaction_type_id;
      CLOSE lcu_get_transaction_type;

      IF lc_transaction_type_id IS NULL THEN
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62708_INVALID_OBJ');
         FND_MESSAGE.SET_TOKEN('OBJ','Transaction Type');
         x_error_message := FND_MESSAGE.GET||p_transaction_type;
         RETURN;
      END IF;
      ----------------------------
      -- Validate the transactions
      ----------------------------

      VALIDATE_DATA
                   ( p_source_system => p_source_system --IN         VARCHAR2    
                    ,p_from_location => p_from_store    --IN         VARCHAR2    
                    ,p_to_location   => p_to_store      --IN         VARCHAR2    
                    ,p_creation_date => p_creation_date --IN         DATE        
                    ,p_created_by    => p_created_by    --IN         VARCHAR2    
                    ,p_comments      => p_comments      --IN         VARCHAR2    
                    ,p_item_in_dtl   => p_item_in_dtl   --IN         xx_gi_validate_item_tab_t
                    ,x_item_out_dtl  => x_item_out_dtl  --OUT NOCOPY validate_output_tbl_type
                    ,x_return_status => x_return_status --OUT NOCOPY VARCHAR2
                    ,x_error_message => x_error_message --OUT NOCOPY VARCHAR2
                    );

      IF x_return_status = G_SUCCESS THEN
         -----------------------------------------------------------------------
         -- Check if shipping network already exists between "From" and "To" org
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

            IF lc_status = G_VALIDATION_ERROR THEN

               x_return_status := G_VALIDATION_ERROR;
               x_error_message := lc_err_msg;
               RETURN;
            END IF;
         END IF;

         lc_first_record := G_YES;

         FOR i IN x_item_out_dtl.FIRST..x_item_out_dtl.LAST
         LOOP
            ----------------------------------------------------------------------
            -- If there is no validation error for the current record then proceed
            --  with the insertion of transaction data into custom tables.
            ----------------------------------------------------------------------
            IF x_item_out_dtl(i).error_message IS NULL THEN

               IF lc_first_record = G_YES THEN

                  lc_first_record := G_NO;

                  -----------------------------------------------------------------------------------------
                  -- Insert transfer header information into the custom header table XX_GI_TRANSFER_HEADERS
                  -----------------------------------------------------------------------------------------
                  BEGIN
                     INSERT
                     INTO  XX_GI_TRANSFER_HEADERS
                     (source_system
                     ,header_id
                     ,transfer_number
                     ,transaction_type
                     ,transaction_type_id
                     ,from_store
                     ,ebs_from_org_id
                     ,from_org_name
                     ,to_org_name
                     ,to_store
                     ,ebs_to_org_id
                     ,creation_date
                     ,created_by
                     ,last_updated_by    
                     ,last_update_date   
                     ,last_update_login  
                     ,comments
                     )
                     VALUES
                     (p_source_system
                     ,XX_GI_TRANSFER_HEADERS_S.nextval
                     ,p_transfer_number
                     ,p_transaction_type
                     ,lc_transaction_type_id
                     ,p_from_store
                     ,gn_from_org_id
                     ,gc_from_org_name
                     ,gc_to_org_name
                     ,p_to_store
                     ,gn_to_org_id
                     ,p_creation_date
                     ,p_created_by
                     ,p_created_by
                     ,p_creation_date
                     ,FND_GLOBAL.login_id
                     ,p_comments
                     );
                  EXCEPTION
                     WHEN OTHERS THEN

                        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62706_TRNS_HDR_INS_ERR');
                        x_error_message := '(CREATE_DATA): '||FND_MESSAGE.GET||SQLERRM;
                        x_return_status := G_UNEXPECTED_ERROR;

                        LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                                 ,p_message   => x_error_message --IN VARCHAR2
                                 ,p_code      => -1              --IN PLS_INTEGER
                                 ); 
                        ROLLBACK;
                        RETURN;
                  END;

               END IF;

               BEGIN

                  -----------------------------------------------------------------------------------
                  -- Insert transfer line information into the custom line table XX_GI_TRANSFER_LINES
                  -----------------------------------------------------------------------------------
                  INSERT 
                  INTO  XX_GI_TRANSFER_LINES
                  (line_id
                  ,header_id
                  ,item
                  ,item_id
                  ,item_desc
                  ,from_store_uom
                  ,transfer_qty
                  ,from_store_unit_cost
                  ,from_org_item_serialized
                  ,to_org_item_serialized
                  ,currency_code
                  ,creation_date
                  ,created_by
                  ,last_updated_by    
                  ,last_update_date   
                  ,last_update_login  
                  ,status
                  )
                  VALUES
                  (XX_GI_TRANSFER_LINES_S.nextval
                  ,XX_GI_TRANSFER_HEADERS_S.currval
                  ,x_item_out_dtl(i).item
                  ,x_item_out_dtl(i).item_id
                  ,x_item_out_dtl(i).item_description
                  ,x_item_out_dtl(i).uom
                  ,x_item_out_dtl(i).transfer_qty
                  ,x_item_out_dtl(i).unit_cost
                  ,x_item_out_dtl(i).item_from_org_serialized
                  ,x_item_out_dtl(i).item_to_org_serialized
                  ,x_item_out_dtl(i).currency_code
                  ,p_creation_date
                  ,p_created_by
                  ,p_created_by
                  ,p_creation_date
                  ,FND_GLOBAL.login_id
                  ,G_OPEN_STATUS
                  );

               EXCEPTION
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62707_INSERT_ERR');
                     FND_MESSAGE.SET_TOKEN('OBJ','transfer lines');
                     x_error_message := '(CREATE_DATA): '||FND_MESSAGE.GET||SQLERRM;
                     x_return_status := G_UNEXPECTED_ERROR;

                     LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                              ,p_message   => x_error_message --IN VARCHAR2
                              ,p_code      => -1              --IN PLS_INTEGER
                              ); 

                     ROLLBACK;
                     RETURN;
               END;

               --------------------------------------------------------------------------------------------------
               -- If only the item is serialized then try to insert the serial numbers in to XX_GI_SERIAL_NUMBERS
               --------------------------------------------------------------------------------------------------

               IF x_item_out_dtl(i).item_from_org_serialized = G_YES OR x_item_out_dtl(i).item_to_org_serialized = G_YES THEN

                  FOR sub_indx IN x_item_out_dtl(i).serial_numbers.FIRST..x_item_out_dtl(i).serial_numbers.LAST
                  LOOP

                     BEGIN

                        INSERT 
                        INTO XX_GI_SERIAL_NUMBERS
                        (line_id
                        ,serial_number
                        ,creation_date
                        ,created_by
                        ,last_updated_by    
                        ,last_update_date   
                        ,last_update_login  
                        ,serial_status
                        )
                        VALUES
                        (XX_GI_TRANSFER_LINES_S.currval
                        ,x_item_out_dtl(i).serial_numbers(sub_indx).serial_number
                        ,p_creation_date
                        ,p_created_by
                        ,p_created_by
                        ,p_creation_date
                        ,FND_GLOBAL.login_id
                        ,NULL
                        );

                     EXCEPTION
                        WHEN OTHERS THEN
                           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62707_INSERT_ERR');
                           FND_MESSAGE.SET_TOKEN('OBJ','serial number');
                           x_error_message := '(CREATE_DATA): '||FND_MESSAGE.GET||SQLERRM;
                           x_return_status := G_UNEXPECTED_ERROR;

                           LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                                    ,p_message   => x_error_message --IN VARCHAR2
                                    ,p_code      => -1              --IN PLS_INTEGER
                                    ); 
                           ROLLBACK;
                           RETURN;
                     END;

                  END LOOP;

               END IF;

            END IF;

         END LOOP;
      ELSE
         x_return_status := G_VALIDATION_ERROR;
         x_error_message := x_error_message;
         RETURN;
      END IF;

      x_return_status := G_SUCCESS;

   EXCEPTION
      WHEN OTHERS THEN
         x_error_message := '(CREATE_DATA): '||SQLERRM;
         x_return_status := G_UNEXPECTED_ERROR;

         LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                  ,p_message   => x_error_message --IN VARCHAR2
                  ,p_code      => -1              --IN PLS_INTEGER
                  );
   END CREATE_DATA;
   -- +==========================================================================================+
   -- | Name        :  UPDATE_DATA                                                               |
   -- |                                                                                          |
   -- | Description :  This procedure updates header and lines, adds new lines, deletes the      |
   -- |                 the existing lines from custom transfer tables.                          |
   -- |                 returns  E => On validation/Derivation error.                            |
   -- |                 returns  S => On complete success.                                       |
   -- |                 returns  U => On unexpected error.                                       |
   -- |                                                                                          |
   -- | Parameters  :  p_source_system   IN  VARCHAR2                                            |
   -- |                p_transfer_number IN  VARCHAR2                                            | 
   -- |                p_new_comments    IN  VARCHAR2                                            |
   -- |                p_line_action     IN  VARCHAR2                                            |
   -- |                p_new_item        IN  VARCHAR2                                            |
   -- |                p_header_id       IN  PLS_INTEGER                                         |
   -- |                p_update_in_dtl   IN  xx_gi_validate_item_tab_t                           |
   -- |                x_update_out_dtl  OUT NOCOPY update_output_tbl_type                       |
   -- |                x_error_message   OUT NOCOPY VARCHAR2                                     |
   -- |                x_return_status   OUT NOCOPY VARCHAR2                                     |
   -- |                                                                                          |
   -- +==========================================================================================+
   PROCEDURE UPDATE_DATA
                       (
                        p_source_system   IN             VARCHAR2
                       ,x_transfer_number IN  OUT NOCOPY VARCHAR2
                       ,x_new_comments    IN  OUT NOCOPY VARCHAR2
                       ,p_line_action     IN             VARCHAR2
                       ,p_new_item        IN             VARCHAR2
                       ,p_header_id       IN             PLS_INTEGER
                       ,p_update_in_dtl   IN             xx_gi_validate_item_tab_t
                       ,x_update_out_dtl  OUT NOCOPY     validate_output_tbl_type
                       ,x_error_message   OUT NOCOPY     VARCHAR2
                       ,x_return_status   OUT NOCOPY     VARCHAR2
                       )
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
      lc_is_header_exist      VARCHAR2(1)              := NULL;
      lc_non_open_line_exists VARCHAR2(1)              := NULL;
      lt_item_out_dtl         validate_output_tbl_type := validate_output_tbl_type();
      lc_return_status        VARCHAR2(1)              := NULL;
      lc_error_message        VARCHAR2(500)            := NULL;
      lc_from_store           VARCHAR2(150)            := NULL;
      lc_to_store             VARCHAR2(150)            := NULL;  
      lc_created_by           PLS_INTEGER              := NULL;
      lc_creation_date        DATE                     := NULL;
      lc_transfer_number      VARCHAR2(25)             := NULL;
      ---------------------------------------------------------------------
      -- Cursor to check if the given header id exists in the system or not
      ---------------------------------------------------------------------
      CURSOR lcu_is_header_exist
      IS
      SELECT G_YES
            ,XGTH.from_store
            ,XGTH.to_store
            ,XGTH.creation_date
            ,XGTH.created_by
            ,XGTH.transfer_number
      FROM   xx_gi_transfer_headers XGTH
      WHERE  XGTH.header_id = p_header_id
      AND    XGTH.transfer_number = NVL(x_transfer_number,XGTH.transfer_number)
      ;
      -----------------------------------------------------------------------------------------
      -- Cursor to check if for the given header id exists any line with status other than OPEN
      -----------------------------------------------------------------------------------------
      CURSOR lcu_non_open_line_exists(p_header_id IN xx_gi_transfer_headers.header_id%TYPE)
      IS
      SELECT G_YES
      FROM   xx_gi_transfer_headers XGTH
            ,xx_gi_transfer_lines   XGTL
      WHERE  XGTH.header_id = p_header_id
      AND    XGTH.header_id = XGTL.header_id
      AND    XGTL.status    <> G_OPEN_STATUS
      ;
   BEGIN
      x_return_status := G_SUCCESS;

      IF p_source_system IS NULL 
         OR
         p_header_id IS NULL
      THEN
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
         FND_MESSAGE.SET_TOKEN('PARAMS','Source system/header id');
         x_error_message := FND_MESSAGE.GET;
         RETURN;
      END IF;
      
      x_update_out_dtl :=  validate_output_tbl_type();
      lc_is_header_exist := G_NO;

      OPEN lcu_is_header_exist;
      FETCH lcu_is_header_exist 
      INTO  lc_is_header_exist
           ,lc_from_store
           ,lc_to_store
           ,lc_creation_date
           ,lc_created_by
           ,x_transfer_number;
      CLOSE lcu_is_header_exist;

      IF lc_is_header_exist = G_NO THEN
         
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62708_INVALID_OBJ');
         FND_MESSAGE.SET_TOKEN('OBJ','Header id/Transfer number');
         x_error_message := FND_MESSAGE.GET;
         RETURN;

      END IF;

      IF p_line_action = G_UPDATE THEN
         ---------------------
         --Update the comments
         ---------------------

         UPDATE xx_gi_transfer_headers   XXTH
         SET    XXTH.comments          = x_new_comments
               ,XXTH.last_updated_by   = FND_GLOBAL.user_id
               ,XXTH.last_update_login = FND_GLOBAL.login_id         
               ,XXTH.last_update_date  = SYSDATE
         WHERE  XXTH.header_id         = p_header_id
         AND    XXTH.transfer_number   = NVL(x_transfer_number,G_989)
         ;
         IF SQL%ROWCOUNT = 0 THEN
            x_return_status := G_VALIDATION_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62708_INVALID_OBJ');
            FND_MESSAGE.SET_TOKEN('OBJ','Transfer number');
            x_error_message := FND_MESSAGE.GET;
            RETURN;
         END IF;

         --------------------------------------------
         --Update the quantity for the given line ids
         --------------------------------------------
         IF p_update_in_dtl.COUNT <> 0 THEN
            FOR i IN p_update_in_dtl.FIRST..p_update_in_dtl.LAST
            LOOP

               IF p_update_in_dtl(i).line_id IS NOT NULL THEN

                  UPDATE xx_gi_transfer_lines   XGTL
                  SET    XGTL.transfer_qty      = p_update_in_dtl(i).transfer_qty
                        ,XGTL.last_updated_by   = FND_GLOBAL.user_id
                        ,XGTL.last_update_login = FND_GLOBAL.login_id         
                        ,XGTL.last_update_date  = SYSDATE
                  WHERE  XGTL.line_id           = p_update_in_dtl(i).line_id 
                  AND    XGTL.status            = G_OPEN_STATUS
                  ;
                  
                  IF SQL%ROWCOUNT = 0 THEN
                     x_return_status := G_VALIDATION_ERROR;
                     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62709_INVLD_LINE_OR_STS');
                     FND_MESSAGE.SET_TOKEN('LINEID',p_update_in_dtl(i).line_id);
                     x_error_message := FND_MESSAGE.GET;
                     ROLLBACK;
                     RETURN;
                  END IF;
               ELSE
                  x_return_status := G_VALIDATION_ERROR;
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
                  FND_MESSAGE.SET_TOKEN('PARAMS','Line id');
                  x_error_message := FND_MESSAGE.GET;
                  ROLLBACK;
                  RETURN;
               END IF;
            END LOOP
            ;
         END IF;

      ELSIF (p_line_action = G_ADD AND p_update_in_dtl.COUNT <> 0) THEN
         ----------------------------
         --Addition of new line items
         ----------------------------
         lc_non_open_line_exists := G_NO;

         OPEN lcu_non_open_line_exists(p_header_id);
         FETCH lcu_non_open_line_exists INTO lc_non_open_line_exists;
         CLOSE lcu_non_open_line_exists;
         
         IF lc_non_open_line_exists = G_NO THEN

            ----------------------------
            -- Validate the transactions
            ----------------------------

            VALIDATE_DATA
                ( p_source_system => p_source_system  --IN         VARCHAR2    
                 ,p_from_location => lc_from_store    --IN         VARCHAR2    
                 ,p_to_location   => lc_to_store      --IN         VARCHAR2    
                 ,p_creation_date => lc_creation_date --IN         DATE        
                 ,p_created_by    => lc_created_by    --IN         VARCHAR2    
                 ,p_comments      => NULL             --IN         VARCHAR2    
                 ,p_item_in_dtl   => p_update_in_dtl  --IN         xx_gi_validate_item_tab_t
                 ,x_item_out_dtl  => x_update_out_dtl --OUT NOCOPY validate_output_tbl_type
                 ,x_return_status => lc_return_status --OUT NOCOPY VARCHAR2
                 ,x_error_message => lc_error_message --OUT NOCOPY VARCHAR2
                 );
            IF lc_return_status = G_SUCCESS THEN

               FOR i IN x_update_out_dtl.FIRST..x_update_out_dtl.LAST
               LOOP
                  BEGIN
                     -----------------------------------------------------------------------------------
                     -- Insert transfer line information into the custom line table XX_GI_TRANSFER_LINES
                     -----------------------------------------------------------------------------------
                     INSERT 
                     INTO  XX_GI_TRANSFER_LINES
                     (line_id
                     ,header_id
                     ,item
                     ,item_id
                     ,item_desc
                     ,from_store_uom
                     ,transfer_qty
                     ,from_store_unit_cost
                     ,from_org_item_serialized
                     ,to_org_item_serialized
                     ,currency_code
                     ,creation_date
                     ,created_by
                     ,last_updated_by    
                     ,last_update_date   
                     ,last_update_login  
                     ,status
                     )
                     VALUES
                     (XX_GI_TRANSFER_LINES_S.NEXTVAL
                     ,p_header_id
                     ,x_update_out_dtl(i).item
                     ,x_update_out_dtl(i).item_id
                     ,x_update_out_dtl(i).item_description
                     ,x_update_out_dtl(i).uom
                     ,x_update_out_dtl(i).transfer_qty
                     ,x_update_out_dtl(i).unit_cost
                     ,x_update_out_dtl(i).item_from_org_serialized
                     ,x_update_out_dtl(i).item_to_org_serialized
                     ,x_update_out_dtl(i).currency_code
                     ,SYSDATE
                     ,FND_GLOBAL.user_id
                     ,FND_GLOBAL.user_id
                     ,SYSDATE
                     ,FND_GLOBAL.login_id
                     ,G_OPEN_STATUS
                     );

                  EXCEPTION
                     WHEN OTHERS THEN
                        x_return_status := G_UNEXPECTED_ERROR;

                        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62710_LINE_CREATION_ERR');
                        FND_MESSAGE.SET_TOKEN('ITEM',x_update_out_dtl(i).item);
                        FND_MESSAGE.SET_TOKEN('QNTY',x_update_out_dtl(i).transfer_qty);
                        x_error_message := '(UPDATE_DATA): '||FND_MESSAGE.GET||SQLERRM;

                        LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                                 ,p_message   => x_error_message --IN VARCHAR2
                                 ,p_code      => -1              --IN PLS_INTEGER
                                 );
                        ROLLBACK;
                        RETURN;
                  END;
               END LOOP;
            ELSE
               x_return_status := G_VALIDATION_ERROR;
               x_error_message := lc_error_message;
               RETURN;
            END IF;
         ELSE
            x_return_status := G_VALIDATION_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62722_NON_OPEN_STATUS');
            x_error_message := FND_MESSAGE.GET||SQLERRM;
            RETURN;
         END IF;
      ELSIF (p_line_action = G_ADD AND (p_update_in_dtl.COUNT = 0 )) THEN

         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62711_ITEM_LINE_NUM_REQ');
         x_error_message := FND_MESSAGE.GET;

      ELSIF p_line_action = G_DELETE THEN
         ----------------------------
         -- Delete the given line ids
         ----------------------------
         IF p_update_in_dtl.COUNT <> 0 THEN

            FOR i IN p_update_in_dtl.FIRST..p_update_in_dtl.LAST
            LOOP
               IF p_update_in_dtl(i).line_id IS NOT NULL THEN

                  DELETE 
                  FROM  xx_gi_transfer_lines XGTL
                  WHERE XGTL.line_id   = p_update_in_dtl(i).line_id 
                  AND   XGTL.status    = G_OPEN_STATUS
                  ;

                  IF SQL%ROWCOUNT = 0 THEN
                     x_return_status := G_VALIDATION_ERROR;
                     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62709_INVLD_LINE_OR_STS');
                     FND_MESSAGE.SET_TOKEN('LINEID',p_update_in_dtl(i).line_id);
                     x_error_message := FND_MESSAGE.GET;
                     ROLLBACK;
                     RETURN;
                  END IF;
               ELSE
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
                  FND_MESSAGE.SET_TOKEN('PARAMS','Line id');
                  x_update_out_dtl(i).error_message := FND_MESSAGE.GET;
               END IF;

            END LOOP;
         ELSE
            x_return_status := G_VALIDATION_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62712_NO_REC_TO_DELETE');
            x_error_message := FND_MESSAGE.GET;
         END IF;
      ELSE
            x_return_status := G_VALIDATION_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62708_INVALID_OBJ');
            FND_MESSAGE.SET_TOKEN('OBJ','Line Action');
            x_error_message := FND_MESSAGE.GET;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := G_UNEXPECTED_ERROR;
         x_error_message := '(UPDATE_DATA): '||SQLERRM;
         LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                  ,p_message   => x_error_message --IN VARCHAR2
                  ,p_code      => -1              --IN PLS_INTEGER
                  );
   END UPDATE_DATA;
   -- +==========================================================================================+
   -- | Name        :  CREATE_SHIPMENT                                                           |
   -- |                                                                                          |
   -- | Description :  This procedure picks up the header and lines passed to this program which |
   -- |                 are in "OPEN" status and loads it into Open interface tables for the     |
   -- |                 standard program to pick up and updates the status in custom table to    |
   -- |                 "SHIP-INITIATED".                                                        |
   -- |                 returns  E => On validation/Derivation error.                            |
   -- |                 returns  S => On complete success.                                       |
   -- |                 returns  U => On unexpected error.                                       |
   -- |                                                                                          |
   -- | Parameters  :  p_source_system    IN VARCHAR2                                            |
   -- |                p_transfer_number  IN VARCHAR2                                            | 
   -- |                p_carton_count     IN VARCHAR2                                            |
   -- |                p_comments         IN VARCHAR2                                            |
   -- |                p_header_id        IN PLS_INTEGER                                         |
   -- |                p_ship_in_dtl      IN shipment_input_tbl_type                             |
   -- |                x_ship_out_dtl     OUT NOCOPY update_output_tbl_type                      |
   -- |                x_error_message    OUT NOCOPY VARCHAR2                                    |
   -- |                x_return_status    OUT NOCOPY VARCHAR2                                    |
   -- |                                                                                          |
   -- +==========================================================================================+
   PROCEDURE CREATE_SHIPMENT
                       (
                        p_source_system     IN VARCHAR2
                       ,p_transfer_number   IN VARCHAR2
                       ,p_carton_count      IN VARCHAR2
                       ,p_subinventory_code IN VARCHAR2 DEFAULT 'STOCK'
                       ,p_comments          IN VARCHAR2
                       ,p_header_id         IN PLS_INTEGER
                       ,p_ship_in_dtl       IN shipment_input_tbl_type
                       ,x_ship_out_dtl      OUT NOCOPY shipment_input_tbl_type
                       ,x_error_message     OUT NOCOPY VARCHAR2
                       ,x_return_status     OUT NOCOPY VARCHAR2
                       )
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
      lc_record_exists_flag VARCHAR2(1) := NULL;
      --------------------
      -- PL/SQL table type
      --------------------
      -----------------------
      -- Used for bulk update
      -----------------------
      TYPE line_id_tbl_type IS TABLE OF PLS_INTEGER
      INDEX BY BINARY_INTEGER;

      lt_line_id_tbl line_id_tbl_type;
      
      lt_ship_in_dtl shipment_input_tbl_type;
      -----------------------------------------------------------------
      -- Cursor to select transaction information for the given line id
      -----------------------------------------------------------------
      CURSOR lcu_for_shipment(p_line_id IN PLS_INTEGER)
      IS
      SELECT XXTH.source_system 
            ,XXTH.transfer_number
            ,XXTH.header_id
            ,XXTH.created_by
            ,XXTH.transaction_type_id
            ,XXTH.from_store
            ,XXTH.ebs_from_org_id
            ,XXTH.to_store
            ,XXTH.ebs_to_org_id
            ,XXTH.creation_date
            ,XXTH.transaction_type
            ,XGTL.item
            ,XGTL.shipment_number
            ,XGTL.item_id
            ,XGTL.line_id
            ,XGTL.from_store_uom
            ,XGTL.to_org_item_serialized
            ,XXTH.creation_date  transaction_date
      FROM   xx_gi_transfer_headers    XXTH
            ,xx_gi_transfer_lines      XGTL
      WHERE  XGTL.status          = G_OPEN_STATUS
      AND    XXTH.header_id       = XGTL.header_id
      AND    XXTH.transfer_number = NVL (p_transfer_number,XXTH.transfer_number)
      AND    XXTH.header_id       = p_header_id
      AND    XGTL.line_id         = p_line_id
      ;
      -------------------------------------------------------
      --Cursor to select serial numbers for the given line id
      -------------------------------------------------------
      CURSOR lcu_serial_numbers(p_line_id IN PLS_INTEGER)
      IS
      SELECT XGSN.serial_number
      FROM   xx_gi_serial_numbers XGSN
      WHERE  XGSN.line_id = p_line_id
      ;
   BEGIN
      IF p_source_system IS NULL 
         OR
         p_carton_count IS NULL
         OR
         p_transfer_number IS NULL
         OR
         p_comments IS NULL
         OR
         p_header_id IS NULL
      THEN
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
         FND_MESSAGE.SET_TOKEN('PARAMS','Source system/Carton count/Transfer number/Comments/Header id');
         x_error_message := FND_MESSAGE.GET;
         RETURN;
      END IF;
      x_ship_out_dtl  := shipment_input_tbl_type();
      lt_ship_in_dtl := p_ship_in_dtl;

      lc_record_exists_flag := G_NO;

      IF lt_ship_in_dtl.COUNT <> 0 THEN

         FOR i IN lt_ship_in_dtl.FIRST..lt_ship_in_dtl.LAST
         LOOP

            IF lt_ship_in_dtl(i).line_id IS NOT NULL THEN

               IF lt_ship_in_dtl(i).shipped_quantity IS NULL THEN

                  x_return_status := G_VALIDATION_ERROR;
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
                  FND_MESSAGE.SET_TOKEN('PARAMS','Shipped quantity');
                  x_error_message := FND_MESSAGE.GET;
                  RETURN;

               END IF;

               FOR lr_shipment IN lcu_for_shipment(lt_ship_in_dtl(i).line_id)
               LOOP
                  lc_record_exists_flag := G_YES;


                  BEGIN
                     INSERT
                     INTO  MTL_TRANSACTIONS_INTERFACE
                     (transaction_interface_id
                     ,source_code
                     ,source_line_id
                     ,source_header_id
                     ,process_flag
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
                     ,shipment_number
                     ,attribute5
                     ,attribute6
                     )
                     VALUES
                     (MTL_MATERIAL_TRANSACTIONS_S.nextval
                     ,p_source_system
                     ,lr_shipment.line_id
                     ,lr_shipment.header_id
                     ,1 --process flag
                     ,3 -- transaction mode
                     ,SYSDATE
                     ,FND_GLOBAL.user_id
                     ,SYSDATE
                     ,FND_GLOBAL.user_id
                     ,FND_GLOBAL.login_id
                     ,lr_shipment.ebs_from_org_id
                     ,ABS(lt_ship_in_dtl(i).shipped_quantity) * -1
                     ,lr_shipment.from_store_uom
                     ,lr_shipment.transaction_date
                     ,lr_shipment.transaction_type_id
                     ,lr_shipment.item_id
                     ,p_subinventory_code
                     ,lr_shipment.ebs_to_org_id
                     ,NVL(lr_shipment.transfer_number,lr_shipment.header_id)
                     ,NVL(lr_shipment.transfer_number,lr_shipment.header_id)
                     ,lr_shipment.created_by 
                     );

                     UPDATE xx_gi_transfer_lines XGTL
                     SET    XGTL.SHIPPED_QTY              = ABS(lt_ship_in_dtl(i).shipped_quantity) * -1
                           ,XGTL.shipment_number          = NVL(lr_shipment.transfer_number,lr_shipment.header_id)
                           ,XGTL.oracle_subinventory_code = p_subinventory_code
                           ,XGTL.last_updated_by          = FND_GLOBAL.user_id
                           ,XGTL.last_update_login        = FND_GLOBAL.login_id         
                           ,XGTL.last_update_date         = SYSDATE
                     WHERE  XGTL.line_id                  = lr_shipment.line_id
                     ;
                     -- Insert serial number information into serial interface table
                     IF lr_shipment.to_org_item_serialized = G_YES THEN
                        FOR lr_serial_number IN lcu_serial_numbers(lt_ship_in_dtl(i).line_id)
                        LOOP
                           BEGIN
                              INSERT
                              INTO   mtl_serial_numbers_interface
                              (transaction_interface_id
                              ,source_code
                              ,source_line_id
                              ,last_update_date
                              ,last_updated_by
                              ,creation_date
                              ,created_by
                              ,parent_serial_number
                              )
                              VALUES
                              (
                               MTL_MATERIAL_TRANSACTIONS_S.currval
                              ,p_source_system
                              ,lr_shipment.line_id
                              ,SYSDATE
                              ,FND_GLOBAL.user_id
                              ,SYSDATE
                              ,FND_GLOBAL.user_id
                              ,lr_serial_number.serial_number
                              )
                              ;
                           EXCEPTION
                              WHEN OTHERS THEN
                                 x_return_status := G_UNEXPECTED_ERROR;
                                 FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62714_MSNI_INSERT_ERR');
                                 FND_MESSAGE.SET_TOKEN('HEADER_ID',lr_shipment.header_id);
                                 FND_MESSAGE.SET_TOKEN('LINE_ID',lr_shipment.line_id);
                                 FND_MESSAGE.SET_TOKEN('SERIAL_NUM',lr_serial_number.serial_number);
                                 x_error_message := '(CREATE_SHIPMENT): '||FND_MESSAGE.GET||SQLERRM;
                                 LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                                          ,p_message   => x_error_message --IN VARCHAR2
                                          ,p_code      => -1              --IN PLS_INTEGER
                                 );
                                 ROLLBACK;
                                 RETURN;
                           END;
                        END LOOP;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS THEN
                        x_return_status := G_UNEXPECTED_ERROR;
                        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62715_MTI_INSERT_ERR');
                        FND_MESSAGE.SET_TOKEN('HEADER_ID',lr_shipment.header_id);
                        FND_MESSAGE.SET_TOKEN('LINE_ID',lr_shipment.line_id);
                        x_error_message := '(CREATE_SHIPMENT): '||FND_MESSAGE.GET||SQLERRM;
                        LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                                 ,p_message   => x_error_message --IN VARCHAR2
                                 ,p_code      => -1              --IN PLS_INTEGER
                                 );
                        ROLLBACK;
                        RETURN;
                  END;
               END LOOP;
               IF lc_record_exists_flag = G_NO THEN
                  x_return_status := G_VALIDATION_ERROR;
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62716_NO_RECORDS');
                  x_error_message := FND_MESSAGE.GET;
                  ROLLBACK;
                  RETURN;
               END IF;
          
            ELSE
               x_return_status := G_VALIDATION_ERROR;
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
               FND_MESSAGE.SET_TOKEN('PARAMS','Line id');
               x_error_message := FND_MESSAGE.GET;
               ROLLBACK;
               RETURN;
            END IF;
            lt_line_id_tbl(i) := lt_ship_in_dtl(i).line_id;
            x_ship_out_dtl := lt_ship_in_dtl;


            FORALL i IN lt_line_id_tbl.FIRST..lt_line_id_tbl.LAST
            UPDATE xx_gi_transfer_lines XGTL
            SET    XGTL.status            = G_SHIP_INITIATED_STATUS
                  ,XGTL.last_updated_by   = FND_GLOBAL.user_id
                  ,XGTL.last_update_login = FND_GLOBAL.login_id         
                  ,XGTL.last_update_date  = SYSDATE
            WHERE  XGTL.line_id           = lt_line_id_tbl(i)
            ;
         END LOOP;--FOR i IN lt_ship_in_dtl.FIRST..lt_ship_in_dtl.LAST

      ELSE
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62717_NO_RECS_SHIPMENT');
         x_error_message := FND_MESSAGE.GET;
         RETURN;
      END IF;

      x_return_status := G_SUCCESS;
      x_error_message := NULL;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := G_UNEXPECTED_ERROR;
         x_error_message := '(CREATE_SHIPMENT): '||SQLERRM;
         LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                  ,p_message   => x_error_message --IN VARCHAR2
                  ,p_code      => -1              --IN PLS_INTEGER
                  );
         ROLLBACK;
   END CREATE_SHIPMENT;
     -- +==========================================================================================+
     -- | Name        :  CAPTURE_CARRIER                                                           |
     -- |                                                                                          |
     -- | Description :  This procedure captures the carrier information that are passed to this   |
     -- |                 API in custom table to XX_GI_SHIPMENT_TRACKING.                          |
     -- |                 returns  S => On complete success.                                       |
     -- |                 returns  U => On unexpected error.                                       |
     -- |                 returns  E => On validation error.                                       |
     -- | Parameters  :  p_source_system           IN         VARCHAR2_NOT_NULL                    |
     -- |                p_transfer_number         IN         VARCHAR2_NOT_NULL                    | 
     -- |                p_carrier_id              IN         VARCHAR2_NOT_NULL                    |
     -- |                p_carrier_tracking_status IN         VARCHAR2                             |
     -- |                p_carrier_in_dtl          IN         carrier_input_tbl_type               |
     -- |                x_carrier_out_dtl         OUT NOCOPY carrier_output_tbl_type              |
     -- |                x_error_message           OUT NOCOPY VARCHAR2                             |
     -- |                x_return_status           OUT NOCOPY VARCHAR2                             |
     -- |                                                                                          |
   -- +============================================================================================+
   PROCEDURE CAPTURE_CARRIER
                       (
                         p_source_system           IN         VARCHAR2
                        ,p_transfer_number         IN         VARCHAR2
                        ,p_carrier_id              IN         VARCHAR2
                        ,p_carrier_tracking_status IN         VARCHAR2          
                        ,p_carrier_in_dtl          IN         carrier_input_tbl_type
                        ,p_header_id               IN         PLS_INTEGER
                        ,x_carrier_out_dtl         OUT NOCOPY carrier_output_tbl_type
                        ,x_error_message           OUT NOCOPY VARCHAR2
                        ,x_return_status           OUT NOCOPY VARCHAR2                        
                       )
   IS
      ----------------------------
      -- Local table type variable
      ----------------------------
      lt_carrier_input_tbl carrier_input_tbl_type;
   BEGIN
      IF p_source_system IS NULL 
         OR
         p_carrier_id IS NULL
         OR
         p_transfer_number IS NULL
         OR
         p_header_id IS NULL
      THEN
         x_return_status := G_VALIDATION_ERROR;
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
         FND_MESSAGE.SET_TOKEN('PARAMS','Source system/Carrier id/Transfer number/Header id');
         x_error_message := FND_MESSAGE.GET;
         RETURN;
      END IF;
      ----------------------------------------
      -- Initialize local carrier pl/sql table
      ----------------------------------------   
      x_carrier_out_dtl := carrier_output_tbl_type();
      lt_carrier_input_tbl := p_carrier_in_dtl;

      FOR i IN lt_carrier_input_tbl.FIRST..lt_carrier_input_tbl.LAST
      LOOP
         IF lt_carrier_input_tbl(i).carrier_tracking_number IS NULL 
            OR
            lt_carrier_input_tbl(i).weight IS NULL 
         THEN
            x_return_status := G_VALIDATION_ERROR;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62713_MANDATORY_PARAM');
            FND_MESSAGE.SET_TOKEN('PARAMS','Carrier Tracking Number (or) Weight');
            x_error_message := FND_MESSAGE.GET;
            ROLLBACK;
            RETURN;
         END IF;
         ------------------------------------------------------------------
         -- Insert the given information into XX_GI_SHIPMENT_TRACKING table
         ------------------------------------------------------------------
         INSERT 
         INTO XX_GI_SHIPMENT_TRACKING
         (line_id                     
         ,document_number             
         ,carrier_id                  
         ,carrier_tracking_number     
         ,carrier_tracking_status     
         ,weight_uom                  
         ,weight                      
         ,pickup_number               
         ,declared_value              
         ,carrier_confirmation_number 
         ,created_by                  
         ,creation_date               
         ,last_updated_by             
         ,last_update_date            
         ,last_update_login           
         )
         VALUES
         (lt_carrier_input_tbl(i).line_id
         ,p_transfer_number
         ,p_carrier_id
         ,lt_carrier_input_tbl(i).carrier_tracking_number
         ,p_carrier_tracking_status
         ,lt_carrier_input_tbl(i).weight_uom                 
         ,lt_carrier_input_tbl(i).weight                     
         ,lt_carrier_input_tbl(i).pickup_number              
         ,lt_carrier_input_tbl(i).declared_value             
         ,lt_carrier_input_tbl(i).carrier_confirmation_number
         ,FND_GLOBAL.user_id
         ,SYSDATE
         ,FND_GLOBAL.user_id
         ,SYSDATE
         ,FND_GLOBAL.login_id
         );
      END LOOP;
      x_return_status := G_SUCCESS;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := G_UNEXPECTED_ERROR;
         x_error_message := '(CAPTURE_CARRIER): '||SQLERRM;
         LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                  ,p_message   => x_error_message --IN VARCHAR2
                  ,p_code      => -1              --IN PLS_INTEGER
                  );
         ROLLBACK;
   END CAPTURE_CARRIER;

   -- +===========================================================================================+
   -- | Name        :  INTER_ORG_INFO                                                             |
   -- |                                                                                           |
   -- | Description :  This API checks if the transaction in the staging table which are initiated|
   -- |                 for shipping are shipped/received. If shipped/received then update the    |
   -- |                 staging table status to G_SHIPPED_STATUS/G_CLOSED_STATUS. If standard     |
   -- |                 program didnt not validate it successfully then staging status will be    |
   -- |                 updated to G_ERROR_STATUS.                                                |
   -- |                 returns  0  => On complete success.                                       |
   -- |                 returns  -1 => On unexpected error.                                       |
   -- |                                                                                           |
   -- | Parameters  :  x_error_message        OUT VARCHAR2                                        |
   -- |                x_error_code           OUT PLS_INTEGER                                     | 
   -- +===========================================================================================+
   PROCEDURE INTER_ORG_INFO(x_error_message        OUT VARCHAR2
                           ,x_error_code           OUT PLS_INTEGER
                           )
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
      lc_program_start_time  VARCHAR2(50) := NULL;
      i                      PLS_INTEGER       := NULL;
      --------------------
      -- PL/SQL table type
      --------------------
      -----------------------
      -- Used for bulk update
      -----------------------
      TYPE line_id_tbl_type IS TABLE OF PLS_INTEGER
      INDEX BY BINARY_INTEGER;

      TYPE error_message_tbl_type IS TABLE OF VARCHAR2(1000)
      INDEX BY BINARY_INTEGER;
      
      lt_line_id_tbl       line_id_tbl_type;
    
      lt_error_message_tbl error_message_tbl_type;
      ---------------------------------------
      -- Cursor to select shipped information
      ---------------------------------------

       CURSOR lcu_mtl_info
       IS
       SELECT                 
              MMT.transaction_id
             ,MMT.rcv_transaction_id
             ,MMT.actual_cost   
             ,XXTH.header_id
             ,XXTH.transfer_number
             ,XXTH.from_org_name
             ,XXTH.to_org_name             
             ,XGTL.status
             ,XGTL.line_id
             ,XGTL.item
        FROM  mtl_material_transactions MMT
             ,xx_gi_transfer_headers    XXTH
             ,xx_gi_transfer_lines      XGTL 
        WHERE XXTH.transfer_number   = MMT.shipment_number
        AND   XXTH.header_id         = XGTL.header_id
        AND   XGTL.status            IN (G_SHIP_INITIATED_STATUS,G_ERROR_STATUS)
        AND   MMT.source_line_id     = XGTL.line_id
        AND   MMT.rcv_transaction_id IS NULL
       ;
      ----------------------------------------
      -- Cursor to select received information
      ----------------------------------------
       CURSOR lcu_rcv_info
       IS
       SELECT                 
             MMT.transaction_id
            ,MMT.rcv_transaction_id
            ,MMT.actual_cost   
            ,XXTH.header_id
            ,XXTH.transfer_number
            ,XXTH.from_org_name
            ,XXTH.to_org_name 
            ,XGTL.status
            ,XGTL.line_id
            ,XGTL.item
            ,RT.shipment_header_id
            ,RT.shipment_line_id
            ,RT.attribute8 key_rec
            ,RSH.receipt_num
            ,RSL.quantity_received
            ,RSL.creation_date
            ,RSL.created_by
       FROM  mtl_material_transactions MMT
            ,xx_gi_transfer_headers    XXTH
            ,xx_gi_transfer_lines      XGTL 
            ,rcv_transactions          RT
            ,rcv_shipment_headers      RSH
            ,rcv_shipment_lines        RSL
       WHERE XXTH.transfer_number   = MMT.shipment_number
       AND   XXTH.header_id         = XGTL.header_id
       AND   XGTL.status            IN (G_SHIPPED_STATUS,G_ERROR_STATUS)
       AND   MMT.transfer_transaction_id    = XGTL.mtl_transaction_id
       AND   MMT.rcv_transaction_id = RT.transaction_id
       AND   RT.shipment_header_id  = RSH.shipment_header_id
       AND   RT.shipment_line_id    = RSL.shipment_line_id 
       AND   MMT.rcv_transaction_id IS NOT NULL
       ;
      -----------------------------------------------
      -- Cursor to select interface error information
      -----------------------------------------------
       CURSOR lcu_interface_error
       IS
       SELECT XGTL.line_id
             ,MTI.error_explanation
             ,MTI.transaction_interface_id
             ,XXTH.from_org_name
             ,XXTH.to_org_name
             ,XXTH.transfer_number
             ,XGTL.item
       FROM  xx_gi_transfer_headers    XXTH
            ,xx_gi_transfer_lines      XGTL 
            ,mtl_transactions_interface MTI
       WHERE XXTH.transfer_number = MTI.attribute5
       AND   XXTH.header_id       = XGTL.header_id
       AND   MTI.source_line_id   = XGTL.line_id
       AND   XGTL.status          IN (G_SHIP_INITIATED_STATUS,G_ERROR_STATUS)
       AND   MTI.process_flag     = G_INTERFACE_ERROR_FLAG
        ;
      ---------------------------------
      -- Cursor to select serial status
      ---------------------------------
       CURSOR lcu_serial_info
       IS
       SELECT XGTL.line_id
             ,MSN.serial_number
             ,XISN.serial_status    
             ,MSN.current_status 
             ,XXTH.transfer_number
       FROM   mtl_material_transactions MMT
             ,xx_gi_transfer_lines      XGTL
             ,xx_gi_transfer_headers    XXTH
             ,xx_gi_serial_numbers      XISN
             ,mtl_serial_numbers        MSN  
       WHERE MMT.source_line_id = XGTL.line_id
       AND   XXTH.header_id     = XGTL.header_id
       AND   MMT.attribute5     = XXTH.transfer_number
       AND   XGTL.status        IN (G_SHIP_INITIATED_STATUS,G_SHIPPED_STATUS,G_ERROR_STATUS)
       AND   XISN.line_id       = XGTL.line_id
       AND   MSN.serial_number  = XISN.Serial_number
       AND   XISN.serial_status IS NULL
       AND   (   XGTL.from_org_item_serialized = G_YES 
              OR XGTL.to_org_item_serialized = G_YES
             )
       ;

    BEGIN
        lc_program_start_time       := TO_CHAR(SYSDATE,G_PGM_STRT_END_FORMAT);

        i := 0;
        -------------------------------
        -- Write log header information
        -------------------------------
        DISPLAY_LOG('Office Depot '||RPAD(' ',48,' ')||RPAD('Date: '||lc_program_start_time,29,' '));
        DISPLAY_LOG('Request ID: '||FND_GLOBAL.conc_request_id);
        DISPLAY_LOG(' ');
        DISPLAY_LOG(RPAD(' ',26,' ')||RPAD('OD Inventory Transfer Interface Errors     ',61,' '));
        DISPLAY_LOG(RPAD('Transfer No.',15,' ')
                    ||'   '||RPAD('From Org',42,' ')
                    ||'   '||RPAD('To Org',42,' ')
                    ||'   '||RPAD('Item Name',15,' ')
                    ||'   '||RPAD('Transaction Interface ID',27,' ')
                    ||'   '||'Error Message'
                    );

        ----------------------------------------------------------------------
        -- Log all the errors and update the staging table with errored status
        ----------------------------------------------------------------------
        BEGIN
           FOR lr_err_rec IN lcu_interface_error
           LOOP
              lt_line_id_tbl(i)       := lr_err_rec.line_id;
              lt_error_message_tbl(i) := lr_err_rec.error_explanation;
              DISPLAY_LOG(        RPAD(NVL(lr_err_rec.transfer_number,' '),15,' ')
                         ||'   '||RPAD(NVL(lr_err_rec.from_org_name,' '),42,' ')
                         ||'   '||RPAD(NVL(lr_err_rec.to_org_name,' '),42,' ')
                         ||'   '||RPAD(NVL(lr_err_rec.item,' '),15,' ')
                         ||'   '||RPAD(lr_err_rec.transaction_interface_id,27,' ')
                         ||'   '||lr_err_rec.error_explanation
                         );
              i := i + 1;
           END LOOP;
           
           IF i = 0 THEN

              DISPLAY_LOG(' ');
              DISPLAY_LOG(RPAD('-',26,'-')||RPAD('No interface errors',26,'-'));           
         
           END IF;
           
           i := NULL;
           
           FORALL i IN lt_line_id_tbl.FIRST..lt_line_id_tbl.LAST
           UPDATE xx_gi_transfer_lines XGTL
           SET    XGTL.status            = G_ERROR_STATUS
                 ,XGTL.error_message     = lt_error_message_tbl(i)
                 ,XGTL.last_updated_by   = FND_GLOBAL.user_id
                 ,XGTL.last_update_login = FND_GLOBAL.login_id         
                 ,XGTL.last_update_date  = SYSDATE
           WHERE  XGTL.line_id = lt_line_id_tbl(i)
           ;
        EXCEPTION
           WHEN OTHERS THEN
              x_error_code := 2;
              FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62718_ERROR_WHILE_ERROR');
              x_error_message := '(INTER_ORG_INFO): '||FND_MESSAGE.GET||SQLERRM;         
              LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                       ,p_message   => x_error_message --IN VARCHAR2
                       ,p_code      => -1              --IN PLS_INTEGER
                       );
              ROLLBACK;
              RETURN;
        END;
        
        ---------------------------------------------------------------------------------
        --  Update the serial status on the staging table with oracle serial table status
        ---------------------------------------------------------------------------------        
        BEGIN
        
           FOR lr_serial_info IN lcu_serial_info
           LOOP
         
              UPDATE  xx_gi_serial_numbers XGSN
              SET     XGSN.serial_status     = lr_serial_info.current_status
                     ,XGSN.last_updated_by   = FND_GLOBAL.user_id
                     ,XGSN.last_update_login = FND_GLOBAL.login_id         
                     ,XGSN.last_update_date  = SYSDATE
              WHERE   XGSN.line_id           = lr_serial_info.line_id 
              AND     XGSN.serial_number     = lr_serial_info.serial_number
              ;  
           END LOOP;
        EXCEPTION
           WHEN OTHERS THEN
              x_error_code := 2;
              FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62719_ERROR_UPDATING');
              FND_MESSAGE.SET_TOKEN('OBJ','serial status');
              x_error_message := '(INTER_ORG_INFO): '||FND_MESSAGE.GET||SQLERRM; 
              LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                       ,p_message   => x_error_message --IN VARCHAR2
                       ,p_code      => -1              --IN PLS_INTEGER
                       );
              ROLLBACK;
              RETURN;
        END;
      
        -------------------------------
        -- Write log header information
        -------------------------------
        DISPLAY_OUT('Office Depot '||RPAD(' ',48,' ')||RPAD('Date: '||lc_program_start_time,29,' '));
        DISPLAY_OUT('Request ID: '||FND_GLOBAL.conc_request_id);
        DISPLAY_OUT(' ');
        DISPLAY_OUT(RPAD(' ',26,' ')||RPAD('OD Inventory Transfer Summary     ',61,' '));
        DISPLAY_OUT(RPAD('Transfer No.',15,' ')
                   ||'   '||RPAD('From Org',42,' ')
                   ||'   '||RPAD('To Org',42,' ')
                   ||'   '||RPAD('Item Name',15,' ')
                   ||'   '||RPAD('Transaction ID',27,' ')
                   ||'   '||RPAD('Status',7,' ')
                   ||'   '||RPAD('Shipment Header ID',27,' ')
                   ||'   '||RPAD('Shipment Line ID',27,' ')
                   ||'   '||RPAD('EBS Receipt Number',27,' ')

                   );

        -----------------------------------------------------------------------------------------------------------------------
        -- Fetch the transactions that are shipped and update the corresponding staging table record status to G_SHIPPED_STATUS
        -----------------------------------------------------------------------------------------------------------------------
        BEGIN
 
           FOR lr_mtl_info  IN  lcu_mtl_info
           LOOP
              
              DISPLAY_OUT(        RPAD(NVL(lr_mtl_info.transfer_number,' '),15,' ')
                         ||'   '||RPAD(NVL(lr_mtl_info.from_org_name,' '),42,' ')
                         ||'   '||RPAD(NVL(lr_mtl_info.to_org_name,' '),42,' ')
                         ||'   '||RPAD(NVL(lr_mtl_info.item,' '),15,' ')
                         ||'   '||RPAD(lr_mtl_info.transaction_id,27,' ')
                         ||'   '||RPAD(G_SHIPPED_STATUS,7,' ')
                         ||'   '||RPAD('NULL',27,' ')
                         ||'   '||RPAD('NULL',27,' ')
                         ||'   '||RPAD('NULL',27,' ')
                         );
           
              UPDATE xx_gi_transfer_lines XGTL
              SET    XGTL.from_store_unit_cost = lr_mtl_info.actual_cost
                    ,XGTL.mtl_transaction_id   = lr_mtl_info.transaction_id
                    ,XGTL.status               = G_SHIPPED_STATUS
                    ,XGTL.last_updated_by      = FND_GLOBAL.user_id
                    ,XGTL.last_update_login    = FND_GLOBAL.login_id         
                    ,XGTL.last_update_date     = SYSDATE
              WHERE  XGTL.line_id              = lr_mtl_info.line_id
              ;

           END LOOP;
        EXCEPTION
           WHEN OTHERS THEN
              x_error_code := 2;
              FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62719_ERROR_UPDATING');
              FND_MESSAGE.SET_TOKEN('OBJ','shipped informtion');
              x_error_message := '(INTER_ORG_INFO): '||FND_MESSAGE.GET||SQLERRM; 
              LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                       ,p_message   => x_error_message --IN VARCHAR2
                       ,p_code      => -1              --IN PLS_INTEGER
                       );
              ROLLBACK;
              RETURN;
        END;
        -----------------------------------------------------------------------------------------------------------------------
        -- Fetch the transactions that are received and update the corresponding staging table record status to G_CLOSED_STATUS
        -----------------------------------------------------------------------------------------------------------------------
        BEGIN
           FOR lr_rcv_info  IN  lcu_rcv_info
           LOOP          
              DISPLAY_OUT(         RPAD(NVL(lr_rcv_info.transfer_number,' '),15,' ')
                          ||'   '||RPAD(NVL(lr_rcv_info.from_org_name,' '),42,' ')
                          ||'   '||RPAD(NVL(lr_rcv_info.to_org_name,' '),42,' ')
                          ||'   '||RPAD(NVL(lr_rcv_info.item,' '),15,' ')
                          ||'   '||RPAD(lr_rcv_info.transaction_id,27,' ')
                          ||'   '||RPAD(G_CLOSED_STATUS,7,' ')
                          ||'   '||RPAD(lr_rcv_info.shipment_header_id,27,' ')
                          ||'   '||RPAD(lr_rcv_info.shipment_line_id,27,' ')
                          ||'   '||RPAD(lr_rcv_info.receipt_num,27,' ')
                          );
              
              UPDATE xx_gi_transfer_lines XGTL
              SET    XGTL.received_qty         = lr_rcv_info.quantity_received
                    ,XGTL.receipt_date         = lr_rcv_info.creation_date
                    ,XGTL.received_by          = lr_rcv_info.created_by
                    ,XGTL.ebs_receipt_number   = lr_rcv_info.receipt_num
                    ,XGTL.keyrec               = lr_rcv_info.key_rec
                    ,XGTL.rcv_shipment_line_id = lr_rcv_info.shipment_line_id
                    ,XGTL.status               = G_CLOSED_STATUS
                    ,XGTL.last_updated_by      = FND_GLOBAL.user_id
                    ,XGTL.last_update_login    = FND_GLOBAL.login_id         
                    ,XGTL.last_update_date     = SYSDATE
              WHERE  XGTL.line_id              = lr_rcv_info.line_id
              ;
              
              UPDATE xx_gi_transfer_headers XXTH
              SET    XXTH.rcv_shipment_header_id = lr_rcv_info.shipment_header_id
                    ,XXTH.last_updated_by        = FND_GLOBAL.user_id
                    ,XXTH.last_update_login      = FND_GLOBAL.login_id         
                    ,XXTH.last_update_date       = SYSDATE
              WHERE  XXTH.header_id              = lr_rcv_info.header_id
              ;
  
            END LOOP;
        EXCEPTION
           WHEN OTHERS THEN
              x_error_code := 2;
              FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62719_ERROR_UPDATING');
              FND_MESSAGE.SET_TOKEN('OBJ','received informtion');
              x_error_message := '(INTER_ORG_INFO): '||FND_MESSAGE.GET||SQLERRM; 
              LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                       ,p_message   => x_error_message --IN VARCHAR2
                       ,p_code      => -1              --IN PLS_INTEGER
                       );
              ROLLBACK;
              RETURN;
        END;
      
       x_error_code := 0;      
      
    EXCEPTION
       WHEN OTHERS THEN
          x_error_code := 2;
          x_error_message := '(INTER_ORG_INFO): '||SQLERRM; 
          LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
                   ,p_message   => x_error_message --IN VARCHAR2
                   ,p_code      => -1              --IN PLS_INTEGER
                   );
    END INTER_ORG_INFO;


END XX_GI_STORE_TRNSFR_PKG;
/
SHOW ERRORS;
EXIT
