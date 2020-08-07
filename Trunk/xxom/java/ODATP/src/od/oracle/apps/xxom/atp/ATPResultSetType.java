/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             AtpResultSetType.java                                         |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This class implements the object to hold the results of                |
 |    each ATP execution thread.                                             |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |     This Class would be utilized in ATPProcessControl.java,               |
 |     ATPMakeCall.java and DateAnalysis.java                                |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/18/2007 Sathish Gnanamani   Initial Creation                        |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp;

import java.math.BigDecimal;

import java.sql.Date;

/**
 * Proides an object type to load all the results of an ATP inquiry.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 */
public class ATPResultSetType {

    public static final String RCS_ID = 
        "$Header: AtpResultSetType.java  05/29/2007 Satis-Gnanmani$";

    /** 
     * The following member variables will be used in dynamic database calls and 
     * for data population and hence are Public.
     * 
     **/
     
    /*
     * Input Params
     */
    public String itemNumber;
    public BigDecimal srcOrgId;
    public BigDecimal tcscOrgId;
    public String subItemNumber;
    public String quantityUOM;
    public String custNumber;
    public String custShiptoLoc;
    public String shipFromOrg;
    public Date requestedDate;
    public BigDecimal quantity;
    public BigDecimal operatingUnit;
    public String shipMethod = "";

    /*
     * Output Params
     */
    public BigDecimal requestedDateQty;
    public Date shipDate;
    public Date arrivalDate;
    public BigDecimal errorCode;
    public String returnStatus;
    public String errorMessage;
    public String itemPlanningCategory;
    public String srcSupplier;
    public String srcSupplierType;
    public String srcSupplierSite;

    /*
     * Local variables
     */
    public BigDecimal callPriority;
    public String callName;


    /*
     * Reference variables
     */
    public BigDecimal unitWeight;
    public String atpOrderType;
    public String supplierItem;
    public String orgName;
    public String shipMethodCode;
    public String atpFullfillmentType;
    public String facilityCode;
    public String supplierAccount;
    public String zoneName;


    public void setSrcOrgId(BigDecimal srcOrgId) {
        this.srcOrgId = srcOrgId;
    }

    public BigDecimal getSrcOrgId() {
        return srcOrgId;
    }

    public void setTcscOrgId(BigDecimal tcscOrgId) {
        this.tcscOrgId = tcscOrgId;
    }

    public BigDecimal getTcscOrgId() {
        return tcscOrgId;
    }

    public void setRequestDateQty(BigDecimal requestDateQty) {
        this.requestedDateQty = requestDateQty;
    }

    public BigDecimal getRequestedDateQty() {
        return requestedDateQty;
    }

    public void setShipDate(Date shipDate) {
        this.shipDate = shipDate;
    }

    public Date getShipDate() {
        return shipDate;
    }

    public void setArrivalDate(Date arrivalDate) {
        this.arrivalDate = arrivalDate;
    }

    public Date getArrivalDate() {
        return arrivalDate;
    }

    public void setErrorCode(BigDecimal errorCode) {
        this.errorCode = errorCode;
    }

    public BigDecimal getErrorCode() {
        return errorCode;
    }

    public void setReturnStatus(String returnStatus) {
        this.returnStatus = returnStatus;
    }

    public String getReturnStatus() {
        return returnStatus;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setRequestedDateQty(BigDecimal requestedDateQty) {
        this.requestedDateQty = requestedDateQty;
    }

    public void setCallPriority(BigDecimal callPriority) {
        this.callPriority = callPriority;
    }

    public BigDecimal getCallPriority() {
        return callPriority;
    }

    public void setCallName(String callName) {
        this.callName = callName;
    }

    public String getCallName() {
        return callName;
    }

    public void setItemPlanningCategory(String itemPlanningCategory) {
        this.itemPlanningCategory = itemPlanningCategory;
    }

    public String getItemPlanningCategory() {
        return itemPlanningCategory;
    }

    public void setUnitWeight(BigDecimal unitWeight) {
        this.unitWeight = unitWeight;
    }

    public BigDecimal getUnitWeight() {
        return unitWeight;
    }

    public void setAtpOrderType(String atpOrderType) {
        this.atpOrderType = atpOrderType;
    }

    public String getAtpOrderType() {
        return atpOrderType;
    }

    public void setSupplierItem(String supplierItem) {
        this.supplierItem = supplierItem;
    }

    public String getSupplierItem() {
        return supplierItem;
    }

    public void setOrgName(String orgName) {
        this.orgName = orgName;
    }

    public String getOrgName() {
        return orgName;
    }

    public void setSrcSupplier(String srcSupplier) {
        this.srcSupplier = srcSupplier;
    }

    public String getSrcSupplier() {
        return srcSupplier;
    }

    public void setSrcSupplierType(String srcSupplierType) {
        this.srcSupplierType = srcSupplierType;
    }

    public String getSrcSupplierType() {
        return srcSupplierType;
    }

    public void setSrcSupplierSite(String srcSupplierSite) {
        this.srcSupplierSite = srcSupplierSite;
    }

    public String getSrcSupplierSite() {
        return srcSupplierSite;
    }

    public void setShipMethodCode(String shipMethodCode) {
        this.shipMethodCode = shipMethodCode;
    }

    public String getShipMethodCode() {
        return shipMethodCode;
    }

    public void setAtpFullfillmentType(String atpFullfillmentType) {
        this.atpFullfillmentType = atpFullfillmentType;
    }

    public String getAtpFullfillmentType() {
        return atpFullfillmentType;
    }

    public void setFacilityCode(String facilityCode) {
        this.facilityCode = facilityCode;
    }

    public String getFacilityCode() {
        return facilityCode;
    }

    public void setSupplierAccount(String supplierAccount) {
        this.supplierAccount = supplierAccount;
    }

    public String getSupplierAccount() {
        return supplierAccount;
    }

    public void setZoneName(String zoneName) {
        this.zoneName = zoneName;
    }

    public String getZoneName() {
        return zoneName;
    }

    public void setItemNumber(String itemNumber) {
        this.itemNumber = itemNumber;
    }

    public String getItemNumber() {
        return itemNumber;
    }

    public void setQuantityUOM(String quantityUOM) {
        this.quantityUOM = quantityUOM;
    }

    public String getQuantityUOM() {
        return quantityUOM;
    }

    public void setCustNumber(String custNumber) {
        this.custNumber = custNumber;
    }

    public String getCustNumber() {
        return custNumber;
    }

    public void setCustShiptoLoc(String custShiptoLoc) {
        this.custShiptoLoc = custShiptoLoc;
    }

    public String getCustShiptoLoc() {
        return custShiptoLoc;
    }

    public void setShipFromOrg(String shipFromOrg) {
        this.shipFromOrg = shipFromOrg;
    }

    public String getShipFromOrg() {
        return shipFromOrg;
    }

    public void setRequestedDate(Date requestedDate) {
        this.requestedDate = requestedDate;
    }

    public Date getRequestedDate() {
        return requestedDate;
    }

    public void setQuantity(BigDecimal quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getQuantity() {
        return quantity;
    }

    public void setSubItemNumber(String subItemNumber) {
        this.subItemNumber = subItemNumber;
    }

    public String getSubItemNumber() {
        return subItemNumber;
    }

    public void setOperatingUnit(BigDecimal operatingUnit) {
        this.operatingUnit = operatingUnit;
    }

    public BigDecimal getOperatingUnit() {
        return operatingUnit;
    }

    public void setShipMethod(String shipMethod) {
        this.shipMethod = shipMethod;
    }

    public String getShipMethod() {
        return shipMethod;
    }
}
