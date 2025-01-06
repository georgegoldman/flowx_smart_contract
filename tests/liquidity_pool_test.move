#[test_only]
module flowx_smart_contract::liquidity_pool_tests;

use sui::test_scenario::{Self, Scenario};
use sui::coin::{Self, Coin};
use sui::test_utils::assert_eq;
use flowx_smart_contract::liquidity_pool::{Self, LiquidityPool};

// Test coin type
public struct USDT has drop {}

// test address
const ADMIN: address = @0xA;
const USER: address = @0xB;

fun setup(): Scenario{
    test_scenario::begin(ADMIN)
}

#[test]
fun test_create_lp(){
    let mut scenario = setup();
    let test = &mut scenario;

    // start transaction from admin
    test_scenario::next_tx(test, ADMIN);
    {
        // create initial coins/balances
        let  mut coins = vector::empty();
        let ctx = test_scenario::ctx(test);
        let initial_coin = coin::mint_for_testing<USDT>(1000000, ctx);
        let balance = coin::into_balance(initial_coin);
        vector::push_back(&mut coins, balance);

        // setup initial parameters
        let initial_rates = vector[1000000]; // 1 USDT = 1 USD
        let initial_fees = vector[30]; // 0.3% fee
        let symbols = vector[std::string::utf8(b"USDT")];

        // create liquidity pool
        let lp_owner = liquidity_pool::create_lp(
            ctx, 
            &mut coins, 
            initial_rates, 
            initial_fees, 
            2, 
            symbols
        );
        
        // verify the owner is set correctly
        assert_eq(lp_owner, ADMIN);
        vector::destroy_empty(coins);
        
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_swap(){
    let mut scenario = setup();
    let test = &mut scenario;

    // Setup initial pool
    test_scenario::next_tx(test, ADMIN);
    {
        // get ctx first 
        let ctx = test_scenario::ctx(test);
        // Create initial pool with USDT and USDC
        let coins = vector::empty();
        let initial_coin = coin::mint_for_testing<USDT>(2000000, ctx);
    }
}