Treasury DAO Smart Contract

Overview

The Treasury DAO Smart Contract is a decentralized governance system built on the Stacks blockchain (Clarity language).
It allows a community to manage shared treasury funds through weighted voting, where members have voting power proportional to their assigned weights. Proposals can be created, voted on, and executed if passed, enabling transparent and decentralized decision-making.

✨ Features

Membership Management

Add members with specific voting power (only contract owner).

Update member voting power dynamically.

Track when each member joined.

Proposal System

Members can create funding proposals (title, description, recipient, and amount).

Automatic voting deadline (~24 hours).

Weighted voting (based on member voting power).

Prevents double-voting.

Voting & Execution

Members cast yes/no votes with their assigned voting power.

A proposal passes if yes-votes > no-votes after the deadline.

Passed proposals transfer STX from the DAO treasury to the recipient.

Prevents execution if insufficient funds or if proposal already executed.

Treasury Management

Members can deposit funds into the DAO treasury.

Proposals execute payouts directly from treasury balance.

Transparency & Read-only Queries

Retrieve member information.

Retrieve proposals and their status.

Check votes on specific proposals.

View treasury balance.

Query total voting power and proposal count.

Verify if a proposal has passed.

⚙️ Contract Structure
Constants

Predefined error codes for member management, proposals, voting, and treasury.

Contract owner is defined at deployment.

Data Storage

members → Map of principals with voting power and join timestamp.

proposals → Map of proposal details (title, description, recipient, votes, etc.).

votes → Map to prevent duplicate votes and track weighted voting.

proposal-counter → Tracks total number of proposals.

total-voting-power → Tracks global voting power across all members.

Public Functions

add-member → Add a new DAO member.

update-member-voting-power → Update a member’s voting weight.

create-proposal → Submit a new proposal.

vote → Cast a weighted vote (yes/no).

execute-proposal → Execute passed proposals and transfer funds.

deposit-funds → Deposit STX into DAO treasury.

Read-only Functions

get-member → Fetch member details.

get-proposal → Fetch proposal details.

get-vote → Fetch a voter’s decision on a proposal.

get-treasury-balance → Get DAO’s STX balance.

get-total-voting-power → Get sum of all members’ voting power.

get-proposal-count → Get total proposals created.

is-proposal-passed → Check if a proposal passed after voting deadline.

🚀 Example Flow

Contract owner adds members with voting power.

A member creates a proposal requesting funds.

Members vote on the proposal using their weighted power.

Once the deadline passes, the DAO checks if yes > no votes.

If passed, the DAO executes the proposal and transfers funds.

🔒 Security Considerations

Only the contract owner can add/update members.

Voting is restricted to registered members.

Prevents double voting by mapping each voter per proposal.

Ensures execution only happens once per proposal.

Transfers only occur if the DAO has enough STX balance.

📌 Future Improvements

Quorum requirements (minimum turnout for validity).

Proposal cancellation by creator or DAO.

Weighted multi-choice proposals.

Upgradeable DAO governance rules.