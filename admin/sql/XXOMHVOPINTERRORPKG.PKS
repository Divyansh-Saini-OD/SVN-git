create or replace
package XX_OM_HVOP_INT_ERROR_PKG
AS 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XXOMHVOPINTERRORPKG.PKS                                         |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   06-JAN-2009   Bala          Initial draft version     |
-- |                                                                   |
-- +===================================================================+


Type error_ord_rec_type IS RECORD(
  Order_number varchar2(50),
  Order_amount number,
  error_category varchar2(50)
  );
  
TYPE error_ord_tbl_type IS TABLE OF error_ord_rec_type INDEX BY BINARY_INTEGER;  


Procedure xx_om_hvop_int_error_count(status OUT varchar2);

Procedure xx_om_hvop_int_error_mail_msg(p_omcount IN Number,
                                        p_omamount IN NUMBER,
                                        p_merchcount IN Number,
                                        p_merchamount IN Number,
                                        p_fincount IN Number,
                                        p_finamount IN Number,
                                        p_cdhcount IN NUMBER,
                                        p_cdhamount IN NUMBER,
                                        p_gtsscount IN Number,
                                        p_gtssamount IN Number,
                                        p_Othercount IN Number,
                                        p_OtherAmount In Number,
                                        x_mail_sent_status out VARCHAR2);

END;
