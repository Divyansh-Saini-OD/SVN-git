-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | SQL Script to insert into the following object                           |
-- |             Table    :XXFIN.XX_CYCLE_WAVE_SETUP                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date              Author               Remarks               |
-- |=======      ==========        =============        ===================== |
-- | V1.0        12-AUG-2010       Jude Felix Antony.A. Initial version       |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

--+======================================+
--+               WAVE1                  +
--+======================================+

INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (10,'Wave1','HVOP');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (20,'Wave1','AUTO_INVOICE');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (30,'Wave1','AUTO_REMITTANCE');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (40,'Wave1','I1025');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (50,'Wave1','AUTO_ADJUSTMENT');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,CA_STATUS) VALUES (60,'Wave1','GL_TRX','N/R');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,CA_STATUS) VALUES (70,'Wave1','GL_COGS','N/R');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (80,'Wave1','BILLING_PROGRAMS');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,CA_STATUS) VALUES (90,'Wave1','GL_ALL','N/R');

--+======================================+
--+               WAVE2                  +
--+======================================+

INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (10,'Wave2','HVOP');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (20,'Wave2','AUTO_INVOICE');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,CA_STATUS) VALUES (30,'Wave2','AUTO_REMITTANCE','N/R');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,CA_STATUS) VALUES (40,'Wave2','GL_TRX','N/R');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,CA_STATUS) VALUES (50,'Wave2','GL_COGS','N/R');

--+======================================+
--+               WAVE3                  +
--+======================================+
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (10,'Wave3','HVOP');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (20,'Wave3','AUTO_INVOICE');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,CA_STATUS) VALUES (30,'Wave3','AUTO_REMITTANCE','N/R');

--+======================================+
--+               WAVE4                  +
--+======================================+

INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (10,'Wave4','HVOP');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (20,'Wave4','AUTO_INVOICE');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (30,'Wave4','AUTO_REMITTANCE');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (40,'Wave4','I1025');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (50,'Wave4','GL_TRX');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,US_STATUS) VALUES (60,'Wave4','GL_ALL','N/R');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (70,'Wave4','GL_COGS');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (80,'Wave4','REFUNDS');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (90,'Wave4','BILLING_PROGRAMS');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (100,'Wave4','DISPUTES');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (110,'Wave4','DAILY_REPORTS');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,US_STATUS,CA_STATUS) VALUES (120,'Wave4','WEEKEND_REPORTS','N/R','N/R');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,US_STATUS,CA_STATUS) VALUES (130,'Wave4','AUTO_ADJUSTMENT','N/R','N/R');

--+======================================+
--+               WAVE5                  +
--+======================================+

INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME) VALUES (10,'Wave5','ADV_COLLECTIONS1');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,CA_STATUS) VALUES (20,'Wave5','ADV_COLLECTIONS2','N/R');
INSERT INTO XXFIN.XX_CYCLE_WAVE_SETUP(S_ORDER,WAVE,PROGRAM_NAME,CA_STATUS) VALUES (30,'Wave5','CREDIT_CHECK','N/R');

COMMIT;

SHOW ERROR