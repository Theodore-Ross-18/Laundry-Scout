// src/Components/Admin/Settings.js
import React, { useState, useEffect } from "react";
import { supabase } from "../../Supabase/supabaseClient";
import { useNavigate } from "react-router-dom";
import { FiSettings, FiBell } from "react-icons/fi";
import "../../Style/Settings.css";
import Sidebar from "../Sidebar";

function Settings() {
  const navigate = useNavigate();

  // UI Preferences
  const [theme, setTheme] = useState("light");
  const [language, setLanguage] = useState("en");

  // Profile (from Supabase)
  const [adminName, setAdminName] = useState("Loading...");
  const [adminEmail, setAdminEmail] = useState("");
  const [adminAvatar, setAdminAvatar] = useState("https://via.placeholder.com/80");

  // Logs (static for now, can be dynamic later)
  const [lastLogin] = useState("2025-09-20 12:00 PM");
  const [lastPasswordChange] = useState("2025-08-15");

  // Load preferences + fetch admin
  useEffect(() => {
    // Theme
    const savedTheme = localStorage.getItem("theme") || "light";
    setTheme(savedTheme);
    document.documentElement.setAttribute("data-theme", savedTheme);

    // Language
    const savedLang = localStorage.getItem("language") || "en";
    setLanguage(savedLang);

    // Fetch admin profile from Supabase
    const fetchAdminData = async () => {
      const { data, error } = await supabase
        .from("admin")
        .select("username, email, profile_img")
        .eq("id", 1) // TODO: replace with logged-in admin's id
        .single();

      if (error) {
        console.error("Error fetching admin:", error.message);
        return;
      }

      if (data) {
        setAdminName(data.username || "Admin");
        setAdminEmail(data.email || "No email provided");

        // Handle avatar (if profile_img exists)
        if (data.profile_img) {
          try {
            const blob = new Blob([new Uint8Array(data.profile_img)], { type: "image/png" });
            setAdminAvatar(URL.createObjectURL(blob));
          } catch (e) {
            console.error("Error processing profile image:", e);
          }
        }
      }
    };

    fetchAdminData();
  }, []);

  // Theme change handler
  const handleThemeChange = (selectedTheme) => {
    setTheme(selectedTheme);
    document.documentElement.setAttribute("data-theme", selectedTheme);
    localStorage.setItem("theme", selectedTheme);
  };

  // Language change handler
  const handleLanguageChange = (e) => {
    const lang = e.target.value;
    setLanguage(lang);
    localStorage.setItem("language", lang);
  };

  return (
    <div className="settings-root">
      <Sidebar />

      <div className="settings-main">
        {/* Header */}
        <div className="settings-header">
          <div className="settings-header-left">
            <h2 className="settings-title">Settings</h2>
            <p className="settings-subtitle">
              Here you have the basic access you need to change to your preference.
            </p>
          </div>

          <div className="settings-header-actions">
            <FiBell className="icon" />
            <FiSettings
              size={22}
              className="icon"
              onClick={() => navigate("/settings")}
            />
            <img
              src={adminAvatar}
              alt="Admin Avatar"
              className="settings-avatar"
              onClick={() => navigate("/settings")}
            />
          </div>
        </div>

        {/* Profile Info */}
        <div className="profile-section">
          <img
            src={adminAvatar}
            alt="Admin Avatar"
            className="profile-avatar"
          />
          <div>
            <h3>{adminName}</h3>
            <p>{adminEmail}</p>
          </div>
        </div>

        {/* Activity Logs */}
        <div className="settings-card">
          <h4>Activity Logs</h4>
          <p>Last Login: {lastLogin}</p>
          <p>Last Password Change: {lastPasswordChange}</p>
        </div>

        {/* Appearance */}
        <div className="settings-card">
          <h4>Appearance</h4>
          <div className="appearance-toggle">
            <button
              className={theme === "light" ? "active" : ""}
              onClick={() => handleThemeChange("light")}
            >
              Light
            </button>
            <button
              className={theme === "dark" ? "active" : ""}
              onClick={() => handleThemeChange("dark")}
            >
              Dark
            </button>
          </div>
        </div>

        {/* Language */}
        <div className="settings-card">
          <h4>Language</h4>
          <select value={language} onChange={handleLanguageChange}>
            <option value="en">English</option>
            <option value="ph">Filipino</option>
          </select>
        </div>
      </div>
    </div>
  );
}

export default Settings;
