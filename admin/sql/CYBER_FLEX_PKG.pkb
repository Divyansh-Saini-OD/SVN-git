CREATE OR REPLACE PACKAGE BODY CYBER_FLEX_PKG
AS
  CURSOR value_c(valueset IN valueset_r, enabled IN fnd_flex_values.enabled_flag%TYPE)
    RETURN value_dr
  IS
    SELECT flex_value,
      flex_value,
      description,
      start_date_active,
      end_date_active,
      parent_flex_value_low
    FROM fnd_flex_values_vl
    WHERE flex_value_set_id = valueset.vsid
    AND enabled_flag        = enabled
    ORDER BY 1;
  CURSOR value_d(valueset IN valueset_r, enabled IN fnd_flex_values.enabled_flag%TYPE)
    RETURN value_dr
  IS
    SELECT flex_value,
      flex_value_meaning,
      description,
      start_date_active,
      end_date_active,
      parent_flex_value_low
    FROM fnd_flex_values_vl
    WHERE flex_value_set_id = valueset.vsid
    AND enabled_flag        = enabled
    ORDER BY 1;
  debug_mode    BOOLEAN:=TRUE; -- := false;
  cursor_handle INTEGER;
PROCEDURE DEBUG(
    state IN BOOLEAN)
IS
BEGIN
  debug_mode := state;
END;
PROCEDURE dbms_debug(
    p_debug IN VARCHAR2)
IS
  i INTEGER;
  m INTEGER;
  c INTEGER; -- := 75;
BEGIN
  c := 75;
  EXECUTE IMMEDIATE ('begin dbms' || '_output' || '.enable(1000000); end;');
  m     := ceil(LENGTH(p_debug)/c);
  FOR i                       IN 1..m
  LOOP
    EXECUTE IMMEDIATE ('begin dbms' || '_output' || '.put_line(''' || REPLACE(SUBSTR(p_debug, 1+c*(i-1), c), '''', '''''') || '''); end;');
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END dbms_debug;
PROCEDURE dbgprint(
    s IN VARCHAR2)
IS
BEGIN
  IF(debug_mode) THEN
    dbms_debug(s);
  END IF;
END;
FUNCTION to_boolean(
    VALUE IN VARCHAR2)
  RETURN BOOLEAN
IS
  rv BOOLEAN;
BEGIN
  IF(VALUE IN ('Y', 'y')) THEN
    rv     := TRUE;
  ELSE
    rv := FALSE;
  END IF;
  RETURN rv;
END;
FUNCTION to_flag(
    VALUE IN BOOLEAN)
  RETURN VARCHAR2
IS
  rv VARCHAR2(1);
BEGIN
  IF(VALUE) THEN
    rv := 'Y';
  ELSE
    rv := 'N';
  END IF;
  RETURN rv;
END;
PROCEDURE get_valueset(
    valueset_id IN fnd_flex_values.flex_value_set_id%TYPE,
    valueset OUT nocopy valueset_r,
    format OUT nocopy valueset_dr)
IS
  vset valueset_r;
  fmt valueset_dr;
  table_info table_r;
BEGIN
  SELECT
    flex_value_set_id,
    flex_value_set_name,
    validation_type
  INTO vset.vsid,
    vset.NAME,
    vset.validation_type
  FROM fnd_flex_value_sets
  WHERE flex_value_set_id = valueset_id;
  SELECT
    format_type,
    alphanumeric_allowed_flag,
    uppercase_only_flag,
    numeric_mode_enabled_flag,
    maximum_size,
    maximum_value,
    minimum_value,
    longlist_flag
  INTO fmt.format_type,
    fmt.alphanumeric_allowed_flag,
    fmt.uppercase_only_flag,
    fmt.numeric_mode_flag,
    fmt.max_size,
    fmt.max_value,
    fmt.min_value,
    fmt.longlist_flag
  FROM fnd_flex_value_sets
  WHERE flex_value_set_id = valueset_id;
  fmt.longlist_enabled   := (fmt.longlist_flag = 'Y');
  valueset               := vset;
  IF(vset.validation_type = 'F') THEN -- table validated
    SELECT
      application_table_name,
      id_column_name,
      id_column_type,
      value_column_name,
      value_column_type,
      meaning_column_name,
      additional_where_clause,
      start_date_column_name,
      end_date_column_name
    INTO table_info
    FROM fnd_flex_validation_tables
    WHERE flex_value_set_id = vset.vsid;
    valueset.table_info    := table_info;
    fmt.has_id             := (table_info.id_column_name IS NOT NULL);
    fmt.has_meaning        := (table_info.meaning_column_name IS NOT NULL);
  ELSE
    fmt.has_id     := FALSE;
    fmt.has_meaning:= TRUE;
  END IF;
  format := fmt;
  dbgprint('returning valueset:' || vset.NAME);
END;
PROCEDURE make_cursor(
    valueset                 IN valueset_r,
    p_flex_field_name        IN VARCHAR2,
    p_flexfield_value_set    IN VARCHAR2,
    p_request_set_short_name IN VARCHAR2)
IS
  sqlstring VARCHAR2(32767);
  cols      VARCHAR2(1500);
  dummy_vc  VARCHAR2(1);
  dummy_num NUMBER;
  dummy_int INTEGER;
  dummy_date DATE;
  table_info table_r;
  /* these are from the tables - should really be doing a select */
  max_id_size      NUMBER; -- := 150;
  max_val_size     NUMBER; -- := 150;
  max_meaning_size NUMBER; -- := 240;
BEGIN
  max_id_size      := 150;
  max_val_size     := 150;
  max_meaning_size := 240;
  dbgprint('make_cursor: making new cursor (table) ...');
  table_info                        := valueset.table_info;
  cols                              := table_info.start_date_column_name || ', ' || table_info.end_date_column_name || ', ' || table_info.value_column_name;
  IF(table_info.meaning_column_name IS NOT NULL) THEN
    dbgprint('  using meaning column since it is not null (' || table_info.meaning_column_name || ')');
    cols := cols || ' , ' || table_info.meaning_column_name || ' ' || 'DESCRIPTION';
  ELSE
    cols := cols || ', NULL ';
  END IF;
  IF (table_info.id_column_name IS NOT NULL) THEN
    dbgprint('  using id column since it is not null (' || table_info.id_column_name || ')');
    --
    -- to_char() conversion function is defined only for
    -- DATE and NUMBER datatypes.
    --
    IF (table_info.id_column_type IN ('D', 'N')) THEN
      dbgprint(' using to_char(id_column_name). ' || 'id_column_type :('||table_info.id_column_type||')');
      cols := cols || ' , To_char(' || table_info.id_column_name || ')';
    ELSE
      dbgprint(' NOT using to_char(id_column_name). ' || 'id_column_type :('||table_info.id_column_type||')');
      cols := cols || ' , ' || table_info.id_column_name || ' ' || 'ID_COL';
    END IF;
  ELSE
    cols := cols || ', NULL ';
  END IF;
  sqlstring := 'select ' || cols || ' from ' || table_info.table_name || '  ' || table_info.where_clause;
  dbgprint('  sql stmt = ' || sqlstring);
  cursor_handle := dbms_sql.open_cursor;
  dbms_sql.parse(cursor_handle, sqlstring, dbms_sql.NATIVE);
  dbms_sql.define_column(cursor_handle, 1, dummy_date);
  dbms_sql.define_column(cursor_handle, 2, dummy_date);
  dbms_sql.define_column(cursor_handle, 3, dummy_vc, max_val_size);
  dbms_sql.define_column(cursor_handle, 4, dummy_vc, max_meaning_size);
  dbms_sql.define_column(cursor_handle, 5, dummy_vc, max_id_size);
  dummy_int := dbms_sql.EXECUTE(cursor_handle);
END;
PROCEDURE get_value_init(
    valueset                 IN valueset_r,
    enabled_only             IN BOOLEAN,
    p_flex_field_name        IN VARCHAR2,
    p_flexfield_value_set    IN VARCHAR2,
    p_request_set_short_name IN VARCHAR2 )
IS
BEGIN
  dbgprint('get_value_init: opening cursor...type: '||valueset.validation_type);
  IF(valueset.validation_type IN ('I', 'D')) THEN
    IF value_c%isopen THEN
      CLOSE value_c;
    END IF;
    OPEN value_c(valueset, to_flag(enabled_only));
  elsif(valueset.validation_type IN ('X', 'Y')) THEN
    IF value_d%isopen THEN
      CLOSE value_d;
    END IF;
    OPEN value_d(valueset, to_flag(enabled_only));
  elsif(valueset.validation_type = 'F') THEN
    make_cursor(valueset,p_flex_field_name , p_flexfield_value_set , p_request_set_short_name );
  END IF;
  dbgprint('get_value_init: done.');
END;
PROCEDURE get_value(
    valueset IN valueset_r,
    rowcount OUT nocopy NUMBER,
    found OUT nocopy    BOOLEAN,
    VALUE OUT nocopy value_dr)
IS
  value_i value_dr;
BEGIN
  dbgprint('get_value: getting a value...');
  IF(valueset.validation_type IN ('I', 'D')) THEN
    dbgprint('get_value: doing fetch (indep, or dep) ...');
    FETCH value_c INTO value_i;
    dbgprint('get_value: assigning values (indep, or dep) ...');
    VALUE                        := value_i;
    found                        := value_c%found;
  elsif(valueset.validation_type IN ('X', 'Y')) THEN
    dbgprint('get_value: doing fetch (trans indep, or dep) ...');
    FETCH value_d INTO value_i;
    dbgprint('get_value: assigning values (trans indep,or dep) ...');
    VALUE                       := value_i;
    found                       := value_d%found;
  elsif(valueset.validation_type = 'F') THEN
    dbgprint('get_value: doing fetch (table) ...');
    found := (dbms_sql.fetch_rows(cursor_handle) > 0);
    dbgprint('get_value: assigning values (table) ...');
    dbms_sql.COLUMN_VALUE(cursor_handle, 1, VALUE.start_date_active);
    dbms_sql.COLUMN_VALUE(cursor_handle, 2, VALUE.end_date_active);
    dbms_sql.COLUMN_VALUE(cursor_handle, 3, VALUE.VALUE);
    dbms_sql.COLUMN_VALUE(cursor_handle, 4, VALUE.meaning);
    dbms_sql.COLUMN_VALUE(cursor_handle, 5, VALUE.ID);
  END IF;
  rowcount := NULL;
  dbgprint('get_value: done.');
END;
PROCEDURE get_value_end(
    valueset IN valueset_r)
IS
BEGIN
  dbgprint('get_value_end: closing cursor...');
  IF(valueset.validation_type IN ('I', 'D')) THEN
    IF value_c%isopen THEN
      CLOSE value_c;
    END IF;
  elsif(valueset.validation_type IN ('X', 'Y')) THEN
    IF value_d%isopen THEN
      CLOSE value_d;
    END IF;
  elsif(valueset.validation_type = 'F') THEN
    IF(dbms_sql.is_open(cursor_handle)) THEN
      dbms_sql.close_cursor(cursor_handle);
    END IF;
  END IF;
  dbgprint('get_value_end: done.');
END;
FUNCTION to_str(
    val BOOLEAN)
  RETURN VARCHAR2
IS
  rv VARCHAR2(100);
BEGIN
  IF(val) THEN
    rv := 'TRUE';
  ELSE
    rv := 'FALSE';
  END IF;
  RETURN rv;
END;
--Custom Code Starts Here
FUNCTION get_valueset_sql(
    p_flex_valueset_id IN NUMBER)
  RETURN VARCHAR2
IS
  l_where_clause    VARCHAR2(4000);
  l_validation_type VARCHAR2(20);
BEGIN
  SELECT additional_where_clause,
    ffvs.validation_type
  INTO l_where_clause,
    l_validation_type
  FROM fnd_flex_validation_tables ffvt,
    fnd_flex_value_sets ffvs
  WHERE ffvs.flex_value_set_id = p_flex_valueset_id --1009645
  AND ffvs.flex_value_set_id   =ffvt.flex_value_set_id (+);
  IF l_validation_type         ='F' THEN
    IF (UPPER(L_WHERE_CLAUSE) not like 'WHERE%' and UPPER(L_WHERE_CLAUSE) not like 'ORDER BY%')  then
    l_where_clause:='WHERE '||l_where_clause;
  END IF; 
    RETURN l_where_clause;
  ELSE    
    RETURN NULL;
  END IF;
END;
FUNCTION convert_value_to_id(
    p_flex_field_name        IN VARCHAR2,
    p_flexfield_value_set    IN VARCHAR2,
    p_request_set_short_name IN VARCHAR2,
    p_flex_valueset_id       IN NUMBER,
    p_value                  IN VARCHAR2,
    p_parsed_where_clause    IN VARCHAR2)
  RETURN VARCHAR2
IS
  vset valueset_r;
  fmt valueset_dr;
  found BOOLEAN;
  ROW   NUMBER;
  VALUE value_dr;
  l_id VARCHAR2(4000):=NULL;
BEGIN
  get_valueset(p_flex_valueset_id, vset, fmt);
  IF (p_parsed_where_clause     IS NOT NULL) THEN
    vset.table_info.where_clause:=p_parsed_where_clause;
  END IF;
  get_value_init(vset, TRUE,p_flex_field_name, p_flexfield_value_set, p_request_set_short_name);
  dbgprint(' Value Type '||fmt.format_type||' - ID Column: '||vset.table_info.id_column_name);
  get_value(vset, ROW, found, VALUE);
  IF vset.table_info.id_column_name IS NOT NULL THEN
    WHILE(found)
    LOOP
      IF upper(p_value)=upper(VALUE.VALUE) THEN
        l_id   :=VALUE.ID;
        dbgprint('ID Found: '||l_id);
        get_value_end(vset);
        IF fmt.format_type IN ('D','X','Y','C') AND p_value IS NOT NULL THEN --> Convert to string for Date, Datetime and Timestamps
               l_id             :=''''||l_id||'''';
        END IF;        
        RETURN l_id;
      END IF;
      get_value(vset, ROW, found, VALUE);
    END LOOP;
  END IF;
  l_id               :=p_value;
  IF fmt.format_type IN ('D','X','Y','C') AND p_value IS NOT NULL THEN --> Convert to string for Date, Datetime and Timestamps
    l_id             :=''''||l_id||'''';
  END IF;
  get_value_end(vset);
  RETURN l_id;
END convert_value_to_id;
--Custom Code Ends Here
END CYBER_FLEX_PKG;
/

