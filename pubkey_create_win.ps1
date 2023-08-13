ssh-keygen

# By default the ssh-agent service is disabled. Configure it to start automatically.
# Make sure you're running as an Administrator.
Get-Service ssh-agent | Set-Service -StartupType Automatic

# Start the service
Start-Service ssh-agent

# This should return a status of Running
Get-Service ssh-agent

$key_pair_name = read-host "Enter the name used for key pair:"
$username = "Enter username on remote PC:"
$remote_ip = "Enter IP of remote PC"
# Now load your key files into ssh-agent
ssh-add $env:USERPROFILE\.ssh\$key_pair_name

cat "~/.ssh/$key_pair_name.pub" | ssh "$username@$remote_ip" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"