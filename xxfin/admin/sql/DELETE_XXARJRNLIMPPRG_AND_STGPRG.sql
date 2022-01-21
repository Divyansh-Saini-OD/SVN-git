SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : DELETE_XXARJRNLIMPPRG_AND_STGPRG.sql                    |
-- | Description : Remove custom programs registered under standar app AR  |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     29-JAN-2010 Rick Aldridge      Removing program registered    |
-- |                                        under wrong application        |
-- +=======================================================================+

BEGIN

  -- Deleting OD: AR HV Journal Import Registered under AR application
  apps.FND_PROGRAM.DELETE_PROGRAM(program_short_name => 'XXARJRNLIMPPRG'
                                 ,application        => 'AR');

  -- Deleting OD: AR HV Journal Staging Registered under AR application
  apps.FND_PROGRAM.DELETE_PROGRAM(program_short_name => 'XXARJRNLSTGPRG'
                                 ,application        => 'AR');
END;

