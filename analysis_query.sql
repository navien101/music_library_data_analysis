select * from invoice_line;
--1 senior most emplpoyee based on the job title
select * from employee;

select * from employee order by levels desc limit 1;

--2 which country has the most invoices
select * from invoice;

select billing_country as country_name,  (count(*)) as num_of_invoices 
from invoice  
group by billing_country 
order by (count(*)) desc limit 1; 

--3 what are top values of total invoices
select * from invoice;

select total from invoice order by total desc limit 3; 

/*4 which city has the best customers. we would like to throw a music festival in the  city we mad the most money
write a query to return one city that has the highest sum of invoices totals. return both the city name and sum of invoice totals */

select * from invoice;

select billing_city as city_name, sum(total)as invoice_total from invoice group by billing_city order by invoice_total desc limit 1 ;  

/*5 who is the best customer ? the customer who has spent the most money will be declared the best customer. write a query that returns
who has spent the most money. */
select * from customer;

select  a.first_name || ' ' || a.last_name as customer_name, sum(total) as total_money  from customer as a join invoice as b
on a.customer_id = b. customer_id group by a.customer_id order by sum(total) desc limit 1;

--6 write a query to return the email, first_name , last_name , & genre of all rock music listeners order by ascending emails
select * from track;
select * from genre;
select * from customer;

select  distinct a.email , a.first_name, a.last_name  from customer as a
join (select b.customer_id , c.invoice_id, c.track_id, c.genre_id, c.name from invoice as b 
	  join (select c.invoice_Id, c.track_Id, d.genre_Id, d.name from invoice_line as c 
			join (select d.track_id, e.genre_id, e.name from track as d 
				  	join genre as e on d.genre_id  = e.genre_id) 
				as d on c.track_Id = d.track_id) 
	  	as c on b.invoice_id = c.invoice_id) as f
on a.customer_id = f.customer_id
where f.name = 'Rock'
group by a.customer_id, f.genre_id,f.name 
order by a.email;

--7 alternate way to do the same question
select distinct email, first_name , last_name
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
join track on track.track_id = invoice_line.track_id
join genre on genre.genre_id = track.genre_id
where genre.name = 'Rock' 
order by email;
		
		
/*8 let's invite the artists who have written the most rock music in our dataset. write a query that returns the artist name and total 
tack count of the top 10 rock band */
select * from artist;

select distinct artist.name, count(*) as number_of_songs from artist 
join album on album.artist_id = artist.artist_id
join track on album.album_id = track.album_id
join genre on track.genre_id = genre.genre_id
where genre.name = 'Rock'
group by artist.artist_id
order by number_of_songs desc 
limit 10;

/*9 return all the tracks names that have a song length longer than the average song lenght. return the name and milliseconds for 
each track. order by the song length with the longest songs lsited first. */

select * from track ;

select name, milliseconds from track where milliseconds > (
select avg(milliseconds) from track)
order by milliseconds desc;


--10  find how much amount spent by each customer on artists? write a query to return customer_name, artist_name and total spent(unit price X quantity)

with best_selling_artist as (
		select artist.artist_id as artist_id, artist.name as artist_name,
		sum((invoice_line.unit_price * invoice_line.quantity)) as total_spent
		from invoice_line
		join track on invoice_line.track_id = track.track_id
		join album on album.album_id = track.album_id
		join artist on artist.artist_id = album.artist_id
		group by 1
		order by 3 desc
		limit 1
		)
select c.customer_id, c.first_name, c.last_name, bsa.artist_name,
sum(il.unit_price*il.quantity) as money_spent
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album alb on alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = alb.artist_id
group by 1,2,3,4
order by 5 desc;

/*11 we want to find out the most popular music genre for each country. we determine the most popular genre as genre with the highest amount of 
purchases. write a query that returns each country along with the top genre. for countries where the maximum number of  purchases is shared 
return all genre*/

with popular_genre as 
(
	select count(invoice_line.quantity) as purchases, customer.country,genre.name , genre.genre_id,
	row_number() over(partition by customer.country order by count(invoice_line.quantity) desc)
	from invoice_line
	join invoice on invoice.invoice_id = invoice_line.invoice_id
	join customer on customer.customer_id = invoice.customer_id
	join track on track.track_id = invoice_line.track_id
	join genre on genre.genre_id = track.genre_id
	group by 2,3,4
	order by 2 asc, 1 desc
)
select  * from popular_genre where Row_Number <= 1;


--alternate method 

with recursive
		purchases as (
		select count(*) as purchase, customer.country, genre.name, genre.genre_id
		from invoice_line
		join invoice on invoice.invoice_id = invoice_line.invoice_id
		join customer on customer.customer_id = invoice.customer_id
		join track on track.track_id = invoice_line.track_id
		join genre on genre.genre_id = track.genre_id
		group by 2,3,4
		order by  2
		),
		popular_genre_country as (select max(purchase) as purchase_max , country
								 from purchases
								 group by 2
								 order by 2)
								 
select purchases.* from purchases 
join popular_genre_country on purchases.country = popular_genre_country.country
where purchases.purchase = popular_genre_country.purchase_max
order by purchases.purchase;


/* 12 write a query that detemines the customer that has spent most money for each country. write a query that returns the country along with 
the top customer and how much they spent. for country where the top amount is shared, provide all the customers who spent this amount. */

select * from customer;
select * from invoice_line;

with recursive 
		customer_spends as(
		select c.customer_id, c.first_name, c.last_name, c.country, sum(il.unit_price*il.quantity) as money_spent
		from customer as c
		join invoice i on i.customer_id = c.customer_id 
		join invoice_line il on il.invoice_id = i.invoice_id
		group by c.customer_id
		order by c.country, money_spent desc
		),
		max_spent_country as(
			select country, max(money_spent) as money_spendings
			from customer_spends
			group by 1
			order by 2 desc)
select distinct customer_spends.* 
from customer_spends  
inner join max_spent_country 
on (customer_spends.money_spent = max_spent_country.money_spendings and
	customer_spends.country = max_spent_country.country)
order by customer_spends.country, money_spent desc
