create or replace
PACKAGE xx_fin_translate_pkg
AS
      /*******************************************************************************
      NAME:       XXFIN_TRANSLATE_PKG
      PURPOSE:     To retrieve target values from ORacle for the given source values.

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2/21/2007    Shankar Murthy  1. Created this package.
      1.1        3/14/2007    Shankar Murthy  1. Modified this package to meet the build standards.
      1.2        2/26/2009    Bushrod Thomas  2. Added NOCOPY to OUT parameters 
   ******************************************************************************/
   PROCEDURE xx_fin_translatevalue_proc(
      p_translation_name   IN       VARCHAR2 DEFAULT NULL,
      p_trx_date           IN       DATE DEFAULT SYSDATE,
      p_source_value1      IN       VARCHAR2 DEFAULT NULL,
      p_source_value2      IN       VARCHAR2 DEFAULT NULL,
      p_source_value3      IN       VARCHAR2 DEFAULT NULL,
      p_source_value4      IN       VARCHAR2 DEFAULT NULL,
      p_source_value5      IN       VARCHAR2 DEFAULT NULL,
      p_source_value6      IN       VARCHAR2 DEFAULT NULL,
      p_source_value7      IN       VARCHAR2 DEFAULT NULL,
      p_source_value8      IN       VARCHAR2 DEFAULT NULL,
      p_source_value9      IN       VARCHAR2 DEFAULT NULL,
      p_source_value10     IN       VARCHAR2 DEFAULT NULL,
      x_target_value1      OUT      NOCOPY VARCHAR2,
      x_target_value2      OUT      NOCOPY VARCHAR2,
      x_target_value3      OUT      NOCOPY VARCHAR2,
      x_target_value4      OUT      NOCOPY VARCHAR2,
      x_target_value5      OUT      NOCOPY VARCHAR2,
      x_target_value6      OUT      NOCOPY VARCHAR2,
      x_target_value7      OUT      NOCOPY VARCHAR2,
      x_target_value8      OUT      NOCOPY VARCHAR2,
      x_target_value9      OUT      NOCOPY VARCHAR2,
      x_target_value10     OUT      NOCOPY VARCHAR2,
      x_target_value11     OUT      NOCOPY VARCHAR2,
      x_target_value12     OUT      NOCOPY VARCHAR2,
      x_target_value13     OUT      NOCOPY VARCHAR2,
      x_target_value14     OUT      NOCOPY VARCHAR2,
      x_target_value15     OUT      NOCOPY VARCHAR2,
      x_target_value16     OUT      NOCOPY VARCHAR2,
      x_target_value17     OUT      NOCOPY VARCHAR2,
      x_target_value18     OUT      NOCOPY VARCHAR2,
      x_target_value19     OUT      NOCOPY VARCHAR2,
      x_target_value20     OUT      NOCOPY VARCHAR2,
      x_error_message      OUT      NOCOPY VARCHAR2
   );
END xx_fin_translate_pkg;
/
