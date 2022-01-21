CREATE OR REPLACE PACKAGE APPS.XX_AR_CONS_BILL_PKG AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_CONS_BILL_PKG                                                                |
-- |  Description:  This package is used to process the Consolidated Bill Reprints and Special  |
-- |                Handling.                                                                   |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version   Date         Author             Remarks                                          |
-- | ========= ===========  =============      ===============================================  |
-- | 1.0       22-Jul-2007  B.Looman           Initial version                                  |
-- | 1.1       21-Aug-2007  B.Looman           Updated special handling data templates to have  |
-- |                                           the "_SPEC" suffix also                          |
-- | 1.2       28-Aug-2007  B.Looman           Add the EXTENSION_ID for special handling        |
-- | 1.3       07-Jun-2008  B.Seshadri         Add request id                                   |
--.| 1.4       02-DEC-2008  Sambasiva Reddy    Changed for the Defect # 12223                   |
-- | 1.5       15-DEC-2009  Gokila Tamilselvam Modified reprint_bill_document Procedure for R1.2|
-- |                                           Defect# 1210 CR# 466.                            |
-- +============================================================================================+


GC_APPL_SHORT_NAME          CONSTANT VARCHAR2(50)     := 'XXFIN';

GC_XDO_TEMPLATE_FORMAT      CONSTANT VARCHAR2(30)     := 'PDF';


-- +============================================================================================+
-- |  Name: REPRINT_BILL_DOCUMENT                                                               |
-- |  Description: This procedure is can be called from a concurrent program to build the XML   |
-- |               data for the given customer bills, and process them using the XML Publisher  |
-- |               templates and data definitions.                                              |
-- |                                                                                            |
-- |  Parameters:  p_cust_account_id  - Customer Account Id                                     |
-- |               p_cons_bill_num_from  - Consolidated Bill Number From                        |
-- |               p_cons_bill_num_to - Consolidated Bill Number To                             |
-- |               p_mbs_document_id - MBS Document Id                                          |
-- |                                                                                            |
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
PROCEDURE reprint_bill_document
( x_error_buffer            OUT    VARCHAR2,
  x_return_code             OUT    NUMBER,
  p_infocopy_flag           IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_search_by               IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_cust_account_id         IN     NUMBER,
  p_virtual_bill_flag       IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_date_from               IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_date_to                 IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_dummy                   IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_dummy1                  IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  --p_cons_bill_num_from      IN     NUMBER,   -- Commented for R1.2 Defect# 1210 CR# 466
  p_cons_bill_num_from      IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  --p_cons_bill_num_to        IN     NUMBER,   -- Commented for R1.2 Defect# 1210 CR# 466
  p_cons_bill_num_to        IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_virtual_bill_num        IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_multiple_bill           IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_cust_doc_id             IN     NUMBER,     --Added for R1.2 Defect# 1210 CR# 466
  p_mbs_document_id         IN     NUMBER,
  p_override_doc_flag       IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_email_option            IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_dummy2                  IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_email_address           IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_special_handling        IN     VARCHAR2   DEFAULT 'N',
  p_mbs_extension_id        IN     NUMBER     DEFAULT NULL,
  p_request_id              IN     NUMBER     DEFAULT NULL,
  p_origin                  IN     VARCHAR2   DEFAULT NULL,
  --Start for the Defect # 12223
  p_doc_detail_cp           IN     VARCHAR2   DEFAULT NULL,
  p_doc_detail              IN     VARCHAR2   DEFAULT NULL,
  p_as_of_date1             IN     VARCHAR2   DEFAULT NULL,
  p_printer                 IN     VARCHAR2   DEFAULT NULL
  --End for the Defect # 12223
);


-- +============================================================================================+
-- |  Name: PRINT_SPECIAL_HANDLING_DOCS                                                         |
-- |  Description: This procedure is can be called from a concurrent program to select the      |
-- |               consolidated bills that flagged as special handling and qualify based on     |
-- |               the frequency.  It then uses XML Publisher to process the data definition    |
-- |               and Template and send a generated bill document to the bill central printer. |
-- |                                                                                            |
-- |  Parameters:  p_as_of_date - send unprocessed consolidated bills qualified up to this date |
-- |                                (should always default to sysdate)                          |
-- |                                                                                            |
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
PROCEDURE print_special_handling_docs
( x_error_buffer            OUT    VARCHAR2,
  x_return_code             OUT    NUMBER,
  p_as_of_date              IN     VARCHAR2   DEFAULT TO_CHAR(TRUNC(SYSDATE),'YYYY/MM/DD HH24:MI:SS'),
  p_optional_printer        IN     VARCHAR2   DEFAULT NULL  --Added for Defect # 12223
);

-- Added the below procedure REPRINT_CBI_DOC_WRAP as part of R1.2 Defect# 1210 CR# 466.
-- +===================================================================+
-- | Name : REPRINT_CBI_DOC_WRAP                                       |
-- | Description : 1. This is used to submit the Consolidated reprint  |
-- |                 program for each separate CBI bills in multiple   |
-- |                 CBI number parameter if customer number is not    |
-- |                 passed.                                           |
-- |               2. If customer number is passed then only one       |
-- |                 CBI reprint program will be submitted even in case|
-- |                 of multiple CBI number parameter is passed.       |
-- |                                                                   |
-- | Program :OD: AR Reprint Summary Bills - Main                      |
-- |                                                                   |
-- | Returns  : x_error_buff,x_ret_code                                |
-- +===================================================================+

 PROCEDURE REPRINT_CBI_DOC_WRAP ( x_error_buffer            OUT    VARCHAR2
                                 ,x_return_code             OUT    NUMBER
                                 ,p_infocopy_flag           IN     VARCHAR2
                                 ,p_search_by               IN     VARCHAR2
                                 ,p_cust_account_id         IN     NUMBER
                                 ,p_virtual_bill_flag       IN     VARCHAR2
                                 ,p_date_from               IN     VARCHAR2
                                 ,p_date_to                 IN     VARCHAR2
                                 ,p_dummy                   IN     VARCHAR2
                                 ,p_dummy1                  IN     VARCHAR2
                                 ,p_cons_bill_num_from      IN     VARCHAR2
                                 ,p_cons_bill_num_to        IN     VARCHAR2
                                 ,p_virtual_bill_num        IN     VARCHAR2
                                 ,p_multiple_bill           IN     VARCHAR2
                                 ,p_cust_doc_id             IN     NUMBER
                                 ,p_mbs_document_id         IN     NUMBER
                                 ,p_override_doc_flag       IN     VARCHAR2
                                 ,p_email_option            IN     VARCHAR2
                                 ,p_dummy2                  IN     VARCHAR2
                                 ,p_email_address           IN     VARCHAR2
                                 ,p_special_handling        IN     VARCHAR2   DEFAULT 'N'
                                 ,p_mbs_extension_id        IN     NUMBER     DEFAULT NULL
                                 ,p_request_id              IN     NUMBER     DEFAULT NULL
                                 ,p_origin                  IN     VARCHAR2   DEFAULT NULL
                                 ,p_doc_detail_cp           IN     VARCHAR2   DEFAULT NULL
                                 ,p_doc_detail              IN     VARCHAR2   DEFAULT NULL
                                 ,p_as_of_date1             IN     VARCHAR2   DEFAULT NULL
                                 ,p_printer                 IN     VARCHAR2   DEFAULT NULL
                                );

END;
/