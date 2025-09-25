import React, { useState, useEffect } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Users.css";
import { FiMoreVertical, FiMenu, FiX } from "react-icons/fi";
import { useNavigate } from "react-router-dom";
import Notifications from "./Notifications";
import Sidebar from "./Sidebar";

const statusColor = (status) =>
  status === "Verified" ? { color: "green" } : { color: "red" };

function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [menuOpen, setMenuOpen] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [showSettings, setShowSettings] = useState(false);

  // 🔔 Notifications states
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  // Modal states
  const [selectedUser, setSelectedUser] = useState(null);
  const [showModal, setShowModal] = useState(false);

  const navigate = useNavigate();

  useEffect(() => {
    const fetchUsers = async () => {
      setLoading(true);
<<<<<<< HEAD
      const { data, error } = await supabase.from("user_profiles").select("*, verified_status");

      if (!error) {
        setUsers(data);
      } else {
        console.error("Error fetching users:", error);
      }
=======
      const { data, error } = await supabase.from("user_profiles").select("*");
      if (!error) setUsers(data);
      else console.error("Error fetching users:", error);
>>>>>>> c136dd8e (Modified)
      setLoading(false);
    };
    fetchUsers();
  }, []);

  // Real-time Supabase notifications
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

  const filteredUsers = users.filter((u) =>
    [u.first_name, u.last_name, u.email, u.mobile_number, u.customer_id]
      .filter(Boolean)
      .some((f) => f.toLowerCase().includes(search.toLowerCase()))
  );

  const toggleMenu = (idx) => {
    setMenuOpen(menuOpen === idx ? null : idx);
  };

  // View user details
  const handleView = (user) => {
    setSelectedUser(user);
    setShowModal(true);
    setMenuOpen(null);
  };

  // Delete user
  const handleDelete = async (user) => {
    if (window.confirm(`Are you sure you want to delete ${user.email}?`)) {
      const { error } = await supabase
        .from("user_profiles")
        .delete()
        .eq("uid", user.uid);

      if (!error) {
        setUsers((prev) => prev.filter((u) => u.uid !== user.uid));
        alert("User deleted successfully.");
      } else {
        console.error("Delete error:", error);
        alert("Failed to delete user.");
      }
    }
    setMenuOpen(null);
  };

  // Close settings dropdown
  useEffect(() => {
    const handleClickOutside = () => setShowSettings(false);
    document.addEventListener("click", handleClickOutside);
    return () => document.removeEventListener("click", handleClickOutside);
  }, []);

  return (
    <div className="users-root">
      {/* ✅ Shared Sidebar */}
      <Sidebar isOpen={sidebarOpen} activePage="users" />

      <main className={`users-main ${sidebarOpen ? "" : "expanded"}`}>
        <div className="users-container">
          {/* Header */}
          <div className="users-header">
            <div className="users-header-left">
              <FiMenu
                className="users-toggle-sidebar"
                onClick={() => setSidebarOpen(!sidebarOpen)}
              />
              <div>
                <h2 className="users-title">Users</h2>
                <p className="users-subtitle">
                  All the users Using the App can be viewed here
                </p>
              </div>
            </div>

            {/* Notifications + Profile */}
            <div className="users-header-icons">
              <Notifications
                notifications={notifications}
                unreadCount={unreadCount}
              />
              <img
                src="/path-to-avatar.jpg"
                alt="Profile"
                className="profile-avatar"
                onClick={(e) => {
                  e.stopPropagation();
                  setShowSettings(!showSettings);
                }}
              />
              {showSettings && (
                <div
                  className="dropdown-panel"
                  onClick={(e) => e.stopPropagation()}
                >
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

          {/* Search */}
          <div className="users-filters">
            <div className="filter-tab">
              All Users <span className="count">{filteredUsers.length}</span>
            </div>
            <input
              type="text"
              placeholder="Search Here"
              className="users-search-box"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          {/* Users Table */}
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
                            <button onClick={() => handleView(user)}>
                              View
                            </button>
                            <button
                              onClick={() => handleDelete(user)}
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

      {/* ✅ User Details Modal */}
      {showModal && selectedUser && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div
            className="modal-content"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-header">
              <h2>User Details</h2>
              <FiX
                className="close-icon"
                onClick={() => setShowModal(false)}
              />
            </div>
            <div className="modal-body">
              <p>
                <strong>Customer ID:</strong> {selectedUser.customer_id}
              </p>
              <p>
                <strong>First Name:</strong> {selectedUser.first_name}
              </p>
              <p>
                <strong>Last Name:</strong> {selectedUser.last_name}
              </p>
              <p>
                <strong>Email:</strong> {selectedUser.email}
              </p>
              <p>
                <strong>Mobile:</strong> {selectedUser.mobile_number}
              </p>
              <p>
                <strong>Status:</strong>{" "}
                <span style={statusColor(selectedUser.verified_status)}>
                  {selectedUser.verified_status}
                </span>
              </p>
              <p>
                <strong>Created At:</strong>{" "}
                {new Date(selectedUser.created_at).toLocaleString()}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Users;
