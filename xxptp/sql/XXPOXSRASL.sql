REM dbdrv:none

/* $Header: POXSRASL.sql 120.0 2005/06/02 00:44:04 appldev noship $ */
SET DOC OFF

--<LOCAL SR/ASL PROJECT 11i11 START>
-------------------------------------------------------------------------------
--Start of Comments
--Name: POXSRASL.sql
--Pre-reqs: 
--  ARCHIVAL option should be APPROVE in document types for BLANKET AGREEMENTS
--Modifies:
--  n/a
--Locks:
--  n/a
--Function:
--  This is the main program block for the "Document Sourcing Rules Creation Process". 
--  PO_CREATE_SOURCING_RULES.create_sourcing_rule_asl is called from here, which inturn
--  would create the ASL and Sourcing Rule for each Agrement line.
--Parameters:
--IN:
--p_purchasing_org_id
--  Specifies the purchasing org in which the ASL/SR would have to be created.
--p_vendor_site_id
--  Specifies the Supplier Site Id Enabled corresponding to the owining
--  org/Purchasing Org
--p_create_sourcing_rule
--  This would have to be 'Y' by default. Infact we can hardcode this
--  and need not have this as a parameter.
--P_update_sourcing_rule
--  This would have to be 'Y' by default. Infact we can hardcode this
--  and need not have this as a parameter.
--p_agreement_lines_selection
--  This parameter specifies whether the sourcing rules would be created
--  for all the lines or for just the new lines. Possible values for 
--  this parameter are 'ALL' 'NEW'
--p_sourcing_level
--  This parameter specifies if the Sourcing Rule should be a Global/Local 
--  Sourcing Rule and if the assignment should be Item or Item Organization.
--p_inv_org
--  Specifies the Inventory Org for which the sourcing rule needs to be created.
--p_sourcing_rule_name
--  Specifies the user defined sourcing rule name.
--p_assigment_set_id
--  Specifies the assignment set to which the created sourcing rule 
--  should be assigned.
--p_release_gen_method
--  This specifies what the release generation method would be :
--  CREATE, CREATE_AND_APPROVE, NONE

--Testing:
--  
--  
--End of Comments
-------------------------------------------------------------------------------

set feedback off;
set verify off;

WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK

DECLARE
l_vendor_id                 PO_HEADERS_ALL.vendor_id%type       ;
l_document_id               PO_HEADERS_ALL.po_header_id%type    ;
l_purchasing_org_id         PO_HEADERS_ALL.org_id%type          ;
l_vendor_site_id            PO_HEADERS_ALL.vendor_site_id%type  ;
l_select_agreement_lines    VARCHAR2(10)                        ;
l_assignment_set            MRP_ASSIGNMENT_SETS.assignment_set_id%type;
l_sourcing_level            VARCHAR2(20)                        ;
l_inv_org                   HR_ALL_ORGANIZATION_UNITS.organization_id%type;
l_sourcing_rule_name        MRP_SOURCING_RULES.sourcing_rule_name%type;
l_release_generation_method PO_ASL_ATTRIBUTES.release_generation_method%type;

l_api_version               NUMBER                              :=1.0;
l_init_msg_list             VARCHAR2(5)                         :=FND_API.G_FALSE;
l_commit                    VARCHAR2(5)                         :=FND_API.G_FALSE;
l_validation_level          NUMBER                              :=FND_API.G_VALID_LEVEL_FULL;
l_return_status             VARCHAR2(5);
l_msg_count                 NUMBER    ;
l_msg_data                  VARCHAR2(2000);
l_progress                  VARCHAR2(3):='000';

BEGIN
--    Call the procedure to create Document Sourcing Rules
    l_vendor_id                 :='&1';
    l_document_id               :='&2';
    l_purchasing_org_id         :='&4';
    l_vendor_site_id            :='&5';
    l_select_agreement_lines    :='&6';
    l_assignment_set            :='&7';
    l_sourcing_level            :='&8';
    l_inv_org                   :='&10';
    l_sourcing_rule_name        :='&11';
    l_release_generation_method :='&12';

    XXPO_CREATE_SR_ASL.create_autosource_rules(
        p_api_version                 =>    l_api_version,
        p_init_msg_list               =>    l_init_msg_list,
        p_commit                      =>    l_commit,
        x_return_status               =>    l_return_status,
        X_msg_count                   =>    l_msg_count, 
        x_msg_data                    =>    l_msg_data,
        p_document_id                 =>    l_document_id,
        p_vendor_id                   =>    l_vendor_id,
        p_purchasing_org_id           =>    l_purchasing_org_id,
        p_vendor_site_id              =>    l_vendor_site_id,
        p_create_sourcing_rule        =>    'Y',
        p_update_sourcing_rule        =>    'Y',
        p_agreement_lines_selection   =>     l_select_agreement_lines,
        p_sourcing_level              =>    l_sourcing_level,
        p_inv_org                     =>    l_inv_org,
        p_sourcing_rule_name          =>    l_sourcing_rule_name,
        p_release_gen_method          =>    l_release_generation_method,
        p_assignment_set_id           =>    l_assignment_set
        );
    l_progress:='001';
EXCEPTION 
    WHEN OTHERS THEN
      po_message_s.sql_error('ODPOASLGEN',l_progress,sqlcode);
      po_message_s.sql_show_error;
      RAISE;
END;
/
COMMIT;
EXIT;
--<LOCAL SR/ASL PROJECT 11i11 END>
