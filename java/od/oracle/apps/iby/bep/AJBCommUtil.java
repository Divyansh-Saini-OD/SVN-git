package od.oracle.apps.iby.bep;

import AJBComm.CAFipay;

import AJBComm.CAFipayNetworkException;
import AJBComm.CAFipayTimeoutException;

import java.io.PrintWriter;

import javax.servlet.http.HttpServletResponse;


/**
 * This AJBCommUtil java class contains the requried APIs for calling AJB.
 * @author
 * @version     1.0     14-Sep-2007
 *              1.1     03-Dec-2007
 *              1.2     13-Oct-2008   For Defect 11864 By Anitha.D
 *              1.3     12-Apr-2016   For TLSv1.2 By Avinash B
 **/
public class

AJBCommUtil {

    private String sIP; // IP Address
    private int iPort; // PORT Address
    private String sRequest;
    private HttpServletResponse oResponse;
    private static int TIMEOUT = 60; // Timeout value in sec
    private CAFipay oCAFObj = new CAFipay();


    // Default Constructor

    public AJBCommUtil(String sIP, int iPort, String sRequest,
                       HttpServletResponse oResponse) {
        this.sIP = sIP;
        this.iPort = iPort;
        this.sRequest = sRequest;
        this.oResponse = oResponse;
    }

// Added for the Defect 11864 -- Starting
    public String getAuthAccountValue(String sRequeststr) throws Exception{
        String number = sRequeststr;
        String leftString = "";
        String RightString = "";
        String finalrequestString = "";
        try
        {
        for(int x=0;x<12;x++)
        {
            leftString = leftString + number.substring(0,number.indexOf(",")+1);
            number = number.substring(number.indexOf(",")+1);
        }
        number=number.substring(0,number.indexOf(","));
        RightString = sRequeststr.substring(sRequeststr.indexOf(number)+number.length(),sRequeststr.length());
        int len1 = number.length();
        String ccnumber = number.substring(0,4)+"********"+number.substring((len1 - 4),len1);
        finalrequestString = leftString+ccnumber+RightString;
        }
        catch (Exception oEx) {
             throw new Exception("Exception occured in forming the masked value :" +
                                    oEx.getMessage());
        }
		  return finalrequestString;
}
    // Added for the Defect 11864 -- Ending

    // Calling AJB component

    public String sendAndReceive() throws Exception {

        String sResponse = "";
        PrintWriter oPrintWriter = oResponse.getWriter();
        oPrintWriter.println("Request string - sending to AJB : " + getAuthAccountValue(sRequest));


        try {

            oPrintWriter.println("IP " + sIP);
            oPrintWriter.println("Port " + iPort);
            oPrintWriter.println("Timeout for response is " + TIMEOUT +
                                 " seconds.");
            // Actual AJB method Call
            // Chnages for TLSv1.2
            //sResponse =
             //       oCAFObj.AJB_MSGAPI(TIMEOUT, sIP, iPort, sRequest, "*4INT");

            sResponse =
                    oCAFObj.AJB_MSGAPI(TIMEOUT, sIP, iPort, sRequest, "*FIPAY", "F001099");

        } catch (CAFipayTimeoutException toExc) {
            /*
            System.out.println("Timeout Exception :" + toExc.errorCode + " " +
                               toExc.errorDesc);
            oPrintWriter.println("Timeout Exception :" + toExc.errorCode +
                                 " " + toExc.errorDesc);
                                 */
            throw toExc;
        } catch (CAFipayNetworkException netExc) {
            /*
            System.out.println("Network Exception :" + netExc.errorCode + " " +
                               netExc.errorDesc);
            oPrintWriter.println("Network Exception :" + netExc.errorCode +
                                 " " + netExc.errorDesc);
                            */
            throw netExc;
        } catch (Exception oEx) {
          //  oEx.printStackTrace();
            throw oEx;
        }

        if (sResponse.length() > 0) {
            oPrintWriter.println(" Response from AJB : " + getAuthAccountValue(sResponse));
        } else {
            oPrintWriter.println("ERROR!! No Response recived");
        }

        return sResponse;

    }

}
