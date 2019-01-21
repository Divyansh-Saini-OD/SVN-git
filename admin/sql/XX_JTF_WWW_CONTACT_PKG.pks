-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_JTF_WWW_CONTACT_PKG.pks                          |
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

create or replace package XX_JTF_WWW_CONTACT_PKG 
AS
PROCEDURE jtf_contact_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
   ,p_batch_id            IN         NUMBER
   );

END XX_JTF_WWW_CONTACT_PKG;
/