
CREATE OR REPLACE PACKAGE XX_OM_GMIL_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : GMIL                                                      |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   26-APR-2007   Bapuji          Initial draft version     |
-- |                                                                   |
-- +===================================================================+

  -- +=============================================================+
  -- | Name  : insert_file                                         |
  -- | Description:                                                |
  -- |                                                             |
  -- |                                                             |
  -- |                                                             |
  -- +=============================================================+
  
     PROCEDURE insert_file(
                            p_country         IN VARCHAR2
                          , p_lang            IN VARCHAR2
                          , p_brand           IN VARCHAR2
                          , p_html_file       IN BLOB
                          , p_cost_center     IN VARCHAR2
                          , p_date_created    IN DATE
                          , p_updated_user    IN VARCHAR2
                          , p_status          IN VARCHAR2);

END XX_OM_GMIL_PKG;
/