$myVer = "1.4.8"
<#
#########################################################
Basic AD-CSV Sync Script for Powershell		        
Created by Desmond Kent 				                
Powershell is a powerful tool but i could never find  
a Basic Sync script online where the CSV file was the 
Point of truth. Every script i found Were over 	    
complicated so i set out to just create a Basic Script
							                            
You will need to alter the script to your requirements
Script can be called by creating a simple batch file  
powershell.exe -nologo -executionpolicy bypass -noprofile -file "C:\Scripts\SyncADUsersCsv\SyncAdUsers-CSV.ps1"
There are currently Three Status for the Script	    
True Meaning that the account is active and in the 	
Users OU for Blah Domain.				                
False which means that the user is disabled but still 
has a user account. Please note that the Account   	
expiry is set on the account when it is made inactive 
And Deleted. The script only needs to run once after  
user account has been set to deleted. Once this has   
run the account will no longer be picked up by the 	
script.						                        
Depending on Auditing within your organisation Leaving
the users details within the Excel document might be  
a legal requirement.				 	                
V 1 Syncs with a CSV file which is the primary point  
of Truth						                        
V1.0: 01/11/2015 Project Start
V1.1.1: 25/11/2015 Minor Changes
V1.2: 04/12/2015 Password Troubleshoot and create RandomPassword
V1.2.2: 8/12/2015 OU Cleanup Added
V1.3: Add Different Companys in OU Structure
V1.4: Create missing Default OU's
V1.4.2: 22/01/2016
        Cleaned up code. Added Mobile/Office Number 
        Corrected OU Creation Issue if $CompanyOU Doesn't exist
        Added User Changable OU's
V1.4.8 29/02/2016
        Corrected and issue were the CSV file was being culled of users.
        Added creation of OU's where a Company OU doesn't exist.
        Cleaned up code
        Added in -Dev for Testing a Dev CSV file in your environment Only users in this CSV will be affected.
        Added description for OU Creation and created variable for OU protection.

Organisational Unit Creations.
Each Base ou will create three Child OU's Under them
Users (Active Users)
Inactive (Disabled Users)
Service (Service Account. Which will only be created if a service user is inserted)
These can be altered by chaging the Default OU Names Variables
						                            
Future releases will sync with SQL. 			        
If you want my e-mail address then you will know what 
to do with this.					                    
							                            
							                            
100,101,115,109,111,110,100,46,107,101,110,116,64,    
100,107,112,99,114,101,112,97,105,114,115,46,99,111,  
109 | %{Write-host "$([char]$_)" -nonewline}| write-host " " 
#########################################################

#>

$ErrorActionPreference = "SilentlyContinue"
Remove-Variable Today_Date,Log,ScriptStartTime,csvimport,User,CSVfile,CSVExportFile -ErrorAction SilentlyContinue
New-variable -name Today_Date -value (get-date -format dd-MM-yyyy) -Visibility Private
New-variable -name ScriptStartTime -value (get-date) -Visibility Private

if ($myver -like "*Dev*"){
write-host ("--------------------------------------------------------------------------------------------------------") -ForegroundColor Red
write-host ("---------------------------------------Dev Version $myVer ---------------------------------------") -ForegroundColor Red
write-host ("--------------------------------------------------------------------------------------------------------") -ForegroundColor Red
sleep(1)
New-variable -name CSVFile -Value  "\\contoso\scripts\SyncADUsersCsv\Users-dev.csv" -Visibility Private
}
Else {
New-variable -name CSVFile -Value  "\\contoso\scripts\SyncADUsersCsv\Users.csv" -Visibility Private
}
New-variable -name CSVExportFile -Value  "\\contoso\scripts\SyncADUsersCsv\Users-Export.csv" -Visibility Private
New-variable -name CSVImport -Value  (import-csv $CSVFile | sort SamAccountName)  -Visibility Private
New-variable -name User -value " " -Visibility Private
New-variable -name Log  -value "\\contoso\scripts\logs\AdSync-Log-$Today_Date-V$myVer.txt" -Visibility Private
$CompanyName = "contoso"
$distinguishedName = "DC=contoso,DC=homeip,DC=net"
$UPND = "@contoso.homeip.net"

$UserOuDescription = "Created By Script $Today_Date"
$InactiveOuDescription = "Created By Script $Today_Date"
$ServiceOuDescription = "Created By Script $Today_Date"
$CompanyOuDescription = "Created By Script $Today_Date"


#OU protection 0 off: 1 on
$ouProtect = 0

#Default OU Names
$UsersOU = "Users"
$DisabledOU = "Inactive"
$ServicesOU = "Service"

#Compile OU Structure
$Userou="OU=$UsersOU,"
$Disou="OU=$DisabledOU,"
$Serviceou="OU=$ServicesOU,"
$DaysBeforeDelete = -200
# remove-item -path $log -ErrorAction SilentlyContinue
ErrorActionPreference = "Continue"
#Sort CSV Import

$CSVImport = $CSVImport | sort EmployeeID | sort Status -Descending 

#Start Functions ------------------------------------------------------------------------------------

#Function to Write information to the log files
Function Write-Log($Info){

    #Get the Date and Format as String
    $Date = $null
    $Date = Get-Date -Format "d/M/yyyy hh:mm:ss"

        write-host $info
        
        #Write all information to General Log File.
        Add-Content -Path $Log -Value ($date + ": " + $Info)
        sleep(1)              
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
    $CompanyOU =("OU=" + $company+ "," + $distinguishedName)

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
                New-ADOrganizationalUnit -name $Company -path $distinguishedName -ProtectedFromAccidentalDeletion $ouProtect -Description $CompanyOuDescription
                write-Log "$CompanyOu doesn't exist"
                Write-log "Creating $companyou"
                }
            if ($AllOus -notLike ("*$DisOU,"+$CompanyOu + "*")) {
                New-ADOrganizationalUnit -name $DisabledOU -path $CompanyOu -ProtectedFromAccidentalDeletion $ouProtect -Description $InactiveOuDescription
                write-Log "Inactive OU doesn't exist"
                Write-log "Creating Inactive OU in $companyou"
                }
            if ($AllOus -notLike ("*$UsersOU,"+$CompanyOu + "*")) {
                New-ADOrganizationalUnit -name $UsersOU -path $CompanyOu -ProtectedFromAccidentalDeletion $ouProtect -Description $UserOuDescription
                write-Log "Users OU doesn't exist"
                Write-log "Creating Users OU in $companyou"
                }
            If (($ou -like "*$ServicesOU*") -and ($AllOus -notLike ("*Service,"+$CompanyOu + "*"))){
                New-ADOrganizationalUnit -name $ServicesOU -path $CompanyOu -ProtectedFromAccidentalDeletion $ouProtect -Description $ServiceOuDescription
                write-Log "Service OU doesn't exist"
                Write-log "Creating Service OU in $companyou"
                }

# Exit
}
}

#End Functions ------------------------------------------------------------------------------------


write-log ("`r`n")
write-log ("--------------------------------------------------------------------------------------------------------")
write-log ("Starting Script at: " + $ScriptStartTime)
Write-log ("My Version is : "+ $myVer)
write-log ("`r`nDomain Variables are`r`nCompany Name: " + $CompanyName + "`r`nDistinguishedName: " + $distinguishedName + "`r`nUPND: "  + $upnd)
write-log ("--------------------------------------------------------------------------------------------------------")

write-log "Checking if Users Exist in the Domain:"

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
                        -City (Out-String -InputObject $_.City) `
                        -Country AU -PostalCode (Out-String -InputObject $_.PostCode) `
                        -StreetAddress (Out-String -InputObject $_.Street) `
                        -enabled $True `
                        -path $baseou `
                        -EmployeeID $_.EmployeeID `
                        -EmployeeNumber $_.EmployeeID `
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
                            -City (Out-String -InputObject $_.City) `
                            -Country AU `
                            -PostalCode (Out-String -InputObject $_.PostCode) `
                            -StreetAddress (Out-String -InputObject $_.Street) `
                            -enabled $True `
                            -path $baseou `
                            -EmployeeID $_.EmployeeID `
                            -EmployeeNumber $_.EmployeeID `
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

$ScriptEndTime=(GET-DATE)
write-log -info ("Finalising Script at: " + $ScriptEndTime)
Write-Log -info ("Finishing Syncing...") 
Write-Log -info ("Minutes: "+ ($ScriptEndTime - $ScriptStartTime).Minutes +" Seconds: " + ($ScriptEndTime - $ScriptStartTime).Seconds + "`r`n`r`n")

write-host "Sleep1"
Sleep(4)
Remove-Item -path $CSVFile -force
Add-Content -Path $CSVFile `
-Value "Status,GivenName,Surname,samAccountName,DisplayName,Street,State,City,PostCode,Country,Manager,EmployeeID,Company,Description,Department,Updated,ScriptPath,Password,OfficeNumber,MobileNumber"



ForEach ($entry in $CSVImport)
    {
         Add-content -path $CSVFile -Value (`
         $entry.Status + "," +`
         $entry.GivenName + "," +`
         $entry.Surname + "," +`
         $entry.samAccountName + "," +`
         $entry.DisplayName + "," + 
         $entry.Street + "," +`
         $entry.State + "," +`
         $entry.City + ","+ `
         $entry.PostCode + "," +`
         $entry.Country + "," +`
         $entry.Manager + "," +`
         $entry.EmployeeID + "," +`
         $entry.Company + "," +`
         $entry.Description + "," +`
         $entry.Department + "," +`
         $entry.Updated + "," +`
         $entry.ScriptPath + "," +`
         $entry.Password + "," +` 
         $entry.OfficeNumber + "," +`
         $entry.MobileNumber)
         sleep(1)

    }

write-host "Sleep2"
Sleep(5)

$CSVImport = ""
$entry = ""


$ErrorActionPreference = "Continue"
#$csvimport | export-csv $CSVExportFile
Remove-Variable Today_Date,Log,ScriptStartTime,csvimport,User,CSVfile,CSVExportFile -ErrorAction SilentlyContinue