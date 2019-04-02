SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_CE_TMS_JE_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

create or replace 
PACKAGE XX_CE_MPL_SETTLEMENT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_CE_MPL_SETTLEMENT_PKG                                                         |
  -- |  RICE ID   :  I3091_CM Marketplace Inbound Interface                                       |
  -- |  Description:  Insert from XX_CE_MPL_SETTLEMENT_PKG into XX_CE_AJB996,XX_CE_AJB998,        |
  -- |                                                                        XX_CE_AJB999        |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         09/18/2014   Avinash Baddam   Initial version                                  |
  -- | 1.6         11/10/2017   Digamber S       Enhancement  for LLC file processing             |
  -- |                                           main_llc ,process_data_998,process_data_999      |
  -- |                                           main_wraper procedure Added                      |
  -- | 1.7         26-MAR-2019  Pramod M K       Code Changes for Amazon Prime NAIT-85869 
  -- +============================================================================================+
TYPE varchar2_table
IS
  TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
  PROCEDURE log_exception(
      p_program_name   IN VARCHAR2 ,
      p_error_location IN VARCHAR2 ,
      p_error_msg      IN VARCHAR2);
  PROCEDURE parse(
      p_delimstring IN VARCHAR2 ,
      p_table OUT varchar2_table ,
      p_nfields OUT INTEGER ,
      p_delim IN VARCHAR2 DEFAULT chr(
        9) ,
      p_error_msg OUT VARCHAR2 ,
      p_retcode OUT VARCHAR2);
  PROCEDURE load_staging(
      p_errbuf OUT VARCHAR2 ,
      p_retcode OUT VARCHAR2 ,
      p_file_name VARCHAR2);
  PROCEDURE duplicate_check(
      p_ajb_file_name VARCHAR2,
      p_error_msg OUT VARCHAR2,
      p_retcode OUT VARCHAR2);
  PROCEDURE process_staging(
      p_settlement_id NUMBER,
      p_error_msg OUT VARCHAR2,
      p_retcode OUT VARCHAR2);
  PROCEDURE process_data_998(
      p_process_name  VARCHAR2,
      p_settlement_id NUMBER,
      p_deposit_date  DATE,
      p_ajb_file_name VARCHAR2,
      p_error_msg OUT VARCHAR2,
      p_retcode OUT VARCHAR2);
  PROCEDURE process_data_999(
      p_process_name  VARCHAR2,
      p_settlement_id NUMBER,
      p_deposit_date  DATE,
      p_ajb_file_name VARCHAR2,
      p_error_msg OUT VARCHAR2,
      p_retcode OUT VARCHAR2);
  PROCEDURE insert_ajb998(
      p_record_type     VARCHAR2 ,
      p_action_code     VARCHAR2 ,
      p_provider_type   VARCHAR2 ,
      p_store_num       VARCHAR2 ,
      p_trx_type        VARCHAR2 ,
      p_trx_amount      NUMBER ,
      p_invoice_num     VARCHAR2 ,
      p_country_code    VARCHAR2 ,
      p_currency_code   VARCHAR2 ,
      p_receipt_num     VARCHAR2 ,
      p_bank_rec_id     VARCHAR2 ,
      p_trx_date        DATE ,
      p_processor_id    VARCHAR2 ,
      p_status_1310     VARCHAR2 ,
      p_ajb_file_name   VARCHAR2 ,
      p_created_by      NUMBER ,
      p_last_updated_by NUMBER ,
      p_org_id          NUMBER ,
      p_recon_date      DATE ,
      p_territory_code  VARCHAR2 ,
      p_currency        VARCHAR2 ,
      p_card_type       VARCHAR2);
  PROCEDURE insert_ajb999(
      p_record_type     VARCHAR2,
      p_store_num       VARCHAR2,
      p_provider_type   VARCHAR2,
      p_submission_date DATE,
      p_country_code    VARCHAR2,
      p_currency_code   VARCHAR2,
      p_processor_id    VARCHAR2,
      p_bank_rec_id     VARCHAR2,
      p_cardtype        VARCHAR2,
      p_net_sales       NUMBER,
      p_cost_funds_amt  NUMBER,
      p_status_1310     VARCHAR2,
      p_ajb_file_name   VARCHAR2,
      p_created_by      VARCHAR2,
      p_last_updated_by VARCHAR2,
      p_org_id          NUMBER,
      P_Recon_Date      DATE,
      p_territory_code  VARCHAR2,
      P_Currency        VARCHAR2,
	  p_discount_amt    NUMBER);
  --  LLC Change Start
  --  PROCEDURE main(
  --  p_errbuf OUT VARCHAR2 ,
  --  p_retcode OUT VARCHAR2 ,
  --  p_settlement_id NUMBER);
  PROCEDURE main_llc(
      p_errbuf OUT VARCHAR2 ,
      P_Retcode OUT VARCHAR2 ,
      p_process_name  VARCHAR2,
      P_Settlement_Id NUMBER );
  --  LLC Change End
  PROCEDURE write_out(
      P_Message IN VARCHAR2 );
  PROCEDURE write_log(
      P_Message IN VARCHAR2 );
  PROCEDURE main_wraper(
      P_Errbuf OUT VARCHAR2 ,
      P_RETCODE OUT VARCHAR2 ,
      P_PROCESS_NAME VARCHAR2,
      P_REPORT_ID    VARCHAR2 );
 END XX_CE_MPL_SETTLEMENT_PKG;
/
show error
