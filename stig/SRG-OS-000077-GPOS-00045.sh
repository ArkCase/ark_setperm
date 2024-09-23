#!/bin/bash
set -euo pipefail

cat <<-EOF
STIG Remediation script for:

cis-csc         1, 12, 15, 16, 5
cjis            5.6.2.1.1
cobit5          DSS05.04, DSS05.05, DSS05.07, DSS05.10, DSS06.03, DSS06.10
cui             3.5.8
disa            CCI-000200
isa-62443-2009  4.3.3.2.2, 4.3.3.5.1, 4.3.3.5.2, 4.3.3.6.1, 4.3.3.6.2, 4.3.3.6.3, 4.3.3.6.4,
                4.3.3.6.5, 4.3.3.6.6, 4.3.3.6.7, 4.3.3.6.8, 4.3.3.6.9, 4.3.3.7.2, 4.3.3.7.4
isa-62443-2013  SR 1.1, SR 1.10, SR 1.2, SR 1.3, SR 1.4, SR 1.5, SR 1.7, SR 1.8, SR 1.9, SR 2.1
iso27001-2013   A.18.1.4, A.7.1.1, A.9.2.1, A.9.2.2, A.9.2.3, A.9.2.4, A.9.2.6, A.9.3.1, A.9.4.2, A.9.4.3
nist            IA-5(f), IA-5(1)(e)
nist-csf        PR.AC-1, PR.AC-6, PR.AC-7
pcidss          Req-8.2.5
os-srg          SRG-OS-000077-GPOS-00045
stigid          UBTU-22-611050
cis             5.4.3
anssi           R31
pcidss4         8.3.7
EOF

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}\n' "libpam-runtime" 2>/dev/null | grep -q installed; then

    var_password_pam_unix_remember="5"
    
    if [ -e "/etc/pam.d/common-password" ] ; then
        valueRegex="$var_password_pam_unix_remember" defaultValue="$var_password_pam_unix_remember"
        # non-empty values need to be preceded by an equals sign
        [ -n "${valueRegex}" ] && valueRegex="=${valueRegex}"
        # add an equals sign to non-empty values
        [ -n "${defaultValue}" ] && defaultValue="=${defaultValue}"
    
        # fix 'type' if it's wrong
        if grep -q -P "^\\s*(?"'!'"password\\s)[[:alnum:]]+\\s+[[:alnum:]]+\\s+pam_unix.so" < "/etc/pam.d/common-password" ; then
            sed --follow-symlinks -i -E -e "s/^(\\s*)[[:alnum:]]+(\\s+[[:alnum:]]+\\s+pam_unix.so)/\\1password\\2/" "/etc/pam.d/common-password"
        fi
    
        # fix 'control' if it's wrong
        if grep -q -P "^\\s*password\\s+(?"'!'"\[success=[[:alnum:]].*\])[[:alnum:]]+\\s+pam_unix.so" < "/etc/pam.d/common-password" ; then
            sed --follow-symlinks -i -E -e "s/^(\\s*password\\s+)[[:alnum:]]+(\\s+pam_unix.so)/\\1\[success=[[:alnum:]].*\]\\2/" "/etc/pam.d/common-password"
        fi
    
        # fix the value for 'option' if one exists but does not match 'valueRegex'
        if grep -q -P "^\\s*password\\s+\[success=[[:alnum:]].*\]\\s+pam_unix.so(\\s.+)?\\s+remember(?"'!'"${valueRegex}(\\s|\$))" < "/etc/pam.d/common-password" ; then
            sed --follow-symlinks -i -E -e "s/^(\\s*password\\s+\[success=[[:alnum:]].*\]\\s+pam_unix.so(\\s.+)?\\s)remember=[^[:space:]]*/\\1remember${defaultValue}/" "/etc/pam.d/common-password"
    
        # add 'option=default' if option is not set
        elif grep -q -E "^\\s*password\\s+\[success=[[:alnum:]].*\]\\s+pam_unix.so" < "/etc/pam.d/common-password" &&
                grep    -E "^\\s*password\\s+\[success=[[:alnum:]].*\]\\s+pam_unix.so" < "/etc/pam.d/common-password" | grep -q -E -v "\\sremember(=|\\s|\$)" ; then
    
            sed --follow-symlinks -i -E -e "s/^(\\s*password\\s+\[success=[[:alnum:]].*\]\\s+pam_unix.so[^\\n]*)/\\1 remember${defaultValue}/" "/etc/pam.d/common-password"
        # add a new entry if none exists
        elif ! grep -q -P "^\\s*password\\s+\[success=[[:alnum:]].*\]\\s+pam_unix.so(\\s.+)?\\s+remember${valueRegex}(\\s|\$)" < "/etc/pam.d/common-password" ; then
            echo "password \[success=[[:alnum:]].*\] pam_unix.so remember${defaultValue}" >> "/etc/pam.d/common-password"
        fi
    else
        echo "/etc/pam.d/common-password doesn't exist" >&2
    fi
    
else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi
