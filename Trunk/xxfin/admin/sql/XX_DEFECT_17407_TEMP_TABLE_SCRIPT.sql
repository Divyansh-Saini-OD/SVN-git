--Please connect to custom schema (xxfin )and execute following 1-4 steps


--Step:1

CREATE TABLE XX_DEPOSITS_TEMP1 
             AS SELECT DISTINCT XOLDD.ORIG_SYS_DOCUMENT_REF, 
                                XOLD.CASH_RECEIPT_ID 
             FROM APPS.XX_OM_LEGACY_DEP_DTLS XOLDD,   
             APPS.XX_OM_LEGACY_DEPOSITS XOLD 
             WHERE   1=2;

--Step:2

CREATE TABLE XX_DEPOSITS_TEMP2 
             AS SELECT /*+ parallel (OEH) */ TO_CHAR(OEH.ORDER_NUMBER) ORDER_NUMBER, 
                                XDT.ORIG_SYS_DOCUMENT_REF, 
                                XDT.CASH_RECEIPT_ID 
             FROM OE_ORDER_HEADERS_ALL OEH, 
             XX_DEPOSITS_TEMP1 XDT 
             WHERE 1=2;

--Step:3

GRANT ALL ON XX_DEPOSITS_TEMP1 TO APPS;

--Step:4

GRANT ALL ON XX_DEPOSITS_TEMP2 TO APPS;

-- Please connect to Apps schema and execute following 6-7 steps

--Step :6 

CREATE PUBLIC SYNONYM XX_DEPOSITS_TEMP1 FOR XXFIN.XX_DEPOSITS_TEMP1;

--Step :7

CREATE PUBLIC SYNONYM XX_DEPOSITS_TEMP2 FOR XXFIN.XX_DEPOSITS_TEMP2;


