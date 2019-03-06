SET SHOW OFF; 
SET VERIFY OFF; 
SET ECHO OFF; 
SET TAB OFF; 
SET FEEDBACK OFF; 
WHENEVER SQLERROR CONTINUE; 
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 

create or replace PACKAGE "XX_QP_CAMPAIGN_PRICELIST_PKG" AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XX_QP_PRICE_REQUEST_PKG                                  |
-- | Description: Interface created to select the Price List Header ID |
-- | that must be sent to QP for pricing calculation.                  |
-- | See I2022_PriceSelection_BestPrice MD050 and related docs.        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 04-OCT-2007  B.Penski         Initial draft version       |
-- |DRAFT 1B 23-OCT-2007  B.Penski         Added as a single package   |
-- |DRAFT 1C 21-DEC-2007                   Modified as per new design  |
-- |1.0      08-Jan-2008  B. Penski        Changed in/OUT Parameter for|
-- |                                       p_plselection_rec to match  |
-- |                                       other PL selection packages |
-- +===================================================================+




-- +===================================================================+
-- | Name  : Get_Campaign_Price_list                                   |
-- | Description : This procedure returns the price list with the most |
-- |              effective date for a given effort/campaign           |

-- | Created by:   Bibiana Penski                                      |
-- | Last Updated: 08-Jan-08
-- +===================================================================+
  PROCEDURE Get_Campaign_PriceList (  
                                        p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                                      , p_plselection_rec    IN XX_QP_PLSELECTION_REC_TYPE
                                      , x_Price_list_rec     OUT NOCOPY XX_QP_PRICE_LIST_REC_TYPE
                                      , x_return_status      OUT NOCOPY VARCHAR2
                                      , x_return_msg         OUT NOCOPY VARCHAR2  );



 
END "XX_QP_CAMPAIGN_PRICELIST_PKG";
/ 

SHOW ERRORS PACKAGE XX_QP_PRICELIST_SELECTION_PKG; 
EXIT; 
