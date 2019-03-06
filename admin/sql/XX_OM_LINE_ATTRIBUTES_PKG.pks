SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                 Oracle NAIO Consulting Organization                       |
-- +===========================================================================+
-- | Name         :XX_OM_LINE_ATTRIBUTES_PKG                                   |
-- | Rice ID      :E1334_OM_Attributes_Setup                                   |
-- | Description  :This package specification is used to Insert, Update        |
-- |               Delete, Lock rows of XX_OM_LINE_ATTRIBUTES_ALL              |
-- |               Table                                                       |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ============================        |
-- |DRAFT 1A  12-JUL-2007 Prajeesh         Initial draft version               |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

CREATE OR REPLACE PACKAGE xx_om_line_attributes_pkg 
AS

PROCEDURE insert_row(p_line_rec      IN OUT NOCOPY    XXOM.XX_OM_LINE_ATTRIBUTES_T,
                     x_return_status OUT    NOCOPY    VARCHAR2,
		     x_errbuf        OUT    NOCOPY    VARCHAR2);

PROCEDURE update_row(p_line_rec      IN OUT NOCOPY    XXOM.XX_OM_LINE_ATTRIBUTES_T,
                     x_return_status OUT    NOCOPY    VARCHAR2,
		     x_errbuf        OUT    NOCOPY    VARCHAR2);

PROCEDURE lock_row(p_line_rec        IN OUT NOCOPY    XXOM.XX_OM_LINE_ATTRIBUTES_T,
                   x_return_status      OUT NOCOPY    VARCHAR2,
		   x_errbuf             OUT NOCOPY    VARCHAR2);

PROCEDURE delete_row(p_line_id       IN            xx_om_line_attributes_all.line_id%TYPE,
                     x_return_status OUT NOCOPY    VARCHAR2,
		     x_errbuf        OUT NOCOPY    VARCHAR2);

END xx_om_line_attributes_pkg;
/

SHOW ERRORS