-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

CREATE OR REPLACE
PACKAGE XXBI_OPPORTUNITY_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name        : XXBI_OPPORTUNITY_PKG                                                      |
-- | Description : Package to populate custom Opportunity Fact table for DBI Reporting       |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0        10-Mar-2008       Sreekanth Rao       Initial Version                         |
-- +=========================================================================================+

AS

  PROCEDURE Log_Exception 
                          ( p_error_location          IN  VARCHAR2
                           ,p_error_message_code      IN  VARCHAR2
                           ,p_error_msg               IN  VARCHAR2
                           ,p_error_message_severity  IN  VARCHAR2
                           ,p_application_name        IN  VARCHAR2
                           ,p_module_name             IN  VARCHAR2
                           ,p_program_type            IN  VARCHAR2
                           ,p_program_name            IN  VARCHAR2
                           );

  PROCEDURE Populate_Oppty_Fact 
                         (
                           x_errbuf         OUT NOCOPY VARCHAR2
                          ,x_retcode        OUT NOCOPY NUMBER
                          ,p_mode           IN  VARCHAR2
                          ,p_from_date      IN  VARCHAR2
                          ,p_debug_mode     IN  VARCHAR2 DEFAULT 'N'                          
                         );

   PROCEDURE log_debug_msg
                         (
                          p_debug_msg              IN        VARCHAR2
                         );

END XXBI_OPPORTUNITY_PKG;
/