-- CS4400: Introduction to Database Systems: Monday, March 3, 2025
-- Simple Airline Management System Course Project Mechanics [TEMPLATE] (v0)
-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'flight_tracking';
use flight_tracking;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [_] supporting functions, views and stored procedures
-- -----------------------------------------------------------------------------
/* Helpful library capabilities to simplify the implementation of the required
views and procedures. */
-- -----------------------------------------------------------------------------
drop function if exists leg_time;
delimiter //
create function leg_time (ip_distance integer, ip_speed integer)
	returns time reads sql data
begin
	declare total_time decimal(10,2);
    declare hours, minutes integer default 0;
    set total_time = ip_distance / ip_speed;
    set hours = truncate(total_time, 0);
    set minutes = truncate((total_time - hours) * 60, 0);
    return maketime(hours, minutes, 0);
end //
delimiter ;

-- [1] add_airplane()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airplane.  A new airplane must be sponsored
by an existing airline, and must have a unique tail number for that airline.
username.  An airplane must also have a non-zero seat capacity and speed. An airplane
might also have other factors depending on it's type, like the model and the engine.  
Finally, an airplane must have a new and database-wide unique location
since it will be used to carry passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airplane;
delimiter //
create procedure add_airplane (in ip_airlineID varchar(50), in ip_tail_num varchar(50),
	in ip_seat_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
    in ip_plane_type varchar(100), in ip_maintenanced boolean, in ip_model varchar(50),
    in ip_neo boolean)
sp_main: begin
	declare insert_maintenanced tinyint(1) default NULL;
    declare insert_neo tinyint(1) default NULL;
    if ip_airlineID is null or ip_tail_num is null or
    ip_seat_capacity is null or ip_speed is null or ip_locationID is null then
		leave sp_main;
	end if;
	-- Check airline if exist
    if ip_airlineID not in (select airlineID from airline) then
		leave sp_main; # airline doesn't exist
	end if;
    -- check unique tail number for that airline
    if ip_tail_num in (select tail_num from airplane where airlineID = ip_airlineID) then
		leave sp_main; # tail number already exist
	end if;
    -- Check speed and seat capacity
    if ip_seat_capacity <= 0 then
		leave sp_main; # seat capacity error
	end if;
    if ip_speed <= 0 then
		leave sp_main; # speed capacity error
	end if;
    -- Ensure that the location values are new and unique
    if ip_locationID in (select locationID from location) then
		leave sp_main; # location not new / unique
	end if;
	-- Ensure that the plane type is valid: Boeing, Airbus, or neither
    -- Ensure that the type-specific attributes are accurate for the type
    if ip_plane_type like 'Boeing' then
		if ip_maintenanced is NULL then
			leave sp_main; # Boeing without maintenanced attribute
		end if;
        if ip_model is NULL then
			leave sp_main; # Boeing without model
		end if;
        if ip_maintenanced is True then
			set insert_maintenanced = 1;
		else
			set insert_maintenanced = 0;
		end if;
	end if;
	if ip_plane_type like 'Airbus' then
		if ip_neo is NULL then
			leave sp_main; # Airbus without neo
		end if;
        if ip_neo is True then
			set insert_neo = 1;
		else
			set insert_neo = 0;
		end if;
    end if;
    if ip_plane_type not like 'Boeing' and ip_plane_type not like 'Airbus' then
		leave sp_main;
	end if;
    -- Add airplane and location into respective tables
    insert into location (locationID) values (ip_locationID);
    insert into airplane (airlineID, tail_num, seat_capacity, speed, locationID, plane_type, maintenanced, model, neo) values
    (ip_airlineID, ip_tail_num, ip_seat_capacity, ip_speed, ip_locationID, ip_plane_type, insert_maintenanced, ip_model, insert_neo);
end //
delimiter ;

-- [2] add_airport()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airport.  A new airport must have a unique
identifier along with a new and database-wide unique location if it will be used
to support airplane takeoffs and landings.  An airport may have a longer, more
descriptive name.  An airport must also have a city, state, and country designation. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airport;
delimiter //
create procedure add_airport (in ip_airportID char(3), in ip_airport_name varchar(200),
    in ip_city varchar(100), in ip_state varchar(100), in ip_country char(3), in ip_locationID varchar(50))
sp_main: begin
	-- Ensure that the airport and location values are new and unique
    if ip_airportID is null or ip_locationID is null then
		leave sp_main;
	end if;
    if ip_locationID in (select locationId from location) then
		leave sp_main; # location not new / unique
    end if;
    if ip_airportID in (select airportID from airport) then
		leave sp_main; # airportID not new / unique
	end if;
    if length(ip_airportID) <> 3 or length(ip_country) <> 3 then
		leave sp_main; # airportID or countryID not exactly 3 letters
	end if;
    if ip_city is null or ip_state is null or ip_country is null then
		leave sp_main; # city, state, country is null
	end if;
    -- Add airport and location into respective tables
	insert into location (locationID) values (ip_locationID);
    insert into airport (airportID, airport_name, city, state, country, locationID) values
    (ip_airportID, ip_airport_name, ip_city, ip_state, ip_country, ip_locationID);
end //
delimiter ;

-- [3] add_person()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new person.  A new person must reference a unique
identifier along with a database-wide unique location used to determine where the
person is currently located: either at an airport, or on an airplane, at any given
time.  A person must have a first name, and might also have a last name.

A person can hold a pilot role or a passenger role (exclusively).  As a pilot,
a person must have a tax identifier to receive pay, and an experience level.  As a
passenger, a person will have some amount of frequent flyer miles, along with a
certain amount of funds needed to purchase tickets for flights. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_person;
delimiter //
create procedure add_person (in ip_personID varchar(50), in ip_first_name varchar(100),
    in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
    in ip_experience integer, in ip_miles integer, in ip_funds integer)
sp_main: begin
	-- Ensure they have first name
    if ip_first_name is null then
		leave sp_main; # no first name
	end if;
	-- Ensure that the location is valid
    if ip_locationID not in (select locationID from location) then
		leave sp_main; # location not valid
	end if;
    -- Ensure that the persion ID is unique
    if ip_personID in (select personID from person) then
		leave sp_main; # person ID not valid
	end if;
    -- Ensure that the person is a pilot or passenger
    -- Add them to the person table as well as the table of their respective role
    -- case pilot
    if ip_taxID is not null and ip_experience is not null then
		insert into person (personID, first_name, last_name, locationID) values
        (ip_personID, ip_first_name, ip_last_name, ip_locationID);
		insert into pilot (personID, taxID, experience, commanding_flight) values
        (ip_personID, ip_taxID, ip_experience, null);
        leave sp_main; # done inserting pilot
    end if;
    -- case passenger
    if ip_miles is not null and ip_funds is not null then
		insert into person (personID, first_name, last_name, locationID) values
        (ip_personID, ip_first_name, ip_last_name, ip_locationID);
        insert into passenger (personID, miles, funds) values
        (ip_personID, ip_miles, ip_funds);
		leave sp_main; # done inserting passenger
    end if;
end //
delimiter ;

-- [4] grant_or_revoke_pilot_license()
-- -----------------------------------------------------------------------------
/* This stored procedure inverts the status of a pilot license.  If the license
doesn't exist, it must be created; and, if it aready exists, then it must be removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists grant_or_revoke_pilot_license;
delimiter //
create procedure grant_or_revoke_pilot_license (in ip_personID varchar(50), in ip_license varchar(100))
sp_main: begin
	-- Ensure that the person is a valid pilot
    if ip_personID not in (select personID from pilot) then
		leave sp_main; # not valid pilot
	end if;
    -- If license exists, delete it, otherwise add the license
    if exists (select 1 from pilot_licenses where personID = ip_personID and license = ip_license) then
		delete from pilot_licenses where personID = ip_personID and license = ip_license;
    else
		insert into pilot_licenses (personID, license) values
        (ip_personID, ip_license);
    end if;
end //
delimiter ;

-- [5] offer_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new flight.  The flight can be defined before
an airplane has been assigned for support, but it must have a valid route.  And
the airplane, if designated, must not be in use by another flight.  The flight
can be started at any valid location along the route except for the final stop,
and it will begin on the ground.  You must also include when the flight will
takeoff along with its cost. */
-- -----------------------------------------------------------------------------
drop procedure if exists offer_flight;
delimiter //
create procedure offer_flight (in ip_flightID varchar(50), in ip_routeID varchar(50),
    in ip_support_airline varchar(50), in ip_support_tail varchar(50), in ip_progress integer,
    in ip_next_time time, in ip_cost integer)
sp_main: begin
	-- Ensure flightID new and unique
    if ip_flightID in (select flightID from flight) then
		leave sp_main; # flight already exist
	end if;
    -- Ensure that the route exists
    if ip_routeID not in (select routeID from route) then
		leave sp_main; # route doesn't exist
	end if;
    -- airplane assigned exists
    if not exists
    (select 1 from airplane where ip_support_airline = airlineID
    and ip_support_tail = tail_num) then
		leave sp_main; # airplane assigned doesn't exist
	end if;
    -- airplane assigned not in use (if assigned)
    if exists 
    (select 1 from flight where support_airline = ip_support_airline
    and support_tail = ip_support_tail) then
		leave sp_main; # airplane assigned already in use
	end if;
    -- route starting point (any valid location except final stop)
    -- Ensure that the progress is less than the length of the route
    if ip_progress >= (select max(sequence) from route_path where routeID = ip_routeID) or ip_progress < 0 then
		leave sp_main; # starting point invalid
	end if;
    -- check next time and cost
    if ip_next_time is null or ip_cost is null or ip_cost < 0 then
		leave sp_main; # next time or cost invalid
	end if;
    -- Create the flight with the airplane starting in on the ground
	insert into flight (flightID, routeID, support_airline, support_tail, progress, airplane_status, next_time, cost) values
    (ip_flightID, ip_routeID, ip_support_airline, ip_support_tail, ip_progress, 'on_ground', ip_next_time, ip_cost);
end //
delimiter ;

-- [6] flight_landing()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight landing at the next airport
along it's route.  The time for the flight should be moved one hour into the future
to allow for the flight to be checked, refueled, restocked, etc. for the next leg
of travel.  Also, the pilots of the flight should receive increased experience, and
the passengers should have their frequent flyer miles updated. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_landing;
delimiter //
create procedure flight_landing (in ip_flightID varchar(50))
sp_main: begin
	declare add_miles int;
    declare this_airline varchar(50);
    declare this_tail varchar(50);
	-- Ensure that the flight exists
    if ip_flightID not in (select flightID from flight) then
		leave sp_main; # flight doesn't exist
	end if;
    -- Ensure that the flight is in the air
    if (select airplane_status from flight where flightID = ip_flightID) = 'on_ground' then
		leave sp_main; # flight not in_flight
	end if;
    -- Increment the pilot's experience by 1
    update pilot set experience = experience + 1 where commanding_flight = ip_flightID;
    -- Increment the frequent flyer miles of all passengers on the plane
    select distance into add_miles from leg where legID = 
    (select legID from route_path where sequence = 
    (select progress from flight where flightID = ip_flightID)
    and routeID =
    (select routeID from flight where flightID = ip_flightID));
    select support_airline, support_tail into this_airline, this_tail from flight where flightID = ip_flightID;
    update passenger set miles = miles + add_miles where
    personID in (select personID from person where locationID = 
    (select locationID from airplane where airlineID = this_airline and tail_num = this_tail));
    -- Update the status of the flight and increment the next time to 1 hour later
		-- Hint: use addtime()
	update flight set next_time = addtime(next_time, '01:00:00'), airplane_status = 'on_ground'
    where flightID = ip_flightID;
end //
delimiter ;

-- [7] flight_takeoff()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight taking off from its current
airport towards the next airport along it's route.  The time for the next leg of
the flight must be calculated based on the distance and the speed of the airplane.
And we must also ensure that Airbus and general planes have at least one pilot
assigned, while Boeing must have a minimum of two pilots. If the flight cannot take
off because of a pilot shortage, then the flight must be delayed for 30 minutes. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_takeoff;
delimiter //
create procedure flight_takeoff (in ip_flightID varchar(50))
sp_main: begin
	declare plane_model varchar(50);
    declare pilot_assigned int;
    declare flight_time time;
	-- Ensure that the flight exists
    if ip_flightID not in (select distinct flightID from flight) then
		leave sp_main; -- flight doesn't exist
	end if;
    -- Ensure that the flight is on the ground
    if (select airplane_status from flight where flightID = ip_flightID) = 'in_flight' then
		leave sp_main; -- flight already in_flight
	end if;
    -- Ensure that the flight has another leg to fly
    if (select progress from flight where flightID = ip_flightID) = 
    (select max(r.sequence) from route_path r left join flight f on r.routeID = f.routeID where f.flightID = ip_flightID group by r.routeID)
    then
		leave sp_main; -- no more progress to complete
	end if;
    -- Ensure that there are enough pilots (1 for Airbus and general, 2 for Boeing)
		-- If there are not enough, move next time to 30 minutes later
    select a.plane_type into plane_model from flight f 
    left join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
    where f.flightID = ip_flightID;
    select count(p.personID) into pilot_assigned from pilot p where p.commanding_flight = ip_flightID;
	if plane_model like 'Boeing' then
		if pilot_assigned < 2 then
			update flight set next_time = addtime(next_time, '00:30:00') where flightID = ip_flightID;
            leave sp_main; -- not enough pilots
		end if;
	else
		if pilot_assigned < 1 then
			update flight set next_time = addtime(next_time, '00:30:00') where flightID = ip_flightID;
            leave sp_main; -- not enough pilots
		end if;
    end if;
    -- Calculate the flight time using the speed of airplane and distance of leg
    -- Update the next time using the flight time
	select sec_to_time(ceil((l.distance / a.speed) * 3600)) into flight_time from flight f
    join route_path r on f.routeID = r.routeID and f.progress + 1 = r.sequence
    join leg l on r.legID = l.legID
    join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
    where f.flightID = ip_flightID;
    
    update flight set next_time = addtime(next_time, flight_time) where flightID = ip_flightID;
    -- Increment the progress and set the status to in flight
    update flight set progress = progress + 1, airplane_status = 'in_flight' where flightID = ip_flightID;
end //
delimiter ;

-- [8] passengers_board()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting on a flight at
its current airport.  The passengers must be at the same airport as the flight,
and the flight must be heading towards that passenger's desired destination.
Also, each passenger must have enough funds to cover the flight.  Finally, there
must be enough seats to accommodate all boarding passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_board;
delimiter //
create procedure passengers_board (in ip_flightID varchar(50))
sp_main: begin
	declare cur_location varchar(50);
    declare next_dest varchar(3);
    declare passenger_count int;
    declare ticket_cost int;
	-- Ensure the flight exists
    if ip_flightID not in (select flightID from flight) then
		leave sp_main;
	end if;
    -- Ensure that the flight is on the ground
    if (select airplane_status from flight where flightID = ip_flightID) = 'in_flight' then
		leave sp_main;
	end if;
    -- Ensure that the flight has further legs to be flown
    if (select progress from flight where flightID = ip_flightID) = 
    (select max(r.sequence) from route_path r 
    left join flight f on r.routeID = f.routeID 
    where f.flightID = ip_flightID group by r.routeID)
    then
		leave sp_main; -- no more progress to complete
	end if;
    
    -- Determine the number of passengers attempting to board the flight
    -- Use the following to check:
		-- The airport the airplane is currently located at
        -- The passengers are located at that airport
        -- The passenger's immediate next destination matches that of the flight
        -- The passenger has enough funds to afford the flight
	select apt.locationID, l.arrival into cur_location, next_dest
    from flight f join route_path r on f.routeID = r.routeID and f.progress + 1 = r.sequence
    join leg l on r.legID = l.legID
    join airport apt on l.departure = apt.airportID
    where f.flightID = ip_flightID;
	
    select cost into ticket_cost from flight where flightID = ip_flightID;
    
    DROP TEMPORARY TABLE IF EXISTS eligible_passengers;
    create temporary table if not exists eligible_passengers (
		personID varchar(50) PRIMARY KEY
	);
	
    insert ignore into eligible_passengers (personID)
    select distinct v.personID
    from passenger_vacations v
    join person p on v.personID = p.personID
    join passenger f on v.personID = f.personID
    where v.airportID = next_dest and v.sequence = 1 and
    v.personID in (select personID from person where locationID = cur_location) and
    f.funds >= ticket_cost; 
    
    select count(*) into passenger_count from eligible_passengers;
    
	-- Check if there enough seats for all the passengers
		-- If not, do not add board any passengers
        -- If there are, board them and deduct their funds
	if (select a.seat_capacity from airplane a 
    join flight f on f.support_airline = a.airlineID and f.support_tail = a.tail_num
    where f.flightID = ip_flightID) < passenger_count then
		leave sp_main; -- not enough seat
	end if;
    
    update person set locationID = 
    (select locationID from airplane a
    join flight f on a.airlineID = f.support_airline and a.tail_num = f.support_tail
    where f.flightID = ip_flightID) where personID in 
    (select personID from eligible_passengers);
    
    update passenger set funds = funds - ticket_cost where personID in 
    (select personID from eligible_passengers);
end //
delimiter ;

-- [9] passengers_disembark()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting off of a flight
at its current airport.  The passengers must be on that flight, and the flight must
be located at the destination airport as referenced by the ticket. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_disembark;
delimiter //
create procedure passengers_disembark (in ip_flightID varchar(50))
sp_main: begin
	declare airport_id varchar(50);
	declare airport_location varchar(50);
    declare flight_location varchar(50);
	-- Ensure the flight exists & Ensure that the flight is on ground
    if ip_flightID not in (select flightID from flight where airplane_status = 'on_ground') then
		leave sp_main;
	end if;
    
    select l.arrival, a.locationID, apt.locationID into airport_id, flight_location, airport_location
    from flight f
    join airplane a on f.support_tail = a.tail_num and f.support_airline = a.airlineID
    join route_path r on f.routeID = r.routeID and f.progress = r.sequence
    join leg l on r.legID = l.legID
    join airport apt on apt.airportID = l.arrival
    where f.flightID = ip_flightID;
    -- Determine the list of passengers who are disembarking
	-- Use the following to check:
		-- Passengers must be on the plane supporting the flight
        -- Passenger has reached their immediate next destionation airport
	DROP TEMPORARY TABLE IF EXISTS eligible_passengers;
	create temporary table if not exists eligible_passengers (
		personID varchar(50) PRIMARY KEY
	);
    insert ignore into eligible_passengers (personID)
    select distinct v.personID 
    from passenger_vacations v
    join person p on v.personID = p.personID
    where p.locationID = flight_location and
    v.sequence = 1 and v.airportID = airport_id;
    
	-- Move the appropriate passengers to the airport
    -- Update the vacation plans of the passengers
    update person set locationID = airport_location 
    where personID in (select personID from eligible_passengers);
    
	delete from passenger_vacations where personID in (select personID from eligible_passengers)
    and sequence = 1;
    update passenger_vacations set sequence = sequence - 1
    where personID in (select personID from eligible_passengers);
end //
delimiter ;

-- [10] assign_pilot()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a pilot as part of the flight crew for a given
flight.  The pilot being assigned must have a license for that type of airplane,
and must be at the same location as the flight.  Also, a pilot can only support
one flight (i.e. one airplane) at a time.  The pilot must be assigned to the flight
and have their location updated for the appropriate airplane. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_pilot;
delimiter //
create procedure assign_pilot (in ip_flightID varchar(50), ip_personID varchar(50))
sp_main: begin
	declare flight_type varchar(50);
    declare flight_location varchar(50);
	-- Ensure the flight exists & Ensure that the flight is on ground
    if ip_flightID not in (select flightID from flight where airplane_status = 'on_ground') then
		leave sp_main;
	end if;
    -- Ensure that the flight has further legs to be flown
    if (select progress from flight where flightID = ip_flightID) = 
    (select max(r.sequence) from route_path r 
    left join flight f on r.routeID = f.routeID 
    where f.flightID = ip_flightID group by r.routeID)
    then
		leave sp_main; -- no more progress to complete
	end if;
    
    -- Ensure that the pilot exists and is not already assigned
    if ip_personID not in (select personID from pilot) then
		leave sp_main;
	end if;
    if (select commanding_flight from pilot where personID = ip_personID) is not null then
		leave sp_main;
	end if;
	-- Ensure that the pilot has the appropriate license
    select ifnull(a.plane_type, 'general') into flight_type
    from airplane a join flight f
    on a.airlineID = f.support_airline and a.tail_num = f.support_tail
    where f.flightID = ip_flightID;
    
    if flight_type not in (select license from pilot_licenses where personID = ip_personID) then
		leave sp_main;
	end if;
    -- Ensure the pilot is located at the airport of the plane that is supporting the flight
    select a.locationID into flight_location
    from flight f
    join route_path r on f.routeID = r.routeID and f.progress + 1 = r.sequence
    join leg l on r.legID = l.legID
    join airport a on l.departure = a.airportID
    where f.flightID = ip_flightID;
    
    if (select locationID from person where personID = ip_personID) != flight_location then
		leave sp_main;
	end if;
    -- Assign the pilot to the flight and update their location to be on the plane
    update pilot set commanding_flight = ip_flightID where personID = ip_personID;
    update person set locationID = 
    (select a.locationID from airplane a join flight f on
    a.airlineID = f.support_airline and a.tail_num = f.support_tail
    where f.flightID = ip_flightID) where personID = ip_personID;

end //
delimiter ;

-- [11] recycle_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure releases the assignments for a given flight crew.  The
flight must have ended, and all passengers must have disembarked. */
-- -----------------------------------------------------------------------------
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew (in ip_flightID varchar(50))
sp_main: begin
	declare flight_location varchar(50);
    declare airport_location varchar(50);
    -- Ensure the flight exists & Ensure that the flight is on ground
    if ip_flightID not in (select flightID from flight where airplane_status = 'on_ground') then
		leave sp_main;
	end if;
    -- Ensure that the flight has no more legs to be flown
    if (select progress from flight where flightID = ip_flightID) != 
    (select max(r.sequence) from route_path r 
    left join flight f on r.routeID = f.routeID 
    where f.flightID = ip_flightID group by r.routeID)
    then
		leave sp_main; -- more progress to complete
	end if;
    
    -- Ensure that the flight is empty of passengers
    select a.locationID into flight_location
    from airplane a join flight f
    on a.airlineID = f.support_airline and a.tail_num = f.support_tail
    where f.flightID = ip_flightID;
    
    if exists 
    (select * from passenger ps left join person p on 
    ps.personID = p.personID where p.locationID = flight_location) then
		leave sp_main;
	end if;
    
    -- Update assignements of all pilots
    update pilot set commanding_flight = null where commanding_flight = ip_flightID;
    -- Move all pilots to the airport the plane of the flight is located at
    select a.locationID into airport_location
    from flight f
    join route_path r on f.routeID = r.routeID
    join leg l on r.legID = l.legID
    join airport a on a.airportID = l.arrival
    where f.progress = r.sequence
    and f.flightID = ip_flightID;
	
    update person set locationID = airport_location where locationID = flight_location;
end //
delimiter ;

-- [12] retire_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a flight that has ended from the system.  The
flight must be on the ground, and either be at the start its route, or at the
end of its route.  And the flight must be empty - no pilots or passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists retire_flight;
delimiter //
create procedure retire_flight (in ip_flightID varchar(50))
sp_main: begin
	declare flight_location varchar(50);
	-- Ensure the flight exists & Ensure that the flight is on ground
    if ip_flightID not in (select flightID from flight where airplane_status = 'on_ground') then
		leave sp_main;
	end if;
    -- Ensure that the flight has no more legs to be flown
    -- or on the start of the progress
    if (select progress from flight where flightID = ip_flightID) != 
    (select max(r.sequence) from route_path r 
    left join flight f on r.routeID = f.routeID 
    where f.flightID = ip_flightID group by r.routeID)
    and 
    (select progress from flight where flightID = ip_flightID) != 0
    then
		leave sp_main; -- not on start or end
	end if;
    
    -- Ensure that there are no more people on the plane supporting the flight
    select a.locationID into flight_location
    from airplane a join flight f on
    a.airlineID = f.support_airline and a.tail_num = f.support_tail
    where f.flightID = ip_flightID;
    
    if exists (select * from person where locationID = flight_location) then
		leave sp_main;
	end if;
    -- Remove the flight from the system
	delete from flight where flightID = ip_flightID;
end //
delimiter ;

-- [13] simulation_cycle()
-- -----------------------------------------------------------------------------
/* This stored procedure executes the next step in the simulation cycle.  The flight
with the smallest next time in chronological order must be identified and selected.
If multiple flights have the same time, then flights that are landing should be
preferred over flights that are taking off.  Similarly, flights with the lowest
identifier in alphabetical order should also be preferred.

If an airplane is in flight and waiting to land, then the flight should be allowed
to land, passengers allowed to disembark, and the time advanced by one hour until
the next takeoff to allow for preparations.

If an airplane is on the ground and waiting to takeoff, then the passengers should
be allowed to board, and the time should be advanced to represent when the airplane
will land at its next location based on the leg distance and airplane speed.

If an airplane is on the ground and has reached the end of its route, then the
flight crew should be recycled to allow rest, and the flight itself should be
retired from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists simulation_cycle;
delimiter //
create procedure simulation_cycle ()
sp_main: begin
	declare ip_flightID varchar(50);
    -- check if there is still any flights
    if not exists (select flightID from flight) then
		leave sp_main;
	end if;
    -- Identify the next flight to be processed
    select flightID into ip_flightID
    from flight
	order by next_time asc, 
	field(airplane_status, 'in_flight', 'on_ground'),
	flightID asc limit 1;
	
    -- If the flight is in the air:
		-- Land the flight and disembark passengers
	if (select airplane_status from flight where flightID = ip_flightID) = 'in_flight' then
		call flight_landing(ip_flightID);
        call passengers_disembark(ip_flightID);
	-- If the flight is on the ground:
		-- Board passengers and have the plane takeoff
        -- If it has reached the end:
			-- Recycle crew and retire flight
	else
		if (select progress from flight where flightID = ip_flightID) < 
        (select max(sequence) from route_path 
        where routeID = (select routeID from flight where flightID = ip_flightID)) then
			call passengers_board(ip_flightID);
            call flight_takeoff(ip_flightID);
		else
			call recycle_crew(ip_flightID);
            call retire_flight(ip_flightID);
		end if;
    end if;
end //
delimiter ;
-- select * from flight;
-- call simulation_cycle();

-- [14] flights_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently airborne are located. 
We need to display what airports these flights are departing from, what airports 
they are arriving at, the number of flights that are flying between the 
departure and arrival airport, the list of those flights (ordered by their 
flight IDs), the earliest and latest arrival times for the destinations and the 
list of planes (by their respective flight IDs) flying these flights. */
-- -----------------------------------------------------------------------------
create or replace view flights_in_the_air (departing_from, arriving_at, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as

select l.departure, l.arrival, count(distinct f.flightID), 
group_concat(distinct f.flightID order by f.flightID separator ','),
min(f.next_time), max(f.next_time), 
group_concat(distinct a.locationID order by f.flightID separator ',')
from flight f left join route_path r on f.progress = r.sequence and f.routeID = r.routeID 
join leg l on r.legID = l.legID 
join airplane a on a.tail_num = f.support_tail and a.airlineID = f.support_airline
where f.airplane_status = 'in_flight'
group by l.departure, l.arrival;

-- [15] flights_on_the_ground()
-- ------------------------------------------------------------------------------
/* This view describes where flights that are currently on the ground are 
located. We need to display what airports these flights are departing from, how 
many flights are departing from each airport, the list of flights departing from 
each airport (ordered by their flight IDs), the earliest and latest arrival time 
amongst all of these flights at each airport, and the list of planes (by their 
respective flight IDs) that are departing from each airport.*/
-- ------------------------------------------------------------------------------
create or replace view flights_on_the_ground (departing_from, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as 

(select l.departure, count(distinct f.flightID),
group_concat(distinct f.flightID order by f.flightID separator ','),
min(f.next_time), max(f.next_time),
group_concat(distinct a.locationID order by f.flightID separator ',')
from flight f 
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
join route_path r on f.routeID = r.routeID and r.sequence = 1
join leg l on r.legID = l.legID
where f.airplane_status = 'on_ground' and f.progress = 0
group by l.departure)

UNION

(select l.arrival, count(distinct f.flightID),
group_concat(distinct f.flightID order by f.flightID separator ','),
min(f.next_time), max(f.next_time),
group_concat(distinct a.locationID order by f.flightID separator ',')
from flight f 
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
join route_path r on f.routeID = r.routeID and f.progress = r.sequence
join leg l on r.legID = l.legID
where f.airplane_status = 'on_ground' and f.progress > 0
group by l.arrival);

-- [16] people_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently airborne are located. We 
need to display what airports these people are departing from, what airports 
they are arriving at, the list of planes (by the location id) flying these 
people, the list of flights these people are on (by flight ID), the earliest 
and latest arrival times of these people, the number of these people that are 
pilots, the number of these people that are passengers, the total number of 
people on the airplane, and the list of these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view people_in_the_air (departing_from, arriving_at, num_airplanes,
	airplane_list, flight_list, earliest_arrival, latest_arrival, num_pilots,
	num_passengers, joint_pilots_passengers, person_list) as

select l.departure, l.arrival, count(distinct f.flightID),
group_concat(distinct a.locationID order by a.locationID separator ','),
group_concat(distinct f.flightID order by f.flightID separator ','),
min(f.next_time), max(f.next_time), 
sum(case when exists (select 1 from pilot pt where pt.personID = p.personID) then 1 else 0 end),
sum(case when exists (select 1 from passenger pa where pa.personID = p.personID) then 1 else 0 end),
count(p.personID),
group_concat(p.personID order by p.personID separator ',')
from person p
join airplane a on p.locationID = a.locationID
join flight f on a.airlineID = f.support_airline and a.tail_num = f.support_tail
join route_path r on f.routeID = r.routeID and f.progress = r.sequence
join leg l on r.legID = l.legID
where f.airplane_status = 'in_flight'
group by l.departure, l.arrival;

-- [17] people_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently on the ground and in an 
airport are located. We need to display what airports these people are departing 
from by airport id, location id, and airport name, the city and state of these 
airports, the number of these people that are pilots, the number of these people 
that are passengers, the total number people at the airport, and the list of 
these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view people_on_the_ground (departing_from, airport, airport_name,
	city, state, country, num_pilots, num_passengers, joint_pilots_passengers, person_list) as
    
select apt.airportID, p.locationID, apt.airport_name, apt.city, apt.state, apt.country,
sum(case when exists (select 1 from pilot pt where p.personID = pt.personID) then 1 else 0 end),
sum(case when exists (select 1 from passenger ps where p.personID = ps.personID) then 1 else 0 end),
count(p.personID),
group_concat(p.personID order by p.personID separator ',')
from person p
join airport apt on p.locationID = apt.locationID
group by apt.airportID;

-- [18] route_summary()
-- -----------------------------------------------------------------------------
/* This view will give a summary of every route. This will include the routeID, 
the number of legs per route, the legs of the route in sequence, the total 
distance of the route, the number of flights on this route, the flightIDs of 
those flights by flight ID, and the sequence of airports visited by the route. */
-- -----------------------------------------------------------------------------
create or replace view route_summary (route, num_legs, leg_sequence, route_length,
	num_flights, flight_list, airport_sequence) as
    
select r.routeID, count(distinct l.legID),
group_concat(distinct r.legID order by r.sequence separator ','),
sum(l.distance) div (count(*) div count(distinct l.legID)),
count(distinct f.flightID),
group_concat(distinct f.flightID order by f.flightID separator ','),
group_concat(distinct concat(l.departure, '->', l.arrival) order by r.sequence separator ',')
from route_path r
join leg l on r.legID = l.legID
left join flight f on r.routeID = f.routeID
group by r.routeID;

-- [19] alternative_airports()
-- -----------------------------------------------------------------------------
/* This view displays airports that share the same city and state. It should 
specify the city, state, the number of airports shared, and the lists of the 
airport codes and airport names that are shared both by airport ID. */
-- -----------------------------------------------------------------------------
create or replace view alternative_airports (city, state, country, num_airports,
	airport_code_list, airport_name_list) as

select city, state, country, count(airportID),
group_concat(airportID order by airportID separator ','),
group_concat(airport_name order by airportID separator ',')
from airport group by city, state, country having count(airportID) > 1;