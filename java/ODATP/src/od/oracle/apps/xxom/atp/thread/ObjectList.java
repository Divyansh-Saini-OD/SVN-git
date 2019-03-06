/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ObjectList.java                                               |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This class implements the First In First Out Object Queue              |
 |    This class will be used for pooling the resources, eg Thread           |
 |    Thread Pooling                                                         |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class will be called from Worker.java and                         |
 |    ThreadPool.java                                                        |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    05/29/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.thread;

/**
 * Object List type implement an list object with First In First Out stategy
 * to execute the worklist.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 */
public class ObjectList {

    public static final String RCS_ID = 
        "$Header: ObjectFIFO.java  05/29/2007 Satis-Gnanmani$";

    /**
     * Provides a default constructor.
     *
     **/
    public ObjectList() {
    }
    private Object[] queue;
    private int capacity;
    private int size;
    private int head;
    private int tail;

    /**
     * Constructor to initialize with the capacity of the list.
     * 
     * @param cap
     * 
     */
    public ObjectList(int cap) {
        capacity = (cap > 0) ? cap : 1;
        queue = new Object[capacity];
        head = 0;
        tail = 0;
        size = 0;
    }

    /**
     * Returns the capacity of the Object List
     * 
     * @return capacity capacity of the list
     * 
     */
    public int getCapacity() {
        return capacity;
    }

    /**
     * Returns the Size of the ObjectList
     * 
     * @return size Size of the objectlist
     * 
     */
    public synchronized int getSize() {
        return size;
    }

    /**
     * Determine if the object is empty
     * 
     * @return
     */
    public synchronized boolean isEmpty() {
        return (size == 0);
    }

    /**
     * Determine if the object is full
     * 
     * @return
     * 
     */
    public synchronized boolean isFull() {
        return (size == capacity);
    }

    /**
     * Add an object to the object List
     * 
     * @param obj Object to be added
     * @throws InterruptedException
     * 
     */
    public synchronized void add(Object obj) throws InterruptedException {

        waitWhileFull();

        queue[head] = obj;
        head = (head + 1) % capacity;
        size++;

        notifyAll();
    }

    /**
     * Add a list of Objects to the list
     * 
     * @param list List of Objects
     * @throws InterruptedException
     * 
     */
    public synchronized void addEach(Object[] list) throws InterruptedException {

        for (int i = 0; i < list.length; i++) {
            add(list[i]);
        }
    }

    /**
     * Remove an Object from the list FIFO.
     * 
     * @return obj the removed object
     * @throws InterruptedException
     * 
     */
    public synchronized Object remove() throws InterruptedException {

        waitWhileEmpty();
        Object obj = queue[tail];
        queue[tail] = null;
        tail = (tail + 1) % capacity;
        size--;
        notifyAll();
        return obj;
    }

    /**
     * Remove all the objects from the ObjectList
     * 
     * @return list the List of objects removed
     * @throws InterruptedException
     * 
     */
    public synchronized Object[] removeAll() throws InterruptedException {

        Object[] list = new Object[size];
        for (int i = 0; i < list.length; i++) {
            list[i] = remove();
        }
        return list;
    }

    /**
     * Remove objects from the List
     * 
     * @return objects list removed from the List
     * @throws InterruptedException
     * 
     */
    public synchronized Object[] removeAtLeastOne() throws InterruptedException {

        waitWhileEmpty();
        return removeAll();
    }

    /**
     * Method to Wait until the ObjectList is Empty
     * 
     * @param msTimeout Timeout for the wait
     * @return boolean
     * @throws InterruptedException
     * 
     */
    public synchronized boolean waitUntilEmpty(long msTimeout) throws InterruptedException {

        if (msTimeout == 0L) {
            waitUntilEmpty(); // use other method
            return true;
        }
        long endTime = System.currentTimeMillis() + msTimeout;
        long msRemaining = msTimeout;
        while (!isEmpty() && (msRemaining > 0L)) {
            wait(msRemaining);
            msRemaining = endTime - System.currentTimeMillis();
        }
        return isEmpty();
    }

    /**
     * Method to Wait until the ObjectList is Empty
     * 
     * @throws InterruptedException
     * 
     */
    public synchronized void waitUntilEmpty() throws InterruptedException {

        while (!isEmpty()) {
            wait();
        }
    }

    /**
     * Method to Wait while the ObjectList is Empty
     * 
     * @throws InterruptedException
     * 
     */
    public synchronized void waitWhileEmpty() throws InterruptedException {

        while (isEmpty()) {
            wait();
        }
    }

    /**
     * Method to Wait until the ObjectList is Full
     * 
     * @throws InterruptedException
     * 
     */
    public synchronized void waitUntilFull() throws InterruptedException {

        while (!isFull()) {
            wait();
        }
    }

    /**
     * Method to Wait while the ObjectList is Full
     * 
     * @throws InterruptedException
     * 
     */
    public synchronized void waitWhileFull() throws InterruptedException {

        while (isFull()) {
            wait();
        }
    }
}// End ObjectList Class
