--**************************************************************************************************
--
-- Object Name    :Archive/Purge Bank Statements
--
-- Program Name   : XX_PURGE_ARCHIVE_V.sql
--
--
-- Purpose        : Create Custom View for Purge Object look up type.
--                  The Objects created are:
--                     1), XX_PURGE_ARCHIVE_V 		View
--                              
--
-- Change History  :
-- Version         Date             Changed By           Description 
--**************************************************************************************************
--    1.0        31-July-2013       Rishabh Chhajer      Initial creation
--**************************************************************************************************

CREATE OR REPLACE FORCE VIEW XX_PURGE_ARCHIVE_V
(
   MEANING,
   DESCRIPTION,
   LOOKUP_CODE
)
AS
   SELECT   MEANING,
            DECODE (
               meaning,
               'Statement',
               '***WARNING*** THIS WOULD DELETE BASE TABLE RECORDS ***'
               || DESCRIPTION,
               'Both',
               '***WARNING*** THIS WOULD DELETE BASE TABLE AND INTERFACE RECORDS ***'
               || DESCRIPTION,
               'Interface',
               '***WARNING*** THIS WOULD DELETE INTERFACE RECORDS ***'
               || DESCRIPTION,
               DESCRIPTION
            ),
            LOOKUP_CODE
     FROM   CE_LOOKUPS
    WHERE   lookup_type = 'PURGE_OBJECTS';