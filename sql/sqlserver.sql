WITH tableKeys AS (
  SELECT t.constraint_schema,
         t.table_name,
         c.column_name,
         'PK' AS column_key
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS t
  JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE c 
    ON c.constraint_schema = t.constraint_schema
    AND c.table_name = t.table_name
    AND c.constraint_name = t.constraint_name
  WHERE t.constraint_type = 'PRIMARY KEY'
),
tableColumns AS (
  SELECT t.table_schema,
         t.table_name,
         c.column_name,
         COALESCE(tk.column_key, '') AS column_pk,
		 c.IS_NULLABLE,
		 c.ordinal_position AS ordinal_position,
         CASE
           WHEN data_type IN ('varchar', 'nvarchar') AND c.CHARACTER_MAXIMUM_LENGTH != -1
		     THEN CONCAT(DATA_TYPE, '(', c.CHARACTER_MAXIMUM_LENGTH ,')') 
           ELSE data_type
         END AS column_type
  FROM INFORMATION_SCHEMA.COLUMNS c
  JOIN INFORMATION_SCHEMA.TABLES t
    ON c.table_schema = t.table_schema
   AND c.table_name = t.table_name
  LEFT JOIN tableKeys tk
    ON tk.constraint_schema = t.table_schema
   AND tk.table_name = t.table_name
   AND tk.column_name = c.column_name
  WHERE t.table_type = 'BASE TABLE'
),
tableDefsTemp AS(
  SELECT table_schema,
         CONCAT('Table',' ', table_name,' ','{',CHAR(13)) AS table_prefix,
         CONCAT('  ', CAST(QUOTENAME(column_name, '"') AS NCHAR(20)),'  ',column_type,'  ',column_pk) AS table_column,
         CONCAT('}',CHAR(13),CHAR(13)) AS table_suffix,
		 ordinal_position
  FROM tableColumns
),
tableDefs AS(
  SELECT TOP 1000 
         tOuter.table_schema,
         tOuter.table_prefix,
         (SELECT tInner.table_column + CHAR(13)
  	      FROM tableDefsTemp tInner 
  	      WHERE tInner.table_prefix = tOuter.table_prefix 
  	      ORDER BY tInner.ordinal_position 
  		  FOR XML PATH(''), type).value('.', 'nvarchar(max)') AS column_list,
         tOuter.table_suffix
   FROM tableDefsTemp as tOuter
   GROUP BY tOuter.table_schema, tOuter.table_prefix, tOuter.table_suffix
   ORDER BY tOuter.table_prefix
),
relDefs AS (
  SELECT TOP 1000 
         PK.TABLE_SCHEMA,
         CONCAT('Ref: ',PK.TABLE_NAME,'.',PT.COLUMN_NAME,' < ',FK.TABLE_NAME,'.',CU.COLUMN_NAME,CHAR(13)) AS relationships,
         FK_Table = FK.TABLE_NAME,
         FK_Column = CU.COLUMN_NAME,
         PK_Table = PK.TABLE_NAME,
         PK_Column = PT.COLUMN_NAME,
         Constraint_Name = C.CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C
    INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK ON C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
    INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS PK ON C.UNIQUE_CONSTRAINT_NAME = PK.CONSTRAINT_NAME
    INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU ON C.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
    INNER JOIN (
      SELECT i1.TABLE_NAME, i2.COLUMN_NAME
      FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS i1
        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE i2 ON i1.CONSTRAINT_NAME = i2.CONSTRAINT_NAME
        WHERE i1.CONSTRAINT_TYPE = 'PRIMARY KEY') PT ON PT.TABLE_NAME = PK.TABLE_NAME
    ORDER BY PK.TABLE_SCHEMA,
             PK.TABLE_NAME,
             FK.TABLE_NAME
)
SELECT CONCAT(table_prefix,column_list,table_suffix)
  FROM tableDefs
UNION ALL
SELECT relationships
  FROM relDefs
FOR XML PATH(''), type
