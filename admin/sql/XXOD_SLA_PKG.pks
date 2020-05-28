create or replace PACKAGE xxod_sla_pkg
AS
  -- +===================================================================+
  -- |                  Office Depot - R12 Upgrade Project               |
  -- |                    Office Depot Organization                      |
  -- +===================================================================+
  -- | Name  : XXOD_SLA_PKG                                              |
  -- | Description :  This PKG will be used to Derive COGS Account and   |
  -- |                 amount values based on interface line id          |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author          Remarks                      |
  -- |=======   ==========  =============   ============================ |
  -- |1.0      19-Sep-2013  Manasa D        E3063 - Initial draft version|
  -- |1.1      15-Jan-2014  Jay Gupta       Added Tax_location Function  |
  -- |                                      Defect#27223                 |
  -- |1.2      16-Oct-2014  Gayathri.K      Defect#31379                 |
  -- |1.3      01-Aug-2017  Sridhar Gajjala Customizing the Write-Off    |
  -- |                                      Accounting                   |
  -- |1.4      10-Nov-2017  Paddy Sanjeevi  Added INV_LOB                |
  -- |1.5      30-Nov-2017  Havish Kasina   Changed the input parameter  |
  -- |                                      from p_distribution_id to    |
  -- |                                      p_write_off_id               |
  -- |1.6      23-Jan-2018  Paddy Sanjeevi  Added Dropship Accrual Acct  |
  -- |1.7      12-Feb-2018  Paddy Sanjeevi  Added for chargeback_acct    |
  -- |1.8      24-May-2020  Sreedhar Mohan  new functions for service    |
  -- |                                      subscription cogs and amount |
  -- +===================================================================+

  -- +==============================================================================+
  -- | Name         :chargeback_acct                                                |
  -- | Description  :This Function return the inventory shrink account for chbk     |
  -- |                                                                              |
  -- | Parameters   :p_invoice_dist_id                                              |
  -- |                                                                              |
  -- +==============================================================================+

  FUNCTION chargeback_acct(p_invoice_dist_id IN NUMBER) RETURN VARCHAR2;



  -- +==============================================================================+
  -- | Name         :dropship_accrual_acct                                          |
  -- | Description  :This Function return the accrual account for Dropship Source   |
  -- |                                                                              |
  -- | Parameters   :p_header_id                                                    |
  -- |                                                                              |
  -- +==============================================================================+

  FUNCTION DROPSHIP_ACCRUAL_ACCT(p_header_id IN NUMBER) RETURN VARCHAR2;

  -- +===================================================================+
  -- | Name         :INV_LOB                                             |
  -- | Description  :This Procedure derive the LOB for the transaction_id|
  -- | Parameters   :p_transaction_id                                    |
  -- |                                                                   |
  -- +===================================================================+
  FUNCTION INV_LOB (p_transaction_id IN NUMBER) RETURN VARCHAR2;

  -- +===================================================================+
  -- | Name         :COGS                                                |
  -- | Description  :This Procedure derive the COGS Value attribute7     |
  -- |               based on the interface line id  from the AR tables  |
  -- | Parameters   :p_trx_line_id                                       |
  -- |                                                                   |
  -- +===================================================================+
  FUNCTION cogs(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2;
  -- +===================================================================+
  -- | Name         :INV                                                 |
  -- | Description  :This Procedure derive the INV Value attribute8/10   |
  -- |               based on the interface line id  from the AR tables  |
  -- | Parameters   :p_trx_line_id                                       |
  -- |                                                                   |
  -- +===================================================================+
  FUNCTION inv(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2;
  -- +===================================================================+
  -- | Name         :COGS_AMOUNT                                         |
  -- | Description  :This Procedure derive the Amount for invoice        |
  -- |               based on the interface line id  from the AR tables  |
  -- | Parameters   :p_trx_line_id                                       |
  -- |                                                                   |
  -- +===================================================================+
  FUNCTION cogs_amount(
      p_trx_line_id IN NUMBER)
    RETURN NUMBER;
  -- +===================================================================+
  -- | Name         :SUBS_COGS                                           |
  -- | Description  :This Procedure derive the COGS Value attribute7     |
  -- |               based on the interface line id  from the AR tables  |
  -- | Parameters   :p_trx_line_id                                       |
  -- |                                                                   |
  -- +===================================================================+
  FUNCTION subs_cogs(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2;
  -- +===================================================================+
  -- | Name         :SUBS_INV                                            |
  -- | Description  :This Procedure derive the INV Value attribute8/10   |
  -- |               based on the interface line id  from the AR tables  |
  -- | Parameters   :p_trx_line_id                                       |
  -- |                                                                   |
  -- +===================================================================+
  FUNCTION subs_inv(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2;
  -- +===================================================================+
  -- | Name         :SUBS_COGS_AMOUNT                                    |
  -- | Description  :This Procedure derive the Amount for invoice        |
  -- |               based on the interface line id  from the AR tables  |
  -- | Parameters   :p_trx_line_id                                       |
  -- |                                                                   |
  -- +===================================================================+
  FUNCTION subs_cogs_amount(
      p_cust_trx_line_gl_dist_id IN NUMBER)
    RETURN NUMBER;
  -- +===================================================================+
  -- | Name         :CM_COGS_AMOUNT                                      |
  -- | Description  :This Procedure derive the amount for Credit memo    |
  -- |               based on the interface line id  from the AR tables  |
  -- | Parameters   :p_trx_line_id                                       |
  -- |                                                                   |
  -- +===================================================================+
  FUNCTION cm_cogs_amount(
      p_trx_line_id IN NUMBER)
    RETURN NUMBER;
  -- +===================================================================+
  -- | Name         :TAX_LOCATION                                        |
  -- | Description  :This derives the account of associated 8 series     |
  -- | Parameters   :p_trx_line_id                                       |
  -- +===================================================================+
  --V1.1
  FUNCTION tax_location(
      p_dist_cc_id IN NUMBER)
    RETURN VARCHAR2;
  --  +=============================================================================+
  -- | Name         :INV_LOCATION                                              |
  -- | Description  :This Function derives the location for Invoice?s               |
  -- |               Inventory Line Location segment based on the interface line id |
  -- |                 from the gl table                                            |
  -- | Parameters   :p_trx_line_id                                                  |
  -- |                                                                              |
  -- +==============================================================================+
  FUNCTION inv_location(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2; -- Added as part of QC#31379
  --  +=============================================================================+
  -- | Name         :INV_COMPANY                                                    |
  -- | Description  :This Function derives the company for Invoice?s                |
  -- |               Inventory company segment based on the interface line id       |
  -- |                 from the gl table                                            |
  -- | Parameters   :p_trx_line_id                                                  |
  -- |                                                                              |
  -- +==============================================================================+
  FUNCTION inv_company(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2; -- Added as part of QC# 31379
  --  +=============================================================================+
  -- | Name         :ACCRUAL_WRITEOFF                                          |
  -- | Description  :This Function return the custom Account for the Write Off      |
  -- |                process                                                       |
  -- | Parameters   :p_write_off_id                                              |
  -- |                                                                              |
  -- +==============================================================================+
  FUNCTION ACCRUAL_WRITEOFF(
      p_write_off_id IN NUMBER)
    RETURN VARCHAR2;


  -- +==============================================================================+
  -- | Name         :ACCRUAL_WRITEOFF_LOCATION                                         		|
  -- | Description  :This Function return the custom Account for the Write Off      |
  -- |                process                                                       |
  -- | Parameters   :p_write_off_id                                              |
  -- |                                                                              |
  -- +==============================================================================+
  FUNCTION ACCRUAL_WRITEOFF_LOCATION (
	  p_write_off_id in number)
	  return varchar2;

  -- +==============================================================================+
  -- | Name         :ACCRUAL_WRITEOFF_LOB                                         		|
  -- | Description  :This Function return the custom Account for the Write Off      |
  -- |                process                                                       |
  -- | Parameters   :p_write_off_id                                              |
  -- |                                                                              |
  -- +==============================================================================+
  FUNCTION ACCRUAL_WRITEOFF_LOB (
		p_write_off_id in number)
		return varchar2;
  --  +=============================================================================+
  -- | Name         :CONSIGN_MATERIAL_ACCT                                          |
  -- | Description  :This Function return the custom Account for the Write Off      |
  -- |                Process based on the Transaction Type derived from the        |
  -- |                Transaction Id                                                |
  -- | Parameters   :p_transaction_id                                               |
  -- |                                                                              |
  -- +==============================================================================+
  FUNCTION CONSIGN_MATERIAL_ACCT(
      p_transaction_id IN NUMBER)
    RETURN VARCHAR2;
END;