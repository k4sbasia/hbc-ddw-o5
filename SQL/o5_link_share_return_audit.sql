set serverout on 
set linesize 30 
set heading off
column eol newline
ttitle center 'Off 5th Link Share Return Load'  

SELECT 'COUNTRY'
  || '     '
  ||'US',
  'RETURN'
  || '       '
  || Trim (TO_CHAR (SUM (L.Amount), '999,999,999')),
  'RETURNDATE'
  || '   '
  || TRUNC (Ordline_Modifydate)
FROM o5.LS_SALES_CANCEL_RETURN l
Where Trunc (L.Ordline_Modifydate) = Trunc (Sysdate) - 1
AND Mid =38801
GROUP BY TRUNC (Ordline_Modifydate);

quit
