systemctl stop xiond

wget https://github.com/burnt-labs/xion/releases/download/v14.0.0/xiond-linux-amd64 && mv xiond-linux-amd64 /root/go/bin/xiond
chmod +x /root/go/bin/xiond

rm xion_v14.0.0_upd.sh

sudo systemctl restart xiond && sudo journalctl -u xiond -f
