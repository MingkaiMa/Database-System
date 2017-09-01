-- COMP9311 17s1 Project 2
--
-- Section 1 Template

--Q1: ...
create type IncorrectRecord as (pattern_number integer, uoc_number integer);

create or replace function Q1(pattern text, uoc_threshold integer) 
	returns IncorrectRecord
as $body$
DECLARE
    result_record IncorrectRecord;
BEGIN  
    select count(s1.code)
    into result_record.pattern_number
    from subjects as s1
    where s1.code like pattern and s1.eftsload * 48 != s1.uoc; 
    select count(code)
    into result_record.uoc_number
    from subjects
    where code like pattern and eftsload * 48 != uoc and uoc > uoc_threshold;
    return result_record;
END;
$body$
language plpgsql;


create or replace view Q2_help(cid,term,code,name,uoc,mark,grade,rank,totalenrols)
as 
select a.cid,a.term,a.code,a.name,
case
  when c.uoc is null then 0
  else c.uoc
end,
a.mark,a.grade,d.rank,
case 
  when b.count is NULL then 0
  else b.count
end
from
(select co.course as cid,substr(cast(se.year as char(4)),3,4)||lower(se.term) as term,s.code as code,s.name as name,co.mark as mark,co.grade as grade
from course_enrolments as co join
courses as c on(c.id=co.course) join
semesters as se on (se.id=c.semester) join
subjects as s on(s.id=c.subject)
where co.student=1010093
) as a
left outer join
(select course as cid,count(course) as count from course_enrolments where course in(select course from course_enrolments where student=1010093) and mark is not null group by course)
as b on a.cid = b.cid
left outer join
(select co.course as cid,s.uoc as uoc 
from course_enrolments as co
join courses as c on(c.id=co.course)
join subjects as s on(c.subject=s.id)
where co.student=1010093
and
co.grade in
('SY','RS','PT','PC','PS','CR','DN','HD','A','B','C','D','E')
) as c
on a.cid=c.cid
left outer join
(select a.course as cid,a.sequence as rank from
(select *,row_number()
over(partition by a.course order by a.mark desc) as sequence from(select * from course_enrolments where course in(select course from course_enrolments where student=1010093)) as a) as a
where a.student=1010093 and a.mark is not null) as d
on a.cid=d.cid
;




-- Q2: ...
create type TranscriptRecord as (cid integer, term char(4), code char(8), name text, uoc integer, mark integer, grade char(2), rank integer, totalEnrols integer);

create or replace function Q2(stu_unswid integer)
	returns setof TranscriptRecord

as $body$
declare
    r TranscriptRecord;
    stu_id integer :=(select id from people where unswid=stu_unswid);
BEGIN
   return query 
   
select a.cid,a.term,a.code,a.name,
case
  when c.uoc is null then 0
  else c.uoc
end,
a.mark,a.grade,d.rank,
case
  when b.count is NULL then 0
  else b.count
end
from
(select co.course as cid,cast(substr(cast(se.year as char(4)),3,4)||lower(se.term) as char(4)) as term,s.code as code,cast(s.name as text) as name,co.mark as mark,cast(co.grade as char(2)) as grade
from course_enrolments as co join
courses as c on(c.id=co.course) join
semesters as se on (se.id=c.semester) join
subjects as s on(s.id=c.subject)
where co.student=stu_id
) as a
left outer join
(select course as cid,cast(count(course) as integer) as count from course_enrolments where course in(select course from course_enrolments where student=stu_id) and mark is not null group by course)
as b on a.cid = b.cid
left outer join
(select co.course as cid,s.uoc as uoc
from course_enrolments as co
join courses as c on(c.id=co.course)
join subjects as s on(c.subject=s.id)
where co.student=stu_id
and
co.grade in
('SY','RS','PT','PC','PS','CR','DN','HD','A','B','C','D','E')
) as c
on a.cid=c.cid
left outer join
(select a.course as cid,cast(a.sequence as integer) as rank from
(select *,row_number()
over(partition by a.course order by a.mark desc) as sequence from(select * from course_enrolments where course in(select course from course_enrolments where student=stu_id)) as a) as a
where a.student=stu_id and a.mark is not null) as d
on a.cid=d.cid
;

 
END;
    
$body$ 
language plpgsql;


















create or replace view Q3_help(staff)
as

select distinct(b.staff),b.id,b.count from(

select cs.staff,s.id,count(s.id)
from course_staff as cs join
courses as c on(c.id=cs.course) join
subjects as s on(s.id=c.subject) 

where cs.staff in(
select a.staff from (
select cs.staff,count(distinct s.id)
from course_staff as cs join
courses as c on(cs.course=c.id) join
subjects as s on(c.subject=s.id) join
staff_roles as ss on(ss.id=cs.role)
where (s.offeredby =52 or s.offeredby in(select member from orgunit_groups where owner=52))
and ss.name not like 'Course Tutor'
group by cs.staff having count(distinct s.id)>20
) as a
) 
group by cs.staff,s.id

) as b 

where b.count>8
order by b.staff,b.id
;


create or replace view Q3_help_1(id,name,code,count,o_name)
as

select p.unswid,p.name,s.code,q.count,g.name from q3_help as q join people as p on(p.id=q.staff) 
join subjects as s on (s.id=q.id)
join orgunits as g on(g.id=s.offeredby)
;


create or replace view Q3_help_2(id,name,record)
as

select q.id,q.name, q.code||', '||q.count||', '||q.o_name as teacing_records
from q3_help_1 as q
group by q.id,q.name,q.code,q.count,q.o_name
order by id,name
;


create or replace view q3_final(unswid,staff_name,teaching_records)
as
select q1.id as unswid,q1.name as staff_name,string_agg(q1.records::text, E'\n')||E'\n' as teaching_records
from (

select q2.unswid as id,q2.pname as name, q2.code||', '||q2.count||', '||q2.o_name as records
from (


select p.unswid as unswid,p.name as pname,s.code,q3.count,g.name as o_name
from (

select distinct(b.staff),b.id,b.count from(

select cs.staff,s.id,count(s.id)
from course_staff as cs join
courses as c on(c.id=cs.course) join
subjects as s on(s.id=c.subject) 

where cs.staff in(
select a.staff from (
select cs.staff,count(distinct s.id)
from course_staff as cs join
courses as c on(cs.course=c.id) join
subjects as s on(c.subject=s.id) join
staff_roles as ss on(ss.id=cs.role)
where (s.offeredby =52 or s.offeredby in(select member from orgunit_groups where owner=52))
and ss.name not like 'Course Tutor'
group by cs.staff having count(distinct s.id)>20
) as a
) 
group by cs.staff,s.id

) as b

where b.count>8
order by b.staff,b.id

)
as q3
join people as p on(p.id=q3.staff)
join subjects as s on (s.id=q3.id)
join orgunits as g on(g.id=s.offeredby)


) as q2
group by q2.unswid,q2.pname,q2.code,q2.count,q2.o_name
order by q2.unswid,q2.pname

)
 as q1
group by q1.id,q1.name
order by q1.name
;


-- Q3: ...
create type TeachingRecord as (unswid integer, staff_name text, teaching_records text);

create or replace function Q3(org_id integer, num_sub integer, num_times integer) 
	returns setof TeachingRecord 
as $$
declare
   r TeachingRecord;
   o_id integer :=org_id;
   ns integer := num_sub;
   nt integer := num_times;
BEGIN
   return query




select q1.id as unswid,cast(q1.name as text) as staff_name,cast(string_agg(q1.records::text, E'\n')||E'\n' as text) as teaching_records
from ( 

select q2.unswid as id,q2.pname as name, q2.code||', '||q2.count||', '||q2.o_name as records
from ( 


select p.unswid as unswid,p.name as pname,s.code,q3.count,g.name as o_name
from ( 

select distinct(b.staff),b.id,b.count from(

select cs.staff,s.id,count(s.id)
from course_staff as cs join
courses as c on(c.id=cs.course) join
subjects as s on(s.id=c.subject) 

where cs.staff in(
select a.staff from (
select cs.staff,count(distinct s.id)
from course_staff as cs join
courses as c on(cs.course=c.id) join
subjects as s on(c.subject=s.id) join
staff_roles as ss on(ss.id=cs.role)
where (s.offeredby =o_id or s.offeredby in(select member from orgunit_groups where owner=o_id))
and ss.name not like 'Course Tutor'
group by cs.staff having count(distinct s.id)>ns
) as a
) 
group by cs.staff,s.id

) as b

where b.count>nt
order by b.staff,b.id

)
as q3
join people as p on(p.id=q3.staff)
join subjects as s on (s.id=q3.id)
join orgunits as g on(g.id=s.offeredby)


) as q2
group by q2.unswid,q2.pname,q2.code,q2.count,q2.o_name
order by q2.unswid,q2.pname

)
 as q1
group by q1.id,q1.name
order by q1.name;

END;


--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;



