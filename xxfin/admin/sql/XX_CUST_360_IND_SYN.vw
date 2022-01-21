/*-- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  Index and Synonym Creation Script                                                  |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description:  Creates Indexes and Public Synonym on all materialzed views used 			  |
  -- | 				  in XX_CRM_CUST360DETAILS_PKG  											  |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                     
  -- | 1.0         01-Oct-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |                     
  -- +============================================================================================| */

CREATE INDEX APPS.XX_CRM_PAYMT_TERMS_OBJS_MV_N1 ON APPS.XX_CRM_PAYMENT_TERMS_OBJS_MV
  (
    ORIG_SYSTEM_REFERENCE
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
CREATE INDEX APPS.XX_CRM_AR_COLLECTOR_OBJS_MV_N1 ON APPS.XX_CRM_AR_COLLECTOR_OBJS_MV
  (
    ORIG_SYSTEM_REFERENCE
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
CREATE INDEX APPS.XX_CRM_GRAND_PARENT_OBJS_MV_N1 ON APPS.XX_CRM_GRAND_PARENT_OBJS_MV
  (
    ORIG_SYSTEM_REFERENCE
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
CREATE INDEX APPS.XX_CRM_CREDIT_LIMTS_OBJS_MV_N1 ON APPS.XX_CRM_CREDIT_LIMTS_OBJS_MV
  (
    ORIG_SYSTEM_REFERENCE
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
CREATE INDEX APPS.XX_AR_CUSTOMER_AGING_MV_N1 ON APPS.XX_AR_CUSTOMER_AGING_MV
  (
    AOPS_NUM
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
CREATE INDEX APPS.XX_AR_CUSTOMER_PARENT_MV_N1 ON APPS.XX_AR_CUSTOMER_PARENT_MV
  (
    ORIG_AOPS_NUM
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
CREATE INDEX APPS.XX_AR_CUSTOMER_AGING_CH_MV_N1 ON APPS.XX_AR_CUSTOMER_AGING_CH_MV
  (
    PAR_AOPS_NUM
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
CREATE INDEX APPS.XX_AR_CUSTOMER_AGING_GC_MV_N1 ON APPS.XX_AR_CUSTOMER_AGING_GC_MV
  (
    PARENT_ID
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
CREATE INDEX APPS.XX_CRM_EBILL_CONTACT_MV_N1 ON APPS.XX_CRM_EBILL_CONTACT_OBJS_MV
  (
    ORIG_SYSTEM_REFERENCE
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
  
CREATE OR REPLACE PUBLIC SYNONYM XX_CRM_AR_COLLECTOR_OBJS_MV FOR APPS.XX_CRM_AR_COLLECTOR_OBJS_MV;
CREATE OR REPLACE PUBLIC SYNONYM XX_AR_CUSTOMER_AGING_MV FOR APPS.XX_AR_CUSTOMER_AGING_MV;
CREATE OR REPLACE PUBLIC SYNONYM XX_AR_CUSTOMER_AGING_CH_MV FOR APPS.XX_AR_CUSTOMER_AGING_CH_MV;
CREATE OR REPLACE PUBLIC SYNONYM XX_AR_CUSTOMER_AGING_GC_MV FOR APPS.XX_AR_CUSTOMER_AGING_GC_MV;
CREATE OR REPLACE PUBLIC SYNONYM XX_AR_CUSTOMER_PARENT_MV FOR APPS.XX_AR_CUSTOMER_PARENT_MV;
CREATE OR REPLACE PUBLIC SYNONYM XX_CRM_CREDIT_LIMTS_OBJS_MV FOR APPS.XX_CRM_CREDIT_LIMTS_OBJS_MV;
CREATE OR REPLACE PUBLIC SYNONYM XX_CRM_EBILL_CONTACT_OBJS_MV FOR APPS.XX_CRM_EBILL_CONTACT_OBJS_MV;
CREATE OR REPLACE PUBLIC SYNONYM XX_CRM_GRAND_PARENT_OBJS_MV FOR APPS.XX_CRM_GRAND_PARENT_OBJS_MV;
CREATE OR REPLACE PUBLIC SYNONYM XX_CRM_PAYMENT_TERMS_OBJS_MV FOR APPS.XX_CRM_PAYMENT_TERMS_OBJS_MV;


