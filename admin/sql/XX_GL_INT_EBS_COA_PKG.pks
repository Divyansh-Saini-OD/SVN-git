-- +===================================================================================+
-- |              Office Depot - Project Simplify                                      |
-- +===================================================================================+
-- | Name :    XX_GL_INT_EBS_COA_PKG                                                   |
-- |                                                                                   |
-- | RICE Id            : C0069 - OD GL Integral TO ORACLE ACCOUNT CONVERION API       |
-- |                                                                                   |
-- | Description : To convert the Integral accounts into Oracle account segments       |
-- |               using PSGL Account Conversion Common API                            |
-- |               DERIVE_STORED_VALUES,DERIVE_ALL_VALUES,DERIVE_COMPANY,              |
-- |               DERIVE_COSTCTR,DERIVE_LOCATION,DERIVE_ACCOUNT,DERIVE_INTERCO        |
-- |               DERIVE_LOCATION_TYPE,DERIVE_COSTCTR_TYPES,DERIVE_LOB,               |
-- |               SAVE_DERIVED_VALUES,DELETE_DERIVED_VALUES,DERIVE_CCID,              |
-- |               TRANSLATE_PS_VALUES                                                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version       Date              Author              Remarks                        |
-- |=======       ==========    =============        =======================           |
-- |1.0           11-JUN-2013   Paddy Sanjeevi       Initial Version (Defect 18792)    |
-- |1.1           22-JUN-2013   Paddy Sanjeevi       Modified for defect 19168         |
-- |1.2           30-JAN-2017   Madhu Bolli          GSCC incompatible. Removed XXFIN schema|
-- +===================================================================================+

CREATE OR REPLACE PACKAGE XX_GL_INT_EBS_COA_PKG
AS

    gn_grp_id    	            XX_GL_INTERFACE_NA_STG.group_id%TYPE;
    gc_source_nm		    	XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
    gn_req_id		    	    NUMBER;
    gc_record_no		    VARCHAR2(50);
    
    gc_error_message   		    VARCHAR2(5000);    
    gc_sr_business_unit		    xx_fin_translatevalues.target_value1%TYPE;
    gc_sr_department	            xx_fin_translatevalues.target_value1%TYPE; 
    gc_sr_account		    xx_fin_translatevalues.target_value1%TYPE;
    gc_sr_operating_unit	    xx_fin_translatevalues.target_value1%TYPE;	
    gc_sr_lob			    xx_fin_translatevalues.target_value1%TYPE;	

    gc_company                      xx_fin_translatevalues.target_value1%TYPE;
    gc_cost_center                  xx_fin_translatevalues.target_value2%TYPE;
    gc_cost_center_type             xx_fin_translatevalues.target_value2%TYPE;
    gc_cost_center_sub_type         xx_fin_translatevalues.target_value2%TYPE;
    gc_account                      xx_fin_translatevalues.target_value3%TYPE;
    gc_location                     xx_fin_translatevalues.target_value4%TYPE;
    gc_location_type                xx_fin_translatevalues.target_value4%TYPE;
    gc_intercompany                 xx_fin_translatevalues.target_value5%TYPE:='0000';
    gc_lob                          xx_fin_translatevalues.target_value6%TYPE;
    gc_sob			    VARCHAR2(50);
    gc_translation_status	    VARCHAR2(50);
    gc_ccid                         gl_code_combinations.code_combination_id%TYPE;
    gc_ccid_enabled		    VARCHAR2(1);
    gc_future                       gl_code_combinations.segment7%TYPE := '000000';
    gc_debug_message                VARCHAR2(1) := 'N';
    gc_error_msg		    VARCHAR2(2000);
    gc_target_value9          	    xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value10          	    xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value11               xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value12               xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value13               xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value14               xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value15               xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value16               xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value17               xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value18               xx_fin_translatevalues.target_value1%TYPE ;
    gc_target_value19               xx_fin_translatevalues.target_value1%TYPE ;
    g_row_id      	            rowid;


-- +===================================================================+
-- | Name             : XX_GL_INT_EBS_COA_REPORT                       |
-- | Description      : This Procedure reads GL_INT_EBS_COA_CALC       |
-- |                    from translation table and creates a pipe      |
-- |                    delimited file                                 |
-- |                                                                   |
-- | Parameters :  p_source_nm                                         |
-- |                                                                   |
-- |                                                                   |
-- | Returns    :  errbuf,retcode                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

  PROCEDURE XX_GL_INT_EBS_COA_REPORT ( ERRBUFF     OUT VARCHAR2
                             	      ,retcode     OUT varchar2
                             	      ,p_source_nm  in VARCHAR2);


-- +===================================================================+
-- | Name  :PROCESS_ERROR                                              |
-- | Description      : This Procedure is used to process any found    |
-- |                    derive  values, balanced errors                |
-- |                                                                   |
-- | Parameters :  p_rowid, p_fnd_message, p_type, p_value, p_details  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


    PROCEDURE PROCESS_ERROR (p_rowid         IN  ROWID
                            ,p_fnd_message   IN  VARCHAR2
                            ,p_source_nm     IN  VARCHAR2
                            ,p_type          IN  VARCHAR2
                            ,p_value         IN  VARCHAR2
                            ,p_details       IN  VARCHAR2
                            ,p_group_id      IN  NUMBER
                            ,p_sob_id        IN  NUMBER DEFAULT NULL
                           );




-- +===================================================================+
-- | Name  :GLSI_ITGORA_DERIVE_VALUES                                  |
-- | Description      : This Procedure is used the interface    to     |
-- |                    call the fuctions and procedures to derive     |
-- |                    needed values                                  |
-- | Parameters : p_group_id                                           |
-- |             ,p_source_nm                                          |
-- |             ,p_request_id                                         |
-- |             ,p_debug_flag                                         |
-- |                                                                   |
-- |                                                                   |
-- | Returns :    p_error_count                                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE GLSI_ITGORA_DERIVE_VALUES ( p_group_id    IN VARCHAR2
			 	         ,p_source_nm   IN VARCHAR2
				         ,p_request_id  IN NUMBER
			                 ,p_debug_flag  IN VARCHAR2	
				         ,p_error_count OUT NUMBER
				      );

-- +===================================================================================+
-- | Name        : TRANSLATE_PS_VALUES                                                 |
-- |                                                                                   |
-- | Description : To convert the Integral accounts into Oracle account segments       |
-- |                                                                                   |
-- | Parameters  : p_record_no                                                         |
-- |               ,p_ps_business_unit                                                 |
-- |               ,p_ps_department                                                    |
-- |               ,p_ps_account                                                       |
-- |               ,p_ps_operating_unit                                                |
-- |               ,p_ps_affiliate                                                     |
-- |               ,p_ps_sales_channel                                                 |
-- |               ,p_use_stored_combinations                                          |
-- |               ,p_convert_gl_history                                               |
-- |               ,p_reference24                                                      |
-- |               ,p_org_id                                                           |
-- |               ,p_trans_date  added per P.Marco(Defect 2598)                       |
-- |                                                                                   |
-- | Returns     :  x_seg1_company                                                     |
-- |               ,x_seg2_costctr                                                     |
-- |               ,x_seg3_account                                                     |
-- |               ,x_seg4_location                                                    |
-- |               ,x_seg5_interco                                                     |
-- |               ,x_seg6_lob                                                         |
-- |               ,x_seg7_future                                                      |
-- |               ,x_ccid                                                             |
-- |               ,x_error_message                                                    |
-- +===================================================================================+


   PROCEDURE TRANSLATE_PS_VALUES(
			         p_record_no 		   IN   VARCHAR2
                                ,p_ps_business_unit        IN   VARCHAR2
                                ,p_ps_department           IN   VARCHAR2
                                ,p_ps_account              IN   VARCHAR2
                                ,p_ps_operating_unit       IN   VARCHAR2
                                ,p_ps_affiliate            IN   VARCHAR2
                                ,p_ps_sales_channel        IN   VARCHAR2
                                ,p_use_stored_combinations IN   VARCHAR2 DEFAULT 'NO'
                                ,p_convert_gl_history      IN   VARCHAR2 
	  	      	        ,p_reference24		   IN   VARCHAR2
                                ,x_seg1_company            OUT  NOCOPY   VARCHAR2
                                ,x_seg2_costctr            OUT  NOCOPY   VARCHAR2
                                ,x_seg3_account            OUT  NOCOPY   VARCHAR2
                                ,x_seg4_location           OUT  NOCOPY   VARCHAR2
                                ,x_seg5_interco            OUT  NOCOPY   VARCHAR2
                                ,x_seg6_lob                OUT  NOCOPY   VARCHAR2
                                ,x_seg7_future             OUT  NOCOPY   VARCHAR2
                                ,x_ccid                    OUT  NOCOPY   VARCHAR2
                                ,x_error_message           OUT  NOCOPY   VARCHAR2
                                ,p_org_id                  IN   NUMBER   DEFAULT  NULL
                                ,p_trans_date              IN   DATE     DEFAULT SYSDATE 
                                );
END;
/
