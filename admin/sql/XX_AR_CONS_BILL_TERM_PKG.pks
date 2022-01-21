CREATE OR REPLACE PACKAGE APPS.XX_AR_CONS_BILL_TERM_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        Providge Consulting                        |
-- +===================================================================+
-- |        Name : AR Increment Consolidated Billing Terms             |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       13-FEB-2007  Terry Banks,         Initial version        |
-- |                       Providge Consulting                         |
-- |1.1       15-FEB-2007  Terry Banks          Changed to read all    |
-- |                       Providge Consulting  RA_TERMS_B rows and    |
-- |                                            make change if the     |
-- |                                            DFF contains the day   |
-- |                                            of the effective-date. |
-- |1.2       05-JUL-2007  Terry Banks          Changed to take care   |
-- |                       Providge Consulting  of new requirements.   |
-- |                                            Essentially a total    |
-- |                                            rewrite.               |
-- |                                                                   |
-- |1.3       13-FEB-2008  Bushrod Thomas       Added default for      |
-- |                                            p_effective_date so    |
-- |                                            body can remove NVLs   |
-- |                                                                   |
-- |1.4       15-SEP-2008  Greg Dill            Fixed Defect 11185     |
-- |                                                                   |
-- +===================================================================+
-- |        Name : INCREMENT_CB_TERM                                   |
-- | Description : Updates RA_TERMS and RA_TERMS_LINES rows for        |
-- |               consolidated billing term types.  It sets           |
-- |               due_cutoff_day and due_day_of_month to the day      |
-- |               of the month of the effective date.  This           |
-- |               process must be run before consolidated billing     |
-- |               invoices are generated each day.                    |
-- |  Parameters : x_error_buff, x_ret_code,                           |
-- |               p_effective_date                                    |
-- +===================================================================+
-- +===================================================================+
    PROCEDURE INCREMENT_CB_TERM(
        x_error_buff         OUT VARCHAR2
       ,x_ret_code           OUT NUMBER
--       ,p_effective_date     IN DATE := SYSDATE); next line added for 11185
       ,lc_effective_date     IN VARCHAR2);
END;
/
