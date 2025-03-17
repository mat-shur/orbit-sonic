import BN from "bn.js";
import * as web3 from "@solana/web3.js";
import * as anchor from "@coral-xyz/anchor";
import {
  getAssociatedTokenAddressSync,
  getOrCreateAssociatedTokenAccount,
} from "@solana/spl-token";
import type { OrbitV2 } from "../target/types/orbit_v2";

describe("Test", () => {
  // Configure the client to use the local cluster
  anchor.setProvider(anchor.AnchorProvider.env());

  const program = anchor.workspace.OrbitV2 as anchor.Program<OrbitV2>;
  
  const extra_seed = "test1";

  const [gameAuthorityPDA] = anchor.web3.PublicKey.findProgramAddressSync(
    [Buffer.from("game_authority")],
    program.programId
  );

  console.log(gameAuthorityPDA.toString())

  const METAPLEX_PROGRAM_ID = new anchor.web3.PublicKey(
    "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"
  );

  const [extraSeedPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from(extra_seed)],
      program.programId
    );

  const [sd] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("token_mint"), extraSeedPDA.toBuffer()],
      program.programId
    );

    console.log(sd.toString())

  

  it.skip("init", async () => {
    const [extraSeedPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from(extra_seed)],
      program.programId
    );

    const [tokenMintPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("token_mint"), extraSeedPDA.toBuffer()],
      program.programId
    );

    const [tokenMetadataPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("metadata"),
        METAPLEX_PROGRAM_ID.toBuffer(),
        tokenMintPDA.toBuffer(),
      ],
      METAPLEX_PROGRAM_ID
    );

    const [collectionMintPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("collection_mint"), extraSeedPDA.toBuffer()],
      program.programId
    );

    const [collectionMetadataPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("metadata"),
        METAPLEX_PROGRAM_ID.toBuffer(),
        collectionMintPDA.toBuffer(),
      ],
      METAPLEX_PROGRAM_ID
    );

    const [collectionEditionPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("metadata"),
        METAPLEX_PROGRAM_ID.toBuffer(),
        collectionMintPDA.toBuffer(),
        Buffer.from("edition"),
      ],
      METAPLEX_PROGRAM_ID
    );

    const associatedTokenAccount = getAssociatedTokenAddressSync(
      collectionMintPDA,
      program.provider.publicKey
    );

    const [leaderboardPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("leaderboard"), extraSeedPDA.toBuffer()],
      program.programId
    );

    const [projectDataPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("project_data"), extraSeedPDA.toBuffer()],
      program.programId
    );

    


    const initializeProjectData = {
      owner: program.provider.publicKey,

      leaderboard: leaderboardPDA,
      projectData: projectDataPDA,

      extraSeed: extraSeedPDA,

      systemProgram: web3.SystemProgram.programId,
      rent: web3.SYSVAR_RENT_PUBKEY,
    };

    const initializeToken = {
      owner: program.provider.publicKey,

      tokenMint: tokenMintPDA,
      tokenMetadata: tokenMetadataPDA,

      projectData: projectDataPDA,

      gameAuthority: gameAuthorityPDA,

      extraSeed: extraSeedPDA,

      systemProgram: web3.SystemProgram.programId,
      rent: web3.SYSVAR_RENT_PUBKEY,
      associatedTokenProgram: anchor.utils.token.ASSOCIATED_PROGRAM_ID,
      tokenProgram: anchor.utils.token.TOKEN_PROGRAM_ID,
      tokenMetadataProgram: METAPLEX_PROGRAM_ID,
    };

    const initializeCollection = {
      owner: program.provider.publicKey,

      collectionEdition: collectionEditionPDA,
      collectionMetadata: collectionMetadataPDA,
      collectionMint: collectionMintPDA,

      associatedTokenAccount: associatedTokenAccount,

      projectData: projectDataPDA,

      gameAuthority: gameAuthorityPDA,

      extraSeed: extraSeedPDA,

      systemProgram: web3.SystemProgram.programId,
      rent: web3.SYSVAR_RENT_PUBKEY,
      associatedTokenProgram: anchor.utils.token.ASSOCIATED_PROGRAM_ID,
      tokenProgram: anchor.utils.token.TOKEN_PROGRAM_ID,
      tokenMetadataProgram: METAPLEX_PROGRAM_ID,
    };

    const transaction = new web3.Transaction();

    transaction.add(
      web3.ComputeBudgetProgram.setComputeUnitLimit({
        units: 300_000,
      })
    );

    const instuction = await program.methods
      .initializeProjectData()
      .accounts(initializeProjectData)
      .instruction();

    transaction.add(instuction);

    const latestBlockhash1 = await program.provider.connection.getLatestBlockhash();
    transaction.recentBlockhash = latestBlockhash1.blockhash;
    transaction.feePayer = program.provider.publicKey;

    try {
      const simulateResult = await anchor.utils.rpc.simulateTransaction(
        program.provider.connection,
        transaction
      );
      if (simulateResult.value && simulateResult.value.logs) {
        console.log("Simulation logs:", simulateResult.value.logs);
      }
    } catch (simError) {
      console.error("Simulation failed:", simError);

      if (simError.logs) {
        console.log("Simulation logs:", simError.logs);
      } else if (simError.error && simError.error.logs) {
        console.log("Simulation logs:", simError.error.logs);
      } else {
        console.log("No simulation logs available.");
      }
    }

    const result_1 = await web3.sendAndConfirmTransaction(
      program.provider.connection,
      transaction,
      [program.provider.wallet.payer]
    );

    console.log("Simulation successful:", result_1);

    const transaction2 = new web3.Transaction();

    transaction2.add(
      web3.ComputeBudgetProgram.setComputeUnitLimit({
        units: 300_000,
      })
    );

    const instuction2 = await program.methods
      .initializeToken()
      .accounts(initializeToken)
      .instruction();

    transaction2.add(instuction2);

    const latestBlockhash2 = await program.provider.connection.getLatestBlockhash();
    transaction2.recentBlockhash = latestBlockhash2.blockhash;
    transaction2.feePayer = program.provider.publicKey;

    try {
      const simulateResult = await anchor.utils.rpc.simulateTransaction(
        program.provider.connection,
        transaction2
      );
      if (simulateResult.value && simulateResult.value.logs) {
        console.log("Simulation logs:", simulateResult.value.logs);
      }
    } catch (simError) {
      console.error("Simulation failed:", simError);

      if (simError.logs) {
        console.log("Simulation logs:", simError.logs);
      } else if (simError.error && simError.error.logs) {
        console.log("Simulation logs:", simError.error.logs);
      } else {
        console.log("No simulation logs available.");
      }
    }

    const result_2 = await web3.sendAndConfirmTransaction(
      program.provider.connection,
      transaction2,
      [program.provider.wallet.payer]
    );

    console.log("Simulation successful:", result_2);

    const transaction3 = new web3.Transaction();

    transaction3.add(
      web3.ComputeBudgetProgram.setComputeUnitLimit({
        units: 300_000,
      })
    );

    const instuction3 = await program.methods
      .initializeCollection()
      .accounts(initializeCollection)
      .instruction();

    transaction3.add(instuction3);

    const latestBlockhash3 = await program.provider.connection.getLatestBlockhash();
    transaction3.recentBlockhash = latestBlockhash3.blockhash;
    transaction3.feePayer = program.provider.publicKey;

    try {
      const simulateResult = await anchor.utils.rpc.simulateTransaction(
        program.provider.connection,
        transaction3
      );
      if (simulateResult.value && simulateResult.value.logs) {
        console.log("Simulation logs:", simulateResult.value.logs);
      }
    } catch (simError) {
      console.error("Simulation failed:", simError);

      if (simError.logs) {
        console.log("Simulation logs:", simError.logs);
      } else if (simError.error && simError.error.logs) {
        console.log("Simulation logs:", simError.error.logs);
      } else {
        console.log("No simulation logs available.");
      }
    }

    const result_3 = await web3.sendAndConfirmTransaction(
      program.provider.connection,
      transaction3,
      [program.provider.wallet.payer]
    );

    console.log("Simulation successful:", result_3);
  
});








it.skip("ask_airdrop", async () => {

    const askAirdrop = {
      player: program.provider.publicKey,
      gameAuthority: gameAuthorityPDA,
      systemProgram: web3.SystemProgram.programId
    };

    const transaction = new web3.Transaction();

    transaction.add(
      web3.ComputeBudgetProgram.setComputeUnitLimit({
        units: 300_000,
      })
    );

    const instuction = await program.methods
      .askForAirdrop()
      .accounts(askAirdrop)
      .instruction();

    transaction.add(instuction);

    const latestBlockhash1 = await program.provider.connection.getLatestBlockhash();
    transaction.recentBlockhash = latestBlockhash1.blockhash;
    transaction.feePayer = program.provider.publicKey;

    try {
      const simulateResult = await anchor.utils.rpc.simulateTransaction(
        program.provider.connection,
        transaction
      );
      if (simulateResult.value && simulateResult.value.logs) {
        console.log("Simulation logs:", simulateResult.value.logs);
      }
    } catch (simError) {
      console.error("Simulation failed:", simError);

      if (simError.logs) {
        console.log("Simulation logs:", simError.logs);
      } else if (simError.error && simError.error.logs) {
        console.log("Simulation logs:", simError.error.logs);
      } else {
        console.log("No simulation logs available.");
      }
    }

    const result_1 = await web3.sendAndConfirmTransaction(
      program.provider.connection,
      transaction,
      [program.provider.wallet.payer]
    );

    console.log("Simulation successful:", result_1);
  
});















it.skip("new_player", async () => {
    const [extraSeedPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from(extra_seed)],
      program.programId
    );


    const [leaderboardPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("leaderboard"), extraSeedPDA.toBuffer()],
      program.programId
    );

    const owner = new web3.PublicKey("E6NeMvQVdqHCy1xtUpqkvpSToZLYACwBshZPuFtHrSof");


    const newPlayer = {
      owner: owner,
      player: program.provider.publicKey,

      leaderboard: leaderboardPDA,
      extraSeed: extraSeedPDA,

      systemProgram: web3.SystemProgram.programId,
      rent: web3.SYSVAR_RENT_PUBKEY,
    };

    const transaction = new web3.Transaction();

    transaction.add(
      web3.ComputeBudgetProgram.setComputeUnitLimit({
        units: 300_000,
      })
    );

    const instuction = await program.methods
      .newPlayer()
      .accounts(newPlayer)
      .instruction();

    transaction.add(instuction);

    const latestBlockhash1 = await program.provider.connection.getLatestBlockhash();
    transaction.recentBlockhash = latestBlockhash1.blockhash;
    transaction.feePayer = program.provider.publicKey;

    try {
      const simulateResult = await anchor.utils.rpc.simulateTransaction(
        program.provider.connection,
        transaction
      );
      if (simulateResult.value && simulateResult.value.logs) {
        console.log("Simulation logs:", simulateResult.value.logs);
      }
    } catch (simError) {
      console.error("Simulation failed:", simError);

      if (simError.logs) {
        console.log("Simulation logs:", simError.logs);
      } else if (simError.error && simError.error.logs) {
        console.log("Simulation logs:", simError.error.logs);
      } else {
        console.log("No simulation logs available.");
      }
    }

    const result_1 = await web3.sendAndConfirmTransaction(
      program.provider.connection,
      transaction,
      [program.provider.wallet.payer]
    );

    console.log("Simulation successful:", result_1);
  
});





it.skip("purchase_attempt", async () => {
    const [extraSeedPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from(extra_seed)],
      program.programId
    );


    const [leaderboardPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("leaderboard"), extraSeedPDA.toBuffer()],
      program.programId
    );

    const owner = new web3.PublicKey("E6NeMvQVdqHCy1xtUpqkvpSToZLYACwBshZPuFtHrSof");


    const purchaseAttempt = {
      owner: owner,
      player: program.provider.publicKey,

      leaderboard: leaderboardPDA,
      extraSeed: extraSeedPDA,

      systemProgram: web3.SystemProgram.programId,
      rent: web3.SYSVAR_RENT_PUBKEY,
    };

    const transaction = new web3.Transaction();

    transaction.add(
      web3.ComputeBudgetProgram.setComputeUnitLimit({
        units: 300_000,
      })
    );

    const instuction = await program.methods
      .purchaseGameAttempt()
      .accounts(purchaseAttempt)
      .instruction();

    transaction.add(instuction);

    const latestBlockhash1 = await program.provider.connection.getLatestBlockhash();
    transaction.recentBlockhash = latestBlockhash1.blockhash;
    transaction.feePayer = program.provider.publicKey;

    try {
      const simulateResult = await anchor.utils.rpc.simulateTransaction(
        program.provider.connection,
        transaction
      );
      if (simulateResult.value && simulateResult.value.logs) {
        console.log("Simulation logs:", simulateResult.value.logs);
      }
    } catch (simError) {
      console.error("Simulation failed:", simError);

      if (simError.logs) {
        console.log("Simulation logs:", simError.logs);
      } else if (simError.error && simError.error.logs) {
        console.log("Simulation logs:", simError.error.logs);
      } else {
        console.log("No simulation logs available.");
      }
    }

    const result_1 = await web3.sendAndConfirmTransaction(
      program.provider.connection,
      transaction,
      [program.provider.wallet.payer]
    );

    console.log("Simulation successful:", result_1);
  
});





















it.skip("write_result", async () => {
    const [extraSeedPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from(extra_seed)],
      program.programId
    );


    const [leaderboardPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("leaderboard"), extraSeedPDA.toBuffer()],
      program.programId
    );

    const owner = new web3.PublicKey("E6NeMvQVdqHCy1xtUpqkvpSToZLYACwBshZPuFtHrSof");
    const tokenMint = new web3.PublicKey("6yFXXXe9qiLMdenf2sfBdYZ3EgYxNEMrSPNj5HsqCjVi")

    const associatedTokenAccount = getAssociatedTokenAddressSync(
      tokenMint,
      program.provider.publicKey
    );


    const writeResult = {
      player: program.provider.publicKey,

      leaderboard: leaderboardPDA,
      extraSeed: extraSeedPDA,

      userTokenAccount: associatedTokenAccount,

      tokenMint: tokenMint,

      gameAuthority: gameAuthorityPDA,

      systemProgram: web3.SystemProgram.programId,
      rent: web3.SYSVAR_RENT_PUBKEY,
      associatedTokenProgram: anchor.utils.token.ASSOCIATED_PROGRAM_ID,
      tokenProgram: anchor.utils.token.TOKEN_PROGRAM_ID,
    };

    const transaction = new web3.Transaction();

    transaction.add(
      web3.ComputeBudgetProgram.setComputeUnitLimit({
        units: 300_000,
      })
    );

    const instuction = await program.methods
      .writeResult(new BN(200000))
      .accounts(writeResult)
      .instruction();

    transaction.add(instuction);

    const latestBlockhash1 = await program.provider.connection.getLatestBlockhash();
    transaction.recentBlockhash = latestBlockhash1.blockhash;
    transaction.feePayer = program.provider.publicKey;

    try {
      const simulateResult = await anchor.utils.rpc.simulateTransaction(
        program.provider.connection,
        transaction
      );
      if (simulateResult.value && simulateResult.value.logs) {
        console.log("Simulation logs:", simulateResult.value.logs);
      }
    } catch (simError) {
      console.error("Simulation failed:", simError);

      if (simError.logs) {
        console.log("Simulation logs:", simError.logs);
      } else if (simError.error && simError.error.logs) {
        console.log("Simulation logs:", simError.error.logs);
      } else {
        console.log("No simulation logs available.");
      }
    }

    const result_1 = await web3.sendAndConfirmTransaction(
      program.provider.connection,
      transaction,
      [program.provider.wallet.payer]
    );

    console.log("Simulation successful:", result_1);
  
});




















it.skip("buy_upgrade", async () => {
    const [extraSeedPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from(extra_seed)],
      program.programId
    );


    const [leaderboardPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("leaderboard"), extraSeedPDA.toBuffer()],
      program.programId
    );

    const owner = new web3.PublicKey("E6NeMvQVdqHCy1xtUpqkvpSToZLYACwBshZPuFtHrSof");
    const tokenMint = new web3.PublicKey("6yFXXXe9qiLMdenf2sfBdYZ3EgYxNEMrSPNj5HsqCjVi")

    const associatedTokenAccount = getAssociatedTokenAddressSync(
      tokenMint,
      program.provider.publicKey
    );

    const associatedTokenOwnerAccount = getAssociatedTokenAddressSync(
      tokenMint,
      owner
    );


    const buyUpgrade = {
      player: program.provider.publicKey,

      leaderboard: leaderboardPDA,
      extraSeed: extraSeedPDA,

      userTokenAccount: associatedTokenAccount,
      projectOwnerTokenAccount: associatedTokenOwnerAccount,
      owner: owner,

      tokenMint: tokenMint,

      gameAuthority: gameAuthorityPDA,

      systemProgram: web3.SystemProgram.programId,
      rent: web3.SYSVAR_RENT_PUBKEY,
      associatedTokenProgram: anchor.utils.token.ASSOCIATED_PROGRAM_ID,
      tokenProgram: anchor.utils.token.TOKEN_PROGRAM_ID,
    };

    const transaction = new web3.Transaction();

    transaction.add(
      web3.ComputeBudgetProgram.setComputeUnitLimit({
        units: 300_000,
      })
    );

    const instuction = await program.methods
      .buyUpgrade()
      .accounts(buyUpgrade)
      .instruction();

    transaction.add(instuction);

    const latestBlockhash1 = await program.provider.connection.getLatestBlockhash();
    transaction.recentBlockhash = latestBlockhash1.blockhash;
    transaction.feePayer = program.provider.publicKey;

    try {
      const simulateResult = await anchor.utils.rpc.simulateTransaction(
        program.provider.connection,
        transaction
      );
      if (simulateResult.value && simulateResult.value.logs) {
        console.log("Simulation logs:", simulateResult.value.logs);
      }
    } catch (simError) {
      console.error("Simulation failed:", simError);

      if (simError.logs) {
        console.log("Simulation logs:", simError.logs);
      } else if (simError.error && simError.error.logs) {
        console.log("Simulation logs:", simError.error.logs);
      } else {
        console.log("No simulation logs available.");
      }
    }

    const result_1 = await web3.sendAndConfirmTransaction(
      program.provider.connection,
      transaction,
      [program.provider.wallet.payer]
    );

    console.log("Simulation successful:", result_1);
  
});










it.skip("mint_rocket", async () => {
    const [extraSeedPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from(extra_seed)],
      program.programId
    );


    const [leaderboardPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("leaderboard"), extraSeedPDA.toBuffer()],
      program.programId
    );

    console.log(leaderboardPDA.toString())

    const owner = new web3.PublicKey("E6NeMvQVdqHCy1xtUpqkvpSToZLYACwBshZPuFtHrSof");
    const [tokenMint] = anchor.web3.PublicKey.findProgramAddressSync(
  [Buffer.from("token_mint"), extraSeedPDA.toBuffer()],
  program.programId
);

    const associatedTokenAccount = getAssociatedTokenAddressSync(
      tokenMint,
      program.provider.publicKey
    );

    const associatedTokenOwnerAccount = getAssociatedTokenAddressSync(
      tokenMint,
      owner
    );

    const [projectDataPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("project_data"), extraSeedPDA.toBuffer()],
      program.programId
    );

    const projectData = await program.account.projectData.fetch(projectDataPDA);
    console.log(projectData)

    const test = Buffer.from(projectData.skinMintIndex.toString(16).padStart(8, '0'), 'hex').reverse()

    const [skinMintPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("skin"), extraSeedPDA.toBuffer(), test],
      program.programId
    );

    const associatedSkinAccount = getAssociatedTokenAddressSync(
      skinMintPDA,
      program.provider.publicKey
    );

    const [skinMetadataPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("metadata"),
        METAPLEX_PROGRAM_ID.toBuffer(),
        skinMintPDA.toBuffer(),
      ],
      METAPLEX_PROGRAM_ID
    );
    console.log(skinMetadataPDA.toString())

    const [skinEditionPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("metadata"),
        METAPLEX_PROGRAM_ID.toBuffer(),
        skinMintPDA.toBuffer(),
        Buffer.from("edition"),
      ],
      METAPLEX_PROGRAM_ID
    );

    const [collectionMintPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("collection_mint"), extraSeedPDA.toBuffer()],
      program.programId
    );

    const [collectionMetadataPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("metadata"),
        METAPLEX_PROGRAM_ID.toBuffer(),
        collectionMintPDA.toBuffer(),
      ],
      METAPLEX_PROGRAM_ID
    );

    const [collectionEditionPDA] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("metadata"),
        METAPLEX_PROGRAM_ID.toBuffer(),
        collectionMintPDA.toBuffer(),
        Buffer.from("edition"),
      ],
      METAPLEX_PROGRAM_ID
    );


    const mintRocket = {
      player: program.provider.publicKey,

      owner: owner,
      tokenMint: tokenMint,
      projectData: projectDataPDA,

      extraSeed: extraSeedPDA,

      userTokenAccount: associatedTokenAccount,
      projectOwnerTokenAccount: associatedTokenOwnerAccount,

      skinMint: skinMintPDA,
      userSkinTokenAccount: associatedSkinAccount,
      skinMetadata: skinMetadataPDA,
      skinEditionAccount: skinEditionPDA,

      collectionMint: collectionMintPDA,
      collectionMetadata: collectionMetadataPDA,
      collectionMasterEdition: collectionEditionPDA,

      gameAuthority: gameAuthorityPDA,

      systemProgram: web3.SystemProgram.programId,
      rent: web3.SYSVAR_RENT_PUBKEY,
      associatedTokenProgram: anchor.utils.token.ASSOCIATED_PROGRAM_ID,
      tokenProgram: anchor.utils.token.TOKEN_PROGRAM_ID,
      tokenMetadataProgram: METAPLEX_PROGRAM_ID,
    };

    const transaction = new web3.Transaction();

    transaction.add(
      web3.ComputeBudgetProgram.setComputeUnitLimit({
        units: 300_000,
      })
    );

    const instuction = await program.methods
      .purchaseRandomSkin()
      .accounts(mintRocket)
      .instruction();

    transaction.add(instuction);

    const latestBlockhash1 = await program.provider.connection.getLatestBlockhash();
    transaction.recentBlockhash = latestBlockhash1.blockhash;
    transaction.feePayer = program.provider.publicKey;

    try {
      const simulateResult = await anchor.utils.rpc.simulateTransaction(
        program.provider.connection,
        transaction
      );
      if (simulateResult.value && simulateResult.value.logs) {
        console.log("Simulation logs:", simulateResult.value.logs);
      }
    } catch (simError) {
      console.error("Simulation failed:", simError);

      if (simError.logs) {
        console.log("Simulation logs:", simError.logs);
      } else if (simError.error && simError.error.logs) {
        console.log("Simulation logs:", simError.error.logs);
      } else {
        console.log("No simulation logs available.");
      }
    }

    const result_1 = await web3.sendAndConfirmTransaction(
      program.provider.connection,
      transaction,
      [program.provider.wallet.payer]
    );

    console.log("Simulation successful:", result_1);
  
});
});