CREATE OR REPLACE PACKAGE BODY APPS.por_custom_pkg
AS
/* $Header: PORCUSTB.pls 120.3.12020000.2 2014/08/14 03:28:51 fenyan ship $ */
/*********************************************************************************************************************
* Package Name  : POR_CUSTOM_PKG   Standard Hook Package                                                              *
*                                                                                                                     *
* Procedure Name                   Description                                     Called From                       *
* ---------------                 ----------------------------                  --------------------------        *
*  1.CUSTOM_DEFAULT_REQ_HEADER    Add custom defaulting logic for all the        CustomDefaultingLogic method in      *
*                                 attributes on a requisition header.            CustomReqHeaderHelper                *
* 2. CUSTOM_VALIDATE_REQ_HEADER  Validation of attributes on Requisition Header                                       *
*                                                                                                                     *
* 3. CUSTOM_DEFAULT_REQ_LINE      Add custom defaulting logic for all the       CustomDefaultingLogic method in       *
*                                attributes on a requision Line                CustomReqLineHelper                    *
* 4. CUSTOM_VALIDATE_REQ_LINE    Validation of attributes on Requisition Lines                                        *
*                                                                                                                     *
* 5. CUSTOM_DEFAULT_REQ_DIST      Add custom defaulting logic for all the       CustomDefaultingLogic method in       *
*                                 attributes on a requisition header            CustomReqDistHelper                   *                                                                                                                    *
* 6. CUSTOM_VALIDATE_REQ_DIST     Validation of attributes on Requisition Distributions                               *
*                                                                                                                     *
* 7. CUSTOM_UPDATE_CHARGE_ACCOUNT  Handle updates to charge accounts                                                  *
* 8. CUSTOM_RCO_REQAPPR_TOL_CHECK  implement a hook for existing customizations.                                      *                                                          
* 9. CUSTOM_DEFAULT_REQ_DIST       Made changes for buy from ourselvs project                                         *
*
* Tables Accessed :                                                                                                   *
* -----------------------
                                      *
*  XX_ICX_CAT_ATTS_BY_ORG CATS                                                                                        *
*                                                                                                                     *
* Change History                                                                                                      *
* -----------------                                                                                                   *
* Version         Date              Author              Description                                                   *
* ---------      -------------     ---------------     -----------------------------                                  *
* 1.0            05-June-2013      Sravanthi Surya     Standard Hook package Retrofitted for R12 upgrade              *
* 1.1            27-May-2015       Madhu Bolli         Standard Hook package Retrofitted from PORCUSTB.pls 120.2.12010000.3 *
* 1.2            28-Jul-2016       Radhika Patnala     Standard Hook package Retrofitted from PORCUSTB.pls  120.3.12020000.2 *
* 1.3           10-JUL-2017        Arun Gannarapu      Made changes for CPD project                                    * 
* 1.4           12-DEC-2017        Arun Gannarapu      Made changes for Jan-san                                        *
**********************************************************************************************************************/

-- Customize this procedure to add custom defaulting logic for all the
-- attributes on a requisition header.
-- This is called when a new requisition gets created.
-- The attribute id's are passed as IN OUT NOCOPY parameters to this procedure and
-- can be modified to reflect any custom defaulting logic.

PROCEDURE CUSTOM_DEFAULT_REQ_HEADER (
    req_header_id            IN NUMBER,    -- 1
    old_req_header_id        IN NUMBER,   -- 2
    req_num                  IN VARCHAR2, -- 3
    preparer_id              IN NUMBER, -- 4
    x_req_type                 IN OUT NOCOPY  VARCHAR2, -- 5
    x_emergency_po_num         IN OUT NOCOPY  VARCHAR2, -- 6
    x_approval_status_code     IN OUT NOCOPY  VARCHAR2, -- 7
    x_cancel_flag              IN OUT NOCOPY  VARCHAR2, -- 8
    x_closed_code              IN OUT NOCOPY  VARCHAR2, -- 9
    x_org_id                   IN OUT NOCOPY  NUMBER, -- 10
    x_wf_item_type             IN OUT NOCOPY  VARCHAR2, -- 11
    x_wf_item_key              IN OUT NOCOPY  VARCHAR2, -- 12
    x_pcard_id                 IN OUT NOCOPY  NUMBER, -- 13
    x_attribute1               IN OUT NOCOPY  VARCHAR2, -- 14
    x_attribute2               IN OUT NOCOPY  VARCHAR2, -- 15
    x_attribute3               IN OUT NOCOPY  VARCHAR2, -- 16
    x_attribute4               IN OUT NOCOPY  VARCHAR2, -- 17
    x_attribute5               IN OUT NOCOPY  VARCHAR2, -- 18
    x_attribute6               IN OUT NOCOPY  VARCHAR2, -- 19
    x_attribute7               IN OUT NOCOPY  VARCHAR2, -- 20
    x_attribute8               IN OUT NOCOPY  VARCHAR2, -- 21
    x_attribute9               IN OUT NOCOPY  VARCHAR2, -- 22
    x_attribute10              IN OUT NOCOPY  VARCHAR2, -- 23
    x_attribute11              IN OUT NOCOPY  VARCHAR2, -- 24
    x_attribute12              IN OUT NOCOPY  VARCHAR2, -- 25
    x_attribute13              IN OUT NOCOPY  VARCHAR2, -- 26
    x_attribute14              IN OUT NOCOPY  VARCHAR2, -- 27
    x_attribute15              IN OUT NOCOPY  VARCHAR2, -- 28
    x_return_code                OUT NOCOPY NUMBER, -- 29
    x_error_msg                  OUT NOCOPY VARCHAR2 -- 30
  )
  is
BEGIN
   X_RETURN_CODE:=0;
   X_ERROR_MSG:='';
END CUSTOM_DEFAULT_REQ_HEADER;

-- Added By Sravanthi on 6/5/2013
-- Custom Procedure - standard error message for E0978 -- Bushrod
   FUNCTION GET_MESSAGE(
      p_message_name   IN   VARCHAR2
    , p_token1_name    IN   VARCHAR2 := NULL
    , p_token1_value   IN   VARCHAR2 := NULL
   )
      RETURN VARCHAR2
   IS
   BEGIN
      fnd_message.CLEAR;
      fnd_message.set_name( 'XXFIN', p_message_name );

      IF p_token1_name IS NOT NULL
      THEN
         fnd_message.set_token( p_token1_name, p_token1_value );
      END IF;

      RETURN fnd_message.get( );
   END;

-- Added By Sravanthi on 6/5/2013
  -- Custom Procedure - standard error logging for E0978 -- Bushrod
   PROCEDURE log_line(
      p_error_location   VARCHAR2
    , p_message          VARCHAR2
   )
   IS
   BEGIN
      xx_com_error_log_pub.log_error( p_program_type                => 'UI'
                                    , p_program_name                => 'POR_CUSTOM_PKG'
                                    , p_module_name                 => 'iPROC'
                                    , p_error_location              => p_error_location
                                    , p_error_message               => p_message
                                    , p_error_message_severity      => 'ERROR'
                                    , p_notify_flag                 => 'N'
                                    );
--    COMMIT;  -- This autonomous transaction commits itself... should not commit here!
   END log_line;

-- Customize this procedure to add logic for validation of the attribute values
-- on a requisition header. This  would be any custom validation, that would
-- be in addition to all the validations done for a requisition header.
-- The return_msg and the error_code can be used to return the results of
-- the validation
-- The return code can be used to indicate on which tab the error message
-- needs to be displayed on the Edit Lines page
-- If the result code is 1, error is displayed on the Delivery tab
-- If the result code is 2, error is displayed on the Billing tab
-- If the result code is 3, error is displayed on the Accounts tab

PROCEDURE CUSTOM_VALIDATE_REQ_HEADER (
    req_header_id            IN  NUMBER, -- 1
    req_num                  IN  VARCHAR2, -- 2
    preparer_id           IN  NUMBER,    -- 3
    req_type                 IN  VARCHAR2, -- 4
    emergency_po_num         IN  VARCHAR2, -- 5
    approval_status_code     IN  VARCHAR2, -- 6
    cancel_flag              IN  VARCHAR2, -- 7
    closed_code              IN  VARCHAR2, -- 8
    org_id                   IN  NUMBER, -- 9
    wf_item_type             IN  VARCHAR2, -- 10
    wf_item_key              IN  VARCHAR2, -- 11
    pcard_id                 IN  NUMBER, -- 12
    attribute1               IN  VARCHAR2, -- 13
    attribute2               IN  VARCHAR2, -- 14
    attribute3               IN  VARCHAR2, -- 15
    attribute4               IN  VARCHAR2, -- 16
    attribute5               IN  VARCHAR2, -- 17
    attribute6               IN  VARCHAR2, -- 18
    attribute7               IN  VARCHAR2, -- 19
    attribute8               IN  VARCHAR2, -- 20
    attribute9               IN  VARCHAR2, -- 21
    attribute10              IN  VARCHAR2, -- 22
    attribute11              IN  VARCHAR2, -- 23
    attribute12              IN  VARCHAR2, -- 24
    attribute13              IN  VARCHAR2, -- 25
    attribute14              IN  VARCHAR2, -- 26
    attribute15              IN  VARCHAR2, -- 27
    x_return_code                OUT NOCOPY NUMBER, -- 28
    x_error_msg                  OUT NOCOPY VARCHAR2 -- 29
  )
  IS
BEGIN
   X_RETURN_CODE:=0;
   X_ERROR_MSG:='';
END CUSTOM_VALIDATE_REQ_HEADER;


-- Customize this procedure to add custom defaulting logic for all the
-- attributes on a requisition line.
-- This is called when a new line gets added to the requisition.
-- The attribute id's are passed as IN OUT NOCOPY parameters to this procedure and
-- can be modified to reflect any custom defaulting logic.
-- The values corresponding to the id's are recalculated in the calling ReqLine
-- Java class

PROCEDURE CUSTOM_DEFAULT_REQ_LINE (
-- READ ONLY data
    req_header_id            IN NUMBER,    -- 1
    req_line_id              IN NUMBER,    -- 2
    old_req_line_id          IN NUMBER,   -- 3
    line_num                 IN NUMBER,    -- 4

-- header data
    preparer_id                IN NUMBER, -- 5
    header_attribute_1         IN VARCHAR2, -- 6
    header_attribute_2         IN VARCHAR2, -- 7
    header_attribute_3         IN VARCHAR2, -- 8
    header_attribute_4         IN VARCHAR2, -- 9
    header_attribute_5         IN VARCHAR2, -- 10
    header_attribute_6         IN VARCHAR2, -- 11
    header_attribute_7         IN VARCHAR2, -- 12
    header_attribute_8         IN VARCHAR2, -- 13
    header_attribute_9         IN VARCHAR2, -- 14
    header_attribute_10        IN VARCHAR2, -- 15
    header_attribute_11        IN VARCHAR2, -- 16
    header_attribute_12        IN VARCHAR2, -- 17
    header_attribute_13        IN VARCHAR2, -- 18
    header_attribute_14        IN VARCHAR2, -- 19
    header_attribute_15        IN VARCHAR2, -- 20

-- line data: update any of the following parameters as default for line
    x_line_type_id             IN OUT NOCOPY  NUMBER, -- 21
    x_item_id                  IN OUT NOCOPY  NUMBER, -- 22
    x_item_revision            IN OUT NOCOPY  VARCHAR2, -- 23
    x_category_id              IN OUT NOCOPY  NUMBER, -- 24
    x_catalog_source           IN OUT NOCOPY  VARCHAR2, -- 25
    x_catalog_type             IN OUT NOCOPY  VARCHAR2, -- 26
    x_currency_code            IN OUT NOCOPY  VARCHAR2, -- 27
    x_currency_unit_price      IN OUT NOCOPY  NUMBER, -- 28
    x_manufacturer_name        IN OUT NOCOPY  VARCHAR2, -- 29
    x_manufacturer_part_num    IN OUT NOCOPY  VARCHAR2, -- 30
    x_deliver_to_loc_id        IN OUT NOCOPY  NUMBER, -- 31
    x_deliver_to_org_id        IN OUT NOCOPY  NUMBER, -- 32
    x_deliver_to_subinv        IN OUT NOCOPY  VARCHAR2, -- 33
    x_destination_type_code    IN OUT NOCOPY  VARCHAR2, -- 34
    x_requester_id             IN OUT NOCOPY  NUMBER, -- 35
    x_encumbered_flag          IN OUT NOCOPY  VARCHAR2, -- 36
    x_hazard_class_id          IN OUT NOCOPY  NUMBER, -- 37
    x_modified_by_buyer        IN OUT NOCOPY  VARCHAR2, -- 38
    x_need_by_date             IN OUT NOCOPY  DATE, -- 39
    x_new_supplier_flag        IN OUT NOCOPY  VARCHAR2, -- 40
    x_on_rfq_flag              IN OUT NOCOPY  VARCHAR2, -- 41
    x_org_id                   IN OUT NOCOPY  NUMBER, -- 42
    x_parent_req_line_id       IN OUT NOCOPY  NUMBER, -- 43
    x_po_line_loc_id           IN OUT NOCOPY  NUMBER, -- 44
    x_qty_cancelled            IN OUT NOCOPY  NUMBER, -- 45
    x_qty_delivered            IN OUT NOCOPY  NUMBER, -- 46
    x_qty_ordered              IN OUT NOCOPY  NUMBER, -- 47
    x_qty_received             IN OUT NOCOPY  NUMBER, -- 48
    x_rate                     IN OUT NOCOPY  NUMBER, -- 49
    x_rate_date                IN OUT NOCOPY  DATE, -- 50
    x_rate_type                IN OUT NOCOPY  VARCHAR2, -- 51
    x_rfq_required             IN OUT NOCOPY  VARCHAR2, -- 52
    x_source_type_code         IN OUT NOCOPY  VARCHAR2, -- 53
    x_spsc_code                IN OUT NOCOPY  VARCHAR2, -- 54
    x_other_category_code      IN OUT NOCOPY  VARCHAR2, -- 55
    x_suggested_buyer_id       IN OUT NOCOPY  NUMBER, -- 56
    x_source_doc_header_id     IN OUT NOCOPY  NUMBER, -- 57
    x_source_doc_line_num      IN OUT NOCOPY  NUMBER, -- 58
    x_source_doc_type_code     IN OUT NOCOPY  VARCHAR2, -- 59
    x_supplier_duns            IN OUT NOCOPY  VARCHAR2, -- 60
    x_supplier_item_num        IN OUT NOCOPY  VARCHAR2, -- 61
    x_taxable_status           IN OUT NOCOPY  VARCHAR2, -- 62
    x_unit_of_measure          IN OUT NOCOPY  VARCHAR2, -- 63
    x_unit_price               IN OUT NOCOPY  NUMBER, -- 64
    x_urgent                   IN OUT NOCOPY  VARCHAR2, -- 65
    x_supplier_contact_id      IN OUT NOCOPY  NUMBER, -- 66
    x_supplier_id              IN OUT NOCOPY  NUMBER, -- 67
    x_supplier_site_id         IN OUT NOCOPY  NUMBER, -- 68
    x_cancel_date              IN OUT NOCOPY  DATE, -- 69
    x_cancel_flag              IN OUT NOCOPY  VARCHAR2, -- 70
    x_closed_code              IN OUT NOCOPY  VARCHAR2, -- 71
    x_closed_date              IN OUT NOCOPY  DATE, -- 72
    x_auto_receive_flag        IN OUT NOCOPY  VARCHAR2, -- 73
    x_pcard_flag               IN OUT NOCOPY  VARCHAR2, -- 74
    x_attribute1               IN OUT NOCOPY  VARCHAR2, -- 75
    x_attribute2               IN OUT NOCOPY  VARCHAR2, -- 76
    x_attribute3               IN OUT NOCOPY  VARCHAR2, -- 77
    x_attribute4               IN OUT NOCOPY  VARCHAR2, -- 78
    x_attribute5               IN OUT NOCOPY  VARCHAR2, -- 79
    x_attribute6               IN OUT NOCOPY  VARCHAR2, -- 80
    x_attribute7               IN OUT NOCOPY  VARCHAR2, -- 81
    x_attribute8               IN OUT NOCOPY  VARCHAR2, -- 82
    x_attribute9               IN OUT NOCOPY  VARCHAR2, -- 83
    x_attribute10              IN OUT NOCOPY  VARCHAR2, -- 84
    x_attribute11              IN OUT NOCOPY  VARCHAR2, -- 85
    x_attribute12              IN OUT NOCOPY  VARCHAR2, -- 86
    x_attribute13              IN OUT NOCOPY  VARCHAR2, -- 87
    x_attribute14              IN OUT NOCOPY  VARCHAR2, -- 88
    x_attribute15              IN OUT NOCOPY  VARCHAR2, -- 89
    X_return_code              OUT NOCOPY     NUMBER, -- 90
    X_error_msg                OUT NOCOPY     VARCHAR2, -- 91
    x_supplierContact          IN OUT NOCOPY  VARCHAR2, -- 92
    x_supplierContactPhone     IN OUT NOCOPY  VARCHAR2, -- 93
    x_supplier                   IN OUT NOCOPY  VARCHAR2, -- 94
    x_supplierSite               IN OUT NOCOPY  VARCHAR2, -- 95
    x_taxCodeId                   IN OUT NOCOPY  NUMBER, -- 96
    x_source_org_id            IN OUT NOCOPY     NUMBER, -- 97
    x_txn_reason_code          IN OUT NOCOPY     VARCHAR2, -- 98
    x_note_to_agent            IN OUT NOCOPY     VARCHAR2, -- 99
    x_note_to_receiver         IN OUT NOCOPY     VARCHAR2, -- 100
    x_note_to_vendor           IN OUT NOCOPY VARCHAR2 -- 101
  )
  IS
      ln_category_buyer                       NUMBER;
-- As per 11i Code new variable declared for storing Buyer_Id on 6/5/2013 by Sravanthi Surya
   BEGIN
      x_return_code                        := 0;
      x_error_msg                          := '';
      -- As per 11i Code functionality added code on 6/5/2013 by Sravanthi Surya--
      -- Added for the Extension E0979 Assign Need By Date Dt 25 Jan 2007 by Pradeep R

      -- Modified on 30-Jan-2007 for the Defect 3583 Assign Need By Date Dt  by Madankumar J, Wipro Technologies
      -- removed the parameter x_deliver_to_org_id.
      xx_ipo_needbydate_proc( x_item_id
                            , x_need_by_date
                            , x_return_code
                            , x_error_msg
                            );

      -- As per 11i code for E0978-Assign Buyer To Purchase Requisition
      -- Requirement :- Buyer name is not inserted into the requisition line if the Source (source_type_code) is "INVENTORY" added the underlying code
      -- ON 6/5/2013 BY Sravanthi
      IF x_source_type_code <> 'INVENTORY'
      THEN
         BEGIN
            log_line( 'CUSTOM_DEFAULT_REQ_LINE'
                    ,    'x_source_type_code='
                      || x_source_type_code );

            SELECT buyer_id
              INTO ln_category_buyer
              FROM xx_icx_cat_atts_by_org cats
             WHERE cats.category_id = x_category_id
               AND cats.org_id = x_org_id;

            x_suggested_buyer_id                 := ln_category_buyer;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               x_suggested_buyer_id                 := NULL; -- not an error;
            WHEN OTHERS
            THEN
               BEGIN
                  x_error_msg                          :=
                        x_error_msg
                     || GET_MESSAGE( 'XX_POR_ASGN_BUYER_0000_UNKN'
                                   , 'INFO'
                                   ,    SQLERRM
                                     || ' buyer_id='
                                     || x_suggested_buyer_id
                                     || '; org='
                                     || x_org_id
                                     || '; category='
                                     || x_category_id
                                   );
                  x_return_code                        := 1;
                  log_line( 'CUSTOM_DEFAULT_REQ_LINE', x_error_msg );


               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_error_msg                          :=
                           x_error_msg
                        || ' Error Assigning Buyer in POR_CUSTOM_PKG';
                                     -- failsafe error; should not be returned
                     x_return_code                        := 1;

               END;
         END;
      END IF;
END;


-- Customize this procedure to add logic for validation of the attribute values
-- on a requisition line. This would be any custom validation, that would be
-- in addition to all the validations done for a requisition line
-- This is called whenever the requisition line gets updated and is called
-- on every page in the checkOUT NOCOPY flow.
-- The return_msg and the error_code can be used to return the results of
-- the validation
-- The return code can be used to indicate on which tab the error message
-- needs to be displayed on the Edit Lines page
-- If the result code is 1, error is displayed on the Delivery tab
-- If the result code is 2, error is displayed on the Billing tab
-- If the result code is 3, error is displayed on the Accounts tab


PROCEDURE CUSTOM_VALIDATE_REQ_LINE (
  x_req_header_id            IN  NUMBER, -- 1
    x_req_line_id              IN  NUMBER, -- 2
    x_line_num                 IN  NUMBER, -- 3


-- header data
    preparer_id                IN NUMBER, -- 4
    header_attribute_1         IN VARCHAR2, -- 5
    header_attribute_2         IN VARCHAR2, -- 6
    header_attribute_3         IN VARCHAR2, -- 7
    header_attribute_4         IN VARCHAR2, -- 8
    header_attribute_5         IN VARCHAR2, -- 9
    header_attribute_6         IN VARCHAR2, -- 10
    header_attribute_7         IN VARCHAR2, -- 11
    header_attribute_8         IN VARCHAR2, -- 12
    header_attribute_9         IN VARCHAR2, -- 13
    header_attribute_10        IN VARCHAR2, -- 14
    header_attribute_11        IN VARCHAR2, -- 15
    header_attribute_12        IN VARCHAR2, -- 16
    header_attribute_13        IN VARCHAR2, -- 17
    header_attribute_14        IN VARCHAR2, -- 18
    header_attribute_15        IN VARCHAR2, -- 19

-- line data
    line_type_id             IN  NUMBER, -- 20
    item_id                  IN  NUMBER, -- 21
    item_revision            IN  VARCHAR2, -- 22
    category_id              IN  NUMBER, -- 23
    catalog_source           IN  VARCHAR2, -- 24
    catalog_type             IN  VARCHAR2, -- 25
    currency_code            IN  VARCHAR2, -- 26
    currency_unit_price      IN  NUMBER, -- 27
    manufacturer_name        IN  VARCHAR2, --28
    manufacturer_part_num    IN  VARCHAR2, -- 29
    deliver_to_loc_id        IN  NUMBER, -- 30
    deliver_to_org_id        IN  NUMBER, -- 31
    deliver_to_subinv        IN  VARCHAR2, -- 32
    destination_type_code    IN  VARCHAR2, -- 33
    requester_id             IN  NUMBER, -- 34
    encumbered_flag          IN  VARCHAR2, -- 35
    hazard_class_id          IN  NUMBER, -- 36
    modified_by_buyer        IN  VARCHAR2, -- 37
    need_by_date             IN  DATE, -- 38
    new_supplier_flag        IN  VARCHAR2, -- 39
    on_rfq_flag              IN  VARCHAR2, -- 40
    org_id                   IN  NUMBER, -- 41
    parent_req_line_id       IN  NUMBER, -- 42
    po_line_loc_id           IN  NUMBER, -- 43
    qty_cancelled            IN  NUMBER, -- 44
    qty_delivered            IN  NUMBER, -- 45
    qty_ordered              IN  NUMBER, -- 46
    qty_received             IN  NUMBER, -- 47
    rate                     IN  NUMBER, -- 48
    rate_date                IN  DATE, -- 49
    rate_type                IN  VARCHAR2, -- 50
    rfq_required             IN  VARCHAR2, -- 51
    source_type_code         IN  VARCHAR2, -- 52
    spsc_code                IN  VARCHAR2, -- 53
    other_category_code      IN  VARCHAR2, -- 54
    suggested_buyer_id       IN OUT NOCOPY NUMBER, -- 55
    source_doc_header_id     IN  NUMBER, -- 56
    source_doc_line_num      IN  NUMBER, -- 57
    source_doc_type_code     IN  VARCHAR2, -- 58
    supplier_duns            IN  VARCHAR2, -- 59
    supplier_item_num        IN  VARCHAR2, -- 60
    taxable_status           IN  VARCHAR2, -- 61
    unit_of_measure          IN  VARCHAR2, -- 62
    unit_price               IN  NUMBER, -- 63
    urgent                   IN  VARCHAR2, -- 64
    supplier_contact_id      IN  NUMBER, -- 65
    supplier_id              IN  NUMBER, -- 66
    supplier_site_id         IN  NUMBER, -- 67
    cancel_date              IN  DATE, -- 68
    cancel_flag              IN  VARCHAR2, -- 69
    closed_code              IN  VARCHAR2, -- 70
    closed_date              IN  DATE, -- 71
    auto_receive_flag        IN  VARCHAR2, -- 72
    pcard_flag               IN  VARCHAR2, -- 73
    attribute1               IN  VARCHAR2, -- 74
    attribute2               IN  VARCHAR2, -- 75
    attribute3               IN  VARCHAR2, -- 76
    attribute4               IN  VARCHAR2, -- 77
    attribute5               IN  VARCHAR2, -- 78
    attribute6               IN  VARCHAR2, -- 79
    attribute7               IN  VARCHAR2, -- 80
    attribute8               IN  VARCHAR2, -- 81
    attribute9               IN  VARCHAR2, -- 82
    attribute10              IN  VARCHAR2, -- 83
    attribute11              IN  VARCHAR2, -- 84
    attribute12              IN  VARCHAR2, -- 85
    attribute13              IN  VARCHAR2, -- 86
    attribute14              IN  VARCHAR2, -- 87
    attribute15              IN  VARCHAR2, -- 88
    x_taxCodeId               IN NUMBER,    -- 89
    x_return_code            OUT NOCOPY NUMBER, -- 90 no error
    x_error_msg              OUT NOCOPY VARCHAR2, -- 91
    x_source_org_id          IN NUMBER, -- 92
    x_txn_reason_code          IN VARCHAR2 -- 93

  )
  IS
BEGIN
   X_RETURN_CODE:=0;
   X_ERROR_MSG:='';
END;




-- Customize this procedure to add custom defaulting logic for all the
-- attributes on a requisition distribution.
-- This is called when a new distribution gets added to the requisition.
-- The attribute id's are passed as IN OUT NOCOPY parameters to this procedure and
-- can be modified to reflect any custom defaulting logic.

PROCEDURE CUSTOM_DEFAULT_REQ_DIST (
    x_distribution_id       IN NUMBER,  -- 1
    x_old_distribution_id   IN NUMBER,  -- 2
    x_code_combination_id   IN OUT NOCOPY   NUMBER, -- 3
    x_budget_account_id   IN OUT NOCOPY   NUMBER, -- 4
    x_variance_account_id   IN OUT NOCOPY   NUMBER, -- 5
    x_accrual_account_id   IN OUT NOCOPY   NUMBER, -- 6
    project_id              IN OUT NOCOPY NUMBER, -- 7
    task_id              IN OUT NOCOPY NUMBER, -- 8
    expenditure_type          IN OUT NOCOPY VARCHAR2, -- 9
    expenditure_organization_id IN OUT NOCOPY NUMBER, -- 10
    expenditure_item_date    IN OUT NOCOPY DATE, -- 11
    award_id                 IN OUT NOCOPY NUMBER, -- 12
    gl_encumbered_date         IN OUT NOCOPY DATE,    -- 13
    gl_period_name           IN OUT NOCOPY VARCHAR2, -- 14
    gl_cancelled_date        IN OUT NOCOPY DATE, -- 15
    gl_closed_date           IN OUT NOCOPY DATE,--16
    gl_date                  IN OUT NOCOPY DATE,--17
    gl_encumbered_period     IN OUT NOCOPY VARCHAR2,--18
    recovery_rate            IN OUT NOCOPY NUMBER, -- 19
    tax_recovery_override_flag IN OUT NOCOPY VARCHAR2, -- 20
    chart_of_accounts_id     IN  NUMBER, -- 21
    category_id          IN  NUMBER, -- 22
    catalog_source           IN  VARCHAR2, -- 23
    catalog_type             IN  VARCHAR2, -- 24
    destination_type_code    IN  VARCHAR2, -- 25
    deliver_to_location_id   IN  NUMBER, -- 26
    destination_organization_id IN NUMBER, -- 27
    destination_subinventory IN  VARCHAR2, -- 28
    item_id            IN  NUMBER, -- 29
    sob_id                      IN NUMBER, -- 30
    currency_code               IN VARCHAR2, -- 31
    currency_unit_price         IN NUMBER, -- 32
    manufacturer_name           IN VARCHAR2, -- 33
    manufacturer_part_num       IN VARCHAR2,-- 34
    need_by_date                IN DATE, -- 35
    new_supplier_flag           IN VARCHAR2, -- 36
    business_org_id             IN NUMBER,    -- 37
    org_id                      IN NUMBER, -- 38
    employee_id                 IN NUMBER, -- 39
    employee_org_id       IN      NUMBER,  -- 40
    default_code_combination_id IN NUMBER, -- 41
    parent_req_line_id       IN  NUMBER, -- 42
    qty_cancelled            IN  NUMBER, -- 43
    qty_delivered            IN  NUMBER, -- 44
    qty_ordered              IN  NUMBER, -- 45
    qty_received             IN  NUMBER, -- 46
    rate                     IN  NUMBER, -- 47
    rate_date                IN  DATE, -- 48
    rate_type                IN  VARCHAR2, -- 49
    source_type_code         IN  VARCHAR2, -- 50
    spsc_code                IN  VARCHAR2, -- 51
    suggested_buyer_id       IN  NUMBER, -- 52
    source_doc_header_id     IN  NUMBER, -- 53
    source_doc_line_num      IN  NUMBER, -- 54
    source_doc_type_code     IN  VARCHAR2, -- 55
    supplier_item_num        IN  VARCHAR2, -- 56
    taxable_status           IN  VARCHAR2, -- 57
    unit_of_measure          IN  VARCHAR2, -- 58
    unit_price               IN  NUMBER, -- 59
    supplier_contact_id      IN  NUMBER, -- 60
    supplier_id              IN  NUMBER, -- 61
    supplier_site_id         IN  NUMBER, -- 62
    pcard_flag               IN  VARCHAR2, -- 63
    line_type_id         IN  NUMBER, -- 64
    taxCodeId                 IN   NUMBER, -- 65
    results_billable_flag    IN VARCHAR2,-- 66
    preparer_id                IN  NUMBER, -- 67
    deliver_to_person_id    IN  NUMBER, -- 68
    po_encumberance_flag    IN  VARCHAR2, -- 69
    DATE_FORMAT        IN  VARCHAR2,    -- 70
    header_att1          IN  VARCHAR2,    -- 71
    header_att2          IN  VARCHAR2,    -- 72
    header_att3          IN  VARCHAR2,    -- 73
    header_att4          IN  VARCHAR2,    -- 74
    header_att5          IN  VARCHAR2,    -- 75
    header_att6          IN  VARCHAR2,    -- 76
    header_att7          IN  VARCHAR2,    -- 77
    header_att8          IN  VARCHAR2,    -- 78
    header_att9          IN  VARCHAR2,    -- 79
    header_att10      IN  VARCHAR2,    -- 80
    header_att11      IN  VARCHAR2,    -- 81
    header_att12      IN  VARCHAR2,    -- 82
    header_att13          IN  VARCHAR2,    -- 83
    header_att14      IN  VARCHAR2,    -- 84
    header_att15      IN  VARCHAR2,    -- 85
    line_att1          IN  VARCHAR2,    -- 86
    line_att2          IN  VARCHAR2,    -- 87
    line_att3          IN  VARCHAR2,    -- 88
    line_att4          IN  VARCHAR2,    -- 89
    line_att5          IN  VARCHAR2,    -- 90
    line_att6          IN  VARCHAR2,    -- 91
    line_att7          IN  VARCHAR2,    -- 92
    line_att8          IN  VARCHAR2,    -- 93
    line_att9          IN  VARCHAR2,    -- 94
    line_att10          IN  VARCHAR2,    -- 95
    line_att11          IN  VARCHAR2,    -- 96
    line_att12          IN  VARCHAR2,    -- 97
    line_att13          IN  VARCHAR2,    -- 98
    line_att14          IN  VARCHAR2,    -- 99
    line_att15          IN  VARCHAR2,    -- 100
    distribution_att1      IN OUT NOCOPY  VARCHAR2, -- 101
    distribution_att2      IN OUT NOCOPY  VARCHAR2, -- 102
    distribution_att3      IN OUT NOCOPY  VARCHAR2, -- 103
    distribution_att4      IN OUT NOCOPY  VARCHAR2, -- 104
    distribution_att5      IN OUT NOCOPY  VARCHAR2, -- 105
    distribution_att6      IN OUT NOCOPY  VARCHAR2, -- 106
    distribution_att7      IN OUT NOCOPY  VARCHAR2, -- 107
    distribution_att8      IN OUT NOCOPY  VARCHAR2, -- 108
    distribution_att9      IN OUT NOCOPY  VARCHAR2, -- 109
    distribution_att10      IN OUT NOCOPY  VARCHAR2, -- 110
    distribution_att11      IN OUT NOCOPY  VARCHAR2, -- 111
    distribution_att12      IN OUT NOCOPY  VARCHAR2, -- 112
    distribution_att13      IN OUT NOCOPY  VARCHAR2, -- 113
    distribution_att14      IN OUT NOCOPY  VARCHAR2, -- 114
    distribution_att15      IN OUT NOCOPY  VARCHAR2, -- 115
    result_code           OUT NOCOPY     NUMBER,  -- 116
    x_error_msg           OUT NOCOPY     VARCHAR2 -- 117
)

IS
 lc_company       gl_code_combinations.segment1%TYPE := NULL;
 lc_location      gl_code_combinations.segment1%TYPE := NULL;
 lc_lob           gl_code_combinations.segment1%TYPE := NULL;
 lc_future        gl_code_combinations.segment1%TYPE := NULL;
 lc_cc            gl_code_combinations.segment1%TYPE := NULL;
 lc_acct          gl_code_combinations.segment1%TYPE := NULL;
 lc_ic            gl_code_combinations.segment1%TYPE := NULL;
 lc_cost_center   gl_code_combinations.segment1%TYPE := NULL;
 lc_intercompany  gl_code_combinations.segment1%TYPE := NULL;
 lc_exists    NUMBER := 0;
 ln_code_combination_id  gl_code_combinations.code_combination_id%TYPE := NULL;
 lc_translation_name     xx_fin_translatedefinition.translation_name%TYPE := 'XXPO_PUNCHOUT_CONFIG';
 ln_exclude_resp_id NUMBER;
 ln_resp_id         NUMBER;
 lc_transvalues_rec xx_fin_translatevalues%ROWTYPE := NULL;
 l_req_info         per_people_v7%ROWTYPE;
 lc_return_status   varchar2(2000) := NULL;
 lc_error_msg       VARCHAR2(2000) := NULL;
 lc_subject         VARCHAR2(2000) := NULL;
 lc_mail_body       VARCHAR2(32000):= NULL;
BEGIN

  -- Added by Arun ..

  log_line( 'CUSTOM_DEFAULT_REQ_DIST','x_distribution_id'||x_distribution_id);
  log_line( 'CUSTOM_DEFAULT_REQ_DIST','destination_organization_id:'||destination_organization_id);
  log_line( 'CUSTOM_DEFAULT_REQ_DIST','Supplier ID:'||supplier_id);
  log_line( 'CUSTOM_DEFAULT_REQ_DIST','Supplier Site ID:'||supplier_site_id);
  log_line( 'CUSTOM_DEFAULT_REQ_DIST','preparer ID:'||preparer_id);
  
 BEGIN 
  SELECT xftv.*
  INTO lc_transvalues_rec
  FROM xx_fin_translatedefinition xft,
       xx_fin_translatevalues xftv,
       ap_suppliers pva, 
       ap_supplier_sites_all pvsa
    WHERE xft.translate_id    = xftv.translate_id
    AND xft.enabled_flag      = 'Y'
    AND xftv.enabled_flag     = 'Y'
    AND xft.translation_name  =  lc_translation_name
    AND xftv.source_value1    =  'CHARGE_ACCOUNT'
    AND  xftv.source_value2    =  pva.vendor_name
    AND  xftv.source_value3    =  pvsa.vendor_site_code
    AND  pva.vendor_id         =  pvsa.vendor_id
    AND  pva.vendor_id         =  supplier_id
    AND  pvsa.vendor_site_id   =  supplier_site_id;

  log_line( 'CUSTOM_DEFAULT_REQ_DIST','Exists'||lc_exists);
 EXCEPTION 
   WHEN NO_DATA_FOUND
   THEN 
    lc_transvalues_rec := null;
 END; 
  IF lc_transvalues_rec.source_value2 IS NOT NULL
  THEN 
    BEGIN
     IF lc_transvalues_rec.target_value7 IS NOT NULL
     THEN 
      SELECT responsibility_ID
      INTO ln_exclude_resp_id
      FROM fnd_responsibility_tl
      WHERE responsibility_name = lc_transvalues_rec.target_value7
      and language = 'US';
      
      ln_resp_id := fnd_profile.VALUE('RESP_ID');
      log_line('CUSTOM_DEFAULT_REQ_DIST','resp id:'|| ln_resp_id || ' Exclude resp id :'|| ln_exclude_resp_id);
   
      IF NVL(ln_resp_id,0) = NVL(ln_exclude_resp_id,1)
      THEN
        lc_exists := 0;
      ELSE 
        lc_exists := 1;      
      END IF;
     ELSE 
        lc_exists :=1; 
     END IF;  
    EXCEPTION 
      WHEN OTHERS THEN 
         lc_exists :=1;
    END;
    
  IF lc_transvalues_rec.source_value2 IS NOT NULL AND lc_exists > 0 
  THEN
    IF lc_transvalues_rec.target_value10 = 'DEST_ORG'
    THEN 
      SELECT segment1,
             segment2, --
             segment4,
             segment5, --
             segment6,
             segment7
      INTO   lc_company,
             lc_cost_center,  
             lc_location,
             lc_intercompany,
             lc_lob,
             lc_future
      FROM  mtl_parameters mp,
            gl_code_combinations gcc
      WHERE mp.organization_id = destination_organization_id
      AND mp.expense_account = gcc.code_combination_id;
      
    ELSIF lc_transvalues_rec.target_value10 = 'USER_PROFILE'
    THEN 
      SELECT segment1,
             segment2, --
             segment4,
             segment5, --
             segment6,
             segment7
      INTO   lc_company,
             lc_cost_center,  
             lc_location,
             lc_intercompany,
             lc_lob,
             lc_future
      FROM  per_people_v7 ppf,
            per_assignments_v7 pav,
            gl_code_combinations gcc
      WHERE ppf.person_id = pav.person_id
      AND  pav.default_code_comb_id = gcc.code_combination_id
      AND  ppf.person_id = preparer_id 
      AND  ( ppf.effective_end_date IS NULL OR ppf.effective_end_date >= sysdate )
      AND  ( pav.effective_end_date IS NULL OR pav.effective_end_date > SYSDATE);
      
    END IF;
    
    --Get combination
    --Get default segment values

    SELECT NVL(xftv.target_value1,lc_cost_center),
           xftv.target_value2,
           NVL(xftv.target_value3,lc_intercompany)
    INTO   lc_cc,
           lc_acct,
           lc_ic
    FROM xx_fin_translatedefinition xft,
         xx_fin_translatevalues xftv,
         ap_suppliers pva, 
         ap_supplier_sites_all pvsa
    WHERE xft.translate_id    = xftv.translate_id
      AND xft.enabled_flag      = 'Y'
      AND xftv.enabled_flag     = 'Y'
      AND xft.translation_name  =  lc_translation_name
      AND xftv.source_value1    =  'CHARGE_ACCOUNT'
      AND  xftv.source_value2    =  pva.vendor_name
      AND  xftv.source_value3    =  pvsa.vendor_site_code
      AND  pva.vendor_id         =  pvsa.vendor_id
      AND  pva.vendor_id         =  supplier_id
      AND  pvsa.vendor_site_id   =  supplier_site_id;
    
    log_line( 'CUSTOM_DEFAULT_REQ_DIST','Segment1 :'||lc_company||' Segment2 :'||lc_cc||' Segment3 :'||lc_acct||' Segment4 :'|| lc_location ||
                                        'Segment5 :'||lc_ic||'Segment6 :'||lc_lob||'Segment7 :'||lc_future);

    SELECT code_combination_id
    INTO ln_code_combination_id
    FROM gl_code_combinations
    WHERE segment1 = lc_company
    AND   segment2 = lc_cc
    AND   segment3 = lc_acct
    AND   segment4 = lc_location
    AND   segment5 = lc_ic
    AND   segment6 = lc_lob
    AND   segment7 = lc_future;

    x_code_combination_id :=  ln_code_combination_id;

    log_line( 'CUSTOM_DEFAULT_REQ_DIST','New x_code_combination_id :'||x_code_combination_id);

   END IF;
END IF; -- transaction value rec 
RESULT_CODE:=0;
   X_ERROR_MSG:='';

EXCEPTION
  WHEN OTHERS
  THEN
    x_error_msg    := 'Error While deriving the charge account for your request :'|| SQLERRM;
    result_code    := 1;
    log_line( 'CUSTOM_DEFAULT_REQ_DIST', x_error_msg );
    l_req_info := NULL;
    lc_error_msg := NULL;
    IF NVL(lc_transvalues_rec.target_value17,'N') = 'Y' THEN  -- send mail to requestor flag
	  lc_return_status := xx_po_punchout_conf_pkg.get_requestor_info (pi_preparer_id     => preparer_id ,
                                                                      xx_requestor_info  => l_req_info,
                                                                      xx_error_message   => lc_error_msg);
      IF lc_error_msg IS NOT NULL THEN
        log_line( 'CUSTOM_DEFAULT_REQ_DIST', lc_error_msg );
      END IF;
      IF l_req_info.email_address IS NOT NULL THEN
	    lc_subject := 'Your Punch out Request failed';
	    lc_mail_body  := '<html> <body> <font face = "Arial" size = "2">You recently attempted to submit a requisition using a punch-out link in iProcurement received the following message,<b>'||'"'||'You have encountered an unexpected error. Please contact the System Administrator for assistance.'||'"'||'</b><br><br>';
        lc_mail_body  := lc_mail_body||'The requisition above had an error with the GL information within the system.  This requisition was not processed due to this error.<br>';
	    lc_mail_body  := lc_mail_body||'Please contact financialsystems@officedepot.com to have this error researched and resolved. Please be sure to include your Location and Cost Center you are ordering for. Once resolved, you will need to enter a new requisition using the Punch-out in iPro.<br><br>';
        lc_mail_body := lc_mail_body||'Error Message: '||'"'||x_error_msg||'"'||'<br>Derived segment values are '||lc_company||'.'||lc_cc||'.'||lc_acct||'.'||lc_location||'.'||lc_ic||'.'||lc_lob||'.'||lc_future||'</body></html>';
	
        xx_po_punchout_conf_pkg.send_mail(pi_mail_subject       =>  lc_subject,
                                          pi_mail_body          =>  lc_mail_body,
                                          pi_mail_sender        =>  'no_reply@officedepot.com',
                                          pi_mail_recipient     =>  l_req_info.email_address,
                                          pi_mail_cc_recipient  =>  NULL,
                                          po_return_msg         =>  lc_error_msg);
        IF lc_error_msg IS NOT NULL THEN
          log_line( 'CUSTOM_DEFAULT_REQ_DIST', lc_error_msg );
        ELSE
          lc_error_msg := 'Mail sent to Requestor Successfully.';
          log_line( 'CUSTOM_DEFAULT_REQ_DIST', lc_error_msg );
        END IF;
      END IF;
    END IF;
END;

-- Customize this procedure to add logic for validation of the attribute values
-- on a requisition distribution. This would be any custom validation, that
-- would be in addition to all the validations done for a requisition
-- distribution.
-- The return_msg and the error_code can be used to return the results of
-- the validation
-- The return code can be used to indicate on which tab the error message
-- needs to be displayed on the Edit Lines page
-- If the result code is 1, error is displayed on the Delivery tab
-- If the result code is 2, error is displayed on the Billing tab
-- If the result code is 3, error is displayed on the Accounts tab

PROCEDURE CUSTOM_VALIDATE_REQ_DIST (

    x_distribution_id IN NUMBER, -- 1
    x_code_combination_id   IN   NUMBER, -- 2
    x_budget_account_id   IN    NUMBER, -- 3
    x_variance_account_id   IN   NUMBER, -- 4
    x_accrual_account_id   IN    NUMBER, -- 5
    project_id              IN NUMBER, -- 6
    task_id              IN NUMBER, -- 7
    expenditure_type          IN VARCHAR2, -- 8
    expenditure_organization_id IN NUMBER, -- 9
    expenditure_item_date    IN DATE, -- 10
    award_id                 IN NUMBER, -- 11
    gl_encumbered_date         IN DATE,    -- 12
    gl_period_name           IN VARCHAR2, -- 13
    gl_cancelled_date        IN DATE, -- 14
    gl_closed_date           IN DATE,--15
    gl_date                  IN DATE,--16
    gl_encumbered_period     IN VARCHAR2,--17
    recovery_rate            IN NUMBER, -- 18
    tax_recovery_override_flag IN VARCHAR2, -- 19
    chart_of_accounts_id     IN  NUMBER, -- 20
    category_id          IN  NUMBER, -- 21
    catalog_source           IN  VARCHAR2, -- 22
    catalog_type             IN  VARCHAR2, -- 23
    destination_type_code    IN  VARCHAR2, -- 24
    deliver_to_location_id   IN  NUMBER, -- 25
    destination_organization_id IN NUMBER, -- 26
    destination_subinventory IN  VARCHAR2, -- 27
    item_id            IN  NUMBER, -- 28
    sob_id                      IN NUMBER, -- 29
    currency_code               IN VARCHAR2, -- 30
    currency_unit_price         IN NUMBER, -- 31
    manufacturer_name           IN VARCHAR2, -- 32
    manufacturer_part_num       IN VARCHAR2,-- 33
    need_by_date                IN DATE, -- 34
    new_supplier_flag           IN VARCHAR2, -- 35
    business_org_id             IN NUMBER,    -- 36
    org_id                      IN NUMBER, -- 37
    employee_id                 IN NUMBER, -- 38
    employee_org_id       IN      NUMBER,  -- 39
    default_code_combination_id IN NUMBER, -- 40
    parent_req_line_id       IN  NUMBER, -- 41
    qty_cancelled            IN  NUMBER, -- 42
    qty_delivered            IN  NUMBER, -- 43
    qty_ordered              IN  NUMBER, -- 44
    qty_received             IN  NUMBER, -- 45
    rate                     IN  NUMBER, -- 46
    rate_date                IN  DATE, -- 47
    rate_type                IN  VARCHAR2, -- 48
    source_type_code         IN  VARCHAR2, -- 49
    spsc_code                IN  VARCHAR2, -- 50
    suggested_buyer_id       IN  NUMBER, -- 51
    source_doc_header_id     IN  NUMBER, -- 52
    source_doc_line_num      IN  NUMBER, -- 53
    source_doc_type_code     IN  VARCHAR2, -- 54
    supplier_item_num        IN  VARCHAR2, -- 55
    taxable_status           IN  VARCHAR2, -- 56
    unit_of_measure          IN  VARCHAR2, -- 57
    unit_price               IN  NUMBER, -- 58
    supplier_contact_id      IN  NUMBER, -- 59
    supplier_id              IN  NUMBER, -- 60
    supplier_site_id         IN  NUMBER, -- 61
    pcard_flag               IN  VARCHAR2, -- 62
    line_type_id         IN  NUMBER, -- 63
    taxCodeId                 IN   NUMBER, -- 64
    results_billable_flag    IN VARCHAR2,-- 65
    preparer_id                IN  NUMBER, -- 66
    deliver_to_person_id    IN  NUMBER, -- 67
    po_encumberance_flag    IN  VARCHAR2, -- 68
    DATE_FORMAT        IN  VARCHAR2,    -- 69
    header_att1          IN  VARCHAR2,    -- 70
    header_att2          IN  VARCHAR2,    -- 71
    header_att3          IN  VARCHAR2,    -- 72
    header_att4          IN  VARCHAR2,    -- 73
    header_att5          IN  VARCHAR2,    -- 74
    header_att6          IN  VARCHAR2,    -- 75
    header_att7          IN  VARCHAR2,    -- 76
    header_att8          IN  VARCHAR2,    -- 77
    header_att9          IN  VARCHAR2,    -- 78
    header_att10      IN  VARCHAR2,    -- 79
    header_att11      IN  VARCHAR2,    -- 80
    header_att12      IN  VARCHAR2,    -- 81
    header_att13          IN  VARCHAR2,    -- 82
    header_att14      IN  VARCHAR2,    -- 83
    header_att15      IN  VARCHAR2,    -- 84
    line_att1          IN  VARCHAR2,    -- 85
    line_att2          IN  VARCHAR2,    -- 86
    line_att3          IN  VARCHAR2,    -- 87
    line_att4          IN  VARCHAR2,    -- 88
    line_att5          IN  VARCHAR2,    -- 89
    line_att6          IN  VARCHAR2,    -- 90
    line_att7          IN  VARCHAR2,    -- 91
    line_att8          IN  VARCHAR2,    -- 92
    line_att9          IN  VARCHAR2,    -- 93
    line_att10          IN  VARCHAR2,    -- 94
    line_att11          IN  VARCHAR2,    -- 95
    line_att12          IN  VARCHAR2,    -- 96
    line_att13          IN  VARCHAR2,    -- 97
    line_att14          IN  VARCHAR2,    -- 98
    line_att15          IN  VARCHAR2,    -- 99
    distribution_att1      IN   VARCHAR2, -- 100
    distribution_att2      IN   VARCHAR2, -- 101
    distribution_att3      IN   VARCHAR2, -- 102
    distribution_att4      IN   VARCHAR2, -- 103
    distribution_att5      IN   VARCHAR2, -- 104
    distribution_att6      IN   VARCHAR2, -- 105
    distribution_att7      IN   VARCHAR2, -- 106
    distribution_att8      IN   VARCHAR2, -- 107
    distribution_att9      IN   VARCHAR2, -- 108
    distribution_att10      IN   VARCHAR2, -- 109
    distribution_att11      IN   VARCHAR2, -- 110
    distribution_att12      IN   VARCHAR2, -- 111
    distribution_att13      IN   VARCHAR2, -- 112
    distribution_att14      IN   VARCHAR2, -- 113
    distribution_att15      IN   VARCHAR2, -- 114
    result_code           OUT NOCOPY     NUMBER,  -- 115
    x_error_msg           OUT NOCOPY     VARCHAR2 -- 116
)
IS
BEGIN
   RESULT_CODE:=0;
   X_ERROR_MSG:='';

END;


-- Customize this procedure to handle updates to charge accounts.
-- The caller passes the charge account segments values in p_seg_vals,
-- and the new segments values should be returned in the same parameter.
-- Null is passed for the value of the read-only and hidden segments.
-- p_changed_seg is the index of the segment that the user changed this time.
-- p_orig_ccid is the CCID in the distribution before any user changes.
-- Any changes made by the user before a submit event are not reflected in
-- p_orig_ccid.

PROCEDURE CUSTOM_UPDATE_CHARGE_ACCOUNT(
  p_orig_ccid   IN     NUMBER, -- the code-combination ID before any user changes
  p_changed_seg IN     NUMBER, -- index of the changed segment (starts at 0)
  p_seg_vals    IN OUT NOCOPY POR_CHARGE_ACCT_SEG_TBL_TYPE, -- table of segment values
  result_code      OUT NOCOPY NUMBER,
  x_error_msg      OUT NOCOPY VARCHAR2
)
IS
BEGIN
  result_code := 0;
  x_error_msg := '';
END;

-- Since we will be obsoleting existing wf for RCO Req Approval tolerance
-- check, this procedure is provided to implement a hook for existing
-- customizations.
--
--  Parameters :
--    p_chreqgrp_id    : change request group id
--    x_appr_status    : approval status
--    x_skip_std_logic : determines whether standard tolerance check
--                       product logic will be skipped after calling
--                       this procedure or not.
PROCEDURE CUSTOM_RCO_REQAPPR_TOL_CHECK (
  p_chreqgrp_id IN NUMBER,
  x_appr_status OUT NOCOPY VARCHAR2,
  x_skip_std_logic OUT NOCOPY VARCHAR2 ) IS
BEGIN
  x_appr_status := 'Y';
  x_skip_std_logic := 'N';
END;


END POR_CUSTOM_PKG;
/
