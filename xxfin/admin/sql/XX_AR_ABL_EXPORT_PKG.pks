CREATE OR REPLACE PACKAGE xx_ar_abl_export_pkg IS
  -- +=================================================================================+
  -- |                       Office Depot - ABL Export                                 |
  -- |                            Providge Consulting                                  |
  -- +=================================================================================+
  -- | Name       : XX_AR_ABL_EXPORT_PKG.pks                                           |
  -- | Description: To Export ABL data to files for a give date                        |
  -- |                                                                                 |
  -- |                                                                                 |
  -- |                                                                                 |
  -- |                                                                                 |
  -- |Change Record                                                                    |
  -- |==============                                                                   |
  -- |Version   Date         Authors            Remarks                                |
  -- |========  ===========  ===============    ============================           |
  -- |DRAFT 1A  04-Aug-2011  Sunildev K         Initial draft version                  |
  -- +=================================================================================+
  -- | Name        : CONS_SENT_INVOICES                                                |
  -- | Description : This procedure will be used to export consolidated unbillled      |
  -- |               Sent Invoices data                                                |
  -- |               AR Lockbox Custom Auto Cash Rules                                 |
  -- |                                                                                 |
  -- | Parameters  : p_as_of_date                                                      |
  -- |               p_email_address                                                   |
  -- |                                                                                 |
  -- | Returns     : x_errbuf                                                          |
  -- |               x_retcode                                                         |
  -- +=================================================================================+

  PROCEDURE cons_sent_invoices
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  );

  PROCEDURE cons_unsent_invoices
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  );

  PROCEDURE ind_sent_unsent_invoices
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  );

  PROCEDURE ind_unbilled
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  );

  PROCEDURE cons_unsent_non_cons
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  );

  PROCEDURE ind_unsent_non_ind
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  );
  PROCEDURE main_process
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  );
END xx_ar_abl_export_pkg;
/