CREATE OR REPLACE PACKAGE XX_CN_OM_EXTRACT_PKG AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_CN_OM_EXTRACT_PKG                                              |
-- |                                                                                |
-- | Rice ID    : E1004B_CustomCollections_(OM_Extract)                             |
-- | Description: Package specification to extract the closed sales order data      |
-- |              and insert it into XX_CN_NOT_TRX and XX_CN_OM_TRX tables          |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  03-OCT-2007  Hema Chikkanna         Initial draft version             |
-- |DRAFT 1B  10-OCT-2007  Hema Chikkanna         Incorporated changes after review |
-- |1.0       15-OCT-2007  Hema Chikkanna         Incorporated changes after Testing|
-- |1.1       02-NOV-2007  Hema Chikkanna         Added data type for Error         |
-- |                                              reporting                         |
-- +================================================================================+

   TYPE omtrx_tbl_type IS TABLE OF XX_CN_OM_TRX%ROWTYPE INDEX BY BINARY_INTEGER;

   lt_omtrx          omtrx_tbl_type;
   lt_omtrx_suc      omtrx_tbl_type;
   lt_omtrx_fal      omtrx_tbl_type;

   TYPE conc_req_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

   lt_conc_req_tbl   conc_req_tbl_type;
   
   
   
-- +=============================================================+
-- | Name        : om_extrcat_main                               |
-- | Description : Procedure to extract the sales                |
-- |               order data and insert it into                 |
-- |               xx_cn_not_trx table                           |
-- |                                                             |
-- | Parameters  : x_errbuf         OUT   VARCHAR2               |
-- |               x_retcode        OUT   NUMBER                 |
-- |               p_mode           IN    VARCHAR2               |
-- |               p_start_date     IN    VARCAHR2               |
-- |               p_end_date       IN    VARCAHR2               |
-- |                                                             |
-- +=============================================================+


PROCEDURE om_extract_main ( x_errbuf      OUT VARCHAR2
                           ,x_retcode     OUT NUMBER
                           ,p_mode        IN  VARCHAR2
                           ,p_start_date  IN  VARCHAR2
                           ,p_end_date    IN  VARCHAR2
                          );


-- +=============================================================+
-- | Name        : om_extrcat_child                              |
-- | Description : Procedure to extract the uncollected data from|
-- |               xx_cn_not_trx table and insert it into        |
-- |               xx_cn_om_trx table batch wise                 |
-- |                                                             |
-- | Parameters  : x_errbuf             OUT   VARCHAR2           |
-- |               x_retcode            OUT   NUMBER             |
-- |               p_batch_id           IN    VARCHAR2           |
-- |               p_process_audit_id   IN    VARCAHR2           |
-- |                                                             |
-- +=============================================================+


PROCEDURE om_extract_child ( x_errbuf            OUT VARCHAR2
                            ,x_retcode           OUT NUMBER
                            ,p_batch_id          IN  NUMBER
                            ,p_process_audit_id  IN  NUMBER
                          );

END XX_CN_OM_EXTRACT_PKG;
/

SHOW ERRORS

EXIT;