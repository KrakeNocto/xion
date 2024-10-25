echo "Sleeping 0 seconds (0 hours)"
sleep 0

min_time_c=600
max_time_c=129600
sleep_time_c=$(shuf -i $min_time_c-$max_time_c -n 1)

echo "Unjail validator after $sleep_time_c seconds"
sleep $sleep_time_c

export PWD="SorexGroup"

PORT=$(grep -oP '(0\.0\.0\.0|127\.0\.0\.1):\K[0-9]*57' .xiond/config/config.toml)
echo "$PWD" | /root/go/bin/xiond --node tcp://0.0.0.0:$PORT tx slashing unjail --from wallet -y

rm xion_unjail.sh
