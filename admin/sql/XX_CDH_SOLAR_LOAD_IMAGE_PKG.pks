SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_SOLAR_LOAD_IMAGE_PKG
AS

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_CDH_SOLAR_LOAD_IMAGE_PKG                         |
-- | Description      :This package contains procedures to load snapshot/  |
-- |                   images of SOLAR data                                |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      14_Nov-2007 David Woods        Initial version                |
-- |1.1      20_Dec-2007 Rizwan Appees      Modified code to convert into  |
-- |                                        Package procedure, added       |
-- |                                        exception handling             |
-- +=======================================================================+


-- +===================================================================+
-- | Name             : Load_State_Country                             |
-- | Description      : This procedure contains scripts to enter       |
-- |                    STATE - COUNTRY mappings                       |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_State_Country ( x_errbuf              OUT NOCOPY VARCHAR2
                              ,x_retcode             OUT NOCOPY NUMBER
                             );

-- +===================================================================+
-- | Name             : Insert_State_Country                           |
-- | Description      : This procedure contains INSERT scripts to enter|
-- |                    STATE - COUNTRY mappings                       |
-- |                                                                   |
-- | Parameters :      p_state                                         |
-- |                   p_country                                       |
-- +===================================================================+

PROCEDURE Insert_State_Country (p_state    IN VARCHAR2
                               ,p_country  IN VARCHAR2);

-- +===================================================================+
-- | Name             : Load_Salutation                                |
-- | Description      : This procedure contains scripts to enter       |
-- |                    Salutation                                     |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_Salutation ( x_errbuf              OUT NOCOPY VARCHAR2
                           ,x_retcode             OUT NOCOPY NUMBER
                          );

-- +===================================================================+
-- | Name             : Insert_Salutation                              |
-- | Description      : This procedure contains INSERT scripts to enter|
-- |                    Salutation                                     |
-- |                                                                   |
-- | Parameters :      p_salutation                                    |
-- +===================================================================+

PROCEDURE Insert_Salutation (p_salutation    IN VARCHAR2);

-- +===================================================================+
-- | Name             : Load_DistrictImage                             |
-- | Description      : This procedure contains scripts to load        |
-- |                    DistrictImage.                                 |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_DistrictImage ( x_errbuf              OUT NOCOPY VARCHAR2
                              ,x_retcode             OUT NOCOPY NUMBER
                             );

-- +===================================================================+
-- | Name             : Load_SiteImage                                 |
-- | Description      : This procedure contains scripts to load        |
-- |                    SiteImage.                                     |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_SiteImage ( x_errbuf              OUT NOCOPY VARCHAR2
                          ,x_retcode             OUT NOCOPY NUMBER
                         );

-- +===================================================================+
-- | Name             : Load_ContactImage                              |
-- | Description      : This procedure contains scripts to load        |
-- |                    ContactImage.                                  |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_ContactImage ( x_errbuf              OUT NOCOPY VARCHAR2
                             ,x_retcode             OUT NOCOPY NUMBER
                            );
-- +===================================================================+
-- | Name             : Load_ToDoImage                                 |
-- | Description      : This procedure contains scripts to load        |
-- |                    ContactImage.                                  |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_ToDoImage ( x_errbuf              OUT NOCOPY VARCHAR2
                          ,x_retcode             OUT NOCOPY NUMBER
                         );

-- +===================================================================+
-- | Name             : Update_conversion_group                         |
-- | Description      : This procedure contains scripts to update      |
-- |                    Conversion group.                              |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Update_conversion_group ( x_errbuf              OUT NOCOPY VARCHAR2
                                   ,x_retcode             OUT NOCOPY NUMBER
                                  );


-- +===================================================================+
-- | Name             : Load_NoteImage                                 |
-- | Description      : This procedure contains scripts to load        |
-- |                    Notes.                                         |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_NoteImage ( x_errbuf              OUT NOCOPY VARCHAR2
                          ,x_retcode             OUT NOCOPY NUMBER
                         );

END XX_CDH_SOLAR_LOAD_IMAGE_PKG;
/
SHOW ERRORS;