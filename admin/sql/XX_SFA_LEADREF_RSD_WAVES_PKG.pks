-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                     Wipro Technologies                                |
-- +=======================================================================+
-- | Name             :XX_SFA_LEADREF_RSD_WAVES_PKG.pks                    |
-- | Description      :I2043 RSD Waves, to validate the data for the RSD   |
-- |                   Waves that were converted from SOLAR.               |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      28-Apr-2008 Sreekanth          Intial Version                 |
-- +=======================================================================+

CREATE OR REPLACE PACKAGE XX_SFA_LEADREF_RSD_WAVES_PKG
AS
  -- +===================================================================+
  -- | Name             : P_Validate_Data_for_RSD_Waves                  |                                                                                       |
  -- | Description      : Procedure to validate the data for the RSD     |                                                                        |
  -- |                    Waves that were converted from SOLAR           |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- +===================================================================+
  
  PROCEDURE validate_data_for_rsd_waves(x_errbuf  OUT NOCOPY VARCHAR2
                                       ,x_retcode  OUT NOCOPY NUMBER);
  -- +===================================================================+
  -- | Name             : report_for_solar                               |
  -- | Description      : Procedure to Report the unprocessed            |
  -- |                    Lead Referral records for RSD Waves            |
  -- |                    not converted to oracle EBiz yet               |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- +===================================================================+
  
  PROCEDURE report_for_solar(x_errbuf  OUT NOCOPY VARCHAR2
                             ,x_retcode  OUT NOCOPY NUMBER);
END XX_SFA_LEADREF_RSD_WAVES_PKG;
/