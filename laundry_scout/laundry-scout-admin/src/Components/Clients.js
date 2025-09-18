import React, { useEffect, useState } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Clients.css";
import {
  FiSettings,
  FiBell,
  FiMenu,
  FiHome,
  FiFileText,
  FiUsers,
  FiUser,
  FiClock,
  FiMessageSquare,
  FiLogOut,
} from "react-icons/fi";
import { Link, useNavigate } from "react-router-dom";

function Clients() {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // 🔧 Settings / Notifications
  const [showSettings, setShowSettings] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  const navigate = useNavigate();

  // 🔹 Fetch APPROVED clients from Supabase
  useEffect(() => {
    const fetchClients = async () => {
      setLoading(true);
      const { data, error } = await supabase
        .from("business_profiles")
        .select("*")
        .eq("status", "approved"); // ✅ only approved

      if (error) {
        console.error("Error fetching clients:", error.message);
      } else {
        setClients(data || []);
      }
      setLoading(false);
    };

    fetchClients();
  }, []);

  // 🔹 Filter clients
  const filteredClients = clients.filter((client) => {
    const name = client?.business_name || client?.name || "";
    return name.toLowerCase().includes(search.toLowerCase());
  });

  return (
    <div className="dashboard-root">
      {/* Sidebar */}
      <aside className={`sidebar ${sidebarOpen ? "" : "closed"}`}>
        <div className="sidebar-title">Laundry Scout</div>
        <nav>
          <ul>
            <li>
              <Link to="/dashboard">
                <FiHome className="menu-icon" />
                <span>Dashboard</span>
              </Link>
            </li>
            <li>
              <Link to="/applications">
                <FiFileText className="menu-icon" />
                <span>Applications</span>
              </Link>
            </li>
            <li className="active">
              <Link to="/clients">
                <FiUsers className="menu-icon" />
                <span>Clients</span>
              </Link>
            </li>
            <li>
              <Link to="/users">
                <FiUser className="menu-icon" />
                <span>Users</span>
              </Link>
            </li>
            <li>
              <Link to="/history">
                <FiClock className="menu-icon" />
                <span>History</span>
              </Link>
            </li>
            <li>
              <Link to="/feedback">
                <FiMessageSquare className="menu-icon" />
                <span>Feedback</span>
              </Link>
            </li>
          </ul>
        </nav>
        <div className="logout" onClick={() => navigate("/logout")}>
          <FiLogOut className="menu-icon" />
          <span>Log Out</span>
        </div>
      </aside>

      {/* Main Content */}
      <main className="dashboard-main">
        <header className="client-header">
          <div className="header-left">
            <FiMenu
              className="toggle-sidebar"
              onClick={() => setSidebarOpen(!sidebarOpen)}
            />
            <div>
              <h1>CLIENTS</h1>
              <p>All Approved Laundry Businesses</p>
            </div>
          </div>
          <div className="client-header-icons">
            {/* Notifications */}
            <div className="dropdown-wrapper">
              <FiBell
                className="icon"
                onClick={() => {
                  setShowNotifications(!showNotifications);
                  setShowSettings(false);
                  setUnreadCount(0);
                }}
              />
              {unreadCount > 0 && (
                <span className="notification-badge">{unreadCount}</span>
              )}

              {showNotifications && (
                <div className="dropdown-panel">
                  {notifications.length === 0 ? (
                    <div className="dropdown-item">No notifications</div>
                  ) : (
                    notifications.slice(0, 5).map((n) => (
                      <div key={n.id} className="dropdown-item">
                        <strong>{n.title}</strong>
                        <p>{n.message}</p>
                        <span className="notif-time">{n.time}</span>
                      </div>
                    ))
                  )}
                  <div
                    className="dropdown-item"
                    onClick={() => navigate("/notifications")}
                  >
                    View All
                  </div>
                </div>
              )}
            </div>

            {/* Profile */}
            <div className="dropdown-wrapper">
              <img
                src="/path/to/updated/profile-image.png"
                alt="Profile"
                className="profile-avatar"
                onClick={() => {
                  setShowSettings(!showSettings);
                  setShowNotifications(false);
                }}
              />
              {showSettings && (
                <div className="dropdown-panel">
                  <div
                    className="dropdown-item"
                    onClick={() => navigate("/profile")}
                  >
                    My Profile
                  </div>
                  <div
                    className="dropdown-item"
                    onClick={() => navigate("/settings")}
                  >
                    Settings
                  </div>
                  <div
                    className="dropdown-item"
                    onClick={async () => {
                      await supabase.auth.signOut();
                      navigate("/login");
                    }}
                  >
                    Logout
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Client Cards */}
        {loading ? (
          <p>Loading clients...</p>
        ) : filteredClients.length === 0 ? (
          <p>No approved clients found.</p>
        ) : (
          <div className="grid">
            {filteredClients.map((client) => (
              <div
                key={client.id}
                className="client-card"
                onClick={() => navigate(`/clients/${client.id}`)} // ✅ go to detail
                style={{ cursor: "pointer" }}
              >
                <img
                  src={
                    client?.cover_photo_url ||
                    "https://via.placeholder.com/400x200"
                  }
                  alt={client?.business_name || client?.name || "Business"}
                />
                <div className="info">
                  <h2>
                    {client?.business_name ||
                      client?.name ||
                      "Unnamed Business"}
                  </h2>
                  <p className="address">
                    📍 {client?.business_address || "No address provided"}
                  </p>
                  <p className="since">
                    Since{" "}
                    {client?.created_at
                      ? new Date(client.created_at).toLocaleDateString()
                      : "N/A"}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}

export default Clients;
