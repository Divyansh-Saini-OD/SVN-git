--- CONTROL_YR should be mapped

DECLARE

l_attr_grp_id            NUMBER;
l_batch_id               NUMBER;
l_commit_flag            VARCHAR2(2);

BEGIN

l_batch_id        :=  &Ebs_Batch_Id;
l_commit_flag     := '&Commit';


SELECT fl_ctx_ext.attr_group_id attr_group_id INTO l_attr_grp_id
FROM APPS.fnd_descr_flex_contexts fl_ctx, APPS.ego_fnd_dsc_flx_ctx_ext fl_ctx_ext
WHERE  fl_ctx.application_id = fl_ctx_ext.application_id
AND fl_ctx.descriptive_flexfield_name = fl_ctx_ext.descriptive_flexfield_name
AND fl_ctx.descriptive_flex_context_code = fl_ctx_ext.descriptive_flex_context_code
AND fl_ctx.descriptive_flex_context_code LIKE 'BILLDOCS'
AND fl_ctx.DESCRIPTIVE_FLEXFIELD_NAME='XX_CDH_CUST_ACCOUNT';


-- Deleting Rows From XX_CDH_CUST_ACCT_EXT_B

DELETE FROM apps.xx_cdh_cust_acct_ext_b
WHERE attr_group_id = l_attr_grp_id
AND cust_account_id IN
(
SELECT cust_account_id FROM
hz_imp_parties_int p, hz_cust_accounts a
WHERE batch_id = l_batch_id
AND p.control_yr = a.account_number
);

DBMS_OUTPUT.PUT_LINE ('Rows Deleted In ''XX_CDH_CUST_ACCT_EXT_B'' : ' || SQL%ROWCOUNT);


-- Deleting Rows From XX_CDH_CUST_ACCT_EXT_TL

DELETE FROM apps.xx_cdh_cust_acct_ext_tl
WHERE attr_group_id = l_attr_grp_id
AND cust_account_id IN
(
SELECT cust_account_id FROM
hz_imp_parties_int p, hz_cust_accounts a
WHERE batch_id = l_batch_id
AND p.control_yr = a.account_number
);

DBMS_OUTPUT.PUT_LINE ('Rows Deleted In ''XX_CDH_CUST_ACCT_EXT_TL'' : ' || SQL%ROWCOUNT);


IF upper(l_commit_flag) = 'Y' THEN
  COMMIT;
ELSE
  ROLLBACK;
END IF;

EXCEPTION WHEN OTHERS THEN
 
 DBMS_OUTPUT.PUT_LINE ('Unexpected Error: ' || SQLERRM);

END;