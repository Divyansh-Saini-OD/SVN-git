create or replace
PACKAGE XXSCS_UTILITY_PKG AS

   
PROCEDURE object_validate (
         x_errbuf       OUT NOCOPY VARCHAR2,
         x_retcode      OUT NOCOPY VARCHAR2
   );

END XXSCS_UTILITY_PKG;
/
