package od.otc.mts;

public class WorkerThread implements Runnable {

    private Task oExec = null;
   
    
    public WorkerThread() {
    }

    public void setExecutionObject(Task o) {
        oExec = o;        
        //notify();    
    }
    
    public void run()  {
        /*if(oExec == null) {
            try {
                wait();
            } catch (InterruptedException e) {
                // should not happen 
                //continue;
            }
        } */
    
        try {
            //MTServer.p("worker thread run");        
             oExec.execute();     
        }catch(Exception oEx) {
            oEx.printStackTrace();
        }finally {
            oExec = null;
        }
        
    }
    
}   //class
