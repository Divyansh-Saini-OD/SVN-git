/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ThreadBarrier.java                                            |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |      Barrier Implementation to synchronize thread execution.              |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/29/2007 Sathish Gnanamani   Initial Creation                        |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.thread;

/**
 * Barrier Implementation to synchronize thread execution.
 * 
 * @author Satis-Gnanmani
 * @version 1.1
 * 
 */
public class ThreadBarrier {
    private int numberOfThreads;
    private InterruptedException _iex;

    /**
     * Provides a default constructor.
     *
     * @param numOfThreads the number of threads to be synchronized by the barrier
     * 
     **/
    public ThreadBarrier(int numOfThreads) {
        numberOfThreads = numOfThreads;

    }

    /**
     * An array of objects.
     *
     * @param barrierCount number of barriers to return
     * @param threadCount number of threads to be supported by each barrier
     * @return an array of objects
     * 
     **/
    public static ThreadBarrier[] getBarriers(int barrierCount, 
                                              int threadCount) {
        ThreadBarrier[] result = null;
        result = new ThreadBarrier[barrierCount];

        // instantiate barriers
        for (int i = 0; i < barrierCount; i++) {
            result[i] = new ThreadBarrier(threadCount);

        }
        return result;
    }

    /**
     * Provides a mechanism for a thread to wait for the last thread to arrive.
     *
     * @throws InterruptedException - if a waiting thread is interrupted
     * 
     **/
    public synchronized int waitForRest() throws InterruptedException {
        int threadNum = --numberOfThreads;
        if (_iex != null)
            throw _iex;
        if (numberOfThreads <= 0) {
            notifyAll();
            return threadNum;
        }
        while (numberOfThreads > 0) {
            if (_iex != null)
                throw _iex;
            try {
                wait();
            } catch (InterruptedException ex) {
                _iex = ex;
                notifyAll();
            }
        }
        return threadNum;
    }

    /**
     * Generates an interruption on all threads.
     * 
     **/
    public synchronized void freeAll() {
        _iex = new InterruptedException("Barrier Released by freeAll");
        notifyAll();

    }

    /**
     * Set the Number of Threads of the Barrier
     * 
     * @param numberOfThreads number of threads to set
     * 
     **/
    public void setNumberOfThreads(int numberOfThreads) {
        this.numberOfThreads = numberOfThreads;
    }

    /**
     * Get the number Of Threads
     * 
     * @return numberOfThreads of this ThreadBarrier
     * 
     **/
    public int getNumberOfThreads() {
        return numberOfThreads;
    }
} // End ThreadBarrier Class
