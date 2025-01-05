module flowx_smart_contract::nft_factory;

use sui::package;
use sui::display;

// Error codes

#[allow(unused_const)]
const ERROR_UNAUTHORIZED: u64 = 1004;
const ERROR_COLLECTION_NOT_FOUND: u64 = 1005;

/// Capability for the factory owner
public struct FactoryAdmin has key {
    id: UID,
}


/// Represents a collection configuration
public struct Collection has key, store {
    id: UID,
    name: std::string::String,
    symbol: std::string::String,
    description: std::string::String,
    creator: address,
    mint_fee: u64,
    total_supply: u64,
    minted: u64
}

/// NFT structure that will be created for each collection
public struct NFT has key, store {
    id: UID,
    collection: address,
    token_id: u64,
    metadata: std::string::String,
    owner: address,
}

// === Events ===
#[allow(unused_field)]
public struct CollectionCreated has copy, drop {
    collection_id: address,
    name: std::string::String,
    creator: address
}

public struct NFT_FACTORY has drop {}

/// add this test-only function to create otw
#[test_only]
public fun init_for_testing(ctx: &mut TxContext){
    init(NFT_FACTORY {}, ctx)
}

/// Initialize the factory
/// Create and transfer factory admin capability to developer
fun init(witness: NFT_FACTORY, ctx: &mut TxContext){

    transfer::transfer(
        FactoryAdmin { id: object::new(ctx) }, tx_context::sender(ctx));
    
    // Create a Publisher for the collection's Display
    let publisher = package::claim(witness, ctx);

    // Create a Display for the NFTs
    let mut display = display::new<NFT>(&publisher, ctx);

    // Set display properties
    display::add(&mut display, b"name".to_string(), b"{name}".to_string());
    display::add(&mut display, b"description".to_string(), b"{description}".to_string());
    display::add(&mut display, b"collection".to_string(), b"{collection}".to_string());

    // update the display with the property
    display::update_version(&mut display);

    // Transfer the publisher to the deployer
    transfer::public_transfer(publisher, tx_context::sender(ctx));
    transfer::public_transfer(display, tx_context::sender(ctx));
}

/// create a new nft collection
public entry fun create_collection(
    // otw: PUBLISHER,
    name: std::string::String,
    symbol: std::string::String,
    description: std::string::String,
    mint_fee: u64,
    total_supply: u64,
    ctx: &mut TxContext
){
    let collection = Collection {
        id: object::new(ctx),
        name,
        symbol,
        description,
        creator: tx_context::sender(ctx),
        mint_fee,
        total_supply,
        minted: 0,
    };

    // create a Publisher for the collection's Display
    transfer::public_transfer(collection, tx_context::sender(ctx))
}

public entry fun mint_nft(
    collection: &mut Collection,
    metadata: std::string::String, 
    ctx: &mut TxContext
    ) {
    assert!(collection.minted < collection.total_supply, ERROR_COLLECTION_NOT_FOUND);
    let token_id = collection.minted + 1;
    collection.minted = token_id;
    let nft = NFT {
        id: object::new(ctx),
        collection: object::id_address(collection),
        token_id,
        metadata,
        owner: tx_context::sender(ctx),
    };

    transfer::transfer(nft, tx_context::sender(ctx))
}

/// Transfers NFT ownership
#[allow(lint(custom_state_change))]
public entry fun transfer_nft(nft: NFT, recipient: address){
    transfer::transfer(nft, recipient);
}

/// Burns (deletes) an NFT
public entry fun burn(nft: NFT){ 
    let NFT {id,  collection: _, token_id: _, metadata: _, owner: _} = nft;
    object::delete(id);
}

// === Getter Functions ===
public fun get_collection_info(collection: &Collection)
: (std::string::String, 
    std::string::String,
    std::string::String,
    address,
    u64,
    u64,
    u64
){
    (
        collection.name,
        collection.symbol,
        collection.description,
        collection.creator,
        collection.mint_fee,
        collection.total_supply,
        collection.minted
    )
}

public fun get_nft_info(nft: &NFT) : (address, u64, std::string::String, address) {
    (
        nft.collection,
        nft.token_id,
        nft.metadata,
        nft.owner
    )
}

/// Gets the owner of the NFT
public fun get_owner(nft: &NFT): address {
    nft.owner
}

/// Gets the metadata of the NFT
public fun get_metadata(nft: &NFT): std::string::String {
    nft.metadata
}