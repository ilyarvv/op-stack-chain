const fs = require("fs")
const rlp = require('rlp')

async function deploy() {
  const MIPS = await ethers.getContractFactory("MIPS")
  const m = await MIPS.deploy()
  const mm = await ethers.getContractAt("MIPSMemory", await m.m())

  let startTrie = JSON.parse(fs.readFileSync("/tmp/cannon/golden.json"))
  let goldenRoot = startTrie["root"]
  console.log("goldenRoot is", goldenRoot)

  const Challenge = await ethers.getContractFactory("Challenge")
  const c = await Challenge.deploy(m.address, goldenRoot)

  return [c,m,mm]
}

function getBlockRlp(block) {
  let dat = [
    block['parentHash'],
    block['sha3Uncles'],
    block['miner'],
    block['stateRoot'],
    block['transactionsRoot'],
    block['receiptsRoot'],
    block['logsBloom'],
    block['difficulty'],
    block['number'],
    block['gasLimit'],
    block['gasUsed'],
    block['timestamp'],
    block['extraData'],
    block['mixHash'],
    block['nonce'],
  ];
  // post london
  if (block['baseFeePerGas'] !== undefined) {
    dat.push(block['baseFeePerGas'])
  }
  dat = dat.map(x => (x == "0x0") ? "0x" : x)
  //console.log(dat)
  let rdat = rlp.encode(dat)
  if (ethers.utils.keccak256(rdat) != block['hash']) {
    throw "block hash doesn't match"
  }
  return rdat
}

async function deployed() {
  let addresses = JSON.parse(fs.readFileSync("/tmp/cannon/deployed.json"))
  const c = await ethers.getContractAt("Challenge", addresses["Challenge"])
  const m = await ethers.getContractAt("MIPS", addresses["MIPS"])
  const mm = await ethers.getContractAt("MIPSMemory", addresses["MIPSMemory"])
  return [c,m,mm]
}

async function getTrieNodesForCall(c, cdat, preimages) {
  let nodes = []
  while (1) {
    try {
      // TODO: make this eth call?
      // needs something like InitiateChallengeWithTrieNodesj
      let calldata = c.interface.encodeFunctionData("CallWithTrieNodes", [cdat, nodes])
      ret = await ethers.provider.call({
        to:c.address,
        data:calldata
      });
      break
    } catch(e) {
      const missing = e.toString().split("'")[1]
      if (missing.length == 64) {
        console.log("requested node", missing)
        let node = preimages["0x"+missing]
        if (node === undefined) {
          throw("node not found")
        }
        const bin = Uint8Array.from(Buffer.from(node, 'base64').toString('binary'), c => c.charCodeAt(0))
        nodes.push(bin)
        continue
      } else {
        console.log(e)
        break
      }
    }
  }
  return nodes
}

module.exports = { deploy, deployed, getTrieNodesForCall, getBlockRlp }
