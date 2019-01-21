SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_SFA_LEADS_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_SFA_LEADS_PKG.pks                                                      |
-- | Description : Package Spec to perform TCA Entity Validations and to invoke the seeded   |
-- |               Import Sales Leads program with the required parameters.                  |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1A   15-Jun-2007       Ashok Kumar T J     Initial draft version                   |
-- |DRAFT 1b   15-Nov-2007      Piyush Khandelwal    Modified to add new error handling part.|
-- |DRAFT 1c   20-Dec-2007      Piyush Khandelwal    Modified to add batch_id as a parameter.|
-- +=========================================================================================+
 AS
  -- Global Variable
  -- g_conversion_id  XX_COM_EXCEPTIONS_LOG_CONV.converion_id%TYPE := 08091;

  G_PROGRAM_TYPE      CONSTANT VARCHAR2(30) := 'I0809_LeadInterface';
  G_APPLICATION_NAME  CONSTANT VARCHAR2(30) := 'XXCRM';
  G_PROGRAM_NAME      CONSTANT VARCHAR2(30) := 'XX_SFA_LEADS_PKG.main_proc';
  G_MODULE_NAME       CONSTANT VARCHAR2(80) := 'SFA';
  G_ERROR_STATUS_FLAG CONSTANT VARCHAR2(80) := 'ACTIVE';
  ------------------------------------------
  -- Function to get the TCA Entity Id's  --
  ------------------------------------------

  FUNCTION GET_OWNER_TABLE_ID(P_ORIG_SYSTEM           IN VARCHAR2,
                              P_ORIG_SYSTEM_REFERENCE IN VARCHAR2,
                              P_OWNER_TABLE_NAME      IN VARCHAR2,
                              P_ERR_MSG               OUT VARCHAR2)
    RETURN NUMBER;

  --------------------------------------------------------------------------------------------
  -- Procedure registered as Concurrent program to perform OSR Checks, update the interface --
  -- table(s) with the respective TCA Entity Id and to call the standard concurrent program --
  -- "Import Sales Leads" to import the leads in to oracle.                                 --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_PROC(X_ERRBUF  OUT NOCOPY VARCHAR2,
                      X_RETCODE OUT NOCOPY NUMBER,
                      P_BATCHID IN NUMBER);

END XX_SFA_LEADS_PKG;

/

SHOW ERR

EXIT
