module flowx_smart_contract::liquidity_pool;
use sui::coin::{Self, Coin, TreasuryCap};
use sui::balance::{Self, Balance};
use sui::transfer;
use sui::tx_context::{Self, TxContext};
use sui::object::{Self, UID};
use sui::table::{Self, Table};
use sui::vec_map::{Self, VecMap};

// create types of assets we have

const ERROR_LENGTH_MISMATCH: u64 = 1001;


public struct Enum{
    name: std::string::String,
    value: vector<std::string::String>
}

public struct Fiat{
    issuing_country: std::string::String, // The country responsible for issuing the fiat currency.
    central_bank: std::string::String, // Name of the central bank regulating the fiat currency.
    is_reserve_currency: bool // Indicates whether the fiat currency is a global reserve currency (e.g., USD).
}

public struct StableCoin{
    peg_to: std::string::String, // The asset the stablecoin is pegged to (e.g., USD, Gold).
    peg_ratio: u64, // The ratio of the stablecoin to its pegged asset (e.g., 1:1 for USD).
    collateral_type: std::string::String, // The type of reserves backing the stablecoin (e.g., cash, treasury bills).
    issuer: address, // The address or identity of the issuer of the stablecoin.
    audit_frequency: std::string::String, // Frequency of audits for reserves (e.g., monthly, quarterly).
    redemption_mechanism: std::string::String // Details of how users can redeem stablecoins for the pegged asset (e.g., fiat).

}

public struct Crypto{
    consensus_mechanism: std::string::String, // The consensus model used by the blockchain (e.g., Proof-of-Work, Proof-of-Stake).
    blockchain_platform: std::string::String, // The blockchain platform the asset resides on (e.g., Ethereum, Solana).
    token_standard: std::string::String, // The token standard followed by the asset (e.g., ERC-20, BEP-20).
    max_suppyly: u128, // Maximum possible supply of the cryptocurrency.
    burn_mechanism: std::string::String, //Mechanism used to reduce the token supply (e.g., transaction fee burn).
}

public struct Asset<phantom T> has key, store {
    id: UID,
    symbol: std::string::String,
    name: std::string::String,
    decimals: u8,
    total_supply: u128,
    coin: Coin<T>

}

// Struct to represent a stablecoin liquidity pool
public struct LiquidityPool<T, U> has key, store {
    id: UID,
    token_pairs: VecMap<std::string::String, Asset<T>>, // List of token pairs available for swaps in the pool
    reserves: VecMap<std::string::String, u128>, // Amount of liquidity available for each asset in the pool (e.g., USD, Naira, SUI).
    rates: VecMap<std::string::String, u128>,
    swap_fee: VecMap<std::string::String, u128>, // The fee percentage taken from each swap (e.g., 0.3%).
    amplification_factor: u64, // The amplification factor for stablecoins to adjust liquidity depth in the pool (e.g., 2x).
    total_lp_tokens: u128,
    liquidity_provider: address, // Address of the liquidity provider who adds liquidity to the pool.
}

public fun create_lp<T, U>(
    assets :  vector<Asset<T>>,
    // reserves: vector<u128>,
    initial_rates: vector<u128>,
    swap_fee: vector<u128>,
    amplification_factor: u64,
    ctx: &mut TxContext,
    symbols: vector<std::string::String>
): LiquidityPool<T, U>{
    // Ensure that the pool ID is unique and that there are no duplicate token pairs
    assert!(vector::length(&assets) > 0, 1); // Pool must have at least one token pair
    // assert!(vector::length(&reserves) ==  vector::length(&token_pairs), ERROR_LENGTH_MISMATCH); // Reserves should match token pairs length

    // Create empty VecMaps
        let token_pairs = vec_map::empty();
        // let reserves = vec_map::empty();
        let rates = vec_map::empty();
        // let fees = vec_map::empty();

    let i = 0;

    while (i < vec_map::size(&token_pairs)){
        let asset = vector::pop_back( &mut assets, );
        let key_value = asset.id.to_address().to_string();
        let rate  = *vector::borrow(&initial_rates, i);
        let symbol = *vector::borrow(&symbols, i);
        let fee = *vector::borrow(&swap_fee, i);
        let coin_value = coin::value(&asset.coin);
        let split_coin = coin::split( &mut asset.coin, coin_value, ctx);

        let asset = create_stablecoin_assest<T>(
            b"peg_to".to_string(), 
            1, 
            b"collateral_type".to_string(), 
            tx_context::sender(ctx), 
            b"audit_frequency".to_string(), 
            b"Cash Equivalents".to_string(), 
            ctx, 
            b"USDT".to_string(), 
            b"USD".to_string(), 
            6, 
            100000000000,
            split_coin
            );

        // insert  the moved assets into the map
        vec_map::insert(  &mut token_pairs, key_value, asset);
        // vec_map::insert(&mut pool.reserves, key_value, coin::value(coin.coin<T>));
        vec_map::insert( &mut rates, key_value, rate);

        
    };

    pool
}

fun create_stablecoin_assest<T>(
    peg_to: std::string::String,
    peg_ratio: u64,
    collateral_type: std::string::String,
    issuer: address,
    audit_frequency: std::string::String,
    redemption_mechanism: std::string::String,
    ctx: &mut TxContext,
    symbol: std::string::String,
    name: std::string::String,
    decimals: u8,
    total_supply: u128,
    coin: Coin<T>,
) : Asset<T> {
    let stable_info = StableCoin{
        peg_to,
        peg_ratio,
        collateral_type,
        issuer,
        audit_frequency,
        redemption_mechanism,
        
    };

    // Create the Asset with stablecoin info
    Asset<T> {
        id: object::new(ctx),
        symbol,
        name,
        decimals,
        total_supply,
        coin,
    }
}
   
