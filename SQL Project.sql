#--Segment 1: Database - Tables, Columns, Relationships--
#---	1-) What are the different tables in the database and how are they connected to each other in the database?

-- ---#Movie to Genre: One movie can belong to multiple genres, but each genre typically applies to multiple movies. So, 
-- #it's a one-to-many relationship from Movie to Genre.each movie references a genre through the genre_id foreign key.
-- #Role_Mapping and Director_Mapping to Movie: Many roles (actors, directors) can be associated with one movie, but each movie has multiple 
-- #roles. So, it's a many-to-one relationship from Role_Mapping and Director_Mapping to Movie.Role_Mapping and Director_Mapping tables
--  have foreign keys (movie_id) referencing the Movie table, establishing a many-to-one relationship.



#---	2-) Find the total number of rows in each table of the schema--#

SELECT

T.table_name,
COUNT(C.column_name) AS row_count
FROM
INFORMATION_SCHEMA.TABLES T
JOIN
INFORMATION_SCHEMA.COLUMNS C ON T.table_name = C.table_name
WHERE
T.table_schema = 'projectsql1'
GROUP BY
T.table_name;


#---	3-) Identify which columns in the movie table have null values.---

select column_name from information_schema.columns
where table_name = 'movies'
and table_schema = 'projectsql1'
and is_nullable = 'YES';

select count(*) from movies;


#Segment 2: Movie Release Trends
#---	1-) Determine the total number of movies released each year and analyse the month-wise trend.

With cte as (SELECT
   month(date_published) AS release_month,
    COUNT(*) AS movies_count
FROM
    movies
GROUP BY
    release_month
ORDER BY  release_month) ,cte2 as (
select release_month, movies_count,
    ifnull(lag(movies_count) over (order by release_month),0) as previous from cte)
    select release_month ,
			movies_count,
           ifnull(round((movies_count-previous)/previous*100 ,2),0) as trend 
	from cte2;
    
#----	2-) Calculate the number of movies produced in the USA or India in the year 2019.---

select count(*) as movie_count from movies
where (country = 'USA' or country = 'India') and year = '2019';


#---Segment 3: Production Statistics and Genre Analysis---#

#-----	1-) Retrieve the unique list of genres present in the dataset.---

select distinct(genre) from genre;


#----	2-) Identify the genre with the highest number of movies produced overall---

select genre, count(movie_id) as movie_count from genre
group by 1
order by 2 desc limit 1;


#----	3-) Determine the count of movies that belong to only one genre.--

select movie_id, count(genre) as count_genre from genre
group by 1
having count_genre = 1;


#----	4-) Calculate the average duration of movies in each genre. ---

select g.genre,
		round(avg(duration),1) as average_duration from genre g
Left Join 
movies m on m.id = g.movie_id
group by 1;

#----	5-) Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.--

select * from (SELECT
    genre,
    dense_rank() OVER (ORDER BY COUNT(*) DESC) AS genre_rank
FROM
    genre
GROUP BY
    genre) as a
    WHERE
    genre = 'thriller';
    
    

#----Segment 4: Ratings Analysis and Crew Members ---#

#----	1-) Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).--
#column name
select
max(avg_rating), min(avg_rating), max(total_votes), min(total_votes), max(median_rating), min(median_rating) from ratings;


#----	2-) Identify the top 10 movies based on average rating. ---

select * from ratings
order by avg_rating desc
limit 10;


#--- -	3-) Summarise the ratings table based on movie counts by median ratings.--
#description add
select median_rating,
count(movie_id) as movie_count from ratings
group by 1;

#----	4-) Identify the production house that has produced the most number of hit movies (average rating > 8).--

with cte as (select m.production_company, count(distinct m.id) from movies m 
Inner Join
ratings r on
r.movie_id = m.id
where avg_rating >8 and production_company <> ""
group by 1
order by 2 desc limit 1)
select production_company from cte;


#----	5-) Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.--

select genre, count(*) from genre g 
Inner Join
movies m 
on m.id = g.movie_id
Join
ratings r on
r.movie_id = m.id
where country = 'USA' and year = 2017 and month(date_published) = 3 and total_votes > 1000
group by 1
order by 2 desc;

#---- 6-) Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.---

select m.title from movies m 
Inner Join
genre g  
on m.id = g.movie_id
Join
ratings r on
r.movie_id = m.id
where title like '%The' and avg_rating > 8;


#----Segment 5: Crew Analysis---#

#----	1-) Identify the columns in the names table that have null values.---

SELECT column_name
FROM information_schema.columns
WHERE table_name = 'names'
AND table_schema = 'projectsql1'
AND is_nullable = 'YES';

#-----	2-) Determine the top three directors in the top three genres with movies having an average rating > 8.---

with cte as (
select 
	genre
   from genre g 
inner join ratings r on g.movie_id=r.movie_id
where avg_rating>8
group by genre 
order by count(r.movie_id) desc limit 3),
cte2 as (
select name, genre, row_number() over (partition by genre order by avg_rating desc) as rnk from movies m
Join
genre g on 
g.movie_id = m.id
Join
ratings r 
on r.movie_id = m.id
Join
director_mapping d on
d.movie_id = m.id
Join
names n on
n.id = d.name_id
where avg_rating > 8 and genre in (select genre from cte))
select * from cte2
where rnk <=3;


#----	3-) Find the top two actors whose movies have a median rating >= 8.---


with cte as (select name, median_rating from role_mapping rm
Join
ratings r on 
r.movie_id = rm.movie_id
Join 
names n on
n.id = rm.name_id
Join
movies m on 
m.id = rm.movie_id
where median_rating >= 8 and category = 'actor')
select name,
row_number() over (order by median_rating desc) as rnk from cte
limit 2;

select name, count(median_rating) from movies m 
Join
ratings r on 
r.movie_id = m.id
Join
role_mapping rm on 
rm.movie_id = m.id
Join 
names n on
n.id = rm.name_id
where category = 'actor' and median_rating >=8
group by 1
order by 2 desc
limit 2;



#-----	4-) Identify the top three production houses based on the number of votes received by their movies. ---

select production_company from ( select production_company,
sum(total_votes) from movies m
Join
ratings r on 
r.movie_id = m.id
group by 1
order by sum(total_votes) desc
limit 3) a;


#---- -5-)	Rank actors based on their average ratings in Indian movies released in India.---


with cte as (select name, avg_rating, country from role_mapping rm
Join
ratings r on 
r.movie_id = rm.movie_id
Join 
names n on
n.id = rm.name_id
Join
movies m on 
m.id = rm.movie_id
where country like '%India%')
select name, dense_rank() over (order by avg_rating desc) as  rnk from cte;


#----	6-) Identify the top five actresses in Hindi movies released in India based on their average ratings.----

with cte as (select name, avg_rating from movies m 
Join
ratings r on 
r.movie_id = m.id
Join
role_mapping rm on 
rm.movie_id = m.id
Join 
names n on
n.id = rm.name_id
where country like '%India%' and languages like '%Hindi%' and category = 'actress')
select name, dense_rank() over (order by avg_rating desc) as rnk from cte
limit 5;

#----Segment 6: Broader Understanding of Data---#

#----1-) -	Classify thriller movies based on average ratings into different categories.---

select category, avg(avg_rating)  from movies m 
Join 
genre g on 
g.movie_id = m.id
Join 
ratings r on 
r.movie_id = m.id
Join 
role_mapping rm on
rm.movie_id = m.id
where genre = 'Thriller'
group by 1;


#----2-) -	analyse the genre-wise running total and moving average of the average movie duration. ---

with cte as (select genre, sum(duration) as total_duration , avg(duration) as avg_duration  from movies m
Join 
genre g on
g.movie_id = m.id
group by genre)
select genre, 
sum(total_duration) over (order by genre rows between unbounded preceding and current row) as running_total,
round(avg(avg_duration) over (order by genre rows between unbounded preceding and current row),2) as moving_avg from cte;

#----3-) -	Identify the five highest-grossing movies of each year that belong to the top three genres.---


with cte as (select 
	genre
   from genre  
group by genre 
order by count(movie_id) desc limit 3), cte2 as (
select year, title, row_number() over (partition by year order by avg_rating desc) as rnk from movies m
Join
genre g on 
g.movie_id=m.id
Join
ratings r on
r.movie_id=m.id
where genre in (select * from cte))
select * from cte2
where rnk <6;


#----4-) -	Determine the top two production houses that have produced the highest number of hits among multilingual movies. ----

select production_company, count(*) from movies m 
Join
ratings r on
r.movie_id=m.id
where avg_rating >8 and production_company <> ""
group by production_company
order by 2 desc
limit 2;

#----5-) -	Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.--

select name, count(*) from role_mapping rm
Join
ratings r on 
r.movie_id = rm.movie_id
Join 
names n on
n.id = rm.name_id
Join
movies m on 
m.id = rm.movie_id
Join 
genre g on
g.movie_id = m.id
where avg_rating >= 8 and category = 'actress' and genre = 'Drama'
group by 1
order by count(*) desc
limit 3;

#-----6-) Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.------#

with innter_movie_duration as 
(select 
     name_id,
	name as director ,
	date_published,
    datediff(lead(date_published) over (partition by name order by date_published), date_published) as day_diff 
from names n 
inner join director_mapping dm on n.id=dm.name_id
inner join movies m on dm.movie_id=m.id 
)
select 
	name as director, day_diff,
	count(dm.movie_id),
    round(avg(avg_rating),2) as ratings
from names n 
inner join director_mapping dm on n.id=dm.name_id
inner join ratings r on dm.movie_id=r.movie_id
inner join innter_movie_duration imd on dm.name_id=imd.name_id 
group by 1,2
order by 3 desc limit 9;


#---Segment 7: Recommendations ---

#----Based on the analysis, provide recommendations for the types of content Bolly movies should focus on producing.----

-- #This project structure provides a comprehensive roadmap for analyzing the IMDb movies dataset using SQL and deriving 
-- #actionable recommendations for Bolly Movies. Each segment addresses specific aspects of the data, ensuring a thorough 
-- #understanding of the dataset and meaningful insights for decision-making.






























