create or replace 
PACKAGE XX_AP_UNMATCH_WRAPPER_PKG
AS
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |              Office Depot Organization                                                           |
  -- +==================================================================================================+
  -- | Name  : XX_AP_UNMATCH_WRAPPER_PKG.pks                                                                |
  -- | Description:  Package to submit OD: Unmatched Receipts Summary Report and XML report Publisher   |
  -- | Change Record:                                                                                   |
  -- |===============                                                                                   |
  -- |Version   Date           Author           Remarks                                                 |
  -- |=======   ==========    =============    ========================================                 |
  -- |DRAFT 1A  11-MAR-2019   Shanti Sethuraj           Initial draft version                                    |
  -- +===================================================================================================+
  gc_errbuff VARCHAR2(500);
  gc_retcode VARCHAR2(1);
 PROCEDURE XX_AP_UNMATCH_WRAP_PROC(
x_errbuf              out varchar2,
X_RETCODE             OUT NUMBER,
    p_date                       DATE,
    p_Currency_Code              VARCHAR2,
    p_GL_Accounting_Segment_From VARCHAR2,
    p_GL_Accounting_Segment_To   VARCHAR2,
    p_Supplier_Site_Code_From    VARCHAR2,
    p_supplier_site_code_to varchar2,
    p_po_type               varchar2);
    end;