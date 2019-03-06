SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CS_MPS_CONTRACTS_PKG AS 
  -- +==============================================================================================+
  -- |                            Office Depot - Project Simplify                                   |
  -- |                                    Office Depot                                              |
  -- +==============================================================================================+
  -- | Name  : XX_CS_MPS_CONTRACTS_PKG.pks                                                          |
  -- | Description  : This package contains procedures related to MPS Contracts                     |
  -- |Change Record:                                                                                |
  -- |===============                                                                               |
  -- |Version    Date          Author             Remarks                                           |
  -- |=======    ==========    =================  ==================================================|
  -- |1.0        07-AUG-2012   Bapuji Nanapaneni  Initial version                                   |
  -- |                                                                                              |
  -- +==============================================================================================+
  /* Global Variables Declaration */

  g_login_id        fnd_user.user_id%TYPE   := fnd_global.login_id;
  g_user_name       fnd_user.user_name%TYPE := 'CS_ADMIN';

  -- +=====================================================================+
  -- | Name  : sfdc_proc                                                   |
  -- | Description      : This Procedure will identify customer if not will|
  -- |                    created party name                               |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_party_id      IN NUMBER party ID               |
  -- |                    p_sales_rep     IN VARCHAR2 Sales Rep Name       |
  -- |                    p_contract_type IN VARCHAR2 Contact Type         |
  -- |                    x_return_status IN OUT VARCHAR2 Return status    |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message   |
  -- +=====================================================================+
  PROCEDURE sfdc_proc( p_party_id      IN NUMBER
                     , p_sales_rep     IN VARCHAR2
                     , p_contract_type IN VARCHAR2
                     , x_return_status IN OUT NOCOPY VARCHAR2
                     , x_return_msg    IN OUT NOCOPY VARCHAR2
                     );

  -- +=====================================================================+
  -- | Name  : contract_proc                                               |
  -- | Description      : This Procedure will created a contract for MPS   |
  -- |                    orders                                           |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:       p_customer      IN OUT NUMBER customer            |
  -- |                   p_cont_rec      IN OUT XX_CS_MPS_CONTRACT_REC_TYPE|
  -- |                   x_return_status IN OUT VARCHAR2 Return status     |
  -- |                   x_return_msg    IN OUT VARCHAR2 Return Message    |
  -- +=====================================================================+
  PROCEDURE contract_proc ( p_customer       IN OUT NUMBER
                          , p_cont_rec       IN OUT XX_CS_MPS_CONTRACT_REC_TYPE
                          , x_return_status  IN OUT VARCHAR2
                          , x_return_msg     IN OUT NOCOPY VARCHAR2
						  );

  PROCEDURE log_exception( p_object_id          IN  VARCHAR2
                         , p_error_location     IN  VARCHAR2
                         , p_error_message_code IN  VARCHAR2
                         , p_error_msg          IN  VARCHAR2
                         );

END XX_CS_MPS_CONTRACTS_PKG;
/
SHOW ERRORS PACKAGE XX_CS_MPS_CONTRACTS_PKG;
--EXIT;