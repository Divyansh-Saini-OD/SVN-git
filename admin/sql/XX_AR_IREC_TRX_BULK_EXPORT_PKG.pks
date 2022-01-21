CREATE OR REPLACE PACKAGE APPS.XX_AR_IREC_TRX_BULK_EXPORT_PKG  
AS
-- +======================================================================================+
-- |                        Office Depot                                                  |
-- +======================================================================================+
-- | Name  : XX_AR_IREC_TRX_BULK_EXPORT_PKG                                               |
-- | Rice ID:                                                                             |
-- | Description      :                                                                   |
-- |                                                                                      |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version Date        Author            Remarks                                         |
-- |======= =========== =============== ==================================================|
-- |1.0     28-MAR-2017 Havish Kasina   Initial draft version                             |
-- +======================================================================================+
     
  PROCEDURE EXTRACT(x_errbuf                    OUT NOCOPY    VARCHAR2,
                    x_retcode                   OUT NOCOPY    NUMBER, 
					p_trx_date_from             IN            DATE,
                    p_trx_date_to               IN            DATE,
					p_due_date_from             IN            DATE,
					p_due_date_to               IN            DATE,
					p_amount_due_original_from  IN            NUMBER,
					p_amount_due_original_to    IN            NUMBER,
                    p_session_id                IN            NUMBER,
                    p_ship_to_site_use_id       IN            NUMBER,
					p_customer_number           IN            VARCHAR2,
					p_cust_account_id           IN            NUMBER,
					p_status                    IN            VARCHAR2,
					p_transaction_type          IN            VARCHAR2,
					p_template_type             IN            VARCHAR2,
                    p_mail_to                   IN            VARCHAR2 				   
				   );
END;
/
SHOW ERRORS;

