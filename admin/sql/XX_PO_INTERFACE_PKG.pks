create or replace 
PACKAGE XX_PO_INTERFACE_PKG AUTHID CURRENT_USER AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Technologies                                            |
-- +================================================================================+
-- | Name        :  XX_PO_INTERFACE_PKG.pks                                         |
-- | Description :  The standard package PO_INTERFACE_S.CREATE_DOCUMENT is copied   |
-- |                to XX_PO_INTERFACE_PKG.CREATE_DOCUMENT,in order to insert the   |
-- |                attribute6,attribute7,attribute_category columns of             |
-- |                PO_HEADERS_INTERFACE table into PO_HEADERS_ALL table as the std |
-- |                package does not take care of inserting the attribute columns.  |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Rice ID   Version   Date        Author           Remarks            	          |
-- |=======   =======   ==========  =============    ===============================|
-- |								                                                                |
-- |E0216     V1.0     10-Apr-2007  SANDEEP GORLA    First Version                  |
-- |          V2.0     26-Apr-2014  Avinash          Defect 28388-Took the R12      |
-- |						     Version and customized                                         |
-- |          V3.0     20-May-2015  Madhu Bolli      Defect#34471, Punchout patch Retrofit|
-- |                                 Updating the version 120.0.12010000.5 changes  |
-- |                                 of package PO_INTERFACE_S.pks               	  |
-- |          V4.0     08-04-2016   Radhika Patnala   Retrofit for R12.2.5 updating the version 
-- |                                                  120.2.12020000.5 Changes of Package PO_INTERFACE_S.pks |
-- |          V5.0     20-Oct-2016   Madhu Bolli   Retrofit for R12.2.5 patch#23318272 updating the version 
-- |                                                  120.2.12020000.6 Changes of Package PO_INTERFACE_S.pks |
-- |                                                                                |
-- |                                                                                |
-- +================================================================================+
/* $Header: POXBWP1S.pls 120.2.12020000.6 2015/07/02 00:06:17 pla ship $
**              (c) Copyright O 2014,2014 Oracle and/or its affiliates.
**                       All Rights Reserved
** ============================================================================
**
**   NAME
**      POXBWP1S.pls - AutoCreate PO package header
**
**   DESCRIPTION
**      This package contains all the functions to create Purchase Orders, 
**      Releases and RFQ's from data stored in the PO_HEADERS_INTERFACE and 
**      PO_LINES_INTERFACE tables
**
**   USAGE
**      To install:
**          start POXBWP1S.pls <un_po> <pw_po> <un_mfg> <pw_mfg>
**
**   HISTORY
**      05/25/95        V Sanjeevan     Created
**      12/14/01        Sarvesh Tiwari  Bug 2082757: added spec for new 
**                                      function source_blanket_line      
** ============================================================================
*/
--REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=pls \
--REM dbdrv: checkfile(115.12=120.0):~PROD:~PATH:~FILE
-- SET VERIFY OFF
--WHENEVER OSERROR EXIT FAILURE ROLLBACK;
--WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

-- drop package po_interface_s;
/* $Header: POXBWP1S.pls 120.2.12020000.6 2015/07/02 00:06:17 pla ship $*/

--Public Variables
--Used by create_documents procedure to set the return status 
--when duplicate document number error is returned
G_RET_STS_DUP_DOC_NUM CONSTANT VARCHAR2(1) := 'D'; --<Shared Proc FPJ>

/****************************************************************************
  --<SOURCING TO PO FPH>
  Name: CREATE_DOCUMENTS_WRAPPER
  DESC: This procedure is modified to add two new parameters.  
  ARGS: x_document_number  OUT    varchar2 returns the PO/Blanket number
					   when for sourcing, null for 
					   existing autocreate.
        x_errorcode	   OUT    number   1 success
					   2 manual document number notunique 
					   3 any other error.
   --<CONTERMS FPJ START>
        p_sourcing_k_doc_type   IN   VARCHAR2 - The document type that Sourcing
                             has seeded in Contracts.
                             Deafault null
        p_conterms_exist_flag   IN    VARCHAR2 - Whether the sourcing document 
                              has contract template attached.
                              Deafult - N
   --<CONTERMS FPJ END>
   --<DBI FPJ>
	p_document_creation_method  IN  VARCHAR2 - Stores the method by which
				    the document has been created.
 *****************************************************************************/
 procedure create_documents(x_batch_id 		IN     number,
			    x_document_id 	IN OUT NOCOPY number,
			    x_number_lines 	IN OUT NOCOPY number,
			    x_document_number 	IN OUT NOCOPY varchar2,
			    x_errorcode		OUT NOCOPY    number
               ,p_sourcing_k_doc_type  IN VARCHAR2 DEFAULT NULL--<CONTERMS FPJ>
               ,p_conterms_exist_flag  IN VARCHAR2 DEFAULT 'N' --<CONTERMS FPJ>
	       ,p_document_creation_method IN VARCHAR2 DEFAULT NULL --<DBI FPJ>
                  ,p_orig_org_id         IN   NUMBER DEFAULT NULL    -- <R12 MOAC>
				  ,p_group_shipments     IN   VARCHAR2  DEFAULT NULL --<Bug 14608120, Autocreate GE ER>
               );
 /****************************************************************************/

/****************************************************************************
  --<SOURCING TO PO FPH>
  Name: CREATE_DOCUMENTS
  DESC: This procedure is a wrapper with the original signature. 
  ARGS: x_batch_id 	   IN     number   unique identifier for the all
					   the documents to be created.
					   It will be the same as 
					   interface_header_id as we always
					   create 1 doc at a time.
        x_document_id 	   IN OUT number   IN  document id to ADD to N/A for 
					       sourcing.
					   OUT returns the id of the document
					       created.
        x_number_lines 	   IN OUT number   IN  N/A
					   OUT returns the number of interface 
					       records processed.
   --<DBI FPJ>
        p_document_creation_method  IN  VARCHAR2 - Stores the method by which
                                    the document has been created.
 *****************************************************************************/
 procedure create_documents(x_batch_id 		IN     number,
			    x_document_id 	IN OUT NOCOPY number,
			    x_number_lines 	IN OUT NOCOPY number,
	                    p_document_creation_method IN VARCHAR2 DEFAULT NULL   --<DBI FPJ>
                           ,p_orig_org_id         IN   NUMBER DEFAULT NULL    -- <R12 MOAC>
						   ,p_group_shipments     IN   VARCHAR2  DEFAULT NULL --<Bug 14608120, Autocreate GE ER>
			    );
 /****************************************************************************/



-- Bug 2082757 :
FUNCTION source_blanket_line(x_po_header_id IN NUMBER,
                             x_requisition_line_id IN NUMBER,
                             x_interface_line_num IN NUMBER,
                             -- Bug 2707576 whether to allow the BPA to have
                             -- a different UOM from the requisition
                             x_allow_different_uoms IN VARCHAR2 DEFAULT 'Y',
                             p_purchasing_ou_id IN NUMBER --<Shared Proc FPJ>
                            ) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES (source_blanket_line, WNDS, RNPS);

--<Shared Proc FPJ Start>
PROCEDURE create_documents (
    p_api_version                IN               NUMBER,
    x_return_status              OUT    NOCOPY    VARCHAR2,
    x_msg_count                  OUT    NOCOPY    NUMBER,
    x_msg_data                   OUT    NOCOPY    VARCHAR2,
    p_batch_id                   IN               NUMBER,
    p_req_operating_unit_id      IN               NUMBER,
    p_purch_operating_unit_id    IN               NUMBER,
    x_document_id                IN OUT NOCOPY    NUMBER,
    x_number_lines               OUT    NOCOPY    NUMBER,
    x_document_number            OUT    NOCOPY    VARCHAR2
   ,p_sourcing_k_doc_type        IN               VARCHAR2 DEFAULT NULL--<CONTERMS FPJ>
   ,p_conterms_exist_flag        IN               VARCHAR2 DEFAULT 'N' --<CONTERMS FPJ>
   ,p_document_creation_method   IN		  VARCHAR2 DEFAULT NULL --<DBI FPJ>
   ,p_orig_org_id                IN               NUMBER DEFAULT NULL    -- <R12 MOAC>
   ,p_group_shipments            IN               VARCHAR2  DEFAULT NULL --<Bug 14608120 Autocreate GE ER>
);
--<Shared Proc FPJ End>

--<PDOI Enhancement Bug#17063664>
-- Creating overloaded procedure as extra parmeter x_online_report_id is required 
-- for displying error messages in Autocreate.
PROCEDURE create_documents (
      p_api_version                IN               NUMBER
    , x_return_status              OUT    NOCOPY    VARCHAR2
    , x_msg_count                  OUT    NOCOPY    NUMBER
    , x_msg_data                   OUT    NOCOPY    VARCHAR2
    , p_batch_id                   IN               NUMBER
    , p_req_operating_unit_id      IN               NUMBER
    , p_purch_operating_unit_id    IN               NUMBER
    , x_document_id                IN OUT NOCOPY    NUMBER
    , x_number_lines               OUT    NOCOPY    NUMBER
    , x_document_number            OUT    NOCOPY    VARCHAR2
    , p_sourcing_k_doc_type        IN               VARCHAR2 DEFAULT NULL--<CONTERMS FPJ>
    , p_conterms_exist_flag        IN               VARCHAR2 DEFAULT 'N' --<CONTERMS FPJ>
    , p_document_creation_method   IN		  VARCHAR2 DEFAULT NULL --<DBI FPJ>
    , p_orig_org_id                IN               NUMBER DEFAULT NULL    -- <R12 MOAC>
    , p_group_shipments            IN               VARCHAR2  DEFAULT NULL --<Bug 14608120 Autocreate GE ER>
    , x_online_report_id           OUT    NOCOPY    NUMBER
); 

-- CLM changes Start
PROCEDURE create_documents (
    p_api_version                IN               NUMBER,
    x_return_status              OUT    NOCOPY    VARCHAR2,
    x_msg_count                  OUT    NOCOPY    NUMBER,
    x_msg_data                   OUT    NOCOPY    VARCHAR2,
    p_batch_id                   IN               NUMBER,
    p_req_operating_unit_id      IN               NUMBER,
    p_purch_operating_unit_id    IN               NUMBER,
    x_document_id                IN OUT NOCOPY    NUMBER,
    x_number_lines               OUT    NOCOPY    NUMBER,
    x_document_number            OUT    NOCOPY    VARCHAR2
   ,p_sourcing_k_doc_type        IN               VARCHAR2 DEFAULT NULL--<CONTERMS FPJ>
   ,p_conterms_exist_flag        IN               VARCHAR2 DEFAULT 'N' --<CONTERMS FPJ>
   ,p_document_creation_method   IN		  VARCHAR2 DEFAULT NULL --<DBI FPJ>
   ,p_orig_org_id                IN               NUMBER DEFAULT NULL    -- <R12 MOAC>
   ,x_draft_id                   OUT   NOCOPY NUMBER
   ,x_error_code_tbl             IN OUT   NOCOPY PO_TBL_VARCHAR2000 --CLM Phase 2
   ,p_group_shipments            IN               VARCHAR2  DEFAULT NULL --<Bug 14608120 Autocreate GE ER>
   ,x_online_report_id           OUT    NOCOPY    NUMBER
);

-- <Complex Work R12>: Add parameters p_table_type, p_po_line_id
PROCEDURE update_award_distributions(
  p_table_type     IN    VARCHAR2   DEFAULT 'INTERFACE'
, p_po_line_id     IN    NUMBER     DEFAULT NULL
); --<GRANTS FPJ>


PROCEDURE calibrate_last_dist_quantity (
  p_line_location_id   IN   NUMBER
);

-- <Complex Work R12 End>

PROCEDURE calibrate_last_dist_amount                           -- <BUG 3322948>
(   p_line_location_id       IN       NUMBER
);

-- CLM changes End

-- Bug#20221798 : populate cbc_accouting_date in po/release header
-- during autocreate document from requisition

PROCEDURE populate_cbc_accounting_date(
  p_req_header_id       IN NUMBER
, p_document_id         IN NUMBER
, p_document_subtype    IN VARCHAR2
, x_return_status       OUT  NOCOPY VARCHAR2
);

END XX_PO_INTERFACE_PKG;
/

--show err;
COMMIT;
EXIT;
