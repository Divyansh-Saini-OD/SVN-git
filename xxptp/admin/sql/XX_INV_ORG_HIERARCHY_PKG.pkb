   SET SHOW      OFF;
   SET VERIFY    OFF;
   SET ECHO      OFF;
   SET TAB       OFF;
   SET FEEDBACK  OFF;
   WHENEVER SQLERROR CONTINUE;
   WHENEVER OSERROR EXIT FAILURE ROLLBACK;

    CREATE OR REPLACE PACKAGE BODY XX_INV_ORG_HIERARCHY_PKG
      -- +===================================================================================== +
      -- |                  Office Depot - Project Simplify                                     |
      -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
      -- +===================================================================================== +
      -- |                                                                                      |
      -- | Name             :  XX_INV_ORG_HIERARCHY_PKG                                         |
      -- | Description      :  This package will contain the procedures to validate the         |
      -- |                     Organization hierarchy data in the XML message and to load the   |
      -- |                     validated data in Oracle                                         |
      -- |                     EBS using Standard API(XX_INV_FND_FLEX_LOADER_APIS.UP_VSET_VALUE)|
      -- |                                                                                      |
      -- |                                                                                      |
      -- | Change Record:                                                                       |
      -- |===============                                                                       |
      -- |Version   Date         Author           Remarks                                       |
      -- |=======   ==========   =============    ============================================= |
      -- |Draft 1a  09-APR-2007  Gowri Nagarajan  Initial draft version                         |
      -- |Draft 1b  11-May-2007  Gowri Nagarajan  Updated value set names as per updated MD.050 |
      -- |Draft 1c  11-Jun-2007  Gowri Nagarajan  Incorporated peer review comments             |
      -- |Draft 1d  12-Jun-2007  Jayshree Kale    Reviewed and Updated                          |
      -- |Draft 1e  16-Jun-2007  Gowri Nagarajan  Added FND_Messages                            |
      -- |DRAFT 1f  21-JUN-2007  Gowri Nagarajan  Changed p_action Parameter in                 |
      -- |                                        PROCESS_ORG_HIERARCHY from ADD                |
      -- |                                        /MODIFY/DELETE to C/D.                        |
      -- |Draft 1g  25-Jun-2007  Jayshree Kale    Reviewed and Updated                          |
      -- |Draft 1h  28-Jun-2007  Siddharth Singh  Changed enabled_flag to 'N' while disabling.  |
      -- |                                        Changed APPS to FND_GLOBAL.USER_NAME for      |
      -- |                                        p_owner attribute in up_vset_value procedure. |
      -- |DRAFT 1i  12-Jul-2007  Gowri Nagarajan  Added error logging procedure                 |
      -- |                                        XX_COM_ERROR_LOG_PUB.LOG_ERROR                |
      -- |                                        in the exception handling part.               |
      -- |1.0       13-Jul-2007  Jayshree Kale    Baselined                                     |
      -- |1.1       25-Jul-2007  Jayshree/Gowri   Updated for 'BUG UPDATE 6163759':             |
      -- |                                        Who column time truncate by                   |
      -- |                                        API FND_FLEX_LOADER_APIS                      |
	-- |1.2       12-Sep-2007  Paddy Sanjeevi   Modified to update the attribute1 of valueset |
      -- +===================================================================================== +

      AS

        -- +===================================================================+
        -- | Name        :  GET_VALUE_SET_ID                                   |
        -- |                                                                   |
        -- | Description :  This function is used to get the value_set_id      |
        -- |                against a particular value set                     |
        -- |                                                                   |
        -- |                                                                   |
        -- | Parameters  :  p_value_set_name  IN   Value Set Name              |
        -- |                x_message_code    OUT Holds '0','1','-1'           |
        -- |                x_message_data    OUT Holds the message            |
        -- |                                                                   |
        -- +===================================================================+

        FUNCTION GET_VALUE_SET_ID (
                                  p_value_set_name IN VARCHAR2
                                 ,x_message_code   OUT NUMBER
                                 ,x_message_data   OUT VARCHAR2
                                  )
        RETURN NUMBER
        IS

          -- --------------------------
          -- Local Variable Declaration
          -- --------------------------
          ln_flex_value_set_id fnd_flex_value_sets.flex_value_set_id%TYPE := NULL;

        BEGIN

            SELECT flex_value_set_id
            INTO   ln_flex_value_set_id
            FROM   fnd_flex_value_sets
            WHERE  flex_value_set_name = p_value_set_name;

            x_message_code := 0;

            RETURN ln_flex_value_set_id;

        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              x_message_code :=  -1;

              fnd_message.set_name('XXPTP','XX_INV_0003_VSET_NOT_EXISTS');
              fnd_message.set_token('VSET_NAME',p_value_set_name);
              x_message_data := fnd_message.get;
              RETURN ln_flex_value_set_id;

           WHEN OTHERS THEN
              x_message_code :=  -1;

              fnd_message.set_name('XXPTP','XX_INV_0004_VSET_ID_ERR');
              fnd_message.set_token('SQL_ERRM',SQLERRM);
              x_message_data := fnd_message.get;

              RETURN ln_flex_value_set_id;

        END GET_VALUE_SET_ID;

        -- +===================================================================== +
        -- | Name       : API_CALL                                                |
        -- |                                                                      |
        -- | Description: This procedure will be used to create/Modify/Delete     |
        -- |              Organization Hierarchy values in EBS.                   |
        -- |                                                                      |
        -- |                                                                      |
        -- | Parameters : p_flex_value_set_name   IN  Value Set Name              |
        -- |              p_value                 IN  Flex Value                  |
        -- |              p_enabled_flag          IN  Holds 'Y' or 'N'            |
        -- |              p_hierarchy_level       IN  Hierarchy_level             |
        -- |              p_value_category        IN  Value Set Name              |
        -- |              p_description           IN  Description of value        |
        -- |              p_attribute1            IN  Holds the value relationship|
        -- |              x_message_code          OUT Holds '0','1','-1'          |
        -- |              x_message_data          OUT Holds the message           |
        -- |                                                                      |
        -- +======================================================================+


        PROCEDURE API_CALL
                         (
                           p_flex_value_set_name     IN  VARCHAR2
                          ,p_value                   IN  VARCHAR2
                          ,p_enabled_flag            IN  VARCHAR2
                          ,p_start_date_active       IN  DATE
                          ,p_end_date_active         IN  DATE
                          ,p_hierarchy_level         IN  VARCHAR2
                          ,p_value_category          IN  VARCHAR2
                          ,p_description             IN  VARCHAR2
                          ,p_attribute1              IN  VARCHAR2
                          ,p_existing_data           IN  fnd_flex_values%ROWTYPE
                          ,p_exists                  IN  VARCHAR2
                          ,p_new_val                 IN  VARCHAR2
                          ,x_message_code            OUT NUMBER
                          ,x_message_data            OUT VARCHAR2
                          )
        AS

        lr_existing_data     fnd_flex_values%ROWTYPE :=  p_existing_data;
        lc_description       fnd_flex_values_tl.description%TYPE;
        lc_start_date_active VARCHAR2(100);
        lc_end_date_active   VARCHAR2(100);

        BEGIN

           IF p_exists = 'N' AND p_new_val = 'N' THEN

              lr_existing_data.flex_value        := p_value               ;
              lc_start_date_active               := to_char(p_start_date_active,'YYYY/MM/DD HH24:MI:SS') ;
              lc_end_date_active                 := p_end_date_active ;
              lr_existing_data.enabled_flag      := p_enabled_flag         ;
              lr_existing_data.hierarchy_level   := p_hierarchy_level      ;
              lr_existing_data.value_category    := p_value_category       ;
              lr_existing_data.attribute1        := p_attribute1           ;

           ELSIF p_exists = 'N' AND p_new_val = 'Y' THEN

              lc_end_date_active                 := p_end_date_active ;
              lc_start_date_active               := to_char(p_start_date_active,'YYYY/MM/DD HH24:MI:SS') ;
              lr_existing_data.enabled_flag      := 'Y'         ;

              lr_existing_data.attribute1        := p_attribute1           ;

           ELSIF p_exists = 'Y' AND p_new_val = 'Y' THEN

              lc_end_date_active   := to_char(p_end_date_active,'YYYY/MM/DD HH24:MI:SS')   ;
              lc_start_date_active := to_char(p_start_date_active,'YYYY/MM/DD HH24:MI:SS') ;

              lr_existing_data.attribute1        := p_attribute1           ;

           ELSIF p_exists = 'Y' AND p_new_val = 'N' THEN

              lc_start_date_active               := to_char(p_start_date_active,'YYYY/MM/DD HH24:MI:SS') ;
              lc_end_date_active                 := to_char(p_end_date_active,'YYYY/MM/DD HH24:MI:SS') ;
              lr_existing_data.flex_value        := p_value               ;
              lr_existing_data.enabled_flag      := p_enabled_flag         ;
              lr_existing_data.hierarchy_level   := p_hierarchy_level      ;
              lr_existing_data.value_category    := p_value_category       ;
              lr_existing_data.attribute1        := p_attribute1           ;

           END IF;

           lc_description                     := p_description          ;


           XX_INV_FND_FLEX_LOADER_APIS.up_vset_value
                                           (
                                             p_upload_phase                 => 'BEGIN'
                                           , p_upload_mode                  =>  NULL
                                           , p_custom_mode                  =>  NULL
                                           , p_flex_value_set_name          =>  p_flex_value_set_name
                                           , p_parent_flex_value_low        =>  NULL
                                           , p_flex_value                   =>  lr_existing_data.flex_value
                                           , p_owner                        =>  FND_GLOBAL.USER_NAME
                                           , p_last_update_date             =>  TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                                           , p_enabled_flag                 =>  lr_existing_data.enabled_flag
                                           , p_summary_flag                 =>  'N'
                                           , p_start_date_active            =>  lc_start_date_active
                                           , p_end_date_active              =>  lc_end_date_active
                                           , p_parent_flex_value_high       =>  NULL
                                           , p_rollup_hierarchy_code        =>  NULL
                                           , p_hierarchy_level              =>  lr_existing_data.hierarchy_level
                                           , p_compiled_value_attributes    =>  NULL
                                           , p_value_category               =>  lr_existing_data.value_category
                                           , p_flex_value_meaning           =>  lr_existing_data.flex_value
                                           , p_description                  =>  lc_description
                                           , p_attribute1                   =>  lr_existing_data.attribute1
                                           , p_attribute2                   =>  lr_existing_data.attribute2
                                           , p_attribute3                   =>  lr_existing_data.attribute3
                                           , p_attribute4                   =>  lr_existing_data.attribute4
                                           , p_attribute5                   =>  lr_existing_data.attribute5
                                           , p_attribute6                   =>  lr_existing_data.attribute6
                                           , p_attribute7                   =>  lr_existing_data.attribute7
                                           , p_attribute8                   =>  lr_existing_data.attribute8
                                           , p_attribute9                   =>  lr_existing_data.attribute9
                                           , p_attribute10                  =>  lr_existing_data.attribute10
                                           , p_attribute11                  =>  lr_existing_data.attribute11
                                           , p_attribute12                  =>  lr_existing_data.attribute12
                                           , p_attribute13                  =>  lr_existing_data.attribute13
                                           , p_attribute14                  =>  lr_existing_data.attribute14
                                           , p_attribute15                  =>  lr_existing_data.attribute15
                                           , p_attribute16                  =>  lr_existing_data.attribute16
                                           , p_attribute17                  =>  lr_existing_data.attribute17
                                           , p_attribute18                  =>  lr_existing_data.attribute18
                                           , p_attribute19                  =>  lr_existing_data.attribute19
                                           , p_attribute20                  =>  lr_existing_data.attribute20
                                           , p_attribute21                  =>  lr_existing_data.attribute21
                                           , p_attribute22                  =>  lr_existing_data.attribute22
                                           , p_attribute23                  =>  lr_existing_data.attribute23
                                           , p_attribute24                  =>  lr_existing_data.attribute24
                                           , p_attribute25                  =>  lr_existing_data.attribute25
                                           , p_attribute26                  =>  lr_existing_data.attribute26
                                           , p_attribute27                  =>  lr_existing_data.attribute27
                                           , p_attribute28                  =>  lr_existing_data.attribute28
                                           , p_attribute29                  =>  lr_existing_data.attribute29
                                           , p_attribute30                  =>  lr_existing_data.attribute30
                                           , p_attribute31                  =>  lr_existing_data.attribute31
                                           , p_attribute32                  =>  lr_existing_data.attribute32
                                           , p_attribute33                  =>  lr_existing_data.attribute33
                                           , p_attribute34                  =>  lr_existing_data.attribute34
                                           , p_attribute35                  =>  lr_existing_data.attribute35
                                           , p_attribute36                  =>  lr_existing_data.attribute36
                                           , p_attribute37                  =>  lr_existing_data.attribute37
                                           , p_attribute38                  =>  lr_existing_data.attribute38
                                           , p_attribute39                  =>  lr_existing_data.attribute39
                                           , p_attribute40                  =>  lr_existing_data.attribute40
                                           , p_attribute41                  =>  lr_existing_data.attribute41
                                           , p_attribute42                  =>  lr_existing_data.attribute42
                                           , p_attribute43                  =>  lr_existing_data.attribute43
                                           , p_attribute44                  =>  lr_existing_data.attribute44
                                           , p_attribute45                  =>  lr_existing_data.attribute45
                                           , p_attribute46                  =>  lr_existing_data.attribute46
                                           , p_attribute47                  =>  lr_existing_data.attribute47
                                           , p_attribute48                  =>  lr_existing_data.attribute48
                                           , p_attribute49                  =>  lr_existing_data.attribute49
                                           , p_attribute50                  =>  lr_existing_data.attribute50
                                           , p_attribute_sort_order         =>  lr_existing_data.attribute_sort_order
                                           ) ;         

         x_message_code := 0;

        EXCEPTION

          WHEN OTHERS THEN

             x_message_code := -1;

             fnd_message.set_name('XXPTP','XX_INV_0005_API_ERR');
             fnd_message.set_token('SQL_ERR',SQLERRM);
             x_message_data := fnd_message.get;

        END;

        -- +===================================================================+
        -- | Name       : CHECK_VALUE_EXISTS                                   |
        -- |                                                                   |
        -- | Description: This procedure will be used to check whether the     |
        -- |              flex value exists or not and get the enabled flag    |
        -- |              and end_date_active of the value                     |
        -- |                                                                   |
        -- |                                                                   |
        -- | Parameters : p_value                 IN   Flex value              |
        -- |              x_value_exists          OUT  Holds 'Y' or 'N'        |
        -- |              x_enabled_flag          OUT  Holds 'Y' or 'N'        |
        -- |              x_end_date_active       OUT  End_date of value       |
        -- |              x_message_code          OUT  Holds '0','1','-1'      |
        -- |              x_message_data          OUT  Holds the message       |
        -- |                                                                   |
        -- +===================================================================+

       PROCEDURE CHECK_VALUE_EXISTS
                                   (
                                      p_value                IN  NUMBER
                                    , x_value_exists         OUT VARCHAR2
                                    , x_existing_data        OUT fnd_flex_values%ROWTYPE
                                    , x_message_code         OUT NUMBER
                                    , x_message_data         OUT VARCHAR2
                                    )
       IS

       BEGIN

          x_message_code := 0;        
          
          x_value_exists := 'Y';

          SELECT FFV.*
          INTO   x_existing_data
          FROM   fnd_flex_values    FFV
          WHERE  flex_value_set_id = gn_value_set_id
          AND    flex_value        = p_value;

       EXCEPTION

          WHEN No_Data_Found THEN

            x_existing_data := NULL;
            x_value_exists := 'N';

          WHEN OTHERS THEN

            x_message_code := -1 ;

            fnd_message.set_name('XXPTP','XX_INV_0007_VAL_ERR');
            fnd_message.set_token('SQL_ERR',SQLERRM);
            x_message_data := fnd_message.get;

       END CHECK_VALUE_EXISTS;

       -- +===================================================================+
       -- | Name       : DELETE_DISTRICT                                      |
       -- |                                                                   |
       -- | Description: This procedure will be used to delete all the        |
       -- |              districts belonging to particular Region.            |
       -- |                                                                   |
       -- |                                                                   |
       -- | Parameters : p_value                 IN   Flex value              |
       -- |              x_value_exists          OUT  Holds 'Y' or 'N'        |
       -- |              x_message_code          OUT  Holds '0','1','-1'      |
       -- |              x_message_data          OUT  Holds the message       |
       -- |                                                                   |
       -- +===================================================================+

       PROCEDURE DELETE_DISTRICT (
                                   p_value           IN NUMBER
                                 , p_end_date_active IN DATE
                                 , x_message_code    OUT NUMBER
                                 , x_message_data    OUT VARCHAR2
                                 )

       IS

         -- -----------------------------------------------------------
         -- Cursor to get all the Districts that belongs to this Region
         -- -----------------------------------------------------------

         CURSOR  cur_delete_district
         IS
         SELECT  FFV.flex_value
               , FFVS.flex_value_set_name
               , FFVT.description
               , FFV.start_date_active
               , FFV.hierarchy_level
               , FFV.value_category
               , FFV.enabled_flag
         FROM   fnd_flex_values     FFV
               ,fnd_flex_values_tl  FFVT
               ,fnd_flex_value_sets FFVS
         WHERE  FFV.flex_value_set_id = gn_district_value_set_id
         AND    FFV.flex_value_set_id = FFVS.flex_value_set_id
         AND    FFVT.flex_value_id    = FFV.flex_value_id
         AND    FFV.attribute1        = p_value ;


       BEGIN

           x_message_code := 0;

           gn_district_value_set_id   := GET_VALUE_SET_ID(
                                                          'XX_GI_DISTRICT_VS'
                                                         , x_message_code
                                                         , x_message_data
                                                         );

           IF x_message_code = -1 THEN

              RETURN;

           ELSE

              FOR lcu_delete_district IN cur_delete_district
              LOOP

                 -- -------------------------------------
                 -- Call API_CALL to disable the District
                 -- -------------------------------------

                 API_CALL
                        (

                          p_flex_value_set_name => lcu_delete_district.flex_value_set_name
                         ,p_value               => lcu_delete_district.flex_value
                         ,p_enabled_flag        => 'N'
                         ,p_start_date_active   => lcu_delete_district.start_date_active
                         ,p_end_date_active     => p_end_date_active
                         ,p_hierarchy_level     => lcu_delete_district.hierarchy_level
                         ,p_value_category      => lcu_delete_district.value_category
                         ,p_description         => lcu_delete_district.description
                         ,p_attribute1          => p_value
                         ,p_existing_data       => NULL
                         ,p_exists              => 'Y'
                         ,p_new_val             => 'N'
                         ,x_message_code        => x_message_code
                         ,x_message_data        => x_message_data
                         );

                  IF  x_message_code = 0 THEN

                      fnd_message.set_name('XXPTP','XX_INV_0025_DIST_VLS_DEL');
                      x_message_data := fnd_message.get;

                  ELSIF x_message_code = -1 THEN

                     RETURN;

                  END IF;

              END LOOP;

           END IF ;

       EXCEPTION

         WHEN OTHERS THEN

             x_message_code :=  -1;

             fnd_message.set_name('XXPTP','XX_INV_0022_HIE_VAL_FLD');
             fnd_message.set_token('SQL_ERR',SQLERRM);
             x_message_data := fnd_message.get;

       END DELETE_DISTRICT;

       -- +===================================================================+
       -- | Name       : DELETE_REGION                                        |
       -- |                                                                   |
       -- | Description: This Procedure will be used to delete all the        |
       -- |              Regions belonging to particular Area.                |
       -- |                                                                   |
       -- |                                                                   |
       -- | Parameters : p_value                 IN   Flex value              |
       -- |              x_value_exists          OUT  Holds 'Y' or 'N'        |
       -- |              x_message_code          OUT  Holds '0','1','-1'      |
       -- |              x_message_data          OUT  Holds the message       |
       -- |                                                                   |
       -- +===================================================================+

       PROCEDURE DELETE_REGION(
                                p_value           IN  NUMBER
                              , p_end_date_active IN  DATE
                              , x_message_code    OUT NUMBER
                              , x_message_data    OUT VARCHAR2
                              )
       IS

         -- -------------------------------------------------------
         -- Cursor to get all the regions that belongs to this Area
         -- -------------------------------------------------------

         CURSOR  cur_delete_region
         IS
         SELECT  FFV.flex_value
               , FFVS.flex_value_set_name
               , FFVT.description
               , FFV.start_date_active
               , FFV.hierarchy_level
               , FFV.value_category
               , FFV.enabled_flag
         FROM    fnd_flex_values     FFV
               , fnd_flex_values_tl  FFVT
               , fnd_flex_value_sets FFVS
         WHERE   FFV.flex_value_set_id = gn_region_value_set_id
         AND     FFV.flex_value_set_id = FFVS.flex_value_set_id
         AND     FFVT.flex_value_id    = FFV.flex_value_id
         AND     FFV.attribute1        = p_value ;


       BEGIN

           x_message_code := 0;

           gn_region_value_set_id := GET_VALUE_SET_ID(
                                                      'XX_GI_REGION_VS'
                                                      , x_message_code
                                                      , x_message_data
                                                      );
           IF x_message_code = -1 THEN

              RETURN;

           ELSE

              FOR lcu_delete_region IN cur_delete_region
              LOOP

                 -- ------------------------------------------------------
                 -- Call DELETE_DISTRICT to get all districts for this Region
                 -- ------------------------------------------------------

                 DELETE_DISTRICT
                            (
                              lcu_delete_region.flex_value
                            , p_end_date_active
                            , x_message_code
                            , x_message_data
                            );

                 IF x_message_code = -1 THEN

                    RETURN;

                 END IF;

                 -- -----------------------------------
                 -- Call API_CALL to disable the Region
                 -- -----------------------------------
                  API_CALL
                          (
                            p_flex_value_set_name => lcu_delete_region.flex_value_set_name
                           ,p_value               => lcu_delete_region.flex_value
                           ,p_enabled_flag        => 'N'
                           ,p_start_date_active   => lcu_delete_region.start_date_active
                           ,p_end_date_active     => p_end_date_active
                           ,p_hierarchy_level     => lcu_delete_region.hierarchy_level
                           ,p_value_category      => lcu_delete_region.value_category
                           ,p_description         => lcu_delete_region.description
                           ,p_attribute1          => p_value
                           ,p_existing_data       => NULL
                           ,p_exists              => 'Y'
                           ,p_new_val             => 'N'
                           ,x_message_code        => x_message_code
                           ,x_message_data        => x_message_data
                           );

                   IF  x_message_code = 0 THEN

                      fnd_message.set_name('XXPTP','XX_INV_0024_REG_VLS_DEL');
                      x_message_data := fnd_message.get;

                   ELSIF x_message_code = -1 THEN

                      RETURN;

                   END IF;

              END LOOP;

           END IF;

       EXCEPTION

          WHEN OTHERS THEN

            x_message_code := -1;

            fnd_message.set_name('XXPTP','XX_INV_0022_HIE_VAL_FLD');
            fnd_message.set_token('SQL_ERR',SQLERRM);
            x_message_data := fnd_message.get;

       END DELETE_REGION;

       -- +===================================================================+
       -- | Name       : DELETE_AREA                                          |
       -- |                                                                   |
       -- | Description: This Procedure will be used to delete all the        |
       -- |              Areas belonging to particular Chain.                 |
       -- |                                                                   |
       -- | Parameters : p_value                 IN   Flex value              |
       -- |              x_value_exists          OUT  Holds 'Y' or 'N'        |
       -- |              x_message_code          OUT  Holds '0','1','-1'      |
       -- |              x_message_data          OUT  Holds the message       |
       -- |                                                                   |
       -- +===================================================================+

       PROCEDURE DELETE_AREA(
                              p_value             IN NUMBER
                            , p_end_date_active   IN DATE
                            , x_message_code      OUT NUMBER
                            , x_message_data      OUT VARCHAR2
                            )
       IS

         -- ------------------------------------------------------
         -- Cursor to get all the Areas that belongs to this Chain
         -- ------------------------------------------------------

         CURSOR cur_delete_area
         IS
         SELECT  FFV.flex_value
               , FFVS.flex_value_set_name
               , FFVT.description
               , FFV.start_date_active
               , FFV.hierarchy_level
               , FFV.value_category
               , FFV.enabled_flag
         FROM    fnd_flex_values     FFV
               , fnd_flex_values_tl  FFVT
               , fnd_flex_value_sets FFVS
         WHERE   FFV.flex_value_set_id  = gn_area_value_set_id
         AND     FFV.flex_value_set_id  = FFVS.flex_value_set_id
         AND     FFVT.flex_value_id     = FFV.flex_value_id
         AND     FFV.attribute1         = p_value ;

       BEGIN

           x_message_code := 0;

           gn_area_value_set_id := GET_VALUE_SET_ID(
                                                    'XX_GI_AREA_VS'
                                                   , x_message_code
                                                   , x_message_data
                                                   );

           IF x_message_code = -1 THEN

              RETURN;

           ELSE

              FOR lcu_delete_area IN cur_delete_area
              LOOP

                 -- ------------------------------------------------
                 -- Call DELETE_REGION to get all Regions for this Area
                 -- ------------------------------------------------

                 DELETE_REGION
                          (
                            lcu_delete_area.flex_value
                          , p_end_date_active
                          , x_message_code
                          , x_message_data
                          );

                 IF x_message_code = -1 THEN

                    RETURN;

                 END IF;

                 -- ----------------------------------
                 -- Call API_CALL to disable the Area
                 -- ----------------------------------
                  API_CALL
                          (

                            p_flex_value_set_name => lcu_delete_area.flex_value_set_name
                           ,p_value               => lcu_delete_area.flex_value
                           ,p_enabled_flag        => 'N'
                           ,p_start_date_active   => lcu_delete_area.start_date_active
                           ,p_end_date_active     => p_end_date_active
                           ,p_hierarchy_level     => lcu_delete_area.hierarchy_level
                           ,p_value_category      => lcu_delete_area.value_category
                           ,p_description         => lcu_delete_area.description
                           ,p_attribute1          => p_value
                           ,p_existing_data       => NULL
                           ,p_exists              => 'Y'
                           ,p_new_val             => 'N'
                           ,x_message_code        => x_message_code
                           ,x_message_data        => x_message_data
                           );
                   
                   IF  x_message_code = 0 THEN

                     x_message_data := 'Area Value set values disabled successfully';

                     fnd_message.set_name('XXPTP','XX_INV_0023_AREA_VLS_DEL');
                     x_message_data := fnd_message.get;

                   ELSIF x_message_code = -1 THEN

                     RETURN;

                   END IF;

              END LOOP;

           END IF ;

       EXCEPTION

          WHEN OTHERS THEN

            x_message_code :=  -1;

            fnd_message.set_name('XXPTP','XX_INV_0022_HIE_VAL_FLD');
            fnd_message.set_token('SQL_ERR',SQLERRM);
            x_message_data := fnd_message.get;

       END DELETE_AREA;

       -- +==================================================================== +
       -- | Name        : PROCESS_ORG_HIERARCHY                                 |
       -- |                                                                     |
       -- | Description : This Procedure will be used to create/update/delete   |
       -- |               Organization Hierarchy values in EBS.                 |
       -- |                                                                     |
       -- |                                                                     |
       -- | Parameters  : p_hierarchy_level       IN  Hierarchy Level           |
       -- |               p_value                 IN  Flex value                |
       -- |               p_description           IN  Description of the value  |
       -- |               p_action                IN  Describes the action to be|
       -- |                                           performed                 |
       -- |               p_chain_number          IN  Chain number              |
       -- |               p_area_number           IN  Area  number              |
       -- |               p_region_number         IN  Region number             |
       -- |               x_message_code          OUT Holds '0','1','-1'        |
       -- |               x_message_data          OUT Holds the message         |
       -- |                                                                     |
       -- +==================================================================== +


       PROCEDURE PROCESS_ORG_HIERARCHY
                                     (
                                       p_hierarchy_level  IN  VARCHAR2
                                     , p_value            IN  NUMBER
                                     , p_description      IN  VARCHAR2
                                     , p_action           IN  VARCHAR2
                                     , p_chain_number     IN  NUMBER
                                     , p_area_number      IN  NUMBER
                                     , p_region_number    IN  NUMBER
                                     , x_message_code     OUT NUMBER
                                     , x_message_data     OUT VARCHAR2
                                     )

       AS

         -- --------------------------
         -- Local Variable Declaration
         -- --------------------------

         EX_END_PROC             EXCEPTION                                             ;
         EX_END_PROC_RBACK       EXCEPTION                                             ;         
         lc_enabled_flag         fnd_flex_values.enabled_flag%TYPE            := 'N'   ;
         lc_flex_value_set_name  fnd_flex_value_sets.flex_value_set_name%TYPE := NULL  ;
         lc_description          fnd_flex_value_sets.description%TYPE         := NULL  ;
         lc_flex_value           fnd_flex_values.flex_value%TYPE              := NULL  ;
         ld_start_date_active    DATE := SYSDATE ;
         ld_end_date_active      DATE := NULL ;
         lc_attribute1           fnd_flex_values.attribute1%TYPE              := NULL  ;
         lc_value_category       fnd_flex_values.value_category%TYPE          := NULL  ;
         lc_value_exists         VARCHAR2(1)                                  := 'N'   ;
         lc_hierarchy_level      fnd_flex_values.hierarchy_level%TYPE         := NULL  ;
         lr_existing_data        fnd_flex_values%ROWTYPE                               ;


       BEGIN

          x_message_code := 0 ;

          IF p_hierarchy_level IS NULL THEN

             x_message_code:= -1;
             fnd_message.set_name('XXPTP','XX_INV_0028_HIER_NULL');
             x_message_data  := fnd_message.get;
             RAISE EX_END_PROC;

          ELSIF p_value IS NULL THEN

             x_message_code := -1;
             fnd_message.set_name('XXPTP','XX_INV_0027_VALUE_NULL');
             x_message_data  := fnd_message.get;
             RAISE EX_END_PROC;

          ELSIF p_action IS NULL THEN

             x_message_code := -1;

             fnd_message.set_name('XXPTP','XX_INV_0026_ACTION_NULL');
             x_message_data := fnd_message.get;
             RAISE EX_END_PROC;

          ELSIF p_action <> 'C' AND p_action <> 'D' THEN

             x_message_code := -1;
             fnd_message.set_name('XXPTP','XX_INV_0001_INVALID_ACTION');
             x_message_data := fnd_message.get;
             RAISE EX_END_PROC;

          END IF;

          IF p_hierarchy_level = 'CHAIN' THEN

             lc_flex_value_set_name := 'XX_GI_CHAIN_VS';

          ELSIF p_hierarchy_level='AREA' THEN

             lc_flex_value_set_name := 'XX_GI_AREA_VS';

          ELSIF p_hierarchy_level='REGION' THEN

             lc_flex_value_set_name := 'XX_GI_REGION_VS';

          ELSIF p_hierarchy_level='DISTRICT' THEN

             lc_flex_value_set_name := 'XX_GI_DISTRICT_VS';

          ELSIF p_hierarchy_level NOT IN ('CHAIN','AREA','REGION','DISTRICT') THEN

             x_message_code := -1;
             fnd_message.set_name('XXPTP','XX_INV_0002_INVALID_HR_LEVEL');
             x_message_data := fnd_message.get;
             RAISE EX_END_PROC;

          END IF;

          -- ------------------------------
          -- Call Function GET_VALUE_SET_ID
          -- ------------------------------

          gn_value_set_id  := GET_VALUE_SET_ID(
                                                lc_flex_value_set_name
                                              , x_message_code
                                              , x_message_data
                                               );
          IF  x_message_code = -1 THEN

             RAISE EX_END_PROC;

          END IF;

          IF p_action = 'C' THEN

             IF p_hierarchy_level ='AREA' AND p_chain_number IS NULL THEN

                x_message_code := -1;
                fnd_message.set_name('XXPTP','XX_INV_0006_HLVL_VAL_FALD');
                fnd_message.set_token('VSET',p_hierarchy_level);
                fnd_message.set_token('NUM' ,'Chain Number');
                x_message_data := fnd_message.get;

                RAISE EX_END_PROC;

             ELSIF p_hierarchy_level ='REGION' AND p_area_number IS NULL THEN

                x_message_code := -1;

                fnd_message.set_name('XXPTP','XX_INV_0006_HLVL_VAL_FALD');
                fnd_message.set_token('VSET',p_hierarchy_level);
                fnd_message.set_token('NUM', 'Area Number');
                x_message_data := fnd_message.get;

                RAISE EX_END_PROC;

             ELSIF p_hierarchy_level ='DISTRICT' AND p_region_number IS NULL THEN

                x_message_code := -1;

                fnd_message.set_name('XXPTP','XX_INV_0006_HLVL_VAL_FALD');
                fnd_message.set_token('VSET',p_hierarchy_level);
                fnd_message.set_token('NUM','Region Number');
                x_message_data := fnd_message.get;

                RAISE EX_END_PROC;

             END IF;

             -- ------------------------------
             -- Check whether the value exists
             -- ------------------------------

             CHECK_VALUE_EXISTS
                               (  p_value
                                , lc_value_exists
                                , lr_existing_data
                                , x_message_code
                                , x_message_data
                               );

             IF  x_message_code = -1  THEN

                 RAISE EX_END_PROC;

             END IF;

             lc_enabled_flag     := lr_existing_data.enabled_flag;
             ld_end_date_active  := lr_existing_data.end_date_active;

               IF p_hierarchy_level = 'CHAIN' THEN

                  lc_attribute1       := NULL;
                  lc_value_category   := NULL;

               ELSIF p_hierarchy_level='AREA' THEN

                  lc_attribute1       := p_chain_number ;
                  lc_value_category   := lc_flex_value_set_name ;

               ELSIF p_hierarchy_level='REGION' THEN

                  lc_attribute1       := p_area_number ;
                  lc_value_category   := lc_flex_value_set_name ;

               ELSIF p_hierarchy_level='DISTRICT' THEN

                  lc_attribute1       := p_region_number ;
                  lc_value_category   := lc_flex_value_set_name ;

               END IF;

             IF lc_value_exists = 'Y' AND (lc_enabled_flag = 'Y' AND (NVL(ld_end_date_active,TRUNC(SYSDATE) +1 ) >= TRUNC(SYSDATE))) THEN

                -- ---------------------------
                -- Exists and enabled - Modify
                -- ---------------------------
                -- -----------------
                -- Cal API_CALL PROC
                -- -----------------

                API_CALL
                        (
                          p_flex_value_set_name => lc_flex_value_set_name
                         ,p_value               => p_value
                         ,p_enabled_flag        => lr_existing_data.enabled_flag
                         ,p_start_date_active   => lr_existing_data.start_date_active
                         ,p_end_date_active     => lr_existing_data.end_date_active
                         ,p_hierarchy_level     => lr_existing_data.hierarchy_level
                         ,p_value_category      => lc_value_category
                         ,p_description         => p_description
                         ,p_attribute1          => lc_attribute1
                         ,p_existing_data       => lr_existing_data
                         ,p_exists              => 'Y'
                         ,p_new_val             => 'Y'
                         ,x_message_code        => x_message_code
                         ,x_message_data        => x_message_data
                         );

                IF  x_message_code = 0 THEN

                   fnd_message.set_name('XXPTP','XX_INV_0014_SUCC_UPD');
                   x_message_data := fnd_message.get;

                ELSIF x_message_code = -1 THEN

                   RAISE EX_END_PROC;

                END IF;

             ELSIF lc_value_exists = 'Y' AND (lc_enabled_flag = 'N' OR (NVL(ld_end_date_active,TRUNC(SYSDATE) +1 ) < TRUNC(SYSDATE))) THEN

                 ld_end_date_active := NULL;

                 -- ---------------------------------------
                 -- Exists and disabled - Enable and Modify
                 -- ---------------------------------------

                 -- -----------------
                 -- Cal API_CALL PROC
                 -- -----------------

                 API_CALL
                         (
                         p_flex_value_set_name => lc_flex_value_set_name
                        ,p_value               => p_value
                        ,p_enabled_flag        => 'Y'
                        ,p_start_date_active   => lr_existing_data.start_date_active
                        ,p_end_date_active     => ld_end_date_active
                        ,p_hierarchy_level     => lr_existing_data.hierarchy_level
                        ,p_value_category      => lc_value_category
                        ,p_description         => p_description
                        ,p_attribute1          => lc_attribute1
                        ,p_existing_data       => lr_existing_data
                        ,p_exists              => 'N'
                        ,p_new_val             => 'Y'
                        ,x_message_code        => x_message_code
                        ,x_message_data        => x_message_data
                      );

                 IF  x_message_code = 0 THEN

                    fnd_message.set_name('XXPTP','XX_INV_0010_SUCC_ENB');
                    fnd_message.set_token('VALUE',p_value);
                    x_message_data := fnd_message.get;                    

                 ELSIF x_message_code = -1 THEN

                  RAISE EX_END_PROC;

                 END IF;

             ELSIF lc_value_exists = 'N' THEN

               -- ------------------------------------
               -- Does not Exists - Add
               -- ------------------------------------

               -- -----------------------------
               -- Call the API to add the value
               -- -----------------------------

               IF p_hierarchy_level = 'CHAIN' THEN

                  lc_attribute1       := NULL;
                  lc_value_category   := NULL;

               ELSIF p_hierarchy_level='AREA' THEN

                  lc_attribute1       := p_chain_number ;
                  lc_value_category   := lc_flex_value_set_name ;

               ELSIF p_hierarchy_level='REGION' THEN

                  lc_attribute1       := p_area_number ;
                  lc_value_category   := lc_flex_value_set_name ;

               ELSIF p_hierarchy_level='DISTRICT' THEN

                  lc_attribute1       := p_region_number ;
                  lc_value_category   := lc_flex_value_set_name ;

               END IF;

               ld_end_date_active := NULL;

               -- -----------------
               -- Cal API_CALL PROC
               -- -----------------

               API_CALL
                      (
                        p_flex_value_set_name => lc_flex_value_set_name
                       ,p_value               => p_value
                       ,p_enabled_flag        => 'Y'
                       ,p_start_date_active   => ld_start_date_active
                       ,p_end_date_active     => ld_end_date_active
                       ,p_hierarchy_level     => p_hierarchy_level
                       ,p_value_category      => lc_value_category
                       ,p_description         => p_description
                       ,p_attribute1          => lc_attribute1
                       ,p_existing_data       => NULL
                       ,p_exists              => 'N'
                       ,p_new_val             => 'N'
                       ,x_message_code        => x_message_code
                       ,x_message_data        => x_message_data
                       );


               IF  x_message_code = 0 THEN

                  fnd_message.set_name('XXPTP','XX_INV_0011_SUCC_LOAD');
                  fnd_message.set_token('VALUE',p_value);
                  x_message_data := fnd_message.get;                 

               ELSIF x_message_code = -1 THEN

                  RAISE EX_END_PROC;

               END IF;

             END IF ;

          ELSIF p_action = 'D' THEN

             -- ------------------------------
             -- Check whether the value exists
             -- ------------------------------

             CHECK_VALUE_EXISTS
                               (  p_value
                                , lc_value_exists
                                , lr_existing_data
                                , x_message_code
                                , x_message_data
                                   );

             IF  x_message_code = -1  THEN

                  RAISE EX_END_PROC;

             END IF;

             IF lc_value_exists = 'N' THEN

               x_message_code  := -1                                                                ;

               fnd_message.set_name('XXPTP','XX_INV_0015_VL_NOT_EXIST');
               x_message_data := fnd_message.get;
               RAISE EX_END_PROC;

             ELSIF lc_value_exists = 'Y' THEN

                ld_end_date_active := SYSDATE;


                BEGIN

                   SELECT  FFVT.description
                   INTO    lc_description
                   FROM    fnd_flex_values    FFV
                          ,fnd_flex_values_tl FFVT
                   WHERE   flex_value_set_id = gn_value_set_id
                   AND     flex_value        = p_value
                   AND     FFV.flex_value_id = FFVT.flex_value_id;

                EXCEPTION
                
                   WHEN NO_DATA_FOUND THEN

                      x_message_code := -1 ; 
                       
                      fnd_message.set_name('XXPTP','XX_INV_0029_DESC_ERR');
                      fnd_message.set_token('VALUE',p_value);
                      x_message_data := fnd_message.get;                

                   WHEN OTHERS THEN

                      x_message_code := -1 ;  
                       
                      fnd_message.set_name('XXPTP','XX_INV_0026_DESC_ERR');
                      fnd_message.set_token('SQL_ERR',SQLERRM);
                      x_message_data := fnd_message.get;

                END;
                
                IF x_message_code = -1 THEN
                   
                   RAISE EX_END_PROC;
                
                END IF;

                IF p_hierarchy_level = 'CHAIN' THEN

                   -- ---------------------------------------------
                   -- Call DELETE_AREA to get all Areas for this Chain
                   -- ---------------------------------------------

                   DELETE_AREA
                           (
                             p_value
                           , ld_end_date_active
                           , x_message_code
                           , x_message_data
                           );

                   IF x_message_code = -1 THEN

                      RAISE EX_END_PROC_RBACK;

                   END IF;

                   -- ----------------------------------
                   -- Call API_CALL to disable the Chain
                   -- ----------------------------------

                   API_CALL
                         (

                           p_flex_value_set_name => lc_flex_value_set_name
                          ,p_value               => p_value
                          ,p_enabled_flag        => 'N'
                          ,p_start_date_active   => lr_existing_data.start_date_active
                          ,p_end_date_active     => ld_end_date_active
                          ,p_hierarchy_level     => lr_existing_data.hierarchy_level
                          ,p_value_category      => lr_existing_data.value_category
                          ,p_description         => lc_description
                          ,p_attribute1          => lr_existing_data.attribute1
                          ,p_existing_data       => lr_existing_data
                          ,p_exists              => 'Y'
                          ,p_new_val             => 'N'
                          ,x_message_code        => x_message_code
                          ,x_message_data        => x_message_data
                         );

                   IF  x_message_code = 0 THEN

                       fnd_message.set_name('XXPTP','XX_INV_0017_CHAIN_DEL');
                       fnd_message.set_token('VALUE',p_value);
                       x_message_data := fnd_message.get;

                   ELSIF x_message_code = -1 THEN

                         RAISE EX_END_PROC;

                   END IF;

                ELSIF p_hierarchy_level = 'AREA' THEN

                  -- ------------------------------------------------
                  -- Call DELETE_REGION to get all Regions for this Area
                  -- ------------------------------------------------

                   DELETE_REGION
                            (
                              p_value
                            , ld_end_date_active
                            , x_message_code
                            , x_message_data
                            );

                   IF x_message_code = -1 THEN

                      RAISE EX_END_PROC_RBACK;

                   END IF;

                   -- ----------------------------------
                   -- Call API_CALL to disable the Area
                   -- ----------------------------------

                   API_CALL
                         (
                           p_flex_value_set_name => lc_flex_value_set_name
                          ,p_value               => p_value
                          ,p_enabled_flag        => 'N'
                          ,p_start_date_active   => lr_existing_data.start_date_active
                          ,p_end_date_active     => ld_end_date_active
                          ,p_hierarchy_level     => lr_existing_data.hierarchy_level
                          ,p_value_category      => lr_existing_data.value_category
                          ,p_description         => lc_description
                          ,p_attribute1          => lr_existing_data.attribute1
                          ,p_existing_data       => lr_existing_data
                          ,p_exists              => 'Y'
                          ,p_new_val             => 'N'
                          ,x_message_code        => x_message_code
                          ,x_message_data        => x_message_data
                         );

                    IF  x_message_code = 0 THEN


                      fnd_message.set_name('XXPTP','XX_INV_0018_ARAE_DEL');
                      fnd_message.set_token('VALUE',p_value);
                      x_message_data := fnd_message.get;

                    ELSIF x_message_code = -1 THEN

                       RAISE EX_END_PROC;
                    END IF;

                ELSIF p_hierarchy_level = 'REGION' THEN

                   -- -----------------
                   -- Call DELETE_DISTRICT
                   -- -----------------

                   DELETE_DISTRICT
                              (
                                p_value
                              , ld_end_date_active
                              , x_message_code
                              , x_message_data
                             );

                   IF x_message_code = -1 THEN

                      RAISE EX_END_PROC_RBACK;

                   END IF;

                   -- -----------------------------------
                   -- Call API_CALL to disable the Region
                   -- -----------------------------------

                   API_CALL
                         (

                           p_flex_value_set_name => lc_flex_value_set_name
                          ,p_value               => p_value
                          ,p_enabled_flag        => 'N'
                          ,p_start_date_active   => lr_existing_data.start_date_active
                          ,p_end_date_active     => ld_end_date_active
                          ,p_hierarchy_level     => lr_existing_data.hierarchy_level
                          ,p_value_category      => lr_existing_data.value_category
                          ,p_description         => lc_description
                          ,p_attribute1          => lr_existing_data.attribute1
                          ,p_existing_data       => lr_existing_data
                          ,p_exists              => 'Y'
                          ,p_new_val             => 'N'
                          ,x_message_code        => x_message_code
                          ,x_message_data        => x_message_data
                         );

                   IF  x_message_code = 0 THEN

                    fnd_message.set_name('XXPTP','XX_INV_0019_REG_DEL');
                    fnd_message.set_token('VALUE',p_value);
                    x_message_data := fnd_message.get;

                   ELSIF x_message_code = -1 THEN

                     RAISE EX_END_PROC;

                   END IF;

                ELSIF p_hierarchy_level = 'DISTRICT' THEN

                   -- -------------------------------------
                   -- Call API_CALL to disable the District
                   -- -------------------------------------
                   API_CALL
                         (

                           p_flex_value_set_name => lc_flex_value_set_name
                          ,p_value               => p_value
                          ,p_enabled_flag        => 'N'
                          ,p_start_date_active   => lr_existing_data.start_date_active
                          ,p_end_date_active     => ld_end_date_active
                          ,p_hierarchy_level     => lr_existing_data.hierarchy_level
                          ,p_value_category      => lr_existing_data.value_category
                          ,p_description         => lc_description
                          ,p_attribute1          => lr_existing_data.attribute1
                          ,p_existing_data       => lr_existing_data
                          ,p_exists              => 'Y'
                          ,p_new_val             => 'N'
                          ,x_message_code        => x_message_code
                          ,x_message_data        => x_message_data
                         );

                   IF  x_message_code = 0 THEN


                       fnd_message.set_name('XXPTP','XX_INV_0020_DIST_DEL');
                       fnd_message.set_token('VALUE',p_value);
                       x_message_data := fnd_message.get;

                   ELSIF x_message_code = -1 THEN

                      RAISE EX_END_PROC;

                   END IF;

                END IF;

            END IF;

       END IF;
       
       COMMIT;  

    EXCEPTION

       WHEN EX_END_PROC THEN

           x_message_code := -1;                      
           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           P_PROGRAM_TYPE            => 'CUSTOM API'
                                          ,P_PROGRAM_NAME            => 'XX_INV_ORG_HIERARCHY_PKG.PROCESS_ORG_HIERARCHY'
                                          ,P_PROGRAM_ID              => NULL
                                          ,P_MODULE_NAME             => 'INV'
                                          ,P_ERROR_LOCATION          => 'EX_END_PROC EXCEPTION'
                                          ,P_ERROR_MESSAGE_COUNT     => NULL
                                          ,P_ERROR_MESSAGE_CODE      => x_message_code
                                          ,P_ERROR_MESSAGE           => x_message_data
                                          ,P_ERROR_MESSAGE_SEVERITY  => 'MAJOR'
                                          ,P_NOTIFY_FLAG             => 'Y'
                                          ,P_OBJECT_TYPE             => 'Organization Hierarchy Interface'
                                          ,P_OBJECT_ID               => TO_CHAR(p_value)
                                          ,P_ATTRIBUTE1              => p_hierarchy_level
                                          ,P_ATTRIBUTE2              => p_description
                                          ,P_ATTRIBUTE3              => p_action
                                          ,P_RETURN_CODE             => NULL
                                          ,P_MSG_COUNT               => NULL
                                         );           
       WHEN EX_END_PROC_RBACK THEN

           x_message_code := -1;           
           ROLLBACK;
           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           P_PROGRAM_TYPE            => 'CUSTOM API'
                                          ,P_PROGRAM_NAME            => 'XX_INV_ORG_HIERARCHY_PKG.PROCESS_ORG_HIERARCHY'
                                          ,P_PROGRAM_ID              => NULL
                                          ,P_MODULE_NAME             => 'INV'
                                          ,P_ERROR_LOCATION          => 'EX_END_PROC_RBACK EXCEPTION'
                                          ,P_ERROR_MESSAGE_COUNT     => NULL
                                          ,P_ERROR_MESSAGE_CODE      => x_message_code
                                          ,P_ERROR_MESSAGE           => x_message_data
                                          ,P_ERROR_MESSAGE_SEVERITY  => 'MAJOR'
                                          ,P_NOTIFY_FLAG             => 'Y'
                                          ,P_OBJECT_TYPE             => 'Organization Hierarchy Interface'
                                          ,P_OBJECT_ID               => TO_CHAR(p_value)
                                          ,P_ATTRIBUTE1              => p_hierarchy_level
                                          ,P_ATTRIBUTE2              => p_description
                                          ,P_ATTRIBUTE3              => p_action
                                          ,P_RETURN_CODE             => NULL
                                          ,P_MSG_COUNT               => NULL
                                         );
       WHEN OTHERS THEN

           x_message_code := -1;

           fnd_message.set_name('XXPTP','XX_INV_0021_PRSSING_ERR');
           fnd_message.set_token('SQL_ERRM',SQLERRM);
           x_message_data := fnd_message.get;                     
           
           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           P_PROGRAM_TYPE            => 'CUSTOM API'
                                          ,P_PROGRAM_NAME            => 'XX_INV_ORG_HIERARCHY_PKG.PROCESS_ORG_HIERARCHY'
                                          ,P_PROGRAM_ID              => NULL
                                          ,P_MODULE_NAME             => 'INV'
                                          ,P_ERROR_LOCATION          => 'WHEN OTHERS EXCEPTION'
                                          ,P_ERROR_MESSAGE_COUNT     => NULL
                                          ,P_ERROR_MESSAGE_CODE      => x_message_code
                                          ,P_ERROR_MESSAGE           => x_message_data
                                          ,P_ERROR_MESSAGE_SEVERITY  => 'MAJOR'
                                          ,P_NOTIFY_FLAG             => 'Y'
                                          ,P_OBJECT_TYPE             => 'Organization Hierarchy Interface'
                                          ,P_OBJECT_ID               => TO_CHAR(p_value)
                                          ,P_ATTRIBUTE1              => p_hierarchy_level
                                          ,P_ATTRIBUTE2              => p_description
                                          ,P_ATTRIBUTE3              => p_action
                                          ,P_RETURN_CODE             => NULL
                                          ,P_MSG_COUNT               => NULL
                                         );           

    END PROCESS_ORG_HIERARCHY;

 END XX_INV_ORG_HIERARCHY_PKG;

/

SHOW ERRORS

EXIT

REM============================================================================================
REM                                   End Of Script
REM============================================================================================
