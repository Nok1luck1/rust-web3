use hex_literal::hex;
use secp256k1::SecretKey;
use std::env;
use std::str::FromStr;
use std::time;
use web3::contract::{Contract, Options};
use web3::futures::StreamExt;
use web3::types::{Address, FilterBuilder, H160, U256};

#[tokio::main]
async fn main() -> web3::Result<()> {
    dotenv::dotenv().ok();
    let websokcet = web3::transports::WebSocket::new(&env::var("INFURA_ROPSTEN").unwrap()).await?;
    let web3s = web3::Web3::new(websokcet);

    let mut accounts = web3s.eth().accounts().await?;
    accounts.push(H160::from_str(&env::var("ACCOUNT_ADDRESS").unwrap()).unwrap());
    println!("Accounts:{:?}", accounts);

    let wei_conv: U256 = U256::exp10(18);
    for account in accounts {
        let balance = web3s.eth().balance(account, None).await?;
        println!(
            "Balance {:?}:{}",
            account,
            balance.checked_div(wei_conv).unwrap()
        );
    }
    let bytecode = include_str!("../bin/contracts/Bridge.bin");
    let bridge_addr = Address::from_str("0x9ea9E1FB8d3B458407f2F348f93574f270d1a529").unwrap();
    // let bdrige_contr =
    //     Contract::from_json(web3s.eth(), bridge_addr, include_bytes!("./bridge.json")).unwrap();
    //let private_key = SecretKey::from_str(&env::var("PRIVATE_KEY").unwrap()).unwrap();
    let prvk = SecretKey::from_str(&env::var("PRIVATE_KEY").unwrap()).unwrap();

    //let data = bridge_addr.abi().function("pause").unwrap();
    // let transact_obj = web3::types::TransactionParameters {
    //     nonce: None,
    //     to: Some(bridge_addr),
    //     ..Default::default()
    // };
    let contract_brdige_depl = Contract::deploy(web3s.eth(), include_bytes!("./bridge.json"))
        .unwrap()
        .confirmations(10)
        .poll_interval(time::Duration::from_secs(10))
        .options(Options::with(|opt| opt.gas = Some(3_000_000.into())))
        .sign_with_key_and_execute(bytecode, (), &prvk, None)
        .await
        .unwrap();
    println!("{:?}", contract_brdige_depl.address());

    let filter = FilterBuilder::default()
        .address(vec![bridge_addr])
        .topics(
            Some(vec![hex!(
                "5e418e57faceed9abcebeb838879291d58af370932340175f34c7daaeadb804a"
            )
            .into()]),
            Some(vec![hex!(
                "79798a5f5c3c7fa54a25ad685d912914645dc006852a962f9102bcde4b7356e3"
            )
            .into()]),
            None,
            None,
        )
        .build();

    let logs_streeam = web3s.eth_filter().create_logs_filter(filter).await?;
    web3::futures::pin_mut!(logs_streeam);

    let trans_to_bdrige = Contract::signed_call_with_confirmations(
        &contract_brdige_depl,
        "pause",
        (),
        Options::default(),
        10,
        &prvk,
    )
    .await;
    println!("tran{:?}", trans_to_bdrige);

    let log = logs_streeam.logs().await.unwrap();

    println!("LOG {:?}", log);
    Ok(())
}
