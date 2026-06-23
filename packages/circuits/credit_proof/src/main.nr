fn main(
    score: Field,
    threshold: pub Field,
    agent_address: pub Field,
    commitment: pub Field,
    block_number: pub Field
) {
    assert(score as u64 >= 300);
    assert(score as u64 <= 900);
    assert(score as u64 >= threshold as u64);
    let computed_commitment = std::hash::pedersen_hash([score, agent_address]);
    assert(computed_commitment == commitment);
}
