#Date Correction
UPDATE public_housing_inspection set `INSPECTION_DATE` = STR_TO_DATE(INSPECTION_DATE, '%Y-%m-%d');
SELECT INSPECTION_DATE from public_housing_inspection;
# Checking PHA's that have entry more than once
SELECT * FROM public_housing_inspection phi
GROUP BY PUBLIC_HOUSING_AGENCY_NAME
HAVING COUNT(*)>1;
# Created a Table to have filtered with PHA's that are Inspected more than once
DROP TABLE if exists newtable;
CREATE TABLE newtable AS
SELECT * 
FROM(SELECT *, count(1) 
over(partition by PUBLIC_HOUSING_AGENCY_NAME) as occurs
FROM public_housing_inspection) AS test
WHERE occurs>1;
SELECT * FROM newtable LIMIT 3851;
# SET falg on DATES to identify Most recent Date and Costs associated to it.
DROP TABLE if exists G;
CREATE TABLE G AS
SELECT N.PUBLIC_HOUSING_AGENCY_NAME AS PHA_NAME,
N.INSPECTION_DATE AS MR_DATE,
N.COST_OF_INSPECTION_IN_DOLLARS AS MR_COST ,row_number()  
 over (partition by PUBLIC_HOUSING_AGENCY_NAME 
 order by INSPECTION_DATE  desc) 
 as flag from newtable as N ;
 SELECT * from G;
 #Created a Table to select only top 2 when there is an increase in COST
 DROP TABLE IF EXISTS A;
 CREATE TABLE A AS
select * from g c where c.PHA_NAME in (
select PHA_NAME from g a
where a.flag = 1
and a.MR_COST > ( select b.MR_COST from g b where b.flag = 2 
					and a.PHA_NAME = b.PHA_NAME))
and c.flag in (1,2);
SELECT * FROM A;

# Converted rows to columns for a better View so that the columns asked in the columns would poulate:
select b.*, b.MR_INSPECTION_COST - b.SECOND_MR_INSPECTION_COST AS CHANGE_IN_COST, (b.MR_INSPECTION_COST - b.SECOND_MR_INSPECTION_COST)*100/b.SECOND_MR_INSPECTION_COST AS PERCENT_CHANGE_IN_COST   from(
SELECT 
A.PHA_NAME,
max(case when A.flag ='1' then A.MR_DATE end) MR_INSPECTION_DATE,
max(case when A.flag ='2' then A.MR_DATE end) SECOND_MR_INSPECTION_DATE,
max(case when A.flag='1' then A.MR_COST end) MR_INSPECTION_COST,
max(case when A.flag='2' then A.MR_COST end) SECOND_MR_INSPECTION_COST
from A
group by A.PHA_NAME) b;