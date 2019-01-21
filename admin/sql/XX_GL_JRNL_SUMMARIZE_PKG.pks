CREATE OR REPLACE PACKAGE XX_GL_JRNL_SUMMARIZE_PKG
AS
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                        Office Depot Organization                      |
-- +=======================================================================+
-- | Name         : XX_GL_JRNL_SUMMARIZE_PKG                               |
-- |                                                                       |
-- | RICE#        : E2049                                                  |
-- |                                                                       |
-- | Description  : This package is used to staging, summarize, and then   |
-- |                import high volume journals.                           |
-- |                                                                       |
-- |                The STAGING procedure will perform the following       |
-- |                steps:                                                 |
-- |                                                                       |
-- |                1. Copy journals from gl_interface to the high volume  |
-- |                   interface table (xx_gl_interface_high_vol_na).      |
-- |                2. Verify counts                                       |
-- |                3. Delete journal from gl_interface                    |
-- |                                                                       |
-- |                The SUMMARIZE procedure will perform the following     |
-- |                steps:                                                 |
-- |                                                                       |
-- |                1. Create new summary journal from detailed journal    |
-- |                2. Submit Journal Import for new journal               |
-- |                3. Delete reference information for summary journal    |
-- |                4. Insert reference information from the detailed      |
-- |                   journal into gl_import_references to maintain       |
-- |                   drill back.                                         |
-- |                5. Verify counts and balances between summarized and   |
-- |                   detailed journal.                                   |
-- |                6. Delete detailed journal from gl_interface           |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version    Date         Author         Remarks                         |
-- |=========  ===========  =============  ================================|
-- | 1 to 2.2  various      various        Defect 2851 - Version 2.2 of the| 
-- |                                       code was the initial production | 
-- |                                       version of the code.  It was    |
-- |                                       implemented as part of R10.2.   |
-- |                                       See subversion revision 94176   |
-- |                                       for any commented changes made  |
-- |                                       through version 2.2             |
-- |                                                                       |
-- | 2.3       09-MAR-2010  R.Aldridge     Defect 4690 - Enhance the       |
-- |                                       reprocessing capabilities.      |
-- |                                       Defect 4925 - Enhance to submit |
-- |                                       by source only.                 |
-- | 2.6       30-AUG-2010  R.Hartman      Defect 7765 - Remove GL.*       |
-- |                                       schema name for Archive         |
-- +=======================================================================+


-- +====================================================================+
-- | Name       : XX_GL_JRNL_STG                                        |
-- | Description:                                                       |
-- |                                                                    |
-- | Parameters : p_source, p_request_id, p_request_type and p_sob_id   |
-- |                                                                    |
-- |                                                                    |
-- | Returns :   x_return_message, x_return_code                        |
-- |                                                                    |
-- |                                                                    |
-- +===================================================================+
   PROCEDURE XX_GL_JRNL_STG (x_errbuf              OUT    VARCHAR2
                             ,x_ret_code           OUT    NUMBER
                             ,p_source             IN     VARCHAR2
                             ,p_sob_id             IN     NUMBER);

-- +====================================================================+
-- | Name       : XX_GL_JRNL_SUM                                        |
-- | Description:                                                       |
-- |                                                                    |
-- | Parameters : p_source, p_period_name, p_process_date,              |
-- |              ,p_jrnl_batch_name_prefix and p_sob_id                |
-- |                                                                    |
-- | Returns :   x_return_message, x_return_code                        |
-- |                                                                    |
-- |                                                                    |
-- +===================================================================+
   PROCEDURE XX_GL_JRNL_SUM (x_errbuf                  OUT   VARCHAR2
                             ,x_ret_code               OUT   NUMBER
                             ,p_source                 IN    VARCHAR2
                             ,p_period_name            IN    VARCHAR2 -- added for by Lincy K on 19.1.2010 for defect 2851
                             ,p_process_date           IN    VARCHAR2
                             ,p_jrnl_batch_name_prefix IN    VARCHAR2
                             ,p_sob_id                 IN    NUMBER);
  
END XX_GL_JRNL_SUMMARIZE_PKG;
/
SHO ERR
