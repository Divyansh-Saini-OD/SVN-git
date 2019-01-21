CREATE OR REPLACE PACKAGE APPS.xx_fin_translate_pkg
AS
      /******************************************************************************
      NAME:       XXFIN_TRANSLATE_PKG
      PURPOSE:     To retrieve target values from ORacle for the given source values.

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2/21/2007    Shankar Murthy  1. Created this package.
      1.1        3/14/2007    Shankar Murthy   1. Modified this package to meet the build standards.
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
      x_target_value1      OUT      VARCHAR2,
      x_target_value2      OUT      VARCHAR2,
      x_target_value3      OUT      VARCHAR2,
      x_target_value4      OUT      VARCHAR2,
      x_target_value5      OUT      VARCHAR2,
      x_target_value6      OUT      VARCHAR2,
      x_target_value7      OUT      VARCHAR2,
      x_target_value8      OUT      VARCHAR2,
      x_target_value9      OUT      VARCHAR2,
      x_target_value10     OUT      VARCHAR2,
      x_target_value11     OUT      VARCHAR2,
      x_target_value12     OUT      VARCHAR2,
      x_target_value13     OUT      VARCHAR2,
      x_target_value14     OUT      VARCHAR2,
      x_target_value15     OUT      VARCHAR2,
      x_target_value16     OUT      VARCHAR2,
      x_target_value17     OUT      VARCHAR2,
      x_target_value18     OUT      VARCHAR2,
      x_target_value19     OUT      VARCHAR2,
      x_target_value20     OUT      VARCHAR2,
      x_error_message      OUT      VARCHAR2
   );
END xx_fin_translate_pkg;
/

CREATE OR REPLACE PACKAGE BODY APPS.xx_fin_translate_pkg
AS
      /******************************************************************************
      NAME:       XXFIN_TRANSLATE_MAPPING_PKG
      PURPOSE:     To retrieve target values from ORacle for the given source values.

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2/21/2007    Shankar Murthy  1. Created this package body.
      1.1        3/15/2007    Shankar Murthy  2. Modified to exclude certain validations.
   ******************************************************************************/
   PROCEDURE xx_fin_translatevalue_proc (
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
      x_target_value1      OUT      VARCHAR2,
      x_target_value2      OUT      VARCHAR2,
      x_target_value3      OUT      VARCHAR2,
      x_target_value4      OUT      VARCHAR2,
      x_target_value5      OUT      VARCHAR2,
      x_target_value6      OUT      VARCHAR2,
      x_target_value7      OUT      VARCHAR2,
      x_target_value8      OUT      VARCHAR2,
      x_target_value9      OUT      VARCHAR2,
      x_target_value10     OUT      VARCHAR2,
      x_target_value11     OUT      VARCHAR2,
      x_target_value12     OUT      VARCHAR2,
      x_target_value13     OUT      VARCHAR2,
      x_target_value14     OUT      VARCHAR2,
      x_target_value15     OUT      VARCHAR2,
      x_target_value16     OUT      VARCHAR2,
      x_target_value17     OUT      VARCHAR2,
      x_target_value18     OUT      VARCHAR2,
      x_target_value19     OUT      VARCHAR2,
      x_target_value20     OUT      VARCHAR2,
      x_error_message      OUT      VARCHAR2
   )
   IS
      v_translate_id   xx_fin_translatedefinition.translate_id%TYPE;
   BEGIN
      DBMS_OUTPUT.ENABLE (1000000);

      --dbms_output.put_line('coming here1');

      --Lookup the translation ID
      SELECT translate_id
        INTO v_translate_id
        FROM xx_fin_translatedefinition
       WHERE translation_name = p_translation_name
         AND enabled_flag = 'Y'
         AND (    start_date_active <= p_trx_date
              AND (end_date_active >= p_trx_date OR end_date_active IS NULL)
             );

      --Translation is fine, retrieve the target values.
      BEGIN
         SELECT target_value1, target_value2, target_value3,
                target_value4, target_value5, target_value6,
                target_value7, target_value8, target_value9,
                target_value10, target_value11, target_value12,
                target_value13, target_value14, target_value15,
                target_value16, target_value17, target_value18,
                target_value19, target_value20
           INTO x_target_value1, x_target_value2, x_target_value3,
                x_target_value4, x_target_value5, x_target_value6,
                x_target_value7, x_target_value8, x_target_value9,
                x_target_value10, x_target_value11, x_target_value12,
                x_target_value13, x_target_value14, x_target_value15,
                x_target_value16, x_target_value17, x_target_value18,
                x_target_value19, x_target_value20
           FROM xx_fin_translatevalues
          WHERE translate_id = v_translate_id
            AND source_value1 = p_source_value1
            AND (source_value2 = p_source_value2 OR p_source_value2 IS NULL)
            AND (source_value3 = p_source_value3 OR p_source_value3 IS NULL)
            AND (source_value4 = p_source_value4 OR p_source_value4 IS NULL)
            AND (source_value5 = p_source_value5 OR p_source_value5 IS NULL)
            AND (source_value6 = p_source_value6 OR p_source_value6 IS NULL)
            AND (source_value7 = p_source_value7 OR p_source_value7 IS NULL)
            AND (source_value8 = p_source_value8 OR p_source_value8 IS NULL)
            AND (source_value9 = p_source_value9 OR p_source_value9 IS NULL)
            AND (source_value10 = p_source_value10 OR p_source_value10 IS NULL
                )
            AND enabled_flag = 'Y'
            AND (    start_date_active <= p_trx_date
                 AND (end_date_active >= p_trx_date OR end_date_active IS NULL
                     )
                );
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            x_error_message :=
               'There are no effective target values for this translation and transaction date.';
         WHEN OTHERS
         THEN
            x_error_message :=
                  'Unhandled exception '
               || SQLERRM
               || ' raised in xxfin_translate_pkg - target.';
      END ;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_error_message :=
               'There is no effective translation definition for '
            || p_translation_name
            || ' and transaction date '
            || p_trx_date
            || '.';
      WHEN OTHERS
      THEN
         x_error_message :=
               'Unhandled exception '
            || SQLERRM
            || ' raised in xxfin_translate_pkg - definition.';
   END xx_fin_translatevalue_proc;
END xx_fin_translate_pkg;
/