-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Oracle Consulting                                  |
-- +==========================================================================+
-- | SQL Script to create the following objects                               |
-- |             Table       : XXOM.XX_OM_TENDER_ATTR_IFACE_ALL               |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ==========   =============       ============================== |
-- | V1.0     25-Jun-2014  Vivek.S             New tab|e to hold tender record|
-- |                                           41 attrbutes data related to   | 
-- |                                           RCC changes                    |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
 
--DROP TABLE XXOM.XX_OM_TENDER_ATTR_IFACE_ALL;

  CREATE TABLE XXOM.XX_OM_TENDER_ATTR_IFACE_ALL 
                        ( orig_sys_document_ref VARCHAR2(20)
                        , order_source_id        NUMBER 
                        , orig_sys_payment_ref   VARCHAR2(20)
                        , routing_line1          VARCHAR2(20) 
                        , routing_line2          VARCHAR2(20)
                        , routing_line3          VARCHAR2(20)
                        , routing_line4          VARCHAR2(20) 
                        , batch_id               NUMBER
                        , request_id             NUMBER
                        , org_id                 NUMBER
                        , created_by             NUMBER    NOT NULL
                        , creation_date          DATE      NOT NULL   
                        , last_update_date       DATE      NOT NULL
                        , last_updated_by        NUMBER    NOT NULL
                        )
 TABLESPACE XXOD_TS_DATA
  PCTUSED    0
  PCTFREE    10
  INITRANS   1
  MAXTRANS   255
  STORAGE (  INITIAL          64K
             NEXT             1M
             MINEXTENTS       1
             MAXEXTENTS       2147483645
             PCTINCREASE      0
             BUFFER_POOL      DEFAULT
           )
  LOGGING 
  NOCOMPRESS 
  NOCACHE
  NOPARALLEL
  MONITORING;

CREATE INDEX XX_OM_TENDER_ATTR_IFACE_ALL_N1 ON XXOM.XX_OM_TENDER_ATTR_IFACE_ALL(orig_sys_document_ref);

CREATE SYNONYM XX_OM_TENDER_ATTR_IFACE_ALL FOR XXOM.XX_OM_TENDER_ATTR_IFACE_ALL;

CREATE SYNONYM XX_OM_TENDER_ATTR_IFACE_ALL FOR APPS;

GRANT ALL on XX_OM_TENDER_ATTR_IFACE_ALL to APPS;

GRANT DELETE, INSERT, SELECT, UPDATE on XXOM.XX_OM_TENDER_ATTR_IFACE_ALL to APPS WITH GRANT OPTION;

GRANT DELETE,INSERT, SELECT, UPDATE on XXOM.XX_OM_TENDER_ATTR_IFACE_ALL to ERP_SYSTEM_TABLE_SELECT_ROLE;

/
