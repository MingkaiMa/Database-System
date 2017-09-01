-- COMP9311 17s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1: buildings that have more than 30 rooms
create or replace view Q1(unswid, name)
as select b.unswid,b.name 
from buildings as b
where(select count(*) from rooms as r where b.id=r.building)>30
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q2: get details of the current Deans of Faculty
create or replace view Q2(name, faculty, phone, starting)
as select p.name,o.longname,s.phone,a.starting
from affiliations as a join orgunits as o on(a.orgunit=o.id) join staff as s on(s.id=a.staff) join people as p on (p.id=s.id)
where a.role in (select id from staff_roles where name like 'Dean') and a.ending is null and a.orgunit in (select o.id from orgunits as o where o.utype=1 and o.longname like 'Faculty%' or o.longname like 'College%(COFA)' or o.longname like 'Australian School%')
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q3: get details of the longest-serving and shortest-serving current Deans of Faculty
create or replace view Q3(status, name, faculty, starting)
as select 'Longest serving',q.name,q.faculty,q.starting from Q2 as q where q.starting in (select min(starting) from Q2) union select 'Shortest serving',q.name,q.faculty,q.starting from Q2 as q where q.starting in (select max(starting) from Q2)
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q4 UOC/ETFS ratio
create or replace view Q4(ratio,nsubjects)
as select distinct cast(uoc/eftsload as numeric(4,1)) as ratio,count(*)
from subjects
where eftsload is not null and eftsload != 0 group by ratio
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q5: program enrolment information from 10s1
create or replace view Q5a(num)
as select count(p.student)
from program_enrolments as p where p.id in (select partof from stream_enrolments where stream in (select id from streams where name like 'Software Engineering%')) and p.semester in (select id from semesters where name like 'Sem1 2010') and p.student in (select id from students where stype = 'intl')
--... SQL statements, possibly using other views/functions defined by you ...
;

create or replace view Q5b(num)
as select count(p.student) 
from program_enrolments as p 
where p.program in (select id from programs where code ='3978') and p.semester in (select id from semesters where name like 'Sem1 2010') and p.student in (select id from students where stype ='local')
--... SQL statements, possibly using other views/functions defined by you ...
;

create or replace view Q5c(num)
as select count(p.student)
from program_enrolments as p
where p.program in (select programs.id from programs where programs.offeredby in (select o.id from orgunits as o where o.longname like 'Faculty of Engineering')) and p.semester in (select id from semesters where name like 'Sem1 2010')
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q6: course CodeName
create or replace function Q6(text)
returns text AS $$
  SELECT s.code || ' ' || s.name from subjects as s where s.code like $1
$$ LANGUAGE SQL;


--... SQL statements, possibly using other views/functions defined by you ...





-- Q7_Aid:create this view to finish the Q7
create or replace view aid(year,term,ending,id,enrol_number)
as select sem.year,sem.term,sem.ending,sem.id,count(c.student)
from course_enrolments as c join courses as co on (c.course=co.id) join semesters as sem on(co.semester=sem.id)
where c.course in (select co.id from courses as co where co.subject in (select s.id from subjects as s where s.name like 'Database Systems') and co.semester in (select se.id from semesters as se where se.term like 'S%' and cast(se.year as char(4)) like '20%')) group by sem.year,sem.term,sem.ending,sem.id order by sem.year,sem.term
--...
;


-- Q7: Percentage of growth of students enrolled in Database Systems
create or replace view Q7(year, term, perc_growth)
as select a1.year,a1.term,cast(cast(a1.enrol_number as float)/a2.enrol_number as numeric(4,2)) from aid as a1,aid as a2 where (a1.year = a2.year and a1.term like 'S2' and a2.term like 'S1') or (a1.year - a2.year = 1 and a1.term like 'S1' and a2.term like 'S2') 
--... SQL statements, possibly using other views/functions defined by you ...
;





--Q8:subject_20_offer
create or replace view Q8_subject_20_offer(subject,count)
as select subject,count(id) from courses group by subject having count(*)>=20
--
;

--Q8:join
create or replace view Q8_course_join(course,subject,semester,student)
as select c.id as course,subject,semester,student from courses as c left outer join course_enrolments as cc on(c.id = cc.course) where subject in(select subject from q8_subject_20_offer) order by subject,semester desc
;

--Q8:
create or replace view Q8_count(subject,semester,count)
as select subject,semester,count(student) from q8_course_join group by subject,semester order by subject,semester desc
;

--Q8:with sequence
create or replace view Q8_with_sequence(subject,semester,count,sequence)
as select *, row_number() over(partition by subject order by semester desc) as sequence from q8_count
--
;

--Q8:top20
create or replace view Q8_20(subject,semester,count,sequence)
as select * from Q8_with_sequence where sequence <= 20
--
;

---Q8:subject result
create or replace view Q8_subject_result(subject)
as select distinct subject from q8_20 as a where not exists (select * from q8_20 as b where a.subject = b.subject and count >= 20)
--
;

--Q8:Least popular subjects
create or replace view Q8(subject)
as select code||' '||name from subjects where id in (select * from q8_subject_result)
--
;

--Q9_help1:
create or replace view Q9_help1(year,term,number)
as select sem.year,sem.term,count(c.student) from course_enrolments as c join courses as co on (c.course=co.id) join semesters as sem on (co.semester=sem.id) where c.course in (select co.id from courses as co where co.subject in (select s.id from subjects as s where s.name like 'Database Systems') and co.semester in (select se.id from semesters as se where se.term like 'S%' and cast(se.year as char(4)) like '20%')) and c.mark >=0 group by sem.year,sem.term order by sem.year,sem.term
--...
;

--Q9_help2:
create or replace view Q9_help2(year,term,number)
as select sem.year,sem.term,count(c.student) from course_enrolments as c join courses as co on (c.course=co.id) join semesters as sem on (co.semester=sem.id) where c.course in (select co.id from courses as co where co.subject in (select s.id from subjects as s where s.name like 'Database Systems') and co.semester in (select se.id from semesters as se where se.term like 'S%' and cast(se.year as char(4)) like '20%')) and c.mark >=50 group by sem.year,sem.term order by sem.year,sem.term
--
;

--Q9_help3:
create or replace view Q9_help3(year,term,rate)
as select h2.year,h2.term,cast(cast(h2.number as float)/h1.number as numeric(4,2)) as s1_pass_rate from q9_help1 as h1,q9_help2 as h2 where h1.term = h2.term and h1.year= h2.year
--
;



-- Q9: Database Systems pass rate for both semester in each year
create or replace view Q9(year, s1_pass_rate, s2_pass_rate)
as select right(cast(h3.year as char(4)),2),h3.rate as s1_pass_rate,h33.rate as s2_pass_rate from q9_help3 as h3,q9_help3 as h33 where h3.year=h33.year and h3.term like 'S1' and h33.term like 'S2' order by h3.year
--... SQL statements, possibly using other views/functions defined by you ...
;




--Q10:Subjectset
create or replace view Q10_subjectset(subject,count)
as select subject,count(semester) from courses where subject in (select id from subjects where code like 'COMP93%') group by subject having count(*)=24
--
;

--Q10:student_set
create or replace view Q10_student(student,count)
as select student,count(course) from course_enrolments where course in (select id from courses where subject in (select subject from q10_subjectset)) and mark < 50 group by student having count(*)>1 order by student
--
;



--Q10:student_subject
create or replace view Q10_student_subject(student,subject)
as select student,sub.id from course_enrolments as cc join courses as c on(cc.course = c.id) join subjects as sub on (sub.id=c.subject) where cc.course in (select id from courses where subject in (select subject from q10_subjectset)) and mark < 50  order by student
--
;

--Q10:student_result(student)
create or replace view Q10_student_result
as select student from q10_student as x where not exists((select subject from q10_subjectset) except (select subject from q10_student_subject as y where x.student = y.student))
--
;

-- Q10: find all students who failed all black series subjects
create or replace view Q10(zid, name)
as select 'z'||unswid, name from people where id in (select student from q10_student_result)
--
;



