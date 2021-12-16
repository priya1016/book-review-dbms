/********************************************** creating goodreads schema ****************************************/
CREATE SCHEMA `goodreads` ;

/*select above schema in mysql workbench*/
/**************************************************** creating tables ********************************************/
/*Total number of tables:6 */

/*table1: Reader containing all attributes of users*/
CREATE TABLE Reader
(
  Username varchar(100) NOT NULL default 'Null',
  Password varchar(10) NOT NULL,
  Email_id varchar(50) ,
  DOB DATE,
  PRIMARY KEY (Username)
);

/*table2: Books containing all attributes of books */
CREATE TABLE Books
(
  Book_title varchar(100) NOT NULL,
  Book_id varchar(10) NOT NULL ,
  no_of_reviews int,
  no_of_pages int check(no_of_pages>0),
  Author_name VARCHAR(50),
  genre varchar(100),
  PRIMARY KEY (Book_id)
);

/*table3: Reading table containing details about the users who are currently reading the book with available number of reviews for that book(2) */
CREATE TABLE Reading
(
  Username varchar(100) ,
  Book_id varchar(10) ,
   Available_no_of_reviews INT DEFAULT 2 ,
  PRIMARY KEY (Username, Book_id),
  FOREIGN KEY (Username) REFERENCES Reader(Username)   on delete set null ,
  FOREIGN KEY (Book_id) REFERENCES Books(Book_id) on  delete cascade
);

/*table4: Review table containing details about all the reviews written by the user for books */
CREATE TABLE Review
(
  Review_id INT,
  Timestamp Date,
  Description VARCHAR(10000),
  Recommended char(1),
  Rating INT NOT NULL check(Rating>0 and Rating<6),
  no_of_likes int,
  Username varchar(100) NOT NULL,
  Book_id varchar(10),
  PRIMARY KEY (Review_id),
  FOREIGN KEY (Username) REFERENCES Reader(Username) on delete set default,
  FOREIGN KEY (Book_id) REFERENCES Books(Book_id) on delete set null
);

/*table5: wants_to_read table containing details about the books that user wants to read */
CREATE TABLE wants_to_read
(
  Username varchar(100) NOT NULL,
  Book_id varchar(10) NOT NULL,
  PRIMARY KEY (Username, Book_id),
  FOREIGN KEY (Username) REFERENCES Reader(Username) on delete set default,
  FOREIGN KEY (Book_id) REFERENCES Books(Book_id) on  delete cascade
);

/*table6: Books_Publisher_name table containing details about the publisher of the book*/
CREATE TABLE Books_Publisher_name
(
  Publisher_name VARCHAR(100),
  Book_id varchar(10) NOT NULL,
  PRIMARY KEY (Publisher_name, Book_id),
  FOREIGN KEY (Book_id) REFERENCES Books(Book_id)
);


/**************************************************** creating views ********************************************/
/*Total number of views: 3 */

/*view 1: to get the average rating at book level from reviews data */
create view avg_rating_book as 
select b.book_id,avg(r.rating) as avg_rating, count(distinct r.review_id) as no_of_reviews
from books as b
left join review as r 
on b.book_id=r.review_id
group by b.book_id ;

/*view 2: to get the  Book Details, reviews (latest 5), average rating  */
create view book_details as 
select b.*,a.avg_rating,r.description,r.rating,r.rankk
from books as b
left join avg_rating_book as a on a.book_id=b.book_id
left join 
	(select r.book_id,r.description,r.rating,r.rankk
	from
		(select r.*,
		row_number() over (partition by r.book_id order by r.Timestamp desc) as rankk
		from review as r 
		) as r
	where r.rankk<6
    )as r on b.book_id=r.book_id ;
	
/*view 3: to get all reader details */
CREATE view reader_details as  
select r.Username AS Username,r.Password AS Password,
r.Email_id AS Email_id,r.DOB AS DOB,
count(distinct v.Review_id) AS no_of_reviews,
avg(v.Rating) AS avg_rating,count(distinct w.Book_id) AS wants_to_read 
from reader as r 
left join review v on r.Username = v.username 
left join wants_to_read as w on r.Username = w.username


/**************************************************** creating Stored Procedures ********************************************/
/*Total number of Stored Procedures: 5 */

/* Stored Procedure1: to insert book details in books table */
delimiter $$  
create procedure insert_books   
( 	 in book_title varchar(100),  
     in book_id varchar(10),  
     in no_of_reviews int, 
     in no_of_pages int, 
     in author_name varchar(50), 
     in genre varchar(100) 
     ) 
  begin  
  insert into books values(book_title,book_id,no_of_reviews,no_of_pages,author_name,genre); 
end $$  
delimiter $$  
 
/* Stored Procedure2: to insert reader details in reader table */
delimiter $$  
create procedure insert_reader  
( 	 in username varchar(100),  
     in password varchar(10),  
     in email_id varchar(50), 
     in dob DATE 	 
     ) 
  begin  
  insert into reader values(username,password,email_id,dob); 
end $$  
delimiter $$  

/* Stored Procedure3: to delete reader details from reader table */
delimiter $$  
create procedure delete_reader   
( 	 in a_username varchar(100) 
     ) 
  begin  
  delete from reader where username=a_username; 
end $$  
delimiter $$  

/* Stored Procedure4:: to search book details by book_name*/
delimiter $$  
create procedure books_search   
(    in  book_title varchar(100),  
     out a_Book_title varchar(100) ,
	 out a_Book_id varchar(10) ,
	 out a_no_of_reviews int,
	 out a_no_of_pages int,
	 out a_Author_name VARCHAR(50),
	 out a_genre varchar(100),
	 out a_avg_rating decimal,
	 out a_description VARCHAR(10000),
	 out a_rating int)
  begin  
  select Book_title into a_Book_title from book_details 
  where trunc(lower(book_details.book_title))=trunc(lower(book_title));
  select Book_id into a_Book_id from book_details 
  where trunc(lower(book_details.book_title))=trunc(lower(book_title));
  select no_of_reviews into a_no_of_reviews from book_details 
  where trunc(lower(book_details.book_title))=trunc(lower(book_title));
  select no_of_pages into a_no_of_pages from book_details 
  where trunc(lower(book_details.book_title))=trunc(lower(book_title));
  select Author_name into a_Author_name from book_details 
  where trunc(lower(book_details.book_title))=trunc(lower(book_title));
  select genre into a_genre from book_details 
  where trunc(lower(book_details.book_title))=trunc(lower(book_title));
  select avg_rating into a_avg_rating from book_details 
  where trunc(lower(book_details.book_title))=trunc(lower(book_title));
  select description into a_description from book_details 
  where trunc(lower(book_details.book_title))=trunc(lower(book_title));
  select rating into a_rating from book_details 
  where trunc(lower(book_details.book_title))=trunc(lower(book_title));
end $$  
delimiter $$  
  
/* Stored Procedure5: to search user details by username */
delimiter $$  
create procedure users_search   
(    in  username varchar(100),  
     out a_username varchar(100) ,
	 out a_email_id varchar(50) ,
	 out a_dob date,
	 out a_no_of_reviews int,
	 out a_avg_rating decimal,
	 out a_wants_to_read int)
  begin  
  select username into a_username from reader_details 
  where trunc(lower(reader_details.username))=trunc(lower(username));
  select email_id into a_email_id from reader_details 
  where trunc(lower(reader_details.username))=trunc(lower(username));
  select dob into a_dob from reader_details 
  where trunc(lower(reader_details.username))=trunc(lower(username));
  select no_of_reviews into a_no_of_reviews from reader_details 
  where trunc(lower(reader_details.username))=trunc(lower(username));
  select avg_rating into a_avg_rating from reader_details 
  where trunc(lower(reader_details.username))=trunc(lower(username));
  select wants_to_read into a_wants_to_read from reader_details 
  where trunc(lower(reader_details.username))=trunc(lower(username));
end $$  
delimiter $$  


/**************************************************** creating Functions ********************************************/
/*Total number of Functions: 3 */

/* Function1: total no of books for each author */
delimiter $$
create function author_books(author_name varchar(50))
returns INT
deterministic
begin
	declare book_count int;
	select count(distinct book_id) into book_count
	from books 
	where books.author_name=author_name;
	return book_count;
end $$
delimiter

/* Function2: total no of read users for each book title */
delimiter $$
create function read_users(book_title varchar(100))
returns INT
deterministic
begin
	declare users_count int;
	select count(distinct r.username) into users_count
	from books as b
	inner join reading r on b.book_id=r.book_id
	where books.book_title=book_title;
	return users_count;
end $$
delimiter;

/* Function3: total no of recommendations for each book title */
delimiter $$
create function recommended_book(book_title varchar(100))
returns INT
deterministic
begin
	declare users_count int;
	select count(distinct r.username) into users_count
	from books as b
	inner join review r on b.book_id=r.book_id
	where books.book_title=book_title
	and r.recommended in ('Y','y');
	return users_count;
end $$
delimiter;


/**************************************************** creating Transactions ********************************************/
/*Total number of Transactions: 2 */

/* Transaction1: when review is written, update no of reviews by 1 in book table*/
delimiter $$
create procedure insert_update_review(review_id int,timestamp Date,  description VARCHAR(10000),
 recommended char(1), rating INT, no_of_likes int, a_username varchar(100),a_book_id varchar(10))
BEGIN
declare exit handler for sqlexception rollback;
start transaction;

-- insert review
insert into review values(review_id,timestamp,description,recommended,rating,no_of_likes, a_username,a_book_id);
-- Update number of reviews in books table
update books
set no_of_reviews = no_of_reviews + 1
where book_id=a_book_id;

commit;
end $$
delimiter; 

/* Transaction2: when someone deletes book then its publisher data also get deleted */
delimiter $$
create procedure delete_books_publisher(a_book_id varchar(100))
BEGIN
declare exit handler for sqlexception rollback;
start transaction;

-- delete book details
delete from books where book_title=a_book_title; 
-- delete publisher's data
delete a from Books_Publisher_name as a inner join books b on a.book_id=b.book_id
 where trunc(lower(b.book_id))=trunc(lower(a_book_id)); 
 
commit;
end $$
delimiter;


/**************************************************** creating Trigger ********************************************/
/*Total number of Trigger: 1 */

/*Trigger1: when someone writes review description of more than 100 characters, it throws message_text */

delimiter $$
create trigger review_desc 
before insert 
on review for each row
begin
if length(new.description)>100 then
signal sqlstate '45000'
set message_text="Max length of review is 100";
end if;
end $$
delimiter

