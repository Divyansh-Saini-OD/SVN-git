create or replace PACKAGE XX_FA_IRS4562_PKG AS
 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                	 |
 -- |                       WIPRO Technologies                           |
 -- +===================================================================+
 -- | Name :     OD FA IRS TAX FORM 4652                               	 |
 -- | Description :To calulate the depreciation and amortization       	 |
 -- |              details and provide the information in the format to	 |
 -- |              populate the IRS Tax Form                             |
 -- |                                                                    |
 -- |Change Record:                                                      |
 -- |===============                                                     |
 -- |Version   Date          Author              Remarks                 |
 -- |=======   ==========   =============        ======================= |	
 -- |1.0       16-SEP-200  Priyanka Nagesh       Initial version       	 |
 -- +===================================================================+
 -- +===================================================================+
 -- | Name : XX_FA_IRS4562_PROC                                        	 |
 -- | Description : This Program will produce the details                |
 -- |               for current year assets and summary information      |
 -- |               for prior year assets                                |
 -- |                                                                    |
 -- | Program "OD: FA IRS Tax Form 4562"                                 |
 -- |                                                                    |
 -- | Parameters : p_book,p_fiscal_year,p_company,p_category_id          |
 -- |                                                                  	 |
 -- |                                                                  	 |
 -- +===================================================================+
    PROCEDURE XX_FA_IRS4562_PROC(p_book                    IN VARCHAR2
                                ,p_fiscal_year             IN VARCHAR2
                                ,p_company                 IN VARCHAR2
                                ,p_category_id             IN NUMBER
                                 );
    END XX_FA_IRS4562_PKG;
/
SHO ERR;