#!/bin/bash -x
exec > /tmp/part-001.log 2>&1

%{ if create_ssh_user }
if sed 's/"//g' /etc/os-release |grep -e '^NAME=CentOS' -e '^NAME=Fedora' -e '^NAME=Red'; then
  useradd ${ssh_user_name}
  usermod -a -G wheel ${ssh_user_name}
  %{ if ssh_user_pass != "" }
  echo "${ssh_user_pass}" | passwd --stdin ${ssh_user_name}
  %{ endif }
elif sed 's/"//g' /etc/os-release |grep -e '^NAME=Mint' -e '^NAME=Ubuntu' -e '^NAME=Debian'; then
  useradd ${ssh_user_name}
  usermod -a -G sudo ${ssh_user_name}
  %{ if ssh_user_pass != "" }
  echo "${ssh_user_pass}" | passwd --stdin ${ssh_user_name}
  %{ endif }
elif sed 's/"//g' /etc/os-release |grep -e '^NAME=SLES'; then
  if ! grep $(hostname) /etc/hosts; then
    echo "127.0.0.1 $(hostname)" >> /etc/hosts
  fi
  %{ if ssh_user_pass != "" }
  pass=$(perl -e 'print crypt($ARGV[0], "password")' ${ssh_user_pass})
  useradd -U -m -p $pass ${ssh_user_name}
  %{ else }
  useradd -U -m ${ssh_user_name}
  %{ endif }
fi

printf >"/etc/sudoers.d/${ssh_user_name}" '%s    ALL= NOPASSWD: ALL\n' "${ssh_user_name}"


%{ if ssh_user_public_key != "" }
mkdir -p /home/${ssh_user_name}/.ssh
chmod 700  /home/${ssh_user_name}/.ssh
cat << EOF >>/home/${ssh_user_name}/.ssh/authorized_keys
${ssh_user_public_key}
EOF
chmod 600 /home/${ssh_user_name}/.ssh/authorized_keys
chown -R ${ssh_user_name}:${ssh_user_name} /home/${ssh_user_name}/.ssh
%{ else }
sed -i  's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
%{ endif }
%{ endif }
