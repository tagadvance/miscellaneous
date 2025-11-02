#!/bin/bash

source "$(dirname "$(readlink -f "$0")")/ntfy.sh"

##
## https://noted.lol/hdd-health-alerts-using-n8n-and-ntfy/
##

smartctl=/usr/sbin/smartctl
all_passed=true;

for d in $(lsblk -dn -o NAME); do
  status=$($smartctl --health /dev/$d | awk '/SMART overall-health/ {print $6}');
  if [[ "$status" != "PASSED" ]]; then
    all_passed=false;
    ntfy_critical homelab "$d: $status";
  fi

  if [[ $d == nvme* ]]; then
    tempC=$($smartctl --attributes /dev/$d | awk -F: '/Temperature/ {gsub(/ /,"",$2); print $2}');
    tempC=${tempC:-0};
    poh=$($smartctl --attributes /dev/$d | awk -F: '/Power On Hours/ {gsub(/ /,"",$2); print $2}');
    poh=${poh:-0};
  else
    reallocated=$($smartctl --attributes /dev/$d | awk '/Reallocated_Sector_Ct/ {print $10}');
    reallocated=${reallocated:-0};
    tempC=$($smartctl --attributes /dev/$d | awk '/Temperature_Celsius/ {print $10}');
    tempC=${tempC:-0};
    poh=$($smartctl --attributes /dev/$d | awk '/Power_On_Hours/ {print $10}');
    poh=${poh:-0};
    cps=$($smartctl --attributes /dev/$d | awk '/Current_Pending_Sector/ {print $10}');
    cps=${cps:-0};
    ou=$($smartctl --attributes /dev/$d | awk '/Offline_Uncorrectable/ {print $10}');
    ou=${ou:-0};
    if [[ $reallocated -gt 0 || $cps -gt 0 || $ou -gt 0 ]]; then
      all_passed=false;
      ntfy_warning homelab "$d: $status (Temp: ${tempC}C, POH: $poh, Reallocated: $reallocated CPS: $cps, OU: $ou)"
    fi;
  fi;
done;

if [[ "$1" != "--quiet" && $all_passed ]]; then
  ntfy_trace homelab "All drives are healthy.";
fi
