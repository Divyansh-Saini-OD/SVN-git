LOAD DATA
TRUNCATE
INTO TABLE XX_PO_APPOINTMENT_DATE_TEMP
(PO_NUMBER			POSITION(1:50)		CHAR,
 APPOINTMENT_NUMBER	POSITION(51:100)	CHAR,
 LOC_NUMBER			POSITION(101:116)	CHAR,
 APPOINTMENT_DATE 	POSITION(117:132)	DATE "MM/DD/YYYY")