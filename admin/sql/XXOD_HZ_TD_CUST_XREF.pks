CREATE OR REPLACE
PACKAGE  XXOD_HZ_TD_CUST_XREF_PKG  
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:   XXOD_HZ_TD_CUST_XREF_PKG                                                          |
-- |  Description:  Insert into XXOD_HZ_TD_CUST_XREF.  	  				        |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03/02/2014   Avinash Baddam   Initial version                                  |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: INSERT_PROC                                                                         |
-- |  Description: This procedure will insert tech depot - oracle customer cross reference      |
-- |               data from XXOD_HZ_TD_CUST_XREF_STG into XXOD_HZ_TD_CUST_XREF tables.         |
-- =============================================================================================|
PROCEDURE insert_proc (p_errbuf            OUT VARCHAR2
                      ,p_retcode           OUT VARCHAR2
                      ,p_batch_id            IN  NUMBER);
                      
-- +===================================================================+
-- | Name  : update_batch                                              |
-- |                                                                   |
-- | Description:       This Procedure updates the batch id of the     |
-- |                    staging table XXOD_HZ_TD_CUST_XREF_STG for     |
-- |                    each file                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE update_batch(p_errbuf          OUT NOCOPY  varchar2 ,
                       p_retcode         OUT NOCOPY  varchar2 ,
                       p_batch_id        IN   number);                      

-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+                      
PROCEDURE write_out(
                    p_message IN VARCHAR2
                   );

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_log(
                    p_message IN VARCHAR2
                   );

-- +===================================================================+
-- | Name  : upload                                                    |
-- |                                                                   |
-- | Description:       This Procedure will submit the programs to     |
-- |                    upload the data                                |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+                   
PROCEDURE upload(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_request_set_id  OUT NOCOPY  number   , 
                    p_file_name       IN  varchar2   
                  );                   
 
END  XXOD_HZ_TD_CUST_XREF_PKG;
/
SHOW ERRORS;
