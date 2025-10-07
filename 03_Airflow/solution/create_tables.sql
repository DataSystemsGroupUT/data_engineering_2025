-- Database: prices_db
-- Replace with: CREATE DATABASE prices_db; if needed

-- Table to store raw BTC prices
CREATE TABLE IF NOT EXISTS btc_prices (
    id SERIAL PRIMARY KEY,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    price NUMERIC(18,8) NOT NULL
);

-- Table to store rolling averages
CREATE TABLE IF NOT EXISTS btc_rolling_avg (
    id SERIAL PRIMARY KEY,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    rolling_avg NUMERIC(18,8) NOT NULL
);

-- Table to log triggered orders
CREATE TABLE IF NOT EXISTS orders_log (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    payload JSONB,
    response JSONB,
    status VARCHAR(32)
);
