CREATE OR REPLACE PACKAGE APPS.XX_AR_POS_SALES_SUM_SPO_PKG
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
-- |1.0       01-MAY-2012   Gayathri K         Intial Version                                 |
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
   PROCEDURE MAIN (
      x_errbuf            OUT NOCOPY      VARCHAR2,
      x_retcode           OUT NOCOPY      VARCHAR2,
      p_trans_date_from   IN              VARCHAR2,
      p_trans_date_to     IN              VARCHAR2,
      p_store_num         IN              VARCHAR2,
      p_gl_date_from      IN              VARCHAR2,
      p_gl_date_to        IN              VARCHAR2,
      p_ou_id             IN              NUMBER
   );


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
   PROCEDURE SUM_BY_STORE_SPO_PROC (
      p_trx_date_from   IN   VARCHAR2,
      p_trx_date_to     IN   VARCHAR2,
      p_store           IN   VARCHAR2,
      p_gl_date_from    IN   VARCHAR2,
      p_gl_date_to      IN   VARCHAR2,
      p_ou_id           IN   NUMBER
   );
END XX_AR_POS_SALES_SUM_SPO_PKG;
/

SHOW ERROR