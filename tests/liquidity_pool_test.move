#[test_only]
module flowx_smart_contract::liquidity_pool_tests;

use sui::test_scenario::{Self, Scenario};
use sui::coin;
use sui::balance::{Self, Balance};
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
        //clean up any remaining coins if needed
        consume_vector(coins, ctx);
        
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
        let mut coins = vector::empty();
        let initial_coin = coin::mint_for_testing<USDT>(2000000, ctx);
        let balance = coin::into_balance(initial_coin);
        vector::push_back(&mut coins, balance);

        let initial_rates = vector[1000000];
        let initial_fees = vector[30];
        let symbols = vector[std::string::utf8(b"USDT")];

        liquidity_pool::create_lp(
            ctx, 
            &mut coins, 
            initial_rates, 
            initial_fees, 
            2, 
            symbols
            );

            consume_vector(coins, ctx);

    };
    // Test adding new asset
    test_scenario::next_tx(test, ADMIN);
    {
        let mut pool = test_scenario::take_shared<LiquidityPool<USDT>>(test);
        // get ctx
        let ctx = test_scenario::ctx(test);
        let new_coin = coin::mint_for_testing<USDT>(500000, ctx);

        liquidity_pool::add_asset(
            &mut pool, 
            ctx, 
            std::string::utf8(b"DAI"), 
            std::string::utf8(b"Dai Stablecoin"), 
            18, 
            coin::into_balance(new_coin), 
            1000000, // 1:1 rate
            30 //0.3% fee
            );

            // Verify the asset was added
            assert!(liquidity_pool::contain_asset(&pool, std::string::utf8(b"DAI")), 0);


            test_scenario::return_shared(pool)
    };
    test_scenario::end(scenario);
}

#[test]
fun test_remove_asset(){
    let mut scenario = setup();
    let test = &mut scenario;

    // setup pool with multiple assets
    test_scenario::next_tx(test, ADMIN);
    {
        // Initial setup similar to add_asset test...
        let ctx = test_scenario::ctx(test);
        let initial_coin = coin::mint_for_testing<USDT>(1000000, ctx);
        let mut coins = vector[coin::into_balance(initial_coin)];
        let initial_rates = vector[1000000];
        let initial_fees = vector[30];
        let symbols = vector[std::string::utf8(b"USDT")];
        
        liquidity_pool::create_lp(
            ctx,
            &mut coins,
            initial_rates,
            initial_fees,
            2,
            symbols
        );
        consume_vector(coins, ctx);
    };
    // Add asset to remove later
    test_scenario::next_tx(test, ADMIN);
    {
        let mut pool = test_scenario::take_shared<LiquidityPool<USDT>>(test);
        let ctx = test_scenario::ctx(test);
        let new_coin = coin::mint_for_testing<USDT>(500000, ctx);

        liquidity_pool::add_asset(
                &mut pool,
                ctx,
                std::string::utf8(b"DAI"),
                std::string::utf8(b"Dai Stablecoin"),
                18,
                coin::into_balance(new_coin),
                1000000,
                30
            );

            test_scenario::return_shared(pool);
    };


    // Test removing asset
    test_scenario::next_tx(test, ADMIN);

    {
    let mut pool = test_scenario::take_shared<LiquidityPool<USDT>>(test);
    let ctx = test_scenario::ctx(test);
    let removed_balance = liquidity_pool::remove_asset(
        &mut pool, 
        ctx, 
        std::string::utf8(b"DAI")
        );

        // Verify balance amount
        assert_eq(balance::value(&removed_balance), 500000);

        // Verify asset was removed
        assert!(!liquidity_pool::contain_asset(&pool, std::string::utf8(b"DAI")), 0);

        // clean up
        let coin = coin::from_balance(removed_balance, ctx);
        coin::burn_for_testing(coin);

        test_scenario::return_shared(pool);
    };

    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = liquidity_pool::ERROR_UNAUTHORIZED)]
fun test_unauthorized_add_asset(){
    let mut scenario = setup();
    let test = &mut scenario;

    // setup pool
    test_scenario::next_tx(test, ADMIN);
    {
        let ctx = test_scenario::ctx(test);
        let initial_coin = coin::mint_for_testing<USDT>(1000000, ctx);
        let mut coins = vector[coin::into_balance(initial_coin)];
        let initial_rates = vector[1000000];
        let initial_fees = vector[30];
        let symbols = vector[std::string::utf8(b"USDT")];

        liquidity_pool::create_lp(
                ctx,
                &mut coins,
                initial_rates,
                initial_fees,
                2,
                symbols
            );

        consume_vector(coins, ctx);
    };
    // Try to add asset as non-admin user (should fail)
    test_scenario::next_tx(test,    ADMIN);

    {
        let mut pool = test_scenario::take_shared<LiquidityPool<USDT>>(test);
        let ctx = test_scenario::ctx(test);
        let new_coin = coin::mint_for_testing<USDT>(500000, ctx);
        
        liquidity_pool::add_asset(
            &mut pool,
            ctx,
            std::string::utf8(b"DAI"),
            std::string::utf8(b"Dai Stablecoin"),
            18,
            coin::into_balance(new_coin),
            1000000,
            30
        );

        test_scenario::return_shared(pool);
    };
    test_scenario::end(scenario);
}

fun consume_vector<T>(mut v:  vector<Balance<T>>, ctx: &mut TxContext) {
    while (!vector::is_empty(&v)){
        let balance = vector::pop_back(&mut v);
        let coin = coin::from_balance(balance, ctx);
        coin::burn_for_testing(coin);
    };
    vector::destroy_empty(v);
}