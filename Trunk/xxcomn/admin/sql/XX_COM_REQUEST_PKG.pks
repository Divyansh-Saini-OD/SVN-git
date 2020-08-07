create or replace
PACKAGE XX_COM_REQUEST_PKG AS

-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  XX_COM_REQUEST_PKG                                                                 | 
-- |  Description:  This package is used by ESP to submit concurrent programs for execution     |
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         17-Nov-2008  B.Thomas         Initial version                                  |
-- +============================================================================================+ 

GC_JOB_DEF_TRANS_NAME    CONSTANT VARCHAR2(50)  := 'ESP_COMN_JOB_DEF';
GC_ARG_DEF_TRANS_NAME    CONSTANT VARCHAR2(50)  := 'ESP_COMN_ARG_DEF';

-- +============================================================================================+ 
-- |  Name: SUBMIT                                                                              | 
-- |  Description: The procedure runs a concurrent program as defined in translation tables     |
-- |              (See XX_FIN_TRANSLATE_PKG, XX_FIN_TRANSLATEDEFINITION, XX_FIN_TRANSLATEVALUES)| 
-- |  Parameters:                                                                               | 
-- |    p_esp_job_name          IN  -- jobname.jobqual as specified in runbook                  |
-- |    p_simulate              IN  -- Y/N/ESP (Y means find args but do not run;               |  
-- |                                            N means run and monitor for completion          |  
-- |                                            ESP means run and return request_id in Errbuf   |  
-- |                                                                                            |  
-- +============================================================================================+
PROCEDURE SUBMIT
( 
     Errbuf          OUT NOCOPY VARCHAR2
    ,Retcode         OUT NOCOPY VARCHAR2
    ,p_esp_job_name  IN  VARCHAR2
    ,p_simulate      IN  VARCHAR2 := NULL
);

-- +============================================================================================+ 
-- |  Name: LIST_MISMATCHED_PARAMS                                                              | 
-- |  Description: The procedure compares translation args with concurrent program parameters   |
-- |                 and outputs a line of details if they do not match.                        |  
-- |                 It also outputs if any arg variables are undefined                         |  
-- |  Parameters:                                                                               | 
-- |    p_translation_name  IN  -- translation to check (e.g., ESP_EFCE_JOB_DEF)                |
-- |                                                                                            |  
-- +============================================================================================+
PROCEDURE LIST_MISMATCHED_PARAMS (
  Errbuf             OUT NOCOPY VARCHAR2
 ,Retcode            OUT NOCOPY VARCHAR2
 ,p_translation_name IN VARCHAR2
);

-- +============================================================================================+
-- |  Name: LIST_JOBS                                                                           |
-- |  Description: The procedure simulates all of the translation's active jobs                 |
-- |                 and outputs a line of details for each, including actual arguments         |
-- |  Parameters:                                                                               |
-- |    p_translation_name  IN  -- translation to check (e.g., ESP_EFCE_JOB_DEF)                |
-- |                                                                                            |  
-- +============================================================================================+
PROCEDURE LIST_JOBS (
  Errbuf             OUT NOCOPY VARCHAR2
 ,Retcode            OUT NOCOPY VARCHAR2
 ,p_translation_name IN VARCHAR2
);

-- +============================================================================================+ 
-- |  Name: COUNT_CHR                                                                           | 
-- |  Description: Utility function to return the number of character occurrences in a string   |
-- |                                                                                            |  
-- |  Parameters:                                                                               | 
-- |    p_str              IN  -- string to look in                                             |
-- |    p_chr              IN  -- character to look for (e.g., ',')                             |  
-- |                                                                                            |  
-- +============================================================================================+
FUNCTION COUNT_CHR (
  p_str IN VARCHAR2
 ,p_chr IN VARCHAR2
) RETURN NUMBER;

-- +============================================================================================+ 
-- |  Name: COUNT_PARMS                                                                         | 
-- |  Description: Utility function to return the number of enabled parameters for program      |
-- |                                                                                            |  
-- |  Parameters:                                                                               | 
-- |    p_application_name    IN  -- application name (e.g., XXCDH)                             |
-- |    p_program_shortname   IN  -- program name  (e.g., XX_CDH_DQM_SYNC_CREATE)               |  
-- |                                                                                            |  
-- +============================================================================================+
FUNCTION COUNT_PARMS (
  p_application_name  IN VARCHAR2
 ,p_program_shortname IN VARCHAR2
) RETURN NUMBER;


END XX_COM_REQUEST_PKG;
/
