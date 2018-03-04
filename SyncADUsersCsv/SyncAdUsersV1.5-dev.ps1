$myver = "1.5-Dev"
<#
#########################################################
Basic AD Sync Script for Powershell		        
Created by Desmond Kent 				                
Powershell is a powerful tool but i could never find  
a Basic Sync script online where the CSV file was the 
Point of truth. Every script i found Were over 	    
complicated so i set out to just create a Basic Script
							                            
You will need to alter the script to your requirements
Script can be called by creating a simple batch file  
powershell.exe -nologo -executionpolicy bypass -noprofile -file "C:\Scripts\SyncADUsersCsv\SyncAdUsers-CSV.ps1"
There are currently Three States a user account can be in for the Script	    
True:       Meaning that the account is active and in the 	
            Users OU for Blah Domain.				                
False:      which means that the user is disabled but still 
            has a user account. 
Deleted:    Please note that the Account   	
            expiry is set on the account when it is made inactive 
            And Deleted. The script only needs to run once after  
            user account has been set to deleted. Once this has   
            run the account will no longer be picked up by the 	
            script.
					                        
Depending on Auditing within your organisation Leaving
the users disabled might be a requirement for legal requirements.				 	                

V0.0:   Syncing with a CSV file for Basic enable-disable of accts					                        
V1.0:   01/11/2015 Project Start
V1.1.1: 25/11/2015 Minor Changes
V1.2:   04/12/2015 Password Troubleshoot and create RandomPassword
V1.2.2: 8/12/2015 OU Cleanup Added
V1.3:   Add Different Companys in OU Structure
V1.4:   Create missing Default OU's
V1.4.2: 22/01/2016
        Cleaned up code. Added Mobile/Office Number 
        Corrected OU Creation Issue if $CompanyOU Doesn't exist
        Added User Changable OU's
V1.4.8  29/02/2016
        Corrected and issue were the CSV file was being culled of users.
        Added creation of OU's where a Company OU doesn't exist.
        Cleaned up code
        Added in -Dev for Testing a Dev CSV file in your environment Only users in this CSV will be affected.
        Added description for OU Creation and created variable for OU protection.
V1.5    27-02-18
        Added in support for SQL
V1.5.1  28-02-18
        Reading users and writing updated back to SQL database
V1.5.2  01-03-18
        Writing log file into Database
V1.5.3  01-03-18
        Added Reading attributes to SQL Database and Checking for SQL module
        Created SQL creation Scripts
        Removal of File based Log file


Organisational Unit Creations.
Each Base ou will create three Child OU's Under them
Users (Active Users)
Inactive (Disabled Users)
Service (Service Account. Which will only be created if a service user is inserted)
These can be altered by chaging the Default OU Names Variables in the Attrib table.

SQL Setup Create a Database Called ADSYNC. If you don't wish to call it ADSYNC
Change the Variable in the script below called SQLDATABASENAME
you can target a specific SQL database server called SQLDATABASESERVER.
You will also need to update the SQL setup Script that'll be provided with this.
This setup has only been tested on SQL Express 2017.
You will need to install the SQLserver module by running 
install-module SQLServer
You will need to accept all the installation requests.
						                            
			        
If you want my e-mail address then you will know what 
to do with this.					                    
							                            
							                            
100,101,115,109,111,110,100,46,107,101,110,116,64,    
100,107,112,99,114,101,112,97,105,114,115,46,99,111,  
109 | %{Write-host "$([char]$_)" -nonewline}| write-host " " 
#########################################################

#>

import-module sqlserver

$ErrorActionPreference = "SilentlyContinue"
Remove-Variable Today_Date,Log,ScriptStartTime,csvimport,User,SQLDATATABLENAME,CSVExportFile -ErrorAction SilentlyContinue
New-variable -name Today_Date -value (get-date -format dd-MM-yyyy) -Visibility Private
New-variable -name ScriptStartTime -value (get-date) -Visibility Private

#UserSet Variables
$SQLDATABASESERVER = "Stafford"
$SQLDATABASENAME = "ADSYNC"
$UserOuDescription = "Created By Script $Today_Date"
$InactiveOuDescription = "Created By Script $Today_Date"
$ServiceOuDescription = "Created By Script $Today_Date"
$CompanyOuDescription = "Created By Script $Today_Date"


#reading Attributes From DB
$attrib = (read-sqltabledata -serverInstance $SQLDATABASESERVER -databasename $SQLDATABASENAME -schemaname dbo -tablename Attrib) | where MyVer -EQ $myver

#Checking for A Script Version Attribute
if ($attrib.MyVer -ne $myver){write-host "No V$myver attributes in Database.`r`nExiting......." -ForegroundColor Red
Exit}

#Growing the Attributes for the Script from the DB
$CompanyName = $attrib.companyname
$distinguishedName = $attrib.DistinguishedName
$TOPOU =$attrib.TopOU
$UPND = $attrib.UPND
$ouProtect = $attrib.OUProtect
$SQLDATALIVENAME = $attrib.DatabaseLiveName
$SQLDATADevTableName = $attrib.DatabaseDevTableName
$UsersOU = $attrib.UsersOU
$DisabledOU = $attrib.DisabledOU
$ServicesOU = $attrib.ServicesOU

#Building OU Structure naming Convention
$Userou="OU=$UsersOU,"
$Disou="OU=$DisabledOU,"
$Serviceou="OU=$ServicesOU,"


# Checking for Dev / Live DB Details and Logging Accordingly.
if ($myver -like "*Dev*"){
write-host ("--------------------------------------------------------------------------------------------------------") -ForegroundColor Red
write-host ("---------------------------------------Dev Version $myVer -------------------------------------------") -ForegroundColor Red
write-host ("--------------------------------------------------------------------------------------------------------") -ForegroundColor Red

New-variable -name SQLDATATABLENAME -Value  $SQLDATADevTableName -Visibility Private
}
Else {
New-variable -name SQLDATATABLENAME -Value  $SQLDATALIVENAME -Visibility Private
}
New-variable -name User -value " " -Visibility Private

ErrorActionPreference = "Continue"

#Import From SQL and Sort Import
$CSVImport = (read-sqltabledata -serverInstance $SQLDATABASESERVER -databasename $SQLDATABASENAME -schemaname dbo -tablename $SQLDATATABLENAME)
$CSVImport = ($CSVImport | sort company,Status,surname)




#Start Functions ------------------------------------------------------------------------------------

#Function to Write information to the log files
Function Write-Log($Info){

    #Get the Date and Format as String
    $Date = $null
    $Date = Get-Date -Format "d/M/yyyy hh:mm:ss"

        write-host $info
        
        #Write all information to Database Log File.
        $SQLLOGINSERT = ""

        if ($myver -like "*Dev*"){
            $INPUTDATA = New-Object PSObject -Property @{DateTime=$date;Entry=$info}
            Write-SqlTableData -ServerInstance localhost -InputData $INPUTDATA -DatabaseName ADsync -SchemaName dbo -TableName LOGDev
            }
        Else {
            $INPUTDATA = New-Object PSObject -Property @{DateTime=$date;Entry=$info}
            Write-SqlTableData -ServerInstance localhost -InputData $INPUTDATA -DatabaseName ADsync -SchemaName dbo -TableName LOG
            }
       #sleep(.1)              
} #End write-log Function

#--------------------------------------------------------------------------------------------------

function Get-RandomPassword 
 { 
  param( 
        $length = 11, 
        $characters = 'abcdefghkmnprstuvwxyzABCDEFGHKLMNPRSTUVWXYZ123456789!"?$%&/()=?*+#_' 
       ) 
  # select random characters 
  $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
  # output random pwd 
  $private:ofs = "" 
  [String]$characters[$random] 
 }

function Randomize-Text 
 { 
  param( 
        $text 
       ) 
  $anzahl = $text.length -1 
  $indizes = Get-Random -InputObject (0..$anzahl) -Count $anzahl 
  $private:ofs = '' 
  [String]$text[$indizes] 
 }

function Get-ComplexPassword 
 { 
  $password = Get-RandomPassword -length 6 -characters 'abcdefghiklmnprstuvwxyz' 
  $password += Get-RandomPassword -length 2 -characters '#*+)' 
  $password += Get-RandomPassword -length 2 -characters '123456789' 
  $password += Get-RandomPassword -length 4 -characters 'ABCDEFGHKLMNPRSTUVWXYZ' 
  $password = Randomize-Text $password 
    
  $secstr = New-Object -TypeName System.Security.SecureString
  $password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
  
  return $secstr
 }

Function Build-OU($Company,$Status,$Department) {

    $Compiledou = $Null
    $CompanyOU =("OU=" + $company+ "," + $TOPOU + $distinguishedName)

    #Create Users OU
    if ($status -eq "FALSE"){ 
    $Compiledou = ($Disou + $CompanyOU)
    } 
    elseif ($status -eq "True") {
    $Compiledou = ($UserOU + $CompanyOU)
    }
    
    If ($Department -like "*Service*") {
    $Compiledou = ($Serviceou + $CompanyOU)
    }

    Check-ou $Compiledou $Companyou $company

    # Write-host "OU is: $Compiledou" -ForegroundColor Red
    Return $Compiledou
}

Function Check-OU($ou,$CompanyOu,$Company)
{

$AllOus = Get-ADOrganizationalUnit -filter * | Select DistinguishedName

if ($AllOus -like "*$ou*")
{
 #   Write-Host ("OU " +$ou+" exists")
}
else{
 #   Write-Host ("OU " +$ou+" does not exist")
            
            if ($AllOus -notLike "*$CompanyOu*") {
                New-ADOrganizationalUnit -name $Company -path ($TOPOU + $distinguishedName) -ProtectedFromAccidentalDeletion $ouProtect -Description $CompanyOuDescription
                write-Log "$CompanyOu doesn't exist"
                Write-log "Creating $companyou"
                }
            if ($AllOus -notLike ("*$DisOU,"+$CompanyOu + "*")) {
                New-ADOrganizationalUnit -name $DisabledOU -path $CompanyOu -ProtectedFromAccidentalDeletion $ouProtect -Description $InactiveOuDescription
                write-Log "$DisabledOU OU doesn't exist"
                Write-log "Creating Inactive OU in $companyou"
                }
            if ($AllOus -notLike ("*$UsersOU,"+$CompanyOu + "*")) {
                New-ADOrganizationalUnit -name $UsersOU -path $CompanyOu -ProtectedFromAccidentalDeletion $ouProtect -Description $UserOuDescription
                write-Log "$UsersOU OU doesn't exist"
                Write-log "Creating Users OU in $companyou"
                }
            If (($ou -like "*$ServicesOU*") -and ($AllOus -notLike ("*Service,"+$CompanyOu + "*"))){
                New-ADOrganizationalUnit -name $ServicesOU -path $CompanyOu -ProtectedFromAccidentalDeletion $ouProtect -Description $ServiceOuDescription
                write-Log "$ServicesOU OU doesn't exist"
                Write-log "Creating Service OU in $companyou"
                }

# Exit
}
}

#End Functions ------------------------------------------------------------------------------------


write-log ("--------------------------------------------------------------------------------------------------------")
write-log ("Starting Script at: " + $ScriptStartTime)
Write-log ("My Version is : "+ $myVer)
write-log ("Domain Variables are`r`nCompany Name: " + $CompanyName)
Write-log ("DistinguishedName: " + $distinguishedName)
Write-log ("UPND: "  + $upnd)
write-log ("--------------------------------------------------------------------------------------------------------")

write-log "Checking if Users Exist in the Domain:"
#Checking for Each user if they Exist.
#If the Sam Acct Name doesn't exist then create account accordingly.

$CSVImport |
foreach {
$check = $null
$Status = $_.status
$password = $null
$Password = ($_.Password).length



$Check = (Get-Aduser $_.samaccountname -ErrorAction Continue)

    if ($check -eq $null) {
      if($_.Status -notlike "*DELETED*") {
        $Companyname = $null
        $UserStatus = $null
        $userDep = $null
        $Companyname = $_.Company
        $UserStatus = $_.Status
        $userDep = $_.Department
        $baseou = build-ou $Companyname $userStatus $userDep
    
        if ($Password -le 7 ){$_.password = Get-ComplexPassword; Write-log ("Generic Password Created")} 
                if ($_.Status -eq "TRUE"){
                        $UPNTEMP = ($_.SamAccountName + $upnd)
                        
                        New-ADUser -Name $_.DisplayName`
                        -AccountPassword (ConvertTo-SecureString -String $_.Password -AsPlainText -Force) `
                        -DisplayName $_.DisplayName `
                        -GivenName $_.GivenName  `
                        -SurName $_.Surname `
                        -SamAccountName $_.samAccountName `
                        -City ($_.City) `
                        -Country AU -PostalCode ($_.PostCode) `
                        -StreetAddress ($_.Street) `
                        -enabled $True `
                        -path $baseou `
                        -EmployeeID $_.EmployeeID `
                        -EmployeeNumber $_.EmployeeID `
                        -office $_.office `
                        -description $_.description `
                        -department $_.Department `
                        -company $_.Company `
                        -Manager $_.Manager `
                        -state $_.State `
                        -ErrorAction SilentlyContinue
                        


                        set-aduser $_.SamAccountName -userprincipalname $upntemp
                        set-aduser $_.SamAccountName -AccountExpirationDate $null
                        $_.Updated = Get-Date -format dd/MM/yyyy
                        # Write-Host "Create User: " $_.displayname
                        $_.Updated = Get-Date -format dd/MM/yyyy
                        write-log -info ("Creating User: " + $_.SamAccountName)
                        
                        $UPNTEMP = $null
                        
                        If ($_.Company -like "*Service*") {get-aduser -Identity $_.SamAccountName | Move-ADObject -TargetPath $baseou 
                         $_.Updated = Get-Date -format dd/MM/yyyy
}
                   }
                        elseif ($_.Status -eq "FALSE") {
                            $UPNTEMP = ($_.SamAccountName + $upnd)
                            
                            New-ADUser -Name $_.DisplayName `
                            -AccountPassword (ConvertTo-SecureString -String $_.Password -AsPlainText -Force) `
                            -DisplayName $_.DisplayName `
                            -GivenName $_.GivenName `
                            -SamAccountName $_.samAccountName `
                            -City ($_.City) `
                            -Country AU `
                            -PostalCode ($_.PostCode) `
                            -StreetAddress ($_.Street) `
                            -enabled $True `
                            -path $baseou `
                            -EmployeeID $_.EmployeeID `
                            -EmployeeNumber $_.EmployeeID `
                            -office $_.office `
                            -description $_.description `
                            -department $_.Department `
                            -company $_.Company `
                            -Manager $_.Manager `
                            -state $_.State `
                            -ErrorAction SilentlyContinue
                            
                            set-aduser $_.SamAccountName -userprincipalname $upntemp
                            get-aduser -Identity $_.SamAccountName | Move-ADObject -TargetPath $baseou
                            set-aduser $_.SamAccountName -AccountExpirationDate $Today_Date
                            Set-ADUser -identity $_.SamAccountName -enabled $False
                            
                            $UPNTEMP = $null
                            $_.Updated = Get-Date -format dd/MM/yyyy
                            write-log -info ("Creating Disabled User: " + $_.SamAccountName)
                            
                   }
             
           }                
                          

}Else {
      if($_.Status -like "*DELETED*") {
                write-log -info ("Deleting User: " + $_.Displayname + " Employee ID: " +$_.employeeID)
                remove-aduser $_.SamAccountName -confirm:$False
               
       }
       }

}

#syncing other Base Variables
write-log "Checking Other User Variables: "
$CSVImport | Where Status -NotLike "*DELETED*"|

foreach {
    $user = $null
    $user = (get-aduser -Identity $_.SamAccountName -Properties *)
    # $user | ft
    $Companyname = $null
    $UserStatus = $null
    $userDep = $null
    $OfficeNumber = $null
    $MobileNumber =$null
    $Companyname = $_.Company
    $UserStatus = $_.Status
    $userDep = $_.Department
    $OfficeNumber = $_.OfficeNumber
    $MobileNumber = $_.MobileNumber
    $office = $_.Office
    $CN = $
    $baseou = build-ou $Companyname $userStatus $userDep

   #Set Phone Number to $Null if there is Null in the Number Field
    if ($OfficeNumber -like "*Null*") {$OfficeNumber = $null}
    if ($MobileNumber -like "*Null*") {$MobileNumber = $null} 


    if (($user -eq $null))
            {Write-log ("No User Account: " + $_.SamAccountName)
    }else{             
            #Create Manager Variables for #Manager Section.
            $Managertemp = $null
            $Managertemp = (get-aduser $user.Manager).SamAccountName
            
            
            #Users EmployeeID Number
            if ($user.employeeID -ne $_.EmployeeID)
                {
                Set-ADUser -identity $_.SamAccountName `
                -EmployeeID $_.employeeID `
                -EmployeeNumber $_.employeeID
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set Employee ID for: " + $_.SamAccountName)
                }
            #Users Description
            if ($user.Description -ne $_.Description)
                {
                Set-ADUser -identity $_.SamAccountName `
                -Description $_.description
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set Description for: " + $_.SamAccountName)
                }

            #Checking Users Principal Domain Name
            $UPNTEMP = ($_.SamAccountName + $upnd)
            if ($user.UserPrincipalName -ne $UPNTEMP)
                {
                Set-ADUser -identity $_.SamAccountName `
                -UserPrincipalName $UPNTEMP
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set UPN for: " + $_.SamAccountName)
                $UPNTEMP = $null
                }

            #city
            if ($user.city -ne $_.city)
                {
                Set-ADUser -identity $_.SamAccountName `
                -city $_.City
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set City for: " + $_.SamAccountName)
                }

            #login Script
            if ($user.ScriptPath -ne $_.ScriptPath)
                {
                Set-ADUser -identity $_.SamAccountName `
                -ScriptPath $_.ScriptPath
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set ScriptPath for: " + $_.SamAccountName)
                }


            #state
            if ($user.st -ne $_.state)
                {
                Set-ADUser -identity $_.SamAccountName `
                -state $_.state
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set state for: " + $_.SamAccountName)
                }

            
            # Street
            if ($user.streetAddress -ne $_.Street)
                {
                Set-ADUser -identity $_.SamAccountName `
                -StreetAddress $_.street
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set Street for: " + $_.SamAccountName)
                }

            #department
            if ($user.Department -ne $_.Department)
                {
                Set-ADUser -identity $_.SamAccountName `
                -Department $_.Department
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set Department for: " + $_.SamAccountName)
                }

            #DisplayName
            if ($user.DisplayName -ne $_.DisplayName)
                {
                Set-ADUser -identity $_.SamAccountName `
                -DisplayName $_.DisplayName
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set Display Name for: " + $_.SamAccountName)
                }
           
            #Cronical Name
            #if ($user.CN -ne $_.DisplayName)
            #    {
            #    Set-ADUser -identity $_.SamAccountName `
            #    -cn $_.DisplayName
            #    $_.Updated = Get-Date -format dd/MM/yyyy
            #    write-log -info ("Set Display Name for: " + $_.SamAccountName)
            #    }

            #Company Information    
            if ($user.Company -ne $_.Company)
                {
                Set-ADUser -identity $_.SamAccountName `
                -Company $_.Company
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set Company for: " + $_.SamAccountName)
                }

            #mobile Number
            if ($user.Mobile -ne $MobileNumber)
                {
                Set-ADUser -identity $_.SamAccountName `
                -MobilePhone $MobileNumber
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set Mobile Phone Number for: " + $_.SamAccountName + " To: " + $MobileNumber)
                }

            #Office Number    
            if ($user.OfficePhone -ne $OfficeNumber)
                {
                Set-ADUser -identity $_.SamAccountName `
                -OfficePhone $OfficeNumber
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set Office Phone Number for: " + $_.SamAccountName + " To:" + $OfficeNumber)
               }

            
            #Office Location Update    
            if ($user.Office -ne $Office)
                {
                #If Office Location Exists in DB Set Office Location
                 If ($office.length -gt 2){
                    Set-ADUser -identity $_.SamAccountName `
                    -Office $Office
                    $_.Updated = Get-Date -format dd/MM/yyyy
                    write-log -info ("Set Office Location for: " + $_.SamAccountName + " To:" + $Office)
                                            }
                }
                
            #Managers Details
            if ($managertemp -ne $_.Manager)
                {
                Set-ADUser -identity $_.SamAccountName `
                -Manager $_.Manager
                $_.Updated = Get-Date -format dd/MM/yyyy
                write-log -info ("Set Manager for: " + $_.SamAccountName + " to: " + $_.manager +  " From: " + $Managertemp) 
                }


            if (($_.Status -eq "TRUE") -and ($user.Enabled -eq $false))
                {
                Set-ADUser -identity $_.SamAccountName `
                -enabled $True
                
                write-log -info ("Enabling Account for: " + $_.SamAccountName)
                
                set-aduser $_.SamAccountName `
                -AccountExpirationDate $null
                $_.Updated = Get-Date -format dd/MM/yyyy
                get-aduser -Identity $_.SamAccountName | Move-ADObject -TargetPath $baseou
                }


            if (($_.Status -eq "FALSE") -and ($user.Enabled -eq $True))
                {
                write-log -info ("Disabling Account for: " + $_.SamAccountName)
                get-aduser -Identity $_.SamAccountName | Move-ADObject -TargetPath $baseou
                
                Set-ADUser -identity $_.SamAccountName `
                -enabled $False
                
                set-aduser $_.SamAccountName `
                -AccountExpirationDate $Today_Date
                $_.Updated = Get-Date -format dd/MM/yyyy
                }

      
#cleanup OU   
#------------------------------------------------------------------------------------------------------------------- 
            If ($_.Department -like "*Service*") 
                {
                 if ($user.DistinguishedName -notlike "*$baseou*")
                        {
                        $from = $user.DistinguishedName
                        write-log -info ("Moving user: " + $_.SamAccountName + " From:" + $from + " To: " + $baseou)
                        get-aduser -Identity $_.SamAccountName | Move-ADObject -TargetPath $baseou
                        $_.Updated = Get-Date -format dd/MM/yyyy
                        set-aduser -Identity $_.SamAccountName `
                        -Organization $baseou
                        
                        }
                }

          
            if (($_.Status -eq "TRUE") -and ($_.Department -notlike "*Service*"))
                {
                
                 if ($user.DistinguishedName -notlike "*$baseou*")
                        {
                        $from = $user.DistinguishedName
                        write-log -info ("Moving user: " + $_.SamAccountName + " From:" + $from + " To: " + $baseou)
                        get-aduser -Identity $_.SamAccountName | Move-ADObject -TargetPath $baseou
                        $_.Updated = Get-Date -format dd/MM/yyyy
                        set-aduser -Identity $_.SamAccountName `
                        -Organization $baseou
                        }
                }


            if ($_.Status -eq "FALSE")
                {
                 if ($user.DistinguishedName -notlike "*$baseou*")
                        {
                        $from = $user.DistinguishedName
                        write-log -info ("Moving user: " + $_.SamAccountName + " From:" + $from + " To: " + $baseou)
                        get-aduser -Identity $_.SamAccountName | Move-ADObject -TargetPath $baseou
                        $_.Updated = Get-Date -format dd/MM/yyyy
                        set-aduser -Identity $_.SamAccountName `
                        -Organization $baseou
                        
                        }
                }

#------------------------------------------------------------------------------------------------------------------- 
                
$_.Password = $null
} #end Check user
}



write-log -info "Writing Data back to SQL Database"
ForEach ($entry in $CSVImport)
    {        
        
        
        $updatedate = $entry.Updated
        $updateSamAcctName = $entry.samAccountName
        $UpdateDateQuery = "UPDATE       $SQLDATATABLENAME","SET                Updated = '$updatedate',Password = '$passwordoutput',jtitle = 'NULL'","WHERE        (samAccountName = '$updateSamAcctName')"
        invoke-sqlcmd -ServerInstance $SQLDATABASESERVER -Query "$UpdateDateQuery" -Database $SQLDATABASENAME 

    }

$ScriptEndTime=(GET-DATE)
write-log -info ("Finalising Script at: " + $ScriptEndTime)
Write-Log -info ("Finishing Syncing...") 
Write-Log -info ("Minutes: "+ ($ScriptEndTime - $ScriptStartTime).Minutes +" Seconds: " + ($ScriptEndTime - $ScriptStartTime).Seconds + "`r`n`r`n")



$CSVImport = ""
$entry = ""


$ErrorActionPreference = "Continue"
Remove-Variable Today_Date,Log,ScriptStartTime,csvimport,User,SQLDATATABLENAME,CSVExportFile -ErrorAction SilentlyContinue
