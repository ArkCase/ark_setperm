#!/bin/bash
set -euo pipefail

cat <<-EOF
STIG Remediation script for:

cis-csc         1, 12, 15, 16
cjis            5.5.3
cobit 5         DSS05.04, DSS05.10, DSS06.10
cui             3.1.8
disa            CCI-000044, CCI-002236, CCI-002237, CCI-002238
isa-62443-2009  4.3.3.6.1, 4.3.3.6.2, 4.3.3.6.3, 4.3.3.6.4, 4.3.3.6.5, 4.3.3.6.6, 4.3.3.6.7, 4.3.3.6.8, 4.3.3.6.9
isa-62443-2013  SR 1.1, SR 1.10, SR 1.2, SR 1.5, SR 1.7, SR 1.8, SR 1.9
ism             0421, 0422, 0431, 0974, 1173, 1401, 1504, 1505, 1546, 1557, 1558, 1559, 1560, 1561
iso27001-2013   A.18.1.4, A.9.2.1, A.9.2.4, A.9.3.1, A.9.4.2, A.9.4.3
nist            CM-6(a), AC-7(a)
nist-csf        PR.AC-7
ospp            FIA_AFL.1
pcidss          Req-8.1.6
os-srg          SRG-OS-000329-GPOS-00128, SRG-OS-000021-GPOS-00005
stigid          UBTU-22-411045
cis             5.4.2
anssi           R31
pcidss4         8.3.4
EOF

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}\n' "libpam-runtime" 2>/dev/null | grep -q installed; then
    
    var_accounts_passwords_pam_faillock_deny="4"
    
    
    if [ -f /usr/bin/authselect ]; then
        if ! authselect check; then
    echo "
    authselect integrity check failed. Remediation aborted!
    This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
    It is not recommended to manually edit the PAM files when authselect tool is available.
    In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
    exit 1
    fi
    authselect enable-feature with-faillock
    
    authselect apply-changes -b
    else
        
    pam_file="/etc/pam.d/common-auth"
    if ! grep -qE '^\s*auth\s+required\s+pam_faillock\.so\s+preauth.*$' "$pam_file" ; then
        # insert at the top
        sed -i --follow-symlinks '/^# here are the per-package modules/i auth        required      pam_faillock.so preauth' "$pam_file"
    fi
    if ! grep -qE '^\s*auth\s+\[default=die\]\s+pam_faillock\.so\s+authfail.*$' "$pam_file" ; then
    
        num_lines=$(sed -n 's/^\s*auth.*success=\([1-9]\).*pam_unix\.so.*/\1/p' "$pam_file")
        if [ ! -z "$num_lines" ]; then
    
            # Add pam_faillock (authfail) module below pam_unix, skipping N-1 lines, where N is
            # the number of jumps in the pam_unix success=N statement. Ignore commented and empty lines.
    
            append_position=$(cat -n "${pam_file}" \
                              | grep -P "^\s+\d+\s+auth\s+.*$" \
                              | grep -w "pam_unix.so" -A $(( num_lines - 1 )) \
                              | tail -n 1 | cut -f 1 | tr -d ' '
                             )
            sed -i --follow-symlinks ''${append_position}'a auth        [default=die]      pam_faillock.so authfail' "$pam_file"
        else
            sed -i --follow-symlinks '/^auth.*pam_unix\.so.*/a auth        [default=die]      pam_faillock.so authfail' "$pam_file"
        fi
    fi
    if ! grep -qE '^\s*auth\s+sufficient\s+pam_faillock\.so\s+authsucc.*$' "$pam_file" ; then
        sed -i --follow-symlinks '/^auth.*pam_faillock\.so.*authfail.*/a auth        sufficient      pam_faillock.so authsucc' "$pam_file"
    fi
    
    pam_file="/etc/pam.d/common-account"
    if ! grep -qE '^\s*account\s+required\s+pam_faillock\.so.*$' "$pam_file" ; then
        echo 'account   required     pam_faillock.so' >> "$pam_file"
    fi
    
    fi
    
    AUTH_FILES=("/etc/pam.d/common-auth")
    
    FAILLOCK_CONF="/etc/security/faillock.conf"
    if [ -f $FAILLOCK_CONF ]; then
        regex="^\s*deny\s*="
        line="deny = $var_accounts_passwords_pam_faillock_deny"
        if ! grep -q $regex $FAILLOCK_CONF; then
            echo $line >> $FAILLOCK_CONF
        else
            sed -i --follow-symlinks 's|^\s*\(deny\s*=\s*\)\(\S\+\)|\1'"$var_accounts_passwords_pam_faillock_deny"'|g' $FAILLOCK_CONF
        fi
        for pam_file in "${AUTH_FILES[@]}"
        do
            if [ -e "$pam_file" ] ; then
                PAM_FILE_PATH="$pam_file"
                if [ -f /usr/bin/authselect ]; then
                    
                    if ! authselect check; then
                    echo "
                    authselect integrity check failed. Remediation aborted!
                    This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
                    It is not recommended to manually edit the PAM files when authselect tool is available.
                    In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
                    exit 1
                    fi
    
                    CURRENT_PROFILE=$(authselect current -r | awk '{ print $1 }')
                    # If not already in use, a custom profile is created preserving the enabled features.
                    if [[ ! $CURRENT_PROFILE == custom/* ]]; then
                        ENABLED_FEATURES=$(authselect current | tail -n+3 | awk '{ print $2 }')
                        authselect create-profile hardening -b $CURRENT_PROFILE
                        CURRENT_PROFILE="custom/hardening"
                        
                        authselect apply-changes -b --backup=before-hardening-custom-profile
                        authselect select $CURRENT_PROFILE
                        for feature in $ENABLED_FEATURES; do
                            authselect enable-feature $feature;
                        done
                        
                        authselect apply-changes -b --backup=after-hardening-custom-profile
                    fi
                    PAM_FILE_NAME=$(basename "$pam_file")
                    PAM_FILE_PATH="/etc/authselect/$CURRENT_PROFILE/$PAM_FILE_NAME"
    
                    authselect apply-changes -b
                fi
                
            if grep -qP "^\s*auth\s.*\bpam_faillock.so\s.*\bdeny\b" "$PAM_FILE_PATH"; then
                sed -i -E --follow-symlinks "s/(.*auth.*pam_faillock.so.*)\bdeny\b=?[[:alnum:]]*(.*)/\1\2/g" "$PAM_FILE_PATH"
            fi
                if [ -f /usr/bin/authselect ]; then
                    
                    authselect apply-changes -b
                fi
            else
                echo "$pam_file was not found" >&2
            fi
        done
    else
        for pam_file in "${AUTH_FILES[@]}"
        do
            if ! grep -qE '^\s*auth.*pam_faillock\.so (preauth|authfail).*deny' "$pam_file"; then
                sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*preauth.*silent.*/ s/$/ deny='"$var_accounts_passwords_pam_faillock_deny"'/' "$pam_file"
                sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*authfail.*/ s/$/ deny='"$var_accounts_passwords_pam_faillock_deny"'/' "$pam_file"
            else
                sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*preauth.*silent.*\)\('"deny"'=\)[0-9]\+\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_deny"'\3/' "$pam_file"
                sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*authfail.*\)\('"deny"'=\)[0-9]\+\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_deny"'\3/' "$pam_file"
            fi
        done
    fi
    
else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi
