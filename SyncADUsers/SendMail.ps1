 ############################################################################
 #Script to e-mail Blah to Blah from Blah 
 #
 # Usage .\Sendlogs.ps1 -from "Tester <email@mail.com.au>" 
 # -to "To <recepient@domain.com.au>" -subject "Hi from My Script" 
 # body "HI this is the body of my message" -SMTPServer "mysmtp.domain.com.au" 
 # -attachment "C:\temp\servers.txt" -smtpport "587" are optional.
 ############################################################################


 param(

    [Parameter(

        Mandatory = $true,

        Position = 0,

        HelpMessage = "From: Who is the e-mail coming from"

    )]

    [String] $From,

 

    [Parameter(

        Mandatory = $true,

        Position = 1,

        HelpMessage = "To: Who is the e-mail going to"

    )]

    [string] $To,

 

    [Parameter(

        Mandatory = $false,

        Position = 3,

        HelpMessage = "Mail Servers Details"


    )]

    [string] $SMTPServer = "smtp.nicta.com.au",



    [parameter(

        Mandatory = $false,

        Position = 4,

        HelpMessage = "What port does the mail servers SMTP respond on Default is Port 25"

        )]

    #Default port 25 for
    [string] $smtpport = "25", 

    

    [Parameter(

        Mandatory = $false,

        Position = 5,

        HelpMessage = "What Attachment you will require being sent with this message"


    )]

    [array] $attachment,


    [parameter(

        Mandatory = $true,

        Position = 6,

        HelpMessage = "What is the Subject of this message"


        )]

    [string] $subject,

    

    [parameter(

        Mandatory = $true,

        Position = 7,

        HelpMessage = "What is the Body of this message"

        )]

    [string] $body,
    


    [parameter(

        Mandatory = $false,

        Position = 8

        )]

    [string] $cc




)
 
##############################################################################
# Send the Actual Message

write-host -f red $attachment
$CC = $cc.ToString()


if($attachment)
    {
        


if($cc)
    {
        Write-host ("Sending Message with Attachment and CC " + $attachment) -ForegroundColor Yellow
      
       Send-MailMessage -From $From -to $To -cc $cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Attachments $attachment  -BodyAsHtml
        

    }

else
    {
        Write-host ("Sending Message with Attachment and No CC") -ForegroundColor red
      
  
        Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Attachments $attachment  -BodyAsHtml
        
    }
      
       


    }

else
    {
        
if($cc)
    {
        Write-host ("Sending Message NO Attachment And CC " + $attachment) -ForegroundColor Yellow
      
       
        
        Send-MailMessage -From $From -to $To -cc $cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort  -BodyAsHtml
    }

else
    {
        Write-host ("Sending Message with no Attachment and No CC") -ForegroundColor red
      
  
        Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort  -BodyAsHtml
        
    }
        
    }


##############################################################################