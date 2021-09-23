create or replace PACKAGE "XX_HR_MAPPING_PKG" AS

  FUNCTION JOB_ID (
     p_job_title          IN VARCHAR2
    ,p_job_country_code   IN VARCHAR2
    ,p_job_business_unit  IN VARCHAR2
    ,p_job_code           IN VARCHAR2
    ,p_grade              IN VARCHAR2
    ,p_manager_level      IN VARCHAR2
  ) RETURN PER_JOBS.job_id%TYPE;

  FUNCTION SET_OF_BOOKS_ID (
     p_company            IN  VARCHAR2
  ) RETURN GL_SETS_OF_BOOKS.set_of_books_id%TYPE;

  FUNCTION LOCATION_ID (
     p_location_number    IN  VARCHAR2
  ) RETURN HR_LOCATIONS.location_id%TYPE;

  FUNCTION ORGANIZATION_ID (
     p_cost_center    IN  VARCHAR2,
	 p_bg_id          IN  NUMBER
  ) RETURN HR_ALL_ORGANIZATION_UNITS.organization_id%TYPE;

  FUNCTION BUSINESS_GROUP_ID (
     p_organization_id    IN NUMBER
  ) RETURN HR_ALL_ORGANIZATION_UNITS.business_group_id%TYPE;

  FUNCTION ADDRESS_STYLE (
     p_country            IN VARCHAR2
  ) RETURN VARCHAR2;



-- DEFAULT_CODE_COMB_ID
--You must have dynamic insertion of gl code combinations turned on.
--GL Super User: Setup->Flexfields->Key->Segments
--Query up your accounting flexfield
--Check box to Allow Dynamic Inserts
--...
--PL/SQL must be run from Oracle Concurrent Manager!!!
--OR
--Variables need to be initialized in PL/SQL using
--dbms_application_info.set_client_info(v_ou_org_id); -- For Multi-org
--FND_GLOBAL.APPS_INITIALIZE(v_userid, v_resp_id, v_appl_id);
  FUNCTION DEFAULT_CODE_COMB_ID (
     p_set_of_books_id    IN GL_SETS_OF_BOOKS.set_of_books_id%TYPE
    ,p_concat_segs        IN VARCHAR2
  ) RETURN GL_CODE_COMBINATIONS.code_combination_id%TYPE;


  FUNCTION COMPANY (
     p_company           IN VARCHAR2
    ,p_location           IN VARCHAR2
  ) RETURN GL_CODE_COMBINATIONS.segment1%TYPE;

  FUNCTION COST_CENTER (
     p_dept               IN VARCHAR2,
	p_BG_id              IN NUMBER)
  RETURN GL_CODE_COMBINATIONS.segment2%TYPE;

  FUNCTION ACCOUNT (
     p_description        IN VARCHAR2)
  RETURN GL_CODE_COMBINATIONS.segment3%TYPE;

  FUNCTION LOCATION (
     p_location           IN VARCHAR2)
  RETURN GL_CODE_COMBINATIONS.segment4%TYPE;

  FUNCTION INTERCOMPANY
  RETURN GL_CODE_COMBINATIONS.segment5%TYPE;

  FUNCTION LINE_OF_BUSINESS (
     p_location           IN VARCHAR2
    ,p_cost_center        IN VARCHAR2)
  RETURN GL_CODE_COMBINATIONS.segment6%TYPE;

  FUNCTION FUTURE
  RETURN GL_CODE_COMBINATIONS.segment7%TYPE;

  FUNCTION JOB_TRANSLATION (
    p_job_country_code   IN  VARCHAR2 := '%'
   ,p_job_business_unit  IN  VARCHAR2 := '%'
   ,p_job_code           IN  VARCHAR2 := '%'
   ,p_manager_level      IN  VARCHAR2 := '%'
   ,p_grade              IN  VARCHAR2 := '%'
  ) RETURN XX_FIN_TRANSLATEVALUES.target_value1%TYPE;

  FUNCTION GET_LEDGER (
     p_company           IN VARCHAR2
    ,p_location          IN VARCHAR2
  ) RETURN gl_ledgers.ledger_id%TYPE;
END XX_HR_MAPPING_PKG;
/