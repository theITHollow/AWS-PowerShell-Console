$inputXML = @"
<Window x:Class="WpfApplication2.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApplication2"
        mc:Ignorable="d"
        Title="EC2 PowerShell Console" Height="515.786" Width="794.979">
    <Grid>
        <Grid.Background>
            <ImageBrush ImageSource="http://theithollow.com/wp-content/uploads/2016/10/AWS-PoshBackground.png"/>
        </Grid.Background>
        <Rectangle HorizontalAlignment="Left" Height="121" Margin="337,253,0,0" Stroke="Black" VerticalAlignment="Top" Width="401" Opacity="0.6">
            <Rectangle.Fill>
                <LinearGradientBrush EndPoint="0.5,1" StartPoint="0.5,0">
                    <GradientStop Color="Black" Offset="0"/>
                    <GradientStop Color="#FF2988F0" Offset="0.396"/>
                </LinearGradientBrush>
            </Rectangle.Fill>
        </Rectangle>

        <Button x:Name="GetEC2InstancesButton" Content="Get-EC2Instance-State" HorizontalAlignment="Left" Margin="374,21,0,0" VerticalAlignment="Top" Width="311" Height="36" Background="#FF7F8D9C"/>
        <ListView x:Name="listView" HorizontalAlignment="Left" Height="161" Margin="311,62,0,0" VerticalAlignment="Top" Width="450" Background="White">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="EC2-Instance" DisplayMemberBinding ="{Binding Instance}" Width="225"/>
                    <GridViewColumn Header="EC2-State" DisplayMemberBinding ="{Binding State}" Width="225"/>
                </GridView>
            </ListView.View>
        </ListView>
        <Button x:Name="StopInstanceButton" Content="Stop Instance" HorizontalAlignment="Left" Margin="554,278,0,0" VerticalAlignment="Top" Width="167"/>
        <Button x:Name="StartInstanceButton" Content="Start Instance" HorizontalAlignment="Left" Margin="554,303,0,0" VerticalAlignment="Top" Width="167"/>
        <Button x:Name="TerminateButton" Content="Terminate" HorizontalAlignment="Left" Margin="554,328,0,0" VerticalAlignment="Top" Width="167"/>
        <TextBlock x:Name="EC2ActionsTextBlock" HorizontalAlignment="Left" Margin="352,302,0,0" TextWrapping="Wrap" Text="EC2 Actions" VerticalAlignment="Top" Width="178" FontSize="18" RenderTransformOrigin="0.5,0.5">
            <TextBlock.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="-0.006"/>
                    <TranslateTransform/>
                </TransformGroup>
            </TextBlock.RenderTransform>
        </TextBlock>

    </Grid>
</Window>

"@       
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}
 
#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
Get-FormVariables
 
#===========================================================================
# Actually make the objects work
#===========================================================================
 
#Get EC2 Instance information and display it in the Grid on the Form
Function Get-EC2 {

$WPFlistView.Items.Clear()
$Instances = (Get-EC2Instance).instances
foreach ($instance in $instances) {
    New-Object -TypeName PSObject -Property @{
    'Instance' = $instance.InstanceId
    'State' = $instance.state.name
    }
}
}

#Stop an EC2 Instance by providing an instanceID in the form
Function Stop-EC2($selectedinstance) {

#Stop the EC2Instance based on the text from the form
Stop-EC2Instance -InstanceId $selectedinstance
Do {
    Get-EC2 | % {$WPFlistView.AddChild($_)}
    $stopinstance = Get-EC2Instance -InstanceId $selectedinstance
    $stopinstancestate = $stopinstance.Instances.State.Name 
    start-sleep -s 5
    }
Until ($stopinstancestate -eq "stopped")
#Refresh the Grid once more to show final state
Get-EC2 | % {$WPFlistView.AddChild($_)}
}
    
#Start an EC2 Instance by providing an instanceID in the form
Function Start-EC2($selectedinstance) {

#Start the EC2Instance based on the text from the form 
Start-EC2Instance -InstanceId $selectedinstance
Do {
    Get-EC2 | % {$WPFlistView.AddChild($_)}
    $startinstance = Get-EC2Instance -instanceId $selectedinstance
    $startinstancestate = $startinstance.Instances.State.Name 
    start-sleep -s 5
    }
Until ($startinstancestate -eq "running")
#Refresh the Grid once more to show final state
Get-EC2 | % {$WPFlistView.AddChild($_)}
}    

#Terminate an EC2 Instance by providing an instancID in the form
Function Terminate-EC2($selectedinstance) {

#Terminate the EC2 instnace based on text from the form
Remove-EC2Instance -InstanceId $selectedinstance -Confirm:$false
Start-Sleep 2
Get-EC2 | % {$WPFlistView.AddChild($_)}
Do {
    Get-EC2 | % {$WPFlistView.AddChild($_)}
    $terminstance = Get-EC2Instance -instanceId $selectedinstance
    $terminstancestate = $terminstance.Instances.State.Name 
    start-sleep -s 3
    Get-EC2 | % {$WPFlistView.AddChild($_)}
    }
Until ($terminstancestate -eq "terminated")
    #Refresh the Grid once more to show final state
    Get-EC2 | % {$WPFlistView.AddChild($_)}
}


#Code the Button Clicks to Call functions
$WPFGetEC2InstancesButton.Add_Click({
Get-EC2 | % {$WPFlistView.AddChild($_)}
})

$WPFStopInstanceButton.Add_Click({
Stop-EC2 -selectedinstance $WPFlistView.SelectedItem.Instance
})

$WPFStartInstanceButton.Add_Click({
Start-EC2 -selectedinstance $WPFlistView.SelectedItem.Instance
})

$WPFTerminateButton.Add_Click({
Terminate-EC2 -selectedinstance $WPFlistView.SelectedItem.Instance
})



#===========================================================================
# Shows the form
#===========================================================================
write-host "To show the form, run the following" -ForegroundColor Cyan
'$Form.ShowDialog() | out-null'

$Form.ShowDialog() | out-null