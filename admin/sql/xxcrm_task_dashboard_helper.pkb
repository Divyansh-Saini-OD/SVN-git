create or replace
PACKAGE BODY xxcrm_task_dashboard_helper AS
  -- +====================================================================+
  -- | Name        : xxcrm_task_dashboard_helper                          |
  -- | Author      : Mohan Kalyanasundaram                                |
  -- | Description : This package is used for getting task dashboard      |
  -- |               related data                                         |
  -- | Date        : February 22, 2010 --> New Version Started by Mohan   |
  -- +====================================================================+
--
-- +====================================================================+
    FUNCTION get_current_year_id
            RETURN NUMBER  
    IS
      l_year_id number := 0;
    BEGIN
      BEGIN
        select fiscal_year_id INTO l_year_id from apps.XXBI_OD_FISCAL_CALENDAR_V
          where accounting_date = trunc(sysdate);
      EXCEPTION
      WHEN OTHERS THEN
        l_year_id := null;
      END;
      return l_year_id;
    END get_current_year_id;
-- +====================================================================+
    FUNCTION get_current_week_number
            RETURN NUMBER  
    IS
      l_week_number number := 0;
    BEGIN
      BEGIN
        select fiscal_week_number INTO l_week_number from apps.XXBI_OD_FISCAL_CALENDAR_V
          where accounting_date = trunc(sysdate);
      EXCEPTION
      WHEN OTHERS THEN
        l_week_number := null;
      END;
      return l_week_number;
    END get_current_week_number;
-- +====================================================================+
    FUNCTION get_task_week_number(
            p_date date)
            RETURN NUMBER  
    IS
      l_week_number number := 0;
    BEGIN
      BEGIN
        select fiscal_week_number INTO l_week_number from apps.XXBI_OD_FISCAL_CALENDAR_V
          where accounting_date = trunc(p_date);
      EXCEPTION
      WHEN OTHERS THEN
        l_week_number := null;
      END;
      return l_week_number;
    END get_task_week_number;
-- +====================================================================+
    FUNCTION get_task_week_desc(
            p_date date)
            RETURN VARCHAR2 
    IS
      l_fiscal_week_desc varchar2(200) := null;
    BEGIN
      BEGIN
        select fiscal_week_descr INTO l_fiscal_week_desc from apps.XXBI_OD_FISCAL_CALENDAR_V
          where accounting_date = trunc(p_date);
      EXCEPTION
      WHEN OTHERS THEN
        l_fiscal_week_desc := null;
      END;
      return l_fiscal_week_desc;
    END get_task_week_desc;
-- +====================================================================+
    FUNCTION get_task_week_id(
            p_date date)
            RETURN NUMBER
  
    IS
      l_week_id number := 0;
    BEGIN
      BEGIN
        select fiscal_week_id INTO l_week_id from apps.XXBI_OD_FISCAL_CALENDAR_V
          where accounting_date = trunc(p_date);
      EXCEPTION
      WHEN OTHERS THEN
        l_week_id := null;
      END;
      return l_week_id;
    END get_task_week_id;
-- +====================================================================+
    FUNCTION get_task_year_id(
            p_date date)
            RETURN NUMBER
  
    IS
      l_year_id number := 0;
    BEGIN
      BEGIN
        select fiscal_year_id INTO l_year_id from apps.XXBI_OD_FISCAL_CALENDAR_V
          where accounting_date = trunc(p_date);
      EXCEPTION
      WHEN OTHERS THEN
        l_year_id := null;
      END;
      return l_year_id;
    END get_task_year_id;
-- +====================================================================+
    FUNCTION get_site_use(
            p_party_site_id NUMBER)
            RETURN VARCHAR2
    IS
      l_site_use varchar2(100) := null;
    BEGIN
      BEGIN
        IF nvl(p_party_site_id,-99) <> -99 THEN
          SELECT site_use INTO l_site_use FROM xxcrm.xxbi_party_site_data_fct_mv
            where party_site_id = p_party_site_id;
        ELSE
          l_site_use := null;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        l_site_use := null;
      END;
      return l_site_use;
    END get_site_use;
-- +====================================================================+
    FUNCTION get_org_type(
            p_party_site_id NUMBER)
            RETURN VARCHAR2
    IS
      l_org_type varchar2(100) := null;
    BEGIN
      BEGIN
        IF nvl(p_party_site_id,-99) <> -99 THEN
          SELECT org_type INTO l_org_type FROM xxcrm.xxbi_party_site_data_fct_mv
            where party_site_id = p_party_site_id;
        ELSE
          l_org_type := null;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        l_org_type := null;
      END;
      return l_org_type;
    END get_org_type;
-- +====================================================================+
    FUNCTION get_site_orig_sys_ref(
            p_party_site_id NUMBER)
            RETURN VARCHAR2
    IS
      l_site_orig_sys_ref varchar2(100) := null;
    BEGIN
      BEGIN
        IF nvl(p_party_site_id,-99) <> -99 THEN
          SELECT site_orig_sys_ref INTO l_site_orig_sys_ref FROM xxcrm.xxbi_party_site_data_fct_mv
            where party_site_id = p_party_site_id;
        ELSE
          l_site_orig_sys_ref := null;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        l_site_orig_sys_ref := null;
      END;
      return l_site_orig_sys_ref;
    END get_site_orig_sys_ref;
-- +====================================================================+
    FUNCTION get_party_site_name(
            p_party_site_id NUMBER)
            RETURN VARCHAR2
    IS
      l_party_site_name varchar2(100) := null;
    BEGIN
      BEGIN
        IF nvl(p_party_site_id,-99) <> -99 THEN
          SELECT party_site_name INTO l_party_site_name FROM xxcrm.xxbi_party_site_data_fct_mv
            where party_site_id = p_party_site_id;
        ELSE
          l_party_site_name := null;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        l_party_site_name := null;
      END;
      return l_party_site_name;
    END get_party_site_name;
-- +====================================================================+
    FUNCTION get_org_number(
            p_party_site_id NUMBER)
            RETURN VARCHAR2
    IS
      l_org_number varchar2(240) := null;
    BEGIN
      BEGIN
        IF nvl(p_party_site_id,-99) <> -99 THEN
          SELECT org_number INTO l_org_number FROM xxcrm.xxbi_party_site_data_fct_mv
            where party_site_id = p_party_site_id;
        ELSE
          l_org_number := null;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        l_org_number := null;
      END;
      return l_org_number;
    END get_org_number;
-- +====================================================================+
    FUNCTION get_party_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN NUMBER
    IS
      l_party_id number := null;
      l_found_count number := 0;
    BEGIN
      BEGIN
        IF nvl(p_source_object_type,'NONE') = 'NONE' THEN
          return null;
        ELSIF p_source_object_type = 'PARTY' THEN
          return p_source_object_id;
        ELSIF p_source_object_type = 'LEAD' THEN
          BEGIN
            select customer_id INTO l_party_id FROM apps.XXBI_SALES_LEADS_FCT_MV
              where sales_lead_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type = 'OPPORTUNITY' THEN
          BEGIN
            select customer_id INTO l_party_id FROM apps.XXBI_SALES_OPPTY_FCT_MV
              where opp_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type IN ('OD_PARTY_SITE','PARTY_SITE') THEN
          BEGIN
            select party_id INTO l_party_id FROM xxcrm.xxbi_party_site_data_fct_mv
              where party_site_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSE
          return null;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        l_party_id := null;
      END;
      return l_party_id;
    END get_party_id;
-- +====================================================================+
    FUNCTION get_party_name(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_party_name varchar2(200) := null;
    BEGIN
      BEGIN
        IF nvl(p_source_object_type,'NONE') = 'NONE' THEN
          return null;
        ELSIF p_source_object_type = 'PARTY' THEN
          BEGIN
            select party_name INTO l_party_name FROM xxcrm.xxbi_party_site_data_fct_mv
              where party_id = p_source_object_id and
              rownum < 2;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type = 'LEAD' THEN
          BEGIN
            select party_name INTO l_party_name FROM apps.XXBI_SALES_LEADS_FCT_MV
              where sales_lead_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type = 'OPPORTUNITY' THEN
          BEGIN
            select party_name INTO l_party_name FROM apps.XXBI_SALES_OPPTY_FCT_MV
              where opp_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type IN ('OD_PARTY_SITE','PARTY_SITE') THEN
          BEGIN
            select party_name INTO l_party_name FROM xxcrm.xxbi_party_site_data_fct_mv
              where party_site_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSE
          return null;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        l_party_name := null;
      END;
      return l_party_name;
    END get_party_name;
-- +====================================================================+
    FUNCTION get_party_site_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN NUMBER
    IS
      l_party_site_id number := null;
    BEGIN
      BEGIN
        IF nvl(p_source_object_type,'NONE') = 'NONE' THEN
          return null;
        ELSIF p_source_object_type = 'PARTY' THEN
          BEGIN
            select party_site_id INTO l_party_site_id FROM xxcrm.xxbi_party_site_data_fct_mv
              where party_id = p_source_object_id and
                    nvl(identifying_address_flag,'N') = 'Y' and
                    site_status = 'A';
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type = 'LEAD' THEN
          BEGIN
            select party_site_id INTO l_party_site_id FROM apps.XXBI_SALES_LEADS_FCT_MV
              where sales_lead_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type = 'OPPORTUNITY' THEN
          BEGIN
            select party_site_id INTO l_party_site_id FROM apps.XXBI_SALES_OPPTY_FCT_MV
              where opp_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type IN ('OD_PARTY_SITE','PARTY_SITE') THEN
          return p_source_object_id;
        ELSE
          return null;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        l_party_site_id := null;
      END;
      return l_party_site_id;
    END get_party_site_id;
-- +====================================================================+
    FUNCTION get_party_site_address(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_address1 varchar2(240) := null;
      l_city varchar2(60) := null; 
      l_state varchar2(60) := null; 
      l_postal_code varchar2(60) := null;
    BEGIN
      BEGIN
        IF nvl(p_source_object_type,'NONE') = 'NONE' THEN
          return null;
        ELSIF p_source_object_type = 'PARTY' THEN
          BEGIN
            select a.address1, a.city, a.state, a.postal_code INTO l_address1, l_city, l_state, l_postal_code 
              FROM xxcrm.xxbi_party_site_data_fct_mv a
              where a.party_id = p_source_object_id and
                    nvl(a.identifying_address_flag,'N') = 'Y' and
                    a.site_status = 'A';
              return get_site_address(l_address1,l_city,l_state,l_postal_code);
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type = 'LEAD' THEN
          BEGIN
            select address1, city, state, postal_code INTO l_address1, l_city, l_state, l_postal_code 
              FROM apps.XXBI_SALES_LEADS_FCT_MV
              where sales_lead_id = p_source_object_id;
              return get_site_address(l_address1,l_city,l_state,l_postal_code);
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type = 'OPPORTUNITY' THEN
          BEGIN
            select address1, city, state, postal_code INTO l_address1, l_city, l_state, l_postal_code 
              FROM apps.XXBI_SALES_OPPTY_FCT_MV
              where opp_id = p_source_object_id;
              return get_site_address(l_address1,l_city,l_state,l_postal_code);
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type IN ('OD_PARTY_SITE','PARTY_SITE') THEN
          BEGIN
            select b.address1, b.city, b.state, b.postal_code INTO l_address1, l_city, l_state, l_postal_code 
              FROM xxcrm.xxbi_party_site_data_fct_mv b
              where b.party_site_id = p_source_object_id;
--                    and nvl(b.identifying_address_flag,'N') = 'Y';
              return get_site_address(l_address1,l_city,l_state,l_postal_code);
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSE
          return null;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
    END get_party_site_address;
-- +====================================================================+
    FUNCTION get_assigned_resource_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN NUMBER
    IS
      l_assigned_resource_id number := null;
      l_party_site_id number := null;
    BEGIN
      BEGIN
        IF nvl(p_source_object_type,'NONE') = 'NONE' THEN
          return null;
        ELSIF p_source_object_type = 'PARTY' THEN
          BEGIN
            select party_site_id INTO l_party_site_id FROM xxcrm.xxbi_party_site_data_fct_mv
              where party_id = p_source_object_id and
              nvl(site_status,'X') = 'A' and
              nvl(identifying_address_flag,'N') = 'Y';
            select resource_id INTO l_assigned_resource_id 
              FROM xxcrm.XXBI_TERENT_ASGNMNT_FCT_MV
              where entity_type = 'PARTY_SITE' and
                    entity_id = l_party_site_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type = 'LEAD' THEN
          BEGIN
            select resource_id INTO l_assigned_resource_id 
              FROM apps.XXBI_SALES_LEADS_FCT_MV
              where sales_lead_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type = 'OPPORTUNITY' THEN
          BEGIN
            select resource_id INTO l_assigned_resource_id 
              FROM apps.XXBI_SALES_OPPTY_FCT_MV
              where opp_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSIF p_source_object_type IN ('OD_PARTY_SITE','PARTY_SITE') THEN
          BEGIN
            select resource_id INTO l_assigned_resource_id 
              FROM xxcrm.XXBI_TERENT_ASGNMNT_FCT_MV
              where entity_type = 'PARTY_SITE' and
                    entity_id = p_source_object_id;
          EXCEPTION
          WHEN OTHERS THEN
            return null;
          END;
        ELSE
          return null;
        END IF;
        return l_assigned_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_assigned_resource_id := null;
      END;
      return l_assigned_resource_id;
    END get_assigned_resource_id;
-- +====================================================================+
    FUNCTION get_assigned_resource_name(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_assigned_resource_id number := null;
      l_assigned_resource_name varchar2(200) := null;
      l_role_name varchar2(100) := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.resource_name, b.role_name INTO l_assigned_resource_name, l_role_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
--        IF (nvl(l_assigned_resource_name,'$MISSING$') <> '$MISSING$') THEN
--          l_assigned_resource_name := l_assigned_resource_name||' ('||l_role_name||')';
--        END IF;
        return l_assigned_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        l_assigned_resource_name := null;
      END;
      return l_assigned_resource_name;
    END get_assigned_resource_name;
-- +====================================================================+
    FUNCTION get_assigned_user_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_assigned_user_id varchar2(200) := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.user_id INTO l_assigned_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_assigned_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_assigned_user_id := null;
      END;
      return l_assigned_user_id;
    END get_assigned_user_id;
-- +====================================================================+
    FUNCTION get_assigned_role_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN NUMBER
    IS
      l_assigned_role_id number := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.role_id INTO l_assigned_role_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_assigned_role_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_assigned_role_id := null;
      END;
      return l_assigned_role_id;
    END get_assigned_role_id;
-- +====================================================================+
    FUNCTION get_assigned_role_name(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_assigned_role_name varchar2(200) := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.role_name INTO l_assigned_role_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_assigned_role_name;
      EXCEPTION
      WHEN OTHERS THEN
        l_assigned_role_name := null;
      END;
      return l_assigned_role_name;
    END get_assigned_role_name;
-- +====================================================================+
    FUNCTION get_assigned_group_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN NUMBER
    IS
      l_assigned_group_id number := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.group_id INTO l_assigned_group_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_assigned_group_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_assigned_group_id := null;
      END;
      return l_assigned_group_id;
    END get_assigned_group_id;
-- +====================================================================+
    FUNCTION get_m1_user_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m1_user_id varchar2(200) := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m1_user_id INTO l_m1_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_m1_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_m1_user_id := null;
      END;
      return l_m1_user_id;
    END get_m1_user_id;
-- +====================================================================+
    FUNCTION get_m1_resource_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN NUMBER
    IS
      l_m1_resource_id number := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m1_resource_id INTO l_m1_resource_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_m1_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_m1_resource_id := null;
      END;
      return l_m1_resource_id;
    END get_m1_resource_id;
-- +====================================================================+
    FUNCTION get_m1_resource_name(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m1_resource_name varchar2(200) := null;
      l_assigned_resource_id number := null;
      l_m1_role_name varchar2(200) := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m1_resource_name, b.m1_role_name INTO l_m1_resource_name, l_m1_role_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        IF (nvl(l_m1_resource_name,'$MISSING$') <> '$MISSING$') THEN
          l_m1_resource_name := l_m1_resource_name||' ('||l_m1_role_name||')';
        END IF;
        return l_m1_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        l_m1_resource_name := null;
      END;
      return l_m1_resource_name;
    END get_m1_resource_name;
-- +====================================================================+
    FUNCTION get_m2_user_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m2_user_id varchar2(200) := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m2_user_id INTO l_m2_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_m2_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_m2_user_id := null;
      END;
      return l_m2_user_id;
    END get_m2_user_id;
-- +====================================================================+
    FUNCTION get_m2_resource_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN NUMBER
    IS
      l_m2_resource_id number := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m2_resource_id INTO l_m2_resource_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_m2_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_m2_resource_id := null;
      END;
      return l_m2_resource_id;
    END get_m2_resource_id;
-- +====================================================================+
    FUNCTION get_m2_resource_name(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m2_resource_name varchar2(200) := null;
      l_m2_role_name varchar2(200) := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m2_resource_name, b.m2_role_name INTO l_m2_resource_name, l_m2_role_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        IF (nvl(l_m2_resource_name,'$MISSING$') <> '$MISSING$') THEN
          l_m2_resource_name := l_m2_resource_name||' ('||l_m2_role_name||')';
        END IF;
        return l_m2_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        l_m2_resource_name := null;
      END;
      return l_m2_resource_name;
    END get_m2_resource_name;
-- +====================================================================+
    FUNCTION get_m3_user_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m3_user_id varchar2(200) := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m3_user_id INTO l_m3_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_m3_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_m3_user_id := null;
      END;
      return l_m3_user_id;
    END get_m3_user_id;
-- +====================================================================+
    FUNCTION get_m3_resource_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN NUMBER
    IS
      l_m3_resource_id number := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m3_resource_id INTO l_m3_resource_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_m3_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_m3_resource_id := null;
      END;
      return l_m3_resource_id;
    END get_m3_resource_id;
-- +====================================================================+
    FUNCTION get_m3_resource_name(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m3_resource_name varchar2(200) := null;
      l_m3_role_name varchar2(200) := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m3_resource_name, b.m3_role_name INTO l_m3_resource_name, l_m3_role_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        IF (nvl(l_m3_resource_name,'$MISSING$') <> '$MISSING$') THEN
          l_m3_resource_name := l_m3_resource_name||' ('||l_m3_role_name||')';
        END IF;
        return l_m3_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        l_m3_resource_name := null;
      END;
      return l_m3_resource_name;
    END get_m3_resource_name;
-- +====================================================================+
    FUNCTION get_m4_user_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m4_user_id varchar2(200) := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m4_user_id INTO l_m4_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_m4_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_m4_user_id := null;
      END;
      return l_m4_user_id;
    END get_m4_user_id;
-- +====================================================================+
    FUNCTION get_m4_resource_id(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN NUMBER
    IS
      l_m4_resource_id number := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m4_resource_id INTO l_m4_resource_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        return l_m4_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_m4_resource_id := null;
      END;
      return l_m4_resource_id;
    END get_m4_resource_id;
-- +====================================================================+
    FUNCTION get_m4_resource_name(
            p_source_object_type VARCHAR2,
            p_source_object_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m4_resource_name varchar2(200) := null;
      l_m4_role_name varchar2(200) := null;
      l_assigned_resource_id number := null;
    BEGIN
      BEGIN
        l_assigned_resource_id := get_assigned_resource_id(p_source_object_type,p_source_object_id);
        select b.m4_resource_name, b.m4_role_name INTO l_m4_resource_name, l_m4_role_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
          where b.resource_id = l_assigned_resource_id and
                rownum < 2;
        IF (nvl(l_m4_resource_name,'$MISSING$') <> '$MISSING$') THEN
          l_m4_resource_name := l_m4_resource_name||' ('||l_m4_role_name||')';
        END IF;
        return l_m4_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        l_m4_resource_name := null;
      END;
      return l_m4_resource_name;
    END get_m4_resource_name;
-- +====================================================================+
    FUNCTION get_user_resource_id(
            p_user NUMBER)
            RETURN NUMBER
    IS
      l_user_resource_id number := null;
    BEGIN
      BEGIN
        select b.resource_id INTO l_user_resource_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_resource_id;
    END get_user_resource_id;
-- +====================================================================+
    FUNCTION get_user_resource_name(
            p_user NUMBER)
            RETURN VARCHAR2
    IS
      l_user_resource_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.resource_name INTO l_user_resource_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_resource_name;
    END get_user_resource_name;
-- +====================================================================+
    FUNCTION get_user_m1_user_id(
            p_user NUMBER)
            RETURN VARCHAR2
    IS
      l_user_m1_user_id varchar2(100) := null;
    BEGIN
      BEGIN
        select b.m1_user_id INTO l_user_m1_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m1_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m1_user_id;
    END get_user_m1_user_id;
-- +====================================================================+
    FUNCTION get_user_m1_res_id(
            p_user NUMBER)
            RETURN NUMBER
    IS
      l_user_m1_res_id number := null;
    BEGIN
      BEGIN
        select b.m1_resource_id INTO l_user_m1_res_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m1_res_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m1_res_id;
    END get_user_m1_res_id;
-- +====================================================================+
    FUNCTION get_user_m1_res_name(
            p_user NUMBER)
            RETURN VARCHAR2
    IS
      l_user_m1_res_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.m1_resource_name INTO l_user_m1_res_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m1_res_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m1_res_name;
    END get_user_m1_res_name;
-- +====================================================================+
    FUNCTION get_user_m2_user_id(
            p_user NUMBER)
            RETURN VARCHAR2
    IS
      l_user_m2_user_id varchar2(100) := null;
    BEGIN
      BEGIN
        select b.m2_user_id INTO l_user_m2_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m2_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m2_user_id;
    END get_user_m2_user_id;
-- +====================================================================+
    FUNCTION get_user_m2_res_id(
            p_user NUMBER)
            RETURN NUMBER
    IS
      l_user_m2_res_id number := null;
    BEGIN
      BEGIN
        select b.m2_resource_id INTO l_user_m2_res_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m2_res_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m2_res_id;
    END get_user_m2_res_id;
-- +====================================================================+
    FUNCTION get_user_m2_res_name(
            p_user NUMBER)
            RETURN VARCHAR2
    IS
      l_user_m2_res_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.m2_resource_name INTO l_user_m2_res_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m2_res_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m2_res_name;
    END get_user_m2_res_name;
-- +====================================================================+
    FUNCTION get_user_m3_user_id(
            p_user NUMBER)
            RETURN VARCHAR2
    IS
      l_user_m3_user_id varchar2(100) := null;
    BEGIN
      BEGIN
        select b.m3_user_id INTO l_user_m3_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m3_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m3_user_id;
    END get_user_m3_user_id;
-- +====================================================================+
    FUNCTION get_user_m3_res_id(
            p_user NUMBER)
            RETURN NUMBER
    IS
      l_user_m3_res_id number := null;
    BEGIN
      BEGIN
        select b.m3_resource_id INTO l_user_m3_res_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m3_res_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m3_res_id;
    END get_user_m3_res_id;
-- +====================================================================+
    FUNCTION get_user_m3_res_name(
            p_user NUMBER)
            RETURN VARCHAR2
    IS
      l_user_m3_res_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.m3_resource_name INTO l_user_m3_res_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m3_res_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m3_res_name;
    END get_user_m3_res_name;
-- +====================================================================+
    FUNCTION get_user_m4_user_id(
            p_user NUMBER)
            RETURN VARCHAR2
    IS
      l_user_m4_user_id varchar2(100) := null;
    BEGIN
      BEGIN
        select b.m4_user_id INTO l_user_m4_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m4_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m4_user_id;
    END get_user_m4_user_id;
-- +====================================================================+
    FUNCTION get_user_m4_res_id(
            p_user NUMBER)
            RETURN NUMBER
    IS
      l_user_m4_res_id number := null;
    BEGIN
      BEGIN
        select b.m4_resource_id INTO l_user_m4_res_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m4_res_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m4_res_id;
    END get_user_m4_res_id;
-- +====================================================================+
    FUNCTION get_user_m4_res_name(
            p_user NUMBER)
            RETURN VARCHAR2
    IS
      l_user_m4_res_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.m4_resource_name INTO l_user_m4_res_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.user_id = p_user and
                rownum < 2;
        return l_user_m4_res_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_m4_res_name;
    END get_user_m4_res_name;
-- +====================================================================+
    FUNCTION get_owner_user_id(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_user_id varchar2(100) := null;
    BEGIN
      BEGIN
        select b.user_id INTO l_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_user_id;
    END get_owner_user_id;
-- +====================================================================+
    FUNCTION get_owner_resource_name(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_resource_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.resource_name INTO l_resource_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_resource_name;
    END get_owner_resource_name;
-- +====================================================================+
    FUNCTION get_owner_m1_user_id(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m1_user_id varchar2(100) := null;
    BEGIN
      BEGIN
        select b.m1_user_id INTO l_m1_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m1_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m1_user_id;
    END get_owner_m1_user_id;
-- +====================================================================+
    FUNCTION get_owner_m1_resource_id(
            p_owner_id NUMBER)
            RETURN NUMBER
    IS
      l_m1_resource_id number := null;
    BEGIN
      BEGIN
        select b.m1_resource_id INTO l_m1_resource_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m1_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m1_resource_id;
    END get_owner_m1_resource_id;
-- +====================================================================+
    FUNCTION get_owner_m1_resource_name(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m1_resource_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.m1_resource_name INTO l_m1_resource_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m1_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m1_resource_name;
    END get_owner_m1_resource_name;
-- +====================================================================+
    FUNCTION get_owner_m2_user_id(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m2_user_id varchar2(100) := null;
    BEGIN
      BEGIN
        select b.m2_user_id INTO l_m2_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m2_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m2_user_id;
    END get_owner_m2_user_id;
-- +====================================================================+
    FUNCTION get_owner_m2_resource_id(
            p_owner_id NUMBER)
            RETURN NUMBER
    IS
      l_m2_resource_id number := null;
    BEGIN
      BEGIN
        select b.m2_resource_id INTO l_m2_resource_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m2_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m2_resource_id;
    END get_owner_m2_resource_id;
-- +====================================================================+
    FUNCTION get_owner_m2_resource_name(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m2_resource_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.m2_resource_name INTO l_m2_resource_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m2_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m2_resource_name;
    END get_owner_m2_resource_name;
-- +====================================================================+
    FUNCTION get_owner_m3_user_id(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m3_user_id varchar2(100) := null;
    BEGIN
      BEGIN
        select b.m3_user_id INTO l_m3_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m3_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m3_user_id;
    END get_owner_m3_user_id;
-- +====================================================================+
    FUNCTION get_owner_m3_resource_id(
            p_owner_id NUMBER)
            RETURN NUMBER
    IS
      l_m3_resource_id number := null;
    BEGIN
      BEGIN
        select b.m3_resource_id INTO l_m3_resource_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m3_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m3_resource_id;
    END get_owner_m3_resource_id;
-- +====================================================================+
    FUNCTION get_owner_m3_resource_name(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m3_resource_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.m3_resource_name INTO l_m3_resource_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m3_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m3_resource_name;
    END get_owner_m3_resource_name;
-- +====================================================================+
    FUNCTION get_owner_m4_user_id(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m4_user_id varchar2(100) := null;
    BEGIN
      BEGIN
        select b.m4_user_id INTO l_m4_user_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m4_user_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m4_user_id;
    END get_owner_m4_user_id;
-- +====================================================================+
    FUNCTION get_owner_m4_resource_id(
            p_owner_id NUMBER)
            RETURN NUMBER
    IS
      l_m4_resource_id number := null;
    BEGIN
      BEGIN
        select b.m4_resource_id INTO l_m4_resource_id 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m4_resource_id;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m4_resource_id;
    END get_owner_m4_resource_id;
-- +====================================================================+
    FUNCTION get_owner_m4_resource_name(
            p_owner_id NUMBER)
            RETURN VARCHAR2
    IS
      l_m4_resource_name varchar2(200) := null;
    BEGIN
      BEGIN
        select b.m4_resource_name INTO l_m4_resource_name 
          FROM apps.XXBI_GROUP_MBR_INFO_MV b
            where b.resource_id = p_owner_id and
                rownum < 2;
        return l_m4_resource_name;
      EXCEPTION
      WHEN OTHERS THEN
        return null;
      END;
      return l_m4_resource_name;
    END get_owner_m4_resource_name;
-- +====================================================================+
    FUNCTION get_site_address
        ( p_address1 IN VARCHAR2,
          p_city IN VARCHAR2,
          p_state IN VARCHAR2,
          p_postal_code IN VARCHAR2
        )
          RETURN VARCHAR2
    IS
      l_site_address varchar2(2000) := null;
    BEGIN
      BEGIN
        l_site_address := p_address1 ||', '||p_city||', '||p_state||' '||p_postal_code;
      EXCEPTION
      WHEN OTHERS THEN
        return l_site_address;
      END;
      return l_site_address;
    END get_site_address;
-- +====================================================================+
END xxcrm_task_dashboard_helper;
/