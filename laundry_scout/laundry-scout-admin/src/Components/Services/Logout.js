// src/Services/logoutService.js
import { supabase } from "../../Supabase/supabaseClient";

export const handleLogout = async (navigate) => {
  try {
    await supabase.auth.signOut();
    navigate("/login");
  } catch (error) {
    console.error("Error logging out:", error.message);
  }
};
