CREATE OR REPLACE PACKAGE XX_MON_TPS_PKG
-- +======================================================================+
-- |                  Office Depot - Project Simplify                     |
-- |                                                                      |
-- +======================================================================+
-- | Name : XX_MON_TPS_PKG                                                |
-- | RICE : E2025                                                         |
-- | Description : This package to Populate the data in xx_mon_tps table  |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version  Date         Author              Remarks                     |
-- |=======  ===========  ==================  ============================|
-- |1.0      2009                             Initial version             |
-- |1.1      16-Feb-2011  Vishwajeet Das      Added Exception             |
-- |1.2      13-Jul-2012  Venkata Reddy       Added Webcollect            |
-- |2.0      12-Feb-2014  R. Aldridge         R12 Changes (defect 28157   |
-- +======================================================================+
AS
   PROCEDURE XX_MON_INS_TPS_PRC;
   PROCEDURE XX_MON_INS_AI;
   PROCEDURE XX_MON_INS_NO_AI;
END XX_MON_TPS_PKG;
/
