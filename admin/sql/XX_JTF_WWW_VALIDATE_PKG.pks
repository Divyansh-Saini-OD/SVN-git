-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_JTF_WWW_VALIDATE_PKG.pks                         |
-- | Description      :I2043 Leads_from_WWW_and_Jmillennia                 |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      15-Feb-2008 David Woods        Initial version                |
-- +=======================================================================+

create or replace package XX_JTF_WWW_VALIDATE_PKG 
AS
PROCEDURE jtf_validate_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
   ,p_end_date            IN         VARCHAR2
   );

END XX_JTF_WWW_VALIDATE_PKG;
/
