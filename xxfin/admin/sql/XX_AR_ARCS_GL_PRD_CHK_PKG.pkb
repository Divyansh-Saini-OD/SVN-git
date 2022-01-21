SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_AR_ARCS_GL_PRD_CHK_PKG AS

-- +===================================================================+
-- | PROCEDURE: CHECK_GL_PERIOD                                        |
-- |                                                                   |
-- | DESCRIPTION: This program will check if the previous GL period    |
-- |              been closed since the last execution. If not it will |
-- |              return code 2. If it has it will return code 0.      |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE CHECK_GL_PERIOD(errbuf       OUT NOCOPY VARCHAR2,
                          retcode      OUT NOCOPY NUMBER,
                          p_appl       IN         VARCHAR2,
                          p_gl_period  IN         VARCHAR2,
                          p_days       IN         NUMBER)
IS
lc_fin_date             DATE;
lc_gl_prd_close         VARCHAR2(1) :='N';
lc_appl                 VARCHAR2(5);
lc_gl_period            VARCHAR2(6);
lc_days                 NUMBER;

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AR_ARCS_GL_PRD_CHK_PKG Begin:');

    BEGIN
        retcode      := 2;
        lc_appl      := p_appl;
        lc_gl_period := p_gl_period;
        lc_days      := p_days;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parameters: '||lc_appl||','||lc_gl_period||','||lc_days);

        SELECT 'Y'
        INTO   lc_gl_prd_close
        FROM   gl_period_statuses   G,
               fnd_application_vl   A 
        WHERE  A.application_id         = G.application_id
        AND    G.set_of_books_id        = 6003
        AND    G.closing_status         = 'C'
        AND    A.application_short_name = lc_appl
        AND    G.period_name            = lc_gl_period
        AND    NOT EXISTS (SELECT 'N'
                           FROM   fnd_concurrent_requests    R,
                                  FND_CONCURRENT_PROGRAMS_VL P
                           WHERE  R.concurrent_program_id   = P.concurrent_program_id
                           AND    P.concurrent_program_name = 'XX_AR_ARCS_GL_PRD_CHK'
                           AND    R.status_code             = 'C'
                           AND    R.phase_code              = 'C'
				     AND    R.argument1               = p_appl
                           AND    R.argument2               = p_gl_period
                           and    R.actual_start_date       > sysdate - lc_days);

        IF lc_gl_prd_close = 'Y' THEN
           retcode := 0;
        END IF;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AR_ARCS_GL_PRD_CHK_PKG status: '||lc_gl_prd_close);

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND: ' || SQLERRM);
                 RETCODE := 2;
            WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'OTHERS: ' || SQLERRM);
                 RETCODE := 2;
    END;

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AR_ARCS_GL_PRD_CHK_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END CHECK_GL_PERIOD;

END XX_AR_ARCS_GL_PRD_CHK_PKG;
/
