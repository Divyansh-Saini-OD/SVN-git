create or replace
PACKAGE XX_HR_EMP_PKG AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                                                                                 |
-- +=================================================================================+
-- | Name       : xx_ce_ajb_preprocess_pkg.pks                                       |
-- | Description: E2077 OD: CE Pre-Process AJB Files                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |  2.0     2011-09-22   Joe Klein          Updated for defect 13429 to            |
-- |                                          update phone numbers.                  |
-- |                                                                                 |
--++=================================================================================+
  G_SYNC_PERSON      CONSTANT NUMBER := 1;
  G_SYNC_ASSIGNMENT  CONSTANT NUMBER := 2;
  G_SYNC_CRITERIA    CONSTANT NUMBER := 4;
  G_SYNC_ADDRESS     CONSTANT NUMBER := 8;
  G_SYNC_LOGIN       CONSTANT NUMBER := 16;
  G_SYNC_SUPERVISORS CONSTANT NUMBER := 32;
  G_SYNC_PHONES      CONSTANT NUMBER := 64;  --Added for defect 13429
  G_SYNC_ALL_BASIC   CONSTANT NUMBER := G_SYNC_PERSON + G_SYNC_ASSIGNMENT + G_SYNC_CRITERIA + G_SYNC_ADDRESS + G_SYNC_LOGIN + G_SYNC_PHONES;
  G_SYNC_ALL         CONSTANT NUMBER := G_SYNC_PERSON + G_SYNC_ASSIGNMENT + G_SYNC_CRITERIA + G_SYNC_ADDRESS + G_SYNC_LOGIN + G_SYNC_PHONES + G_SYNC_SUPERVISORS;

  FUNCTION DEFAULT_SYNC_MODE_CONVERSION  RETURN NUMBER; --G_SYNC_ALL_BASIC
  FUNCTION DEFAULT_SYNC_MODE_INTEGRATION RETURN NUMBER; --G_SYNC_ALL

  PROCEDURE SYNC_EMPLOYEE (               -- for testing
    p_employee_number    IN VARCHAR2
   ,p_sync_mode          IN NUMBER := DEFAULT_SYNC_MODE_INTEGRATION
   ,p_create_supervisors IN BOOLEAN := FALSE
  );

--  Warning: SET_HIRE_DATE is unsupported!
--  PROCEDURE SET_HIRE_DATE(              -- for testing
--     p_employee_number IN VARCHAR2
--    ,p_new_hire_date   IN DATE   := '07-JAN-07'
--  );

  PROCEDURE SYNC_ALL_EMPLOYEES (          -- for testing
     p_from_employee_number IN VARCHAR2 := '000000'
    ,p_to_employee_number   IN VARCHAR2 := '999999'
    ,p_sync_mode            IN NUMBER   := DEFAULT_SYNC_MODE_CONVERSION
    ,p_create_supervisors   IN BOOLEAN  := FALSE  -- recursively create any nonexistent supervisors, even if outside from/to range
  );

  PROCEDURE SYNC_ALL_EMPLOYEES (          -- for conversion via concurrent program
     Errbuf                 OUT NOCOPY VARCHAR2
    ,Retcode                OUT NOCOPY VARCHAR2
    ,p_from_employee_number IN VARCHAR2
    ,p_to_employee_number   IN VARCHAR2
    ,p_sync_mode            IN NUMBER
    ,p_create_supervisors   IN VARCHAR2
  );

  PROCEDURE SYNC_CHANGED_EMPLOYEES (      -- for integration
     Errbuf                 OUT NOCOPY VARCHAR2
    ,Retcode                OUT NOCOPY VARCHAR2
  );
  PROCEDURE LINK_MISSING_EMPS_TO_LOGINS ( -- for integration
     Errbuf                 OUT NOCOPY VARCHAR2
    ,Retcode                OUT NOCOPY VARCHAR2
  );
  PROCEDURE LINK_MISSING_EMAIL_ADDRESSES ( -- for integration
     Errbuf                 OUT NOCOPY VARCHAR2
    ,Retcode                OUT NOCOPY VARCHAR2
  );

END XX_HR_EMP_PKG;

/