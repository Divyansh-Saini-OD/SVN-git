REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.9.12010000.26=120.18.12020000.5)(120.7.12000000.8=120.9.12010000.4)(115.11=120.0):~PROD:~PATH:~FILE
REM *============================================================================================+
REM |  Copyright (c) 1994, 2014 Oracle Corporation, Redwood Shores, CA, USA                            |
REM |                     All rights reserved.                                                   |
REM +============================================================================================+
REM | FILENAME                                                                                   |
REM |   PAAPINTB.pls                                                                             |
REM |                                                                                            |
REM | NAME                                                                                       |
REM |   PA_AP_INTEGRATION                                                                        |
REM |                                                                                            |
REM | DESCRIPTION:                                                                               |
REM |   This package is created for all PA integrations with Payables                            |
REM |                                                                                            |
REM | USAGE:    sqlplus &un_apps/&pw_apps @PAAPINTS.pls                                          |
REM |                                                                                            |
REM | HISTORY:  27-APR-98    Adwait Marathe    Created.                                          |
REM |                        Bug 2541302 SUPPLIER MERGE IN PAYABLES                              |
REM |                        Created Procedure Allow_Supplier_Merge and                          |
REM |                        upd_pa_details_supplier_merge. These will                           |
REM |                        be called via payables supplier merge.                              |
REM |                        Added New procedure  UPD_PA_DETAILS_SUPPLIER_MERGE bug 2541302      |
REM |                        which will be called by Supplier merge api of payables              |
REM |                        This api will update new vendor_id with old one which is merged     |
REM |                        in following..                                                      |
REM |                        update CDL with new vendor_id in system_reference1 field            |
REM |                        update Asset Lines with new vendor_id in po_vendor_id field         |
REM |                        update pa_implementations with new_vendor_id in vendor_id field     |
REM |                        update pa_expenditures with new_vendor_id in vendor_id field        |
REM |                        Call Summarization to summarize the data if the vendor is been      |
REM |                        used as a resource in any of the resource lists                     |
REM |                        Sumarization                                                        |
REM |                         - Find all resource lists in which old vendor exists as resource   |
REM |                         - See if new vendor exists as resource if not create new vendor    |
REM |                           as resource                                                      |
REM |                         - See if new vendor exists as resource_list member in the resource |
REM |                           list under consideration if not create new vendor as member      |
REM |                         - Disable old vendor as member in resource_list_members            |
REM |                         - Call api to summarize data based on resourcelist changes.        |
REM |                        Added New function Allow_Supplier_Merge to be called by Supplier    |
REM |                        Merge form of AP. If this call return "N" then No vendors is used   |
REM |                        in Budgets Merge can be performed for the supplier.                 |
REM |  31-OCT-2002 sguduru  Bug#2601683. Created a new Procedure get_asset_addition_flag(),      |
REM |                                    which will find if the given project_id is of type      |
REM |                                    'CAPITAL' project and accordingly populate the          |
REM |                                    'OUT' variable with 'P' or 'U'.                         |
REM |  01-NOV-2002 sguduru               Renamed paramter p_asset_addition_flag to               |
REM |                                    x_asset_addition_flag as it is OUT parameter.           |
REM |                                                                                            |
REM |  14-NV-02   admarath  Bug 2649043 Added PA_CI_SUPPLIER_DETAILS table to update new vendor  |
REM |  28-MAR-03  sesingh   Added Function Get_Project_Type which will return 'P' if the given   |        
REM |                       project_id is of type 'CAPITAL' otherwise it will return 'U'.        |
REM |                                                                                            |
REM |  09-JUN-04  jwhite    FP.M Impact for Planning Res lists.                                  |
REM |                       Made minor changes to address FP.M                                   |
REM |                       data model changes for resource lists and members.                   |
REM |                                                                                            |  
REM |  21-JUN-04  Vthakkar  Bug 3613381 : SQL Performance Rep Issue No : 8192344		         |
REM |  29-SEP-04  VGade     FP.M change. Added pa_resource_utils.chk_supplier_in_use function    |
REM |                       to see if the given supplier ID is used by any planning resource     |
REM |                       lists or resource breakdown structures.  If it is in use,            |
REM |                       it returns 'Y'; if not, it returns 'N'.                              |
REM | 14-DEC-04   sesingh   Bug#4029384:Introduced additional checks in the section  of          |
REM |                       inserting new vendor as a resource list member,to avoid ORA1403.     | 
REM | 11-JUL-05   PBandla   R12 - need to update vendor ID on pa_bc_packets and pa_bc_commitments|
REM |                       Also removed nvl on ORG_ID                                           |
REM | 08-May-06   aaggarwa  Bug 5201382 R12.PJ:XB3:DEV:NEW API TO RETRIEVE THE DATES FOR PROFILE | 
REM |                       PA_AP_EI_DATE_DEFAULT                                                |
REM |                       added get_si_default_exp_org.                                        |
REM | 02-JUN-06   aaggarwa  Bug: 5262492 (R12.PJ:XB5:QA:APL: PROJECT EI DATE NULL FOR PO/REC     |
REM |                       MATCHED INVOICE LINE/DISTRIBU                                        |
REM | 27-Jun-06   aaggarwa  Bug : 4940969                                                        |
REM |                       In the case of unmatched invoice the Invoice date must get  defaulted|
REM |                       as the EI date.                                                      |
REM | 21-SEP-06   asubrama  Bug 5555041 - Modified FUCNTION Get_si_default_exp_org to return the |
REM |                       expenditure organization name in the correct language                |
REM | 07-FEB-07   VGade     Bug 5498336 - Included the update for pa_expenditure_items_all(vendor)
REM | 22-FEB-07   pkaur     Bug 5864959 - SUPPLIER MERGE UPDATED PA DATA WHEN ONLY UPDATES TO    |
REM |                       UNPAID INVOICE IS SELECTED                                           |
REM | 30-05-2008  Jravisha  Bug 7125912:Performance enhancement                                  |
REM | 29-NOV-08   svivaram  Bug 7575377 - Modified FUCNTION Get_si_default_exp_org to return the |
REM |                       expenditure organization name only if it is present in               |
REM |						per_organization_units view and to return Null, if not present.      |
REM | 27-feb-09   svivaram  Bug 8289798 - Modified FUCNTION Get_si_cost_exp_item_date to care of |
REM |                       the change done in the return value of profile option                |
REM |						PA_AP_EI_DATE_DEFAULT, from meaning to lookup code.                  |
REM | 05-JUN-09  DJANASWA   Bug 8562065 : 8538965 :Supplier Merge program is corrupting CDL data |
REM |                       when run is done across supplier for ALL Invoices option.            |
REM | 27-Aug-09  rrambati   Bug#8845025: Performance issue with supplier merge program.	         |
REM |                       Added p_invoice_id parameter to allow AP to send the invoice_id      |
REM |                       updated by AP program so as to restrict the data selected in PA      |          
REM | 24-Jan-11  vekotha    Bug#10254549 :FP:10011690 Supplier merge program is not updating the |
REM |                       who columns in pa_expednditures_all and pa_cost_ditribution_lines_all| 
REM |                       tables                                                               |
REM | 23-Mar-2011 vikarora  Bug 9701340 : Changed Function Get_si_cost_exp_item_date Previously  |
REM |                       it was returning null if none of the condition was matched . We      |
REM |                       changed it to retun the transaction date e.i. p_transaction_date;    |
REM | 01-NOV-2011 jjgeorge  Bug 13013074 Added no_unnest hint in the query in                    |
REM |                       UPD_PA_DETAILS_SUPPLIER_MERGE .Changes tagged with bug number.       |
REM |  01-Mar-2012 nbudi    Bug#13706985: expenditure item date validation enhancements          |
REM |                       Added two APIs, a procedure and  a function that will be used by     |
REM |                       AP Team in various scenarios of PO Match                             |
REM | 30-APR-2012   bdixit  Bug 14012059: Added last_updated_date and last_updated_by in ei      |
REM |                       update 																 |
REM | 28-MAY-2012   nbudi   Bug 14050469: Modified the query selecting award id,project id and   |
REM |                       task id in Get_Po_Match_Si_Exp_Item_Date and also added validation   |
REM |                       for GMS 															 |
REM | 06-JUN-2012	nbudi   Bug 14057813: Modified the procedure Get_si_cost_exp_item_date to use|
REM |                       a global variable to return source doc ei date if transaction gl     |
REM |                       date(or any) fails validation 										 |
REM | 27-JUL-2012	nbudi   Bug 14057813: Modified the procedure Get_Po_Match_Si_Exp_Item_Date to|
REM |                       use the standard procedur patc.get_status to improve the quality of  |
REM |                       validation 															 |
REM | 16-Aug-2012 rboyalap  Bug 14387738: Handled nvl for the variable p_invoice_id as it can be |
REM |                       null while updating the who columns of pa_expenditures_all table in  |
REM |                       the procedure UPD_PA_DETAILS_SUPPLIER_MERGE.                         |
REM | 29-AUG-2012	nbudi   Bug 14529067: Modified the procedure Get_Po_Match_Si_Exp_Item_Date to|
REM |                           pass null tokens as the message is getting displayed incorrectly  |
REM | 25-SEP-2012	utdas   Bug 14580572: In Procedure Get_Po_Match_Si_Exp_Item_Date, unnecessary space |
REM |                           has been removed for V_Gms_Message='GMS_AWARD_IS_CLOSED' and      |
REM |                           V_Gms_Message='GMS_AWARD_NOT_ACTIVE'                              |
REM | 27-DEC-2012	NBUDI  Bug 14501328: In Procedure Validate_Ei_Date, for some GMS and PA messages|
REM |				the new message is passed without reference to the profile option date       |
REM | 30-JAN-2013 arbandyo Bug 15934260 : Added additional validation in case POTRNSDT ot |
REM |                      Get_Po_Match_Si_Exp_Item_Date to display appropriate warning message |
REM |                      when matching an invoice to a PO for a closed project. Also made     |
REM |                      changes in Validate_Ei_Date                                          |
REM | 08-Feb-2013 speddi Bug 16193073 : Added additional validation in |
REM |                      Get_Po_Match_Si_Exp_Item_Date to display appropriate warning message |
REM |                      when matching an invoice to a PO. Also made     |
REM |                      changes in Validate_Ei_Date                                          |
REM |27-feb-2013  speddi Bug16401667:Modified the error the message and removed
REM |                    the extra text from the message.
REM | 28-MAR-2013 arbandyo Bug 16312792 : Added code in Get_Po_Match_Si_Exp_Item_Date to not    |
REM |                      throw warnings for INVENTORY POs if expenditure type, expenditure_item_date|
REM |                      and expenditure organization are not valid as costs from Inventory   |
REM |                      POs will come in through CSE transaction sources and not through AP/PO|
REM | 02-SEP-2013 viviverm Bug 16720575  : Forwardported changes of bug 14629489.                |
REM | 11-SEP-2013 viviverm Bug 17433208 : EXPENDITURE_ITEM_DATE on po matched invoice line was having date with |
REM |                      timestamp, and as the form truncates the time component, the lock API found a  |
REM |                      mismatch between the front end and back end date and raised FRM-40654          |
REM |                      So, truncated the date.                                                        |
REM | 19-SEP-2013 bdixit   Bug 17440081 : Modified code in Get_Po_Match_Si_Exp_Item_Date to not    |
REM |                      throw warnings for POs where destnation_type is not 'EXPENSE'            |
REM | 17-DEC-2103 viviverm Bug 17895878: Added condition to stamp supplier id in pa_expenditure_items_all |
REM |                      after supplier merge for PO reciepts items.                              |
REM | 01-JUL-2014 bdixit   Bug 19013397: Removed to_char from invoice_id, added to_number in orig_exp_txn_reference1 |
REM |                      to improve performance of Supplier Merge process                         |
REM | 04-Aug-2016 Psanjeevi Retrofit for R12.2.5 (Defect 30340)                                     |
REM +==================================================================================================+

CREATE OR REPLACE PACKAGE BODY pa_ap_integration AS
--$Header: PAAPINTB.pls 120.18.12020000.11 2014/07/01 06:20:56 bdixit ship $
g_po_match_date DATE := NULL;

PROCEDURE UPD_PA_DETAILS_SUPPLIER_MERGE
                           ( p_old_vendor_id   IN po_vendors.vendor_id%type,
                             p_new_vendor_id   IN po_vendors.vendor_id%type,
                             p_paid_inv_flag   IN ap_invoices_all.PAYMENT_STATUS_FLAG%type,
                             p_invoice_id      IN ap_invoices_all.invoice_id%TYPE DEFAULT NULL,  /* Bug# 8845025 */ 
                             x_stage          OUT NOCOPY VARCHAR2,
                             x_status         OUT NOCOPY VARCHAR2) 

IS
 /* bug 8845025 start */ 
  TYPE eiid_tbl IS TABLE OF PA_EXPENDITURE_ITEMS_ALL.expenditure_item_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE lnum_tbl IS TABLE OF PA_COST_DISTRIBUTION_LINES_ALL.line_num%TYPE INDEX BY BINARY_INTEGER;
  TYPE pdist_tbl IS TABLE OF PO_DISTRIBUTIONS_ALL.po_distribution_id%TYPE INDEX BY BINARY_INTEGER; /* Added for Bug 16720575  */

  eiid_rec eiid_tbl;
  lnum_rec lnum_tbl;

  type expid_tbl IS TABLE OF PA_EXPENDITURES_ALL.expenditure_id%TYPE INDEX BY BINARY_INTEGER;
  expid_rec expid_tbl;
  /* bug 8845025 end */

  /* Added for Bug 16720575  */
  p_dist_rec pdist_tbl;  
  expid_rec1 expid_tbl;
  /* Added for Bug 16720575  */


Begin
x_stage := 'Updating Pa_implementations Table';
Update pa_implementations_all set  Vendor_Id = p_new_vendor_id
Where  Vendor_Id = p_old_vendor_id;


/* Added for Bug 16720575  */
x_stage := 'Pulling out PO distributions matched to AP invoices';
select distinct po_distribution_id 
BULK COLLECT into p_dist_rec 
from ap_invoice_distributions_all apd,
     ap_invoices_all a
where a.vendor_id = p_new_vendor_id
and a.invoice_id = apd.invoice_id
and apd.project_id > 0
and apd.po_distribution_id is not null;
/* Added for Bug 16720575  */

x_stage := 'Updating Pa_Expenditures_All Table';
   /* Added for bug# 8845025 */
   UPDATE pa_expenditures_all e  
   SET   e.vendor_id = p_new_vendor_id  
         -- Bug#10254549 added the last updated columns    
         ,last_update_date = sysdate
         ,last_updated_by = fnd_global.user_id
         ,last_update_login =fnd_global.login_id
   WHERE e.vendor_id = p_old_vendor_id  and
         orig_exp_txn_reference1 = nvl(p_invoice_id, orig_exp_txn_reference1) and -- Added nvl for the Bug 14387738, Modified for bug 16720575 
         exists ( 
          select 1 from ap_invoices_all i
          where invoice_id = nvl(p_invoice_id, invoice_id) -- added nvl for the Bug 14387738, Modified for bug 16720575 
          and invoice_id = to_number(orig_exp_txn_reference1)   /* Bug 19013397: added to_number, removed to_char */
          and vendor_id = p_new_vendor_id 
          and payment_status_flag = DECODE (NVL (p_paid_inv_flag, 'Y'), 'N', 'N',  i.payment_status_flag)
                 )
      returning expenditure_id BULK COLLECT INTO expid_rec;

  /* Added for Bug 16720575  */
   x_stage := 'Updating Pa_Expenditures_All Table for invoices matched to POs';
   FOR I IN 1 .. p_dist_rec.count loop
   
      UPDATE pa_expenditures_all e  
      SET   e.vendor_id = p_new_vendor_id   
           ,last_update_date = sysdate
           ,last_updated_by = fnd_global.user_id
           ,last_update_login =fnd_global.login_id
      WHERE e.vendor_id = p_old_vendor_id  
        and orig_exp_txn_reference1 = p_dist_rec(i)
        and exists (select 1 
                    from rcv_receiving_sub_ledger rcv, 
                         po_distributions_all pod
                   where rcv.reference3 = e.orig_exp_txn_reference1
	                  and rcv.reference3 = to_char(pod.po_distribution_id)
	                  and pod.accrue_on_receipt_flag = 'Y'
	                  and rcv.pa_addition_flag='Y')
        returning expenditure_id BULK COLLECT INTO expid_rec1;
  end loop;
  /* Added for Bug 16720575  */

/*Code change for 	7125912 */
/* commenting for bug 8845025
UPDATE pa_expenditures_all e  
   SET e.vendor_id = p_new_vendor_id 
       -- Bug#10254549 added the last updated columns    
       ,last_update_date = sysdate
       ,last_updated_by = fnd_global.user_id
       ,last_update_login =fnd_global.login_id
 WHERE e.vendor_id = p_old_vendor_id  
   AND e.expenditure_id in (  
          SELECT ---- /*+ LEADING(ei) 
             ei.expenditure_id  
            FROM pa_cost_distribution_lines_all c,  
                 pa_expenditure_items_all ei,  
                 ap_invoices_all i  
           WHERE --TO_CHAR (i.invoice_id) = c.system_reference2  -- Changed by Paddy for performance defect 30340 (R12.2.5 Retrofit)
		  i.invoice_id= TO_NUMBER(c.system_reference2)  -- Changed by Paddy for performance defect 30340 (R12.2.5 Retrofit)
             AND c.expenditure_item_id = ei.expenditure_item_id  
            -- AND ei.expenditure_id = e.expenditure_id  
             AND c.system_reference1 = TO_CHAR(p_old_vendor_id)  
             AND i.vendor_id = p_new_vendor_id  
             AND i.payment_status_flag = DECODE (NVL (p_paid_inv_flag, 'Y'), 'N', 'N', i.payment_status_flag)  
                )  ;  */
/*Code change for 	7125912  END */
x_stage := 'Updating Pa_Expenditure_Items_All Table';

/*Changed for Bug:5864959*/
/* Bug 13013074 Added no_unnest hint */	
Update pa_expenditure_items_all ei 
set vendor_id =  p_new_vendor_id 
,last_update_date = sysdate     --bug 14012059       
,last_updated_by = fnd_global.user_id -- bug 14012059 
Where  Vendor_Id = p_old_vendor_id 
  and exists 
       (select /*+ no_unnest */ 1 
        from  pa_cost_distribution_lines_all c, 
              ap_invoices_all i 
        where i.invoice_id = to_number(c.system_reference2) 
        and   c.expenditure_item_id = ei.expenditure_item_id 
        and   c.system_reference1 = p_old_vendor_id 
        and   i.vendor_id = p_new_vendor_id 
        and   i.PAYMENT_STATUS_FLAG = 
decode(nvl(p_paid_inv_flag,'Y'),'N','N',i.PAYMENT_STATUS_FLAG) 
        ); 
/* Added for bug 17895878*/ 
FORALL I IN 1 .. expid_rec1.count
 UPDATE PA_EXPENDITURE_ITEMS_ALL ei
   SET ei.vendor_id       = p_new_vendor_id,
     ei.last_update_date  = sysdate,
     ei.last_updated_by   = fnd_global.user_id,
     ei.last_update_login = fnd_global.login_id
 where expenditure_id = expid_rec1(i);
		
x_stage := 'Updating Pa_Cost_Distribution_Lines_All Table';
/* Added for bug# 8845025 */

  FORALL I IN 1 .. expid_rec.count
   UPDATE  PA_COST_DISTRIBUTION_LINES_ALL
   SET     System_reference1 = to_char(p_new_vendor_id)
           -- Bug#10254549 added the program update columns
           ,program_id = FND_GLOBAL.CONC_PROGRAM_ID()
           ,program_update_date = sysdate
   WHERE   expenditure_item_id IN (
             SELECT expenditure_item_id 
             FROM PA_EXPENDITURE_ITEMS_ALL ei
             WHERE ei.expenditure_id = expid_rec(i)
             );

/* Added for Bug 16720575  */
  FORALL I IN 1 .. expid_rec1.count
   UPDATE  PA_COST_DISTRIBUTION_LINES_ALL
   SET     System_reference1 = to_char(p_new_vendor_id)
           ,program_id = FND_GLOBAL.CONC_PROGRAM_ID()
           ,program_update_date = sysdate
   WHERE   expenditure_item_id IN (
             SELECT expenditure_item_id 
             FROM PA_EXPENDITURE_ITEMS_ALL ei
             WHERE ei.expenditure_id = expid_rec1(i)
             );
/* Added for Bug 16720575 */

/* Commented for bug# 88845025
If nvl(p_paid_inv_flag,'Y') = 'N' Then

--Code change for 	7125912 
 Declare Cursor c1 is
      Select c.rowid row_id, c.expenditure_item_id, c.line_num
      from pa_cost_distribution_lines_all c, ap_invoices_all i
      where --to_char(i.invoice_id) = c.system_reference2  -- Changed by Paddy for performance defect 30340 (R12.2.5 Retrofit)
   	      i.invoice_id= TO_NUMBER(c.system_reference2)  -- Changed by Paddy for performance defect 30340 (R12.2.5 Retrofit)
     --and i.vendor_id = to_number(c.system_reference1) --Vendor_ID on Invoice is already  changed...so this is not needed 
       and c.system_reference1 = to_char(p_old_vendor_id)
       and i.vendor_id = p_new_vendor_id
       and i.PAYMENT_STATUS_FLAG = 'N';
        
--Code change for 	7125912 END 
  Begin

  x_stage := 'Updating Pa_Cost_Distribution_Lines_All Table For UNPAID Invoices';

  For Rec in C1 Loop

	Update pa_cost_distribution_lines_all
	Set    System_reference1 = (p_new_vendor_id)
               -- Bug#10254549 added the program update columns
               ,program_id = FND_GLOBAL.CONC_PROGRAM_ID()
               ,program_update_date = sysdate
	Where  rowid = rec.row_id;

  End Loop;
  End;

Else  -- p_paid_inv_flag <> 'N'

  x_stage := 'Updating Pa_Cost_Distribution_Lines_All Table For ALL Invoices';

  Update Pa_Cost_Distribution_Lines_All cdl
  Set    System_Reference1 = to_char(p_new_vendor_id)
          -- Bug#10254549 added the program update columns
         ,program_id = FND_GLOBAL.CONC_PROGRAM_ID()
         ,program_update_date = sysdate
  Where  System_Reference1 = to_char(p_old_vendor_id)
  And    system_reference1 is not null
  And    system_reference2 is not null
  And    system_reference3 is not null
  and exists (select 1  -- added this for bug8562065 
                   from ap_invoices_all inv
                  where --to_char(inv.invoice_id) = cdl.system_reference2 -- changed by Paddy for performance defect 30340 (R12.2.5 Retrofit)
	  			   inv.invoice_id = TO_NUMBER(cdl.system_reference2)  -- changed by Paddy for performance defect 30340 (R12.2.5 Retrofit)
                    and inv.vendor_id = p_new_vendor_id 
              );


End If;  for bug 8845025*/

--R12 need to update vendor ID on pa_bc_packets
x_stage := 'Updating Pa_Bc_Packets Table';
Update pa_bc_packets
set  Vendor_Id = p_new_vendor_id
Where  Vendor_Id = p_old_vendor_id
And  Status_Code = 'A';

--R12 need to update vendor ID on pa_bc_commitments
x_stage := 'Updating Pa_Bc_Commitments_All Table';
Update pa_bc_commitments_all
set  Vendor_Id = p_new_vendor_id
Where  Vendor_Id = p_old_vendor_id;

  x_stage := 'Updating Pa_Project_Asset_Lines_All Table For ALL Invoices';

update pa_project_asset_lines_all set po_vendor_id = p_new_vendor_id
where  po_vendor_id = p_old_vendor_id
and    po_vendor_id is not null;

/* Added for bug 2649043  */

  x_stage := 'Updating PA_CI_SUPPLIER_DETAILS Table For ALL Invoices';

update PA_CI_SUPPLIER_DETAILS set vendor_id = p_new_vendor_id
where  vendor_id = p_old_vendor_id
and    vendor_id is not null;

/* Summarization Changes */

-- FP.M Resource LIst Data Model Impact Changes, 09-JUN-04, jwhite -----------------------------
-- Augmented original code with additional filter 

/* -- Original Code
Declare
Cursor c_resource_list is
Select distinct resource_list_id from pa_resource_list_members 
where vendor_id = p_old_vendor_id and enabled_flag = 'Y';
*/

-- FP.M Data Model Logic 

Declare
Cursor c_resource_list is
Select distinct resource_list_id from pa_resource_list_members 
where vendor_id = p_old_vendor_id 
and enabled_flag = 'Y'
 and nvl(migration_code,'M')= 'M';

-- End: FP.M Resource LIst Data Model Impact Changes -----------------------------



/*****
l_new_vendor_exists_member varchar2(1) := 'N';
l_new_vendor_exists_resource varchar2(1) := 'N';
*******Bug# 4029384*/

l_new_vendor_exists_member number := 0;      /*Bug# 4029384*/
l_new_vendor_exists_resource number := 0;   /*Bug#  4029384*/ 
 
l_new_vendor_name po_vendors.vendor_name%type;

l_expenditure_category pa_resource_list_members.expenditure_category%type;
l_parent_member_id pa_resource_list_members.resource_list_member_id%type;
l_resource_list_member_id pa_resource_list_members.resource_list_member_id%type;
l_track_as_labor_flag varchar2(10);
l_err_code Varchar2(200);
l_err_stage Varchar2(200);
l_err_stack Varchar2(2000);
l_resource_id pa_resources.resource_id%type;

Begin
x_stage := 'Start For Summarization';
for rec1 in c_resource_list loop
 
   x_stage := 'New Vendor Name';
   Select vendor_name into l_new_vendor_name from po_vendors where vendor_id = p_new_vendor_id;

   Begin
   x_stage:='See whether New vendor exists as resource in PA tables'; 

   Select nvl(count(a.name),0) into l_new_vendor_exists_resource from pa_resource_types b, pa_resources a
   where  a.RESOURCE_TYPE_ID=b.RESOURCE_TYPE_ID and b.RESOURCE_TYPE_CODE='VENDOR'
   And    a.name = l_new_vendor_name;
  
   Exception When no_data_found then l_new_vendor_exists_resource := 0;
   
   End;    

   If  l_new_vendor_exists_resource = 0 Then -- Insert New vendor as a resource 

   x_stage := 'New Vendor Does Not Exists ... Creating New vendor as resource';

				PA_CREATE_RESOURCE.Create_Resource 
				(p_resource_name             =>  l_new_vendor_name,
                                 p_resource_type_Code        =>  'VENDOR',
                                 p_description               =>  l_new_vendor_name,
                                 p_unit_of_measure           =>  NULL,    
                                 p_rollup_quantity_flag      =>  NULL,    
                                 p_track_as_labor_flag       =>  NULL,    
                                 p_start_date                =>  to_date('01/01/1950','DD/MM/YYYY'),
                                 p_end_date                  =>  NULL,
                                 p_person_id                 =>  NULL,
                                 p_job_id                    =>  NULL, 
                                 p_proj_organization_id      =>  NULL,
                                 p_vendor_id                 =>  p_new_vendor_id,
                                 p_expenditure_type          =>  NULL,
                                 p_event_type                =>  NULL,
                                 p_expenditure_category      =>  NULL,
                                 p_revenue_category_code     =>  NULL,
                                 p_non_labor_resource        =>  NULL,
                                 p_system_linkage            =>  NULL, 
                                 p_project_role_id           =>  NULL,
                                 p_resource_id               =>  l_resource_id,
                                 p_err_code                  =>  l_err_code,
                                 p_err_stage                 =>  x_stage,
                                 p_err_stack                 =>  l_err_stack);
   End If;


       -- FP.M Resource LIst Data Model Impact Changes, 09-JUN-04, jwhite -----------------------------
       -- Augmented original code with additional filter for migration_code


	Begin

/* --Origianal Code

		Select nvl(count(*),0) into l_new_vendor_exists_member from pa_resource_list_members 
		where 	resource_list_id = rec1.resource_list_id and VENDOR_ID = p_new_vendor_id;
*/


  -- FP.M Data Model

                Select nvl(count(*),0) 
                into l_new_vendor_exists_member 
                from pa_resource_list_members 
		where 	resource_list_id = rec1.resource_list_id 
                and VENDOR_ID = p_new_vendor_id
                    and nvl(migration_code,'M') = 'M';


		exception when no_data_found then l_new_vendor_exists_member := 0;

	End;


/* --Origianal Code
	
		update pa_resource_list_members set enabled_flag = 'N'
		where  resource_list_id = rec1.resource_list_id
		and    vendor_id = p_old_vendor_id;
*/



  -- FP.M Data Model

                update pa_resource_list_members set 
                enabled_flag = 'N'
		where  resource_list_id = rec1.resource_list_id
		and    vendor_id = p_old_vendor_id
                    and nvl(migration_code,'M') = 'M';

       -- End: FP.M Resource LIst Data Model Impact Changes -----------------------------



   If  l_new_vendor_exists_member = 0 Then -- Insert New vendor as a resource list member
       
	    x_stage:=' New Vendor Does not esists as resource member.. creating resource member'; 

	Declare

	L_RESOURCE_LIST_ID              PA_RESOURCE_LIST_MEMBERS.RESOURCE_LIST_ID%TYPE;
	L_RESOURCE_ID			PA_RESOURCE_LIST_MEMBERS.RESOURCE_ID%TYPE;
	L_ORGANIZATION_ID         	PA_RESOURCE_LIST_MEMBERS.ORGANIZATION_ID%TYPE;
	L_EXPENDITURE_CATEGORY		PA_RESOURCE_LIST_MEMBERS.EXPENDITURE_CATEGORY%TYPE;
	L_REVENUE_CATEGORY		PA_RESOURCE_LIST_MEMBERS.REVENUE_CATEGORY%TYPE;
        l_res_grouped                   PA_RESOURCE_LISTS_ALL_BG.group_resource_type_id%TYPE;  /*Bug# 4029384*/ 
	Begin


 -- FP.M Resource LIst Data Model Impact Changes, 09-JUN-04, jwhite -----------------------------
 -- Augmented original code with additional filter 

/* -- Original Logic


	SELECT 
	RESOURCE_LIST_ID, RESOURCE_ID, ORGANIZATION_ID, EXPENDITURE_CATEGORY, REVENUE_CATEGORY  
 	INTO 
 	L_RESOURCE_LIST_ID, L_RESOURCE_ID, L_ORGANIZATION_ID,L_EXPENDITURE_CATEGORY, L_REVENUE_CATEGORY
 	From pa_resource_list_members
 	Where RESOURCE_LIST_ID = rec1.resource_list_id
 	And   resource_list_member_id  = (Select parent_member_id from pa_resource_list_members 
				   where RESOURCE_LIST_ID = rec1.resource_list_id
				   and vendor_id= p_old_vendor_id);
*/


 -- FP.M Data Model Logic 

/*Bug# 4029384*/
        select group_resource_type_id 
        into l_res_grouped
        from pa_resource_lists_all_BG
        where  RESOURCE_LIST_ID = rec1.resource_list_id;

       IF (l_res_grouped <> 0) THEN    /*To check if resource list is grouped */

	SELECT 
 	 RESOURCE_LIST_ID, RESOURCE_ID, ORGANIZATION_ID, EXPENDITURE_CATEGORY, REVENUE_CATEGORY  
 	INTO 
 	 L_RESOURCE_LIST_ID, L_RESOURCE_ID, L_ORGANIZATION_ID,L_EXPENDITURE_CATEGORY, L_REVENUE_CATEGORY
 	From pa_resource_list_members
 	Where RESOURCE_LIST_ID = rec1.resource_list_id
 	And   resource_list_member_id  = (Select parent_member_id from pa_resource_list_members 
	     			          where RESOURCE_LIST_ID = rec1.resource_list_id
				           and vendor_id= p_old_vendor_id
                                           and nvl(migration_code,'M') = 'M' );

 -- End: FP.M Resource LIst Data Model Impact Changes -----------------------------
      
       ELSE /*If resource list is not grouped*/ 

        SELECT
         RESOURCE_LIST_ID, RESOURCE_ID, ORGANIZATION_ID, EXPENDITURE_CATEGORY, REVENUE_CATEGORY
        INTO
         L_RESOURCE_LIST_ID, L_RESOURCE_ID, L_ORGANIZATION_ID,L_EXPENDITURE_CATEGORY, L_REVENUE_CATEGORY
        From pa_resource_list_members
        Where RESOURCE_LIST_ID = rec1.resource_list_id
         and vendor_id =p_old_vendor_id 
         and nvl(migration_code,'M') = 'M';


       END IF;   /*End of changes of Bug# 4029384*/

			PA_CREATE_RESOURCE.Create_Resource_list_member
                         (p_resource_list_id          =>  rec1.resource_list_id,
                          p_resource_name             =>  l_new_vendor_name,
                          p_resource_type_Code        =>  'VENDOR',
                          p_alias                     =>  l_new_vendor_name,
                          p_sort_order                =>  NULL,  
                          p_display_flag              =>  'Y',
                          p_enabled_flag              =>  'Y', 
                          p_person_id                 =>  NULL,  
                          p_job_id                    =>  NULL,  
                          p_proj_organization_id      =>  L_ORGANIZATION_ID,  
                          p_vendor_id                 =>  p_new_vendor_id, 
                          p_expenditure_type          =>  NULL, 
                          p_event_type                =>  NULL,    
                          p_expenditure_category      =>  l_expenditure_category,    
                          p_revenue_category_code     =>  L_REVENUE_CATEGORY,    
                          p_non_labor_resource        =>  NULL,    
                          p_system_linkage            =>  NULL,    
                          p_project_role_id           =>  NULL,    
                          p_parent_member_id          =>  l_parent_member_id,
                          p_resource_list_member_id   =>  l_resource_list_member_id,
                          p_track_as_labor_flag       =>  l_track_as_labor_flag,
                          p_err_code                  =>  l_err_code,
                          p_err_stage                 =>  x_stage,
                          p_err_stack                 =>  l_err_stack);
	End;
   End If;


   x_stage := ' Calling Resource List change api to update summarization data';
   /* The following code need to be called from API for resource list merger and refresh summary amounts */

		pa_proj_accum_main.ref_rl_accum(
               		    	l_err_stack,
                   		l_err_code,
                   		NULL,
                   		NULL,
                   		rec1.resource_list_id);

End Loop;



end; /** End Summarization **/

End UPD_PA_DETAILS_SUPPLIER_MERGE;


FUNCTION Allow_Supplier_Merge ( p_vendor_id         IN po_vendors.vendor_id%type
                            )
RETURN varchar2
IS
    l_budget_exists    Varchar2(1);
    l_allow_merge_flg  Varchar2(1); -- FP.M Change
BEGIN

 -- FP.M Resource LIst Data Model Impact Changes, 09-JUN-04, jwhite -----------------------------
 -- Augmented original code with additional filter 

/* -- Original Logic

select 'Y' into l_budget_exists
from pa_resource_assignments assign, pa_resource_list_members member, pa_budget_lines budget
where assign.RESOURCE_LIST_MEMBER_ID=member.RESOURCE_LIST_MEMBER_ID
and   member.vendor_id = p_vendor_id 
and   budget.resource_assignment_id = assign.resource_assignment_id
and   rownum < 2 ;


*/

   -- FP.M Data Model Logic 

    select 'Y' 
    into l_budget_exists
    from pa_resource_assignments assign
    , pa_resource_list_members member
    , pa_budget_lines budget
    where assign.RESOURCE_LIST_MEMBER_ID=member.RESOURCE_LIST_MEMBER_ID
    and   member.vendor_id = p_vendor_id 
    and   budget.resource_assignment_id = assign.resource_assignment_id
    and   rownum < 2 
     and  nvl(member.migration_code,'M') = 'M';


  -- End: FP.M Resource LIst Data Model Impact Changes -----------------------------


-- Since Budget exists for the vendor to be merged Do not allow Supplier merge

Return 'N';
 
   -- FP.M change. 
   -- pa_resource_utils.chk_supplier_in_use function checks to see if the given supplier ID is used by any
   -- planning resource lists or resource breakdown structures.  If it is in use, it returns 'Y'; if not, 
   -- it returns 'N'. If the value returned is Y, Supplier merge is not allowed.

Exception 
 When no_data_found then 
   select decode(pa_resource_utils.chk_supplier_in_use(p_vendor_id),'Y','N','Y')
   into   l_allow_merge_flg
   from   dual;
Return  l_allow_merge_flg;
END Allow_Supplier_Merge;

/***************************************************************************   
   Procedure        : get_asset_addition_flag
   Purpose          : When Expense Reports are sent to AP from PA,
                      the intermediate tables ap_expense_report_headers_all
                      and ap_expense_report_lines_all are populated. A Process 
                      process in AP then populates the
                      Invoice Distribution tables. As there is no way in the
                      intermediate tables, to find out if the expense report is
                      associated with a 'Capital Project', which should not be 
                      interfaced from AP to FA, unlike Invoice Distribution line
                      table, where asset_addition_flag is used. This API is to
                      find out if the given project_id is a 'CAPITAL' project 
                      and if so, populate the 'out' vairable to 'P', else 'U'.
   Arguments        : p_project_id            IN - project id
                      x_asset_addition_flag  OUT - asset addition flag
****************************************************************************/                      


PROCEDURE get_asset_addition_flag
             (p_project_id           IN  pa_projects_all.project_id%TYPE,
              x_asset_addition_flag  OUT NOCOPY ap_invoice_distributions_all.assets_addition_flag%TYPE)
IS

   l_project_type_class_code  pa_project_types_all.project_type_class_code%TYPE;

BEGIN

  /* For Given Project Id, Get the Project_Type_Class_Code depending on the Project_Type */
  SELECT  ptype.project_type_class_code
    INTO  l_project_type_class_code
    FROM  pa_project_types_all ptype,
          pa_projects_all      proj
   WHERE  ptype.project_type     = proj.project_type
     --R12 AND  NVL(ptype.org_id, -99) = NVL(proj.org_id, -99)
     AND  ptype.org_id = proj.org_id
     AND  proj.project_id        = p_project_id;

   /* IF Project is CAPITAL then set asset_addition_flag to 'P' else 'U' */
   
   IF (l_project_type_class_code = 'CAPITAL') THEN
   
     x_asset_addition_flag  := 'P'; 
   
   ELSE 
     
     x_asset_addition_flag  := 'U';
     
   END IF;

EXCEPTION

   WHEN OTHERS THEN
     RAISE;

END get_asset_addition_flag;

/***************************************************************************
   Function         : Get_Project_Type
   Purpose          : This function will check if the project id passed to this 
                      is a 'CAPITAL' Project.If it is then this will return 
                      'P' otherwise 'U'
   Arguments        : p_project_id            IN           - project id
                      Returns 'P' if the project is Capital otherwise 'U'
****************************************************************************/

FUNCTION Get_Project_Type 
       (p_project_id IN pa_projects_all.project_id%TYPE)RETURN VARCHAR2 IS
l_project_type VARCHAR2(1);

BEGIN

/* For Given Project Id, Get the Project_Type_Class_Code depending on the Project_Type */

 SELECT decode(ptype.project_type_class_code,'CAPITAL','P','U')
  INTO  l_project_type
  FROM  pa_project_types_all ptype,
        pa_projects_all      proj
 WHERE proj.project_type = ptype.project_type 
 -- R12 AND   NVL(ptype.org_id, -99) = NVL(proj.org_id, -99)
 AND   ptype.org_id = proj.org_id
 AND   proj.project_id   = p_project_id ;

 RETURN l_project_type;     

 EXCEPTION
    WHEN OTHERS THEN
        RAISE;
  END Get_Project_Type;

-- ==========================================================================================================================================
-- Bug 5201382 R12.PJ:XB3:DEV:NEW API TO RETRIEVE THE DATES FOR PROFILE PA_AP_EI_DATE_DEFAULT 
-- p_transaction_date : API would return transaction date when profile value was set to 'Transaction Date' 
--                       a. For Invoice transaction invoice_date should be passed as parameter 
--                       b. For PO or Receipt Matched Invoice  Transactions invoice_date should be passed as parameter 
--                       c. For RCV Transactions transaction_date should be passed. 
--                       d. For payments and discounts ap dist exp_item_date should be passed. 
-- p_gl_date          : API would return transaction date when profile value was set to 'Transaction GL Date' 
--                      a. For Invoice transactions gl_date should be passed b. For payments and discounts the accounting date must be passed 
--                      c. for RCV transactions accounting date should be passed. 
-- p_po_exp_item_date : API would return the purchase order expenditure item date for po matched cases when profile value was set to 
--                      'PO Expenditure Item Date/Transaction Date'. This is used for PO matched cases. It may be NULL when 
--                       p_po_distribution_id was passed to the API. 
-- p_po_distribution_id: The parameter value is used to determine the purchase order expenditure item date for po matched cases when profile 
--                        value was set to 'PO Expenditure Item Date/Transaction Date'. when p_po_exp_item_date was passed  then 
--                        p_po_distribution_id is not used to derive the expenditure item date. 
-- p_creation_date : API would return this date when profile value was set to 'Transaction System Date' 
-- p_calling_program : a. when called during the PO Match case : PO-MATCH b. When called from Invoice form        : APXINWKB 
--                     c. When called from supplier cost xface for discounts : DISCOUNT d. When called from supplier cost xface for Payment: PAYMENT 
--                     e. When called from supplier cost xface for Receipts  : RECEIPT 
-- ==========================================================================================================================================
FUNCTION Get_si_cost_exp_item_date ( p_transaction_date      IN pa_expenditure_items_all.expenditure_item_date%TYPE,
                                     p_gl_date               IN pa_cost_distribution_lines_all.gl_date%TYPE, 
                                     p_po_exp_item_date      IN pa_expenditure_items_all.expenditure_item_date%TYPE,
                                     p_creation_date         IN pa_expenditure_items_all.creation_date%TYPE, 
                                     p_po_distribution_id    IN pa_expenditure_items_all.document_distribution_id%TYPE, 
                                     p_calling_program       IN varchar2  ) 
 RETURN date is
    l_return_date          date ;
    l_pa_exp_date_default  varchar2(50) ;
    l_pa_debug_flag        varchar2(1) ;

    cursor c_po_date is 
      select expenditure_item_date 
        from po_distributions_all 
       where po_distribution_id = p_po_distribution_id ;

 BEGIN 
    l_pa_debug_flag :=  NVL(FND_PROFILE.value('PA_DEBUG_MODE'), 'N');
    l_pa_exp_date_default := FND_PROFILE.VALUE('PA_AP_EI_DATE_DEFAULT'); 
   
   IF l_pa_debug_flag = 'Y' THEN
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
         FND_LOG.string(FND_LOG.LEVEL_STATEMENT,'PA_AP_INTEGRATION', 'Default Exp item date profile:'||l_pa_exp_date_default) ; 
      END IF ;
   END IF ;

/*bug 14057183*/
   IF g_po_match_date is NOT NULL AND p_calling_program = 'PO-MATCH' THEN 
   return g_po_match_date; 
   END IF;

   /* Changes for bug 8289798 : Modified the case statements to handle lookup codes , rather than meanings*/
   CASE l_pa_exp_date_default 
         WHEN 'INVTRNSDT' THEN 
                l_return_date := p_transaction_date ; 
         WHEN 'INVGLDT' THEN 
                l_return_date := p_gl_date ; 
         WHEN 'INVSYSDT' THEN 
                l_return_date := p_creation_date ; 
         -- Bug: 5262492 (R12.PJ:XB5:QA:APL: PROJECT EI DATE NULL FOR PO/REC MATCHED INVOICE LINE/DISTRIBU 
         WHEN 'POTRNSDT' THEN 
              IF p_po_exp_item_date is not NULL then 
                 l_return_date := p_po_exp_item_date  ;
              ELSE 
                IF l_pa_debug_flag = 'Y' THEN
                   IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
                      FND_LOG.string(FND_LOG.LEVEL_STATEMENT,'PA_AP_INTEGRATION', 'PO expenditure item date is NULL') ; 
                   END IF ;
                END IF ;

                IF p_po_distribution_id is not NULL then 
                   open c_po_date ;
		   fetch c_po_date into l_return_date ;
		   close c_po_date ;
                   IF l_pa_debug_flag = 'Y' THEN
                      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
                         FND_LOG.string(FND_LOG.LEVEL_STATEMENT,'PA_AP_INTEGRATION', 
			                'Determining the date based on the PO distribution IDL') ; 
                      END IF ;
                   END IF ;
		ELSE
		-- Bug : 4940969
		-- In the case of unmatched invoice the Invoice date must get @ defaulted as the EI date.
		   l_return_date := p_transaction_date ;

                END IF ; 
	      END IF ;
         ELSE 
                l_return_date := p_transaction_date ; --Changed from null to p_transaction_date for Bug 9701340

   END CASE; 
         
    IF l_pa_debug_flag = 'Y' THEN
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
         FND_LOG.string(FND_LOG.LEVEL_STATEMENT,'PA_AP_INTEGRATION', 'Date returned :'||to_char(l_return_date, 'DD-MON-YYYY')) ; 
      END IF ;
   END IF ;

   return trunc(l_return_date) ; --Bug 17433208


 End Get_si_cost_exp_item_date ;


FUNCTION Get_si_default_exp_org RETURN varchar2 is 
   l_default_exp_org HR_ALL_ORGANIZATION_UNITS_TL.NAME%TYPE; /* Bug 5555041 */
   l_organization_id HR_ALL_ORGANIZATION_UNITS_TL.ORGANIZATION_ID%TYPE; /* Bug 5555041 */
   l_default_exp_org1 HR_ALL_ORGANIZATION_UNITS_TL.NAME%TYPE; /* Bug 7575377 */

/* Bug 5555041 - Start */
   CURSOR c_get_org_id(p_org_name HR_ALL_ORGANIZATION_UNITS_TL.NAME%TYPE) IS
   SELECT organization_id
   FROM hr_all_organization_units_tl
   WHERE name = p_org_name;

   CURSOR c_get_org_name(p_organization_id HR_ALL_ORGANIZATION_UNITS_TL.ORGANIZATION_ID%TYPE) IS
   SELECT name
   FROM per_organization_units
   WHERE organization_id = p_organization_id;
/* Bug 5555041 - End */
BEGIN
    l_default_exp_org := FND_PROFILE.VALUE('PA_DEFAULT_EXP_ORG'); 

/* Bug 5555041 - Start */
    OPEN  c_get_org_id(l_default_exp_org);
    FETCH c_get_org_id INTO l_organization_id;
    CLOSE c_get_org_id;

    OPEN c_get_org_name(l_organization_id);
    FETCH c_get_org_name INTO l_default_exp_org1; /* Modified for bug 7575377 */
    CLOSE c_get_org_name;
/* Bug 5555041 - End */

    return l_default_exp_org1 ; /* Modified for bug 7575377 */
END Get_si_default_exp_org ;


/*13706985  - Start*/

/***************************************************************************
   Procedure        :	Get_Po_Match_Si_Exp_Item_Date
   Purpose           :	Bug#13706985 PO match action does not verify whether EI
				date falls in a closed PA period or not. During PO match AP invokes API
				PA_AP_INTEGRATION.Get_Si_Cost_Exp_Item_Date to retrieve the 
				EI date and stamps the date returned by the API as the EI date. 
				This procedure is an enhancement to the previous function 
				which returns specific error messages to the calling 
				program based on the validation of the expenditure item date
   Arguments        :	     p_transaction_date		IN
				     p_gl_date				IN
				     p_po_exp_item_date		IN
				     p_creation_date			IN
				     p_po_distribution_id		IN
				     p_calling_program		IN 
				     p_exp_item_date		OUT 
				     p_date_valid_flag		OUT
				     p_pa_message_name	OUT
****************************************************************************/

PROCEDURE Get_Po_Match_Si_Exp_Item_Date
             (	p_transaction_date			IN  DATE,
		p_gl_date					IN  DATE, 
		p_po_exp_item_date		IN  DATE,
		p_creation_date			IN  DATE,
		p_po_distribution_id		IN  po_distributions_all.po_distribution_id%TYPE, 
		p_calling_program			IN  VARCHAR2,
	  	p_exp_item_date			OUT NOCOPY DATE,
		p_is_date_valid			OUT NOCOPY VARCHAR2,
		p_pa_message_name		OUT  NOCOPY varchar2,
		p_token_value1			OUT NOCOPY VARCHAR2,
		p_token_value2			OUT NOCOPY VARCHAR2)
	      
IS

	l_return_date			DATE ;
	l_pa_exp_date_default	VARCHAR2(50) ;
	l_pa_debug_flag		VARCHAR2(1) ;
	l_gms_installed		BOOLEAN; /*Added for bug 14050469*/
	l_po_exp_item_date	DATE;
	l_pa_date			DATE;
	
	l_award_id			NUMBER ;
	l_project_id			NUMBER;
	l_task_id				NUMBER;
	l_expenditure_type	VARCHAR2(30);
	l_profile_date			DATE;
	l_DESTINATION_TYPE_CODE  VARCHAR2(25); /* Added for bug 16312792 */	
	

	V_PROJECT_ID NUMBER;
	V_TASK_ID NUMBER;
	V_PROFILE_DATE DATE;
	V_EXPENDITURE_TYPE VARCHAR2(30);
	V_NON_LABOR_RESOURCE VARCHAR2(30);
	V_EMPLOYEE_ID NUMBER;
	V_QUANTITY NUMBER;
	V_DENOM_CURRENCY_CODE VARCHAR2(15);
	V_ACCT_CURRENCY_CODE VARCHAR2(15);
	V_INVOICE_AMOUNT NUMBER;
	V_ACCT_RAW_COST NUMBER;
	V_RATE_DATE DATE;
	V_RATE_TYPE VARCHAR2(30);
	V_RATE NUMBER;
	V_TRANSFER_EI NUMBER;
	V_EXP_ORG_ID NUMBER(15);
	V_NL_RES_ORG_ID NUMBER(15);
	V_TRANSACTION_SOURCE VARCHAR2(30);
	V_VENDOR_ID NUMBER;
	V_ENTERED_BY_USER_ID NUMBER;
	V_ATTRIBUTE_CATEGORY VARCHAR2(150);
	V_ATTRIBUTE1 VARCHAR2(150);
	V_ATTRIBUTE2 VARCHAR2(150);
	V_ATTRIBUTE3 VARCHAR2(150);
	V_ATTRIBUTE4 VARCHAR2(150);
	V_ATTRIBUTE5 VARCHAR2(150);
	V_ATTRIBUTE6 VARCHAR2(150);
	V_ATTRIBUTE7 VARCHAR2(150);
	V_ATTRIBUTE8 VARCHAR2(150);
	V_ATTRIBUTE9 VARCHAR2(150);
	V_ATTRIBUTE10 VARCHAR2(150);
	V_ATTRIBUTE11 VARCHAR2(150);
	V_ATTRIBUTE12 VARCHAR2(150);
	V_ATTRIBUTE13 VARCHAR2(150);
	V_ATTRIBUTE14 VARCHAR2(150);
	V_ATTRIBUTE15 VARCHAR2(150);

	V_Msg_Application VARCHAR2(10) := 'PA';
	V_MsgType VARCHAR2(150);
	V_MsgToken1 VARCHAR2(150);
	V_MsgToken2 VARCHAR2(150);
	V_MsgToken3 VARCHAR2(150);
	V_MsgName1 VARCHAR2(2000);
	V_MsgName2 VARCHAR2(2000);
	V_Gms_Message VARCHAR2(2000);
	V_billable_flag VARCHAR2(1);
	V_MSGCOUNT NUMBER;

	cursor c_po_date is
	select expenditure_item_date
        from po_distributions_all
	where po_distribution_id = p_po_distribution_id ;
																				

/* The cursor for getting all the variables to be passed to the patc.get_status proc. The use of ap_invoices_all is not done here as we dont have the invoice id being passed by AP */
	cursor patc_cursor is
	select 
	POD.project_id PROJECT_ID,
	POD.task_id TASK_ID,
	decode(NVL(FND_PROFILE.VALUE('PA_AP_EI_DATE_DEFAULT'),'POTRNSDT'),
	'INVTRNSDT',
	p_transaction_date,
	'INVGLDT',
	p_gl_date,
	'INVSYSDT',
	p_creation_date,
	'POTRNSDT',
	l_po_exp_item_date) PROFILE_DATE,
	POD.expenditure_type EXPENDITURE_TYPE,
	NULL NON_LABOR_RESOURCE,
	NULL EMPLOYEE_ID,
	QUANTITY_ORDERED QUANTITY,
	NULL ,
	G.CURRENCY_CODE,
	NULL,
	NULL ACCT_RAW_COST,
	NULL ,
	NULL ,
	NULL ,
	NULL TRANSFER_EI,
	POD.EXPENDITURE_ORGANIZATION_ID,
	NULL NL_RESOURCE_ORG_ID,
	'AP INVOICE' TRANSACTION_SOURCE,
	NULL,
	NULL ENTERED_BY_USER_ID,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
	from po_distributions_all pod,
	po_headers_all poh, 
	GL_SETS_OF_BOOKS G
	where
	poh.po_header_id = pod.po_header_id 
	and pod.po_distribution_id = p_po_distribution_id
	and G.set_of_books_id = pod.set_of_books_id;

 BEGIN
     l_pa_debug_flag :=  NVL(FND_PROFILE.value('PA_DEBUG_MODE'), 'N');
    /*In case of null value of profile option, we would use source doucment ei date*/
    l_pa_exp_date_default := NVL(FND_PROFILE.VALUE('PA_AP_EI_DATE_DEFAULT'),'POTRNSDT');

/* Verfication variable to check if gms is installed */
    l_gms_installed :=  pa_gms_api.vert_install; /*Added for bug 14050469*/
     
     IF p_po_exp_item_date is NULL THEN  /*bug 14057183*/
		IF p_po_distribution_id is not NULL then
			open c_po_date;
			fetch c_po_date into l_po_exp_item_date ;
			close c_po_date;
		END IF;
     END IF;

   IF l_pa_debug_flag = 'Y' THEN
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
         FND_LOG.string(FND_LOG.LEVEL_STATEMENT,'PA_AP_INTEGRATION', 'Default Exp item date profile:'||l_pa_exp_date_default) ;
      END IF ;
   END IF ;

/*bug 14050469 - Divided the single query for selecting all 3 - award id, project id and task id to two queries and also added the gms validation
for checking if the user is a gms user*/

begin
select  pod.project_id,pod.task_id,pod.expenditure_type,DESTINATION_TYPE_CODE /* Added for bug 16312792 */ 
into l_project_id,l_task_id,l_expenditure_type,l_DESTINATION_TYPE_CODE  /* Added for bug 16312792 */
        from po_distributions_all pod
     where   
       pod.po_distribution_id = p_po_distribution_id; 
exception when no_data_found then 
l_project_id := NULL;      
l_task_id := NULL;
l_expenditure_type := NULL;
l_DESTINATION_TYPE_CODE := NULL;  /* Added for bug 16312792 */
end;

/*If gms is installed then call the gms_transactions_pub.validate_transaction to validate the award information   */

IF l_gms_installed THEN /*Added for bug 14050469 */

begin
 select  awd.award_id,
		 decode(NVL(FND_PROFILE.VALUE('PA_AP_EI_DATE_DEFAULT'),'POTRNSDT'),
								'INVTRNSDT',
								p_transaction_date,
								'INVGLDT',
								p_gl_date,
								'INVSYSDT',
								p_creation_date,
								'POTRNSDT',
								l_po_exp_item_date)
 into l_award_id,l_profile_date
        from    gms_awards_all               awd, 
             po_distributions_all pod, 
             gms_award_distributions      adl
     where   adl.award_id          = awd.award_id 
       and   pod.po_distribution_id = p_po_distribution_id 
       and   pod.award_id                = adl.award_set_id 
       and   adl.adl_line_num            = 1 ;
exception when no_data_found then l_award_id := NULL;       
end;



gms_transactions_pub.validate_transaction( l_project_id, 
							  l_task_id, 
							   l_award_id, 
							   l_expenditure_type, 
							  l_profile_date , 
							   'APTXNIMP', 
							   V_Gms_Message ) ; /* Collect the out message into V_Gms_Message  */



END IF;


/* Open and fetch the cursor into the local variables defined. We pass these variables into patc.get_status */

OPEN patc_cursor;
FETCH patc_cursor INTO 
V_PROJECT_ID,
V_TASK_ID,
V_PROFILE_DATE,
V_EXPENDITURE_TYPE,
V_NON_LABOR_RESOURCE,
V_EMPLOYEE_ID,
V_QUANTITY,
V_DENOM_CURRENCY_CODE,
V_ACCT_CURRENCY_CODE,
V_INVOICE_AMOUNT,
V_ACCT_RAW_COST,
V_RATE_TYPE,
V_RATE_DATE,
V_RATE,
V_TRANSFER_EI,
V_EXP_ORG_ID,
V_NL_RES_ORG_ID,
V_TRANSACTION_SOURCE,
V_VENDOR_ID,
V_ENTERED_BY_USER_ID,
V_ATTRIBUTE_CATEGORY,
V_ATTRIBUTE1,
V_ATTRIBUTE2,
V_ATTRIBUTE3,
V_ATTRIBUTE4,
V_ATTRIBUTE5,
V_ATTRIBUTE6,
V_ATTRIBUTE7,
V_ATTRIBUTE8,
V_ATTRIBUTE9,
V_ATTRIBUTE10,
V_ATTRIBUTE11,
V_ATTRIBUTE12,
V_ATTRIBUTE13,
V_ATTRIBUTE14,
V_ATTRIBUTE15;
CLOSE patc_cursor;

/* Call the standard proc patc.get_status and collect the output 14057813*/
PATC.GET_STATUS(
  X_PROJECT_ID         => V_PROJECT_ID,
  X_TASK_ID            => V_TASK_ID,
  X_EI_DATE            => V_PROFILE_DATE,
  X_EXPENDITURE_TYPE   => V_EXPENDITURE_TYPE,
  X_NON_LABOR_RESOURCE => NULL,
  X_PERSON_ID          => V_EMPLOYEE_ID,
  X_QUANTITY           => V_QUANTITY,
  X_DENOM_CURRENCY_CODE =>V_DENOM_CURRENCY_CODE,
  X_ACCT_CURRENCY_CODE => V_ACCT_CURRENCY_CODE,
  X_DENOM_RAW_COST     => V_INVOICE_AMOUNT,
  X_ACCT_RAW_COST      => V_INVOICE_AMOUNT,
  X_ACCT_RATE_TYPE     => V_RATE_TYPE,
  X_ACCT_RATE_DATE     => V_RATE_DATE,
  X_ACCT_EXCHANGE_RATE => V_RATE,
  X_TRANSFER_EI        => V_TRANSFER_EI,
  X_INCURRED_BY_ORG_ID => V_EXP_ORG_ID,
  X_NL_RESOURCE_ORG_ID => V_NL_RES_ORG_ID,
  X_TRANSACTION_SOURCE => V_TRANSACTION_SOURCE,
  X_CALLING_MODULE     => 'APXINENT',
  X_VENDOR_ID          => V_VENDOR_ID,
  X_ENTERED_BY_USER_ID => V_ENTERED_BY_USER_ID,
  X_ATTRIBUTE_CATEGORY => V_ATTRIBUTE_CATEGORY,
  X_ATTRIBUTE1         => V_ATTRIBUTE1,
  X_ATTRIBUTE2         => V_ATTRIBUTE2,
  X_ATTRIBUTE3         => V_ATTRIBUTE3,
  X_ATTRIBUTE4         => V_ATTRIBUTE4,
  X_ATTRIBUTE5         => V_ATTRIBUTE5,
  X_ATTRIBUTE6         => V_ATTRIBUTE6,
  X_ATTRIBUTE7         => V_ATTRIBUTE7,
  X_ATTRIBUTE8         => V_ATTRIBUTE8,
  X_ATTRIBUTE9         => V_ATTRIBUTE9,
  X_ATTRIBUTE10        => V_ATTRIBUTE10,
  X_ATTRIBUTE11        => V_ATTRIBUTE11,
  X_ATTRIBUTE12        => V_ATTRIBUTE12,
  X_ATTRIBUTE13        => V_ATTRIBUTE13,
  X_ATTRIBUTE14        => V_ATTRIBUTE14,
  X_ATTRIBUTE15        => V_ATTRIBUTE15,
  X_MSG_APPLICATION    => V_Msg_Application ,
  X_MSG_TYPE           => V_MsgType,
  X_MSG_TOKEN1         => V_MsgToken1,
  X_MSG_TOKEN2         => V_MsgToken2,
  X_MSG_TOKEN3         => V_MsgToken3,
  X_MSG_COUNT          => V_MsgCount,
  X_STATUS			=> V_MsgName1,    /*Collect the out put message into  */
  X_BILLABLE_FLAG      => V_billable_flag,
  p_sys_link_function		=>  'VI'
 );

/*According to the message V_MsgName1 we need Populate the PA Token with proper meaningful sentence*/
		
IF V_MsgName1 = 'PA_EX_QTY_EXIST' then

p_token_value1  :=  'This item requires a valid quantity';

elsif V_MsgName1 = 'PA_PJR_NO_ASSIGNMENT' then

p_token_value1  :=  'No Assigment exists for this Project Resource';

elsif V_MsgName1 = 'PA_CWK_TXN_NOT_ALLOWED' then

p_token_value1  :=  'The project/task transaction controls prohibit contingent worker transactions.';

elsif V_MsgName1 = 'PA_TR_EPE_PROJ_TXN_CTRLS' then

p_token_value1  :=  'This item would violate a project-level transaction control.';

elsif V_MsgName1 = 'PA_TR_EPE_TASK_TXN_CTRLS' then

p_token_value1  :=  'This item would violate a task-level transaction control.';

elsif V_MsgName1 = 'PA_CWK_TC_NOT_ALLOWED' then

p_token_value1  :=  ' You cannot enter contingent worker timecards for this organization.';

elsif V_MsgName1 = 'PA_WP_RES_NOT_DEFINED' then

p_token_value1  :=  ' The resource is not assigned to the task.';

elsif V_MsgName1 = 'EXP_TYPE_INACTIVE' then

if l_pa_exp_date_default = 'INVTRNSDT' then
		p_token_value1  :=  'The expenditure type is not active on the Transaction date.';
	elsif l_pa_exp_date_default = 'INVGLDT' then
		p_token_value1  :=  'The expenditure type is not active on the Transaction GL date.';
	elsif l_pa_exp_date_default = 'INVSYSDT' then
		p_token_value1  :=  'The expenditure type is not active on the Transaction System date.';
	elsif l_pa_exp_date_default = 'POTRNSDT' then
		p_token_value1  :=  'The expenditure type is not active on the Source Document date.';
end if;


elsif V_MsgName1 = 'PA_TR_EPE_NLR_ORG_NOT_ACTIVE' then

if l_pa_exp_date_default = 'INVTRNSDT' then
		p_token_value1  :=  'The Non Labor Resource Organization is not active on the Transaction date.';
	elsif l_pa_exp_date_default = 'INVGLDT' then
		p_token_value1  :=  'The Non Labor Resource Organization is not active on the Transaction GL date.';
	elsif l_pa_exp_date_default = 'INVSYSDT' then
		p_token_value1  :=  'The Non Labor Resource Organization is not active on the Transaction System date.';
	elsif l_pa_exp_date_default = 'POTRNSDT' then
		p_token_value1  :=  'The Non Labor Resource Organization is not active on the Source Document date.';
end if;

elsif V_MsgName1 = 'PA_ER_CANNOT_XFACE_EMP' then

p_token_value1  :=  ' This expense report cannot be interfaced to Oracle Projects because the employee vendor does not have a valid employee ID.';

elsif V_MsgName1 = 'PA_ER_CANNOT_XFACE' then

p_token_value1  :=  'This expense report cannot be interfaced to Oracle Projects because the supplier is not defined as an employee.';

elsif V_MsgName1 = 'PA_INVALID_EXPENDITURE_TYPE' then

p_token_value1  :=  'The Expenditure Type is Invalid';

elsif V_MsgName1 = 'INVALID_ETYPE_SYSLINK' then

p_token_value1  :=  'Invalid expenditure type and expenditure type class combination';

elsif V_MsgName1 = 'ETYPE_SLINK_INACTIVE' then

p_token_value1  :=  'The Expenditure Type and Expenditure Type Class combination is inactive.';

elsif V_MsgName1 = 'PA_PROJECT_NOT_VALID' then

p_token_value1  :=  'The project is not chargeable';

elsif V_MsgName1 = 'PA_EX_TEMPLATE_PROJECT' then

p_token_value1  :=  'Template projects cannot be charged.';

elsif V_MsgName1 = 'PA_NEW_TXNS_NOT_ALLOWED' then

p_token_value1  :=  'The project status does not allow creation of new transactions.';

elsif V_MsgName1 = 'INVALID_PA_DATE' then

if l_pa_exp_date_default = 'INVTRNSDT' then
		p_token_value1  :=  'There is no open or future PA period for the given Transaction Date.';
	elsif l_pa_exp_date_default = 'INVGLDT' then
		p_token_value1  :=  'There is no open or future PA period for the given Transaction GL Date.';
	elsif l_pa_exp_date_default = 'INVSYSDT' then
		p_token_value1  :=  'There is no open or future PA period for the given Transaction System Date.';
	elsif l_pa_exp_date_default = 'POTRNSDT' then
		p_token_value1  :=  'There is no open or future PA period for the given Source Document Date.';
end if;


elsif V_MsgName1 = 'PA_NO_ASSIGNMENT' then

p_token_value1  :=  'No assignment exists with the given information.';

elsif V_MsgName1 = 'NO_ASSIGNMENT' then

p_token_value1  :=  'No assignment.';

elsif V_MsgName1 = 'PA_NO_ASSIGNMENT' then

p_token_value1  :=  'No assignment exists with the given information.';

elsif V_MsgName1 = 'NO_PO_ASSIGNMENT' then

if l_pa_exp_date_default = 'INVTRNSDT' then
		p_token_value1  :=  'No active assignment for entered PO and Transasction date';
	elsif l_pa_exp_date_default = 'INVGLDT' then
		p_token_value1  :=  'No active assignment for entered PO and Transasction GL date';
	elsif l_pa_exp_date_default = 'INVSYSDT' then
		p_token_value1  :=  'No active assignment for entered PO and Transasction System date';
	elsif l_pa_exp_date_default = 'POTRNSDT' then
		p_token_value1  :=  'No active assignment for entered PO and Source Document date';
end if;


elsif V_MsgName1 = 'PA_TRX_CANT_BE_CAP' then

p_token_value1  :=  'The capitalizable flag may not be set to Y when the Retirement Cost Flag for the task is Y.';

elsif V_MsgName1 = 'PA_EXP_ORG_NOT_ACTIVE' then

p_token_value1  :=  'The expenditure organization is not active.';

elsif V_MsgName1 = 'PA_EX_PROJECT_DATE'  then


	if l_pa_exp_date_default = 'INVTRNSDT' then
		p_token_value1  :=  'The  Transaction date is not within the active dates of the project';
	elsif l_pa_exp_date_default = 'INVGLDT' then
		p_token_value1  :=  'The  Transaction GL date is not within the active dates of the project';
	elsif l_pa_exp_date_default = 'INVSYSDT' then
		p_token_value1  :=  'The  Transaction System date is not within the active dates of the project';
	elsif l_pa_exp_date_default = 'POTRNSDT' then
		p_token_value1  :=  'The  Source Document date is not within the active dates of the project';
	end if;

elsif V_MsgName1 = 'PA_EX_PROJECT_CLOSED' then

p_token_value1  :=  'You cannot charge expenditure items to a closed project';

elsif V_MsgName1 = 'PA_EXP_TASK_EFF'  then 

	if l_pa_exp_date_default = 'INVTRNSDT' then
		p_token_value1  :=  'The Transaction date is not within the active dates of the task';
	elsif l_pa_exp_date_default = 'INVGLDT' then
		p_token_value1  :=  'The Transaction GL date is not within the active dates of the task';
	elsif l_pa_exp_date_default = 'INVSYSDT' then
		p_token_value1  :=  'The Transaction System date is not within the active dates of the task';
	elsif l_pa_exp_date_default = 'POTRNSDT' then
		p_token_value1  :=  'The Source Document date is not within the active dates of the task';
	end if;

elsif V_MsgName1 = 'PA_EXP_TASK_STATUS' then
p_token_value1  :=  'The task is not chargeable';

elsif V_MsgName1 = 'PA_EXP_PJ_TC' then

p_token_value1  :=  'A project-level expenditure transaction control has been violated ';

elsif V_MsgName1 = 'PA_EXP_TASK_TC' then

p_token_value1  :=  'A task-level expenditure transaction control has been violated';

elsif V_MsgName1 = 'PA_NO_VALID_ASSIGN' then

p_token_value1  :=  'No valid assignment exists in HR';

elsif V_MsgName1 is NULL then

p_token_value1  :=  ' ';

end if;

/*Just Similar to the above we will send a text message to the AP for GMS validation*/
/*Populate the GMS Token*/

if V_Gms_Message='GMS_AWARD_REQUIRED' then

p_token_value2 := 'An award number is required for this project';

elsif V_Gms_Message='GMS_NOT_FUNDING_AWARD' then

p_token_value2 := 'The entered award does not fund the project and task combination';

elsif V_Gms_Message='GMS_INVALID_AWARD' then

p_token_value2 := 'The entered award number is not a valid award';

elsif V_Gms_Message='GMS_INVALID_EXP_TYPE' then

p_token_value2 := 'The entered expenditure type is not available for this award.';

elsif V_Gms_Message='GMS_NOT_A_SPONSORED_PROJECT' then

p_token_value2 := 'Non-sponsored projects cannot have an associated award number';

elsif V_Gms_Message='GMS_EXP_ITEM_DATE_INVALID'  then

/* Whenever there are date validations, make sure to use the correct sentence as required  */

	IF l_pa_exp_date_default = 'INVTRNSDT' then
		p_token_value2 := 'The entered Transasction date is not in the active date range for this award';
	elsif l_pa_exp_date_default = 'INVGLDT' then
		p_token_value2 := 'The entered Transasction GL date is not in the active date range for this award';
	elsif l_pa_exp_date_default = 'INVSYSDT' then
		p_token_value2 := 'The entered Transasction System date is not in the active date range for this award';
	elsif  l_pa_exp_date_default = 'POTRNSDT' then
		p_token_value2 := 'The entered Soruce Document date is not in the active date range for this award';
	END IF;

elsif V_Gms_Message='GMS_EXP_ITEM_DT_BEFORE_AWD_ST' then

	IF l_pa_exp_date_default = 'INVTRNSDT' then
		p_token_value2 := 'Transaction date is less than award start date';
	elsif l_pa_exp_date_default = 'INVGLDT' then
		p_token_value2 := 'Transaction GL date is less than award start date';
	elsif l_pa_exp_date_default = 'INVSYSDT' then
		p_token_value2 := 'Transaction System date is less than award start date';
	elsif  l_pa_exp_date_default = 'POTRNSDT' then
		p_token_value2 := 'Source Document date is less than award start date';
	END IF;

elsif V_Gms_Message='GMS_EXP_ITEM_DT_AFTER_AWD_END' then

	IF l_pa_exp_date_default = 'INVTRNSDT' then
		p_token_value2 := 'Transaction date does not fall between award start date and award end date';
	elsif l_pa_exp_date_default = 'INVGLDT' then
		p_token_value2 := 'Transaction GL date does not fall between award start date and award end date';
	elsif l_pa_exp_date_default = 'INVSYSDT' then
		p_token_value2 := 'Transaction System Date does not fall between award start date and award end date';
	elsif  l_pa_exp_date_default = 'POTRNSDT' then
		p_token_value2 := 'Source Document date does not fall between award start date and award end date';
	END IF;

elsif V_Gms_Message='GMS_AWARD_IS_CLOSED' then  /* Bug 14580572: Removed Space */

p_token_value2 := 'The close date for this award has passed.  Expenses cannot be charged to an award after its close date.'; /*  Added the changes for bug 16193073 */ /*Modified for bug 16401667 */
elsif V_Gms_Message='GMS_AWARD_NOT_ACTIVE' then /* Bug 14580572: Removed Space */

p_token_value2 := 'This award is closed or on hold. Expenses cannot be charged to an award if it has a status of closed or on hold.';/*  Added the changes for bug 16193073 */ /*Modified for bug#16401667 */

elsif V_Gms_Message='GMS_UNEXPECTED_ERROR' then

p_token_value2 := 'An unexpected program error has occurred';

elsif V_Gms_Message is NULL then  /*If the award is fine, then populate the token with a blank message such that nothing is displayed in its place */

p_token_value2 := ' ';

end if;
	 
   CASE l_pa_exp_date_default
         WHEN 'INVTRNSDT' THEN

		/* Validate the Transaction Date and if not valid then collect the error message into p_pa_message */
		Validate_EI_Date(V_Gms_Message, V_MsgName1,p_transaction_date,l_po_exp_item_date,l_pa_exp_date_default,l_return_date,p_pa_message_name,p_is_date_valid);


         WHEN 'INVGLDT' THEN

		Validate_EI_Date(V_Gms_Message, V_MsgName1,p_gl_date,l_po_exp_item_date,l_pa_exp_date_default,l_return_date,p_pa_message_name,p_is_date_valid);


         WHEN 'INVSYSDT' THEN

		Validate_EI_Date(V_Gms_Message, V_MsgName1,sysdate,l_po_exp_item_date,l_pa_exp_date_default,l_return_date,p_pa_message_name,p_is_date_valid);


            WHEN 'POTRNSDT' THEN
              IF p_po_exp_item_date is not NULL then
                 l_return_date := p_po_exp_item_date  ;

		/* Validate the Source Document Date and if not valid then return the generic error message  */
		/*  Added this validation for bug 16193073 */
		
		Validate_EI_Date(V_Gms_Message, V_MsgName1,p_po_exp_item_date,l_po_exp_item_date,l_pa_exp_date_default,l_return_date,p_pa_message_name,p_is_date_valid);

		IF p_pa_message_name IS NULL THEN  		/*  Added this IF for bug 16193073 */

		l_pa_date := pa_utils2.get_pa_date(	l_return_date, SYSDATE, pa_moac_utils.get_current_org_id); 
		
			IF l_pa_date is not NULL THEN
			p_pa_message_name := NULL;
			p_is_date_valid := 'Y';
			ELSE
			p_pa_message_name := 'PA_PO_MATCH_DER_DATE_INVALID';
			p_token_value1 := ' ';/* 14529067 */
			p_token_value2 := ' ';/* 14529067 */
			g_po_match_date := p_po_exp_item_date;
			p_is_date_valid := 'N';
			
			END IF;   

		END IF; 		/*  16193073 */

              ELSE

	                IF l_pa_debug_flag = 'Y' THEN
		           IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
			      FND_LOG.string(FND_LOG.LEVEL_STATEMENT,'PA_AP_INTEGRATION', 'PO expenditure item date is NULL') ;
	                   END IF ;
	                END IF ;

			IF p_po_distribution_id is not NULL then

			open c_po_date ;
			fetch c_po_date into l_return_date ;
			close c_po_date ;

		/* Validate the Source Document Date and if not valid then return the generic error message  */

		/*  Added this validation for bug 16193073 */

		Validate_EI_Date(V_Gms_Message, V_MsgName1,l_po_exp_item_date,p_po_exp_item_date,l_pa_exp_date_default,l_return_date,p_pa_message_name,p_is_date_valid);

		l_pa_date := pa_utils2.get_pa_date(	l_return_date, SYSDATE, pa_moac_utils.get_current_org_id); 

		IF p_pa_message_name IS NULL THEN  		/*  Added this IF for bug 16193073 */

			IF l_pa_date is not NULL THEN
			p_pa_message_name := NULL;
			p_is_date_valid := 'Y';
			ELSE
			p_pa_message_name := 'PA_PO_MATCH_DER_DATE_INVALID';
			p_token_value1 := ' ';/* 14529067 */
			p_token_value2 := ' ';/* 14529067 */
			g_po_match_date := p_po_exp_item_date;

			/*  Added this  for bug 16193073 */
			IF (p_po_exp_item_date is null) Then
				g_po_match_date := l_po_exp_item_date;
			END IF;
			/*  End this validation for bug 16193073 */
			p_is_date_valid := 'N';

			END IF;

		END IF; 		/*  16193073 */


			IF l_pa_debug_flag = 'Y' THEN
			IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
                         FND_LOG.string(FND_LOG.LEVEL_STATEMENT,'PA_AP_INTEGRATION','Determining the date based on the PO distribution IDL') ;
			END IF ;
	                END IF ;
		
		ELSE

			-- In the case of unmatched invoice the Invoice date must get @ defaulted as the EI date.
			l_return_date := p_transaction_date ;

			END IF ;

	         END IF ;
	
	/* Added for bug 15934260 */
        if 
        (
        nvl(V_MsgName1,' ') = 'PA_EXP_ORG_NOT_ACTIVE'
        or nvl(V_MsgName1,' ') = 'PA_NEW_TXNS_NOT_ALLOWED'
        or nvl(V_MsgName1,' ') = 'PA_PROJECT_NOT_VALID'
        or nvl(V_MsgName1,' ') = 'PA_INVALID_EXPENDITURE_TYPE'
        or nvl(V_MsgName1,' ') = 'PA_EX_TEMPLATE_PROJECT'
        or nvl(V_MsgName1,' ') = 'PA_EX_PROJECT_CLOSED'
        or nvl(V_MsgName1,' ') = 'PA_EX_QTY_EXIST'
        or nvl(V_Gms_Message,' ') = 'GMS_AWARD_REQUIRED'
        or nvl(V_Gms_Message,' ') = 'GMS_NOT_FUNDING_AWARD'
        or nvl(V_Gms_Message,' ') = 'GMS_AWARD_IS_CLOSED'
        or nvl(V_Gms_Message,' ') = 'GMS_UNEXPECTED_ERROR'
        or nvl(V_Gms_Message,' ') = 'GMS_NOT_A_SPONSORED_PROJECT'
        or nvl(V_Gms_Message,' ') = 'GMS_INVALID_EXP_TYPE'
        or nvl(V_Gms_Message,' ') = 'GMS_INVALID_AWARD'
	or nvl(V_Gms_Message,' ') = 'GMS_AWARD_NOT_ACTIVE'
        )
        then
        
        p_pa_message_name := 'PA_PO_MATCH_ERR';
        p_exp_item_date := l_return_date;
        g_po_match_date := l_return_date;
        p_is_date_valid := 'N';
        
        end if;
        /* Added for bug 15934260 */

         ELSE
                l_return_date := NULL ;

   END CASE;

    IF l_pa_debug_flag = 'Y' THEN
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
         FND_LOG.string(FND_LOG.LEVEL_STATEMENT,'PA_AP_INTEGRATION', 'Date returned :'||to_char(l_return_date, 'DD-MON-YYYY')) ;
      END IF ;
   END IF ;

   /* Added for bug 16312792 */
   IF nvl(l_DESTINATION_TYPE_CODE,'X') <> 'EXPENSE' THEN   /*Bug 17440081: Changed '= INVENTORY' to '<> EXPENSE' */
      IF V_MsgName1 = 'EXP_TYPE_INACTIVE' OR
         V_MsgName1 = 'PA_INVALID_EXPENDITURE_TYPE' OR
         V_MsgName1 = 'INVALID_ETYPE_SYSLINK' OR
         V_MsgName1 = 'ETYPE_SLINK_INACTIVE' OR
         V_MsgName1 = 'INVALID_PA_DATE' OR
         V_MsgName1 = 'PA_EXP_ORG_NOT_ACTIVE' OR
         V_Gms_Message='GMS_INVALID_EXP_TYPE' OR
         V_Gms_Message='GMS_EXP_ITEM_DATE_INVALID' THEN
         
              V_MsgName1 := NULL;
              V_Gms_Message := NULL;
              p_token_value1 := NULL;
              p_token_value2 := NULL;
		          p_is_date_valid := 'Y';
		          p_pa_message_name	:= NULL;
         
      END IF;
   END IF;
   /* Added for bug 16312792 */
   
    p_exp_item_date := l_return_date ;

/*  Added the changes for bug 16193073 */

IF (trim(p_token_value1) is not null ) THEN
p_token_value1  := '1.'||p_token_value1;
END IF;
IF (trim(p_token_value1) is not null  AND trim(p_token_value2) is not null ) THEN
p_token_value2  := '2.'||p_token_value2;
END IF;
IF (trim(p_token_value1) is null AND trim(p_token_value2) is not null ) THEN
 p_token_value2  := '1.'||p_token_value2;
END IF;

/*  End for bug 16193073 */
EXCEPTION

   WHEN OTHERS THEN

     RAISE;

END Get_Po_Match_Si_Exp_Item_Date;


PROCEDURE Validate_Ei_Date(
			gms_message	IN  VARCHAR2 DEFAULT NULL,
			pa_message		IN  VARCHAR2 DEFAULT NULL  ,
			profile_date		IN   DATE DEFAULT NULL  ,
			source_doc_date	IN   DATE DEFAULT NULL  ,
			profile			IN   VARCHAR2 DEFAULT NULL  ,
			x_exp_item_date			OUT NOCOPY DATE,
			x_pa_message_name		OUT NOCOPY VARCHAR2,
			x_is_date_valid			OUT NOCOPY VARCHAR2
)
IS

l_pa_date	DATE;

BEGIN


if nvl(gms_message,' ') = ' ' and nvl(pa_message,' ') = ' ' then

/* both award and project are ok */

x_exp_item_date  := profile_date ;
x_is_date_valid := 'Y';
x_pa_message_name := NULL;

elsif 
(
nvl(pa_message,' ') = 'PA_EXP_ORG_NOT_ACTIVE'   		/* changed gms_message to pa_message for bug 16193073 */
or nvl(pa_message,' ') = 'PA_NEW_TXNS_NOT_ALLOWED'    /* changed gms_message to pa_message for bug 16193073 */
or nvl(pa_message,' ') = 'PA_PROJECT_NOT_VALID'			/* changed gms_message to pa_message for bug 16193073 */
or nvl(pa_message,' ') = 'PA_INVALID_EXPENDITURE_TYPE'	/* changed gms_message to pa_message for bug 16193073 */
or nvl(pa_message,' ') = 'PA_EX_TEMPLATE_PROJECT'		/* changed gms_message to pa_message for bug 16193073 */
or nvl(pa_message,' ') = 'PA_EX_PROJECT_CLOSED'		/* changed gms_message to pa_message for bug 16193073 */
or nvl(pa_message,' ') = 'PA_EX_QTY_EXIST'				/* changed gms_message to pa_message for bug 16193073 */
or nvl(gms_message,' ') = 'GMS_AWARD_REQUIRED'			
or nvl(gms_message,' ') = 'GMS_NOT_FUNDING_AWARD'		
or nvl(gms_message,' ') = 'GMS_AWARD_IS_CLOSED'
or nvl(gms_message,' ') = 'GMS_UNEXPECTED_ERROR'
or nvl(gms_message,' ') = 'GMS_NOT_A_SPONSORED_PROJECT'
or nvl(gms_message,' ') = 'GMS_INVALID_EXP_TYPE'
or nvl(gms_message,' ') = 'GMS_INVALID_AWARD'
or nvl(gms_message,' ') = 'GMS_AWARD_NOT_ACTIVE'
)
then

x_pa_message_name := 'PA_PO_MATCH_ERR';
x_exp_item_date := source_doc_date;
g_po_match_date := source_doc_date;
x_is_date_valid := 'N';

else 

/*either award or project is not ok or both award and project are not ok*/

l_pa_date := pa_utils2.get_pa_date(	source_doc_date, SYSDATE, pa_moac_utils.get_current_org_id); 
		     
			if l_pa_date is not null then
				
				if profile = 'INVGLDT' then
				x_pa_message_name := 'PA_PO_MATCH_GL_DATE_INVALID';
				elsif profile = 'INVTRNSDT' then
				x_pa_message_name := 'PA_PO_MATCH_TXN_DATE_INVALID';
				elsif profile = 'INVSYSDT' then
				x_pa_message_name := 'PA_PO_MATCH_TXNSYS_INVALID';
				end if;

				


			else

				if profile = 'INVGLDT' then
				x_pa_message_name := 'PA_PO_MATCH_GL_DATE_ERR';
				elsif profile = 'INVTRNSDT' then
				x_pa_message_name := 'PA_PO_MATCH_TXN_DATE_ERR';
				elsif profile = 'INVSYSDT' then
				x_pa_message_name := 'PA_PO_MATCH_TXNSYS_ERR';
				end if;


			end if;

				x_exp_item_date := source_doc_date;
				g_po_match_date := source_doc_date;
				x_is_date_valid := 'N';


end if;

exception

when others then 

raise;

END Validate_Ei_Date;

/*13706985  - End*/

END pa_ap_integration;
/
commit;
--show errors;
exit;

