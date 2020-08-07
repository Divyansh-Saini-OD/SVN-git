package od.oracle.apps.xxcrm.addattr.achcccontrol.cccontrol.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
 /*
  --  Copyright (c) 2015, by Office Depot., All Rights Reserved
  --
  -- Author: Sridevi Kondoju
  -- Component Id: E0255 CR1120
  -- Script Location:
             $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/addattr/achcccontrol/cccontrol/server
  -- Description: 
  -- Package Usage       : 
  -- Name                  Type         Purpose
  -- --------------------  -----------  ------------------------------------------
   -- Notes:
   -- History:
   -- Name            Date         Version    Description
   -- -----           -----        -------    -----------
   -- Sridevi Kondoju 27-MAR-2015  1.0        Initial version
   --
  */
public class ODCCControlVOImpl extends OAViewObjectImpl {
    /**This is the default constructor (do not remove)
     */
    public ODCCControlVOImpl() {
    }
    
    public void initQuery(String custAcctId)
          {
            Number xCustAcctId = new Number(Integer.parseInt(custAcctId));
            this.setWhereClauseParams(null);
          
            this.setWhereClauseParam(0,xCustAcctId);
            this.executeQuery();
          }
}
