import React, { useState, useEffect } from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import "./App.css";

// Import your components
import Dashboard from "./Components/Dashboard";
import Users from "./Components/Users";
import Applications from "./Components/Applications";
import Clients from "./Components/Clients";
import History from "./Components/History";
import Feedback from "./Components/Feedback";
import { supabase } from "./Supabase/supabaseClient";

// Splash screen
function SplashScreen() {
  return (
    <div className="app-bg">
      <div className="splash-screen">
      <div className="splash-logo">
        <img src="/lslogo.png" alt="Laundry Scout Logo" width="250" height="250" />
      </div>
        <h1 className="splash-title">Laundry Scout</h1>
      </div>
    </div>
    
  );
}

// Admin login
function AdminLogin({ onLogin }) {
  const [username, setUsername] = useState("admin");
  const [password, setPassword] = useState("admin");
  const [error, setError] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();
    if (username === "admin" && password === "admin") {
      setError("");
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
          {error && (
            <div style={{ color: "red", marginBottom: "10px" }}>{error}</div>
          )}
          <div className="forgot-password">
            <a href="#">Forgot Password?</a>
          </div>
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
  const [users, setUsers] = useState([]);

  // Splash screen timeout
  useEffect(() => {
    const timer = setTimeout(() => setShowSplash(false), 2000);
    return () => clearTimeout(timer);
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
      console.error("Error fetching users:", error);
    } else {
      setUsers(data);
    }
  }

  if (showSplash) {
    return <SplashScreen />;
  }

  if (!loggedIn) {
    return <AdminLogin onLogin={() => setLoggedIn(true)} />;
  }

  return (
    <Router>
      <Routes>
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/dashboard" element={<Dashboard users={users} />} />
        <Route path="/users" element={<Users />} />
        <Route path="/applications" element={<Applications />} />
        <Route path="/clients" element={<Clients />} />
        <Route path="/history" element={<History />} />
        <Route path="/feedback" element={<Feedback />} />
        {/* catch-all route */}
        <Route path="*" element={<h2>Page Not Found</h2>} />
      </Routes>
    </Router>
  );
}

export default App;
