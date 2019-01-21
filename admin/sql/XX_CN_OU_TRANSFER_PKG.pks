CREATE OR REPLACE PACKAGE XX_CN_OU_TRANSFER_PKG AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_CN_OU_TRANSFER_PKG                                             |
-- |                                                                                |
-- | Rice ID    : E0605_PostCollectionProcess                                       |
-- | Description: Package specification to extract and transfer the eligible lines  |
-- |              between xx_cn_sum_trx and xx_cn_ou_trnsfr tables.                 |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  18-OCT-2007  Hema Chikkanna         Initial draft version             |
-- |1.0       19-OCT-2007  Hema Chikkanna         Incorporated changes After TL's   |
-- |                                              Review.                           |
-- |                                                                                |
-- +================================================================================+

   

-- +==============================================================+
-- | Name        : OU_TRANSFER_MAIN                               |
-- |                                                              |
-- | Description : Procedure to extract and transfer the eligible |
-- |               lines between xx_cn_sum_trx and xx_cn_ou_trnsfr|
-- |               tables.                                        |
-- |                                                              |
-- | Parameters  : x_errbuf         OUT   VARCHAR2                |
-- |               x_retcode        OUT   NUMBER                  |
-- |                                                              |
-- +==============================================================+


PROCEDURE ou_transfer_main  ( x_errbuf      OUT NOCOPY VARCHAR2
                             ,x_retcode     OUT NOCOPY NUMBER
                            ); 



END XX_CN_OU_TRANSFER_PKG;

/
SHOW ERRORS;

EXIT;