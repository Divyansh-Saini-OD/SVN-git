SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_CS_TDS_PARTS_PKG
PROMPT Program exits if the creation is not successful
create or replace
PACKAGE xx_cs_tds_parts_pkg
AS

-- +=============================================================================================+
-- |                       Office Depot - TDS                                                    |
-- |                                                                                             |
-- +=============================================================================================+
-- | Name         : Xx_Cs_Tds_Parts_Pkg.sql                                                      |
-- | Description  : This package is used to add the selected parts, create items in inventory    |
-- |                and create the requisition and PO for the vendor                             |
-- |                                                                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  11-Jul-2011  Deepti S  Initial draft version                                       |
-- +=============================================================================================+
    G_User_Id      Number                 := 0;
    G_Resp_Id      Constant Pls_Integer   := 50598 ; --fnd_global.resp_id;
    G_Resp_Appl_Id Constant Pls_Integer   := 514 ; --fnd_global.resp_appl_id;
    g_login_id     CONSTANT PLS_INTEGER   := -1; --fnd_global.login_id;
    G_User_Name    Constant Varchar2 (20) := 'CS_ADMIN';
    G_Req_Header_Id Po_Requisition_Headers_All.Requisition_Header_Id%Type;
    G_Item_Id Mtl_System_Items_B.Inventory_Item_Id%Type;
    G_Buyer_Id Po_Agents_V.Agent_Id%Type :=84974;
    G_Requirement_Hdr_Id Csp_Requirement_Headers.Requirement_Header_Id%Type;
    G_Charge_account     number;
    g_charge_acc_id      number;
    g_accrual_account_id number;
    
TYPE XX_CS_TDS_PARTS_REC_TYPE
IS
  RECORD
        (
          Item_number      VARCHAR2(25),
          Item_description VARCHAR2(250),
          RMS_SKU          VARCHAR2(25),
          Quantity         NUMBER,
          Item_category    VARCHAR2(25),
          Purchase_price   NUMBER,
          Exchange_price   NUMBER,
          Core_flag        VARCHAR2(1),
          UOM              VARCHAR2(5),
          schedule_date    DATE,
          Attribue1        VARCHAR2(250),
          Attribue2        VARCHAR2(250),
          Attribue3        VARCHAR2(250),
          Attribue4        VARCHAR2(250),
          Attribue5        VARCHAR2(250),
          Manufacturer     VARCHAR2(50),
          Model            VARCHAR2(25),
          Serial_number    VARCHAR2(25),
          Prob_descr         VARCHAR2(250),
          Special_instr    VARCHAR2(1000)          
        );
          
  G_TDS_PARTS_REC XX_CS_TDS_PARTS_REC_TYPE;

TYPE Xx_Cs_Tds_Parts_Tbl_Type
Is  Table Of Xx_Cs_Tds_Parts_Rec_Type Index By Binary_Integer;

-- Add parts procedure will insert the records into xx_cs_tds_parts table
PROCEDURE ADD_PARTS( p_sr_number      IN VARCHAR2
                    ,p_store_Number   IN VARCHAR2
                    ,p_PARTS_TABLE    IN Xx_Cs_Tds_Parts_Tbl_Type
                    ,x_return_status  IN OUT VARCHAR2
                    ,x_return_message IN OUT VARCHAR2 
                   );
                                          
-- Main procedure will call all other procedures 
PROCEDURE MAIN_PROC( p_sr_number        IN       VARCHAR2
                    ,x_return_status    IN OUT   VARCHAR2
                    ,x_return_Message   IN Out   VARCHAR2
                   );
  
--Create item procedure will call the item creation API and it will 
--create the item if the item is not existed in inventory
PROCEDURE  CREATE_ITEMS( p_sr_number      IN VARCHAR2
                        ,p_Store_Number   IN VARCHAR2
                        ,p_Parts_Table    IN Xx_Cs_Tds_Parts_Tbl_Type
                        ,x_return_status  IN OUT VARCHAR2
                        ,x_return_message IN OUT VARCHAR2
                       );

-- create_parts_req API will create the records in Requirement header and lines table
PROCEDURE CREATE_PARTS_REQ( p_sr_Number      IN  VARCHAR2
                           ,p_store_Number   IN  VARCHAR2
                           ,P_PARTS_TBL      IN  xx_Cs_Tds_Parts_Tbl_Type
                           ,x_return_status  OUT VARCHAR2
                           ,x_msg_data       OUT VARCHAR2
                          );
                          
-- process_req will create the records in requisition interface table                           
PROCEDURE PROCESS_REQ( p_sr_number       IN  VARCHAR2
                      ,p_req_header_rec  IN  csp_requirement_headers_pub.rqh_rec_type
                      ,p_req_line_tbl    IN  csp_requirement_Lines_pub.rql_tbl_type
                      ,p_header_rec      IN  csp_parts_requirement.header_rec_type
                      ,p_line_tbl        IN  csp_parts_requirement.line_tbl_type
                      ,x_return_status   OUT VARCHAR2
                      ,x_msg_data        OUT VARCHAR2
                      );

--purchase_req API will submit requisition import program to import the requisitions 
PROCEDURE PURCHASE_REQ( x_return_status    IN OUT   VARCHAR2
                       ,x_return_message   IN OUT   VARCHAR2
                      );
                      
--purchase_order API will call purchase order import program to create the purchase orders 
PROCEDURE PURCHSE_ORDER( p_sr_number           IN  VARCHAR2
                      --  ,p_requirement_hdr_id  IN  NUMBER
                        ,P_PARTS_TABLE         IN xx_cs_tds_parts_tbl_type
                        ,x_return_status       IN OUT   VARCHAR2
                        ,x_return_message      IN OUT   VARCHAR2
                       );
 
END xx_cs_tds_parts_pkg;
/
SHOW ERROR