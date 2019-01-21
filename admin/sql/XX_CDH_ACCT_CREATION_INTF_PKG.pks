SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_ACCT_CREATION_INTF_PKG
AS
        -- +===================================================================+
        -- |                  Office Depot - Project Simplify                  |
        -- |                       WIPRO Technologies                          |
        -- +===================================================================+
        -- | Name       :  XX_CDH_ACCT_CREATION_INTF_PKG                       |
        -- | Rice ID    :  E0806_SalesCustomerAccountCreation                  |
        -- | Description:  This package contains procedure to extract customer |
        -- |               account setup request details, find the             |
        -- |               corresponding Bill To Address, Ship To Address and  |
        -- |               Sales Rep details and load them into Interface table|
        -- |                                                                   |
        -- |Change Record:                                                     |
        -- |===============                                                    |
        -- |Version   Date        Author           Remarks                     |
        -- |=======   ==========  =============    ============================|
        -- |1.a      14-SEP-2007  Rizwan           Initial draft version       |
        -- |1.0      04-OCT-2007  Rizwan           Implemented logic to update |
        -- |                                       request status.             |
        -- |1.1      10-DEC-2007  Rizwan           Removed function            |
        -- |                                       'GET_DOC_PROPERTY_VALUE'    |
	-- +===================================================================+

       -- +===================================================================+
        -- | Name             : GET_REQUEST                                    |
        -- | Description      : This procedure extract customer account setup  |
        -- |                    request details, find the corresponding        |
        -- |                    Bill To Address, Ship To Address and Sales Rep |
        -- |                    details and load them into Interface table     |
        -- |                                                                   |
        -- | Parameters :      x_batch_id                                      |
        -- |                   x_status                                        |
        -- |                   x_message                                       |
        -- +===================================================================+

PROCEDURE Get_Request (x_batch_id  OUT NUMBER
                      ,x_status    OUT VARCHAR
                      ,x_message   OUT VARCHAR);

        -- +===================================================================+
        -- | Name             : DELETE INTERFACE TABLE                         |
        -- | Description      : This procedure deletes records from the        |
        -- |                    interface table corresponding to the input     |
        -- |                    batch id                                       |
        -- |                                                                   |
        -- | Parameters :      p_batch_id                                      |
        -- |                   x_status                                        |
        -- |                   x_message                                       |
        -- +===================================================================+

PROCEDURE Delete_Intf_Table (p_batch_id  IN  NUMBER
                            ,x_status    OUT VARCHAR
                            ,x_message   OUT VARCHAR);


        -- +===================================================================+
        -- | Name             : GET_LEGACY_REP_ID                              |
        -- | Description      : This function get legacy sales representive ID |
        -- |                                                                   |
        -- | Parameters :      P_Sales_Rep_ID                                  |
        -- |                   P_Group_ID                                      |
        -- |                                                                   |
        -- +===================================================================+

FUNCTION Get_Legacy_Rep_ID (P_Sales_Rep_ID IN NUMBER
                           ,P_Role_ID      IN NUMBER
                           ,P_Group_ID     IN NUMBER) 
RETURN VARCHAR2;

END XX_CDH_ACCT_CREATION_INTF_PKG;
/
SHOW ERRORS;