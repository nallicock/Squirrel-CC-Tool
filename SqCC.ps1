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

 #Loop through all services to find the service passed into the function, aka srvName
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
            $javawSrv

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
                    taskkill /IM javaw.exe /F | WHERE $javawSrv.WS = $highestMem
                } else {
                    #perform this if there is only one javaw
                    Write-Host "Only 1 javaw"
                    taskkill /IM javaw.exe /F
                    Write-Host "Javaw.exe killed."
                    Start-Sleep -Seconds 3
                    Start-Service SqGateway
                    $lblbody.Location= "100,150"
                    Write-Host $srvName "service(s) restarted..."
                }
            }
        #perform this elseif when the service is not SqGateway
        elseif($srvName -NE "SqGateway") {
            $lbltitle.Text="Restarting services, please wait"
            $lbltitle.Location = "125, 100"
            Start-Sleep -Seconds 1
            $lblbody.Location= "100,150"
            Write-Host "Restarting $srvName service(s)..."
            Stop-Service -Force $services
            Start-Sleep -Seconds 2
            Start-Service $services
            Write-Host $srvName" service(s) restarted..."
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
    $btnOk.Visible = $false
}
#Display the following if the user clicks NO for "Are your credit cards now working?"
function NotWorking()
{
    $HelpCenterLabel.BringToFront()
    $SupportLabel.BringToFront()
    $LogMeInLabel.BringToFront()
    $lblbody.Font = "Verdana,10,style=Bold"
    $lblbody.Location= "100,150"
    $lbltitle.text = "Contact Support"
    $lbltitle.Location = "250, 100"
    $LogMeInLabel.Visible=$true
    $HelpCenterLabel.Visible=$true
    $SupportLabel.Visible=$true
    $lblbody.text = 
    "Please call our Solution Center at: 1-800-288-8160 for further troubleshooting.
    `nYou can also visit our support page at: " + 
    "`nHelp Center: " + 
    "`nRemote Connection Link: " 
    NoButtons
}

#Display the following if the user clicks YES for "Are your credit cards now working?"
function YesWorking()
{
     $lbltitle.text = "Squirrel Systems"
     $lbltitle.Location = "250, 100"
     $lblbody.text = "Have a great day!"
     $lblbody.Location = "320, 150"
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
    # Get-SqService "Shift4"
    # Get-SqService "TGI"
    Get-SqService "SqGateway"
    # Get-SqService "Moneris"
    # Get-SqService "STPI"
    # Get-SqService "Stunnel"
    Start-Sleep -Seconds 2
    Write-Host "Confirm if CCs are working -- YES or NO"
    $lbltitle.Text = "Squirrel Systems CC GUI"
    $lblbody.Location = "150,250"
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
$SupportLabel.Text = "https://www.squirrelsystems.com/support/"
$SupportLabel.Visible = $false
$SupportLabel.Font="Verdana,10,style=Bold"
$SupportLabel.add_Click({[system.Diagnostics.Process]::start("https://www.squirrelsystems.com/support/")})

$HelpCenterLabel = New-Object System.Windows.Forms.LinkLabel
$HelpCenterLabel.Location = New-Object System.Drawing.Size(200,200)
$HelpCenterLabel.Size = New-Object System.Drawing.Size(300,15)
$HelpCenterLabel.LinkColor = "WHITE"
$HelpCenterLabel.Visible = $false
$HelpCenterLabel.ActiveLinkColor = "WHITE"
$HelpCenterLabel.Text = "https://help.squirrelsystems.com/s/"
$HelpCenterLabel.Font="Verdana,10,style=Bold"
$HelpCenterLabel.add_Click({[system.Diagnostics.Process]::start("https://help.squirrelsystems.com/s/")})

$LogMeInLabel = New-Object System.Windows.Forms.LinkLabel
$LogMeInLabel.Location = New-Object System.Drawing.Size(285, 215)
$LogMeInLabel.Size = New-Object System.Drawing.Size(450,15)
$LogMeInLabel.LinkColor = "WHITE"
$LogMeInLabel.Visible = $false
$LogMeInLabel.ActiveLinkColor = "WHITE"
$LogMeInLabel.Text = "https://secure.logmeinrescue.com/Customer/Code.aspx"
$LogMeInLabel.Font="Verdana,10,style=Bold"
$LogMeInLabel.add_Click({[system.Diagnostics.Process]::start("https://secure.logmeinrescue.com/Customer/Code.aspx")})

#WINDOW GUI info
$HelloWorldForm = New-Object $FormObject
$HelloWorldForm.ClientSize = '800,600'
$HelloWorldForm.Text = "Squirrel Systems - CC GUI Test"
$HelloWorldForm.BackColor = "GRAY"
$HelloWorldForm.StartPosition = 'CenterScreen'

#TITLE
$lbltitle = New-Object $LabelObject
$lbltitle.Text = "Squirrel Systems CC GUI"
$lbltitle.ForeColor = "White"
$lbltitle.Font = "Verdana,25,style=Bold"
$lbltitle.AutoSize=$true
$lbltitle.Location=New-Object System.Drawing.Point(185,50)


#BODY
$lblbody = New-Object $LabelObject
$lblbody.Font = "Verdana,10,style=Bold"
$lblbody.AutoSize=$true
$lblbody.ForeColor = "White"
$lblbody.Location=New-Object System.Drawing.Point(400,300)


#START BUTTON
$btnStart=New-Object $ButtonObject
$btnStart.Text = "CLICK TO START CC FIX"
$btnStart.ForeColor = "White"
$btnStart.AutoSize=$false
$btnStart.Size = "300,300"
$btnStart.BackColor = "BLACK"
$btnStart.ForeColor = "WHITE"
$btnStart.Location=New-Object System.Drawing.Point(275,150)
$btnStart.Font="Verdana,25,style=Bold"

#YES BUTTON
$btnYes=New-Object $ButtonObject
$btnYes.ForeColor = "White"
$btnYes.Text = "YES"
$btnYes.AutoSize=$false
$btnYes.Size="200,75"
$btnYes.Visible = $false
$btnYes.Location=New-Object System.Drawing.Point(150,150)
$btnYes.Font="Verdana,20,style=Bold"

#NO BUTTON
$btnNo=New-Object $ButtonObject
$btnNo.Text = "NO"
$btnNo.ForeColor = "White"
$btnNo.AutoSize=$false
$btnNo.Size="200,75"
$btnNo.Visible = $false
$btnNo.Location=New-Object System.Drawing.Point(500,150)
$btnNo.Font="Verdana,20,style=Bold"

$HelloWorldForm.Controls.AddRange(@($lbltitle, $btnYes, $btnNo, $btnStart, $lblbody, $SupportLabel, $HelpCenterLabel, $LogMeInLabel))

#BTN start is visible right away when opening the GUI. Executes the SqServiceList function when clicked
#This is also the start of the program.
$btnStart.Add_Click({ SqServiceList })

$HelloWorldForm.ShowDialog()