create or replace package XX_OM_HVOP_ALERT_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XXOMHVOPALERTPKG.PKS                                      |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   06-AUG-2009   Bala          Initial draft version       |
-- |V1.0       21-MAR-2011   Bala	   Added a procedue for TDS    |  
-- |					   Alet                        |
-- +===================================================================+

Procedure hvop_error_count( errbuf             OUT VARCHAR2
                          , retcode            OUT NUMBER
                          , p_email_list        IN VARCHAR2
                          , p_trigger_file_name IN VARCHAR2
                          , p_process_date      IN VARCHAR2
                          );                          
                          
Procedure sr_exception_count( errbuf             OUT VARCHAR2
                            , retcode            OUT NUMBER
                            , p_email_list        IN VARCHAR2                         
                           );                                    
                          
                             
END;
/


