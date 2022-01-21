SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE XX_TAXWAREADSYNC_PKG AS
  -- +==========================================================================+
  -- |                           Office Depot                                   |
  -- |                                                                 |
  -- +==========================================================================+
  -- | Name             :    XX_TAXWAREADSYNC_PKG                                  |
  -- | Description      :    Package for Taxware AD Users Sync program               |
  -- | RICE ID          :    NA                                             |
  -- |                                                                          |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date         Author              Remarks                        |
  -- |=======   ===========  ================    ========================       |
  -- | 1.0      30-Jan-2018  Visu P                Initial                      |
  -- +==========================================================================+
----------------------------------------------------------------
/* Procedure to sync users between Taxware system and Oracle EBS */
----------------------------------------------------------------
  PROCEDURE xx_ebs_ad_sync(
  x_errbuf  OUT NOCOPY VARCHAR2
 ,x_retcode OUT NOCOPY NUMBER
  );
--
END XX_TAXWAREADSYNC_PKG;

/

SHOW ERRORS;