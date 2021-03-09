[all]
%{ for ip in servers~}
${ip} ansible_host={ip}
%{ endfor ~}
