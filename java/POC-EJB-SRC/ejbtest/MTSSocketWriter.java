package ejbtest;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

import java.net.Socket;

public class MTSSocketWriter {

    public MTSSocketWriter() {
    }

    public static Object readWriteObject(String sHost, int iPort, 
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

    } //method

}
