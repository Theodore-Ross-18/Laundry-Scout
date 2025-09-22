import React, { useEffect, useState } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Users.css";
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
  FiMoreVertical,
} from "react-icons/fi";
import { Link, useNavigate } from "react-router-dom";

const statusColor = (status) =>
  status === "Verified" ? { color: "green" } : { color: "red" };

function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [menuOpen, setMenuOpen] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // 🔔 Notifications & Profile states
  const [showSettings, setShowSettings] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  const navigate = useNavigate();

  useEffect(() => {
    const fetchUsers = async () => {
      setLoading(true);
      const { data, error } = await supabase.from("user_profiles").select("*, verified_status");

      if (!error) {
        setUsers(data);
      } else {
        console.error("Error fetching users:", error);
      }
      setLoading(false);
    };
    fetchUsers();
  }, []);

  // ✅ Real-time Supabase notifications (same as Dashboard)
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

    return () => {
      supabase.removeChannel(userSub);
    };
  }, []);

  // ✅ Filter users
  const filteredUsers = users.filter((u) =>
    [u.first_name, u.last_name, u.email, u.mobile_number, u.customer_id]
      .filter(Boolean)
      .some((f) => f.toLowerCase().includes(search.toLowerCase()))
  );

  const toggleMenu = (idx) => {
    setMenuOpen(menuOpen === idx ? null : idx);
  };

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
            <li>
              <Link to="/clients">
                <FiUsers className="menu-icon" />
                <span>Clients</span>
              </Link>
            </li>
            <li className="active">
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

      {/* Main */}
      <main className="dashboard-main">
        <div className="users-container">
          {/* 🔝 Top Header Bar */}
          <div className="users-header">
            <div>
              <h2 className="users-title">Users</h2>
              <p>All the users Using the App can be viewed here</p>
            </div>

            <div className="users-header-actions">
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
                      onClick={() => alert("Logging out...")}
                    >
                      Logout
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* 🔍 Filter/Search Bar */}
          <div className="users-filters">
            <div className="filter-tab">
              All Users <span className="count">{filteredUsers.length}</span>
            </div>
            <input
              type="text"
              placeholder="Search Here"
              className="search-box"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          {/* ✅ Table */}
          <div className="users-table-wrapper">
            <h3 className="user-profiles-title">User Profiles</h3>
            <table className="users-table">
              <thead>
                <tr>
                  <th>Customer ID</th>
                  <th>FirstName</th>
                  <th>LastName</th>
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
                          ? new Date(user.created_at).toLocaleDateString(
                              "en-US",
                              {
                                year: "numeric",
                                month: "long",
                                day: "numeric",
                              }
                            )
                          : ""}
                      </td>
                      <td style={statusColor(user.verified_status)}>
                        {user.verified_status === "Verified"
                          ? "Verified"
                          : "Not-Verified"}
                      </td>
                      <td className="actions-cell">
                        <button
                          className="menu-btn"
                          onClick={() => toggleMenu(idx)}
                        >
                          <FiMoreVertical />
                        </button>
                        {menuOpen === idx && (
                          <div className="menu-dropdown">
                            <button
                              onClick={() => alert(`Viewing ${user.email}`)}
                            >
                              View
                            </button>
                            <button
                              onClick={() => alert(`Editing ${user.email}`)}
                            >
                              Edit
                            </button>
                            <button
                              onClick={() => alert(`Deleting ${user.email}`)}
                              className="danger"
                            >
                              Delete
                            </button>
                          </div>
                        )}
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
        </div>
      </main>
    </div>
  );
}

export default Users;
