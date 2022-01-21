BEGIN

  UPDATE XDO_DS_DEFINITIONS_B 
  SET DATA_SOURCE_CODE   = 'XXARCBIONE_SPEC' 
  WHERE DATA_SOURCE_CODE = 'XXARCBIONE-SPEC';
  
  dbms_output.put_line('Data Source XXARCBIONE_SPEC successfully updated');

  UPDATE XDO_DS_DEFINITIONS_TL
  SET    DATA_SOURCE_CODE         = 'XXARCBIONE_SPEC' 
  WHERE  DATA_SOURCE_CODE         = 'XXARCBIONE-SPEC'
  AND    APPLICATION_SHORT_NAME   = 'XXFIN'
  AND    LANGUAGE                 =  USERENV ('LANG');
  
  dbms_output.put_line('Data Source XXARCBIONE_SPEC successfully updated');
   
  UPDATE XDO_DS_DEFINITIONS_B 
  SET DATA_SOURCE_CODE = 'XXARCBISUM_SPEC' 
  WHERE DATA_SOURCE_CODE = 'XXARCBISUM-SPEC';
  
  dbms_output.put_line('Data Source XXARCBISUM_SPEC successfully updated');
  
  UPDATE XDO_DS_DEFINITIONS_TL
  SET    DATA_SOURCE_CODE         = 'XXARCBISUM_SPEC' 
  WHERE  DATA_SOURCE_CODE         = 'XXARCBISUM-SPEC'
  AND    APPLICATION_SHORT_NAME   = 'XXFIN'
  AND    LANGUAGE                 =  USERENV ('LANG');
  
  dbms_output.put_line('Data Source XXARCBISUM_SPEC successfully updated');
  
  UPDATE XDO_DS_DEFINITIONS_B 
  SET    DATA_SOURCE_CODE = 'XXARCBIHDR_SPEC' 
  WHERE  DATA_SOURCE_CODE = 'XXARCBIHDR-SPEC';
  
  dbms_output.put_line('Data Source XXARCBIHDR_SPEC successfully updated');
  
  UPDATE XDO_DS_DEFINITIONS_TL
  SET    DATA_SOURCE_CODE         = 'XXARCBIHDR_SPEC' 
  WHERE  DATA_SOURCE_CODE         = 'XXARCBIHDR-SPEC'
  AND    APPLICATION_SHORT_NAME   = 'XXFIN'
  AND    LANGUAGE                 =  USERENV ('LANG');
  
  dbms_output.put_line('Data Source XXARCBIHDR_SPEC successfully updated');
  
  UPDATE XDO_DS_DEFINITIONS_B 
  SET    DATA_SOURCE_CODE = 'XXARCBIDTL_SPEC' 
  WHERE  DATA_SOURCE_CODE = 'XXARCBIDTL-SPEC';
  
  dbms_output.put_line('Data Source XXARCBIDTL_SPEC successfully updated');
  
  UPDATE XDO_DS_DEFINITIONS_TL
  SET    DATA_SOURCE_CODE         = 'XXARCBIDTL_SPEC' 
  WHERE  DATA_SOURCE_CODE         = 'XXARCBIDTL-SPEC'
  AND    APPLICATION_SHORT_NAME   = 'XXFIN'
  AND    LANGUAGE                 =  USERENV ('LANG');
  
  dbms_output.put_line('Data Source XXARCBIDTL_SPEC successfully updated');
  
  UPDATE XDO_TEMPLATES_B 
  SET    TEMPLATE_CODE = 'XXARCBIONE_SPEC' 
  WHERE  TEMPLATE_CODE = 'XXARCBIONE-SPEC';
  
  dbms_output.put_line('Data Template XXARCBIONE_SPEC successfully updated');
  
  UPDATE XDO_TEMPLATES_TL
  SET    TEMPLATE_CODE                = 'XXARCBIONE_SPEC' 
  WHERE  TEMPLATE_CODE                = 'XXARCBIONE-SPEC'
  AND    APPLICATION_SHORT_NAME       = 'XXFIN'
  AND    LANGUAGE                     =  USERENV ('LANG');
  
  dbms_output.put_line('Data Template XXARCBIONE_SPEC successfully updated');
  
  UPDATE XDO_TEMPLATES_B 
  SET    TEMPLATE_CODE = 'XXARCBISUM_SPEC' 
  WHERE  TEMPLATE_CODE = 'XXARCBISUM-SPEC';
  
    dbms_output.put_line('Data Template XXARCBISUM_SPEC successfully updated');

  UPDATE XDO_TEMPLATES_TL
  SET    TEMPLATE_CODE            = 'XXARCBISUM_SPEC' 
  WHERE  TEMPLATE_CODE            = 'XXARCBISUM-SPEC'
  AND    APPLICATION_SHORT_NAME   = 'XXFIN'
  AND    LANGUAGE                 =  USERENV ('LANG');
 
    dbms_output.put_line('Data Template XXARCBISUM_SPEC successfully updated');

  UPDATE XDO_TEMPLATES_B 
  SET    TEMPLATE_CODE            = 'XXARCBIHDR_SPEC' 
  WHERE  TEMPLATE_CODE            = 'XXARCBIHDR-SPEC';

    dbms_output.put_line('Data Template XXARCBIHDR_SPEC successfully updated');

  UPDATE XDO_TEMPLATES_TL
  SET    TEMPLATE_CODE            = 'XXARCBIHDR_SPEC' 
  WHERE  TEMPLATE_CODE            = 'XXARCBIHDR-SPEC'
  AND    APPLICATION_SHORT_NAME   = 'XXFIN'
  AND    LANGUAGE                 =  USERENV ('LANG');
  
    dbms_output.put_line('Data Template XXARCBIHDR_SPEC successfully updated');

  UPDATE XDO_TEMPLATES_B 
  SET    TEMPLATE_CODE = 'XXARCBIDTL_SPEC' 
  WHERE  TEMPLATE_CODE = 'XXARCBIDTL-SPEC';
  
  dbms_output.put_line('Data Template XXARCBIDTL_SPEC successfully updated');

  UPDATE XDO_TEMPLATES_TL
  SET    TEMPLATE_CODE            = 'XXARCBIDTL_SPEC' 
  WHERE  TEMPLATE_CODE            = 'XXARCBIDTL-SPEC'
  AND    APPLICATION_SHORT_NAME   = 'XXFIN'
  AND    LANGUAGE                 =  USERENV ('LANG');
  
    dbms_output.put_line('Data Template XXARCBIDTL_SPEC successfully updated');
 
  COMMIT;

END;
/

