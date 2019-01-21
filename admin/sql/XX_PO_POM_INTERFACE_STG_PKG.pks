CREATE OR REPLACE PACKAGE APPS.XX_PO_POM_INTERFACE_STG_PKG AS
PROCEDURE main(x_retcode  OUT NOCOPY  NUMBER
              ,x_errbuf   OUT NOCOPY  VARCHAR2
              ,p_filepath IN          VARCHAR2
              ,p_filename IN          VARCHAR2
								   );

END XX_PO_POM_INTERFACE_STG_PKG;
/
