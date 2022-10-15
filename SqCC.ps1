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
 $logFilePath = "logs\"+$todaysDate+".log"


#Loop through all services to find the service passed into the function, aka srvName
 function WriteToLogFile($message)
 {
    Write-Host "Log file created."
    Add-Content $logFilePath -Value $message
 }
 $highestMem = 0

 function Restarting-Services()
 {
    $lbltitle.Text="Restarting services, please wait"
    $lbltitle.Location = "125, 100"
 }
 function Home-Screen()
 {
    NoButtons
    NoLinks
    $lbltitle.Text = "What Is Not Working?"
    $lbltitle.Location = "250, 50"

    #btnCC Properties
    $btnCC.Visible = $true
    $btnCC.Location = "100, 100"
    $btnCC.Add_Click({SqCCService})

    #btnQSR Properties
    $btnQSR.Visible = $true
    $btnQSR.Location = "600, 100"
    $btnQSR.Add_Click({SqQSRService})
    
    #btnOO Properties
    $btnOO.Visible = $true
    $btnOO.Location = "100, 350"
    $btnOO.Add_Click({SqOnlineOrderService})

    #btnTerm Properties
    $btnTerm.Visible = $true
    $btnTerm.Location = "600, 350"
    $btnTerm.Add_Click({SqTerminalsService})
 }

 function Term-Screen()
 {
    $lbltitle.Text = "What Is Showing On Your Terminals?"
    $lbltitle.Location = "100, 50"
    NoButtons

    #Host is busy
    $btnHost.Visible = $true
    $btnHost.Location = "100, 100"

    #Searching for server
    $btnSFS.Visible = $true
    $btnSFS.Location = "600, 100"
    
    #Loading Data
    $btnData.Visible = $true
    $btnData.Location = "100, 350"

    #btnTerm Properties
    $btnCRM.Visible = $true
    $btnCRM.Location = "600, 350"
 }

 function Get-SqService($srvName)
{
    $serviceNum = 0
    NoButtons
    $currentTime = Get-Date -DisplayHint DateTime
    #after starting the script, remove the start button from screen
    $btnStart.Visible=$false
    $services = Get-Service -DisplayName *$srvName* 
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
            Restarting-Services
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
            Restarting-Services
            Start-Sleep -Seconds 2
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
    $btnStart.Visible = $false
    $btnYes.Visible = $false
    $btnNo.Visible = $false
    $btnOk.Visible = $false
    $btnCC.Visible = $false
    $btnQSR.Visible = $false
    $btnOO.Visible = $false
    $btnTerm.Visible = $false
    $btnHost.Visible = $false
    $btnSFS.Visible = $false
    $btnData.Visible = $false
    $btnCRM.Visible = $false
}

function NoLinks()
{
    $SupportLabel.Visible = $false
    $lblbody.Text = ""
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
    $btnOk.Visible = $true
}

#Display the following if the user clicks YES for "Are your credit cards now working?"
function YesWorking()
{
     $SupportLabel.BringToFront()
     $SupportLabel.Visible = $true
     $SupportLabel.Location = "275, 167"
     $lblbody.text = "If you would like to launch an investigation`nfor the root cause, please see:`nOr call us at: 1-800-288-8160"
     $lblbody.Font = "Verdana,10,style=Bold"
     $lblbody.Location = "25, 150"
     NoButtons
     $btnOk.Visible = $true
}

function ClearList()
{
    $lbltitle.Text = "Squirrel Systems CC GUI"
    $lblbody.Text = "Next..."
}

#check if the service is installed, and if it is, restart it (see the very top function, Get-SqService)

function ConfirmWorking($msg)
{
    $lbltitle.Text = "Squirrel Systems Fix Utility"
    $lbltitle.Location = "185, 50"
    $lblbody.Location = "150,425"
    $lblbody.Font="Verdana,15,style=Bold"
    $lblbody.text = "Are your $msg now working? YES or NO?"
    $btnYes.Visible = $true
    $btnNo.Visible = $true
    $btnYes.Add_Click({ YesWorking })
    $btnNo.Add_Click({ NotWorking })
}
function SqCCService ()
{
    Get-SqService "Shift4"
    Get-SqService "TGI"
    Get-SqService "SqGateway"
    # Get-SqService "Moneris"
    # Get-SqService "STPI"
    # Get-SqService "Stunnel"
    # Get-SqService "SquirrelRelay53Bank"
    # Get-SqService "Elavon"
    # Get-SqService "SkyTab"
    # Get-SqService "eLaunch"
    # Get-SqService "Counter"
    # Get-SqService "PAX Agent Service"
    # Get-SqService "CayanService"
    # Get-SqService "FCCMiddleService"
    # Get-SqService "SquirrelLogansCC"
    # Get-SqService "FreedomPay"
    # Get-SqService "CRM"
    # Get-SqService "Paytronix"
    # Get-SqService "SquirrelPXC"
    # Get-SqService "SquirrelRelayBuyATab"
    # Get-SqService "SqMatrix"
    WriteToLogFile "`n-------------------------------------------------------`n"
    
    Start-Sleep -Seconds 2
    Write-Host "Confirm if CCs are working -- YES or NO"
    ConfirmWorking("Credit Cards")
    
}

function SqQSRService()
{
    Get-SqService "QSR"
    ConfirmWorking("Kitchen Screens")
}

function SqOnlineOrderService()
{
    Get-SqService "OLO Agent"
    Get-SqService "OComm"
    Get-SqService "eLaunch"
    Get-SqService "SqGateway"
    ConfirmWorking("Online Orders")
}

function SqTerminalsService()
{
    NoButtons
    Term-Screen
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
$btnStart.Text = "Click to Start Quick Fix"
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

#OK BUTTON
$btnOk=New-Object $ButtonObject
$btnOk.Text = "OK"
$btnOk.ForeColor = "White"
$btnOk.BackColor = "#333333"
$btnOk.AutoSize=$false
$btnOk.Size="200,75"
$btnOk.Visible = $false
$btnOk.Location=New-Object System.Drawing.Point(330, 350)
$btnOk.Font="Verdana,20,style=Bold"
$btnOk.Add_Click({$HelloWorldForm.Close()})

#CC FIX BUTTON
$btnCC=New-Object $ButtonObject
$btnCC.Text = "Credit Cards"
$btnCC.ForeColor = "White"
$btnCC.BackColor = "#333333"
$btnCC.AutoSize=$false
$btnCC.Size="200,75"
$btnCC.Visible = $false
$btnCC.Location=New-Object System.Drawing.Point(650,250)
$btnCC.Font="Verdana,20,style=Bold"

#QSR BUTTON
$btnQSR=New-Object $ButtonObject
$btnQSR.Text = "Kitchen Screens"
$btnQSR.ForeColor = "White"
$btnQSR.BackColor = "#333333"
$btnQSR.AutoSize=$false
$btnQSR.Size="200,75"
$btnQSR.Visible = $false
$btnQSR.Location=New-Object System.Drawing.Point(650,250)
$btnQSR.Font="Verdana,20,style=Bold"

#ONLINE ORDER BUTTON
$btnOO=New-Object $ButtonObject
$btnOO.Text = "Online Orders"
$btnOO.ForeColor = "White"
$btnOO.BackColor = "#333333"
$btnOO.AutoSize=$false
$btnOO.Size="200,75"
$btnOO.Visible = $false
$btnOO.Location=New-Object System.Drawing.Point(650,250)
$btnOO.Font="Verdana,20,style=Bold"

#TERMINALS BUTTON
$btnTerm=New-Object $ButtonObject
$btnTerm.Text = "Terminals"
$btnTerm.ForeColor = "White"
$btnTerm.BackColor = "#333333"
$btnTerm.AutoSize=$false
$btnTerm.Size="200,75"
$btnTerm.Visible = $false
$btnTerm.Location=New-Object System.Drawing.Point(650,250)
$btnTerm.Font="Verdana,20,style=Bold"

#HOST IS BUSY
$btnHost=New-Object $ButtonObject
$btnHost.Text = "Host Is Busy"
$btnHost.ForeColor = "White"
$btnHost.BackColor = "#333333"
$btnHost.AutoSize=$false
$btnHost.Size="230,75"
$btnHost.Visible = $false
$btnHost.Location=New-Object System.Drawing.Point(650,250)
$btnHost.Font="Verdana,12,style=Bold"

#SEARCHING FOR SERVER
$btnSFS=New-Object $ButtonObject
$btnSFS.Text = "Searching for Server"
$btnSFS.ForeColor = "White"
$btnSFS.BackColor = "#333333"
$btnSFS.AutoSize=$false
$btnSFS.Size="230,75"
$btnSFS.Visible = $false
$btnSFS.Location=New-Object System.Drawing.Point(650,250)
$btnSFS.Font="Verdana,12,style=Bold"

#LOADING DATA/IMAGE 0/1
$btnData=New-Object $ButtonObject
$btnData.Text = "Loading Data Page 0 Image 1"
$btnData.ForeColor = "White"
$btnData.BackColor = "#333333"
$btnData.AutoSize=$false
$btnData.Size="230,75"
$btnData.Visible = $false
$btnData.Location=New-Object System.Drawing.Point(650,250)
$btnData.Font="Verdana,12,style=Bold"

#CRM INTERFACE
$btnCRM=New-Object $ButtonObject
$btnCRM.Text = "CRM Interface Is Not Turned On"
$btnCRM.ForeColor = "White"
$btnCRM.BackColor = "#333333"
$btnCRM.AutoSize=$false
$btnCRM.Size="230,75"
$btnCRM.Visible = $false
$btnCRM.Location=New-Object System.Drawing.Point(650,250)
$btnCRM.Font="Verdana,12,style=Bold"

$HelloWorldForm.Controls.AddRange(@($lbltitle, $btnYes, $btnNo, $btnOk,  $btnStart, $btnCC, $btnQSR, $btnTerm, $btnOO, $btnHost, $btnSFS, $btnData, $btnCRM, $lblbody, $SupportLabel))

#BTN start is visible right away when opening the GUI. Executes the SqServiceList function when clicked
#This is also the start of the program.
$btnStart.Add_Click({ Home-Screen })

$HelloWorldForm.ShowDialog()