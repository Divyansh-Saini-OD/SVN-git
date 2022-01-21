CREATE OR REPLACE PACKAGE APPS.XXPO_CREATE_SR_ASL AUTHID CURRENT_USER AS
/* $Header: POXWSRAS.pls 120.1.12020000.2 2013/02/10 22:23:28 vegajula ship $ */

 /*=======================================================================+
 | FILENAME
 |   POXWSRS.pls
 |
 | DESCRIPTION
 |   PL/SQL package:  PO_CREATE_SR_ASL
 |
 | NOTES

 | MODIFIED    (MM/DD/YY)
 |
 *=======================================================================*/

procedure PROCESS_PO_LINES_FOR_SR_ASL( itemtype        in varchar2,
                                itemkey         in varchar2,
                                actid           in number,
                                funcmode        in varchar2,
                                resultout       out NOCOPY varchar2);

PROCEDURE GET_LINE_FOR_PROCESS
(
     x_header_id        IN  NUMBER, -- PO  Header ID
     x_prev_line_num    IN  NUMBER, -- Line number last processed
     x_line_id          OUT NOCOPY NUMBER, -- PO Line ID
     x_line_num         OUT NOCOPY NUMBER, -- PO Line Num
     x_vendor_id        OUT NOCOPY NUMBER, -- Vendor ID
     x_vendor_site_id   OUT NOCOPY NUMBER, -- Vendor Site ID
     x_item_id          OUT NOCOPY NUMBER,  -- Inventory Item ID
     x_approved_flag    OUT NOCOPY VARCHAR2,  -- Approval Status
     x_start_date       OUT NOCOPY DATE,
     x_end_date         OUT NOCOPY DATE,
     x_interface_header_id OUT NOCOPY NUMBER,
     x_interface_line_id OUT NOCOPY NUMBER,
     x_org_assign_change IN VARCHAR2 default null
     );  -- GA FPI


procedure Create_ASL (itemtype        in varchar2,
                      itemkey         in varchar2,
                      actid           in number,
                      funcmode        in varchar2,
                      resultout       out NOCOPY varchar2);


procedure Create_Sourcing_Rule(itemtype        in varchar2,
		                      itemkey         in varchar2,
       			              actid           in number,
               			      funcmode        in varchar2,
                     		  resultout       out NOCOPY varchar2);
--<LOCAL SR/ASL PROJECT 11i11 START>
PROCEDURE CREATE_AUTOSOURCE_RULES(
        p_api_version           IN  NUMBER,
        p_init_msg_list         IN  VARCHAR2 :=FND_API.G_FALSE	,
        p_commit                IN  VARCHAR2 :=FND_API.G_FALSE	,
	    x_return_status         OUT	NOCOPY VARCHAR2,
	    x_msg_count             OUT	NOCOPY NUMBER,
        x_msg_data              OUT	NOCOPY VARCHAR2,
        p_document_id           IN  PO_HEADERS_ALL.po_header_id%type,
        p_vendor_id             IN  PO_HEADERS_ALL.vendor_id%type,
        p_purchasing_org_id     IN  PO_HEADERS_ALL.org_id%type,
        p_vendor_site_id        IN  PO_HEADERS_ALL.vendor_site_id%type,
        p_create_sourcing_rule  IN  VARCHAR2,
        p_update_sourcing_rule  IN  VARCHAR2,
        p_agreement_lines_selection IN VARCHAR2  ,
        p_sourcing_level        IN  VARCHAR2,
        p_inv_org               IN  HR_ALL_ORGANIZATION_UNITS.organization_id%type,
        p_sourcing_rule_name    IN  VARCHAR2,
        p_release_gen_method    IN  PO_ASL_ATTRIBUTES.release_generation_method%type,
        p_assignment_set_id     IN  MRP_ASSIGNMENT_SETS.assignment_set_id%type) ;

PROCEDURE  CREATE_SOURCING_RULES_ASL
  (
        p_api_version                   IN NUMBER,
        p_init_msg_list                 IN VARCHAR2 :=FND_API.G_FALSE,
        p_commit                        IN VARCHAR2 :=FND_API.G_FALSE,
        x_return_status                 OUT NOCOPY VARCHAR2,
        x_msg_count                     OUT NOCOPY NUMBER,
        x_msg_data                      OUT NOCOPY VARCHAR2,
        p_interface_header_id           IN      PO_HEADERS_INTERFACE.interface_header_id%type,
        p_interface_line_id             IN      PO_LINES_INTERFACE.interface_line_id%type,
        p_document_id                   IN      PO_HEADERS.po_header_id%type,
        p_po_line_id                    IN      PO_LINES.po_line_id%type,
        p_document_type                 IN      PO_HEADERS.type_lookup_code%type,
        p_approval_status               IN      VARCHAR2,
        p_vendor_id                     IN      PO_HEADERS.vendor_id%type,
        p_vendor_site_id                IN      PO_HEADERS.vendor_site_id%type,
        p_inv_org_id                    IN      HR_ALL_ORGANIZATION_UNITS.organization_id%type,
        p_sourcing_level                IN      VARCHAR2,
        p_item_id                       IN      MTL_SYSTEM_ITEMS.inventory_item_id%type,
        p_category_id                   IN      MTL_ITEM_CATEGORIES.category_id%type,
        p_rel_gen_method                IN      PO_ASL_ATTRIBUTES.release_generation_method%type,
        p_rule_name                     IN      MRP_SOURCING_RULES.sourcing_rule_name%type,
        p_rule_name_prefix              IN      VARCHAR2,
        p_start_date                    IN      DATE,
        p_end_date                      IN      DATE,
        p_assignment_set_id             IN      MRP_ASSIGNMENT_SETS.assignment_set_id%type,
        p_create_update_code            IN      VARCHAR2,
        p_interface_error_code          IN      VARCHAR2,
        x_header_processable_flag       IN OUT NOCOPY VARCHAR2
 );
--<LOCAL SR/ASL PROJECT 11i11 END>

/* Bug 10417292 - Launching Conucrrent Request for Creating ASL and SR
Instead of doing it in workflow*/

procedure CREATE_SR_ASL
 (                          itemtype        in varchar2,
 	                          itemkey         in varchar2,
 	                          actid           in number,
 	                          funcmode        in varchar2,
 	                          resultout       out NOCOPY varchar2
 );
END XXPO_CREATE_SR_ASL;
/