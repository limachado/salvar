if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] 
then
   echo -e "Sintaxe: $0 [ USER ] [ PASSWORD ] [ SERVER ]  \n"
   exit 3
else
   USER=$1
   PASSWORD=$2
   SERVER=$3
   
fi

echo '############################################################'
echo '# Script criado pelo time de Devops para automação Windows #'
echo '# Cria o arquivo do inventario para ansible                #'    
echo '############################################################'

echo '[windows]'> hosts
echo ${SERVER}>>hosts
echo ''>>hosts
echo '[windows:vars]'>>hosts
echo 'ansible_user='${USER}>>hosts
echo 'ansible_password='${PASSWORD}>>hosts
echo 'ansible_port=5985'>>hosts
echo 'ansible_connection=winrm'>>hosts

echo '############################################################'
echo '# cria o playbook                                          #'
echo '############################################################'
sleep 5

echo '---
- name: configurar ambiente
  hosts: all 

  tasks:
  - name: instalando chocolatey
    win_shell: |
      @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
  
  - name: instalando pyton
    win_chocolatey:
      name: python
      version: '3.6.5'
      state: present
      force: yes

  - name: Criando um usuário
    win_user:
      name: Devops 
      password: Zaq1@wsx
      password_never_expires: yes
      state: present
      groups:
        - Administradores
        
  - name: criar pasta
    win_file: path=C:\Windows\Temp\AUTOMACAO state=directory  

  - name: variavel de ambiente
    win_environment:
      state: present
      name: DIRAUTOMACAO
      value: C:\Windows\Temp\AUTOMACAO 
      level: machine'>preparaAmbiente.yml


echo '############################################################'
echo '# Habilita WINRM no alvo                                   #'    
echo '############################################################'

sleep 5
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c winrm quickconfig -q'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c winrm quickconfig -transport:http'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c winrm set winrm/config @{MaxTimeoutms="1800000"}'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"}'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c winrm set winrm/config/service @{AllowUnencrypted="true"}'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c winrm set winrm/config/service/auth @{Basic="true"}'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c winrm set winrm/config/client/auth @{Basic="true"}'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c winrm set winrm/config/listener?Address=*+Transport=HTTP @{Port="5985"}'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" profile=public protocol=tcp localport=5985 remoteip=localsubnet new remoteip=any'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c net stop winrm '
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c sc config winrm start= auto'
psexec.py $USER:$PASSWORD@$SERVER 'cmd.exe /c net start winrm' 
echo '############################################################'
echo '# executa o ansible                                        #'
echo '############################################################'
sleep 5
ansible-playbook -i hosts preparaAmbiente.yml
rm hosts 
rm preparaAmbiente.yml
 
