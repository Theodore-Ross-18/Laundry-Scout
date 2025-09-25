import React, { useEffect, useState, useRef } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Users.css";
import {
  FiBell,
  FiSearch,
  FiMoreVertical,
} from "react-icons/fi";
import { useNavigate } from "react-router-dom";
import Sidebar from "./Sidebar";
import Notifications from "./Notifications";

const statusColor = (status) =>
  status === "Verified" ? { color: "green" } : { color: "red" };

function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [history, setHistory] = useState([]);
  const [showHistory, setShowHistory] = useState(false);
  const [menuOpen, setMenuOpen] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [showSettings, setShowSettings] = useState(false);

  const navigate = useNavigate();
  const searchRef = useRef(null);

  // ✅ Fetch users
  useEffect(() => {
    const fetchUsers = async () => {
      setLoading(true);
      const { data, error } = await supabase
        .from("user_profiles")
        .select("*");
      if (!error) setUsers(data || []);
      setLoading(false);
    };
    fetchUsers();
  }, []);

  // ✅ Real-time Supabase notifications
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    const addNotification = (title, message) => {
      setNotifications((prev) => [
        {
          id: Date.now(),
          title,
          message,
          time: new Date().toLocaleTimeString(),
          read: false,
        },
        ...prev,
      ]);
      setUnreadCount((prev) => prev + 1);
    };

    const userSub = supabase
      .channel("user-changes")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "user_profiles" },
        (payload) => {
          addNotification(
            "New user registered",
            `User ${payload.new.username || payload.new.email} just signed up.`
          );
        }
      )
      .subscribe();

    return () => supabase.removeChannel(userSub);
  }, []);

  // ✅ Filtered users
  const filteredUsers = users.filter((u) =>
    [u.first_name, u.last_name, u.email, u.mobile_number, u.customer_id]
      .filter(Boolean)
      .some((f) => f.toLowerCase().includes(search.toLowerCase()))
  );

  // ✅ Click outside search history
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (searchRef.current && !searchRef.current.contains(e.target)) {
        setShowHistory(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleKeyDown = (e) => {
    if (e.key === "Enter" && search.trim() !== "") {
      if (!history.includes(search)) {
        setHistory([search, ...history].slice(0, 5));
      }
      setShowHistory(false);
    }
  };

  const toggleMenu = (idx) => setMenuOpen(menuOpen === idx ? null : idx);

  return (
    <div className="users-root">
      <Sidebar isOpen={sidebarOpen} activePage="users" />

      <main className={`users-main ${sidebarOpen ? "" : "expanded"}`}>
        {/* Header */}
        <header className="users-header">
          <div className="users-header-left">
            <div>
               <h2 className="users-title">Users</h2>
                <p className="users-subtitle">
                  All users registered in the app
                </p>
            </div>
          </div>
          <div className="users-header-icons">
            <Notifications />
            <div className="dropdown-wrapper">
            </div>
            <div className="dropdown-wrapper">
              <img
                src="https://via.placeholder.com/32"
                alt="Profile"
                className="profile-avatar"
                onClick={(e) => {
                  e.stopPropagation();
                  setShowSettings(!showSettings);
                }}
              />
              {showSettings && (
                <div className="dropdown-panel" onClick={(e) => e.stopPropagation()}>
                  <div className="dropdown-item" onClick={() => navigate("/profile")}>
                    My Profile
                  </div>
                  <div className="dropdown-item" onClick={() => navigate("/settings")}>
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

        {/* Filters */}
        <div className="users-filters">
          <div className="users-filter-tab">
            <span className="app-filter-label">All Users</span>
            <span className="count">{filteredUsers.length}</span>
          </div>
          <div className="users-search-box" ref={searchRef}>
            <FiSearch className="search-icon" />
            <input
              type="text"
              placeholder="Search Here"
              className="users-search-input"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={handleKeyDown}
              onFocus={() => setShowHistory(true)}
            />
            {showHistory && history.length > 0 && (
              <ul className="users-search-history">
                {history.map((item, idx) => (
                  <li key={idx} onClick={() => setSearch(item)}>
                    <span>{item}</span>
                    <button
                      className="users-delete-history"
                      onClick={(e) => {
                        e.stopPropagation();
                        setHistory(history.filter((h) => h !== item));
                      }}
                    >
                      ×
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
          <div className="applications-filter-right">
            <button className="date-btn">19 Dec - 20 Dec 2024</button>
            <button className="all-btn">All Transactions</button>
          </div>
        </div>

        {/* Table */}
        <div className="users-table-wrapper">
          <h3 className="user-profiles-title">User Profiles</h3>
          <table className="users-table">
            <thead>
              <tr>
                <th>Customer ID</th>
                <th>First Name</th>
                <th>Last Name</th>
                <th>Mobile Number</th>
                <th>Email</th>
                <th>Update Date</th>
                <th>Verified Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="8">Loading...</td>
                </tr>
              ) : filteredUsers.length > 0 ? (
                filteredUsers.map((user, idx) => (
                  <tr key={user.uid || idx}>
                    <td>{user.customer_id || `000${idx + 1}`}</td>
                    <td>{user.first_name}</td>
                    <td>{user.last_name}</td>
                    <td>{user.mobile_number}</td>
                    <td>{user.email}</td>
                    <td>
                      {user.created_at
                        ? new Date(user.created_at).toLocaleDateString("en-US", {
                            year: "numeric",
                            month: "long",
                            day: "numeric",
                          })
                        : ""}
                    </td>
                    <td style={statusColor(user.verified_status)}>
                      {user.verified_status === "Verified"
                        ? "Verified"
                        : "Not Verified"}
                    </td>
                    <td className="actions-cell">
                      <button 
                        onClick={() => alert(`Deleting ${user.email}`)} 
                        className="danger"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="8">No users found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}

export default Users;
