CREATE OR REPLACE PACKAGE XX_CN_FAN_EXTRACT_PKG AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_CN_FAN_EXTRACT_PKG                                             |
-- |                                                                                |
-- | Rice ID    : E1004D_CustomCollections_(Fanatic_Extract)                        |
-- | Description: Package specification to extract the fanatic data from staging    |
-- |              table and insert it into XX_CN_NOT_TRX and XX_CN_FAN_TRX tables   |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  12-OCT-2007  Hema Chikkanna         Initial draft version             |
-- |1.0       19-OCT-2007  Hema Chikkanna         Updated After Testing             |
-- |1.1       02-NOV-2007  Hema Chikkanna         Added data type for Error         |
-- |                                              reporting                         |
-- +================================================================================+

   TYPE fantrx_tbl_type IS TABLE OF XX_CN_FAN_TRX%ROWTYPE INDEX BY BINARY_INTEGER;

   lt_fantrx          fantrx_tbl_type;
   lt_fantrx_suc      fantrx_tbl_type;
   lt_fantrx_fal      fantrx_tbl_type;


   TYPE conc_req_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

   lt_conc_req_tbl   conc_req_tbl_type;



-- +=============================================================+
-- | Name        : fanatic_extrcat_main                          |
-- | Description : Procedure to extract the fanatic data and     |
-- |               insert it into xx_cn_not_trx table            |
-- |                                                             |
-- |                                                             |
-- | Parameters  : x_errbuf         OUT   VARCHAR2               |
-- |               x_retcode        OUT   NUMBER                 |
-- |               p_mode           IN    VARCHAR2               |
-- |               p_start_date     IN    VARCAHR2               |
-- |               p_end_date       IN    VARCAHR2               |
-- |                                                             |
-- +=============================================================+


PROCEDURE fanatic_extract_main ( x_errbuf      OUT NOCOPY VARCHAR2
                                ,x_retcode     OUT NOCOPY NUMBER
                                ,p_mode        IN  VARCHAR2
                                ,p_start_date  IN  VARCHAR2
                                ,p_end_date    IN  VARCHAR2
                               );


-- +=============================================================+
-- | Name        : fanatic_extrcat_child                         |
-- | Description : Procedure to extract the uncollected data from|
-- |               xx_cn_not_trx table and insert it into        |
-- |               xx_cn_fan_trx table batch wise                |
-- |                                                             |
-- | Parameters  : x_errbuf             OUT   VARCHAR2           |
-- |               x_retcode            OUT   NUMBER             |
-- |               p_batch_id           IN    VARCHAR2           |
-- |               p_process_audit_id   IN    VARCAHR2           |
-- |                                                             |
-- +=============================================================+


PROCEDURE fanatic_extract_child ( x_errbuf            OUT NOCOPY VARCHAR2
                                 ,x_retcode           OUT NOCOPY NUMBER
                                 ,p_batch_id          IN  NUMBER
                                 ,p_process_audit_id  IN  NUMBER
                                );

END XX_CN_FAN_EXTRACT_PKG;
/

SHOW ERRORS

EXIT;
