#==============================================================
# SCRIPT INFO
#
# Enables enduser to Create/Restore/Delete VM snapshots
#
# By Keith Olsen - keith.olsen@nutanix.com
#
# With thanks to Chris Jeucken - leveraged some code from his
# Query all Snapshots on Nutanix script
#
# Requires 2 scripts to be run on management server with
# NutanixCmdlets installed
#
# NutanixCmdlets available from Prism under the Logged in User 
# Menu in the upper right corner.
#
# To increase security, place SnapActions.ps1 in a directory
# with limited access and only grant read/execute permissions
# to users
#
# PLEASE NOTE - this script has not been audited for any 
# security vulnerabilities.
# Please review and understand what it does, and how this 
# may impact your environment.
#
# THIS CARRIES NO WARRANTY - EXPRESSED NOR IMPLIED
# USE STRICTLY AT YOUR OWN RISK.
#
#=============================================================




# SCRIPT INFO -------------------
# --- Query all Snapshots on Nutanix ---
# By Chris Jeucken
# v0.9
# -------------------------------
# Run on management server with NutanixCmdlets installed



# VARIABLES ---------------------

# Define input variables from Snap_SelfServ script
param(
    $in_vmname = "Client1",
    $in_snap_name = "invalid",
    $rs_snap_name = "inalid",
    $rm_snap_name ="invalid",
    $user_action = "List_Snaps"
    )

# Default variables
    $NTNXSnapin = "NutanixCmdletsPSSnapin"

# Set environment specific variables
    $NTNXCluster = "192.168.1.30" # Divide multiple clusters with semicolon (;).
   
# SCRIPT ------------------------
# Convert variables to multi line
    $NTNXCluster = $NTNXCluster.Split(";")


# Set admin credentials 
    #$secureString = "01000000d08c9ddf0115d1118c7a00c04fc297eb0100000031b0577a76789141bf05df195dd37d1c000000000200000000001066000000010000200000003dabb153749040c110ccc0bf04fce496d427a01f5fccd2eb823ecc6cf236ddf6000000000e800000000200002000000012f3e9b130b39145fab56a2fe7c9bb16023f5813f9ccee6f1a2602a1bffcbe3620000000e4f65f60e8c6acc96783cd81a062043e5ea7ce0e7ee97dca39a19b9efcf9f00a40000000683ee5dc9c83457c65fc41b43df4db778398c20f9fa889e5d073db2ad9de06777c6c401754e9056df940f264c3c70ad9ee17056a8ef93716806e303b02f3a3eb"
    #$secpasswd = ConvertTo-SecureString $secureString
    $login =  "snapadmin@neslok.local"
    $secpasswd = ConvertTo-SecureString "plo00olpeR!" -AsPLainText -Force
    $NTNXCredentials = New-Object System.Management.Automation.PSCredential ($login,$secpasswd)
    

# Importing Nutanix Cmdlets
    $Loaded = Get-PSSnapin -Name $NTNXSnapin -ErrorAction SilentlyContinue | ForEach-Object {$_.Name}
    $Registered = Get-PSSnapin -Name $NTNXSnapin -Registered -ErrorAction SilentlyContinue | ForEach-Object {$_.Name}

    foreach ($Snapin in $Registered) {
        if ($Loaded -notcontains $Snapin) {
            Add-PSSnapin $Snapin
        }
    }

# Connect to Nutanix Clusters
    foreach ($Cluster in $NTNXCluster) {
        try {
            Connect-NTNXCluster -Server $Cluster  -UserName $NTNXCredentials.UserName -Password $NTNXCredentials.Password -acceptinvalidsslcert  -ErrorAction SilentlyContinue | Out-Null
        } catch {
            Write-Host *** Not able to connect to Nutanix Cluster $Cluster *** -ForegroundColor Red
        }
    }

# Test connection to Nutanix cluster
    if (!(Get-NTNXCluster -ErrorAction SilentlyContinue)) {
        Write-Host *** No functional Nutanix connection available *** -ForegroundColor Red
        exit
    }


# Get all VMs and snapshots

    $AllNTNXVM = Get-NTNXVM -ErrorAction SilentlyContinue
    $AllNTNXSnapshots = Get-NTNXSnapshot -ErrorAction SilentlyContinue
 

# Get VM to snapshot and snapshot name

$vmUuid = ($AllNTNXVM |  Where-Object {$_.vmName -eq $in_vmname}).uuid

function ListSnap {

#==============================================================
# Validates VM exists
#==============================================================

foreach ($VM in $AllNTNXVM) {

    if ($VM.vmName -eq $in_vmname){
       
    write-host "VM found, querying snapshots"
#==============================================================
# Creates table of snapshots for specified VM
#==============================================================


# Create results table

    $Results = New-Object system.Data.DataTable "All NTNX snapshots"
    $Column1 = New-Object System.Data.DataColumn VM-Name,([string])
    $Column2 = New-Object System.Data.DataColumn Snapshot-Name,([string])
    $Column3 = New-Object System.Data.DataColumn Creation-Time,([string])
    $Results.Columns.Add($Column1)
    $Results.Columns.Add($Column2)
    $Results.Columns.Add($Column3)

# Find VM for each snapshot and export to table

        foreach ($Snapshot in $AllNTNXSnapshots) {
        $VMUuid = $Snapshot.vmUuid
        $VMname = ($AllNTNXVM |  Where-Object {$_.Uuid -eq $VMUuid}).vmName
        $SnapshotName = $Snapshot.snapshotName
        $CreationTimeStamp = ($Snapshot.createdTime)/1000
        $CreationTime = (Get-Date '1/1/1970').AddMilliseconds($CreationTimeStamp)
        $SnapshotCreationTime = $CreationTime.ToLocalTime()

        if ($VMname -eq $in_vmname){

        $Row = $Results.NewRow()
        $Row."VM-Name" = $VMname
        $Row."Snapshot-Name" = $SnapshotName
        $Row."Creation-Time" = $SnapshotCreationTime
        $Results.Rows.Add($Row)
         }
        }

    # Present results
   $Results | Sort-Object { $_."Creation-Time" -as [datetime] } | Format-Table
# -------------------------------
        Start-Sleep -Seconds 5

        disconnect 
       
       }
    }

        ""
         Write-Host 'No VM by that name, please verify and try again.'

            Start-Sleep -Seconds 5

disconnect

}



function CreateSnap {

#==============================================================
# Validates VM exists
#==============================================================

foreach ($VM in $AllNTNXVM) {

    if ($VM.vmName -eq $in_vmname){
       
        #==============================================================
        # Define snapshot name from external user script (VMname-Snapshotname)
        #==============================================================

        $snap_name = New-Object psobject -Property @{
        vm = $in_vmname
        snap = $in_snap_name
        }

        $snapshotname = "$($snap_name.vm)-$($snap_name.snap)"

        #==============================================================
        # Validates snapshot name does not already exist
        #==============================================================

        foreach ($Snapshot in $AllNTNXSnapshots) {
       
        if ($Snapshot.snapshotName -eq $snapshotname) {

        ""

        Write-Host 'A snapshot with that name already exists. Please use a different name.'

        Start-Sleep -Seconds 5

        disconnect

             }
        
        }
       
        #==============================================================
        # Creates new snapshot
        #==============================================================
    
        ""
        Write-Host 'Creating new snapshot' $snapshotname

        #create snapshot
        $snap = new-ntnxobject -Name SnapshotSpecDTO
        $snap.vmuuid = $vmUuid
        $snap.snapshotname = $snapshotname

        New-NTNXSnapshot -SnapshotSpecs $snap

        ""

        Write-Host 'Created snapshot:' $snapshotname

        ""
        Start-Sleep -Seconds 5

        disconnect 
  
     }  
        
   }
        ""
         Write-Host 'No VM by that name, please verify and try again.'

            Start-Sleep -Seconds 5

disconnect
}


function RestoreSnap {

#==============================================================
# Validates snapshot exists and restore when match found
#==============================================================
 foreach ($Snapshot in $AllNTNXSnapshots) {
       
        if ($Snapshot.snapshotName -eq $rs_snap_name) {
        ""
        Write-Host 'Restoring to snapshot' $rs_snap_name

$vmUuid = ($AllNTNXSnapshots | Where {$_.snapshotName -eq $rs_snap_name}).vmUuid
$Uuid = ($AllNTNXSnapshots |  Where {$_.snapshotName -eq $rs_snap_name}).uuid
$restore_snap = ($AllNTNXSnapshots |  Where {$_.snapshotName -eq $rs_snap_name}).snapshotName
$restored_vm = ($AllNTNXVM |  Where {$_.uuid -eq $vmUuid}).vmName

restore-ntnxvirtualmachine -Vmid $vmUuid  -Snapshotuuid $Uuid

Start-Sleep -s 20
""
Write-Host 'VM' $restored_vm' restored to' $restore_snap

""
        Start-Sleep -Seconds 5

        disconnect
   }
     
}


#==============================================================
# Snapshot not found action
#==============================================================

Write-Host 'Snapshot' $rs_snap_name 'not found  please verify and try again. '

       Start-Sleep -s 5

disconnect

}



function DeleteSnap {

#==============================================================
# Validates snapshot exists
#==============================================================

foreach ($Snapshot in $AllNTNXSnapshots) {
       
        if ($Snapshot.snapshotName -eq $rm_snap_name) {

$vmUuid = ($AllNTNXSnapshots | Where {$_.snapshotName -eq $rm_snap_name}).vmUuid
$Uuid = ($AllNTNXSnapshots |  Where {$_.snapshotName -eq $rm_snap_name}).uuid
$delete_snap = ($AllNTNXSnapshots |  Where {$_.snapshotName -eq $rm_snap_name}).snapshotName
$target_vm = ($AllNTNXVM |  Where {$_.uuid -eq $vmUuid}).vmName


#==============================================================
# Confirm delete - case sensetive answer required
#==============================================================


$confirm_delete = Read-Host 'Are you SURE you want to delete'$rm_snap_name'?'`n '(Enter DELETE to confirm)' 
""

Switch -CaseSensitive ($confirm_delete)
        { 
DELETE {Write-Host 'Proceeding with deletion of'$rm_snap_name ; Start-Sleep -s 5 ; Break }
Default {Write-Host 'Response not DELETE - cancelling deletion, Please try again'; Start-Sleep -s 5; exit}
        } 


#==============================================================
# Deletes snapshot
#==============================================================

remove-ntnxsnapshot -Uuid $Uuid

""
Write-Host $delete_snap' deleted from ' $target_vm 'VM'

""
        Start-Sleep -Seconds 5

        disconnect
  }
}
    Write-Host 'Snapshot' $rm_snap_name 'not found, please verify and try again.'

       Start-Sleep -s 5

disconnect  
}

# Disconnect from Nutanix Clusters
function disconnect {

    foreach ($Cluster in $NTNXCluster) {
        if (Get-NTNXCluster -ErrorAction SilentlyContinue) {
            Disconnect-NTNXCluster -Server $Cluster
        }
    }
exit
}

#==============================================================
# Executes appropriate function based on user's input
#==============================================================

Switch -CaseSensitive ($user_action)
{ 
List_Snaps {ListSnap}
Create_Snap {CreateSnap}
Restore_Snap {RestoreSnap}
Delete_Snap {DeleteSnap}
}



