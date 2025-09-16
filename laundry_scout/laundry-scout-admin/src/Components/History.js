import React, { useState, useEffect, useRef } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/History.css";
import {
  FiBell,
  FiMenu,
  FiHome,
  FiFileText,
  FiUsers,
  FiUser,
  FiClock,
  FiMessageSquare,
  FiLogOut,
  FiSearch,
} from "react-icons/fi";
import { Link, useNavigate } from "react-router-dom";

function History() {
  // 🔹 Data & States
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);

  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [search, setSearch] = useState("");
  const [searchHistory, setSearchHistory] = useState([]);
  const [showHistory, setShowHistory] = useState(false);

  // 🔹 Dropdowns
  const [showSettings, setShowSettings] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  const searchRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchHistory();
  }, []);

  // 🔹 Fetch history records
  const fetchHistory = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("business_profiles")
      .select("id,business_name,owner_first_name,owner_last_name,status,rejection_reason,created_at")
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Error fetching history:", error.message);
    } else {
      // Transform data to match previous structure (owner_name, action)
      const transformed = (data || []).map((row) => ({
        id: row.id,
        business_name: row.business_name,
        owner_name: `${row.owner_first_name || ""} ${row.owner_last_name || ""}`.trim(),
        action: row.status && row.status.toLowerCase() === "approved" ? "Approval" : row.status && row.status.toLowerCase() === "rejected" ? "Rejection" : "-",
        status: row.status,
        rejection_reason: row.rejection_reason,
        created_at: row.created_at,
      }));
      setRecords(transformed);
    }
    setLoading(false);
  };

  // 🔹 Save search into history
  const handleKeyDown = (e) => {
    if (e.key === "Enter" && search.trim() !== "") {
      if (!searchHistory.includes(search)) {
        setSearchHistory([search, ...searchHistory].slice(0, 5));
      }
      setShowHistory(false);
    }
  };

  const deleteHistory = (item) => {
    setSearchHistory(searchHistory.filter((h) => h !== item));
  };

  // 🔹 Close history dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (searchRef.current && !searchRef.current.contains(event.target)) {
        setShowHistory(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // 🔹 Filter records by search
  const filteredRecords = records.filter((rec) =>
    [rec.business_name, rec.owner_name, rec.action, rec.status]
      .filter(Boolean)
      .some((field) => field.toLowerCase().includes(search.toLowerCase()))
  );

  // 🔹 Toggle Sidebar
  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };

  return (
    <div className="dashboard-root">
      {/* Sidebar */}
      <aside className={`sidebar ${isSidebarOpen ? "open" : "closed"}`}>
        <div className="sidebar-title">Laundry Scout</div>
        <nav className="sidebar-menu">
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
            <li>
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
            <li className="active">
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

      {/* Main */}
      <main className={`dashboard-main ${isSidebarOpen ? "shifted" : "full"}`}>
        {/* Header */}
        <header className="History-header">
          <div className="header-left">
            <FiMenu className="toggle-sidebar" onClick={toggleSidebar} />
            <h2>HISTORY</h2>
            <p className="dashboard-date">
              Track all approval and rejection records
            </p>
          </div>
          <div className="dashboard-header-icons">
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
                src="https://via.placeholder.com/32"
                alt="profile"
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
                    onClick={() => alert("Logging out...")}
                  >
                    Logout
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Filters */}
        <div className="history-filters">
          <div className="filter-left">
            <span className="filter-label">All Records</span>
            <span className="filter-count">{filteredRecords.length}</span>
          </div>

          <div className="filter-center" ref={searchRef}>
            <FiSearch className="search-icon" />
            <input
              type="text"
              placeholder="Search History"
              className="search-input"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={handleKeyDown}
              onFocus={() => setShowHistory(true)}
            />
            {showHistory && searchHistory.length > 0 && (
              <ul className="search-history">
                {searchHistory.map((item, idx) => (
                  <li key={idx} onClick={() => setSearch(item)}>
                    <span>{item}</span>
                    <button
                      className="delete-history"
                      onClick={(e) => {
                        e.stopPropagation();
                        deleteHistory(item);
                      }}
                    >
                      ×
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>

          <div className="filter-right">
            <button className="date-btn">19 Dec - 20 Dec 2024</button>
            <button className="all-btn">All Transactions</button>
          </div>
        </div>

        {/* Table */}
        <div className="history-table">
          <h3 className="table-title">Application History</h3>
          <table>
            <thead>
              <tr>
                <th>Business</th>
                <th>Owner</th>
                <th>Action</th>
                <th>Status</th>
                <th>Reason</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="6">Loading...</td>
                </tr>
              ) : filteredRecords.length > 0 ? (
                filteredRecords.map((rec, idx) => (
                  <tr key={rec.id || idx}>
                    <td>{rec.business_name}</td>
                    <td>{rec.owner_name}</td>
                    <td>{rec.action || "-"}</td>
                    <td className={`status ${rec.status}`}>
                      {rec.status && rec.status.toLowerCase() === "approved" && (
                        <span style={{ color: "green", fontWeight: "bold" }}>✔ Approved</span>
                      )}
                      {rec.status && rec.status.toLowerCase() === "rejected" && (
                        <span style={{ color: "red", fontWeight: "bold" }}>✖ Rejected</span>
                      )}
                      {!rec.status || (rec.status.toLowerCase() !== "approved" && rec.status.toLowerCase() !== "rejected") ? (
                        <span>{rec.status || "Pending"}</span>
                      ) : null}
                    </td>
                    <td>
                      {rec.status && rec.status.toLowerCase() === "rejected"
                        ? rec.rejection_reason || "N/A"
                        : "N/A"}
                    </td>
                    <td className="record-time">
                      {rec.created_at
                        ? new Date(rec.created_at).toLocaleString()
                        : ""}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="6">No history records found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}

export default History;
