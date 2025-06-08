-- Aetherium Database Seed Data Migration
-- Version: 002
-- Description: Insert sample data for development and testing

-- Insert sample company phone numbers
INSERT INTO company_number_pool (phone_number, is_active) VALUES
('+998901234567', true),
('+998901234568', true),
('+998901234569', true),
('+998901234570', true),
('+998901234571', true),
('+998901234572', true),
('+998901234573', true),
('+998901234574', true),
('+998901234575', true),
('+998901234576', true)
ON CONFLICT (phone_number) DO NOTHING;

-- Insert sample GSM modems
INSERT INTO gsm_modems (device_path, phone_number, imei, operator, signal_strength, status) VALUES
('/dev/ttyUSB0', '+998901234567', '123456789012345', 'Ucell', 85, 'active'),
('/dev/ttyUSB1', '+998901234568', '123456789012346', 'Beeline', 78, 'active'),
('/dev/ttyUSB2', '+998901234569', '123456789012347', 'UMS', 92, 'active'),
('/dev/ttyUSB3', '+998901234570', '123456789012348', 'Ucell', 67, 'inactive'),
('/dev/ttyUSB4', '+998901234571', '123456789012349', 'Beeline', 89, 'active')
ON CONFLICT (device_path) DO NOTHING;

-- Insert sample scribe workflows
INSERT INTO scribe_workflows (user_id, name, description, prompt_template, voice_settings) VALUES
(1, 'Customer Support', 'General customer support workflow', 
'You are a helpful customer support representative. Greet the customer warmly and assist them with their inquiry. Be professional, empathetic, and solution-oriented.',
'{"voice": "en-US-AriaNeural", "rate": "+0%", "pitch": "+0Hz"}'),

(1, 'Sales Inquiry', 'Handle sales and product inquiries',
'You are a knowledgeable sales representative. Help customers understand our products and services. Be enthusiastic but not pushy. Focus on how our solutions can benefit them.',
'{"voice": "en-US-DavisNeural", "rate": "+5%", "pitch": "+2Hz"}'),

(1, 'Appointment Booking', 'Schedule appointments and meetings',
'You are an appointment scheduler. Help customers book appointments efficiently. Confirm dates, times, and contact information. Be clear about availability and policies.',
'{"voice": "en-US-JennyNeural", "rate": "+0%", "pitch": "+0Hz"}'),

(1, 'Technical Support', 'Provide technical assistance',
'You are a technical support specialist. Help customers troubleshoot issues step by step. Be patient and clear in your explanations. Ask relevant questions to diagnose problems.',
'{"voice": "en-US-GuyNeural", "rate": "-5%", "pitch": "-1Hz"}'),

(1, 'Survey Collection', 'Conduct customer satisfaction surveys',
'You are conducting a brief customer satisfaction survey. Be polite and respectful of the customer\'s time. Ask clear questions and thank them for their feedback.',
'{"voice": "en-US-AriaNeural", "rate": "+0%", "pitch": "+0Hz"}')
ON CONFLICT DO NOTHING;

-- Insert sample dream journal entries for testing
INSERT INTO dream_journal_entries (user_id, title, content, mood, tags, dream_date) VALUES
(1, 'Flying Over Mountains', 
'I was soaring above snow-capped mountains with incredible freedom. The air was crisp and I could see for miles. There was a sense of peace and accomplishment.',
'peaceful', ARRAY['flying', 'mountains', 'freedom'], CURRENT_DATE - INTERVAL '1 day'),

(1, 'Lost in a Library', 
'I found myself in an enormous library with endless shelves. I was searching for a specific book but the layout kept changing. Other people were there but they seemed to ignore me.',
'anxious', ARRAY['library', 'searching', 'confusion'], CURRENT_DATE - INTERVAL '2 days'),

(1, 'Meeting an Old Friend', 
'I encountered my childhood friend in a familiar neighborhood. We talked about old times and shared memories. It felt warm and nostalgic.',
'nostalgic', ARRAY['friendship', 'childhood', 'memories'], CURRENT_DATE - INTERVAL '3 days')
ON CONFLICT DO NOTHING;

-- Insert sample support tickets
INSERT INTO support_tickets (user_id, subject, description, category, priority, status) VALUES
(1, 'Unable to make outbound calls', 
'I am experiencing issues when trying to make outbound calls. The system shows an error message about modem connectivity.',
'technical', 'high', 'open'),

(1, 'Billing question about subscription', 
'I have a question about my recent billing statement. The amount seems different from what I expected.',
'billing', 'medium', 'open'),

(1, 'Feature request: Custom voice training', 
'It would be great to have the ability to train custom voices for specific use cases in our business.',
'feature_request', 'low', 'open')
ON CONFLICT DO NOTHING;

-- Insert sample call statistics
INSERT INTO call_statistics (user_id, date, total_calls, successful_calls, failed_calls, total_duration_seconds, average_duration_seconds) VALUES
(1, CURRENT_DATE - INTERVAL '1 day', 25, 22, 3, 3600, 144.0),
(1, CURRENT_DATE - INTERVAL '2 days', 18, 16, 2, 2880, 160.0),
(1, CURRENT_DATE - INTERVAL '3 days', 30, 28, 2, 4200, 140.0),
(1, CURRENT_DATE - INTERVAL '4 days', 22, 20, 2, 3300, 150.0),
(1, CURRENT_DATE - INTERVAL '5 days', 27, 25, 2, 3750, 138.9),
(1, CURRENT_DATE - INTERVAL '6 days', 20, 18, 2, 2700, 135.0),
(1, CURRENT_DATE - INTERVAL '7 days', 24, 22, 2, 3480, 145.0)
ON CONFLICT DO NOTHING;

-- Insert sample communication sessions
INSERT INTO communication_sessions (user_id, workflow_id, phone_number, status, started_at, ended_at, duration_seconds, transcript, ai_response) VALUES
(1, 1, '+998901111111', 'completed', 
 CURRENT_TIMESTAMP - INTERVAL '2 hours', 
 CURRENT_TIMESTAMP - INTERVAL '2 hours' + INTERVAL '3 minutes', 
 180,
 'Customer: Hello, I need help with my account. AI: Hello! I\'d be happy to help you with your account. What specific issue are you experiencing?',
 'I provided assistance with account access issues and guided the customer through the password reset process.'),

(1, 2, '+998902222222', 'completed',
 CURRENT_TIMESTAMP - INTERVAL '4 hours',
 CURRENT_TIMESTAMP - INTERVAL '4 hours' + INTERVAL '5 minutes',
 300,
 'Customer: I\'m interested in your premium plan. AI: Great! I\'d love to tell you about our premium features...',
 'I explained the premium plan benefits and answered questions about pricing and features.'),

(1, 3, '+998903333333', 'completed',
 CURRENT_TIMESTAMP - INTERVAL '6 hours',
 CURRENT_TIMESTAMP - INTERVAL '6 hours' + INTERVAL '2 minutes',
 120,
 'Customer: I need to schedule an appointment. AI: I can help you schedule an appointment. What type of service do you need?',
 'I successfully scheduled an appointment for next Tuesday at 2 PM and sent confirmation details.')
ON CONFLICT DO NOTHING;

-- Update user subscription to basic plan
UPDATE user_subscriptions 
SET tier_id = (SELECT id FROM subscription_tiers WHERE name = 'basic'),
    expires_at = CURRENT_TIMESTAMP + INTERVAL '30 days',
    next_payment_date = CURRENT_TIMESTAMP + INTERVAL '30 days'
WHERE user_id = 1;

-- Insert a subscription if none exists
INSERT INTO user_subscriptions (user_id, tier_id, expires_at, next_payment_date)
SELECT 1, 
       (SELECT id FROM subscription_tiers WHERE name = 'basic'),
       CURRENT_TIMESTAMP + INTERVAL '30 days',
       CURRENT_TIMESTAMP + INTERVAL '30 days'
WHERE NOT EXISTS (SELECT 1 FROM user_subscriptions WHERE user_id = 1);

-- Insert sample payment transaction
INSERT INTO payment_transactions (user_id, subscription_id, amount, currency, payment_method, transaction_id, status, payment_date) VALUES
(1, 
 (SELECT id FROM user_subscriptions WHERE user_id = 1 LIMIT 1),
 29.99, 
 'USD', 
 'bank_transfer', 
 'TXN_' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::TEXT,
 'completed',
 CURRENT_TIMESTAMP - INTERVAL '1 day')
ON CONFLICT DO NOTHING;