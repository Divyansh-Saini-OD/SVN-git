CREATE OR REPLACE PACKAGE ZX_PTNR_SRVC_INTGRTN_PKG AUTHID CURRENT_USER AS
/* $Header: zxifptnrintpkgs.pls 120.9 2006/03/14 07:10:39 vchallur ship $ */
/* ======================================================================*
 | Global Data Types                                                     |
 * ======================================================================*/

/* In code generator,we are declaring these global variables in package body.
   Hence commenting in package specification.
G_PKG_NAME              CONSTANT VARCHAR2(50) := 'ZX_PTNR_SRVC_INTGRTN_PKG';
G_CURRENT_RUNTIME_LEVEL CONSTANT NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
G_LEVEL_UNEXPECTED      CONSTANT NUMBER       := FND_LOG.LEVEL_UNEXPECTED;
G_LEVEL_ERROR           CONSTANT NUMBER       := FND_LOG.LEVEL_ERROR;
G_LEVEL_EXCEPTION       CONSTANT NUMBER       := FND_LOG.LEVEL_EXCEPTION;
G_LEVEL_EVENT           CONSTANT NUMBER       := FND_LOG.LEVEL_EVENT;
G_LEVEL_PROCEDURE       CONSTANT NUMBER       := FND_LOG.LEVEL_PROCEDURE;
G_LEVEL_STATEMENT       CONSTANT NUMBER       := FND_LOG.LEVEL_STATEMENT;
G_MODULE_NAME           CONSTANT VARCHAR2(250):= 'ZX.PLSQL.ZX_PTNR_SRVC_INTGRTN_PKG.';*/

/* ======================================================================*
 | Global Structure Data Types                                           |
 * ======================================================================*/

  G_TAX_CURRENCIES_TBL    ZX_TAX_PARTNER_PKG.tax_currencies_tbl_type;
  G_TAX_LINES_RESULT_TBL  ZX_TAX_PARTNER_PKG.tax_lines_tbl_type;
  G_TRX_REC               ZX_TAX_PARTNER_PKG.trx_rec_type;
  G_SYNC_TAX_LINES_TBL    ZX_TAX_PARTNER_PKG.output_sync_tax_lines_tbl_type;
--  G_MESSAGES_TBL          ZX_TAX_PARTNER_PKG.messages_rec_type;
  G_MESSAGES_TBL          ZX_TAX_PARTNER_PKG.messages_tbl_type;
  G_EXEMPTION_REC         ZX_TAX_PARTNER_PKG.exemption_rec_type;
  G_EXEMPTION_TBL         ZX_TAX_PARTNER_PKG.exemptions_tbl_type;
  G_EXEMPTION_MSG_TBL     ZX_TAX_PARTNER_PKG.exmpt_messages_tbl_type;
  G_ERROR_STATUS          VARCHAR2(1);



PROCEDURE invoke_third_party_interface (
  p_api_owner_id       IN NUMBER,
  p_service_type_id    IN NUMBER,
  p_context_ccid       IN NUMBER,
  p_data_transfer_mode IN VARCHAR2,
  x_return_status      OUT NOCOPY VARCHAR2
  );

END ZX_PTNR_SRVC_INTGRTN_PKG;

/