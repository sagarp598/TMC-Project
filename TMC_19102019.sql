USE [TMC]
GO
ALTER TABLE [dbo].[users] DROP CONSTRAINT [DF_users_isVIP]
GO
ALTER TABLE [dbo].[users] DROP CONSTRAINT [DF_users_isAdmin]
GO
ALTER TABLE [dbo].[bookingdetails] DROP CONSTRAINT [DF_bookingdetails_active]
GO
/****** Object:  Table [dbo].[users]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP TABLE [dbo].[users]
GO
/****** Object:  Table [dbo].[bookingdetails]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP TABLE [dbo].[bookingdetails]
GO
/****** Object:  Table [dbo].[activitymaster]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP TABLE [dbo].[activitymaster]
GO
/****** Object:  StoredProcedure [dbo].[sp_viewrequeststatus]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_viewrequeststatus]
GO
/****** Object:  StoredProcedure [dbo].[sp_validateUser]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_validateUser]
GO
/****** Object:  StoredProcedure [dbo].[sp_updatereqstatus]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_updatereqstatus]
GO
/****** Object:  StoredProcedure [dbo].[sp_updateLastLogin]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_updateLastLogin]
GO
/****** Object:  StoredProcedure [dbo].[sp_isUsernameAvailable]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_isUsernameAvailable]
GO
/****** Object:  StoredProcedure [dbo].[sp_getcategory]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_getcategory]
GO
/****** Object:  StoredProcedure [dbo].[sp_getbookingstatus]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_getbookingstatus]
GO
/****** Object:  StoredProcedure [dbo].[sp_getallvip]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_getallvip]
GO
/****** Object:  StoredProcedure [dbo].[sp_getallrequests]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_getallrequests]
GO
/****** Object:  StoredProcedure [dbo].[sp_getactivitymaster]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_getactivitymaster]
GO
/****** Object:  StoredProcedure [dbo].[sp_getactivityid]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_getactivityid]
GO
/****** Object:  StoredProcedure [dbo].[sp_getactivity]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_getactivity]
GO
/****** Object:  StoredProcedure [dbo].[sp_createUser]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_createUser]
GO
/****** Object:  StoredProcedure [dbo].[sp_createbooking]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_createbooking]
GO
/****** Object:  StoredProcedure [dbo].[sp_chkavailabilitystatus]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_chkavailabilitystatus]
GO
/****** Object:  StoredProcedure [dbo].[sp_cancelbooking]    Script Date: 10/19/2019 7:42:03 PM ******/
DROP PROCEDURE [dbo].[sp_cancelbooking]
GO
/****** Object:  StoredProcedure [dbo].[sp_cancelbooking]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_cancelbooking]
@bookingid int,@flag int out
as
begin 

set @flag = 1

Update dbo.bookingdetails  
Set Active = 0
where booking_id = @bookingid

set @flag = 0




end;
GO
/****** Object:  StoredProcedure [dbo].[sp_chkavailabilitystatus]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_chkavailabilitystatus]
@activityname varchar(50),
@categoryname varchar(50),
@bookingdate varchar(20)
as
begin

Select am.activityname,am.categoryname,am.timeslot,coalesce(bd.bookingdate,' ') as bookingdate,
abs(coalesce(am.quantityno,0) - coalesce(bd.quantityno,0)) as quantityno,
Case when abs(coalesce(am.quantityno,0) - coalesce(bd.quantityno,0)) = 0 then 'BOOKED' ELSE 'AVAILABLE' end as BookingStatus,
' ' as bookingcreateddate
from dbo.activitymaster am
Left join 
		(Select activity_id,bookingdate,sum(quantityno)  as quantityno
		from dbo.bookingdetails 
		where active = 1 and bookingdate = cast(@bookingdate as date) and bookingstatus = 'Approved'
		Group by activity_id,bookingdate) bd   
		on bd.activity_id = am.activity_id 
where am.activityname = @activityname and am.categoryname = @categoryname 
and am.availableforday in (DATENAME(WEEKDAY, cast(@bookingdate as date)),'ALL')


end
;


GO
/****** Object:  StoredProcedure [dbo].[sp_createbooking]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_createbooking]
@user_id int,
@activity_id int,
@quantityno int,
@bookingdate varchar(50),
@bookingstatus varchar(50),
@bookingupdatedby varchar(50),
@flag int out
AS
Begin

set @flag = 1;
insert into dbo.bookingdetails 
([user_id],
activity_id,
quantityno,
bookingdate,
bookingstatus,
bookingupdatedby,
bookingcreateddate
)
values
( 
@user_id,
@activity_id,
@quantityno,
cast (@bookingdate as date),
@bookingstatus,
@bookingupdatedby,
GETDATE()
)

set @flag = 0;
return @flag;
End

GO
/****** Object:  StoredProcedure [dbo].[sp_createUser]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_createUser] 
@username	varchar(50)	,
@password	varchar(50)	,
@salutation	varchar(20)	,
@fname	varchar(50)	,
@lname	varchar(50)	,
@institutionname varchar(100),
@contactpersonname varchar(50),
@custtype varchar(50),
@emailid	varchar(50)	,
@contactno	varchar(50)	,
@mobileno	varchar(50)	,
@address	varchar(50)	,
@city	varchar(50)	,
@pincode	int	,
@isAdmin	bit	,
@isVIP	bit	,
@designation varchar(50),
@flag int output
as
begin


if @isVIP = 0 
Begin
insert into dbo.users 
(username	,[password]	,lastlogindate	,usercreationdate	,salutation	,fname	,lname	,
institutionname,contactpersonname,custtype ,emailid	,contactno	,mobileno	,[address]	,
city	,pincode)
values
(@username	,@password	,GETDATE(),GETDATE(),@salutation	,@fname	,
@lname	,@institutionname,@contactpersonname,@custtype,@emailid	,@contactno	,@mobileno	,
@address	,@city	,@pincode	)

End
Else 
Begin
insert into dbo.users 
(username	,[password]	,lastlogindate	,usercreationdate	,salutation	,fname	,lname	,
institutionname,contactpersonname,custtype ,emailid	,contactno	,mobileno	,[address]	,
city	,pincode	,isAdmin	,isVIP	,designation)
values
(@username	,@password	,GETDATE()	,GETDATE(),@salutation	,@fname	,
@lname	,@institutionname,@contactpersonname,@custtype,@emailid	,@contactno	,@mobileno	,
@address	,@city	,@pincode	,@isAdmin	,@isVIP	,@designation)
End

set @flag = 0

return @flag
end


GO
/****** Object:  StoredProcedure [dbo].[sp_getactivity]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_getactivity] (@dayname varchar(50))
as
Begin

Select distinct activityname from dbo.activitymaster where availableforday in ('ALL',@dayName);


End;
GO
/****** Object:  StoredProcedure [dbo].[sp_getactivityid]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_getactivityid] (
@activityname varchar(50),
@categoryname varchar(50),
@timeslot varchar(50),
@dayname varchar(50),
@activityid int out)
as
Begin

Select @activityid = Activity_id from 
dbo.activitymaster 
where activityname = @activityname and
categoryname = @categoryname and
timeslot = @timeslot and
availableforday in (@dayname,'ALL');

return @activityid;



End;
GO
/****** Object:  StoredProcedure [dbo].[sp_getactivitymaster]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_getactivitymaster] 
@dayname varchar(50)
as
begin

if (@dayname = 'ALL')
begin
	select 
	activity_id,
	activityname,
	categoryname,
	timeslot,
	quantityno,
	availableforday
	From dbo.activitymaster;
end
else
begin
	select 
	activity_id,
	activityname,
	categoryname,
	timeslot,
	quantityno,
	availableforday
	From dbo.activitymaster Where availableforday = @dayname;
end


end;
GO
/****** Object:  StoredProcedure [dbo].[sp_getallrequests]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_getallrequests]
as
begin

Select bd.booking_id, case when u.custtype = 'Institution' 
	   then u.institutionname + ' : ' + u.contactpersonname 
	   else u.salutation+'. '+ u.fname+' '+u.lname end as requester,
u.emailid,u.mobileno,u.contactno,
am.activityname,am.categoryname,am.timeslot,bd.bookingdate,bd.quantityno,bd.bookingstatus,
bd.bookingcreateddate,bd.remarks
from dbo.bookingdetails bd 
inner join dbo.activitymaster am on bd.activity_id = am.activity_id
inner join dbo.users u on u.userid = bd.[user_id]
where active = 1;

end;


GO
/****** Object:  StoredProcedure [dbo].[sp_getallvip]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_getallvip]
as
begin

select salutation+'. '+fname + ' '+lname as name,userid
from dbo.users where isVIP = 1

end;
GO
/****** Object:  StoredProcedure [dbo].[sp_getbookingstatus]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_getbookingstatus]
@userid int
as
declare @isadmin bit
begin

Select @isadmin = isAdmin from dbo.users where [userid] = @userid; 

if (@isadmin = 0 )
begin
Select am.activityname,am.categoryname,am.timeslot,bd.bookingdate,bd.quantityno,bd.bookingstatus,
bd.bookingcreateddate
from dbo.bookingdetails bd 
inner join dbo.activitymaster am on bd.activity_id = am.activity_id
where active = 1 and [user_id] = @userid
end
else
begin

Select case when u.custtype = 'Institution' 
	   then u.institutionname + ' : ' + u.contactpersonname 
	   else u.salutation+'. '+ u.fname+' '+u.lname end as requester,
u.emailid,u.mobileno,u.contactno,
am.activityname,am.categoryname,am.timeslot,bd.bookingdate,bd.quantityno,bd.bookingstatus,
bd.bookingcreateddate
from dbo.bookingdetails bd 
inner join dbo.activitymaster am on bd.activity_id = am.activity_id
inner join dbo.users u on u.userid = bd.[user_id]
where active = 1
end

end;
GO
/****** Object:  StoredProcedure [dbo].[sp_getcategory]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_getcategory] (@activtyname varchar(100),@dayname varchar(50))
as
Begin

Select distinct categoryname from dbo.activitymaster 
where activityname = @activtyname AND
availableforday in ('ALL', @dayname)
;


End;
GO
/****** Object:  StoredProcedure [dbo].[sp_isUsernameAvailable]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_isUsernameAvailable] 
@username	varchar(50)	,
@flag int output
as

begin
select @flag = count(1) from dbo.users where username = @username
return @flag --output = 0 means username is valid and <> 0 means username is not valid
end
GO
/****** Object:  StoredProcedure [dbo].[sp_updateLastLogin]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_updateLastLogin] 
@username	varchar(50)	,
@flag int output
as

begin

begin try
update dbo.users
set lastlogindate = GETDATE()
where username = @username;
commit;
set @flag = 0 
end try
begin catch
set @flag = 1
end catch

return @flag --output = 0 means username is valid and <> 0 means username is not valid
end
GO
/****** Object:  StoredProcedure [dbo].[sp_updatereqstatus]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_updatereqstatus]
@decision varchar(50),
@updatedby int,
@remarks varchar(4000),
@bookingid int,
@flag int out
as
begin

set @flag = 1;
Update dbo.bookingdetails
set bookingstatus = @decision,
remarks = @remarks,
bookingupdatedby = @updatedby
Where booking_id = @bookingid;
set @flag = 0;




end;


GO
/****** Object:  StoredProcedure [dbo].[sp_validateUser]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_validateUser] 
@username varchar(50),
@password varchar(50),
@flag int output,
@userid int output,
@isadmin bit output
as
declare 
@isAvailable int,
@validate	int
begin
select @isAvailable = COUNT(1) from dbo.users a where a.username =@username;
select @validate = COUNT(1) from dbo.users a where a.username =@username and a.password = @password;
select @userid = a.userid,@isadmin = a.isAdmin from dbo.users a where a.username =@username and a.password = @password;
if @isAvailable=0 
begin
	 set @flag = 0; --user not available
end
	else 
		begin 
			if @validate = 0
				set @flag = 1; --user not validated. wrong password
			else 
				set @flag = 2;
			
		end 


return @flag
end
GO
/****** Object:  StoredProcedure [dbo].[sp_viewrequeststatus]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_viewrequeststatus]
@userid int
as
begin

Select bd.booking_id, am.activityname,am.categoryname,am.timeslot,coalesce(bd.bookingdate,' ') as bookingdate,
bd.quantityno as quantityno,
bookingstatus as BookingStatus,
bookingcreateddate as bookingcreateddate,
remarks 
from  dbo.bookingdetails bd 
inner join dbo.activitymaster am on bd.activity_id = am.activity_id
where active = 1 and user_id = @userid
		


end
;
GO
/****** Object:  Table [dbo].[activitymaster]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[activitymaster](
	[activity_id] [int] IDENTITY(1,1) NOT NULL,
	[activityname] [varchar](50) NULL,
	[categoryname] [varchar](50) NULL,
	[timeslot] [varchar](100) NULL,
	[quantityno] [int] NULL,
	[availableforday] [varchar](50) NULL,
 CONSTRAINT [PK_activitymaster] PRIMARY KEY CLUSTERED 
(
	[activity_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[bookingdetails]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[bookingdetails](
	[booking_id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NOT NULL,
	[activity_id] [int] NOT NULL,
	[quantityno] [int] NULL,
	[bookingdate] [date] NULL,
	[bookingstatus] [varchar](50) NULL,
	[bookingupdatedby] [varchar](50) NULL,
	[bookingcreateddate] [date] NULL,
	[active] [bit] NOT NULL,
	[remarks] [varchar](4000) NULL,
 CONSTRAINT [PK_bookingdetails] PRIMARY KEY CLUSTERED 
(
	[booking_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[users]    Script Date: 10/19/2019 7:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[users](
	[userid] [int] IDENTITY(1,1) NOT NULL,
	[username] [varchar](50) NULL,
	[password] [varchar](50) NULL,
	[lastlogindate] [datetime] NULL,
	[usercreationdate] [datetime] NULL,
	[salutation] [varchar](20) NULL,
	[fname] [varchar](50) NULL,
	[lname] [varchar](50) NULL,
	[institutionname] [varchar](100) NULL,
	[contactpersonname] [varchar](50) NULL,
	[custtype] [varchar](50) NULL,
	[emailid] [varchar](50) NULL,
	[contactno] [varchar](50) NULL,
	[mobileno] [varchar](50) NULL,
	[address] [varchar](50) NULL,
	[city] [varchar](50) NULL,
	[pincode] [int] NULL,
	[isAdmin] [bit] NULL,
	[isVIP] [bit] NULL,
	[designation] [varchar](50) NULL,
 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED 
(
	[userid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
SET IDENTITY_INSERT [dbo].[activitymaster] ON 

INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (5, N'Cricket', N'Ground', N'9:00 AM to 4:00 PM', 1, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (6, N'Cricket', N'Changing room', N'9:00 AM to 4:00 PM', 1, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (7, N'Cricket', N'Outside Gallery', N'9:00 AM to 4:00 PM', 1, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (8, N'Cricket', N'VIP room', N'9:00 AM to 4:00 PM', 1, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (9, N'Cricket', N'VIP Gallery', N'9:00 AM to 4:00 PM', 1, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (10, N'Cricket', N'Cricket Net Practice', N'6:30 to 8:30 AM', 1, N'Tuesday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (11, N'Cricket', N'Cricket Net Practice', N'4:30 to 6:30 PM', 1, N'Tuesday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (12, N'Cricket', N'Cricket Net Practice', N'6:30 to 8:30 AM', 1, N'Wednesday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (13, N'Cricket', N'Cricket Net Practice', N'4:30 to 6:30 PM', 1, N'Wednesday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (14, N'Cricket', N'Cricket Net Practice', N'6:30 to 8:30 AM', 1, N'Thursday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (15, N'Cricket', N'Cricket Net Practice', N'4:30 to 6:30 PM', 1, N'Thursday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (16, N'Cricket', N'Cricket Net Practice', N'6:30 to 8:30 AM', 1, N'Friday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (17, N'Cricket', N'Cricket Net Practice', N'4:30 to 6:30 PM', 1, N'Friday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (18, N'Cricket', N'Cricket Net Practice', N'6:30 to 8:30 AM', 1, N'Saturday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (19, N'Cricket', N'Cricket Net Practice', N'4:30 to 6:30 PM', 1, N'Saturday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (20, N'Cricket', N'Cricket Net Practice', N'6:30 to 8:30 AM', 1, N'Sunday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (21, N'Cricket', N'Cricket Net Practice', N'4:30 to 6:30 PM', 1, N'Sunday')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (22, N'Open Varanda', N'Open Varanda', N'4 Hours', 1, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (25, N'Table Tennis', N'Table Tennis', N'9:00 AM to 4:00 PM', 8, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (26, N'Badminton', N'Badminton', N'10:00 AM to 4:00 PM', 5, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (27, N'Squash', N'Squash', N'10:00 AM to 4:00 PM', 1, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (28, N'Skating', N'Skating', N'10:00 AM to 4:00 PM', 1, N'ALL')
INSERT [dbo].[activitymaster] ([activity_id], [activityname], [categoryname], [timeslot], [quantityno], [availableforday]) VALUES (29, N'Canteen', N'Canteen', N'6:00 PM to 10:00 PM', 1, N'ALL')
SET IDENTITY_INSERT [dbo].[activitymaster] OFF
SET IDENTITY_INSERT [dbo].[bookingdetails] ON 

INSERT [dbo].[bookingdetails] ([booking_id], [user_id], [activity_id], [quantityno], [bookingdate], [bookingstatus], [bookingupdatedby], [bookingcreateddate], [active], [remarks]) VALUES (1, 1, 12, 1, CAST(0x5F400B00 AS Date), N'Rejected', N'2', CAST(0x40400B00 AS Date), 1, N'Request Rejected. Not Available')
INSERT [dbo].[bookingdetails] ([booking_id], [user_id], [activity_id], [quantityno], [bookingdate], [bookingstatus], [bookingupdatedby], [bookingcreateddate], [active], [remarks]) VALUES (2, 3, 7, 1, CAST(0x41400B00 AS Date), N'Approved', N'3', CAST(0x40400B00 AS Date), 1, NULL)
INSERT [dbo].[bookingdetails] ([booking_id], [user_id], [activity_id], [quantityno], [bookingdate], [bookingstatus], [bookingupdatedby], [bookingcreateddate], [active], [remarks]) VALUES (1002, 1, 26, 5, CAST(0x66400B00 AS Date), N'Approved', N'2', CAST(0x46400B00 AS Date), 1, N'Request has been approved.')
SET IDENTITY_INSERT [dbo].[bookingdetails] OFF
SET IDENTITY_INSERT [dbo].[users] ON 

INSERT [dbo].[users] ([userid], [username], [password], [lastlogindate], [usercreationdate], [salutation], [fname], [lname], [institutionname], [contactpersonname], [custtype], [emailid], [contactno], [mobileno], [address], [city], [pincode], [isAdmin], [isVIP], [designation]) VALUES (1, N'test_user', N'abc123', NULL, NULL, N'Mr', N'Sagar', N'Patole', NULL, NULL, N'Individual', N'sagar.p.patole@gmail.com', N'022-25168540', N'9619163347', N'Ghatkopar', N'Mumbai', 400084, 0, 0, N'Registered User')
INSERT [dbo].[users] ([userid], [username], [password], [lastlogindate], [usercreationdate], [salutation], [fname], [lname], [institutionname], [contactpersonname], [custtype], [emailid], [contactno], [mobileno], [address], [city], [pincode], [isAdmin], [isVIP], [designation]) VALUES (2, N'test_admin', N'admin123', NULL, NULL, NULL, NULL, NULL, N'TMC', NULL, N'Insititution', N'admin@tmc.com', N'022-68995698', NULL, N'Thane', N'Thane', 400606, 1, 0, N'Admin User')
INSERT [dbo].[users] ([userid], [username], [password], [lastlogindate], [usercreationdate], [salutation], [fname], [lname], [institutionname], [contactpersonname], [custtype], [emailid], [contactno], [mobileno], [address], [city], [pincode], [isAdmin], [isVIP], [designation]) VALUES (3, N'VIP-Pratap Sarnaik', N' ', CAST(0x0000AAE500DC5040 AS DateTime), CAST(0x0000AAE500DC5040 AS DateTime), N'Mr', N'Pratap', N'Sarnaik', N' ', N' ', N' ', N' ', N'9648256987', N'256487921', N'Vartak Nagar', N' ', 0, 0, 1, N'Aamdar')
SET IDENTITY_INSERT [dbo].[users] OFF
ALTER TABLE [dbo].[bookingdetails] ADD  CONSTRAINT [DF_bookingdetails_active]  DEFAULT ((1)) FOR [active]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_isAdmin]  DEFAULT ((0)) FOR [isAdmin]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_isVIP]  DEFAULT ((0)) FOR [isVIP]
GO
