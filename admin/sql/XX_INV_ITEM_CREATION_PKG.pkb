SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_INV_ITEM_CREATION_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE
create or replace PACKAGE BODY xx_inv_item_creation_pkg
AS
-- +=============================================================================================+
-- |                       Oracle GSD  (India)                                                   |
-- |                        Hyderabad  India                                                     |
-- +=============================================================================================+
-- | Name         : xx_inv_item_creation_pkg.pkb                                                 |
-- | Description  : This package is used to validate the data passed and Interface the item      |
-- |                using API,Assign to required Inventory Organization, Add to the category,    |
-- |                Approved Supplier List and to Sourcing rule set.                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |V1.0      01-Jul-2011  Sreenivasa Tirumala  Initial draft version                            |
-- +=============================================================================================+
   gv_messages   VARCHAR2 (4000);
   gn_user_id    NUMBER;

-- +=============================================================================+
-- | PROCEDURE NAME : create_item_process                                        |
-- | DESCRIPTION    : This procedure is the main wrapper which calls all other   |
-- |                  programs for Creation or Updation of item and assigns item |
-- |                  to the required Inventory Org, Add to Category, ASL and    |
-- |                  Souricng rule set                                          |
-- |                                                                             |
-- | Parameters  :  None                                                         |
-- | Returns     :  x_item_id              OUT NOCOPY NUMBER                     |
-- |                x_success_msg          OUT NOCOPY VARCHAR2                   |
-- |                p_item_description     IN         VARCHAR2                   |
-- |                p_store                IN         VARCHAR2                   |
-- |                p_primary_uom_code     IN         VARCHAR2                   |
-- |                p_list_price_per_unit  IN         NUMBER,                    |
-- |                p_dummy_sku            IN         VARCHAR2                   |
-- |                p_vendor_sku           IN         VARCHAR2                   |
-- |                p_item_list_price      IN         VARCHAR2                   |
-- +=============================================================================+
   PROCEDURE create_item_process (
      x_item_id               OUT NOCOPY      NUMBER,
      x_success_msg           OUT NOCOPY      VARCHAR2,
      p_item_description      IN              VARCHAR2,
      p_store                 IN              VARCHAR2,
      p_primary_uom_code      IN              VARCHAR2,
      p_list_price_per_unit   IN              NUMBER,
      p_dummy_sku             IN              VARCHAR2,
      p_vendor_sku            IN              VARCHAR2,
      p_item_list_price       IN              VARCHAR2
   )
   IS
      CURSOR c_get_org (p_organization VARCHAR2)
      IS
         SELECT organization_id
           FROM hr_all_organization_units
          WHERE NAME = p_organization;

      CURSOR c_item_check (
         p_vendor_sku         VARCHAR2,
         p_organization_id    VARCHAR2
      )
      IS
         SELECT inventory_item_id, segment1
           FROM mtl_system_items_b
          WHERE 1=1--description = p_item_description
            AND attribute2 = p_vendor_sku
            AND organization_id = p_organization_id;

      lv_master_org            VARCHAR2 (100) := 'OD_ITEM_MASTER';
      lv_validation_org        VARCHAR2 (100) := 'OD_ITEM_VALIDATION_US';
      ln_master_org_id         NUMBER;
      ln_organization_id       NUMBER;
      ln_val_organization_id   NUMBER;
      ln_inventory_item_id     NUMBER;
      ln_store_inv_item_id     NUMBER;
      ln_item_id               NUMBER;
      lv_item_number           VARCHAR2 (150);
      ln_resp_id               NUMBER;
      ln_application_id        NUMBER;      
   BEGIN
      ln_inventory_item_id := NULL;
      ln_master_org_id := NULL;
      gv_messages := NULL;

      SELECT fnd.user_id ,
             fresp.responsibility_id,
             fresp.application_id
      INTO   gn_user_id, ln_resp_id,ln_application_id
      FROM   fnd_user fnd
      ,      fnd_responsibility_tl fresp
      WHERE  fnd.user_name = 'SVC_ESP_MER'
      AND    fresp.responsibility_name = 'OD (US) Inventory';

      -- Initialization of Apps
      fnd_global.apps_initialize (user_id           => gn_user_id,--1832,
                                  resp_id           => ln_resp_id,
                                  resp_appl_id      => ln_application_id
                                 );
                                 
      --DBMS_OUTPUT.put_line ('create_item_process - 1'   );

      -- Getting the Master Org Information
      OPEN c_get_org (lv_master_org);

      FETCH c_get_org
       INTO ln_master_org_id;

      IF c_get_org%NOTFOUND
      THEN
         gv_messages :=
                 gv_messages || '-' || 'Master org OD_ITEM_MASTER is not Set';
      END IF;

      CLOSE c_get_org;

      --DBMS_OUTPUT.put_line ('create_item_process - 2');
      --DBMS_OUTPUT.put_line ('Master Org:' || ln_master_org_id);

      -- Cursor which Check if Item exists
      OPEN c_item_check (p_vendor_sku, ln_master_org_id);

      FETCH c_item_check
       INTO ln_inventory_item_id, lv_item_number;

      CLOSE c_item_check;

      --DBMS_OUTPUT.put_line ('create_item_process - 3');

      -- If ln_item_check is not null then checks if Item is assigned to Store
      -- else it will Create the item.
      IF ln_inventory_item_id IS NOT NULL
      THEN
         --DBMS_OUTPUT.put_line ('create_item_process - 4');
         ln_organization_id := NULL;
         ln_store_inv_item_id := NULL;

         OPEN c_get_org (p_store);

         FETCH c_get_org
          INTO ln_organization_id;

         IF c_get_org%NOTFOUND
         THEN
            gv_messages :=
                 gv_messages || '-' || 'Inventory org is not Set:' || p_store;
         END IF;

         CLOSE c_get_org;

         --DBMS_OUTPUT.put_line ('create_item_process - 5:'
                      --         || ln_organization_id
                      --        );

         -- Checking if the Item is assigned to the Store
         OPEN c_item_check (p_vendor_sku, ln_organization_id);

         FETCH c_item_check
          INTO ln_store_inv_item_id, lv_item_number;

         CLOSE c_item_check;

         --DBMS_OUTPUT.put_line (   'create_item_process - 6:'
                               --|| ln_store_inv_item_id
                               --|| '-'
                               --|| lv_item_number
                              --);
 --DBMS_OUTPUT.put_line ('Before caling assign_to_org'  ||ln_store_inv_item_id || '--'||  ln_organization_id  );
         -- Assign item to the store
         IF ln_store_inv_item_id IS NULL
         THEN
         
         --DBMS_OUTPUT.put_line ('Before caling assign_to_org 2'  ||ln_inventory_item_id  || '--'||   lv_item_number || '--' ||ln_organization_id ||'--' || p_primary_uom_code   );
            assign_to_org (ln_inventory_item_id,
                           lv_item_number,
                           ln_organization_id,
                           p_primary_uom_code
                          );
            -- Assgning Item to the ASL
            add_to_asl (ln_inventory_item_id, ln_organization_id);
            --DBMS_OUTPUT.put_line ('create_item_process - 17:');
            -- Assigining Item to the Sourcing Rules
            add_to_sourcing_rule (ln_inventory_item_id, ln_organization_id);
            ln_item_id := ln_inventory_item_id;
            gv_messages :=
               'Item Getting Assigned to given Store:' || p_store || '-'
               || gv_messages;
         ELSE
            gv_messages :=
                  'Item Already Assigned to given Store'
               || p_store
               || '-'
               || gv_messages;
            ln_item_id := ln_store_inv_item_id;
         END IF;

         --DBMS_OUTPUT.put_line ('create_item_process - 7:');
      ELSE
         --DBMS_OUTPUT.put_line ('create_item_process - 11');
         -- Creating New Item to the Master Org
         create_item (ln_item_id,
                      p_item_description,
                      ln_master_org_id,
                      p_primary_uom_code,
                      p_list_price_per_unit,
                      p_dummy_sku,
                      p_vendor_sku,
                      p_item_list_price
                     );

         IF ln_item_id IS NOT NULL
         THEN
            --DBMS_OUTPUT.put_line ('create_item_process - 12');

            -- Derive Validation Organization Id
            OPEN c_get_org (lv_validation_org);

            FETCH c_get_org
             INTO ln_val_organization_id;

            IF c_get_org%NOTFOUND
            THEN
               gv_messages :=
                            gv_messages || '-' || 'Validation org is not Set';
            END IF;

            CLOSE c_get_org;

            --DBMS_OUTPUT.put_line (   'create_item_process - 13:'
                                  --|| ln_val_organization_id
                                 --);
            -- Assigning Created Item to the Validation Org
            assign_to_org (ln_item_id,
                           NULL,
                           ln_val_organization_id,
                           p_primary_uom_code
                          );
            --DBMS_OUTPUT.put_line ('create_item_process - 13.1');

            -- Derive Inventory Organization Id
            OPEN c_get_org (p_store);

            FETCH c_get_org
             INTO ln_organization_id;

            IF c_get_org%NOTFOUND
            THEN
               gv_messages := 'Inventory org is not Set:' || p_store;
            END IF;

            CLOSE c_get_org;

            --DBMS_OUTPUT.put_line (   'create_item_process - 14:'
                                  --|| ln_organization_id
                                 --);
            -- Assigning Created Item to the Store Specified
            assign_to_org (ln_item_id,
                           NULL,
                           ln_organization_id,
                           p_primary_uom_code
                          );
            --DBMS_OUTPUT.put_line ('create_item_process - 15:');
            add_or_update_category (ln_item_id, ln_master_org_id, p_dummy_sku);
            --DBMS_OUTPUT.put_line ('create_item_process - 16:');
            -- Assgning Item to the ASL
            add_to_asl (ln_item_id, ln_organization_id);
            --DBMS_OUTPUT.put_line ('create_item_process - 17:');
            -- Assigining Item to the Sourcing Rules
            add_to_sourcing_rule (ln_item_id, ln_organization_id);
            --DBMS_OUTPUT.put_line ('create_item_process - 18:');
            gv_messages := 'Item Created Succesfully' || gv_messages;
         ELSE
            gv_messages := 'ERROR while Creating Item' || gv_messages;
         END IF;
      END IF;

      COMMIT;
      --DBMS_OUTPUT.put_line ('create_item_process - 31');
      x_item_id := ln_item_id;
      x_success_msg := gv_messages;
   EXCEPTION
      WHEN OTHERS
      THEN
         --DBMS_OUTPUT.put_line ('create_item_process - Exception');
         gv_messages := gv_messages || '-' || SQLCODE || '-' || SQLERRM;
         x_item_id := ln_item_id;
         x_success_msg := gv_messages;
   END create_item_process;

-- +=============================================================================+
-- | PROCEDURE NAME : create_item                                                |
-- | DESCRIPTION    : This procedure is the called to create a new item for the  |
-- |                  master org and it returns the Inventory item Id            |
-- |                                                                             |
-- | Parameters  :  None                                                         |
-- | Returns     :  x_item_id              OUT NOCOPY NUMBER                     |
-- |                p_item_description     IN         VARCHAR2                   |
-- |                p_org_id               IN         VARCHAR2                   |
-- |                p_primary_uom_code     IN         VARCHAR2                   |
-- |                p_list_price_per_unit  IN         NUMBER,                    |
-- |                p_dummy_sku            IN         VARCHAR2                   |
-- |                p_vendor_sku           IN         VARCHAR2                   |
-- |                p_item_list_price      IN         VARCHAR2                   |
-- +=============================================================================+
   PROCEDURE create_item (
      x_item_id               OUT NOCOPY      NUMBER,
      p_item_description      IN              VARCHAR2,
      p_org_id                IN              NUMBER,
      p_primary_uom_code      IN              VARCHAR2,
      p_list_price_per_unit   IN              NUMBER,
      p_dummy_sku             IN              VARCHAR2,
      p_vendor_sku            IN              VARCHAR2,
      p_item_list_price       IN              VARCHAR2
   )
   IS
      ln_template_id         NUMBER;
      ln_inventory_item_id   NUMBER;
      ln_organization_id     NUMBER;
      ln_item_number         NUMBER;
      lv_return_status       VARCHAR2 (4000);
      ln_msg_count           NUMBER;
      lv_msg_data            VARCHAR2 (4000);
      ln_msg_index_out       NUMBER;
      lv_attribute1          mtl_system_items_b.attribute1%TYPE;
      ln_template_name       VARCHAR2 (20)                  := 'OD TDS Parts';
      lv_debug_flag          VARCHAR2 (1);
      CURSOR c_dummy_sku_attribute
      IS
      SELECT attribute1
        FROM mtl_system_items_b
       WHERE segment1 = p_dummy_sku AND organization_id = p_org_id;

      CURSOR c_template(p_template_name VARCHAR2)
      IS
      SELECT template_id
        FROM mtl_item_templates
       WHERE template_name = p_template_name;
   BEGIN
      lv_debug_flag := 'S';
      --DBMS_OUTPUT.put_line ('create_item - 1');

      -- Get the Attribute1 value of the DUMMY SKU passed

      IF p_dummy_sku IS NOT NULL
      THEN
          OPEN  c_dummy_sku_attribute;
          FETCH c_dummy_sku_attribute INTO lv_attribute1;
          IF c_dummy_sku_attribute%NOTFOUND THEN
              gv_messages := gv_messages||'-'||'Warning: Invalid Dummy Sku provided:'||p_dummy_sku;
          END IF;
          CLOSE c_dummy_sku_attribute;
      ELSE
          gv_messages := gv_messages||'-'||'Warning: Dummy Sku IS NULL:';
      END IF;

      --DBMS_OUTPUT.put_line ('create_item - 2');

      OPEN  c_template(ln_template_name);
      FETCH c_template INTO ln_template_id;
      IF c_template%NOTFOUND THEN
          --DBMS_OUTPUT.put_line ('create_item - 2.1');
          gv_messages := gv_messages||'-'||'Error: Setup for template is not done:'||ln_template_name;
          lv_debug_flag := 'E';
      END IF;
      CLOSE c_template;

      --FND_GLOBAL.APPS_INITIALIZE(USER_ID=>1197706,RESP_ID=>NULL,RESP_APPL_ID=>NULL);
      --DBMS_OUTPUT.put_line (   'create_item - 3:'
                            --|| ln_template_id
                            --|| '-'
                            --|| p_org_id
                           --);

      IF lv_debug_flag <> 'E' THEN
          --DBMS_OUTPUT.put_line (   'create_item - 3.1:');
          SELECT apps.xx_inv_item_creation_pkg_s.NEXTVAL
            INTO ln_item_number
            FROM DUAL;

          --DBMS_OUTPUT.put_line ('Item Sequence:' || ln_item_number);
          ego_item_pub.process_item
                      (p_api_version                     => 1.0,
                       p_init_msg_list                   => 'T',
                       p_commit                          => 'T',
                       p_transaction_type                => 'CREATE'
                                                       -- UPDATE FOR Updating item
                                                                    ,
                       p_segment1                        => ln_item_number
                                                                     --  ITEM CODE
                                                                          ,
                       p_organization_id                 => p_org_id
                                                     --  WAREHOUSE ORGANIZATION ID
                                                                    ,
                       p_approval_status                 => 'A',
                       p_description                     => p_item_description,
                       p_template_id                     => ln_template_id,
                       p_inventory_item_status_code      => 'A',
                     --  p_item_type                       => '01', --Updated by Gaurav
                       p_purchasing_item_flag            => 'Y',
                       p_customer_order_flag             => 'Y',
                       p_shippable_item_flag             => 'Y',
                       p_primary_uom_code                => p_primary_uom_code,
                       p_list_price_per_unit             => p_list_price_per_unit,
                       p_summary_flag                    => 'Y',
                       p_attribute1                      => lv_attribute1,
                       p_attribute2                      => p_vendor_sku,
                       p_attribute3                      => p_item_list_price,
                       x_inventory_item_id               => ln_inventory_item_id,
                       x_organization_id                 => ln_organization_id,
                       x_return_status                   => lv_return_status,
                       x_msg_count                       => ln_msg_count,
                       x_msg_data                        => lv_msg_data
                      );
          --DBMS_OUTPUT.put_line ('create_item - 4');
          --DBMS_OUTPUT.put_line ('lv_msg_data:' || lv_msg_data);
          --DBMS_OUTPUT.put_line ('ln_msg_count:' || ln_msg_count);
          --DBMS_OUTPUT.put_line ('lv_return_status:' || lv_return_status);

          FOR j IN 1 .. ln_msg_count
          LOOP
             fnd_msg_pub.get (p_msg_index          => j,
                              p_encoded            => 'F',
                              p_data               => lv_msg_data,
                              p_msg_index_out      => ln_msg_index_out
                             );
             --DBMS_OUTPUT.put_line ('lv_msg_data1' || lv_msg_data);
             gv_messages := gv_messages || '-' || lv_msg_data;
          END LOOP;

          --DBMS_OUTPUT.put_line ('create_item - 5');

          IF lv_return_status = 'S'
          THEN
             --DBMS_OUTPUT.put_line ('ITEM CREATION SUCCESSFUL');
             x_item_id := ln_inventory_item_id;
          ELSE
             gv_messages :=
                  gv_messages || '-' || 'Item Return Status:' || lv_return_status;
          END IF;
      END IF;
      --DBMS_OUTPUT.put_line ('create_item - 6');
   EXCEPTION
      WHEN OTHERS
      THEN
         --DBMS_OUTPUT.put_line ('create_item - Exception');
         --DBMS_OUTPUT.put_line (SQLCODE || ':' || SQLERRM);
         gv_messages := gv_messages || '- Exception Raised while creating Item-' || SQLCODE || '-' || SQLERRM;
         ln_inventory_item_id := NULL;
   END create_item;

-- +=============================================================================+
-- | PROCEDURE NAME : assign_to_org                                              |
-- | DESCRIPTION    : This procedure is used to assign the item to the invntory  |
-- |                  organization provided as parameter                         |
-- |                                                                             |
-- | Parameters  :  None                                                         |
-- | Returns     :  p_inventory_item_id    IN         VARCHAR2                   |
-- |                p_item_number          IN         VARCHAR2                   |
-- |                p_organization_id      IN         VARCHAR2                   |
-- |                p_primary_uom_code     IN         NUMBER,                    |
-- +=============================================================================+
   PROCEDURE assign_to_org (
      p_inventory_item_id   IN   NUMBER,
      p_item_number         IN   VARCHAR2,
      p_organization_id     IN   NUMBER,
      p_primary_uom_code    IN   VARCHAR2
   )
   IS
      l_api_version      NUMBER                       := 1.0;
      l_commit           VARCHAR2 (2)                 := fnd_api.g_false;
      l_message_list     error_handler.error_tbl_type;
      lv_return_status   VARCHAR2 (2);
      ln_msg_count       NUMBER                       := 0;
   BEGIN
      --DBMS_OUTPUT.put_line ('assign_to_org - 1');
      ego_item_pub.assign_item_to_org
                                 (p_api_version            => l_api_version,
                                  p_init_msg_list          => 'T',
                                  p_commit                 => 'T',
                                  p_inventory_item_id      => p_inventory_item_id,
                                  p_item_number            => p_item_number,
                                  p_organization_id        => p_organization_id
                                                                               --,  P_ORGANIZATION_CODE    => p_organization_code
      ,
                                  p_primary_uom_code       => p_primary_uom_code,
                                  x_return_status          => lv_return_status,
                                  x_msg_count              => ln_msg_count
                                 );
      --DBMS_OUTPUT.put_line ('assign_to_org - 2');
      --DBMS_OUTPUT.put_line ('Item Assignment Return Status: ' || lv_return_status);

      IF (lv_return_status <> fnd_api.g_ret_sts_success)
      THEN
         --DBMS_OUTPUT.put_line ('Error Messages :');
         error_handler.get_message_list (x_message_list => l_message_list);
         gv_messages :=
               gv_messages
            || '-'
            || 'Assign Item Return Status:'
            || lv_return_status;

         FOR j IN 1 .. l_message_list.COUNT
         LOOP
            --DBMS_OUTPUT.put_line (l_message_list (j).MESSAGE_TEXT);
            gv_messages :=
                        gv_messages || '-' || l_message_list (j).MESSAGE_TEXT;
         END LOOP;
      ELSE
         gv_messages :=
               gv_messages
            || '-'
            || 'Assigning Item to Org is Successful:'
            || p_organization_id;
      END IF;

      --DBMS_OUTPUT.put_line ('assign_to_org - 3');
   EXCEPTION
      WHEN OTHERS
      THEN
         --DBMS_OUTPUT.put_line ('Exception Occured :');
         --DBMS_OUTPUT.put_line (SQLCODE || ':' || SQLERRM);
         gv_messages := gv_messages || '- Exception Raised While Assigning Item to Inventory Org-' || SQLCODE || '-' || SQLERRM;
   END assign_to_org;

-- +=============================================================================+
-- | PROCEDURE NAME : add_or_update_category                                     |
-- | DESCRIPTION    : This procedure is used to add or updated the item to the   |
-- |                  category derived using the Dumy SKU provided as the input. |
-- |                                                                             |
-- | Parameters  :  None                                                         |
-- | Returns     :  p_inventory_item_id    IN         VARCHAR2                   |
-- |                p_organization_id      IN         VARCHAR2                   |
-- |                p_dummy_sku            IN         VARCHAR2                   |
-- +=============================================================================+
   PROCEDURE add_or_update_category (
      p_inventory_item_id   IN   NUMBER,
      p_organization_id     IN   NUMBER,
      p_dummy_sku           IN   VARCHAR2
   )
   IS
      ln_category_id         NUMBER;
      ln_category_set_id     NUMBER;
      ln_old_category_id     NUMBER;
      lv_category_set_name   VARCHAR2 (20)   := 'Inventory';
      lv_return_status       VARCHAR2 (1)    := NULL;
      ln_msg_count           NUMBER          := 0;
      lv_msg_data            VARCHAR2 (2000);
      lv_errorcode           VARCHAR2 (1000);
      lv_debug_flag          VARCHAR2 (1);

      CURSOR c_category_set_id
      IS
      SELECT category_set_id
        FROM mtl_category_sets_tl
       WHERE category_set_name = lv_category_set_name;

      CURSOR c_category_id
      IS
      SELECT mc.category_id
        FROM mtl_categories mc,
             mtl_item_categories mic,
             mtl_system_items_b msi
       WHERE mc.category_id = mic.category_id
         AND mc.structure_id = 101
         AND mic.inventory_item_id = msi.inventory_item_id
         AND mic.organization_id = msi.organization_id
         AND msi.organization_id = p_organization_id
         AND msi.segment1 = p_dummy_sku;

      CURSOR c_old_category
      IS
      SELECT category_id
        INTO ln_old_category_id
        FROM mtl_item_categories mic, mtl_category_sets_tl mcs
       WHERE mic.inventory_item_id = p_inventory_item_id
         AND mic.organization_id = p_organization_id
         AND mic.category_set_id = mcs.category_set_id
         AND mcs.category_set_name = lv_category_set_name;

   BEGIN
      --DBMS_OUTPUT.put_line ('add_or_update_category-1:');
      lv_debug_flag := 'S';
      OPEN  c_category_set_id;
      FETCH c_category_set_id INTO ln_category_set_id;
      IF c_category_set_id%NOTFOUND THEN
         gv_messages := gv_messages||'-'||'Error: Category Set is not Setup:'||lv_category_set_name;
         lv_debug_flag := 'E';
      END IF;
      CLOSE c_category_set_id;
      --DBMS_OUTPUT.put_line ('add_or_update_category-2:' || ln_category_set_id);

      OPEN  c_category_id;
      FETCH c_category_id INTO ln_category_id;
      IF c_category_id%NOTFOUND THEN
         gv_messages := gv_messages||'-'||'Error: Cannot derive Category using Dummy SKU'||p_dummy_sku;
         lv_debug_flag := 'E';
      END IF;
      CLOSE c_category_id;
      --DBMS_OUTPUT.put_line ('add_or_update_category-3:' || ln_category_id);

      OPEN  c_old_category;
      FETCH c_old_category INTO ln_old_category_id;
      CLOSE c_old_category;
      --DBMS_OUTPUT.put_line ('add_or_update_category-4:' || ln_old_category_id);

      IF lv_debug_flag <> 'E'  THEN
          IF ln_old_category_id IS NULL
          THEN
             --DBMS_OUTPUT.put_line ('add_or_update_category-5:');
             inv_item_category_pub.create_category_assignment
                                     (p_api_version            => 1.0,
                                      p_init_msg_list          => fnd_api.g_true,
                                      p_commit                 => fnd_api.g_false,
                                      x_return_status          => lv_return_status,
                                      x_errorcode              => lv_errorcode,
                                      x_msg_count              => ln_msg_count,
                                      x_msg_data               => lv_msg_data,
                                      p_category_id            => ln_category_id,
                                      p_category_set_id        => ln_category_set_id,
                                      p_inventory_item_id      => p_inventory_item_id,
                                      p_organization_id        => p_organization_id
                                     );
             --DBMS_OUTPUT.put_line ('add_or_update_category-6:');
          ELSE
             --DBMS_OUTPUT.put_line ('add_or_update_category-7:');
             inv_item_category_pub.update_category_assignment
                                     (p_api_version            => 1.0,
                                      p_init_msg_list          => fnd_api.g_true,
                                      p_commit                 => fnd_api.g_false,
                                      p_category_id            => ln_category_id,
                                      p_old_category_id        => ln_old_category_id,
                                      p_category_set_id        => ln_category_set_id,
                                      p_inventory_item_id      => p_inventory_item_id,
                                      p_organization_id        => p_organization_id,
                                      x_return_status          => lv_return_status,
                                      x_errorcode              => lv_errorcode,
                                      x_msg_count              => ln_msg_count,
                                      x_msg_data               => lv_msg_data
                                     );
             --DBMS_OUTPUT.put_line ('add_or_update_category-8:');
          END IF;
      END IF;
      --DBMS_OUTPUT.put_line ('add_or_update_category-9:');

      IF lv_return_status = fnd_api.g_ret_sts_success
      THEN
         COMMIT;
         --DBMS_OUTPUT.put_line
         --              (   'The Item assignment to category is Successful : '
         --               || ln_category_id
         --              );
         gv_messages :=
               gv_messages
            || '-'
            || 'The Item assignment to category is Successful';
      ELSE
         --DBMS_OUTPUT.put_line (   'The Item assignment to category failed:'
         --                      || lv_msg_data
         --                     );
         gv_messages :=
                gv_messages || '-' || 'The Item assignment to category failed';
         ROLLBACK;

         FOR i IN 1 .. ln_msg_count
         LOOP
            lv_msg_data :=
                          oe_msg_pub.get (p_msg_index      => i,
                                          p_encoded        => 'F');
            --DBMS_OUTPUT.put_line (i || ') ' || lv_msg_data);
            gv_messages := gv_messages || '-' || lv_msg_data;
         END LOOP;
      END IF;

      --DBMS_OUTPUT.put_line ('add_or_update_category-10:');
   EXCEPTION
      WHEN OTHERS
      THEN
         --DBMS_OUTPUT.put_line ('Exception Occured :');
         --DBMS_OUTPUT.put_line (SQLCODE || ':' || SQLERRM);
         --DBMS_OUTPUT.put_line ('add_or_update_category-Exception:');
         gv_messages := gv_messages || '- Exception Raised while Adding/Updating category - ' || SQLCODE || '-' || SQLERRM;
   END add_or_update_category;

-- +=============================================================================+
-- | PROCEDURE NAME : add_to_asl                                        |
-- | DESCRIPTION    : This procedure is used to add Item to the approved supplier|
-- |                  list                                                       |
-- |                                                                             |
-- | Parameters  :  None                                                         |
-- | Returns     :  p_inventory_item_id    IN         VARCHAR2                   |
-- |                p_organization_id      IN         VARCHAR2                   |
-- +=============================================================================+
   PROCEDURE add_to_asl (
      p_inventory_item_id   IN   NUMBER,
      p_organization_id     IN   NUMBER
   )
   IS
      lv_row_id                   VARCHAR2 (200);
      ln_asl_id                   NUMBER;
      ln_using_organization_id    NUMBER;
      ln_owning_organization_id   NUMBER;
      lv_vendor_business_type     VARCHAR2 (200);
      ln_asl_status_id            NUMBER;
      ld_last_update_date         DATE;
      ln_last_updated_by          NUMBER;
      ld_creation_date            DATE;
      ln_created_by               NUMBER;
      ln_manufacturer_id          NUMBER;
      ln_vendor_id                NUMBER;
      ln_item_id                  NUMBER;
      ln_category_id              NUMBER;
      ln_vendor_site_id           NUMBER;
      lv_primary_vendor_item      VARCHAR2 (200);
      ln_manufacturer_asl_id      NUMBER;
      lv_comments                 VARCHAR2 (200);
      ld_review_by_date           DATE;
      lv_attribute_category       VARCHAR2 (200);
      lv_attribute1               VARCHAR2 (200);
      lv_attribute2               VARCHAR2 (200);
      lv_attribute3               VARCHAR2 (200);
      lv_attribute4               VARCHAR2 (200);
      lv_attribute5               VARCHAR2 (200);
      lv_attribute6               VARCHAR2 (200);
      lv_attribute7               VARCHAR2 (200);
      lv_attribute8               VARCHAR2 (200);
      lv_attribute9               VARCHAR2 (200);
      lv_attribute10              VARCHAR2 (200);
      lv_attribute11              VARCHAR2 (200);
      lv_attribute12              VARCHAR2 (200);
      lv_attribute13              VARCHAR2 (200);
      lv_attribute14              VARCHAR2 (200);
      lv_attribute15              VARCHAR2 (200);
      ln_last_update_login        NUMBER;
      lv_disable_flag             VARCHAR2 (200);
   BEGIN
      --DBMS_OUTPUT.put_line ('add_to_asl-1:');
      ln_using_organization_id := p_organization_id;
      ln_owning_organization_id := p_organization_id;
      lv_vendor_business_type := 'DIRECT';
      ln_asl_status_id := 2;
      ld_last_update_date := SYSDATE;
      ln_last_updated_by := gn_user_id;--1832;
      ld_creation_date := SYSDATE;
      ln_created_by := gn_user_id;--1832;
      ln_item_id := p_inventory_item_id;

      -- ln_category_id            := ;
      -- lv_primary_vendor_item    := ;
      -- ln_last_update_login      := ;

      --Derving the vendor_id
      SELECT vendor_id
        INTO ln_vendor_id
        FROM po_vendors
       WHERE vendor_name = 'NEXICORE SERVICES';

      --DBMS_OUTPUT.put_line ('add_to_asl-2:' || ln_vendor_id);

      -- Derving the vendor_site_id
      SELECT pvs.vendor_site_id
        INTO ln_vendor_site_id
        FROM po_vendors pov, po_vendor_sites_all pvs
       WHERE pov.vendor_name = 'NEXICORE SERVICES'
         AND pov.vendor_id = pvs.vendor_id
         AND vendor_site_code = 'TDS682916';-- 'TST0000468147PR'; Updated by Gaurav

      --DBMS_OUTPUT.put_line ('add_to_asl-3:' || ln_vendor_site_id);
      -- Calling the API - PO_ASL_THS.insert_row
      -- to insert the row in PO_APPROVED_SUPPLIER_LIST
      po_asl_ths.insert_row
                       (x_row_id                      => lv_row_id,
                        x_asl_id                      => ln_asl_id,
                        x_using_organization_id       => ln_using_organization_id,
                        x_owning_organization_id      => ln_owning_organization_id,
                        x_vendor_business_type        => lv_vendor_business_type,
                        x_asl_status_id               => ln_asl_status_id,
                        x_last_update_date            => ld_last_update_date,
                        x_last_updated_by             => ln_last_updated_by,
                        x_creation_date               => ld_creation_date,
                        x_created_by                  => ln_created_by,
                        x_manufacturer_id             => ln_manufacturer_id,
                        x_vendor_id                   => ln_vendor_id,
                        x_item_id                     => ln_item_id,
                        x_category_id                 => ln_category_id,
                        x_vendor_site_id              => ln_vendor_site_id,
                        x_primary_vendor_item         => lv_primary_vendor_item,
                        x_manufacturer_asl_id         => ln_manufacturer_asl_id,
                        x_comments                    => lv_comments,
                        x_review_by_date              => ld_review_by_date,
                        x_attribute_category          => lv_attribute_category,
                        x_attribute1                  => lv_attribute1,
                        x_attribute2                  => lv_attribute2,
                        x_attribute3                  => lv_attribute3,
                        x_attribute4                  => lv_attribute4,
                        x_attribute5                  => lv_attribute5,
                        x_attribute6                  => lv_attribute6,
                        x_attribute7                  => lv_attribute7,
                        x_attribute8                  => lv_attribute8,
                        x_attribute9                  => lv_attribute9,
                        x_attribute10                 => lv_attribute10,
                        x_attribute11                 => lv_attribute11,
                        x_attribute12                 => lv_attribute12,
                        x_attribute13                 => lv_attribute13,
                        x_attribute14                 => lv_attribute14,
                        x_attribute15                 => lv_attribute15,
                        x_last_update_login           => ln_last_update_login,
                        x_disable_flag                => lv_disable_flag
                       );
      --DBMS_OUTPUT.put_line ('add_to_asl-4:' || ln_asl_id);

      IF lv_row_id IS NOT NULL
      THEN
         gv_messages :=
               gv_messages
            || '-'
            || 'Successfully Added Item to Approved Supplier List';
         add_to_asl_attribute (p_inventory_item_id,
                               p_organization_id,
                               ln_vendor_id,
                               ln_vendor_site_id,
                               ln_asl_id
                              );
      ELSE
         gv_messages :=
               gv_messages
            || '-'
            || 'Error While adding Item to the Approved Supplier List';
      END IF;

      --DBMS_OUTPUT.put_line ('add_to_asl-5:');
      --DBMS_OUTPUT.put_line ('X_ASL_ID' || ln_asl_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         --DBMS_OUTPUT.put_line ('Exception Occured :');
         --DBMS_OUTPUT.put_line (SQLCODE || ':' || SQLERRM);
         --DBMS_OUTPUT.put_line ('add_to_asl-Exception:');
         gv_messages := gv_messages || '- Exception raised while adding Item to Approved Supplier List - ' || SQLCODE || '-' || SQLERRM;
   END add_to_asl;

-- +=============================================================================+
-- | PROCEDURE NAME : add_to_asl_attribute                                       |
-- | DESCRIPTION    : This procedure is the used to add the item and created     |
-- |                  ASL to the required attirbutes                             |
-- |                                                                             |
-- | Parameters  :  None                                                         |
-- | Returns     :  p_inventory_item_id    IN         NUMBER                     |
-- |                p_organization_id      IN         NUMBER                     |
-- |                p_vendor_id            IN         NUMBER                     |
-- |                p_vendor_site_id       IN         NUMBER                     |
-- |                p_asl_id               IN         NUMBER                     |
-- +=============================================================================+
   PROCEDURE add_to_asl_attribute (
      p_inventory_item_id   IN   NUMBER,
      p_organization_id     IN   NUMBER,
      p_vendor_id           IN   NUMBER,
      p_vendor_site_id      IN   NUMBER,
      p_asl_id              IN   NUMBER
   )
   IS
      lv_row_id                        VARCHAR2 (200);
      ln_asl_id                        NUMBER;
      ln_using_organization_id         NUMBER;
      ld_last_update_date              DATE;
      ln_last_updated_by               NUMBER;
      ld_creation_date                 DATE;
      ln_created_by                    NUMBER;
      lv_document_sourcing_method      VARCHAR2 (200);
      lv_release_generation_method     VARCHAR2 (200);
      lv_purchasing_unit_of_measure    VARCHAR2 (200);
      lv_enable_plan_schedule_flag     VARCHAR2 (200);
      lv_enable_ship_schedule_flag     VARCHAR2 (200);
      lv_plan_schedule_type            VARCHAR2 (200);
      lv_ship_schedule_type            VARCHAR2 (200);
      ln_plan_bucket_pattern_id        NUMBER;
      ln_ship_bucket_pattern_id        NUMBER;
      lv_enable_autoschedule_flag      VARCHAR2 (200);
      ln_scheduler_id                  NUMBER;
      lv_enable_authorizations_flag    VARCHAR2 (200);
      ln_vendor_id                     NUMBER;
      ln_vendor_site_id                NUMBER;
      ln_item_id                       NUMBER;
      ln_category_id                   NUMBER;
      lv_attribute_category            VARCHAR2 (200);
      lv_attribute1                    VARCHAR2 (200);
      lv_attribute2                    VARCHAR2 (200);
      lv_attribute3                    VARCHAR2 (200);
      lv_attribute4                    VARCHAR2 (200);
      lv_attribute5                    VARCHAR2 (200);
      lv_attribute6                    VARCHAR2 (200);
      lv_attribute7                    VARCHAR2 (200);
      lv_attribute8                    VARCHAR2 (200);
      lv_attribute9                    VARCHAR2 (200);
      lv_attribute10                   VARCHAR2 (200);
      lv_attribute11                   VARCHAR2 (200);
      lv_attribute12                   VARCHAR2 (200);
      lv_attribute13                   VARCHAR2 (200);
      lv_attribute14                   VARCHAR2 (200);
      lv_attribute15                   VARCHAR2 (200);
      ln_last_update_login             NUMBER;
      ln_price_update_tolerance        NUMBER;
      ln_processing_lead_time          NUMBER;
      lv_delivery_calendar             VARCHAR2 (200);
      ln_min_order_qty                 NUMBER;
      ln_fixed_lot_multiple            NUMBER;
      lv_country_of_origin_code        VARCHAR2 (200);
      lv_enable_vmi_flag               VARCHAR2 (200);
      ln_vmi_min_qty                   NUMBER;
      ln_vmi_max_qty                   NUMBER;
      lv_enable_vmi_auto_repl_flag     VARCHAR2 (200);
      lv_vmi_replenishment_approval    VARCHAR2 (200);
      lv_consigned_from_supplier_flg   VARCHAR2 (200);
      ln_consigned_billing_cycle       NUMBER;
      ld_last_billing_date             DATE;
      ln_replenishment_method          NUMBER;
      ln_vmi_min_days                  NUMBER;
      ln_vmi_max_days                  NUMBER;
      ln_fixed_order_quantity          NUMBER;
      ln_forecast_horizon              NUMBER;
      lv_consume_on_aging_flag         VARCHAR2 (200);
      ln_aging_period                  NUMBER;
   BEGIN
      --DBMS_OUTPUT.put_line ('add_to_asl_attribute-1:');
      ln_asl_id := p_asl_id;
      ln_using_organization_id := p_organization_id;
      ld_last_update_date := SYSDATE;
      ln_last_updated_by := gn_user_id;--1832;
      ld_creation_date := SYSDATE;
      ln_created_by := gn_user_id;--1832;
      lv_document_sourcing_method := 'ASL';
      lv_release_generation_method := 'CREATE_AND_APPROVE';
      ln_vendor_id := p_vendor_id;
      ln_vendor_site_id := p_vendor_site_id;
      ln_item_id := p_inventory_item_id;
      --ln_category_id                   :=  X_CATEGORY_ID;
      --ln_last_update_login             :=  X_LAST_UPDATE_LOGIN;
      --DBMS_OUTPUT.put_line ('add_to_asl_attribute-2:');
      po_asl_attributes_ths.insert_row
           (x_row_id                            => lv_row_id,
            x_asl_id                            => ln_asl_id,
            x_using_organization_id             => ln_using_organization_id,
            x_last_update_date                  => ld_last_update_date,
            x_last_updated_by                   => ln_last_updated_by,
            x_creation_date                     => ld_creation_date,
            x_created_by                        => ln_created_by,
            x_document_sourcing_method          => lv_document_sourcing_method,
            x_release_generation_method         => lv_release_generation_method,
            x_purchasing_unit_of_measure        => lv_purchasing_unit_of_measure,
            x_enable_plan_schedule_flag         => lv_enable_plan_schedule_flag,
            x_enable_ship_schedule_flag         => lv_enable_ship_schedule_flag,
            x_plan_schedule_type                => lv_plan_schedule_type,
            x_ship_schedule_type                => lv_ship_schedule_type,
            x_plan_bucket_pattern_id            => ln_plan_bucket_pattern_id,
            x_ship_bucket_pattern_id            => ln_ship_bucket_pattern_id,
            x_enable_autoschedule_flag          => lv_enable_autoschedule_flag,
            x_scheduler_id                      => ln_scheduler_id,
            x_enable_authorizations_flag        => lv_enable_authorizations_flag,
            x_vendor_id                         => ln_vendor_id,
            x_vendor_site_id                    => ln_vendor_site_id,
            x_item_id                           => ln_item_id,
            x_category_id                       => ln_category_id,
            x_attribute_category                => lv_attribute_category,
            x_attribute1                        => lv_attribute1,
            x_attribute2                        => lv_attribute2,
            x_attribute3                        => lv_attribute3,
            x_attribute4                        => lv_attribute4,
            x_attribute5                        => lv_attribute5,
            x_attribute6                        => lv_attribute6,
            x_attribute7                        => lv_attribute7,
            x_attribute8                        => lv_attribute8,
            x_attribute9                        => lv_attribute9,
            x_attribute10                       => lv_attribute10,
            x_attribute11                       => lv_attribute11,
            x_attribute12                       => lv_attribute12,
            x_attribute13                       => lv_attribute13,
            x_attribute14                       => lv_attribute14,
            x_attribute15                       => lv_attribute15,
            x_last_update_login                 => ln_last_update_login,
            x_price_update_tolerance            => ln_price_update_tolerance,
            x_processing_lead_time              => ln_processing_lead_time,
            x_delivery_calendar                 => lv_delivery_calendar,
            x_min_order_qty                     => ln_min_order_qty,
            x_fixed_lot_multiple                => ln_fixed_lot_multiple,
            x_country_of_origin_code            => lv_country_of_origin_code,
            x_enable_vmi_flag                   => lv_enable_vmi_flag,
            x_vmi_min_qty                       => ln_vmi_min_qty,
            x_vmi_max_qty                       => ln_vmi_max_qty,
            x_enable_vmi_auto_repl_flag         => lv_enable_vmi_auto_repl_flag,
            x_vmi_replenishment_approval        => lv_vmi_replenishment_approval,
            x_consigned_from_supplier_flag      => lv_consigned_from_supplier_flg,
            x_consigned_billing_cycle           => ln_consigned_billing_cycle,
            x_last_billing_date                 => ld_last_billing_date,
            x_replenishment_method              => ln_replenishment_method,
            x_vmi_min_days                      => ln_vmi_min_days,
            x_vmi_max_days                      => ln_vmi_max_days,
            x_fixed_order_quantity              => ln_fixed_order_quantity,
            x_forecast_horizon                  => ln_forecast_horizon,
            x_consume_on_aging_flag             => lv_consume_on_aging_flag,
            x_aging_period                      => ln_aging_period
           );

      IF lv_row_id IS NOT NULL
      THEN
         --DBMS_OUTPUT.put_line ('X_ROW_ID:' || lv_row_id);
         gv_messages :=
            gv_messages || '-' || 'Successfully Added Item to ASL Attributes';
      ELSE
         gv_messages :=
               gv_messages
            || '-'
            || 'Error While adding Item to the ASL Attributes';
      END IF;

      --DBMS_OUTPUT.put_line ('add_to_asl_attribute-3:');
   EXCEPTION
      WHEN OTHERS
      THEN
         --DBMS_OUTPUT.put_line ('Exception Occured :');
         --DBMS_OUTPUT.put_line (SQLCODE || ':' || SQLERRM);
         --DBMS_OUTPUT.put_line ('add_to_asl_attribute-Exception:');
         gv_messages := gv_messages || '- Exception Raised while Adding Item to ASL Attribute' || SQLCODE || '-' || SQLERRM;
   END add_to_asl_attribute;

-- +=============================================================================+
-- | PROCEDURE NAME : add_to_sourcing_rule                                       |
-- | DESCRIPTION    : This procedure is used to add the newly created item to the|
-- |                  Sourcing rule set.                                         |
-- |                                                                             |
-- | Parameters  :  None                                                         |
-- | Returns     :  p_inventory_item_id    IN         NUMBER                     |
-- |                p_organization_id      IN         NUMBER                     |
-- +=============================================================================+
   PROCEDURE add_to_sourcing_rule (
      p_inventory_item_id   IN   NUMBER,
      p_organization_id     IN   NUMBER
   )
   IS
      lv_commit                  VARCHAR2 (200);
      lv_return_status           VARCHAR2 (200);
      ln_msg_count               NUMBER;
      lv_msg_data                VARCHAR2 (200);
      l_msg_data                 VARCHAR2 (200);
      l_assignment_set_rec       apps.mrp_src_assignment_pub.assignment_set_rec_type;
      p_assignment_set_val_rec   apps.mrp_src_assignment_pub.assignment_set_val_rec_type;
      l_assignment_tbl           apps.mrp_src_assignment_pub.assignment_tbl_type;
      p_assignment_val_tbl       apps.mrp_src_assignment_pub.assignment_val_tbl_type;
      x_assignment_set_rec       apps.mrp_src_assignment_pub.assignment_set_rec_type;
      x_assignment_set_val_rec   apps.mrp_src_assignment_pub.assignment_set_val_rec_type;
      x_assignment_tbl           apps.mrp_src_assignment_pub.assignment_tbl_type;
      x_assignment_val_tbl       apps.mrp_src_assignment_pub.assignment_val_tbl_type;
      ln_sourcing_rule_id        NUMBER;
      ln_assignment_set_id       NUMBER;
   BEGIN
      --DBMS_OUTPUT.put_line ('add_to_sourcing_rule-1:');
      fnd_msg_pub.delete_msg;

      -- Derive the values for Assignment_set_id
      SELECT assignment_set_id
        INTO ln_assignment_set_id
        FROM mrp_assignment_sets
       WHERE assignment_set_name = 'OD TDS PARTS ASSIGNMENT SET';

      --DBMS_OUTPUT.put_line ('add_to_sourcing_rule-2:' || ln_assignment_set_id);

      -- Derive the values for sourcing_rule_id
      SELECT sourcing_rule_id
        INTO ln_sourcing_rule_id
        FROM mrp_sourcing_rules
       WHERE sourcing_rule_name = 'TDS PARTS';

      --DBMS_OUTPUT.put_line ('add_to_sourcing_rule-3:' || ln_sourcing_rule_id);
      -- Call the API -MRP_SRC_ASSIGNMENT_PUB.process_assignment
      -- for updating the sourcing assignment set
      l_assignment_tbl (1).assignment_set_id := ln_assignment_set_id;
      l_assignment_tbl (1).assignment_type := 3;
      l_assignment_tbl (1).operation := 'CREATE';
      l_assignment_tbl (1).organization_id := p_organization_id;
      l_assignment_tbl (1).inventory_item_id := p_inventory_item_id;
      l_assignment_tbl (1).sourcing_rule_id := ln_sourcing_rule_id;
      l_assignment_tbl (1).sourcing_rule_type := 1;
      --DBMS_OUTPUT.put_line ('add_to_sourcing_rule-4:');
      mrp_src_assignment_pub.process_assignment
                        (p_api_version_number          => 1.0,
                         p_init_msg_list               => fnd_api.g_false,
                         p_return_values               => fnd_api.g_false,
                         p_commit                      => NULL,
                         x_return_status               => lv_return_status,
                         x_msg_count                   => ln_msg_count,
                         x_msg_data                    => lv_msg_data,
                         p_assignment_set_rec          => l_assignment_set_rec,
                         p_assignment_set_val_rec      => p_assignment_set_val_rec,
                         p_assignment_tbl              => l_assignment_tbl,
                         p_assignment_val_tbl          => p_assignment_val_tbl,
                         x_assignment_set_rec          => x_assignment_set_rec,
                         x_assignment_set_val_rec      => x_assignment_set_val_rec,
                         x_assignment_tbl              => x_assignment_tbl,
                         x_assignment_val_tbl          => x_assignment_val_tbl
                        );

      IF lv_return_status = fnd_api.g_ret_sts_success
      THEN
         --DBMS_OUTPUT.put_line ('Success!');
         gv_messages :=
              gv_messages || '-' || 'Succesfully Added Item to Sourcing Rule';
      ELSE
         --DBMS_OUTPUT.put_line ('count:' || ln_msg_count);
         gv_messages :=
             gv_messages || '-' || 'Error while Adding Item to Sourcing Rule';

         IF ln_msg_count > 0
         THEN
            FOR l_index IN 1 .. ln_msg_count
            LOOP
               lv_msg_data :=
                  fnd_msg_pub.get (p_msg_index      => l_index,
                                   p_encoded        => fnd_api.g_false
                                  );
               --DBMS_OUTPUT.put_line (SUBSTR (lv_msg_data, 1, 250));
               gv_messages := gv_messages || '-' || lv_msg_data;
            END LOOP;

            --DBMS_OUTPUT.put_line ('MSG:' || x_assignment_set_rec.return_status);
         END IF;
      END IF;

      --DBMS_OUTPUT.put_line ('add_to_sourcing_rule-5:');
   EXCEPTION
      WHEN OTHERS
      THEN
         --DBMS_OUTPUT.put_line ('Exception Occured :');
         --DBMS_OUTPUT.put_line (SQLCODE || ':' || SQLERRM);
         --DBMS_OUTPUT.put_line ('add_to_sourcing_rule-Exception:');
         gv_messages := gv_messages || '- Exception raised while adding Item to Sourcing rule -' || SQLCODE || '-' || SQLERRM;
   END add_to_sourcing_rule;
END xx_inv_item_creation_pkg;
/
SHOW ERROR;
--EXIT;
