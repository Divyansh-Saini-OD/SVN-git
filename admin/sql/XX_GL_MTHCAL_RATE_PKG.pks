SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GL_MTHCAL_RATE_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_GL_MTHCAL_RATE_PKG                                                              |
  -- |                                                                                            |
  -- |  Description: This package body is to creates rates for CC Period End/Average and send     |
  -- |               rates to ERP Financial Cloud and EPM Cloud for FISCAL and CALENDAR Month     |
  -- |  RICE ID   :  I2122_Exchange Rates                                                         |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         01/20/2019   Paddy Sanjeevi       Initial version                              |
  -- +============================================================================================+
PROCEDURE Extract_rates( p_errbuf OUT VARCHAR2,p_retcode OUT NUMBER,
						 p_request_type IN VARCHAR2,
						 p_date IN VARCHAR2);

END XX_GL_MTHCAL_RATE_PKG;


/

SHOW ERRORS;