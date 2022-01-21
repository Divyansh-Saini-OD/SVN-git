/*=======================================================================+
 |  Copyright (c) 1995 Oracle Corporation Redwood Shores, California, USA|
 |                            All rights reserved.                       |
 +=======================================================================+
 | FILENAME
 |   OEXINVWB.pls
 |
 | DESCRIPTION
 |   TEMPLATE PL/SQL body for package XX_ITEM_TYPE
 |
 | NOTES
 |   This file is a TEMPLATE that should be modified with your own
 |   names and procedures before installing.  Names that begin with
 |   XX should be replaced with values for your implemenation.  
 |   procedure bodies should be filled in with your code.
 |
 |   It may be convenient to use the following naming standard 
 |       - package name is equivalent to the item type internal name
 |       - procedure names are equivalent to the workflow activity 
 |         function internal which the procedure implements.
 *=======================================================================*/

SET VERIFY OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb checkfile:~PROD:~PATH:~FILE



CREATE OR REPLACE PACKAGE BODY OE_INVOICE_WF AS
/* $Header: OEXWINVB.pls 115.12.11510.8 2007/12/19 07:12:05 ramising ship $ */

-- PROCEDURE XX_ACTIVITY_NAME
--
-- <describe the activity here>
--
-- IN
--   itemtype  - type of the current item
--   itemkey   - key of the current item
--   actid     - process activity instance id
--   funcmode  - function execution mode ('RUN', 'CANCEL', 'TIMEOUT', ...)
-- OUT
--   result
--       - COMPLETE[:<result>]
--           activity has completed with the indicated result
--       - WAITING            
--           activity is waiting for additional transitions
--       - DEFERED            
--           execution should be defered to background
--       - NOTIFIED[:<notification_id>:<assigned_user>]
--           activity has notified an external entity that this 
--           step must be performed.  A call to wf_engine.CompleteActivty
--           will signal when this step is complete.  Optional 
--           return of notification ID and assigned user.
--       - ERROR[:<error_code>]
--           function encountered an error.
g_defer varchar2(2000) := FND_PROFILE.value('ONT_DEFER_INV_MIN'); -- 4343417
g_defer_min NUMBER := 0;

PROCEDURE Invoice_Interface
(   itemtype     IN     VARCHAR2
,   itemkey      IN     VARCHAR2
,   actid        IN     NUMBER
,   funcmode     IN     VARCHAR2
,   resultout    IN OUT NOCOPY VARCHAR2
) IS
l_result_out    VARCHAR2(30);
l_return_status VARCHAR2(30);
l_line_id       NUMBER;
l_header_id     NUMBER;
l_count         NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--

l_order_number  number; -- Added for bug 6610480
BEGIN

  -- 
  -- RUN mode - normal process execution
  --
  IF (funcmode = 'RUN') THEN
  
     OE_STANDARD_WF.Set_Msg_Context(actid);

     IF itemtype = OE_GLOBALS.G_WFI_LIN THEN
	 l_line_id := to_number(itemkey);
         IF l_debug_level > 0 THEN
            oe_debug_pub.add('Entering OE_INVOICE_WF.INTERFACE_LINE for Line Id : ' || l_line_id, 1);
         END IF;
     ELSIF itemtype = OE_GLOBALS.G_WFI_HDR THEN
         l_header_id := to_number(itemkey);
         IF l_debug_level > 0 THEN
            oe_debug_pub.add('Entering OE_INVOICE_WF.INTERFACE_LINE for Header Id : ' || l_header_id, 1);
         END IF;
     END IF;

     IF itemtype = OE_GLOBALS.G_WFI_LIN THEN

          -- Added below code for bug 6610480
          select t1.order_number
          into   l_order_number
          from   oe_order_lines_all t2,
                 oe_order_headers_all t1
          where  t2.line_id = l_line_id
          and    t1.header_id = t2.header_id;

          IF l_debug_level > 0 THEN
             oe_debug_pub.add(' Sales Order : ' || l_order_number, 1);
          END IF;
          -- End of bug 6610480 
--bug 6054959
          SELECT count(1) into l_count
          from   RA_INTERFACE_LINES_ALL
          where line_type = 'LINE'
          and   interface_line_context = 'ORDER ENTRY'
          and   interface_line_attribute6 = to_char(l_line_id)
          and   sales_order = TO_CHAR(l_order_number)  -- Added for bug 6610480
          and   sales_order_line IS NOT NULL; -- Added for bug 6610480
          
          IF( l_count = 0) THEN
            SELECT   count(1) into l_count    from   RA_CUSTOMER_TRX_LINES_ALL RCTL
              where  rctl.interface_line_context = 'ORDER ENTRY'
              and    rctl.line_type = 'LINE'
              and    RCTL.interface_line_attribute6 = to_char(l_line_id)
              and    rctl.sales_order = to_char(l_order_number) -- Added for bug 6610480
              and    rctl.sales_order_line is not null; -- Added for bug 6610480
          END IF;
          
          IF( l_count <> 0) THEN
            resultout := OE_GLOBALS.G_WFR_COMPLETE || ':' || OE_GLOBALS.G_WFR_COMPLETE ;
            IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'Line is Invoiced, NOT invoicing any more ' ) ;
            END IF;
            OE_STANDARD_WF.Clear_Msg_Context;
            RETURN;
          END IF;
--END Bug 6054959 
        OE_Invoice_PUB.Interface_Line(  l_line_id
                                     ,  itemtype
                                     ,  l_result_out
                                     ,  l_return_status);
     ELSIF itemtype = OE_GLOBALS.G_WFI_HDR THEN

          -- Added below code for bug 6610480
          select t1.order_number
          into   l_order_number
          from   oe_order_headers_all t1
          where  t1.header_id = l_header_id;

          IF l_debug_level > 0 THEN
             oe_debug_pub.add(' Sales Order : ' || l_order_number, 1);
          END IF;
          -- End of bug 6610480 


-- bug 6054959
         SELECT count(1) into l_count
          from   RA_INTERFACE_LINES_ALL
          where line_type = 'LINE'
          and   interface_line_context = 'ORDER ENTRY'
          and   interface_line_attribute6 IN (select to_char(line_id) from oe_order_lines_all where header_id=l_header_id) -- bug#6662802: added to_char() 
          and   sales_order = TO_CHAR(l_order_number)  -- Added for bug 6610480
          and   sales_order_line IS NOT NULL; -- Added for bug 6610480
          
          IF( l_count = 0) THEN
            SELECT   count(1) into l_count    from   RA_CUSTOMER_TRX_LINES_ALL
             where  interface_line_context = 'ORDER ENTRY'
             and   line_type = 'LINE'
             and  interface_line_attribute6 IN (select to_char(line_id) from oe_order_lines_all  where header_id=l_header_id) -- bug#6662802: added to_char() 
             and   sales_order = TO_CHAR(l_order_number)  -- Added for bug 6610480
             and   sales_order_line IS NOT NULL; -- Added for bug 6610480
          END IF;
          
          IF( l_count <> 0) THEN
            resultout := OE_GLOBALS.G_WFR_COMPLETE || ':' || OE_GLOBALS.G_WFR_COMPLETE ;
            IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'Lines in Header Invoiced, NOT invoicing any more ' ) ;
            END IF;
            OE_STANDARD_WF.Clear_Msg_Context;
            RETURN;
          END IF;
--END Bug 6054959 
        OE_Invoice_PUB.Interface_Header(  l_header_id
                                     ,  itemtype
                                     ,  l_result_out
                                     ,  l_return_status);
     END IF;
     IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'INFO-L_RETURN_STATUS: '||L_RETURN_STATUS ) ;
        oe_debug_pub.add(  'INFO-L_RESULT_OUT: '||L_RESULT_OUT ) ;
     END IF;
    IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
       IF l_result_out = OE_GLOBALS.G_WFR_NOT_ELIGIBLE THEN
          resultout := OE_GLOBALS.G_WFR_COMPLETE ||':' || OE_GLOBALS.G_WFR_NOT_ELIGIBLE ;
          OE_STANDARD_WF.Clear_Msg_Context;
          RETURN;
       ELSIF l_result_out = OE_GLOBALS.G_WFR_COMPLETE THEN
          resultout := OE_GLOBALS.G_WFR_COMPLETE || ':' || OE_GLOBALS.G_WFR_COMPLETE ;
          OE_STANDARD_WF.Clear_Msg_Context;
          RETURN;
       ELSIF l_result_out = OE_GLOBALS.G_WFR_PRTL_COMPLETE THEN
          resultout := OE_GLOBALS.G_WFR_COMPLETE || ':' || OE_GLOBALS.G_WFR_PRTL_COMPLETE;
          OE_STANDARD_WF.Clear_Msg_Context;
          RETURN;
       END IF;
    ELSIF l_return_status = 'DEFERRED' THEN
       OE_STANDARD_WF.Clear_Msg_Context;
       IF g_defer IS NOT NULL THEN  -- 4343417
         BEGIN
           IF TO_NUMBER(g_defer) >= 0 THEN
           resultout := 'DEFERRED:'||to_char(sysdate+(TO_NUMBER(g_defer)/1440),wf_engine.date_format);
           ELSE
             g_defer := NULL;
           END IF;
         EXCEPTION
         WHEN OTHERS THEN
           g_defer := NULL;
         END;
       END IF;

       IF g_defer IS NULL THEN
         resultout := 'DEFERRED:'||to_char(sysdate+((1+g_defer_min)/1440), wf_engine.date_format);
         g_defer_min := mod(g_defer_min + 0.5, 4.5);
       END IF;

       IF l_debug_level  > 0 THEN
         oe_debug_pub.add(resultout, 5);
       END IF;

       RETURN;
    ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
       -- start data fix project
       -- UPDATE OE_ORDER_LINES_ALL   /* Bug #3427029 */
       -- SET INVOICE_INTERFACE_STATUS_CODE = 'INVOICE-UNEXPECTED-ERROR', 
       -- FLOW_STATUS_CODE = 'INVOICE_UNEXPECTED_ERROR',
       -- CALCULATE_PRICE_FLAG = 'N',
       -- LOCK_CONTROL = LOCK_CONTROL + 1
       -- WHERE LINE_ID = l_line_id;
       --OE_STANDARD_WF.Save_Messages(p_instance_id => actid);
       --OE_STANDARD_WF.Clear_Msg_Context;
       -- commit; -- messages were not saved without this
       -- end data fix project
       IF l_debug_level  > 0 THEN
          oe_debug_pub.add('OEXWINVB.pls - in unexpected error raise exception');
       END IF;
       --resultout := OE_GLOBALS.G_WFR_COMPLETE || ':' || OE_GLOBALS.G_WFR_INCOMPLETE;
       --return;
       app_exception.raise_exception;
    ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN 
         -- For HOLDs and Validation errors
       IF l_result_out = OE_GLOBALS.G_WFR_ON_HOLD THEN
          resultout := OE_GLOBALS.G_WFR_COMPLETE || ':' || OE_GLOBALS.G_WFR_ON_HOLD;
          OE_STANDARD_WF.Save_Messages(p_instance_id => actid);
          OE_STANDARD_WF.Clear_Msg_Context;
	     RETURN;
       ELSIF l_result_out = OE_GLOBALS.G_WFR_INCOMPLETE THEN
	     resultout := OE_GLOBALS.G_WFR_COMPLETE || ':' || OE_GLOBALS.G_WFR_INCOMPLETE;
          OE_STANDARD_WF.Save_Messages(p_instance_id => actid);
          OE_STANDARD_WF.Clear_Msg_Context;
	     RETURN;
       END IF;
    END IF;

  END IF;


  --
  -- CANCEL mode - activity 'compensation'
  --
  -- This is an event point is called with the effect of the activity must
  -- be undone, for example when a process is reset to an earlier point
  -- due to a loop back.
  --
  IF (funcmode = 'CANCEL') THEN

    -- your cancel code goes here
   null;

    -- no result needed
    resultout := 'COMPLETE';
    return;
  END IF;


  --
  -- Other execution modes may be created in the future.  Your 
  -- activity will indicate that it does not implement a mode
  -- by returning null
  --
 
EXCEPTION
  WHEN OTHERS THEN
    -- The line below records this function call in the error system
    -- in the case of an exception.
    wf_core.context('OE_Invoice_WF', 'Invoice_Interface', 
		    itemtype, itemkey, to_char(actid), funcmode);
    -- start data fix project
    OE_STANDARD_WF.Add_Error_Activity_Msg(p_actid => actid, 
                                          p_itemtype => itemtype,
                                          p_itemkey => itemkey);
    OE_STANDARD_WF.Save_Messages(p_instance_id => actid);
    OE_STANDARD_WF.Clear_Msg_Context;
    -- end data fix project
    RAISE;

END Invoice_Interface;

END  OE_INVOICE_WF;
/ 

--SHOW ERRORS PACKAGE BODY OE_INVOICE_WF

COMMIT;
EXIT;

