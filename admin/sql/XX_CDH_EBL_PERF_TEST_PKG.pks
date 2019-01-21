CREATE OR REPLACE PACKAGE XX_CDH_EBL_PERF_TEST_PKG
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_PERF_TEST_PKG                                    |
-- | Description :                                                             |
-- | This package will validate entire data before changing the document       |
-- |             status, to make sure that the data is Valid. It will insert   |
-- |             file naming parameters if the file naming parameters are      |
-- |             are not present                                               |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author               Remarks                          |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 08-JUL-2010 Parameswaran S N     Initial draft version            |
-- |                                                                           |
-- |===========================================================================|
AS
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_VALD_PROG                                        |
-- | Description :                                                             |
-- | This program will validate entire data before changing the document       |
-- |             status to COMPLETE                                            |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author               Remarks                          |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 08-JUL-2010 Parameswaran S N     Initial draft version            |
-- |                                                                           |
-- |===========================================================================|
    PROCEDURE XX_CDH_EBL_VALID_PROG  (x_error_buff        OUT VARCHAR2
                                     ,x_ret_code          OUT NUMBER
                                     ,p_summary_id        IN NUMBER
                                     ,p_delivery_mthd     IN VARCHAR2
                                     ,p_no_of_documents   IN NUMBER
                                      );
END XX_CDH_EBL_PERF_TEST_PKG;
/
