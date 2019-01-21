-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name             :    XX_ICX_CAT_ATTS_BY_ORG_V.vw                 |
-- | Description      :    View  for  Category  attributes extn E0978  |
-- |                                                                   |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author              Remarks                 |
-- |=======   ===========  ================    ========================|
-- |1.0                    Bushrod Thomas      Initial version         |
-- |                                                                   | 
-- |1.1       22-AUG-2007  Anitha.          Fixed defect 1371          | 
-- +===================================================================+
CREATE OR REPLACE VIEW XX_ICX_CAT_ATTS_BY_ORG_V AS
  SELECT Organization_ID
      ,OrgName
     ,CategoriesPerOrg.Category_ID
     ,CONCATENATED_SEGMENTS
      ,CategoryDescription
      ,Buyer_ID
      ,BuyerName
      ,Approver_ID
      ,ApproverName
  FROM (SELECT hr_all_organization_units.Organization_ID
              ,hr_all_organization_units.Name OrgName
              ,mtl_categories_tl.Category_ID
              ,concatenated_segments
              ,mtl_categories_tl.Description CategoryDescription
         FROM hr_all_organization_units
             ,mtl_categories_tl 
             ,MTL_CATEGORIES_KFV
       WHERE hr_all_organization_units.Type='OU'
         and sysdate between hr_all_organization_units.date_from and nvl(hr_all_organization_units.date_to,sysdate)
         and hr_all_organization_units.creation_date>'01-JAN-07'
         and mtl_categories_tl.category_id = MTL_CATEGORIES_KFV.category_id) CategoriesPerOrg,
       ( SELECT Cats.Org_ID
              ,Cats.Category_ID
              ,Cats.Buyer_ID
              ,Cats.Approver_ID
              ,XX_ICX_Get_Persons_Full_Name(Cats.Buyer_ID) BuyerName
              ,XX_ICX_Get_Persons_Full_Name(Cats.Approver_ID) ApproverName
          FROM XX_ICX_CAT_ATTS_BY_ORG Cats) CatPeople
 WHERE CatPeople.Org_ID      (+) = CategoriesPerOrg.Organization_ID
   AND CatPeople.Category_ID (+) = CategoriesPerOrg.Category_ID
/