create or replace
PACKAGE XXSC_REP_PKG as
-- +=============================================================================================+
-- |                       Office Depot - Social Compliance                                                    |
-- |                                                                                             |
-- +=============================================================================================+
-- | Name         : XXSC_REP_PKG.pks                                                        |
-- | Description  : This package is used to get the date required for needs improvement report    |
-- |                and create the requisition and PO for the vendor                             |
-- |                                                                                             |
-- |Type        Name                       Description                                           | 
-- |=========   ===========                ===================================================   | 
-- |FUNCTION   GET_SCHEDULE_DATE             This package is used to get the date required for needs  |
-- |                                         Improvement Report and create the requisition and PO for the vendor |
-- |                                                                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  11-Jul-2011  Deepti S             Initial draft version                            |
-- +=============================================================================================+
FUNCTION GET_SCHEDULE_DATE
(p_vendor_name   IN      q_od_pb_sc_vendor_master_v.OD_SC_VENDOR_NAME%TYPE
      , p_vendor_num    IN       q_od_pb_sc_vendor_master_v.od_sc_vendor_number%TYPE
      , p_factory_name       iN      q_od_pb_sc_vendor_master_v.od_sc_factory_name%TYPE
      , p_factory_num     IN      q_od_pb_sc_vendor_master_v.od_sc_factory_number%TYPE) RETURN date ;
      
      
      end XXSC_REP_PKG;
/
