

# Устанавливаем необходимые зависимости


`sudo apt update && sudo apt upgrade -y && \
sudo apt install curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils git make ncdu htop screen unzip bc fail2ban htop -y`

`ver="1.21.3" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version`

`sudo apt update && sudo apt install -y git npm jq direnv && npm install -g pnpm`

npm install -g n
n latest

`curl -L https://foundry.paradigm.xyz | bash`

`source /root/.bashrc`

`foundryup`


# Клонируем репозиторий с OP-stack


`cd ~`

`git clone https://github.com/ethereum-optimism/optimism.git`

`cd optimism `

`git checkout tutorials/chain`



# Проверяем версии установленных зависимостей

`./packages/contracts-bedrock/scripts/getting-started/versions.sh`

# Собираем бинарники из исходного кода

`pnpm install`

`make op-node op-batcher op-proposer`

`pnpm build`

#
#

`cd ~`
`git clone https://github.com/ethereum-optimism/op-geth.git`

`cd op-geth`

`make geth`

`cd ~/optimism`


# Генерируем адреса и приватные ключи(только для тестнета)

`./packages/contracts-bedrock/scripts/getting-started/wallets.sh`



# Настройка .envrc
`cp .envrc.example .envrc`

Редактируем файл .envrc

`L1_RPC_URL ссылка на RPC Etherium`

`L1_RPC_KIND	RPC провайдер(alchemy, quicknode, infura, parity, nethermind, debug_geth, erigon, basic, any)`

Вставляем адреса и приватные ключи из вывода скрипта wallets.sh

# Сохраняем переменные

`eval "$(direnv hook bash)"`

`direnv allow`

`source /root/.bashrc`

# Запускаем скрипт конфигурации сети

`cd packages/contracts-bedrock`

`./scripts/getting-started/config.sh`

# Деплоим контракты в Etherium

`forge script scripts/Deploy.s.sol:Deploy --private-key $GS_ADMIN_PRIVATE_KEY --broadcast --rpc-url $L1_RPC_URL --slow`

!!!Важно сделать копию ~/optimism/packages/contracts-bedrock/deployments/getting-started/.deploy !!!


# Создаём генезис файлы и JSON Web Token

`cd ~/optimism/op-node`

`eval "$(direnv hook bash)"`


`go run cmd/main.go genesis l2 \
  --deploy-config ../packages/contracts-bedrock/deploy-config/getting-started.json \
  --l1-deployments ../packages/contracts-bedrock/deployments/getting-started/.deploy \
  --outfile.l2 genesis.json \
  --outfile.rollup rollup.json \
  --l1-rpc $L1_RPC_URL`

`openssl rand -hex 32 > jwt.txt`

`cp genesis.json ~/op-geth
cp jwt.txt ~/op-geth`


`go run cmd/main.go genesis l2 \
  --deploy-config ../packages/contracts-bedrock/deploy-config/getting-started.json \
  --l1-deployments ../packages/contracts-bedrock/deployments/getting-started/.deploy \
  --outfile.l2 genesis.json \
  --outfile.rollup rollup.json \
  --l1-rpc $L1_RPC_URL`

# Инициализируем op-geth
`cd ~/op-geth
mkdir datadir
build/bin/geth init --datadir=datadir genesis.json`

# Запуск op-geth

`screen`

`cd ~/op-geth`

`eval "$(direnv hook bash)"`

`./build/bin/geth \
  --datadir ./datadir \
  --http \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --http.addr=0.0.0.0 \
  --http.api=web3,debug,eth,txpool,net,engine \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.origins="*" \
  --ws.api=debug,eth,txpool,net,engine \
  --syncmode=full \
  --gcmode=archive \
  --nodiscover \
  --maxpeers=0 \
  --networkid=42069 \   
  --authrpc.vhosts="*" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=./jwt.txt \
  --rollup.disabletxpoolgossip=true`


параметр --networkid=42069 заменить на уникальный

# Запуск op-node
`screen`

`cd ~/optimism/op-node`


`eval "$(direnv hook bash)"`



`./bin/op-node \
  --l2=http://localhost:8551 \
  --l2.jwt-secret=./jwt.txt \
  --sequencer.enabled \
  --sequencer.l1-confs=5 \
  --verifier.l1-confs=4 \
  --rollup.config=./rollup.json \
  --rpc.addr=0.0.0.0 \
  --rpc.port=8547 \
  --p2p.disable \
  --rpc.enable-admin \
  --p2p.sequencer.key=$GS_SEQUENCER_PRIVATE_KEY \
  --l1=$L1_RPC_URL \
  --l1.rpckind=$L1_RPC_KIND`


Данная конфигурация предназанчена для одной ноды


# Запуск op-batcher

`screen`

`cd ~/optimism/op-batcher`

`eval "$(direnv hook bash)"`

`./bin/op-batcher \
  --l2-eth-rpc=http://0.0.0.0:8545 \
  --rollup-rpc=http://localhost:8547 \
  --poll-interval=1s \
  --sub-safety-margin=6 \
  --num-confirmations=1 \
  --safe-abort-nonce-too-low-count=3 \
  --resubmission-timeout=30s \
  --rpc.addr=0.0.0.0 \
  --rpc.port=8548 \
  --rpc.enable-admin \
  --max-channel-duration=1 \
  --l1-eth-rpc=$L1_RPC_URL \
  --private-key=$GS_BATCHER_PRIVATE_KEY`


# Запуск op-proposer

`screen`

`cd ~/optimism/op-proposer`


`./bin/op-proposer \
--poll-interval=12s \
--rpc.port=8560 \
--rollup-rpc=http://localhost:8547 \
--l2oo-address=$(cat ../packages/contracts-bedrock/deployments/getting-started/.deploy | jq -r .L2OutputOracleProxy) \
--private-key=$GS_PROPOSER_PRIVATE_KEY \
--l1-eth-rpc=$L1_RPC_URL`

# Подключение кошелька к сети
В кошельке добавляем сеть с вашим networkid, rpc - `http://ip.of.your.node:8545`, ticker - ETH

# Получаем адрес контракта моста для пополнения кошелька в сети L2
`cat deployments/getting-started/L1StandardBridgeProxy.json | jq -r .address`

Отправляем ETH на этот адрес.Далее можно делать тестовые транзакции 
