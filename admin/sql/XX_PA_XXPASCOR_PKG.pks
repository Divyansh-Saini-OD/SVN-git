CREATE OR REPLACE PACKAGE APPS.XX_PA_XXPASCOR_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_XXAPASCOR_PKG                                |
-- | Description :  OD Private Brand Reports                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-Aug-2009 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

  p_cancelled VARCHAR2(1);
 p_year      Number;
 p_status_where varchar2(200);

 function BeforeReportTrigger return boolean;

 FUNCTION get_total_proj(p_cancelled IN VARCHAR2,p_year IN NUMBER) return NUMBER;

 FUNCTION get_total_sku(P_cancelled IN VARCHAR2,p_year IN NUMBER) return NUMBER;

 FUNCTION get_fcst_sku(p_cancelled IN VARCHAR2, p_division IN VARCHAR2,p_year IN NUMBER) return NUMBER;

 FUNCTION get_fcst_skuc(p_cancelled IN VARCHAR2, p_division IN VARCHAR2,p_year IN NUMBER) return NUMBER;

 FUNCTION get_total_fcst(P_cancelled IN VARCHAR2,p_year IN NUMBER) return NUMBER;

 FUNCTION get_fcst_sku_di(p_cancelled IN VARCHAR2,p_division IN VARCHAR2,
  p_di_asoc_merc IN VARCHAR2,p_year IN NUMBER) return  NUMBER;

 FUNCTION get_fcst_sku_dic(p_cancelled IN VARCHAR2,p_division IN VARCHAR2,
  p_di_asoc_merc IN VARCHAR2,p_year IN NUMBER) return  NUMBER;


FUNCTION get_fcst_sku_trk(p_cancelled IN VARCHAR2,p_tracker IN VARCHAR2,p_year IN NUMBER) return NUMBER ;

FUNCTION get_fcst_sku_trkc(p_cancelled IN VARCHAR2,p_tracker IN VARCHAR2,p_year IN NUMBER) return NUMBER ;

FUNCTION get_division(p_division IN VARCHAR2,p_project_id IN NUMBER,p_year IN NUMBER) return NUMBER ;

FUNCTION get_dmm(p_dept IN VARCHAR2) RETURN VARCHAR2;

FUNCTION get_lu_namedate(p_prod_dtl_id IN NUMBER) RETURN VARCHAR2;

END;
/

