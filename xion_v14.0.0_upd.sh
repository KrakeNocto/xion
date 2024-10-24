systemctl stop xiond

wget https://github.com/burnt-labs/xion/releases/download/v14.0.0/xiond-linux-amd64 && mv xiond-linux-amd64 /root/go/bin/xiond
chmod +x /root/go/bin/xiond

cp $HOME/.xiond/data/priv_validator_state.json $HOME/.xiond/priv_validator_state.json.backup
rm -rf $HOME/.xiond/data $HOME/.xiond/wasm
curl https://server-5.itrocket.net/testnet/burnt/burnt_2024-10-24_10469507_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.xiond
mv $HOME/.xiond/priv_validator_state.json.backup $HOME/.xiond/data/priv_validator_state.json

sudo systemctl restart xiond && sudo journalctl -u xiond -f
