CREATE OR REPLACE PACKAGE XX_AR_ARCS_GL_PRD_CHK_PKG AS

-- +===================================================================+
-- | Name  : XX_RJS_TEST_PKG.LOAD_RJS_TEST                             |
-- | Parameters      none                                              |
-- +===================================================================+

PROCEDURE CHECK_GL_PERIOD(errbuf                OUT NOCOPY VARCHAR2,
                          retcode               OUT NOCOPY NUMBER,
                          p_appl                IN         VARCHAR2,
                          p_gl_period           IN         VARCHAR2,
                          p_days                IN         NUMBER);

END XX_AR_ARCS_GL_PRD_CHK_PKG;
/
