/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             AtpWorker.java                                                |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This Class is the actual work that would be done by the Theard pool    |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class object will be used in ThreadPool.java               |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    05/29/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.thread;


/**
 * The indivial worker spawns a thread and process the jobs - runnables 
 * as it is executed.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 */
public class Worker {

    /**
     * Header Information
     */
    public static final String RCS_ID = 
        "$Header: Worker.java  06/29/2007 Satis-Gnanmani$";

    /**
     * Work started status Pointer
     */
    public static final int WORK_STARTED = 0;

    /**
     * Work Complete status pointer
     */
    public static final int WORK_DONE = 1;

    private static int nextWorkerID = 0;
    private ObjectList idleWorkers;
    private int workerID;
    private ObjectList handoffBox;
    private Thread internalThread;
    private volatile boolean noStopRequested;
    private boolean[] status;
    private ThreadPool parent;

    /**
     * Constructor to invoke the worker thread within the given list of idle
     * workers available to do work
     * 
     * @param idleWorkers Arrya list of the idle workers
     * 
     */
    public Worker(ObjectList idleWorkers) {
        this.idleWorkers = idleWorkers;

        workerID = getNextWorkerID();
        handoffBox = new ObjectList(1);
        noStopRequested = true;
        Runnable r = new Runnable() {
                public void run() {
                    try {
                        runWork();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            };
        internalThread = new Thread(r);
        internalThread.start();
        status = new boolean[2];
    }

    /**
     * Run method of this Worker
     * 
     */
    public void run() {
        try {
            runWork();
        } catch (Exception x) {
            x.printStackTrace();
        }
    }

    /**
     * Returns the next worker Id
     * 
     * @return id next worker id
     * 
     */
    public static synchronized int getNextWorkerID() {
        int id = nextWorkerID;
        nextWorkerID++;
        return id;
    }

    /**
     * Processes the given Runnable target
     * 
     * @param target runnable object to be processed
     * @throws InterruptedException 
     * 
     */
    public void process(Runnable target) throws InterruptedException {
        handoffBox.add(target);
    }

    /**
     * Stop the processing of the current thread
     * 
     */
    public void stopRequest() {
        System.out.println("workerID=" + workerID + 
                           ", stopRequest() received.");
        noStopRequested = false;
        internalThread.interrupt();
    }

    /**
     * Returns if the thread is Alive, Thread.isAlice()
     * 
     * @return internalThread.isAlive()
     * 
     */
    public boolean isAlive() {
        return internalThread.isAlive();
    }

    /**
     * Set the priority of the thread
     * 
     * @param num priority value to set
     * 
     */
    public void setPriority(int num) {
        internalThread.setPriority(num);
    }

    /**
     * Notify the parent thread
     * 
     * @throws InterruptedException
     * 
     */
    public void notifyThreads() throws InterruptedException {
        synchronized (this) {
            internalThread.notify();
        }
    }

    /**
     * Wait for the other threads to complete execution
     * 
     */
    public void waitForRelease() {
        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            System.out.println("Interrupted Exception while waiting for other Threads.");
            e.printStackTrace();
        }
    }

    /**
     * Returns the completion status of the worker
     * 
     * @return status if work completed
     * 
     */
    public boolean isDone() {
        return status[WORK_DONE];
    }

    /**
     * Returns the Start status of the worker
     * 
     * @return status if work started.
     */
    public boolean isStarted() {
        return status[WORK_STARTED];
    }


    private void runWork() {
        while (noStopRequested) {
            try {
                idleWorkers.add(this);
                Runnable r = (Runnable)handoffBox.remove();
                System.out.println("workerID=" + workerID + 
                                   ", starting execution of new Runnable: " + 
                                   r);
                runIt(r);
            } catch (InterruptedException x) {
                Thread.currentThread().interrupt();
            }
        }
    }

    private void runIt(Runnable r) {
        try {
            synchronized (r) {
                status[WORK_STARTED] = true;
                status[WORK_DONE] = false;
            }
            r.run();
        } catch (Exception runex) {
            System.err.println("Uncaught exception fell through from run()");
            runex.printStackTrace();
        } finally {
            try {
                idleWorkers.add(this);
                status[WORK_DONE] = true;
            } catch (InterruptedException e) {
                System.out.println("Interrupted Exception : " + 
                                   e.getMessage());
            }
            Thread.interrupted();
        }
    }
}// End Worker Class
