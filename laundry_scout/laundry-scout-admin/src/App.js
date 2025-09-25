// src/App.js
import React, { useState, useEffect } from "react";
import { BrowserRouter as Router, Routes, Route, Navigate, Link } from "react-router-dom";
import "./App.css";
import { supabase } from "./Supabase/supabaseClient";

// Import your components
import Dashboard from "./Components/Dashboard";
import Users from "./Components/Users";
import Applications from "./Components/Applications";
import Clients from "./Components/Clients";
import History from "./Components/History";
import Feedback from "./Components/Feedback";
import ClientDetails from "./Components/Details/ClientDetails";
import Profile from "./Components/settings/Profile";
import Settings from "./Components/settings/Settings";
import ForgotPassword from "./Components/Auth/ForgotPassword";

// Splash screen
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

// Admin login
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
            <label>
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
              />{" "}
              Remember Me
            </label>
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

// Main App
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
