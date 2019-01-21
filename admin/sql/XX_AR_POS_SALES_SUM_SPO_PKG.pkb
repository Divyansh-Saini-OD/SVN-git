CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_POS_SALES_SUM_SPO_PKG
AS
-- +==========================================================================================+
-- |                  Office Depot - Project Simplify                                         |
-- +==========================================================================================+
-- | Name        : XX_AR_POS_SALES_SUM_SPO_PKG                                                |
-- | Description : This package is used for to display output in excel format                 |
-- |        for the program "OD: AR POS Sales Summary by Store Report for Single Pay Orders." |
-- |                                                                                          |
-- |Change Record:                                                                            |
-- |===============                                                                           |
-- |Version    Date         Author              Remarks                                       |
-- |=========  ===========  ==================  ==============================================|
-- |1.0       01-MAY-2012   Gayathri K           Intial Version                               |
-- +==========================================================================================+

   -- +=========================================================================================+
-- | PROCEDURE  : MAIN                                                                       |
-- |                                                                                         |
-- | DESCRIPTION: This procedure is used to call  PROCEDURE "SUM_BY_STORE_SPO_PROC" which    |
-- |              will submit OD: AR POS Sales Summary by Store Report for Single Pay Orders |
-- |                                                                                         |
-- | PARAMETERS : x_errbuf , x_retcode ,p_trans_date_from,p_trans_date_to                    |
-- |             p_store_num  , p_gl_date_from ,  p_gl_date_to ,p_ou_id                      |
-- |                                                                                         |
-- |                                                                                         |
-- | RETURNS    : x_errbuf  and  x_retcode                                                   |
-- +=========================================================================================+
   PROCEDURE main (
      x_errbuf            OUT NOCOPY      VARCHAR2,
      x_retcode           OUT NOCOPY      VARCHAR2,
      p_trans_date_from   IN              VARCHAR2,
      p_trans_date_to     IN              VARCHAR2,
      p_store_num         IN              VARCHAR2,
      p_gl_date_from      IN              VARCHAR2,
      p_gl_date_to        IN              VARCHAR2,
      p_ou_id             IN              NUMBER
   )
   IS
   BEGIN
      sum_by_store_spo_proc (p_trans_date_from,
                             p_trans_date_to,
                             p_store_num,
                             p_gl_date_from,
                             p_gl_date_to,
                             p_ou_id
                            );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'ERRMSG AT SUM_BY_STORE_SPO_PROC : ' || SQLERRM
                           );
       
   END main;

-- +===========================================================================================+
-- | PROCEDURE  : SUM_BY_STORE_SPO_PROC                                                        |
-- |                                                                                           |
-- | DESCRIPTION: This procedure is used to SUBMIT THE PROGRAM "XXARPOSSASU_SPO"               |
-- |                to get output of XML Report into Excel Sheet format.                       |
-- |                                                                                           |
-- | PARAMETERS : p_trx_date_from  , p_trx_date_to ,p_store,p_gl_date_from                     |
-- |             p_gl_date_t and p_ou_id                                                       |
-- |                                                                                           |
-- | RETURNS    :None                                                                          |
-- +===========================================================================================+
   PROCEDURE sum_by_store_spo_proc (
      p_trx_date_from   IN   VARCHAR2,
      p_trx_date_to     IN   VARCHAR2,
      p_store           IN   VARCHAR2,
      p_gl_date_from    IN   VARCHAR2,
      p_gl_date_to      IN   VARCHAR2,
      p_ou_id           IN   NUMBER
   )
   IS
    
      lb_layout          BOOLEAN;
      ln_request_id      NUMBER;
      ld_trx_date_from   DATE;
      ld_trx_date_to     DATE;
      ld_gl_date_from    DATE;
      ld_gl_date_to      DATE;
   BEGIN
      ld_trx_date_from := TO_DATE (p_trx_date_from, 'RRRR/MM/DD HH24:MI:SS');
      ld_trx_date_to := TO_DATE (p_trx_date_to, 'RRRR/MM/DD HH24:MI:SS');
      ld_gl_date_from := TO_DATE (p_gl_date_from, 'RRRR/MM/DD HH24:MI:SS');
      ld_gl_date_to := TO_DATE (p_gl_date_to, 'RRRR/MM/DD HH24:MI:SS');
    
 -- Set the Output File Format
-- --------------------------
      lb_layout :=
         fnd_request.add_layout ('XXFIN',
                                 'XXARPOSSASU_SPO',
                                 'en',
                                 'US',
                                 'EXCEL'
                                );
-- Submit the program - OD: AR POS Sales Summary by Store Report for Single Pay Orders
-- -----------------------------------------------------------------------------------
      ln_request_id :=
         fnd_request.submit_request ('XXFIN',
                                     'XXARPOSSASU_SPO',
                                     NULL,
                                     NULL,
                                     FALSE,
                                     ld_trx_date_from,
                                     ld_trx_date_to,
                                     p_store,
                                     ld_gl_date_from,
                                     ld_gl_date_to,
                                     p_ou_id
                                    );
      COMMIT;

      IF ln_request_id <> 0
      THEN
         COMMIT;
         fnd_file.put_line
            (fnd_file.LOG,
                'Successfully submitted OD: AR POS Sales Summary by Store Report for Single Pay Orders : '
             || ln_request_id
            );
      ELSE
         fnd_file.put_line
            (fnd_file.LOG,
                'OD: AR POS Sales Summary by Store Report for Single Pay Orders Failed : '
             || ln_request_id
            );
         fnd_file.put_line (fnd_file.LOG, 'ERRMSG : ' || SQLERRM);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
                'OD: AR POS Sales Summary by Store Report for Single Pay Orders Failed : '
             || ln_request_id
            );
         fnd_file.put_line (fnd_file.LOG, 'ERRMSG : ' || SQLERRM);
   END sum_by_store_spo_proc;
END XX_AR_POS_SALES_SUM_SPO_PKG;
/

SHOW ERROR