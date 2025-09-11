// supabaseClient.js
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = "https://aoyaedzbgollhajvrxiu.supabase.co";
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFveWFlZHpiZ29sbGhhanZyeGl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyNzY1NzUsImV4cCI6MjA2Mjg1MjU3NX0.iShQfGX-jB7798jk6fLim6m_eGpupzPb8lVgEBTMd1U"; // anon key
export const supabase = createClient(supabaseUrl, supabaseKey);


// import { createClient } from '@supabase/supabase-js'
// const supabaseUrl = 'https://vlsatvnlywpeqjfrrwxu.supabase.co'
// const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsc2F0dm5seXdwZXFqZnJyd3h1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjQ3NjM5NywiZXhwIjoyMDcyMDUyMzk3fQ.VVQZwk9mZ-x8bUArewuL4Yyyau4JdzDx2mV3YKN3ono'
// export const supabase = createClient(supabaseUrl, supabaseKey)