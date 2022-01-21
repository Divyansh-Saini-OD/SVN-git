SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AP_MERCH_CONT_PKG

WHENEVER SQLERROR CONTINUE
create or replace PACKAGE XX_AP_MERCH_CONT_PKG
IS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_AP_MERCH_CONT_PKG                                                                 |
-- |                                                                                                     |
-- | Description :  Package to Create the AP Merch Contact Details                                       |
-- | Rice ID     :                                                                                       |
-- |Change Record:                                                                                       |
-- |===============                                                                                      |
-- |Version   Date         Author           Remarks                                                      |
-- |=======   ==========   =============    ======================                                       |
-- | 1.0      07-Jul-2017  Havish Kasina    Initial Version                                              |
-- +=====================================================================================================+

  -- +===================================================================+
  -- | Name  : fetch_data                                                |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_AP_MERCH_CONT_STG table            |
  -- |                                                                   |
  -- | Parameters      : p_dept                                          |
  -- |                   p_dept_name                                     |
  -- |                   p_vp                                            |
  -- |                   p_dmm                                           |
  -- |                   p_channel                                       |
  -- |                   p_scm                                           |
  -- |                   p_cm                                            |
  -- |                   p_acm                                           |
  -- |                   p_ca                                            |
  -- |                   p_repl_planner                                  |
  -- +===================================================================+                                  
PROCEDURE fetch_data(p_dept        		IN  NUMBER,
                     p_dept_name   		IN  VARCHAR2,
                     p_vp          		IN  VARCHAR2,
                     p_dmm         		IN  VARCHAR2,
					 p_channel     		IN  VARCHAR2,
					 p_scm         		IN  VARCHAR2,
					 p_cm               IN  VARCHAR2,
					 p_acm              IN  VARCHAR2,
					 p_ca               IN  VARCHAR2,
					 p_repl_planner     IN  VARCHAR2
                     );
  -- +===================================================================+
  -- | Name  : extract                                                   |
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records from XX_AP_MERCH_CONT_STG               |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- +===================================================================+                     
PROCEDURE extract(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER);
				  
/* Added the below procedures by Naveen */
				  
PROCEDURE email_merchant(p_errbuf      OUT NOCOPY VARCHAR2, 
                         p_return_code OUT NOCOPY VARCHAR2);
						 
FUNCTION get_distribution_list 
  RETURN VARCHAR2;

FUNCTION xx_ap_get_hold_date(p_invoice_id NUMBER) 
  RETURN date;
  
FUNCTION merch_name (p_dept_no in number) return varchar2; 

END XX_AP_MERCH_CONT_PKG;
/
SHOW ERRORS;
