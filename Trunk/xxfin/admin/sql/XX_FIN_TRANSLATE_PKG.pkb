create or replace
PACKAGE BODY xx_fin_translate_pkg
AS

      /*****************************************************************************
      NAME:       XXFIN_TRANSLATE_MAPPING_PKG
      PURPOSE:     To retrieve target values from ORacle for the given source values.
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2/21/2007    Shankar Murthy  1. Created this package body.
      1.1        3/15/2007    Shankar Murthy  2. Modified to exclude certain validations.
      1.2        6/15/2007    Shankar Murthy  3. Modified to include common error handling routine.
      1.3        7/10/2007    Shankar Murthy  4. Modified to allow source value1 to be null
                                                 as per requirements
      1.4        23-OCT-2007  Greg Dill       5. Added reset_all_proc.
      1.5        26-FEB-2009  Bushrod Thomas  6. Added trunc to effectivity date checks for defect 13396
   *******************************************************************************/
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
   )
   IS
      v_translate_id   xx_fin_translatedefinition.translate_id%TYPE;
      l_return_code    VARCHAR2 (1)             := 'E';
      l_msg_count      NUMBER                   := 0;
      l_msg_status     VARCHAR2 (4000);
      err_code         NUMBER                   := SQLCODE;
      err_msg          VARCHAR2 (200)           := SUBSTR (SQLERRM, 1, 200);
      ld_trx_date      DATE                     := TRUNC(p_trx_date);

   /* Define procedure to reset all target values */
   PROCEDURE reset_all_proc IS
   BEGIN
     x_target_value1 := '';
     x_target_value2 := '';
     x_target_value3 := '';
     x_target_value4 := '';
     x_target_value5 := '';
     x_target_value6 := '';
     x_target_value7 := '';
     x_target_value8 := '';
     x_target_value9 := '';
     x_target_value10 := '';
     x_target_value11 := '';
     x_target_value12 := '';
     x_target_value13 := '';
     x_target_value14 := '';
     x_target_value15 := '';
     x_target_value16 := '';
     x_target_value17 := '';
     x_target_value18 := '';
     x_target_value19 := '';
     x_target_value20 := '';
   END reset_all_proc;

   BEGIN
      DBMS_OUTPUT.ENABLE (1000000);

--      dbms_output.put_line('trans pkg p_source_value1 is: '||p_source_value1);

      --Lookup the translation ID
      SELECT translate_id
        INTO v_translate_id
        FROM xx_fin_translatedefinition
       WHERE translation_name = p_translation_name
         AND enabled_flag = 'Y'
         AND ld_trx_date BETWEEN start_date_active AND NVL(end_date_active,ld_trx_date);

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
            AND (source_value1 = p_source_value1 OR p_source_value1 IS NULL)
            AND (source_value2 = p_source_value2 OR p_source_value2 IS NULL)
            AND (source_value3 = p_source_value3 OR p_source_value3 IS NULL)
            AND (source_value4 = p_source_value4 OR p_source_value4 IS NULL)
            AND (source_value5 = p_source_value5 OR p_source_value5 IS NULL)
            AND (source_value6 = p_source_value6 OR p_source_value6 IS NULL)
            AND (source_value7 = p_source_value7 OR p_source_value7 IS NULL)
            AND (source_value8 = p_source_value8 OR p_source_value8 IS NULL)
            AND (source_value9 = p_source_value9 OR p_source_value9 IS NULL)
            AND (source_value10 = p_source_value10 OR p_source_value10 IS NULL)
            AND enabled_flag = 'Y'
            AND ld_trx_date BETWEEN start_date_active AND NVL(end_date_active,ld_trx_date);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            /* Reset all target values */
            reset_all_proc;
            fnd_message.CLEAR;
            fnd_message.set_name ('xxfin', 'XX_FIN_TRANSLATE_TARGET_ERROR');
            l_msg_count := l_msg_count + 1;
            l_msg_status := fnd_message.get ();
            x_error_message := 'There are no effective target values for translation '||p_translation_name||', source1 '||p_source_value1||', source2 '||p_source_value2||', and transaction date '||p_trx_date||'. ';
         WHEN OTHERS
         THEN
            /* Reset all target values */
            reset_all_proc;
            fnd_message.CLEAR;
            fnd_message.set_name ('xxfin', 'XX_FIN_TRANSLATE_OTHERS_ERROR');
            fnd_message.set_token ('ERR_CODE', err_code);
            fnd_message.set_token ('ERR_MSG', err_msg);
            l_msg_count := l_msg_count + 1;
            --x_target_value1 := -2;
            l_msg_status := fnd_message.get ();
            x_error_message := 'Unhandled exception '||SQLERRM||' raised in xxfin_translate_pkg - target. ';
      END;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         /* Reset all target values */
         reset_all_proc;
         fnd_message.CLEAR;
         fnd_message.set_name ('xxfin', 'XX_FIN_TRANSLATE_DEFN_ERROR');
         fnd_message.set_token ('TRANSLATION_NAME', p_translation_name);
         fnd_message.set_token ('TRANSACTION_DATE', p_trx_date);
         l_msg_count := l_msg_count + 1;
         l_msg_status := fnd_message.get ();
         x_error_message := 'Translation '||p_translation_name||' is not defined. ';
      WHEN OTHERS
      THEN
         /* Reset all target values */
         reset_all_proc;
         fnd_message.CLEAR;
         fnd_message.set_name ('xxfin', 'XX_FIN_TRANSLATE_OTHERS_ERROR');
         fnd_message.set_token ('ERR_CODE', err_code);
         fnd_message.set_token ('ERR_MSG', err_msg);
         l_msg_count := l_msg_count + 1;
         l_msg_status := fnd_message.get ();
         x_error_message := 'Unhandled exception '||SQLERRM||' raised in xxfin_translate_pkg - definition. ';
   END xx_fin_translatevalue_proc;
END xx_fin_translate_pkg;
/
