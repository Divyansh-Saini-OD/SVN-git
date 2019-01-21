CREATE OR REPLACE PACKAGE BODY xx_cdh_update_relationship_pkg AS
  -- +======================================================================+
  -- |                  Office Depot - Project Simplify                     |
  -- +======================================================================+
  -- | Name        :  XX_CDH_UPDATE_RELATIONSHIP_PKG.pkb                    |
  -- | Description :  Perform lookup to see if an existing relationship     |
  -- |                exist.  If so update existing relationship with       |
  -- |                inactive status and end date.                         |
  -- |                                                                      |
  -- |Change Record:                                                        |
  -- |===============                                                       |
  -- |Version   Date        Author             Remarks                      |
  -- |========  =========== ============== =================================|
  -- |DRAFT 1a  11/17/2008  Y.Ali          Initial draft version            |
  -- |DRAFT 1.1 01/30/2009  Kalyan         Commented the code for check on  |
  -- |                                     relationship_code while finding  |
  -- |                                     existing relationship records.   |
  -- |DRAFT 1.1 07/08/2009  Kalyan         Added check to direction_code.   |
  -- |                                     Removed setting end_date to      |
  -- |                                     Sysdate.                         |
  -- |      1.2 10/29/2009  Y.Ali          Created new procedure for getting|
  -- |                                     party ids                        |
  -- +======================================================================+

  PROCEDURE inactive_relationship(p_orig_system IN VARCHAR2,   
                                  p_parent_account_osr IN VARCHAR2,   
                                  p_child_account_osr IN VARCHAR2,   
                                  x_parent_account_id OUT nocopy NUMBER,   
                                  x_child_account_id OUT nocopy NUMBER,   
                                  x_return_status OUT nocopy VARCHAR2,   
                                  x_error_message OUT nocopy VARCHAR2)

   IS

  ln_owner_table_id NUMBER;
  ln_parent_party_id NUMBER;
  ln_relationship_id NUMBER;
  ln_obj_version_number NUMBER;
  ln_object_version_number NUMBER;
  l_status VARCHAR2(1);
  p_relationship_rec hz_relationship_v2pub.relationship_rec_type;
  l_return_status VARCHAR2(1);
  l_error_message VARCHAR2(2000);
  l_msg_count NUMBER;
  l_object_number NUMBER;
  ln_party_object_version_number NUMBER;
  p_init_msg_list VARCHAR2(200);

  functional_error EXCEPTION;
  end_program EXCEPTION;
  
                     


  BEGIN

    SAVEPOINT inactive_relationship;

    x_return_status := 'E';
    
     BEGIN
  
            getpartyids(p_parent_account_osr => p_parent_account_osr,   
                        p_child_account_osr => p_child_account_osr,  
                        x_parent_account_id => x_parent_account_id,   
                        x_child_account_id => x_child_account_id,   
                        x_return_status => x_return_status,   
                        x_error_message => x_error_message);

        IF(x_error_message != 'S')THEN
          x_error_message := x_error_message;
        END IF;
        
     EXCEPTION                   
     WHEN others THEN
      x_error_message := 'Error occurred when searching for relationship ID.  Here is the sql error message: ' || sqlerrm;
      RETURN;
    END;  



    BEGIN

      SELECT relationship_id,
        object_version_number
      INTO ln_relationship_id,
        ln_obj_version_number
      FROM hz_relationships
      WHERE subject_id = x_child_account_id --ln_owner_table_id
       AND subject_table_name = 'HZ_PARTIES'
       AND object_table_name = 'HZ_PARTIES' --AND    relationship_code  = 'CHILD_COMPANY_OF'
      AND direction_code = 'C'
       AND relationship_type = 'OD_CUST_HIER'
       AND status = 'A';

    EXCEPTION
    WHEN too_many_rows THEN
      x_error_message := 'Too many records found from relationship table for ' || p_child_account_osr;
      RETURN;
    WHEN no_data_found THEN
      x_error_message := 'No ID found from relationship table for ' || p_child_account_osr;
      x_child_account_id := x_child_account_id; --ln_owner_table_id;
      x_parent_account_id := x_parent_account_id; --ln_parent_party_id;
      x_return_status := 'S';
      RETURN;
    WHEN others THEN
      x_error_message := 'Error occurred when searching for relationship ID.  Here is the sql error message: ' || sqlerrm;
      RETURN;
    END;

    IF ln_relationship_id IS NOT NULL THEN
      p_relationship_rec.relationship_id := ln_relationship_id;
      --  p_relationship_rec.end_date           := SYSDATE;
      p_relationship_rec.status := 'I';
      ln_object_version_number := ln_obj_version_number;

      hz_relationship_v2pub.update_relationship(p_init_msg_list => fnd_api.g_true,   p_relationship_rec => p_relationship_rec,   p_object_version_number => ln_object_version_number,   p_party_object_version_number => ln_party_object_version_number,   x_return_status => x_return_status,   x_msg_count => l_msg_count,   x_msg_data => x_error_message);

      IF l_msg_count > 1 THEN
        FOR counter IN 1 .. l_msg_count
        LOOP
          x_error_message := x_error_message || ' ' || fnd_msg_pub.GET(counter,   fnd_api.g_false);
        END LOOP;

        fnd_msg_pub.delete_msg;
      END IF;

    END IF;

  EXCEPTION
  WHEN others THEN
    ROLLBACK TO inactive_relationship;
    x_return_status := 'E';
    x_error_message := 'Roll back completed.  The following error occurred: ' || sqlerrm; 
END  inactive_relationship;
  
  
  

  PROCEDURE getpartyids(p_parent_account_osr IN VARCHAR2,   
                        p_child_account_osr IN VARCHAR2,  
                        x_parent_account_id OUT nocopy NUMBER,   
                        x_child_account_id OUT nocopy NUMBER,   
                        x_return_status OUT nocopy VARCHAR2,   
                        x_error_message OUT nocopy VARCHAR2)

   IS

  ln_parent_party_id NUMBER;
  ln_child_table_id NUMBER;
  l_return_status VARCHAR2(1);
  l_error_message VARCHAR2(2000);
  l_msg_count NUMBER;
  l_object_number NUMBER;
  ln_party_object_version_number NUMBER;
  p_init_msg_list VARCHAR2(200);

  functional_error EXCEPTION;
  end_program   EXCEPTION;

  BEGIN
    x_return_status := 'E';

    BEGIN
      SELECT party_id
      INTO ln_child_table_id
      FROM hz_cust_accounts
      WHERE orig_system_reference = p_child_account_osr;
      DBMS_OUTPUT.PUT_LINE('ln_child_table_id=====' || ln_child_table_id);

    EXCEPTION
    WHEN too_many_rows THEN
      x_error_message := 'Too many records found from cross reference table for ' || p_child_account_osr;
      RETURN;
    WHEN no_data_found THEN
      x_error_message := 'No ID found from cross reference table for ' || p_child_account_osr;
      RETURN;
    WHEN others THEN
      x_error_message := 'Error occurred when searching for party ID.  Here is the sql error message: ' || sqlerrm;
      RETURN;
    END;

    BEGIN
      --The following block of code is for fetching the parent party ID

      SELECT party_id
      INTO ln_parent_party_id
      FROM hz_cust_accounts
      WHERE orig_system_reference = p_parent_account_osr;

    EXCEPTION
    WHEN too_many_rows THEN
      x_error_message := 'Too many records found from cross reference table for parent account ' || p_parent_account_osr;
      RETURN;
    WHEN no_data_found THEN
      x_error_message := 'No ID found from cross reference table for parent account ' || p_parent_account_osr;
      RETURN;
    WHEN others THEN
      x_error_message := 'Error occurred when searching for parent party ID.  Here is the sql error message: ' || sqlerrm;
      RETURN;
    END;
    
     x_return_status := 'S';
     x_child_account_id := ln_child_table_id;
     x_parent_account_id := ln_parent_party_id;
    
  END getpartyids;

END xx_cdh_update_relationship_pkg;

/