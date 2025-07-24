#!/bin/bash
curl -k  -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}
setenforce 0

# cat > /tmp/requirements.yml << EOF
# ---
# - name: vscode-server
#   src: https://github.com/redhat-cop/agnosticd
#   scm: git
#   version: development
#   path: ansible/roles/vscode-server
# EOF


# cat >> /tmp/vscode.yml << EOF
# - hosts: localhost
#   become: true
#   tasks:
#     - name: Configure VS Code Server
#       include_role:
#         name: vscode-server
#       vars:
#         vscode_server_version: "4.95.3"
#         vscode_server_rpm_url: >-
#           https://github.com/coder/code-server/releases/download/v{{ vscode_server_version }}/code-server-{{ vscode_server_version }}-amd64.rpm
#         install_vscode_server: true
#         vscode_server_install_nginx: true
#         vscode_use_automationcontroller_nginx: false
#         vscode_server_nginx_https_port: 8443
#         vscode_server_ansible_become: true
#         vscode_user_workspace_path: "/home/{{ student_name }}"
#         vscode_auth_type: password
#         vscode_user_name: "{{ student_name }}"
#         vscode_user_password: "{{ common_password }}"
#         vscode_server_hostname: "{{ groups['bastions'][0].split('.')[0] }}.{{ guid }}.{{ sandbox_zone }}"
#         vscode_ansible_python_interpreter: /usr/libexec/platform-python
#         vscode_server_default_extensions: []
#         vscode_server_extension_urls:
#           - https://github.com/ansible/workshops/raw/devel/files/bierner.markdown-preview-github-styles-0.1.6.vsix
#           - https://github.com/ansible/workshops/raw/devel/files/hnw.vscode-auto-open-markdown-preview-0.0.4.vsix
#           - https://github.com/ansible/workshops/raw/devel/files/redhat.ansible-0.4.5.vsix
#         vscode_server_additional_settings: |
#           "files.exclude": {
#             "**/.git": true,
#             "**/.kube": true,
#             "**/.bash*": true,
#             "**/.vim*": true,
#             "**/.ssh": true,
#             "**/.vscode": true,
#             "**/.local": true,
#             "**/.config": true,
#             "**/.ansible": true,
#             "**/.cache": true },
#           "security.workspace.trust.enabled": false
# EOF

# dnf install ansible-core nano git -y

# ansible-galaxy install -r /tmp/requirements.yml
# ansible-playbook /tmp/vscode.yml








# cat > /tmp/test.yml << EOF

# ---
# - name: Install VS Code Server on RHEL
#   hosts: localhost
#   become: yes
#   vars:
#     vscode_server_version: "4.22.1"
#     vscode_server_user: "vscode"
#     vscode_server_password: "ansible123!"
#     vscode_server_port: 8080
#     vscode_server_home: "/opt/code-server"

#   tasks:
#     - name: Create vscode user
#       user:
#         name: "{{ vscode_server_user }}"
#         system: yes
#         shell: /bin/bash
#         home: "/home/{{ vscode_server_user }}"
#         create_home: yes

#     - name: Install required packages
#       dnf:
#         name:
#           - curl
#           - wget
#           - tar
#           - gzip
#           - unzip
#         state: present

#     - name: Create VS Code Server directory
#       file:
#         path: "{{ vscode_server_home }}"
#         state: directory
#         owner: "{{ vscode_server_user }}"
#         group: "{{ vscode_server_user }}"
#         mode: '0755'

#     - name: Download VS Code Server
#       get_url:
#         url: "https://github.com/coder/code-server/releases/download/v{{ vscode_server_version }}/code-server-{{ vscode_server_version }}-linux-amd64.tar.gz"
#         dest: "/tmp/code-server-{{ vscode_server_version }}-linux-amd64.tar.gz"
#         mode: '0644'

#     - name: Extract VS Code Server
#       unarchive:
#         src: "/tmp/code-server-{{ vscode_server_version }}-linux-amd64.tar.gz"
#         dest: "/tmp"
#         remote_src: yes
#         owner: "{{ vscode_server_user }}"
#         group: "{{ vscode_server_user }}"

#     - name: Move VS Code Server to installation directory
#       shell: |
#         mv /tmp/code-server-{{ vscode_server_version }}-linux-amd64/* {{ vscode_server_home }}/
#         chown -R {{ vscode_server_user }}:{{ vscode_server_user }} {{ vscode_server_home }}

#     - name: Create VS Code Server config directory
#       file:
#         path: "/home/{{ vscode_server_user }}/.config/code-server"
#         state: directory
#         owner: "{{ vscode_server_user }}"
#         group: "{{ vscode_server_user }}"
#         mode: '0755'

#     - name: Create VS Code Server configuration file
#       copy:
#         content: |
#           bind-addr: 0.0.0.0:{{ vscode_server_port }}
#           auth: password
#           password: {{ vscode_server_password }}
#           cert: false
#         dest: "/home/{{ vscode_server_user }}/.config/code-server/config.yaml"
#         owner: "{{ vscode_server_user }}"
#         group: "{{ vscode_server_user }}"
#         mode: '0600'

#     - name: Create systemd service file
#       copy:
#         content: |
#           [Unit]
#           Description=code-server
#           After=network.target

#           [Service]
#           Type=exec
#           ExecStart={{ vscode_server_home }}/bin/code-server
#           Restart=always
#           User={{ vscode_server_user }}
#           Group={{ vscode_server_user }}
#           Environment=PASSWORD={{ vscode_server_password }}

#           [Install]
#           WantedBy=multi-user.target
#         dest: /etc/systemd/system/code-server.service
#         mode: '0644'

#     - name: Reload systemd daemon
#       systemd:
#         daemon_reload: yes

#     - name: Enable and start VS Code Server service
#       systemd:
#         name: code-server
#         enabled: yes
#         state: started

#     - name: Clean up downloaded files
#       file:
#         path: "/tmp/code-server-{{ vscode_server_version }}-linux-amd64.tar.gz"
#         state: absent

#     - name: Display access information
#       debug:
#         msg: 
#           - "VS Code Server has been installed and started"
#           - "Access it at: http://{{ ansible_default_ipv4.address }}:{{ vscode_server_port }}"
#           - "Password: {{ vscode_server_password }}"
#           - "Service status: systemctl status code-server"

# EOF

# ansible-playbook /tmp/test.yml
