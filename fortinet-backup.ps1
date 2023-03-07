$fortigates = Import-Csv fortigates.csv

foreach ($fortigate in $fortigates) {
    $credential = Get-Credential -UserName $fortigate.username
    $SSHSession = New-SSHSession -ComputerName $fortigate.ip -Port $fortigate.port_ssh -Credential $credential -AcceptKey -Verbose

    if ($SSHSession.Connected) {
        # result output of system console mode check
        $console_mode = Invoke-SSHCommand -SSHSession $SSHSession -Command 'get system console | grep -i output'

        # checking the console mode (should be standard but default is more)
        if ($console_mode.output -match '.standard.') {
            # if standard, continue
            Write-Host('console mode is standard');
        }
        else {
            # if not standard, change to standard
            Write-Host('could not find standard in result')
            $SSHStream = New-SSHShellStream -SSHSession $SSHSession
            $SSHStream.WriteLine('config system console')
            $SSHStream.WriteLine('set output standard')
            $SSHStream.WriteLine('end')
            $SSHStream.Read()
        }

        # get current date based on year, month, day - hours minutes seconds.
        $date = Get-Date -Format yyyyMMdd-HHmmss
        # get the current configuration by executing the show command
        $SSHResponse = Invoke-SSHCommand -SSHSession $SSHSession -Command 'show';
        # set filename to $fortgate.name and add the date
        $savePath = './{0}-{1}.cfg' -f $fortigate.name,$date
        # store the output of the show command to a file with the filepath above
        $SSHResponse.output | Out-File -Encoding unicode -FilePath $savePath
    }
}