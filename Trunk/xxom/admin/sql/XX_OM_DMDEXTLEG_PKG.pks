SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_OM_DMDEXTLEG_PKG
IS
-- +=================================================================================================+
-- |                  Office Depot - Project Simplify                                                |
-- |                                                                                                 |
-- +=================================================================================================+
-- | Name        :  XX_OM_DMDEXTLEG_PKG.pks                                                          |
-- | Description :  This package will extracts the Sales Order demand into 2 files for use in the    |
-- |                Legacy replenishment engine                                                      |                                                                                
-- |                                                                                                 |
-- |Change Record:                                                                                   |
-- |===============                                                                                  |
-- |RiceID   Version   Date        Author           Remarks                                          |
-- |======  =======   ==========  =============    ================================                  |
-- |E1315   V1.0      27-Jun-2007 Marc Kelly       First Version                                     |
-- |        V1.1      01-Aug-2007 Matthew Craig    Updated parameter order                                                                                       |
-- |                                                                                                 |
-- +=================================================================================================+

-- +======================================================================+
-- | Name: Demand_Extract                                                 |
-- | Description: This procedure serves as the entry point to the package.|
-- |              It calls both DEMAND_EXTRACT_FUTURE and                 |
-- |              DEMAND_EXTRACT_SEASONAL private procedures.  Errors     |
-- |              creating flat files will be logged in global exceptions.|
-- |              Other errors wil be caught and logged and a business    |
-- |              event raised.                                           |
-- |                                                                      |
-- | Parameters:                                                          |
-- |              p_seasonal_file  - seasonal demand file name by default |
-- |                                 file name is XXOMDMDEXTLEGSEA.txt    |
-- |              p_future_file    - future demand file name by default   |
-- |                                 file name is XXOMDMDEXTLEGFUT.txt    |
-- |              p_file_location  - EBS XXOM output directory            |
-- |              x_retcode                                               |
-- |              x_errbuf                                                |
-- +======================================================================+
PROCEDURE Demand_Extract(
                x_retcode OUT NOCOPY NUMBER
                ,x_errbuf OUT NOCOPY VARCHAR2   
                ,p_seasonal_file IN VARCHAR2 DEFAULT 'XOMDMDEXTLEGSEA.txt'
                ,p_future_file IN VARCHAR2 DEFAULT 'XOMDMDEXTLEGFUT.txt'
                ,p_file_location IN VARCHAR2
                );

-- +======================================================================+
-- | Name: Demand_Extract_Future                                          |
-- | Description: This procedure extracts future orders and creates       |
-- |              a flat file. Errors creating flat files will be         |
-- |              logged in global exception log.                         |
-- |                                                                      |
-- | Parameters:                                                          |
-- |              p_future_file    - future demand file name              |
-- |              p_file_location  - EBS XXOM output directory            |
-- |              x_ret_code                                              |
-- |              x_err_buf                                               |
-- +======================================================================+
PROCEDURE Demand_Extract_Future (
                p_future_file IN VARCHAR2 
                ,p_file_location IN VARCHAR2
                ,x_error_code OUT NOCOPY NUMBER
                ,x_error_status OUT NOCOPY VARCHAR2   
                );

-- +======================================================================+
-- | Name: Demand_Extract_Seasonal                                        |
-- | Description: This procedure extracts seasonal orders and creates     |
-- |              a flat file. Errors creating flat files will be         |
-- |              logged in global exception log.                         |
-- |                                                                      |
-- | Parameters:                                                          |
-- |              p_seasonal_file  - seasonal demand file name            |
-- |              p_file_location  - EBS XXOM output directory            |
-- |              x_ret_code                                              |
-- |              x_err_buf                                               |
-- +======================================================================+
PROCEDURE Demand_Extract_Seasonal (
                p_seasonal_file IN VARCHAR2 
                ,p_file_location IN VARCHAR2
                ,x_error_code OUT NOCOPY NUMBER
                ,x_error_status OUT NOCOPY VARCHAR2   
                );

-- +======================================================================+
-- | Name: is_replenished                                                 |
-- | Description: This function decides if the item is replenishable based|
-- |              on the item attributes defined.                         |
-- |                                                                      |
-- | Parameters:                                                          |
-- |              p_replen_type                                           |
-- |              p_replen_subtype                                        |
-- +======================================================================+
FUNCTION is_replenished (
      p_replen_type IN mtl_categories_b.segment7%TYPE     --replen type 
      ,p_replen_subtype IN mtl_categories_b.segment6%TYPE --replen subtype
      ) RETURN BOOLEAN;

END XX_OM_DMDEXTLEG_PKG;
/
SHOW ERRORS