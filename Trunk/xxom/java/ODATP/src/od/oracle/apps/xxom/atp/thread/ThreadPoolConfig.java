/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ThreadPoolConfig.java                                         |
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
 |    This class will be used in ThreadPool.java                             |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/28/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.thread;

/**
 * This class provides the necessary configuration for the Thread Pool
 * It only represents the default configuration to be set. 
 * 
 * @author Satis-Gnanmani
 * @version 1.1
 * 
 */
public class ThreadPoolConfig {

    /**
     * Max size of the thread pool
     * 
     */
    public static final int DEFAULT_MAX_SIXE = 10;

    /**
     * Min size of the thread pool
     * 
     */
    public static final int DEFAULT_MIN_SIZE = 2;

    /**
     * Increment of the thread pool
     * 
     */
    public static final int DEFAULT_INCREMENT_SIZE = 1;

    private int maxSize = DEFAULT_MAX_SIXE;
    private int minSize = DEFAULT_MIN_SIZE;
    private int increment = DEFAULT_INCREMENT_SIZE;


    /**
     * Constructor 
     * 
     */
    public ThreadPoolConfig() {
    }

    /** 
     * Set the Maximum size of the thread pool
     * 
     * @param maxSize
     * 
     */
    public void setMaxSize(int maxSize) {
        this.maxSize = maxSize;
    }

    /**
     * Get the maximum size of the thread pool
     * 
     * @return maxSize maximum size of the thread pool
     * 
     */
    public int getMaxSize() {
        return maxSize;
    }

    /**
     * Set the minimum size of the thread pool
     * 
     * @param minSize minimum size of the thread pool
     * 
     */
    public void setMinSize(int minSize) {
        this.minSize = minSize;
    }

    /**
     * Get the minimum size of the thread pool
     * 
     * @return minSize minimum size of the thread pool
     * 
     */
    public int getMinSize() {
        return minSize;
    }

    /**
     * Set the increment size of the thread pool
     * 
     * @param increment increment size of the thread pool
     * 
     */
    public void setIncrement(int increment) {
        this.increment = increment;
    }

    /**
     * Set the increment size of the thread pool
     * 
     * @return increment increment size of the thread pool
     * 
     */
    public int getIncrement() {
        return increment;
    }
} //End ThreadPoolConfig Class
