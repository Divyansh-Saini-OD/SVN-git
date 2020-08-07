-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
---|  Application    :   AR                                                   |
---|                                                                          |
---|  Name           :   XXFIN_AR_UPDTRXTYPEDFF.sql                           |
---|                                                                          |
---|  Description    :   This script updates POSTING_WORKER_NUMBER of         |
---|                                        AR_ADJUSTMENTS_ALL table          |
---|                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     12-JAN-2011   K. Dhillon           One time Update of Attribute1|
-- |                                             DFF on RA_CUST_TRX_TYPES_ALL |
-- |                                             To initialize the DFF value. |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

Update ra_cust_trx_types_all
set Attribute1 = 'Y';

Update ra_cust_trx_types_all
set Attribute1 = 'N'
where name in ('CA_DM-AMXCRD-CC',
'CA_DM-CCSCOMM-CC',
'CA_DM-CCSCRD-CONS-CC',
'CA_DM-NABMC-CC',
'CA_DM-NABVISA-CC',
'CA_DM-TELCHK-CK',
'CA_MSC-DM-CCSCOM-CC',
'CA_MSC-DM-NABVISA-CC',
'CA_MSC-DM-TELCHK-CK',
'US_DM-AMXCRD-CC_OD',
'US_DM-CCSCRD-COMM-CC',
'US_DM-CCSCRD-CONS-CC',
'US_DM-DCV3RN-CC',
'US_DM-MPSCRD-CC',
'US_DM-TELCHK-CK',
'US_MSC-DM-AMX-CC_OD',
'US_MSC-DM-CCSCOM-CC',
'US_MSC-DM-MPS-CC',
'US_MSC-DM-TEL-CK',
'CA_DM-CC CHGBACK_OD',
'CA_MSC-DM-AMX-CC',
'US_DM-MPSCRD-DB',
'CA_MSC-DM-NABMC-CC',
'US_MSC-DM-CCSCONS-CC',
'US_MSC-DM-DCV3RN-CC',
'US_MSC-DM-MPS-DB',
'US_DM-MPSCRD-CC_OD');

commit;


