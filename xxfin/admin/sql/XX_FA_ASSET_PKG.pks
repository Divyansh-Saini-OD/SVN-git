create or replace PACKAGE XX_FA_ASSET_PKG
AS
   -- +===================================================================================+
   -- |              Office Depot - Project Merge                                         |
   -- |                                                                                   |
   -- +===================================================================================+
   -- | Name :       FA Mass Additions Conversion  Program                                |
   -- | Description :To convert the active assets for both the SAP data and the PWC data  |
   -- |              from custom staging tables to Oracle Productin tables                |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version       Date              Author              Remarks                        |
   -- |=======       ==========    =============        =======================           |
   -- |  1.0         06-JUN-2007   Sayeed Ahamed        Applied Build Standards           |
   -- |  2.0         06-JUN-2014   Mark Schmit          Modified for Merge Project        |
   -- |  3.0         16-Feb-2015   Paddy Sanjeevi	Modified procedure definitions    |
   -- +===================================================================================+
   gb_corp_book_name        VARCHAR2 (15) := 'OD US CORP';
   gb_fed_book_name         VARCHAR2 (15) := 'OD US FED';
   gb_state_book_name       VARCHAR2 (15) := 'OD US STATE';
   gb_fed_ace_book_name     VARCHAR2 (15) := 'OD US FED ACE';
   gb_fed_amt_book_name     VARCHAR2 (15) := 'OD US FED AMT';
   gb_state_amt_book_name   VARCHAR2 (15) := 'OD US STATE AMT';
   ln_book_loop             VARCHAR2(3);
   -- +===================================================================================+
   -- | Name        :MASTER                                                               |
   -- | Description :It creates the batches of FA Mass additions transactions             |
   -- |              from the custom staging table XX_FA_MASS_ADDITIONS_STG               |
   -- |              and calls the needed CHILD procedure for each batch.                 |
   -- | Parameters:  x_err_buf, x_ret_code, p_process_name,                               |
   -- |              p_validate_flag, p_reset_status_flag                                 |
   -- |                                                                                   |
   -- | Returns   :  Error Buffer, Return Code                                            |
   -- +===================================================================================+
   PROCEDURE MASTER (x_errbuf      	OUT NOCOPY VARCHAR2,
                     x_retcode     	OUT NOCOPY VARCHAR2,
		     p_validate_flag    IN VARCHAR2,
                     p_corp_book        IN VARCHAR2,
                     p_fed_book         IN VARCHAR2,
                     p_state_book       IN VARCHAR2,
                     p_fed_ace_book     IN VARCHAR2,
                     p_fed_amt_book     IN VARCHAR2,
                     p_state_amt_book   IN VARCHAR2);
   -- +===================================================================================+
   -- | Name        :CHILD                                                                |
   -- | Description :To populate defaults and validate data for each batch                |
   -- | Parameters : p_process_name, p_validate_flag, p_reset_status_flag, p_batch_id     |
   -- |                                                                                   |
   -- | Returns    : None                                                                 |
   -- +===================================================================================+
   PROCEDURE CHILD (p_validate_flag IN VARCHAR2);
   -- +===================================================================================+
   -- | Name        :VALIDATE_DATA                                                        |
   -- | Description :It validates all the incoming data                                   |
   -- | Parameters:  p_process_name, p_validate_flag, p_reset_status_flag, p_batch_id     |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE VALIDATE_DATA (p_validate_flag IN VARCHAR2);
   -- +===================================================================================+
   -- | Name        :TRANSLATE_DATA                                                       |
   -- | Description :To perform needed translations on the incoming data                  |
   -- | Parameters:  p_process_name, p_validate_flag, p_reset_status_flag, p_batch_id     |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE TRANSLATE_DATA (p_validate_flag IN VARCHAR2);
   -- +===================================================================================+
   -- | Name        :LOAD_MA                                                              |
   -- | Description :When requested by the business it loads data to the seeded Oracle    |
   -- |              FA Mass Additions Staging Table                                      |
   -- | Parameters:  p_process_name, p_batch_id                                           |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE LOAD_MA( x_errbuf      	OUT NOCOPY VARCHAR2
                     ,x_retcode     	OUT NOCOPY VARCHAR2
  		    );
   -- +===================================================================================+
   -- | Name        :LOAD_TAX                                                             |
   -- | Description :When requested by the business it loads data to the seeded Oracle    |
   -- |              FA Tax Interface Staging Table                                       |
   -- | Parameters:  p_process_name, p_batch_id, p_book_type_code, p_depr_flag_only       |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE LOAD_TAX ( x_errbuf      	OUT NOCOPY VARCHAR2
                       ,x_retcode     	OUT NOCOPY VARCHAR2
		       ,p_book_type_code   IN VARCHAR2);
   -- +===================================================================================+
   -- | Name        :FA_CLOSEOUT                                                          |
   -- | Description :Verify that the conversion record is in the Production tables        |
   -- | Parameters : p_batch_id                                                           |
   -- |                                                                                   |
   -- | Returns    : None                                                                 |
   -- +===================================================================================+
   PROCEDURE FA_CLOSEOUT ( x_errbuf      	OUT NOCOPY VARCHAR2
                          ,x_retcode     	OUT NOCOPY VARCHAR2
  		         );
   -- +===================================================================================+
   -- | Name        :GET_DEFAULTS                                                         |
   -- | Description :Populate default values in XX_FA_MASS_ADDITIONS_STG and              |
   -- |              XX_FA_TAX_INTERFACE_STG                                              |
   -- | Parameters:  p_batch_id, p_validate_flag                                          |
   -- |                                                                                   |
   -- | Returns   :  None                                                                 |
   -- +===================================================================================+
   PROCEDURE GET_DEFAULTS (p_validate_flag IN VARCHAR2);
END XX_FA_ASSET_PKG;
/
