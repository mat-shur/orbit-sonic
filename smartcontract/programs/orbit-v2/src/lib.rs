use anchor_lang::prelude::*;
use anchor_lang::system_program;
use anchor_spl::{
    token::{self, Mint, MintTo, Token, TokenAccount, mint_to, transfer, Transfer},
    associated_token::AssociatedToken,
    metadata::{
        create_metadata_accounts_v3, create_master_edition_v3,
        sign_metadata, SignMetadata, Metadata, MetadataAccount, MasterEditionAccount,
        SetAndVerifySizedCollectionItem, set_and_verify_sized_collection_item,
        mpl_token_metadata::types::DataV2, CreateMetadataAccountsV3, CreateMasterEditionV3,
        mpl_token_metadata::types::{CollectionDetails, Creator, Collection},
    },
};
use solana_program::pubkey;

declare_id!("orbSp1BEce8Tkiha55T6iWrZB2ZX1dipaCxiC5Bybub");

// Constant project owner public key.
const PROJECT_OWNER: Pubkey = pubkey!("orbWh48F9G6UBb5XstTreYGPpRNq9dqhxxdCefQuiws");

// Fees and costs (in lamports)
const REGISTRATION_FEE: u64 = 10_000_000;
const GAME_ATTEMPT_FEE: u64 = 5_000_000;
const UPGRADE_COST: u64 = 10_000_000000;
const SKIN_PRICE: u64 = 100_000_000000;

// Rocket metadata array: (name, symbol, uri, weight)
// The weights define the chance: lower weight = rarer.
pub const ROCKET_METADATA: [(&str, &str, &str, u16); 8] = [
    ("Sonic RUSH", "RKT-SR", "https://gateway.pinata.cloud/ipfs/bafkreiavy3hcpwuehfua2wuprm6bum2doiflxa25lhex4n2utickgeasgq", 1),
    ("BNB-cket", "RKT-B", "https://gateway.pinata.cloud/ipfs/bafkreia65mgik63ex4oun2wa32r6ghdfm5mzhi5xr3kdln6oiqvsmwzkee", 4),
    ("Solstar", "RKT-S", "https://gateway.pinata.cloud/ipfs/bafkreiangnoc723v4yfftqmarsrbs6ysdxxfp4ma6kt7w3h3g76laoxog4", 4),
    ("Tetherion", "RKT-T", "https://gateway.pinata.cloud/ipfs/bafkreidg33ei6if36yxvytdqyc5kprpxeh5ns4vno6nmkjvyulksfpysea", 4),
    ("Etherifly", "RKT-E", "https://gateway.pinata.cloud/ipfs/bafkreia5vyj2xmgxqfhkjwzgoxllnvxjrmooqcnkark37uk6h6slj6d46e", 4),
    ("Rocket Phi", "RKT-3", "https://gateway.pinata.cloud/ipfs/bafkreih4724dgo7vycu7ygitk4mfvoruubly3dj4jz4xs65kmri5adtqpy", 10),
    ("Rocket Eta", "RKT-2", "https://gateway.pinata.cloud/ipfs/bafkreia6wbacc25ppun7evmo2uwltg5yossexavduo3ixebgskn7kopgny", 10),
    ("Rocket Theta", "RKT-1", "https://gateway.pinata.cloud/ipfs/bafkreia7sjinzm4db5halubqhta5qki35tux7pchbweqhznaslezy4s5nu", 10)
];

// Token Metadata
const TOKEN_NAME: &str = "Orbitals";
const TOKEN_SYMBOL: &str = "ORBITALS";
const TOKEN_URI: &str = "https://gateway.pinata.cloud/ipfs/bafkreiaubaeb4ommbzktfwgftekzhu5k54n3pps2knhlssbl7ivmidw2dq";

// Collection Metadata
const COLLECTION_NAME: &str = "Orbit Rockets";
const COLLECTION_SYMBOL: &str = "oROCKETS";
const COLLECTION_URI: &str = "https://gateway.pinata.cloud/ipfs/bafkreid2wns4yfnmum7m54zjxq2rfisvzoxntiwzwqoun2hl7dybxwzpau";


#[program]
pub mod orbit_v2 {
    use super::*;

    pub fn ask_for_airdrop(ctx: Context<SendSolToPlayer>) -> Result<()> {
        // Only for testing purposes!
        let authority_seeds: &[&[u8]] = &[b"game_authority", &[ctx.bumps.game_authority]];
        let signer_seeds = &[&authority_seeds[..]];

        system_program::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.system_program.to_account_info(),
                system_program::Transfer {
                    from: ctx.accounts.game_authority.to_account_info(),
                    to: ctx.accounts.player.to_account_info(),
                },
                signer_seeds,
            ),
            1000000000, // 1 SOL
        )?;

        Ok(())
    }

    // Initialize the project:
    // - Mint in-game token
    // - Create leaderboard account
    // - Create collection NFT for the project (simple NFT)
    // - Initialize project data (including skin mint index)
    pub fn initialize_project_data(ctx: Context<InitializeProjectData>) -> Result<()> {
        require!(
            ctx.accounts.owner.key() == PROJECT_OWNER,
            OrbitV2Errors::Unauthorized
        );

        // Initialize leaderboard
        let leaderboard = &mut ctx.accounts.leaderboard;
        leaderboard.players = Vec::new();

        // Initialize project data
        let project_data = &mut ctx.accounts.project_data;
        project_data.skin_mint_index = 0;
        project_data.status = 0;

        Ok(())
    }

    pub fn initialize_token(ctx: Context<InitializeToken>) -> Result<()> {
        require!(
            ctx.accounts.owner.key() == PROJECT_OWNER,
            OrbitV2Errors::Unauthorized
        );

        // Mint the collection NFT (only 1 token)
        let authority_seeds: &[&[u8]] = &["game_authority".as_bytes(), &[ctx.bumps.game_authority]];
        let signer_seeds = &[&authority_seeds[..]];

        create_metadata_accounts_v3(
            CpiContext::new_with_signer(
            ctx.accounts.token_metadata_program.to_account_info(),
            CreateMetadataAccountsV3 {
                payer: ctx.accounts.owner.to_account_info(),
                update_authority: ctx.accounts.game_authority.to_account_info(),
                mint: ctx.accounts.token_mint.to_account_info(),
                metadata: ctx.accounts.token_metadata.to_account_info(),
                mint_authority: ctx.accounts.game_authority.to_account_info(),
                system_program: ctx.accounts.system_program.to_account_info(),
                rent: ctx.accounts.rent.to_account_info(),
            },
            signer_seeds
            ),
            DataV2 {
                name: TOKEN_NAME.to_string(),
                symbol: TOKEN_SYMBOL.to_string(),
                uri: TOKEN_URI.to_string(),
                seller_fee_basis_points: 0,
                creators: None,
                collection: None,
                uses: None,
            },
            true,
            true,
            None
        )?;

        let project_data = &mut ctx.accounts.project_data;
        project_data.token_mint = ctx.accounts.token_mint.key();
        project_data.status = 1;

        Ok(())
    }

    pub fn initialize_collection(ctx: Context<InitializeCollection>) -> Result<()> {
        require!(
            ctx.accounts.owner.key() == PROJECT_OWNER,
            OrbitV2Errors::Unauthorized
        );

        // Mint the collection NFT (only 1 token).
        let authority_seeds: &[&[u8]] = &["game_authority".as_bytes(), &[ctx.bumps.game_authority]];
        let signer_seeds = &[&authority_seeds[..]];

        mint_to(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                MintTo {
                    mint: ctx.accounts.collection_mint.to_account_info(),
                    to: ctx.accounts.associated_token_account.to_account_info(),
                    authority: ctx.accounts.game_authority.to_account_info(),
                },
                signer_seeds,
            ),
            1,
        )?;

        // Create metadata for the collection NFT
        create_metadata_accounts_v3(
            CpiContext::new_with_signer(
                ctx.accounts.token_metadata_program.to_account_info(),
                CreateMetadataAccountsV3 {
                    metadata: ctx.accounts.collection_metadata.to_account_info(),
                    mint: ctx.accounts.collection_mint.to_account_info(),
                    mint_authority: ctx.accounts.game_authority.to_account_info(),
                    payer: ctx.accounts.owner.to_account_info(),
                    update_authority: ctx.accounts.game_authority.to_account_info(),
                    system_program: ctx.accounts.system_program.to_account_info(),
                    rent: ctx.accounts.rent.to_account_info(),
                },
                signer_seeds,
            ),
            DataV2 {
                name: COLLECTION_NAME.to_string(),
                symbol: COLLECTION_SYMBOL.to_string(),
                uri: COLLECTION_URI.to_string(),
                seller_fee_basis_points: 500,
                creators: Some(vec![Creator {
                    address: ctx.accounts.owner.key(),
                    verified: false,
                    share: 100, 
                }]),
                collection: None,
                uses: None,
            },
            true,
            true,
            Some(CollectionDetails::V1 { size: 0 }),
        )?;

        // Create master edition for the collection NFT
        create_master_edition_v3(
            CpiContext::new_with_signer(
                ctx.accounts.token_metadata_program.to_account_info(),
                CreateMasterEditionV3 {
                    edition: ctx.accounts.collection_edition.to_account_info(),
                    mint: ctx.accounts.collection_mint.to_account_info(),
                    update_authority: ctx.accounts.game_authority.to_account_info(),
                    mint_authority: ctx.accounts.game_authority.to_account_info(),
                    payer: ctx.accounts.owner.to_account_info(),
                    metadata: ctx.accounts.collection_metadata.to_account_info(),
                    token_program: ctx.accounts.token_program.to_account_info(),
                    system_program: ctx.accounts.system_program.to_account_info(),
                    rent: ctx.accounts.rent.to_account_info(),
                },
                signer_seeds,
            ),
            Some(0),
        )?;

        // Verify Creator
        sign_metadata(CpiContext::new(
            ctx.accounts.token_metadata_program.to_account_info(),
            SignMetadata {
                creator: ctx.accounts.owner.to_account_info(),
                metadata: ctx.accounts.collection_metadata.to_account_info(),
            }
        ))?;

        
        // Initialize project data
        let project_data = &mut ctx.accounts.project_data;
        project_data.collection_mint = ctx.accounts.collection_mint.key();
        project_data.status = 2;

        Ok(())
    }

    // Register a new player by adding them to the leaderboard and transferring registration fee.
    pub fn new_player(ctx: Context<NewPlayer>) -> Result<()> {
        let leaderboard = &mut ctx.accounts.leaderboard;

        if leaderboard.players.iter().any(|p| p.pubkey == ctx.accounts.player.key()) {
            return Err(OrbitV2Errors::PlayerAlreadyExists.into());
        }

        system_program::transfer(
            CpiContext::new(
                ctx.accounts.system_program.to_account_info(),
                system_program::Transfer {
                    from: ctx.accounts.player.to_account_info(),
                    to: ctx.accounts.owner.to_account_info(),
                },
            ),
            REGISTRATION_FEE,
        )?;

        let new_player = Player {
            pubkey: ctx.accounts.player.key(),
            last_score: 0,
            has_active_try: false,
            upgrades: 0,
        };

        leaderboard.players.push(new_player);

        Ok(())
    }

    // Purchase a game attempt – transfer fee and mark the player's try as active.
    pub fn purchase_game_attempt(ctx: Context<PurchaseGameAttempt>) -> Result<()> {
        let leaderboard = &mut ctx.accounts.leaderboard;
        let player_pubkey = ctx.accounts.player.key();
        let player = leaderboard.players.iter_mut().find(|p| p.pubkey == player_pubkey)
            .ok_or(OrbitV2Errors::PlayerNotFound)?;

        if player.has_active_try {
            return Err(OrbitV2Errors::GameAttemptAlreadyPurchased.into());
        }

        system_program::transfer(
            CpiContext::new(
                ctx.accounts.system_program.to_account_info(),
                system_program::Transfer {
                    from: ctx.accounts.player.to_account_info(),
                    to: ctx.accounts.owner.to_account_info(),
                },
            ),
            GAME_ATTEMPT_FEE,
        )?;

        player.has_active_try = true;
        Ok(())
    }

    // Write the game result, update the player's best score and mint in-game tokens accordingly.
    pub fn write_result(ctx: Context<WriteResult>, score: u64) -> Result<()> {
        let leaderboard = &mut ctx.accounts.leaderboard;
        let player_pubkey = ctx.accounts.player.key();
        let player = leaderboard.players.iter_mut().find(|p| p.pubkey == player_pubkey)
            .ok_or(OrbitV2Errors::PlayerNotFound)?;

        require!(player.has_active_try, OrbitV2Errors::NoActiveTry);

        if score > player.last_score {
            player.last_score = score;
        }
        player.has_active_try = false;

        // For simplicity, tokens to mint equal the score.
        let tokens_to_mint = score * 10u64.pow(6 as u32);
        let authority_seeds: &[&[u8]] = &["game_authority".as_bytes(), &[ctx.bumps.game_authority]];
        let signer_seeds = &[&authority_seeds[..]];

        mint_to(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                MintTo {
                    mint: ctx.accounts.token_mint.to_account_info(),
                    to: ctx.accounts.user_token_account.to_account_info(),
                    authority: ctx.accounts.game_authority.to_account_info(),
                },
                signer_seeds,
            ),
            tokens_to_mint,
        )?;

        Ok(())
    }

    // Purchase an upgrade by transferring tokens from the user to the project owner.
    pub fn buy_upgrade(ctx: Context<BuyUpgrade>) -> Result<()> {
        let leaderboard = &mut ctx.accounts.leaderboard;
        let player_pubkey = ctx.accounts.player.key();
        let player = leaderboard.players.iter_mut().find(|p| p.pubkey == player_pubkey)
            .ok_or(OrbitV2Errors::PlayerNotFound)?;

        if player.upgrades >= 24 {
            return Err(OrbitV2Errors::MaxUpgradesReached.into());
        }
        if ctx.accounts.user_token_account.amount < UPGRADE_COST {
            return Err(OrbitV2Errors::InsufficientTokens.into());
        }

        transfer(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                Transfer {
                    from: ctx.accounts.user_token_account.to_account_info(),
                    to: ctx.accounts.project_owner_token_account.to_account_info(),
                    authority: ctx.accounts.player.to_account_info(),
                },
            ),
            UPGRADE_COST,
        )?;

        player.upgrades += 1;
        Ok(())
    }

    // Purchase a random skin (rocket) NFT.
    // A chest is opened using a pseudo-random value (from Clock). Based on weight the NFT metadata is chosen.
    pub fn purchase_random_skin(ctx: Context<PurchaseRandomSkin>) -> Result<()> {
        // Transfer skin purchase fee from player to project owner.

        if ctx.accounts.user_token_account.amount < SKIN_PRICE {
            return Err(OrbitV2Errors::InsufficientTokens.into());
        }

        transfer(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                Transfer {
                    from: ctx.accounts.user_token_account.to_account_info(),
                    to: ctx.accounts.project_owner_token_account.to_account_info(),
                    authority: ctx.accounts.player.to_account_info(),
                },
            ),
            SKIN_PRICE,
        )?;

        // Get randomness from the clock. (will be improved - not def random)
        let clock = Clock::get()?;
        let random_seed = clock.unix_timestamp as u64;
        let total_weight: u64 = ROCKET_METADATA.iter().map(|&(_, _, _, weight)| weight as u64).sum();
        let rand_val = random_seed % total_weight;

        // Determine selected rocket based on weights.
        let mut cumulative: u64 = 0;
        let mut selected_index: usize = 0;
        for (i, &(_, _, _, weight)) in ROCKET_METADATA.iter().enumerate() {
            cumulative += weight as u64;
            if rand_val < cumulative {
                selected_index = i;
                break;
            }
        }
        let (rocket_name, rocket_symbol, rocket_uri, _) = ROCKET_METADATA[selected_index];

        // Mint the skin NFT using PDA seeds for the skin mint.
        let authority_seeds: &[&[u8]] = &["game_authority".as_bytes(), &[ctx.bumps.game_authority]];
        let signer_seeds = &[&authority_seeds[..]];

        mint_to(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                MintTo {
                    mint: ctx.accounts.skin_mint.to_account_info(),
                    to: ctx.accounts.user_skin_token_account.to_account_info(),
                    authority: ctx.accounts.game_authority.to_account_info(),
                },
                signer_seeds,
            ),
            1,
        )?;

        // Create metadata for the skin NFT.
        create_metadata_accounts_v3(
            CpiContext::new_with_signer(
                ctx.accounts.token_metadata_program.to_account_info(),
                CreateMetadataAccountsV3 {
                    metadata: ctx.accounts.skin_metadata.to_account_info(),
                    mint: ctx.accounts.skin_mint.to_account_info(),
                    mint_authority: ctx.accounts.game_authority.to_account_info(),
                    payer: ctx.accounts.player.to_account_info(),
                    update_authority: ctx.accounts.game_authority.to_account_info(),
                    system_program: ctx.accounts.system_program.to_account_info(),
                    rent: ctx.accounts.rent.to_account_info(),
                },
                signer_seeds
            ),
            DataV2 {
                name: rocket_name.to_string(),
                symbol: rocket_symbol.to_string(),
                uri: rocket_uri.to_string(),
                seller_fee_basis_points: 500,
                creators: Some(vec![
                    Creator {
                        address: PROJECT_OWNER,
                        verified: false,
                        share: 100,
                    },
                    Creator {
                        address: ctx.accounts.game_authority.key(),
                        verified: false,
                        share: 0,
                    }
                ]),
                collection: Some(Collection {
                    key: ctx.accounts.collection_mint.key(),
                    verified: false,
                }),
                uses: None,
            },
            true,
            true,
            None,
        )?;

        create_master_edition_v3(
            CpiContext::new_with_signer(
                ctx.accounts.token_metadata_program.to_account_info(),
                CreateMasterEditionV3 {
                    edition: ctx.accounts.skin_edition_account.to_account_info(),
                    mint: ctx.accounts.skin_mint.to_account_info(),
                    update_authority: ctx.accounts.game_authority.to_account_info(),
                    mint_authority: ctx.accounts.game_authority.to_account_info(),
                    payer: ctx.accounts.player.to_account_info(),
                    metadata: ctx.accounts.skin_metadata.to_account_info(),
                    token_program: ctx.accounts.token_program.to_account_info(),
                    system_program: ctx.accounts.system_program.to_account_info(),
                    rent: ctx.accounts.rent.to_account_info(),
                },
                signer_seeds,
            ),
            Some(0),
        )?;

        set_and_verify_sized_collection_item(
            CpiContext::new_with_signer(
                ctx.accounts.token_metadata_program.to_account_info(),
                SetAndVerifySizedCollectionItem {
                    update_authority: ctx.accounts.game_authority.to_account_info(),
                    payer: ctx.accounts.player.to_account_info(),
                    metadata: ctx.accounts.skin_metadata.to_account_info(),
                    collection_authority: ctx.accounts.game_authority.to_account_info(),
                    collection_mint: ctx.accounts.collection_mint.to_account_info(),
                    collection_metadata: ctx.accounts.collection_metadata.to_account_info(),
                    collection_master_edition: ctx.accounts.collection_master_edition.to_account_info()
                },
                signer_seeds,
            ),
            None,
        )?;

        // Increment the skin mint index.
        ctx.accounts.project_data.skin_mint_index += 1;

        Ok(())
    }
}

// Parameters for project initialization.
#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct InitProjectParams {
    pub token_decimals: u8,
    pub collection_name: String,
    pub collection_symbol: String,
    pub collection_uri: String,
}

// Context for project initialization.
#[derive(Accounts)]
pub struct InitializeProjectData<'info> {
    #[account(mut)]
    pub owner: Signer<'info>,

    #[account(
        init_if_needed,
        payer=owner,
        space=Leaderboard::get_space(0),
        seeds=[b"leaderboard", extra_seed.key().as_ref()],
        bump
    )]
    pub leaderboard: Account<'info, Leaderboard>,

    #[account(
        init_if_needed,
        payer=owner,
        seeds=[b"project_data", extra_seed.key().as_ref()],
        bump,
        space=ProjectData::LEN
    )]
    pub project_data: Account<'info, ProjectData>,
    
    /// CHECK: Extra seed for collection mint PDA.
    pub extra_seed: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct InitializeToken<'info> {
    #[account(mut)]
    pub owner: Signer<'info>,

    #[account(
        init,
        seeds=[b"token_mint", extra_seed.key().as_ref()],
        bump,
        payer=owner,
        mint::decimals=6,
        mint::authority=game_authority,
    )]
    pub token_mint: Account<'info, Mint>,
    /// CHECK: PDA for token metadata.
    #[account(
        mut, 
        seeds=[b"metadata", token_metadata_program.key().as_ref(), token_mint.key().as_ref()],
        bump,
        seeds::program=token_metadata_program.key()
    )]
    pub token_metadata: UncheckedAccount<'info>,

    #[account(
        init_if_needed,
        payer=owner,
        seeds=[b"project_data", extra_seed.key().as_ref()],
        bump,
        space=ProjectData::LEN
    )]
    pub project_data: Account<'info, ProjectData>,
    
    /// CHECK: Orbit authority PDA.
    #[account(
        seeds = [b"game_authority".as_ref()],
        bump,
    )]
    pub game_authority: UncheckedAccount<'info>,
    /// CHECK: Extra seed for collection mint PDA.
    pub extra_seed: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token>,
    /// CHECK: Token Metadata program.
    pub token_metadata_program: Program<'info, Metadata>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct InitializeCollection<'info> {
    #[account(mut)]
    pub owner: Signer<'info>,

    #[account(
        init,
        payer=owner,
        seeds=[b"collection_mint", extra_seed.key().as_ref()],
        bump,
        mint::decimals=0,
        mint::authority=game_authority,
        mint::freeze_authority=game_authority,
    )]
    pub collection_mint: Account<'info, Mint>,
    /// CHECK: PDA for collection metadata.
    #[account(
        mut, 
        seeds=[b"metadata", token_metadata_program.key().as_ref(), collection_mint.key().as_ref()],
        bump,
        seeds::program=token_metadata_program.key()
    )]
    pub collection_metadata: UncheckedAccount<'info>,
    /// CHECK: PDA for collection master edition.
    #[account(
        mut, 
        seeds=[b"metadata", token_metadata_program.key().as_ref(), collection_mint.key().as_ref(), b"edition"],
        bump,
        seeds::program=token_metadata_program.key()
    )]
    pub collection_edition: UncheckedAccount<'info>,
    #[account(
        init_if_needed,
        payer=owner,
        associated_token::mint=collection_mint,
        associated_token::authority=owner,
    )]
    pub associated_token_account: Account<'info, TokenAccount>,

    #[account(
        init_if_needed,
        payer=owner,
        seeds=[b"project_data", extra_seed.key().as_ref()],
        bump,
        space=ProjectData::LEN
    )]
    pub project_data: Account<'info, ProjectData>,
    
    /// CHECK: Orbit authority PDA.
    #[account(
        seeds = [b"game_authority".as_ref()],
        bump,
    )]
    pub game_authority: UncheckedAccount<'info>,
    /// CHECK: Extra seed for collection mint PDA.
    pub extra_seed: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token>,
    /// CHECK: Token Metadata program.
    pub token_metadata_program: Program<'info, Metadata>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub rent: Sysvar<'info, Rent>,
}

// Context for registering a new player.
#[derive(Accounts)]
pub struct NewPlayer<'info> {
    #[account(mut)]
    pub player: Signer<'info>,
    /// CHECK: Must match PROJECT_OWNER.
    #[account(mut, address = PROJECT_OWNER)]
    pub owner: UncheckedAccount<'info>,
    #[account(
        mut,
        seeds=[b"leaderboard", extra_seed.key().as_ref()],
        bump,
        realloc = Leaderboard::get_space(leaderboard.players.len() + 1),
        realloc::payer = player,
        realloc::zero = false,
    )]
    pub leaderboard: Account<'info, Leaderboard>,
    /// CHECK: Extra seed for collection mint PDA.
    pub extra_seed: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}

// Context for purchasing a game attempt.
#[derive(Accounts)]
pub struct PurchaseGameAttempt<'info> {
    #[account(mut)]
    pub player: Signer<'info>,
    /// CHECK: Must match PROJECT_OWNER.
    #[account(mut, address = PROJECT_OWNER)]
    pub owner: UncheckedAccount<'info>,
    #[account(
        mut,
        seeds=[b"leaderboard", extra_seed.key().as_ref()],
        bump,
    )]
    pub leaderboard: Account<'info, Leaderboard>,
    /// CHECK: Extra seed for collection mint PDA.
    pub extra_seed: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}

// Context for writing a game result.
#[derive(Accounts)]
pub struct WriteResult<'info> {
    #[account(mut)]
    pub player: Signer<'info>,
    #[account(
        mut,
        seeds=[b"leaderboard", extra_seed.key().as_ref()],
        bump,
    )]
    pub leaderboard: Account<'info, Leaderboard>,
    pub extra_seed: UncheckedAccount<'info>,
    #[account(
        init_if_needed,
        payer = player,
        associated_token::mint = token_mint,
        associated_token::authority = player,
    )]
    pub user_token_account: Account<'info, TokenAccount>,

    #[account(
        mut,
        seeds=[b"token_mint", extra_seed.key().as_ref()],
        bump,
        mint::authority=game_authority,
    )]
    pub token_mint: Account<'info, Mint>,

    #[account(
        seeds = [b"game_authority".as_ref()],
        bump,
    )]
    pub game_authority: UncheckedAccount<'info>,

    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

// Context for purchasing an upgrade.
#[derive(Accounts)]
pub struct BuyUpgrade<'info> {
    #[account(mut)]
    pub player: Signer<'info>,
    #[account(
        init_if_needed,
        payer = player,
        associated_token::mint = token_mint,
        associated_token::authority = player,
    )]
    pub user_token_account: Account<'info, TokenAccount>,
    #[account(
        init_if_needed,
        payer = player,
        associated_token::mint = token_mint,
        associated_token::authority = owner,
    )]
    pub project_owner_token_account: Account<'info, TokenAccount>,
    #[account(
        mut,
        seeds=[b"leaderboard", extra_seed.key().as_ref()],
        bump,
    )]
    pub leaderboard: Account<'info, Leaderboard>,
    pub extra_seed: UncheckedAccount<'info>,
    /// CHECK: Must match PROJECT_OWNER.
    #[account(mut, address = PROJECT_OWNER)]
    pub owner: UncheckedAccount<'info>,
    #[account(
        mut,
        seeds=[b"token_mint", extra_seed.key().as_ref()],
        bump,
        mint::authority=game_authority,
    )]
    pub token_mint: Account<'info, Mint>,
    #[account(
        seeds = [b"game_authority".as_ref()],
        bump,
    )]
    pub game_authority: UncheckedAccount<'info>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

// Context for purchasing a random skin.
#[derive(Accounts)]
pub struct PurchaseRandomSkin<'info> {
    #[account(mut)]
    pub player: Signer<'info>,
    /// CHECK: Must match PROJECT_OWNER.
    #[account(
        mut,
        seeds=[b"token_mint", extra_seed.key().as_ref()],
        bump,
        mint::authority=game_authority,
    )]
    pub token_mint: Box<Account<'info, Mint>>,
    #[account(
        mut,
        seeds=[b"project_data", extra_seed.key().as_ref()],
        bump,
    )]
    pub project_data: Box<Account<'info, ProjectData>>,
    #[account(
        init_if_needed,
        payer = player,
        associated_token::mint = token_mint,
        associated_token::authority = player,
    )]
    pub user_token_account: Box<Account<'info, TokenAccount>>,
    #[account(
        init_if_needed,
        payer = player,
        associated_token::mint = token_mint,
        associated_token::authority = owner,
    )]
    pub project_owner_token_account: Box<Account<'info, TokenAccount>>,
    #[account(mut, address = PROJECT_OWNER)]
    pub owner: UncheckedAccount<'info>,
    /// CHECK: PDA for skin metadata.
    #[account(
        init,
        payer = player,
        seeds = [b"skin", extra_seed.key().as_ref(), &project_data.skin_mint_index.to_le_bytes()],
        bump,
        mint::decimals = 0,
        mint::authority = game_authority,
        mint::freeze_authority=game_authority,
    )]
    pub skin_mint: Box<Account<'info, Mint>>,
    #[account(
        init_if_needed,
        payer=player,
        associated_token::mint=skin_mint,
        associated_token::authority=player,
    )]
    pub user_skin_token_account: Box<Account<'info, TokenAccount>>,

    #[account(
        mut, 
        seeds = [
            b"metadata", 
            token_metadata_program.key().as_ref(), 
            skin_mint.key().as_ref()
        ], 
        bump,
        seeds::program=token_metadata_program.key()
    )]
    pub skin_metadata: UncheckedAccount<'info>,
    /// CHECK: PDA for skin master edition.
    #[account(
        mut, 
        seeds = [
            b"metadata", 
            token_metadata_program.key().as_ref(), 
            skin_mint.key().as_ref(), 
            b"edition"
        ], 
        bump,
        seeds::program=token_metadata_program.key()
    )]
    pub skin_edition_account: UncheckedAccount<'info>,

    #[account(
        mut,
        seeds=[b"collection_mint", extra_seed.key().as_ref()],
        bump
    )]
    pub collection_mint: Box<Account<'info, Mint>>,
    /// CHECK: PDA for collection metadata.
    #[account(
        mut, 
        seeds=[b"metadata", token_metadata_program.key().as_ref(), collection_mint.key().as_ref()],
        bump,
        seeds::program=token_metadata_program.key()
    )]
    pub collection_metadata: Box<Account<'info, MetadataAccount>>,
    /// CHECK: PDA for collection master edition.
    #[account(
        mut, 
        seeds=[b"metadata", token_metadata_program.key().as_ref(), collection_mint.key().as_ref(), b"edition"],
        bump,
        seeds::program=token_metadata_program.key()
    )]
    pub collection_master_edition: Box<Account<'info, MasterEditionAccount>>,

    pub extra_seed: UncheckedAccount<'info>,

    #[account(
        seeds = [b"game_authority".as_ref()],
        bump,
    )]
    pub game_authority: UncheckedAccount<'info>,

    pub token_program: Program<'info, Token>,
    /// CHECK: Token Metadata program.
    pub token_metadata_program: Program<'info, Metadata>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct SendSolToPlayer<'info> {
    #[account(mut)]
    pub player: Signer<'info>,
    #[account(
        mut,
        seeds = [b"game_authority".as_ref()],
        bump,
    )]
    pub game_authority: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}

#[account]
pub struct Leaderboard {
    // Tracks the number of players.
    pub players: Vec<Player>,
}

impl Leaderboard {
    // Calculate required space:
    // 8 bytes for the discriminator,
    // 4 bytes for num_players,
    // 4 bytes for the vector length,
    // plus space for each player.
    pub fn get_space(num_players: usize) -> usize {
        8 + 4 + 4 + (num_players * Player::LEN)
    }
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct Player {
    pub pubkey: Pubkey,       // 32 bytes
    pub last_score: u64,      // 8 bytes
    pub has_active_try: bool, // 1 byte
    pub upgrades: u8,         // 1 byte
}

impl Player {
    pub const LEN: usize = 32 + 8 + 1 + 1;
}

#[account]
pub struct ProjectData {
    pub collection_mint: Pubkey,
    pub token_mint: Pubkey,
    pub skin_mint_index: u32,
    pub status: u8
}

impl ProjectData {
    pub const LEN: usize = 8 + 32 + 32 + 8 + 8;
}

#[error_code]
pub enum OrbitV2Errors {
    #[msg("Unathorized access")]
    Unauthorized,
    #[msg("Player not found")]
    PlayerNotFound,
    #[msg("Username is too long")]
    UsernameTooLong,
    #[msg("Maximum number of players reached")]
    MaxPlayersReached,
    #[msg("No active game attempt")]
    NoActiveTry,
    #[msg("Maximum number of upgrades reached")]
    MaxUpgradesReached,
    #[msg("Insufficient tokens for upgrade")]
    InsufficientTokens,
    #[msg("Player already exist")]
    PlayerAlreadyExists,
    #[msg("Attempt bought already")]
    GameAttemptAlreadyPurchased,
}
