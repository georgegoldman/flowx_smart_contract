#[test_only]
module flowx_smart_contract::nft_factory_tests;

use sui::test_scenario::{Self, Scenario};
use flowx_smart_contract::nft_factory::{Self, Collection, NFT, FactoryAdmin, NFT_FACTORY};
use sui::test_utils;

// test addresses
const ADMIN: address = @0xA1;
const USER1: address = @0xB1;
const USER2: address = @0xC1;

// Test initialization of the factory
#[test]
fun test_init_factory() {
    let mut scenario = test_scenario::begin(ADMIN);
    {
        nft_factory::init_for_testing(test_scenario::ctx(&mut scenario));
    };

    // verify initialization
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        // Verify admin capability was created
        assert!(test_scenario::has_most_recent_for_sender<FactoryAdmin>(&scenario), 0)
    };
    test_scenario::end(scenario);
}

// helper function for other tests
#[allow(unused_function)]
fun init_module_for_test(scenario: &mut test_scenario::Scenario) {
    nft_factory::init_for_testing(test_scenario::ctx(scenario));
}