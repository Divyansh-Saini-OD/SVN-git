
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_SFA_WWW_CONV_PKG.pks                             |
-- | Description      :I2043 Leads_from_WWW_and_Jmillennia                 |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      15-Feb-2008 David Woods        Initial version                |
-- +=======================================================================+

Create or replace package XX_SFA_WWW_CONV_PKG
As 
PROCEDURE get_batch_id
  (  p_process_name      in VARCHAR2
    ,p_group_id          in VARCHAR2
    ,x_batch_descr       out VARCHAR2
    ,x_batch_id          out VARCHAR2
    ,x_error_msg         out VARCHAR2
  );
END XX_SFA_WWW_CONV_PKG;
/
