CREATE OR REPLACE PACKAGE APPS.XX_AR_REFUNDS_ESCHEATS_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                            Providge                               |
-- +===================================================================+
-- | Name             :    XX_AR_refunds_escheats_pkg                  |
-- | Description      :    Package for Refund Escheats File            |   
-- |                                                                   |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author              Remarks                 |
-- |=======   ===========  ================    ========================|
-- |1.0       26-JUL-2007  Deepak               Initial version        |
-- |1.1       12-JUN-2008  Sandeep Pandhare     Added Parameters       |
-- |1.2       16-JUL-2008  Sandeep Pandhare     Defect 7703            |
-- |1.3       21-JUL-2008  Brian J Looman       Defects 9143,9144,9146 |
-- +===================================================================+


-- +===================================================================+
-- |  Name: XX_AR_REFUNDS_ESCHEATS_PROC                                |
-- |  Description:  Procedure to create the escheats file.             |
-- +===================================================================+
PROCEDURE xx_ar_refunds_escheats_proc
(  x_errbuf      OUT      VARCHAR2
 , x_retcode     OUT      VARCHAR2
 , p_org_id      IN       VARCHAR2
 , p_file_path   IN       VARCHAR2
 , p_ident_type  IN       VARCHAR2   DEFAULT 'N'   -- defect 7703
 , p_days_old    IN       NUMBER     DEFAULT 120   -- defect 9144
 , p_email_addr  IN       VARCHAR2   DEFAULT NULL  -- defect 9146
);

   
END;
/
