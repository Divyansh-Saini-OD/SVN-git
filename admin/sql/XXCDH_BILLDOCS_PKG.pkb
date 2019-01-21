create or replace package body XXCDH_BILLDOCS_PKG

   -- +=======================================================================+
   -- |                  Office Depot - Project Simplify                      |
   -- +=======================================================================+
   -- | Name       :  XXCDH_BILLDOCS_PKG.pkb                                  |
   -- | Description:  This package creates default BILLDOCS for CONTRACT      |
   -- |               or DIRECT customers with AB flag, reading default       |
   -- |               values created in FIN traslation setups                 |
   -- |               Sales Rep details and load them into Interface table    |
   -- |                                                                       |
   -- |Change Record:                                                         |
   -- |===============                                                        |
   -- |Version   Date        Author           Remarks                         |
   -- |=======   ==========  =============    ================================|
   -- |1.0      16-SEP-2009  Sreedhar Mohan   Initial draft version           |
   -- |                                                                       |
   -- |1.1      11-MAR-2010  Srini Cherukuri  Added new columns in FINTRANS   |
   -- |                                       table for Mid Cycle / eBilling  |
   -- |                                       Changes (CR# 738 / CR# 586).    |
   -- |1.2      22-OCT-2015  Vasu Raparla     Removed schema References for   |
   -- |                                                  for R12.2            |
   -- |                                                                       |
   -- |1.3      14-MAR-2018  Theja Rajula     Defect 44425                   
  --  |1.4      05-JUL-2018  Sridhar Pamu	  Defect 45359 added NVL for profileclass |
   -- +=======================================================================+
as

procedure create_billdocs (
                             P_BATCH_ID                   IN      NUMBER,
                             P_ORIG_SYSTEM                IN      VARCHAR2,
                             P_ORIG_SYSTEM_REFERENCE      IN      VARCHAR2,
                             p_CUSTOMER_TYPE              IN      VARCHAR2
                          )
is

  LC_TRANSLATION_NAME      VARCHAR2(240);

  LC_DOCUMENT_ID           NUMBER(22,5);
  LC_DIRECT_DOCUMENT       VARCHAR2(150);
  LC_DOCUMENT_TYPE         VARCHAR2(150);
  LC_PAYDOC_INDICATOR      VARCHAR2(150);
  LC_DELIVERY_METHOD       VARCHAR2(150);
  LC_SIGNATURE_REQUIRED    VARCHAR2(150);
  LC_PRINT_LOCATION        VARCHAR2(150);
  LC_SUMMARY_FLAG          VARCHAR2(150);
  LC_PAYMENT_TERM          VARCHAR2(150);
  LC_SPECIAL_HANDLING      VARCHAR2(150);
  LC_NUMBER_OF_COPIES      VARCHAR2(150);
  LC_REPORTING_DAY         VARCHAR2(150);
  LC_DOCUMENT_FREQUENCY    VARCHAR2(150);
  LC_AUTO_REPRINT_FLAG     VARCHAR2(150);
  LC_DOCUMENT_FORMAT       VARCHAR2(150);
  LC_MEDIA_TYPE            VARCHAR2(150);
  LC_COMBO_TYPE            VARCHAR2(150);
  LC_MAIL_TO_ATTENTION     VARCHAR2(150);
  LC_COMMENTS1             VARCHAR2(150);
  LC_COMMENTS2             VARCHAR2(150);
  LC_COMMENTS3             VARCHAR2(150);
  LC_COMMENTS4             VARCHAR2(150);

  -----------------------------------------------------------------------------
  -- Below Variables are added by Srini (Version# 1.1)
  -----------------------------------------------------------------------------

  LC_TERM_ID               VARCHAR2(150);
  LC_IS_PARENT             VARCHAR2(150);
  LC_SEND_TO_PARENT        VARCHAR2(150);
  LC_PARENT_DOC_ID         VARCHAR2(150);
  LC_BILL_DOCUMENT_STATUS  VARCHAR2(150);
  LC_PROCESS_FLAG          VARCHAR2(150);
  LC_CUST_REQ_START_DATE   DATE;
  LC_CUST_REQ_END_DATE     DATE;
  LC_EFFECTIVE_START_DATE  DATE;
  LC_EFFECTIVE_END_DATE    DATE;

begin

if (P_CUSTOMER_TYPE = 'CONTRACT') THEN
  lc_translation_name := 'XXCDH_CONTRACT_BILLDOCS';
else
  lc_translation_name := 'XXCDH_DIRECT_BILLDOCS';
end if;

  SELECT xval.source_value1,
         xval.source_value2,
         xval.source_value3,
         xval.source_value4,
         xval.source_value5,
         xval.source_value6,
         xval.source_value7,
         xval.source_value8,
         xval.source_value9,
         xval.source_value10,
         xval.target_value1,
         xval.target_value2,
         xval.target_value3,
         xval.target_value4,
         xval.target_value5,
         xval.target_value6,
         xval.target_value7,
         xval.target_value8,
         xval.target_value9,
         xval.target_value10,
         xval.target_value11,
         xval.target_value12,

          -- Below Columns are added by Srini (Version# 1.1)
         xval.target_value13,
         xval.target_value14,
         xval.target_value15,
         xval.target_value16,
         xval.target_value17
  INTO
         lc_Document_ID,
         lc_Direct_Document,
         lc_Document_Type,
         lc_Paydoc_Indicator,
         lc_Delivery_Method,
         lc_Signature_Required,
         lc_Print_Location,
         lc_Summary_Flag,
         lc_Payment_Term,
         lc_Special_Handling,
         lc_Number_of_Copies,
         lc_Reporting_Day,
         lc_Document_Frequency,
         lc_Auto_Reprint_Flag,
         lc_Document_Format,
         lc_Media_Type,
         lc_Combo_Type,
         lc_Mail_To_Attention,
         lc_Comments1,
         lc_Comments2,
         lc_Comments3,
         lc_Comments4,

         -- Below Columns are added by Srini (Version# 1.1)
         lc_term_id,
	 lc_is_parent,
	 lc_send_to_parent,
	 lc_bill_document_status,
	 lc_process_flag
  FROM   xx_fin_translatedefinition           xdef,
         xx_fin_translatevalues               xval
  WHERE  xdef.translation_name                = lc_translation_name
  AND    xdef.translate_id                    = xval.translate_id
  AND    xval.source_value5                   = 'PRINT'  --'ePDF' or 'PRINT'
  AND    xval.source_value3                   = 'Invoice' -- 'Invoice' or 'Consolidated Bill'
  AND    xval.target_value3                   = 'WEEKLY' -- 'DAILY' or 'WEEKLY'
  AND    TRUNC  (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1))
                              AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1));

  -----------------------------------------------------------------------------
  -- Added by Srini (Version# 1.1)
  -----------------------------------------------------------------------------

 lc_parent_doc_id        := NULL;
 lc_cust_req_start_date  := TRUNC(sysdate);
 lc_cust_req_end_date    := NULL;
 lc_effective_start_date := TRUNC(sysdate);
 lc_effective_end_date   := NULL;

  -----------------------------------------------------------------------------
  -- Changes end by Srini (Version# 1.1).
  -----------------------------------------------------------------------------

  insert into XXOD_HZ_IMP_EXT_ATTRIBS_INT
  (
  BATCH_ID,
  INTERFACE_STATUS,
  ORIG_SYSTEM,
  ORIG_SYSTEM_REFERENCE,
  INTERFACE_ENTITY_NAME,
  INTERFACE_ENTITY_REFERENCE,
  ATTRIBUTE_GROUP_CODE,
  C_EXT_ATTR1,
  C_EXT_ATTR2,
  C_EXT_ATTR3,
  C_EXT_ATTR4,
  C_EXT_ATTR5,
  C_EXT_ATTR6,
  C_EXT_ATTR7,
  C_EXT_ATTR8,
  C_EXT_ATTR9,
  C_EXT_ATTR10,
  C_EXT_ATTR11,
  C_EXT_ATTR12,
  C_EXT_ATTR13,
  C_EXT_ATTR14,
  C_EXT_ATTR15,
  C_EXT_ATTR17,
  C_EXT_ATTR18,
  C_EXT_ATTR19,
  C_EXT_ATTR20,
  N_EXT_ATTR1,
  N_EXT_ATTR2,
  N_EXT_ATTR20,

   -- Below Columns are added by Srini (Version# 1.1)
  N_EXT_ATTR18,
  N_EXT_ATTR17,
  N_EXT_ATTR16,
  N_EXT_ATTR15,
  C_EXT_ATTR16,
  N_EXT_ATTR19,
  D_EXT_ATTR9,
  D_EXT_ATTR10,
  D_EXT_ATTR1,
  D_EXT_ATTR2
  )
  VALUES (
  P_BATCH_ID,
  1,
  P_ORIG_SYSTEM,
  P_ORIG_SYSTEM_REFERENCE,
  'ACCOUNT',
  P_ORIG_SYSTEM_REFERENCE,
  'BILLDOCS',
  LC_DOCUMENT_TYPE,
  LC_PAYDOC_INDICATOR,
  LC_DELIVERY_METHOD,
  LC_SPECIAL_HANDLING,
  LC_SIGNATURE_REQUIRED,
  LC_DOCUMENT_FREQUENCY,
  LC_DIRECT_DOCUMENT,
  LC_AUTO_REPRINT_FLAG,
  LC_PRINT_LOCATION,
  LC_DOCUMENT_FORMAT,
  LC_SUMMARY_FLAG,
  LC_MEDIA_TYPE, --   C_EXT_ATTR12,
  LC_COMBO_TYPE,
  LC_PAYMENT_TERM,
  LC_MAIL_TO_ATTENTION,
  LC_COMMENTS1,
  LC_COMMENTS2,
  LC_COMMENTS3,
  LC_COMMENTS4,
  to_number(LC_DOCUMENT_ID),
  XX_CDH_CUST_DOC_ID_S.NEXTVAL,
  P_BATCH_ID,

   -- Below Columns are added by Srini (Version# 1.1)
  to_number(lc_term_id),
  to_number(lc_is_parent),
  to_number(lc_send_to_parent),
  lc_parent_doc_id,
  lc_bill_document_status,
  to_number(lc_process_flag),
  lc_cust_req_start_date,
  lc_cust_req_end_date,
  lc_effective_start_date,
  lc_effective_end_date
  );

COMMIT;

exception
  when others then
    fnd_file.put_line(fnd_file.LOG,'Error in Creating Billdocs- '||SQLERRM);
end create_billdocs;

procedure create_billdocs (
                             P_BATCH_ID                   IN      NUMBER,
                             P_ORIG_SYSTEM                IN      VARCHAR2,
                             P_ORIG_SYSTEM_REFERENCE      IN      VARCHAR2,
                             p_CUSTOMER_TYPE              IN      VARCHAR2,
                             p_PROF_CLASS_NAME            IN      VARCHAR2                             
                          )
is

  LC_TRANSLATION_NAME      VARCHAR2(240);

  LC_DOCUMENT_ID           NUMBER(22,5);
  LC_DIRECT_DOCUMENT       VARCHAR2(150);
  LC_DOCUMENT_TYPE         VARCHAR2(150);
  LC_PAYDOC_INDICATOR      VARCHAR2(150);
  LC_DELIVERY_METHOD       VARCHAR2(150);
  LC_SIGNATURE_REQUIRED    VARCHAR2(150);
  LC_PRINT_LOCATION        VARCHAR2(150);
  LC_SUMMARY_FLAG          VARCHAR2(150);
  LC_PAYMENT_TERM          VARCHAR2(150);
  LC_SPECIAL_HANDLING      VARCHAR2(150);
  LC_NUMBER_OF_COPIES      VARCHAR2(150);
  LC_REPORTING_DAY         VARCHAR2(150);
  LC_DOCUMENT_FREQUENCY    VARCHAR2(150);
  LC_AUTO_REPRINT_FLAG     VARCHAR2(150);
  LC_DOCUMENT_FORMAT       VARCHAR2(150);
  LC_MEDIA_TYPE            VARCHAR2(150);
  LC_COMBO_TYPE            VARCHAR2(150);
  LC_MAIL_TO_ATTENTION     VARCHAR2(150);
  LC_COMMENTS1             VARCHAR2(150);
  LC_COMMENTS2             VARCHAR2(150);
  LC_COMMENTS3             VARCHAR2(150);
  LC_COMMENTS4             VARCHAR2(150);

  -----------------------------------------------------------------------------
  -- Below Variables are added by Srini (Version# 1.1)
  -----------------------------------------------------------------------------

  LC_TERM_ID               VARCHAR2(150);
  LC_IS_PARENT             VARCHAR2(150);
  LC_SEND_TO_PARENT        VARCHAR2(150);
  LC_PARENT_DOC_ID         VARCHAR2(150);
  LC_BILL_DOCUMENT_STATUS  VARCHAR2(150);
  LC_PROCESS_FLAG          VARCHAR2(150);
  LC_CUST_REQ_START_DATE   DATE;
  LC_CUST_REQ_END_DATE     DATE;
  LC_EFFECTIVE_START_DATE  DATE;
  LC_EFFECTIVE_END_DATE    DATE;

begin

if (P_CUSTOMER_TYPE = 'CONTRACT') THEN
  lc_translation_name := 'XXCDH_CONTRACT_BILLDOCS';
else
  lc_translation_name := 'XXCDH_DIRECT_BILLDOCS';
end if;

IF P_CUSTOMER_TYPE = 'CONTRACT' THEN  -- Defect# 44425 Added by Theja Rajula 03/14/2018

  SELECT xval.source_value1,
         xval.source_value2,
         xval.source_value3,
         xval.source_value4,
         xval.source_value5,
         xval.source_value6,
         xval.source_value7,
         xval.source_value8,
         xval.source_value9,
         xval.source_value10,
         xval.target_value1,
         xval.target_value2,
         xval.target_value3,
         xval.target_value4,
         xval.target_value5,
         xval.target_value6,
         xval.target_value7,
         xval.target_value8,
         xval.target_value9,
         xval.target_value10,
         xval.target_value11,
         xval.target_value12,

          -- Below Columns are added by Srini (Version# 1.1)
         xval.target_value13,
         xval.target_value14,
         xval.target_value15,
         xval.target_value16,
         xval.target_value17
  INTO
         lc_Document_ID,
         lc_Direct_Document,
         lc_Document_Type,
         lc_Paydoc_Indicator,
         lc_Delivery_Method,
         lc_Signature_Required,
         lc_Print_Location,
         lc_Summary_Flag,
         lc_Payment_Term,
         lc_Special_Handling,
         lc_Number_of_Copies,
         lc_Reporting_Day,
         lc_Document_Frequency,
         lc_Auto_Reprint_Flag,
         lc_Document_Format,
         lc_Media_Type,
         lc_Combo_Type,
         lc_Mail_To_Attention,
         lc_Comments1,
         lc_Comments2,
         lc_Comments3,
         lc_Comments4,

         -- Below Columns are added by Srini (Version# 1.1)
         lc_term_id,
	 lc_is_parent,
	 lc_send_to_parent,
	 lc_bill_document_status,
	 lc_process_flag
  FROM   xx_fin_translatedefinition           xdef,
         xx_fin_translatevalues               xval
  WHERE  xdef.translation_name                = lc_translation_name
  AND    xdef.translate_id                    = xval.translate_id
  AND    xval.source_value5                   = 'PRINT'  --'ePDF' or 'PRINT'
  AND    xval.source_value3                   = 'Invoice' -- 'Invoice' or 'Consolidated Bill'
  AND    xval.target_value3                   = 'WEEKLY' -- 'DAILY' or 'WEEKLY'
  and    xval.target_value9                   = nvl(p_PROF_CLASS_NAME,'SFA_LOW_RISK20_US') -- added nvl for defect 45359-- 'SFA_LOW_RISK_US' or 'SFA_LOW_RISK20_US' or 'FOS_MEDIUM_RISK_US'
  AND    TRUNC  (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1))
                              AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1));
 ELSIF P_CUSTOMER_TYPE = 'DIRECT' THEN 
   SELECT xval.source_value1,
         xval.source_value2,
         xval.source_value3,
         xval.source_value4,
         xval.source_value5,
         xval.source_value6,
         xval.source_value7,
         xval.source_value8,
         xval.source_value9,
         xval.source_value10,
         xval.target_value1,
         xval.target_value2,
         xval.target_value3,
         xval.target_value4,
         xval.target_value5,
         xval.target_value6,
         xval.target_value7,
         xval.target_value8,
         xval.target_value9,
         xval.target_value10,
         xval.target_value11,
         xval.target_value12,
          -- Below Columns are added by Srini (Version# 1.1)
         xval.target_value13,
         xval.target_value14,
         xval.target_value15,
         xval.target_value16,
         xval.target_value17
  INTO
         lc_Document_ID,
         lc_Direct_Document,
         lc_Document_Type,
         lc_Paydoc_Indicator,
         lc_Delivery_Method,
         lc_Signature_Required,
         lc_Print_Location,
         lc_Summary_Flag,
         lc_Payment_Term,
         lc_Special_Handling,
         lc_Number_of_Copies,
         lc_Reporting_Day,
         lc_Document_Frequency,
         lc_Auto_Reprint_Flag,
         lc_Document_Format,
         lc_Media_Type,
         lc_Combo_Type,
         lc_Mail_To_Attention,
         lc_Comments1,
         lc_Comments2,
         lc_Comments3,
         lc_Comments4,

         -- Below Columns are added by Srini (Version# 1.1)
         lc_term_id,
	 lc_is_parent,
	 lc_send_to_parent,
	 lc_bill_document_status,
	 lc_process_flag
  FROM   xx_fin_translatedefinition           xdef,
         xx_fin_translatevalues               xval
  WHERE  xdef.translation_name                = lc_translation_name
  AND    xdef.translate_id                    = xval.translate_id
  AND    xval.source_value5                   = 'PRINT'  --'ePDF' or 'PRINT'
  AND    xval.source_value3                   = 'Invoice' -- 'Invoice' or 'Consolidated Bill'
  AND    xval.target_value3                   = 'WEEKLY' -- 'DAILY' or 'WEEKLY'
  AND    TRUNC  (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1))
                              AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1));
 
 END IF;

  -----------------------------------------------------------------------------
  -- Added by Srini (Version# 1.1)
  -----------------------------------------------------------------------------

 lc_parent_doc_id        := NULL;
 lc_cust_req_start_date  := TRUNC(sysdate);
 lc_cust_req_end_date    := NULL;
 lc_effective_start_date := TRUNC(sysdate);
 lc_effective_end_date   := NULL;

  -----------------------------------------------------------------------------
  -- Changes end by Srini (Version# 1.1).
  -----------------------------------------------------------------------------

  insert into XXOD_HZ_IMP_EXT_ATTRIBS_INT
  (
  BATCH_ID,
  INTERFACE_STATUS,
  ORIG_SYSTEM,
  ORIG_SYSTEM_REFERENCE,
  INTERFACE_ENTITY_NAME,
  INTERFACE_ENTITY_REFERENCE,
  ATTRIBUTE_GROUP_CODE,
  C_EXT_ATTR1,
  C_EXT_ATTR2,
  C_EXT_ATTR3,
  C_EXT_ATTR4,
  C_EXT_ATTR5,
  C_EXT_ATTR6,
  C_EXT_ATTR7,
  C_EXT_ATTR8,
  C_EXT_ATTR9,
  C_EXT_ATTR10,
  C_EXT_ATTR11,
  C_EXT_ATTR12,
  C_EXT_ATTR13,
  C_EXT_ATTR14,
  C_EXT_ATTR15,
  C_EXT_ATTR17,
  C_EXT_ATTR18,
  C_EXT_ATTR19,
  C_EXT_ATTR20,
  N_EXT_ATTR1,
  N_EXT_ATTR2,
  N_EXT_ATTR20,

   -- Below Columns are added by Srini (Version# 1.1)
  N_EXT_ATTR18,
  N_EXT_ATTR17,
  N_EXT_ATTR16,
  N_EXT_ATTR15,
  C_EXT_ATTR16,
  N_EXT_ATTR19,
  D_EXT_ATTR9,
  D_EXT_ATTR10,
  D_EXT_ATTR1,
  D_EXT_ATTR2
  )
  VALUES (
  P_BATCH_ID,
  1,
  P_ORIG_SYSTEM,
  P_ORIG_SYSTEM_REFERENCE,
  'ACCOUNT',
  P_ORIG_SYSTEM_REFERENCE,
  'BILLDOCS',
  LC_DOCUMENT_TYPE,
  LC_PAYDOC_INDICATOR,
  LC_DELIVERY_METHOD,
  LC_SPECIAL_HANDLING,
  LC_SIGNATURE_REQUIRED,
  LC_DOCUMENT_FREQUENCY,
  LC_DIRECT_DOCUMENT,
  LC_AUTO_REPRINT_FLAG,
  LC_PRINT_LOCATION,
  LC_DOCUMENT_FORMAT,
  LC_SUMMARY_FLAG,
  LC_MEDIA_TYPE, --   C_EXT_ATTR12,
  LC_COMBO_TYPE,
  LC_PAYMENT_TERM,
  LC_MAIL_TO_ATTENTION,
  LC_COMMENTS1,
  LC_COMMENTS2,
  LC_COMMENTS3,
  LC_COMMENTS4,
  to_number(LC_DOCUMENT_ID),
  XX_CDH_CUST_DOC_ID_S.NEXTVAL,
  P_BATCH_ID,

   -- Below Columns are added by Srini (Version# 1.1)
  to_number(lc_term_id),
  to_number(lc_is_parent),
  to_number(lc_send_to_parent),
  lc_parent_doc_id,
  lc_bill_document_status,
  to_number(lc_process_flag),
  lc_cust_req_start_date,
  lc_cust_req_end_date,
  lc_effective_start_date,
  lc_effective_end_date
  );

COMMIT;

exception
  when others then
    fnd_file.put_line(fnd_file.LOG,'Error in Creating Billdocs- '||SQLERRM);
end create_billdocs;

/*
procedure get_billdoc_attrbs (
                              p_CUSTOMER_TYPE              IN      VARCHAR2,
                              x_Document_ID                OUT NOCOPY NUMBER,
                              x_Direct_Document            OUT NOCOPY VARCHAR2,
                              x_Document_Type              OUT NOCOPY VARCHAR2,
                              x_Paydoc_Indicator           OUT NOCOPY VARCHAR2,
                              x_Delivery_Method            OUT NOCOPY VARCHAR2,
                              x_Signature_Required         OUT NOCOPY VARCHAR2,
                              x_Print_Location             OUT NOCOPY VARCHAR2,
                              x_Summary_Flag               OUT NOCOPY VARCHAR2,
                              x_Payment_Term               OUT NOCOPY VARCHAR2,
                              x_Special_Handling           OUT NOCOPY VARCHAR2,
                              x_Number_of_Copies           OUT NOCOPY VARCHAR2,
                              x_Reporting_Day              OUT NOCOPY VARCHAR2,
                              x_Document_Frequency         OUT NOCOPY VARCHAR2,
                              x_Auto_Reprint_Flag          OUT NOCOPY VARCHAR2,
                              x_Document_Format            OUT NOCOPY VARCHAR2,
                              x_Media_Type                 OUT NOCOPY VARCHAR2,
                              x_Combo_Type                 OUT NOCOPY VARCHAR2,
                              x_Mail_To_Attention          OUT NOCOPY VARCHAR2,
                              x_Comments1                  OUT NOCOPY VARCHAR2,
                              x_Comments2                  OUT NOCOPY VARCHAR2,
                              x_Comments3                  OUT NOCOPY VARCHAR2,
                              x_Comments4                  OUT NOCOPY VARCHAR2,

                              -- Below Columns are added by Srini (Version# 1.1)
                              x_billdocs_term_id           OUT NOCOPY VARCHAR2,
                              x_Is_Parent                  OUT NOCOPY VARCHAR2,
                              x_Send_To_Parent             OUT NOCOPY VARCHAR2,
                              x_Parent_Doc_id              OUT NOCOPY VARCHAR2,
                              x_billdocs_status            OUT NOCOPY VARCHAR2,
                              x_billdoc_process_flag       OUT NOCOPY VARCHAR2,
                              x_Cust_Req_Start_date        OUT NOCOPY DATE,
                              x_Cust_Req_End_date          OUT NOCOPY DATE,
                              x_billdocs_eff_from_date     OUT NOCOPY DATE,
                              x_billdocs_eff_to_date       OUT NOCOPY DATE,
                              -- End (Below Columns are added by Srini (Version# 1.1))

                              x_msg_status                 OUT NOCOPY VARCHAR2,
                              x_msg_data                   OUT NOCOPY VARCHAR2
                          ) IS

L_TRANSLATION_NAME         VARCHAR2(240);
BEGIN

  x_msg_status := 'S';

  if (P_CUSTOMER_TYPE = 'CONTRACT') THEN
    l_translation_name := 'XXCDH_CONTRACT_BILLDOCS';
  else
    l_translation_name := 'XXCDH_DIRECT_BILLDOCS';
  end if;

SELECT   xval.source_value1,
         xval.source_value2,
         xval.source_value3,
         xval.source_value4,
         xval.source_value5,
         xval.source_value6,
         xval.source_value7,
         xval.source_value8,
         xval.source_value9,
         xval.source_value10,
         xval.target_value1,
         xval.target_value2,
         xval.target_value3,
         xval.target_value4,
         xval.target_value5,
         xval.target_value6,
         xval.target_value7,
         xval.target_value8,
         xval.target_value9,
         xval.target_value10,
         xval.target_value11,
         xval.target_value12,

         xval.target_value13, -- Below Columns are added by Srini (Version# 1.1)
         xval.target_value14,
         xval.target_value15,
         xval.target_value16,
         xval.target_value17
  INTO
         x_Document_ID,
         x_Direct_Document,
         x_Document_Type,
         x_Paydoc_Indicator,
         x_Delivery_Method,
         x_Signature_Required,
         x_Print_Location,
         x_Summary_Flag,
         x_Payment_Term,
         x_Special_Handling,
         x_Number_of_Copies,
         x_Reporting_Day,
         x_Document_Frequency,
         x_Auto_Reprint_Flag,
         x_Document_Format,
         x_Media_Type,
         x_Combo_Type,
         x_Mail_To_Attention,
         x_Comments1,
         x_Comments2,
         x_Comments3,
         x_Comments4,

         x_billdocs_term_id, -- Below Columns are added by Srini (Version# 1.1)
         x_Is_Parent,
         x_Send_To_Parent,
         x_billdocs_status,
         x_billdoc_process_flag
  FROM   xx_fin_translatedefinition           xdef,
         xx_fin_translatevalues               xval
  WHERE  xdef.translation_name                = l_translation_name
  AND    xdef.translate_id                    = xval.translate_id
  AND    TRUNC  (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1))
                              AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1));
  -----------------------------------------------------------------------------
  -- Added by Srini (Version# 1.1)
  -----------------------------------------------------------------------------

 x_Parent_Doc_id          := NULL;
 x_Cust_Req_Start_date    := TRUNC(sysdate);
 x_Cust_Req_End_date      := NULL;
 x_billdocs_eff_from_date := TRUNC(sysdate);
 x_billdocs_eff_to_date   := NULL;

  -----------------------------------------------------------------------------
  -- Changes end by Srini (Version# 1.1).
  -----------------------------------------------------------------------------


EXCEPTION WHEN OTHERS THEN
    x_msg_status := 'E';
    x_msg_data := 'Error in get_billdoc_attrbs ' || sqlerrm ;

END get_billdoc_attrbs;
*/

procedure get_billdoc_attrbs (
                              p_CUSTOMER_TYPE              IN      VARCHAR2,
                              p_DELIVERY_METHOD            IN      VARCHAR2,
                              p_DOC_TYPE                   IN      VARCHAR2,
                              p_DOC_FREQUENCY              IN      VARCHAR2,
                              x_Document_ID                OUT NOCOPY NUMBER,
                              x_Direct_Document            OUT NOCOPY VARCHAR2,
                              x_Document_Type              OUT NOCOPY VARCHAR2,
                              x_Paydoc_Indicator           OUT NOCOPY VARCHAR2,
                              x_Delivery_Method            OUT NOCOPY VARCHAR2,
                              x_Signature_Required         OUT NOCOPY VARCHAR2,
                              x_Print_Location             OUT NOCOPY VARCHAR2,
                              x_Summary_Flag               OUT NOCOPY VARCHAR2,
                              x_Payment_Term               OUT NOCOPY VARCHAR2,
                              x_Special_Handling           OUT NOCOPY VARCHAR2,
                              x_Number_of_Copies           OUT NOCOPY VARCHAR2,
                              x_Reporting_Day              OUT NOCOPY VARCHAR2,
                              x_Document_Frequency         OUT NOCOPY VARCHAR2,
                              x_Auto_Reprint_Flag          OUT NOCOPY VARCHAR2,
                              x_Document_Format            OUT NOCOPY VARCHAR2,
                              x_Media_Type                 OUT NOCOPY VARCHAR2,
                              x_Combo_Type                 OUT NOCOPY VARCHAR2,
                              x_Mail_To_Attention          OUT NOCOPY VARCHAR2,
                              x_Comments1                  OUT NOCOPY VARCHAR2,
                              x_Comments2                  OUT NOCOPY VARCHAR2,
                              x_Comments3                  OUT NOCOPY VARCHAR2,
                              x_Comments4                  OUT NOCOPY VARCHAR2,

                              -- Below Columns are added by Srini (Version# 1.1)
                              x_billdocs_term_id           OUT NOCOPY VARCHAR2,
                              x_Is_Parent                  OUT NOCOPY VARCHAR2,
                              x_Send_To_Parent             OUT NOCOPY VARCHAR2,
                              x_Parent_Doc_id              OUT NOCOPY VARCHAR2,
                              x_billdocs_status            OUT NOCOPY VARCHAR2,
                              x_billdoc_process_flag       OUT NOCOPY VARCHAR2,
                              x_Cust_Req_Start_date        OUT NOCOPY DATE,
                              x_Cust_Req_End_date          OUT NOCOPY DATE,
                              x_billdocs_eff_from_date     OUT NOCOPY DATE,
                              x_billdocs_eff_to_date       OUT NOCOPY DATE,
                              -- End (Below Columns are added by Srini (Version# 1.1))

                              x_msg_status                 OUT NOCOPY VARCHAR2,
                              x_msg_data                   OUT NOCOPY VARCHAR2
                          ) IS

L_TRANSLATION_NAME         VARCHAR2(240);
BEGIN

  x_msg_status := 'S';

  if (P_CUSTOMER_TYPE = 'CONTRACT') THEN
    l_translation_name := 'XXCDH_CONTRACT_BILLDOCS';
  else
    l_translation_name := 'XXCDH_DIRECT_BILLDOCS';
  end if;

SELECT   xval.source_value1,
         xval.source_value2,
         xval.source_value3,
         xval.source_value4,
         decode(p_DELIVERY_METHOD,'ePDF', p_DELIVERY_METHOD, xval.source_value5),
         xval.source_value6,
         xval.source_value7,
         xval.source_value8,
         xval.source_value9,
         xval.source_value10,
         xval.target_value1,
         xval.target_value2,
         xval.target_value3,
         xval.target_value4,
         xval.target_value5,
         xval.target_value6,
         xval.target_value7,
         xval.target_value8,
         xval.target_value9,
         xval.target_value10,
         xval.target_value11,
         xval.target_value12,

         xval.target_value13, -- Below Columns are added by Srini (Version# 1.1)
         xval.target_value14,
         xval.target_value15,
         decode(p_DELIVERY_METHOD,'ePDF', 'IN_PROCESS', xval.target_value16),
         xval.target_value17
  INTO
         x_Document_ID,
         x_Direct_Document,
         x_Document_Type,
         x_Paydoc_Indicator,
         x_Delivery_Method,
         x_Signature_Required,
         x_Print_Location,
         x_Summary_Flag,
         x_Payment_Term,
         x_Special_Handling,
         x_Number_of_Copies,
         x_Reporting_Day,
         x_Document_Frequency,
         x_Auto_Reprint_Flag,
         x_Document_Format,
         x_Media_Type,
         x_Combo_Type,
         x_Mail_To_Attention,
         x_Comments1,
         x_Comments2,
         x_Comments3,
         x_Comments4,

         x_billdocs_term_id, -- Below Columns are added by Srini (Version# 1.1)
         x_Is_Parent,
         x_Send_To_Parent,
         x_billdocs_status,
         x_billdoc_process_flag
  FROM   xx_fin_translatedefinition           xdef,
         xx_fin_translatevalues               xval
  WHERE  xdef.translation_name                = l_translation_name  -- 'XXCDH_CONTRACT_BILLDOCS' -- 'XXCDH_DIRECT_BILLDOCS'
  AND    xval.source_value5                   = p_DELIVERY_METHOD  --'ePDF' or 'PRINT'
  AND    xval.source_value3                   = p_DOC_TYPE -- 'Invoice' or 'Consolidated Bill'
  AND    xval.target_value3                   = p_DOC_FREQUENCY -- 'DAILY' or 'WEEKLY'
  AND    xdef.translate_id                    = xval.translate_id
  AND    TRUNC  (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1))
                              AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1));
  -----------------------------------------------------------------------------
  -- Added by Srini (Version# 1.1)
  -----------------------------------------------------------------------------

 x_Parent_Doc_id          := NULL;
 x_Cust_Req_Start_date    := TRUNC(sysdate);
 x_Cust_Req_End_date      := NULL;
 x_billdocs_eff_from_date := TRUNC(sysdate);
 x_billdocs_eff_to_date   := NULL;

  -----------------------------------------------------------------------------
  -- Changes end by Srini (Version# 1.1).
  -----------------------------------------------------------------------------

EXCEPTION 
  WHEN NO_DATA_FOUND THEN
  NULL;
  
  WHEN TOO_MANY_ROWS THEN
     
SELECT   xval.source_value1,
         xval.source_value2,
         xval.source_value3,
         xval.source_value4,
         decode(p_DELIVERY_METHOD,'ePDF', p_DELIVERY_METHOD, xval.source_value5),
         xval.source_value6,
         xval.source_value7,
         xval.source_value8,
         xval.source_value9,
         xval.source_value10,
         xval.target_value1,
         xval.target_value2,
         xval.target_value3,
         xval.target_value4,
         xval.target_value5,
         xval.target_value6,
         xval.target_value7,
         xval.target_value8,
         xval.target_value9,
         xval.target_value10,
         xval.target_value11,
         xval.target_value12,

         xval.target_value13, -- Below Columns are added by Srini (Version# 1.1)
         xval.target_value14,
         xval.target_value15,
         decode(p_DELIVERY_METHOD,'ePDF', 'IN_PROCESS', xval.target_value16),
         xval.target_value17
  INTO
         x_Document_ID,
         x_Direct_Document,
         x_Document_Type,
         x_Paydoc_Indicator,
         x_Delivery_Method,
         x_Signature_Required,
         x_Print_Location,
         x_Summary_Flag,
         x_Payment_Term,
         x_Special_Handling,
         x_Number_of_Copies,
         x_Reporting_Day,
         x_Document_Frequency,
         x_Auto_Reprint_Flag,
         x_Document_Format,
         x_Media_Type,
         x_Combo_Type,
         x_Mail_To_Attention,
         x_Comments1,
         x_Comments2,
         x_Comments3,
         x_Comments4,

         x_billdocs_term_id, -- Below Columns are added by Srini (Version# 1.1)
         x_Is_Parent,
         x_Send_To_Parent,
         x_billdocs_status,
         x_billdoc_process_flag
  FROM   xx_fin_translatedefinition           xdef,
         xx_fin_translatevalues               xval
  WHERE  xdef.translation_name                = l_translation_name  -- 'XXCDH_CONTRACT_BILLDOCS' -- 'XXCDH_DIRECT_BILLDOCS'
  AND    xval.source_value5                   = p_DELIVERY_METHOD  --'ePDF' or 'PRINT'
  AND    xval.source_value3                   = p_DOC_TYPE -- 'Invoice' or 'Consolidated Bill'
  AND    xval.target_value3                   = p_DOC_FREQUENCY -- 'DAILY' or 'WEEKLY'
  and    xval.target_value9                   = 'SFA_LOW_RISK20_US' -- 'SFA_LOW_RISK_US' or 'SFA_LOW_RISK20_US'
  AND    xdef.translate_id                    = xval.translate_id
  AND    TRUNC  (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1))
                              AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1));
  
  
  
 x_Parent_Doc_id          := NULL;
 x_Cust_Req_Start_date    := TRUNC(sysdate);
 x_Cust_Req_End_date      := NULL;
 x_billdocs_eff_from_date := TRUNC(sysdate);
 x_billdocs_eff_to_date   := NULL;  
  
    
 WHEN OTHERS THEN
    x_msg_status := 'E';
    x_msg_data := 'Error in get_billdoc_attrbs ' || sqlerrm ;

END get_billdoc_attrbs;


procedure get_billdoc_attrbs (
                              p_CUSTOMER_TYPE              IN      VARCHAR2,
                              p_DELIVERY_METHOD            IN      VARCHAR2,
                              p_DOC_TYPE                   IN      VARCHAR2,
                              p_DOC_FREQUENCY              IN      VARCHAR2,
                              p_PROF_CLASS_NAME            IN      VARCHAR2,
                              x_Document_ID                OUT NOCOPY NUMBER,
                              x_Direct_Document            OUT NOCOPY VARCHAR2,
                              x_Document_Type              OUT NOCOPY VARCHAR2,
                              x_Paydoc_Indicator           OUT NOCOPY VARCHAR2,
                              x_Delivery_Method            OUT NOCOPY VARCHAR2,
                              x_Signature_Required         OUT NOCOPY VARCHAR2,
                              x_Print_Location             OUT NOCOPY VARCHAR2,
                              x_Summary_Flag               OUT NOCOPY VARCHAR2,
                              x_Payment_Term               OUT NOCOPY VARCHAR2,
                              x_Special_Handling           OUT NOCOPY VARCHAR2,
                              x_Number_of_Copies           OUT NOCOPY VARCHAR2,
                              x_Reporting_Day              OUT NOCOPY VARCHAR2,
                              x_Document_Frequency         OUT NOCOPY VARCHAR2,
                              x_Auto_Reprint_Flag          OUT NOCOPY VARCHAR2,
                              x_Document_Format            OUT NOCOPY VARCHAR2,
                              x_Media_Type                 OUT NOCOPY VARCHAR2,
                              x_Combo_Type                 OUT NOCOPY VARCHAR2,
                              x_Mail_To_Attention          OUT NOCOPY VARCHAR2,
                              x_Comments1                  OUT NOCOPY VARCHAR2,
                              x_Comments2                  OUT NOCOPY VARCHAR2,
                              x_Comments3                  OUT NOCOPY VARCHAR2,
                              x_Comments4                  OUT NOCOPY VARCHAR2,
                              -- Below Columns are added by Srini (Version# 1.1)
                              x_billdocs_term_id           OUT NOCOPY VARCHAR2,
                              x_Is_Parent                  OUT NOCOPY VARCHAR2,
                              x_Send_To_Parent             OUT NOCOPY VARCHAR2,
                              x_Parent_Doc_id              OUT NOCOPY VARCHAR2,
                              x_billdocs_status            OUT NOCOPY VARCHAR2,
                              x_billdoc_process_flag       OUT NOCOPY VARCHAR2,
                              x_Cust_Req_Start_date        OUT NOCOPY DATE,
                              x_Cust_Req_End_date          OUT NOCOPY DATE,
                              x_billdocs_eff_from_date     OUT NOCOPY DATE,
                              x_billdocs_eff_to_date       OUT NOCOPY DATE,
                              x_msg_status                 OUT NOCOPY VARCHAR2,
                              x_msg_data                   OUT NOCOPY VARCHAR2
                          ) IS

L_TRANSLATION_NAME         VARCHAR2(240);
BEGIN

  x_msg_status := 'S';

  if (P_CUSTOMER_TYPE = 'CONTRACT') THEN
    l_translation_name := 'XXCDH_CONTRACT_BILLDOCS';
  else
    l_translation_name := 'XXCDH_DIRECT_BILLDOCS';
  end if;

IF p_DOC_FREQUENCY='WEEKLY' AND P_CUSTOMER_TYPE = 'CONTRACT' THEN  -- Defect# 44425 Added by Theja Rajula 03/14/2018

SELECT   xval.source_value1,
         xval.source_value2,
         xval.source_value3,
         xval.source_value4,
         decode(p_DELIVERY_METHOD,'ePDF', p_DELIVERY_METHOD, xval.source_value5),
         xval.source_value6,
         xval.source_value7,
         xval.source_value8,
         xval.source_value9,
         xval.source_value10,
         xval.target_value1,
         xval.target_value2,
         xval.target_value3,
         xval.target_value4,
         xval.target_value5,
         xval.target_value6,
         xval.target_value7,
         xval.target_value8,
         xval.target_value9,
         xval.target_value10,
         xval.target_value11,
         xval.target_value12,

         xval.target_value13, -- Below Columns are added by Srini (Version# 1.1)
         xval.target_value14,
         xval.target_value15,
         decode(p_DELIVERY_METHOD,'ePDF', 'IN_PROCESS', xval.target_value16),
         xval.target_value17
  INTO
         x_Document_ID,
         x_Direct_Document,
         x_Document_Type,
         x_Paydoc_Indicator,
         x_Delivery_Method,
         x_Signature_Required,
         x_Print_Location,
         x_Summary_Flag,
         x_Payment_Term,
         x_Special_Handling,
         x_Number_of_Copies,
         x_Reporting_Day,
         x_Document_Frequency,
         x_Auto_Reprint_Flag,
         x_Document_Format,
         x_Media_Type,
         x_Combo_Type,
         x_Mail_To_Attention,
         x_Comments1,
         x_Comments2,
         x_Comments3,
         x_Comments4,

         x_billdocs_term_id, -- Below Columns are added by Srini (Version# 1.1)
         x_Is_Parent,
         x_Send_To_Parent,
         x_billdocs_status,
         x_billdoc_process_flag
  FROM   xx_fin_translatedefinition           xdef,
         xx_fin_translatevalues               xval
  WHERE  xdef.translation_name                = l_translation_name  -- 'XXCDH_CONTRACT_BILLDOCS' -- 'XXCDH_DIRECT_BILLDOCS'
  AND    xval.source_value5                   = p_DELIVERY_METHOD  --'ePDF' or 'PRINT'
  AND    xval.source_value3                   = p_DOC_TYPE -- 'Invoice' or 'Consolidated Bill'
  AND    xval.target_value3                   = p_DOC_FREQUENCY -- 'DAILY' or 'WEEKLY'
  and    xval.target_value9                   = nvl(p_PROF_CLASS_NAME,'SFA_LOW_RISK20_US')  -- Modified for defect 45359 'SFA_LOW_RISK_US' or 'SFA_LOW_RISK20_US' or 'FOS_MEDIUM_RISK_US'
  AND    xdef.translate_id                    = xval.translate_id
  AND    TRUNC  (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1))
                              AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1));
  ELSE
  SELECT   xval.source_value1,
         xval.source_value2,
         xval.source_value3,
         xval.source_value4,
         decode(p_DELIVERY_METHOD,'ePDF', p_DELIVERY_METHOD, xval.source_value5),
         xval.source_value6,
         xval.source_value7,
         xval.source_value8,
         xval.source_value9,
         xval.source_value10,
         xval.target_value1,
         xval.target_value2,
         xval.target_value3,
         xval.target_value4,
         xval.target_value5,
         xval.target_value6,
         xval.target_value7,
         xval.target_value8,
         xval.target_value9,
         xval.target_value10,
         xval.target_value11,
         xval.target_value12,

         xval.target_value13, -- Below Columns are added by Srini (Version# 1.1)
         xval.target_value14,
         xval.target_value15,
         decode(p_DELIVERY_METHOD,'ePDF', 'IN_PROCESS', xval.target_value16),
         xval.target_value17
  INTO
         x_Document_ID,
         x_Direct_Document,
         x_Document_Type,
         x_Paydoc_Indicator,
         x_Delivery_Method,
         x_Signature_Required,
         x_Print_Location,
         x_Summary_Flag,
         x_Payment_Term,
         x_Special_Handling,
         x_Number_of_Copies,
         x_Reporting_Day,
         x_Document_Frequency,
         x_Auto_Reprint_Flag,
         x_Document_Format,
         x_Media_Type,
         x_Combo_Type,
         x_Mail_To_Attention,
         x_Comments1,
         x_Comments2,
         x_Comments3,
         x_Comments4,

         x_billdocs_term_id, -- Below Columns are added by Srini (Version# 1.1)
         x_Is_Parent,
         x_Send_To_Parent,
         x_billdocs_status,
         x_billdoc_process_flag
  FROM   xx_fin_translatedefinition           xdef,
         xx_fin_translatevalues               xval
  WHERE  xdef.translation_name                = l_translation_name  -- 'XXCDH_CONTRACT_BILLDOCS' -- 'XXCDH_DIRECT_BILLDOCS'
  AND    xval.source_value5                   = p_DELIVERY_METHOD  --'ePDF' or 'PRINT'
  AND    xval.source_value3                   = p_DOC_TYPE -- 'Invoice' or 'Consolidated Bill'
  AND    xval.target_value3                   = p_DOC_FREQUENCY -- 'DAILY' or 'WEEKLY'
  AND    xdef.translate_id                    = xval.translate_id
  AND    TRUNC  (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1))
                              AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1));
  END IF;
  
  -----------------------------------------------------------------------------
  -- Added by Srini (Version# 1.1)
  -----------------------------------------------------------------------------

 x_Parent_Doc_id          := NULL;
 x_Cust_Req_Start_date    := TRUNC(sysdate);
 x_Cust_Req_End_date      := NULL;
 x_billdocs_eff_from_date := TRUNC(sysdate);
 x_billdocs_eff_to_date   := NULL;

  -----------------------------------------------------------------------------
  -- Changes end by Srini (Version# 1.1).
  -----------------------------------------------------------------------------


EXCEPTION 
  WHEN NO_DATA_FOUND THEN
  NULL;

  WHEN OTHERS THEN
    x_msg_status := 'E';
    x_msg_data := 'Error in get_billdoc_attrbs ' || sqlerrm ;

END get_billdoc_attrbs;

end XXCDH_BILLDOCS_PKG;
/