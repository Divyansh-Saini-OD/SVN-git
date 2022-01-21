create or replace package XX_CE_CUST_JE_LINES_CREATE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XX_CE_CUST_JE_LINES_CREATE_PKG                              |
-- | Description      :  This Package is created for custom JE creation|
-- |                     extension that excludes certain BAI2          |
-- |                     Transaction codes on the bank statement lines |
-- |                     from standard JE creation so they are not sent|
-- |                     through the standard JE and reconciliation    |
-- |                     process, enabling processing by the           |
-- |                     other CE custom extensions.                   |                             |
-- |                                                                   |                                                               |
-- |                                                                   |
-- | RICE#            : E2027                                          |
-- | Main ITG Package :                                                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============     ===== ===================+=|
-- |DRAFT 1A DD-MON-YYYY  Pradeep Krishnan  Initial draft version      |
-- |1        09-DEC-2008  Pradeep Krishnan                             |
-- |2.0     07-Apr-2020  Amit Kumar    		Changes for E1319		   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
-- +===================================================================+
-- | Name  : CREATE_GL_INTRF_WF_LINE                             	   |
-- | Description      : This Procedure is used to insert  GL Journal for|
-- |                    Wells Fargo Statement entry line into      		|
-- |                    the XX_GL_INTERFACE_NA_STG table.              |
-- |                                                                   |
-- | Parameters :p_bank_branch_id                                      |
-- |             p_bank_account_id                                     |
-- |             p_statement_number_from                               |
-- |             p_statement_number_to                                 |
-- |             p_statement_date_from                                 |
-- |             p_statement_date_to                                   |
-- |             p_gl_date                                             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE CREATE_GL_INTRF_WF_LINE (
		   p_bank_branch_id        IN NUMBER
          ,p_bank_account_id       IN NUMBER
          ,p_statement_number_from IN VARCHAR2
          ,p_statement_number_to   IN VARCHAR2
          ,p_statement_date_from   IN VARCHAR2
          ,p_statement_date_to     IN VARCHAR2
          ,p_gl_date               IN VARCHAR2
          );
-- +===================================================================+
-- | Name  : create_gl_intrf_stg_line_main                             |
-- | Description      : This Procedure can be used to insert GL Journal|
-- |                    entry line into the XX_GL_INTERFACE_NA_STG     |
-- |                    table.                                         |
-- |                                                                   |
-- | Parameters :p_bank_branch_id                                      |
-- |             p_bank_account_id                                     |
-- |             p_statement_number_from                               |
-- |             p_statement_number_to                                 |
-- |             p_statement_date_from                                 |
-- |             p_statement_date_to                                   |
-- |             p_gl_date                                             |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE CREATE_GL_INTRF_STG_LINE_MAIN (
      x_errbuf                OUT NOCOPY  VARCHAR2
    , x_retcode               OUT NOCOPY  NUMBER
    ,p_bank_branch_id         IN NUMBER
    ,p_bank_account_id        IN NUMBER
    ,p_statement_number_from  IN VARCHAR2
    ,p_statement_number_to    IN VARCHAR2
    ,p_statement_date_from    IN VARCHAR2
    ,p_statement_date_to      IN VARCHAR2
    ,p_gl_date                IN VARCHAR2
   );
END;
/