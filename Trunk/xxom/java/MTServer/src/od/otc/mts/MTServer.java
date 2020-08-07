package od.otc.mts;

import java.io.*;
import java.net.*;
import java.util.*;

import static java.lang.System.*;

import org.apache.log4j.PropertyConfigurator;
import static od.otc.mts.MTSLogger.*;

import od.otc.mts.config.AppServerConfig;
import od.otc.mts.config.Parent;
import od.otc.mts.config.Worker;

public class MTServer {

    /* context for the app server*/
    /*public static final String sAppServContext="oracle.j2ee.rmi.RMIInitialContextFactory";
    public static final String sAppServProviderURL="ormi://localhost:23791/EJBTest";
    public static final String sAppServPrincipal="oc4jadmin";
    public static final String sAppServCredential="admin135";*/

    private static boolean bRunServer = false;
    private static boolean bServerStarted = false;
    private static int iPort;    
    
    public static String MTSHome = "";
    public static String MTSConfigPath = "";
    public static int iMaxWorkers = 1;
    public static String sLogConfigFile = null; 
    public static Parent oPThreads = null;
    public static Worker oWThreads = null;
    public static AppServerConfig oAppServer = null;

    public static Vector<ParentThread> oParentThreads = new Vector<ParentThread>();
    public static Vector<WorkerThread> oWorkerThreads = new Vector<WorkerThread>();
    public static Vector<Socket> oWaitedRequests = new Vector<Socket>();
    
    private static ServerSocket oServer = null;


    public MTServer() {
        // Add the shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread() {
                    public void run() {
                    if(bServerStarted==false) return;
                    System.out.println("Shuting down MTServer...");
                        log("Shutting down MTServer...");
                        stopServer();
                        shutdownServer();
                    }
                });
    }


    public static void main(String[] sArgs) {

        File oConfigFile = null; 
        new MTServer(); //init so that the shutdown hook will be called
        int iPMinThreads = 0;

        //accept the config file as parameter, validate & take it
        if (sArgs.length < 1) {
            //just out will do as the there is a static import stmt
            out.println("*** Usage: MTServer <path where MTS is installed(MTSHome)> ***");
            exit(1); // Exit the application
        }

        MTSHome = sArgs[0];
        MTSConfigPath = MTSHome + File.separator + "config" ;
        MTSConfigLoader oLoader = null;
        
        try {
            oConfigFile = new File(MTSHome);

            //check if valid directory
            if (!oConfigFile.isDirectory()) {
                out.println("*** The path " + MTSHome + " is not a valid ***");
                exit(1);
            }
            //check if config dir is found
            oConfigFile = new File(MTSConfigPath);
            if (!oConfigFile.isDirectory()) {
                out.println("*** The config path under " + MTSHome + 
                            " is not found. Can't proceed ***");
                exit(1);
            }
            oConfigFile = null;
            sLogConfigFile = MTSConfigPath + File.separator + "log4j.properties";
            
            //init the logger
            try {
                PropertyConfigurator.configure(sLogConfigFile);
            }catch(Exception oEx) {
                log("Error while loading the log4j property file");
                exit(1);
            }
          
            log("Starting the MTServer...");
            log("Loading the MTServer config file from the path " + MTSConfigPath);

            //load the config file
            oLoader = new MTSConfigLoader(MTSConfigPath);
            //get the config values
            iPort = oLoader.getPort();
            oPThreads = oLoader.getParentThread();
            oWThreads = oLoader.getWorkerThread();
            oAppServer = oLoader.getAppServerConfig();
            /*System.out.println("config "+oAppServer.getInitialContext());
            System.out.println("url "+oAppServer.getProviderUrl());
            System.out.println("user "+oAppServer.getUserName());
            System.out.println("pwd "+oAppServer.getPassword());*/
            
        } catch (Exception oEx) {
            out.println("***Error reading MTServer config files. Check the log for details");
            logError("***Error reading MTServer config files. Check the log for details");
            logStackTrace(oEx);
            exit(1);
        }

        log("MTS Config file loaded successfully");
        log("Creating the thread pool...");

        //initialise the thread pool & start the parent threads
        iPMinThreads = oLoader.getMinParent();
        iMaxWorkers = oLoader.getMaxWorker();

        for (int i = 0; i < iPMinThreads; ++i) {
            ParentThread oPT = new ParentThread();
            (new Thread(oPT, "Parent #" + i)).start();
            oParentThreads.addElement(oPT);
        }
        log("Thread pool created");

        /* start worker threads & create a pool */
        //Thread th = null;
        /*for (int i = 0; i < (workers_num*2); ++i) {
            WorkerThread w = new WorkerThread();
            /*th = new Thread(w, "worker #"+i);
            try {
                th.wait();
            }catch(Exception oEx) { }
            workers.addElement(w);
        }*/

        //init the server socket and listen to the port
        try {

            oServer = new ServerSocket(iPort);
            log("MTServer started & listening to Port "+iPort);
            
            bRunServer = true;    
            bServerStarted = true;
            
            while (bRunServer) {

                Socket oClient = oServer.accept();
                ParentThread oPTh = null;
                log("Request received from " + oClient.getInetAddress());

                //find the availale free thread and assign the request
                synchronized (oParentThreads) {
                    for (int iCtr = 0; iCtr < oParentThreads.size(); iCtr++) {
                        if (oParentThreads.elementAt(iCtr).isUsed()) {
                            continue;
                        } else {
                            oPTh = oParentThreads.elementAt(iCtr);
                            oPTh.setSocket(oClient);
                            log("Request assigned to Parent thread #"+iCtr);
                            break;
                        }
                    } //for
                } //sync
                if(oPTh == null) {  //means all threads are busy
                    //synchronized(oWaitedRequests) {
                        oWaitedRequests.add(oClient);
                        log("Request from "+oClient.getInetAddress()+" waited");
                    //}
                }

            } //while

        } catch (Exception oEx) {
            out.println("***Error in MTServer. Check the log for details");
            logError("***Error in MTServer***");
            logStackTrace(oEx);
        }

        System.out.println("Exiting the accept loop...");
        //now close the server socket
        try {
            log("Closing Server socket.");
            oServer.close();
        } catch (Exception oEx) {
            oEx.printStackTrace();
        }
        //graceful shutdown - taken care by shutdown hook
        exit(0);
        
    } //main


    public static void stopServer() {

        if(bRunServer==false) return;
        log("Request to stop the server");
        
        bRunServer = false;
        // send a dummy msg to make the main thread to come out
        // of socket.accept() state. If main thread already closed
        // the socket, ignore the exception
        log("MTServer shutdown initiated");
        try {
        
            Socket oSock = new Socket("localhost",iPort);
            ObjectOutputStream oTempObjOS = new ObjectOutputStream(oSock.getOutputStream());
            oTempObjOS.writeObject("DUMMY");
            oTempObjOS.flush();
            oTempObjOS.close();
            oSock.close();
            return;            

        }catch(Exception oEx) {
            //oEx.printStackTrace();
        }

    }

    /**
     * Request a clean termination of the process 
     * 
     */
    public synchronized void shutdownServer() {
    
        boolean bThreadBusy = true;
        int iThreadCount = oParentThreads.size();
        int iAllowedIdleTime = 100;
        ParentThread oPTh = null;
        stopServer();

        log("Shutting down MTServer...");        
        //check if all the threads have finished their tasks and if so exit
        try {
            while (bThreadBusy) {

                bThreadBusy = false;
                synchronized (oParentThreads) {
                    for (int iCtr = 0; iCtr < iThreadCount; iCtr++) {
                        oPTh = oParentThreads.elementAt(iCtr);
                        if (oPTh.isAlive()) {
                            if (oPTh.isUsed() == false) {
                                oPTh.stopRun();
                                oPTh.notifyThread();
                            } else {
                                bThreadBusy = true;
                            }
                        }
                    }

                } //sync

                Thread.sleep(iAllowedIdleTime);
            } //while
            
            //now close the server socket
            //oServer.close();
            
        } catch (Exception oEx) {
            //oEx.printStackTrace();
        }
        
        log("MTServer stopped (Shutdown hook).");
    }


}   //class MTServer


/*
 //assign a thread to the request
 synchronized (oParentThreads) {
     if (oParentThreads.isEmpty()) {
         oPTh = new ParentThread();
         oPTh.setSocket(oClient);
         (new Thread(oPTh, "additional parent")).start();
     } else {
         oPTh = oParentThreads.elementAt(0);
         oParentThreads.removeElementAt(0);
         oPTh.setSocket(oClient);
     }
 }
*/
