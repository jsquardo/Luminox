# frozen_string_literal: true

require "httparty"

class BlockchainService
  # ============================================================================
  # This service handles all communication with the Ethereum blockchain via Alchemy
  # It fetches transactions, address information, and other blockchain data
  # ============================================================================

  include HTTParty

  # Alchemy API endpoint (mainnet)
  BASE_URL = "https://eth-mainnet.g.alchemy.com/v2"

  # Get your API key from environment variables (you'll set this later)
  attr_reader :api_key

  def initialize(api_key = nil)
    @api_key = api_key || ENV["ALCHEMY_API_KEY"]
    raise "ALCHEMY_API_KEY not set in environment variables" if @api_key.blank?
  end

  # ============================================================================
  # PUBLIC METHODS
  # ============================================================================

  # Fetch the most recent transactions from the blockchain
  # This gets transactions from the latest blocks
  def fetch_recent_transactions(limit: 100)
    # Get the latest block number first
    latest_block = get_latest_block_number
    return [] if latest_block.nil?

    # Fetch transactions from recent blocks
    transactions = []

    # Check the last few blocks (we'll start with 10)
    (latest_block - 10..latest_block).reverse_each do |block_number|
      block_txs = get_block_transactions(block_number)
      transactions.concat(block_txs) if block_txs.any?
      break if transactions.count >= limit
    end

    transactions.take(limit)
  end

  # Get all transactions for a specific address
  # This returns both sent and received transactions
  def get_address_transactions(address, limit: 100)
    validate_address(address)

    response = make_request(
      method: "alchemy_getAssetTransfers",
      params: [
        {
          fromAddress: address,
          category: ["external", "internal", "erc20", "erc721", "erc1155"]
        }
      ]
    )

    parse_transfers(response)
  end

  # Get information about a specific address
  def get_address_info(address)
    validate_address(address)

    # Get balance
    balance_response = make_request(
      method: "eth_getBalance",
      params: [address, "latest"]
    )

    balance = balance_response["result"]

    # Get transaction count (how many transactions from this address)
    tx_count_response = make_request(
      method: "eth_getTransactionCount",
      params: [address, "latest"]
    )

    tx_count = tx_count_response["result"]

    # Get code (if it's a contract, it will have code)
    code_response = make_request(
      method: "eth_getCode",
      params: [address, "latest"]
    )

    is_contract = code_response["result"] != "0x"

    {
      address: address,
      balance: balance,
      transaction_count: tx_count,
      is_contract: is_contract
    }
  end

  # Get a specific transaction by hash
  def get_transaction(tx_hash)
    validate_tx_hash(tx_hash)

    response = make_request(
      method: "eth_getTransactionByHash",
      params: [tx_hash]
    )

    parse_transaction(response["result"])
  end

  # Get the latest block number
  def get_latest_block_number
    response = make_request(
      method: "eth_blockNumber",
      params: []
    )

    # Convert hex to integer
    result = response["result"]
    result.nil? ? nil : result.to_i(16)
  end

  # Get all transactions in a specific block
  def get_block_transactions(block_number)
    block_hex = "0x#{block_number.to_s(16)}"

    response = make_request(
      method: "eth_getBlockByNumber",
      params: [block_hex, true] # true = include transactions
    )

    block_data = response["result"]
    return [] if block_data.nil?

    transactions = block_data["transactions"] || []
    transactions.map { |tx| parse_transaction(tx) }
  end

  # Get token transfers for an address (ERC-20 tokens)
  def get_token_transfers(address, limit: 100)
    validate_address(address)

    response = make_request(
      method: "alchemy_getAssetTransfers",
      params: [
        {
          fromAddress: address,
          category: ["erc20"]
        }
      ]
    )

    parse_transfers(response, token: true)
  end

  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================

  private

  # Make a JSON-RPC request to Alchemy
  def make_request(method:, params: [])
    url = "#{BASE_URL}/#{api_key}"

    body = {
      jsonrpc: "2.0",
      method: method,
      params: params,
      id: 1
    }

    begin
      response = HTTParty.post(
        url,
        body: body.to_json,
        headers: {"Content-Type" => "application/json"},
        timeout: 30
      )

      parsed = JSON.parse(response.body)

      # Check for errors in the response
      if parsed["error"]
        Rails.logger.error("Alchemy API Error: #{parsed['error']['message']}")
        return {"result" => nil, "error" => parsed["error"]}
      end

      parsed
    rescue StandardError => e
      Rails.logger.error("Alchemy API Request Failed: #{e.message}")
      {"result" => nil, "error" => e.message}
    end
  end

  # Parse a raw transaction from the blockchain into our format
  def parse_transaction(tx_data)
    return nil if tx_data.nil?

    {
      tx_hash: tx_data["hash"],
      from_address: tx_data["from"],
      to_address: tx_data["to"],
      value: hex_to_wei(tx_data["value"]),
      gas_price: hex_to_wei(tx_data["gasPrice"]),
      block_number: hex_to_int(tx_data["blockNumber"]),
      timestamp: get_block_timestamp(hex_to_int(tx_data["blockNumber"])),
      is_contract_interaction: tx_data["input"] != "0x"
    }
  end

  # Parse token transfers from Alchemy response
  def parse_transfers(response, token: false)
    result = response["result"]
    return [] if result.nil?

    transfers = result["transfers"] || []

    transfers.map do |transfer|
      {
        tx_hash: transfer["hash"],
        from_address: transfer["from"],
        to_address: transfer["to"],
        value: transfer["rawContract"]["value"],
        token_address: transfer["rawContract"]["address"],
        token_symbol: transfer["asset"],
        timestamp: Time.at(transfer["blockNum"].to_i(16)),
        is_token: true
      }
    end
  end

  # Helper: Convert hex string to Wei (as integer)
  def hex_to_wei(hex_value)
    return 0 if hex_value.nil?
    hex_value.to_i(16)
  end

  # Helper: Convert hex string to integer
  def hex_to_int(hex_value)
    return 0 if hex_value.nil?
    hex_value.to_i(16)
  end

  # Helper: Get the timestamp of a block
  # (This is cached because blocks don't change)
  def get_block_timestamp(block_number)
    block_hex = "0x#{block_number.to_s(16)}"
    response = make_request(
      method: "eth_getBlockByNumber",
      params: [block_hex, false]
    )

    block_data = response["result"]
    return Time.current if block_data.nil?

    timestamp = block_data["timestamp"].to_i(16)
    Time.at(timestamp)
  end

  # Helper: Validate Ethereum address format
  def validate_address(address)
    unless address.match?(/\A0x[a-fA-F0-9]{40}\z/)
      raise ArgumentError, "Invalid Ethereum address: #{address}"
    end
  end

  # Helper: Validate transaction hash format
  def validate_tx_hash(tx_hash)
    unless tx_hash.match?(/\A0x[a-fA-F0-9]{64}\z/)
      raise ArgumentError, "Invalid transaction hash: #{tx_hash}"
    end
  end
end
