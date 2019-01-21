SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE XXCRM_IMPORT_SFDC_CONTACTS_PKG AS

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XXCRM_IMPORT_SFDC_CONTACTS_PKG.pks                        |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | Import AP and Ebill contacts from SFDC to Ebiz.                          |
-- |                                                                          |
-- | Contact records are placed in Ebiz staging table by a SOA process.       |
-- | This program reads all contacts not yet imported from the staging table. |
-- | Import each contact found if the corresponding corresponding Party Site  |
-- | is a customer.  Contacts are typically selected for import shortly after |
-- | their corresponding party site changes status from a prospect to         |
-- | a customer.                                                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author             Remarks                         |
-- |========  ===========  =================  ================================|
-- |1.0       25-JUL-2011  Phil Price         Initial version                 |
-- |                                                                          |
-- +==========================================================================+


PROCEDURE do_main (errbuf             out varchar2,
                   retcode            out number,
                   p_ap_role          in  varchar2,
                   p_ebill_role       in  varchar2,
                   p_timeout_days     in  number    default 90,
                   p_purge_days       in  number    default 365,
                   p_reprocess_errors in  varchar2  default 'N',
                   p_commit_flag      in  varchar2  default 'Y',
                   p_debug_level      in  number    default 0,
                   p_sql_trace        in  varchar2  default 'N'); 

END XXCRM_IMPORT_SFDC_CONTACTS_PKG;
/

show errors
