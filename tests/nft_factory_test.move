#[test_only]
module flowx_smart_contract::nft_factory_tests;

use sui::test_scenario::{Self, Scenario};
use flowx_smart_contract::nft_factory::{Self, Collection, NFT, FactoryAdmin, NFT_FACTORY};
use sui::test_utils;

// test addresses
const ADMIN: address = @0xA1;
const USER1: address = @0xB1;
const USER2: address = @0xC1;

// test constants
const COLLECTION_NAME: vector<u8> = b"Test Collection";
const COLLECTION_SYMBOL: vector<u8> = b"TEST";
const COLLECTION_DESCRIPTION: vector<u8> = b"Test Description";
const MINT_FEE :u64 = 100;
const TOTAL_SUPPLY: u64 = 1000;

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

// test collection creation
#[test]
fun test_create_collection(){
    let mut scenario = test_scenario::begin(USER1);

    //create collection
    {
        nft_factory::create_collection(
            std::string::utf8(COLLECTION_NAME), 
            std::string::utf8(COLLECTION_SYMBOL), 
            std::string::utf8(COLLECTION_DESCRIPTION), 
            MINT_FEE, 
            TOTAL_SUPPLY, 
            test_scenario::ctx(&mut scenario));
            
    };
    test_scenario::end(scenario);
}

// test nft minting
#[test]
fun test_mint_nft(){
    let mut scenario = test_scenario::begin(USER1);

    // first create a collection
    {
        nft_factory::create_collection(
            std::string::utf8(COLLECTION_NAME), 
            std::string::utf8(COLLECTION_SYMBOL), 
            std::string::utf8(COLLECTION_DESCRIPTION), 
            MINT_FEE, 
            TOTAL_SUPPLY, 
            test_scenario::ctx(&mut scenario));
    };
    // then mint the nft
    test_scenario::next_tx(&mut scenario,USER1);

    {
        let mut collection = test_scenario::take_from_sender<Collection>(&scenario);
        nft_factory::mint_nft(&mut collection, std::string::utf8(b"test nft meta data"), test_scenario::ctx(&mut scenario));
        test_scenario::return_to_sender(&scenario, collection);
    };
    test_scenario::next_tx(&mut scenario, USER1);
    {
        let nft = test_scenario::take_from_sender<NFT>(&scenario);
        let (_, token_id, metadata, owner) = nft_factory::get_nft_info(&nft);

        assert!(token_id == 1, 1);
        assert!(owner == USER2, 2);
        assert!(metadata == std::string::utf8(b"Test NFT Metadata"), 3);

        test_scenario::return_to_sender(&scenario, nft);

    };
    test_scenario::end(scenario);
}

// test nft transfer
#[test]
fun test_transfer_nft(){
    let mut scenario = test_scenario::begin(USER1);

    // create collection and mint nft
    {
        nft_factory::create_collection(
            b"{COLLECTION_NAME}".to_string(), 
            std::string::utf8(COLLECTION_SYMBOL),
             
             std::string::utf8(COLLECTION_DESCRIPTION), 
             MINT_FEE, 
             TOTAL_SUPPLY,
              test_scenario::ctx(&mut scenario));
    };
    test_scenario::next_tx(&mut scenario, USER1);
    {
        let mut collection = test_scenario::take_from_sender<Collection>(&scenario);
        nft_factory::mint_nft(
            &mut collection, 
            std::string::utf8(b"test nft metadata"), 
            test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, collection);
    };

    // transfer nft to user2
    test_scenario::next_tx(&mut scenario, USER1);
    {
        let nft = test_scenario::take_from_sender<NFT>(&scenario);
        nft_factory::transfer_nft(nft, USER2);
    };

    // verify transfer
    test_scenario::next_tx(&mut scenario, USER2);
    {
        let nft = test_scenario::take_from_sender<NFT>(&scenario);
        let(_,_,_, owner) = nft_factory::get_nft_info(&nft);
        assert!(owner == USER2, 1);
        test_scenario::return_to_sender(&scenario, nft);
    };
    test_scenario::end(scenario);
}

// test nft burning
#[test]
fun test_burn_nft(){
    let mut scenario = test_scenario::begin(USER1);

    // create collection and mint nft
    {
        nft_factory::create_collection(
            std::string::utf8(COLLECTION_NAME), 
            std::string::utf8(COLLECTION_SYMBOL), 
            std::string::utf8(COLLECTION_DESCRIPTION), 
            MINT_FEE, 
            TOTAL_SUPPLY, 
            test_scenario::ctx(&mut scenario));
    };
    test_scenario::next_tx(&mut scenario, USER1);
    {
        let mut collection = test_scenario::take_from_sender<Collection>(&scenario);
        nft_factory::mint_nft(&mut collection, std::string::utf8(b"Test nft meta"), test_scenario::ctx(&mut scenario));
        test_scenario::return_to_sender(&scenario, collection)
    
    };
    // burn nft
    test_scenario::next_tx(&mut scenario, USER1);
    {
        let nft = test_scenario::take_from_sender<NFT>(&scenario);
        nft_factory::burn_nft(nft);
    };

    // verify nft is burnt ie it should not exist in user inventory
    test_scenario::next_tx(&mut scenario, USER1);
    {
        assert!(!test_scenario::has_most_recent_for_sender<NFT>(&scenario), 1);
    };
    test_scenario::end(scenario);

}