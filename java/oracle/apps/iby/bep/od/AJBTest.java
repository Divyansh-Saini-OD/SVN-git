//package AJBComm;

import AJBComm.*;
import AJBComm.CAFipayNetworkException;
import AJBComm.CAFipayTimeoutException;


public class AJBTest {

    public AJBTest() {
    }

    public static void main(String[] args) {


		String sIP = "10.95.206.87";
        int iPort = 26306;
        String sTestStr = "100,,,,20,Credit,,001099,55,Sale,,,5444009999222205,1312,,200,13841,,,,,,,,,,,,,,,,,ARI_6770,,,,,,,,,,,,,,,,12132007,100815,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,";
		int TIMEOUT = 30;
        
        try {
            
            CAFipay oCAFObj = new CAFipay();
            String sResponse = "";
            

            System.out.println("IP " + sIP);
            System.out.println("Port " + iPort);
            System.out.println("Msg " + sTestStr);
            System.out.println("Timeout for response is " + TIMEOUT + " seconds.");


            //send receive 
            System.out.println("sending msg to AJB...");
			System.out.println("Request String : " + sTestStr);
            sResponse = oCAFObj.AJB_MSGAPI(TIMEOUT, sIP, iPort,sTestStr,"*4INT");
            System.out.println("response from ajb "+sResponse);
    
        }catch (CAFipayTimeoutException toExc) {
                System.out.println("Timeout Exception :" + toExc.errorCode + 
                                   " " + toExc.errorDesc);
                
            } catch (CAFipayNetworkException netExc) {
                System.out.println("Network Exception :" + netExc.errorCode + 
                                   " " + netExc.errorDesc);
                
            }catch(Exception oEx) {
			System.out.println("Error Message : " + oEx.getMessage());
			oEx.printStackTrace();
        }


    }
    
}
