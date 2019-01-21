CREATE OR REPLACE 
PACKAGE xx_ce_ordtsas_disc_pkg AS

-- +=====================================================================================================+
-- |                                Office Depot - Project Simplify                                      |
-- |                                     Oracle AMS Support                                              |
-- +=====================================================================================================+
-- |  Name:  XX_CE_ORDTSAS_DISC_PKG (RICE ID : R1392)                                                    |
-- |                                                                                                     |
-- |  Description: This package will be used by following concurrent programs (reports):                 |
-- |                1. OD: CE Order Receipt Detail Discrepancy Report - Excel (XXCEORDTSASDISC_EXCEL)    |
-- |                2. OD: CE Order Receipt Detail Discrepancy Report - Child (XXCEORDTSASDISC_CHILD)    |
-- |                3. OD: CE Order Receipt Detail Discrepancy Summary Report (XXCEORDTSASDISC_SUMMARY)  |
-- |                4. OD: CE Order Receipt Detail Discrepancy Detail Report  (XXCEORDTSASDISC)          |
-- |                                                                                                     |
-- |    FUNCTION before_report_det    Before report trigger for XML Publisher detail report              |
-- |    FUNCTION after_report_det     After report trigger for XML Publisher details report              |
-- |    FUNCTION before_report_sum    Before report trigger for XML Publisher summary report             |
-- |    FUNCTION after_report_sum     After report trigger for XML Publisher summary report              |
-- |    PROCEDURE submit_child_prog   Procedure to submit child request to prepare master data for report|
-- |    PROCEDURE submit_wrapper_prog Procedure to submit wrapper program which will main submit report  |
-- |                                                                                                     |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  ===================  ======================================================|
-- | 1.0         14-Nov-2013  Abdul Khan           Initial version - QC Defect # 25401                   |
-- +=====================================================================================================+

    
    -- Variables for report parameters
    p_report_mode           VARCHAR2(30);
    p_receipt_date_from     VARCHAR2(30);
    p_receipt_date_to       VARCHAR2(30);
    p_tender_type           VARCHAR2(50);
    p_store_number_from     VARCHAR2(10); 
    p_store_number_to       VARCHAR2(10);
    
    -- Variables for Summary report generation
    p_pos_sql_summary       VARCHAR2(32000);
    p_aops_sql_summary      VARCHAR2(32000);
    p_spay_sql_summary      VARCHAR2(32000);
    
    -- Variables for Detail report generation
    p_pos_sql_detail        VARCHAR2(32000);
    p_aops_sql_detail       VARCHAR2(32000);
    p_spay_sql_detail       VARCHAR2(32000);
    
    -- Variables for Total Discrepancy
    p_pos_total_disc        VARCHAR2(32000);
    p_aops_total_disc       VARCHAR2(32000);
    p_spay_total_disc       VARCHAR2(32000);
  
    -- Before Report trigger for Summary report
    FUNCTION before_report_sum
    RETURN BOOLEAN;
    
    -- After Report trigger for Summary report
    FUNCTION after_report_sum 
    RETURN BOOLEAN; 
      
    -- Before Report trigger for Detail report
    FUNCTION before_report_det
    RETURN BOOLEAN;
    
    -- After Report trigger for Detail report
    FUNCTION after_report_det 
    RETURN BOOLEAN;                                                                          

    -- Submit child request to prepare master data for report
    -- OD: CE Order Receipt Detail Discrepancy Report - Child (XXCEORDTSASDISC_CHILD)
    PROCEDURE submit_child_prog   ( x_err_buff      OUT NOCOPY VARCHAR2,
                                    x_ret_code      OUT NOCOPY VARCHAR2,
                                    p_receipt_date_from     IN VARCHAR2,
                                    p_receipt_date_to       IN VARCHAR2,
                                    p_tender_type           IN VARCHAR2,
                                    p_store_number_from     IN VARCHAR2, 
                                    p_store_number_to       IN VARCHAR2,
                                    p_min_header_id         IN NUMBER,
                                    p_max_header_id         IN NUMBER,
                                    p_thread_number         IN NUMBER,
                                    p_sas_ordt              IN VARCHAR2
                                  );

    -- Submit wrapper program for generating excel output
    -- OD: CE Order Receipt Detail Discrepancy Report - Excel (XXCEORDTSASDISC_EXCEL)
    PROCEDURE submit_wrapper_prog ( x_err_buff      OUT NOCOPY VARCHAR2,
                                    x_ret_code      OUT NOCOPY VARCHAR2,
                                    p_report_mode           IN VARCHAR2,
                                    p_receipt_date_from     IN VARCHAR2,
                                    p_receipt_date_to       IN VARCHAR2,
                                    p_tender_type           IN VARCHAR2,
                                    p_store_number_from     IN VARCHAR2, 
                                    p_store_number_to       IN VARCHAR2,
                                    p_thread_count          IN NUMBER
                                  );
                                    
END xx_ce_ordtsas_disc_pkg;

/

SHOW ERROR