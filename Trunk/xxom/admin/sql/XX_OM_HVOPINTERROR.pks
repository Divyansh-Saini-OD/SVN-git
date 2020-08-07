create or replace 
package XX_OM_HVOP_INT_ERROR_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XXOMHVOPINTERRORPKG.PKS                                   |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   06-JAN-2009   Bala          Initial draft version       |
-- |V1.0       20-Jan-2009   Bala	       Added the logic to avoid dup|
-- |					                    licate orders              |
-- |V1.1       18-OCT-2015   Sai Kiran    Changes made as part of      |   
-- |                                        Defect# 36145              | 
-- |V1.2        27-APR-2016   Surendra Oruganti Changes made to display|
-- |                                      every WAVE defect# 37784     |
-- |1.5       11-MAY-2016 Surendra Oruganti  Changes made to add date  |
-- |                              parameter to schedule job through ESP|
-- |1.6       07-NOV-2016     Poonam Gupta  Changes Made for           |
-- |										Enhancement Defect#39138   |
-- +===================================================================+

Type error_ord_rec_type IS RECORD(
  Order_number varchar2(50),
  Order_amount number,
  error_category varchar2(50)
  );

Type cmn_error_rec_type is RECORD(
Order_number varchar2(50));

TYPE error_ord_tbl_type IS TABLE OF error_ord_rec_type INDEX BY BINARY_INTEGER;
TYPE cmn_error_tbl_type IS TABLE OF cmn_error_rec_type INDEX BY BINARY_INTEGER;




Procedure hvop_int_error_count(
                               retcode OUT NUMBER
                               ,errbuf OUT VARCHAR2
							     ,p_date VARCHAR2     -- Added as per Ver 1.5
                              --  ,l_email_list VARCHAR2
                               ); --commented as part of36145

PROCEDURE HVOP_INT_ERROR_MAIL_MSG(P_OMCOUNT IN VARCHAR2,			 -- changed NUMBER to VARCHAR2 datatype in all parameters for Defect#39138
                                        p_omamount IN VARCHAR2 ,	
                                        P_MERCHCOUNT IN VARCHAR2,	
                                        p_merchamount IN VARCHAR2 ,	
                                        p_fincount IN VARCHAR2,		
                                        p_finamount IN VARCHAR2,	
                                        P_CDHCOUNT IN VARCHAR2,		
                                        p_cdhamount IN VARCHAR2,	
                                        p_gtsscount IN VARCHAR2,	
                                        P_GTSSAMOUNT IN VARCHAR2,	
                                        P_OTHERCOUNT IN VARCHAR2,	
                                        P_OTHERAMOUNT IN VARCHAR2,	
                                        P_OVERALLCOUNT IN VARCHAR2, 	 -- Added for Defect#39138
                                        p_overallamount IN VARCHAR2, 	 -- Added for Defect#39138
                                        p_sas_order_cnt IN VARCHAR2,     -- Added as per Ver 1.2
					p_sas_order_amt IN VARCHAR2,					
					p_sas_pay_amount IN VARCHAR2,					
					p_sas_pay_count  IN VARCHAR2,					
					p_ebs_order_err_cnt  IN VARCHAR2,				
					p_ebs_order_err_amt  IN VARCHAR2,				
					p_ebs_ord_err_pay_count  IN VARCHAR2,			
					p_ebs_ord_err_pay_amount  IN VARCHAR2,			
					p_ebs_order_cnt   IN VARCHAR2,					
					p_ebs_order_amt   IN VARCHAR2,					
					p_ebs_total_pay_amt  IN VARCHAR2,				
					p_ebs_total_pay_cnt  IN VARCHAR2,				
					p_ebs_pay_cnt  IN VARCHAR2,						
					p_ebs_pay_amt  IN VARCHAR2,						
					p_pay_miss_ordt_cre_amt  IN VARCHAR2, 			
					p_pay_miss_ordt_cre_cnt  IN VARCHAR2,			
				        p_pay_miss_ordt_dbt_amt  IN VARCHAR2, 		
			                p_pay_miss_ordt_dbt_cnt  IN VARCHAR2,	
			                p_pay_total_cnt  IN VARCHAR2,			
				        p_pay_total_amt  IN VARCHAR2,  				
							p_ebs_order_err_total_cnt_ch VARCHAR2,	--Added for Defect#39138
							p_ebs_order_err_total_amt_ch VARCHAR2,	--Added for Defect#39138
							p_ebs_err_pay_total_amt_ch VARCHAR2,	--Added for Defect#39138
							p_ebs_err_pay_total_cnt_ch VARCHAR2, 	--Added for Defect#39138
						
                                        p_email_list IN VARCHAR2,
                                        x_mail_sent_status out VARCHAR2);

END;
/
exit;