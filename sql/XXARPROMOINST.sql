/**********************************************************************************
 Program Name: XXARPROMOINST.sql
 Purpose:      Creates xx_ar_promo_cardtypes and related objects.
               Creates xx_ar_promo_header and realted objects.
               Creates xx_ar_promo_detail and related objects.

 REVISIONS:
-- Version Date        Author                               Description
-- ------- ----------- ------------------------------------ ---------------------
-- 1.0     05-MAR-2007 Raji Natarajan,Wipro Technologies   Created base version.
-- 
**********************************************************************************/
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

DROP TABLE xxfin.xx_ar_promo_cardtypes CASCADE CONSTRAINTS;

CREATE TABLE xxfin.xx_ar_promo_cardtypes 
   (	card_type_id NUMBER, 
	card_type VARCHAR2(30 BYTE) NOT NULL ENABLE, 
	bin_start NUMBER NOT NULL ENABLE, 
	bin_end NUMBER NOT NULL ENABLE, 
	creation_date DATE DEFAULT SYSDATE, 
	created_by NUMBER(15), 
	last_update_date DATE DEFAULT SYSDATE, 
	last_updated_by NUMBER(15), 
      attribute1 VARCHAR2(30 BYTE),
      attribute2 VARCHAR2(30 BYTE),
      attribute3 VARCHAR2(30 BYTE)
    ) ;

DROP SEQUENCE xxfin.xx_ar_promo_card_id_s;

CREATE SEQUENCE xxfin.xx_ar_promo_card_id_s START WITH 10000 INCREMENT BY 1;

DROP SYNONYM xx_ar_promo_cardtypes;

CREATE SYNONYM xx_ar_promo_cardtypes FOR xxfin.xx_ar_promo_cardtypes;

--GRANT SELECT,INSERT,UPDATE ON xxfin.xx_ar_promo_cardtypes TO APPS;


DROP TABLE xxfin.xx_ar_promo_header CASCADE CONSTRAINTS;

CREATE TABLE xxfin.xx_ar_promo_header
   (	promo_id NUMBER NOT NULL ENABLE, 
	card_type VARCHAR2(30 BYTE) NOT NULL ENABLE, 
	promo_plan_code NUMBER NOT NULL ENABLE, 
	effective_start_date DATE DEFAULT SYSDATE, 
	effective_end_date DATE DEFAULT SYSDATE, 
	description VARCHAR2(50 BYTE), 
	comments VARCHAR2(50 BYTE), 
	minimum_amount NUMBER(15,0) NOT NULL ENABLE, 
	creation_date DATE DEFAULT SYSDATE, 
	created_by NUMBER(15), 
	last_update_date DATE DEFAULT SYSDATE, 
	last_updated_by NUMBER(15), 
      attribute1 VARCHAR2(30 BYTE),
      attribute2 VARCHAR2(30 BYTE),
      attribute3 VARCHAR2(30 BYTE)
 ) ;

DROP SEQUENCE xxfin.xx_ar_promo_id_s;

CREATE SEQUENCE xxfin.xx_ar_promo_id_s START WITH 10000 INCREMENT BY 1;

DROP SYNONYM xx_ar_promo_header;

CREATE SYNONYM xx_ar_promo_header FOR xxfin.xx_ar_promo_header;

--GRANT SELECT,INSERT,UPDATE ON xxfin.xx_ar_promo_header TO APPS;

DROP TABLE xxfin.xx_ar_promo_detail CASCADE CONSTRAINTS;

  CREATE TABLE xxfin.xx_ar_promo_detail
   (	promo_id NUMBER NOT NULL ENABLE, 
	promo_column VARCHAR2(50 BYTE) NOT NULL ENABLE, 
	promo_values VARCHAR2(50 BYTE) NOT NULL ENABLE, 
	creation_date DATE DEFAULT SYSDATE, 
	created_by NUMBER(15), 
	last_update_date DATE DEFAULT SYSDATE, 
	last_updated_by NUMBER(15),
      attribute1 VARCHAR2(30 BYTE),
      attribute2 VARCHAR2(30 BYTE),
      attribute3 VARCHAR2(30 BYTE)
   ) ;


DROP SYNONYM xx_ar_promo_detail;

CREATE SYNONYM xx_ar_promo_detail FOR xxfin.xx_ar_promo_detail;

--GRANT SELECT,INSERT,UPDATE ON xxfin.xx_ar_promo_detail TO APPS;

SHOW ERROR

