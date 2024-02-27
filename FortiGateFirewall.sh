#!/bin/bash
# Author: Emin  Eyvazov

# 1) fortihitprimary.sh
scp -i /home/FG/fortikey USERNAME@HOSTNAME:sys_config /home/FG/forti.txt
sed -n '/config firewall policy/,/config firewall shaping-policy/ p' /home/FG/forti.txt | grep 'edit' >/home/FG/fortiedit.txt
grep 'edit[[:space:]]*[0-9]' /home/FG/fortiedit.txt >/home/FG/fortidigit.txt
sed 's/edit//g' /home/FG/fortidigit.txt >/home/FG/numberrule.txt
cp /home/FG/hitpaste.sh /home/FG/temphitpaste.sh
cp /home/FG/idxhitpaste.sh /home/FG/tempidxhitpaste.sh
cp /home/FG/zeropaste.sh /home/FG/tempzeropaste.sh
sh /home/FG/fortiapplyhit.sh
sh /home/FG/temphitpaste.sh >/home/FG/idlasthit.txt
grep -E 'idx:|last hit' /home/FG/idlasthit.txt >/home/FG/templast.txt
grep -A 1 -e 'idx:' /home/FG/templast.txt | awk '/last hit/ {print prev} {prev=$0}' | tail -n +1 >/home/FG/idx.txt
grep 'last hit:' /home/FG/templast.txt >/home/FG/lasthittemp.txt
sed -E 's/^.{43}(.*)/\1/' /home/FG/lasthittemp.txt > /home/FG/lasthit.txt
sed '$!N;/last hit/!P;D' /home/FG/templast.txt > /home/FG/zerotemp.txt
paste -d ' ' /home/FG/idx.txt /home/FG/lasthit.txt > /home/FG/primaryhit.txt
sh /home/FG/formathit.sh > /home/FG/oldhit.txt
sed 's/^.\{22\}//' /home/FG/oldhit.txt > /home/FG/idxhit.txt
sed 's/^.\{22\}//' /home/FG/zerotemp.txt > /home/FG/zero.txt
sh /home/FG/idxapply.sh
sh /home/FG/zeroapply.sh
awk 'length($0) != 92' /home/FG/tempidxhitpaste.sh > /home/FG/tempidx.sh
awk 'length($0) != 92' /home/FG/tempzeropaste.sh > /home/FG/tempzero.sh
sh /home/FG/tempidx.sh | grep 'edit\|name' | sed 's/edit//g' | sed 's/set name//g' > /home/FG/tempidx.txt
sh /home/FG/tempzero.sh | grep 'edit\|name' | sed 's/edit//g' | sed 's/set name//g' > /home/FG/tempzero.txt
sh /home/FG/fortihitempty.sh

# 2) formathit.sh
cat /home/FG/primaryhit.txt | while read line; do
    date_in_line=$(grep -oP "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}" <<< "$line")
    if [ -n "$date_in_line" ]; then
        timestamp=$(date -d "$date_in_line" +%s)
        current_time=$(date +%s)
        if ((current_time - timestamp > 90 * 24 * 60 * 60)); then
            awk -v d="$date_in_line" '{gsub(d, ""); print}' <<< "$line"
        fi
    fi
done

# 3) fortiapplyhit.sh
input_file="/home/FG/numberrule.txt"
output_file="/home/FG/temphitpaste.sh"
while IFS= read -r line; do
    line_number=$(grep -n "$line" "$input_file" | cut -d':' -f1)
    sed -i "${line_number}s/^.\{109\}/&$line/" "$output_file"
done < "$input_file"

# 4) fortihitempty.sh
#!/bin/bash
file1="/home/FG/tempidx.txt"
file2="/home/FG/tempzero.txt"
script_to_run="/home/FG/sendhit.sh"
# Check if either of the files is not empty
if [ -s "$file1" ] || [ -s "$file2" ] ; then
    # Run your script
    sh "$script_to_run"
else
    echo "Both files are empty or do not exist."
fi

# 5) hitpaste.sh
ssh -i /home/FG/fortikey USERNAME@HOSTNAME "diagnose firewall iprope show 00100004"

# 6) idxapply.sh
#!/bin/bash
input_file="/home/FG/idxhit.txt"
output_file="/home/FG/tempidxhitpaste.sh"
while IFS= read -r line; do
    line_number=$(grep -n "$line" "$input_file" | cut -d':' -f1)
    sed -i "${line_number}s/^.\{91\}/&$line/" "$output_file"
done < "$input_file"

# 7) idxhitpaste.sh
ssh -i /home/FG/fortikey USERNAME@HOSTNAME "show firewall policy"

# 8) sendhit.sh
#!/bin/bash
# -------------------------------------------------------
if [ -f "/home/FG/tempidx.txt" ]; then
    {
        echo 'From: "FortiGate unused rules" <FROM@EMAIL.COM>'
        echo 'To: "USER1" <USER1@EMAIL.COM>, "USER2" <USER2@EMAIL.COM>'
        echo 'Subject: FortiGate Notification'
        echo '-----------------------------------------------'
        echo 'These Security Policies unused greater than 90 days.'
        echo '-----------------------------------------------'
        sed -n '1,40p' /home/FG/tempidx.txt
        echo '-----------------------------------------------'
        echo 'These Security Policies have ZERO hit count.'
        echo '-----------------------------------------------'
        sed -n '1,500p' /home/FG/tempzero.txt
    } > /home/FG/notifhit.txt
fi
curl --ssl-reqd \
 --url 'smtps://smtp.gmail.com:465' \
 --user 'FROM@EMAIL.COM:PASSWORD' \
 --mail-from 'FROM@EMAIL.COM' \
 --mail-rcpt 'USER1@EMAIL.COM' \
 --mail-rcpt 'USER2@EMAIL.COM' \
 --upload-file /home/FG/notifhit.txt

# 9) zeroapply.sh
#!/bin/bash
input_file="/home/FG/zero.txt"
output_file="/home/FG/tempzeropaste.sh"
while IFS= read -r line; do
    line_number=$(grep -n "$line" "$input_file" | cut -d':' -f1)
    sed -i "${line_number}s/^.\{91\}/&$line/" "$output_file"
done < "$input_file"

# 10) zeropaste.sh
ssh -i /home/FG/fortikey USERNAME@HOSTNAME "show firewall policy"
