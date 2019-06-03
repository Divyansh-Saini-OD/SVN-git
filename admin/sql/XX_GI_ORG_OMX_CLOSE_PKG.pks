CREATE OR REPLACE PACKAGE APPS.XX_GI_ORG_OMX_CLOSE_PKG 
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_GI_ORG_OMX_CLOSE_PKG                            |
-- | Description      :    Pkg to close inventory periods for OMX Locations   |
-- | RICE ID          :    E0351b                                             |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      09-Jun-2014  Paddy Sanjeevi      Initial                        |
-- +==========================================================================+

PROCEDURE XX_OMX_INV_ORG_CLOSE (  x_errbuf     OUT NOCOPY VARCHAR2,
			          x_retcode    OUT NUMBER,
				  p_no_periods  IN NUMBER
                               );

END XX_GI_ORG_OMX_CLOSE_PKG;
/
