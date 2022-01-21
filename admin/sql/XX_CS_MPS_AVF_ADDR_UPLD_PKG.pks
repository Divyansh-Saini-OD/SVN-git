create or replace
package XX_CS_MPS_AVF_ADDR_UPLD_PKG
as

  PROCEDURE main(  errbuf      OUT NOCOPY VARCHAR2
                 , retcode     OUT NOCOPY VARCHAR2
                 , p_batch_id  IN         VARCHAR2
                ) ;
				
  PROCEDURE send_avf_mail( p_party_id        IN   NUMBER
                         , x_return_status  OUT VARCHAR2
                         , x_return_mesg    OUT VARCHAR2
                         ); 
end XX_CS_MPS_AVF_ADDR_UPLD_PKG;
/
SHOW ERRORS;