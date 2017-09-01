-- COMP9311 17s1 Project 2
--
-- Section 2 Template

--------------------------------------------------------------------------------
-- Q4
--------------------------------------------------------------------------------

drop function if exists skyline_naive(text) cascade;

-- This function calculates skyline in O(n^2)
create or replace function skyline_naive(dataset text) 
    returns integer
as $body$
BEGIN
  EXECUTE 'CREATE OR REPLACE VIEW '|| dataset||'_skyline_naive(x,y) as '||
    ' select s1.x as x,s1.y as y  from ' || dataset|| ' as s1 where not exists(select * from '|| dataset|| ' as s2 where s2.x >= s1.x and s2.y > s1.y or s2.x >s1.x and s2.y >= s1.y) ';
  RETURN null;
END;
$body$ language plpgsql;

--------------------------------------------------------------------------------
-- Q5
--------------------------------------------------------------------------------

drop function if exists skyline(text) cascade;

-- This function simply creates a view to store skyline
create or replace function skyline(dataset text) 
    returns integer 
as $body$
DECLARE
   dataset_1  text:= dataset;
   now_value integer;
   i integer;
   i_1 integer;
   j integer;
   s integer;
   x_list_1 integer[];
   y_list_1 integer[];
   s_list integer[];
   
BEGIN
   EXECUTE 'select x from (select *,row_number() over (order by y desc) as sequence from '||dataset||' ) as s where s.sequence = 1'
      INTO now_value;  
   x_list_1 := array_append(x_list_1, now_value);
   s_list := array_append(s_list, 1);
   for i in 
      EXECUTE 'select x from (select *,row_number() over(order by y desc,x desc) as sequence from '|| dataset||' ) as s where s.sequence != 1'
   LOOP
      if i > now_value THEN
          now_value := i;
          EXECUTE '(select y from (select * from '||dataset||' order by y desc) as s where s.x = '|| i||' fetch first 1 rows only)'
             INTO j;
          
         EXECUTE '(select sequence from (select *,row_number() over (order by y desc,x desc) as sequence from '||dataset||') as s  where s.x = '|| i || ' fetch first 1 rows only)'
             INTO s;
 
          x_list_1 := array_append(x_list_1, i);
	  y_list_1 := array_append(y_list_1, j);
          s_list := array_append(s_list, s);
      end if;
   END LOOP;
   
  -- for i_1 in x_list_1
  -- LOOP
  --    EXECUTE '(select y from (select * from '||dataset||' order by y desc) as s where s.x = '||i_1||' fetch first 1 rows only)'
  --        INTO j;
  --    y_list_1 := array_append(y_list_1, j)
  -- END LOOP;
   
    
   EXECUTE 'CREATE OR REPLACE VIEW '|| dataset ||'_skyline(x,y) as '||
           'select x, y from (select *,row_number() over (order by y desc,x desc) as sequence from '||dataset|| ' ) as s where s.sequence in (' || array_to_string(s_list, ',')|| ' )';
   RETURN null;
END;
$body$ language plpgsql;

--------------------------------------------------------------------------------
-- Q6
--------------------------------------------------------------------------------

drop function if exists skyband_naive(text) cascade;

-- This function calculates skyband in O(n^2)
create or replace function skyband_naive(dataset text, k integer) 
    returns integer 
as $body$
BEGIN
  EXECUTE 'CREATE OR REPLACE VIEW '|| dataset ||'_skyband_naive(x,y) as '||
   ' select * from '|| dataset ||' as s1 where (select count(*) from '|| dataset ||' as s2 where s2.x >= s1.x and s2.y >s1.y or s2.x > s1.x and s2.y >= s1.y)< '||k;
  RETURN null;
END;
$body$ language plpgsql;

--------------------------------------------------------------------------------
-- Q7
--------------------------------------------------------------------------------

drop function if exists skyband(text, integer) cascade;

-- This function simply creates a view to store skyband
create or replace function skyband(dataset text, k integer) 
    returns integer 
as $body$
DECLARE
   i integer;
   s_list integer[];
   nv integer;
   now_value integer;
   now_se integer;
   se integer;
   se_1 integer;
   sequen integer;
   k_1 integer := k;
BEGIN
  s_list := array_append(s_list,-1);
  for nv,se in 
    EXECUTE 'select x,sequence from (select *,row_number() over (order by y desc,x desc) as sequence from '||dataset|| ' ) as s where s.sequence not in (' ||array_to_string(s_list, ',')|| ' )' 
  LOOP
    if k_1 <= 0  then
       EXIT;
    ELSIF se = any(s_list) then
       CONTINUE;
    ELSE
       now_value := nv;
       now_se := se;
       s_list := array_append(s_list, se);
       for i,se_1 in
         EXECUTE 'select x,sequence from (select *,row_number() over (order by y desc, x desc) as sequence from '||dataset|| ' ) as s where s.sequence != '|| now_se
       LOOP
         if se_1 = any(s_list) then
            CONTINUE;
         ELSIF i > now_value and se_1 != any(s_list) THEN
            now_value := i;
            sequen := se_1;
            s_list := array_append(s_list, sequen);
         END IF;
       END LOOP;
    END IF;
    k_1 := k_1 - 1;
  END LOOP;
  EXECUTE 'CREATE OR REPLACE VIEW '||dataset || '_skyband(x,y) as '||
          'select x, y from 
          (select * from (select *,row_number() over (order by y desc, x desc) as sequence from '||dataset || ' ) as s where s.sequence in (' || array_to_string(s_list, ',')|| ' )) as s1 where '||
          '( select count(*) from (select* from (select *,row_number() over (order by y desc, x desc) as sequence from '||dataset || ' ) as s where s.sequence in (' || array_to_string(s_list, ',')|| ' )) as s2 where (s2.x >=s1.x and s2.y >s1.y or s2.x > s1.x and s2.y >= s1.y))< ' ||k;

 
  RETURN null;
END;
$body$ language plpgsql;
