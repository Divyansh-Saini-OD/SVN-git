SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET DEFINE OFF

PROMPT Creating Package Specification XX_IBY_CREREP_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE      XX_IBY_CREREP_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      Credit Card Settlement Report                         |
-- | Description : To generate a report of the Credit Card Settlement  |
-- |              History table which helps to analyze all previous    |
-- |              credit card settlement transactions.                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       25-MAY-2007  Anusha Ramanujam     Initial version        |
-- |1.1       06-DEC-2007  Aravind A.           Fixed defect 2925      |
-- |1.2       31-JAN-2008  Aravind A.           Fixed defect 3832      |
-- |1.3       04-APR-2008  Ranjith Prabu T      Fix for defect 5436    |
-- |1.4       25-JUN-2008  Aravind A.           Fixed defect 8403      |
-- +===================================================================+

-- +===================================================================+
-- | Name : XX_IBY_DISPPAGE                                            |
-- | Description : To to create and display the frame structure only   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_IBY_DISPPAGE;

-- +===================================================================+
-- | Name : XX_IBY_PARAFORM                                            |
-- | Description : To create and display parameter form along with     |
-- |               "Go" and "Cancel" buttons.                          |
-- |               It will also verify if the date paramter values     |
-- |               entered by the user are valid or not.               |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_IBY_PARAFORM ;


-- +===================================================================+
-- | Name : XX_IBY_HDRREC                                              |
-- | Description : To display all the header records from the table    |
-- |               based on the input parameters provided by the user. |
-- |                                                                   |
-- | Parameters : p_ldate,p_hdate,p_locstrnum, p_ordtyp,p_regnum,      |
-- |              p_trannum,p_batchnum,p_dollamt,p_trantyp,p_recptnum  |
-- +===================================================================+
    /*PROCEDURE XX_IBY_HDRREC (
                             p_ldate        IN  DATE
                            ,p_hdate        IN  DATE
                            ,p_locstrnum    IN  NUMBER
                            ,p_ordtyp       IN  VARCHAR2
                            ,p_regnum       IN  NUMBER    DEFAULT NULL
                            ,p_trannum      IN  VARCHAR2  DEFAULT NULL
                            ,p_batchnum     IN  NUMBER
                            ,p_dollamt      IN  NUMBER
                            ,p_trantyp      IN  VARCHAR2
                            ,p_recptnum     IN  VARCHAR2
                            );*/
    --Fixed defect 2925
    PROCEDURE XX_IBY_HDRREC (
                             p_ldate        IN  DATE
                            ,p_hdate        IN  DATE
                            ,p_locstrnum    IN  VARCHAR2  DEFAULT NULL
                            ,p_ordtyp       IN  VARCHAR2
                            ,p_regnum       IN  VARCHAR2  DEFAULT NULL
                            ,p_trannum      IN  VARCHAR2  DEFAULT NULL
                            ,p_batchnum     IN  VARCHAR2
                            ,p_cond         IN  VARCHAR2  --Added for defect 3832
                            ,p_dollamt      IN  VARCHAR2
                            ,p_trantyp      IN  VARCHAR2
                            ,p_recptnum     IN  VARCHAR2
                            ,p_rec_count    IN  VARCHAR2  DEFAULT '1000'  --Added for defect 8403
                            ,p_cash_rec_id  IN  VARCHAR2  DEFAULT '0'     --Added for defect 8403
                            ,p_sign         IN  VARCHAR2  DEFAULT '>'     --Added for defect 8403
                            ,p_country_code IN  VARCHAR2                  --Added for defect 8403
                            ,p_cnt_exec     IN  VARCHAR2  DEFAULT '1'     --Added for defect 8403
                            ,p_tot_cnt      IN  PLS_INTEGER DEFAULT NULL  --Added for defect 8403
                            ,p_page_num     IN  NUMBER    DEFAULT  0      --Added for defect 8403
                            ,p_cur_page_num IN  NUMBER    DEFAULT  0      --Added for defect 8403
                            );


-- +===================================================================+
-- | Name : XX_IBY_LABLNAME                                            |
-- | Description : To fetch the corresponding column label names for   |
-- |               all the column names to display it in the required  |
-- |               format in the bottom frame.                         |
-- | Parameters :  p_colname, x_lablname                               |
-- +===================================================================+
    PROCEDURE XX_IBY_LABLNAME(p_colname   IN  VARCHAR2
                             ,x_lablname  OUT NOCOPY VARCHAR2
                             );


-- +===================================================================+
-- | Name : XX_IBY_DTLREC                                              |
-- | Description : To facilitate the user to see more detail records   |
-- |               on clicking the "More Info" Link on specific        |
-- |               record. It will display the records in a new page.  |
-- | Parameters :  p_receipt_num  ,p_batch_num                         |
-- +===================================================================+
   /* PROCEDURE XX_IBY_DTLREC(p_rowid         IN  VARCHAR2
                            );*/
    PROCEDURE XX_IBY_DTLREC(p_receipt_num        IN  VARCHAR2
                            ,p_batch_num          IN  VARCHAR2
                          );


-- +===================================================================+
-- | Name : XX_IBY_CHDREC                                              |
-- | Description : To facilitate the user to see more detail records   |
-- |               on clicking the "More Info" Link on specific        |
-- |               record. It will display the records in a new page.  |
-- | Parameters :  p_receipt_num   ,p_batch_num                        |
-- +===================================================================+
   /* PROCEDURE XX_IBY_CHDREC(p_rowid   IN  VARCHAR2
                            );

    */
    PROCEDURE XX_IBY_CHDREC(p_receipt_num   IN  VARCHAR2
                            ,p_batch_num          IN  VARCHAR2
                            );
                            
                            
    FUNCTION XX_DECRYPT_KEY(P_RECEIPT_NUM   IN  VARCHAR2
                            ,P_BATCH_NUM          IN  VARCHAR2)
                            RETURN VARCHAR2; 
                            
    END XX_IBY_CREREP_PKG;
/
SHOW ERR