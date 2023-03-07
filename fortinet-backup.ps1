$fortigates = Import-Csv fortigates.csv

foreach ($fortigate in $fortigates) {
    $credential = Get-Credential -UserName $fortigate.username
    $SSHSession = New-SSHSession -ComputerName $fortigate.ip -Port $fortigate.port_ssh -Credential $credential -AcceptKey -Verbose

    if ($SSHSession.Connected) {

        $console_mode = Invoke-SSHCommand -SSHSession $SSHSession -Command 'get system console | grep -i output'
        # checking the console mode (should be standard but default is more)
        if ($console_mode.output -match '.standard.') {
            Write-Host('console mode is standard');
        }
        else {
            Write-Host('could not find standard in result')
            $SSHStream = New-SSHShellStream -SSHSession $SSHSession
            $SSHStream.WriteLine('config system console')
            sleep 1 # because without this it didnt work for me
            $SSHStream.WriteLine('set output standard')
            sleep 1 # because without this it didnt work for me
            $SSHStream.WriteLine('end')
            $SSHStream.Read()
        }

        $SSHResponse = Invoke-SSHCommand -SSHSession $SSHSession -Command 'show';
        $savePath = './{0}.cfg' -f $fortigate.name
        $SSHResponse.output | Out-File -Encoding unicode -FilePath $savePath
        # > ${fortigate.name}.cfg
    }
}