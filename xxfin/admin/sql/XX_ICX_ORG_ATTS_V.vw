
  CREATE OR REPLACE FORCE VIEW "APPS"."XX_ICX_ORG_ATTS_V" ("ORGANIZATION_ID", "ORGNAME", "APPROVER_ID", "APPROVERNAME") AS 
  select Organization_ID
      ,OrgName
      ,Approver_ID
      ,ApproverName
  from (select hr_all_organization_units.Organization_ID
              ,hr_all_organization_units.Name OrgName
         from hr_all_organization_units
        where hr_all_organization_units.Type='OU'
          and sysdate between date_from and nvl(date_to,sysdate)
          and creation_date>'01-JAN-07') Orgs,
       ( select OUatts.Org_ID
              ,OUatts.Approver_ID
              ,XX_ICX_Get_Persons_Full_Name(OUatts.Approver_ID) ApproverName
          from XX_ICX_ORG_ATTS OUatts) OUattPeople
 where OUattPeople.Org_ID   (+) = Orgs.Organization_ID
;
