package od.otc.mts;

import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;

//import java.io.PrintWriter;
//import java.io.StringWriter;

/**
 * This class provides for logging messages and errors for this application
 * 
 */

public class MTSLogger {	
	// Logger object
    private static Logger oLogger = Logger.getLogger(MTSLogger.class);

    // Initialize log4j - initialised in MTServer itself
    /*static {
    	try {
    		PropertyConfigurator.configure(MTServer.sLogConfigFile);
    	}
    	catch(Exception oEx) {
    		System.out.println("Error while loading the log4j property file");
    		//System.exit(1);
    	}
    }*/
   	/**
   	 * This method is used to log the string message as information
   	 * 
   	 * @param sMessage
   	 */
    public static void log(String sMessage) {
    	oLogger.info(sMessage);
    }
    
	/**
   	 * This method is used to log the error stack
   	 * 
   	 * @param oThrow
   	 */
    public static void logStackTrace(Throwable oThrow) {
    	
    	oLogger.warn("Error", oThrow);   	
  	
    }
    
    /**
   	 * This method is used to log the string message as errors
   	 * 
   	 * @param sMsg
   	 */  
    public static void logError(String sMsg) {
    	oLogger.error(sMsg);
    }
    
    /**
   	 * This method is used to log the string message as warnings
   	 * 
   	 * @param sMsg
   	 */
    public static void logWarning(String sMsg) {
    	oLogger.warn(sMsg);
    }
    
}	//class
