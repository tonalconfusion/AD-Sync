﻿         

         $userStatus = read-host("Enter Status of Account True: Active and False: Disabled")
         $userGivenName = Read-Host("Enter the Users Given Name")
         $userSurname = Read-Host("Enter the users Surname")
         $usersamAccountName = Read-Host("Enter the Users LoginName")
         $userDisplayName = Read-Host("Enter the Users displayname")
         $userStreet = Read-Host("Enter the users Street Address")
         $userState = Read-Host("Enter the users State")
         $userCity = Read-Host("Enter The users City")
         $userPostCode = Read-Host("Enter the users Post Code")
         $userCountry = Read-Host("Enter the users Country")
         $userManager = Read-Host("Enter the Users Managers samaccountname")
         $userEmployeeID = Read-Host("Enter the Users Employee ID")
         $userCompany = Read-Host("Enter The users Company")
         $userDescription = Read-Host("Enter the Users Description")
         $userDepartment = Read-Host("Enter the Users Department")
         $userScriptPath = Read-Host("Enter the users Login Script Null.bat if non required")
         $userPassword = Read-Host("Enter a Password. Radom Generated if none entered")
         $userOfficeNumber = Read-Host("Enter Office Number enter `$null for No Number")
         $userMobileNumber = Read-host ("Enter Mobile Number enter `$null for No Number")
         $userOfficeLocation = read-host("Enter Office Location")
  