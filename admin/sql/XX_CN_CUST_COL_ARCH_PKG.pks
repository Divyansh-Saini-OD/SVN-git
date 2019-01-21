CREATE OR REPLACE PACKAGE XX_CN_CUST_COL_ARCH_PKG AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_CN_CUST_COL_ARCH_PKG                                           |
-- |                                                                                |
-- | Rice ID    : E1004B_CustomCollections_(Archiving)                              |
-- | Description: Package to archive all the tables related to custom collections   |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  15-Nov-2007  Hema Chikkanna         Initial draft version             |
-- |1.0       21-Nov-2007  Hema Chikkanna         Incorporated the review comments  |
-- +================================================================================+


-- +=============================================================+
-- | Name        : archive_main                                  |
-- | Description : Procedure to                                  |
-- |                                                             |
-- | Parameters  : x_errbuf         OUT   VARCHAR2               |
-- |               x_retcode        OUT   NUMBER                 |
-- +=============================================================+


PROCEDURE archive_main  (
                            x_errbuf      OUT NOCOPY VARCHAR2
                           ,x_retcode     OUT NOCOPY NUMBER
                        );
                        
-- +=============================================================+
-- | Name        : archive_child                                 |
-- | Description : Procedure                                     |
-- |                                                             |
-- | Parameters  : x_errbuf             OUT   VARCHAR2           |
-- |               x_retcode            OUT   NUMBER             |
-- |               p_batch_id           IN    VARCHAR2           |
-- |               p_table_name         IN    VARCAHR2           |
-- |                                                             |
-- +=============================================================+


PROCEDURE archive_child ( 
                           x_errbuf            OUT NOCOPY VARCHAR2
                          ,x_retcode           OUT NOCOPY NUMBER
                          ,p_batch_id          IN  NUMBER DEFAULT NULL 
                          ,p_table_name        IN  VARCHAR2
                          ,p_archive_date      IN  VARCHAR2
                       );
                           

END XX_CN_CUST_COL_ARCH_PKG;
/

SHOW ERRORS

EXIT;                        

