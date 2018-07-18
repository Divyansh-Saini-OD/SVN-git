create or replace
TYPE  XX_CS_MPS_CONTRACT_REC_TYPE AS OBJECT
(Contract_Id              Integer,
Title                     VARCHAR2(150),
Description	              VARCHAR2(2000),
Currency_Code             VARCHAR2(50),
Sign_date                 Date,
Effective_date 	          Date,
Expiration_date 	        Date,
Extension_terms	          VARCHAR2(100),
Payment_terms	            VARCHAR2(100),
Custom_core_type          VARCHAR2(100),
Custom_core_list 	        VARCHAR2(100),
Custom_core_term          VARCHAR2(50),
Core_price_structure 	    VARCHAR(100),
Pricing_Summary	          VARCHAR2(2000),
attribute1                VARCHAR2(250),
attribute2                VARCHAR2(250),
attribute3                VARCHAR2(250),
attribute4                VARCHAR2(250),
attribute5                VARCHAR2(250))
/
show errors;
exit;