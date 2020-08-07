SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_C2FO_INT_EBS_AP_PAY_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

/********************************************************************************************************************
*   Name:        XX_AP_C2FO_INT_EBS_AP_PAY_PKG
*   PURPOSE:     
*   REVISIONS:
*   Ver          Date             Author                        Company           Description
*   ---------    ----------       ---------------               ----------        -----------------------------------
*   1.0          9/2/2018          Antonio Morales              OD                OD Initial Customized Version
*********************************************************************************************************************/
 
CREATE OR REPLACE PACKAGE XX_AP_C2FO_INT_EBS_AP_PAY_PKG AS

	--
	--+=====================================================================================================+
	--|                       			C2FO                                              					|
	--|                       				                                                  				|
	--+=====================================================================================================+
	--| $Header$                                                                        					|
	--|                                                                                 					|
	--| FILE NAME                                                                        					|
	--| 		xxc2fo_int_ebs_ap_pay_pkg.pkg                                  								|
	--|                                                                                 					|
	--| DESCRIPTION                                                                     					|
	--| 		Script for creating package "apps.xx_ap_c2fo_int_ebs_ap_pay_pkg" specification.                	|
	--|                                                                                 					|
	--| Notes:                                                                          					|
	--| 		Created By: Nageswara Rao Chennupati                                      					|
	--|                                                                                 					|
	--| HISTORY                                                                         					|
	--|                                                                                 					|
	--|	Version		Author 						Date			CR#		Comments                    		|
	--| --------	------------------------	-----------		-----	--------------------------- 		|
	--| 1.0       	Nageswara Rao Chennupati	14-AUG-2018   		 	No previous version   				|
  --| 2.0         Antonio Morales           09-SEP-2018         OD Initial Customized Version
	--|                                                                                 					|
	--|                                                                                 					|
	--+=====================================================================================================+
	--
	--+=====================================================================================================+
	--  Declaration And Initialization Of GLOBAL Variables.
	--+=====================================================================================================+

	gc_package_name   	CONSTANT 	VARCHAR2(30) 	:= 'xx_ap_c2fo_int_ebs_ap_pay_pkg';

	--+=====================================================================================================+
	--  Purpose -- To determine Early due date as per the payment terms.
	--+=====================================================================================================+

	FUNCTION pay_term_early_due_date(p_org_id IN NUMBER, p_invoice_id IN NUMBER) RETURN VARCHAR2;	

	--+=====================================================================================================+
	--  Purpose -- To determine the invoice amount after available discount amount
	--+=====================================================================================================+

	FUNCTION amt_or_amt_netvat_after_disc(p_org_id IN NUMBER, p_invoice_id IN NUMBER) RETURN NUMBER;

	--+=====================================================================================================+
	--  Purpose -- To determine the invoice discount amount.
	--+=====================================================================================================+

	FUNCTION amount_grossvat_after_disc(p_org_id IN NUMBER, p_invoice_id IN NUMBER) RETURN NUMBER;		

	--+=====================================================================================================+
	--  Purpose -- To determine the amount gross vat after discount amount.
	--+=====================================================================================================+

	FUNCTION ebs_cash_discount_amt(p_org_id IN NUMBER, p_invoice_id IN NUMBER) RETURN NUMBER;	

	--+=====================================================================================================+
	--  Purpose -- To determine the amount gross vat after discount amount.
	--+=====================================================================================================+

	FUNCTION local_currency_org_inv_amount(p_org_id IN NUMBER, p_invoice_id IN NUMBER) RETURN NUMBER;

	--+=====================================================================================================+
	--  Purpose -- To determine paid invoice id for the other than the invoice type 'STANDARD'.
	--+=====================================================================================================+

	FUNCTION paid_invoice_id(p_org_id IN NUMBER, p_invoice_id IN NUMBER,p_transaction_type IN NUMBER) RETURN NUMBER;    

END XX_AP_C2FO_INT_EBS_AP_PAY_PKG; 
/

SHOW ERRORS
