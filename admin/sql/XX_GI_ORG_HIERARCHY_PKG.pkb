create or replace 
PACKAGE BODY      XX_GI_ORG_HIERARCHY_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  xx_gi_org_hierarchy_pkg                                  |
-- | Description      : This package body will create the Org          |
-- |                    hierarchy and related reports as part of       |
-- |                    period close automation                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- |1.1      04-DEC-2007  Ramesh Kurapati  Changed OU Name to OU_US    |
-- |1.2      19-JUN-2008  Rama Dwibhashaym  Added Unprocessed Shipping |
-- |                      transactions to the report                   |
-- |1.3      10-OCT-2017  Nagendra Chitla  Added functions to get the  |
-- |                      period close date                            |
-- |1.4      09-OCT-2018  Venkateshwar Panduga  Defect#25454 - Added PO|
-- |                      Number to Month End: Inventory Transaction   |
-- |                       report fixes                                |
-- +===================================================================+

-- +===================================================================+
-- | Name  : get_parent_org_id                                         |
-- | Description      : This Function will be used to fetch org id     |
-- |                    for a given org name                           |
-- |                                                                   |
-- | Parameters :       organization name                              |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          org id                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_parent_org_id (p_org_name  IN VARCHAR2 )
  RETURN NUMBER
  IS
    ln_organization_id NUMBER;
BEGIN

        SELECT organization_id
          INTO ln_organization_id
          FROM hr_all_organization_units
         WHERE name = p_org_name ;

    RETURN (ln_organization_id) ;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
   ln_organization_id := NULL ;
   RETURN (ln_organization_id) ;
   WHEN OTHERS THEN
    RAISE ;
    xx_gi_comn_utils_pkg.write_log ('When Others Error in parent org id function'||sqlerrm);
END get_parent_org_id;
-- +===================================================================+
-- | Name  : get_timezone_count                                        |
-- | Description      : This Function will be used to fetch count      |
-- |                    for a given org name and hierarchy name        |
-- |                                                                   |
-- | Parameters :       hierarchy name and organization name           |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          count                                          |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_timezone_count (p_hierarchy_name  IN VARCHAR2,
                             p_parent_org_name IN VARCHAR2)
  RETURN NUMBER
  IS
    ln_timezone_count NUMBER;
  BEGIN

    SELECT COUNT(*)
      INTO ln_timezone_count
      FROM hr_all_organization_units hou,
           per_organization_structures pos,
           per_org_structure_versions pov,
           per_org_structure_elements poe,
           hr_all_organization_units hou2
     WHERE 1=1
       AND pos.organization_structure_id = pov.organization_structure_id
       AND pov.org_structure_version_id = poe.org_structure_version_id
       AND pos.name =  p_hierarchy_name
       AND hou2.name = p_parent_org_name
       AND hou.organization_id = poe.organization_id_child
       AND hou2.organization_id = poe.organization_id_parent ;

    RETURN (ln_timezone_count) ;

  EXCEPTION
   WHEN OTHERS THEN
    RAISE ;
   xx_gi_comn_utils_pkg.write_log ('When Others Error in Timezone function'||sqlerrm);
  END get_timezone_count;
--
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  create_org_hierarchy                                     |
-- | Description      : This procedure will create the Org             |
-- |                    hierarchy                                      |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+
PROCEDURE create_org_hierarchy(p_hierarchy IN VARCHAR2,
                               x_retcode   OUT NUMBER,
                               x_errbuf    OUT NOCOPY VARCHAR2) IS

    -- for structure api
    lb_validate BOOLEAN;
    ln_organization_structure_id NUMBER;
    ln_object_version_number   NUMBER;
   --- for version api
    ln_org_structure_version_id NUMBER;
    lb_gap_warning BOOLEAN;

BEGIN

     xx_gi_comn_utils_pkg.write_log ('Structure API values');

-- Calling organization structure API

          per_organization_structure_api.create_organization_structure
          (p_validate                       => lb_validate --IN     BOOLEAN   DEFAULT false
          ,p_effective_date                 => SYSDATE--in     date
          ,p_name                           => p_hierarchy
          ,p_business_group_id              => 0 --in     number   default null
          ,p_comments                       => NULL--in     varchar2 default null
          ,p_primary_structure_flag         => 'N'--in     varchar2 default 'N'
          ,p_request_id                     => NULL--in     number   default null
          ,p_program_application_id         => NULL--in     number   default null
          ,p_program_id                     => NULL--in     number   default null
          ,p_program_update_date            => NULL--in     date     default null
          ,p_attribute_category             => NULL--in     varchar2 default null
          ,p_attribute1                     => NULL--in     varchar2 default null
          ,p_attribute2                     => NULL--in     varchar2 default null
          ,p_attribute3                     => NULL--in     varchar2 default null
          ,p_attribute4                     => NULL--in     varchar2 default null
          ,p_attribute5                     => NULL--in     varchar2 default null
          ,p_attribute6                     => NULL--in     varchar2 default null
          ,p_attribute7                     => NULL--in     varchar2 default null
          ,p_attribute8                     => NULL--in     varchar2 default null
          ,p_attribute9                     => NULL--in     varchar2 default null
          ,p_attribute10                    => NULL--in     varchar2 default null
          ,p_attribute11                    => NULL--in     varchar2 default null
          ,p_attribute12                    => NULL--in     varchar2 default null
          ,p_attribute13                    => NULL--in     varchar2 default null
          ,p_attribute14                    => NULL--in     varchar2 default null
          ,p_attribute15                    => NULL--in     varchar2 default null
          ,p_attribute16                    => NULL--in     varchar2 default null
          ,p_attribute17                    => NULL--in     varchar2 default null
          ,p_attribute18                    => NULL--in     varchar2 default null
          ,p_attribute19                    => NULL--in     varchar2 default null
          ,p_attribute20                    => NULL--in     varchar2 default null
          ,p_position_control_structure_f   => 'N'--in     varchar2 default 'N'
          ,p_organization_structure_id      => ln_organization_structure_id--   out nocopy number
          ,p_object_version_number          => ln_object_version_number--   out nocopy number
          );

   xx_gi_comn_utils_pkg.write_log ('Structure API values');
   xx_gi_comn_utils_pkg.write_log ('p_organization_structure_id is -'||ln_organization_structure_id);
   xx_gi_comn_utils_pkg.write_log ('p_object_version_number is     -'||ln_object_version_number);

      IF ln_organization_structure_id IS NOT NULL
      THEN
-- Calling organization version creation API

            PER_ORG_STRUCTURE_VERSION_API.create_org_structure_version
            (p_validate                       => lb_validate--in     boolean  default false
            ,p_effective_date                 => SYSDATE--in     date
            ,p_organization_structure_id      => ln_organization_structure_id--6061--in     number
            ,p_date_FROM                      => SYSDATE--in     date
            ,p_version_number                 => 1 --in     number
            ,p_copy_structure_version_id      => NULL--in     number   default null
            ,p_date_to                        => NULL--in     date     default null
            ,p_request_id                     => NULL--in     number   default null
            ,p_program_application_id         => NULL--in     number   default null
            ,p_program_id                     => NULL--in     number   default null
            ,p_program_update_date            => NULL--in     date     default null
            ,p_topnode_pos_ctrl_enabled_fla   => 'N'--in     varchar2 default 'N'
            ,p_org_structure_version_id       => ln_org_structure_version_id--out nocopy number
            ,p_object_version_number          => ln_object_version_number--out nocopy number
            ,p_gap_warning                    => lb_gap_warning--out nocopy boolean
             );
       END IF; -- end ln_organization_structure_id is not null check
    COMMIT;
   xx_gi_comn_utils_pkg.write_log ('Structure version  API values');
   xx_gi_comn_utils_pkg.write_log ('Org Structure Version Id :'||ln_org_structure_version_id);
   xx_gi_comn_utils_pkg.write_log ('Object Version Number :'||ln_object_version_number);

  IF ln_organization_structure_id IS NOT NULL AND ln_org_structure_version_id IS NOT NULL THEN
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      xx_gi_comn_utils_pkg.write_out (p_hierarchy||' Structure created successfully');
      xx_gi_comn_utils_pkg.write_out ('Structure Version Number'||ln_object_version_number||' created successfully');
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
  END IF;


EXCEPTION
    WHEN OTHERS THEN
     xx_gi_comn_utils_pkg.write_log ('API When Others Error'||sqlerrm);
     x_retcode := 2 ;
     x_errbuf  := sqlerrm ;
----------------
END create_org_hierarchy;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  create_org_elements                                      |
-- | Description      : This procedure will create the Org             |
-- |                    hierarchy elements                             |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- |1.1      04-DEC-2007  Ramesh Kurapati  Changed OU Name to OU_US    |
-- +===================================================================+
-----
PROCEDURE create_org_elements(p_hierarchy_name  IN VARCHAR2
                             ,p_bucket_size IN NUMBER
                             ,x_retcode OUT NUMBER
                             ,x_errbuf  OUT NOCOPY VARCHAR2) IS

    CURSOR lcu_hierarchy is
    SELECT pos.organization_structure_id,
           pos.name,
           pov.org_structure_version_id,
           pov.version_number
      FROM PER_ORGANIZATION_STRUCTURES pos,
           PER_ORG_STRUCTURE_VERSIONS pov
     WHERE pos.organization_structure_id = pov.organization_structure_id
       AND pos.name = p_hierarchy_name ;


    CURSOR lcu_element is
    SELECT flv.meaning org_type
          ,hou.organization_id
          ,hou.name org_name
          ,hou1.name ou_name
          ,hou.business_group_id
          ,hou.attribute1 legacy_loc_id
          ,hrl.timezone_code
          ,ftt.name timezone_name
      FROM hr_all_organization_units hou,
           hr_organization_information hoi,
           org_organization_definitions ood,
           hr_all_organization_units hou1,
           hr_locations_all hrl,
           fnd_timezones_b ftb,
           fnd_timezones_tl ftt,
           fnd_lookup_values flv
     WHERE hou.organization_id = hoi.organization_id
       AND hou.organization_id = ood.organization_id
       AND hou1.organization_id = ood.operating_unit
       AND hoi.org_information_context = 'CLASS'
       AND hoi.org_information1 = 'INV'
       AND hou.location_id = hrl.location_id
       AND ftb.timezone_code  = hrl.timezone_code
       AND ftb.timezone_code  = ftt.timezone_code
       AND ftt.source_lang = 'US'
       AND hou.type = flv.lookup_code
       AND flv.lookup_type = 'ORG_TYPE'
       AND SYSDATE BETWEEN hou.date_FROM AND nvl(hou.date_to,SYSDATE)
       AND flv.language = 'US'
       AND NOT EXISTS (SELECT 'x'
                         FROM PER_ORGANIZATION_STRUCTURES pos,
                              PER_ORG_STRUCTURE_VERSIONS pov,
                              PER_ORG_STRUCTURE_ELEMENTS poe
                        WHERE pos.organization_structure_id = pov.organization_structure_id
                          AND pov.org_structure_version_id = poe.org_structure_version_id
                          AND pos.name = p_hierarchy_name
                          AND hou.organization_id = poe.organization_id_child)
       ORDER BY ftt.name;

    -- for element api
   lb_validate BOOLEAN;
   lc_warning_raised VARCHAR2(2000);
   ln_org_structure_element_id NUMBER;
   ln_object_version_number   NUMBER;
   ln_parent_org_id NUMBER ;
   ln_success_count  NUMBER := 0;
   ln_failure_count  NUMBER := 0;
   ln_bucket_size NUMBER := 150 ;


BEGIN

      xx_gi_comn_utils_pkg.write_log ('Begning the create hierarchy element API ');
      ln_bucket_size := nvl(p_bucket_size,ln_bucket_size) ;
-- Calling organization element creation API

        FOR hierarchy_rec IN lcu_hierarchy
        LOOP
           -- xx_gi_comn_utils_pkg.write_log ('In Loop - org id is '||hierarchy_rec.org_name);

   -----------
          FOR element_rec IN lcu_element
          LOOP
          xx_gi_comn_utils_pkg.write_log ('In Loop - org name is '||element_rec.org_name);
          xx_gi_comn_utils_pkg.write_log ('In Loop - org id is '||element_rec.organization_id);
          IF element_rec.org_type = 'Hierarchy Node'
             AND element_rec.ou_name = 'OU_US'--Changed from OD_US_OU by krb 12/4/07
          THEN
               ln_parent_org_id := get_parent_org_id('OD US HIERARCHY') ;
          ELSIF element_rec.org_type = 'Hierarchy Node'
             AND element_rec.ou_name = 'OU_CA' -- Changed from OD_CA_OU by krb 12/4/07
          THEN
               ln_parent_org_id := get_parent_org_id('OD CA HIERARCHY') ;
          ELSIF element_rec.ou_name = 'OU_US'--Changed from OD_US_OU by krb 12/4/07
          THEN

            IF element_rec.timezone_name = 'Eastern Time' THEN

               IF  get_timezone_count(p_hierarchy_name
                              ,'VIRTUAL ORG EST 1') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG EST 1') ;
               ELSIF get_timezone_count(p_hierarchy_name
                                   ,'VIRTUAL ORG EST 2') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG EST 2') ;
               ELSIF get_timezone_count(p_hierarchy_name
                                   ,'VIRTUAL ORG EST 3') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG EST 3') ;
               ELSE
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG EST 4') ;
               END IF;


            ELSIF element_rec.timezone_name = 'Central Time' THEN
               IF  get_timezone_count(p_hierarchy_name
                              ,'VIRTUAL ORG CST 1') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG CST 1') ;
               ELSIF get_timezone_count(p_hierarchy_name
                                   ,'VIRTUAL ORG CST 2') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG CST 2') ;
               ELSIF get_timezone_count(p_hierarchy_name
                                   ,'VIRTUAL ORG CST 3') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG CST 3') ;
               ELSE
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG CST 4') ;
               END IF;

            ELSIF element_rec.timezone_name = 'Mountain Time' THEN
               IF  get_timezone_count(p_hierarchy_name
                              ,'VIRTUAL ORG MST 1') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG MST 1') ;
               ELSE
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG MST 2') ;
               END IF;
            ELSIF element_rec.timezone_name = 'Pacific Time' THEN
               IF  get_timezone_count(p_hierarchy_name
                              ,'VIRTUAL ORG PST 1') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG PST 1') ;
               ELSIF get_timezone_count(p_hierarchy_name
                                   ,'VIRTUAL ORG PST 2') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG PST 2') ;
               ELSIF get_timezone_count(p_hierarchy_name
                                   ,'VIRTUAL ORG PST 3') < ln_bucket_size
               THEN
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG PST 3') ;
               ELSE
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG PST 4') ;
               END IF;

            ELSE
               ln_parent_org_id := get_parent_org_id('VIRTUAL ORG PST 1') ;
            END IF; -- end timezone_name check
          ELSIF element_rec.ou_name = 'OU_CA' -- Changed from OD_CA_OU By krb 12/4/07
          THEN
               ln_parent_org_id := get_parent_org_id('OD CA HIERARCHY') ;
          END IF ;  -- element_rec.org_type check

            IF ln_parent_org_id IS NOT NULL
               AND element_rec.org_name != 'OD US HIERARCHY'
               AND element_rec.org_name != 'OD CA HIERARCHY'
            THEN
           -- xx_gi_comn_utils_pkg.write_log ('In Loop - parent org id is '||ln_parent_org_id);
            HR_HIERARCHY_ELEMENT_API.create_hierarchy_element
                    (p_validate                      => lb_validate
                    ,p_organization_id_parent        => ln_parent_org_id
                    ,p_org_structure_version_id      => hierarchy_rec.org_structure_version_id
                    ,p_organization_id_child         => element_rec.organization_id
                    ,p_business_group_id             => element_rec.business_group_id
                    ,p_effective_date                => SYSDATE + 1
                    ,p_date_from                     => SYSDATE + 1
                    ,p_security_profile_id           => 0
                    ,p_view_all_orgs                 => 'Y'
                    ,p_end_of_time                   => NULL
                    ,p_hr_installed                  => NULL
                    ,p_pa_installed                  => NULL
                    ,p_pos_control_enabled_flag      => 'N'
                    ,p_warning_raised                => lc_warning_raised --IN OUT NOCOPY VARCHAR2
                    ,p_org_structure_element_id      => ln_org_structure_element_id --out nocopy number
                    ,p_object_version_number         => ln_object_version_number --out nocopy number
                    );

                xx_gi_comn_utils_pkg.write_log ('Element API warning raised :'||lc_warning_raised);
                xx_gi_comn_utils_pkg.write_log ('Element API org stru ele id :'||ln_org_structure_element_id);
                xx_gi_comn_utils_pkg.write_log ('Element API obj version num :'||ln_object_version_number);

                IF ln_org_structure_element_id IS NOT NULL
                THEN
                 COMMIT;
                 ln_success_count := ln_success_count + 1 ;
                 xx_gi_comn_utils_pkg.write_log ('Org Element created for :'||element_rec.org_name);
                ELSE
                 ln_failure_count := ln_failure_count + 1 ;
                 xx_gi_comn_utils_pkg.write_log ('Org Element Not created for :'||element_rec.org_name);
                END IF;

             ELSE
                 xx_gi_comn_utils_pkg.write_log ('Unable to find the Parent ID');
             END IF;  --- end ln_parent_org_id is not null check
             xx_gi_comn_utils_pkg.write_log ('Element API Loop completed');
          END LOOP;    -- end element loop
          xx_gi_comn_utils_pkg.write_log ('Hierarchy Loop completed');
        END LOOP;  -- end hierarchy loop
   ---------
      IF (ln_success_count = 0 AND ln_failure_count = 0) THEN
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      xx_gi_comn_utils_pkg.write_out ('No Organizations found for Hierarchy Element creation');
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      END IF;

      IF ln_success_count > 0 THEN
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      xx_gi_comn_utils_pkg.write_out ('Number of Hierarchy Element Records created :'||ln_success_count);
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      END IF;

      IF ln_failure_count > 0 THEN
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      xx_gi_comn_utils_pkg.write_out ('Number of Hierarchy Records Failed :'||ln_failure_count);
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      END IF;

EXCEPTION
    WHEN OTHERS THEN
     xx_gi_comn_utils_pkg.write_log ('Element API When Others Error'||sqlerrm);
     x_retcode := 2 ;
     x_errbuf  := sqlerrm ;
END create_org_elements;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  pending_transactions                                     |
-- | Description      : This procedure will show the errors            |
-- |                    from the interface tables                      |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+
PROCEDURE pending_transactions(x_errbuf     OUT NOCOPY VARCHAR2,
                               x_retcode    OUT NUMBER,
                               p_period_name IN VARCHAR2) IS

        CURSOR lcu_pending_trans(p_schedule_close_date DATE) is
        SELECT decode(mti.process_flag,3,'Error','Unprocessed') status,
               nvl(hou.attribute1,'999999') loc_id,
               hou.name loc_name,
               'MTI' table_name,
               --'MTL_TRANSACTIONS_INTERFACE' table_name,
               COUNT(*) count,
               nvl(round(sum(mti.transaction_quantity * cic.item_cost),2),0) tran_cost,
               nvl(mti.error_code,'No Error Code') error_code,
               substr(mti.error_explanation,1,60) error_explanation
          FROM mtl_transactions_interface mti,
               hr_all_organization_units hou,
               cst_item_costs cic
         WHERE mti.organization_id = hou.organization_id
           AND mti.organization_id = cic.organization_id (+)
           AND mti.inventory_item_id = cic.inventory_item_id (+)
           AND (mti.error_code IS NOT NULL OR mti.error_explanation IS NOT NULL)
           AND mti.transaction_date <= p_schedule_close_date
      GROUP BY mti.process_flag,
               hou.attribute1 ,
               hou.name,
               mti.error_code,mti.error_explanation
      UNION ALL
        SELECT rcv.processing_status_code status,
               nvl(hou.attribute1,'999999') loc_id,
               nvl(hou.name,'No Org Found') loc_name,
               'RTI' table_name,
               --nvl(pie.table_name,'RCV_TRANSACTIONS_INTERFACE') table_name,
               COUNT(*) count,
               nvl(round(sum(rcv.quantity * cic.item_cost),2),0) tran_cost,
               nvl(pie.error_message_name,'No Error Code') error_code,
               nvl(substr(pie.error_message,1,60),'No Error Message') error_explanation
          FROM rcv_transactions_interface rcv,
               rcv_headers_interface rch,
               hr_all_organization_units hou,
               po_interface_errors pie,
               cst_item_costs cic
         WHERE rcv.to_organization_id = hou.organization_id  (+)
           AND rch.header_interface_id = rcv.header_interface_id
           AND rcv.destination_type_code = 'INVENTORY'
           AND rcv.to_organization_id = cic.organization_id (+)
           AND rcv.item_id = cic.inventory_item_id (+)
           AND rch.asn_type IS NULL
           AND (pie.error_message_name IS NOT NULL OR pie.error_message IS NOT NULL)
           AND rcv.transaction_date <= p_schedule_close_date
           AND rch.header_interface_id = pie.interface_header_id (+)
           AND pie.interface_line_id  = rcv.interface_transaction_id(+)
      GROUP BY rcv.processing_status_code,
               rcv.transaction_status_code,
               hou.attribute1 ,
               hou.name,
               nvl(pie.table_name,'RCV_TRANSACTIONS_INTERFACE'),
               pie.error_message_name ,
               pie.error_message
      UNION ALL
       SELECT 'Error' status,
               nvl(hou.attribute1,'999999') loc_id,
               hou.name loc_name,
               'MMTT' table_name,
               --'MTL_MATERIAL_TRANSACTIONS_TEMP' table_name,
               COUNT(*) count,
               nvl(round(sum(mmtt.transaction_cost),2),0) tran_cost,
               nvl(mmtt.error_code,'No Error Code') error_code,
               nvl(substr(mmtt.error_explanation,1,60),'No Error Explanation') error_explanation
          FROM mtl_material_transactions_temp mmtt,
               hr_all_organization_units hou
         WHERE mmtt.organization_id = hou.organization_id
           AND (mmtt.error_code IS NOT NULL OR mmtt.error_explanation IS NOT NULL)
           AND mmtt.transaction_date <= p_schedule_close_date
      GROUP BY hou.attribute1 ,
               hou.name,
               mmtt.error_code,mmtt.error_explanation
     UNION ALL
        SELECT 'Error' status,
               nvl(hou.attribute1,'999999') loc_id,
               hou.name loc_name,
               'MMT' table_name,
               --'MTL_MATERIAL_TRANSACTIONS' table_name,
               COUNT(*) count,
               nvl(round(sum(mmt.transaction_cost),2),0) tran_cost,
               nvl(mmt.error_code,'No Error Code') error_code,
               nvl(substr(mmt.error_explanation,1,60),'No Error Explanation') error_explanation
          FROM mtl_material_transactions mmt,
               hr_all_organization_units hou
         WHERE mmt.organization_id = hou.organization_id
           AND mmt.costed_flag = 'E'
           AND mmt.transaction_date <= p_schedule_close_date
      GROUP BY hou.attribute1 ,
               hou.name,
               mmt.error_code,mmt.error_explanation
      UNION ALL         
        select 'Unprocessed' status, 
               nvl(hou.attribute1,'999999') loc_id,
               hou.name loc_name,
               'WSH' table_name,
               COUNT(*) count,
               nvl(round(sum(wdd.shipped_quantity * wdd.unit_price),2),0) tran_cost,
               'No Error Code' error_code,
               'Unprocessed' error_explanation
          from wsh_delivery_details wdd, wsh_delivery_assignments wda,
               wsh_new_deliveries wnd, wsh_delivery_legs wdl, wsh_trip_stops wts,
               hr_all_organization_units hou
         where
               wdd.source_code = 'OE'
           and wdd.released_status = 'C'
           and wdd.inv_interfaced_flag in ('N' ,'P')
           and wdd.organization_id = hou.organization_id
           and wda.delivery_detail_id = wdd.delivery_detail_id
           and wnd.delivery_id = wda.delivery_id
           and wnd.status_code in ('CL','IT')
           and wdl.delivery_id = wnd.delivery_id
           and wts.pending_interface_flag in ('Y', 'P')
           and trunc(wts.actual_departure_date) <= p_schedule_close_date
           and wdl.pick_up_stop_id = wts.stop_id
      GROUP BY hou.attribute1 ,
               hou.name               
       ORDER BY 3,4 ;


       CURSOR lcu_detail_error (p_schedule_close_date DATE) IS
       SELECT  nvl(hou.attribute1,'999999') loc_id,
               hou.name loc_name,
               'MTI' table_name,
               mtt.transaction_type_name tran_type_name,
               NVL(MTI.ATTRIBUTE5,0) DOC_NUMBER,
               NVL((SELECT ATTRIBUTE_CATEGORY 
                   FROM po_headers_all where segment1  =NVL(MTI.ATTRIBUTE5,0)),NULL)  DOC_TYPE,   ---Added for Defect#25454 
               trunc(mti.transaction_date) tran_date,
               msi.segment1 sku,
               mti.subinventory_code subinv_code,
               nvl(mti.transaction_quantity * cic.item_cost,0) tran_cost,
               nvl(mti.error_code,'No Error Code') error_code,
               mti.error_explanation error_explanation
          FROM mtl_transactions_interface mti,
               mtl_transaction_types mtt,
               mtl_system_items_b msi,
               hr_all_organization_units hou,
               cst_item_costs cic
         WHERE mti.organization_id = hou.organization_id
           AND mti.transaction_type_id = mtt.transaction_type_id
           AND mti.inventory_item_id = msi.inventory_item_id
           AND mti.organization_id = msi.organization_id
           AND mti.organization_id = cic.organization_id (+)
           AND mti.inventory_item_id = cic.inventory_item_id (+)
           AND (mti.error_code IS NOT NULL OR mti.error_explanation IS NOT NULL)
           AND mti.transaction_date <= p_schedule_close_date
      UNION ALL
        SELECT nvl(hou.attribute1,'999999') loc_id,
               nvl(hou.name,'No Org Found') loc_name,
               'RTI' table_name,
               rcv.transaction_type tran_type_name,
               NVL(RCH.RECEIPT_NUM,RCV.ATTRIBUTE8) DOC_NUMBER,
               NVL((SELECT ATTRIBUTE_CATEGORY 
                   FROM PO_HEADERS_ALL WHERE SEGMENT1  =SUBSTR( RCV.ATTRIBUTE8, INSTR( RCV.ATTRIBUTE8, '|', 1, 1 )+1, 
                                                                INSTR( rcv.ATTRIBUTE8,'|',1,2 )-INSTR( rcv.ATTRIBUTE8,'|',1,1 )-1 )),NULL)  DOC_TYPE,   ---Added for Defect#25454 
               trunc(rcv.transaction_date) tran_date,
               msi.segment1 sku,
               rcv.subinventory subinv_code,
               round(nvl(rcv.quantity * cst.item_cost ,0),2) tran_cost,
               nvl(pie.error_message_name,'No Error Code') error_code,
               nvl(pie.error_message,'No Error Message') error_explanation
          FROM rcv_transactions_interface rcv,
               rcv_headers_interface rch,
               hr_all_organization_units hou,
               po_interface_errors pie,
               cst_item_costs cst,
               mtl_system_items_b msi
         WHERE rcv.to_organization_id = hou.organization_id  (+)
           AND rch.header_interface_id = rcv.header_interface_id
           AND rcv.destination_type_code = 'INVENTORY'
           AND rch.asn_type IS NULL
           AND rcv.item_id = cst.inventory_item_id (+)
           AND rcv.to_organization_id = cst.organization_id (+)
           AND rcv.to_organization_id = msi.organization_id (+)
           AND rcv.item_id = msi.inventory_item_id (+)
           AND (pie.error_message_name IS NOT NULL OR pie.error_message IS NOT NULL)
           AND rcv.transaction_date <= p_schedule_close_date
           AND rch.header_interface_id = pie.interface_header_id (+)
           AND pie.interface_line_id  = rcv.interface_transaction_id(+)
      UNION ALL
       SELECT  nvl(hou.attribute1,'999999') loc_id,
               hou.name loc_name,
               'MMTT' table_name,
               mtt.transaction_type_name tran_type_name,
               NVL(MMTT.ATTRIBUTE5,0) DOC_NUMBER,
               NVL((SELECT ATTRIBUTE_CATEGORY 
                   FROM po_headers_all where segment1  =MMTT.ATTRIBUTE5),NULL)  DOC_TYPE,   ---Added for Defect#25454 
               trunc(mmtt.transaction_date) tran_date,
               msi.segment1 sku,
               mmtt.subinventory_code subinv_code,
               round(nvl(mmtt.transaction_cost,0),2) tran_cost,
               nvl(mmtt.error_code,'No Error Code') error_code,
               nvl(mmtt.error_explanation,'No Error Explanation') error_explanation
          FROM mtl_material_transactions_temp mmtt,
               mtl_transaction_types mtt,
               mtl_system_items_b msi,
               hr_all_organization_units hou
         WHERE mmtt.organization_id = hou.organization_id
           AND mmtt.transaction_type_id = mtt.transaction_type_id
           AND mmtt.organization_id = msi.organization_id
           AND mmtt.inventory_item_id = msi.inventory_item_id
           AND (mmtt.error_code IS NOT NULL OR mmtt.error_explanation IS NOT NULL)
           AND mmtt.transaction_date <= p_schedule_close_date
     UNION ALL
        SELECT nvl(hou.attribute1,'999999') loc_id,
               hou.name loc_name,
               'MMT' table_name,
               mtt.transaction_type_name tran_type_name,
               NVL(MMT.ATTRIBUTE5,0) DOC_NUMBER,
               NVL((SELECT ATTRIBUTE_CATEGORY 
                   FROM po_headers_all where segment1  =mmt.ATTRIBUTE5),NULL)  DOC_TYPE,   ---Added for Defect#25454 
               trunc(mmt.transaction_date) tran_date,
               msi.segment1 sku,
               mmt.subinventory_code subinv_code,
               round(nvl(mmt.transaction_cost,0),2) tran_cost,
               nvl(mmt.error_code,'No Error Code') error_code,
               nvl(mmt.error_explanation,'No Error Explanation') error_explanation
          FROM mtl_material_transactions mmt,
               mtl_transaction_types mtt,
               mtl_system_items_b msi,
               hr_all_organization_units hou
         WHERE mmt.organization_id = hou.organization_id
           AND mmt.transaction_type_id = mtt.transaction_type_id
           AND mmt.organization_id = msi.organization_id
           AND mmt.inventory_item_id = msi.inventory_item_id
           AND mmt.costed_flag = 'E'
           AND mmt.transaction_date <= p_schedule_close_date
       UNION ALL    
        select nvl(hou.attribute1,'999999') loc_id,
               hou.name loc_name,
               'WSH' table_name,
               wdd.source_header_type_name tran_type_name,
               NVL(WDD.CUST_PO_NUMBER,0) DOC_NUMBER,
               NVL((SELECT ATTRIBUTE_CATEGORY 
                   FROM po_headers_all where segment1  =WDD.CUST_PO_NUMBER),NULL)  DOC_TYPE,   ---Added for Defect#25454 
               trunc(wts.actual_departure_date) tran_date,
               msi.segment1 sku,
               wdd.subinventory subinv_code,
               nvl(wdd.shipped_quantity * wdd.unit_price,0) tran_cost,
               'No Error Code' error_code,
               'Unprocessed' error_explanation               
          from wsh_delivery_details wdd, wsh_delivery_assignments wda,
               wsh_new_deliveries wnd, wsh_delivery_legs wdl, wsh_trip_stops wts,
               hr_all_organization_units hou,mtl_system_items_b msi
         where
               wdd.source_code = 'OE'
           and wdd.released_status = 'C'
           and wdd.inv_interfaced_flag in ('N' ,'P')
           and wdd.organization_id = hou.organization_id
           and wda.delivery_detail_id = wdd.delivery_detail_id
           and wnd.delivery_id = wda.delivery_id
           and wnd.status_code in ('CL','IT')
           and wdl.delivery_id = wnd.delivery_id
           and wts.pending_interface_flag in ('Y', 'P')
           and wdd.organization_id = msi.organization_id
           and wdd.inventory_item_id = msi.inventory_item_id
           and trunc(wts.actual_departure_date) <= p_schedule_close_date
           and wdl.pick_up_stop_id = wts.stop_id           
       ORDER BY 2,3 ;

   ld_schedule_close_date DATE ;

BEGIN
      xx_gi_comn_utils_pkg.write_log ('Period Name :'||p_period_name);
      xx_gi_comn_utils_pkg.write_log ('Begning the pending transaction report');

-- Calling organization pending transactions report
      xx_gi_comn_utils_pkg.pvg_sql_point :=  100;
     --
      -- Header
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(RPAD (' ', 50, ' ') || 'Inventory Transactions Error Report');
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out('Period Name :'||p_period_name);
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out('Summary Report');
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(RPAD ('-', 180, '-'));
      xx_gi_comn_utils_pkg.write_out(
         --RPAD ('Status', 15, ' ') || ' ' ||
         LPAD ('Loc ID', 6, ' ') || ' ' ||
         RPAD ('Loc Name', 30, ' ') || ' ' ||
         RPAD ('Table Name', 10, ' ') || ' ' ||
         RPAD ('Count', 10, ' ') || ' ' ||
         RPAD ('Transaction Cost', 16, ' ') || ' ' ||
         RPAD ('Error Code', 20, ' ') || ' ' ||
         RPAD ('Error Explanation', 60, ' '));
      --
      xx_gi_comn_utils_pkg.write_out(
         --RPAD ('-', 15, '-') || ' ' ||
         LPAD ('-', 6, '-') || ' ' ||
         RPAD ('-', 30, '-') || ' ' ||
         RPAD ('-', 10, '-') || ' ' ||
	 RPAD ('-', 10, '-') || ' ' ||
         RPAD ('-', 16, '-') || ' ' ||
         RPAD ('-', 20, '-') || ' ' ||
         RPAD ('-', 60, '-'));

        BEGIN

        SELECT end_date
          INTO ld_schedule_close_date
          FROM gl_period_statuses
         WHERE application_id = 101
           AND set_of_books_id = pvg_sob_id
           AND period_name = p_period_name ;

        EXCEPTION
          WHEN TOO_MANY_ROWS THEN
          xx_gi_comn_utils_pkg.write_log ('Too many rows returned '||sqlerrm);
          WHEN OTHERS THEN
          xx_gi_comn_utils_pkg.write_log ('When Others Error in schedule close date'||sqlerrm);

        END;

        FOR pending_trans_rec IN lcu_pending_trans(ld_schedule_close_date)
        LOOP
            xx_gi_comn_utils_pkg.write_log ('In Loop -');

             --
             xx_gi_comn_utils_pkg.write_out(
                --RPAD (pending_trans_rec.status, 15, ' ') || ' ' ||
                LPAD (pending_trans_rec.loc_id, 6, ' ') || ' ' ||
                RPAD (pending_trans_rec.loc_name, 30, ' ') || ' ' ||
                RPAD (pending_trans_rec.table_name, 10, ' ') || ' ' ||
                RPAD (pending_trans_rec.count, 10, ' ') || ' ' ||
                LPAD (to_char(pending_trans_rec.tran_cost,'999,999,999.90'), 16, ' ') || ' ' ||
                RPAD (pending_trans_rec.error_code, 20, ' ') || ' ' ||
                RPAD (pending_trans_rec.error_explanation, 60, ' '));
             --
             --
             -- xx_gi_comn_utils_pkg.write_out(' ');

   -----------
        END LOOP;  -- end pending trans loop
      xx_gi_comn_utils_pkg.write_out(RPAD ('-', 168, '-'));
      xx_gi_comn_utils_pkg.write_out(' ');
   ---------
     xx_gi_comn_utils_pkg.pvg_sql_point :=  500;
     --
      -- Header
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(' ');
      --xx_gi_comn_utils_pkg.write_out(RPAD (' ', 50, ' ') || 'Detail Report');
      xx_gi_comn_utils_pkg.write_out('Detail Report');
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(RPAD ('-', 180, '-'));
      xx_gi_comn_utils_pkg.write_out(
         LPAD ('Loc ID', 6, ' ') || ' ' ||
         RPAD ('Loc Name', 30, ' ') || ' ' ||
         RPAD ('Table Name', 5, ' ') || ' ' ||
         RPAD ('Transaction Type', 15, ' ') || ' ' ||
         RPAD ('Doc Number', 10, ' ') || ' ' ||
         RPAD ('Doc Type', 20, ' ') || ' ' ||                   --------Added for Defect#25454 
         RPAD ('Tran Date', 10, ' ') || ' ' ||
         RPAD ('SKU Number', 10, ' ') || ' ' ||
         RPAD ('SubInventory', 10, ' ') || ' ' ||
         RPAD ('Transaction Cost', 16, ' ') || ' ' ||
         RPAD ('Error Code', 20, ' ') || ' ' ||
         RPAD ('Error Explanation', 40, ' '));
      --
      xx_gi_comn_utils_pkg.write_out(
         LPAD ('-', 6, '-') || ' ' ||
         RPAD ('-', 30, '-') || ' ' ||
         RPAD ('-', 5, '-') || ' ' ||
         RPAD ('-', 15, '-') || ' ' ||
         RPAD ('-', 10, '-') || ' ' ||
         RPAD ('-', 20, '-') || ' ' ||                        --------Added for Defect#25454 
         RPAD ('-', 10, '-') || ' ' ||
         RPAD ('-', 10, '-') || ' ' ||
	     RPAD ('-', 10, '-') || ' ' ||
         RPAD ('-', 16, '-') || ' ' ||
         RPAD ('-', 20, '-') || ' ' ||
         RPAD ('-', 40, '-'));


        FOR detail_rec IN lcu_detail_error(ld_schedule_close_date)
        LOOP
            xx_gi_comn_utils_pkg.write_log ('In detail Loop -');
             --
             xx_gi_comn_utils_pkg.write_out(
                LPAD (detail_rec.loc_id, 6, ' ') || ' ' ||
                RPAD (detail_rec.loc_name, 30, ' ') || ' ' ||
                RPAD (detail_rec.table_name, 5, ' ') || ' ' ||
                RPAD (detail_rec.tran_type_name, 15, ' ') || ' ' ||
                RPAD (NVL(DETAIL_REC.DOC_NUMBER,0), 10, ' ') || ' ' ||
                RPAD (nvl(detail_rec.doc_type,0), 20, ' ') || ' ' ||   --------Added for Defect#25454  
                RPAD (nvl(detail_rec.tran_date,trunc(sysdate)), 10, ' ') || ' ' ||
                RPAD (detail_rec.sku, 10, ' ') || ' ' ||
                RPAD (detail_rec.subinv_code, 10, ' ') || ' ' ||
                LPAD (to_char(detail_rec.tran_cost,'999,999,999.90'), 16, ' ') || ' ' ||
                RPAD (detail_rec.error_code, 20, ' ') || ' ' ||
                RPAD (detail_rec.error_explanation, 40, ' '));
             --
             --

             --xx_gi_comn_utils_pkg.write_out(' ');

   -----------
        END LOOP;  -- end pending trans loop

      xx_gi_comn_utils_pkg.write_out(RPAD ('-', 180, '-'));
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(RPAD (' ', 50, ' ') || '***End of Report***');



EXCEPTION
    WHEN OTHERS THEN
     xx_gi_comn_utils_pkg.write_log ('API When Others Error'||sqlerrm);
     x_retcode := 2 ;
     x_errbuf  := sqlerrm ;
   ----------------

END pending_transactions;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  Closed_period_count                                      |
-- | Description      : This procedure will show the count of open     |
-- |                    and closed period for inv orgs                 |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+
PROCEDURE Closed_period_count (x_errbuf     OUT NOCOPY VARCHAR2,
                               x_retcode    OUT NUMBER,
                               p_period_name IN VARCHAR2) IS

        CURSOR lcu_period_count is
        SELECT COUNT(*) COUNT,decode(org.open_flag,'Y','Open','Close') status
          FROM org_acct_periods org,
               hr_all_organization_units hou
         WHERE 1=1
           AND org.period_name = p_period_name
           AND org.organization_id = hou.organization_id
           AND hou.type NOT IN('TMPL','MAS','VAL','HNODE')
        GROUP BY org.open_flag ;

        CURSOR lcu_details IS
        SELECT hou.attribute1 loc_id,
               hou.name loc_name
          FROM org_acct_periods org,
               hr_all_organization_units hou,
               org_organization_definitions ood
        WHERE 1=1
          AND org.period_name = p_period_name
          AND org.open_flag = 'Y'
          AND ood.organization_id = hou.organization_id
          AND org.organization_id = hou.organization_id
          AND hou.type NOT IN('TMPL','MAS','VAL','HNODE')
        ORDER BY 1,2;

   lv_open_count NUMBER ;
   lv_closed_count NUMBER;
   ld_schedule_close_date DATE ;

BEGIN
      xx_gi_comn_utils_pkg.write_log ('Period Name :'||p_period_name);
      xx_gi_comn_utils_pkg.write_log ('Begning the Period Count report');
-- Calling organization pending transactions report
      xx_gi_comn_utils_pkg.pvg_sql_point :=  100;
     --
      -- Header
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(RPAD (' ', 20, ' ') || 'OD GI Period Count Report');
      xx_gi_comn_utils_pkg.write_out(' ');
      xx_gi_comn_utils_pkg.write_out(RPAD ('-', 80, '-'));
      xx_gi_comn_utils_pkg.write_out('Name of the Period :'||p_period_name);

        FOR period_count_rec IN lcu_period_count
        LOOP
            xx_gi_comn_utils_pkg.write_log ('In Loop -');
             --
             IF period_count_rec.status = 'Open'
             THEN
               xx_gi_comn_utils_pkg.write_out(
                'Number of Inventory Organizations Period Open  :'||period_count_rec.count);
             ELSE
               xx_gi_comn_utils_pkg.write_out(
                'Number of Inventory Organizations Period Closed:'||period_count_rec.count);
             END IF;
             --
        END LOOP;  -- end pending trans loop

         SELECT COUNT(*)
           INTO lv_open_count
          FROM org_acct_periods org,
               hr_all_organization_units hou,
               org_organization_definitions ood
         WHERE 1=1
           AND org.period_name = p_period_name
           AND org.open_flag = 'Y'
           AND ood.organization_id = hou.organization_id
           AND org.organization_id = hou.organization_id
           AND hou.type NOT IN('TMPL','MAS','VAL','HNODE');

        IF lv_open_count > 0
        THEN
              -- Details
        xx_gi_comn_utils_pkg.write_out(' ');
        xx_gi_comn_utils_pkg.write_out(' ');
        xx_gi_comn_utils_pkg.write_out('Details of Inventory Organizations that are Open:');
        xx_gi_comn_utils_pkg.write_out(' ');
        xx_gi_comn_utils_pkg.write_out('Loc ID'||'  '||
                                       'Location Name');
        xx_gi_comn_utils_pkg.write_out(
         LPAD ('-', 6, '-') || ' ' ||
         RPAD ('-', 30, '-'));

          FOR details_rec IN lcu_details
          LOOP
          xx_gi_comn_utils_pkg.write_log ('In Loop -');
            --
             xx_gi_comn_utils_pkg.write_out(
                LPAD (details_rec.loc_id, 6, ' ') || '   ' ||
                RPAD (details_rec.loc_name, 40, ' '));
             --
          END LOOP; --- end details_rec
             --
             xx_gi_comn_utils_pkg.write_out(' ');
             xx_gi_comn_utils_pkg.write_out(' ');
             xx_gi_comn_utils_pkg.write_out(
                (RPAD (' ', 20, ' ') ||'***END OF REPORT*** '));
        END IF;
   ---------
EXCEPTION
    WHEN OTHERS THEN
     xx_gi_comn_utils_pkg.write_log ('API When Others Error'||sqlerrm);
     x_retcode := 2 ;
     x_errbuf  := sqlerrm ;
   ----------------
END closed_period_count;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  main                                                     |
-- | Description      : This procedure will call the hierarchy and     |
-- |                    hierarchy element procedures                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+
PROCEDURE main(
      x_errbuf     OUT NOCOPY VARCHAR2,
      x_retcode    OUT NUMBER,
      p_hierarchy  IN VARCHAR2,
      p_bucket_size IN NUMBER
  )
IS

    CURSOR lcu_org_hierarchy IS
    SELECT COUNT(*)
      FROM PER_ORGANIZATION_STRUCTURES pos,
           PER_ORG_STRUCTURE_VERSIONS pov
     WHERE pos.organization_structure_id = pov.organization_structure_id
       AND pos.name = p_hierarchy ;

  r_mtl_param            mtl_parameters%ROWTYPE;
  lv_org_count           NUMBER ;
  lv_trans_count         NUMBER ;
  lv_hdr_count           NUMBER ;

BEGIN

   xx_gi_comn_utils_pkg.pvg_sql_point :=  1000;
   xx_gi_comn_utils_pkg.write_log ('Hierarchy Name :'||p_hierarchy);
   xx_gi_comn_utils_pkg.write_log ('Bucket Size    :'||p_bucket_size);

   xx_gi_comn_utils_pkg.write_log ('Starting Hierarchy Creation Program Loop');
  -- Header Loop Start

    OPEN lcu_org_hierarchy;
    FETCH lcu_org_hierarchy INTO lv_org_count;

    IF lcu_org_hierarchy%found THEN
    --
      IF lv_org_count > 1 THEN
      --
        CLOSE lcu_org_hierarchy;
        xx_gi_comn_utils_pkg.write_log ('More than one Hierarchy found for the same name');
      --
      ELSIF lv_org_count = 1 THEN
      xx_gi_comn_utils_pkg.write_log ('Before Hierarchy Element Procedure');
      create_org_elements(p_hierarchy,p_bucket_size,x_retcode,x_errbuf) ;
      xx_gi_comn_utils_pkg.write_log ('After Hierarchy Element Procedure');
    --
      ELSIF lv_org_count = 0 THEN
        xx_gi_comn_utils_pkg.write_log ('Before Hierarchy Procedure');
        create_org_hierarchy(p_hierarchy,x_retcode,x_errbuf) ;
        xx_gi_comn_utils_pkg.write_log ('After Hierarchy Procedure');
        xx_gi_comn_utils_pkg.write_log ('Before Hierarchy Element Procedure');
        create_org_elements(p_hierarchy,p_bucket_size,x_retcode,x_errbuf) ;
        xx_gi_comn_utils_pkg.write_log ('After Hierarchy Element Procedure');
      END IF; -- end lv_org_count check

    END IF; -- end lcu_org_hierarchy%found check

    CLOSE lcu_org_hierarchy;
  --
  --
   xx_gi_comn_utils_pkg.pvg_sql_point :=  1100;
   xx_gi_comn_utils_pkg.write_log('Completed Hierarchy Creation Program');
  --
  COMMIT;
  --
EXCEPTION
   WHEN OTHERS THEN
      xx_gi_comn_utils_pkg.pvg_sql_point :=  1200;
      xx_gi_comn_utils_pkg.write_log ('********************************************************');
      xx_gi_comn_utils_pkg.write_log ('Following Exception occured in Org Creation Program.');
      xx_gi_comn_utils_pkg.write_log (SQLERRM);
      xx_gi_comn_utils_pkg.write_log ('********************************************************');
      x_retcode := 2 ;
      x_errbuf  := sqlerrm ;
END Main;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  Closed_period_count                                      |
-- | Description      : This procedure will return the scheduled close | 
-- | date to the concurrent program 'OD: GI Inventory Transactions     | 
-- | Error Report(Excel)'                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 05-OCT-2017  Nagendra         Initial draft version       |
-- |1.0      06-OCT-2017  Nagendra         Baselined after testing     |
-- +===================================================================+  
   FUNCTION beforereport(p_period_name IN VARCHAR2)
      RETURN BOOLEAN
   IS
      errbuf   VARCHAR2 (2000);
   BEGIN
      BEGIN
         SELECT end_date
          INTO gn_schedule_close_date
          FROM gl_period_statuses
         WHERE application_id = 101
           AND set_of_books_id = pvg_sob_id
           AND period_name = p_period_name ;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            errbuf := 'Too many rows returned '||sqlerrm;
            raise_application_error (-20101, errbuf);
         WHEN OTHERS
         THEN
            errbuf := 'When Others Error in schedule close date'||sqlerrm;
            raise_application_error (-20101, errbuf);
      END;
      RETURN (TRUE);
   END;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  Closed_period_count                                      |
-- | Description      : This procedure will return the scheduled close | 
-- | date to the concurrent program 'OD: GI Inventory Transactions     | 
-- | Error Report(Excel)'                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 05-OCT-2017  Nagendra         Initial draft version       |
-- |1.0      06-OCT-2017  Nagendra         Baselined after testing     |
-- +===================================================================+  
   FUNCTION sch_cls_date_p
      RETURN DATE
   IS
   BEGIN
      RETURN gn_schedule_close_date;
   END;
-----
END;
/
