--SET SHOW         OFF 
--SET VERIFY       OFF
--SET ECHO         OFF
--SET TAB          OFF
--SET TERM ON
--PROMPT Creating Package XX_GL_PERIOD_RATES_PKG
--PROMPT Program exits if the creation is not successful
--WHENEVER SQLERROR CONTINUE
create or replace
PACKAGE XX_GL_PERIOD_RATES_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name   :      Exchange Rates Calculation Program                  |
-- | Rice ID:      I0105                                               |
-- | Description : To calculate average rates and ending rate for      |
-- |               the currencies.                                     |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |1.0       10-JULY-2007 Samitha U M          Initial version        |
-- |1.1       24-FEB-2010  Subbu Pillai         R1.2 Defect 4272.      |
-- |1.2       31-AUG-2010  Bushrod Thomas       R1.5 CR759             |
-- |1.3       26-MAY-2011  Ritch Hartman        R11.3 CR912            |
-- +===================================================================+

-- +===================================================================+
-- | Name :  SUBMIT_GLDRICCP                                           |
-- | Description : The procedure Submits the delivered concurrent      |
-- |               program, GLDRICCP, to import whatever is in         |
-- |               the interface table.                                |
-- | Returns  :  Number                                                |
-- +===================================================================+
   FUNCTION  SUBMIT_GLDRICCP RETURN NUMBER;

-- +===================================================================+
-- | Name :  GL_AVG_END_RATES                                          |
-- | Description : The procedure  fetches currency values for the      |
-- |               the currenct period calculates the Average rate for |
-- |               US SOB  and  inserts into the gl_daily_rates  table |
-- |               and inserts the Average Rate and Ending Rate for    |
-- |               CAD in gl_translation_rates                         |
-- | Parameters : x_error_buff, x_ret_code,p_rundate                   |
-- | Returns :    Returns Code                                         |
-- |              Error Message                                        |
-- +===================================================================+
   PROCEDURE GL_AVG_END_RATES(
      x_error_buff  OUT NOCOPY VARCHAR2
     ,x_ret_code    OUT NOCOPY VARCHAR2
     ,p_rundate     IN  VARCHAR2 := to_char(SYSDATE,'MM-DD-RRRR')
   );
   
   -- +===================================================================+
-- | Name :  GL_FX_RATES_FORMULA                                       |
-- | Description :This procedure fetches by rate type i.e. 'OD Forecast|
-- |              all values with a 1, which were loaded from Bloomberg|
-- |              with a N.A.  Uses trasnlation for each currency to   |
-- |              calculate a conversion rate                          |
-- |                                                                   |
-- | Parameters : x_error_buff, x_ret_code,p_rundate,p_rate_type       |
-- | Returns :    Returns Code                                         |
-- |              Error Message                                        |
-- +===================================================================+
   PROCEDURE GL_FX_RATES_FORMULA(
      x_error_buff  OUT NOCOPY VARCHAR2
     ,x_ret_code    OUT NOCOPY VARCHAR2
     ,p_period_year     IN  VARCHAR2
     ,p_rate_type   IN  VARCHAR2
   );
   
-- +===================================================================+
-- | Name :  GL_FX_RATES_AVG                                           |
-- | Description:This procedure fetches currency values for OD Forecast|
-- |          ,OD Board Forecast, OD Internal Plan, OD Board Plan      |
-- |          calculates avgerage, and inserts with an Avg rate type   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : x_error_buff, x_ret_code,p_rundate,p_rate_type       |
-- | Returns :    Returns Code                                         |
-- |              Error Message                                        |
-- +===================================================================+
   PROCEDURE GL_FX_RATES_AVG(
      x_error_buff  OUT NOCOPY VARCHAR2
     ,x_ret_code    OUT NOCOPY VARCHAR2
     ,p_period_year     IN  VARCHAR2
     ,p_rate_type   IN  VARCHAR2
   );

-- +=======================================================================+
-- | Name : CREATE_AND_SEND_OUTBOUND_FILES                                 |
-- | Description : Generate files for delivery to partner systems          |
-- |                                                                       |
-- | Parameters : x_error_buff, x_ret_code                                 |
-- |             ,p_rundate     -- rate date                               |
-- |             ,p_request_key -- source1 in GL_RATE_REQUESTS translation |
-- |             ,p_create      -- Y/N to create file(s)                   |
-- |             ,p_send        -- Y/N to spawn jobs to FTP file(s)        |
-- | Returns :    Returns Code                                             |
-- |              Error Message                                            |
-- +=======================================================================+
   PROCEDURE CREATE_AND_SEND_OUTBOUND_FILES (
      x_error_buff  OUT NOCOPY VARCHAR2
     ,x_ret_code    OUT NOCOPY VARCHAR2
     ,p_rundate     IN  VARCHAR2 := TO_CHAR(SYSDATE,'MM-DD-RRRR')
     ,p_request_key IN  VARCHAR2 := '%'
     ,p_create      IN  VARCHAR2 := 'Y'
     ,p_send        IN  VARCHAR2 := 'Y'
     ,p_request_type IN  VARCHAR2 := 'FX'
   );

-- +=======================================================================+
-- | Name : TO_CONVERSION_DATE                                             |
-- | Description : Returns the ending date for a conversion rate           |
-- |               imported into gl_daily_rate_interface via host sqlldr   |
-- |               concurrent program XXGLRATELOAD.prog                    |
-- |               based on the starting date, taking into consideration   |
-- |               the need to have Friday rates valid through weekends    |
-- |               and rates requested after 5pm available for use during  |
-- |               the next working day prior to 5pm.                      |
-- | Parameters : p_from_conversion_date                                   |
-- |             ,p_date_format                                            |
-- | Returns :    date                                                     |
-- +=======================================================================+
   FUNCTION TO_CONVERSION_DATE (
      p_from_conversion_date VARCHAR2
     ,p_date_format          VARCHAR2
   ) RETURN DATE;

-- +=======================================================================+
-- | Name : PREVIOUS_RATE                                                  |
-- | Description : Returns the most recent ending rate for a conversion    |
-- |               prior to a specified date.  Used to populate a rate     |
-- |               when Bloomberg returns N.A. (because of holiday, etc)   |
-- |               If none found, return 0.                                |
-- | Parameters : p_from_conversion_date                                   |
-- | Returns :    conversion_rate                                          |
-- +=======================================================================+
   FUNCTION PREVIOUS_RATE (
      p_from_currency   VARCHAR2
     ,p_to_currency     VARCHAR2
     ,p_conversion_date VARCHAR2
     ,p_date_format     VARCHAR2
   ) RETURN NUMBER;

END XX_GL_PERIOD_RATES_PKG;
/
SHOW ERROR
