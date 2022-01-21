SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification xx_ce_clear_float_recon_lines
PROMPT Program exits if the creation is not successful

CREATE OR REPLACE 
PACKAGE xx_ce_clear_float_recon_lines 
as 
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- +=================================================================================+
-- | Name       : xx_ce_clear_float_recon_lines.pks                                  |
-- | Description: Cash Management Clearing float reconciliation status               |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |                                                                                 |
-- |1.0      14-APR-2018   M.Rakesh Reddy     Created the package for Defect#44057   |
---+=================================================================================+

procedure clear_records(X_ERRBUF              OUT VARCHAR2,
                        X_RETCODE             OUT NUMBER);
						
END xx_ce_clear_float_recon_lines;
/
show errors;