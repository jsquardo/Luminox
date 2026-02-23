# Luminox Architecture Plan

## Overview
Luminox monitors the Ethereum blockchain for suspicious activity, patterns, and anomalies. The system continuously fetches transactions, analyzes them, and provides real-time alerts and visualizations.

## Core Features (MVP)
1. **Wallet Clustering & Entity Detection** - Identify when one entity controls multiple wallets
2. **Pump-and-Dump Pattern Detection** - Spot suspicious token transfer patterns
3. **Money Trail Visualization** - Visualize fund flows between addresses
4. **Risk Scoring** - Flag suspicious behavior (dormant wallets moving funds, circular transfers)
5. **Real-time Alerts** - Notify on high-value transactions
6. **Time-based Pattern Analysis** - Analyze wallet behavior over time

## Database Models

### Core Models
1. **Address**
   - address: string (unique, indexed)
   - label: string (optional - "suspicious", "whale", "bot", etc.)
   - first_seen: datetime
   - last_seen: datetime
   - transaction_count: integer
   - total_sent: decimal
   - total_received: decimal
   - is_contract: boolean
   - risk_score: float (0-100)
   - cluster_id: integer (foreign key to AddressCluster)

2. **Transaction**
   - tx_hash: string (unique, indexed)
   - from_address: string (indexed)
   - to_address: string (indexed)
   - value: decimal
   - gas_price: decimal
   - block_number: integer (indexed)
   - timestamp: datetime (indexed)
   - token_symbol: string (optional)
   - is_contract_interaction: boolean
   - anomaly_score: float (0-100)
   - is_alerted: boolean

3. **AddressCluster**
   - cluster_name: string
   - address_count: integer
   - created_at: datetime
   - cluster_score: float (0-100)
   - cluster_type: string (wallet_cluster, exchange, bot, etc.)

4. **RiskAlert**
   - alert_type: string (high_value, dormant_activation, pump_dump, circular_transfer, etc.)
   - related_transaction_id: integer (foreign key)
   - related_address: string (indexed)
   - risk_score: float
   - description: text
   - is_read: boolean
   - created_at: datetime

5. **AddressPattern**
   - address: string (indexed)
   - pattern_type: string (dormant_activation, rapid_transfers, etc.)
   - pattern_data: jsonb (stores pattern metadata)
   - confidence: float (0-100)
   - detected_at: datetime

6. **TokenTransfer** (for token monitoring)
   - tx_hash: string
   - from_address: string (indexed)
   - to_address: string (indexed)
   - token_address: string (indexed)
   - token_symbol: string
   - amount: decimal
   - timestamp: datetime (indexed)
   - is_suspicious: boolean
   - anomaly_type: string

## Data Flow Architecture

```
Ethereum Network (via API)
    ↓
API Integration Layer (Alchemy/Etherscan)
    ↓
Transaction Ingestion Service (Background Job)
    ↓
Processing Pipeline:
  1. Store raw transaction
  2. Extract addresses
  3. Calculate risk scores
  4. Detect patterns
  5. Update address clusters
  6. Generate alerts
    ↓
Database
    ↓
Rails API Endpoints
    ↓
React + Inertia Frontend
    ↓
Visualizations & Real-time Alerts
```

## Key Services & Classes

### 1. BlockchainService (API Integration)
- Responsible for fetching data from Ethereum API
- Methods: fetch_transactions, fetch_address_info, fetch_token_transfers
- Uses Alchemy or Etherscan API

### 2. TransactionProcessor
- Takes raw transaction data
- Extracts addresses
- Stores transaction records
- Triggers analysis pipeline

### 3. RiskScoringService
- Analyzes individual transactions and addresses
- Calculates risk scores based on:
  - Transaction size relative to wallet history
  - Dormancy period before transaction
  - Circular transfer patterns
  - Token transfer anomalies
- Returns risk score (0-100)

### 4. PatternDetectionService
- Identifies suspicious patterns:
  - Wallet clustering (same entity multiple wallets)
  - Pump-and-dump sequences
  - Dormant activation
  - Rapid circular transfers
  - Flash loan attacks

### 5. AlertService
- Generates alerts based on risk scores and patterns
- Stores alerts in database
- Could integrate with notifications (email, webhooks)

### 6. VisualizationService
- Prepares data for frontend visualizations
- Transaction flow graphs
- Address relationship mapping
- Timeline data

## API Endpoints (Rails)

### Transactions
- `GET /api/transactions` - List recent transactions with filters
- `GET /api/transactions/:id` - Transaction details
- `GET /api/transactions/address/:address` - Transactions for specific address

### Addresses
- `GET /api/addresses` - High-risk addresses
- `GET /api/addresses/:address` - Detailed address info & history
- `GET /api/addresses/:address/cluster` - Addresses in same cluster
- `GET /api/addresses/:address/timeline` - Time-based pattern analysis

### Alerts
- `GET /api/alerts` - List all alerts (with filters)
- `POST /api/alerts/:id/read` - Mark alert as read

### Analytics
- `GET /api/analytics/risk-distribution` - Risk score distribution
- `GET /api/analytics/top-suspicious` - Top suspicious addresses/transactions
- `GET /api/analytics/patterns` - Pattern statistics

### Visualization Data
- `GET /api/visualizations/money-trail/:address` - Transaction flow graph
- `GET /api/visualizations/cluster/:cluster_id` - Cluster relationship visualization

## Frontend Pages (React + Inertia)

1. **Dashboard**
   - Real-time alerts feed
   - Risk score distribution chart
   - High-value transactions widget
   - Top suspicious addresses widget

2. **Transactions**
   - Paginated transaction list
   - Filters (by address, risk score, date range)
   - Transaction detail modal

3. **Addresses**
   - Address list with risk scores
   - Address detail page with:
     - Transaction history
     - Cluster information
     - Timeline/pattern analysis
     - Money trail visualization
   - Search/filter

4. **Alerts**
   - Alert list with filters
   - Alert detail view
   - Mark as read functionality

5. **Analytics/Reports**
   - Risk score distribution
   - Top suspicious entities
   - Pattern trends over time

## Background Jobs

1. **FetchTransactionsJob**
   - Runs every 12-30 seconds
   - Fetches latest Ethereum transactions
   - Processes and stores them

2. **AnalyzeTransactionsJob**
   - Analyzes stored transactions
   - Calculates risk scores
   - Detects patterns
   - Generates alerts

3. **UpdateAddressMetricsJob**
   - Updates address statistics
   - Recalculates cluster assignments
   - Runs periodically (every 5-10 minutes)

4. **CleanupJob**
   - Removes old alerts/data (configurable retention)
   - Runs daily

## Testing Strategy

1. **Load Testing**
   - Create fake users and seed transaction data
   - Simulate concurrent API calls
   - Monitor database and processing performance
   - Test with 1000+ addresses and 10000+ transactions

2. **Unit Tests**
   - Risk scoring logic
   - Pattern detection algorithms
   - Data transformation services

3. **Integration Tests**
   - API endpoint tests
   - Background job tests
   - Database transaction handling

## Configuration & Environment

- API Keys: Alchemy/Etherscan endpoints stored in environment variables
- Risk Score Thresholds: Configurable in initializers
- Alert Types: Configurable alert rules
- Data Retention: Configurable cleanup policies

## Implementation Phases

### Phase 1 (MVP)
- Set up models and migrations
- Implement blockchain API integration
- Build basic transaction ingestion
- Simple risk scoring
- Basic alert generation
- Simple dashboard and transaction list views

### Phase 2
- Advanced pattern detection
- Wallet clustering
- Money trail visualization
- Real-time alerts
- More comprehensive dashboard

### Phase 3
- Analytics and reporting
- Advanced filtering
- Machine learning for pattern detection
- User preferences and saved searches
- Export functionality

## Tech Stack
- **Backend**: Rails 8, Ruby
- **Frontend**: React + TypeScript, Inertia.js
- **Database**: PostgreSQL
- **Jobs**: Sidekiq or similar
- **API**: Alchemy or Etherscan
- **Real-time**: ActionCable (optional, for live alerts)
- **Visualization**: Recharts or D3.js