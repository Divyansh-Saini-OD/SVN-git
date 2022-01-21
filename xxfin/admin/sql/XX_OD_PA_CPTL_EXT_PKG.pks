create or replace
PACKAGE      XX_OD_PA_CPTL_EXT_PKG
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_OD_PA_CPTL_EXT_PKG                                               |
-- | Description : This Package will be executable code for the projects download repor|
-- |                                                                                   |
-- |  Rice ID : E3062                                                                  |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2013  Yamuna Shankarappa      Initial draft version               |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                            ORACLE                                                 |
-- +===================================================================================+
-- | Name        : PROJECT_ASSETS_DATA_EXTRACT                                         |
-- | Description : This Package is used to generate the project related asset informati| 
-- |                on.                                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2013  Yamuna Shankarappa     Initial draft version                |
-- +===================================================================================+

      
PROCEDURE  XX_MAIN ( x_err_buff OUT VARCHAR2,
                           x_ret_code OUT NUMBER
                		  ) ; 
						   
END;
/