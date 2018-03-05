#!/bin/sh

firewall_open_service()
{
  for t in FW_CONFIGURATIONS_EXT FW_CONFIGURATIONS_DMZ FW_CONFIGURATIONS_INT; do
    sudo sed -e "s/^${t}=\"\(.*\)\"/${t}=\"\1 $1\"/g" \
         -i /etc/sysconfig/SuSEfirewall2
  done
  sudo systemctl restart SuSEfirewall2
}

postfix_install()
{
  sudo zypper -n in postfix

  sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.orig

  # shellcheck disable=SC2016
  cat <<EOF | sudo tee /etc/postfix/main.cf
myhostname = ${1}
mydomain = ${2}
myorigin = \$myhostname.\$mydomain
mydestination = localhost, localhost.\$mydomain, \$myhostname, \$mydomain, \$myorigin
queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/lib/postfix
data_directory = /var/lib/postfix
mail_owner = postfix
inet_interfaces = all
local_recipient_maps = unix:passwd.byname \$alias_maps
unknown_local_recipient_reject_code = 550
mynetworks_style = subnet
mynetworks = 127.0.0.0/8
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
smtpd_banner = \$myhostname ESMTP  (\$mail_version)
debug_peer_level = 2
debugger_command =
         PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin
         ddd \$daemon_directory/\$process_name \$process_id & sleep 5
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = maildrop
inet_protocols = ipv4
EOF

  sudo newaliases
  sudo systemctl restart postfix

  firewall_open_service smtp

  sudo zypper -n in mutt
}

postfix_main()
{
  postfix_install localhost localdomain           # localhost only.
  # postfix_install ${YOUR_HOSTNAME} ${YOUR_DOMAIN} # your network.
}

postfix_main
