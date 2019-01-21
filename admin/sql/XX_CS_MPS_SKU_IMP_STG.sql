--DROP TABLE  XXCRM.XX_CS_MPS_SKU_IMP_STG;

CREATE TABLE XXCRM.XX_CS_MPS_SKU_IMP_STG
(
MODEL                 VARCHAR2(250), 
SERIAL_NO             VARCHAR2(250), 
BLACK1                VARCHAR2(100), 
BLACK2                VARCHAR2(100), 
BLACK3                VARCHAR2(100), 
MAGENTA1              VARCHAR2(100), 
MAGENTA2              VARCHAR2(100), 
MAGENTA3              VARCHAR2(100), 
CYAN1                 VARCHAR2(100), 
CYAN2                 VARCHAR2(100), 
CYAN3                 VARCHAR2(100), 
YELLOW1               VARCHAR2(100), 
YELLOW2               VARCHAR2(100), 
YELLOW3               VARCHAR2(100), 
CREATION_DATE         DATE,          
CREATED_BY            NUMBER,        
LAST_UPDATE_DATE      DATE,          
LAST_UPDATED_BY       NUMBER  );