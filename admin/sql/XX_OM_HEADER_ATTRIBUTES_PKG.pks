SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE xx_om_header_attributes_pkg 
AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                 Oracle NAIO Consulting Organization                       |
-- +===========================================================================+
-- | Name         :XX_OM_HEADER_ATTRIBUTES_PKG                                 |
-- | Rice ID      :E1334_OM_Attributes_Setup                                   |
-- | Description  :This package specification is used to Insert, Update        |
-- |               Delete, Lock rows of XX_OM_HEADER_ATTRIBUTES_ALL            |
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

--  Global constant holding the package name


  G_exception_header   CONSTANT VARCHAR2(40) := 'Custom Order Attributes';
  G_track_code         CONSTANT VARCHAR2(5)  := 'OTC';
  G_solution_domain    CONSTANT VARCHAR2(40) := 'OrderManagement';
  G_function           CONSTANT VARCHAR2(40) := 'Custom Attributes';



  -- Variable Declaration for exception handling
exception_object_type xx_om_report_exception_t := xx_om_report_exception_t(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

PROCEDURE xx_log_exception_proc(p_error_code          IN            VARCHAR2
                                ,p_error_description  IN            VARCHAR2
                                ,p_entity_ref         IN            VARCHAR2
                                ,p_entity_ref_id      IN            NUMBER
				,x_return_status      IN OUT NOCOPY VARCHAR2
				,x_errbuf             IN OUT NOCOPY VARCHAR2
                                  );

PROCEDURE insert_row(p_header_rec    IN OUT NOCOPY XXOM.XX_OM_HEADER_ATTRIBUTES_T,
                     x_return_status OUT NOCOPY    VARCHAR2,
		     x_errbuf        OUT NOCOPY    VARCHAR2);

PROCEDURE update_row(p_header_rec    IN OUT NOCOPY XXOM.XX_OM_HEADER_ATTRIBUTES_T,
                     x_return_status OUT NOCOPY    VARCHAR2,
		     x_errbuf        OUT NOCOPY    VARCHAR2);

PROCEDURE lock_row(p_header_rec IN   OUT NOCOPY    XXOM.XX_OM_HEADER_ATTRIBUTES_T,
                   x_return_status   OUT NOCOPY    VARCHAR2,
		   x_errbuf          OUT NOCOPY    VARCHAR2);

PROCEDURE delete_row(p_header_id     IN            XX_OM_HEADER_ATTRIBUTES_ALL.header_id%TYPE,
                     x_return_status OUT NOCOPY    VARCHAR2,
		     x_errbuf        OUT NOCOPY    VARCHAR2);

END xx_om_header_attributes_pkg;
/

SHOW ERRORS
