SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_MISSHIP_ASN_PKG
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- | Name        :  XX_GI_MISSHIP_ASN_PKG.pkb                                    |
-- | Description :  Mis - Ship SKU and Add - on PO Package Body                  |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |  Version      Date         Author             Remarks                       |
-- | =========  =========== =============== ==================================== |
-- |  DRAFT 1a  17-Oct-2007   Ritu Shukla     Initial draft version              |
-- |    1.0                   Vikas Raina     Incorporated TL Review Comments    |
-- +=============================================================================+

AS
----------------------------
--Declaring Global Constants
----------------------------
G_REPROCESSING_FREQUENCY CONSTANT fnd_profile_option_values.profile_option_value%type :=  'OD: PO CUSTOM IV REPROCESSING FREQUENCY';
G_TRADE_EMAIL            CONSTANT fnd_profile_option_values.profile_option_value%type :=  'OD: GI MISSHIP TRADE ITEM NOTIFICATION TEAM';
G_NON_TRADE_EMAIL        CONSTANT fnd_profile_option_values.profile_option_value%type :=  'OD: GI MISSHIP NON-TRADE ITEM NOTIFICATION TEAM';
G_UPC                    CONSTANT VARCHAR2(10)                                        :=  'UPC';
G_VPC                    CONSTANT VARCHAR2(10)                                        :=  'VPC';
G_MASTER                 CONSTANT VARCHAR2(10)                                        :=  'MASTER';
G_TRADE                  CONSTANT VARCHAR2(10)                                        :=  'TRADE';
G_NONTRADE               CONSTANT VARCHAR2(10)                                        :=  'NON-TRADE';
G_ERROR_STATUS           CONSTANT VARCHAR2(10)                                        :=  'E';
G_SUCCESS_STATUS         CONSTANT VARCHAR2(10)                                        :=  'S';
G_ASN_TYPE               CONSTANT VARCHAR2(10)                                        :=  'ASN';
G_ERROR                  CONSTANT VARCHAR2(10)                                        :=  'ERROR';
G_APPROVED               CONSTANT VARCHAR2(10)                                        :=  'APPROVED';
G_PENDING                CONSTANT VARCHAR2(10)                                        :=  'PENDING';
G_BATCH                  CONSTANT VARCHAR2(10)                                        :=  'BATCH';
G_FAILED                 CONSTANT VARCHAR2(10)                                        :=  'FAILED';
G_SUCCESS                CONSTANT VARCHAR2(10)                                        :=  'SUCCESS';
G_XX346DELETE            CONSTANT VARCHAR2(40)                                        :=  'XX346DELETE';
G_PROGRAM_TYPE           CONSTANT VARCHAR2(40)                                        :=  'CONCURRENT PROGRAM';
G_PROGRAM_NAME           CONSTANT VARCHAR2(50)                                        :=  'XX_GI_MISSHIP_ASN_PKG.VALIDATE_SKU_ASN_PROC' ;
G_MODULE_NAME            CONSTANT VARCHAR2(10)                                        :=  'GI';

----------------------------
--Declaring Global Variables
----------------------------
gc_reprocessing_frequency                                             fnd_profile_option_values.profile_option_value%type;
gc_trade_email                                                        fnd_profile_option_values.profile_option_value%type;
gc_non_trade_email                                                    fnd_profile_option_values.profile_option_value%type;
gn_master_organization                                                mtl_parameters.organization_id%type;

-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE processing_status_tbl_type IS TABLE OF rcv_transactions_interface.processing_status_code%type
INDEX BY BINARY_INTEGER;
gt_processing_status_code    processing_status_tbl_type;

TYPE transaction_status_tbl_type IS TABLE OF rcv_transactions_interface.transaction_status_code%type
INDEX BY BINARY_INTEGER;
gt_transaction_status_code    transaction_status_tbl_type;

TYPE processing_mode_code_tbl_type IS TABLE OF rcv_transactions_interface.processing_mode_code%type
INDEX BY BINARY_INTEGER;
gt_processing_mode_code    processing_mode_code_tbl_type;

TYPE validation_flag_tbl_type IS TABLE OF rcv_transactions_interface.validation_flag%type
INDEX BY BINARY_INTEGER;
gt_validation_flag    validation_flag_tbl_type;

TYPE processing_request_id_tbl_type IS TABLE OF rcv_transactions_interface.processing_request_id%type
INDEX BY BINARY_INTEGER;
gt_processing_request_id    processing_request_id_tbl_type;
gt_request_id               processing_request_id_tbl_type;

TYPE last_update_date_tbl_type IS TABLE OF rcv_transactions_interface.last_update_date%type
INDEX BY BINARY_INTEGER;
gt_last_update_date    last_update_date_tbl_type;

TYPE item_num_tbl_type IS TABLE OF rcv_transactions_interface.item_num%type
INDEX BY BINARY_INTEGER;
gt_item_num    item_num_tbl_type;

TYPE inventory_item_id_tbl_type IS TABLE OF rcv_transactions_interface.item_id%type
INDEX BY BINARY_INTEGER;
gt_inventory_item_id inventory_item_id_tbl_type;

TYPE attribute9_tbl_type IS TABLE OF rcv_transactions_interface.attribute9%type
INDEX BY BINARY_INTEGER;
gt_attribute9    attribute9_tbl_type;

TYPE error_message_tbl_type IS TABLE OF VARCHAR2(4000)
INDEX BY BINARY_INTEGER;
gt_error_message    error_message_tbl_type;

TYPE error_status_tbl_type IS TABLE OF VARCHAR2(10)
INDEX BY BINARY_INTEGER;
gt_error_status     error_status_tbl_type;   

TYPE rowid_tbl_type IS TABLE OF rowid
INDEX BY BINARY_INTEGER;
gt_rowid     rowid_tbl_type; 

gt_item_details    XX_GI_MISSHIP_COMM_PKG.ITEM_DETAILS_REC_TBL_TYPE;

-- +====================================================================+
-- | Name        :  display_log                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  p_message                                           |
-- +====================================================================+
PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END display_log;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the out file  |
-- |                                                                    |
-- | Parameters  :  p_message                                           |
-- +====================================================================+
PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END display_out;

-- +======================================================================+
-- | Name        :  derive_profile_value                                  |
-- | Description :  This procedure derives prifile option value for the   |
-- |                given profile option                                  |
-- |                                                                      |
-- | Parameters  :  p_profile_option                                      |
-- |                                                                      |
-- | Returns     :  x_profile_value                                       |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE derive_profile_value(  p_profile_option      IN         VARCHAR2
                                ,x_profile_value       OUT NOCOPY VARCHAR2
                                ,x_status              OUT NOCOPY VARCHAR2
                                ,x_message             OUT NOCOPY VARCHAR2
                               )
IS
    lc_profile_value     fnd_profile_option_values.profile_option_value%type;
BEGIN
    lc_profile_value := FND_PROFILE.VALUE(p_profile_option);
    IF lc_profile_value is NULL THEN
        x_profile_value := NULL;
        x_status        := G_ERROR_STATUS;
        x_message       := 'Profile Option '||p_profile_option|| ' is not setup.';
    ELSE
        x_status        := G_SUCCESS_STATUS;
        x_profile_value := lc_profile_value;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        x_profile_value := NULL;
        x_status        := G_ERROR_STATUS;
        x_message       := 'Error while deriving value for Profile Option: '||p_profile_option|| ' Error: '||SUBSTR(SQLERRM,1,500);
END derive_profile_value;

-- +======================================================================+
-- | Name        :  derive_master_organization                            |
-- | Description :  This procedure derives master organization in the     |
-- |                system                                                |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_master_organization                                 |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE derive_master_organization(  x_master_organization OUT NOCOPY VARCHAR2
                                      ,x_status              OUT NOCOPY VARCHAR2
                                      ,x_message             OUT NOCOPY VARCHAR2
                                    )
IS
    ln_master_organization         mtl_parameters.organization_id%type;
BEGIN
    SELECT DISTINCT MP.master_organization_id 
    INTO   ln_master_organization
    FROM   mtl_parameters MP;
    x_status              := G_SUCCESS_STATUS;
    x_master_organization := ln_master_organization;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_master_organization := NULL;
        x_status              := G_ERROR_STATUS;
        x_message             := 'Master Organization is not setup.';
    WHEN OTHERS THEN
        x_master_organization := NULL;
        x_status              := G_ERROR_STATUS;
        x_message             := 'Error while deriving Master Organization. Error: '||SUBSTR(SQLERRM,1,500);
END derive_master_organization;

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

    x_status               := G_SUCCESS_STATUS;
    x_authorization_status := lc_authorization_status;
    x_line_id              := ln_line_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_authorization_status := NULL;
        x_line_id              := NULL;
        x_status               := G_ERROR_STATUS;
        x_message              := 'Purchase Order does not exist';
    WHEN OTHERS THEN
        x_authorization_status := NULL;
        x_line_id              := NULL;
        x_status               := G_ERROR_STATUS;
        x_message              := 'Error while finding item in Purchase Order. Error: '||SUBSTR(SQLERRM,1,500);
END check_po_line;

-- +======================================================================+
-- | Name        :  upc_validation                                        |
-- | Description :  This procedure checks if UPC Code exist for an        |
-- |                item                                                  |
-- |                                                                      |
-- | Parameters  :  p_organizaion_id                                      |
-- |                p_item_num                                            |
-- |                                                                      |
-- | Returns     :  x_inv_item_num                                        |
-- |                x_inventory_item_id                                   |
-- |                x_primary_uom_code                                    |
-- |                x_count                                               |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE upc_validation(  p_organization_id         IN         NUMBER
                          ,p_item_num                IN         VARCHAR2
                          ,x_inv_item_num            OUT NOCOPY VARCHAR2
                          ,x_inventory_item_id       OUT NOCOPY NUMBER
                          ,x_primary_uom_code        OUT NOCOPY VARCHAR2
                          ,x_count                   OUT NOCOPY NUMBER
                          ,x_status                  OUT NOCOPY VARCHAR2
                          ,x_message                 OUT NOCOPY VARCHAR2
                        )
IS
    lc_primary_uom_code                     mtl_system_items_b.primary_uom_code%type;
    ln_inventory_item_id                    mtl_system_items_b.inventory_item_id%type;
    lc_inv_item_num                         mtl_system_items_b.segment1%type;  
    ln_count                                PLS_INTEGER;
BEGIN
    SELECT MSIB.segment1, MSIB.inventory_item_id,MSIB.primary_uom_code, count(MSIB.segment1)
    INTO   lc_inv_item_num, ln_inventory_item_id,lc_primary_uom_code,ln_count
    FROM   mtl_system_items      MSIB
          ,mtl_cross_references  MCR
    WHERE  MSIB.inventory_item_id       = MCR.inventory_item_id
    AND    MSIB.organization_id         in ( gn_master_organization, p_organization_id)
    AND    MCR.cross_reference_type     = G_UPC
    AND    MCR.cross_reference          = p_item_num
    GROUP BY MSIB.segment1, MSIB.inventory_item_id,MSIB.primary_uom_code;
    x_status               :=  G_SUCCESS_STATUS;
    x_inventory_item_id    :=  ln_inventory_item_id;
    x_inv_item_num         :=  lc_inv_item_num;
    x_primary_uom_code     :=  lc_primary_uom_code;
    x_count                :=  ln_count;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_inventory_item_id    :=  NULL;
        x_inv_item_num         :=  NULL;
        x_primary_uom_code     :=  NULL;
        x_count                :=  0;
        x_status               :=  G_SUCCESS_STATUS;
        x_message              :=  NULL;
    WHEN OTHERS THEN
        x_inventory_item_id    :=  NULL;
        x_inv_item_num         :=  NULL;
        x_primary_uom_code     :=  NULL;
        x_count                :=  0;
        x_status               :=  G_ERROR_STATUS;
        x_message              :=  'Error while deriving UPC Code for an item '||p_item_num||' Error: '||SUBSTR(SQLERRM,1,500);
END upc_validation;

-- +======================================================================+
-- | Name        :  vpc_validation                                        |
-- | Description :  This procedure checks if VPC Code exist for an        |
-- |                item                                                  |
-- |                                                                      |
-- | Parameters  :  p_organizaion_id                                      |
-- |                p_item_num                                            |
-- |                p_vendor_id                                           |
-- |                                                                      |
-- | Returns     :  x_inv_item_num                                        |
-- |                x_inventory_item_id                                   |
-- |                x_primary_uom_code                                    |
-- |                x_count                                               |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE vpc_validation(  p_organization_id         IN         NUMBER
                          ,p_item_num                IN         VARCHAR2
                          ,p_vendor_id               IN         NUMBER
                          ,x_inv_item_num            OUT NOCOPY VARCHAR2
                          ,x_inventory_item_id       OUT NOCOPY NUMBER
                          ,x_primary_uom_code        OUT NOCOPY VARCHAR2
                          ,x_count                   OUT NOCOPY NUMBER
                          ,x_status                  OUT NOCOPY VARCHAR2
                          ,x_message                 OUT NOCOPY VARCHAR2
                        )
IS
    lc_primary_uom_code                     mtl_system_items_b.primary_uom_code%type;
    ln_inventory_item_id                    mtl_system_items_b.inventory_item_id%type;
    lc_inv_item_num                         mtl_system_items_b.segment1%type;  
BEGIN
    /*SELECT MSIB.segment1, MSIB.inventory_item_id, MSIB.primary_uom_code, count(MSIB.segment1)
    INTO   lc_inv_item_num, ln_inventory_item_id,lc_primary_uom_code,ln_count
    FROM   po_approved_supplier_list ASL
          ,mtl_system_items_b        MSIB
    WHERE  ASL.primary_vendor_item       =   p_item_num
    AND    ASL.item_id                   =   MSIB.inventory_item_id
    AND    MSIB.organization_id          in (gn_master_organization, p_organization_id )
    AND    ASL.vendor_id                 =   p_vendor_id 
    AND    ASL.using_organization_id     =   p_organization_id 
    Group by MSIB.segment1, MSIB.inventory_item_id, MSIB.primary_uom_code;*/
    
    BEGIN
        -------------------------------------
        -- Check if the VPC item exist in ASL
        -------------------------------------
        SELECT DISTINCT MSIB.segment1, MSIB.inventory_item_id, MSIB.primary_uom_code
        INTO   lc_inv_item_num, ln_inventory_item_id,lc_primary_uom_code
        FROM   po_approved_supplier_list ASL
              ,mtl_system_items_b        MSIB
        WHERE  ASL.primary_vendor_item       =   p_item_num
        AND    ASL.item_id                   =   MSIB.inventory_item_id
        AND    MSIB.organization_id          =   gn_master_organization--, p_organization_id )
        AND    ASL.vendor_id                 =   p_vendor_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            x_inventory_item_id    :=  NULL;
            x_inv_item_num         :=  NULL;
            x_primary_uom_code     :=  NULL;
            x_count                :=  0;
            x_status               :=  G_SUCCESS_STATUS;
            x_message              :=  NULL;
    END;
    IF lc_inv_item_num IS NOT NULL THEN
        BEGIN
        ---------------------------------------------------
        --Check if VPC item exist in receiving Organization
        ---------------------------------------------------
        SELECT     ASL.item_id
            INTO   ln_inventory_item_id
            FROM   po_approved_supplier_list ASL
            WHERE  ASL.primary_vendor_item       =   p_item_num
            AND    ASL.item_id                   =   ln_inventory_item_id
            AND    ASL.vendor_id                 =   p_vendor_id
            AND    ASL.using_organization_id     =   p_organization_id;
            
            x_status               :=  G_SUCCESS_STATUS;
            x_inventory_item_id    :=  ln_inventory_item_id;
            x_inv_item_num         :=  lc_inv_item_num;
            x_primary_uom_code     :=  lc_primary_uom_code;
            x_count                :=  2;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                x_inventory_item_id    :=  NULL;
                x_inv_item_num         :=  NULL;
                x_primary_uom_code     :=  NULL;
                x_count                :=  1;
                x_status               :=  G_SUCCESS_STATUS;
                x_message              :=  NULL;
        END;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        x_inventory_item_id    :=  NULL;
        x_inv_item_num         :=  NULL;
        x_primary_uom_code     :=  NULL;
        x_count                :=  0;
        x_status               :=  G_ERROR_STATUS;
        x_message              :=  'Error while deriving VPC Code for an item '||p_item_num||' Error: '||SUBSTR(SQLERRM,1,500);
END vpc_validation;
-- +======================================================================+
-- | Name        :  item_in_master_and_recv                               |
-- | Description :  This procedure checks if item exist in master and     |
-- |                receiving org                                         |
-- |                                                                      |
-- | Parameters  :  p_organizaion_id                                      |
-- |                p_item_num                                            |
-- |                                                                      |
-- | Returns     :  x_inv_item_num                                        |
-- |                x_inventory_item_id                                   |
-- |                x_primary_uom_code                                    |
-- |                x_count                                               |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE item_in_master_and_recv(  p_organization_id         IN         NUMBER
                                   ,p_item_num                IN         VARCHAR2
                                   ,x_inventory_item_id       OUT NOCOPY NUMBER
                                   ,x_primary_uom_code        OUT NOCOPY VARCHAR2
                                   ,x_item_description        OUT NOCOPY VARCHAR2
                                   ,x_count                   OUT NOCOPY NUMBER
                                   ,x_status                  OUT NOCOPY VARCHAR2
                                   ,x_message                 OUT NOCOPY VARCHAR2
                                 )
IS
    lc_primary_uom_code                     mtl_system_items_b.primary_uom_code%type;
    lc_item_description                     mtl_system_items_b.description%type;
    ln_inventory_item_id                    mtl_system_items_b.inventory_item_id%type;
    ln_count                                PLS_INTEGER;
BEGIN
    SELECT  MSIB.inventory_item_id, MSIB.primary_uom_code, MSIB.description,count(MSIB.inventory_item_id)
    INTO    ln_inventory_item_id,lc_primary_uom_code,lc_item_description,ln_count
    FROM    mtl_system_items_b MSIB
    WHERE   MSIB.organization_id      in (gn_master_organization,p_organization_id)
    AND     MSIB.segment1             =   p_item_num
    GROUP BY MSIB.inventory_item_id,MSIB.primary_uom_code,MSIB.description;
    x_status               :=  G_SUCCESS_STATUS;
    x_inventory_item_id    :=  ln_inventory_item_id;
    x_primary_uom_code     :=  lc_primary_uom_code;
    x_item_description     :=  lc_item_description;
    x_count                :=  ln_count;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_inventory_item_id    :=  NULL;
        x_primary_uom_code     :=  NULL;
        x_item_description     :=  NULL;
        x_count                :=  0;
        x_status               :=  G_SUCCESS_STATUS;
        x_message              :=  NULL;
    WHEN OTHERS THEN
        x_inventory_item_id    :=  NULL;
        x_primary_uom_code     :=  NULL;
        x_item_description     :=  NULL;
        x_count                :=  0;
        x_status               :=  G_ERROR_STATUS;
        x_message              :=  'Error while validating if item '||p_item_num||' exist in master and receiving org. Error: '||SUBSTR(SQLERRM,1,500);
END item_in_master_and_recv;

-- +======================================================================+
-- | Name        :  reset_process_flags                                   |
-- | Description :  This procedure updates the global table with all      |
-- |                the statuses                                          |
-- |                                                                      |
-- | Parameters  :  p_index                                               |
-- |                p_rowid                                               |
-- |                p_processing_status_code                              |
-- |                p_transaction_status_code                             |
-- |                p_processing_mode_code                                |
-- |                p_last_update_date                                    |
-- |                p_processing_request_id                               |
-- |                p_validation_flag                                     |
-- |                p_attribute9                                          |
-- |                p_request_id                                          |
-- |                p_item_num                                            |
-- |                p_inventory_item_id                                   |
-- |                p_error_message                                       |
-- |                p_error_status                                        |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE reset_process_flags(  p_index                       IN    NUMBER
                               ,p_rowid                       IN    ROWID
                               ,p_processing_status_code      IN    VARCHAR2
                               ,p_transaction_status_code     IN    VARCHAR2
                               ,p_processing_mode_code        IN    VARCHAR2
                               ,p_last_update_date            IN    DATE
                               ,p_processing_request_id       IN    NUMBER
                               ,p_validation_flag             IN    VARCHAR2
                               ,p_attribute9                  IN    VARCHAR2
                               ,p_request_id                  IN    NUMBER
                               ,p_item_num                    IN    VARCHAR2
                               ,p_inventory_item_id           IN    NUMBER
                               ,p_error_message               IN    VARCHAR2
                               ,p_error_status                IN    VARCHAR2
                             )

IS
    lc_item_type                    VARCHAR2(50);
BEGIN
    gt_rowid(p_index)                                   :=  p_rowid;
    gt_processing_status_code(p_index)                  :=  p_processing_status_code;
    gt_transaction_status_code(p_index)                 :=  p_transaction_status_code;
    gt_processing_mode_code(p_index)                    :=  p_processing_mode_code;
    gt_validation_flag(p_index)                         :=  p_validation_flag;
    gt_processing_request_id(p_index)                   :=  p_processing_request_id;
    gt_last_update_date(p_index)                        :=  p_last_update_date;
    gt_item_num(p_index)                                :=  p_item_num;
    gt_inventory_item_id(p_index)                       :=  p_inventory_item_id;
    gt_attribute9(p_index)                              :=  p_attribute9;
    gt_request_id(p_index)                              :=  p_request_id;
    gt_error_message(p_index)                           :=  p_error_message;
    gt_error_status(p_index)                            :=  p_error_status;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END reset_process_flags;

-- +======================================================================+
-- | Name        :  is_item_trade_nontrade                                |
-- | Description :  This procedure checks if item exist in master and     |
-- |                receiving org                                         |
-- |                                                                      |
-- | Parameters  :  p_organizaion_id                                      |
-- |                p_item_num                                            |
-- |                p_inventory_item_id                                   |
-- |                p_location_id                                         |
-- |                p_documnet_num                                        |
-- |                p_asn_ref                                             |
-- |                p_source                                              |
-- |                                                                      |
-- | Returns     :  x_status                                              |
-- |                x_message                                             |
-- |                x_trade_nontrade                                      |
-- +======================================================================+
PROCEDURE is_item_trade_nontrade (  p_organization_id         IN         NUMBER
                                   ,p_inventory_item_id       IN         VARCHAR2
                                   ,p_location_id             IN         NUMBER
                                   ,p_documnet_num            IN         VARCHAR2
                                   ,p_item_num                IN         VARCHAR2
                                   ,p_asn_ref                 IN         VARCHAR2
                                   ,p_source                  IN         VARCHAR2
                                   ,x_trade_nontrade          OUT NOCOPY VARCHAR2
                                   ,x_status                  OUT NOCOPY VARCHAR2
                                   ,x_message                 OUT NOCOPY VARCHAR2
                                 )
IS
    lc_item_type                    VARCHAR2(1);
    ln_item_ix                      PLS_INTEGER;
BEGIN
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
        gt_item_details(ln_item_ix).loc          :=  p_location_id;
        gt_item_details(ln_item_ix).po_number    :=  p_documnet_num;
        gt_item_details(ln_item_ix).sku          :=  p_item_num;
        gt_item_details(ln_item_ix).upc_vpc      :=  p_source;
        gt_item_details(ln_item_ix).asnref       :=  p_asn_ref;

    END IF; --Trade/Non Trade
    x_status                   :=  G_SUCCESS_STATUS;
    x_trade_nontrade           :=  lc_item_type;
EXCEPTION
    WHEN OTHERS THEN
        x_status               :=  G_ERROR_STATUS;
        x_message              :=  SQLERRM;
        x_trade_nontrade       :=  NULL;
END is_item_trade_nontrade;


-- +======================================================================+
-- | Name        :  validate_sku_asn_proc                                 |
-- | Description :  This procedure is called by concurrent program        |
-- |                'OD: GI Item Validation For ASN Data'                 |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_errbuf                                              |
-- |                x_retcode                                             |
-- +======================================================================+
PROCEDURE validate_sku_asn_proc(
                                 x_errbuf              OUT NOCOPY VARCHAR2
                                ,x_retcode             OUT NOCOPY VARCHAR2
                               )
IS

----------------------
--Declaring Exceptions
----------------------
EX_MISSING_SETUP               EXCEPTION;
EX_TRANSACTION                 EXCEPTION;

---------------------------
--Declaring Local Varibales
---------------------------
lc_status                      VARCHAR2(1);
lc_message                     VARCHAR2(4000);
lc_authorization_status        po_headers_all.authorization_status%type;
ln_line_id                     po_lines_all.po_line_id%type;
lc_primary_uom_code            mtl_system_items_b.primary_uom_code%type;
lc_item_description            mtl_system_items_b.description%type;
ln_inventory_item_id           mtl_system_items_b.inventory_item_id%type;
lc_inv_item_num                mtl_system_items_b.segment1%type;  
ln_count                       PLS_INTEGER;
ln_po_ix                       PLS_INTEGER  := 0;
ln_item_ix                     PLS_INTEGER  := 0;
lc_item_cost                   NUMBER;
ln_failure_count               PLS_INTEGER  := 0;
ln_success_count               PLS_INTEGER  := 0;
ln_total_count                 PLS_INTEGER  := 0;
lc_timestamp                   VARCHAR2(50);
lc_attribute9                  rcv_transactions_interface.attribute9%type;
lc_trade_nontrade              VARCHAR2(10);
lc_error_message               VARCHAR2(4000);


--------------------------------------------------
--Cursor to fetch all the errored records from RTI
--------------------------------------------------
CURSOR lcu_errored_asn
IS
SELECT RTI.rowid
      ,RHI.expected_receipt_date
      ,RTI.quantity
      ,RTI.interface_transaction_id
      ,RTI.item_num
      ,RTI.item_id
      ,RTI.to_organization_id
      ,RTI.location_id
      ,RTI.document_num
      ,RHI.vendor_id
      ,RHI.vendor_site_id
      ,RTI.po_header_id
      ,RTI.po_line_id
      ,RTI.header_interface_id
      ,RTI.amount
      ,RTI.document_line_num
      ,PVSA.org_id
      ,RTI.processing_status_code
      ,RTI.transaction_status_code
      ,RTI.processing_mode_code
      ,RTI.processing_request_id
      ,RTI.last_update_date
      ,RTI.validation_flag
      ,RTI.attribute9
      ,RTI.request_id
      ,RTI.shipment_num
      ,NULL error_status
      ,NULL error_message
FROM   rcv_headers_interface       RHI
      ,rcv_transactions_interface  RTI
      ,po_vendor_sites_all         PVSA
WHERE  RHI.asn_type = G_ASN_TYPE
AND   (   RTI.processing_status_code = G_ERROR
       OR RTI.transaction_status_code = G_ERROR)
AND   (   TRUNC((SYSDATE - to_date(RTI.attribute9,'DD-MON-RRRR HH24:MI:SS'))*24) > gc_reprocessing_frequency
       OR RTI.attribute9 is NULL)
AND    RHI.header_interface_id = RTI.header_interface_id
AND    RHI.vendor_site_id      = PVSA.vendor_site_id;


------------------------
--Declaring plsql tables
------------------------
TYPE errored_asn_tbl_type IS TABLE OF lcu_errored_asn%rowtype
INDEX BY BINARY_INTEGER;
lt_errored_asn errored_asn_tbl_type;

lt_po_details      XX_GI_MISSHIP_COMM_PKG.PO_ADD_LINE_REC_TBL_TYPE;

TYPE timestamp_tbl_type IS TABLE OF VARCHAR2(50)
INDEX BY BINARY_INTEGER;
gt_timestamp  timestamp_tbl_type;

BEGIN
    ------------------------------
    --Derive Profile option Values
    ------------------------------
    lc_status  := NULL;
    lc_message := NULL;
    derive_profile_value(  p_profile_option      =>  G_REPROCESSING_FREQUENCY
                          ,x_profile_value       =>  gc_reprocessing_frequency
                          ,x_status              =>  lc_status
                          ,x_message             =>  lc_message
                        );
    IF lc_status = G_ERROR_STATUS                        
    THEN
        display_log(lc_message);
    END IF;
    lc_status  := NULL;
    lc_message := NULL;                        
    derive_profile_value(  p_profile_option      =>  G_TRADE_EMAIL
                          ,x_profile_value       =>  gc_trade_email
                          ,x_status              =>  lc_status
                          ,x_message             =>  lc_message
                        );
    IF lc_status = G_ERROR_STATUS                        
    THEN
        display_log(lc_message);
    END IF;                        
    lc_status  := NULL;
    lc_message := NULL;
    derive_profile_value(  p_profile_option      =>  G_NON_TRADE_EMAIL
                          ,x_profile_value       =>  gc_non_trade_email
                          ,x_status              =>  lc_status
                          ,x_message             =>  lc_message
                        );
    IF lc_status = G_ERROR_STATUS                        
    THEN
        display_log(lc_message);
    END IF;
    lc_status  := NULL;
    lc_message := NULL;
    -------------------------------
    --Derive Master Organization id
    -------------------------------
    derive_master_organization(  x_master_organization =>  gn_master_organization
                                ,x_status              =>  lc_status
                                ,x_message             =>  lc_message
                              );
    IF lc_status = G_ERROR_STATUS                        
        THEN
            display_log(lc_message);
    END IF;

    -----------------------------------------
    --Raise exception if any setup is missing
    -----------------------------------------

    IF gc_reprocessing_frequency = NULL 
    OR gc_trade_email            = NULL 
    OR gc_non_trade_email        = NULL 
    OR gn_master_organization    = NULL
    THEN 
        RAISE EX_MISSING_SETUP;
    END IF;

    ------------------------------------------
    --Fetch all the errored asn in PLSQL Table
    ------------------------------------------
    OPEN  lcu_errored_asn;
    FETCH lcu_errored_asn BULK COLLECT INTO lt_errored_asn;
    CLOSE lcu_errored_asn;


    IF lt_errored_asn.COUNT <> 0 THEN
        FOR i in lt_errored_asn.FIRST..lt_errored_asn.LAST
        LOOP
        BEGIN
            -----------
            --Timestamp
            -----------
            lc_timestamp := to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS');
            ----------------------------------------------------------------
            --Validate if ASN item matches PO Line Item and derive PO status
            ----------------------------------------------------------------
            check_po_line (  p_header_id              =>  lt_errored_asn(i).po_header_id
                            ,p_item_num               =>  lt_errored_asn(i).item_num
                            ,x_authorization_status   =>  lc_authorization_status
                            ,x_line_id                =>  ln_line_id
                            ,x_status                 =>  lc_status
                            ,x_message                =>  lc_message
                          );
            IF lc_status = G_ERROR_STATUS THEN
                RAISE EX_TRANSACTION;
            ELSE --lc_status = G_ERROR_STATUS (check po line)
                IF ln_line_id IS NOT NULL AND lc_authorization_status = G_APPROVED
                THEN
                    -------------------
                    --Reset status flag 
                    -------------------
                    reset_process_flags(  p_index                       =>  i
                                         ,p_rowid                       =>  lt_errored_asn(i).rowid
                                         ,p_processing_status_code      =>  G_PENDING
                                         ,p_transaction_status_code     =>  G_PENDING
                                         ,p_processing_mode_code        =>  G_BATCH
                                         ,p_last_update_date            =>  SYSDATE
                                         ,p_processing_request_id       =>  NULL
                                         ,p_validation_flag             =>  'Y'
                                         ,p_attribute9                  =>  lt_errored_asn(i).attribute9--gt_timestamp(i)
                                         ,p_request_id                  =>  fnd_global.conc_request_id
                                         ,p_item_num                    =>  lt_errored_asn(i).item_num
                                         ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                         ,p_error_message               =>  NULL
                                         ,p_error_status                =>  G_SUCCESS
                                       );
                ELSIF ln_line_id IS NOT NULL AND lc_authorization_status <> G_APPROVED
                THEN
                    -------------------
                    --Reset status flag 
                    -------------------
                    fnd_message.set_name('XXPTP','XX_GI_60000_PO_NOT_VALID');
                    fnd_message.set_token('PONUM',lt_errored_asn(i).document_num);
                    lc_error_message:= fnd_message.get;
                    
                    reset_process_flags(  p_index                       =>  i
                                         ,p_rowid                       =>  lt_errored_asn(i).rowid
                                         ,p_processing_status_code      =>  lt_errored_asn(i).processing_status_code
                                         ,p_transaction_status_code     =>  lt_errored_asn(i).transaction_status_code
                                         ,p_processing_mode_code        =>  lt_errored_asn(i).processing_mode_code
                                         ,p_last_update_date            =>  lt_errored_asn(i).last_update_date
                                         ,p_processing_request_id       =>  lt_errored_asn(i).processing_request_id
                                         ,p_validation_flag             =>  lt_errored_asn(i).validation_flag
                                         ,p_attribute9                  =>  lt_errored_asn(i).attribute9
                                         ,p_request_id                  =>  fnd_global.conc_request_id
                                         ,p_item_num                    =>  lt_errored_asn(i).item_num
                                         ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                         ,p_error_message               =>  lc_error_message
                                         ,p_error_status                =>  G_FAILED
                                       );
                ELSE --ln_line_id IS NOT NULL AND lc_authorization_status = 'APPROVED'
                    -----------------------------------
                    --Validate if item matches UPC Code
                    -----------------------------------
                    upc_validation(  p_organization_id        =>  lt_errored_asn(i).to_organization_id
                                    ,p_item_num               =>  lt_errored_asn(i).item_num
                                    ,x_inv_item_num           =>  lc_inv_item_num
                                    ,x_inventory_item_id      =>  ln_inventory_item_id
                                    ,x_primary_uom_code       =>  lc_primary_uom_code
                                    ,x_count                  =>  ln_count
                                    ,x_status                 =>  lc_status
                                    ,x_message                =>  lc_message
                                  );
                    IF lc_status = G_ERROR_STATUS THEN
                        RAISE EX_TRANSACTION;
                    ELSE  --lc_status = 'E(upc validation)
                        IF ln_count = 2 THEN--Validate if item matches UPC Code
                            ---------------------------------------------
                            --Item exist in both master and receiving org
                            ---------------------------------------------
                            reset_process_flags(  p_index                       =>  i
                                                 ,p_rowid                       =>  lt_errored_asn(i).rowid
                                                 ,p_processing_status_code      =>  G_PENDING
                                                 ,p_transaction_status_code     =>  G_PENDING
                                                 ,p_processing_mode_code        =>  G_BATCH
                                                 ,p_last_update_date            =>  SYSDATE
                                                 ,p_processing_request_id       =>  NULL
                                                 ,p_validation_flag             =>  'Y'
                                                 ,p_attribute9                  =>  lt_errored_asn(i).attribute9
                                                 ,p_request_id                  =>  fnd_global.conc_request_id
                                                 ,p_item_num                    =>  lc_inv_item_num
                                                 ,p_inventory_item_id           =>  ln_inventory_item_id
                                                 ,p_error_message               =>  NULL
                                                 ,p_error_status                =>  G_SUCCESS
                                       );
                        ELSIF ln_count = 1 THEN --Validate if item matches UPC Code
                            -------------------------------
                            --Item exist only in master org
                            -------------------------------
                            ----------------------
                            --Call Trade non trade
                            ----------------------
                            is_item_trade_nontrade (  p_organization_id         =>  lt_errored_asn(i).to_organization_id
                                                     ,p_inventory_item_id       =>  ln_inventory_item_id
                                                     ,p_location_id             =>  lt_errored_asn(i).location_id
                                                     ,p_documnet_num            =>  lt_errored_asn(i).document_num
                                                     ,p_item_num                =>  lt_errored_asn(i).item_num
                                                     ,p_asn_ref                 =>  lt_errored_asn(i).shipment_num
                                                     ,p_source                  =>  G_UPC
                                                     ,x_trade_nontrade          =>  lc_trade_nontrade
                                                     ,x_status                  =>  lc_status
                                                     ,x_message                 =>  lc_message
                                                   );
                            lc_attribute9 := NULL;
                            IF lc_trade_nontrade = 'Y' THEN
                                lc_attribute9 := lc_timestamp;
                            ELSE
                                lc_attribute9 := lt_errored_asn(i).attribute9;
                            END IF;
                            fnd_message.set_name('XXPTP','XX_GI_60005_UPC_NOTIN_ORG');
                            fnd_message.set_token('ITEM',lt_errored_asn(i).item_num);
                            fnd_message.set_token('ORGANIZATION',lt_errored_asn(i).to_organization_id);
                            lc_error_message:= fnd_message.get;
                    
                            reset_process_flags(  p_index                       =>  i
                                                 ,p_rowid                       =>  lt_errored_asn(i).rowid
                                                 ,p_processing_status_code      =>  lt_errored_asn(i).processing_status_code
                                                 ,p_transaction_status_code     =>  lt_errored_asn(i).transaction_status_code
                                                 ,p_processing_mode_code        =>  lt_errored_asn(i).processing_mode_code
                                                 ,p_last_update_date            =>  lt_errored_asn(i).last_update_date
                                                 ,p_processing_request_id       =>  lt_errored_asn(i).processing_request_id
                                                 ,p_validation_flag             =>  lt_errored_asn(i).validation_flag
                                                 ,p_attribute9                  =>  lc_attribute9
                                                 ,p_request_id                  =>  fnd_global.conc_request_id
                                                 ,p_item_num                    =>  lt_errored_asn(i).item_num
                                                 ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                                 ,p_error_message               =>  lc_error_message
                                                 ,p_error_status                =>  G_FAILED
                                               );
                            IF lc_status = G_ERROR_STATUS THEN
                                RAISE EX_TRANSACTION;
                            END IF;
                        ELSIF ln_count =0  THEN--Validate if item matches UPC Code
                            -----------------------------------------------------------
                            --Item is not a UPC Code. Validate if item matches VPC Code
                            -----------------------------------------------------------
                            vpc_validation(  p_organization_id         =>  lt_errored_asn(i).to_organization_id
                                            ,p_item_num                =>  lt_errored_asn(i).item_num
                                            ,p_vendor_id               =>  lt_errored_asn(i).vendor_id
                                            ,x_inv_item_num            =>  lc_inv_item_num
                                            ,x_inventory_item_id       =>  ln_inventory_item_id
                                            ,x_primary_uom_code        =>  lc_primary_uom_code
                                            ,x_count                   =>  ln_count
                                            ,x_status                  =>  lc_status
                                            ,x_message                 =>  lc_message
                                          );
                             IF lc_status = G_ERROR_STATUS THEN
                                 RAISE EX_TRANSACTION;
                             ELSE --lc_status = 'E (vpc validation)
                                 IF ln_count=2 THEN --Validate if item matches VPC Code
                                     ---------------------------------------------
                                     --Item exist in both master and receiving org
                                     ---------------------------------------------
                                     reset_process_flags(  p_index                       =>  i
                                                          ,p_rowid                       =>  lt_errored_asn(i).rowid
                                                          ,p_processing_status_code      =>  G_PENDING
                                                          ,p_transaction_status_code     =>  G_PENDING
                                                          ,p_processing_mode_code        =>  G_BATCH
                                                          ,p_last_update_date            =>  SYSDATE
                                                          ,p_processing_request_id       =>  NULL
                                                          ,p_validation_flag             =>  'Y'
                                                          ,p_attribute9                  =>  lt_errored_asn(i).attribute9
                                                          ,p_request_id                  =>  fnd_global.conc_request_id
                                                          ,p_item_num                    =>  lc_inv_item_num
                                                          ,p_inventory_item_id           =>  ln_inventory_item_id
                                                          ,p_error_message               =>  NULL
                                                          ,p_error_status                => G_SUCCESS
                                       );
                                 ELSIF ln_count=1 THEN--Validate if item matches VPC Code
                                     -------------------------------
                                     --Item exist only in master org
                                     -------------------------------
                                     ----------------------
                                     --Call Trade non trade
                                     ----------------------
                                     is_item_trade_nontrade (  p_organization_id         =>  lt_errored_asn(i).to_organization_id
                                                              ,p_inventory_item_id       =>  ln_inventory_item_id
                                                              ,p_location_id             =>  lt_errored_asn(i).location_id
                                                              ,p_documnet_num            =>  lt_errored_asn(i).document_num
                                                              ,p_item_num                =>  lt_errored_asn(i).item_num
                                                              ,p_asn_ref                 =>  lt_errored_asn(i).shipment_num
                                                              ,p_source                  =>  G_VPC
                                                              ,x_trade_nontrade          =>  lc_trade_nontrade
                                                              ,x_status                  =>  lc_status
                                                              ,x_message                 =>  lc_message
                                                            );
                                     lc_attribute9 := NULL;
                                     IF lc_trade_nontrade = 'Y' THEN
                                         lc_attribute9 := lc_timestamp;
                                     ELSE
                                         lc_attribute9 := lt_errored_asn(i).attribute9;
                                     END IF;

                                     fnd_message.set_name('XXPTP','XX_GI_60006_VPC_NOTIN_ORG');
                                     fnd_message.set_token('ITEM',lt_errored_asn(i).item_num);
                                     fnd_message.set_token('ORGANIZATION',lt_errored_asn(i).to_organization_id);
                                     lc_error_message:= fnd_message.get;
                                     
                                     reset_process_flags(  p_index                       =>  i
                                                          ,p_rowid                       =>  lt_errored_asn(i).rowid
                                                          ,p_processing_status_code      =>  lt_errored_asn(i).processing_status_code
                                                          ,p_transaction_status_code     =>  lt_errored_asn(i).transaction_status_code
                                                          ,p_processing_mode_code        =>  lt_errored_asn(i).processing_mode_code
                                                          ,p_last_update_date            =>  lt_errored_asn(i).last_update_date
                                                          ,p_processing_request_id       =>  lt_errored_asn(i).processing_request_id
                                                          ,p_validation_flag             =>  lt_errored_asn(i).validation_flag
                                                          ,p_attribute9                  =>  lc_attribute9
                                                          ,p_request_id                  =>  fnd_global.conc_request_id
                                                          ,p_item_num                    =>  lt_errored_asn(i).item_num
                                                          ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                                          ,p_error_message               =>  lc_error_message
                                                          ,p_error_status                =>  G_FAILED
                                       );
                                     IF lc_status = G_ERROR_STATUS THEN
                                         RAISE EX_TRANSACTION;
                                     END IF;
                                 ELSIF ln_count=0 THEN--Validate if item matches VPC Code
                                     ------------------------------------------------------
                                     --Validate if ASN Item exist in Master Org and rec org
                                     ------------------------------------------------------
                                     item_in_master_and_recv(  p_organization_id         =>  lt_errored_asn(i).to_organization_id
                                                              ,p_item_num                =>  lt_errored_asn(i).item_num
                                                              ,x_inventory_item_id       =>  ln_inventory_item_id
                                                              ,x_primary_uom_code        =>  lc_primary_uom_code
                                                              ,x_item_description        =>  lc_item_description
                                                              ,x_count                   =>  ln_count
                                                              ,x_status                  =>  lc_status
                                                              ,x_message                 =>  lc_message
                                                            );
                                     IF lc_status = G_ERROR_STATUS THEN
                                         RAISE EX_TRANSACTION;
                                     ELSE --lc_status = G_ERROR_STATUS (master and receiving)
                                         IF ln_count=2 THEN --Validate if ASN Item exist in Master Org and rec org
                                             ---------------------------------------------
                                             --Item exist in both Master and receiving Org
                                             ---------------------------------------------
                                             reset_process_flags(  p_index                       =>  i
                                                                  ,p_rowid                       =>  lt_errored_asn(i).rowid
                                                                  ,p_processing_status_code      =>  lt_errored_asn(i).processing_status_code
                                                                  ,p_transaction_status_code     =>  lt_errored_asn(i).transaction_status_code
                                                                  ,p_processing_mode_code        =>  lt_errored_asn(i).processing_mode_code
                                                                  ,p_last_update_date            =>  lt_errored_asn(i).last_update_date
                                                                  ,p_processing_request_id       =>  lt_errored_asn(i).processing_request_id
                                                                  ,p_validation_flag             =>  lt_errored_asn(i).validation_flag
                                                                  ,p_attribute9                  =>  lt_errored_asn(i).attribute9
                                                                  ,p_request_id                  =>  fnd_global.conc_request_id
                                                                  ,p_item_num                    =>  lt_errored_asn(i).item_num
                                                                  ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                                                  ,p_error_message               =>  NULL
                                                                  ,p_error_status                =>  G_SUCCESS
                                                                );
                                             ---------------------
                                             --Derive price for PO
                                             ---------------------
                                             XX_GI_MISSHIP_COMM_PKG.PO_GET_ITEM_PRICE(  p_vendor_id          =>  lt_errored_asn(i).vendor_id
                                                                                       ,p_item_id            =>  ln_inventory_item_id
                                                                                       ,p_order_qty          =>  lt_errored_asn(i).quantity
                                                                                       ,p_vendor_site_id     =>  lt_errored_asn(i).vendor_site_id
                                                                                       ,x_item_cost          =>  lc_item_cost
                                                                                       ,x_return_message     =>  lc_message
                                                                                     );
                                             IF lc_item_cost = -1 OR lc_item_cost IS NULL THEN
                                                 RAISE EX_TRANSACTION;
                                             ELSE                                         
                                                 ---------------------------------------
                                                 --Add line to lt_po_details Plsql table
                                                 ---------------------------------------
                                                 ln_po_ix := ln_po_ix + 1;
                                                 lt_po_details(ln_po_ix).header_po_number          :=  lt_errored_asn(i).document_num;
                                                 lt_po_details(ln_po_ix).header_vendor_id          :=  lt_errored_asn(i).vendor_id;
                                                 lt_po_details(ln_po_ix).header_vendor_site_id     :=  lt_errored_asn(i).vendor_site_id;
                                                 lt_po_details(ln_po_ix).line_item                 :=  lt_errored_asn(i).item_num;
                                                 lt_po_details(ln_po_ix).item_description          :=  lc_item_description;
                                                 lt_po_details(ln_po_ix).uom_code                  :=  lc_primary_uom_code;
                                                 lt_po_details(ln_po_ix).org_id                    :=  lt_errored_asn(i).org_id;
                                                 lt_po_details(ln_po_ix).po_header_id              :=  lt_errored_asn(i).po_header_id;
                                                 lt_po_details(ln_po_ix).inv_item_id               :=  ln_inventory_item_id;
                                                 lt_po_details(ln_po_ix).line_quantity             :=  lt_errored_asn(i).quantity;
                                                 lt_po_details(ln_po_ix).line_unit_price           :=  lc_item_cost;
                                                 lt_po_details(ln_po_ix).line_ship_to_org_id       :=  lt_errored_asn(i).to_organization_id;
                                                 lt_po_details(ln_po_ix).line_ship_to_location_id  :=  lt_errored_asn(i).location_id;
                                                 lt_po_details(ln_po_ix).rowid_reference           :=  lt_errored_asn(i).rowid;
                                                 
                                             END IF;
                                         ELSIF ln_count=1 THEN --Validate if ASN Item exist in Master Org and rec org
                                             -------------------------------
                                             --Item exist only in master Org
                                             -------------------------------
                                             ----------------------
                                             --Call Trade non trade
                                             ----------------------
                                             is_item_trade_nontrade (  p_organization_id         =>  lt_errored_asn(i).to_organization_id
                                                                      ,p_inventory_item_id       =>  ln_inventory_item_id
                                                                      ,p_location_id             =>  lt_errored_asn(i).location_id
                                                                      ,p_documnet_num            =>  lt_errored_asn(i).document_num
                                                                      ,p_item_num                =>  lt_errored_asn(i).item_num
                                                                      ,p_asn_ref                 =>  lt_errored_asn(i).shipment_num
                                                                      ,p_source                  =>  G_MASTER
                                                                      ,x_trade_nontrade          =>  lc_trade_nontrade
                                                                      ,x_status                  =>  lc_status
                                                                      ,x_message                 =>  lc_message
                                                                    );
                                             lc_attribute9 := NULL;
                                             IF lc_trade_nontrade = 'Y' THEN
                                                 lc_attribute9 := lc_timestamp;
                                             ELSE
                                                 lc_attribute9 := lt_errored_asn(i).attribute9;
                                             END IF;
                                             fnd_message.set_name('XXPTP','XX_GI_60002_ITEM_NOT_IN_ORG');
                                             fnd_message.set_token('ITEM',lt_errored_asn(i).item_num);
                                             fnd_message.set_token('ORGANIZATION',lt_errored_asn(i).to_organization_id);
                                             lc_error_message:= fnd_message.get;                                             
                                             reset_process_flags(  p_index                       =>  i
                                                                  ,p_rowid                       =>  lt_errored_asn(i).rowid
                                                                  ,p_processing_status_code      =>  lt_errored_asn(i).processing_status_code
                                                                  ,p_transaction_status_code     =>  lt_errored_asn(i).transaction_status_code
                                                                  ,p_processing_mode_code        =>  lt_errored_asn(i).processing_mode_code
                                                                  ,p_last_update_date            =>  lt_errored_asn(i).last_update_date
                                                                  ,p_processing_request_id       =>  lt_errored_asn(i).processing_request_id
                                                                  ,p_validation_flag             =>  lt_errored_asn(i).validation_flag
                                                                  ,p_attribute9                  =>  lc_attribute9
                                                                  ,p_request_id                  =>  fnd_global.conc_request_id
                                                                  ,p_item_num                    =>  lt_errored_asn(i).item_num
                                                                  ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                                                  ,p_error_message               =>  lc_error_message
                                                                  ,p_error_status                =>  G_FAILED
                                                                );
                                             IF lc_status = G_ERROR_STATUS THEN
                                                 RAISE EX_TRANSACTION;
                                             END IF;
                                         ELSIF ln_count=0 THEN--Validate item in master and receiving org
                                             --------------------------------------------------------
                                             --Store the items in PLSQL table to send the notfication
                                             --------------------------------------------------------
                                             ln_item_ix := ln_item_ix + 1;
                                             gt_item_details(ln_item_ix).loc          :=  lt_errored_asn(i).location_id;
                                             gt_item_details(ln_item_ix).po_number    :=  lt_errored_asn(i).document_num;
                                             gt_item_details(ln_item_ix).sku          :=  lt_errored_asn(i).item_num;
                                             gt_item_details(ln_item_ix).upc_vpc      :=  null;
                                             gt_item_details(ln_item_ix).asnref       :=  null;
                                             gt_item_details(ln_item_ix).item_type    :=  G_TRADE;

                                             ---------------------------------------------------------------
                                             --Item does not exist in master Org, Mark RTI Line for Deletion
                                             ---------------------------------------------------------------
                                             fnd_message.set_name('XXPTP','XX_GI_60007_ITEM_NOTIN_MAS');
                                             fnd_message.set_token('ITEM',lt_errored_asn(i).item_num);
                                             lc_error_message:= fnd_message.get;
                                             reset_process_flags(  p_index                       =>  i
                                                                  ,p_rowid                       =>  lt_errored_asn(i).rowid
                                                                  ,p_processing_status_code      =>  G_XX346DELETE
                                                                  ,p_transaction_status_code     =>  lt_errored_asn(i).transaction_status_code
                                                                  ,p_processing_mode_code        =>  lt_errored_asn(i).processing_mode_code
                                                                  ,p_last_update_date            =>  lt_errored_asn(i).last_update_date
                                                                  ,p_processing_request_id       =>  lt_errored_asn(i).processing_request_id
                                                                  ,p_validation_flag             =>  lt_errored_asn(i).validation_flag
                                                                  ,p_attribute9                  =>  lt_errored_asn(i).attribute9
                                                                  ,p_request_id                  =>  fnd_global.conc_request_id
                                                                  ,p_item_num                    =>  lt_errored_asn(i).item_num
                                                                  ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                                                  ,p_error_message               =>  lc_error_message
                                                                  ,p_error_status                =>  G_FAILED
                                                                );
                                         END IF;--Validate item in master and receiving org
                                     END IF; --lc_status = 'E' (Master and Rec Org)
                                 END IF;--Validate if item matches VPC Code
                             END IF;-- lc_status = 'E' (VPC Validation)
                        END IF;--Validate if item matches UPC Code
                    END IF;--lc_status = 'E' (UPC VAlidation)
                END IF;--x_line_id IS NOT NULL AND x_authorization_status ='APPROVED'
            END IF;--lc_status = 'E'
        EXCEPTION
        WHEN EX_TRANSACTION THEN
            display_log(lc_message);
            reset_process_flags(  p_index                       =>  i
                                 ,p_rowid                       =>  lt_errored_asn(i).rowid
                                 ,p_processing_status_code      =>  lt_errored_asn(i).processing_status_code
                                 ,p_transaction_status_code     =>  lt_errored_asn(i).transaction_status_code
                                 ,p_processing_mode_code        =>  lt_errored_asn(i).processing_mode_code
                                 ,p_last_update_date            =>  lt_errored_asn(i).last_update_date
                                 ,p_processing_request_id       =>  lt_errored_asn(i).processing_request_id
                                 ,p_validation_flag             =>  lt_errored_asn(i).validation_flag
                                 ,p_attribute9                  =>  lt_errored_asn(i).attribute9
                                 ,p_request_id                  =>  fnd_global.conc_request_id
                                 ,p_item_num                    =>  lt_errored_asn(i).item_num
                                 ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                 ,p_error_message               =>  lc_message
                                 ,p_error_status                =>  G_FAILED
                               );
            XX_COM_ERROR_LOG_PUB.log_error( p_program_type            =>  G_PROGRAM_TYPE
                                           ,p_program_name            =>  G_PROGRAM_NAME
                                           ,p_module_name             =>  G_MODULE_NAME
                                           ,p_error_message           =>  lc_message
                                           ,p_notify_flag             =>  'Y'
                                          );                  
        WHEN OTHERS THEN
            display_log(sqlerrm);
            reset_process_flags(  p_index                       =>  i
                                  ,p_rowid                       =>  lt_errored_asn(i).rowid
                                  ,p_processing_status_code      =>  lt_errored_asn(i).processing_status_code
                                  ,p_transaction_status_code     =>  lt_errored_asn(i).transaction_status_code
                                  ,p_processing_mode_code        =>  lt_errored_asn(i).processing_mode_code
                                  ,p_last_update_date            =>  lt_errored_asn(i).last_update_date
                                  ,p_processing_request_id       =>  lt_errored_asn(i).processing_request_id
                                  ,p_validation_flag             =>  lt_errored_asn(i).validation_flag
                                  ,p_attribute9                  =>  lt_errored_asn(i).attribute9
                                  ,p_request_id                  =>  fnd_global.conc_request_id
                                  ,p_item_num                    =>  lt_errored_asn(i).item_num
                                  ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                  ,p_error_message               =>  SQLERRM
                                  ,p_error_status                =>  G_FAILED
                                );
             XX_COM_ERROR_LOG_PUB.log_error( p_program_type            =>  G_PROGRAM_TYPE
                                            ,p_program_name            =>  G_PROGRAM_NAME
                                            ,p_module_name             =>  G_MODULE_NAME
                                            ,p_error_message           =>  lc_message
                                            ,p_notify_flag             =>  'Y'
                                           );
        END;
        END LOOP;
    ELSE--lt_errored_asn.COUNT <> 0
        display_log('No errored records found in RTI');
    END IF;--lt_errored_asn.COUNT <> 0

    --------------------------------------
    --Call the procedure to add line to PO
    --------------------------------------
    IF lt_po_details.COUNT <> 0 THEN
    display_log('XX_GI_MISSHIP_COMM_PKG.CREATE_PO_LINE');
        XX_GI_MISSHIP_COMM_PKG.CREATE_PO_LINE (
                                                p_add_po_line_tbl   =>  lt_po_details
                                               ,x_return_status     =>  lc_status
                                               ,x_return_message    =>  lc_message
                                              );
        IF lc_status = G_ERROR_STATUS THEN
            display_log ('XX_GI_MISSHIP_COMM_PKG.CREATE_PO_LINE API Failed with Error '||lc_message);
        ELSE
            display_log ('XX_GI_MISSHIP_COMM_PKG.CREATE_PO_LINE API Success');
            FOR  i in lt_errored_asn.FIRST .. lt_errored_asn.LAST
            LOOP
                FOR j IN lt_po_details.FIRST .. lt_po_details.LAST
                LOOP
                    IF lt_errored_asn(i).rowid = lt_po_details(j).rowid_reference THEN
                        IF lt_po_details(j).error_status = G_ERROR_STATUS THEN
                            reset_process_flags(  p_index                       =>  i
                                                 ,p_rowid                       =>  lt_errored_asn(i).rowid
                                                 ,p_processing_status_code      =>  lt_errored_asn(i).processing_status_code
                                                 ,p_transaction_status_code     =>  lt_errored_asn(i).transaction_status_code
                                                 ,p_processing_mode_code        =>  lt_errored_asn(i).processing_mode_code
                                                 ,p_last_update_date            =>  lt_errored_asn(i).last_update_date
                                                 ,p_processing_request_id       =>  lt_errored_asn(i).processing_request_id
                                                 ,p_validation_flag             =>  lt_errored_asn(i).validation_flag
                                                 ,p_attribute9                  =>  lt_errored_asn(i).attribute9
                                                 ,p_request_id                  =>  fnd_global.conc_request_id
                                                 ,p_item_num                    =>  lt_errored_asn(i).item_num
                                                 ,p_inventory_item_id           =>  lt_errored_asn(i).item_id
                                                 ,p_error_message               =>  lt_po_details(j).error_message
                                                 ,p_error_status                =>  G_FAILED
                                               );
                        ELSE
                            reset_process_flags(  p_index                       =>  i
                                                 ,p_rowid                       =>  lt_errored_asn(i).rowid
                                                 ,p_processing_status_code      =>  G_PENDING
                                                 ,p_transaction_status_code     =>  G_PENDING
                                                 ,p_processing_mode_code        =>  G_BATCH
                                                 ,p_last_update_date            =>  SYSDATE
                                                 ,p_processing_request_id       =>  NULL
                                                 ,p_validation_flag             =>  'Y'
                                                 ,p_attribute9                  =>  lt_errored_asn(i).attribute9
                                                 ,p_request_id                  =>  fnd_global.conc_request_id
                                                 ,p_item_num                    =>  lc_inv_item_num
                                                 ,p_inventory_item_id           =>  ln_inventory_item_id
                                                 ,p_error_message               =>  NULL
                                                 ,p_error_status                =>  G_SUCCESS
                                               );
                        END IF;--lt_po_details(j).error_message = 'FAILED'
                        EXIT;
                    END IF;--lt_errored_asn(i).rowid = lt_po_details(j).rowid
                END LOOP;
            END LOOP;   
        END IF;
    END IF;

    -----------------------------------------
    --Call the procedure to send notification
    -----------------------------------------
    IF gt_item_details.COUNT <> 0 THEN
    display_log('XX_GI_MISSHIP_COMM_PKG.SEND_NOTIFICATION');
        XX_GI_MISSHIP_COMM_PKG.SEND_NOTIFICATION (
                                                   p_item_details      =>  gt_item_details
                                                  ,x_return_status     =>  lc_status
                                                  ,x_return_message    =>  lc_message
                                                 );
    END IF;

    -----------------------------------------------------
    --Bulk update processing statuses for all the records
    -----------------------------------------------------
    FORALL i IN lt_errored_asn.FIRST .. lt_errored_asn.LAST
    UPDATE rcv_transactions_interface RTI
    SET    RTI.processing_status_code        =  gt_processing_status_code(i)
          ,RTI.transaction_status_code       =  gt_transaction_status_code(i)
          ,RTI.processing_mode_code          =  gt_processing_mode_code(i)
          ,RTI.validation_flag               =  gt_validation_flag(i)
          ,RTI.processing_request_id         =  gt_processing_request_id(i)
          ,RTI.last_update_date              =  gt_last_update_date(i)
          ,RTI.item_num                      =  gt_item_num(i)
          ,RTI.attribute9                    =  gt_attribute9(i)
          ,RTI.request_id                    =  gt_request_id(i)
          ,RTI.item_id                       =  gt_inventory_item_id(i)
   WHERE   RTI.ROWID                         =  gt_rowid(i);

    ----------------------------------------------------------------------------
    --Delete all the records from RTI for which item do not exist in item master
    ----------------------------------------------------------------------------
    DELETE FROM  rcv_transactions_interface
    WHERE processing_status_code = G_XX346DELETE;

    --------------
    --Print Output
    --------------
    ln_failure_count := 0;
    ln_success_count := 0;
    IF lt_errored_asn.COUNT <>0
    THEN
        display_out(RPAD('Trans_id',15,' ')||RPAD('loc',15,' ')||RPAD('PO Number',15,' ')||RPAD('SKU',15,' ')||RPAD('ASN Ref',15,' ')||RPAD('Qty',15,' ')||RPAD('Processed',15,' ')||RPAD('Failed reason if any',30,' '));
        FOR  i in lt_errored_asn.FIRST..lt_errored_asn.LAST
        LOOP
            display_out(RPAD(lt_errored_asn(i).interface_transaction_id,15,' ') || RPAD(NVL(TO_CHAR(lt_errored_asn(i).location_id),' '),15,' ') || RPAD(NVL(lt_errored_asn(i).document_num,' '),15,' ') || RPAD(NVL(lt_errored_asn(i).item_num,' '),15,' ') ||RPAD(NVL(lt_errored_asn(i).shipment_num,' '),15,' ') || RPAD(NVL(TO_CHAR(lt_errored_asn(i).quantity),' '),15,' ')|| RPAD(NVL(gt_error_status(i),' '),15,' ')|| RPAD(NVL(gt_error_message(i),' '),100,' '));
            IF    gt_error_status(i) = G_SUCCESS THEN
                ln_success_count := ln_success_count+1;
            ELSIF gt_error_status(i) = G_FAILED THEN
                ln_failure_count := ln_failure_count+1;
            END IF;
        END LOOP;
    END IF;
    ln_total_count :=  lt_errored_asn.COUNT; 
    
    display_out('');
    display_out('=================================================================================================================================================');
    display_out('');
    display_out(RPAD('Office Depot',70,' ')||'Date: '|| SYSDATE);
    display_out(LPAD('OD GI ASN Validation',50,' '));
        
    display_out('No of records processed        :'||ln_total_count);
    display_out('No of records validation passed:  '||ln_success_count);
    display_out('No of records validation failed:  '||ln_failure_count);
    COMMIT;
EXCEPTION
    WHEN EX_MISSING_SETUP THEN
        lc_message := 'Required setups are missing, Profile options are not configured OR Master Organization is not setup.';
        display_log(lc_message);
        XX_COM_ERROR_LOG_PUB.log_error( p_program_type            =>  G_PROGRAM_TYPE
                                       ,p_program_name            =>  G_PROGRAM_NAME
                                       ,p_module_name             =>  G_MODULE_NAME
                                       ,p_error_message           =>  lc_message
                                       ,p_notify_flag             =>  'Y'
                                      );
    WHEN OTHERS THEN
        lc_message := 'Unhandled Exception in VALIDATE_SKU_ASN_PROC '||SQLERRM ;
         display_log(lc_message);
         XX_COM_ERROR_LOG_PUB.log_error( p_program_type            =>  G_PROGRAM_TYPE
                                        ,p_program_name            =>  G_PROGRAM_NAME
                                        ,p_module_name             =>  G_MODULE_NAME
                                        ,p_error_message           =>  lc_message
                                        ,p_notify_flag             =>  'Y'
                                       );

END validate_sku_asn_proc;

END XX_GI_MISSHIP_ASN_PKG;
/

SHOW ERRORS
--EXIT;
