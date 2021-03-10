[all]
%{ for ip in servers~}
${ip}
%{ endfor ~}

[all:vars]
ansible_connection=ssh
ansible_user=automation
