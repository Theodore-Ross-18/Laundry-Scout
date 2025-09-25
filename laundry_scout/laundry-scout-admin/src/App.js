// src/App.js
import React, { useState, useEffect } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
  Link,
} from "react-router-dom";
import "./App.css";
import { supabase } from "./Supabase/supabaseClient";

// Your pages/components
import Dashboard from "./Components/Dashboard";
import Users from "./Components/Users";
import Applications from "./Components/Applications";
import Clients from "./Components/Clients";
import History from "./Components/History";
import Feedback from "./Components/Feedback";
import ClientDetails from "./Components/Details/ClientDetails";
import Profile from "./Components/settings/Profile";
import Settings from "./Components/settings/Settings";

/* ---------------- Splash screen ---------------- */
function SplashScreen() {
  return (
    <div className="app-bg">
      <div className="splash-screen">
        <div className="splash-logo">
          <img src="/lslogo.png" alt="Laundry Scout Logo" width="100" height="100" />
        </div>
        <h1 className="splash-title">Laundry Scout</h1>
      </div>
    </div>
  );
}

/* ---------------- Admin Login ---------------- */
function AdminLogin({ onLogin }) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState("");

  // Load saved credentials
  useEffect(() => {
    const savedUser = localStorage.getItem("admin-username");
    const savedPass = localStorage.getItem("admin-password");
    if (savedUser && savedPass) {
      setUsername(savedUser);
      setPassword(savedPass);
      setRememberMe(true);
    }
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (username === "admin" && password === "admin") {
      setError("");

      // Save credentials if "Remember Me" checked
      if (rememberMe) {
        localStorage.setItem("admin-username", username);
        localStorage.setItem("admin-password", password);
      } else {
        localStorage.removeItem("admin-username");
        localStorage.removeItem("admin-password");
      }

      onLogin();
    } else {
      setError("Invalid username or password");
    }
  };

  return (
    <div className="app-bg">
      <div className="login-container">
        <div className="login-logo">
          <img src="/lslogo.png" alt="Laundry Scout Logo" width="60" height="60" />
        </div>
        <h2 className="login-title">Welcome Admin</h2>
        <form className="login-form" onSubmit={handleSubmit}>
          <input
            type="text"
            placeholder="Username or email"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
          />
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          {/* Remember Me checkbox */}
          <div className="remember-forgot">
            <div className="remember-checkbox">
              <label>
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                />{" "}
                Remember Me
              </label>
            </div>

            <div className="forgot-password">
              <Link to="/forgot-password">Forgot Password?</Link>
            </div>
          </div>

          {error && <div style={{ color: "red", marginBottom: "10px" }}>{error}</div>}
          <button type="submit">Login</button>
        </form>
      </div>
    </div>
  );
}

/* ---------------- Forgot Password ---------------- */
function ForgotPassword() {
  const [step, setStep] = useState(1);
  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [serverOtp, setServerOtp] = useState("");
  const [newUsername, setNewUsername] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const sendOtp = async () => {
    if (!email) {
      setError("Please enter your registered email.");
      return;
    }
    const generatedOtp = Math.floor(100000 + Math.random() * 900000).toString();
    setServerOtp(generatedOtp);
    console.log("Simulated OTP (would send email):", generatedOtp);
    setMessage("OTP sent to your email.");
    setError("");
    setStep(2);
  };

  const verifyOtp = () => {
    if (otp === serverOtp) {
      setStep(3);
      setMessage("OTP verified. Set your new credentials.");
      setError("");
    } else {
      setError("Invalid OTP. Please try again.");
    }
  };

  const resetCredentials = async () => {
    if (!newUsername || !newPassword) {
      setError("Please fill in both fields.");
      return;
    }
    const { error: updateError } = await supabase
      .from("admin")
      .update({ username: newUsername, password: newPassword })
      .eq("email", email);

    if (updateError) {
      setError(updateError.message);
    } else {
      setMessage("Credentials updated successfully. You can now log in.");
      setError("");
      // Reset form after success
      setStep(1);
      setEmail("");
      setOtp("");
      setNewUsername("");
      setNewPassword("");
    }
  };

  const buttonLabel =
    step === 1 ? "Send OTP" : step === 2 ? "Verify OTP" : "Reset Credentials";

  const handleAction = () => {
    if (step === 1) sendOtp();
    if (step === 2) verifyOtp();
    if (step === 3) resetCredentials();
  };

  return (
    <div className="app-bg">
      <div className="login-container">
        <div className="login-logo">
          <img src="/lslogo.png" alt="Laundry Scout Logo" width="60" height="60" />
        </div>
        <h2 className="login-title">Forgot Password</h2>

        {message && <div style={{ color: "green", marginBottom: "10px" }}>{message}</div>}
        {error && <div style={{ color: "red", marginBottom: "10px" }}>{error}</div>}

        <form
          className="login-form"
          onSubmit={(e) => {
            e.preventDefault();
            handleAction();
          }}
        >
          {step === 1 && (
            <input
              type="email"
              placeholder="Enter your registered email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          )}

          {step === 2 && (
            <input
              type="text"
              placeholder="Enter the OTP you received"
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
            />
          )}

          {step === 3 && (
            <>
              <input
                type="text"
                placeholder="New username"
                value={newUsername}
                onChange={(e) => setNewUsername(e.target.value)}
              />
              <input
                type="password"
                placeholder="New password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
              />
            </>
          )}

          <button type="submit">{buttonLabel}</button>
        </form>

        <div style={{ marginTop: "15px", textAlign: "center" }}>
          <Link to="/" style={{ textDecoration: "none", color: "#fff"}}>
            ← Back to Login
          </Link>
        </div>
      </div>
    </div>
  );
}

/* ---------------- Main App ---------------- */
function App() {
  const [showSplash, setShowSplash] = useState(true);
  const [loggedIn, setLoggedIn] = useState(false);
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState([]);

  // Splash screen timeout
  useEffect(() => {
    const timer = setTimeout(() => setShowSplash(false), 2000);
    return () => clearTimeout(timer);
  }, []);

  // Track Supabase session (auto handles login/logout)
  useEffect(() => {
    const checkSession = async () => {
      const { data } = await supabase.auth.getSession();
      setLoggedIn(!!data.session);
      setLoading(false);
    };
    checkSession();

    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      setLoggedIn(!!session);
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  // Fetch users after login
  useEffect(() => {
    if (loggedIn) {
      fetchUsers();
    }
  }, [loggedIn]);

  async function fetchUsers() {
    const { data, error } = await supabase.from("users").select("*");
    if (error) {
      console.error("Error fetching users:", error.message);
    } else {
      setUsers(data);
    }
  }

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setLoggedIn(false);
  };

  if (showSplash) return <SplashScreen />;
  if (loading) return <div className="loading-screen">Loading...</div>;

  return (
    <Router>
      {!loggedIn ? (
        <Routes>
          <Route path="/" element={<AdminLogin onLogin={() => setLoggedIn(true)} />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      ) : (
        <Routes>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<Dashboard users={users} onLogout={handleLogout} />} />
          <Route path="/users" element={<Users onLogout={handleLogout} />} />
          <Route path="/applications" element={<Applications onLogout={handleLogout} />} />
          <Route path="/clients" element={<Clients onLogout={handleLogout} />} />
          <Route path="/clients/:id" element={<ClientDetails onLogout={handleLogout} />} />
          <Route path="/history" element={<History onLogout={handleLogout} />} />
          <Route path="/feedback" element={<Feedback onLogout={handleLogout} />} />
          <Route path="/settings" element={<Settings onLogout={handleLogout} />} />
          <Route path="/profile" element={<Profile onLogout={handleLogout} />} />
          <Route path="*" element={<h2>Page Not Found</h2>} />
        </Routes>
      )}
    </Router>
  );
}

export default App;
