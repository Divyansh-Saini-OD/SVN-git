SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_INV_ITEM_CREATION_PKG
PROMPT Program exits if the creation is not successful
create or replace PACKAGE xx_inv_item_creation_pkg
AS
-- +=============================================================================================+
-- |                       Oracle NAIO (India)                                                   |
-- |                        Bangalore, India                                                     |
-- +=============================================================================================+
-- | Name         : xx_inv_item_creation_pkg.sql                                                |
-- | Description  : This package is used to validate the data in the staging table based on the  |
-- |                business rules. It is also used to process the data by inserting them into   |
-- |                the ITEMS AND CATEGORIES INTERFACE table and invoking the Import Item Program|
-- |                which inturn is used to import the data into Oracle Items Base table.        |
-- |                                                                                             |
-- |                                                                                             |
-- |                                                                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  01-Jul-2011  Sreenivasa Tirumala  Initial draft version                            |
-- +=============================================================================================+
   -- +=============================================================================+
-- | PROCEDURE NAME : xxae_inv_item_validate                                     |
-- | DESCRIPTION    : This procedure validates all the records in the            |
-- |                  staging table based on the business rules. The             |
-- |                  status of the validated records will be updated            |
-- |                  to 'VD' and in case of any errors the status will be 'VE'. |
-- |                                                                             |
-- | Parameters  :  None                                                         |
-- | Returns     :  p_debug           IN            VARCHAR2    Debug Flag       |
-- |                x_retcode         OUT NOCOPY    VARCHAR2    Return Code      |
-- |                x_errbuf          OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE create_item_process (
      x_item_id              OUT NOCOPY  NUMBER,
      x_success_msg          OUT NOCOPY  VARCHAR2,
      p_item_description     IN VARCHAR2,
      p_store                IN VARCHAR2,
      p_primary_uom_code     IN VARCHAR2,
      p_list_price_per_unit  IN NUMBER,
      p_dummy_sku            IN VARCHAR2,
      p_vendor_sku           IN VARCHAR2,
      p_item_list_price      IN VARCHAR2
   );
   PROCEDURE create_item (
      x_item_id              OUT NOCOPY  NUMBER,
      p_item_description     IN VARCHAR2,
      p_org_id               IN NUMBER,
      p_primary_uom_code     IN VARCHAR2,
      p_list_price_per_unit  IN NUMBER,
      p_dummy_sku            IN VARCHAR2,
      p_vendor_sku           IN VARCHAR2,
      p_item_list_price      IN VARCHAR2
   );
   PROCEDURE assign_to_org  (
      p_inventory_item_id        IN      NUMBER,
      p_item_number              IN      VARCHAR2,
      p_organization_id          IN      NUMBER,
      p_primary_uom_code         IN      VARCHAR2
   );
   PROCEDURE add_or_update_category  (
      p_inventory_item_id        IN      NUMBER,
      p_organization_id          IN      NUMBER,
      p_dummy_sku                IN      VARCHAR2
   );   
   PROCEDURE add_to_asl(
      p_inventory_item_id        IN      NUMBER,
      p_organization_id          IN      NUMBER
      );
   PROCEDURE add_to_asl_attribute(
      p_inventory_item_id        IN      NUMBER,
      p_organization_id          IN      NUMBER,
      p_vendor_id                IN      NUMBER,
      p_vendor_site_id           IN      NUMBER,
      p_asl_id                   IN      NUMBER
      );
   PROCEDURE add_to_sourcing_rule(
      p_inventory_item_id        IN      NUMBER,
      p_organization_id          IN      NUMBER
   );
END xx_inv_item_creation_pkg;
/
SHOW ERROR
