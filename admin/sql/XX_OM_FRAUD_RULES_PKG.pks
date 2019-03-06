SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_fraud_rules_pkg AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_FRAUD_RULES_PKG.pks                                       |
-- | Description      : This Program will load all fraud data  from          |
-- |                    Legacy System into EBIZ                              |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==========================    |
-- |DRAFT 1A   03-SEP-07     Bapuji Nanapaneni Initial Draft Version         |
-- +=========================================================================+

  /* Global Variables */
  gn_org_id        NUMBER; --:= FND_PROFILE.VALUE('ORG_ID');
  gn_condition_id    xx_om_fraud_rules_stg.condition_id%TYPE;
  gn_request_id            NUMBER ;
  g_exception xxom.xx_om_report_exception_t := xxom.xx_om_report_exception_t
                                              (  'OTHERS'
                                              ,  'OTC'
                                              ,  'Order Management'
                                              ,  'Fraud Rules'
                                              ,  NULL
                                              ,  NULL
                                              ,  NULL
                                              ,  NULL
                                              );
  gc_entity_ref                xx_om_global_exceptions.entity_ref%TYPE;
  gn_entity_ref_id             xx_om_global_exceptions.entity_ref_id%TYPE;
  gc_error_description         xx_om_global_exceptions.description%TYPE;
  gc_error_code                xx_om_global_exceptions.error_code%TYPE;
  gc_file_path                 VARCHAR2(80);
  gc_file_name                 VARCHAR2(120);
  gc_curr_line                 VARCHAR2(2000);

  /* Table Type Deleration */

  TYPE T_DATE        IS TABLE OF DATE           INDEX BY BINARY_INTEGER;
  TYPE T_NUM         IS TABLE OF NUMBER         INDEX BY BINARY_INTEGER;
  TYPE T_V1          IS TABLE OF VARCHAR2(01)   INDEX BY BINARY_INTEGER;
  TYPE T_V3          IS TABLE OF VARCHAR2(03)   INDEX BY BINARY_INTEGER;
  TYPE T_V4          IS TABLE OF VARCHAR2(04)   INDEX BY BINARY_INTEGER;
  TYPE T_V10         IS TABLE OF VARCHAR2(10)   INDEX BY BINARY_INTEGER;
  TYPE T_V11         IS TABLE OF VARCHAR2(11)   INDEX BY BINARY_INTEGER;
  TYPE T_V15         IS TABLE OF VARCHAR2(15)   INDEX BY BINARY_INTEGER;
  TYPE T_V25         IS TABLE OF VARCHAR2(25)   INDEX BY BINARY_INTEGER;
  TYPE T_V30         IS TABLE OF VARCHAR2(30)   INDEX BY BINARY_INTEGER;
  TYPE T_V40         IS TABLE OF VARCHAR2(40)   INDEX BY BINARY_INTEGER;
  TYPE T_V50         IS TABLE OF VARCHAR2(50)   INDEX BY BINARY_INTEGER;
  TYPE T_V80         IS TABLE OF VARCHAR2(80)   INDEX BY BINARY_INTEGER;
  TYPE T_V100        IS TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
  TYPE T_V150        IS TABLE OF VARCHAR2(150)  INDEX BY BINARY_INTEGER;
  TYPE T_V240        IS TABLE OF VARCHAR2(240)  INDEX BY BINARY_INTEGER;
  TYPE T_V250        IS TABLE OF VARCHAR2(250)  INDEX BY BINARY_INTEGER;
  TYPE T_V360        IS TABLE OF VARCHAR2(360)  INDEX BY BINARY_INTEGER;
  TYPE T_V1000       IS TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER;
  TYPE T_V2000       IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
  TYPE T_BI          IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;

  /* Record Type Declaration */
  TYPE curr_line_rec_type IS RECORD (curr_line VARCHAR2(2000));

  /* Globale Record Type Declaration Type */
  gr_curr_line_rec curr_line_rec_type;

  /* Table Type Declaration for curr_line_rec_type record */
  TYPE curr_line_tbl_type IS TABLE OF curr_line_rec_type INDEX BY BINARY_INTEGER;

  /*Global Table Type Deleration */
  gc_line_tbl curr_line_tbl_type;

  /* Record Type Declaration */
  TYPE file_line_Rec_Type IS RECORD
      (  condition_id                T_NUM
      ,  ord_amt                     T_NUM
      ,  ship_address1               T_V240
      ,  ship_address2               T_V240
      ,  ship_city                   T_V80
      ,  ship_state                  T_V240
      ,  ship_zip_code               T_V30
      ,  ship_country                T_V30
      ,  customer_num                T_V80
      ,  customer_name               T_V240
      ,  email                       T_V240
      ,  email_domain                T_V240
      ,  bill_address1               T_V240
      ,  bill_address2               T_V240
      ,  bill_city                   T_V80
      ,  bill_state                  T_V80
      ,  bill_zip_code               T_V30
      ,  bill_country                T_V30
      ,  customer_date_check_rtl     T_V240
      ,  customer_date_check_con     T_V240
      ,  ip_address                  T_V240
      ,  item                        T_V240
      ,  item_class                  T_V240
      ,  item_quantity               T_NUM
      ,  credit_card_num             T_V80
      ,  credit_card_type            T_V30
      ,  hash_account                T_V240
      ,  encrypt_key                 T_V240
      ,  account_first_6             T_V30
      ,  account_last_4              T_V30
      ,  phone_num                   T_V30
      ,  hold_count                  T_NUM
      ,  accepted_count              T_NUM
      ,  del_flag                    T_V1
      ,  appl_flag                   T_V1
      ,  condition_name              T_V80
      ,  i_count                     T_NUM
      ,  error_flag                  T_V1
      ,  request_id                  T_NUM
      ,  ship_loc                    T_V30
      ,  error_description           T_V2000
      );

   /* Global Record Declaration for file_line_rec_type */
    gc_file_line_rec  file_line_Rec_Type;

  -- +===================================================================+
  -- | Name  : get_data                                                  |
  -- | Description     : To Fetch Record by Record info from flat file   |
  -- |                                                                   |
  -- | Parameters      : p_file_name         IN -> pass name of file     |
  -- |                   x_status           OUT -> x_status              |
  -- |                   x_message          OUT -> x_message             |
  -- |                                                                   |
  -- +===================================================================+

   PROCEDURE get_data( 
                       x_status    OUT NOCOPY  VARCHAR2
                     , x_message   OUT NOCOPY  VARCHAR2
                     , p_file_name  IN         VARCHAR2
                     );

  -- +===================================================================+
  -- | Name  : fraud_data_to_stg                                         |
  -- | Description     : The fetch record is read column by colum and    |
  -- |                   inserted in to stagging table                   |
  -- |                                                                   |
  -- | Parameters      : p_curr_line         IN -> pass the current line |
  -- |                                             read from get data    |
  -- |                   x_status           OUT -> x_status              |
  -- |                   x_message          OUT -> x_message             |
  -- |                                                                   |
  -- +===================================================================+

  PROCEDURE fraud_data_to_stg (
                                p_curr_line  IN curr_line_tbl_type
                              , x_status    OUT NOCOPY VARCHAR2
                              , x_message   OUT NOCOPY VARCHAR2
                              );

  -- +===================================================================+
  -- | Name  : insert_data                                               |
  -- | Description     : To Insert data into xx_om_fraud_rules_stg table |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+

  PROCEDURE insert_data;

  -- +===================================================================+
  -- | Name  : initialize_record                                         |
  -- | Description     : To Initialize columns with null values          |
  -- |                                                                   |
  -- | Parameters      : p_index                                         |
  -- |                                                                   |
  -- +===================================================================+

  PROCEDURE Initialize_record(p_index BINARY_INTEGER);

  -- +===================================================================+
  -- | Name  : Log_exceptions                                            |
  -- | Description     : To Log Exceptions by calling this procedure     |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+

  PROCEDURE log_exceptions;

  -- +===================================================================+
  -- | Name  : customer_number                                           |
  -- | Description     : To validate customer_number by passing legacy   |
  -- |                   customer_number                                 |
  -- |                                                                   |
  -- | Parameters     : p_customer_number  IN -> pass legacy customer num|
  -- |                                                                   |
  -- | Return         : customer_number                                  |
  -- +===================================================================+

  FUNCTION customer_number (p_cust_number IN hz_cust_accounts.account_number%TYPE) RETURN VARCHAR2;
  -- +===================================================================+
  -- | Name  : customer_name                                             |
  -- | Description     : To validate customer_name  by passing legacy    |
  -- |                   customer name                                   |
  -- |                                                                   |
  -- | Parameters     : p_customer_name  IN -> pass legacy customer name |
  -- |                                                                   |
  -- | Return         : customer_name                                    |
  -- +===================================================================+

  FUNCTION customer_name (p_cust_name IN hz_parties.party_name%TYPE) RETURN VARCHAR2;

  -- +===================================================================+
  -- | Name  : farud_data_to_base_table                                  |
  -- | Description     : To Insert from stg tbl to xx_om_fraud_rules tbl |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- +===================================================================+

  PROCEDURE fraud_data_to_base_table;

  -- +===================================================================+
  -- | Name  : clear_memory                                              |
  -- | Description     : To Clear Memory in tbl type records for every   |
  -- |                    5000 records.                                  |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE clear_memory;

  -- +===================================================================+
  -- | Name  : purge_stagging                                            |
  -- | Description     : To delete all rows from stg tbl with error_flag |
  -- |                   is null or 'N'.                                 |
  -- |                                                                   |
  -- | Parameters      : request_id         IN request_id                |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE purge_stagging(p_request_id IN VARCHAR2);

  --  PROCEDURE fetch_rename_file;

  -- +===================================================================+
  -- | Name  : get_item_class                                            |
  -- | Description     : To validate item_class by passing legacy item   |
  -- |                   class                                           |
  -- |                                                                   |
  -- | Parameters     : p_item_class  IN -> pass legacy item_class       |
  -- |                                                                   |
  -- | Return         : item class in oracle                             |
  -- +===================================================================+

  FUNCTION get_item_class (p_item_class IN  VARCHAR2) RETURN VARCHAR2;

  -- +===================================================================+
  -- | Name  : appl_flag                                                 |
  -- | Description     : To validate if any one column is not null in all|
  -- |                   parameters passed to function and return Y or N |
  -- |                                                                   |
  -- | Parameters     : p_ship_address  IN -> pass ship_address1         |
  -- |                  p_bill_address  IN -> pass bill_address1         |
  -- |                  p_phome         IN -> pass phone Number          |
  -- |                  p_cc_number     IN -> pass credit card num       |
  -- |                  p_zip_code      IN -> pass ship zip code         |
  -- |                                                                   |
  -- | Return         : 'Y' or 'N' for appl_flag                         |
  -- +===================================================================+

  FUNCTION appl_flag
      (  p_ship_address IN xxom.xx_om_fraud_rules.ship_address1%TYPE
      ,  p_bill_address IN xxom.xx_om_fraud_rules.bill_address1%TYPE
      ,  p_phone        IN xxom.xx_om_fraud_rules.phone_num%TYPE
      ,  p_cc_number    IN xxom.xx_om_fraud_rules.credit_card_num%TYPE
      ,  p_zip_code     IN xxom.xx_om_fraud_rules.ship_zip_code%TYPE
      )  RETURN VARCHAR2;

END xx_om_fraud_rules_pkg;

/
SHOW ERRORS PACKAGE XX_OM_FRAUD_RULES_PKG;
EXIT;

