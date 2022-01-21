CREATE OR REPLACE
PACKAGE BODY XX_ICX_CAT_ATTS_PKG AS

  PROCEDURE INSERT_ROW (
    p_org_id      IN NUMBER
   ,p_category_id IN NUMBER
   ,p_buyer_id    IN NUMBER
   ,p_approver_id IN NUMBER
   ,p_user_id     IN NUMBER := NULL
   ,p_login_id    IN NUMBER := NULL
  )
  IS
  BEGIN
    INSERT INTO XX_ICX_CAT_ATTS_BY_ORG (
       org_id
      ,category_id
      ,buyer_id
      ,approver_id
      ,last_update_date
      ,creation_date
      ,created_by
      ,last_updated_by
      ,last_update_login
    ) VALUES (
       p_org_id
      ,p_category_id
      ,p_buyer_id
      ,p_approver_id
      ,SYSDATE
      ,SYSDATE
      ,p_user_id
      ,p_user_id
      ,p_login_id
    );

    IF (SQL%NOTFOUND) THEN
      RAISE NO_DATA_FOUND;
    ELSE
      COMMIT;
    END IF;
  END INSERT_ROW;



  PROCEDURE UPDATE_ROW (
    p_org_id      IN NUMBER
   ,p_category_id IN NUMBER
   ,p_buyer_id    IN NUMBER
   ,p_approver_id IN NUMBER
   ,p_user_id     IN NUMBER := NULL
   ,p_login_id    IN NUMBER := NULL
  ) 
  IS
  BEGIN
    UPDATE XX_ICX_CAT_ATTS_BY_ORG 
    SET    buyer_id          = p_buyer_id
          ,approver_id       = p_approver_id
          ,last_update_date  = SYSDATE
          ,last_updated_by   = p_user_id
          ,last_update_login = p_login_id
    WHERE  category_id       = p_category_id
    AND    org_id            = p_org_id;

    IF (SQL%NOTFOUND) THEN
      RAISE NO_DATA_FOUND;
    ELSE
      COMMIT;
    END IF;
  END UPDATE_ROW;


  PROCEDURE DELETE_ROW (
    p_org_id      IN NUMBER
   ,p_category_id IN NUMBER
  ) 
  IS
  BEGIN
    DELETE 
    FROM  XX_ICX_CAT_ATTS_BY_ORG
    WHERE org_id      = p_org_id
    AND   category_id = p_category_id;

    IF (SQL%NOTFOUND) THEN
      RAISE NO_DATA_FOUND;
    ELSE
      COMMIT;
    END IF;
  END DELETE_ROW;



  PROCEDURE LOAD_ROW(
    p_org_id      IN NUMBER
   ,p_category_id IN NUMBER
   ,p_buyer_id    IN NUMBER
   ,p_approver_id IN NUMBER
   ,p_user_id     IN NUMBER := NULL
   ,p_login_id    IN NUMBER := NULL
  )
  IS
  BEGIN
    XX_ICX_CAT_ATTS_PKG.UPDATE_ROW (   
       p_org_id        => p_org_id
      ,p_category_id   => p_category_id
      ,p_buyer_id      => p_buyer_id
      ,p_approver_id   => p_approver_id
      ,p_user_id       => p_user_id
      ,p_login_id      => p_login_id);

    EXCEPTION WHEN NO_DATA_FOUND THEN
      XX_ICX_CAT_ATTS_PKG.INSERT_ROW (
         p_org_id      => p_org_id
        ,p_category_id => p_category_id
        ,p_buyer_id    => p_buyer_id
        ,p_approver_id => p_approver_id
        ,p_user_id     => p_user_id
        ,p_login_id    => p_login_id);
  END LOAD_ROW;


  PROCEDURE LOAD_ROW(
    p_org_id        IN NUMBER
   ,p_category_id   IN NUMBER
   ,p_buyer_name    IN VARCHAR2
   ,p_approver_name IN VARCHAR2
   ,p_user_id       IN NUMBER := NULL
   ,p_login_id      IN NUMBER := NULL
  )
  IS
    ln_buyer_id        NUMBER := NULL;
    ln_approver_id     NUMBER := NULL;
  BEGIN
    GET_PERSON_ID(p_buyer_name,   ln_buyer_id);
    GET_PERSON_ID(p_approver_name,ln_approver_id);

    XX_ICX_CAT_ATTS_PKG.UPDATE_ROW (
       p_org_id        => p_org_id
      ,p_category_id   => p_category_id
      ,p_buyer_id      => ln_buyer_id
      ,p_approver_id   => ln_approver_id
      ,p_user_id       => p_user_id
      ,p_login_id      => p_login_id
    );

    EXCEPTION WHEN NO_DATA_FOUND THEN
      XX_ICX_CAT_ATTS_PKG.INSERT_ROW (
	 p_org_id        => p_org_id
	,p_category_id   => p_category_id
	,p_buyer_id      => ln_buyer_id
	,p_approver_id   => ln_approver_id
        ,p_user_id       => p_user_id
        ,p_login_id      => p_login_id
      );
  END LOAD_ROW;


  PROCEDURE GET_PERSON_ID (
    p_employee_number_or_full_name IN     VARCHAR2
   ,x_person_id                    IN OUT VARCHAR2
  ) 
  IS
    lc_find VARCHAR2(240) := UPPER(TRIM(p_employee_number_or_full_name));
  BEGIN
    IF NOT lc_find IS NULL THEN
       SELECT PER_ALL_PEOPLE_F.person_id
       INTO   x_person_id
       FROM   PER_ALL_PEOPLE_F
       WHERE  employee_number=lc_find
       AND    current_employee_flag='Y' 
       AND    effective_start_date<=SYSDATE 
       AND    effective_end_date>=SYSDATE
       AND    rownum=1;
    END IF;

    EXCEPTION WHEN NO_DATA_FOUND THEN
       SELECT PER_ALL_PEOPLE_F.person_id 
       INTO   x_person_id 
       FROM   PER_ALL_PEOPLE_F
       WHERE  UPPER(full_name)=lc_find
       AND    current_employee_flag='Y' 
       AND    effective_start_date<=SYSDATE 
       AND    effective_end_date>=SYSDATE
       AND    rownum=1;
  END GET_PERSON_ID;


END XX_ICX_CAT_ATTS_PKG;

/
