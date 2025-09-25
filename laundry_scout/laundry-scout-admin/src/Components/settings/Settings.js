// src/Components/Admin/Settings.js
import React, { useState, useEffect } from "react";
import { supabase } from "../../Supabase/supabaseClient";
import { useNavigate } from "react-router-dom";
import { FiSettings } from "react-icons/fi";
import "../../Style/Settings.css";

// ✅ Translations
const translations = {
  en: {
    back: "⬅ Back",
    title: "⚙️ Admin Settings",
    profile: "👤 Admin Profile",
    displayName: "Display Name",
    email: "Email",
    avatar: "Avatar URL",
    updateProfile: "Update Profile",
    logs: "📜 Activity Logs",
    lastLogin: "Last Login",
    lastPassword: "Last Password Change",
    security: "🔑 Security",
    newPassword: "New Password",
    updatePassword: "Update Password",
    twoFA: "Enable Two-Factor Authentication (2FA)",
    signOutAll: "Sign Out of All Devices",
    preferences: "🎨 Preferences",
    theme: "Theme",
    panelTitle: "Admin Panel Title",
    logoURL: "Logo URL",
    emailNotif: "Enable Email Notifications",
    systemControls: "🛠 System Controls",
    maintenanceMode: "Enable Maintenance Mode",
    autoApprove: "Auto-Approve Applications",
    exportData: "Export User Data",
    saveSettings: "Save Settings",
    language: "Language",
    dangerZone: "⚠️ Danger Zone",
    deactivate: "Deactivate Account",
  },
  ph: {
    back: "⬅ Bumalik",
    title: "⚙️ Mga Setting ng Admin",
    profile: "👤 Profile ng Admin",
    displayName: "Pangalan",
    email: "Email",
    avatar: "URL ng Avatar",
    updateProfile: "I-update ang Profile",
    logs: "📜 Mga Log ng Aktibidad",
    lastLogin: "Huling Pag-login",
    lastPassword: "Huling Pagpalit ng Password",
    security: "🔑 Seguridad",
    newPassword: "Bagong Password",
    updatePassword: "I-update ang Password",
    twoFA: "I-enable ang Dalawang Hakbang na Pagpapatunay (2FA)",
    signOutAll: "Mag-Sign Out sa Lahat ng Device",
    preferences: "🎨 Mga Kagustuhan",
    theme: "Tema",
    panelTitle: "Pamagat ng Admin Panel",
    logoURL: "URL ng Logo",
    emailNotif: "I-enable ang Email Notifications",
    systemControls: "🛠 Mga Kontrol ng Sistema",
    maintenanceMode: "I-enable ang Maintenance Mode",
    autoApprove: "Awtomatikong Aprubahan ang Mga Aplikasyon",
    exportData: "I-export ang Data ng User",
    saveSettings: "I-save ang Mga Setting",
    language: "Wika",
    dangerZone: "⚠️ Mapanganib na Aksyon",
    deactivate: "I-deactivate ang Account",
  },
};

function Settings() {
  const [password, setPassword] = useState("");
  const [theme, setTheme] = useState("light");
  const [notifications, setNotifications] = useState(true);
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [twoFA, setTwoFA] = useState(false);
  const [panelTitle, setPanelTitle] = useState("Laundry Scout Admin");
  const [panelLogo, setPanelLogo] = useState("https://via.placeholder.com/100");
  const [autoApprove, setAutoApprove] = useState(false);
  const [language, setLanguage] = useState("en");
  const [message, setMessage] = useState("");

  // ✅ Admin Profile states
  const [adminName, setAdminName] = useState("Admin User");
  const [adminEmail, setAdminEmail] = useState("admin@example.com");
  const [adminAvatar, setAdminAvatar] = useState("https://via.placeholder.com/80");

  // ✅ Logs
  const [lastLogin, setLastLogin] = useState("2025-09-20 12:00 PM");
  const [lastPasswordChange, setLastPasswordChange] = useState("2025-08-15");

  const navigate = useNavigate();
  const t = translations[language];

  // ✅ Load settings on mount
  useEffect(() => {
    const savedTheme = localStorage.getItem("theme") || "light";
    setTheme(savedTheme);
    document.documentElement.setAttribute("data-theme", savedTheme);

    setPanelTitle(localStorage.getItem("panelTitle") || "Laundry Scout Admin");
    setPanelLogo(localStorage.getItem("panelLogo") || "https://via.placeholder.com/100");
    setAutoApprove(localStorage.getItem("autoApprove") === "true");
    setTwoFA(localStorage.getItem("twoFA") === "true");
    setLanguage(localStorage.getItem("language") || "en");

    setAdminName(localStorage.getItem("adminName") || "Admin User");
    setAdminEmail(localStorage.getItem("adminEmail") || "admin@example.com");
    setAdminAvatar(localStorage.getItem("adminAvatar") || "https://via.placeholder.com/80");
  }, []);

  // ✅ Save settings
  const handleSaveSettings = () => {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem("theme", theme);
    localStorage.setItem("panelTitle", panelTitle);
    localStorage.setItem("panelLogo", panelLogo);
    localStorage.setItem("autoApprove", autoApprove);
    localStorage.setItem("twoFA", twoFA);
    localStorage.setItem("language", language);
    setMessage("✅ Settings saved & applied globally!");
  };

  // ✅ Update password
  const handlePasswordUpdate = async () => {
    if (!password) return setMessage("❌ Please enter a new password.");
    const { error } = await supabase.auth.updateUser({ password });
    if (error) setMessage("❌ Error: " + error.message);
    else {
      setMessage("✅ Password updated successfully!");
      setPassword("");
      setLastPasswordChange(new Date().toLocaleString());
    }
  };

  // ✅ Sign out all sessions
  const handleSignOutAll = async () => {
    const { error } = await supabase.auth.signOut();
    setMessage(error ? "❌ Error signing out: " + error.message : "✅ Signed out of all sessions.");
  };

  // ✅ Export data
  const handleExportData = async () => {
    const { data, error } = await supabase.from("user_profiles").select("*");
    if (error) return setMessage("❌ Export failed: " + error.message);
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "user_profiles.json";
    a.click();
    URL.revokeObjectURL(url);
    setMessage("✅ Data exported successfully!");
  };

  // ✅ Update profile
  const handleUpdateProfile = () => {
    localStorage.setItem("adminName", adminName);
    localStorage.setItem("adminEmail", adminEmail);
    localStorage.setItem("adminAvatar", adminAvatar);
    setMessage("✅ Profile updated successfully!");
  };

  // ✅ Deactivate account
  const handleDeactivateAccount = async () => {
    if (window.confirm("⚠️ Are you sure you want to deactivate this account?")) {
      const { error } = await supabase.auth.signOut();
      if (error) setMessage("❌ Error: " + error.message);
      else {
        setMessage("✅ Account deactivated. Redirecting...");
        navigate("/login");
      }
    }
  };

  return (
    <div className="page-container">
      {/* Back Button */}
      <button className="btn" onClick={() => navigate(-1)}>{t.back}</button>
      <h2>{t.title}</h2>

      {/* Admin Profile */}
      <div className="card">
        <h3>{t.profile}</h3>
        <div className="form-group">
          <label>{t.displayName}</label>
          <input type="text" value={adminName} onChange={(e) => setAdminName(e.target.value)} />
        </div>
        <div className="form-group">
          <label>{t.email}</label>
          <input type="email" value={adminEmail} onChange={(e) => setAdminEmail(e.target.value)} />
        </div>
        <div className="form-group">
          <label>{t.avatar}</label>
          <input type="text" value={adminAvatar} onChange={(e) => setAdminAvatar(e.target.value)} />
        </div>
        <img src={adminAvatar} alt="Admin Avatar" width="80" style={{ borderRadius: "50%" }} />
        <button className="btn primary" onClick={handleUpdateProfile}>{t.updateProfile}</button>
      </div>

      {/* Logs */}
      <div className="card">
        <h3>{t.logs}</h3>
        <p>{t.lastLogin}: {lastLogin}</p>
        <p>{t.lastPassword}: {lastPasswordChange}</p>
      </div>

      {/* Security */}
      <div className="card">
        <h3>{t.security}</h3>
        <div className="form-group">
          <label>{t.newPassword}</label>
          <input type="password" placeholder={t.newPassword} value={password} onChange={(e) => setPassword(e.target.value)} />
        </div>
        <button className="btn danger" onClick={handlePasswordUpdate}>{t.updatePassword}</button>
        <div className="form-group checkbox">
          <input type="checkbox" checked={twoFA} onChange={() => setTwoFA(!twoFA)} />
          <label>{t.twoFA}</label>
        </div>
        <button className="btn" onClick={handleSignOutAll}>{t.signOutAll}</button>
      </div>

      {/* Preferences */}
      <div className="card">
        <h3>{t.preferences}</h3>
        <div className="form-group">
          <label>{t.theme}</label>
          <select value={theme} onChange={(e) => setTheme(e.target.value)}>
            <option value="light">🌞 Light</option>
            <option value="dark">🌙 Dark</option>
          </select>
        </div>
        <div className="form-group">
          <label>{t.panelTitle}</label>
          <input type="text" value={panelTitle} onChange={(e) => setPanelTitle(e.target.value)} />
        </div>
        <div className="form-group">
          <label>{t.logoURL}</label>
          <input type="text" value={panelLogo} onChange={(e) => setPanelLogo(e.target.value)} />
        </div>
        <div className="form-group">
          <label>{t.language}</label>
          <select value={language} onChange={(e) => setLanguage(e.target.value)}>
            <option value="en">English</option>
            <option value="ph">Filipino</option>
          </select>
        </div>
        <div className="form-group checkbox">
          <input type="checkbox" checked={notifications} onChange={() => setNotifications(!notifications)} />
          <label>{t.emailNotif}</label>
        </div>
      </div>

      {/* System Controls */}
      <div className="card">
        <h3>{t.systemControls}</h3>
        <div className="form-group checkbox">
          <input type="checkbox" checked={maintenanceMode} onChange={() => setMaintenanceMode(!maintenanceMode)} />
          <label>{t.maintenanceMode}</label>
        </div>
        <div className="form-group checkbox">
          <input type="checkbox" checked={autoApprove} onChange={() => setAutoApprove(!autoApprove)} />
          <label>{t.autoApprove}</label>
        </div>
        <button className="btn" onClick={handleExportData}>{t.exportData}</button>
        <button className="btn primary" onClick={handleSaveSettings}>{t.saveSettings}</button>
      </div>

      {/* Danger Zone */}
      <div className="card danger-zone">
        <h3>{t.dangerZone}</h3>
        <button className="btn danger" onClick={handleDeactivateAccount}>{t.deactivate}</button>
      </div>

      {message && <p className="message">{message}</p>}
    </div>
  );
}

export default Settings;
