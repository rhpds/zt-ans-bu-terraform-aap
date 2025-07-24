#!/bin/bash
curl -k  -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}
setenforce 0


cat > /tmp/test.yml << EOF

---
- name: Install VS Code Server on RHEL
  hosts: localhost
  become: yes
  vars:
    vscode_server_version: "4.22.1"
    vscode_server_user: "vscode"
    vscode_server_password: "ansible123!"
    vscode_server_port: 8080
    vscode_server_home: "/opt/code-server"

  tasks:
    - name: Create vscode user
      user:
        name: "{{ vscode_server_user }}"
        system: yes
        shell: /bin/bash
        home: "/home/{{ vscode_server_user }}"
        create_home: yes

    - name: Install required packages
      dnf:
        name:
          - curl
          - wget
          - tar
          - gzip
          - unzip
        state: present

    - name: Create VS Code Server directory
      file:
        path: "{{ vscode_server_home }}"
        state: directory
        owner: "{{ vscode_server_user }}"
        group: "{{ vscode_server_user }}"
        mode: '0755'

    - name: Download VS Code Server
      get_url:
        url: "https://github.com/coder/code-server/releases/download/v{{ vscode_server_version }}/code-server-{{ vscode_server_version }}-linux-amd64.tar.gz"
        dest: "/tmp/code-server-{{ vscode_server_version }}-linux-amd64.tar.gz"
        mode: '0644'

    - name: Extract VS Code Server
      unarchive:
        src: "/tmp/code-server-{{ vscode_server_version }}-linux-amd64.tar.gz"
        dest: "/tmp"
        remote_src: yes
        owner: "{{ vscode_server_user }}"
        group: "{{ vscode_server_user }}"

    - name: Move VS Code Server to installation directory
      shell: |
        mv /tmp/code-server-{{ vscode_server_version }}-linux-amd64/* {{ vscode_server_home }}/
        chown -R {{ vscode_server_user }}:{{ vscode_server_user }} {{ vscode_server_home }}

    - name: Create VS Code Server config directory
      file:
        path: "/home/{{ vscode_server_user }}/.config/code-server"
        state: directory
        owner: "{{ vscode_server_user }}"
        group: "{{ vscode_server_user }}"
        mode: '0755'

    - name: Create VS Code Server configuration file
      copy:
        content: |
          bind-addr: 0.0.0.0:{{ vscode_server_port }}
          auth: password
          password: {{ vscode_server_password }}
          cert: false
        dest: "/home/{{ vscode_server_user }}/.config/code-server/config.yaml"
        owner: "{{ vscode_server_user }}"
        group: "{{ vscode_server_user }}"
        mode: '0600'

    - name: Create systemd service file
      copy:
        content: |
          [Unit]
          Description=code-server
          After=network.target

          [Service]
          Type=exec
          ExecStart={{ vscode_server_home }}/bin/code-server
          Restart=always
          User={{ vscode_server_user }}
          Group={{ vscode_server_user }}
          Environment=PASSWORD={{ vscode_server_password }}

          [Install]
          WantedBy=multi-user.target
        dest: /etc/systemd/system/code-server.service
        mode: '0644'

    - name: Reload systemd daemon
      systemd:
        daemon_reload: yes

    - name: Enable and start VS Code Server service
      systemd:
        name: code-server
        enabled: yes
        state: started

    - name: Clean up downloaded files
      file:
        path: "/tmp/code-server-{{ vscode_server_version }}-linux-amd64.tar.gz"
        state: absent

    - name: Display access information
      debug:
        msg: 
          - "VS Code Server has been installed and started"
          - "Access it at: http://{{ ansible_default_ipv4.address }}:{{ vscode_server_port }}"
          - "Password: {{ vscode_server_password }}"
          - "Service status: systemctl status code-server"

EOF

ansible-playbook /tmp/test.yml
