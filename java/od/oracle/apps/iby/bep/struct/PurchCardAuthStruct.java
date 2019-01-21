package od.oracle.apps.iby.bep.struct;



 /**
  * This PurchCardAuthStruct java class contains only the additional request 
  * parameters for the purchase auth from ipayment and it's accessor methods
  * @author     
  * @version     1.0
  * @date        14-Sep-2007
  **/
  

public class PurchCardAuthStruct extends AuthStruct {

    // Additional Field for Purchasecardauth Request

    private String CommCard;
    private String PONum;
    private String TaxAmount;
    private String ShipToZip;
    private String ShipFromZip;

    // Default Constructor

    public PurchCardAuthStruct() {
    }

    // Generating Accessors for above fields

    public void setCommCard(String commCard) {
        this.CommCard = commCard;
    }

    public String getCommCard() {
        return CommCard;
    }

    public void setPONum(String pONum) {
        this.PONum = pONum;
    }

    public String getPONum() {
        return PONum;
    }

    public void setTaxAmount(String taxAmount) {
        this.TaxAmount = taxAmount;
    }

    public String getTaxAmount() {
        return TaxAmount;
    }

    public void setShipToZip(String shipToZip) {
        this.ShipToZip = shipToZip;
    }

    public String getShipToZip() {
        return ShipToZip;
    }

    public void setShipFromZip(String shipFromZip) {
        this.ShipFromZip = shipFromZip;
    }

    public String getShipFromZip() {
        return ShipFromZip;
    }

} 
