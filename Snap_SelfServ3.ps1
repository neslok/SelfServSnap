# script1.ps1


function MainMenu {

$xuser_action = Read-Host '
============================
Nutanix Snapshot Management
============================

 1 - Create Snap
 2 - Restore from Snap
 3 - Delete Snap
 Q - Quit/Exit

 What action would you like to perform?' 

 SetUserAction $xuser_action
 
 }
 
 function SetUserAction {  

Switch -CaseSensitive ($xuser_action)
    { 
1 {Create_Snap}
2 {Restore_Snap}
3 {Delete_Snap}
Q {exit}

    } 
}

 

function Create_Snap {

cls

Write-Host '
============================
Nutanix Snapshot Create
============================

Snapshots will be created with the following format:
'VM Name-Snapshot Name'
'

$in_vmname = Read-Host 'Enter VM'
$in_snap_name = Read-Host 'Enter snap name'
$user_action = 'Create_Snap'    

Invoke-Command -ComputerName UTIL  -scriptblock  {param($v1,$v2,$v3) C:\Users\Administrator\Documents\SnapSelfServ\v3\SnapActionsv3.ps1 -in_vmname $v1 -in_snap_name $v2 -user_action $v3 } -ArgumentList $in_vmname,$in_snap_name,$user_action

#start-sleep -s 10

}

function Restore_Snap {

cls

Write-Host '
============================
Nutanix Snapshot Restore
============================
'
""

$rs_snap_name = Read-Host 'Enter snap name to restore'
$user_action = 'Restore_Snap'

#Invoke-Command -ComputerName UTIL  -scriptblock  { C:\Users\Administrator\Documents\SnapSelfServ\SnapActions.ps1 $rs_snap_name $user_action }
Invoke-Command -ComputerName UTIL  -scriptblock  {param($v1,$v2) C:\Users\Administrator\Documents\SnapSelfServ\v3\SnapActionsv3.ps1 -rs_snap_name $v1 -user_action $v2 } -ArgumentList $rs_snap_name,$user_action

}

function Delete_Snap {

cls

Write-Host '
============================
Nutanix Snapshot Delete
============================
'
""

$rm_snap_name = Read-Host 'Enter snap name to delete'
$user_action = 'Delete_Snap'

#C:\Users\Administrator\Documents\SnapSelfServ\SnapActions.ps1 $rm_snap_name $user_action
Invoke-Command -ComputerName UTIL  -scriptblock  {param($v1,$v2) C:\Users\Administrator\Documents\SnapSelfServ\v3\SnapActionsv3.ps1 -rm_snap_name $v1 -user_action $v2 } -ArgumentList $rm_snap_name,$user_action


}

cls



if ($xuser_action -eq $null) {
    MainMenu
    } else {
    SetUserAction
    }
 