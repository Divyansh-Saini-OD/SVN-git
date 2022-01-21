create or replace
PACKAGE XX_AR_AB_ARCHIVE_INV_RCPT_PKG
  --+======================================================================+
  --|      Office Depot -                                                  |
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
  --| Parameters : p_lvl1_rowcnt   -- This parameter is used to fetch the   |
  --|                                 initial first level data, based on    |
  --|                                 this the further chain will be fetched|
  --+=======================================================================+
AS
PROCEDURE POPULATE_AB_INV_RCPT (
                                 x_errbuf          OUT      VARCHAR2
                                ,X_RETCODE         OUT      VARCHAR2
                                ,p_lvl1_rowcnt     IN       NUMBER
                               );


END XX_AR_AB_ARCHIVE_INV_RCPT_PKG;