                                                                       --SET SHOW         OFF 
--SET VERIFY       OFF
--SET ECHO         OFF
--SET TAB          OFF
--SET TERM ON
--PROMPT Creating Package XX_MM_GL_PERIOD_RATES_PKG
--PROMPT Program exits if the creation is not successful
--WHENEVER SQLERROR CONTINUE
create or replace
PACKAGE XX_MM_GL_PERIOD_RATES_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name   :      Exchange Rates Calculation Program  for MidMonth    |
-- | Rice ID:                                                          |
-- | Description : To calculate average rates and ending rate for      |
-- |               the currencies.  For Midmonth, copied the package   |
-- |               XX_GL_PERIOD_RATES_PKG(Subversion) and adjusted to  |
-- |               run if thePeriodEndDate is on any day(Sun-Sat)      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |1.0       19-AUG-2015  Madhu Bolli          Initial version        |
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
   
END XX_MM_GL_PERIOD_RATES_PKG;
/
SHOW ERROR
