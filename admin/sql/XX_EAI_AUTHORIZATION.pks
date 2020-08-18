create or replace PACKAGE XX_EAI_AUTHORIZATION IS

--
-- Setting Global variables
--
G_PKG_NAME CONSTANT VARCHAR2(30) := 'XX_EAI_AUTHORIZATION';

G_DEBUG_MODULE CONSTANT VARCHAR2(100):='XX_EAI_AUTHORIZATION';
G_CURRENT_RUNTIME_LEVEL CONSTANT NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
G_LEVEL_UNEXPECTED      CONSTANT NUMBER       := FND_LOG.LEVEL_UNEXPECTED;
G_LEVEL_ERROR           CONSTANT NUMBER       := FND_LOG.LEVEL_ERROR;
G_LEVEL_EXCEPTION       CONSTANT NUMBER       := FND_LOG.LEVEL_EXCEPTION;
G_LEVEL_EVENT           CONSTANT NUMBER       := FND_LOG.LEVEL_EVENT;
G_LEVEL_PROCEDURE       CONSTANT NUMBER       := FND_LOG.LEVEL_PROCEDURE;
G_LEVEL_STATEMENT       CONSTANT NUMBER       := FND_LOG.LEVEL_STATEMENT;

G_RC_INVALID_PAYEE CONSTANT VARCHAR2(30) := 'INVALID_PAYEE';
G_RC_AUTH_SUCCESS CONSTANT VARCHAR2(30) := 'AUTH_SUCCESS';
G_RC_EXTENSION_IMMUTABLE CONSTANT VARCHAR2(30) := 'EXTENSION_NOT_UPDATEABLE';
G_RC_INVALID_EXTENSION_ATTRIB CONSTANT VARCHAR2(30) := 'INVALID_EXTENSION_ATTRIB';
G_RC_INVALID_EXTENSION_ID CONSTANT VARCHAR2(30) := 'INVALID_TXN_EXTENSION';
G_RC_DUPLICATE_AUTHORIZATION CONSTANT VARCHAR2(30) := 'DUPLICATE_AUTH';
  -- +==================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- +===================================================================================+
  -- | Name        : GET_TRANSLATION                                                     |
  -- | Description : copy of standard iby_fndcpt_trxn_pub.create_authorization, modified |
  -- |               for JIRA  NAIT-129669                                               |
  -- |Parameters   : p_translation_name                                                  |
  -- |             : p_source_value1                                                     |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
  -- +===================================================================================+
PROCEDURE Create_Authorization
            (
            p_api_version      IN   NUMBER,
            p_init_msg_list    IN   VARCHAR2  := FND_API.G_FALSE,
            x_return_status    OUT NOCOPY VARCHAR2,
            x_msg_count        OUT NOCOPY NUMBER,
            x_msg_data         OUT NOCOPY VARCHAR2,
            p_payer            IN   IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type,
            p_payer_equivalency IN  VARCHAR2 :=
              IBY_FNDCPT_COMMON_PUB.G_PAYER_EQUIV_UPWARD,
            p_payee            IN   IBY_FNDCPT_TRXN_PUB.PayeeContext_rec_type,
            p_trxn_entity_id   IN   NUMBER,
            p_auth_attribs     IN   IBY_FNDCPT_TRXN_PUB.AuthAttribs_rec_type,
            p_amount           IN   IBY_FNDCPT_TRXN_PUB.Amount_rec_type,
            x_auth_result      OUT NOCOPY IBY_FNDCPT_TRXN_PUB.AuthResult_rec_type,
            x_response         OUT NOCOPY IBY_FNDCPT_COMMON_PUB.Result_rec_type
            );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : XX_CAPTURE                                                          |
-- | Description : Procedure to capture ORAPMTCAPTURE Event and populate               |
-- |                xx_ar_order_details                                                |
-- |Parameters   : p_trxn_extension_id                                                 |
-- |             , p_payer                                                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
PROCEDURE xx_capture(p_trxn_id              IN  NUMBER,
                     x_transaction_id_out   OUT iby_trxn_summaries_all.TransactionID%TYPE,
                     x_transaction_mid_out  OUT iby_trxn_summaries_all.trxnmid%TYPE,
                     p_ret_status           OUT VARCHAR2,
                     p_ret_error            OUT VARCHAR2);
END XX_EAI_AUTHORIZATION;
/