-- Create table
create global temporary table XXFIN.OD_ABL_CONS_TBL
(
  OP_UNIT            NUMBER(15),
  ORACLE_ACCT_NO     VARCHAR2(30) not null,
  OPEN_AMT           NUMBER not null,
  ORG_AMT            NUMBER not null,
  TRANSACTION_NUMBER VARCHAR2(20),
  PRINT_DATE         DATE,
  INVOICE_DATE       DATE not null,
  DUE_DATE           DATE not null,
  LEGEND             VARCHAR2(20),
  EXCEPTION_ITEM     CHAR(1),
  CUSTOMER           VARCHAR2(240),
  DELIVERY_METHOD    VARCHAR2(150),
  STATUS             VARCHAR2(20)
)
on commit preserve rows;