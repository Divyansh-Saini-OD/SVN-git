create or replace
PACKAGE XX_INV_ITEM_UPDATE_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XX_INV_ITEM_UPDATE_PKG                                    |
-- | Description      :  This PKG will be used to insert records into  |
-- |                     mtl_system_items_interface  in update mode    |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0                                    Initial draft version       |
-- +===================================================================+

-- +===================================================================+
-- | Name  : XX_INV_ITEM_CHILD_PROC                                    |
-- | Description      : The main controlling procedure for  interface  |
-- |                                                                   |
-- | Parameters :   p_batch_size,p_inv_item_id_low,p_inv_item_id_high  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :  x_return_message, x_return_code                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     PROCEDURE XX_INV_ITEM_CHILD_PROC (
                                       x_return_message        OUT  VARCHAR2
                                      ,x_return_code           OUT  VARCHAR2
                                      ,p_batch_size            IN   NUMBER   DEFAULT '10000'
                                         );


END XX_INV_ITEM_UPDATE_PKG;
/