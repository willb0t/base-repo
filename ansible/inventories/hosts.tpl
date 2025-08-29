[gitlab_servers]
${vm_name} ansible_host=${vm_ip} ansible_user=${ssh_username} ansible_ssh_private_key_file=${ssh_key_file}

[gitlab_servers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
