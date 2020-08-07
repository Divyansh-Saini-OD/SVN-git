SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
FUNCTION xx_om_fraud_condition_name(p_hold_source_id IN NUMBER)
   RETURN VARCHAR2
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                                                                     |
-- +=====================================================================+
-- | Name  : XX_OM_FRAUD_CONDITION_NAME                                                 |
-- | RiceID: I1285_FraudPool                                             |
-- | Description      : This function is used in building view           |
-- |                    XX_OM_OFP_V for fraud pools.  This function will |
-- |                    return the Fraud Condition Name                  |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version    Date          Author           Remarks                    |
-- |=======    ==========    =============    ========================   |
-- |DRAFT 1A   21-AUG-2007   Dedra Maloy      Initial draft version      |
-- |                                                                     |
-- +=====================================================================+   
IS
ln_cnt               NUMBER := 0;
ln_max_cnt           NUMBER := 0;
lc_hold_comment      VARCHAR2(250);
ln_comma_cnt         NUMBER := 0;
lc_hold              VARCHAR2(250);
lc_hold_comment_name VARCHAR2(250);
BEGIN
   BEGIN
      SELECT nvl(instr(hold_comment,   ',',   -1),   0)
      INTO ln_max_cnt
      FROM oe_hold_sources_all
      WHERE hold_source_id = p_hold_source_id;
   EXCEPTION
   WHEN others THEN
      DBMS_OUTPUT.PUT_LINE('Select failed on search for comma ' || p_hold_source_id);
   END;
   IF ln_max_cnt > 0 THEN
      LOOP
         ln_cnt := ln_comma_cnt + 1;
         BEGIN
            SELECT instr(hold_comment,   ',',   ln_cnt)
            INTO ln_comma_cnt
            FROM oe_hold_sources_all
            WHERE hold_source_id = p_hold_source_id;
         EXCEPTION
            WHEN others THEN
               DBMS_OUTPUT.PUT_LINE('Select failed on search for comma ' || p_hold_source_id);
         END;
         BEGIN
            SELECT SUBSTR(hold_comment,ln_cnt,decode
                   (ln_comma_cnt,0,999999,ln_comma_cnt) -ln_cnt)
            INTO lc_hold
            FROM oe_hold_sources_all
            WHERE hold_source_id = p_hold_source_id;
         EXCEPTION
            WHEN others THEN
               DBMS_OUTPUT.PUT_LINE('Select failed while searching comment ' ||p_hold_source_id);
         END;
         BEGIN
            SELECT condition_name
            INTO lc_hold_comment_name
            FROM xx_om_fraud_rules_stg
            WHERE condition_id = lc_hold;
         EXCEPTION
            WHEN others THEN
               DBMS_OUTPUT.PUT_LINE('Select failed on search for condition_name ' ||p_hold_source_id);
         END;
         IF lc_hold_comment IS NOT NULL THEN
            lc_hold_comment := lc_hold_comment || ',' || 
            lc_hold_comment_name;
         ELSE
            lc_hold_comment := lc_hold_comment_name;
         END IF;
      EXIT
      WHEN ln_cnt > ln_max_cnt;
   END LOOP;
   RETURN lc_hold_comment;
ELSE
   RETURN NULL;
END IF;
END;

/
EXIT