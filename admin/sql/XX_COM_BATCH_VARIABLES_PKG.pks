create or replace PACKAGE XX_COM_BATCH_VARIABLES_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_COM_BATCH_VARIABLES_PKG                                                         |
-- |  Description:  This package is used to process variables used by batch jobs run by ESP     |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08-Jan-2009  Joe Klein        Initial version                                  |
-- +============================================================================================+


-- +============================================================================================+
-- |  Name: get                                                                                 |
-- |  Description: This function will return the value of a variable in the                     |
-- |               xxfin.xx_batch_variables table.                                              |
-- |  Parameters:                                                                               |
-- |    p_subtrack              IN  -- subtrack of variable                                     |
-- |    p_variable_name         IN  -- variable name                                            |
-- |                                                                                            |
-- +============================================================================================+
  FUNCTION get
  (p_subtrack IN VARCHAR2 DEFAULT NULL,
   p_variable_name IN VARCHAR2 DEFAULT NULL) 
   RETURN VARCHAR2;


-- +============================================================================================+
-- |  Name: set_batch_single_variable_efap                                                                 |
-- |  Description: This procedure will call the AP-specific procedure to set a single AP        |
-- |               variable value.                                                              |
-- |  Parameters:                                                                               |
-- |    p_variable_name         IN  -- Variable name                                            |
-- |    p_value                 IN  -- Variable value                                           |
-- |                                                                                            |
-- +============================================================================================+
  PROCEDURE set_batch_single_variable_efap
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL);


-- +============================================================================================+
-- |  Name: set_batch_single_variable_efar                                                                 |
-- |  Description: This procedure will call the AR-specific procedure to set a single AR        |
-- |               variable value.                                                              |
-- |  Parameters:                                                                               |
-- |    p_variable_name         IN  -- Variable name                                            |
-- |    p_value                 IN  -- Variable value                                           |
-- |                                                                                            |
-- +============================================================================================+
  PROCEDURE set_batch_single_variable_efar
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL);


-- +============================================================================================+
-- |  Name: set_batch_single_variable_efce                                                                 |
-- |  Description: This procedure will call the CE-specific procedure to set a single CE        |
-- |               variable value.                                                              |
-- |  Parameters:                                                                               |
-- |    p_variable_name         IN  -- Variable name                                            |
-- |    p_value                 IN  -- Variable value                                           |
-- |                                                                                            |
-- +============================================================================================+
  PROCEDURE set_batch_single_variable_efce
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL);


-- +============================================================================================+
-- |  Name: set_batch_single_variable_efgl                                                                 |
-- |  Description: This procedure will call the GL-specific procedure to set a single GL        |
-- |               variable value.                                                              |
-- |  Parameters:                                                                               |
-- |    p_variable_name         IN  -- Variable name                                            |
-- |    p_value                 IN  -- Variable value                                           |
-- |                                                                                            |
-- +============================================================================================+
  PROCEDURE set_batch_single_variable_efgl
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL);


-- +============================================================================================+
-- |  Name: set_batch_single_variable_efpa                                                                 |
-- |  Description: This procedure will call the PA-specific procedure to set a single PA        |
-- |               variable value.                                                              |
-- |  Parameters:                                                                               |
-- |    p_variable_name         IN  -- Variable name                                            |
-- |    p_value                 IN  -- Variable value                                           |
-- |                                                                                            |
-- +============================================================================================+
  PROCEDURE set_batch_single_variable_efpa
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL);


-- +============================================================================================+
-- |  Name: set_batch_variables_efap                                                            |
-- |  Description: This procedure set the AP specific variables.                                |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_procdate              IN  -- date from which all date variables are calculated        |
-- |                                                                                            |
-- +============================================================================================+
  PROCEDURE set_batch_variables_efap
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_procdate IN DATE DEFAULT sysdate);


-- +============================================================================================+
-- |  Name: set_batch_variables_efar                                                            |
-- |  Description: This procedure set the AR specific variables.                                |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_procdate              IN  -- date from which all date variables are calculated        |
-- |                                                                                            |
-- +============================================================================================+  
  PROCEDURE set_batch_variables_efar
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_procdate IN DATE DEFAULT sysdate);


-- +============================================================================================+
-- |  Name: set_batch_variables_efce                                                            |
-- |  Description: This procedure set the CE specific variables.                                |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_procdate              IN  -- date from which all date variables are calculated        |
-- |                                                                                            |
-- +============================================================================================+  
  PROCEDURE set_batch_variables_efce
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_procdate IN DATE DEFAULT sysdate);


-- +============================================================================================+
-- |  Name: set_batch_variables_efgl                                                            |
-- |  Description: This procedure set the GL specific variables.                                |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_procdate              IN  -- date from which all date variables are calculated        |
-- |                                                                                            |
-- +============================================================================================+  
  PROCEDURE set_batch_variables_efgl
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_procdate IN DATE DEFAULT sysdate);


-- +============================================================================================+
-- |  Name: set_batch_variables_efpa                                                            |
-- |  Description: This procedure set the PA specific variables.                                |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_procdate              IN  -- date from which all date variables are calculated        |
-- |                                                                                            |
-- +============================================================================================+  
  PROCEDURE set_batch_variables_efpa
  (errbuff OUT varchar2,
   retcode OUT varchar2,
   p_procdate IN DATE DEFAULT sysdate);



END XX_COM_BATCH_VARIABLES_PKG;


/
