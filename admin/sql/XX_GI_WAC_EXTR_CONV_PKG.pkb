SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_WAC_EXTR_CONV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_GI_WAC_EXTR_CONV_PKG.pkb                        |
-- | Description :  Weighted Average Costs Package Body                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date         Author           Remarks                   |
-- |========   ===========  ===============  ==========================|
-- |DRAFT 1a   17-Jul-2007  Abhradip Ghosh   Initial draft version     |
-- |DRAFT 1.0  03-Aug-2007  Parvez Siddiqui  TL Review                 |
-- +===================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------
G_CONVERSION_CODE    CONSTANT xx_com_conversions_conv.conversion_code%TYPE := 'C0052_WAC';
G_PACKAGE_NAME       CONSTANT VARCHAR2(50)                                 := 'XX_GI_WAC_EXTR_CONV_PKG';
G_STAGING_TABLE_NAME CONSTANT VARCHAR2(50)                                 := 'XX_GI_MTL_TRANS_INTF_STG';
G_APPLICATION        CONSTANT VARCHAR2(30)                                 := 'INV';
G_WAC_MASTER_PRGM    CONSTANT VARCHAR2(30)                                 := 'XX_GI_WAC_LOAD_CNV_PKG_MAST_MN';
G_LOOKUP_TYPE        CONSTANT VARCHAR2(50)                                 := 'MTL_TRANSACTION_ACTION';
G_MEANING            CONSTANT VARCHAR2(50)                                 := 'Receipt into stores';
G_ATTRIBUTE_CATEGORY CONSTANT VARCHAR2(50)                                 := 'CONVOHA';

-----------------------------
--Declaring Global Variables
-----------------------------
gn_batch_size        PLS_INTEGER;
gn_conversion_id     PLS_INTEGER;
gn_max_child_req     PLS_INTEGER;
gn_count             PLS_INTEGER := 0;

-----------------------------------
--Declaring Global Record Variables 
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------



-- +====================================================================+
-- | Name        :  display_log                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+

PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the out file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+

PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END;

-- +====================================================================+
-- | Name        :  get_conversion_id                                   |
-- | Description :  This procedure is invoked to get the conversion_id  |
-- |                ,batch_size and max_threads                         |
-- |                                                                    |
-- | Parameters  :                                                      |
-- |                                                                    |
-- | Returns     :  x_conversion_id                                     |
-- |                x_batch_size                                        |
-- |                x_max_threads                                       |
-- |                x_return_status                                     |
-- +====================================================================+

PROCEDURE get_conversion_id(
                             x_conversion_id  OUT NOCOPY NUMBER
                            ,x_batch_size     OUT NOCOPY NUMBER
                            ,x_max_threads    OUT NOCOPY NUMBER
                            ,x_return_status  OUT NOCOPY VARCHAR2
                           )
IS

BEGIN
   SELECT XCC.conversion_id
          ,XCC.batch_size
          ,XCC.max_threads
   INTO   x_conversion_id
          ,x_batch_size
          ,x_return_status
   FROM   xx_com_conversions_conv XCC
   WHERE  XCC.conversion_code = G_CONVERSION_CODE;

   x_return_status := 'S';
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_return_status := 'E';
   WHEN OTHERS THEN
       x_return_status := SQLERRM;
END get_conversion_id;

-- +=====================================================================+
-- | Name        :  upd_hist_rcpts                                       |
-- |                                                                     |
-- | Description :  This procedure is invoked to update wac_process_flag |
-- |                of XX_GI_MTL_TRANS_INTF_STG by extracting distinct   |
-- |                item and organization combinations from              |
-- |                OD_RCV_TRANS_INTF_STG                                |
-- | Parameters  :                                                       |
-- |                                                                     |
-- | Returns     :  x_errbuf                                             |
-- |                x_retcode                                            |
-- +=====================================================================+

PROCEDURE upd_hist_rcpts(
                         x_errbuf   OUT NOCOPY VARCHAR2
                         ,x_retcode OUT NOCOPY VARCHAR2
                        )
IS

--------------------------------------------
-- Declaring local Exceptions and Variables
--------------------------------------------  
ln_hist_count PLS_INTEGER;
----------------------------------
-- Declaring Table Type Variables
----------------------------------
TYPE item_tbl_type IS TABLE OF od_rcv_trans_intf_stg.item%type
INDEX BY BINARY_INTEGER;
lt_item item_tbl_type;

TYPE organization_tbl_type IS TABLE OF od_rcv_trans_intf_stg.organization%type
INDEX BY BINARY_INTEGER;
lt_organization organization_tbl_type ;

----------------------------------------
-- Cusor to fetch item and organization
----------------------------------------
CURSOR lcu_hist_rcpts
IS
SELECT ORT.item,
       ORT.organization
FROM  OD_RCV_TRANS_INTF_STG ORT
WHERE (
       (ORT.attribute_category = 'OD History PO Receipts Miscellaneous')
        OR (ORT.attribute_category = 'CONVOHA' AND ORT.transaction_source = 'Receipt Into Stores')
        OR (ORT.source_code = 'OD History RTV Return Receipts')
        OR (ORT.source_code = 'OD History Inter Org Receipts')
      )
AND ORT.process_flag = 7;

BEGIN
   
   OPEN  lcu_hist_rcpts;
   FETCH lcu_hist_rcpts BULK COLLECT INTO lt_item, lt_organization;
   CLOSE lcu_hist_rcpts;
   
   IF lt_item.COUNT <> 0 THEN
     
      FORALL i IN 1 .. lt_item.COUNT
      UPDATE xx_gi_mtl_trans_intf_stg XGM
      SET    XGM.wac_process_flag = 1
      WHERE  XGM.sku    = lt_item(i)
      AND    XGM.loc_id = lt_organization(i)
      AND    XGM.wac_process_flag <> 1;
      
      ln_hist_count := SQL%ROWCOUNT;
      
      COMMIT;
      
      gn_count := ln_hist_count;
   
   END IF; -- lt_item.COUNT

EXCEPTION
   WHEN OTHERS THEN
       x_errbuf  := 'Unexpected error in upd_hist_rcpts - '||SQLERRM;
       x_retcode := 2;
       display_log(x_errbuf);
       
END upd_hist_rcpts;
-- +=====================================================================+
-- | Name        :  derive_trans_actn_id                                 |
-- |                                                                     |
-- | Description :  This procedure is invoked to derive the lookup_code  |
-- |                for transaction_action = 'Receipt into stores'       |
-- | Parameters  :                                                       |
-- |                                                                     |
-- | Returns     :  x_errbuf                                             |
-- |                x_retcode                                            |
-- |                x_trans_actn_id                                      |
-- +=====================================================================+

PROCEDURE derive_trans_actn_id(
                               x_trans_actn_id OUT NOCOPY PLS_INTEGER
                               ,x_retcode      OUT NOCOPY VARCHAR2
                               ,x_errbuf       OUT NOCOPY VARCHAR2
                              )
IS

BEGIN

   SELECT lookup_code
   INTO   x_trans_actn_id
   FROM   fnd_lookup_values FLV
   WHERE  FLV.lookup_type = G_LOOKUP_TYPE
   AND    FLV.meaning = G_MEANING;
   
   x_retcode := 0;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_retcode := 1;
       x_errbuf  := 'Either Lookup_type = MTL_TRANSACTION_ACTION or lookup_value = Receipt into stores is not defined.';
       display_log(x_errbuf);
   WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected Error in derive_trans_actn_id : '||SQLERRM;
       display_log(x_errbuf);
END derive_trans_actn_id;

-- +=====================================================================+
-- | Name        :  upd_onhand_adj_conv                                  |
-- |                                                                     |
-- | Description :  This procedure is invoked to update wac_process_flag |
-- |                of XX_GI_MTL_TRANS_INTF_STG by extracting distinct   |
-- |                item and organization combinations from              |
-- |                XX_GI_OHADJ_DTL_CONV_STG                             |
-- | Parameters  :                                                       |
-- |                                                                     |
-- | Returns     :  x_errbuf                                             |
-- |                x_retcode                                            |
-- +=====================================================================+

PROCEDURE upd_onhand_adj_conv(
                              x_errbuf   OUT NOCOPY VARCHAR2
                              ,x_retcode OUT NOCOPY VARCHAR2
                             )
IS

--------------------------------------------
-- Declaring local Exceptions and Variables
-------------------------------------------- 
ln_trans_actn_id PLS_INTEGER;
lc_retcode       VARCHAR2(2000);
lc_errbuf        VARCHAR2(2000);
ln_count         PLS_INTEGER;

----------------------------------
-- Declaring Table Type Variables
----------------------------------
TYPE item_tbl_type IS TABLE OF xx_gi_ohadj_dtl_conv_stg.attribute3%type
INDEX BY BINARY_INTEGER;
lt_item item_tbl_type;

TYPE organization_tbl_type IS TABLE OF xx_gi_ohadj_dtl_conv_stg.attribute1%type
INDEX BY BINARY_INTEGER;
lt_organization organization_tbl_type ;

----------------------------------------
-- Cusor to fetch item and organization
----------------------------------------
CURSOR lcu_onhand_conv
IS
SELECT XGO.attribute3
       ,XGO.attribute1
FROM   xx_gi_ohadj_dtl_conv_stg XGO
WHERE  XGO.attribute_category    = G_ATTRIBUTE_CATEGORY
AND    XGO.transaction_action_id = ln_trans_actn_id
AND    XGO.transaction_quantity > 0
AND    XGO.process_flag = 7;

BEGIN

   derive_trans_actn_id(
                        x_trans_actn_id => ln_trans_actn_id
                        ,x_retcode      => lc_retcode
                        ,x_errbuf       => lc_errbuf
                       );
                       
   lt_item.DELETE;
                       
   IF lc_retcode = 0 THEN
           OPEN  lcu_onhand_conv;
           FETCH lcu_onhand_conv BULK COLLECT INTO lt_item, lt_organization;
           CLOSE lcu_onhand_conv;
           
           IF lt_item.COUNT <> 0 THEN

             FORALL i IN 1 .. lt_item.COUNT
             UPDATE xx_gi_mtl_trans_intf_stg XGM
             SET    XGM.wac_process_flag = 1
             WHERE  XGM.sku    = lt_item(i)
             AND    XGM.loc_id = lt_organization(i)
             AND    XGM.wac_process_flag <> 1;
             
             ln_count := SQL%ROWCOUNT;
             
             COMMIT;

           END IF; -- lt_item.COUNT
           gn_count := gn_count + ln_count;
       
   END IF; -- lc_retcode

EXCEPTION
   WHEN OTHERS THEN
       x_errbuf  := 'Unexpected error in upd_onhand_adj_conv - '||SQLERRM;
       x_retcode := 2;
       display_log(x_errbuf);
END upd_onhand_adj_conv;

-- +======================================================================+
-- | Name        :  launch_master_program                                 |
-- |                                                                      |
-- | Description :  This procedure is invoked to launch                   |
-- |                OD: GI WAC Conversion Master Program.                 |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_errbuf                                              |
-- |                x_retcode                                             |
-- +======================================================================+

PROCEDURE launch_master_program( 
                                x_errbuf              OUT NOCOPY VARCHAR2
                                ,x_retcode            OUT NOCOPY VARCHAR2
                                ,p_validate_only_flag IN VARCHAR2
                                ,p_reset_status_flag  IN VARCHAR2
                                ,p_max_wait_time      IN NUMBER
                                ,p_sleep              IN NUMBER
                               )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_WAC_MASTER        EXCEPTION;
ln_request_id        PLS_INTEGER;

BEGIN
   
   --------------------------------------------------
   -- Submitting the Exception Report for each batch
   --------------------------------------------------
   ln_request_id := FND_REQUEST.submit_request(
                                               application  => G_APPLICATION
                                               ,program     => G_WAC_MASTER_PRGM
                                               ,sub_request => FALSE                -- TRUE means is a sub request
                                               ,argument1   => p_validate_only_flag -- Validate Only Flag
                                               ,argument2   => p_reset_status_flag  -- Reset Status Flag
                                               ,argument3   => p_max_wait_time
                                               ,argument4   => p_sleep
                                              );

   IF ln_request_id = 0 THEN
      x_errbuf  := FND_MESSAGE.get;
      RAISE EX_WAC_MASTER;
   ELSE
      COMMIT;
   END IF; -- ln_request_id

EXCEPTION
   WHEN EX_WAC_MASTER THEN
       x_errbuf  := 'Error while launching WAC Conversion Master Program : '||SQLERRM;
       x_retcode := 2;
       display_log(x_errbuf);
   WHEN OTHERS THEN
       x_errbuf  := 'Error in launch_master_program : '||SQLERRM;
       x_retcode := 2;
       display_log(x_errbuf);
END launch_master_program;


-- +====================================================================+
-- | Name        :  load_main                                           |
-- |                                                                    |
-- | Description :  This procedure is invoked from the OD: GI WAC       |
-- |                Extract Conversion Concurrent Program.This will     |
-- |                update the wac_process_flag of                      |
-- |                XX_GI_MTL_TRANS_INTF_STG and will also launch       |
-- |                OD: GI WAC Conversion Master Program.               |
-- |                                                                    |
-- | Parameters  :  p_validate_only_flag                                |
-- |                p_reset_status_flag                                 |
-- |                p_max_wait_time                                     |
-- |                p_sleep                                             |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE load_main( 
                    x_errbuf              OUT NOCOPY VARCHAR2
                    ,x_retcode            OUT NOCOPY VARCHAR2
                    ,p_validate_only_flag IN VARCHAR2
                    ,p_reset_status_flag  IN VARCHAR2
                    ,p_max_wait_time      IN NUMBER
                    ,p_sleep              IN NUMBER
                   )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_NO_ENTRY       EXCEPTION;
lc_return_status  VARCHAR2(2000);

BEGIN
   
   -----------------------------
   -- Getting the Conversion id
   -----------------------------
   
   get_conversion_id(
                     x_conversion_id  => gn_conversion_id
                     ,x_batch_size    => gn_batch_size
                     ,x_max_threads   => gn_max_child_req
                     ,x_return_status => lc_return_status
                    );
                    
   CASE lc_return_status
       WHEN 'S' THEN
           
           upd_hist_rcpts(
                          x_errbuf   => x_errbuf
                          ,x_retcode => x_retcode
                         );
                         
           upd_onhand_adj_conv(
                               x_errbuf   => x_errbuf
                               ,x_retcode => x_retcode
                              );
                              
           launch_master_program(
                                 x_errbuf              => x_errbuf
                                 ,x_retcode            => x_retcode
                                 ,p_validate_only_flag => p_validate_only_flag
                                 ,p_reset_status_flag  => p_reset_status_flag
                                 ,p_max_wait_time      => p_max_wait_time
                                 ,p_sleep              => p_sleep
                                );
           display_out(RPAD('=',67,'='));                     
           display_out('Total number of records updated in the staging table : '||gn_count);
           display_out(RPAD('=',67,'='));  
           
           
       WHEN 'E' THEN
           
           RAISE EX_NO_ENTRY;
           
       ELSE
           
           x_retcode := 2;
           x_errbuf  := lc_return_status;
           display_log(x_errbuf);
           
   END CASE;


EXCEPTION
   WHEN EX_NO_ENTRY THEN
       x_retcode := 2;
       display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE);
   WHEN OTHERS THEN
       x_errbuf := 'Error in load_main : '||SQLERRM;
       x_retcode := 2;
       display_log(x_errbuf);
END load_main;
END XX_GI_WAC_EXTR_CONV_PKG;
/
SHOW ERRORS
EXIT;
