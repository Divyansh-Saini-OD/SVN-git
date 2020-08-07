create or replace PACKAGE      XX_AP_CUSTOMER_REBATE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_AP_CUSTOMER_REBATE_PKG.pks		       |
-- | RICE ID     :  E3515                                              |
-- | Description :  Plsql package for AP Customer Rebate invoices      |
-- |                                                                   |
-- | Change Record:                                                    |
-- | ===============                                                   |
-- | Version   Date        Author             Remarks                  |
-- | ========  =========== ================== =========================|
-- | 1.0       25-Aug-2016 Radhika Patnala    Initial version          |
-- +===================================================================+
AS
--=================================================================
-- Declaring Global variables
--=================================================================

 gn_request_id        NUMBER := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);


--=================================================================
-- Declaring Global Constants
--=================================================================

 g_user_id             NUMBER:= fnd_global.user_id;
 g_login_id            NUMBER:= fnd_global.login_id;
 gc_debug              VARCHAR2(1):= 'N';
 g_org_id              NUMBER:=FND_PROFILE.VALUE('ORG_ID');


--+==================================================================+
--| Name          : process_rebate                                   |
--| Description   : process_rebate procedure will be called from the |
--|                 concurrent program for invoice Interface         |
--| Parameters    : p_debug_level          IN     VARCHAR2           |
--| Returns       :                                                  |
--|                 x_errbuf               OUT    VARCHAR2           |
--|                 x_retcode              OUT    NUMBER             |
--+==================================================================+

PROCEDURE process_rebate(x_errbuf         OUT NOCOPY VARCHAR2
		        ,x_retcode        OUT NOCOPY NUMBER
			,p_debug_level    IN         VARCHAR2
                        );

END XX_AP_CUSTOMER_REBATE_PKG;
/
Show errors;