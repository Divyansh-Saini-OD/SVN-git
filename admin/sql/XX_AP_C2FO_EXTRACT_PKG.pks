SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_C2FO_EXTRACT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
 
----------------***************************************************---------------------
----------------***************************************************---------------------
 /***************************************************************/
 /* PACKAGE SPECIFICATION                                       */
 /* DATE: 29-AUG-2018                                           */
 /***************************************************************/
 

create or replace PACKAGE XX_AP_C2FO_EXTRACT_PKG AS
/****************************************************************************************************************
*   Name:        XXC2FO_EXTRACT_PKG
*   PURPOSE:     This package was created for the C2O Extract Process
*   @author      Joshua Wilson - C2FO
*   @version     12.1.3.1.0
*   @comments
*
*   REVISIONS:
*   Ver          Date         Author                    Company           Description
*   ---------    ----------   ---------------           ----------        -----------------------------------
*   12.1.3.1.0   5/01/15      Joshua Wilson             C2FO              1. Created this package.
*   12.1.3.1.0   8/29/2018    Nageswara Rao Chennupati  C2FO              2. Modified the package as per the new requirements.
*   1.0          9/2/2018     Antonio Morales           OD                OD Initial Customized Version          |
*   1.1          5/13/2018    Arun DSouza               OD                Funding Partner Remit Bank Extract     |
*****************************************************************************************************************/

 /***********************************************/
 /* Global Constants                            */
 /***********************************************/
  C_DIRECTORY   VARCHAR2(100) := 'XXFIN_C2FO_OUTBOUND';

  /***************************************************************/
 /* PROCEDURE GENERATE_EXTRACT                                   */
 /* Procedure to extract all files                               */
 /***************************************************************/
    PROCEDURE GENERATE_EXTRACT(
                          errbuf             OUT  VARCHAR2,
                          retcode            OUT  NUMBER,
                          p_procdate          IN  VARCHAR2,
                          p_file_prefix       IN  VARCHAR2,
                          p_operating_unit    IN  NUMBER,
                          p_supp_num_from     IN  VARCHAR2,
                          p_supp_num_to       IN  VARCHAR2,
                          p_invoice_num_from  IN  VARCHAR2,
                          p_invoice_num_to    IN  VARCHAR2,
                          p_invoice_date_from IN  VARCHAR2,
                          p_invoice_date_to   IN  VARCHAR2,
                          p_pay_due_date_from IN  VARCHAR2,
                          p_pay_due_date_to   IN  VARCHAR2,
                          p_po_data_extract   IN  VARCHAR2,
                          p_po_date_from      IN  VARCHAR2,
                          p_po_date_to        IN  VARCHAR2
                          );

 /***************************************************************/
 /* PROCEDURE INVOICE_EXTRACT                                   */
 /* Procedure to extract invoice data                           */
 /***************************************************************/
    PROCEDURE INVOICE_EXTRACT(
                          errbuf            OUT   VARCHAR2,
                          retcode           OUT   NUMBER
                                    );

 /***********************************************/
 /* PROCEDURE ORGANIZATION_EXTRACT              */
 /* Procedure to extract organization data      */
 /***********************************************/
    PROCEDURE ORGANIZATION_EXTRACT(
                          errbuf            OUT   VARCHAR2,
                          retcode           OUT   NUMBER
                                    );

 /***********************************************/
 /* PROCEDURE USER_EXTRACT                      */
 /* Procedure to extract user data              */
 /***********************************************/
    PROCEDURE USER_EXTRACT(
                          errbuf            OUT   VARCHAR2,
                          retcode           OUT   NUMBER
                                    );

 /***********************************************/
 /* PROCEDURE PO_EXTRACT                        */
 /* Procedure to extract user data              */
 /***********************************************/
    PROCEDURE PO_EXTRACT(
                          errbuf            OUT   VARCHAR2,
                          retcode           OUT   NUMBER
                                    );

/***********************************************/
 /* PROCEDURE REMIT BANK EXTRACT              */
 /* Procedure to extract C2FO Remit to Supplier and Original Supplier Bank Account Info for Funding Partner Award Invoices  */
 /***********************************************/
    PROCEDURE REMIT_BANK_EXTRACT(
                          errbuf            OUT   VARCHAR2,
                          retcode           OUT   NUMBER
                                    );



END  XX_AP_C2FO_EXTRACT_PKG;
/
SHOW ERRORS