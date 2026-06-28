use std::hash::poseidon;

fn main(
    // PRIVATE — never revealed
    score: Field,

    // PUBLIC — visible to verifier
    threshold: pub Field,
    agent_address: pub Field,
    commitment: pub Field,
    block_number: pub Field
) {
    // Constraint 1: score is a valid credit score
    assert(score as u64 >= 300);
    assert(score as u64 <= 900);

    // Constraint 2: score exceeds the claimed threshold
    assert(score as u64 >= threshold as u64);

    // Constraint 3: commitment matches on-chain stored value
    // Use Poseidon BN254 hash with 2 inputs — MUST match PoseidonT3.hash() in Solidity
    let computed_commitment: Field = poseidon::bn254::hash_2([score, agent_address]);
    assert(computed_commitment == commitment);

    // Constraint 4: block_number is included to prevent proof replay
    // The verifier checks this is within 3600 blocks of current block
    // We don't constrain it here — it's a public input the API checks off-chain
    let _ = block_number; // silence unused warning
}
