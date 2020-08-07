SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CM_TRACK_LOG_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name : XX_CM_TRACK_LOG_PKG                                             |
-- | RICE ID :  R0472                                                       |
-- | Description : This package is derives the card type based              |
-- |                                                                        |
-- |               on the provider code.                                    |
-- | Change Record:                                                         |
-- |===============                                                         |
-- |Version   Date              Author              Remarks                 |
-- |======   ==========     =============        ===========================|
-- |DRAFT 1A  05-DEC-08     Ganesan JV           Initial Version            |
-- |DRAFT 1B  26-DEC-08     Manovinayak A        Initial Version            |
-- +DRAFT 1C  25-MAY-09     Usha Ramachandran    Changed as per defect1246  |
-- |1.0       18-JUN-10     RamyaPriya M         Modified for Defect#1061   |
--==========================================================================+
-- +=====================================================================+
-- | Name :  get_card_type                                               |
-- | Parameters :p_processor_id,p_ajb_file_name,p_provider_type,p_card_number
-- | Description : This function will derive and return the card type if |
-- |               it is not present in the xx_ce_ajb996 and xx_ce_ajb998
-- | Returns :  card type                                                |
-- +=====================================================================+
  FUNCTION get_card_type(p_processor_id  VARCHAR2
                        ,p_ajb_file_name VARCHAR2
                        ,p_provider_type VARCHAR2
                        ,p_card_number VARCHAR2)
  RETURN VARCHAR2
  IS
  lc_card_type     VARCHAR2(80)  := NULL;
  lc_ajb_file_name VARCHAR2(200) := NULL;
  lc_provider_type VARCHAR2(50)  := NULL;
  ln_org_id        NUMBER        := FND_PROFILE.VALUE('ORG_ID');
  BEGIN
    IF p_processor_id = 'CCSCRD' THEN
      lc_ajb_file_name := p_ajb_file_name;
    END IF;
    IF (p_processor_id = 'MPSCRD' AND p_provider_type = 'DEBIT' ) THEN
        lc_provider_type := p_provider_type;
    ELSIF (p_processor_id = 'TELCHK' AND p_provider_type = 'CHECK') THEN
        lc_provider_type := p_provider_type;
       END IF;
    IF lc_ajb_file_name IS NOT NULL THEN
       SELECT XFV.target_value1
       INTO   lc_card_type
       FROM   xx_fin_translatedefinition XFT
             ,xx_fin_translatevalues     XFV
       WHERE  XFT.translate_id     = XFV.translate_id
       AND    XFT.translation_name = 'XX_CE_AJB_CARD_TYPE'
       AND    XFV.source_value1    = p_processor_id
       AND    NVL(XFV.end_date_active,sysdate) >= sysdate
       AND    XFV.ENABLED_FLAG='Y'
       AND    lc_ajb_file_name       LIKE '%'|| XFV.source_value2 ||'%';
       RETURN lc_card_type;
    END IF;
    IF    (p_processor_id = 'AMX3RD') THEN
       SELECT XFV.target_value1
       INTO   lc_card_type
       FROM   xx_fin_translatedefinition XFT
             ,xx_fin_translatevalues     XFV
       WHERE  XFT.translate_id          = XFV.translate_id
       AND    XFT.translation_name      = 'XX_CE_AJB_CARD_TYPE'
       AND    XFV.source_value1         = p_processor_id
       AND    NVL(XFV.end_date_active,sysdate) >= sysdate
       AND    XFV.ENABLED_FLAG='Y';
       RETURN lc_card_type;
    END IF;
      IF (p_processor_id IN('MPSCRD','DCV3RN') AND p_provider_type = 'CREDIT' ) THEN
       SELECT XFV.target_value1
       INTO   lc_card_type
       FROM   xx_fin_translatedefinition XFT
             ,xx_fin_translatevalues     XFV
       WHERE  XFT.translate_id          = XFV.translate_id
       AND    XFT.translation_name      = 'XX_CE_AJB_CARD_TYPE'
       AND    XFV.source_value1         = p_processor_id
       AND    NVL(XFV.end_date_active,sysdate) >= sysdate
       AND    XFV.ENABLED_FLAG='Y'
       AND    NVL(XFV.source_value3,'X') = p_card_number;
       RETURN lc_card_type;
       END IF;
       IF (p_processor_id = 'MPSCRD' AND p_provider_type = 'DEBIT' ) THEN
       SELECT XFV.target_value1
       INTO   lc_card_type
       FROM   xx_fin_translatedefinition XFT
             ,xx_fin_translatevalues     XFV
       WHERE  XFT.translate_id          = XFV.translate_id
       AND    XFT.translation_name      = 'XX_CE_AJB_CARD_TYPE'
       AND    XFV.source_value1         = p_processor_id
       AND    NVL(XFV.end_date_active,sysdate) >= sysdate
       AND    XFV.ENABLED_FLAG='Y'
       AND    NVL(lc_provider_type,'X') = NVL(XFV.source_value2,'X');
       RETURN lc_card_type;
       END IF;
       IF (p_processor_id = 'NABCRD' AND p_provider_type = 'CREDIT' ) THEN
       SELECT XFV.target_value1
       INTO   lc_card_type
       FROM   xx_fin_translatedefinition XFT
             ,xx_fin_translatevalues     XFV
       WHERE  XFT.translate_id          = XFV.translate_id
       AND    XFT.translation_name      = 'XX_CE_AJB_CARD_TYPE'
       AND    XFV.source_value1         = p_processor_id
       AND    NVL(XFV.source_value3,'X') = p_card_number
       AND    NVL(XFV.end_date_active,sysdate) >= sysdate
       AND    XFV.ENABLED_FLAG='Y';
       RETURN lc_card_type;
       END IF;
	IF (p_processor_id = 'TELCHK' AND p_provider_type = 'CHECK' ) THEN
       SELECT XFV.target_value1
       INTO   lc_card_type
       FROM   xx_fin_translatedefinition XFT
             ,xx_fin_translatevalues     XFV
       WHERE  XFT.translate_id          = XFV.translate_id
       AND    XFT.translation_name      = 'XX_CE_AJB_CARD_TYPE'
       AND    XFV.source_value1         = p_processor_id
       AND    XFV.source_value4         = ln_org_id        --Added for Defect #1061
       AND    NVL(XFV.end_date_active,sysdate) >= sysdate
       AND    XFV.ENABLED_FLAG='Y'
       AND    NVL(lc_provider_type,'X') = NVL(XFV.source_value2,'X');
       RETURN lc_card_type;
       END IF;
      RETURN NULL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       lc_card_type := NULL;
       RETURN lc_card_type;
    WHEN OTHERS THEN
       lc_card_type := NULL;
       RETURN lc_card_type;
  END get_card_type;
END xx_cm_track_log_pkg;
/
SHOW ERROR
