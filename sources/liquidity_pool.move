#[allow(unused_field)]
module flowx_smart_contract::liquidity_pool;

use sui::balance::{Self, Balance};
use sui::vec_map::{Self, VecMap};

// create types of assets we have

const ERROR_LENGTH_MISMATCH: u64 = 1001;

// Constants for error handling
#[allow(unused_const)]
const ERROR_INSUFFICIENT_BALANCE: u64 = 1003;
const ERROR_ASSET_NOT_FOUND: u64 = 1003;
const ERROR_UNAUTHORIZED: u64 = 1004;


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
    coin: Balance<T>

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

#[allow(lint(self_transfer))]
public fun create_lp<T>(
    ctx: &mut TxContext,
        coins: &mut vector<Balance<T>>,
        initial_rates: vector<u128>,
        initial_fees: vector<u128>,
        amp_factor: u64,
        symbols: vector<std::string::String>
): address {
    // Ensure that the pool ID is unique and that there are no duplicate token pairs
    assert!(vector::length(coins) > 0, ERROR_LENGTH_MISMATCH); // Pool must have at least one token pair

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

    let coin_value = balance::value(&coin);

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

    tx_context::sender(ctx)
    
}

#[allow(unused_variable)]
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
    coin: Balance<T>,
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
   
public fun swap<T>(
    _ctx: &mut TxContext,
    pool: &mut LiquidityPool<T>,
    from_token: std::string::String,
    to_token: std::string::String,
    amount_in: u64
): u64 {
    // Ensure tokens are present in the pool
    assert!(
        vec_map::contains(&pool.token_pairs, &from_token) && vec_map::contains(&pool.token_pairs, &to_token),
        ERROR_LENGTH_MISMATCH
    );

    // Get reserves of the tokens
    let from_reserve = *vec_map::get(&pool.reserves, &from_token);
    let to_reserve = *vec_map::get(&pool.reserves, &to_token);

    // Get swap fee
    let swap_fee = vec_map::get(&pool.swap_fee, &from_token);

    // Apply swap fee (fee is deducted from the input amount)
    let amount_in_after_fee = (amount_in * (10000 - (*swap_fee as u64)))/10000;

    // Calculate the amount of `token` to be given (using constant product formula)
    let amount_out: u64 = (amount_in_after_fee * to_reserve)/ (from_reserve + amount_in_after_fee);

    // Ensure enough liquidity is available
    assert!(to_reserve >= amount_out, ERROR_LENGTH_MISMATCH);

    // Update reserves
    vec_map::insert(&mut pool.reserves, from_token, from_reserve + amount_in);
    vec_map::insert(&mut pool.reserves, to_token, to_reserve - amount_out);

    // First handle the withdrawal
    {
        let to_asset = vec_map::get_mut(&mut pool.token_pairs, &to_token);
        let withdrawn_balance = balance::split(&mut to_asset.coin, amount_out);
        
        // Now handle the deposit in a separate scope
        let from_asset = vec_map::get_mut(&mut pool.token_pairs, &from_token);
        balance::join(&mut from_asset.coin, withdrawn_balance);
    };

    amount_out
}

public fun add_asset<T>(
    pool: &mut LiquidityPool<T>,
    ctx: &mut TxContext,
    symbol: std::string::String,
    name: std::string::String,
    decimals: u8,
    initial_balance: Balance<T>,
    initial_rate: u128,
    swap_fee: u128
){
    // Only liquidity provider can add assets
    assert!(pool.liquidity_provider == tx_context::sender(ctx), ERROR_UNAUTHORIZED);
    
    // Ensure asset doesn't already exist
    assert!(!vec_map::contains(&pool.token_pairs, &symbol), ERROR_ASSET_NOT_FOUND);

    let balance_amount = balance::value(&initial_balance);

    // create new assets
    let asset = Asset<T> {
        id: object::new(ctx),
        symbol: symbol,
        name: name,
        decimals: decimals,
        total_supply: (balance_amount as u128),
        coin: initial_balance
    };

    // Add to pool's maps
    vec_map::insert(&mut pool.token_pairs, symbol, asset);
    vec_map::insert(&mut pool.reserves, symbol, balance_amount);
    vec_map::insert(&mut pool.rates, symbol, initial_rate);
    vec_map::insert(&mut pool.swap_fee, symbol, swap_fee);
}

public fun remove_asset<T>(
    pool: &mut LiquidityPool<T>,
    ctx: &mut TxContext,
    symbol: std::string::String
): Balance<T> {
    // Only liquidity provider can remove assets
    assert!(pool.liquidity_provider == tx_context::sender(ctx), ERROR_UNAUTHORIZED);

    // ensure asset exist
    assert!(vec_map::contains(&pool.token_pairs,&symbol), ERROR_ASSET_NOT_FOUND);

    // Remove asset from all maps
    let (_, asset) = vec_map::remove(&mut pool.token_pairs, &symbol);
    vec_map::remove(&mut pool.reserves, &symbol);
    vec_map::remove(&mut pool.swap_fee, &symbol);
    vec_map::remove(&mut pool.rates, &symbol);

    // Extract balance from asset
    let Asset { id, symbol: _, name: _, decimals: _, total_supply: _, coin } = asset;
    object::delete(id);

    coin
}

public fun contain_asset<T>(pool: &LiquidityPool<T>, symbol: std::string::String): bool {
    vec_map::contains(&pool.token_pairs, &symbol)
}