// src/Components/Auth/ResetPassword.js
import React, { useState } from "react";
import { supabase } from "../../Supabase/supabaseClient";
import "../../Style/Admin.css";

function ResetPassword() {
  const [newPassword, setNewPassword] = useState("");
  const [message, setMessage] = useState("");

  const handleReset = async (e) => {
    e.preventDefault();
    const { error } = await supabase.auth.updateUser({ password: newPassword });
    if (error) setMessage("❌ " + error.message);
    else setMessage("✅ Password updated!");
  };

  return (
    <div className="app-bg">
      <div className="login-container">
        <h2>Reset Password</h2>
        <form className="login-form" onSubmit={handleReset}>
          <input
            type="password"
            placeholder="Enter new password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            required
          />
          <button type="submit">Update Password</button>
        </form>
        {message && <p className="message">{message}</p>}
      </div>
    </div>
  );
}

export default ResetPassword;
