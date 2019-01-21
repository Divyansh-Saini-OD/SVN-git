CREATE OR REPLACE PACKAGE APPS.XX_CDH_OMX_EBILL_CONTACTS_PKG 
AS
-- +==================================================================================+
-- |                        Office Depot                                              |
-- +==================================================================================+
-- | Name  : XX_CDH_OMX_EBILL_CONTACTS_PKG                                            |
-- | Rice ID: C0700                                                                   |
-- | Description      : This program will process all the records and creates the     |
-- |                    ebilling contacts and link to corresponding billing document  |                      
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version Date        Author            Remarks                                     |
-- |======= =========== =============== ==============================================|
-- |1.0     18-FEB-2015 Havish Kasina   Initial draft version                         |
-- |2.0     12-MAR-2015 Havish Kasina   Code Review Changes                           |
-- +==================================================================================+

g_debug_flag           BOOLEAN; 
     
PROCEDURE EXTRACT(
                  x_retcode              OUT NOCOPY    NUMBER,
                  x_errbuf               OUT NOCOPY    VARCHAR2,
                  p_batch_id             IN            NUMBER,
                  p_debug_flag           IN            VARCHAR2,
                  p_aops_customer_number IN            VARCHAR2,
                  p_status               IN            VARCHAR2     
                 );
END;
/
SHOW ERRORS;
