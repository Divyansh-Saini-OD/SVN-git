SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_WFL_POSCHORD_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :  XX_WFL_POSCHORD_PKG.pkb                                         |
-- | Rice Id     :  E0242 PO cancellation from ISP                                  |
-- | Description :  This script creates custom package body required for            |
-- |                PoCancellationFromIsp.                             		    |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks            	                    |
-- |=======   ==========  =============    ============================             |
-- |DRAFT 1A 09-FEB-2007  Niharika        Initial draft version                     |
-- |1.0      10-Mar-2007  Niharika           Baselined after testing                |
-- |1.1      04-Jun-2007  Prajeesh        Modified due to MD040 Changes		    |	                                                            |
-- |                                                            		    |
-- +================================================================================+
AS


-- Procedure  Get_Posrc_Type_Proc  will derive value of  attribute_category from po_headers_all table 
-- and check  whether it exist in  custom  lookup code or not.


PROCEDURE GET_POSRC_TYPE_PROC( p_itemtype     IN  VARCHAR2
                             , p_itemkey      IN  VARCHAR2
                             , p_actid        IN  NUMBER
                             , p_funcmode     IN  VARCHAR2
                             , x_resultout    OUT VARCHAR2)

-- +================================================================================+
-- | Name        :  GET_POSRC_TYPE_PROC                                             |
-- | Description :  This  custom procedure to get value of                          |
-- |                attribute_category and to check whether it exist in custom      |
-- |                lookup code or not                                              |
-- +================================================================================+
AS
-- Declaration of local variables
    ln_po_header_id                po_headers_all.po_header_id%TYPE       DEFAULT 0;
    lc_attribute_category          po_headers_all.attribute_category%TYPE DEFAULT NULL;
    lc_flag                        VARCHAR2(1) DEFAULT NULL;
    lc_err_buff                    VARCHAR2(2000);
    lc_ret_code                    VARCHAR2(10);
    
    -- Declaration of cursors
    CURSOR    lcu_get_attr_cat(p_po_header_id IN NUMBER)
    IS
    SELECT    UPPER(attribute_category)
    FROM      apps.po_headers_all
    WHERE     po_header_id = p_po_header_id;

    CURSOR    lcu_get_lookup( p_attribute_category IN VARCHAR2)
    IS
    SELECT 'Y'
    FROM   apps.fnd_lookup_values
    WHERE lookup_type ='OD_PO_CANCEL_ISP'
    AND   UPPER(meaning) = NVL(p_attribute_category,'')
    AND   sysdate BETWEEN NVL(start_date_active,sysdate)                               
    AND   NVL(end_date_active,sysdate)
    AND   LANGUAGE =userenv('LANG')   
    AND   enabled_flag='Y';


BEGIN
    ln_po_header_id:= Wf_Engine.GetItemAttrNumber(itemtype => p_itemtype
                                                 ,itemkey => p_itemkey
                                                 ,aname   => 'PO_HEADER_ID');
    

    -- Opening of the cursors and fetching value into local variables
    OPEN  lcu_get_attr_cat(ln_po_header_id);
    FETCH lcu_get_attr_cat INTO lc_attribute_category;
    CLOSE lcu_get_attr_cat;

    

    OPEN  lcu_get_lookup(lc_attribute_category);
    FETCH lcu_get_lookup INTO lc_flag ;
    CLOSE lcu_get_lookup;


    IF  lc_flag IS NOT NULL THEN
      x_resultout:= 'COMPLETE:'||'Y';
    ELSE
       x_resultout:= 'COMPLETE:'||'N';
    END IF;
EXCEPTION
WHEN OTHERS THEN
      x_resultout :='COMPLETE:'||'N';
      gc_err_desc := SUBSTR(SQLERRM,1,1000);
      gc_entity_ref := 'PO Header ID';
      gn_entity_ref_id := NVL(ln_po_header_id,0);
      gc_err_report_type := XX_OM_REPORT_EXCEPTION_T('OTHERS'
                                                ,'OTC'
                                                ,'Internal Fulfillment'
                                                ,'Purchasing'
                                                ,SQLCODE
                                                ,gc_err_desc
                                                ,gc_entity_ref
                                                ,gn_entity_ref_id
                                                );
       --used to insert exception in xx_om_global_exceptions table	
       XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(gc_err_report_type
                                                     ,lc_err_buff
                                                     ,lc_ret_code
                                                     );  

END GET_POSRC_TYPE_PROC;
----------------------------------------------------------------------------

PROCEDURE VALIDATE_POSTATUS_PROC( p_itemtype     IN  VARCHAR2
                             	, p_itemkey      IN  VARCHAR2
                             	, p_actid        IN  NUMBER
                             	, p_funcmode     IN  VARCHAR2
                             	, x_resultout    OUT VARCHAR2)


-- +================================================================================+
-- | Name        :  VALIDATE_POSTATUS_PROC                                          |
-- | Description :  This script creates custom procedure to check status of PO      |
-- |                whether it is cancelled or not. If it is cancelled then it will |
-- |                update table apps.po_change_requests with request_status        |
-- |                ='BUYER_APP'                                                    |
-- +================================================================================+
AS
-- Declaration of local variables
	 
   lc_action_type                 po_change_requests.action_type%TYPE DEFAULT NULL;
   ln_po_header_id                NUMBER      DEFAULT 0;
   lc_err_buff                    VARCHAR2(2000);
   lc_ret_code                    VARCHAR2(10);
    

-- Declaration of cursor
   CURSOR   lcu_get_action_type 
   IS
   SELECT   action_type
   FROM     apps.po_change_requests
   WHERE    wf_item_key = p_itemkey;


BEGIN
   -- Fetch PO header id , to be used while capturing error in error handler pkg

   ln_po_header_id:= Wf_Engine.GetItemAttrNumber(itemtype => p_itemtype
                                                 ,itemkey => p_itemkey
                                                 ,aname   => 'PO_HEADER_ID');

   -- Opening the cursor and fetching value into local variable
   OPEN lcu_get_action_type ;
   FETCH lcu_get_action_type INTO lc_action_type;
   CLOSE lcu_get_action_type;

   
   IF lc_action_type ='CANCELLATION'  THEN 	
      -- If the status of PO is ‘Cancelled’, update  table apps.po_change_requests with request_status = 'BUYER_APP'
   
      UPDATE  apps.po_change_requests
      SET     request_status   = 'BUYER_APP',
              last_updated_by  = fnd_global.user_id,
              last_update_date = gd_sysdate
      WHERE   wf_item_key      = p_itemkey ;
        
      COMMIT;   
      x_resultout:= 'COMPLETE:'||'ACCEPT';
   ELSE
      x_resultout:= 'COMPLETE:'||'REJECT';
   END IF;



EXCEPTION
WHEN OTHERS THEN
     x_resultout :='COMPLETE:' ||'REJECT';
     gc_err_desc := substr(SQLERRM,1,1000);
     gc_entity_ref := 'PO Header ID';
     gn_entity_ref_id := NVL(ln_po_header_id,0);
     gc_err_report_type := XX_OM_REPORT_EXCEPTION_T('OTHERS'
                                                ,'OTC'
                                                ,'Internal Fulfillment'
                                                ,'Purchasing'
                                                ,SQLCODE
                                                ,gc_err_desc
                                                ,gc_entity_ref
                                                ,gn_entity_ref_id
                                                );
       --used to insert exception in xxod_global_exceptions_tbl table	
       XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(gc_err_report_type
                                                     ,lc_err_buff
                                                     ,lc_ret_code
                                                     );  
END VALIDATE_POSTATUS_PROC;
-----------------------------------------------------------------------------
END XX_WFL_POSCHORD_PKG;
/
SHOW ERROR
