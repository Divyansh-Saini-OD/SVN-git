SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_CDH_CLASS_CODE_CORRECTION
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                Oracle NAIO Consulting Organization                |
  -- +===================================================================+
  -- | Name        :  XX_CDH_CLASS_CODE_CORRECTION.pks                   |
  -- | Description :  CDH Class Codes Correction                         |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author             Remarks                   |
  -- |========  =========== ================== ==========================|
  -- |DRAFT 1a  28-Aug-2008 Indra Varada       Initial draft version     |
  -- |2.0       11-Sep-2008 Indra Varada       Added logic for NAICS     |
  -- |2.1       17-Sep-2008 Indra Varada       Status not set to 'I'     |
  -- |2.2       24-Jun-2009 Indra Varada       Removed Trunc on End Date |
  -- +===================================================================+
PROCEDURE code_assignments_correction(
    x_errbuf OUT VARCHAR2,
    x_retcode OUT VARCHAR2,
    p_start_date IN VARCHAR2,
    p_end_date   IN VARCHAR2 )
AS
  CURSOR new_code_assignment (p_actual_source VARCHAR2, p_st_date DATE, p_en_date DATE)
  IS
    SELECT code_assignment_id,
      owner_table_id,
      class_category,
      object_version_number,
      primary_flag,
      creation_date
    FROM
      (SELECT ROW_NUMBER() OVER(PARTITION BY OWNER_TABLE_ID,CLASS_CATEGORY ORDER BY CREATION_DATE DESC) AS ROWNUM1,
        owner_table_id,
        class_category,
        actual_content_source,
        code_assignment_id,
        object_version_number,
        primary_flag,
        creation_date
      FROM HZ_CODE_ASSIGNMENTS
      WHERE OWNER_TABLE_NAME    ='HZ_PARTIES'
      AND actual_content_source = p_actual_source
      AND status                = 'A'
      AND end_date_active      IS NULL
      AND TRUNC(CREATION_DATE) BETWEEN TRUNC(NVL(p_st_date,TO_DATE('01-01-1800','DD-MM-YYYY'))) AND TRUNC(NVL(p_en_date,SYSDATE))
      ) A
  WHERE A.ROWNUM1    =1
  AND (A.primary_flag='N'
  OR A.primary_flag IS NULL);
  CURSOR other_code_assignments (p_code_assignment NUMBER, p_owner_table_id NUMBER,p_category VARCHAR2)
  IS
    SELECT code_assignment_id,
      status,
      primary_flag,
      object_version_number,
      end_date_active,
      actual_content_source,
      creation_date,
      class_category
    FROM hz_code_assignments
    WHERE owner_table_id      = p_owner_table_id
    AND owner_table_name      = 'HZ_PARTIES'
    AND class_category        = p_category
    AND actual_content_source = 'GDW'
    AND code_assignment_id   <> p_code_assignment;
TYPE date_cur_type
IS
  REF
  CURSOR;
    date_cur date_cur_type;
  TYPE new_code_assignments
IS
  TABLE OF new_code_assignment%ROWTYPE INDEX BY BINARY_INTEGER;
TYPE other_code_assign_type
IS
  RECORD
  (
    code_assignment_id    NUMBER,
    status                VARCHAR2(5),
    primary_flag          VARCHAR2(5),
    object_version_number NUMBER,
    end_date_active       DATE,
    actual_content_source VARCHAR2(30),
    creation_date         DATE,
    class_category        VARCHAR2(40) );
  l_new_code_assign_tab new_code_assignments;
  l_other_code_assign_rec other_code_assign_type;
  p_code_assign_rec HZ_CLASSIFICATION_V2PUB.code_assignment_rec_type;
  ln_bulk_limit    NUMBER := 100;
  l_update_status  VARCHAR2(10);
  l_update_flag    BOOLEAN;
  update_err       EXCEPTION;
  l_return_status  VARCHAR2(30);
  l_msg_count      NUMBER;
  l_msg_data       VARCHAR2(4000);
  l_total_records  NUMBER := 0;
  l_total_errors   NUMBER := 0;
  l_start_date     DATE   := NULL;
  l_end_date       DATE   := NULL;
  l_start_date_str VARCHAR2(20);
  l_end_date_str   VARCHAR2(20);
  l_sql            VARCHAR2(200);
BEGIN
  fnd_file.put_line (fnd_file.log, ' ****************** BEGIN - code_assignments_correction ****************** ');
  fnd_file.put_line (fnd_file.output, '**************** Failed Records **************** ');
  fnd_file.put_line (fnd_file.output, 'PARTY ID - CLASS CATEGORY - CODE ASSIGNMENT ID ');
  fnd_file.put_line (fnd_file.output, ' ');
  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN
    l_start_date  := TO_DATE(p_start_date,'YYYY/MM/DD HH24:MI:SS');
    l_end_date    := TO_DATE(p_end_date,'YYYY/MM/DD HH24:MI:SS');
  ELSE
    l_start_date_str          := fnd_profile.value('XX_CDH_SEAMLESS_START_DATE');
    l_end_date_str            := fnd_profile.value('XX_CDH_SEAMLESS_END_DATE');
    IF TRIM(l_start_date_str) IS NOT NULL AND TRIM(l_end_date_str) IS NOT NULL THEN
      l_sql                   := 'SELECT ' || l_start_date_str || ' FROM DUAL';
      OPEN date_cur FOR l_sql;
      FETCH date_cur INTO l_start_date;
    CLOSE date_cur;
    l_sql := 'SELECT ' || l_end_date_str || ' FROM DUAL';
    OPEN date_cur FOR l_sql;
    FETCH date_cur INTO l_end_date;
    CLOSE date_cur;
  END IF;
END IF;
fnd_file.put_line (fnd_file.log, 'Start Date: ' || l_start_date);
fnd_file.put_line (fnd_file.log, 'End Date: ' || l_end_date);
-- Open Cursor to Get The Most Recent Class Code Created For A Specific Category and Party
OPEN new_code_assignment ('GDW',l_start_date,l_end_date);
LOOP
  FETCH new_code_assignment BULK COLLECT
  INTO l_new_code_assign_tab LIMIT ln_bulk_limit;
  l_total_records               := l_total_records + l_new_code_assign_tab.COUNT;
  IF l_new_code_assign_tab.COUNT = 0 THEN
    EXIT;
  END IF;
  FOR ln_counter IN l_new_code_assign_tab.FIRST .. l_new_code_assign_tab.LAST
  LOOP
    BEGIN
      l_update_flag := false;
      SAVEPOINT transaction_save;
      /*Open Cursor to Get other class codes within the category and for that party which have to
      become inactive and non primary*/
      OPEN other_code_assignments (l_new_code_assign_tab(ln_counter).code_assignment_id, l_new_code_assign_tab(ln_counter).owner_table_id, l_new_code_assign_tab(ln_counter).class_category );
      LOOP
        FETCH other_code_assignments INTO l_other_code_assign_rec;
        EXIT
      WHEN other_code_assignments%NOTFOUND;
        p_code_assign_rec                          := NULL;
        IF l_other_code_assign_rec.end_date_active IS NULL OR l_other_code_assign_rec.primary_flag = 'Y' THEN
          -- Call Update Class Code Assignment API to Unset Primary
          IF (l_other_code_assign_rec.class_category != 'NAICS_2002' OR (l_other_code_assign_rec.class_category = 'NAICS_2002' AND l_other_code_assign_rec.creation_date != l_new_code_assign_tab(ln_counter).creation_date)) THEN
            p_code_assign_rec.code_assignment_id     := l_other_code_assign_rec.code_assignment_id;
            p_code_assign_rec.primary_flag           := 'N';
            p_code_assign_rec.status                 := 'A';
            p_code_assign_rec.end_date_active        := SYSDATE;
            l_return_status                          := FND_API.G_RET_STS_SUCCESS;
            HZ_CLASSIFICATION_V2PUB.update_code_assignment ( p_init_msg_list => NULL, p_code_assignment_rec => p_code_assign_rec, p_object_version_number => l_other_code_assign_rec.object_version_number, x_return_status => l_return_status, x_msg_count => l_msg_count, x_msg_data => l_msg_data );
            IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
              RAISE UPDATE_ERR;
            END IF;
            l_update_flag := true;
          END IF;
        END IF;
      END LOOP;
      CLOSE other_code_assignments;
      IF l_new_code_assign_tab(ln_counter).class_category = 'CUSTOMER_CATEGORY' THEN
        -- Call Update Class Code Assignment API to Set Primary
        p_code_assign_rec                    := NULL;
        p_code_assign_rec.code_assignment_id := l_new_code_assign_tab(ln_counter).code_assignment_id;
        p_code_assign_rec.primary_flag       := 'Y';
        p_code_assign_rec.status             := 'A';
        p_code_assign_rec.end_date_active    := FND_API.G_MISS_DATE;
        l_return_status                      := FND_API.G_RET_STS_SUCCESS;
        HZ_CLASSIFICATION_V2PUB.update_code_assignment ( p_init_msg_list => NULL, p_code_assignment_rec => p_code_assign_rec, p_object_version_number => l_new_code_assign_tab(ln_counter).object_version_number, x_return_status => l_return_status, x_msg_count => l_msg_count, x_msg_data => l_msg_data );
        IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          RAISE UPDATE_ERR;
        ELSE
          fnd_file.put_line (fnd_file.log,'Successfully Processed : Code Assignment ID  - ' || p_code_assign_rec.code_assignment_id);
        END IF;
      END IF;
    EXCEPTION
    WHEN UPDATE_ERR THEN
      fnd_file.put_line (fnd_file.log,'Update Failed On Code Assignment Id:' || p_code_assign_rec.code_assignment_id);
      fnd_file.put_line (fnd_file.log,'Error - ' || l_msg_data);
      fnd_file.put_line (fnd_file.output, l_new_code_assign_tab(ln_counter).owner_table_id || ' - ' || l_new_code_assign_tab(ln_counter).class_category || ' - ' || l_new_code_assign_tab(ln_counter).code_assignment_id);
      ROLLBACK TO transaction_save;
      IF other_code_assignments%ISOPEN THEN
        CLOSE other_code_assignments;
      END IF;
      l_total_errors := l_total_errors + 1;
    END;
  END LOOP;
  COMMIT;
END LOOP;
fnd_file.put_line (fnd_file.output, '**************** Failed Records **************** ');
fnd_file.put_line(fnd_file.output,'Total Records Read:' || l_total_records);
fnd_file.put_line(fnd_file.output,'Total Erros:' || l_total_errors);
fnd_file.put_line (fnd_file.log, ' ****************** END - code_assignments_correction ****************** ');
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure code_assignments_correction - Error - '||SQLERRM);
  x_errbuf  := 'Unexpected Error in procedure code_assignments_correction - Error - '||SQLERRM;
  x_retcode := 2;
END code_assignments_correction;
END XX_CDH_CLASS_CODE_CORRECTION;
/
SHOW ERRORS;
