create or replace
PACKAGE xx_ce_cc_preprocess_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                                                                                 |
-- +=================================================================================+
-- | Name       : xx_ce_ajb_preprocess_pkg.pks                                       |
-- | Description: E2077 OD: CE Pre-Process AJB Files                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |  1.0     2011-02-28   Joe Klein          New package copied from E1310 to       |
-- |                                          create separate package for the        |
-- |                                          pre-process procedure.                 |
-- |                                          Make appropriate changes for E2077     |
-- |                                          and SDR project.                       |
-- |                                                                                 |
-- +=================================================================================+

   PROCEDURE xx_ce_ajb_preprocess 
             ( x_errbuf          OUT NOCOPY      VARCHAR2
              ,x_retcode         OUT NOCOPY      NUMBER
              ,p_file_type       IN              VARCHAR2
              ,p_ajb_file_name   IN              VARCHAR2
              ,p_batch_size      IN              NUMBER
             );

END xx_ce_cc_preprocess_pkg;

/
