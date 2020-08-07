CREATE OR REPLACE
PACKAGE XX_AR_AB_ARCHIVE_INV_RCPT_PKG
  --+======================================================================+
  --|      Office Depot -   RICE#E3097                                     |
  --+======================================================================+
  --|Name       : XX_AR_AB_ARCHIVE_INV_RCPT_PKG.pks                        |
  --|Description: This Package is used for fetching all the likely         |
  --|             AB invoices/CMs and receipts for archiving               |
  --|                                                                      |
  --|                                                                      |
  --|                                                                      |
  --|Change Record:                                                        |
  --|===============                                                       |
  --| 05-Apr-2018   Capgemini  Intial Draft                                |
  --+======================================================================+
  --+=======================================================================+
  --| Name : POPULATE_AB_INV_RCPT                                           |
  --| Description : The POPULATE_AB_INV_RCPT proc will perform the following|
  --|                                                                       |
  --|             1. Fetch all the receipts for a particular set of         |
  --|                invoices                                               |
  --|             2. In the recursive fashion, pick all the corresponding   |
  --|                invoices/CMs                                           |
  --|             3. Check if the entire invoice-CM-receipt transaction     |
  --|                chain is fetched                                       |
  --|                                                                       |
  --| Parameters : p_rowcnt        -- This parameter is used to fetch the   |
  --|                                 initial first level data, based on    |
  --|                                 this the further chain will be fetched|
  --|              p_cutoff_dt     -- This parameter is used to determine   |
  --|                                 the date until which the transactions |
  --|                                 are eligible to be purged.            |
  --|              p_delete_flag   -- This parameter is used as a deciding  |
  --|                                 factor to delete the historical data  |
  --|                                 in the custom table or not.           |
  --+=======================================================================+
AS
PROCEDURE POPULATE_AB_INV_RCPT(
    x_errbuf OUT VARCHAR2 ,
    x_retcode OUT VARCHAR2 ,
    p_rowcnt      IN NUMBER ,
    p_cutoff_dt   IN VARCHAR2, 
    p_delete_flag IN VARCHAR2 DEFAULT 'N' );
  --+=======================================================================+
  --| Name : UPDATE_CHAIN_COMP_INCOMP                                       |
  --| Description : The UPDATE_CHAIN_COMP_INCOMP proc will perform the      |
  --|               following                                               |
  --|             1. Update all the transactions for a particular set of    |
  --|                invoice fetched in level1 forming a chain to           |
  --|                complete = 'Y' when all the records are fetched and    |
  --|                the chain is complete or to 'N' when there is a        |
  --|                record with gl_date in the last 4 years                |
  --|                                                                       |
  --| Parameters : p_top_node      -- This parameter is used to fetch the   |
  --|                                 all the transactions belonging        |
  --|                                 to a particular chain                 |
  --|              p_cutoff_dt     -- This parameter is used to determine   |
  --|                                 the date until which the transactions |
  --|                                 are eligible to be purged.            |
  --|              conc_request_id -- This is to capture the request id     |
  --|                                 of the current run.                   |
  --+=======================================================================+
PROCEDURE UPDATE_CHAIN_COMP_INCOMP(
    p_top_node    IN NUMBER,
    p_cutoff_date IN DATE, 
    p_conc_request_id IN NUMBER
  );
--+=======================================================================+
--| Name : UPDATE_HISTORICAL_DATA                                         |
--| Description : The UPDATE_HISTORICAL_DATA proc will perform the        |
--|               following                                               |
--|             1. Find all the transactions in the table with            |
--|                complete column value as 'N', check if the records are |
--|                eligible to be purged in the current run for the given |
--|                cutoff date. If Yes, then find additional transactions |
--|                if any which are part of the chain and then            |
--|                mark the chain as complete with status 'Y'.            |
--|                                                                       |
--| Parameters : conc_request_id -- This is to capture the request id     |
--|                                 of the current run.                   |
--|              p_cutoff_dt     -- This parameter is used to determine   |
--|                                 the date until which the transactions |
--|                                 are eligible to be purged.            |
--|              p_total_trans_countThis parameter is used to limit the   |
--|                                 records to be processed.              |
--+=======================================================================+
PROCEDURE UPDATE_HISTORICAL_DATA (
    p_conc_request_id    IN NUMBER,
    p_cutoff_date        IN DATE,
    p_total_trans_count IN NUMBER,
    p_count_reached     OUT NUMBER); 
--+=======================================================================+
--| Name : BUILD_TRANSACTION_CHAIN                                        |
--| Description : The BUILD_TRANSACTION_CHAIN proc will perform the       |
--|               following                                               |
--|             1. Build the transaction chain for a given invoice        |
--|                at level 1                                             |
--|                                                                       |
--| Parameters : p_top_node      -- This parameter is used to fetch the   |
--|                                 all the transactions belonging        |
--|                                 to a particular chain                 |
--|              conc_request_id -- This is to capture the request id     |
--|                                 of the current run.                   |
--+=======================================================================+
PROCEDURE BUILD_TRANSACTION_CHAIN(
    p_top_node    IN NUMBER,
    p_conc_request_id in number);
END XX_AR_AB_ARCHIVE_INV_RCPT_PKG;
/