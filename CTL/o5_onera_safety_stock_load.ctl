OPTIONS(skip=1)
LOAD DATA
TRUNCATE
INTO TABLE O5.ONERA_SAFETY_STOCK
Fields terminated by X'09' optionally enclosed by '"' trailing nullcols
(
  UPC_CODE,
  SFS_SAFETY_STOCK,
  SFS_STATUS,
  FIS_SAFETY_STOCK,
  FIS_STATUS
)
