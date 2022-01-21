SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE BODY XX_GL_COGS_REP_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- |Name             : XX_GL_COGS_REP_PKG.pkb                          |
-- |Rice Id          : R0493_InTransitOrders                           |
-- |                                                                   |
-- |Description      :  This PKG will be used to fetch COGS and        |
-- |                    Liability Account and Amount                   |
-- |Change Record    :                                                 |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      26-SEP-2008  Maha             Initial draft version       |
-- |                                                                   |
-- |1.1      16-OCT-2008  Trisha Saxena	   Added a function for        |
-- |                                        Liability account          |
-- |1.2      29-JUL-2013  Darshini         R0493 - Modified for R12    | 
-- |                                       Upgrade Retrofit            |
-- |1.3      30-May-16    Madhan Sanjeevi  Defect# 37959               |
-- +===================================================================+
AS
-- +===================================================================+

-- | Name             : XX_DERIVE_COGS_ACC                             |

-- | Description      : Function to return the COGS account            |

-- | Parameters       : p_dist_id,  p_set_of_books_id                  |

-- | Returns          : COGS account                                   |

-- +===================================================================+

FUNCTION XX_DERIVE_COGS_ACC(p_dist_id IN NUMBER,P_SET_OF_BOOKS_ID IN NUMBER)
 RETURN VARCHAR2
 IS
 flag NUMBER;
 lc_ccid VARCHAR2(500);

 BEGIN

 SELECT XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(DECODE(sign(ral.revenue_amount),
                           -1,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4),glc.segment4,SUBSTR(hou.name,1,6))
                           ,glc.segment4))||'.'
                 || DECODE(SUBSTR(DECODE(sign(ral.revenue_amount),- 1,DECODE(TRIM(rad.attribute10),NULL,trim(rad.attribute8),trim(rad.attribute10))
                                ,trim(rad.attribute7)),1,1)
                               ,'1','00000'
                               ,'2','00000'
                               ,'3','00000'
                               ,'4','00000'
                               ,'5','00000'
                               ,glc.segment2)||'.'
                || DECODE(sign(ral.revenue_amount),- 1,DECODE(TRIM(rad.attribute10), NULL,trim(rad.attribute8),trim(rad.attribute10))
                              ,trim(rad.attribute7))||'.'
                || DECODE(sign(ral.revenue_amount),
                       -1,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4),glc.segment4,SUBSTR(hou.name,1,6))
                       ,glc.segment4)||'.'
                || glc.segment5 ||'.'
                || DECODE((DECODE(sign(ral.revenue_amount),- 1,DECODE(TRIM(rad.attribute10), NULL,trim(rad.attribute8)
                                        ,trim(rad.attribute10)),trim(rad.attribute7)))
                      ,trim(rad.attribute8),(XX_GL_COGS_INT_MASTER_PKG.XX_DERIVE_LOB_TEST(DECODE(sign(ral.revenue_amount),-1
                                                        ,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4)
                                                        ,glc.segment4,SUBSTR(hou.name,1,6)),glc.segment4)))
                                        ,trim(rad.attribute7),glc.segment6
                     ,trim(rad.attribute10),(XX_GL_COGS_INT_MASTER_PKG.XX_DERIVE_LOB_TEST(DECODE(sign(ral.revenue_amount),-1
                                                        ,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4)
                                                        ,glc.segment4,SUBSTR(hou.name,1,6)),glc.segment4))))||'.'
              ||glc.segment7  
 INTO lc_ccid
 FROM  ra_customer_trx_all rta
       ,ra_cust_trx_line_gl_dist_all rad
       ,ra_customer_trx_lines_all ral
       ,gl_code_combinations glc
	   -- Commented and added by Darshini(1.2) for R12 Upgrade Retrofit
       --,gl_sets_of_books gls
	   ,gl_ledgers gl
	   -- end of addition
       ,hr_organization_units hou
 WHERE  rad.account_class = 'REV'
  AND  rad.attribute_category = 'SALES_ACCT'
  AND  rad.attribute6 IN ('Y','N') -- Modified for Defect# 37959
  AND rad.cust_trx_line_gl_dist_id=p_dist_id
  AND  rad.gl_posted_date IS NOT NULL
  AND  rad.set_of_books_id = p_set_of_books_id
  AND  ral.customer_trx_line_id = rad.customer_trx_line_id
  AND  rta.trx_number=ral.sales_order
-- Commented and Added by Darshini(1,2) for R12 Upgrade Retrofit  
--  AND  gls.set_of_books_id = rad.set_of_books_id
  AND  gl.ledger_id = rad.set_of_books_id
-- end of addition  
  AND  glc.code_combination_id = rad.code_combination_id
  AND  hou.organization_id(+) = ral.warehouse_id;

 RETURN lc_ccid;
 EXCEPTION
          WHEN NO_DATA_FOUND THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'No sign for revenue amount found:'
				                    || SQLERRM );
 RETURN NULL;
          WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Other error while fetching the sign of revenue amount:'
				                    || SQLERRM );
 RETURN NULL;
END XX_DERIVE_COGS_ACC;

-- +===================================================================+

-- | Name             : XX_DERIVE_LIABILITY_ACC                        |

-- | Description      : Function to return the Liability account       |

-- | Parameters       : p_dist_id,  p_set_of_books_id                  |

-- | Returns          : Liability account                              |

-- +===================================================================+
FUNCTION XX_DERIVE_LIABILITY_ACC(p_dist_id IN NUMBER,P_SET_OF_BOOKS_ID IN NUMBER)
 RETURN VARCHAR2
 IS
 flag NUMBER;
 lc_ccid VARCHAR2(500);

 BEGIN

 SELECT XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(DECODE(sign(ral.revenue_amount),
                      - 1,glc.segment4,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4),glc.segment4,
                                              nvl(SUBSTR(hou.name,1,6),glc.segment4))))||'.'
                 || DECODE(SUBSTR(DECODE(sign(ral.revenue_amount),- 1,trim(rad.attribute7),
                               DECODE(TRIM(rad.attribute10), NULL,trim(rad.attribute8),trim(rad.attribute10))),1,1)
                               ,'1','00000'
                               ,'2','00000'
                               ,'3','00000'
                               ,'4','00000'
                               ,'5','00000'
                               ,glc.segment2)||'.'
                 || DECODE(sign(ral.revenue_amount),- 1,trim(rad.attribute7),
                               DECODE(TRIM(rad.attribute10), NULL,trim(rad.attribute8),trim(rad.attribute10)))||'.'
                 || DECODE(sign(ral.revenue_amount),
                     - 1,glc.segment4,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4),glc.segment4,
                                             nvl(SUBSTR(hou.name,1,6),glc.segment4)))||'.'
                 || glc.segment5  ||'.'
                 || DECODE((DECODE(sign(ral.revenue_amount),- 1,trim(rad.attribute7),
                            DECODE(TRIM(rad.attribute10), NULL,trim(rad.attribute8),trim(rad.attribute10))))
                                   ,trim(rad.attribute8),(XX_GL_COGS_INT_MASTER_PKG.XX_DERIVE_LOB_TEST(DECODE(sign(ral.revenue_amount),- 1
                                                   ,glc.segment4,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4)
                                                   ,glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4)))))
                                   ,trim(rad.attribute7),glc.segment6
                                   ,trim(rad.attribute10),(XX_GL_COGS_INT_MASTER_PKG.XX_DERIVE_LOB_TEST(DECODE(sign(ral.revenue_amount),-1
                                                   ,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4)
                                                   ,glc.segment4,SUBSTR(hou.name,1,6)),glc.segment4))))||'.'
                 || glc.segment7 
 INTO lc_ccid
 FROM  ra_customer_trx_all rta
       ,ra_cust_trx_line_gl_dist_all rad
       ,ra_customer_trx_lines_all ral
       ,gl_code_combinations glc
	   --Commented and added by Darshini(1.2) for R12 Upgrade Retrofit
       --,gl_sets_of_books gls
	   ,gl_ledgers gl
	   --end of addition
       ,hr_organization_units hou
 WHERE  rad.account_class = 'REV'
  AND  rad.attribute_category = 'SALES_ACCT'
  AND  rad.attribute6 IN ('Y','N') -- Modified for Defect# 37959
  AND rad.cust_trx_line_gl_dist_id=p_dist_id
  AND  rad.gl_posted_date IS NOT NULL
  AND  rad.set_of_books_id = p_set_of_books_id
  AND  ral.customer_trx_line_id = rad.customer_trx_line_id
  AND  rta.trx_number=ral.sales_order
  --Commented and added by Darshini(1.2) for R12 Upgrade Retrofit
  --AND  gls.set_of_books_id = rad.set_of_books_id
  AND gl.ledger_id = rad.set_of_books_id
  --end of addition
  AND  glc.code_combination_id = rad.code_combination_id
  AND  hou.organization_id(+) = ral.warehouse_id;

 RETURN lc_ccid;
 EXCEPTION
          WHEN NO_DATA_FOUND THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'No sign for revenue amount found:'
				                    || SQLERRM );
 RETURN NULL;
          WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Other error while fetching the sign of revenue amount:'
				                    || SQLERRM );
 RETURN NULL;
END XX_DERIVE_LIABILITY_ACC;

-- +===================================================================+

-- | Name             : XX_DERIVE_COGS_AMOUNT                          |

-- | Description      : Function to return the COGS amount             |

-- | Parameters       : p_dist_id                                      |

-- | Returns          : COGS amount                                    |

-- +===================================================================+

FUNCTION XX_DERIVE_COGS_AMOUNT(p_dist_id IN NUMBER)
RETURN NUMBER
IS
ln_amt NUMBER;

BEGIN
SELECT ABS(ROUND(DECODE(to_number(nvl(trim(rad.attribute9),'0')) * ral.quantity_invoiced, NULL
                 ,to_number(nvl(trim(rad.attribute9),'0')) * ral.quantity_credited
                 ,to_number(nvl(trim(rad.attribute9),'0')) * ral.quantity_invoiced),2))
INTO ln_amt
FROM ra_cust_trx_line_gl_dist_all rad
     ,ra_customer_trx_lines_all ral
WHERE rad.cust_trx_line_gl_dist_id=p_dist_id 
 AND rad.account_class = 'REV'
 AND  rad.attribute_category = 'SALES_ACCT'
 AND  rad.attribute6 IN ('Y','N') -- Modified for Defect# 37959
 AND rad.gl_posted_date IS NOT NULL
 AND ral.customer_trx_line_id = rad.customer_trx_line_id;
RETURN(ln_amt);
 EXCEPTION
        WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'COGS amount not fetched:'
				                    || SQLERRM );
  RETURN 0;
        WHEN OTHERS   THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Other error while fetching the COGS AMount :'
                                      || SQLERRM );
  RETURN 0;
END XX_DERIVE_COGS_AMOUNT;
END XX_GL_COGS_REP_PKG;
/
SHOW ERROR
/