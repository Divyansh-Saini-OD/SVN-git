package od.otc.mts;

import java.io.*;

import java.net.*;

import java.text.SimpleDateFormat;

import java.util.*;


public class ParentThread implements Runnable {

    private Socket oReqSocket = null;
    private boolean bRunThread = true;
    private boolean bInUse = false;
    private boolean bIsAlive = false;
    
    private SimpleDateFormat oSDF = 
        new SimpleDateFormat("dd/MM/yyyy hh:mm:ss a");

    public ParentThread() {
    }


    public synchronized void setSocket(Socket oSock) {
        oReqSocket = oSock;
        notify();
        //run();
    }

    public boolean isUsed() {
        return bInUse;
    }

    /**
     *Issues a stop request to this object
     */
    public void stopRun() {
        bRunThread = false;
    }

    /**
     *<p>This returns whether this thread is active
     *@return boolean
     */
    public boolean isAlive() {
        return bIsAlive;
    }

    /**
     * notifyThread Method.
     * Notifies the thread to wake up from idle state
     */
    synchronized void notifyThread() {
        notify();
    }

    public synchronized void run() {

        bIsAlive = true;
        while (bRunThread) {
            if (oReqSocket == null) { //nothing to do 
                try {
                    wait();
                } catch (InterruptedException e) {
                    continue; //should not happen 
                }
            }
            try {
                System.out.println("Request recd at " + 
                                   oSDF.format(new java.util.Date()));
                bInUse = true;
                handleClient();
                if (oReqSocket != null)
                    oReqSocket.close(); //close the socket
                System.out.println("Request serviced at " + 
                                   oSDF.format(new java.util.Date()));
                bInUse = false;
            } catch (Exception e) {
                e.printStackTrace();
                bInUse = false;
            }
            oReqSocket = null;
            //check if any request is waiting and if so assign this thread to it
            synchronized (MTServer.oWaitedRequests) {
                Socket oWaitSocket = null;
                if (MTServer.oWaitedRequests.size() > 0) {
                    oWaitSocket = MTServer.oWaitedRequests.elementAt(0);
                    MTServer.oWaitedRequests.remove(0);
                    bInUse = true;
                    setSocket(oWaitSocket);
                }
            } //sync

        } //while

        bInUse = false;
        bIsAlive = false;

    } //run

    private void handleClient() throws IOException {

        if (oReqSocket == null)
            return;

        ObjectInputStream oInStream = 
            new ObjectInputStream(oReqSocket.getInputStream());
        ObjectOutputStream oOutStream = 
            new ObjectOutputStream(oReqSocket.getOutputStream());

        int iThreadNumbers = 0;
        int iMethodCallCount = 0;
        int iParamValueCount = 0;

        MTSRequestLoader oReqLoader = null;
        ArrayList<EJBCallStruct> oEJBArr = null;
        Task[] oTasks = null;
        Thread[] oWThread = null;

        //WorkerThread oWTh = null;
        Object oWriteObj = null;
        //EJBCallStruct oCallStruct = null;
        Vector oReturnObject = null;

        try {

            Object oData = null;
            if (oInStream != null && !oReqSocket.isClosed()) {
                oData = oInStream.readObject();
            } else {
                return;
            }

            if (oData instanceof String) {

                String sReq = (String)oData;

                if (sReq.equalsIgnoreCase("STOP")) {

                    String sShutdownMsg = "MTServer shutdown initiated...\r\n";

                    MTServer.stopServer();

                    sShutdownMsg += "MTServer shutdown complete";
                    oWriteObj = sShutdownMsg;
                    oOutStream.writeObject(oWriteObj);
                    oOutStream.flush();

                    oReqSocket.close();
                    return;

                } else if (sReq.equalsIgnoreCase("DUMMY")) {
                    //ignore this message
                    try {
                        oReqSocket.close();
                    } catch (Exception oEx) {
                        //ignore exception
                    }
                } else { //we take this as the request XML and process it
                
                    try {
                        //process the xml, get the request details
                        oReqLoader = new MTSRequestLoader(sReq);
                        oEJBArr = oReqLoader.getEJBCallStructures();

                        //spawn worker threads, collate results & return

                        //get the methodcall count
                        iMethodCallCount = oEJBArr.size();
                        //get the max param value count
                        iParamValueCount = oReqLoader.getMaxParamValue();

                        if (iMethodCallCount == 1 && 
                            iParamValueCount > iMethodCallCount) {
                            iThreadNumbers = iParamValueCount;
                        } else {
                            iThreadNumbers = iMethodCallCount;
                        }

                        oTasks = new Task[iThreadNumbers];
                        oWThread = new Thread[iThreadNumbers];
System.out.println("thread numbers***********"+iThreadNumbers);

                        if(iThreadNumbers > MTServer.iMaxWorkers) {
System.out.println("less workers than req***********"+MTServer.iMaxWorkers);
                            //split the processing into batches
                            Vector oVec = new Vector();
                            oReturnObject = new Vector();

                            for(int iStartFrom=0;iStartFrom<iThreadNumbers;iStartFrom+=MTServer.iMaxWorkers) {
                                oVec=executeRequestsInThread(iStartFrom,
                                                        MTServer.iMaxWorkers,
                                                        iParamValueCount,
                                                        iMethodCallCount,
                                                        oEJBArr);
                                //build the return vector with the above return vector
                                if(oVec == null) {
                                    System.out.println("return obj null");
                                } else {
                                    for(Object obj: oVec) {
                                        oReturnObject.add(obj);
                                    }
                                }
                            }

                        } else {
                                oReturnObject=executeRequestsInThread(0,iThreadNumbers,iParamValueCount,iMethodCallCount,oEJBArr);
                        }
                        oWriteObj = oReturnObject;
                        

                    } catch (Exception oEx) {
                        oEx.printStackTrace();
                    }

                } //req xml processing 

            } else { //not a string obj

                oWriteObj = 
                        new String("MTServer expects a XML that conforms to MTSRequest.xsd schema");
            }

            //write the object on to the socket
            if (oWriteObj != null) {
                oOutStream.writeObject(oWriteObj);
                oOutStream.flush();
            }
            //oReqSocket.close();

        } catch (Exception oEx) {
            oEx.printStackTrace();
        }

    } //handleclient  

    /*private boolean putInThread(Task oTask, Thread oThread, String sWid) throws Exception {
        
        //Task[] oTasks = null;
        //Thread[] oWThread = null;
        WorkerThread oWTh = null;
        
        try {

            //set the task to worker thread
            oWTh = new WorkerThread();
            oWTh.setExecutionObject(oTask);
            //start the worker thread
            oThread = new Thread(oWTh, sWid) ;
            oThread.start();
            
            return true;
            

        } catch (Exception oEx) {
            throw oEx;
        }
        
        
    }   //putinthread */

     private Vector executeRequestsInThread(int iStartFrom, 
                                            int iThreadNumbers,
                                            int iParamValueCount,
                                            int iMethodCallCount,
                                            ArrayList<EJBCallStruct> oEJBArr) {
                                            
        Vector oReturnObject = null;
        Task[] oTasks = null;
        Thread[] oWThread = null;

        WorkerThread oWTh = null;
        //Object oWriteObj = null;
        EJBCallStruct oCallStruct = null;
 
        oTasks = new Task[iThreadNumbers];
        oWThread = new Thread[iThreadNumbers];
        
        int iMethodStart = 0;
        int iMethodEnd = 0;
        int iParamStart = 0;
        int iParamEnd = 0;
        
        if(iMethodCallCount==1) {
            iMethodStart = 0;
            iMethodEnd = 1;
            iParamStart = iStartFrom;
        } else {
            iMethodStart = iStartFrom;
            iParamStart = 0;
            if(iMethodCallCount > iThreadNumbers) {
                iMethodEnd = iMethodStart+iThreadNumbers;
                if(iMethodEnd > iMethodCallCount) {
                    iMethodEnd = iMethodCallCount;
                }
            } else {
                iMethodEnd = iMethodCallCount;
            }
        }
         int iTaskCtr = 0;

        try {

            for (int iCtr = iMethodStart; iCtr < iMethodEnd; iCtr++) {
            
                oCallStruct = oEJBArr.get(iCtr);
                
                //if MethodCallCount==1 and more param values
                if (oCallStruct.getParamVal().size() > 0 && (iMethodCallCount==1)) {

                    if(oCallStruct.getParamVal().size() > iThreadNumbers) {
                        iParamEnd = iParamStart+iThreadNumbers;
                        if(iParamEnd > oCallStruct.getParamVal().size()) {
                            iParamEnd = oCallStruct.getParamVal().size();
                        }
                    } else {
                        iParamEnd = oCallStruct.getParamVal().size();    
                    }

                    for (int iPV = iParamStart; iPV < iParamEnd;iPV++) {

                        oTasks[iTaskCtr] = 
                                new EJBInvoker(oCallStruct.getJNDIName(), 
                                               oCallStruct.getMethodName(), 
                                               oCallStruct.getParamType(), 
                                               oCallStruct.getParamVal().get(iPV));
                        //set the task to worker thread
                        oWTh = new WorkerThread();
                        oWTh.setExecutionObject(oTasks[iTaskCtr]);
                        //start the worker thread
                        oWThread[iTaskCtr] = 
                                new Thread(oWTh, "worker " + iPV);
                        oWThread[iTaskCtr].start();
                        iTaskCtr++;
                        
                    } //for
                } else if (iMethodCallCount > 1) {

                    oTasks[iTaskCtr] = 
                            new EJBInvoker(oCallStruct.getJNDIName(), 
                                           oCallStruct.getMethodName(), 
                                           oCallStruct.getParamType(), 
                                           oCallStruct.getParamVal());
                    //set the task to worker thread
                    oWTh = new WorkerThread();
                    oWTh.setExecutionObject(oTasks[iTaskCtr]);
                    //start the worker thread
                    oWThread[iTaskCtr] = 
                            new Thread(oWTh, "worker " + iTaskCtr);
                    oWThread[iTaskCtr].start();
                    iTaskCtr++;
                    
                } else {
                    oTasks[iTaskCtr] = 
                            new EJBInvoker(oCallStruct.getJNDIName(), 
                                           oCallStruct.getMethodName(), 
                                           oCallStruct.getParamType(), 
                                           new Object[0]);
                    //set the task to worker thread
                    oWTh = new WorkerThread();
                    oWTh.setExecutionObject(oTasks[iTaskCtr]);
                    //start the worker thread
                    oWThread[iTaskCtr] = 
                            new Thread(oWTh, "worker " + iTaskCtr);
                    oWThread[iTaskCtr].start();
                    iTaskCtr++;
                }


            } //for

            //wait for completion    
            for (int iCtr = 0; iCtr < iThreadNumbers; iCtr++) {
                if(oWThread[iCtr]==null) continue;
                oWThread[iCtr].join();
            }

            //collate the objects to be sent back and form an Vector
            oReturnObject = new Vector();
            Vector oRetVector = new Vector();
            
            for (int iCtr = 0; iCtr < iThreadNumbers; iCtr++) {
            
                if(oTasks[iCtr]==null) continue;
                if (oTasks[iCtr].getReturnObject() instanceof Vector) {
                    System.out.println("vector inside vector");
                    oRetVector = 
                            (Vector)oTasks[iCtr].getReturnObject();
                    for (Object obj: oRetVector) {
                        oReturnObject.add(obj);
                    }

                } else {
                    System.out.println("***********return str "+(String)oTasks[iCtr].getReturnObject());                             
                    oReturnObject.add(oTasks[iCtr].getReturnObject());
                }
            }
            System.out.println("ret obj size " + 
                               oReturnObject.size());

            
    } catch (Exception oEx) {
        oEx.printStackTrace();
    }
        
         return oReturnObject;
         
     }  //execreq
     
     
}   //class
