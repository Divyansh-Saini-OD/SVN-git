create or replace
PACKAGE XX_CRM_INCENTCOMP_FEED_PKG

-- +===================================================================+
-- |                  Office Depot - Varicent Project                  |
-- +===================================================================+
-- | Name       :  XX_CRM_INCENTCOMP_OUTBOUND_PKG                      |
-- | Description:  This package contains procedures to extract Resource|
-- |               manager data and FTP flat files with those          |
-- |               data to Varicent                                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |V 1.0     18-JAN-2011 Kishore Jena     Initial draft version       |
-- +===================================================================+

AS

G_LEVEL_ID                      CONSTANT  NUMBER       := 10001;
G_LEVEL_VALUE                   CONSTANT  NUMBER       := 0;

-- +===================================================================+
-- | Name             : Generate_File                                  |
-- | Description      : This procedure extracts feeds and FTP          |
-- |                    it over to VARICENT.                           |
-- |                                                                   |
-- | parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Generate_File(x_errbuf              OUT NOCOPY VARCHAR2,
                        x_retcode             OUT NOCOPY NUMBER,
                        p_enable_ftp          IN         VARCHAR2,
                        p_as_of_date          IN         DATE
                       );
PROCEDURE Generate_Quota_File(x_errbuf              OUT NOCOPY VARCHAR2,
                              x_retcode             OUT NOCOPY NUMBER
                             ) ;
PROCEDURE Generate_Overlay_File(x_errbuf              OUT NOCOPY VARCHAR2,
                              x_retcode             OUT NOCOPY NUMBER
                             ) ;
END XX_CRM_INCENTCOMP_FEED_PKG;
/