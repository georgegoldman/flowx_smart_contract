module flowx_smart_contract::liquidity_pool;
use sui::coin::{Self, Coin, TreasuryCap};
use sui::balance::{Self, Balance};
use sui::transfer;
use sui::tx_context::{Self, TxContext};
use sui::object::{Self, UID};

// create types of assets we have


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
    total_supply: u128

}

// Struct to represent a stablecoin liquidity pool
public struct StableLiquidityPool<T, U> has key, store {
    id: UID,
    token_pairs: vector<Asset<T>>, // List of token pairs available for swaps in the pool
    stablecoin: Asset<U>, //The stablecoin used as the base for liquidity
    reserves: vector<u128>, // Amount of liquidity available for each asset in the pool (e.g., USD, Naira, SUI).
    swap_fee: u64, // The fee percentage taken from each swap (e.g., 0.3%).
    amplification_factor: u64, // The amplification factor for stablecoins to adjust liquidity depth in the pool (e.g., 2x).
    liquidity_provider: address, // Address of the liquidity provider who adds liquidity to the pool.
}

   
