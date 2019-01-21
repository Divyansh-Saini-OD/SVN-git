SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE package body XX_CDH_CUST_ACCT_SITE_EXTW_PKG
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_CDH_CUST_ACCT_SITE_EXTW_PKG                                          |
-- | Description: This package is the Wrapper for  XX_CDH_CUST_ACCT_SITE_EXT_PKG          |
-- |                                                .                                     |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version     Date         Author               Remarks                                 |
-- |=======   ===========  ==================   ==========================================|
-- |DRAFT 1A  17-MAR-2010   Mangala               Initial draft version                   |
-- |                                                                                      |
-- |======================================================================================|                         
-- | Subversion Info:                                                                     |
-- | $HeadURL$                                                                          |
-- | $Rev$                                                                              |
-- | $Date$                                                                             |
-- |                                                                                      |
-- +======================================================================================+
AS

-- +==================================================================================+
-- | Name             : INSERT_ROW                                                    |
-- | Description      : This procedure shall insert data into XX_CDH_ACCT_SITE_EXT_B  |
-- |                    and XX_CDH_ACCT_SITE_EXT_TL tables.                           |
-- |                                                                                  |
-- +==================================================================================+

procedure INSERT_ROW (
  x_rowid             IN OUT NOCOPY VARCHAR2,
  x_return_status     OUT VARCHAR2,
  p_extension_id      IN NUMBER,
  p_cust_acct_site_id IN NUMBER,
  p_attr_group_id     IN NUMBER,
  p_c_ext_attr1       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr2       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr3       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr4       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr5       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr6       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr7       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr8       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr9       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr10      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr11      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr12      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr13      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr14      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr15      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr16      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr17      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr18      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr19      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr20      IN VARCHAR2 DEFAULT NULL,
  p_n_ext_attr1       IN NUMBER DEFAULT NULL,
  p_n_ext_attr2       IN NUMBER DEFAULT NULL,
  p_n_ext_attr3       IN NUMBER DEFAULT NULL,
  p_n_ext_attr4       IN NUMBER DEFAULT NULL,
  p_n_ext_attr5       IN NUMBER DEFAULT NULL,
  p_n_ext_attr6       IN NUMBER DEFAULT NULL,
  p_n_ext_attr7       IN NUMBER DEFAULT NULL,
  p_n_ext_attr8       IN NUMBER DEFAULT NULL,
  p_n_ext_attr9       IN NUMBER DEFAULT NULL,
  p_n_ext_attr10      IN NUMBER DEFAULT NULL,
  p_n_ext_attr11      IN NUMBER DEFAULT NULL,
  p_n_ext_attr12      IN NUMBER DEFAULT NULL,
  p_n_ext_attr13      IN NUMBER DEFAULT NULL,
  p_n_ext_attr14      IN NUMBER DEFAULT NULL,
  p_n_ext_attr15      IN NUMBER DEFAULT NULL,
  p_n_ext_attr16      IN NUMBER DEFAULT NULL,
  p_n_ext_attr17      IN NUMBER DEFAULT NULL,
  p_n_ext_attr18      IN NUMBER DEFAULT NULL,
  p_n_ext_attr19      IN NUMBER DEFAULT NULL,
  p_n_ext_attr20      IN NUMBER DEFAULT NULL,
  p_d_ext_attr1       IN DATE DEFAULT NULL,
  p_d_ext_attr2       IN DATE DEFAULT NULL,
  p_d_ext_attr3       IN DATE DEFAULT NULL,
  p_d_ext_attr4       IN DATE DEFAULT NULL,
  p_d_ext_attr5       IN DATE DEFAULT NULL,
  p_d_ext_attr6       IN DATE DEFAULT NULL,
  p_d_ext_attr7       IN DATE DEFAULT NULL,
  p_d_ext_attr8       IN DATE DEFAULT NULL,
  p_d_ext_attr9       IN DATE DEFAULT NULL,
  p_d_ext_attr10      IN DATE DEFAULT NULL,
  p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL,
  p_creation_date     IN DATE DEFAULT SYSDATE,
  p_created_by        IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
  p_last_update_date  IN DATE DEFAULT SYSDATE,
  p_last_updated_by   IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
  p_last_update_login IN NUMBER DEFAULT FND_GLOBAL.USER_ID  
  ) 
  
  IS
  
BEGIN

        XX_CDH_CUST_ACCT_SITE_EXT_PKG.INSERT_ROW(x_rowid             
                                                 ,p_extension_id      
                                                 ,p_cust_acct_site_id 
                                                 ,p_attr_group_id     
                                                 ,p_c_ext_attr1       
                                                 ,p_c_ext_attr2       
                                                 ,p_c_ext_attr3       
                                                 ,p_c_ext_attr4       
                                                 ,p_c_ext_attr5       
                                                 ,p_c_ext_attr6       
                                                 ,p_c_ext_attr7       
                                                 ,p_c_ext_attr8       
                                                 ,p_c_ext_attr9       
                                                 ,p_c_ext_attr10      
                                                 ,p_c_ext_attr11      
                                                 ,p_c_ext_attr12      
                                                 ,p_c_ext_attr13      
                                                 ,p_c_ext_attr14      
                                                 ,p_c_ext_attr15      
                                                 ,p_c_ext_attr16      
                                                 ,p_c_ext_attr17      
                                                 ,p_c_ext_attr18      
                                                 ,p_c_ext_attr19      
                                                 ,p_c_ext_attr20      
                                                 ,p_n_ext_attr1       
                                                 ,p_n_ext_attr2       
                                                 ,p_n_ext_attr3       
                                                 ,p_n_ext_attr4       
                                                 ,p_n_ext_attr5       
                                                 ,p_n_ext_attr6       
                                                 ,p_n_ext_attr7       
                                                 ,p_n_ext_attr8       
                                                 ,p_n_ext_attr9       
                                                 ,p_n_ext_attr10      
                                                 ,p_n_ext_attr11      
                                                 ,p_n_ext_attr12      
                                                 ,p_n_ext_attr13      
                                                 ,p_n_ext_attr14      
                                                 ,p_n_ext_attr15      
                                                 ,p_n_ext_attr16      
                                                 ,p_n_ext_attr17      
                                                 ,p_n_ext_attr18      
                                                 ,p_n_ext_attr19      
                                                 ,p_n_ext_attr20      
                                                 ,p_d_ext_attr1       
                                                 ,p_d_ext_attr2       
                                                 ,p_d_ext_attr3       
                                                 ,p_d_ext_attr4       
                                                 ,p_d_ext_attr5       
                                                 ,p_d_ext_attr6       
                                                 ,p_d_ext_attr7       
                                                 ,p_d_ext_attr8       
                                                 ,p_d_ext_attr9       
                                                 ,p_d_ext_attr10      
                                                 ,p_tl_ext_attr1      
                                                 ,p_tl_ext_attr2      
                                                 ,p_tl_ext_attr3      
                                                 ,p_tl_ext_attr4      
                                                 ,p_tl_ext_attr5      
                                                 ,p_tl_ext_attr6      
                                                 ,p_tl_ext_attr7      
                                                 ,p_tl_ext_attr8      
                                                 ,p_tl_ext_attr9      
                                                 ,p_tl_ext_attr10     
                                                 ,p_tl_ext_attr11     
                                                 ,p_tl_ext_attr12     
                                                 ,p_tl_ext_attr13     
                                                 ,p_tl_ext_attr14     
                                                 ,p_tl_ext_attr15     
                                                 ,p_tl_ext_attr16     
                                                 ,p_tl_ext_attr17     
                                                 ,p_tl_ext_attr18     
                                                 ,p_tl_ext_attr19     
                                                 ,p_tl_ext_attr20     
                                                 ,p_creation_date     
                                                 ,p_created_by        
                                                 ,p_last_update_date  
                                                 ,p_last_updated_by   
                                                 ,p_last_update_login 
                                                 );                  

-- Call VALIDATE_DUPLICATE_ROW for performing the Validation

            VALIDATE_DUPLICATE_ROW (x_ret_status    => x_return_status
                                   ,p_cust_doc_id   => p_n_ext_attr1
                                    ,p_from_site     => p_cust_acct_site_id);
Exception 
when others then
  Raise;
 
end INSERT_ROW;

-- +==============================================================================+
-- | Name             : LOCK_ROW                                                  |
-- | Description      : This procedure shall lock rows into XX_CDH_ACCT_SITE_EXT_B    |
-- |                    and XX_CDH_ACCT_SITE_EXT_TL tables.                           |
-- |                                                                              |
-- |                                                                              |
-- +==============================================================================+

procedure LOCK_ROW (
  p_extension_id      IN NUMBER,
  p_cust_acct_site_id IN NUMBER,
  p_attr_group_id     IN NUMBER,
  p_c_ext_attr1       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr2       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr3       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr4       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr5       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr6       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr7       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr8       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr9       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr10      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr11      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr12      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr13      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr14      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr15      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr16      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr17      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr18      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr19      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr20      IN VARCHAR2 DEFAULT NULL,
  p_n_ext_attr1       IN NUMBER DEFAULT NULL,
  p_n_ext_attr2       IN NUMBER DEFAULT NULL,
  p_n_ext_attr3       IN NUMBER DEFAULT NULL,
  p_n_ext_attr4       IN NUMBER DEFAULT NULL,
  p_n_ext_attr5       IN NUMBER DEFAULT NULL,
  p_n_ext_attr6       IN NUMBER DEFAULT NULL,
  p_n_ext_attr7       IN NUMBER DEFAULT NULL,
  p_n_ext_attr8       IN NUMBER DEFAULT NULL,
  p_n_ext_attr9       IN NUMBER DEFAULT NULL,
  p_n_ext_attr10      IN NUMBER DEFAULT NULL,
  p_n_ext_attr11      IN NUMBER DEFAULT NULL,
  p_n_ext_attr12      IN NUMBER DEFAULT NULL,
  p_n_ext_attr13      IN NUMBER DEFAULT NULL,
  p_n_ext_attr14      IN NUMBER DEFAULT NULL,
  p_n_ext_attr15      IN NUMBER DEFAULT NULL,
  p_n_ext_attr16      IN NUMBER DEFAULT NULL,
  p_n_ext_attr17      IN NUMBER DEFAULT NULL,
  p_n_ext_attr18      IN NUMBER DEFAULT NULL,
  p_n_ext_attr19      IN NUMBER DEFAULT NULL,
  p_n_ext_attr20      IN NUMBER DEFAULT NULL,
  p_d_ext_attr1       IN DATE DEFAULT NULL,
  p_d_ext_attr2       IN DATE DEFAULT NULL,
  p_d_ext_attr3       IN DATE DEFAULT NULL,
  p_d_ext_attr4       IN DATE DEFAULT NULL,
  p_d_ext_attr5       IN DATE DEFAULT NULL,
  p_d_ext_attr6       IN DATE DEFAULT NULL,
  p_d_ext_attr7       IN DATE DEFAULT NULL,
  p_d_ext_attr8       IN DATE DEFAULT NULL,
  p_d_ext_attr9       IN DATE DEFAULT NULL,
  p_d_ext_attr10      IN DATE DEFAULT NULL,
  p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL
  )
 is
 BEGIN
        XX_CDH_CUST_ACCT_SITE_EXT_PKG.LOCK_ROW(         p_extension_id     
                                                        ,p_cust_acct_site_id
                                                        ,p_attr_group_id    
                                                        ,p_c_ext_attr1      
                                                        ,p_c_ext_attr2      
                                                        ,p_c_ext_attr3      
                                                        ,p_c_ext_attr4      
                                                        ,p_c_ext_attr5      
                                                        ,p_c_ext_attr6      
                                                        ,p_c_ext_attr7      
                                                        ,p_c_ext_attr8      
                                                        ,p_c_ext_attr9      
                                                        ,p_c_ext_attr10     
                                                        ,p_c_ext_attr11     
                                                        ,p_c_ext_attr12     
                                                        ,p_c_ext_attr13     
                                                        ,p_c_ext_attr14     
                                                        ,p_c_ext_attr15     
                                                        ,p_c_ext_attr16     
                                                        ,p_c_ext_attr17     
                                                        ,p_c_ext_attr18     
                                                        ,p_c_ext_attr19     
                                                        ,p_c_ext_attr20     
                                                        ,p_n_ext_attr1      
                                                        ,p_n_ext_attr2      
                                                        ,p_n_ext_attr3      
                                                        ,p_n_ext_attr4      
                                                        ,p_n_ext_attr5      
                                                        ,p_n_ext_attr6      
                                                        ,p_n_ext_attr7      
                                                        ,p_n_ext_attr8      
                                                        ,p_n_ext_attr9      
                                                        ,p_n_ext_attr10     
                                                        ,p_n_ext_attr11     
                                                        ,p_n_ext_attr12     
                                                        ,p_n_ext_attr13     
                                                        ,p_n_ext_attr14     
                                                        ,p_n_ext_attr15     
                                                        ,p_n_ext_attr16     
                                                        ,p_n_ext_attr17     
                                                        ,p_n_ext_attr18     
                                                        ,p_n_ext_attr19     
                                                        ,p_n_ext_attr20     
                                                        ,p_d_ext_attr1      
                                                        ,p_d_ext_attr2      
                                                        ,p_d_ext_attr3      
                                                        ,p_d_ext_attr4      
                                                        ,p_d_ext_attr5      
                                                        ,p_d_ext_attr6      
                                                        ,p_d_ext_attr7      
                                                        ,p_d_ext_attr8      
                                                        ,p_d_ext_attr9      
                                                        ,p_d_ext_attr10     
                                                        ,p_tl_ext_attr1     
                                                        ,p_tl_ext_attr2     
                                                        ,p_tl_ext_attr3     
                                                        ,p_tl_ext_attr4     
                                                        ,p_tl_ext_attr5     
                                                        ,p_tl_ext_attr6     
                                                        ,p_tl_ext_attr7     
                                                        ,p_tl_ext_attr8     
                                                        ,p_tl_ext_attr9     
                                                        ,p_tl_ext_attr10    
                                                        ,p_tl_ext_attr11    
                                                        ,p_tl_ext_attr12    
                                                        ,p_tl_ext_attr13    
                                                        ,p_tl_ext_attr14    
                                                        ,p_tl_ext_attr15    
                                                        ,p_tl_ext_attr16    
                                                        ,p_tl_ext_attr17    
                                                        ,p_tl_ext_attr18    
                                                        ,p_tl_ext_attr19    
                                                        ,p_tl_ext_attr20 );


Exception 
when others then
  Raise;

 END LOCK_ROW;

-- +==============================================================================+
-- | Name             : UPDATE_ROW                                                |
-- | Description      : This procedure shall update data into XX_CDH_ACCT_SITE_EXT_B  |
-- |                    and XX_CDH_ACCT_SITE_EXT_TL tables.                           |
-- |                                                                              |
-- +==============================================================================+
procedure UPDATE_ROW (
  x_return_status     OUT VARCHAR2,
  p_extension_id      IN NUMBER,
  p_cust_acct_site_id IN NUMBER,
  p_attr_group_id     IN NUMBER,
  p_c_ext_attr1       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr2       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr3       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr4       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr5       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr6       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr7       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr8       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr9       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr10      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr11      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr12      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr13      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr14      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr15      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr16      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr17      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr18      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr19      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr20      IN VARCHAR2 DEFAULT NULL,
  p_n_ext_attr1       IN NUMBER DEFAULT NULL,
  p_n_ext_attr2       IN NUMBER DEFAULT NULL,
  p_n_ext_attr3       IN NUMBER DEFAULT NULL,
  p_n_ext_attr4       IN NUMBER DEFAULT NULL,
  p_n_ext_attr5       IN NUMBER DEFAULT NULL,
  p_n_ext_attr6       IN NUMBER DEFAULT NULL,
  p_n_ext_attr7       IN NUMBER DEFAULT NULL,
  p_n_ext_attr8       IN NUMBER DEFAULT NULL,
  p_n_ext_attr9       IN NUMBER DEFAULT NULL,
  p_n_ext_attr10      IN NUMBER DEFAULT NULL,
  p_n_ext_attr11      IN NUMBER DEFAULT NULL,
  p_n_ext_attr12      IN NUMBER DEFAULT NULL,
  p_n_ext_attr13      IN NUMBER DEFAULT NULL,
  p_n_ext_attr14      IN NUMBER DEFAULT NULL,
  p_n_ext_attr15      IN NUMBER DEFAULT NULL,
  p_n_ext_attr16      IN NUMBER DEFAULT NULL,
  p_n_ext_attr17      IN NUMBER DEFAULT NULL,
  p_n_ext_attr18      IN NUMBER DEFAULT NULL,
  p_n_ext_attr19      IN NUMBER DEFAULT NULL,
  p_n_ext_attr20      IN NUMBER DEFAULT NULL,
  p_d_ext_attr1       IN DATE DEFAULT NULL,
  p_d_ext_attr2       IN DATE DEFAULT NULL,
  p_d_ext_attr3       IN DATE DEFAULT NULL,
  p_d_ext_attr4       IN DATE DEFAULT NULL,
  p_d_ext_attr5       IN DATE DEFAULT NULL,
  p_d_ext_attr6       IN DATE DEFAULT NULL,
  p_d_ext_attr7       IN DATE DEFAULT NULL,
  p_d_ext_attr8       IN DATE DEFAULT NULL,
  p_d_ext_attr9       IN DATE DEFAULT NULL,
  p_d_ext_attr10      IN DATE DEFAULT NULL,
  p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL,
  p_last_update_date  IN DATE DEFAULT SYSDATE,
  p_last_updated_by   IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
  p_last_update_login IN NUMBER DEFAULT FND_GLOBAL.USER_ID
  )
  IS

 BEGIN
        XX_CDH_CUST_ACCT_SITE_EXT_PKG.UPDATE_ROW(         p_extension_id      
                                                         ,p_cust_acct_site_id 
                                                         ,p_attr_group_id     
                                                         ,p_c_ext_attr1       
                                                         ,p_c_ext_attr2       
                                                         ,p_c_ext_attr3       
                                                         ,p_c_ext_attr4       
                                                         ,p_c_ext_attr5       
                                                         ,p_c_ext_attr6       
                                                         ,p_c_ext_attr7       
                                                         ,p_c_ext_attr8       
                                                         ,p_c_ext_attr9       
                                                         ,p_c_ext_attr10      
                                                         ,p_c_ext_attr11      
                                                         ,p_c_ext_attr12      
                                                         ,p_c_ext_attr13      
                                                         ,p_c_ext_attr14      
                                                         ,p_c_ext_attr15      
                                                         ,p_c_ext_attr16      
                                                         ,p_c_ext_attr17      
                                                         ,p_c_ext_attr18      
                                                         ,p_c_ext_attr19      
                                                         ,p_c_ext_attr20      
                                                         ,p_n_ext_attr1       
                                                         ,p_n_ext_attr2       
                                                         ,p_n_ext_attr3       
                                                         ,p_n_ext_attr4       
                                                         ,p_n_ext_attr5       
                                                         ,p_n_ext_attr6       
                                                         ,p_n_ext_attr7       
                                                         ,p_n_ext_attr8       
                                                         ,p_n_ext_attr9       
                                                         ,p_n_ext_attr10      
                                                         ,p_n_ext_attr11      
                                                         ,p_n_ext_attr12      
                                                         ,p_n_ext_attr13      
                                                         ,p_n_ext_attr14      
                                                         ,p_n_ext_attr15      
                                                         ,p_n_ext_attr16      
                                                         ,p_n_ext_attr17      
                                                         ,p_n_ext_attr18      
                                                         ,p_n_ext_attr19      
                                                         ,p_n_ext_attr20      
                                                         ,p_d_ext_attr1       
                                                         ,p_d_ext_attr2       
                                                         ,p_d_ext_attr3       
                                                         ,p_d_ext_attr4       
                                                         ,p_d_ext_attr5       
                                                         ,p_d_ext_attr6       
                                                         ,p_d_ext_attr7       
                                                         ,p_d_ext_attr8       
                                                         ,p_d_ext_attr9       
                                                         ,p_d_ext_attr10      
                                                         ,p_tl_ext_attr1      
                                                         ,p_tl_ext_attr2      
                                                         ,p_tl_ext_attr3      
                                                         ,p_tl_ext_attr4      
                                                         ,p_tl_ext_attr5      
                                                         ,p_tl_ext_attr6      
                                                         ,p_tl_ext_attr7      
                                                         ,p_tl_ext_attr8      
                                                         ,p_tl_ext_attr9      
                                                         ,p_tl_ext_attr10     
                                                         ,p_tl_ext_attr11     
                                                         ,p_tl_ext_attr12     
                                                         ,p_tl_ext_attr13     
                                                         ,p_tl_ext_attr14     
                                                         ,p_tl_ext_attr15     
                                                         ,p_tl_ext_attr16     
                                                         ,p_tl_ext_attr17     
                                                         ,p_tl_ext_attr18     
                                                         ,p_tl_ext_attr19     
                                                         ,p_tl_ext_attr20     
                                                         ,p_last_update_date  
                                                         ,p_last_updated_by   
                                                         ,p_last_update_login );



-- Call VALIDATE_DUPLICATE_ROW for performing the Validation

            VALIDATE_DUPLICATE_ROW ( x_ret_status    => x_return_status
                                    ,p_cust_doc_id   => p_n_ext_attr1
                                     ,p_from_site     => p_cust_acct_site_id);
            

Exception 
when others then
  Raise;
  
END UPDATE_ROW;

-- +==============================================================================+
-- | Name             : DELETE_ROW                                                |
-- | Description      : This procedure shall delete data  in XX_CDH_ACCT_SITE_EXT_B   |
-- |                    XX_CDH_ACCT_SITE_EXT_TL table for the given extension id.     |
-- |                                                                              |
-- +==============================================================================+

procedure DELETE_ROW (
  p_extension_id  IN NUMBER)
  
  IS
  
 BEGIN
        XX_CDH_CUST_ACCT_SITE_EXT_PKG.DELETE_ROW (p_extension_id);
        
  
 END DELETE_ROW;

-- +==============================================================================+
-- | Name             : ADD_LANGUAGE                                              |
-- | Description      : This procedure shall insert and update data  in           |
-- |                    XX_CDH_ACCT_SITE_EXT_TL table.                                |
-- |                                                                              |
-- +==============================================================================+

procedure ADD_LANGUAGE
IS

BEGIN
        XX_CDH_CUST_ACCT_SITE_EXT_PKG.ADD_LANGUAGE();
        
end ADD_LANGUAGE;


-- +==============================================================================+
-- | Name             : LOAD_ROW                                                  |
-- | Description      : This procedure is not being implemented.                  |
-- |                                                                              |
-- |                                                                              |
-- +==============================================================================+

procedure LOAD_ROW(
  p_extension_id      IN NUMBER,
  p_cust_acct_site_id IN NUMBER,
  p_attr_group_id     IN NUMBER,
  p_c_ext_attr1       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr2       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr3       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr4       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr5       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr6       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr7       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr8       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr9       IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr10      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr11      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr12      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr13      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr14      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr15      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr16      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr17      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr18      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr19      IN VARCHAR2 DEFAULT NULL,
  p_c_ext_attr20      IN VARCHAR2 DEFAULT NULL,
  p_n_ext_attr1       IN NUMBER DEFAULT NULL,
  p_n_ext_attr2       IN NUMBER DEFAULT NULL,
  p_n_ext_attr3       IN NUMBER DEFAULT NULL,
  p_n_ext_attr4       IN NUMBER DEFAULT NULL,
  p_n_ext_attr5       IN NUMBER DEFAULT NULL,
  p_n_ext_attr6       IN NUMBER DEFAULT NULL,
  p_n_ext_attr7       IN NUMBER DEFAULT NULL,
  p_n_ext_attr8       IN NUMBER DEFAULT NULL,
  p_n_ext_attr9       IN NUMBER DEFAULT NULL,
  p_n_ext_attr10      IN NUMBER DEFAULT NULL,
  p_n_ext_attr11      IN NUMBER DEFAULT NULL,
  p_n_ext_attr12      IN NUMBER DEFAULT NULL,
  p_n_ext_attr13      IN NUMBER DEFAULT NULL,
  p_n_ext_attr14      IN NUMBER DEFAULT NULL,
  p_n_ext_attr15      IN NUMBER DEFAULT NULL,
  p_n_ext_attr16      IN NUMBER DEFAULT NULL,
  p_n_ext_attr17      IN NUMBER DEFAULT NULL,
  p_n_ext_attr18      IN NUMBER DEFAULT NULL,
  p_n_ext_attr19      IN NUMBER DEFAULT NULL,
  p_n_ext_attr20      IN NUMBER DEFAULT NULL,
  p_d_ext_attr1       IN DATE DEFAULT NULL,
  p_d_ext_attr2       IN DATE DEFAULT NULL,
  p_d_ext_attr3       IN DATE DEFAULT NULL,
  p_d_ext_attr4       IN DATE DEFAULT NULL,
  p_d_ext_attr5       IN DATE DEFAULT NULL,
  p_d_ext_attr6       IN DATE DEFAULT NULL,
  p_d_ext_attr7       IN DATE DEFAULT NULL,
  p_d_ext_attr8       IN DATE DEFAULT NULL,
  p_d_ext_attr9       IN DATE DEFAULT NULL,
  p_d_ext_attr10      IN DATE DEFAULT NULL,
  p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL,
  p_owner              IN VARCHAR2 DEFAULT NULL
  )
 IS

 BEGIN

                XX_CDH_CUST_ACCT_SITE_EXT_PKG.LOAD_ROW(p_extension_id      
                                                       ,p_cust_acct_site_id 
                                                       ,p_attr_group_id     
                                                       ,p_c_ext_attr1       
                                                       ,p_c_ext_attr2       
                                                       ,p_c_ext_attr3       
                                                       ,p_c_ext_attr4       
                                                       ,p_c_ext_attr5       
                                                       ,p_c_ext_attr6       
                                                       ,p_c_ext_attr7       
                                                       ,p_c_ext_attr8       
                                                       ,p_c_ext_attr9       
                                                       ,p_c_ext_attr10      
                                                       ,p_c_ext_attr11      
                                                       ,p_c_ext_attr12      
                                                       ,p_c_ext_attr13      
                                                       ,p_c_ext_attr14      
                                                       ,p_c_ext_attr15      
                                                       ,p_c_ext_attr16      
                                                       ,p_c_ext_attr17      
                                                       ,p_c_ext_attr18      
                                                       ,p_c_ext_attr19      
                                                       ,p_c_ext_attr20      
                                                       ,p_n_ext_attr1       
                                                       ,p_n_ext_attr2       
                                                       ,p_n_ext_attr3       
                                                       ,p_n_ext_attr4       
                                                       ,p_n_ext_attr5       
                                                       ,p_n_ext_attr6       
                                                       ,p_n_ext_attr7       
                                                       ,p_n_ext_attr8       
                                                       ,p_n_ext_attr9       
                                                       ,p_n_ext_attr10      
                                                       ,p_n_ext_attr11      
                                                       ,p_n_ext_attr12      
                                                       ,p_n_ext_attr13      
                                                       ,p_n_ext_attr14      
                                                       ,p_n_ext_attr15      
                                                       ,p_n_ext_attr16      
                                                       ,p_n_ext_attr17      
                                                       ,p_n_ext_attr18      
                                                       ,p_n_ext_attr19      
                                                       ,p_n_ext_attr20      
                                                       ,p_d_ext_attr1       
                                                       ,p_d_ext_attr2       
                                                       ,p_d_ext_attr3       
                                                       ,p_d_ext_attr4       
                                                       ,p_d_ext_attr5       
                                                       ,p_d_ext_attr6       
                                                       ,p_d_ext_attr7       
                                                       ,p_d_ext_attr8       
                                                       ,p_d_ext_attr9       
                                                       ,p_d_ext_attr10      
                                                       ,p_tl_ext_attr1      
                                                       ,p_tl_ext_attr2      
                                                       ,p_tl_ext_attr3      
                                                       ,p_tl_ext_attr4      
                                                       ,p_tl_ext_attr5      
                                                       ,p_tl_ext_attr6      
                                                       ,p_tl_ext_attr7      
                                                       ,p_tl_ext_attr8      
                                                       ,p_tl_ext_attr9      
                                                       ,p_tl_ext_attr10     
                                                       ,p_tl_ext_attr11     
                                                       ,p_tl_ext_attr12     
                                                       ,p_tl_ext_attr13     
                                                       ,p_tl_ext_attr14     
                                                       ,p_tl_ext_attr15     
                                                       ,p_tl_ext_attr16     
                                                       ,p_tl_ext_attr17     
                                                       ,p_tl_ext_attr18     
                                                       ,p_tl_ext_attr19     
                                                       ,p_tl_ext_attr20     
                                                       ,p_owner             );

  Exception 
when others then
  Raise;
  
 END LOAD_ROW;

-- +==============================================================================+
-- | Name             : TRANSLATE_ROW                                             |
-- | Description      : This procedure is not being implemented.                  |
-- |                                                                              |
-- +==============================================================================+

procedure TRANSLATE_ROW (
  p_extension_id      IN NUMBER,
  p_cust_acct_site_id IN NUMBER,
  p_attr_group_id     IN NUMBER,
  p_tl_ext_attr1      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr2      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr3      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr4      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr5      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr6      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr7      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr8      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr9      IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr10     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr11     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr12     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr13     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr14     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr15     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr16     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr17     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr18     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr19     IN VARCHAR2 DEFAULT NULL,
  p_tl_ext_attr20     IN VARCHAR2 DEFAULT NULL,
  p_owner             IN VARCHAR2 DEFAULT NULL
   )
   
  IS
  
BEGIN

        XX_CDH_CUST_ACCT_SITE_EXT_PKG. TRANSLATE_ROW(p_extension_id      
                                                     ,p_cust_acct_site_id 
                                                     ,p_attr_group_id     
                                                     ,p_tl_ext_attr1      
                                                     ,p_tl_ext_attr2      
                                                     ,p_tl_ext_attr3      
                                                     ,p_tl_ext_attr4      
                                                     ,p_tl_ext_attr5      
                                                     ,p_tl_ext_attr6      
                                                     ,p_tl_ext_attr7      
                                                     ,p_tl_ext_attr8      
                                                     ,p_tl_ext_attr9      
                                                     ,p_tl_ext_attr10     
                                                     ,p_tl_ext_attr11     
                                                     ,p_tl_ext_attr12     
                                                     ,p_tl_ext_attr13     
                                                     ,p_tl_ext_attr14     
                                                     ,p_tl_ext_attr15     
                                                     ,p_tl_ext_attr16     
                                                     ,p_tl_ext_attr17     
                                                     ,p_tl_ext_attr18     
                                                     ,p_tl_ext_attr19     
                                                     ,p_tl_ext_attr20     
                                                     ,p_owner             );

Exception 
when others then
  Raise;
 
END TRANSLATE_ROW;
-- +==========================================================================================+
-- | Name             : VALIDATE_DUPLICATE_ROW                                                |
-- | Description      : This procedure is to do the validation while the user tries creating  |
-- |                    more than one Exception for a particular Cust Doc Id .                |
-- |                                                                                          |
-- +==========================================================================================+

procedure VALIDATE_DUPLICATE_ROW ( x_ret_status OUT VARCHAR2,
                                   p_cust_doc_id IN NUMBER,
                                   p_from_site   IN NUMBER)
IS

l_cnt  number ;

BEGIN
    l_cnt := 0;

SELECT count(1) INTO l_cnt from XX_CDH_ACCT_SITE_EXT_B
WHERE n_ext_attr1 = p_cust_doc_id
AND cust_acct_site_id = p_from_site
AND  c_ext_attr20     =  'Y';

IF (l_cnt > 1)
THEN
   x_ret_status := 'E'; -- When there are more than one cust doc Ids , then the return Status will be E
    
ELSE
    x_ret_status := 'S';
END IF;

END VALIDATE_DUPLICATE_ROW;

END XX_CDH_CUST_ACCT_SITE_EXTW_PKG;
/
show errors;
