CREATE OR REPLACE PACKAGE XX_POMPO_EXTRACT_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_POMPO_EXTRACT_PKG                                                               |
  -- |                                                                                            |
  -- |  Description: Scripts for fetching Po Number from EBS and placed into the XXFIN Top.       |
  -- |  RICE ID:                                                                                  |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  ===============      =============================================|
  -- | 1.0         28-OCT-2020   Karan Varshney      Initial Version Added                        |
  -- +============================================================================================|
  -- +============================================================================================|
  
  PROCEDURE POM_PO_EXPORT_PRC (ERRBUF OUT VARCHAR2,
                               RETCODE OUT NUMBER
                              );
  
END XX_POMPO_EXTRACT_PKG;
/