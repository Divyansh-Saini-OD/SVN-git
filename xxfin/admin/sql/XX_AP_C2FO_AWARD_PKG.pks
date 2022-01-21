SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AP_C2FO_AWARD_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE


create or replace PACKAGE XX_AP_C2FO_AWARD_PKG AS
/****************************************************************************************************************
*   Name:        XX_AP_C2FO_AWARD_PKG
*   PURPOSE:     This package was created for the C2O Extract Process
*   @author      Joshua Wilson - C2FO
*   @version     12.1.3.1.0
*   @comments
*
*   REVISIONS:
*   Ver          Date         	Author            			Company           Description
*   ---------    ----------   	---------------   			----------        -----------------------------------
*   12.1.3.1.0   5/01/15      	Joshua Wilson     			C2FO              1. Created this package.
*   12.1.3.1.0   8/31/2018		Nageswara Rao Chennupati	C2FO              1. Updated the package as per the new requirements.
*   1.0          9/2/2018       Antonio Morales             OD                OD Initial Customized Version
*   1.1          5/17/2018      Arun DSouza                 OD                commented award_file_batch_name
*****************************************************************************************************************/

 /***********************************************/
 /* Global Constants                            */
 /***********************************************/
  C_UPLOAD_DIRECTORY    VARCHAR2(2000)  := 'XXFIN_C2FO_INBOUND';
  C_ARCHIVE_DIRECTORY   VARCHAR2(2000)  := 'XXFIN_C2FO_INBOUND_ARC';

 -- c_award_file_batch_name VARCHAR2(50) := 'XX_AP_C2FO'||'-'||TO_CHAR(SYSDATE,'RRRRMMDDHH24MISS');
  G_LIABILITY_CCID        NUMBER; --    := NVL(fnd_profile.value('XX_AP_C2FO_LIABILITY_CCID'), '12854');
  G_US_EXPENSE_CCID          NUMBER; --    := NVL(fnd_profile.value('XX_AP_C2FO_EXPENSE_CCID'), '17347');
  G_CA_EXPENSE_CCID          NUMBER;
  C_MEMO_TERM_ID          NUMBER; --    := NVL(fnd_profile.value('XX_AP_C2FO_MEMO_TERM_ID'), '10001');

 /***************************************************************/
 /* PROCEDURE PROCESS_AWARD                                     */
 /* Procedure to process award data                             */
 /***************************************************************/

    PROCEDURE PROCESS_AWARD(errbuf        OUT VARCHAR2,
                            retcode       OUT NUMBER,
                            p_file_prefix  IN VARCHAR2
                           );

END XX_AP_C2FO_AWARD_PKG;
/

SHOW ERRORS