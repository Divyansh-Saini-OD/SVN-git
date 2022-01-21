SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT CREATING PACKAGE SPEC XX_AR_RFND_POS_PKG
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AR_RFND_POS_PKG
AS
-- +============================================================================================+
-- |  Office Depot - SDR project                                                                |
-- |  Oracle GSD Consulting                                                                     |
-- +============================================================================================+
-- |  Name:  XX_AR_RFND_POS_PKG                                                                 |
-- |  Rice Id : I1038                                                                           |
-- |  Description:  This OD Package that contains a procedure to create AR Refund process for   |
-- |                POS                                                                         |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    =================================================|
-- | 1.0         06-APR-2011  Vamshi Katta     Initial version                                  |
-- +============================================================================================+
PROCEDURE INSERT_MCHECK_POS_RFND_PROC
(  ERR_BUF      OUT VARCHAR2
 , RETCODE      OUT NUMBER   );
-- +============================================================================================+
-- |  Name: INSERT_MCHECK_POS_RFND_PROC                                                         |
-- |  Description: This procedure extracts records from mail check table and insert only        |
-- |               pending POS records inot refund temp table for further processing via E055.  |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |                                                                                            |
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+

END XX_AR_RFND_POS_PKG;
/