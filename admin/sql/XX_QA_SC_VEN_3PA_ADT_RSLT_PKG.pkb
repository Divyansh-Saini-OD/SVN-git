CREATE OR REPLACE 
PACKAGE BODY xx_qa_sc_ven_3pa_adt_rslt_pkg
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_QA_SC_ADUIT_RESULT_PKG                                       |
-- | Description      : This Program will load all SC Audit data             |
-- |                    into EBIZ                                            |
-- | Author          : Bala Edupuganti   Date: 01-Jun-2011                   |
-- | Revised         : Rama Dwibhashyam  Date: 21-Jun-2011                   |
-- | Revised         : Rama Dwibhashyam  Date: 01-Jul-2011                   |
-- | Revised         : Rama Dwibhashyam  Date: 21-Sep-2011                   |
-- | Revised         : Paddy Sanjeevi    Date: 20-Jul-2012 Defect 19239      |
-- | Revised         : Harvinder Rakhra  Date: 25-Nov-2015 Retrofit R12.2    |
-- | added vendor_audit_notify procedure                                     |
-- | added get_vendor_count function                                         |
-- | added vendor_audit_notify procedure                                     |
-- | Added the Upper function to fix QC defect 15296                         |
-- | Correction to INSPECTION word to fix QC defect 22622                    |
-- |																		 | 
-- | Revised         : Anoop Salim       Date: 25-Nov-2015 Retrofit R12.2    |
-- | Remove email address hard coding - Defect# 36805                        |

-- +=========================================================================+

   PROCEDURE log_exception (
      p_error_location       IN   VARCHAR2,
      p_error_message_code   IN   VARCHAR2,
      p_error_msg            IN   VARCHAR2
   )
   IS
      ln_login     PLS_INTEGER := fnd_global.login_id;
      ln_user_id   PLS_INTEGER := fnd_global.user_id;
   BEGIN
      xx_com_error_log_pub.log_error
                               (p_return_code                 => fnd_api.g_ret_sts_error,
                                p_msg_count                   => 1,
                                p_application_name            => 'XX_QA',
                                p_program_type                => 'Custom Messages',
                                p_program_name                => 'XX_QA_SC_VEN_AUDIT_PKG',
                                p_program_id                  => NULL,
                                p_module_name                 => 'QASC',
                                p_error_location              => p_error_location,
                                p_error_message_code          => p_error_message_code,
                                p_error_message               => p_error_msg,
                                p_error_message_severity      => 'MAJOR',
                                p_error_status                => 'ACTIVE',
                                p_created_by                  => 500904, --ln_user_id
                                p_last_updated_by             => 500904,
                                p_last_update_login           => 500904
                               );
   END log_exception;
-----
FUNCTION get_vendor_match( p_header_rec    IN XX_QA_SC_HEADER_MATCH_REC_TYPE
                          ,p_audit_rec     IN XX_QA_SC_AUDIT_REC_TYPE
                          ,p_vendor_tbl    IN XX_QA_SC_VENDOR_TBL_TYPE
                         )
RETURN VARCHAR2 IS

   lc_us_match_flag     VARCHAR2 (1);
   lc_eu_match_flag     VARCHAR2 (1);
   lc_asia_match_flag   VARCHAR2 (1);
   lc_mx_match_flag     VARCHAR2 (1);
   lc_match_flag        VARCHAR2 (1);
   lc_region            VARCHAR2 (150) ;
   lc_vendor_no         VARCHAR2 (150) ;
   lc_vendor_name       VARCHAR2 (150) ;
   lc_factory_no        VARCHAR2 (150) ;
   lc_factory_name      VARCHAR2 (150) ;
   lc_agent             VARCHAR2 (150) ;
   lc_vendor_address    VARCHAR2 (150) ;
   lc_factory_address   VARCHAR2 (150) ;
   lc_dft_vendor_id     VARCHAR2 (150) ;
   lc_dft_vendor_name   VARCHAR2 (150) ;
   lc_dft_agent         VARCHAR2 (150) ;
   lc_dft_vendor_addr   VARCHAR2 (150) ;
   lc_dft_factory_id    VARCHAR2 (150) ;
   lc_dft_factory_name  VARCHAR2 (150) ;
   lc_dft_factory_addr  VARCHAR2 (150) ;
   lc_dft_europe_region VARCHAR2 (150) ;
   lc_dft_mexico_region VARCHAR2 (150) ;
   lc_dft_asia_region   VARCHAR2 (150) ;
   lc_dft_us_region     VARCHAR2 (150) ;

            CURSOR cur_us (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2,lc_region varchar2) IS
             SELECT upper(vmast.od_sc_vendor_number)
                   ,upper(vmast.od_sc_vendor_name)
                   ,upper(vmast.od_sc_audit_agent)
                   ,upper(vmast.od_sc_vend_address)
                   ,upper(vmast.od_sc_factory_number)
                   ,upper(vmast.od_sc_factory_name)
                   ,upper(vmast.od_sc_factory_address)
                   ,instr(lc_region,vmast.od_sc_europe_rgn)
                   ,instr(lc_region,vmast.od_sc_mexico_region)
                   ,instr(lc_region,vmast.od_sc_asia_region)
                   ,instr(lc_region,vmast.od_sc_vend_region)
              FROM q_od_pb_sc_vendor_master_v vmast
             WHERE (vmast.od_sc_vendor_number = lc_vendor_no 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND vmast.od_sc_factory_number = lc_factory_no 
               AND upper(vmast.od_sc_factory_name) like substr(upper(lc_factory_name),1,15)||'%'
               AND ROWNUM < 2; 
               
            CURSOR cur_eu (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2,lc_region varchar2) IS
             SELECT upper(vmast.od_sc_vendor_number)
                   ,upper(vmast.od_sc_vendor_name)
                   ,upper(vmast.od_sc_audit_agent)
                   ,upper(vmast.od_sc_vend_address)
                   ,upper(vmast.od_sc_factory_number)
                   ,upper(vmast.od_sc_factory_name)
                   ,upper(vmast.od_sc_factory_address)
                   ,instr(lc_region,vmast.od_sc_europe_rgn)
                   ,instr(lc_region,vmast.od_sc_mexico_region)
                   ,instr(lc_region,vmast.od_sc_asia_region)
                   ,instr(lc_region,vmast.od_sc_vend_region)
              FROM q_od_sc_eu_vendor_master_v vmast
             WHERE (vmast.od_sc_vendor_number = lc_vendor_no 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND (vmast.od_sc_factory_number = lc_factory_no 
                    or upper(vmast.od_sc_factory_name) like upper(lc_factory_name)||'%')
               AND ROWNUM < 2; 
               
            CURSOR cur_asia (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2,lc_region varchar2) IS
             SELECT upper(vmast.od_sc_vendor_number)
                   ,upper(vmast.od_sc_vendor_name)
                   ,upper(vmast.od_sc_audit_agent)
                   ,upper(vmast.od_sc_vend_address)
                   ,upper(vmast.od_sc_factory_number)
                   ,upper(vmast.od_sc_factory_name)
                   ,upper(vmast.od_sc_factory_address)
                   ,instr(lc_region,vmast.od_sc_europe_rgn)
                   ,instr(lc_region,vmast.od_sc_mexico_region)
                   ,instr(lc_region,vmast.od_sc_asia_region)
                   ,instr(lc_region,vmast.od_sc_vend_region)
              FROM q_od_sc_asia_vendor_master_v vmast
             WHERE (vmast.od_sc_vendor_number = lc_vendor_no 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND (vmast.od_sc_factory_number = lc_factory_no 
                    or upper(vmast.od_sc_factory_name) like upper(lc_factory_name)||'%')
               AND ROWNUM < 2; 
               
            CURSOR cur_mx (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2,lc_region varchar2) IS
             SELECT upper(vmast.od_sc_vendor_number)
                   ,upper(vmast.od_sc_vendor_name)
                   ,upper(vmast.od_sc_audit_agent)
                   ,upper(vmast.od_sc_vend_address)
                   ,upper(vmast.od_sc_factory_number)
                   ,upper(vmast.od_sc_factory_name)
                   ,upper(vmast.od_sc_factory_address)
                   ,instr(lc_region,vmast.od_sc_europe_rgn)
                   ,instr(lc_region,vmast.od_sc_mexico_region)
                   ,instr(lc_region,vmast.od_sc_asia_region)
                   ,instr(lc_region,vmast.od_sc_vend_region)
              FROM q_od_sc_mx_vendor_master_v vmast
             WHERE (vmast.od_sc_vendor_number = lc_vendor_no 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND (vmast.od_sc_factory_number = lc_factory_no 
                    or upper(vmast.od_sc_factory_name) like upper(lc_factory_name)||'%')
               AND ROWNUM < 2;                                              
                              
                              
                              
BEGIN


      FOR j IN 1 .. p_vendor_tbl.COUNT
      LOOP
         lc_vendor_no       := upper(p_vendor_tbl (j).od_vendor_no);
         lc_vendor_name     := upper(p_vendor_tbl (j).vendor);
         lc_vendor_address  := upper(p_vendor_tbl (j).vendor_address.address_1);
         lc_factory_no      := upper(p_vendor_tbl (j).od_factory_no);
         lc_factory_name    := upper(p_vendor_tbl (j).vendor_attribute1);
         lc_factory_address := upper(p_vendor_tbl (j).base_address);
         lc_region          := upper(p_vendor_tbl (j).region);
         lc_agent           := upper(p_vendor_tbl (j).vendor_attribute2);
      END LOOP;
      
   IF INSTR (lc_region, 'ODUS') > 0
   THEN
   
        OPEN cur_us(lc_vendor_no ,lc_vendor_name ,
                    lc_factory_no ,lc_factory_name ,
                    lc_region );
        
        FETCH cur_us 
         INTO  lc_dft_vendor_id
                   ,lc_dft_vendor_name
                   ,lc_dft_agent
                   ,lc_dft_vendor_addr
                   ,lc_dft_factory_id
                   ,lc_dft_factory_name
                   ,lc_dft_factory_addr
                   ,lc_dft_europe_region
                   ,lc_dft_mexico_region
                   ,lc_dft_asia_region
                   ,lc_dft_us_region ;
                   
               IF (lc_vendor_no != lc_dft_vendor_id 
                or substr(lc_dft_vendor_name,1,15) != substr(lc_vendor_name,1,15) 
                or lc_dft_agent != lc_agent
                or substr(lc_dft_vendor_addr,1,15) != substr(lc_vendor_address,1,15)
                or lc_dft_factory_id != lc_factory_no
                or substr(lc_dft_factory_name,1,15) != substr(lc_factory_name,1,15)
                or substr(lc_dft_factory_addr,1,15) != substr(lc_factory_address,1,15)
                or lc_dft_europe_region = '0'
                or lc_dft_mexico_region = '0'
                or lc_dft_asia_region   = '0'
                or lc_dft_us_region     = '0'
                 ) 
               THEN
                  lc_us_match_flag := 'N';
               ELSE 
                  lc_us_match_flag := 'Y';
               END IF;      
                   
                 if cur_us%notfound then
                   lc_us_match_flag := 'Y';
                 end if;

         CLOSE cur_us;
   
               
   END IF;
 
   IF INSTR (lc_region, 'ODEU') > 0
   THEN
        OPEN cur_eu(lc_vendor_no ,lc_vendor_name ,
                    lc_factory_no ,lc_factory_name ,
                    lc_region );
        
        FETCH cur_eu 
         INTO  lc_dft_vendor_id
                   ,lc_dft_vendor_name
                   ,lc_dft_agent
                   ,lc_dft_vendor_addr
                   ,lc_dft_factory_id
                   ,lc_dft_factory_name
                   ,lc_dft_factory_addr
                   ,lc_dft_europe_region
                   ,lc_dft_mexico_region
                   ,lc_dft_asia_region
                   ,lc_dft_us_region ;
                   
               IF ( substr(lc_dft_vendor_name,1,15) != substr(lc_vendor_name,1,15) 
                or lc_dft_agent != lc_agent
                or substr(lc_dft_vendor_addr,1,15) != substr(lc_vendor_address,1,15)
                --or lc_dft_factory_id != lc_factory_no
                or substr(lc_dft_factory_name,1,15) != substr(lc_factory_name,1,15)
                or substr(lc_dft_factory_addr,1,15) != substr(lc_factory_address,1,15)
                or lc_dft_europe_region = '0'
                or lc_dft_mexico_region = '0'
                or lc_dft_asia_region   = '0'
                or lc_dft_us_region     = '0'
                 ) 
               THEN
                  lc_eu_match_flag := 'N';
               ELSE 
                  lc_eu_match_flag := 'Y';
               END IF;      
                   
                 if cur_eu%notfound then
                   lc_eu_match_flag := 'Y';
                 end if;

         CLOSE cur_eu;
   
   END IF;
   
   IF INSTR (lc_region, 'ODASIA') > 0
   THEN
        OPEN cur_asia(lc_vendor_no ,lc_vendor_name ,
                    lc_factory_no ,lc_factory_name ,
                    lc_region );
        
        FETCH cur_asia 
         INTO  lc_dft_vendor_id
                   ,lc_dft_vendor_name
                   ,lc_dft_agent
                   ,lc_dft_vendor_addr
                   ,lc_dft_factory_id
                   ,lc_dft_factory_name
                   ,lc_dft_factory_addr
                   ,lc_dft_europe_region
                   ,lc_dft_mexico_region
                   ,lc_dft_asia_region
                   ,lc_dft_us_region ;
                   
               IF (substr(lc_dft_vendor_name,1,15) != substr(lc_vendor_name,1,15) 
                or lc_dft_agent != lc_agent
                or substr(lc_dft_vendor_addr,1,15) != substr(lc_vendor_address,1,15)
                --or lc_dft_factory_id != lc_factory_no
                or substr(lc_dft_factory_name,1,15) != substr(lc_factory_name,1,15)
                or substr(lc_dft_factory_addr,1,15) != substr(lc_factory_address,1,15)
                or lc_dft_europe_region = '0'
                or lc_dft_mexico_region = '0'
                or lc_dft_asia_region   = '0'
                or lc_dft_us_region     = '0'
                 ) 
               THEN
                  lc_asia_match_flag := 'N';
               ELSE 
                  lc_asia_match_flag := 'Y';
               END IF;      
                   
                 if cur_asia%notfound then
                    lc_asia_match_flag := 'Y';
                 end if;

         CLOSE cur_asia;
   
               
   END IF;
   
   IF INSTR (lc_region, 'ODMX') > 0
   THEN
        OPEN cur_mx(lc_vendor_no ,lc_vendor_name ,
                    lc_factory_no ,lc_factory_name ,
                    lc_region );
        
        FETCH cur_mx 
         INTO lc_dft_vendor_id
                   ,lc_dft_vendor_name
                   ,lc_dft_agent
                   ,lc_dft_vendor_addr
                   ,lc_dft_factory_id
                   ,lc_dft_factory_name
                   ,lc_dft_factory_addr
                   ,lc_dft_europe_region
                   ,lc_dft_mexico_region
                   ,lc_dft_asia_region
                   ,lc_dft_us_region ;
                   
               IF (substr(lc_dft_vendor_name,1,15) != substr(lc_vendor_name,1,15) 
                or lc_dft_agent != lc_agent
                or substr(lc_dft_vendor_addr,1,15) != substr(lc_vendor_address,1,15)
                --or lc_dft_factory_id != lc_factory_no
                or substr(lc_dft_factory_name,1,15) != substr(lc_factory_name,1,15)
                or substr(lc_dft_factory_addr,1,15) != substr(lc_factory_address,1,15)
                or lc_dft_europe_region = '0'
                or lc_dft_mexico_region = '0'
                or lc_dft_asia_region   = '0'
                or lc_dft_us_region     = '0'
                 ) 
               THEN
                  lc_mx_match_flag := 'N';
               ELSE 
                  lc_mx_match_flag := 'Y';
               END IF;      
                   
                 if cur_mx%notfound then
                    lc_mx_match_flag := 'Y';
                 end if;

         CLOSE cur_mx;
   
   END IF;

   IF (   lc_us_match_flag   = 'N'
       OR lc_eu_match_flag   = 'N'
       OR lc_asia_match_flag = 'N'
       OR lc_mx_match_flag   = 'N'
      )
   THEN
      lc_match_flag := 'N' ;
      RETURN lc_match_flag ;
   ELSE
      lc_match_flag := 'Y' ;
      RETURN lc_match_flag ;
   END IF;

EXCEPTION
   WHEN OTHERS
   THEN
      lc_match_flag := 'N';
      RETURN lc_match_flag ;

            log_exception (p_error_location          => 'XX_GET_VENDOR_MATCH',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => 'Error in When others in get Vendor Match:'||SQLERRM
                          );

END get_vendor_match;
   
---
FUNCTION get_vendor_count( p_header_rec    IN XX_QA_SC_HEADER_MATCH_REC_TYPE
                          ,p_audit_rec     IN XX_QA_SC_AUDIT_REC_TYPE
                          ,p_vendor_tbl    IN XX_QA_SC_VENDOR_TBL_TYPE
                         )
RETURN NUMBER IS

   ln_us_count     NUMBER;
   ln_eu_count     NUMBER;
   ln_asia_count   NUMBER;
   ln_mx_count     NUMBER;
   ln_count        NUMBER;
   lc_region       VARCHAR2 (150) ;
   lc_vendor_no    VARCHAR2 (150) ;
   lc_vendor_name  VARCHAR2 (150) ;
   lc_factory_no   VARCHAR2 (150) ;
   lc_factory_name VARCHAR2 (150) ;
                              
                              
                              
BEGIN


      FOR j IN 1 .. p_vendor_tbl.COUNT
      LOOP
         lc_vendor_no     := upper(p_vendor_tbl (j).od_vendor_no);
         lc_vendor_name   := upper(p_vendor_tbl (j).vendor);
         lc_factory_no    := upper(p_vendor_tbl (j).od_factory_no);
         lc_factory_name  := upper(p_vendor_tbl (j).vendor_attribute1);
         lc_region        := upper(p_vendor_tbl (j).region);
      END LOOP;
      
   IF INSTR (lc_region, 'ODUS') > 0
   THEN
      SELECT COUNT (*)
        INTO ln_us_count
        FROM q_od_pb_sc_vendor_master_v vmast
       WHERE (   upper(vmast.od_sc_vendor_number) = lc_vendor_no
              OR upper(vmast.od_sc_vendor_name) LIKE
                                             SUBSTR (lc_vendor_name, 1, 15)
                                             || '%'
             )
         AND upper(vmast.od_sc_factory_number) = lc_factory_no
         AND upper(vmast.od_sc_factory_name) LIKE SUBSTR(lc_factory_name, 1, 15)||'%'
            ;
   END IF;
   
   IF INSTR (lc_region, 'ODEU') > 0
   THEN
      SELECT COUNT (*)
        INTO ln_eu_count
        FROM q_od_sc_eu_vendor_master_v vmast
       WHERE (   upper(vmast.od_sc_vendor_number) = lc_vendor_no
              OR upper(vmast.od_sc_vendor_name) LIKE
                                             SUBSTR (lc_vendor_name, 1, 15)
                                             || '%'
             )
         AND (   upper(vmast.od_sc_factory_number) = lc_factory_no
              OR upper(vmast.od_sc_factory_name) LIKE UPPER(lc_factory_name)||'%'
             );
   END IF;
   
   IF INSTR (lc_region, 'ODASIA') > 0
   THEN
      SELECT COUNT (*)
        INTO ln_asia_count
        FROM q_od_sc_asia_vendor_master_v vmast
       WHERE (   upper(vmast.od_sc_vendor_number) = lc_vendor_no
              OR upper(vmast.od_sc_vendor_name) LIKE
                                             SUBSTR (lc_vendor_name, 1, 15)
                                             || '%'
             )
         AND (   upper(vmast.od_sc_factory_number) = lc_factory_no
              OR upper(vmast.od_sc_factory_name) LIKE UPPER(lc_factory_name)||'%'
             );
   END IF;
   
   IF INSTR (lc_region, 'ODMX') > 0
   THEN
      SELECT COUNT (*)
        INTO ln_mx_count
        FROM q_od_sc_mx_vendor_master_v vmast
       WHERE (   upper(vmast.od_sc_vendor_number) = lc_vendor_no
              OR upper(vmast.od_sc_vendor_name) LIKE
                                             SUBSTR (lc_vendor_name, 1, 15)
                                             || '%'
             )
         AND (   upper(vmast.od_sc_factory_number) = lc_factory_no
              OR upper(vmast.od_sc_factory_name) LIKE UPPER(lc_factory_name)||'%'
             );
   END IF;

   IF (   ln_us_count > 0
       OR ln_eu_count > 0
       OR ln_asia_count > 0
       OR ln_mx_count > 0
      )
   THEN
      ln_count := 1;
      RETURN ln_count ;
   ELSE
      ln_count := 0;
      RETURN ln_count ;
   END IF;

EXCEPTION
   WHEN OTHERS
   THEN
      ln_count := 0;
      RETURN ln_count ;
           
            log_exception (p_error_location          => 'XX_GET_VENDOR_COUNT',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => 'Error in When others in Send Notify :'||SQLERRM
                          );

END get_vendor_count;
--------

PROCEDURE update_vendor_data(p_header_rec    IN XX_QA_SC_HEADER_MATCH_REC_TYPE
                            ,p_audit_rec     IN XX_QA_SC_AUDIT_REC_TYPE
                            ,p_vendor_tbl    IN XX_QA_SC_VENDOR_TBL_TYPE
                            )
IS


   lc_region                VARCHAR2 (150) ;
   lc_vendor_no             VARCHAR2 (150) ;
   lc_vendor_name           VARCHAR2 (150) ;
   lc_factory_no            VARCHAR2 (150) ;
   lc_factory_name          VARCHAR2 (150) ;
   lc_agent                 VARCHAR2 (150) ;
   lc_vendor_address        VARCHAR2 (150) ;
   lc_factory_address       VARCHAR2 (150) ;
   lc_inspection_type       VARCHAR2 (150) ;
   ld_nextaudit_date	    DATE;
   lc_grade                 VARCHAR2 (150);
   ld_payment_date          DATE;
   ld_audit_schduled_date   DATE;
   ld_inspection_date       DATE;   
   ln_us_occurrence_id         NUMBER;
   ln_us_plan_id               NUMBER;
   ln_eu_occurrence_id         NUMBER;
   ln_eu_plan_id               NUMBER;
   ln_asia_occurrence_id       NUMBER;
   ln_asia_plan_id             NUMBER;
   ln_mx_occurrence_id         NUMBER;
   ln_mx_plan_id               NUMBER;

            CURSOR cur_us (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2) IS
             SELECT vmast.plan_id
                   ,vmast.occurrence
              FROM q_od_pb_sc_vendor_master_v vmast
             WHERE (upper(vmast.od_sc_vendor_number) = upper(lc_vendor_no) 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND upper(vmast.od_sc_factory_number) = upper(lc_factory_no) 
               AND upper(vmast.od_sc_factory_name) like substr(upper(lc_factory_name),1,15)||'%'
               AND ROWNUM < 2; 
               
            CURSOR cur_eu (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2) IS
             SELECT vmast.plan_id
                   ,vmast.occurrence
              FROM q_od_sc_eu_vendor_master_v vmast
             WHERE (upper(vmast.od_sc_vendor_number) = upper(lc_vendor_no) 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND (upper(vmast.od_sc_factory_number) = upper(lc_factory_no) 
                    or upper(vmast.od_sc_factory_name) like upper(lc_factory_name)||'%')
               AND ROWNUM < 2; 
               
            CURSOR cur_asia (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2) IS
             SELECT vmast.plan_id
                   ,vmast.occurrence
              FROM q_od_sc_asia_vendor_master_v vmast
             WHERE (upper(vmast.od_sc_vendor_number) = upper(lc_vendor_no) 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND (upper(vmast.od_sc_factory_number) = upper(lc_factory_no) 
                    or upper(vmast.od_sc_factory_name) like upper(lc_factory_name)||'%')
               AND ROWNUM < 2; 
               
            CURSOR cur_mx (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2) IS
             SELECT vmast.plan_id
                   ,vmast.occurrence
              FROM q_od_sc_mx_vendor_master_v vmast
             WHERE (upper(vmast.od_sc_vendor_number) = upper(lc_vendor_no) 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND (upper(vmast.od_sc_factory_number) = upper(lc_factory_no) 
                    or upper(vmast.od_sc_factory_name) like upper(lc_factory_name)||'%')
               AND ROWNUM < 2;                                              
                              
                              
                              
BEGIN

      ld_audit_schduled_date := p_audit_rec.audit_schduled_date;
      ld_inspection_date     := p_audit_rec.inspection_date;
      lc_inspection_type     := p_audit_rec.inspection_type;      
      FOR j IN 1 .. p_vendor_tbl.COUNT
      LOOP
         lc_vendor_no       := p_vendor_tbl (j).od_vendor_no;
         lc_vendor_name     := p_vendor_tbl (j).vendor;
         lc_vendor_address  := p_vendor_tbl (j).vendor_address.address_1;
         lc_factory_no      := p_vendor_tbl (j).od_factory_no;
         lc_factory_name    := p_vendor_tbl (j).vendor_attribute1;
         lc_factory_address := p_vendor_tbl (j).base_address;
         lc_region          := p_vendor_tbl (j).region;
         lc_agent           := p_vendor_tbl (j).vendor_attribute2;
         ld_payment_date    := p_vendor_tbl (j).payment_date;
         lc_grade           := p_vendor_tbl (j).grade;

      END LOOP;
      
      
        IF lc_grade = 'Denied Entry'  THEN
            ld_nextaudit_date:= ld_audit_schduled_date + 30;
        ELSIF lc_grade = 'Zero Tolerance' THEN
            ld_nextaudit_date := Null;                                
        ELSIF lc_grade = 'Needs Improvement' THEN
            ld_nextaudit_date := ld_audit_schduled_date + 180;
        ELSIF lc_grade IN ('Satisfactory','Minor Progress Needed') THEN
            ld_nextaudit_date := ld_audit_schduled_date + 365;
        END IF;                                
--                        
   IF INSTR (lc_region, 'ODUS') > 0
   THEN
   
        OPEN cur_us(lc_vendor_no ,lc_vendor_name ,
                    lc_factory_no ,lc_factory_name);
        
        FETCH cur_us 
         INTO  ln_us_plan_id,ln_us_occurrence_id ;
                   
           UPDATE qa_results
              SET character69               = lc_grade
                 ,character66               = to_char(ld_payment_date,'YYYY/MM/DD')
                 ,character67               = to_char(ld_inspection_date,'YYYY/MM/DD')
                 ,character68               = TO_CHAR(ld_nextaudit_date,'YYYY/MM/DD') --  OD_SC_REQ_AUDIT_DATE
                 ,character70               = null   --"OD_SC_CAP_ASSIGNMENT"
                 ,character71               = null   --"OD_SC_CAP_SENT_D"
                 ,character72               = null   --"OD_SC_CAP_RECD_D"
                 ,character73               = null   --"OD_SC_STRAUDT_CAP_STATUS"
                 ,character74               = null   --"OD_SC_CAP_RESP_D"
                 ,comment3                  = null   --"OD_SC_CAP_REV_COMMENTS"
                 ,character75               = null   --"OD_SC_CAP_PREAPPROVER"
                 ,character76               = null   --"OD_SC_STRAUDT_GSO_APR_D"
                 ,character77               = null   --"OD_SC_CAP_FINAL_APPROVER"
                 ,character78               = null   --"OD_SC_SRTAUDT_US_APR_D"
                 ,character92               = lc_inspection_type
            WHERE occurrence = ln_us_occurrence_id 
              AND plan_id    = ln_us_plan_id ;
                           
           COMMIT;                   

         CLOSE cur_us;
   
               
   END IF;
 
   IF INSTR (lc_region, 'ODEU') > 0
   THEN
        OPEN cur_eu(lc_vendor_no ,lc_vendor_name ,
                    lc_factory_no ,lc_factory_name);
        
        FETCH cur_eu
         INTO  ln_eu_plan_id,ln_eu_occurrence_id ;
                   
          UPDATE qa_results
              SET character70               = lc_grade
                 ,character67               = to_char(ld_payment_date,'YYYY/MM/DD')
                 ,character68               = to_char(ld_inspection_date,'YYYY/MM/DD')
                 ,character69               = TO_CHAR(ld_nextaudit_date,'YYYY/MM/DD') --  OD_SC_REQ_AUDIT_DATE
                 ,character71               = null   --"OD_SC_CAP_ASSIGNMENT"
                 ,character72               = null   --"OD_SC_CAP_SENT_D"
                 ,character73               = null   --"OD_SC_CAP_RECD_D"
                 ,character74               = null   --"OD_SC_STRAUDT_CAP_STATUS"
                 ,character75               = null   --"OD_SC_CAP_RESP_D"
                 ,comment3                  = null   --"OD_SC_CAP_REV_COMMENTS"
                 ,character76               = null   --"OD_SC_CAP_PREAPPROVER"
                 ,character77               = null   --"OD_SC_STRAUDT_GSO_APR_D"
                 ,character78               = null   --"OD_SC_CAP_FINAL_APPROVER"
                 ,character79               = null   --"OD_SC_SRTAUDT_US_APR_D"
                 ,character92               = lc_inspection_type
            WHERE occurrence = ln_eu_occurrence_id 
              AND plan_id    = ln_eu_plan_id ;
                           
           COMMIT;                   

         CLOSE cur_eu;   
   END IF;
   
   IF INSTR (lc_region, 'ODASIA') > 0
   THEN
        OPEN cur_asia(lc_vendor_no ,lc_vendor_name ,
                    lc_factory_no ,lc_factory_name);
        
        FETCH cur_asia 
         INTO  ln_asia_plan_id,ln_asia_occurrence_id ;
                   
           UPDATE qa_results
              SET character70               = lc_grade
                 ,character67               = to_char(ld_payment_date,'YYYY/MM/DD')
                 ,character68               = to_char(ld_inspection_date,'YYYY/MM/DD')
                 ,character69               = TO_CHAR(ld_nextaudit_date,'YYYY/MM/DD') --  OD_SC_REQ_AUDIT_DATE
                 ,character71               = null   --"OD_SC_CAP_ASSIGNMENT"
                 ,character72               = null   --"OD_SC_CAP_SENT_D"
                 ,character73               = null   --"OD_SC_CAP_RECD_D"
                 ,character74               = null   --"OD_SC_STRAUDT_CAP_STATUS"
                 ,character75               = null   --"OD_SC_CAP_RESP_D"
                 ,comment3                  = null   --"OD_SC_CAP_REV_COMMENTS"
                 ,character76               = null   --"OD_SC_CAP_PREAPPROVER"
                 ,character77               = null   --"OD_SC_STRAUDT_GSO_APR_D"
                 ,character78               = null   --"OD_SC_CAP_FINAL_APPROVER"
                 ,character79               = null   --"OD_SC_SRTAUDT_US_APR_D"
                 ,character92               = lc_inspection_type
            WHERE occurrence = ln_asia_occurrence_id 
              AND plan_id    = ln_asia_plan_id ;
                           
           COMMIT;                   

         CLOSE cur_asia;   
               
   END IF;
   
   IF INSTR (lc_region, 'ODMX') > 0
   THEN
        OPEN cur_mx(lc_vendor_no ,lc_vendor_name ,
                    lc_factory_no ,lc_factory_name);
        
        FETCH cur_mx 
         INTO  ln_mx_plan_id,ln_mx_occurrence_id ;
                   
           UPDATE qa_results
              SET character70               = lc_grade
                 ,character67               = to_char(ld_payment_date,'YYYY/MM/DD')
                 ,character68               = to_char(ld_inspection_date,'YYYY/MM/DD')
                 ,character69               = TO_CHAR(ld_nextaudit_date,'YYYY/MM/DD') --  OD_SC_REQ_AUDIT_DATE
                 ,character71               = null   --"OD_SC_CAP_ASSIGNMENT"
                 ,character72               = null   --"OD_SC_CAP_SENT_D"
                 ,character73               = null   --"OD_SC_CAP_RECD_D"
                 ,character74               = null   --"OD_SC_STRAUDT_CAP_STATUS"
                 ,character75               = null   --"OD_SC_CAP_RESP_D"
                 ,comment3                  = null   --"OD_SC_CAP_REV_COMMENTS"
                 ,character76               = null   --"OD_SC_CAP_PREAPPROVER"
                 ,character77               = null   --"OD_SC_STRAUDT_GSO_APR_D"
                 ,character78               = null   --"OD_SC_CAP_FINAL_APPROVER"
                 ,character79               = null   --"OD_SC_SRTAUDT_US_APR_D"
                 ,character92               = lc_inspection_type
            WHERE occurrence = ln_mx_occurrence_id 
              AND plan_id    = ln_mx_plan_id ;
                           
           COMMIT;                   

         CLOSE cur_mx;   
   END IF;

EXCEPTION
   WHEN OTHERS
   THEN
            log_exception (p_error_location          => 'XX_GET_VENDOR_MATCH',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => 'Error in When others in get Vendor Match:'||SQLERRM
                          );

END update_vendor_data;

---   

PROCEDURE vendor_audit_notify( p_header_rec    IN XX_QA_SC_HEADER_MATCH_REC_TYPE
                              ,p_audit_rec     IN XX_QA_SC_AUDIT_REC_TYPE
                              ,p_vendor_tbl    IN XX_QA_SC_VENDOR_TBL_TYPE
                              ,p_match_flag    IN VARCHAR2
                              ,x_errbuf      OUT NOCOPY VARCHAR2
                              ,x_retcode     OUT NOCOPY VARCHAR2
                            ) IS
                            
 
 conn 			    utl_smtp.connection;
 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000);
 v_text			    VARCHAR2(32000) := null;
 v_subject		    VARCHAR2(3000);
 v_region_contact  	varchar2(250);
 v_region		    varchar2(50);
 v_nextaudit_date	date;
 lc_send_mail       VARCHAR2(1) := FND_PROFILE.VALUE('XX_PB_SC_SEND_MAIL');
 v_errbuf           VARCHAR2(2000);
 v_retcode          VARCHAR2(50);
      lc_log_profile_value          VARCHAR2 (10)
                                  := fnd_profile.VALUE ('XX_QA_SC_AUDIT_LOG');
 ln_audit_count     NUMBER;
 -- *******temporary variables for Audit Record ***********************
      lc_trans_status               VARCHAR2 (150);
      lc_client                     VARCHAR2 (150);
      lc_inspection_no              VARCHAR2 (150);
      lc_inspection_type            VARCHAR2 (150);
      lc_service_type               VARCHAR2 (150);
      lc_status                     VARCHAR2 (150);
      ld_audit_schduled_date        DATE;
      ld_inspection_date            DATE;
-- ************temporary variables for VEMDOR Record table type**************
-- *****Not using for this release ******
      lc_od_vendor_no               VARCHAR2 (150);
      lc_sc_vendor                  VARCHAR2 (150);
      lc_od_factory_no              VARCHAR2 (150);
      lc_factory_name               VARCHAR2 (150);
      lc_base_address               VARCHAR2 (150);
      lc_city                       VARCHAR2 (150);
      lc_state                      VARCHAR2 (150);
      lc_country                    VARCHAR2 (150);
      lc_factory_status             VARCHAR2 (150);
      lc_factory_contacts           VARCHAR2 (150);
      lc_invoice_no                 VARCHAR2 (150);
      ld_invoice_date               DATE;
      lc_invoice_amount             VARCHAR2 (150);
      lc_payment_method             VARCHAR2 (150);
      ld_payment_date               DATE;
      lc_payment_amount             VARCHAR2 (150);
      lc_grade                      VARCHAR2 (150);
      lc_region                     VARCHAR2 (150);
      lc_sub_region                 VARCHAR2 (150);
      lc_ven_contact_name           VARCHAR2 (150);
      lc_ven_address_1              VARCHAR2 (150);
      lc_ven_address_2              VARCHAR2 (150);
      lc_ven_address_3              VARCHAR2 (150);
      lc_ven_address_4              VARCHAR2 (150);
      lc_ven_address_city           VARCHAR2 (150);
      lc_ven_address_state          VARCHAR2 (150);
      lc_ven_address_country        VARCHAR2 (150);
      lc_ven_contact_type           VARCHAR2 (150);
      lc_ven_contact_no             VARCHAR2 (150);
      lc_contact_address            VARCHAR2 (150);
      lc_contact_address_1          VARCHAR2 (150);
      lc_contact_address_2          VARCHAR2 (150);
      lc_contact_ddress_3           VARCHAR2 (150);
      lc_contact_address_4          VARCHAR2 (150);
      lc_contact_address_city       VARCHAR2 (150);
      lc_contact_address_state      VARCHAR2 (150);
      lc_contact_address_country    VARCHAR2 (150);
      lc_ven_contact                VARCHAR2 (150);
      lc_agent                      VARCHAR2 (150);
      lc_rush_audit                 VARCHAR2 (150);
      lc_fact_contact_type          VARCHAR2 (150);
      lc_fact_contact_no            VARCHAR2 (150);
      lc_factory_phone              VARCHAR2 (150);
	 -- 
	-- Start of changes as per version  to remove email address hard coding  - Defect# 36805
		v_zero_tolerance_mail 		xx_fin_translatevalues.target_value1%TYPE;
		v_draft_mail 				xx_fin_translatevalues.target_value1%TYPE;
		v_mismatch_mail 			xx_fin_translatevalues.target_value1%TYPE;
		v_exception_mail			xx_fin_translatevalues.target_value1%TYPE;
		v_cc_email					xx_fin_translatevalues.target_value1%TYPE;
	-- End of changes as per version  to remove email address hard coding  	- Defect# 36805
	--
                            
BEGIN
	--
	-- Start of changes as per version  to remove email address hard coding - Defect# 36805
	BEGIN
		SELECT 	xftv.target_value1 ,
				xftv.target_value2 ,
				xftv.target_value3 ,
				xftv.target_value4 ,
				xftv.target_value5
		INTO 	v_zero_tolerance_mail ,
				v_draft_mail ,
				v_mismatch_mail ,
				v_exception_mail ,
				v_cc_email
		FROM 	xx_fin_translatedefinition xftd ,
				xx_fin_translatevalues xftv
		WHERE 	xftd.translate_id   	= xftv.Translate_Id
		AND 	xftd.translation_name 	= 'XX_VENDOR_AUDIT_NOTIFY'
		AND		xftv.source_value1    	= 'XX_COMPLIANCE_EMAIL'
		AND 	xftv.enabled_flag 		= 'Y'
		AND 	xftd.enabled_flag 		= 'Y'
		AND 	SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
		AND 	SYSDATE BETWEEN xftd.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1);
	EXCEPTION
	WHEN OTHERS THEN
		fnd_file.put_line(fnd_file.log, 'Failed to retrieve email adresses from Translation ');
		v_zero_tolerance_mail := NULL;
		v_draft_mail 		  := NULL;
		v_mismatch_mail       := NULL;
		v_exception_mail	  := NULL;
		v_cc_email			  := NULL;
   END;
   	-- End of changes as per version  to remove email address hard coding  	- Defect# 36805
	--
-----
--  ************Audit Rec****************************************
      lc_trans_status := p_audit_rec.transmission_status;
      lc_inspection_no := p_audit_rec.inspection_no;
      lc_inspection_type := p_audit_rec.inspection_type;
      lc_service_type := p_audit_rec.service_type;
      lc_status := p_audit_rec.status;
      ld_audit_schduled_date := p_audit_rec.audit_schduled_date;
      ld_inspection_date := p_audit_rec.inspection_date;
-- Expecting One record only for this release 11.3
      FOR j IN 1 .. p_vendor_tbl.COUNT
      LOOP
         lc_od_vendor_no := p_vendor_tbl (j).od_vendor_no;
         lc_sc_vendor := p_vendor_tbl (j).vendor;
         lc_factory_name := p_vendor_tbl (j).vendor_attribute1;
         lc_od_factory_no := p_vendor_tbl (j).od_factory_no;
         lc_factory_name := p_vendor_tbl (j).vendor_attribute1;
         lc_base_address := p_vendor_tbl (j).base_address;
         lc_city := p_vendor_tbl (j).city;
         lc_state := p_vendor_tbl (j).state;
         lc_country := p_vendor_tbl (j).country;
         lc_factory_status := p_vendor_tbl (j).factory_status;
         lc_invoice_no := p_vendor_tbl (j).invoice_no;
         ld_invoice_date := p_vendor_tbl (j).invoice_date;
         lc_invoice_amount := p_vendor_tbl (j).invoice_amount;
         lc_payment_method := p_vendor_tbl (j).payment_method;
         ld_payment_date := p_vendor_tbl (j).payment_date;
         lc_payment_amount := p_vendor_tbl (j).payment_amount;
         lc_grade := p_vendor_tbl (j).grade;
         lc_region := p_vendor_tbl (j).region;
         lc_sub_region := p_vendor_tbl (j).sub_region;
         lc_ven_address_1 := p_vendor_tbl (j).vendor_address.address_1;
         lc_agent := p_vendor_tbl (j).vendor_attribute2;
---      
         lc_ven_contact_name := p_vendor_tbl (j).vendor_contact.contact_name;

         lc_ven_contact_type :=
                   p_vendor_tbl (j).vendor_contact.contact_phone.contact_type;
         lc_ven_contact_no :=
                     p_vendor_tbl (j).vendor_contact.contact_phone.contact_no;
         lc_ven_contact := lc_ven_contact_type || ':' || lc_ven_contact_no;
         
---         
         lc_factory_contacts :=
                               p_vendor_tbl (j).factory_contacts.contact_name;
         lc_fact_contact_type :=
                 p_vendor_tbl (j).factory_contacts.contact_phone.contact_type;
         lc_fact_contact_no :=
                   p_vendor_tbl (j).factory_contacts.contact_phone.contact_no;
         lc_factory_phone :=
                            lc_fact_contact_type || ':' || lc_fact_contact_no;
      END LOOP;


-----

  IF lc_trans_status = 'Draft' and lc_grade IN ('Denied Entry','Zero Tolerance')  THEN

	--
	-- Start of changes as per version  to remove email address hard coding - Defect# 36805
	/*
	 IF lc_send_mail='Y' THEN
            v_email_list    :='Sabrina.hernandezcruz@officedepot.com:SA-Compliance@officedepot.com';
  	        v_cc_email_list :=NULL;
	 ELSE
            v_email_list:='rama.dwibhashyam@officedepot.com';
            v_cc_email_list:='francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
	 END IF;
	 */
	IF lc_send_mail='Y' 
	THEN
		v_email_list    := v_zero_tolerance_mail;
		v_cc_email_list := v_cc_email;
	ELSE
		v_email_list    := v_exception_mail;
		v_cc_email_list := v_cc_email;
	END IF;		
	--
	-- End of changes as per version  to remove email address hard coding - Defect# 36805  	
	--

	     IF lc_grade ='Zero Tolerance' THEN
	        v_subject:= 'Zero Tolerance Notification for ';
         ELSIF lc_grade ='Denied Entry' THEN
	        v_subject:='Denied Entry Notification for ';
         END IF;

         v_subject:=v_subject||lc_sc_vendor||' / '||lc_factory_name||' / '||lc_agent||' / '||lc_region;

     v_text := v_text||chr(13);  
	 v_text := v_text||'The audit for '||lc_sc_vendor||' / '||lc_factory_name||' was conducted on '||TO_CHAR(ld_audit_schduled_date)||'.'||chr(10);
	 v_text := v_text||'The facility is graded as '||lc_grade||' based on the current assessment.';


        XX_PA_PB_COMPLIANCE_PKG.send_notification(v_subject,v_email_list,v_cc_email_list,v_text);

  END IF;



     IF lc_trans_status = 'Draft'  THEN
       v_text := null;
       v_text := v_text||chr(13);
       v_text := v_text||'This notification is to advise you that Vendor '||lc_sc_vendor ||'/'||lc_od_vendor_no||chr(13);
       v_text := v_text||chr(13);  
       v_text := v_text||'assigned to Factory '||lc_factory_name||'/'||lc_od_factory_no||' has received STR audit results.'||chr(10);
       v_text := v_text||chr(10);    
	   --v_text := v_text||'Inspecton No: '||lc_inspection_no||chr(10); --QC 22622      
	   v_text := v_text||'Inspection No: '||lc_inspection_no||chr(10);
       v_text := v_text||chr(10);              
	   v_text := v_text||'Agent: '||lc_agent||chr(10);
       v_text := v_text||chr(10);
	   v_text := v_text||'Grade: '||lc_grade||chr(10);
       v_text := v_text||chr(10);
	   v_text := v_text||'Audit Schedule Date: '||TO_CHAR(ld_audit_schduled_date)||chr(10);       
       v_text := v_text||chr(10);
	   v_text := v_text||'Vendor Address: '||lc_ven_address_1||chr(10);
       v_text := v_text||chr(10);       
	   v_text := v_text||'Factory Address: '||lc_base_address||' '||lc_city||' '||lc_state||' '||lc_country||chr(10);
       v_text := v_text||chr(10);              
       v_text := v_text||'Region: '||lc_region||chr(10);
       v_text := v_text||chr(10);              
       v_text := v_text||'Vendor Payment Received Date: '||ld_payment_date||chr(10);
       v_text := v_text||chr(10);              
       v_text := v_text||chr(10);              


       v_subject :='STR Draft Audit Results Received and Processed with Inspection No :'||lc_inspection_no;
	--
	-- Start of changes as per version  to remove email address hard coding - Defect# 36805
	/*
	   IF lc_send_mail='Y' THEN
           v_email_list:='sandy.stainton@officedepot.com:francia.pampillonia@officedepot.com';
    	   v_cc_email_list:='SA-Compliance@officedepot.com';
       ELSE
 	       v_email_list:='rama.dwibhashyam@officedepot.com';
  	       v_cc_email_list:='sandy.stainton@officedepot.com:francia.pampillonia@officedepot.com';
	   END IF;
	*/
	IF lc_send_mail='Y' 
	THEN
		v_email_list    := v_draft_mail;
		v_cc_email_list := v_cc_email;
	ELSE
		v_email_list    := v_exception_mail;
		v_cc_email_list := v_cc_email;
	END IF;		
	--
	-- End of changes as per version  to remove email address hard coding  - Defect# 36805	
	-- 
           XX_PA_PB_COMPLIANCE_PKG.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

     END IF;
    
     
     IF p_match_flag = 'N'  THEN
       v_text := null;
       v_text := v_text||chr(13); 
       v_text := v_text||'This notification is to advise you that Vendor '||lc_sc_vendor ||'/'||lc_od_vendor_no||''||chr(10);
       v_text := v_text||chr(10);       
       v_text := v_text||'assigned to Factory '||lc_factory_name||'/'||lc_od_factory_no||' has Mis-Matched Data with Vendor Master.'||chr(10);
       v_text := v_text||chr(10);      
       v_text := v_text||'Please verify the Staging Area.'||chr(10);   
       v_text := v_text||chr(10);          
	   --v_text := v_text||'Inspecton No: '||lc_inspection_no||chr(10);       --QC 22622
	   v_text := v_text||'Inspection No: '||lc_inspection_no||chr(10);       
       v_text := v_text||chr(10);              
	   v_text := v_text||'Agent: '||lc_agent||chr(10);
       v_text := v_text||chr(10);
	   v_text := v_text||'Grade: '||lc_grade||chr(10);
       v_text := v_text||chr(10);
	   v_text := v_text||'Audit Schedule Date: '||TO_CHAR(ld_audit_schduled_date)||chr(10);       
       v_text := v_text||chr(10);
	   v_text := v_text||'Vendor Address: '||lc_ven_address_1||chr(10);
       v_text := v_text||chr(10);       
	   v_text := v_text||'Factory Address: '||lc_base_address||' '||lc_city||' '||lc_state||' '||lc_country||chr(10);
       v_text := v_text||chr(10);              
       v_text := v_text||'Region: '||lc_region||chr(10);
       v_text := v_text||chr(10);              
       v_text := v_text||'Vendor Payment Received Date: '||ld_payment_date||chr(10);
       v_text := v_text||chr(10);              
       v_text := v_text||chr(10);              


       v_subject :='STR Final Audit Results Data Mis-Matched with Master Data, please verify. Inspection No: '||lc_inspection_no;
	--
	-- Start of changes as per version  to remove email address hard coding - Defect# 36805
	/*
	   IF lc_send_mail='Y' THEN
           v_email_list:='sandy.stainton@officedepot.com:francia.pampillonia@officedepot.com';
    	   v_cc_email_list:='SA-Compliance@officedepot.com';
       ELSE
 	       v_email_list:='rama.dwibhashyam@officedepot.com';
  	       v_cc_email_list:='sandy.stainton@officedepot.com:francia.pampillonia@officedepot.com';
	   END IF;
	*/
	IF lc_send_mail='Y' 
	THEN
		v_email_list    := v_mismatch_mail;
		v_cc_email_list := v_cc_email;
	ELSE
		v_email_list    := v_exception_mail;
		v_cc_email_list := v_cc_email;
	END IF;		
	--
	-- End of changes as per version  to remove email address hard coding  	- Defect# 36805
	-- 
           XX_PA_PB_COMPLIANCE_PKG.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

     END IF;
       


EXCEPTION
WHEN OTHERS THEN

  v_errbuf:='Error in When others in Send Notify :'||SQLERRM;
  v_retcode:=SQLCODE;
         IF lc_log_profile_value = 'Y'
         THEN
            
            log_exception (p_error_location          => 'XX_VENDOR_AUDIT_NOTIFY',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => v_errbuf
                          );
         END IF;
  
END vendor_audit_notify;                            


   PROCEDURE vendor_audit_result_pub (
      p_header_rec      IN       xx_qa_sc_header_match_rec_type,
      p_audit_rec       IN       xx_qa_sc_audit_rec_type,
      p_vendor_tbl      IN       xx_qa_sc_vendor_tbl_type,
      p_auditor_tbl     IN       xx_qa_sc_auditors_tbl_type,
      p_findings_tbl    IN       xx_qa_sc_findings_tbl_type,
      p_violation_tbl   IN       xx_qa_sc_violation_tbl_type,
      x_lc_return_cd    OUT      VARCHAR2,
      x_lc_return_msg   OUT      VARCHAR2
   )
   IS
-- Constant variables
      lc_log_profile_value          VARCHAR2 (10)
                                  := fnd_profile.VALUE ('XX_QA_SC_AUDIT_LOG');
      lc_process_status             VARCHAR2 (2)                       := '1';
      lc_org_code                   VARCHAR2 (10)                    := 'PRJ';
      lc_plan_name                  VARCHAR2 (50)     := 'OD_SC_VENDOR_AUDIT';
      lc_insert_type                VARCHAR2 (2)                       := '1';
      lc_matching_elements          VARCHAR2 (50) := 'OD_SC_INSPECTION_NO,OD_SC_INSERT_IFACE_ID';
      ln_vio_count                  NUMBER                               := 0;
      ln_find_count                 NUMBER                               := 0;
      ln_count                      NUMBER                               := 0;
      ln_audit_count                NUMBER                               := 0;
      lc_vend_exists_count          NUMBER                               := 0;
      ln_rec_count                  NUMBER                               := 0;
      ln_update_rec_count           NUMBER                               := 0;
-- ******* temporary variables for Header Record *********************
      lc_message_invoke_for         VARCHAR2 (100);
      lc_vendor_id                  NUMBER;                  --VARCHAR2(150);
      lc_vendor_name                VARCHAR2 (150);
      lc_msg_time                   DATE;
-- *******temporary variables for Audit Record ***********************
      lc_trans_status               VARCHAR2 (150);
      lc_client                     VARCHAR2 (150);
      lc_inspection_no              VARCHAR2 (150);
      lc_inspection_id              VARCHAR2 (150);
      lc_inspection_type            VARCHAR2 (150);
      lc_service_type               VARCHAR2 (150);
      lc_qa_profile                 VARCHAR2 (150);
      lc_status                     VARCHAR2 (150);
      ld_complete_by_start_date     DATE;
      ld_complete_by_end_date       DATE;
      ld_audit_schduled_date        DATE;
      ld_inspection_date            DATE;
      lc_inspection_time_in         VARCHAR2 (10);
      lc_inspection_time_out        VARCHAR2 (10);
      ld_inspection_schduled_date   DATE;
      ld_initial_inspection_date    DATE;
      lc_relationships              VARCHAR2 (150);
      ld_inspectors_schduled        VARCHAR2 (150);
      lc_inspection_month           VARCHAR2 (10);
      lc_inspection_year            VARCHAR2 (4);
-- ************temporary variables for VEMDOR Record table type**************
-- *****Not using for this release ******
      lc_od_vendor_no               VARCHAR2 (150);
      lc_sc_vendor                  VARCHAR2 (150);
--lc_vendor_address        contact_add_Rec_Type;
--lc_vendor_contact      vend_contact_Rec_Type;
      lc_entity_id                  VARCHAR2 (150);
      lc_od_factory_no              VARCHAR2 (150);
      lc_factory_name               VARCHAR2 (150);
      lc_base_address               VARCHAR2 (150);
      lc_city                       VARCHAR2 (150);
      lc_state                      VARCHAR2 (150);
      lc_country                    VARCHAR2 (150);
--lc_factory_contacts          vend_contact_Rec_Type;
      lc_factory_status             VARCHAR2 (150);
      lc_factory_contacts           VARCHAR2 (150);
      lc_invoice_no                 VARCHAR2 (150);
      ld_invoice_date               DATE;
      lc_invoice_amount             VARCHAR2 (150);
      lc_payment_method             VARCHAR2 (150);
      ld_payment_date               DATE;
      lc_payment_amount             VARCHAR2 (150);
      lc_grade                      VARCHAR2 (150);
      lc_region                     VARCHAR2 (150);
      lc_sub_region                 VARCHAR2 (150);
      lc_ven_contact_name           VARCHAR2 (150);
      lc_ven_address_1              VARCHAR2 (150);
      lc_ven_address_2              VARCHAR2 (150);
      lc_ven_address_3              VARCHAR2 (150);
      lc_ven_address_4              VARCHAR2 (150);
      lc_ven_address_city           VARCHAR2 (150);
      lc_ven_address_state          VARCHAR2 (150);
      lc_ven_address_country        VARCHAR2 (150);
      lc_ven_contact_type           VARCHAR2 (150);
      lc_ven_contact_no             VARCHAR2 (150);
      lc_contact_address            VARCHAR2 (150);
      lc_contact_address_1          VARCHAR2 (150);
      lc_contact_address_2          VARCHAR2 (150);
      lc_contact_ddress_3           VARCHAR2 (150);
      lc_contact_address_4          VARCHAR2 (150);
      lc_contact_address_city       VARCHAR2 (150);
      lc_contact_address_state      VARCHAR2 (150);
      lc_contact_address_country    VARCHAR2 (150);
      lc_ven_contact                VARCHAR2 (150);
      lc_agent                      VARCHAR2 (150);
      lc_rush_audit                 VARCHAR2 (150);
      lc_fact_contact_type          VARCHAR2 (150);
      lc_fact_contact_no            VARCHAR2 (150);
      lc_factory_phone              VARCHAR2 (150);
-- ***************temporary variables for AUDITORS Record table type ***********
-- *****Not using for this release ******
      lc_od_sc_auditor_name         VARCHAR2 (150)                      := '';
      lc_od_sc_auditor_level        VARCHAR2 (150)                      := '';
-- temporary variables for FINDINGS Record table type
      lc_question_code              VARCHAR2 (150);
      lc_section                    VARCHAR2 (150);
      lc_sub_section                VARCHAR2 (150);
      lc_question                   VARCHAR2 (150);
      lc_answer                     VARCHAR2 (150);
      lc_nayn                       VARCHAR2 (40);
      lc_auditor_comments           VARCHAR2 (2000);
-- temporary variables for VIOLATIONS Record table type
      lc_viol_code                  VARCHAR2 (150);
      lc_viol_flag                  VARCHAR2 (150);
      lc_viol_text                  VARCHAR2 (150);
      lc_viol_section               VARCHAR2 (150);
      lc_viol_sub_section           VARCHAR2 (150);
      lc_viol_question              VARCHAR2 (150);
      lc_viol_auditor_comments      VARCHAR2 (2000);
      lc_interface_error_status     VARCHAR2 (3)                      := NULL;
--lx_return_cd VARCHAR2(100);
--lx_return_msg VARCHAR2(100);
      lc_dft_vendor_id              VARCHAR2 (150);
      lc_dft_vendor_name            VARCHAR2 (150);
      lc_dft_region                 VARCHAR2 (150);
      lc_dft_region_sub             VARCHAR2 (150);
      lc_dft_service_type           q_od_sc_vendor_audit_v.od_sc_service_type%TYPE;
                                                             --VARCHAR2(150);
      lc_dft_factory_id             VARCHAR2 (150);
      lc_dft_agent                  VARCHAR2 (150);
      lc_dft_grade                  VARCHAR2 (150);
      ld_dft_inspect_date           DATE;
      lc_dft_vendor_addr            varchar2(150);
      lc_dft_factory_name           varchar2(150);
      lc_dft_factory_addr           varchar2(150);
      lc_dft_europe_region          varchar2(150);
      lc_dft_mexico_region          varchar2(150);
      lc_dft_asia_region            varchar2(150);
      lc_dft_us_region              varchar2(150);      
      lc_match_flag                 VARCHAR2 (1)                       := 'Y';
      lc_match_msg                  VARCHAR2 (2500)
                               := 'Final Data was not matched with Drfat for';
      v_request_id                  NUMBER;
      v_user_id                     NUMBER              := fnd_global.user_id;
      lc_user_name                  VARCHAR2(150) ;
      lc_log_msg                    VARCHAR2 (2000);
      x_return_cd                   VARCHAR2 (100);
      x_return_msg                  VARCHAR2 (2000);
      ld_sysdate                    DATE;
      lc_sysdate                    VARCHAR2 (40);
      ln_plan_id                    NUMBER;
      ln_occurrence_id              NUMBER;
      v_nextaudit_date	            date;
      
      
   BEGIN                                                            -- begin 1
-- ************* Audit Log************************************************************************************
-- #############################################################################################################

       lc_user_name := '499103';
       
      select user_id 
        into v_user_id
        from fnd_user
       where user_name = lc_user_name ;
       
      IF lc_log_profile_value = 'Y'
      THEN
         SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS')
           INTO lc_sysdate
           FROM DUAL;

         lc_log_msg :=
               'STEP-1 '
            || p_audit_rec.transmission_status
            || ' message Received at '
            || lc_sysdate
            || ' For Inspection No '
            || p_audit_rec.inspection_no;
         log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_PKG',
                        p_error_message_code      => 'XX_QA_LOG_MSG',
                        p_error_msg               => lc_log_msg
                       );
      
      END IF;

-- #############################################################################################################
      x_return_cd := 'Y';
      ln_find_count := p_findings_tbl.COUNT;
      ln_vio_count := p_violation_tbl.COUNT;
      lc_trans_status := p_audit_rec.transmission_status;
      

-- *************************Logic to set the process status either Insert or Update*************************
-- #############################################################################################################
      IF TRIM (UPPER (lc_trans_status)) = 'DRAFT'
      THEN
         lc_process_status := '1';
         lc_insert_type    := '1' ; 

         -- Audit Log
         IF lc_log_profile_value = 'Y'
         THEN
            lc_log_msg :=
                  'STEP-2'
               || ' Draft Version.process status is '
               || lc_process_status;
            log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_PKG',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => lc_log_msg
                          );
         END IF;
      ELSE
         SELECT COUNT (*)
           INTO ln_audit_count
           FROM q_od_sc_vendor_audit_v
          WHERE od_sc_inspection_no = p_audit_rec.inspection_no
            AND UPPER (od_sc_transmission_status) = 'DRAFT';

         IF ln_audit_count > 0
         THEN
            lc_process_status := '1';
            lc_insert_type := '2' ; 
            

            -- Audit Log
            IF lc_log_profile_value = 'Y'
            THEN
               lc_log_msg :=
                     'STEP-2A'
                  || ' Final Version has Draft record exists.process status: '
                  || lc_process_status;
               log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_PKG',
                              p_error_message_code      => 'XX_QA_LOG_MSG',
                              p_error_msg               => lc_log_msg
                             );
            END IF;
         ELSE
           lc_process_status := '3';
           lc_insert_type := '2' ;

            -- Audit Log
            IF lc_log_profile_value = 'Y'
            THEN
               lc_log_msg :=
                     'STEP-2B'
                  || ' Final Version received but no Draft record exists.Process status '
                  || lc_process_status;
               log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_PKG',
                              p_error_message_code      => 'XX_QA_LOG_MSG',
                              p_error_msg               => lc_log_msg
                             );
            END IF;
         END IF;
      END IF;

--**************************************End for Process status*************************************************
-- #############################################################################################################
-- ************************************** Checking the Vendor is exists are not in the system ******************
-- #############################################################################################################
      BEGIN                                                          --Begin 2
--         SELECT COUNT (*)
--           --od_sc_vendor_no,od_sc_vendor_name
--         INTO   lc_vend_exists_count
--           --lc_venodr_id,lc_venodr_name
--         FROM   q_od_pb_sc_vendor_master_v vmast
--          WHERE (vmast.od_sc_vendor_number = p_vendor_tbl (1).od_vendor_no 
--                or vmast.od_sc_vendor_name like substr(p_vendor_tbl (1).vendor,1,15)||'%')
--            AND (vmast.od_sc_factory_number = p_vendor_tbl (1).od_factory_no 
--                or vmast.od_sc_factory_name like substr(p_vendor_tbl (1).vendor_attribute1,1,15)||'%')
--            AND ROWNUM < 2; 
-- added the following function call to include the regional collection plans 
           lc_vend_exists_count := get_vendor_count (p_header_rec,p_audit_rec,p_vendor_tbl) ;    
         -- **********************************Setting process status as  Error(3) if vendor doesn't exists********************
         IF lc_vend_exists_count = 0
         THEN
            lc_interface_error_status := 'E';
            lc_process_status := '3';

            -- Audit Log
            IF lc_log_profile_value = 'Y'
            THEN
               lc_log_msg :=
                     'STEP-3'
                  || ' Vendor does not exists. Received Vendor is :  '
                  || p_vendor_tbl (1).vendor;
               log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_PKG',
                              p_error_message_code      => 'XX_QA_LOG_MSG',
                              p_error_msg               => lc_log_msg
                             );
            END IF;
         END IF;
      EXCEPTION                                       -- Exception for begin 2
         WHEN OTHERS
         THEN
            x_return_msg :=
                  'Unexpected Error in Querying Vendor for '
               || p_vendor_tbl (1).vendor;
            x_return_cd := 'N';

            -- Audit Log
            IF lc_log_profile_value = 'Y'
            THEN
               x_return_msg := 'EXCEPTION-2' || x_return_msg;
               log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_PKG',
                              p_error_message_code      => 'XX_QA_LOG_MSG',
                              p_error_msg               => x_return_msg
                             );
            END IF;
      END;                                                  -- End for Begin 2
      
      
--*******************************************--
--***** code added for notification
      IF TRIM (UPPER (lc_trans_status)) = 'DRAFT'
      THEN
          vendor_audit_notify( p_header_rec    => p_header_rec
                              ,p_audit_rec     => p_audit_rec
                              ,p_vendor_tbl    => p_vendor_tbl
                              ,p_match_flag    => lc_match_flag
                              ,x_errbuf        => x_return_msg
                              ,x_retcode       => x_return_cd
                              );
                              
       END IF;

--*******************************************--      

-- *************************************************************************************************************
-- #############################################################################################################
-- *********** Looking for the count of Findings and Violations ************************************************
-- #############################################################################################################
      SELECT GREATEST ((SELECT ln_find_count
                          FROM DUAL), (SELECT ln_vio_count
                                         FROM DUAL))
        INTO ln_count
        FROM DUAL;

-- *******************************************************************************
-- ***************Header Rec************************************* **********************************************
-- #############################################################################################################
      lc_message_invoke_for := p_header_rec.message_invoke_for;
      lc_vendor_id := p_header_rec.vendor_id;
      lc_vendor_name := p_header_rec.vendor_name;
      lc_msg_time := p_header_rec.msg_date_time;
--  ************Audit Rec****************************************
      lc_trans_status := p_audit_rec.transmission_status;
      lc_client := p_audit_rec.client;
      lc_inspection_no := p_audit_rec.inspection_no;
      lc_inspection_id := p_audit_rec.inspection_id;
      lc_inspection_type := p_audit_rec.inspection_type;
      lc_service_type := p_audit_rec.service_type;
      lc_qa_profile := p_audit_rec.qa_profile;
      lc_status := p_audit_rec.status;
      ld_complete_by_start_date := p_audit_rec.complete_by_start_date;
      ld_complete_by_end_date := p_audit_rec.complete_by_end_date;
      ld_audit_schduled_date := p_audit_rec.audit_schduled_date;
      ld_inspection_date := p_audit_rec.inspection_date;
      lc_inspection_time_in := p_audit_rec.inspection_time_in;
      lc_inspection_time_out := p_audit_rec.inspection_time_out;
      ld_inspection_schduled_date := p_audit_rec.inspection_schduled_date;
      ld_initial_inspection_date := p_audit_rec.initial_inspection_date;
      lc_relationships := p_audit_rec.relationships;
      ld_inspectors_schduled := p_audit_rec.inspectors_schduled;
      lc_inspection_month := p_audit_rec.inspection_month;
      lc_inspection_year := p_audit_rec.inspection_year;
      lc_rush_audit := p_audit_rec.attribute1;

-- Expecting One record only for this release 11.3
      FOR j IN 1 .. p_vendor_tbl.COUNT
      LOOP
         lc_od_vendor_no := p_vendor_tbl (j).od_vendor_no;
         lc_sc_vendor := p_vendor_tbl (j).vendor;
         lc_entity_id := p_vendor_tbl (j).entity_id;
         lc_factory_name := p_vendor_tbl (j).vendor_attribute1;
         lc_od_factory_no := p_vendor_tbl (j).od_factory_no;
         lc_factory_name := p_vendor_tbl (j).vendor_attribute1;
         lc_base_address := p_vendor_tbl (j).base_address;
         lc_city := p_vendor_tbl (j).city;
         lc_state := p_vendor_tbl (j).state;
         lc_country := p_vendor_tbl (j).country;
         lc_factory_status := p_vendor_tbl (j).factory_status;
         lc_invoice_no := p_vendor_tbl (j).invoice_no;
         ld_invoice_date := p_vendor_tbl (j).invoice_date;
         lc_invoice_amount := p_vendor_tbl (j).invoice_amount;
         lc_payment_method := p_vendor_tbl (j).payment_method;
         ld_payment_date := p_vendor_tbl (j).payment_date;
         lc_payment_amount := p_vendor_tbl (j).payment_amount;
         lc_grade := p_vendor_tbl (j).grade;
         lc_region := p_vendor_tbl (j).region;
         lc_sub_region := p_vendor_tbl (j).sub_region;
         lc_ven_address_1 := p_vendor_tbl (j).vendor_address.address_1;
         lc_agent := p_vendor_tbl (j).vendor_attribute2;
---      
     --    for p in 1.. p_vendor_tbl.vendor_contact.last loop
      --   
      --   lc_ven_contact_name := p_vendor_tbl.vendor_contact(p).contact_name;
       --  end loop;
        
         lc_ven_contact_name := p_vendor_tbl (j).vendor_contact.contact_name;

         lc_ven_contact_type :=
                   p_vendor_tbl (j).vendor_contact.contact_phone.contact_type;
         lc_ven_contact_no :=
                     p_vendor_tbl (j).vendor_contact.contact_phone.contact_no;
         lc_ven_contact := lc_ven_contact_type || ':' || lc_ven_contact_no;
         
---         
         lc_factory_contacts :=
                               p_vendor_tbl (j).factory_contacts.contact_name;
         lc_fact_contact_type :=
                 p_vendor_tbl (j).factory_contacts.contact_phone.contact_type;
         lc_fact_contact_no :=
                   p_vendor_tbl (j).factory_contacts.contact_phone.contact_no;
         lc_factory_phone :=
                            lc_fact_contact_type || ':' || lc_fact_contact_no;
      END LOOP;

      FOR k IN 1 .. p_auditor_tbl.COUNT
      LOOP
          lc_od_sc_auditor_name :=
               lc_od_sc_auditor_name
            || p_auditor_tbl (k).od_sc_auditor_name
            || ',';
         lc_od_sc_auditor_level :=
               lc_od_sc_auditor_level
            || p_auditor_tbl (k).od_sc_auditor_level
            || ',';
      END LOOP;

-- *************************** Looping Findings and Violations Tbl type ***************************************
-- #############################################################################################################
--dbms_output.put_line('**********Finding Table*****************');
      FOR i IN 1 .. ln_count
      LOOP                                                  -- Loop for Insert
         --dbms_output.put_line('---------count ....' || i);
         IF i <= p_findings_tbl.COUNT
         THEN
            --dbms_output.put_line('---------In Finding Loop count ....' || i);
            lc_question_code := p_findings_tbl (i).question_code;
            lc_question := p_findings_tbl (i).question;
            lc_answer := p_findings_tbl (i).answer;
            lc_section := p_findings_tbl (i).section;
            lc_sub_section := p_findings_tbl (i).sub_section;
            if p_findings_tbl(i).nayn = '0'
            then
            lc_nayn := 'Applicable';
            else
            lc_nayn := 'Not Applicable';
            end if;
            lc_auditor_comments := p_findings_tbl (i).auditor_comments;
         END IF;

         IF i <= p_violation_tbl.COUNT
         THEN
            --dbms_output.put_line('---------In violation Loop count ....' || i);
            lc_viol_code := p_violation_tbl (i).viol_code;
            lc_viol_question := p_violation_tbl (i).viol_question;
            lc_viol_text := p_violation_tbl (i).viol_text;
            lc_viol_flag := p_violation_tbl (i).viol_flag;
            lc_viol_section := p_violation_tbl (i).viol_section;
            lc_viol_sub_section := p_violation_tbl (i).viol_sub_section;
            lc_viol_auditor_comments :=
                                    p_violation_tbl (i).viol_auditor_comments;
         END IF;

-- *************************** Inserting Data into IV **********************************************************
-- #############################################################################################################
         INSERT INTO q_od_sc_vendor_audit_iv
                     (process_status, organization_code, plan_name,
                      insert_type, matching_elements,
                      qa_created_by_name, qa_last_updated_by_name,
                      od_sc_transmission_status, od_sc_client,
                      od_sc_inspection_no, od_sc_inspection_id,
                      od_sc_inspection_type, od_sc_service_type,
                      od_sc_qaprofile, od_sc_status,
                      od_sc_complete_by_start_date,
                      od_sc_complete_by_end_date, od_sc_scheduled_date,
                      od_sc_inspect_date, od_sc_time_in,
                      od_sc_time_out, od_sc_scheduled_time,
                      od_sc_init_inspection_date, od_sc_relationships,
                      od_sc_no_inspectors_schd, od_sc_inspection_month,
                      od_sc_inspection_year, od_sc_rush_audit_yn,
                      od_sc_od_vendor_id, od_sc_vendor, od_sc_vendor_address,
                      od_sc_vendor_contacts, od_sc_vendor_phones,
                      od_sc_entity_id, od_sc_factory_id, od_sc_factory,
                      od_sc_factory_addr, od_sc_fact_city,
                      od_sc_factory_state, od_sc_origin_country,
                      od_sc_factory_contacts, od_sc_fact_phone,
                      od_sc_factory_status, od_sc_vendor_invoice_no,
                      od_sc_vendor_invoice_date, od_sc_vendor_invoice_amt,
                      od_sc_payment_method, od_sc_ven_invoice_payment_date,
                      od_sc_ven_invoice_payment_amt, od_sc_grade,
                      od_sc_region, od_sc_region_sub, od_sc_agent,
                      od_sc_auditor_name, od_sc_auditor_level,
                      od_sc_question_code, od_sc_section, od_sc_sub_section,
                      od_sc_question, od_sc_answer,
                      od_sc_question_applicable, od_sc_auditor_comments,
                      od_sc_violation_code, od_sc_violat,
                      od_sc_violation_text, od_sc_violation_section,
                      od_sc_violation_sub_section, od_sc_violation_question,
                      od_sc_auditor_comments_viol, od_sc_insert_iface_id
                     )
              VALUES (lc_process_status, lc_org_code, lc_plan_name,
                      lc_insert_type                         --1 for INSERT
                                       , lc_matching_elements,
                      lc_user_name, lc_user_name,
                      lc_trans_status, lc_client,
                      lc_inspection_no, lc_inspection_id,
                      lc_inspection_type, lc_service_type,
                      lc_qa_profile, lc_status,
                      ld_complete_by_start_date,
                      ld_complete_by_end_date, ld_audit_schduled_date,
                      ld_inspection_date, lc_inspection_time_in,
                      lc_inspection_time_out, ld_inspection_schduled_date,
                      ld_initial_inspection_date, lc_relationships,
                      ld_inspectors_schduled, lc_inspection_month,
                      lc_inspection_year, lc_rush_audit,
                      lc_od_vendor_no, lc_sc_vendor, lc_ven_address_1,
                      lc_ven_contact_name, lc_ven_contact,
                      lc_entity_id, lc_od_factory_no, lc_factory_name,
                      lc_base_address, lc_city,
                      lc_state, lc_country,
                      lc_factory_contacts, lc_factory_phone,
                      lc_factory_status, lc_invoice_no,
                      ld_invoice_date, lc_invoice_amount,
                      lc_payment_method, ld_payment_date,
                      lc_payment_amount, lc_grade,
                      lc_region, lc_sub_region, lc_agent,
                      lc_od_sc_auditor_name, lc_od_sc_auditor_level,
                      lc_question_code, lc_section, lc_sub_section,
                      lc_question, lc_answer,
                      lc_nayn, lc_auditor_comments,
                      lc_viol_code, lc_viol_flag,
                      lc_viol_text, lc_viol_section,
                      lc_viol_sub_section, lc_viol_question,
                      lc_viol_auditor_comments, i
                     );

         COMMIT;
--
         lc_question_code := '';
         lc_question := '';
         lc_answer := '';
         lc_section := '';
         lc_sub_section := '';
         lc_nayn := '';
         lc_auditor_comments := '';
         lc_viol_code := '';
         lc_viol_question := '';
         lc_viol_text := '';
         lc_viol_flag := '';
         lc_viol_section := '';
         lc_viol_sub_section := '';
         lc_viol_auditor_comments := '';
         ln_rec_count := ln_rec_count + 1;
      END LOOP;                                        --  End Loop for Insert

--- *****************************END INSERT *******************************************************
-- #############################################################################################################
                        -- Audit Log
      IF lc_log_profile_value = 'Y'
      THEN
         SELECT TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI:SS')
           INTO lc_sysdate
           FROM DUAL;

         lc_log_msg :=
               'STEP-4 Inserted Record count is '
            || ln_rec_count
            || ' With mode '
            || lc_process_status
            || ' at '
            || lc_sysdate
            || ' Process Status is: '
            || lc_process_status;
         log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_PKG',
                        p_error_message_code      => 'XX_QA_LOG_MSG',
                        p_error_msg               => lc_log_msg
                       );
      END IF;

-- *************************** Process continues Call Import prgogram ************
-- ###################################################################################################################
--************************************************************************************************************
      IF lc_process_status = '1'  ---and lc_insert_type = '2'
      THEN
         -- Audit Log
         IF lc_log_profile_value = 'Y'
         THEN
            SELECT TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI:SS')
              INTO lc_sysdate
              FROM DUAL;

            lc_log_msg :=
                     'STEP-5 Veifying the Draft Data ' || ' at ' || lc_sysdate;
            log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_PKG',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => lc_log_msg
                          );
         END IF;

         BEGIN                                                      -- Begin 3


            IF lc_match_flag = 'Y' and lc_insert_type = '2'
            THEN
-- **************** Before calling Import Match the data with Master Data Incase of Final version**************
-- #############################################################################################################
     
            lc_match_flag := get_vendor_match( p_header_rec
                                             ,p_audit_rec     
                                             ,p_vendor_tbl    
                                            ) ;
              -- Audit Log
               IF lc_log_profile_value = 'Y'
               THEN
                  SELECT TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI:SS')
                    INTO lc_sysdate
                    FROM DUAL;

                  lc_log_msg :=
                            'STEP-6 Matching the Master data at ' || lc_sysdate;
                  log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_PKG',
                                 p_error_message_code      => 'XX_QA_LOG_MSG',
                                 p_error_msg               => lc_log_msg
                                );
               END IF;

 -- **************************** Comparing the Master values With Final***********************************
-- #############################################################################################################
               IF lc_match_flag = 'N'
               THEN
                    vendor_audit_notify( p_header_rec    => p_header_rec
                      ,p_audit_rec     => p_audit_rec
                      ,p_vendor_tbl    => p_vendor_tbl
                      ,p_match_flag    => lc_match_flag
                      ,x_errbuf        => x_return_msg
                      ,x_retcode       => x_return_cd
                      );
                  
                  
                  lc_match_msg :=
                        lc_match_msg
                     || ' Vendor ID '
                     || lc_dft_vendor_id
                     || ' and '
                     || lc_od_vendor_no;
                     
                     
                 update q_od_sc_vendor_audit_iv
                    set process_status = '3'
                  where od_sc_inspection_no = lc_inspection_no ;

                  -- Audit Log
                  IF lc_log_profile_value = 'Y'
                  THEN
                     lc_log_msg :=
                              'STEP-7 Data Matched Flag is ' || lc_match_flag;
                     log_exception
                          (p_error_location          => 'XX_QA_SC_VEN_AUDIT_BPEL_PKG',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => lc_match_msg
                          );
                  END IF;
               END IF;

-- *********************************** End Comparison **********************************************************

            END IF;                                -- End of If process status

            BEGIN                                                   -- Begin 4
-- #############################################################################################################
-- ********** If the Final Data matches with Master data SUBMIT IMPORT PROGRAM *********************************
-- #############################################################################################################
               IF lc_match_flag = 'Y'
               THEN
                  --lc_match_flag := 'N';
                  v_request_id :=
                     fnd_request.submit_request ('QA',
                                                 'QLTTRAMB',
                                                 'Collection Import Manager',
                                                 NULL,
                                                 FALSE,
                                                 '200',
                                                 lc_insert_type,
                                                 TO_CHAR (v_user_id),
                                                 'Yes'
                                                );

                  -- Audit Log
                  IF lc_log_profile_value = 'Y'
                  THEN
                     SELECT TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI:SS')
                       INTO lc_sysdate
                       FROM DUAL;

                     lc_log_msg :=
                          'STEP-9 Submitted Import Program at: ' || lc_sysdate;
                     log_exception
                           (p_error_location          => 'XX_QA_SC_VEN_AUDIT_BPEL_PKG',
                            p_error_message_code      => 'XX_QA_LOG_MSG',
                            p_error_msg               => lc_log_msg
                           );
                  END IF;

-- ********** Verfify Status of Import program ************************************************************
-- #########################################################################################################
                  IF v_request_id > 0
                  THEN                             -- Import Program Successul
                     COMMIT;

                     -- Audit Log
                     IF lc_log_profile_value = 'Y'
                     THEN
                        SELECT TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI:SS')
                          INTO lc_sysdate
                          FROM DUAL;

                        lc_log_msg :=
                              'STEP-10 Import Program completed Successfully at: '
                           || lc_sysdate||'with Request ID:'||v_request_id;
                        log_exception
                           (p_error_location          => 'XX_QA_SC_VEN_AUDIT_BPEL_PKG',
                            p_error_message_code      => 'XX_QA_LOG_MSG',
                            p_error_msg               => lc_log_msg
                           );
                     END IF;

-- ********** Update vendor master ***********************************************************************
-- #########################################################################################################

                   IF TRIM (UPPER (lc_trans_status)) = 'FINAL'
                   THEN
                   
                       update_vendor_data(p_header_rec => p_header_rec
                                         ,p_audit_rec  => p_audit_rec  
                                         ,p_vendor_tbl => p_vendor_tbl  
                                         );
                   

                   END IF;                      -- End if 
                  ELSE                        -- Import program not successful
                     -- Audit Log
                     IF lc_log_profile_value = 'Y'
                     THEN
                        SELECT TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI:SS')
                          INTO lc_sysdate
                          FROM DUAL;

                        lc_log_msg :=
                            'STEP-10 Import Program Failed at: ' || lc_sysdate;
                        log_exception
                           (p_error_location          => 'XX_QA_SC_VEN_AUDIT_BPEL_PKG',
                            p_error_message_code      => 'XX_QA_LOG_MSG',
                            p_error_msg               => lc_log_msg
                           );
                     END IF;
                  END IF;
-- ***********************************End Status of Import Progrm*******************************************
-- #############################################################################################################
               ELSE
                  -- Audit Log
                  IF lc_log_profile_value = 'Y'
                  THEN
                     lc_log_msg :=
                         'STEP-8 Draft data Match Flag is: ' || lc_match_flag;
                     log_exception
                          (p_error_location          => 'XX_QA_SC_VEN_AUDIT_BPEL_PKG',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => lc_log_msg
                          );
                  END IF;
-- ***********************************************************************************************************
               END IF;
            EXCEPTION                                 -- Exception for begin 4
               WHEN OTHERS
               THEN
                  x_return_cd := 'Y';
                  x_return_msg := 'Error in Executing Concurrent Program';

                  -- Audit Log
                  IF lc_log_profile_value = 'Y'
                  THEN
                     lc_log_msg := 'EXCEPTION-4 ' || x_return_msg;
                     log_exception
                          (p_error_location          => 'XX_QA_SC_VEN_AUDIT_BPEL_PKG',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => lc_log_msg
                          );
                  END IF;
            END;                                            -- End for Begin 4
         EXCEPTION                                    -- Exception for Begin 3
            WHEN NO_DATA_FOUND
            THEN
               x_return_cd := 'Y';
               x_return_msg :=
                          'Received Final Audit report no draft record found';

               -- Audit Log
               IF lc_log_profile_value = 'Y'
               THEN
                  lc_log_msg := 'EXCEPTION-3 ' || x_return_msg;
                  log_exception
                          (p_error_location          => 'XX_QA_SC_VEN_AUDIT_BPEL_PKG',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => lc_log_msg
                          );
               END IF;
            WHEN OTHERS
            THEN
               x_return_cd := 'N';
               x_return_msg :=
                     'Unexpected Error occured while matching the data with Master'
                  || SQLERRM;

               -- Audit Log
               IF lc_log_profile_value = 'Y'
               THEN
                  lc_log_msg := 'EXCEPTION-3 ' || x_return_msg;
                  log_exception
                          (p_error_location          => 'XX_QA_SC_VEN_AUDIT_BPEL_PKG',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => lc_log_msg
                          );
               END IF;
         END;                                               -- End for Begin 3

         x_return_cd := lc_match_flag;
         x_return_msg := lc_match_msg;
      END IF;                                -- End if for Process status is 2
COMMIT;
      x_lc_return_cd := 'Y';
      x_lc_return_cd := 'success';
--dbms_output.put_line('Return Code....' ||  x_return_cd);
   EXCEPTION                                          -- Exception for Begin 1
      WHEN OTHERS
      THEN
         x_lc_return_cd := 'N';
         x_lc_return_msg :=
               'Unexpected Error in Executing the Audit Result Pacakge'
            || lc_od_sc_auditor_name
            || SQLERRM;

         -- Audit Log
         IF lc_log_profile_value = 'Y'
         THEN
            lc_log_msg := 'EXCEPTION-1 ' || x_lc_return_msg;
            log_exception (p_error_location          => 'XX_QA_SC_VEN_AUDIT_BPEL_PKG',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => lc_log_msg
                          );
         END IF;
   END vendor_audit_result_pub;                             -- End for begin 1
   
PROCEDURE audit_reprocess(  x_errbuf      OUT NOCOPY VARCHAR2
                           ,x_retcode     OUT NOCOPY NUMBER
                           ,p_trans_status    IN VARCHAR2
                           ,p_inspection_no   IN VARCHAR2
                           ,p_vendor_no       IN VARCHAR2
                           ,p_vendor_name     IN VARCHAR2
                           ,p_vendor_addr     IN VARCHAR2
                           ,p_factory_no      IN VARCHAR2
                           ,p_factory_name    IN VARCHAR2
                           ,p_factory_addr    IN VARCHAR2
                           ,p_agent           IN VARCHAR2
                           ,p_region          IN VARCHAR2
                            ) IS
                            
 
 lc_log_profile_value  VARCHAR2(1):= fnd_profile.VALUE ('XX_QA_SC_AUDIT_LOG'); 
 lc_log_msg            VARCHAR2(2000); 
 v_nextaudit_date	   date;
 v_request_id          number;
 v_user_id             number;
 ln_plan_id            number;
 ln_occurrence_id      number;
 ln_us_plan_id         number;
 ln_us_occurrence_id   number;
 ln_eu_plan_id         number;
 ln_eu_occurrence_id   number;
 ln_asia_plan_id         number;
 ln_asia_occurrence_id   number;  
 ln_mx_plan_id         number;
 ln_mx_occurrence_id   number; 
 lc_schedule_date      date;
 lc_trans_status       varchar2(150);
 lc_inspection_no      varchar2(150);
 lc_grade              varchar2(150);
 ld_audit_schduled_date date;
 ld_inspection_date     date;
 lc_inspection_type     varchar2(150);      
 lc_vendor_no           varchar2(150);
 lc_vendor_name         varchar2(150);
 lc_vendor_address      varchar2(150);
 lc_factory_no          varchar2(150);
 lc_factory_name        varchar2(150);
 lc_factory_address     varchar2(150);
 lc_region              varchar2(150);
 lc_agent               varchar2(150);
 ld_payment_date        date;
 ld_nextaudit_date      date;
 
 

    cursor cur_aud is
    select *
    from q_od_sc_vendor_audit_iv
    where process_status = 3
      and plan_name = 'OD_SC_VENDOR_AUDIT'
      and od_sc_inspection_no = p_inspection_no
      and od_sc_transmission_status = p_trans_status;    
      
     cursor cur_qri is 
     select distinct insert_type,
            od_sc_od_vendor_id,
            od_sc_vendor,
            od_sc_vendor_address,
            od_sc_factory_id,
            od_sc_factory,
            od_sc_factory_addr,
            od_sc_region,od_sc_agent,od_sc_ven_invoice_payment_date,
            od_sc_grade,od_sc_scheduled_date,od_sc_inspect_date,
            od_sc_inspection_type
      from q_od_sc_vendor_audit_iv 
     where od_sc_inspection_no = p_inspection_no
       and plan_name = 'OD_SC_VENDOR_AUDIT'
       and process_status = 1
       and od_sc_transmission_status = p_trans_status;
       
       
              
--
            CURSOR cur_us (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2) IS
             SELECT vmast.plan_id
                   ,vmast.occurrence
              FROM q_od_pb_sc_vendor_master_v vmast
             WHERE (upper(vmast.od_sc_vendor_number) = upper(lc_vendor_no) 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND upper(vmast.od_sc_factory_number) = upper(lc_factory_no) 
               AND upper(vmast.od_sc_factory_name) like substr(upper(lc_factory_name),1,15)||'%'
               AND ROWNUM < 2; 
               
            CURSOR cur_eu (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2) IS
             SELECT vmast.plan_id
                   ,vmast.occurrence
              FROM q_od_sc_eu_vendor_master_v vmast
             WHERE (upper(vmast.od_sc_vendor_number) = upper(lc_vendor_no) 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND (upper(vmast.od_sc_factory_number) = upper(lc_factory_no) 
                    or upper(vmast.od_sc_factory_name) like upper(lc_factory_name)||'%')
               AND ROWNUM < 2;
               
            CURSOR cur_asia (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2) IS
             SELECT vmast.plan_id
                   ,vmast.occurrence
              FROM q_od_sc_asia_vendor_master_v vmast
             WHERE (upper(vmast.od_sc_vendor_number) = upper(lc_vendor_no) 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND (upper(vmast.od_sc_factory_number) = upper(lc_factory_no) 
                    or upper(vmast.od_sc_factory_name) like upper(lc_factory_name)||'%')
               AND ROWNUM < 2;
               
            CURSOR cur_mx (lc_vendor_no varchar2,lc_vendor_name varchar2,
                           lc_factory_no varchar2,lc_factory_name varchar2) IS
             SELECT vmast.plan_id
                   ,vmast.occurrence
              FROM q_od_sc_mx_vendor_master_v vmast
             WHERE (upper(vmast.od_sc_vendor_number) = upper(lc_vendor_no) 
                    or upper(vmast.od_sc_vendor_name) like substr(upper(lc_vendor_name),1,15)||'%')
               AND (upper(vmast.od_sc_factory_number) = upper(lc_factory_no) 
                    or upper(vmast.od_sc_factory_name) like upper(lc_factory_name)||'%')
               AND ROWNUM < 2;                                     
      
                
                            
BEGIN

    select user_id
      into v_user_id
      from fnd_user
     where user_name = '499103' ;
     
     lc_trans_status := p_trans_status ;
     lc_inspection_no := p_inspection_no ;
     
     fnd_file.put_line (fnd_file.LOG, 'Transmission Status : '||lc_trans_status);
     fnd_file.put_line (fnd_file.LOG, 'Inspection Number : '||lc_inspection_no);

    for aud_rec in cur_aud 
    loop
    
   -- fnd_file.put_line (fnd_file.LOG, 'Inside the audit Rec loop : '||aud_rec.od_sc_vendor);
        
        update q_od_sc_vendor_audit_iv
           set process_status = 1
              ,od_sc_od_vendor_id = nvl(p_vendor_no,od_sc_od_vendor_id)
              ,od_sc_vendor       = nvl(p_vendor_name,od_sc_vendor)
              ,od_sc_vendor_address = nvl(p_vendor_addr,od_sc_vendor_address)
              ,od_sc_factory_id   = nvl(p_factory_no,od_sc_factory_id)
              ,od_sc_factory      = nvl(p_factory_name,od_sc_factory)
              ,od_sc_factory_addr = nvl(p_factory_addr,od_sc_factory_addr)
              ,od_sc_region       = nvl(p_region,od_sc_region)
              ,od_sc_agent        = nvl(p_agent,od_sc_agent)
         where process_status = aud_rec.process_status
           and plan_name = aud_rec.plan_name
           and od_sc_inspection_no = aud_rec.od_sc_inspection_no ;
    commit;
    
    end loop;
    
    
    for qri_rec in cur_qri
    loop
    
         v_request_id := fnd_request.submit_request ('QA',
                                                     'QLTTRAMB',
                                                     'Collection Import Manager',
                                                      NULL,
                                                      FALSE,
                                                      '200',
                                                      qri_rec.insert_type,
                                                      TO_CHAR (v_user_id),
                                                      'Yes'
                                                     );
                                                     
                                                     
           IF v_request_id > 0
           THEN                             -- Import Program Successul
                     COMMIT;
                     
               
            fnd_file.put_line (fnd_file.LOG, 'The Concurrent Request ID : '||v_request_id);
-- ********** Uodated vendor master ***********************************************************************
-- #########################################################################################################

       IF TRIM (UPPER (p_trans_status)) = 'FINAL'
       THEN

------------------------------------


              ld_audit_schduled_date := qri_rec.od_sc_scheduled_date;
              ld_inspection_date     := qri_rec.od_sc_inspect_date;
              lc_inspection_type     := qri_rec.od_sc_inspection_type;      
              lc_vendor_no           := qri_rec.od_sc_od_vendor_id;
              lc_vendor_name         := qri_rec.od_sc_vendor;
              lc_vendor_address      := qri_rec.od_sc_vendor_address;
              lc_factory_no          := qri_rec.od_sc_factory_id;
              lc_factory_name        := qri_rec.od_sc_factory;
              lc_factory_address     := qri_rec.od_sc_factory_addr;
              lc_region              := qri_rec.od_sc_region;
              lc_agent               := qri_rec.od_sc_agent;
              ld_payment_date        := qri_rec.od_sc_ven_invoice_payment_date;
              lc_grade               := qri_rec.od_sc_grade;

     
      
                IF lc_grade = 'Denied Entry'  THEN
                    ld_nextaudit_date:= ld_audit_schduled_date + 30;
                ELSIF lc_grade = 'Zero Tolerance' THEN
                    ld_nextaudit_date := Null;                                
                ELSIF lc_grade = 'Needs Improvement' THEN
                    ld_nextaudit_date := ld_audit_schduled_date + 180;
                ELSIF lc_grade IN ('Satisfactory','Minor Progress Needed') THEN
                    ld_nextaudit_date := ld_audit_schduled_date + 365;
                END IF;                                
--                        
           IF INSTR (lc_region, 'ODUS') > 0
           THEN
   
                OPEN cur_us(lc_vendor_no ,lc_vendor_name ,
                            lc_factory_no ,lc_factory_name);
        
                FETCH cur_us 
                 INTO  ln_us_plan_id,ln_us_occurrence_id ;
                   
                   UPDATE qa_results
                      SET character69               = lc_grade
                         ,character66               = to_char(ld_payment_date,'YYYY/MM/DD')
                         ,character67               = to_char(ld_inspection_date,'YYYY/MM/DD')
                         ,character68               = TO_CHAR(ld_nextaudit_date,'YYYY/MM/DD') --  OD_SC_REQ_AUDIT_DATE
                         ,character70               = null   --"OD_SC_CAP_ASSIGNMENT"
                         ,character71               = null   --"OD_SC_CAP_SENT_D"
                         ,character72               = null   --"OD_SC_CAP_RECD_D"
                         ,character73               = null   --"OD_SC_STRAUDT_CAP_STATUS"
                         ,character74               = null   --"OD_SC_CAP_RESP_D"
                         ,comment3                  = null   --"OD_SC_CAP_REV_COMMENTS"
                         ,character75               = null   --"OD_SC_CAP_PREAPPROVER"
                         ,character76               = null   --"OD_SC_STRAUDT_GSO_APR_D"
                         ,character77               = null   --"OD_SC_CAP_FINAL_APPROVER"
                         ,character78               = null   --"OD_SC_SRTAUDT_US_APR_D"
                         ,character92               = lc_inspection_type
                    WHERE occurrence = ln_us_occurrence_id 
                      AND plan_id    = ln_us_plan_id ;
                           
                   COMMIT;                   

                 CLOSE cur_us;
   
               
           END IF;
 
           IF INSTR (lc_region, 'ODEU') > 0
           THEN
                OPEN cur_eu(lc_vendor_no ,lc_vendor_name ,
                            lc_factory_no ,lc_factory_name);
        
                FETCH cur_eu
                 INTO  ln_eu_plan_id,ln_eu_occurrence_id ;
                   
                  UPDATE qa_results
                      SET character70               = lc_grade
                         ,character67               = to_char(ld_payment_date,'YYYY/MM/DD')
                         ,character68               = to_char(ld_inspection_date,'YYYY/MM/DD')
                         ,character69               = TO_CHAR(ld_nextaudit_date,'YYYY/MM/DD') --  OD_SC_REQ_AUDIT_DATE
                         ,character71               = null   --"OD_SC_CAP_ASSIGNMENT"
                         ,character72               = null   --"OD_SC_CAP_SENT_D"
                         ,character73               = null   --"OD_SC_CAP_RECD_D"
                         ,character74               = null   --"OD_SC_STRAUDT_CAP_STATUS"
                         ,character75               = null   --"OD_SC_CAP_RESP_D"
                         ,comment3                  = null   --"OD_SC_CAP_REV_COMMENTS"
                         ,character76               = null   --"OD_SC_CAP_PREAPPROVER"
                         ,character77               = null   --"OD_SC_STRAUDT_GSO_APR_D"
                         ,character78               = null   --"OD_SC_CAP_FINAL_APPROVER"
                         ,character79               = null   --"OD_SC_SRTAUDT_US_APR_D"
                         ,character92               = lc_inspection_type
                    WHERE occurrence = ln_eu_occurrence_id 
                      AND plan_id    = ln_eu_plan_id ;
                           
                   COMMIT;                   

                 CLOSE cur_eu;   
           END IF;
   
           IF INSTR (lc_region, 'ODASIA') > 0
           THEN
                OPEN cur_asia(lc_vendor_no ,lc_vendor_name ,
                            lc_factory_no ,lc_factory_name);
        
                FETCH cur_asia 
                 INTO  ln_asia_plan_id,ln_asia_occurrence_id ;
                   
                   UPDATE qa_results
                      SET character70               = lc_grade
                         ,character67               = to_char(ld_payment_date,'YYYY/MM/DD')
                         ,character68               = to_char(ld_inspection_date,'YYYY/MM/DD')
                         ,character69               = TO_CHAR(ld_nextaudit_date,'YYYY/MM/DD') --  OD_SC_REQ_AUDIT_DATE
                         ,character71               = null   --"OD_SC_CAP_ASSIGNMENT"
                         ,character72               = null   --"OD_SC_CAP_SENT_D"
                         ,character73               = null   --"OD_SC_CAP_RECD_D"
                         ,character74               = null   --"OD_SC_STRAUDT_CAP_STATUS"
                         ,character75               = null   --"OD_SC_CAP_RESP_D"
                         ,comment3                  = null   --"OD_SC_CAP_REV_COMMENTS"
                         ,character76               = null   --"OD_SC_CAP_PREAPPROVER"
                         ,character77               = null   --"OD_SC_STRAUDT_GSO_APR_D"
                         ,character78               = null   --"OD_SC_CAP_FINAL_APPROVER"
                         ,character79               = null   --"OD_SC_SRTAUDT_US_APR_D"
                         ,character92               = lc_inspection_type
                    WHERE occurrence = ln_asia_occurrence_id 
                      AND plan_id    = ln_asia_plan_id ;
                           
                   COMMIT;                   

                 CLOSE cur_asia;   
               
           END IF;
   
           IF INSTR (lc_region, 'ODMX') > 0
           THEN
                OPEN cur_mx(lc_vendor_no ,lc_vendor_name ,
                            lc_factory_no ,lc_factory_name);
        
                FETCH cur_mx 
                 INTO  ln_mx_plan_id,ln_mx_occurrence_id ;
                   
                   UPDATE qa_results
                      SET character70               = lc_grade
                         ,character67               = to_char(ld_payment_date,'YYYY/MM/DD')
                         ,character68               = to_char(ld_inspection_date,'YYYY/MM/DD')
                         ,character69               = TO_CHAR(ld_nextaudit_date,'YYYY/MM/DD') --  OD_SC_REQ_AUDIT_DATE
                         ,character71               = null   --"OD_SC_CAP_ASSIGNMENT"
                         ,character72               = null   --"OD_SC_CAP_SENT_D"
                         ,character73               = null   --"OD_SC_CAP_RECD_D"
                         ,character74               = null   --"OD_SC_STRAUDT_CAP_STATUS"
                         ,character75               = null   --"OD_SC_CAP_RESP_D"
                         ,comment3                  = null   --"OD_SC_CAP_REV_COMMENTS"
                         ,character76               = null   --"OD_SC_CAP_PREAPPROVER"
                         ,character77               = null   --"OD_SC_STRAUDT_GSO_APR_D"
                         ,character78               = null   --"OD_SC_CAP_FINAL_APPROVER"
                         ,character79               = null   --"OD_SC_SRTAUDT_US_APR_D"
                         ,character92               = lc_inspection_type
                    WHERE occurrence = ln_mx_occurrence_id 
                      AND plan_id    = ln_mx_plan_id ;
                           
                   COMMIT;                   

                 CLOSE cur_mx;   
           END IF;

-----------------------------------
        fnd_file.put_line (fnd_file.LOG, 'Grade : '||lc_grade);
        fnd_file.put_line (fnd_file.LOG, 'Inspection Type : '||lc_inspection_type);
        fnd_file.put_line (fnd_file.LOG, 'Inspection Date : '||ld_inspection_date);
        fnd_file.put_line (fnd_file.LOG, 'Scheduled Date : '||lc_schedule_date);
        fnd_file.put_line (fnd_file.LOG, 'Payment Date : '||ld_payment_date);
                            
                         
        END IF;  -- end checking the transmission status 
                        
    END IF;                               

    
    end loop;

EXCEPTION
WHEN OTHERS THEN
         x_retcode := 2;
         x_errbuf :=
               'Unexpected Error in Executing the Audit reprocess Procedure'
            || SQLERRM;

         -- Audit Log
         IF lc_log_profile_value = 'Y'
         THEN
            lc_log_msg := 'EXCEPTION-1 ' || x_errbuf;
            log_exception (p_error_location          => 'XX_QA_SC_VEN_3PA_ADT_RSLT_PKG',
                           p_error_message_code      => 'XX_QA_LOG_MSG',
                           p_error_msg               => lc_log_msg
                          );
         END IF;

END audit_reprocess;                               
   
END xx_qa_sc_ven_3pa_adt_rslt_pkg;
/
exit;