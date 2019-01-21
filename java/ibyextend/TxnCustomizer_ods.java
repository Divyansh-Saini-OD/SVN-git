package ibyextend;
import java.sql.*;
import java.util.Hashtable;
import java.util.Enumeration;
import java.util.Set;
import java.util.Iterator;
import oracle.apps.iby.extend.TxnCustomizer;
import oracle.apps.iby.util.AddOnlyHashtable;
import oracle.apps.iby.util.ReadOnlyHashtable;
import oracle.apps.iby.exception.PSException;

public class TxnCustomizer_ods implements TxnCustomizer
{

  static final String RESPONSE_CALL="BEGIN xx_iby_settlement_pkg.process_cc_processor_response(p_payment_system_order_number => ?, p_transaction_id => ?, p_instrument_sub_type => ?, p_auth_code => ?, p_status => ?, p_ret_code_value => ?, p_ps2000_value => ?); END;"; 

  public void preTxn(String bep, Connection dbconn, AddOnlyHashtable inputs) throws PSException
  { 
  }

  public void postTxn(String bep, Connection dbconn, ReadOnlyHashtable outputs) throws PSException
  { 
    String authOnlyTrxnType = new String("2");
    String trxnType         = (String)outputs.get("OapfTrxnType");
    String orderId          = (String)outputs.get("OapfOrderId");
    String transactionId    = (String)outputs.get("OapfTransactionId");
    String instrType        = (String)outputs.get("OapfPmtInstrType");
    String authCode         = (String)outputs.get("OapfAuthcode");
    String status           = (String)outputs.get("OapfStatus");
    String oDRetCode        = (String)outputs.get("OapfODRetCode");
    String oDPS2000         = (String)outputs.get("OapfODPS2000");
   
    try
    {
      
      if (authOnlyTrxnType.equals(trxnType)                  &&
          orderId       != null && !orderId.equals("")       &&
          transactionId != null && !transactionId.equals("") &&
          status        != null && !status.equals("")        &&
          authCode      != null && 
          instrType     != null &&
          oDRetCode     != null && 
          oDPS2000      != null)
      {
        PreparedStatement stmnt=dbconn.prepareStatement(RESPONSE_CALL);

        // p_payment_system_order_number
        stmnt.setString(1, orderId);

        // p_transaction_id
        stmnt.setString(2, transactionId);

        // p_instrument_sub_type
        stmnt.setString(3, instrType);

        // p_auth_code
        stmnt.setString(4, authCode);

        // p_status
        stmnt.setString(5, status);

        // p_ret_code_value
        stmnt.setString(6, oDRetCode);

        // p_ps2000_value 
        stmnt.setString(7, oDPS2000);

        stmnt.executeUpdate();
        dbconn.commit();
        stmnt.close();

        // !! do not close the database connection !!
      }
    }
    catch (SQLException sqle)
    { 
      throw new PSException("IBY_0005",sqle.getMessage(),false); 
    }
  }
}
