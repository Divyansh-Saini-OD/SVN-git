SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_get_salesorder_pkg AUTHID CURRENT_USER

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_GET_SALESORDER_PKG                                    |
-- | Rice ID     : I0340_GetSalesOrd                                           |
-- | Description : Custom Package to contain procedure that retrieves the      |
-- |               Sales Order Information for a given order number from Kiosk |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 21-Jan-2007  B.Faiz Mohammad        Initial draft version         |
-- |                                                                           |
-- +===========================================================================+

AS                                      -- Package Block

-- ----------------------------
-- Global Variable Declarations
-- ----------------------------

    ge_exception xx_om_report_exception_t := xx_om_report_exception_t(
                                                                      'OTHERS'
                                                                     ,'OTC'
                                                                     ,'Kiosk Orders'
                                                                     ,'Get Sales Order'
                                                                     ,null
                                                                     ,null
                                                                     ,null
                                                                     ,null
                                                                    );
-- -----------------
-- Type Declarations
-- -----------------

    --
    -- Database Type to represent Order Header Attributes
    --

    TYPE hdr_attr_rec_type IS RECORD(
         attribute1   VARCHAR2(240)
        ,attribute2   VARCHAR2(240)
        ,attribute3   VARCHAR2(240)
        ,attribute4   VARCHAR2(240)
        ,attribute5   VARCHAR2(240)
        ,attribute6   VARCHAR2(240)
        ,attribute7   VARCHAR2(240)
        ,attribute8   VARCHAR2(240)
        ,attribute9   VARCHAR2(240)
        ,attribute10  VARCHAR2(240)
        ,attribute11  VARCHAR2(240)
        ,attribute12  VARCHAR2(240)
        ,attribute13  VARCHAR2(240)
        ,attribute14  VARCHAR2(240)
        ,attribute15  VARCHAR2(240)
        ,attribute16  VARCHAR2(240)
        ,attribute17  VARCHAR2(240)
        ,attribute18  VARCHAR2(240)
        ,attribute19  VARCHAR2(240)
        ,attribute20  VARCHAR2(240)
    );

    --
    -- Database Type to represent Order Header Attributes
    --

    TYPE line_attr_rec_type IS RECORD(
         attribute1   VARCHAR2(240)
        ,attribute2   VARCHAR2(240)
        ,attribute3   VARCHAR2(240)
        ,attribute4   VARCHAR2(240)
        ,attribute5   VARCHAR2(240)
        ,attribute6   VARCHAR2(240)
        ,attribute7   VARCHAR2(240)
        ,attribute8   VARCHAR2(240)
        ,attribute9   VARCHAR2(240)
        ,attribute10  VARCHAR2(240)
        ,attribute11  VARCHAR2(240)
        ,attribute12  VARCHAR2(240)
        ,attribute13  VARCHAR2(240)
        ,attribute14  VARCHAR2(240)
        ,attribute15  VARCHAR2(240)
        ,attribute16  VARCHAR2(240)
        ,attribute17  VARCHAR2(240)
        ,attribute18  VARCHAR2(240)
        ,attribute19  VARCHAR2(240)
        ,attribute20  VARCHAR2(240)
   );

-- -----------------------------------
-- Function and Procedure Declarations
-- -----------------------------------

    -- +===================================================================+
    -- | Name  : Write_Exception                                           |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_Reference                               |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception (
                                p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                               ,p_entity_reference  IN  VARCHAR2
                               ,p_entity_ref_id     IN  VARCHAR2
                              );

    -- +===================================================================+
    -- | Name  : Get_Sales_Order                                           |
    -- +===================================================================+

    PROCEDURE Get_Orders(p_Order_Number          IN NUMBER,
                         p_msg                    OUT VARCHAR2,
                         l_header_rec             OUT Oe_Order_Pub.Header_Rec_Type,
                         l_Header_Adj_tbl         OUT Oe_Order_Pub.Header_Adj_Tbl_Type,
                         l_Header_price_Att_tbl   OUT Oe_Order_Pub.Header_Price_Att_Tbl_Type,
                         l_Header_Adj_Assoc_tbl   OUT Oe_Order_Pub.Header_Adj_Assoc_Tbl_Type,
                         l_Header_Payment_tbl     OUT Oe_Order_Pub.Header_Payment_Tbl_Type,
                         ln_header_attributes_rec OUT Header_Attributes_Rec_Type,
                         l_line_tbl               OUT Oe_Order_Pub.Line_Tbl_Type,
                         l_Line_Adj_tbl           OUT Oe_Order_Pub.Line_Adj_Tbl_Type,
                         l_Line_price_Att_tbl     OUT Oe_Order_Pub.Line_Price_Att_Tbl_Type,
                         l_Lot_Serial_tbl         OUT Oe_Order_Pub.Lot_Serial_Tbl_Type,
                         ln_line_attributes_rec   OUT Line_Attributes_Rec_Type,
                         ln_total                 OUT NUMBER,
                         l_payments               OUT NUMBER,
                         ln_unpaid_amount         OUT NUMBER,
                         ln_paid_amount           OUT NUMBER
                         );


END xx_om_get_salesorder_pkg;
/

SHOW ERRORS;
