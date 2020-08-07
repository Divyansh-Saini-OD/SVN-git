CREATE OR REPLACE PACKAGE xx_om_global_exception_pkg AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XXOMGLEXPPKGS.PKS                                         |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   06-MAR-2007   Bapuji          Initial draft version     |
-- |                                                                   |
-- +===================================================================+

  -- +=============================================================+
  -- | Name  : INSERT_EXCEPTION                                    |
  -- | Description: This is the main Procedure where the exceptions|
  -- |              will be captured form all custom programs      |
  -- |              written for ONT module                         |
  -- |                                                             |
  -- +=============================================================+

 PROCEDURE insert_exception  (
                 p_report_exception  IN xx_om_report_exception
               , x_err_buf          OUT VARCHAR2              
               , x_ret_code         OUT VARCHAR2              
               );

  -- +=============================================================+
  -- | Name  : GENERATE_XML                                        |
  -- | Description: This is the main Procedure where the exceptions|
  -- |              will be captured in CLOB DATATYPE              |
  -- |                                                             |
  -- |                                                             |
  -- +=============================================================+                           

PROCEDURE generate_xml (
                x_err_buf          OUT VARCHAR2
              , x_ret_code         OUT VARCHAR2 
              );

END xx_om_global_exception_pkg; 


