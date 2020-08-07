  SET VERIFY OFF
   WHENEVER SQLERROR CONTINUE
   WHENEVER OSERROR EXIT FAILURE ROLLBACK 
   
   PROMPT
   PROMPT Creating XX_PO_ASN_CONV_PKG package specification
   PROMPT     
  
CREATE OR REPLACE PACKAGE XX_PO_ASN_CONV_PKG AUTHID CURRENT_USER
  -- +=========================================================================================+
  -- |                  Office Depot - Project Simplify                                        |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                             |
  -- +=========================================================================================+
  -- | Name  :       XX_PO_ASN_CONV_PKG                                                        |
  -- | Description:  This package spec is used for ASN conversion                              |
  -- |                                                                                         |
  -- |                                                                                         |
  -- |Change Record:                                                                           |
  -- |===============                                                                          |
  -- |Version       Date              Author            Remarks                                |
  -- |=======    ==========        =============    ========================                   |
  -- |DRAFT 1A   25-May-2007       Gowri Nagarajan  Initial draft version                      |
  -- |DRAFT 1B   15-Jun-2007       Gowri Nagarajan  Incorporated Peer Review Comments          |
  -- |DRAFT 1C   17-Jul-2007       Gowri Nagarajan  Added p_debug_flag parameter in            |
  -- |                                              master_main and child_main                 |
  -- |1.0        19-Jul-2007       Gowri Nagarajan  Baselined                                  |
  -- +=========================================================================================+
  AS

  PROCEDURE master_main
                      ( x_errbuf              OUT VARCHAR2
                      , x_retcode             OUT VARCHAR2
                      , p_validate_only_flag  IN  VARCHAR2
                      , p_reset_status_flag   IN  VARCHAR2
                      , p_batch_size          IN  NUMBER
                      , p_max_threads         IN  NUMBER
                      , p_debug_flag          IN  VARCHAR2
                      );

  PROCEDURE child_main
                    (
                       x_errbuf               OUT  VARCHAR2
                     , x_retcode              OUT  VARCHAR2
                     , p_validate_only_flag   IN   VARCHAR2
                     , p_reset_status_flag    IN   VARCHAR2
                     , p_batch_id             IN   NUMBER
                     , p_debug_flag           IN   VARCHAR2
                     );


 END XX_PO_ASN_CONV_PKG;
/
 
 SHOW ERRORS
 
--EXIT


REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================