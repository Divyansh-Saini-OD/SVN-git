SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AP_COST_VARIANCE_PKG

WHENEVER SQLERROR CONTINUE
create or replace PACKAGE XX_AP_COST_VARIANCE_PKG
IS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_AP_COST_VARIANCE_PKG                                                              |
-- |                                                                                                     |
-- | Description :  This Package is to get all the new invoice lines which are having price variance and |
-- |                insert into the custom table                                                         |
-- | Rice ID     :  E3523                                                                                |
-- |Change Record:                                                                                       |
-- |===============                                                                                      |
-- |Version   Date         Author           Remarks                                                      |
-- |=======   ==========   =============    ======================                                       |
-- | 1.0      11-Jul-2017  Havish Kasina    Initial Version                                              |
-- +=====================================================================================================+

  -- +===================================================================+
  -- | Name  : fetch_data                                                |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_AP_COST_VAR_STG table              |
  -- |                                                                   |
  -- | Parameters      : p_sku        		                             |
  -- |                   p_sku_description                               |
  -- |                   p_vendor_no                                     |
  -- |                   p_vendor_name                                   |
  -- |                   p_po_cost     		                             |
  -- |                   p_invoice_price                                 |
  -- |                   p_invoice_num                                   |
  -- |                   p_po_num                                        |
  -- |                   p_po_date                                       |
  -- |                   p_po_line_number                                |
  -- |                   p_answer_code                                   |
  -- |                   p_memo_comments                                 |
  -- |                   p_cost_effective_date                           |
  -- |                   p_pay_other_cost                                |
  -- +===================================================================+                                  
PROCEDURE fetch_data(p_sku        		        IN  VARCHAR2,
                     p_sku_description   		IN  VARCHAR2,
                     p_vendor_no          		IN  VARCHAR2,
                     p_vendor_name         		IN  VARCHAR2,
					 p_po_cost     		        IN  NUMBER,
					 p_invoice_price            IN  NUMBER,
					 p_invoice_num              IN  VARCHAR2,
					 p_po_num                   IN  VARCHAR2,
					 p_po_date                  IN  DATE,
					 p_po_line_number           IN  NUMBER,
					 p_answer_code              IN  VARCHAR2,
					 p_memo_comments            IN  VARCHAR2,
					 p_cost_effective_date      IN  DATE,
					 p_pay_other_cost           IN  NUMBER
                     );
  -- +===================================================================+
  -- | Name  : extract                                                   |
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records from XX_AP_COST_VAR_STG                 |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- +===================================================================+                     
PROCEDURE extract(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER);
				  
PROCEDURE Submit_cost_var_report;				
				  
PROCEDURE xx_cost_variance(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER);

END XX_AP_COST_VARIANCE_PKG;
/
