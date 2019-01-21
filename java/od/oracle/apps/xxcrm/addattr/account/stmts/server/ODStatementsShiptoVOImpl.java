package od.oracle.apps.xxcrm.addattr.account.stmts.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
 /*
  --  Copyright (c) 2015, by Office Depot., All Rights Reserved
  --
  -- Author: Sridevi Kondoju
  -- Component Id: E0255 CR1120
  -- Script Location:
             $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/addattr/account/stmts/server
  -- Description: 
  -- Package Usage       : 
  -- Name                  Type         Purpose
  -- --------------------  -----------  ------------------------------------------
  -- Notes:
   -- History:
   -- Name            Date         Version    Description
   -- -----           -----        -------    -----------
   -- Sridevi Kondoju 24-June-2015  1.0        Initial version
   --
  */
public class ODStatementsShiptoVOImpl extends OAViewObjectImpl {
    /**This is the default constructor (do not remove)
     */
    public ODStatementsShiptoVOImpl() {
    }
    
    public void initQuery(String custAcctId)
          {
            Number xCustAcctId = new Number(Integer.parseInt(custAcctId));
            this.setWhereClauseParams(null);
          
            this.setWhereClauseParam(0,xCustAcctId);
            this.executeQuery();
          }
}
