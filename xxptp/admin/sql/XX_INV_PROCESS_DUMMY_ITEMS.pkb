CREATE OR REPLACE PACKAGE BODY APPS.XX_INV_PROCESS_DUMMY_ITEMS IS
-- Version 1.1
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- +===========================================================================+
-- |Package Name : XX_INV_PROCESS_DUMMY_ITEMS                                  |
-- |Purpose      : This package contains the procedures to assign dummy OM     |
-- |               items to all RMS Inventory Organizations.                   |
-- |                                                                           |
-- |                                                                           |
-- |Change History                                                             |
-- |                                                                           |
-- |Ver   Date          Author             Description                         |
-- |---   -----------   -----------------  ------------------------------------|
-- |1.0   19-JUL-2008  Ganesh Nadakudhiti Original Code                        |
-- |1.1   29-SEP-2008  Ganesh Nadakudhiti Modified to do pull the OM Dummy Item|
-- |                                      info from Custom Value set           |
-- +===========================================================================+

PROCEDURE main(p_errbuf        OUT VARCHAR2 ,
               p_retcode       OUT VARCHAR2 ,
               p_master_org_id  IN NUMBER   ,
               p_item           IN VARCHAR2 ,
               p_start_rec      IN NUMBER   ,
               p_end_rec        IN NUMBER   ,
               p_user_name      IN VARCHAR2 ,
               p_resp_key       IN VARCHAR2
              ) IS

 -- Type Declarations
 TYPE P_ITEM_REC IS RECORD(Item        VARCHAR2(100) :=NULL ,
                           Item_id     NUMBER       :=NULL
                          );
 v_item_rec      p_item_rec  ;
 --
 TYPE p_item_tab IS TABLE OF v_item_rec%TYPE
 INDEX BY BINARY_INTEGER;
 v_item_tab      p_item_tab;
 v_item_count    NUMBER :=0 ;

 --
 -- Cursor to get the the OM dummy items from Value set
 --
 CURSOR csr_get_dummy_item IS
 SELECT ffv.flex_value      Item
   FROM fnd_flex_values     ffv  ,
        fnd_flex_value_sets fvs
  WHERE fvs.flex_value_set_name   = 'XX_INV_OM_DUMMY_ITEMS'
    AND ffv.flex_value_set_id     = fvs.flex_value_set_id
    AND NVL(ffv.enabled_flag,'N') =  'Y'
    AND NVL(ffv.end_date_active, TRUNC(SYSDATE + 1)) > TRUNC(SYSDATE) 
 ORDER BY ffv.flex_value_id   ; 

 --
 -- Cursor to get item id for the dummy item
 --
 CURSOR csr_get_item_id(p_item   IN VARCHAR2,
                        p_org_id IN NUMBER
                       ) IS
 SELECT inventory_item_id
   FROM mtl_system_items_b
  WHERE segment1        = p_item
    AND organization_id = p_org_id;
 --
 -- Cursor to get RMS Organizations for assigning the dummy item
 --
 CURSOR csr_get_item_orgs(p_item_id IN NUMBER) IS
 SELECT NULL             Return_Status     ,
        p_item_id        Inventory_Item_Id ,
        NULL             Item_Number       ,
        hou.Organization_Id                    ,
        NULL         Organization_Code ,
        NULL             Primary_Uom_Code
   FROM hr_organization_units hou,
        mtl_parameters        mtp
  WHERE hou.attribute1 IS NOT NULL
    AND mtp.organization_id = hou.organization_id
    AND NOT EXISTS(SELECT  1
                     FROM mtl_system_items_b
                    WHERE inventory_item_id = p_item_id
                      AND organization_id   = hou.organization_id);
 v_item_to_org_tbl    EGO_Item_PUB.Item_Org_Assignment_Tbl_Type;

 --
 -- Cursor to Check if the dummy item is defined in the Master Org
 --
 CURSOR csr_check_item_org(p_item_id IN NUMBER,
                           p_org_id  IN NUMBER) IS
 SELECT 'Y'
   FROM mtl_system_items_b
  WHERE inventory_item_id = p_item_id
    AND organization_id = p_org_id ;
 v_item_exists   VARCHAR2(1) ;
 v_msg_count    NUMBER;
 v_return_status VARCHAR2(1);

 --
 -- General Variables
 --
 G_USER_NAME         CONSTANT VARCHAR2(240) := 'SVC_ESP_MER';
 G_RESP_KEY          CONSTANT VARCHAR2(240) := 'OD (US) INV Foundation Trade';
 V_user_id                    NUMBER;
 v_resp_id                    NUMBER;
 v_resp_app_id                NUMBER;
 v_tot                        NUMBER  :=0;
 v_error                      NUMBER  :=0;
 v_pass                       NUMBER  :=0;
 v_item_tot                   NUMBER  :=0;
 v_item_error                 NUMBER  :=0;
 v_item_pass                  NUMBER  :=0;
 v_from                       NUMBER;
 v_to                         NUMBER;
BEGIN
 --
 SELECT fu.user_id
   INTO v_user_id
   FROM FND_USER fu
  WHERE fu.user_name = NVL(p_user_name,G_USER_NAME);
 --
 SELECT fr.responsibility_id ,
        fr.application_id
   INTO v_resp_id     ,
        v_resp_app_id
   FROM FND_RESPONSIBILITY_VL fr
  WHERE fr.responsibility_name = NVL(p_resp_key,G_RESP_KEY);
 -- Initialize the Environment
 FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id      ,
                            RESP_ID      => v_resp_id      ,
                            RESP_APPL_ID => v_resp_app_id
                            );


 ------------------------------------------
 -- Assign dummy items to the item table --
 ------------------------------------------
 FOR i IN csr_get_dummy_item LOOP
  v_item_count := v_item_count +1;
  v_item_tab(v_item_count).item   := i.item   ;
 END LOOP;
 --
 IF p_start_rec IS NOT NULL THEN
  --
  IF p_start_rec > v_item_count THEN
   RAISE_APPLICATION_ERROR(-20987,'Start record parameter is greater than available records');
  ELSE
    --
    IF p_start_rec = 0 THEN
     v_from := 1;
    ELSE
     v_from := p_start_rec;
    END IF;
    --
  END IF;
  --
 END IF;
 --
 IF p_end_rec IS NOT NULL THEN
  IF p_end_rec >= v_item_count THEN
   v_to := v_item_count;
  ELSE
   v_to := p_end_rec;
  END IF;
 ELSE
  v_to := v_item_count;
 END IF;
 --
 -- Extend the table by adding the item that is passed as parameter
 --
 IF p_item IS NOT NULL THEN
  v_to := v_to +1;
  v_item_tab(v_to).item := p_item  ;
 END IF;
 ---------------------------------------------------------------
 -- Get the Master org inventory item id for the dummy items  --
 ---------------------------------------------------------------
 FOR i IN v_from..v_to LOOP
  --
   OPEN  csr_get_item_id(v_item_tab(i).item,p_master_org_id);
  FETCH csr_get_item_id INTO v_item_tab(i).item_id;
  CLOSE csr_get_item_id;
  --
  IF v_item_tab(i).item_id IS NULL THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,'************************************************');	
   FND_FILE.PUT_LINE(FND_FILE.LOG,'**Error**- Item '||v_item_tab(i).item||' Does not exist in Master Org');
   FND_FILE.PUT_LINE(FND_FILE.LOG,'************************************************');
   p_retcode := 1;
  END IF;
  --
 END LOOP;
 --------------------------------------------------------------
 -- Buld the item Org Assignment table --
 --------------------------------------------------------------
 FOR j IN  v_from..v_to  LOOP
  --
  v_item_to_org_tbl.delete;
  v_item_tot   := 0;
  v_item_error := 0;
  v_item_pass  := 0;
  --
  IF v_item_tab(j).item_id IS NOT NULL THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing Org Assignments for Item '||v_item_tab(j).item);
   OPEN  csr_get_item_orgs(v_item_tab(j).item_id);
   FETCH csr_get_item_orgs BULK COLLECT INTO v_item_to_org_tbl;
   CLOSE csr_get_item_orgs;
   EGO_ITEM_PUB.PROCESS_ITEM_ORG_ASSIGNMENTS(p_api_version             => 1.0               ,
                                             p_init_msg_list           => FND_API.G_TRUE    ,
                                             p_commit                  => FND_API.G_TRUE    ,
                                             p_Item_Org_Assignment_Tbl => v_item_to_org_tbl ,
                                             x_return_status           => v_return_status   ,
                                             x_msg_count               => v_msg_count
                                            );
   FOR k IN 1..v_item_to_org_tbl.COUNT LOOP
    v_item_tot := v_item_tot + 1 ;
    v_item_exists := NULL;
    OPEN  csr_check_item_org(v_item_to_org_tbl(k).inventory_item_id,
                             v_item_to_org_tbl(k).organization_id
                            );
    FETCH csr_check_item_org INTO v_item_exists;
    CLOSE csr_check_item_org;
    IF v_item_exists IS NULL THEN
      v_item_error := v_item_error + 1;
     FND_FILE.PUT_LINE(FND_FILE.LOG,'************************************************'); 
     FND_FILE.PUT_LINE(FND_FILE.LOG,'**Error** - Item not Assigned to Org id '||TO_CHAR(v_item_to_org_tbl(k).organization_id));
     FND_FILE.PUT_LINE(FND_FILE.LOG,'************************************************');
     p_retcode := 1;
    ELSE
      v_item_pass := v_item_pass + 1;
    END IF;
   END LOOP;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Organization Assignments found : '||TO_CHAR(v_item_tot));
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Successful : '||TO_CHAR(v_item_pass)||' Failed :'||TO_CHAR(v_item_error));
   FND_FILE.PUT_LINE(FND_FILE.LOG,'************************************************');
   v_tot   := v_tot   + v_item_tot   ;
   v_pass  := v_pass  + v_item_pass  ;
   v_error := v_error + v_item_error ;
  END IF;
 END LOOP;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Organization Assignments found : '||TO_CHAR(v_tot));
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Successful : '||TO_CHAR(v_pass)||' Failed :'||TO_CHAR(v_error));
  FND_FILE.PUT_LINE(FND_FILE.LOG,'************************************************');
 EXCEPTION
  WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception raised');
   FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
   p_retcode := 2;
 END main;
END XX_INV_PROCESS_DUMMY_ITEMS;
/
