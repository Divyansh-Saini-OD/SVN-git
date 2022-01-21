create or replace
PACKAGE BODY XX_INV_ITEM_UPDATE_PKG
AS
    gn_request_id      NUMBER:= FND_GLOBAL.CONC_REQUEST_ID();

---child program

PROCEDURE XX_INV_ITEM_CHILD_PROC(x_return_message   OUT VARCHAR2
                                ,x_return_code       OUT VARCHAR2
                                ,p_batch_size        IN NUMBER DEFAULT '10000' 
                                 )
IS

ln_conc_req_id      NUMBER;
ln_set_process_id mtl_system_items_interface.set_process_id%TYPE;
ln_cnt             NUMBER;

ln_request_id      fnd_concurrent_requests.request_id%TYPE;
lc_meaning         fnd_concurrent_requests.status_code%TYPE;

lc_item_flag        VARCHAR2(1):='Y';


CURSOR lcu_inv IS 
select inventory_item_id inv_item_id
,organization_id org
From mtl_system_items_b 
where item_type='99' --- NON-TRADE
and receipt_required_flag='N' --- 2-way match
--and organization_id = '441'
order by segment1; 


TYPE c_insert_inv_lines_tab_type  IS TABLE OF lcu_inv%ROWTYPE;
v_insert_inv_lines c_insert_inv_lines_tab_type  := c_insert_inv_lines_tab_type() ;

TYPE xx_mtl_items_interface_type is table of mtl_system_items_interface%ROWTYPE index by pls_integer;
ltab_mtl_items_interface_type xx_mtl_items_interface_type;

BEGIN

OPEN lcu_inv;
 ln_cnt := 1;
LOOP
    -- Get the item data up to the limit
  
 FETCH lcu_inv BULK COLLECT INTO v_insert_inv_lines LIMIT p_batch_size;
 select inv.mtl_system_items_intf_sets_s.nextval 
 INTO ln_set_process_id
 from dual;
 
 IF v_insert_inv_lines.FIRST IS NOT NULL THEN

 FOR i IN v_insert_inv_lines.FIRST .. v_insert_inv_lines.LAST
 
 LOOP
  ltab_mtl_items_interface_type(i).transaction_type := 'UPDATE';
  ltab_mtl_items_interface_type(i).RECEIVE_CLOSE_TOLERANCE := 100;
  ltab_mtl_items_interface_type(i).inventory_item_id := v_insert_inv_lines(i).inv_item_id;
  ltab_mtl_items_interface_type(i).organization_id  := v_insert_inv_lines(i).org;
  ltab_mtl_items_interface_type(i).set_process_id := ln_set_process_id;
  ltab_mtl_items_interface_type(i).process_FLAG := '1';
END LOOP;

ELSE

    IF v_insert_inv_lines.FIRST IS NULL AND ln_cnt = 1 THEN

     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No data exists in interface table for processing');

    END IF;
 EXIT;

END IF;

 FORALL i IN ltab_mtl_items_interface_type.FIRST..ltab_mtl_items_interface_type.LAST
     INSERT INTO INV.mtl_system_items_interface
     VALUES ltab_mtl_items_interface_type(i);

COMMIT;

-----Submitting the Item Import
FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitting Item Import Program');

             ln_conc_req_id:= FND_REQUEST.SUBMIT_REQUEST(
                                              'INV'
                                              ,'INCOIN'
                                              ,''
                                              ,''
                                              ,FALSE
                                              ,'441'
                                              ,'1'
                                              ,'1'
                                              ,'1'
                                              ,'1'
                                              ,ln_set_process_id
                                              ,'2' );
COMMIT;

 ln_cnt:=ln_cnt+1;  
  END LOOP;
  CLOSE lcu_inv;

 
EXCEPTION

         WHEN NO_DATA_FOUND THEN

                 FND_FILE.PUT_LINE(FND_FILE.LOG,'No records for processing');
                
                x_return_code    := 0;
                x_return_message := fnd_message.get();

        WHEN OTHERS THEN

               FND_FILE.PUT_LINE(FND_FILE.LOG,'When others exception in child while processing');
                
                x_return_code    := 0;
                x_return_message := fnd_message.get();

END XX_INV_ITEM_CHILD_PROC;

END XX_INV_ITEM_UPDATE_PKG;
/