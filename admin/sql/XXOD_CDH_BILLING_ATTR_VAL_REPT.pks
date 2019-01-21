SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_BILLING_ATTR_VAL_REPT.pks                        |
 |Description                                                             |
 |              Package specification and body for billing attributes     |
 |              validation report                                         |
 |                                                                        |
 |  Date        Author              Comments                              |
 |  05-Mar-09   Anirban Chaudhuri   Initial version                       |
 |======================================================================= */

CREATE OR REPLACE package XXOD_CDH_BILLING_ATTR_VAL_REPT
as

  TYPE XX_CDH_DATA_C1_REC_TYPE IS RECORD (
      account_number               VARCHAR2 (30),
      orig_system_reference        VARCHAR2 (240),
      account_name                 VARCHAR2 (240),
      attribute18                  VARCHAR2 (150),
      global_attribute20           VARCHAR2 (150)
   );

  TYPE XX_CDH_DATA_C1_TBL_TYPE IS TABLE OF XX_CDH_DATA_C1_REC_TYPE INDEX BY BINARY_INTEGER;

  TYPE XX_CDH_DATA_C2_REC_TYPE IS RECORD (
      account_number               VARCHAR2 (30),
      orig_system_reference        VARCHAR2 (240),
      account_name                 VARCHAR2 (240),
      standard_terms_name          VARCHAR2 (15),
      billdocs_payment_term        VARCHAR2 (150),
      global_attribute20           VARCHAR2 (150)     
   );

  TYPE XX_CDH_DATA_C2_TBL_TYPE IS TABLE OF XX_CDH_DATA_C2_REC_TYPE INDEX BY BINARY_INTEGER;

  TYPE XX_CDH_DATA_C6_REC_TYPE IS RECORD (
      account_number               VARCHAR2 (30),
      orig_system_reference        VARCHAR2 (240),
      billdocs_doc_id              NUMBER,
      billdocs_cust_doc_id         NUMBER,
      billdocs_paydoc_ind          VARCHAR2 (150),
      billdocs_doc_type            VARCHAR2 (150),
      billdocs_delivery_meth       VARCHAR2 (150),
      billdocs_payment_term        VARCHAR2 (150)
   );

  TYPE XX_CDH_DATA_C6_TBL_TYPE IS TABLE OF XX_CDH_DATA_C6_REC_TYPE INDEX BY BINARY_INTEGER;

  TYPE XX_CDH_DATA_C345_REC_TYPE IS RECORD (
      account_number               VARCHAR2 (30),
      orig_system_reference        VARCHAR2 (240),
      account_name                 VARCHAR2 (240),
      attribute18                  VARCHAR2 (150),
      status                       VARCHAR2 (1),
      c_ext_attr1                  VARCHAR2 (150),
      c_ext_attr2                  VARCHAR2 (150),
      n_ext_attr1                  NUMBER,
      n_ext_attr2                  NUMBER
   );

  TYPE XX_CDH_DATA_C345_TBL_TYPE IS TABLE OF XX_CDH_DATA_C345_REC_TYPE INDEX BY BINARY_INTEGER;

  procedure print_validation_report(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_from_batch_id   IN   varchar2,
		    p_to_batch_id     IN   varchar2
                  );
end XXOD_CDH_BILLING_ATTR_VAL_REPT;
/
