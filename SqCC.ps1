 # Remove comment '#' for lines 3-11 to make the Console window disappear.
# ------------------------------------------------------------------------
 #Add-Type -Name Window -Namespace Console -MemberDefinition '
 #[DllImport("Kernel32.dll")]
 #public static extern IntPtr GetConsoleWindow();

#[DllImport("user32.dll")]
#public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
#'
 #$consolePtr = [Console.Window]::GetConsoleWindow()
 #[Console.Window]::ShowWindow($consolePtr, 0)

 # ------------------------------------------------------------------------
#Create the date, and log file path. Creates a new file depending on the day, can append events to these logs when running.
 $todaysDate = Get-Date -Format "MM-dd-yyyy"
 $currentTime = Get-Date -DisplayHint DateTime
 $logFilePath = "logs\"+$todaysDate+".log"


#Loop through all services to find the service passed into the function, aka srvName
 function WriteToLogFile($message)
 {
    Write-Host "Log file created."
    Add-Content $logFilePath -Value $message
 }
 $highestMem = 0
 function Get-SqService($srvName)
{
    #after starting the script, remove the start button from screen
    $btnStart.Visible=$false
    $services = Get-Service -DisplayName *$srvName* 
    $serviceNum = 0
        foreach($service in $services){
        ++$serviceNum
    }
    #perform this if statement if there are no services that match the function parameter
        if($serviceNum -EQ 0){
            Write-Host "No $srvName service(s) found."
        } 
        #If the service is SqGateway, go through the process of restarting 
        elseif ($srvName -EQ "SqGateway") {
            Start-Sleep -Seconds 1
            Write-Host "Please wait... restarting SqGateway"
            $lbltitle.Text="Restarting services, please wait"
            $lbltitle.Location = "125, 100"
            #begin testing to see if there are more than 1 javaw's(Giordanos has more than 1 javaw)

            #javaw process array
            $javawArr = @()
            $javawSrv = Get-Process | WHERE {$_.ProcessName -EQ "javaw"}

            #add javaw processes into javaw array
            foreach($javaw in $javawSrv) {
                $javawArr += $javaw
            }
            #if there is more than one javaw execute the following
                if ($javawArr[1]) {
                    Write-Host "More than 1 javaw"
                    #loop through each process in the javawArr and determine which is the biggest
                    #the biggest requires a restart, as that is the SqGateway
                    foreach($item in $javawArr) {
                        Write-Host $item.WS
                        #while looping through the array, if a javaw process uses more memory, assign that to highestMem
                        if($item.WS -GT $highestMem) {
                            Write-Host $item.WS
                            $highestMem = $item.WS
                            Write-Host $highestMem "is the new highest memory javaw usage."
                        }  else {
                            Write-Host "!!! NOT HIGHER THAN HIGHEST JAVAW MEMORY !!!"
                        }
                        Write-Host $highestMem "Needs to be killed" 
                    }
                    #kill the javaw process using the most memory
                    try {
                    WriteToLogFile "Attempting to restart $srvName service(s) at: $currentTime`n"
                    taskkill /IM javaw.exe /F | WHERE $javawSrv.WS = $highestMem
                    Start-Sleep -Seconds 3
                    Start-Service SqGateway
                    Write-Host $srvName "service(s) restarted..."
                    WriteToLogFile "$srvName service(s) restarted successfully."
                    }
                    catch [System.Management.Automation.ActionPreferenceStopException] {
                        Write-Host [System.Management.Automation.ActionPreferenceStopException]
                        WriteToLogFile "`nThere was an issue restarting the $srvName service at $currentTime`n" 
                    }
                } else {
                    #perform this if there is only one javaw
                    Write-Host "Only 1 javaw"
                    WriteToLogFile "Attempting to restart $srvName service(s) at: $currentTime`n"
                    try { 
                    taskkill /IM javaw.exe /F
                    Write-Host "Javaw.exe killed."
                    Start-Sleep -Seconds 3                   
                        Start-Service SqGateway -ErrorAction Stop
                        $lblbody.Location= "100,150"
                        Write-Host $srvName "service(s) restarted..."
                        WriteToLogFile "$srvName service(s) restarted successfully.`n"
                    }
                    catch [System.Management.Automation.ActionPreferenceStopException] {
                        Write-Host "There was an issue restarting the $srvName service."
                        WriteToLogFile "There was an issue restarting the $srvName service at $currentTime`n"
                    }
                }
            }
        #perform this elseif when the service is not SqGateway
        elseif($srvName -NE "SqGateway") {
            WriteToLogFile "Attempting to restart $srvName service(s) at: $currentTime`n"
            $lbltitle.Text="Restarting services, please wait"
            $lbltitle.Location = "125, 100"
            $lblbody.Location= "100,150"
            Start-Sleep -Seconds 1
            Write-Host "Restarting $srvName service(s)..."
            try {
                Stop-Service -Force $services
                Start-Sleep -Seconds 2
                Start-Service $services -ErrorAction Stop
                Write-Host $srvName" service(s) restarted..."
                WriteToLogFile "$srvName service(s) restarted successfully.`n"
            } 
            catch [System.Management.Automation.ActionPreferenceStopException]{
                Write-Host "There was an issue restarting the $srvName service at $currentTime."
                WriteToLogFile "There was an issue restarting the $srvName service at $currentTime`n"
            }

        } else  {
            Write-Host "An error has occurred..."
        }
        Start-Sleep -Seconds 1
    }
#remove all buttons from screen for a cleaner appearance
function NoButtons()
{
    $btnYes.Visible = $false
    $btnNo.Visible = $false
}
#Display the following if the user clicks NO for "Are your credit cards now working?"
function NotWorking()
{
    $SupportLabel.BringToFront()
    $lblbody.Font = "Verdana,10,style=Bold"
    $lblbody.Location= "75,150"
    $lbltitle.text = "Contact Support"
    $lbltitle.Location = "250, 100"
    $SupportLabel.Visible=$true
    $lblbody.text = 
    "Please call our Solution Center at: 1-800-288-8160 for further troubleshooting.
    `nFor more ways of contacting support, see:" 
    NoButtons
}

#Display the following if the user clicks YES for "Are your credit cards now working?"
function YesWorking()
{
     $SupportLabel.BringToFront()
     $SupportLabel.Visible = $true
     $SupportLabel.Location = "275, 167"
     $lblbody.text = "If you would like to launch an investigation`nfor the root cause, please see:`nOr call us at: 1-800-288-8160"
     $lblbody.Font = "Verdana,10,style=Bold"
     $lblbody.Location = "50, 150"
     NoButtons
}

function ClearList()
{
    $lbltitle.Text = "Squirrel Systems CC GUI"
    $lblbody.Text = "Next..."
}

#check if the service is installed, and if it is, restart it (see the very top function, Get-SqService)
function SqServiceList ()
{
    Get-SqService "Shift4"
    Get-SqService "TGI"
    Get-SqService "SqGateway"
    Get-SqService "Moneris"
    Get-SqService "STPI"
    Get-SqService "Stunnel"
    Get-SqService "SquirrelRelay53Bank"
    Get-SqService "Elavon"
    Get-SqService "SkyTab"
    Get-SqService "eLaunch"
    Get-SqService "Counter"
    Get-SqService "PAX Agent Service"
    Get-SqService "CayanService"
    Get-SqService "FCCMiddleService"
    Get-SqService "FreedomPay"
    Get-SqService "CRM"
    Get-SqService "Paytronix"
    Get-SqService "SquirrelPXC"
    Get-SqService "SquirrelRelayBuyATab"
    Get-SqService "SqMatrix"
    WriteToLogFile "`n-------------------------------------------------------`n"
    
    Start-Sleep -Seconds 2
    Write-Host "Confirm if CCs are working -- YES or NO"
    $lbltitle.Text = "Squirrel Systems Fix Utility"
    $lblbody.Location = "150,425"
    $lblbody.Font="Verdana,15,style=Bold"
    $lblbody.text = "Are your credit cards now working? YES or NO?"
    $btnYes.Visible = $true
    $btnNo.Visible = $true
    $btnYes.Add_Click({ YesWorking })
    $btnNo.Add_Click({ NotWorking })
}

Add-Type -AssemblyName System.Windows.Forms

#CREATE OBJECTS
$FormObject = [System.Windows.Forms.Form]
$LabelObject = [System.Windows.Forms.Label]
$ButtonObject = [System.Windows.Forms.Button]

#link GUI info
$SupportLabel = New-Object System.Windows.Forms.LinkLabel
$SupportLabel.Size = New-Object System.Drawing.Size(375,20)
$SupportLabel.Location = New-Object System.Drawing.Size(400,183)
$SupportLabel.LinkColor = "WHITE"
$SupportLabel.ActiveLinkColor = "WHITE"
$SupportLabel.BackColor = "Transparent"
$SupportLabel.Text = "https://help.squirrelsystems.com/s/contactus"
$SupportLabel.Visible = $false
$SupportLabel.Font="Verdana,10,style=Bold"
$SupportLabel.add_Click({[system.Diagnostics.Process]::start("https://help.squirrelsystems.com/s/contactus")})

#WINDOW GUI info
$HelloWorldForm = New-Object $FormObject
$HelloWorldForm.ClientSize = '875,600'
$HelloWorldForm.Text = "Squirrel Systems Fix Utility"
$HelloWorldForm.BackColor = "GRAY"
$HelloWorldForm.StartPosition = 'CenterScreen'

#BACKGROUND IMAGE
$Image = [system.drawing.image]::FromFile("$PSScriptRoot\img\squirrel2.png") 
$HelloWorldForm.BackgroundImage = $Image
$HelloWorldForm.BackgroundImageLayout = "Center"

#FORM ICON
$sqIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("$PSScriptRoot\img\squirrelicon2.ico")
$HelloWorldForm.Icon = $sqIcon

#TITLE
$lbltitle = New-Object $LabelObject
$lbltitle.Text = "Squirrel Systems Fix Utility"
$lbltitle.ForeColor = "White"
$lbltitle.BackColor = "Transparent"
$lbltitle.Font = "Verdana,25,style=Bold"
$lbltitle.AutoSize=$true
$lbltitle.Location=New-Object System.Drawing.Point(185,50)


#BODY
$lblbody = New-Object $LabelObject
$lblbody.Font = "Verdana,10,style=Bold"
$lblbody.AutoSize=$true
$lblbody.ForeColor = "White"
$lblbody.BackColor = "Transparent"
$lblbody.Location=New-Object System.Drawing.Point(400,300)


#START BUTTON
$btnStart=New-Object $ButtonObject
$btnStart.Text = "CLICK TO START CC FIX"
$btnStart.ForeColor = "White"
$btnStart.AutoSize=$false
$btnStart.Size = "300,100"
$btnStart.BackColor = "#333333"
$btnStart.Location=New-Object System.Drawing.Point(315,250)
$btnStart.Font="Verdana,25,style=Bold"

#YES BUTTON
$btnYes=New-Object $ButtonObject
$btnYes.ForeColor = "White"
$btnYes.BackColor = "#333333"
$btnYes.Text = "YES"
$btnYes.AutoSize=$false
$btnYes.Size="200,75"
$btnYes.Visible = $false
$btnYes.Location=New-Object System.Drawing.Point(50,250)
$btnYes.Font="Verdana,20,style=Bold"

#NO BUTTON
$btnNo=New-Object $ButtonObject
$btnNo.Text = "NO"
$btnNo.ForeColor = "White"
$btnNo.BackColor = "#333333"
$btnNo.AutoSize=$false
$btnNo.Size="200,75"
$btnNo.Visible = $false
$btnNo.Location=New-Object System.Drawing.Point(650,250)
$btnNo.Font="Verdana,20,style=Bold"

$HelloWorldForm.Controls.AddRange(@($lbltitle, $btnYes, $btnNo, $btnStart, $lblbody, $SupportLabel))

#BTN start is visible right away when opening the GUI. Executes the SqServiceList function when clicked
#This is also the start of the program.
$btnStart.Add_Click({ SqServiceList })

$HelloWorldForm.ShowDialog()