# script to get uptime for AD connected computers. if you have sccm agents installed they can provide the same data.
# there a number of ways to do this, this is just one of them. the script will write error messages if an object is not
# found in the AD but it will continue to run.
#
# use and run at your own risk!# 

Function Get-WmiCustom([string]$ComputerName, [string]$Namespace = "root\cimv2", [string]$Class, [int]$Authentication = -1, [string]$Filter = "", [int]$Timeout = 15)

{

$ConnectionOptions = new-object System.Management.ConnectionOptions

$ConnectionOptions.Authentication = $Authentication

$EnumerationOptions = new-object System.Management.EnumerationOptions

$timeoutseconds = new-timespan -seconds $timeout

$EnumerationOptions.set_timeout($timeoutseconds)

$assembledpath = "\\" + $computername + "\" + $namespace

$Scope = new-object System.Management.ManagementScope $assembledpath, $ConnectionOptions

$Scope.Connect()

$querystring = "SELECT LastBootUpTime FROM Win32_OperatingSystem"

if($Filter.Length -gt 0) {

$querystring += " WHERE " + $Filter

}

$query = new-object System.Management.ObjectQuery $querystring

$searcher = new-object System.Management.ManagementObjectSearcher

$searcher.set_options($EnumerationOptions)

$searcher.Query = $querystring

$searcher.Scope = $Scope

trap { $_ } $result = $searcher.get()

return $result

}
# correct searchbase parameters to match your environment

$computers = Get-AdComputer -Searchbase 'OU=XXX Servers,DC=XXXX,DC=XXXXX' -SearchScope 2 -Filter * -Verbose

$sysuptime = foreach ($computer in $computers) {

    $Computerobj = "" | select ComputerName, Uptime, LastReboot
    $wmi = Get-WmiCustom -ComputerName $computer.Name -Timeout 2
    $now = Get-Date
       #$boottime = [Management.ManagementDateTimeConverter]::ToDateTime($wmi.LastBootUpTime)
    $boottime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
       $uptime = $now - $boottime
       $d =$uptime.days
       $h =$uptime.hours
       $m =$uptime.Minutes
       $s = $uptime.Seconds
       $Computerobj.ComputerName = $computer.Name
       $Computerobj.Uptime = "$d Days $h Hours $m Min $s Sec"
       $Computerobj.LastReboot = $boottime
    $Computerobj
}

# set file directory that matches your environment, ensure that you have write permissions

$sysuptime |Sort-Object Uptime -Descending | Export-Csv C:\lastboottime.csv -Encoding Unicode -NoTypeInformation 
