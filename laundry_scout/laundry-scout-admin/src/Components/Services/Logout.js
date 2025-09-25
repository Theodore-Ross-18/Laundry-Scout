// src/Components/Services/Logout.js
import { supabase } from "../../Supabase/supabaseClient";

export const handleLogout = async (navigate, onLogout, setLoggingOut) => {
  try {
    setLoggingOut(true); // disable button
    const { error } = await supabase.auth.signOut();
    if (error) throw error;

    if (onLogout) onLogout();
    navigate("/");
  } catch (error) {
    console.error("❌ Logout failed:", error.message);
  } finally {
    setLoggingOut(false);
  }
};
