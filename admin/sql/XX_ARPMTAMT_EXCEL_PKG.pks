create or replace
PACKAGE XX_ARPMTAMT_EXCEL_PKG
AS
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                                                                            |
-- +============================================================================+
-- | Name         : XXARPMTAMT_EXCEL_PKG                                        |
-- | RICE ID      : QC 18618                                                    |
-- | Description  : This package is the executable of the wrapper program       |
-- |                that used for submitting the                                |
-- |                OD: AR POS Contactless Payment Amounts report with the      |
-- |                default format of EXCEL                                     |
-- |                                                                            |
-- | Change Record:                                                             |
-- |===============                                                             |
-- |Version   Date              Author              Remarks                     |
-- |======   ==========     =============        =======================        |
-- |  1.0    2012-08-17     Joe Klein             Defect 18618 Initial version. |
-- |  2.0    2013-09-04     Vamshi Katta          Added new parameter           |
-- +============================================================================+

-- +============================================================================+
-- | Name        : XX_ARPMTAMT_WRAP_PROC                                        |
-- | Description : The procedure will submit the                                |
-- |               OD: AR POS Contactless Payment Amounts program in EXCEL      |
-- |               format.                                                      |
-- | Parameters  : p_from_date,p_to_date,p_store_number                         |
-- | Returns     : x_err_buff,x_ret_code                                        |
-- +============================================================================+

PROCEDURE XX_ARPMTAMT_WRAP_PROC( x_err_buff  OUT VARCHAR2
                                ,x_ret_code  OUT NUMBER
                                ,p_from_date  IN VARCHAR2
                                ,p_to_date    IN VARCHAR2
                                ,p_store_number IN VARCHAR2 -- Added new parameter by Vamshi Katta on 04-Sep-2013
                                );

END XX_ARPMTAMT_EXCEL_PKG;

/