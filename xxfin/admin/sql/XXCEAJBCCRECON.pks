CREATE OR REPLACE PACKAGE XX_CE_AJB_CC_RECON_PKG AS 
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XXCEAJBCCRECON.pks                                                 |
-- | Description: Cash Management AJB Creditcard Reconciliation E1310-Extension      |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  14-AUG-2007  Sunayan Mohanty    Initial draft version                  |
-- |                                                                                 |
-- +=================================================================================+
-- | Name        : RECON_PROCESS                                                     |
-- | Description : This procedure will be used to process the                        |
-- |               Cash Management AJB Creditcard Reconciliation                     |
-- |                                                                                 |
-- | Parameters  : p_run_from_date   IN DATE                                         |
-- |               p_run_to_date     IN DATE                                         |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- +=================================================================================+

PROCEDURE  recon_process 
                        (x_errbuf           OUT   NOCOPY VARCHAR2
                        ,x_retcode          OUT   NOCOPY NUMBER
                        ,p_email_id         IN           VARCHAR2  DEFAULT NULL
                        ,p_match_process    IN           VARCHAR2  DEFAULT NULL
                        );

PROCEDURE  stmt_match_process 
                        (x_errbuf           OUT   NOCOPY   VARCHAR2
                        ,x_retcode          OUT   NOCOPY   NUMBER
                        ,p_email_id         IN             VARCHAR2  DEFAULT NULL                        
                        );


FUNCTION get_provider_code ( p_bank_account      IN   ap_bank_accounts.bank_account_num%TYPE
                            ,p_description       IN   ce_statement_lines.trx_text%TYPE
                           )RETURN CHAR;


END XX_CE_AJB_CC_RECON_PKG;
/
SHOW ERROR;
EXIT;

-- -------------------------------------------------------------------
-- End of Script                                                   
-- -------------------------------------------------------------------
