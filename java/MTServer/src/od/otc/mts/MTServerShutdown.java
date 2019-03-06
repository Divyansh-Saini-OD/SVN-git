package od.otc.mts;

import java.io.File;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

import java.net.Socket;
import static java.lang.System.*;

public class MTServerShutdown {

    public MTServerShutdown() {
    }

    public static void main(String[] sArgs) {
    
        try {
            //accept the config file as parameter, validate & take it
            if (sArgs.length < 1) {
                //just out will do as the there is a static import stmt
                out.println("*** Usage: MTServer <path where MTS is installed(MTSHome)> ***");
                exit(1); // Exit the application
            }
            
            String sConfFile = sArgs[0];
            MTSConfigLoader oLoader = new MTSConfigLoader(sConfFile+File.separator+"config");
                        
            Object oReturnObj = readWriteObject("localhost",oLoader.getPort(),"STOP");
            if(oReturnObj instanceof String) {
                System.out.println((String)oReturnObj);
            }
        }catch(Exception oEx) {
            System.out.println("***MTServer is not running***");
            oEx.printStackTrace();
        }
    }
    
    private static Object readWriteObject(String sHost, int iPort, 
                                         Object oObj) throws IOException, 
                                                             Exception {

        Socket oSocket = null;
        ObjectInputStream oObjIn = null;
        ObjectOutputStream oObjOut = null;
        Object oReturnObj = null;

        try {
            //create the socket
            oSocket = new Socket(sHost, iPort);

            //wait for 3min. If no reply for 3min it will throw Excep
            oSocket.setSoTimeout(180000);
            oSocket.setTcpNoDelay(true);

            java.io.InputStream is = oSocket.getInputStream();
            java.io.OutputStream os = oSocket.getOutputStream();

            //write the object
            oObjOut = new ObjectOutputStream(os);
            oObjOut.writeObject(oObj);
            oObjOut.flush();

            //read the response object and return
            oObjIn = new ObjectInputStream(is);
            oReturnObj = oObjIn.readObject();

            //close the socket
            oSocket.close();

            return oReturnObj;

        } catch (IOException oIOEx) {
            throw oIOEx;
        } catch (Exception oGenEx) {
            throw oGenEx;
        }
    }
    
}   //class
