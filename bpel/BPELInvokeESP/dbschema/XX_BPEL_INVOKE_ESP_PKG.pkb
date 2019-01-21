CREATE OR REPLACE PACKAGE BODY xx_bpel_invoke_esp_pkg 
AS

  -- ------------------------------------------------------------------------
  -- $Id$
  -- ------------------------------------------------------------------------

  /*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_BPEL_INVOKE_ESP_PKG                                                               |
-- | Description : Package body for BPEL ESP Invocation                                                 |
-- |               This package performs the following                                                  |
-- |               1. Gets the ESP parameters to be used when invoking ESPMgr                           |
-- |               2. Updates a record in the XX_BPEL_ESP_SETUP table                                   |
-- |               3. Adds a record to the XX_BPEL_ESP_SETUP table                                      |
-- |                                                                                                    |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       21-June-2008 Cecilia Macean    Initial draft version.      			 	                    |
-- |                                                                                                    |
-- +====================================================================================================+
*/ 
PROCEDURE get_esp_job_info(p_process_domain IN VARCHAR2, 
                           p_process_name IN VARCHAR2, 
                           p_file_pattern IN VARCHAR2, 
                           x_job_name OUT VARCHAR2, 
                           x_esp_application OUT VARCHAR2, 
                           x_esp_verb OUT VARCHAR2) 
AS
  l_job_name                xx_bpel_esp_setup.JOB_NAME%TYPE;
  l_esp_application         xx_bpel_esp_setup.ESP_APPLICATION%TYPE;
  l_esp_verb                xx_bpel_esp_setup.ESP_VERB%TYPE;
  l_file_pattern            xx_bpel_esp_setup.FILE_PATTERN%TYPE;
  invalid_parameters        EXCEPTION;  
 
  BEGIN
    
    IF ( p_process_domain IS NULL OR p_process_domain = '') THEN
      RAISE invalid_parameters;
    END IF;
    
    IF ( p_process_name IS NULL OR p_process_name = '') THEN
      RAISE invalid_parameters;      
    END IF;
    
   IF ( p_file_pattern IS NULL OR p_file_pattern = '') THEN
      l_file_pattern := 'ALL';
   ELSE 
      l_file_pattern := p_file_pattern;
   END IF;
   
   BEGIN
      SELECT  job_name, esp_application, esp_verb
      INTO    l_job_name, l_esp_application, l_esp_verb
      FROM    xx_bpel_esp_setup
      WHERE       process_domain = p_process_domain
              AND process_name = p_process_name
              AND file_pattern = l_file_pattern;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
            IF ( l_file_pattern != 'ALL') THEN
                  l_file_pattern := 'ALL';
                  SELECT  job_name, esp_application, esp_verb
                  INTO    l_job_name, l_esp_application, l_esp_verb
                  FROM    xx_bpel_esp_setup
                  WHERE       process_domain = p_process_domain
                          AND process_name = p_process_name
                          AND file_pattern = l_file_pattern;
            END IF;
      WHEN OTHERS THEN
        RAISE;
  END;
   
    x_job_name := l_job_name;
    x_esp_application := l_esp_application;
    x_esp_verb := l_esp_verb;
    
  EXCEPTION
  WHEN others THEN
    x_job_name := '';
    x_esp_application := '';
    x_esp_verb := '';  
    
  END get_esp_job_info;

END xx_bpel_invoke_esp_pkg;

/

SHOW ERRORS;