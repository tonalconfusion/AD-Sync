USE [SYNCAD]
GO
/****** Object:  Table [dbo].[Attrib]    Script Date: 5/03/2018 9:58:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Attrib](
	[MyVer] [nvarchar](50) NULL,
	[CompanyName] [nvarchar](50) NULL,
	[DistinguishedName] [nvarchar](50) NULL,
	[TopOU] [nvarchar](50) NULL,
	[OUProtect] [int] NULL,
	[UPND] [nvarchar](50) NULL,
	[DatabaseLiveName] [nvarchar](50) NULL,
	[DatabaseDevTableName] [nvarchar](50) NULL,
	[UsersOU] [nvarchar](50) NULL,
	[DisabledOU] [nvarchar](50) NULL,
	[ServicesOU] [nvarchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LOG]    Script Date: 5/03/2018 9:58:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LOG](
	[DateTime] [varchar](max) NULL,
	[LogEntry] [varchar](max) NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LOGDev]    Script Date: 5/03/2018 9:58:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LOGDev](
	[DateTime] [varchar](max) NULL,
	[LogEntry] [varchar](max) NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 5/03/2018 9:58:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[Status] [varchar](50) NULL,
	[GivenName] [varchar](max) NULL,
	[Surname] [varchar](max) NULL,
	[samAccountName] [varchar](50) NULL,
	[DisplayName] [varchar](max) NULL,
	[Street] [varchar](max) NULL,
	[State] [varchar](50) NULL,
	[City] [varchar](50) NULL,
	[PostCode] [varchar](50) NULL,
	[Country] [varchar](50) NULL,
	[Manager] [varchar](50) NULL,
	[EmployeeID] [varchar](50) NULL,
	[Company] [varchar](50) NULL,
	[Description] [varchar](50) NULL,
	[Department] [varchar](50) NULL,
	[JTitle] [varchar](50) NULL,
	[Updated] [varchar](50) NULL,
	[ScriptPath] [varchar](50) NULL,
	[Password] [varchar](50) NULL,
	[OfficeNumber] [varchar](50) NULL,
	[MobileNumber] [varchar](50) NULL,
	[Office] [varchar](max) NULL,
	[VPN] [varchar](50) NULL,
	[HomeDrive] [varchar](50) NULL,
	[HomePath] [varchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UsersDev]    Script Date: 5/03/2018 9:58:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UsersDev](
	[Status] [varchar](50) NULL,
	[GivenName] [varchar](max) NULL,
	[Surname] [varchar](max) NULL,
	[samAccountName] [varchar](50) NULL,
	[DisplayName] [varchar](max) NULL,
	[Street] [varchar](max) NULL,
	[State] [varchar](50) NULL,
	[City] [varchar](50) NULL,
	[PostCode] [varchar](50) NULL,
	[Country] [varchar](50) NULL,
	[Manager] [varchar](50) NULL,
	[EmployeeID] [varchar](50) NULL,
	[Company] [varchar](50) NULL,
	[Description] [varchar](50) NULL,
	[Department] [varchar](50) NULL,
	[JTitle] [varchar](50) NULL,
	[Updated] [varchar](50) NULL,
	[ScriptPath] [varchar](50) NULL,
	[Password] [varchar](50) NULL,
	[OfficeNumber] [varchar](50) NULL,
	[MobileNumber] [varchar](50) NULL,
	[Office] [varchar](max) NULL,
	[VPN] [varchar](50) NULL,
	[HomeDrive] [varchar](50) NULL,
	[HomePath] [varchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
