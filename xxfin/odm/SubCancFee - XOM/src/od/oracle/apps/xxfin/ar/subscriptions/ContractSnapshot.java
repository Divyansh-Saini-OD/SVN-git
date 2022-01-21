/**
 * 
 */
package od.oracle.apps.xxfin.ar.subscriptions;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * This class models a Contract Snapshot at any point of time
 * to facilitate calculating the cancellation fee at Line level.
 *
 * A contract can have start-date, end-date, service-type-code, 
 * total-contract-line-amount, bulling-frequency, number-of-Payments-Made
 * Payment-Type, Unpaid-Balance, Vendor-Number, and Sku-Number
 * 
 * With the Billing-Frequency, contract line start-date and end-date,
 * it computes the line duration and number of periods.
 * Based on the above, it calculates the Cancellation Fee.
 * 
 */
public class ContractSnapshot {

	private String terminationFeeFlag;
	private String strContractStartDate;
	private String strContractEndDate;	
	private String serviceTypeCode;
	private double totalContractLineAmount;
	private double lineAmount;
	private String billingFrequency;
	private double numberOfPmtsMade;
	private double numberOfPmtsMissed;
	private String paymentType;
	private String vendorNumber;
	private String skuNumber;	

	/**
	 * @return The TerminationFeeFlag.
	 */
	public String getTerminationFeeFlag() {
		return terminationFeeFlag;
	}
	/**
	 * Sets the terminationFeeFlag.
	 * @param terminationFeeFlag.
	 */	
	public void setTerminationFeeFlag(String terminationFeeFlag) {
		this.terminationFeeFlag = terminationFeeFlag;
	}
	/**
	 * @return The StrContractStartDate.
	 */	
	public String getStrContractStartDate() {
		return strContractStartDate;
	}
	/**
	 * Sets the strContractStartDate.
	 * @param strContractStartDate.
	 */		
	public void setStrContractStartDate(String strContractStartDate) {
		this.strContractStartDate = strContractStartDate;
	}
	/**
	 * @return The StrContractEndDate.
	 */		
	public String getStrContractEndDate() {
		return strContractEndDate;
	}
	/**
	 * Sets the strContractEndDate.
	 * @param strContractEndDate.
	 */		
	public void setStrContractEndDate(String strContractEndDate) {
		this.strContractEndDate = strContractEndDate;
	}	
	/**
	 * @return The serviceTypeCode.
	 */		
	public String getServiceTypeCode() {
		return serviceTypeCode;
	}
	/**
	 * Sets the serviceTypeCode.
	 * @param serviceTypeCode.
	 */		
	public void setServiceTypeCode(String serviceTypeCode) {
		this.serviceTypeCode = serviceTypeCode;
	}
	/**
	 * @return The totalContractLineAmount.
	 */		
    public double getTotalContractLineAmount() {
		return totalContractLineAmount;
	}
	/**
	 * Sets the totalContractLineAmount.
	 * @param totalContractLineAmount.
	 */	    
	public void setTotalContractLineAmount(double totalContractLineAmount) {
		this.totalContractLineAmount = totalContractLineAmount;
	}
	public double getLineAmount() {
		return lineAmount;
	}
	public void setLineAmount(double lineAmount) {
		this.lineAmount = lineAmount;
	}
	/**
	 * @return The billingFrequency.
	 */		
	public String getBillingFrequency() {
		return billingFrequency;
	}
	/**
	 * Sets the billingFrequency.
	 * @param billingFrequency.
	 */	 	
	public void setBillingFrequency(String billingFrequency) {
		this.billingFrequency = billingFrequency;
	}    
	/**
	 * @return The numberOfPmtsMade.
	 */		
	public double getNumberOfPmtsMade() {
		return numberOfPmtsMade;
	}
	/**
	 * Sets the numberOfPmtsMade.
	 * @param numberOfPmtsMade.
	 */	 	
	public void setNumberOfPmtsMade(double numberOfPmtsMade) {
		this.numberOfPmtsMade = numberOfPmtsMade;
	}
	public double getNumberOfPmtsMissed() {
		return numberOfPmtsMissed;
	}
	public void setNumberOfPmtsMissed(double numberOfPmtsMissed) {
		this.numberOfPmtsMissed = numberOfPmtsMissed;
	}
	/**
	 * @return The paymentType.
	 */		
	public String getPaymentType() {
		return paymentType;
	}
	/**
	 * Sets the paymentType.
	 * @param paymentType.
	 */		
	public void setPaymentType(String paymentType) {
		this.paymentType = paymentType;
	}
	/**
	 * @return The vendorNumber.
	 */		
	public String getVendorNumber() {
		return vendorNumber;
	}
	/**
	 * Sets the vendorNumber.
	 * @param vendorNumber.
	 */		
	public void setVendorNumber(String vendorNumber) {
		this.vendorNumber = vendorNumber;
	}
	/**
	 * @return The skuNumber.
	 */		
	public String getSkuNumber() {
		return skuNumber;
	}
	/**
	 * Sets the skuNumber.
	 * @param skuNumber.
	 */		
	public void setSkuNumber(String skuNumber) {
		this.skuNumber = skuNumber;
	}	
	/**
	 * @return The unpaidBalance.
	 */		
	public double getUnpaidBalance() {		

		double unpaidBalance2 = 0;

		unpaidBalance2 = getLineAmount() * getNumberOfPmtsMissed();

		return unpaidBalance2;
	}
	/**
	 * @return The remaining un-billed periods by calculating the 
	 * number of periods from the contract line start and end dates
	 * and the number of payments made.
	 */		
	public double getRemainingUnbilledPeriods() {
		//Elastic does not have history of initial payment. So, adding one payment extra
		return getCalculatedNumberOfPeriods() - 
				(getNumberOfPmtsMade()+1+getNumberOfPmtsMissed());
	}
	/**
	 * @return The StrContractStartDate.
	 */		
    public double daysBetween(Date d1, Date d2){
    	//subtracting time returns milli-seconds. To get days-from 1000 seconds,minutes,days
        return ( (d2.getTime() - d1.getTime()) / (1000 * 60 * 60 * 24));
    } 
	/**
	 * @return The number of periods from the contract line start and end dates.
	 */	    
    public double getCalculatedNumberOfPeriods() {

        double calculatedNumberOfPeriods = 1.0;
        double numberOfDaysInAPeriod = 30.0;
        
		Calendar cal1 = new GregorianCalendar();
	    Calendar cal2 = new GregorianCalendar();
	    Date sDate = null;
	    Date eDate = null;

	    SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy");
		try {
	      sDate= sdf.parse(strContractStartDate);

	      cal1.setTime(sDate);
	     
	      eDate= sdf.parse(strContractEndDate);

	      cal2.setTime(eDate);	
	     	      
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}	        
        
        if ( "MON".equalsIgnoreCase(getBillingFrequency())) {
        	numberOfDaysInAPeriod = 30.0;
        	
        	//int diffYear = cal2.get(Calendar.YEAR) - cal1.get(Calendar.YEAR);

        	//int diffMonth = diffYear * 12 + cal2.get(Calendar.MONTH) - cal1.get(Calendar.MONTH);
        	
        	//calculatedNumberOfPeriods = (double)diffMonth;
        	
        	calculatedNumberOfPeriods = getTotalContractDurationDays()/numberOfDaysInAPeriod;
        	
        } else if ("QTR".equalsIgnoreCase(getBillingFrequency())){
            numberOfDaysInAPeriod = 90.0;        	
            calculatedNumberOfPeriods = getTotalContractDurationDays()/numberOfDaysInAPeriod;	
        } else if ("YR".equalsIgnoreCase(getBillingFrequency())){
        	numberOfDaysInAPeriod = 365.0;     
        	calculatedNumberOfPeriods = getTotalContractDurationDays()/numberOfDaysInAPeriod;
        }       
        
    	return (double)(int)Math.round(calculatedNumberOfPeriods);
    }
	/**
	 * @return The number of periods from the contract line start and end dates.
	 */	    
    public double getActualNumberOfPeriods() {

        double calculatedNumberOfPeriods = 1.0;
        double numberOfDaysInAPeriod = 30.0;
        
		Calendar cal1 = new GregorianCalendar();
	    Calendar cal2 = new GregorianCalendar();
	    Date sDate = null;

	    SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy");
		try {
	      sDate= sdf.parse(strContractStartDate);

	      cal1.setTime(sDate);
	     
	      cal2.setTime(new Date());	
	     	      
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}	        
        
        if ( "MON".equalsIgnoreCase(getBillingFrequency())) {
        	numberOfDaysInAPeriod = 30.0;
        	
        	int diffYear = cal2.get(Calendar.YEAR) - cal1.get(Calendar.YEAR);

        	int diffMonth = diffYear * 12 + cal2.get(Calendar.MONTH) - cal1.get(Calendar.MONTH);
        	
        	calculatedNumberOfPeriods = (double)diffMonth;
        	
        } else if ("QTR".equalsIgnoreCase(getBillingFrequency())){
            numberOfDaysInAPeriod = 90.0;        	
            calculatedNumberOfPeriods = getTotalContractDurationDays()/numberOfDaysInAPeriod;	
        } else if ("YR".equalsIgnoreCase(getBillingFrequency())){
        	numberOfDaysInAPeriod = 365.0;     
        	calculatedNumberOfPeriods = getTotalContractDurationDays()/numberOfDaysInAPeriod;
        }       
        
    	return (double)(int)Math.round(calculatedNumberOfPeriods);
    }
	/**
	 * @return The total contract lines duration days from the contract line start date
	 * and contract line end date.
	 */	    
	public double getTotalContractDurationDays() {
		
		Calendar cal1 = new GregorianCalendar();
	    Calendar cal2 = new GregorianCalendar();
	    
	    double daysBetween = 1.0;

	    SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy");
		try {
	      Date sDate= sdf.parse(strContractStartDate);

	      cal1.setTime(sDate);
	     
	      Date eDate= sdf.parse(strContractEndDate);

	      cal2.setTime(eDate);	
	     
	      daysBetween = daysBetween(cal1.getTime(),cal2.getTime());
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}				
		return daysBetween;
	}    
	/**
	 * @return The total contract lines duration days from the contract line start date
	 * and sysdate.
	 */	
	public double getContractDurationDays() {
		
		Calendar cal1 = new GregorianCalendar();
	    Calendar cal2 = new GregorianCalendar();
	    
	    double durationDays = 1.0;
        try{
	     SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy");

	     Date date = sdf.parse(strContractStartDate);

	     cal1.setTime(date);

	     cal2.setTime(new Date());		
		 
	     durationDays = (double)(int)daysBetween(cal1.getTime(),cal2.getTime());
	     
		 } catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		 }	     
		 return durationDays;
	}  	
	
	public double numberOfDaysInAPeriod(){
        double numberOfDaysInAPeriod = 30.0;
        
        if ( "MON".equalsIgnoreCase(getBillingFrequency())) {
        	numberOfDaysInAPeriod = 30.0;
        } else if ("QTR".equalsIgnoreCase(getBillingFrequency())){
            numberOfDaysInAPeriod = 90.0;        		
        } else if ("YR".equalsIgnoreCase(getBillingFrequency())){
        	numberOfDaysInAPeriod = 365.0;        		
        }
		
        return numberOfDaysInAPeriod;
	}
	public static void main (String args[]){
      System.out.println("Args--");		
	  System.out.println("terminationFeeFlag: " + args[0]);
	  System.out.println("strContractStartDate: " + args[1]);
	  System.out.println("strContractEndDate: " + args[2]);
	  System.out.println("serviceTypeCode: " + args[3]);
	  System.out.println("totalContractLineAmount: " + args[4]);
	  System.out.println("lineAmount: " + args[5]);
	  System.out.println("billingFrequency: " + args[6]);
	  System.out.println("numberOfPmtsMade: " + args[7]);
	  System.out.println("numberOfPmtsMissed: " + args[8]);
	  System.out.println("paymentType: " + args[9]);
	  System.out.println("vendorNumber: " + args[10]);
	  System.out.println("skuNumber: " + args[11]);
	  
	  ContractSnapshot contractSnapshot = new ContractSnapshot();
	  
	  contractSnapshot.setTerminationFeeFlag(args[0]);
	  contractSnapshot.setStrContractStartDate(args[1]);
	  contractSnapshot.setStrContractEndDate(args[2]);
	  contractSnapshot.setServiceTypeCode(args[3]);
	  contractSnapshot.setTotalContractLineAmount(Double.parseDouble(args[4]));
	  contractSnapshot.setLineAmount(Double.parseDouble(args[5]));
	  contractSnapshot.setBillingFrequency(args[6]);
	  contractSnapshot.setNumberOfPmtsMade(Integer.parseInt(args[7]));
	  contractSnapshot.setNumberOfPmtsMissed(Integer.parseInt(args[8]));
	  contractSnapshot.setPaymentType(args[9]);
	  contractSnapshot.setVendorNumber(args[10]);
	  contractSnapshot.setSkuNumber(args[11]);
	  
	  System.out.println("getContractDurationDays: " + contractSnapshot.getContractDurationDays());
	  System.out.println("getTotalContractDurationDays: " + contractSnapshot.getTotalContractDurationDays());
	  System.out.println("getCalculatedNumberOfPeriods: " + contractSnapshot.getCalculatedNumberOfPeriods());
	  System.out.println("getActualNumberOfPeriods: " + contractSnapshot.getActualNumberOfPeriods());
	  System.out.println("getRemainingUnbilledPeriods: " + contractSnapshot.getRemainingUnbilledPeriods());
	  System.out.println("missedPayments: " + contractSnapshot.getNumberOfPmtsMissed());
	  System.out.println("getUnpaidBalance: " + contractSnapshot.getUnpaidBalance());
      double part1 = 0.0;
      double part2 = 0.0;
	  double cancellationFee = (((double)contractSnapshot.getTotalContractLineAmount()/contractSnapshot.getCalculatedNumberOfPeriods())*(((double)contractSnapshot.getRemainingUnbilledPeriods()/2)))+contractSnapshot.getUnpaidBalance();
	  part1 = ((double)contractSnapshot.getTotalContractLineAmount()/contractSnapshot.getCalculatedNumberOfPeriods());
	  System.out.println("part1: " + part1);
	  part2 = ((double)contractSnapshot.getRemainingUnbilledPeriods()/2);
	  System.out.println("part2: " + part2);
	  double part3 = 0.0;
	  System.out.println("part3: " + contractSnapshot.getUnpaidBalance());
	  System.out.println("total: " + (double)part1 * part2 + part3);
	  System.out.println("CancellationFee: " + cancellationFee);

	}
}
