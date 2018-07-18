SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_CS_TDS_PARTS_PKG
PROMPT Program exits if the creation is not successful
create or replace PACKAGE XX_CS_TDS_PARTS_PKG
AS
-- +=============================================================================================+
-- |                       Office Depot - TDS                                                    |
-- |                                                                                             |
-- +=============================================================================================+
-- | Name         : XX_CS_TDS_PARTS_PKG.pks                                                      |
-- | Description  : This package is used to add the selected parts, create items in inventory    |
-- |                and create the requisition and PO for the vendor                             |
-- |                                                                                             |
-- |Type        Name                       Description                                           | 
-- |=========   ===========                ===================================================   | 
-- |PROCEDURE   ADD_PARTS                  This procedure will add the Service Request Details   |
-- |                                       to XX_CS_TDS_PARTS Table along with Item,Quantity     |
-- |                                       ,Price details and updates the status of service      |
-- |                                        request to pending for approval                      |    
-- |                                                                                             |
-- |PROCEDURE   MAIN_PROC                  Main Procedure will calls the remaining all other     |
-- |                                       Procedures to craete the item/requisition and PO      |
-- |                                                                                             |
-- |PROCEDURE   CREATE_ITEMS               This procedure will check if the item is created or   |
-- |                                       not in Inventory.If the Item is not created in        |
-- |                                       Inventory then this procedure will create the item    |
-- |                                       in Inventory.This procedure will create the item By   |
-- |                                       calling create_item_process procedure.                |
-- |                                                                                             |
-- |PROCEDURE   CREATE_PARTS_REQ           This procedure will fetch all the required details    |
-- |                                       like resource_type,resource_id,item revision,task_id  |
-- |                                      ,task_assignment_id,shi_to_location_id and             |
-- |                                       destination subinventory.After fetches the all        |
-- |                                       required details this procedure will call's the       |
-- |                                       PROCESS_REQ API create requisition.                   |
-- |                                                                                             |
-- |PROCEDURE   PROCESS_REQ                This Procedure will insert the data into requisition  |
-- |                                       Interface tables.                                     |
-- |                                                                                             |
-- |PROCEDURE   PURCHASE_REQ               This Procedure will calls the requisition standard    |
-- |                                       Import program to create the requisition.             |
-- |                                                                                             |
-- |PROCEDURE   PURCHSE_ORDER              This procedure will insert the data into PO Interface |
-- |                                       tables and calls the PO standard import program to    |
-- |                                       create purchase order                                 |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  11-Jul-2011  Deepti S             Initial draft version                            |
-- +=============================================================================================+
    G_User_Id               NUMBER                 := 0;
    G_Resp_Id               CONSTANT PLS_INTEGER   := 50598 ; --fnd_global.resp_id;
    G_Resp_Appl_Id          CONSTANT PLS_INTEGER   := 514 ;   --fnd_global.resp_appl_id;
    g_login_id              CONSTANT PLS_INTEGER   := -1;     --fnd_global.login_id;
    G_User_Name             CONSTANT VARCHAR2(20)  := 'CS_ADMIN';
    G_Charge_account        NUMBER                 := 0;
    g_charge_acc_id         NUMBER                 := 0;
    g_accrual_account_id    NUMBER                 := 0;
	
	G_Buyer_Id Po_Agents_V.Agent_Id%TYPE           := 84974;	
	G_Req_Header_Id Po_Requisition_Headers_All.Requisition_Header_Id%TYPE;
    G_Item_Id Mtl_System_Items_B.Inventory_Item_Id%TYPE;    
    G_Requirement_Hdr_Id Csp_Requirement_Headers.Requirement_Header_Id%TYPE;

-- Defining the record type
  
TYPE xx_cs_tds_items_rec_type
IS
  RECORD
        (
          store_id          NUMBER,
          item_number       VARCHAR2(25),
          item_description  VARCHAR2(250),
          rms_sku           VARCHAR2(25),
          quantity          NUMBER,
          item_category     VARCHAR2(25),
          purchase_price    NUMBER,
          selling_price     NUMBER,
          exchange_price    NUMBER,
          core_flag         VARCHAR2(1),
          uom               VARCHAR2(5),
          schedule_date     DATE,
          attribue1         VARCHAR2(250),
          attribue2         VARCHAR2(250),
          attribue3         VARCHAR2(250),
          attribue4         VARCHAR2(250),
          attribue5         VARCHAR2(250),
          manufacturer	    VARCHAR2(50),
          model	            VARCHAR2(25),
          serial_number	    VARCHAR2(25),
          prob_descr	    VARCHAR2(250),
          special_instr	    VARCHAR2(1000),
          inventory_item_id NUMBER  -- Added By Bala on 28-Jul to retrive inventory item id from XX_CS_TDS_PARTS table 
        ); 

g_tds_parts_rec xx_cs_tds_items_rec_type;


TYPE Xx_Cs_Tds_Items_Tbl_Type IS  TABLE OF Xx_Cs_Tds_Items_Rec_Type INDEX BY BINARY_INTEGER; 

-- +==================================================================================================+
-- |PROCEDURE   : ADD_PARTS                                                                           |
-- |                                                                                                  |
-- |DESCRIPTION : This procedure will add the Service Request Details to XX_CS_TDS_PARTS Table along  |
-- |              with Item,Quantity ,Price details and updates the status of service                 |
-- |              request to pending for approval                                                     |   
-- |PARAMETERS  :                                                                                     |
-- |                                                                                                  |
-- |    NAME                Mode    TYPE            DESCRIPTION                                       |
-- |-------------           ----   --------------   ---------------------------------                 |
-- | p_sr_number             IN      VARCHAR2        Pass the service request number                  |
-- |                                                                                                  |
-- | p_store_Number          IN      VARCHAR2        Pass the store number                            |
-- |                                                                                                  |
-- | p_parts_table           IN      TABLE TYPE      Pass the table type                              |
-- |                                                                                                  |
-- | x_return_status         IN OUT  VARCHAR2        Return the status of the procedure E-Error       |
-- |                                                 or S-Success                                     |
-- |                                                                                                  |
-- | x_return_message        IN OUT  VARCHAR2        Return the Error message if there is any failure.|
-- |                                                 While executing this procedure.Failure means if  |
-- |                                                 it is validation failure or API failure or any   |
-- |                                                 other failures.                                  |
-- |--------------------------------------------------------------------------------------------------|
   
PROCEDURE ADD_PARTS( p_sr_number      IN VARCHAR2
                    ,p_store_Number   IN VARCHAR2
                    ,p_quote_rec      IN xx_cs_tds_quote_rec
                    ,p_parts_table    IN Xx_Cs_Tds_Parts_Quote_Tbl
                    ,x_return_status  IN OUT VARCHAR2
                    ,x_return_message IN OUT VARCHAR2 
                   );
                                          
-- +==================================================================================================+
-- |PROCEDURE   : MAIN_PROC                                                                           |
-- |                                                                                                  |
-- |DESCRIPTION : Main Procedure will calls the remaining all other                                   |
-- |              Procedures to craete the item/requisition and PO                                    |   
-- |PARAMETERS  :                                                                                     |
-- |                                                                                                  |
-- |    NAME                Mode     TYPE            DESCRIPTION                                      |
-- |-------------           ----    --------------   ---------------------------------                |
-- | p_sr_number             IN      VARCHAR2        Pass the service request number                  |
-- |                                                                                                  |
-- | x_return_status         IN OUT  VARCHAR2        Return the status of the procedure E-Error       |
-- |                                                 or S-Success                                     |
-- |                                                                                                  |
-- | x_return_message        IN OUT  VARCHAR2        Return the Error message if there is any failure.|
-- |                                                 While executing this procedure.Failure means if  |
-- |                                                 it is validation failure or API failure or any   |
-- |                                                 other failures.                                  |
-- |--------------------------------------------------------------------------------------------------|

PROCEDURE MAIN_PROC( p_sr_number        IN       VARCHAR2
                    ,x_return_status    IN OUT   VARCHAR2
                    ,x_return_Message   IN Out   VARCHAR2
                   );
  
-- +==================================================================================================+
-- |PROCEDURE   : CREATE_ITEMS                                                                        |
-- |                                                                                                  |
-- |DESCRIPTION : This procedure will check if the item is created or not in Inventory.               |
-- |              If the Item is not created in Inventory then this procedure will create the item    |
-- |              in Inventory.This procedure will create the item By calling create_item_process     |  
-- |              procedure.                                                                          |  
-- |PARAMETERS  :                                                                                     |
-- |                                                                                                  |
-- |    NAME                Mode    TYPE            DESCRIPTION                                       |
-- |-------------           ----   --------------   ---------------------------------                 |
-- | p_sr_number             IN     VARCHAR2        Pass the service request number                   |
-- |                                                                                                  |
-- | p_store_Number          IN     VARCHAR2        Pass the store number                             |
-- |                                                                                                  |
-- | p_parts_table           IN     TABLE TYPE      Pass the table type                               |
-- |                                                                                                  |
-- | x_return_status         IN OUT  VARCHAR2       Return the status of the procedure E-Error        |
-- |                                                or S-Success                                      |
-- |                                                                                                  |
-- | x_return_message        IN OUT  VARCHAR2       Return the Error message if there is any failure. |
-- |                                                While executing this procedure.Failure means if   |
-- |                                                it is validation failure or API failure or any    |
-- |                                                other failures.                                   |
-- |--------------------------------------------------------------------------------------------------|

PROCEDURE  CREATE_ITEMS( p_sr_number      IN VARCHAR2
                        ,p_store_number   IN VARCHAR2
                        ,p_store_name     IN VARCHAR2
                        ,p_Parts_Table    IN xx_cs_tds_items_tbl_type
                        ,x_return_status  IN OUT VARCHAR2
                        ,x_return_message IN OUT VARCHAR2
                       );

-- +==================================================================================================+
-- |PROCEDURE   : CREATE_PARTS_REQ                                                                    |
-- |                                                                                                  |
-- |DESCRIPTION : This procedure will fetch all the required details like resource_type,resource_id,  |
-- |              item revision,task_id,task_assignment_id,shi_to_location_id and destination         |
-- |              subinventory.After fetches the all required details this procedure will call's the  |
-- |              PROCESS_REQ API create requisition.                                                 |  
-- |PARAMETERS  :                                                                                     |
-- |                                                                                                  |
-- |    NAME                Mode    TYPE            DESCRIPTION                                       |
-- |-------------           ----   --------------   ---------------------------------                 |
-- | p_sr_number             IN     VARCHAR2        Pass the service request number                   |
-- |                                                                                                  |
-- | p_store_Number          IN     VARCHAR2        Pass the store number                             |
-- |                                                                                                  |
-- | p_parts_table           IN     TABLE TYPE      Pass the table type                               |
-- |                                                                                                  |
-- | x_return_status         IN OUT  VARCHAR2       Return the status of the procedure E-Error        |
-- |                                                or S-Success                                      |
-- |                                                                                                  |
-- | x_return_message        IN OUT  VARCHAR2       Return the Error message if there is any failure. |
-- |                                                While executing this procedure.Failure means if   |
-- |                                                it is validation failure or API failure or any    |
-- |                                                other failures.                                   |
-- |--------------------------------------------------------------------------------------------------|

PROCEDURE CREATE_PARTS_REQ( p_sr_Number      IN  VARCHAR2
                           ,p_store_Number   IN  VARCHAR2
                           ,p_parts_tbl      IN  xx_cs_tds_items_tbl_type
                           ,x_return_status  OUT VARCHAR2
                           ,x_msg_data       OUT VARCHAR2
                          );
                          
-- +==================================================================================================+
-- |PROCEDURE   : PROCESS_REQ                                                                         |
-- |                                                                                                  |
-- |DESCRIPTION :  This Procedure will insert the data into requisition Interface tables.             |  
-- |PARAMETERS  :                                                                                     |
-- |                                                                                                  |
-- |    NAME                Mode    TYPE            DESCRIPTION                                       |
-- |-------------           ----   --------------   ---------------------------------                 |
-- | p_sr_number             IN     VARCHAR2        Pass the service request number                   |
-- |                                                                                                  |
-- | p_store_Number          IN     VARCHAR2        Pass the store number                             |
-- |                                                                                                  |
-- | p_req_line_tbl          IN     Table Type      Passes the Table Type                             |
-- |                                                                                                  |
-- | p_req_header_rec        IN     Record Type     Pass the Record Type type                         |
-- |                                                                                                  |
-- | p_line_tbl              IN     Table Type      Passes the Table Type                             |
-- |                                                                                                  |
-- | x_return_status         IN OUT  VARCHAR2       Return the status of the procedure E-Error        |
-- |                                                or S-Success                                      |
-- |                                                                                                  |
-- | x_return_message        IN OUT  VARCHAR2       Return the Error message if there is any failure. |
-- |                                                While executing this procedure.Failure means if   |
-- |                                                it is validation failure or API failure or any    |
-- |                                                other failures.                                   |
-- |--------------------------------------------------------------------------------------------------|                         

PROCEDURE PROCESS_REQ( p_sr_number       IN  VARCHAR2
                      ,p_req_header_rec  IN  csp_requirement_headers_pub.rqh_rec_type
                      ,p_req_line_tbl    IN  csp_requirement_Lines_pub.rql_tbl_type
                      ,p_header_rec      IN  csp_parts_requirement.header_rec_type
                      ,p_line_tbl        IN  csp_parts_requirement.line_tbl_type
                      ,x_return_status   OUT VARCHAR2
                      ,x_msg_data        OUT VARCHAR2
                      );

-- +==================================================================================================+
-- |PROCEDURE   : PURCHASE_REQ                                                                        |
-- |                                                                                                  |
-- |DESCRIPTION : This Procedure will calls the requisition standard Import program to create         |
-- |              the requisition.                                                                    |
-- |PARAMETERS  :                                                                                     |
-- |                                                                                                  |
-- |    NAME                Mode    TYPE            DESCRIPTION                                       |
-- |-------------           ----   --------------   -----------------------------------------------   |
-- | x_return_status         IN OUT  VARCHAR2       Return the status of the procedure E-Error        |
-- |                                                or S-Success                                      |
-- |                                                                                                  |
-- | x_return_message        IN OUT  VARCHAR2       Return the Error message if there is any failure. |
-- |                                                While executing this procedure.Failure means if   |
-- |                                                it is validation failure or API failure or any    |
-- |                                                other failures.                                   |
-- |--------------------------------------------------------------------------------------------------|  

PROCEDURE PURCHASE_REQ( x_return_status    IN OUT   VARCHAR2
                       ,x_return_message   IN OUT   VARCHAR2
                      );
                      
-- +==================================================================================================+
-- |PROCEDURE   : PURCHSE_ORDER                                                                       |
-- |                                                                                                  |
-- |DESCRIPTION :  This Procedure will insert the data into requisition Interface tables.             |  
-- |PARAMETERS  :                                                                                     |
-- |                                                                                                  |
-- |    NAME                Mode    TYPE            DESCRIPTION                                       |
-- |-------------           ----   --------------   ---------------------------------                 |
-- | p_sr_number             IN     VARCHAR2        Pass the service request number                   |
-- |                                                                                                  |
-- | p_requirement_hdr_id    IN     NUMBER          Pass the Requisition header id                    |
-- |                                                                                                  |
-- | p_parts_table           IN     TABLE TYPE      Pass the table type                               |
-- |                                                                                                  |
-- | x_return_status         IN OUT  VARCHAR2       Return the status of the procedure E-Error        |
-- |                                                or S-Success                                      |
-- |                                                                                                  |
-- | x_return_message        IN OUT  VARCHAR2       Return the Error message if there is any failure. |
-- |                                                While executing this procedure.Failure means if   |
-- |                                                it is validation failure or API failure or any    |
-- |                                                other failures.                                   |
-- |--------------------------------------------------------------------------------------------------| 

PROCEDURE PURCHSE_ORDER( p_sr_number           IN  VARCHAR2
                        ,p_requirement_hdr_id  IN  NUMBER
                        ,p_parts_table         IN  xx_cs_tds_items_tbl_type
                        ,x_return_status       IN OUT   VARCHAR2
                        ,x_return_message      IN OUT   VARCHAR2
                       );
 
END XX_CS_TDS_PARTS_PKG;
/
SHOW ERROR;
EXIT;