WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 2000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET TRIMSPOOL ON
SET SERVEROUT ON
SET WRAP OFF
SET NEWPAGE NONE
SET PAGESIZE 0
SET SQLBLANKLINE OFF
SET ARRAYSIZE 5000

DECLARE
VAR_COUNT INT;
BEGIN
SELECT COUNT(*) INTO VAR_COUNT
FROM ALL_TABLES WHERE OWNER = 'O5' AND TABLE_NAME = 'PRODUCT_ATTRIBUTE_RR_FEED';
IF VAR_COUNT > 0 THEN
EXECUTE IMMEDIATE
'DROP TABLE O5.PRODUCT_ATTRIBUTE_RR_FEED';
END IF;
END;
/
      CREATE TABLE  O5.PRODUCT_ATTRIBUTE_RR_FEED AS
         SELECT *
          FROM (SELECT PRODUCT_ID,
                        GROUP_ID,
                        DEPARTMENT,
                        COST,
                        MORECOLORS,
                        PREORDER,
                        RATING_IMAGE_URL,
                        DISPLAY_REVIEW,
                        NOW_PRICE_RANGE,
                        WAS_PRICE_RANGE,
                        SALES_FLAG,
                        CASE
                           WHEN O5.F_GET_RR_ALT_IMAGE (PRODUCT_ID, 'A1')
                                   IS NOT NULL
                           THEN
                              'Y'
                           ELSE
                              'N'
                        END
                           AS ALT_IMAGE_1,
                         O5.F_GET_RR_ALT_IMAGE (PRODUCT_ID, '')  AS ALT_IMAGE_2,
                      O5.F_GET_RR_ALT_IMAGE (PRODUCT_ID, 'A1') AS ALT_IMAGE_FLAG,
                        DECODE (
                           'o5',
                           'mrep.', 'http://m.saks.com/pd.jsp?productCode=',
                           'o5.', 'https://m.saksoff5th.com/pd.jsp?productCode=')
                        || PRODUCT_ID
                           AS MOBILE_URL,
                        DECODE (
                           'o5',
                           'mrep.', 'http://image.s5a.com/is/image/saks/',
                           'o5.', 'https://image.s5a.com/is/image/saksoff5th/')
                        || PRODUCT_ID
                           AS MOBILE_URL_ALT,
                        NVL (OBA_STR_VAL, NVL (OBA_BOO_VAL, OBA_INT_VAL))
                           ATR_VAL,
                        ATR_NM_LOWER
                   FROM O5.OBJECT_ATTRIBUTE OA,
                        O5.ATTRIBUTE A,
                        O5.FEED_RR_PRODUCT_DAILY P
                  WHERE OA.OBA_ATR_ID = A.ATR_ID
                        AND P.PRD_ID = OA.OBA_OBJ_ID
                        AND OA.VERSION = 1
                        AND A.ATR_NM_LOWER IN
                               ('backorderable',
                                'brandname',
                                'dropship_ind',
                                'featuredtype',
                                'gwp_flag',
                                'item_gender',
                                'pd_restrictedcountry_text',
                                'pd_restrictedstate_text',
                                'personalizable',
                                'productshortdescription',
                                'returnable',
                                'totalreviewcount',
                                'isdesigneritem',
                                'isegc',
                                'isvirtual',
                                'lifestylecontemporary',
                                'lifestylemodern',
                                'lifestylepremier',
                                'refinementproducttype1',
                                'refinementproducttype2',
                                'refinementproducttype3',
                                'refinementstyle1',
                                'refinementstyle2',
                                'refinementstyle3',
                                'refage',
                                'refcollection',
                                'refconcern1',
                                'refconcern2',
                                'refconcern3',
                                'refcoverage',
                                'refcuff',
                                'reffinefashion',
                                'reffinish',
                                'refgender',
                                'reflength',
                                'refmaterial1',
                                'refmaterial2',
                                'refmaterial3',
                                'refoccasion1',
                                'refoccasion2',
                                'refpatternprint',
                                'refrise',
                                'refspf',
                                'refscent1',
                                'refscent2',
                                'refscent3',
                                'refsilhouette1',
                                'refsilhouette2',
                                'refsilhouette3',
                                'refskintype',
                                'refsleevelength',
                                'refwash',
                                'refinementfit1',
                                'refinementfit2',
                                'refinementheelheight')) PIVOT (MIN (ATR_VAL)
                                                         FOR ATR_NM_LOWER
                                                         IN  ('backorderable',
                                                             'brandname',
                                                             'dropship_ind',
                                                             'featuredtype',
                                                             'gwp_flag',
                                                             'item_gender',
                                                             'pd_restrictedcountry_text',
                                                             'pd_restrictedstate_text',
                                                             'personalizable',
                                                             'productshortdescription',
                                                             'returnable',
                                                             'totalreviewcount',
                                                             'isdesigneritem',
                                                             'isegc',
                                                             'isvirtual',
                                                             'lifestylecontemporary',
                                                             'lifestylemodern',
                                                             'lifestylepremier',
                                                             'refinementproducttype1',
                                                             'refinementproducttype2',
                                                             'refinementproducttype3',
                                                             'refinementstyle1',
                                                             'refinementstyle2',
                                                             'refinementstyle3',
                                                             'refage',
                                                             'refcollection',
                                                             'refconcern1',
                                                             'refconcern2',
                                                             'refconcern3',
                                                             'refcoverage',
                                                             'refcuff',
                                                             'reffinefashion',
                                                             'reffinish',
                                                             'refgender',
                                                             'reflength',
                                                             'refmaterial1',
                                                             'refmaterial2',
                                                             'refmaterial3',
                                                             'refoccasion1',
                                                             'refoccasion2',
                                                             'refpatternprint',
                                                             'refrise',
                                                             'refspf',
                                                             'refscent1',
                                                             'refscent2',
                                                             'refscent3',
                                                             'refsilhouette1',
                                                             'refsilhouette2',
                                                             'refsilhouette3',
                                                             'refskintype',
                                                             'refsleevelength',
                                                             'refwash',
                                                             'refinementfit1',
                                                             'refinementfit2',
                                                             'refinementheelheight'));

SELECT 'product_id'||'|'||
'attribute.Group'||'|'||
'attribute.Department'||'|'||
'attribute.cost'||'|'||
'attribute.morecolors'||'|'||
'attribute.preorder'||'|'||
'attribute.rating_image_url'||'|'||
'attribute.display_review'||'|'||
'attribute.now_price_range'||'|'||
'attribute.was_price_range'||'|'||
'attribute.sale_flag'||'|'||
'attribute.alt_image_flag'||'|'||
'attribute.alt_image_1'||'|'||
'attribute.alt_image_2'||'|'||
'attribute.mobile_url'||'|'||
'attribute.mobile_url_alt'||'|'||
'attribute.backorderable'||'|'||
'attribute.brandname'||'|'||
'attribute.dropship_ind'||'|'||
'attribute.featuredtype'||'|'||
'attribute.gwp_flag'||'|'||
'attribute.item_gender'||'|'||
'attribute.pd_restrictedcountry_text'||'|'||
'attribute.pd_restrictedstate_text'||'|'||
'attribute.personalizable'||'|'||
'attribute.productshortdescription'||'|'||
'attribute.returnable'||'|'||
'attribute.totalreviewcount'||'|'||
'attribute.isdesigneritem'||'|'||
'attribute.isegc'||'|'||
'attribute.isvirtual'||'|'||
'attribute.lifestylecontemporary'||'|'||
'attribute.lifestylemodern'||'|'||
'attribute.lifestylepremier'||'|'||
'attribute.refinementproducttype1'||'|'||
'attribute.refinementproducttype2'||'|'||
'attribute.refinementproducttype3'||'|'||
'attribute.refinementstyle1'||'|'||
'attribute.refinementstyle2'||'|'||
'attribute.refinementstyle3'||'|'||
'attribute.refage'||'|'||
'attribute.refcollection'||'|'||
'attribute.refconcern1'||'|'||
'attribute.refconcern2'||'|'||
'attribute.refconcern3'||'|'||
'attribute.refcoverage'||'|'||
'attribute.refcuff'||'|'||
'attribute.reffinefashion'||'|'||
'attribute.reffinish'||'|'||
'attribute.refgender'||'|'||
'attribute.reflength'||'|'||
'attribute.refmaterial1'||'|'||
'attribute.refmaterial2'||'|'||
'attribute.refmaterial3'||'|'||
'attribute.refoccasion1'||'|'||
'attribute.refoccasion2'||'|'||
'attribute.refpatternprint'||'|'||
'attribute.refrise'||'|'||
'attribute.refspf'||'|'||
'attribute.refscent1'||'|'||
'attribute.refscent2'||'|'||
'attribute.refscent3'||'|'||
'attribute.refsilhouette1'||'|'||
'attribute.refsilhouette2'||'|'||
'attribute.refsilhouette3'||'|'||
'attribute.refskintype'||'|'||
'attribute.refsleevelength'||'|'||
'attribute.refwash'||'|'||
'attribute.refinementfit1'||'|'||
'attribute.refinementfit2'||'|'||
'attribute.refinementheelheight' FROM DUAL;

SELECT PRODUCT_ID    ||'|'||
GROUP_ID    ||'|'||
DEPARTMENT    ||'|'||
COST    ||'|'||
MORECOLORS    ||'|'||
PREORDER    ||'|'||
RATING_IMAGE_URL    ||'|'||
DISPLAY_REVIEW    ||'|'||
NOW_PRICE_RANGE    ||'|'||
WAS_PRICE_RANGE    ||'|'||
SALES_FLAG    ||'|'||
ALT_IMAGE_1    ||'|'||
ALT_IMAGE_2    ||'|'||
ALT_IMAGE_FLAG    ||'|'||
MOBILE_URL    ||'|'||
MOBILE_URL_ALT    ||'|'||
"'backorderable'" ||'|'||
"'brandname'" ||'|'||
"'dropship_ind'" ||'|'||
"'featuredtype'" ||'|'||
"'gwp_flag'" ||'|'||
"'item_gender'" ||'|'||
"'pd_restrictedcountry_text'" ||'|'||
"'pd_restrictedstate_text'" ||'|'||
"'personalizable'" ||'|'||
"'productshortdescription'" ||'|'||
"'returnable'" ||'|'||
"'totalreviewcount'" ||'|'||
"'isdesigneritem'" ||'|'||
"'isegc'" ||'|'||
"'isvirtual'" ||'|'||
"'lifestylecontemporary'" ||'|'||
"'lifestylemodern'" ||'|'||
"'lifestylepremier'" ||'|'||
"'refinementproducttype1'" ||'|'||
"'refinementproducttype2'" ||'|'||
"'refinementproducttype3'" ||'|'||
"'refinementstyle1'" ||'|'||
"'refinementstyle2'" ||'|'||
"'refinementstyle3'" ||'|'||
"'refage'" ||'|'||
"'refcollection'" ||'|'||
"'refconcern1'" ||'|'||
"'refconcern2'" ||'|'||
"'refconcern3'" ||'|'||
"'refcoverage'" ||'|'||
"'refcuff'" ||'|'||
"'reffinefashion'" ||'|'||
"'reffinish'" ||'|'||
"'refgender'" ||'|'||
"'reflength'" ||'|'||
"'refmaterial1'" ||'|'||
"'refmaterial2'" ||'|'||
"'refmaterial3'" ||'|'||
"'refoccasion1'" ||'|'||
"'refoccasion2'" ||'|'||
"'refpatternprint'" ||'|'||
"'refrise'" ||'|'||
"'refspf'" ||'|'||
"'refscent1'" ||'|'||
"'refscent2'" ||'|'||
"'refscent3'" ||'|'||
"'refsilhouette1'" ||'|'||
"'refsilhouette2'" ||'|'||
"'refsilhouette3'" ||'|'||
"'refskintype'" ||'|'||
"'refsleevelength'" ||'|'||
"'refwash'" ||'|'||
"'refinementfit1'" ||'|'||
"'refinementfit2'" ||'|'||
"'refinementheelheight'" FROM O5.PRODUCT_ATTRIBUTE_RR_FEED;

EXIT;
