-- 18-Dec-2006 testing TortoiseSVN
--  Discoverer DDL Statements

CREATE OR REPLACE VIEW XXGCS_CONS_HIERARCHY_V
(HIERARCHY_NAME, PARENT_ENTITY, CHILD_ENTITY, CHILD_DESCRIPTION, CHILD_ENTITY_ID)
AS 
SELECT DISTINCT 
	   ght.hierarchy_name, 
           fetp.entity_name parent_entity, 
--	   fetp.description parent_description, 
	   fetc.entity_name child_entity, 
	   fetc.description child_description, 
	   gcr.child_entity_id 
FROM fem_entities_tl fetc, 
     fem_entities_tl fetp, 
     gcs_cons_relationships gcr, 
     gcs_hierarchies_b ghb, 
     gcs_hierarchies_tl ght, 
     fnd_profile_option_values fpov, 
     fnd_profile_options_vl fpo 
WHERE fpo.user_profile_option_name = 'XXGCS: Consolidation Hierarchy' 
AND   fpov.profile_option_id = fpo.profile_option_id 
AND   ghb.hierarchy_id = ght.hierarchy_id 
AND   ght.hierarchy_name = fpov.profile_option_value 
AND   ghb.hierarchy_id = gcr.hierarchy_id 
--there are old child entity relationships in here with start_date values > end_date 
AND   (gcr.end_date IS NULL OR gcr.start_date < gcr.end_date) 
AND   fetp.entity_id = gcr.parent_entity_id 
AND   fetc.entity_id = gcr.child_entity_id 
START WITH gcr.parent_entity_id = ghb.top_entity_id 
CONNECT BY PRIOR gcr.child_entity_id = gcr.parent_entity_id 
ORDER BY 1, 2, 3
/


CREATE OR REPLACE VIEW XXFEM_CAL_PERIODS_TL_V
(CAL_PERIOD_ID, FULL_CAL_PERIOD_ID, CAL_PERIOD_NAME)
AS 
SELECT cpb.cal_period_id, 
       TO_CHAR(cpb.cal_period_id) full_cal_period_id, 
       cptl.cal_period_name 
FROM fem_cal_periods_tl cptl, 
     fem_cal_periods_b cpb, 
     fem_dimension_grps_tl dgtl 
WHERE cpb.cal_period_id = cptl.cal_period_id 
AND   cpb.dimension_group_id = dgtl.dimension_group_id 
AND   dgtl.dimension_group_name LIKE 'General Ledger%'
/


CREATE TABLE XXFEM_CAL_PERIODS_TL
(
  CAL_PERIOD_ID       NUMBER                    NOT NULL,
  LANGUAGE            VARCHAR2(4 BYTE)          NOT NULL,
  SOURCE_LANG         VARCHAR2(4 BYTE)          NOT NULL,
  CAL_PERIOD_NAME     VARCHAR2(150 BYTE)        NOT NULL,
  DESCRIPTION         VARCHAR2(255 BYTE),
  CREATION_DATE       DATE                      NOT NULL,
  CREATED_BY          NUMBER                    NOT NULL,
  LAST_UPDATED_BY     NUMBER                    NOT NULL,
  LAST_UPDATE_DATE    DATE                      NOT NULL,
  LAST_UPDATE_LOGIN   NUMBER,
  CALENDAR_ID         NUMBER(5)                 NOT NULL,
  DIMENSION_GROUP_ID  NUMBER                    NOT NULL
)
TABLESPACE APPS_TS_TX_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE INDEX XXFEM_CAL_PERIODS_TL_N1 ON XXFEM_CAL_PERIODS_TL
(CAL_PERIOD_ID)
LOGGING
TABLESPACE APPS_TS_TX_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE OR REPLACE TRIGGER XXFEM_CAL_PERIODS_TL
AFTER INSERT ON FEM_CAL_PERIODS_TL
FOR EACH ROW
BEGIN
  INSERT INTO XXFEM_CAL_PERIODS_TL
  SELECT *
  FROM FEM_CAL_PERIODS_TL FCPT
  WHERE DIMENSION_GROUP_ID >= 1000
  AND   NOT EXISTS (SELECT 'RECORD ALREADY EXISTS'
                    FROM XXFEM_CAL_PERIODS_TL XCPT2
                    WHERE XCPT2.CAL_PERIOD_NAME = FCPT.CAL_PERIOD_NAME
                    AND   XCPT2.CAL_PERIOD_ID = FCPT.CAL_PERIOD_ID
                    AND   XCPT2.LANGUAGE = FCPT.LANGUAGE
                    AND   XCPT2.DIMENSION_GROUP_ID = FCPT.DIMENSION_GROUP_ID);
END;
/


create or replace FUNCTION xxfem_security (v_entity_id NUMBER)
RETURN NUMBER IS
  v_count             NUMBER :=0;
  v_responsibility_id fnd_responsibility.responsibility_id%TYPE := Fnd_Global.resp_id;

BEGIN
  /* If this is and Oracle E-Business Suite or Oracle Discoverer connection the responsibility_id will be > 1 */
  IF v_responsibility_id = -1 THEN
    /* Let non-apps connections see everything */
    RETURN 1;

  ELSE
    /* See if this responsibility has access to this entity */
    SELECT COUNT(*)
    INTO v_count
    FROM gcs_role_entity_relns
    WHERE orig_system_id = v_responsibility_id
    AND   entity_id = v_entity_id;

    IF v_count = 0 THEN
      RETURN 0;
    ELSE
      RETURN 1;
    END IF;
  END IF;

END;
/


CREATE OR REPLACE VIEW XXFEM_BALANCES_V
AS 
SELECT *
WHERE  Xxfem_Security(entity_id) = 1
/


CREATE UNIQUE INDEX XXGCS.XXGCS_ROLE_ENTITY_RELNS_U1 ON GCS.GCS_ROLE_ENTITY_RELNS
(ORIG_SYSTEM_ID, ENTITY_ID)
LOGGING
TABLESPACE APPS_TS_SEED
PCTFREE    10
INITRANS   11
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;
