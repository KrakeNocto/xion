sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

cd $HOME
VER="1.23.1"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

min_am=10
max_am=64
random_am=$(shuf -i $min_am-$max_am -n 1)

echo "Moniker:"
read -r MONIKER

echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export XION_CHAIN_ID="xion-testnet-1"" >> $HOME/.bash_profile
echo "export XION_PORT="$random_am"" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
wget https://github.com/burnt-labs/xion/releases/download/v13.0.1/xiond-linux-amd64
mv /root/xiond-linux-amd64 /root/xiond
chmod +x $HOME/xiond
mv $HOME/xiond $HOME/go/bin/xiond

xiond init $MONIKER --chain-id $XION_CHAIN_ID
xiond config set client chain-id $XION_CHAIN_ID
xiond config set client node tcp://localhost:${XION_PORT}657
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${XION_PORT}657\"|" $HOME/.xiond/config/client.toml

wget -O $HOME/.xiond/config/genesis.json https://server-5.itrocket.net/testnet/burnt/genesis.json
wget -O $HOME/.xiond/config/addrbook.json  https://server-5.itrocket.net/testnet/burnt/addrbook.json

SEEDS="69e1aa5800ffa82615986eac5f99b77c2b8f1ccb@burnt-testnet-seed.itrocket.net:55656"
PEERS="a386af218bd4e5d0a5f2dcfbcc1051eff63d059f@burnt-testnet-peer.itrocket.net:55656,36a85158fe89f309de1792a538783a7026807eb3@65.108.105.48:22356,d4fd3250aafb6431e47e9dc476a4666bc6a38ad3@135.181.238.38:22356,73b62ebfb71023900d8debb6e6dc7f1379c34686@65.109.58.86:22356,546a135e9b70ba1ca999dc27a04bcbdfa7afc79e@142.132.209.236:22356,997a7f612a569f2a152b93d3e8f557243f5b1f8b@54.160.157.204:26656,0f2c632cc1a9226b1d9317c576c1644986e630ed@78.46.46.91:36656,65e8c0dd01f486121dbd355e406e57492fea9106@15.235.87.88:56656,81b6f3ef9529ed1a8f3ac2c1f848a19566a88baa@65.109.112.144:1020,45c4422c7afd1d7833c67f2151f6ea442865b3a0@144.76.163.244:26656,c1b664b464852487cefd9115d7b959059f6f2961@159.223.189.191:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.xiond/config/config.toml

sed -i.bak -e "s%:1317%:${XION_PORT}317%g;
s%:8080%:${XION_PORT}080%g;
s%:9090%:${XION_PORT}090%g;
s%:9091%:${XION_PORT}091%g;
s%:8545%:${XION_PORT}545%g;
s%:8546%:${XION_PORT}546%g;
s%:6065%:${XION_PORT}065%g" $HOME/.xiond/config/app.toml

sed -i.bak -e "s%:26658%:${XION_PORT}658%g;
s%:26657%:${XION_PORT}657%g;
s%:6060%:${XION_PORT}060%g;
s%:26656%:${XION_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${XION_PORT}656\"%;
s%:26660%:${XION_PORT}660%g" $HOME/.xiond/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.xiond/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.xiond/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.xiond/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0uxion"|g' $HOME/.xiond/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.xiond/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.xiond/config/config.toml

sudo tee /etc/systemd/system/xiond.service > /dev/null <<EOF
[Unit]
Description=Burnt node
After=network-online.target
[Service]
User=root
WorkingDirectory=$HOME/.xiond
ExecStart=$(which xiond) start --home $HOME/.xiond
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

cp $HOME/.xiond/data/priv_validator_state.json $HOME/.xiond/priv_validator_state.json.backup
rm -rf $HOME/.xiond/data $HOME/.xiond/wasm
curl https://server-5.itrocket.net/testnet/burnt/burnt_2024-10-08_10206259_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.xiond
mv $HOME/.xiond/priv_validator_state.json.backup $HOME/.xiond/data/priv_validator_state.json

sudo systemctl start xiond && sudo journalctl -fu xiond -o cat
