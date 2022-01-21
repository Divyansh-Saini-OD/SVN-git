-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_AP_DCN_STG_TYP.sql                                                              |
-- |  Description:  New Object Type                                                             |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         13-DEC-2012  Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
CREATE OR REPLACE TYPE XX_AP_DCN_STG_TYP AS OBJECT
(
 DCN                        NUMBER(9),
 VENDOR_NUM                 VARCHAR2(10),
 INVOICE_NUM                VARCHAR2(20),
 INVOICE_DATE               DATE,
 STATUS                     VARCHAR2(40),
 CREATION_DATE              DATE
);
/
CREATE OR REPLACE TYPE XX_AP_DCN_STG_LIST_T AS TABLE OF XX_AP_DCN_STG_TYP;

/
