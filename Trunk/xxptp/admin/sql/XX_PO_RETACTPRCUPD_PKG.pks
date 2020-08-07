SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE XX_PO_RETACTPRCUPD_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/Office Depot/Consulting Organization             |
-- +===================================================================+
-- | Name       : XX_PO_RETACTPRCUPD_PKG.pks                           |
-- | Description: This package is used to select all the quotations,   |
-- | which got cost changes and past effective date. This package also |
-- | select all the po, that are created after the effective date for  |
-- | that item against that quotations. This package also update the PO|
-- | price and submit PO for approval if current status is approved    |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ===========================|
-- |DRAFT 1A  23-Jul-2007  Sriramdas S      Initial draft version      |
-- |1.0       25-Sep-2007  Seemant Gour     Updated as per Onsite      |
-- |                                        (Dharma's) Review comments |
-- |                                        and OD IT Design review comments.|
-- |1.1       12-Dec-2007  Vikas Raina      Updated with new collection|
-- +===================================================================+

AS

-- -------------------------
-- Table declarations
-- -------------------------
   TYPE tbl_line_document  IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
   TYPE tbl_line_document1 IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
   TYPE tbl_total          IS TABLE OF NUMBER         INDEX BY BINARY_INTEGER;
   TYPE tbl_total1         IS TABLE OF NUMBER         INDEX BY BINARY_INTEGER;
   
   TYPE po_wf_app_type IS RECORD   ( po_header_id          NUMBER
                                    ,buyer_id              NUMBER
                                    ,update_po_flag        BOOLEAN
                                    ,last_update_date      DATE
                                    ,launch_approvals_flag VARCHAR2(1)
                                   );
                                         
   TYPE xx_po_wf_app_tbl_type IS TABLE OF po_wf_app_type; 

   lc_last_run_date1       VARCHAR2(100);     -- Capture last run date in Varchar initially

-- +====================================================================+
-- | Name         : GET_UPD_PRICE_QUO                                   |
-- | Description  : This procedure select the quotations and purchase   |
-- | order lines that are created after the effective date for that item|
-- | against that quotation                                             |
-- |                                                                    |
-- |                                                                    |
-- | Parameters   : x_err_buf          OUT  VARCHAR2  Error Message     |
-- |                x_retcode          OUT  NUMBER    Error Code        |
-- |                p_price_protection IN   VARCHAR2                    |
-- |                                                                    |
-- | Returns      : None                                                |
-- +====================================================================+

   PROCEDURE GET_UPD_PRICE_QUO(
                      x_err_buf          OUT   VARCHAR2
                     ,x_retcode          OUT   NUMBER
                     ,p_price_protection IN    VARCHAR2
                     ,x_ln_total         OUT   NUMBER
                     ,x_ln_total1        OUT   NUMBER
                     ,x_line_document    OUT   tbl_line_document
                     ,x_line_document1   OUT   tbl_line_document
                     );

-- +====================================================================+
-- | Name         : GET_ERR_PRICE_PO                                    |
-- | Description  : This procedure will select all the records from the |
-- | error table, call the API PO_SOURCING2_SV.GET_PRICE_BREAK to get   |
-- | the new purchase order price and API  PO_CHANGE_API1_S.update_po   |
-- | to update the po price and submit po for approval if current       |
-- | status of the PO is approved.                                      |
-- |                                                                    |
-- |                                                                    |
-- | Parameters   : x_err_buf            OUT  VARCHAR2  Error Message   |
-- |                x_retcode            OUT  NUMBER    Error Code      |
-- |                p_prcs_only_err_flag IN   VARCHAR2                  |
-- |                                                                    |
-- | Returns      : None                                                |
-- +====================================================================+

   PROCEDURE GET_ERR_PRICE_PO(
                      x_err_buf            OUT   VARCHAR2
                     ,x_retcode            OUT   NUMBER
                     ,p_prcs_only_err_flag IN    VARCHAR2
                     ,x_ln_total           OUT   NUMBER
                     ,x_ln_total1          OUT   NUMBER
                     ,x_line_document      OUT   tbl_line_document
                     ,x_line_document1     OUT   tbl_line_document
                     );

-- +====================================================================+
-- | Name         : PRINT_HEADER                                        |
-- | Description  : This is useing for header  printing                 |
-- |                                                                    |
-- |                                                                    |
-- | Parameters   : x_err_buf            OUT  VARCHAR2  Error Message   |
-- |                x_retcode            OUT  NUMBER    Error Code      |
-- |                p_price_protection   IN   VARCHAR2                  |
-- |                p_prcs_only_err_flag IN   VARCHAR2                  |
-- |                                                                    |
-- | Returns      : None                                                |
-- +====================================================================+
   PROCEDURE PRINT_HEADER(
                          x_errbuf            OUT   VARCHAR2
                         ,x_retcode           OUT   NUMBER
                         ,p_total             IN    NUMBER
                         ,p_total1            IN    NUMBER
                         ,p_line_document     IN    tbl_line_document
                         ,p_line_document1    IN    tbl_line_document
                               );

-- +====================================================================+
-- | Name         : MAIN_PROC                                           |
-- | Description  : This is the main procedure of the package, which in |
-- |turn calls to the other procedures of the package.                  |
-- |                                                                    |
-- |                                                                    |
-- | Parameters   : x_err_buf            OUT  VARCHAR2  Error Message   |
-- |                x_retcode            OUT  NUMBER    Error Code      |
-- |                p_price_protection   IN   VARCHAR2                  |
-- |                p_prcs_only_err_flag IN   VARCHAR2                  |
-- |                                                                    |
-- | Returns      : None                                                |
-- +====================================================================+
   PROCEDURE MAIN_PROC(
                      x_errbuf             OUT   VARCHAR2
                     ,x_retcode            OUT   NUMBER
                     ,p_price_protection   IN    VARCHAR2
                     ,p_prcs_only_err_flag IN    VARCHAR2
   		     );
END XX_PO_RETACTPRCUPD_PKG;
/

SHOW ERRORS;

EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
