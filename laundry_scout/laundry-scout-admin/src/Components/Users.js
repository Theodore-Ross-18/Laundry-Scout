import React, { useEffect, useState, useRef } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Users.css";
import { FiSearch, FiSettings } from "react-icons/fi";
import { useNavigate } from "react-router-dom";
import Sidebar from "./Sidebar";
import Notifications from "./Notifications";
import DateRangePicker from "./DateRangePicker";
import AccessibleDropdown from "./AccessibleDropdown";

const statusColor = (status) =>
  status === "Verified" ? { color: "green" } : { color: "red" };

function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [history, setHistory] = useState([]);
  const [showHistory, setShowHistory] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [showSettings, setShowSettings] = useState(false);
  const [toast, setToast] = useState(null);
  const [confirmDelete, setConfirmDelete] = useState(null); // For overlay confirmation
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [selectedStatus, setSelectedStatus] = useState("All Users");
  const navigate = useNavigate();
  const searchRef = useRef(null);

  // ✅ Fetch all users
  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    setLoading(true);
    const { data, error } = await supabase.from("user_profiles").select("*");
    if (error) console.error("Fetch error:", error);
    else setUsers(data || []);
    setLoading(false);
  };

  // ✅ Real-time user inserts
  useEffect(() => {
    const channel = supabase
      .channel("user-changes")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "user_profiles" },
        (payload) => {
          showToast(`New user ${payload.new.email || "registered"} added.`);
          fetchUsers();
        }
      )
      .subscribe();

    return () => supabase.removeChannel(channel);
  }, []);

  // ✅ Show confirmation overlay
  const confirmDeleteUser = (user) => {
    setConfirmDelete(user);
  };

  // ✅ Handle deletion
  const handleDelete = async () => {
    if (!confirmDelete) return;
    const { uid, email } = confirmDelete;

    const { error } = await supabase.from("user_profiles").delete().eq("uid", uid);
    if (error) {
      console.error(error);
      showToast("❌ Failed to delete user.");
    } else {
      setUsers((prev) => prev.filter((u) => u.uid !== uid));
      showToast(`✅ ${email} deleted successfully.`);
    }
    setConfirmDelete(null);
  };

  // ✅ Toast helper
  const showToast = (message) => {
    setToast(message);
    setTimeout(() => setToast(null), 2500);
  };

  // ✅ Search filter
  const filteredUsers = users.filter((u) => {
    const textMatch = [
      u.first_name,
      u.last_name,
      u.email,
      u.mobile_number,
      u.customer_id,
    ]
      .filter(Boolean)
      .some((f) => f.toLowerCase().includes(search.toLowerCase()));

    const dateMatch = (() => {
      if (!startDate || !endDate) return true;
      if (!u.created_at) return false;
      const created = new Date(u.created_at).getTime();
      const start = new Date(startDate).getTime();
      const end = new Date(endDate).getTime();
      return created >= start && created <= end;
    })();

    const statusMatch = (() => {
      if (selectedStatus === "All Users") return true;
      if (selectedStatus === "Verified") return u.verified_status === "Verified";
      if (selectedStatus === "Not Verified") return u.verified_status !== "Verified";
      return true;
    })();

    return textMatch && dateMatch && statusMatch;
  });

  // ✅ Hide search history when clicking outside
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

  return (
    <div className="users-root">
      <Sidebar isOpen={sidebarOpen} activePage="users" />

      <main className={`users-main ${sidebarOpen ? "" : "expanded"}`}>
        {/* Header */}
        <header className="users-header">
          <div className="users-header-left">
            <div>
              <h2 className="users-title">Users</h2>
              <p className="users-subtitle">All users registered in the app</p>
            </div>
          </div>
          <div className="users-header-icons">
            <Notifications />
            <FiSettings
              size={22}
              className="settings-icon"
              onClick={() => navigate("/settings")}
            />
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
          <div className="users-filter-right">
            <DateRangePicker
              startDate={startDate}
              endDate={endDate}
              onChangeStart={setStartDate}
              onChangeEnd={setEndDate}
              onApply={() => {}}
            />
            <AccessibleDropdown
              buttonClassName="u-all-btn"
              selected={selectedStatus}
              options={["All Users", "Verified", "Not Verified"]}
              onSelect={setSelectedStatus}
              placeholder="All Transactions"
              align="right"
            />
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
                        className="danger"
                        onClick={() => confirmDeleteUser(user)}
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

        {/* ✅ Delete Confirmation Overlay */}
        {confirmDelete && (
          <div className="confirm-overlay">
            <div className="confirm-box">
              <h3>Confirm Deletion</h3>
              <p>
                Are you sure you want to delete{" "}
                <strong>{confirmDelete.email}</strong>?<br />
                This action cannot be undone.
              </p>
              <div className="confirm-actions">
                <button className="cancel-btn" onClick={() => setConfirmDelete(null)}>
                  Cancel
                </button>
                <button className="users-delete-btn" onClick={handleDelete}>
                  Delete
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ✅ Toast Notification */}
        {toast && <div className="toast-message">{toast}</div>}
      </main>
    </div>
  );
}

export default Users;
