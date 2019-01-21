package od.oracle.apps.xxcrm.customer.account.server;

/* Subversion Info:

*

* $HeadURL$

*

* $Rev$

*

* $Date$

*/

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupContractCustomLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupContractNumberLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupDocFreqLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupDocNameLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupDocTypeLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupTargetSysVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODDefaultPageDefLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODDelDocTypeLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODDocPaymentMethodLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODPricePlanLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupDocSortLokkupVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupDocTotalsShuttleVOImpl;
import od.oracle.apps.xxcrm.asn.common.poplist.server.ODAcctSetupAdminDocPageBreakShuttleVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODPartyRevenueBandAttributeVOImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODDefaultValuesVOImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODDocumentTemplatesVOImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODDocTemplateAttributesVOImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupDepartmentValidatedLovVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAccountSetupUpOffVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODContractTemplatePoplistVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODContractTemplatesVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODContractTemplatesVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCdhContractProgCodesVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCdhContractProgCodesVORowImpl;

import oracle.apps.ar.hz.components.lookup.server.HzPuiLookupVOImpl;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.jbo.server.ViewLinkImpl;

//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODCustomerAccountSetupRequestAMImpl extends OAApplicationModuleImpl
{
  /**
   *
   * This is the default constructor (do not remove)
   */
  public ODCustomerAccountSetupRequestAMImpl()
  {
  }

  /**
   *
   * Container's getter for CustomerAccountSetupRequestVO
   */
  public ODCustomerAccountSetupRequestVOImpl getCustomerAccountSetupRequestVO()
  {
    return (ODCustomerAccountSetupRequestVOImpl)findViewObject("CustomerAccountSetupRequestVO");
  }


  /**
   *
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.customer.account.server", "CustomerAccountSetupRequestAMLocal");
  }



  public void initPopLists_SalesContactTitle()
  {
    String str_contactTitle = "CONTACT_TITLE";
    OAViewObject oaviewobject = null;
    Serializable aserializable[] = {
       str_contactTitle
    };
    oaviewobject = (OAViewObject)findViewObject("HzPuiPrefixVO");
    oaviewobject.invokeMethod("initQuery", aserializable);
  }

  public void initPopLists_APContactTitle()
  {
    String str_contactTitle = "CONTACT_TITLE";
    OAViewObject oaviewobject = null;
    Serializable aserializable[] = {
       str_contactTitle
    };
    oaviewobject = (OAViewObject)findViewObject("HzPuiPrefixVO1");
    oaviewobject.invokeMethod("initQuery", aserializable);
  }

  public HzPuiLookupVOImpl getHzPuiPrefixVO()
  {
    return (HzPuiLookupVOImpl)findViewObject("HzPuiPrefixVO");
  }

  public HzPuiLookupVOImpl getHzPuiPrefixVO1()
  {
    return (HzPuiLookupVOImpl)findViewObject("HzPuiPrefixVO1");
  }

  public OAViewObjectImpl getHzPuiPhoneCountryCodeVO()
  {
    return (OAViewObjectImpl)findViewObject("HzPuiPhoneCountryCodeVO");
  }

  public OAViewObjectImpl getHzPuiPhoneCountryCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("HzPuiPhoneCountryCodeVO1");
  }

  public OAViewObjectImpl getHzPuiFaxCountryCodeVO()
  {
    return (OAViewObjectImpl)findViewObject("HzPuiFaxCountryCodeVO");
  }

  public OAViewObjectImpl getHzPuiFaxCountryCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("HzPuiFaxCountryCodeVO1");
  }


  public OAViewObjectImpl getAPContactsVO()
  {
    return (OAViewObjectImpl)findViewObject("ODAPContactsVO");
  }
  public OAViewObjectImpl getAPContactPointEmailVO()
  {
    return (OAViewObjectImpl)findViewObject("ODAPContactPointEmailVO");
  }
  public OAViewObjectImpl getAPContactPointFaxVO()
  {
    return (OAViewObjectImpl)findViewObject("ODAPContactPointFaxVO");
  }
  public OAViewObjectImpl getAPContactPointPhoneVO()
  {
    return (OAViewObjectImpl)findViewObject("ODAPContactPointPhoneVO");
  }


  public OAViewObjectImpl getSalesContactsVO()
  {
    return (OAViewObjectImpl)findViewObject("ODSalesContactsVO");
  }
  public OAViewObjectImpl getSalesContactPointEmailVO()
  {
    return (OAViewObjectImpl)findViewObject("ODSalesContactPointEmailVO");
  }
  public OAViewObjectImpl getSalesContactPointFaxVO()
  {
    return (OAViewObjectImpl)findViewObject("ODSalesContactPointFaxVO");
  }
  public OAViewObjectImpl getSalesContactPointPhoneVO()
  {
    return (OAViewObjectImpl)findViewObject("ODSalesContactPointPhoneVO");
  }


  /**
   *
   * Container's getter for ODAcctSetupTargetSysVO
   */
  public ODAcctSetupTargetSysVOImpl getODAcctSetupTargetSysVO()
  {
    return (ODAcctSetupTargetSysVOImpl)findViewObject("ODAcctSetupTargetSysVO");
  }

  /**
   *
   * Container's getter for ODPricePlanLovVO
   */
  public ODPricePlanLovVOImpl getODPricePlanLovVO()
  {
    return (ODPricePlanLovVOImpl)findViewObject("ODPricePlanLovVO");
  }

  /**
   *
   * Container's getter for ODDefaultPageDefLovVO
   */
  public ODDefaultPageDefLovVOImpl getODDefaultPageDefLovVO()
  {
    return (ODDefaultPageDefLovVOImpl)findViewObject("ODDefaultPageDefLovVO");
  }

  /**
   *
   * Container's getter for ODDelDocTypeLovVO
   */
  public ODDelDocTypeLovVOImpl getODDelDocTypeLovVO()
  {
    return (ODDelDocTypeLovVOImpl)findViewObject("ODDelDocTypeLovVO");
  }

  /**
   *
   * Container's getter for ODDocPaymentMethodLovVO
   */
  public ODDocPaymentMethodLovVOImpl getODDocPaymentMethodLovVO()
  {
    return (ODDocPaymentMethodLovVOImpl)findViewObject("ODDocPaymentMethodLovVO");
  }


  /**
   *
   * Container's getter for ODAcctSetupContractCustomLovVO
   */
  public ODAcctSetupContractCustomLovVOImpl getODAcctSetupContractCustomLovVO()
  {
    return (ODAcctSetupContractCustomLovVOImpl)findViewObject("ODAcctSetupContractCustomLovVO");
  }

  /**
   *
   * Container's getter for ODAcctSetupContractNumberLovVO
   */
  public ODAcctSetupContractNumberLovVOImpl getODAcctSetupContractNumberLovVO()
  {
    return (ODAcctSetupContractNumberLovVOImpl)findViewObject("ODAcctSetupContractNumberLovVO");
  }

  /**
   *
   * Container's getter for ODAcctSetupDocFreqLovVO
   */
  public ODAcctSetupDocFreqLovVOImpl getODAcctSetupDocFreqLovVO()
  {
    return (ODAcctSetupDocFreqLovVOImpl)findViewObject("ODAcctSetupDocFreqLovVO");
  }

  /**
   *
   * Container's getter for ODAcctSetupDocNameLovVO
   */
  public ODAcctSetupDocNameLovVOImpl getODAcctSetupDocNameLovVO()
  {
    return (ODAcctSetupDocNameLovVOImpl)findViewObject("ODAcctSetupDocNameLovVO");
  }

  /**
   *
   * Container's getter for ODAcctSetupDocTypeLovVO
   */
  public ODAcctSetupDocTypeLovVOImpl getODAcctSetupDocTypeLovVO()
  {
    return (ODAcctSetupDocTypeLovVOImpl)findViewObject("ODAcctSetupDocTypeLovVO");
  }

  /**
   *
   * Container's getter for ODCustomerAccountSetupRequestDetailsVO
   */
  public ODCustomerAccountSetupRequestDetailsVOImpl getODCustomerAccountSetupRequestDetailsVO()
  {
    return (ODCustomerAccountSetupRequestDetailsVOImpl)findViewObject("ODCustomerAccountSetupRequestDetailsVO");
  }



  /**
   *
   * Container's getter for ODAcctSetupDocSortLokkupVO
   */
  public ODAcctSetupDocSortLokkupVOImpl getODAcctSetupDocSortLokkupVO()
  {
    return (ODAcctSetupDocSortLokkupVOImpl)findViewObject("ODAcctSetupDocSortLokkupVO");
  }

  /**
   *
   * Container's getter for ODAcctSetupDocTotalsShuttleVO
   */
  public ODAcctSetupDocTotalsShuttleVOImpl getODAcctSetupDocTotalsShuttleVO()
  {
    return (ODAcctSetupDocTotalsShuttleVOImpl)findViewObject("ODAcctSetupDocTotalsShuttleVO");
  }

  /**
   *
   * Container's getter for ODAcctSetupAdminDocPageBreakShuttleVO
   */
  public ODAcctSetupAdminDocPageBreakShuttleVOImpl getODAcctSetupAdminDocPageBreakShuttleVO()
  {
    return (ODAcctSetupAdminDocPageBreakShuttleVOImpl)findViewObject("ODAcctSetupAdminDocPageBreakShuttleVO");
  }

  /**
   *
   * Container's getter for ODCustAcctSetupDocPropertyVO
   */
  public ODCustAcctSetupDocPropertyVOImpl getODCustAcctSetupDocPropertyVO()
  {
    return (ODCustAcctSetupDocPropertyVOImpl)findViewObject("ODCustAcctSetupDocPropertyVO");
  }

  /**
   *
   * Container's getter for ODCustAcctSetupDocPropertyNewVO
   */
  public ODCustAcctSetupDocPropertyVOImpl getODCustAcctSetupDocPropertyNewVO()
  {
    return (ODCustAcctSetupDocPropertyVOImpl)findViewObject("ODCustAcctSetupDocPropertyNewVO");
  }



  /**
   *
   * Container's getter for ODCustAcctSetupContractsVO
   */
  public ODCustAcctSetupContractsVOImpl getODCustAcctSetupContractsVO()
  {
    return (ODCustAcctSetupContractsVOImpl)findViewObject("ODCustAcctSetupContractsVO");
  }

  /**
   *
   * Container's getter for ODCustAcctSetupContractsNewVO
   */
  public ODCustAcctSetupContractsVOImpl getODCustAcctSetupContractsNewVO()
  {
    return (ODCustAcctSetupContractsVOImpl)findViewObject("ODCustAcctSetupContractsNewVO");
  }

  /**
   *
   * Container's getter for ODCustAcctSetupDocumentVO
   */
  public ODCustAcctSetupDocumentVOImpl getODCustAcctSetupDocumentVO()
  {
    return (ODCustAcctSetupDocumentVOImpl)findViewObject("ODCustAcctSetupDocumentVO");
  }

  /**
   *
   * Container's getter for CustomerAccountSetupRequestPopupVO
   */
  public ODCustomerAccountSetupRequestVOImpl getCustomerAccountSetupRequestPopupVO()
  {
    return (ODCustomerAccountSetupRequestVOImpl)findViewObject("CustomerAccountSetupRequestPopupVO");
  }


  /**
   *
   * Container's getter for ODDefaultValuesVO
   */
  public ODDefaultValuesVOImpl getODDefaultValuesVO()
  {
    return (ODDefaultValuesVOImpl)findViewObject("ODDefaultValuesVO");
  }

  /**
   *
   * Container's getter for ODDocumentTemplatesVO
   */
  public ODDocumentTemplatesVOImpl getODDocumentTemplatesVO()
  {
    return (ODDocumentTemplatesVOImpl)findViewObject("ODDocumentTemplatesVO");
  }

  /**
   *
   * Container's getter for ODDocTemplateAttributesVO
   */
  public ODDocTemplateAttributesVOImpl getODDocTemplateAttributesVO()
  {
    return (ODDocTemplateAttributesVOImpl)findViewObject("ODDocTemplateAttributesVO");
  }

  /**
   *
   * Container's getter for ODPartyRevenueBandAttributeVO
   */
  public ODPartyRevenueBandAttributeVOImpl getODPartyRevenueBandAttributeVO()
  {
    return (ODPartyRevenueBandAttributeVOImpl)findViewObject("ODPartyRevenueBandAttributeVO");
  }

  /**
   *
   * Container's getter for ODAcctSetupDepartmentValidatedLovVO
   */
  public ODAcctSetupDepartmentValidatedLovVOImpl getODAcctSetupDepartmentValidatedLovVO()
  {
    return (ODAcctSetupDepartmentValidatedLovVOImpl)findViewObject("ODAcctSetupDepartmentValidatedLovVO");
  }

  /**
   *
   * Container's getter for ODApContactLovVO
   */
  public ODApContactLovVOImpl getODApContactLovVO()
  {
    return (ODApContactLovVOImpl)findViewObject("ODApContactLovVO");
  }

  public OAViewObjectImpl getODSalesContactLovVO()
  {
    return (OAViewObjectImpl)findViewObject("ODSalesContactLovVO");
  }

  /**
   *
   * Container's getter for ODCustomerAssignedRoleVO
   */
  public ODCustomerAssignedRoleVOImpl getODCustomerAssignedRoleVO()
  {
    return (ODCustomerAssignedRoleVOImpl)findViewObject("ODCustomerAssignedRoleVO");
  }

  /**
   *
   * Container's getter for ODAccountSetupUpOffVO
   */
  public ODAccountSetupUpOffVOImpl getODAccountSetupUpOffVO()
  {
    return (ODAccountSetupUpOffVOImpl)findViewObject("ODAccountSetupUpOffVO");
  }


  /**
   *
   * Container's getter for ODContractsAssignedVO
   */
  public ODContractsAssignedVOImpl getODContractsAssignedVO()
  {
    return (ODContractsAssignedVOImpl)findViewObject("ODContractsAssignedVO");
  }

  /**
   *
   * Container's getter for ODContTempCUPVO
   */
  public ODContTempCUPVOImpl getODContTempCUPVO()
  {
    return (ODContTempCUPVOImpl)findViewObject("ODContTempCUPVO");
  }

  /**
   *
   * Container's getter for ODContractTemplatePoplistVO
   */
  public ODContractTemplatePoplistVOImpl getODContractTemplatePoplistVO()
  {
    return (ODContractTemplatePoplistVOImpl)findViewObject("ODContractTemplatePoplistVO");
  }

  /**
   *
   * Container's getter for ODAccountSetupButtonsPVO
   */
  public ODAccountSetupButtonsPVOImpl getODAccountSetupButtonsPVO()
  {
    return (ODAccountSetupButtonsPVOImpl)findViewObject("ODAccountSetupButtonsPVO");
  }

  /**
   *
   * Container's getter for ODOrgAccountSetupPVO
   */
  public ODOrgAccountSetupPVOImpl getODOrgAccountSetupPVO()
  {
    return (ODOrgAccountSetupPVOImpl)findViewObject("ODOrgAccountSetupPVO");
  }
  /**
   *
   * Container's getter for ODCustomerSegmentationLOVVO
   */
  public ODCustomerSegmentationLOVVOImpl getODCustomerSegmentationLOVVO()
  {
    return (ODCustomerSegmentationLOVVOImpl)findViewObject("ODCustomerSegmentationLOVVO");
  }
  /**
   *
   * Container's getter for ODCustomerLoyaltyLOVVO
   */
  public ODCustomerLoyaltyLOVVOImpl getODCustomerLoyaltyLOVVO()
  {
    return (ODCustomerLoyaltyLOVVOImpl)findViewObject("ODCustomerLoyaltyLOVVO");
  }

  /**
   *
   * Container's getter for ODCustLoyaltySegmentVO
   */
  public ODCustLoyaltySegmentVOImpl getODCustLoyaltySegmentVO()
  {
    return (ODCustLoyaltySegmentVOImpl)findViewObject("ODCustLoyaltySegmentVO");
  }

  /**
   *
   * Container's getter for ODContractTemplatesVO1
   */
  public ODContractTemplatesVOImpl getODContractTemplatesVO1()
  {
    return (ODContractTemplatesVOImpl)findViewObject("ODContractTemplatesVO1");
  }


  /**
   *
   * Container's getter for ODUnivPriceProgCodesLOVVO
   */
  public ODUnivPriceProgCodesLOVVOImpl getODUnivPriceProgCodesLOVVO()
  {
    return (ODUnivPriceProgCodesLOVVOImpl)findViewObject("ODUnivPriceProgCodesLOVVO");
  }

  /**
   *
   * Container's getter for ODCdhContractProgCodesVO
   */
  public ODCdhContractProgCodesVOImpl getODCdhContractProgCodesVO()
  {
    return (ODCdhContractProgCodesVOImpl)findViewObject("ODCdhContractProgCodesVO");
  }

  /**
   *
   * Container's getter for ODCdhContractCompPVO
   */
  public ODCdhContractCompPVOImpl getODCdhContractCompPVO()
  {
    return (ODCdhContractCompPVOImpl)findViewObject("ODCdhContractCompPVO");
  }

  /**
   *
   * Container's getter for OdCdhAcctTemplateContractsVO
   */
  public OdCdhAcctTemplateContractsVOImpl getOdCdhAcctTemplateContractsVO()
  {
    return (OdCdhAcctTemplateContractsVOImpl)findViewObject("OdCdhAcctTemplateContractsVO");
  }


}
