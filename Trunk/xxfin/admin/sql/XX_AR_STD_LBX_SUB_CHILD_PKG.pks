CREATE OR REPLACE PACKAGE APPS.XX_AR_STD_LBX_SUB_CHILD_PKG AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XX_AR_STD_LBX_SUB_CHILD_PKG.pks                                    |
-- | Description: OD: AR Standard Lockbox Submission Program - Child                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  10-APR-2010  Sundaram S         Initial draft version                  |
-- +=================================================================================+
-- | Name        : XX_AR_STD_LBX_SUB_CHILD_PKG                                       |
-- | Description : This procedure will be used to Submit Processs Lockbox            |
-- |               and invoke BPEL process to release ESP jobs                       |
-- | Parameters  : x_errbuf                                                          |
-- |              ,x_retcode                                                         |
-- |              ,p_trans_name                                                      |
-- |              ,p_custom_main_req_id                                              |
-- |              ,p_transmission_id                                                 |
-- |              ,p_trans_request_id                                                |
-- |              ,p_trans_format_id                                                 |
-- |              ,p_gl_date                                                         |
-- |              ,p_email_notify_flag                                               |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- +=================================================================================+
  PROCEDURE XX_PROC_LBX_CHILD_MAIN ( x_errbuf                  OUT     NOCOPY     VARCHAR2
                                    ,x_retcode                 OUT     NOCOPY     NUMBER
                                    ,p_file_name               IN                 VARCHAR2
                                    ,p_custom_main_req_id      IN                 NUMBER
                                    ,p_transmission_id         IN                 NUMBER
                                    ,p_trans_request_id        IN                 NUMBER
                                    ,p_trans_format_id         IN                 NUMBER
                                    ,p_gl_date                 IN                 DATE
                                    ,p_email_notify_flag       IN                 VARCHAR2);
END XX_AR_STD_LBX_SUB_CHILD_PKG;
/
