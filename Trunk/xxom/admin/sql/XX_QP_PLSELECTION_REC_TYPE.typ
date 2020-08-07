create or replace TYPE XX_QP_PLSELECTION_REC_TYPE AS OBJECT
(  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 31-DEC-07  B.Penski         Initial draft version         |
-- |1.0      22-JAN-08  B.Penski         Added Attributes for          |
-- |                                     Contract PL Selection         |
-- +===================================================================+
     Cust_account_id         NUMBER(15)
   , Account_Number          VARCHAR2(30)
   , Cust_Acct_Site_id       NUMBER(15)
   , Cust_Zone               VARCHAR2(40)
   , Specific_Pricing_Code   VARCHAR2(3)
   , Country_code            VARCHAR2(40)
   , Postal_Code             VARCHAR2(10)
   , City                    VARCHAR2(40)
   , State_Code              VARCHAR2(40)
   , SKU_ID                  VARCHAR2(40)
   , Inventory_Item_id       NUMBER
   , ordered_uom             VARCHAR2(3)
   , ordered_quantity        NUMBER
   , has_MAP                 VARCHAR2(1)
   , has_MSRP                VARCHAR2(1)
   , campaign_code           VARCHAR2(40)
   , ordered_date            DATE
   , OD_Store_id             VARCHAR2(40)
   , MAP_PL_id               NUMBER
   , MSRP_Pl_id              NUMBER
   , Selling_PL_id           NUMBER
   , Selling_PL_Type         VARCHAR2(40)
   , Selling_PL_OD_Type      VARCHAR2(40)
   , Final_Campaign_Code     VARCHAR2(40)
   
);