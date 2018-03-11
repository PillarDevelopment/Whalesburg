var MAINET_RPC_URL = 'https://mainnet.infura.io/metamask' ;
var ROPSTEN_RPC_URL = 'https://ropsten.infura.io/metamask' ;
var KOVAN_RPC_URL = 'https://kovan.infura.io/metamask' ;
var RINKEBY_RPC_URL = 'https://rinkeby.infura.io/metamask' ;

var CURRENT_URL = RINKEBY_RPC_URL ;



const contractAddress   = "0xcc22450A2F889a8Cd2075912986B7c3369B2B834";

const contractABI = [
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "avaliableSupply",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "name",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "string"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "membersWhiteList",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "totalSupply",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "decimals",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [
                    			{
                    				"name": "who",
                    				"type": "address"
                    			}
                    		],
                    		"name": "isWhitelisted",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "bool"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": false,
                    		"inputs": [
                    			{
                    				"name": "_value",
                    				"type": "uint256"
                    			}
                    		],
                    		"name": "burn",
                    		"outputs": [
                    			{
                    				"name": "success",
                    				"type": "bool"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "nonpayable",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "multisig",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "address"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": false,
                    		"inputs": [],
                    		"name": "finalize",
                    		"outputs": [],
                    		"payable": false,
                    		"stateMutability": "nonpayable",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "endICO",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [
                    			{
                    				"name": "",
                    				"type": "address"
                    			}
                    		],
                    		"name": "balanceOf",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "startICO",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "buyPrice",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "investors",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "isFinalized",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "bool"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "owner",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "address"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "individualRoundCap",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "symbol",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "string"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": false,
                    		"inputs": [
                    			{
                    				"name": "_to",
                    				"type": "address"
                    			},
                    			{
                    				"name": "_value",
                    				"type": "uint256"
                    			}
                    		],
                    		"name": "transfer",
                    		"outputs": [],
                    		"payable": false,
                    		"stateMutability": "nonpayable",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"name": "_whitelist",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "address"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [
                    			{
                    				"name": "",
                    				"type": "address"
                    			}
                    		],
                    		"name": "moneySpent",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "weisRaised",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"constant": true,
                    		"inputs": [],
                    		"name": "hardCap",
                    		"outputs": [
                    			{
                    				"name": "",
                    				"type": "uint256"
                    			}
                    		],
                    		"payable": false,
                    		"stateMutability": "view",
                    		"type": "function"
                    	},
                    	{
                    		"inputs": [],
                    		"payable": false,
                    		"stateMutability": "nonpayable",
                    		"type": "constructor"
                    	},
                    	{
                    		"payable": true,
                    		"stateMutability": "payable",
                    		"type": "fallback"
                    	},
                    	{
                    		"anonymous": false,
                    		"inputs": [],
                    		"name": "Finalized",
                    		"type": "event"
                    	},
                    	{
                    		"anonymous": false,
                    		"inputs": [
                    			{
                    				"indexed": true,
                    				"name": "from",
                    				"type": "address"
                    			},
                    			{
                    				"indexed": true,
                    				"name": "to",
                    				"type": "address"
                    			},
                    			{
                    				"indexed": false,
                    				"name": "value",
                    				"type": "uint256"
                    			}
                    		],
                    		"name": "Transfer",
                    		"type": "event"
                    	},
                    	{
                    		"anonymous": false,
                    		"inputs": [
                    			{
                    				"indexed": true,
                    				"name": "from",
                    				"type": "address"
                    			},
                    			{
                    				"indexed": false,
                    				"name": "value",
                    				"type": "uint256"
                    			}
                    		],
                    		"name": "Burn",
                    		"type": "event"
                    	}
                    ];


$(document).ready(function(){

    if (typeof web3 !== 'undefined') {
        web3 = new Web3(web3.currentProvider);
    } else {
        // set the provider you want from Web3.providers
        web3 = new Web3(new Web3.providers.HttpProvider(CURRENT_URL));
    }

    var myContract = web3.eth.contract(contractABI);
    var myContractInstance = myContract.at(contractAddress);


    var availableSupply = 0;
    var totalSupply = 0;
    var investors = 0;
    var buyPrice = 0;
    var weisRaised = 0;
    var hardCap = 0;


    myContractInstance.avaliableSupply(function(err, res){
        var avaliableSupply = res['c'][0].toString() //+ res['c'][1].toString();
        $('#avaliableSupply').html(avaliableSupply);
        console.log(avaliableSupply);
    });

     myContractInstance.totalSupply(function(err, res){
              var totalSupply = res['c'][0].toString();
              $('#totalSupply').html(totalSupply);
              console.log(totalSupply);
          });
 myContractInstance.buyPrice(function(err, res){
          var buyPrice = res['c'][0].toString();// + res['c'][1].toString();
          $('#buyPrice').html(buyPrice);
          console.log(buyPrice);
      });
myContractInstance.weisRaised(function(err, res){
          var weisRaised = web3.fromWei(res , 'ether');// + res['c'][1].toString();
          weisRaised = weisRaised['c'][0].toString();
          $('#weisRaised').html(weisRaised);
          console.log(weisRaised);
      });

      myContractInstance.hardCap(function(err, res){
                   var hardCap = web3.fromWei(res , 'ether');// + res['c'][1].toString();
                   hardCap = hardCap['c'][0].toString();
                   $('#hardCap').html(hardCap);
                   console.log(hardCap);
               });

      myContractInstance.investors(function(err, res){
          var investors = res['c'][0].toString();
          $('#investors').html(investors);
      });
});