-- ====================================================================================================
-- Project 10: Enterprise Knowledge & Workflow Agent Platform
-- Course: n8n Full-Stack Enterprise Automation Engineering
-- Code: N8N-FIN-PRJ-10 | Evaluator: Deepesh Jain
-- Complete Enterprise PostgreSQL Schema & Seed Data (schema.sql)
-- ====================================================================================================

-- 0. Enable Required PostgreSQL Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- 1. Employee Directory & RBAC Roles Table
DROP TABLE IF EXISTS employee_leave_requests CASCADE;
DROP TABLE IF EXISTS enterprise_it_tickets CASCADE;
DROP TABLE IF EXISTS agent_execution_audit CASCADE;
DROP TABLE IF EXISTS enterprise_knowledge CASCADE;
DROP TABLE IF EXISTS enterprise_crm_clients CASCADE;
DROP TABLE IF EXISTS enterprise_users CASCADE;

CREATE TABLE enterprise_users (
    user_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('EMPLOYEE', 'MANAGER', 'EXECUTIVE')),
    department VARCHAR(100) NOT NULL,
    manager_email VARCHAR(255),
    annual_leave_balance INT DEFAULT 20 CHECK (annual_leave_balance >= 0)
);

-- 2. Knowledge Base with RBAC Metadata Filter & Vector Embeddings
CREATE TABLE enterprise_knowledge (
    chunk_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_title VARCHAR(255) NOT NULL,
    section_title VARCHAR(255) NOT NULL,
    required_role_tier VARCHAR(50) NOT NULL CHECK (required_role_tier IN ('EMPLOYEE', 'MANAGER', 'EXECUTIVE')),
    chunk_content TEXT NOT NULL,
    embedding VECTOR(1536), -- Compatible with OpenAI text-embedding-3-small
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_knowledge_role_tier ON enterprise_knowledge(required_role_tier);

-- 3. Leave Requests Master Table
CREATE TABLE employee_leave_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(50) REFERENCES enterprise_users(user_id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days_count INT NOT NULL CHECK (days_count > 0),
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING_APPROVAL' CHECK (status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED')),
    approved_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. IT Service Tickets Table
CREATE TABLE enterprise_it_tickets (
    ticket_id VARCHAR(50) PRIMARY KEY,
    submitted_by VARCHAR(50) REFERENCES enterprise_users(user_id) ON DELETE CASCADE,
    issue_category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    urgency VARCHAR(50) NOT NULL CHECK (urgency IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    ticket_status VARCHAR(50) DEFAULT 'OPEN' CHECK (ticket_status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Enterprise CRM Client Account Database
CREATE TABLE enterprise_crm_clients (
    client_id VARCHAR(50) PRIMARY KEY,
    client_name VARCHAR(150) UNIQUE NOT NULL,
    contract_status VARCHAR(50) NOT NULL CHECK (contract_status IN ('ACTIVE', 'EXPIRING_SOON', 'DELINQUENT', 'CHURNED')),
    active_mrr NUMERIC(12, 2) NOT NULL,
    renewal_date DATE NOT NULL,
    account_manager VARCHAR(100) NOT NULL,
    tier VARCHAR(50) DEFAULT 'ENTERPRISE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Agent Audit & Telemetry Ledger
CREATE TABLE agent_execution_audit (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(50) REFERENCES enterprise_users(user_id) ON DELETE SET NULL,
    user_prompt TEXT NOT NULL,
    tools_invoked JSONB NOT NULL,
    agent_response TEXT NOT NULL,
    latency_ms INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================================================
-- SEED DATA INGESTION FOR ENTERPRISE DEMONSTRATION & TEST SCENARIOS
-- ====================================================================================================

-- Seed Users
INSERT INTO enterprise_users (user_id, name, email, role, department, manager_email, annual_leave_balance)
VALUES
('USER-EMP-4019', 'Kavita Reddy', 'kavita.r@enterprise.com', 'EMPLOYEE', 'Engineering', 'vikram.singh@enterprise.com', 14),
('USER-EMP-9912', 'Rahul Verma', 'rahul.v@enterprise.com', 'EMPLOYEE', 'Operations', 'vikram.singh@enterprise.com', 2),
('USER-MGR-2010', 'Vikram Singh', 'vikram.singh@enterprise.com', 'MANAGER', 'Engineering', 'priya.sharma@enterprise.com', 22),
('USER-EXEC-1001', 'Priya Sharma', 'priya.sharma@enterprise.com', 'EXECUTIVE', 'Executive Leadership', 'board@enterprise.com', 30);

-- Seed Knowledge Base Chunks with RBAC Classification
INSERT INTO enterprise_knowledge (document_title, section_title, required_role_tier, chunk_content)
VALUES
('Corporate Travel Policy 2026', 'Domestic Flight Reimbursement', 'EMPLOYEE',
 'Employees traveling on company business are authorized for economy class commercial domestic flights booked at least 14 days in advance. Meals are reimbursed up to $75 USD per diem with valid itemized receipts. Ground transit via Uber/Lyft is covered for airport transfers and client meetings. Source: SOP-TRAVEL-2026-V2.'),

('IT Remote Access Standard Operating Procedure', 'VPN Client Configuration & Error 789', 'EMPLOYEE',
 'Remote staff must authenticate via the Enterprise GlobalProtect VPN using FIDO2 MFA keys. Error 789 indicates an IPsec / L2TP connection failure where the security negotiation layer timed out. Users should flush DNS via `ipconfig /flushdns`, ensure UDP ports 500 and 4500 are open, or submit an urgent IT ticket for gateway certificate re-issuance. Source: SOP-SEC-NET-789.'),

('HR Leave & Time Off Policy', 'Annual & Medical Leave Accrual', 'EMPLOYEE',
 'Full-time enterprise personnel receive 20 business days of paid annual leave per calendar year. Up to 5 consecutive business days may be approved directly by immediate managers via workflow approval cards. Requests exceeding 5 consecutive days require second-level Department Head sign-off. Source: HR-POL-LEAVE-2026.'),

('Management Operations Handbook', 'Manager Performance Review Guidelines', 'MANAGER',
 'Managers are required to conduct bi-quarterly performance calibration for all Level 1 and Level 2 reports. Compensation adjustments within the 3% to 7% merit band may be recommended directly in Workday by managers prior to Q3 close. Source: MGR-OPS-REV-2026.'),

('Executive Compensation Covenant', 'C-Suite Bonus Tiers & Equity Acceleration', 'EXECUTIVE',
 'CONFIDENTIAL RESTRICTED: Executive leadership bonus compensation tiers are evaluated on annual EBITDA benchmarks: Tier 1 (100% target achievement) yields a 45% base bonus multiplier; Tier 2 (125% target) triggers a 75% multiplier with 25% accelerated vesting on Class A preferred equity shares. Source: EXEC-CONFIDENTIAL-COMP-2026.');

-- Seed CRM Accounts
INSERT INTO enterprise_crm_clients (client_id, client_name, contract_status, active_mrr, renewal_date, account_manager)
VALUES
('CRM-ACME-01', 'Acme Corporation', 'ACTIVE', 45000.00, '2027-04-15', 'Vikram Singh'),
('CRM-GLOBEX-02', 'Globex Systems', 'EXPIRING_SOON', 18500.00, '2026-12-31', 'Vikram Singh'),
('CRM-INITECH-03', 'Initech Solutions', 'ACTIVE', 82000.00, '2027-09-30', 'Priya Sharma');
