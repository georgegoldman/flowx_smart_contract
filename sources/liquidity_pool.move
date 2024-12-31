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
public struct LiquidityPool<phantom T> has key, store {
    id: UID,
    token_pairs: VecMap<std::string::String, Asset<T>>, // List of token pairs available for swaps in the pool
    reserves: VecMap<std::string::String, u64>, // Amount of liquidity available for each asset in the pool (e.g., USD, Naira, SUI).
    rates: VecMap<std::string::String, u128>,
    swap_fee: VecMap<std::string::String, u128>, // The fee percentage taken from each swap (e.g., 0.3%).
    amplification_factor: u64, // The amplification factor for stablecoins to adjust liquidity depth in the pool (e.g., 2x).
    total_lp_tokens: u128,
    liquidity_provider: address, // Address of the liquidity provider who adds liquidity to the pool.
}

public fun create_lp<T>(
    ctx: &mut TxContext,
        coins: &mut vector<Coin<T>>,
        initial_rates: vector<u128>,
        initial_fees: vector<u128>,
        amp_factor: u64,
        symbols: vector<std::string::String>
){
    // Ensure that the pool ID is unique and that there are no duplicate token pairs
    assert!(vector::length(coins) > 0, 1); // Pool must have at least one token pair

    // Create empty VecMaps
    let mut token_pairs = vec_map::empty();
    let mut reserves = vec_map::empty();
    let mut rates = vec_map::empty();
    let mut fees = vec_map::empty();

    

    let mut i = 0;

    while (i < vec_map::size(&token_pairs)){
    let  coin = vector::pop_back(coins);
    let symbol = *vector::borrow(&symbols, i);
    let rate = *vector::borrow(&initial_rates, i);
    let fee = *vector::borrow(&initial_fees, i);

    let coin_value = coin::value(&coin);

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
        coin
        );



    // Add to VecMaps
    vec_map::insert(&mut token_pairs, symbol, asset);
    vec_map::insert(&mut reserves, symbol, coin_value);
    vec_map::insert(&mut rates, symbol, rate);
    vec_map::insert(&mut fees, symbol, fee);

    i = i + 1;
        
    };

    let pool = LiquidityPool<T>{
        id: object::new(ctx),
        token_pairs,
        reserves,
        rates,
        swap_fee: fees,
        amplification_factor: amp_factor,
        total_lp_tokens: 0,
        liquidity_provider: tx_context::sender(ctx)
    };

    sui::transfer::transfer(pool, tx_context::sender(ctx));
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
) : Asset<T>  {

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
   
