CREATE OR REPLACE
PACKAGE XX_GL_INTERFACE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_INTERFACE_PKG                                       |
-- | Description      :  This PKG will be used to insert and update the|
-- |                       date in the GL interface tables             |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A DD-MON-YYYY  P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name             : GET_JE_LINE_CNT                                |
-- | Description      : This function is used to obtain the number of  | 
-- |                    journal lines in gl_import_references table    |
-- |                    for a given je_batch_id                        |
-- | Parameters       : p_je_batch_id: journal batch id for which      |
-- |                    count needs to be obtained                     |
-- |                                                                   |
-- | Returns :        : count                                          |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    FUNCTION GET_JE_LINE_CNT(p_je_batch_id IN NUMBER)
		RETURN NUMBER;





-- +===================================================================+
-- | Name  :EMAIL_OUTPUT                                               |
-- | Description      :  This local procedure will submit concurrent   |
-- |                     program XX_GL_INTERFACE_EMAIL to email        |
-- |                     output file                                   |
-- |                     p_email_lookup is value on tranlation lookup  |
-- |                     Table                                         |
-- |                                                                   |
-- | Parameters : p_request_id, p_email_lookup, p_email_subject        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :   x_return_message, x_return_code                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE EMAIL_OUTPUT (x_return_message   OUT VARCHAR2
			  ,x_return_code      OUT VARCHAR2
                          ,p_request_id       IN  NUMBER
                          ,p_email_lookup     IN VARCHAR2 DEFAULT NULL
                          ,p_email_subject    IN VARCHAR2
                           );


-- +===================================================================+
-- | Name  :PROCESS_ERROR                                              |
-- | Description      : This Procedure is used to process any found    |
-- |                    derive  values, balanced errors                |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE PROCESS_ERROR (p_rowid         IN  ROWID    DEFAULT NULL
                            ,p_fnd_message   IN  VARCHAR2
                            ,p_source_nm     IN  VARCHAR2
                            ,p_type          IN  VARCHAR2 DEFAULT NULL
      	                    ,p_value         IN  VARCHAR2 DEFAULT NULL
                            ,p_details       IN  VARCHAR2
                            ,p_group_id      IN  NUMBER
                            ,p_sob_id        IN  NUMBER   DEFAULT NULL
                           );

-- +===================================================================+
-- | Name  : UPDATE_SET_OF_BOOKS_ID                                    |
-- | Description      : Call this procedure to update all set of book  |
-- |                    id based on group_id                           |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_source_name, p_group_id                             |
-- |                                                                   |
-- |                                                                   |
-- | Returns : x_return_code, x_return_message	                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

  PROCEDURE UPDATE_SET_OF_BOOKS_ID (p_group_id          IN  VARCHAR2
                                   ,x_return_err_cnt    OUT NUMBER
			           ,x_return_message    OUT VARCHAR2
                                   );


-- +===================================================================+
-- | Name  : CREATE_STG_JRNL_LINE                                      |
-- | Description      : This Procedure can be used to insert rows the  |
-- |                    XX_GL_INTERFACE_NA_STG table  YOU WILL NEED    |
-- |                    TO COMMIT after calling the procedure!!!!      |
-- | Parameters :                                                      |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


	PROCEDURE CREATE_STG_JRNL_LINE
                         (p_status            IN  VARCHAR2
			, p_date_created      IN  DATE
			, p_created_by        IN  NUMBER
			, p_actual_flag       IN  VARCHAR2
			, p_group_id          IN  NUMBER
			, p_batch_name        IN  VARCHAR2              --reference1
			, p_batch_desc        IN  VARCHAR2 DEFAULT NULL --reference2
			, p_je_name           IN  VARCHAR2 DEFAULT NULL --reference4
			, p_je_Descrp         IN  VARCHAR2 DEFAULT NULL --reference5
			, p_je_reference      IN  VARCHAR2 DEFAULT NULL --reference6
			, p_je_ref_date       IN  DATE     DEFAULT NULL --reference_date
			, p_je_rev_flg        IN  VARCHAR2 DEFAULT NULL --reference7
			, p_je_rev_period     IN  VARCHAR2 DEFAULT NULL --reference8
			, p_je_rev_method     IN  VARCHAR2 DEFAULT NULL --reference9
			, p_user_source_name  IN  VARCHAR2
			, p_user_catgory_name IN  VARCHAR2
			, p_set_of_books_id   IN  NUMBER
			, p_accounting_date   IN  DATE
			, p_currency_code     IN  VARCHAR2
			, p_company           IN  VARCHAR2              --segment1
			, p_cost_center       IN  VARCHAR2              --segment2
			, p_account           IN  VARCHAR2              --segment3
			, p_location          IN  VARCHAR2              --segment4
			, p_intercompany      IN  VARCHAR2              --segment5
			, p_channel           IN  VARCHAR2              --segment6
			, p_future            IN  VARCHAR2              --segment7
                        , p_ccid              IN  NUMBER   DEFAULT NULL
			, p_entered_dr        IN  NUMBER   DEFAULT NULL
			, p_entered_cr        IN  NUMBER   DEFAULT NULL
			, p_je_line_dsc       IN  VARCHAR2 DEFAULT NULL
			, p_reference11       IN  VARCHAR2 DEFAULT NULL
			, p_reference12       IN  VARCHAR2 DEFAULT NULL
			, p_reference13       IN  VARCHAR2 DEFAULT NULL
			, p_reference14       IN  VARCHAR2 DEFAULT NULL
			, p_reference15       IN  VARCHAR2 DEFAULT NULL
			, p_reference16       IN  VARCHAR2 DEFAULT NULL
			, p_reference17       IN  VARCHAR2 DEFAULT NULL
			, p_reference18       IN  VARCHAR2 DEFAULT NULL
			, p_reference19       IN  VARCHAR2 DEFAULT NULL
			, p_reference20       IN  VARCHAR2 DEFAULT NULL
			, p_reference21       IN  VARCHAR2 DEFAULT NULL
			, p_reference22       IN  VARCHAR2 DEFAULT NULL
			, p_reference23       IN  VARCHAR2 DEFAULT NULL
			, p_reference24       IN  VARCHAR2 DEFAULT NULL
			, p_reference25       IN  VARCHAR2 DEFAULT NULL
			, p_reference26       IN  VARCHAR2 DEFAULT NULL
			, p_reference27       IN  VARCHAR2 DEFAULT NULL
			, p_reference28       IN  VARCHAR2 DEFAULT NULL
			, p_reference29       IN  VARCHAR2 DEFAULT NULL
			, p_reference30       IN  VARCHAR2 DEFAULT NULL
                        , p_legacy_segment1   IN  VARCHAR2 DEFAULT NULL
                        , p_legacy_segment2   IN  VARCHAR2 DEFAULT NULL
                        , p_legacy_segment3   IN  VARCHAR2 DEFAULT NULL
                        , p_legacy_segment4   IN  VARCHAR2 DEFAULT NULL
                        , p_legacy_segment5   IN  VARCHAR2 DEFAULT NULL
                        , p_legacy_segment6   IN  VARCHAR2 DEFAULT NULL
                        , p_legacy_segment7   IN  VARCHAR2 DEFAULT NULL
                        , p_derived_val       IN  VARCHAR2 DEFAULT NULL
                        , p_derived_sob       IN  VARCHAR2 DEFAULT NULL
                        , p_balanced          IN  VARCHAR2 DEFAULT NULL
			, x_output_msg        OUT VARCHAR2
			);


-- +===================================================================+
-- | Name  :PROCESS_JRNL_LINES                                         |
-- | Description :  The main processing procedure.  After records are  |
-- |               inserted in the staging table using the             |
-- |               CREATE_STG_JRNL_LINE, you can call the              |
-- |               PROCESS_JRNL_LINES copy and import the JE lines     |
-- |               into GL.                                            |
-- |                    table                                          |
-- | Parameters : user_je_source_name,group_id, set_of_books_id        |
-- |                                                                   |
-- |               p_chk_sob_flg can be used to by-pass derive sob id. |
-- |               p_chk_balb_flg can be used to by-pass derive balan  |
-- |                               checking.                           |
-- |                                                                   |
-- |               p_bypass_flag  can be used to allow all records to  |
-- |                              be loaded to the interface table.    |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :   output_msg                                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
     PROCEDURE PROCESS_JRNL_LINES ( p_grp_id      IN      NUMBER
                                   ,p_source_nm   IN      VARCHAR2
                                   ,p_import_ctrl IN      VARCHAR2 DEFAULT 'Y'
                                   ,p_file_name   IN      VARCHAR2 DEFAULT NULL
                                   ,p_err_cnt     IN OUT  NUMBER
                                   ,p_debug_flag  IN      VARCHAR2 DEFAULT 'N'
                                   ,p_chk_sob_flg IN      VARCHAR2 DEFAULT 'N'
                                   ,p_chk_bal_flg IN      VARCHAR2 DEFAULT 'N'
                                   ,p_bypass_flg  IN      VARCHAR2 DEFAULT 'N'
                                   ,p_summary_flag IN     VARCHAR2 DEFAULT 'N'
                                   ,p_cogs_update IN      VARCHAR2 DEFAULT 'N'
                                    );



-- +===================================================================+
-- | Name  :CREATE_OUTPUT_FILE                                         |
-- | Description : This procedure will be used to format data written  |
-- |               to the ouput file for email report prt_cntrl_flag   |
-- |               can be set to (HEADER,BODY, TRAILER)                |
-- | Parameters : p_group_id, p_sob_id, p_batch_name, p_total_dr       |
-- |              p_total_cr, prt_cntrl_flag|                          |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE  CREATE_OUTPUT_FILE(p_group_id       IN NUMBER   DEFAULT NULL
                                 ,p_sob_id         IN NUMBER   DEFAULT NULL
                                 ,p_batch_name     IN VARCHAR2 DEFAULT NULL
                                 ,p_batch_desc     IN VARCHAR2 DEFAULT NULL
                                 ,p_total_dr       IN NUMBER   DEFAULT NULL
                                 ,p_total_cr       IN NUMBER   DEFAULT NULL
                                 ,p_source_name    IN VARCHAR2 DEFAULT NULL
                                 ,p_intrfc_transfr IN VARCHAR2 DEFAULT NULL
                                 ,p_submit_import  IN VARCHAR2 DEFAULT NULL
                                 ,p_import_stat    IN VARCHAR2 DEFAULT NULL
                                 ,p_import_req_id  IN NUMBER   DEFAULT NULL
                                 ,p_cntrl_flag     IN VARCHAR2
                                 );


-- +===================================================================+
-- | Name  :LOG_MESSAGE                                                |
-- | Description :  This procedure will be used to write record to the |
-- |                xx_gl_interface_na_log table.                      |
-- |                                                                   |
-- | Parameters : p_grp_id,p_source_nm,p_status,p_date_time,p_details  |
-- |              p_request_id                                         |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE  LOG_MESSAGE (p_grp_id         IN NUMBER   DEFAULT NULL
                           ,p_source_nm      IN VARCHAR2 DEFAULT NULL
                           ,p_status         IN VARCHAR2 DEFAULT NULL
                           ,p_details        IN VARCHAR2 DEFAULT NULL
                           ,p_debug_flag  IN VARCHAR2 DEFAULT NULL
                            );



-- +===================================================================+
-- | Name  :TABLE_UTILITY                                              |
-- | Description      :  This public procedure will be used to clean   |
-- |                     up records on the custom interface tables     |
-- |                                                                   |
-- | Parameters :  p_group_id: is needed to delete records from any of |
-- |                           the tables.                             |
-- |               p_del_stg_tbl: set to Y to delete records from the  |
-- |                              staging table based on the group_id  |
-- |               p_del_err_tbl: set to Y to delete records from the  |
-- |                              errors table                         |
-- |                                                                   |
-- |               p_purge_log_tbl: Will ALL purge records from the log|
-- |                                table older then 6 months          |
-- |                                                                   |
-- | Returns :    x_return_message,x_return_code                       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE TABLE_UTILITY ( x_return_message    OUT VARCHAR2
			    ,x_return_code       OUT VARCHAR2
                            ,p_group_id          IN  NUMBER   DEFAULT NULL
                            ,p_del_stg_tbl       IN  VARCHAR2 DEFAULT 'N'
                            ,p_del_err_tbl       IN  VARCHAR2 DEFAULT 'N'
                            ,p_purge_log_tbl     IN  VARCHAR2 DEFAULT 'N'
                            ,p_purge_retain_days IN  NUMBER   DEFAULT NULL
                            ,p_debug_flag        IN  VARCHAR2 DEFAULT 'N'
                            );


END XX_GL_INTERFACE_PKG;
/