-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |               Oracle Consulting Organization                          |
-- +=======================================================================+
-- | Name             :DATA_XX_COM_SYSTEM_CODES_CONV.SQL                   |
-- | Description      :Data load for when XX_COM_SYSTEM_CODES_CONV         |
-- |                   is overwritten by drop/create script                |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |Draft1a  14-Jun-2007 Rajeev Kamath      Initial Version (Extract from  |
-- |                                        GSICNV02 14-Jun-2007)          |
-- +=======================================================================+



INSERT INTO XX_COM_SYSTEM_CODES_CONV ( SYSTEM_CODE, SYSTEM_NAME, DESCRIPTION, SYSTEM_PLATFORM,
COUNTRY_CODE, APPLICATION, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY,
LAST_UPDATE_DATE ) VALUES ( 
'U1PSF', 'PeopleSoft Financials', 'PeopleSoft Financial Systems', 'DB2/OS390', 'U1'
, 'EBS', 1677, '19-MAY-07', 1677, '04-JUN-07'); 
INSERT INTO XX_COM_SYSTEM_CODES_CONV ( SYSTEM_CODE, SYSTEM_NAME, DESCRIPTION, SYSTEM_PLATFORM,
COUNTRY_CODE, APPLICATION, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY,
LAST_UPDATE_DATE ) VALUES ( 
'U1RTK', 'RTK', 'Retek/Oracle Retail Merchandising Application', 'Oracle/Linux', 'U1'
, 'EBS', 1677, '19-MAY-07', 1677, '04-JUN-07'); 
INSERT INTO XX_COM_SYSTEM_CODES_CONV ( SYSTEM_CODE, SYSTEM_NAME, DESCRIPTION, SYSTEM_PLATFORM,
COUNTRY_CODE, APPLICATION, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY,
LAST_UPDATE_DATE ) VALUES ( 
'U1MAR', 'MARS', 'Mainframe Accounts Receivable System', 'DB2/ES9000', 'U1', 'EBS'
, 1677, '19-MAY-07', 1677, '04-JUN-07'); 
INSERT INTO XX_COM_SYSTEM_CODES_CONV ( SYSTEM_CODE, SYSTEM_NAME, DESCRIPTION, SYSTEM_PLATFORM,
COUNTRY_CODE, APPLICATION, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY,
LAST_UPDATE_DATE ) VALUES ( 
'U1MBS', 'MBS', 'Mainframe Billing System', 'DB2/ES9000', 'U1', 'EBS', 1677, '19-MAY-07'
, 1677, '04-JUN-07'); 
INSERT INTO XX_COM_SYSTEM_CODES_CONV ( SYSTEM_CODE, SYSTEM_NAME, DESCRIPTION, SYSTEM_PLATFORM,
COUNTRY_CODE, APPLICATION, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY,
LAST_UPDATE_DATE ) VALUES ( 
'U1GPD', 'GetPaid', 'Credit, Collection, and Customer Relationship Management System'
, 'SQL Server/Windows', 'U1', 'EBS', 1677, '19-MAY-07', 1677, '04-JUN-07'); 
INSERT INTO XX_COM_SYSTEM_CODES_CONV ( SYSTEM_CODE, SYSTEM_NAME, DESCRIPTION, SYSTEM_PLATFORM,
COUNTRY_CODE, APPLICATION, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY,
LAST_UPDATE_DATE ) VALUES ( 
'U1BNA', 'BNA', 'Fixed Asset Management System', 'SQL Server/Windows', 'U1', 'EBS'
, 1677, '19-MAY-07', 1677, '04-JUN-07'); 
COMMIT;
 