/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ThreadPool.java                                               |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This Class manages the thread pool. This class also makes the          |
 |    objects that is being sent to this as Runnable so that a thread        |
 |    created to process it.                                                 |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class object will be used in AtpProcessControl.java                  |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    05/29/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.thread;

import od.oracle.apps.xxom.atp.LogATP;

/**
 * Creates and maitains a ThreadPool for the set of work to be done. Invokes the
 * corresponding workers as per the request arrival.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 */
public class ThreadPool {

    /**
     * Header Information
     * 
     **/
    public static final String RCS_ID = 
        "$Header: ThreadPool.java  05/29/2007 Satis-Gnanmani$";

    private ObjectList idleWorkers;
    private Worker[] workerList;
    private int numberofThreads;
    private int activeThreads = 0;
    private int inactiveThreads = 0;
    private ThreadPoolConfig config = new ThreadPoolConfig();
    private int maxSize = config.getMaxSize();
    private int minSize = config.getMinSize();
    private int incrementSize = config.getIncrement();

    /**
     * Constructor to create a thread pool with numberOfThreads threads
     * 
     * @param numberOfThreads number of threads in the pool
     * 
     **/
    public ThreadPool(int numberOfThreads) {
        if (config.getMaxSize() >= maxSize) {
            numberOfThreads = Math.max(1, numberOfThreads);
            this.numberofThreads = numberOfThreads;
            idleWorkers = new ObjectList(numberOfThreads);
            workerList = new Worker[numberOfThreads];
            for (int i = 0; i < workerList.length; i++) {
                workerList[i] = new Worker(idleWorkers);
            }
            inactiveThreads = numberOfThreads;
        } else {
            System.out.println("Illegal Access to ThreadPool ");
            System.out.println("Illegal Access Description : Attempt to " + 
                               "create Thread Pool greater than Allowed ");
        }
    }

    /**
     * Execute the runnable object target with a priority set to num
     * 
     * @param target runnable object to be processed
     * @throws InterruptedException
     * 
     **/
    public void execute(Runnable target, int num) throws InterruptedException {
        Worker worker = (Worker)idleWorkers.remove();
        worker.process(target);
        worker.setPriority(num);
        activeThreads = activeThreads + 1;
        inactiveThreads = inactiveThreads - 1;
    }

    /**
     * Stop execution / processing of all the idle workers 
     * 
     **/
    public void stopRequestIdleWorkers() {
        try {
            Object[] idle = idleWorkers.removeAll();
            for (int i = 0; i < idle.length; i++) {
                ((Worker)idle[i]).stopRequest();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } finally {
            System.out.println("Idle Workers Stopped");
        }
    }

    /**
     * Stop execution of All the worker threads
     * 
     **/
    public void stopRequestAllWorkers() {

        stopRequestIdleWorkers();
        notifyAll();
        for (int i = 0; i < workerList.length; i++) {
            stopThread(i);
        }
        System.out.println("All Workers Stop");
    }

    /**
     * Synchronization method to join all workers.
     * 
     **/
    public void synchronizeThreads() {
        boolean anyAlive = false;
        for (int i = 0; i < workerList.length; i++) {
            if(workerList[i].isAlive()) {
                anyAlive = true;
                try {
                    workerList[i].waitForRelease();
                } catch (Exception e) {
                    LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
                }
            } else {
            try {
                    workerList[i].notifyThreads();
            } catch (Exception e) {
                LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
            }
            }
        }
    }


    // Yet to be implemented - for future.
    /*  public void synchronizeThreads(boolean stopRequest){
    }*/

    /**
     * Returns the number of active running threads
     * 
     * @return active number of active running threads
     * 
     **/
    public int getActiveThreads() {
        int active = 0;
        for (int i = 0; i < numberofThreads; i++) {
            if (this.workerList[i].isAlive()) {
                active = active + 1;
            }
        }
        return active;
    }

    /**
     * Return the number of inactiveThreads
     * 
     * @return inactive number of inactiveThreads
     * 
     **/
    public int getInactiveThreads() {
        int inactive = 0;
        for (int i = 0; i < numberofThreads; i++) {
            if (!this.workerList[i].isAlive()) {
                inactive = inactive + 1;
            }
        }
        return inactive;
    }

    private void stopThread(int i) {
        if (workerList[i].isAlive()) {
            workerList[i].stopRequest();
        }
    }
} // End ThreadPool Class
