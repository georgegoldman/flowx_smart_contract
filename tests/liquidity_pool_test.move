#[test_only]
module flowx_smart_contract::liquidity_pool_tests;

use sui::test_scenario::{Self, Scenario};
use sui::coin::{Self, Coin};
use sui::test_utils::assert_eq;
use flowx_smart_contract::liquidity_pool::{Self, LiquidityPool};
use sui::balance;

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

// fun consume_vector<T>(v: &mut vector<T>) {
//     while(!vector::is_empty(v)){
//         let element = vector::pop_back(v);
//         consume_element(element)
//     }
// }

// // Example function that consumes the element
// fun consume_element<T>(element: T) {
//     // Ensure the element is fully consumed
//     let _ = element;
// }