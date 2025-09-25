// src/Components/Auth/ForgotPassword.js
import React, { useState } from "react";
import { supabase } from "../../Supabase/supabaseClient";
import "../../Style/Admin.css";

function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);

  const handleForgot = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage("");

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: "http://localhost:3000/reset-password", // ⚠️ Update for production
    });

    if (error) {
      setMessage("❌ " + error.message);
    } else {
      setMessage("✅ Password reset link sent! Please check your email.");
    }
    setLoading(false);
  };

  return (
    <div className="app-bg">
      <div className="login-container">
        <div className="login-logo">
          <img src="/lslogo.png" alt="Laundry Scout Logo" width="60" height="60" />
        </div>
        <h2 className="login-title">Forgot Password</h2>

        <form className="login-form" onSubmit={handleForgot}>
          <input
            type="email"
            placeholder="Enter your registered email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          <button type="submit" disabled={loading}>
            {loading ? "Sending..." : "Send Reset Link"}
          </button>
        </form>

        {message && <p className="message">{message}</p>}

        <div className="forgot-password">
          <a href="/admin">⬅ Back to Login</a>
        </div>
      </div>
    </div>
  );
}

export default ForgotPassword;
