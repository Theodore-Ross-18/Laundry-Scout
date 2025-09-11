import React, { useState, useEffect, useRef } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Applications.css";
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
  FiUserCheck,
  FiUserPlus,
  FiGrid,
  FiMail,
} from "react-icons/fi";
import { Link, useNavigate } from "react-router-dom";

function Applications() {
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [history, setHistory] = useState([]);
  const [showHistory, setShowHistory] = useState(false);
  const [selectedBiz, setSelectedBiz] = useState(null);
  const [preview, setPreview] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);

    // 🔧 Settings / Notifications
  const [showSettings, setShowSettings] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  // Reject Modal states
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [reason, setReason] = useState("");
  const [specificReason, setSpecificReason] = useState("");

  const navigate = useNavigate();
  const searchRef = useRef(null);

  useEffect(() => {
    fetchBusinesses();
  }, []);

  const fetchBusinesses = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("business_profiles")
      .select("*");

    if (error) {
      console.error("Error fetching businesses:", error.message);
    } else {
      setBusinesses(data);
    }
    setLoading(false);
  };

  // helper to get public storage url
  const getFileUrl = (path) => {
    if (!path) return null;
    const { data } = supabase.storage
      .from("businessdocuments")
      .getPublicUrl(path);
    return data.publicUrl;
  };

  // Save search to history
  const handleKeyDown = (e) => {
    if (e.key === "Enter" && search.trim() !== "") {
      if (!history.includes(search)) {
        setHistory([search, ...history].slice(0, 5));
      }
      setShowHistory(false);
    }
  };

  const deleteHistory = (item) => {
    setHistory(history.filter((h) => h !== item));
  };

  const filteredBusinesses = businesses.filter((biz) =>
    [
      biz.business_name,
      biz.owner_first_name,
      biz.owner_last_name,
      biz.email,
      biz.business_address,
      biz.business_phone_number,
    ]
      .filter(Boolean)
      .some((field) => field.toLowerCase().includes(search.toLowerCase()))
  );

  // Close history dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (searchRef.current && !searchRef.current.contains(event.target)) {
        setShowHistory(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // Approve action
  const handleApprove = async () => {
    if (!selectedBiz) return;
    const { error } = await supabase
      .from("business_profiles")
      .update({ status: "approved" })
      .eq("id", selectedBiz.id);

    if (error) {
      console.error("Error approving:", error.message);
    } else {
      fetchBusinesses();
      setSelectedBiz(null);
    }
  };

  // Reject action
  const handleReject = async () => {
    if (!selectedBiz) return;
    const { error } = await supabase
      .from("business_profiles")
      .update({
        status: "rejected",
        rejection_reason: reason,
        rejection_notes: specificReason,
      })
      .eq("id", selectedBiz.id);

    if (error) {
      console.error("Error rejecting:", error.message);
    } else {
      fetchBusinesses();
      setSelectedBiz(null);
      setShowRejectModal(false);
      setReason("");
      setSpecificReason("");
    }
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
            <li className="active">
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
        <div className="applications-container">
          <header className="applications-header">
            <div className="header-left">
              <FiMenu
                className="toggle-sidebar"
                onClick={() => setSidebarOpen(!sidebarOpen)}
              />
              <div>
                <h2>APPLICATIONS</h2>
                <p className="applications-subtitle">
                  All the Applicants Businesses waiting to be reviewed and Approved
                </p>
              </div>
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
                {unreadCount > 0 && <span className="notification-badge">{unreadCount}</span>}

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
                    <div className="dropdown-item" onClick={() => navigate("/profile")}>
                      My Profile
                    </div>
                    <div className="dropdown-item" onClick={() => navigate("/settings")}>
                      Settings
                    </div>
                    <div className="dropdown-item" onClick={() => alert("Logging out...")}>
                      Logout
                    </div>
                  </div>
                )}
              </div>
            </div>
          </header>
            

          {!selectedBiz ? (
            <>
              {/* Filters */}
              <div className="applications-filters">
                <div className="filter-tab">
                  <span>
                    All Applicants <span className="count">{filteredBusinesses.length}</span>
                  </span>
                </div>

                <div className="search-wrapper" ref={searchRef}>
                  <input
                    type="text"
                    placeholder="Search Here"
                    className="search-box"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    onKeyDown={handleKeyDown}
                    onFocus={() => setShowHistory(true)}
                  />
                  {showHistory && history.length > 0 && (
                    <ul className="search-history">
                      {history.map((item, idx) => (
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

                <select className="date-filter">
                  <option>19 Dec - 20 Dec 2024</option>
                </select>
                <select className="transaction-filter">
                  <option>All Transactions</option>
                </select>
              </div>

              {/* Table */}
              <div className="applications-table-wrapper">
                <h3 className="table-title">Applicants For Review</h3>
                <table className="applications-table">
                  <thead>
                    <tr>
                      <th>Review</th>
                      <th>Store Name</th>
                      <th>Owner Name</th>
                      <th>Phone Number</th>
                      <th>Date Submitted</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {loading ? (
                      <tr>
                        <td colSpan="6">Loading...</td>
                      </tr>
                    ) : filteredBusinesses.length > 0 ? (
                      filteredBusinesses.map((biz, idx) => (
                        <tr key={biz.id || idx}>
                          <td>
                            <button
                              className="review-btn"
                              onClick={() => setSelectedBiz(biz)}
                            >
                              Review
                            </button>
                          </td>
                          <td>{biz.business_name}</td>
                          <td>
                            {biz.owner_first_name || ""} {biz.owner_last_name || ""}
                          </td>
                          <td>{biz.business_phone_number}</td>
                          <td>
                            {biz.created_at
                              ? new Date(biz.created_at).toLocaleDateString("en-US", {
                                  year: "numeric",
                                  month: "long",
                                  day: "numeric",
                                })
                              : ""}
                          </td>
                          <td className={`status ${biz.status || "pending"}`}>
                            {biz.status || "Pending"}
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan="6">No businesses found.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </>
          ) : (
            <div className="review-panel">
              <h3>{selectedBiz.business_name} For Review</h3>

              <p><strong>First Name:</strong> {selectedBiz.owner_first_name}</p>
              <p><strong>Last Name:</strong> {selectedBiz.owner_last_name}</p>
              <p><strong>Phone Number:</strong> {selectedBiz.business_phone_number}</p>
              <p><strong>Business Name:</strong> {selectedBiz.business_name}</p>
              <p><strong>Business Address:</strong> {selectedBiz.business_address}</p>

              <div className="review-docs">
                <div className="doc-box">
                  <p>Attach BIR Registration</p>
                  {selectedBiz.bir_registration_url ? (
                    <img
                      src={getFileUrl(selectedBiz.bir_registration_url)}
                      alt="BIR Registration"
                      className="doc-img"
                      onClick={() =>
                        setPreview(getFileUrl(selectedBiz.bir_registration_url))
                      }
                    />
                  ) : (
                    <span>No file uploaded</span>
                  )}
                </div>

                <div className="doc-box">
                  <p>Business Certificate</p>
                  {selectedBiz.business_certificate_url ? (
                    <img
                      src={getFileUrl(selectedBiz.business_certificate_url)}
                      alt="Business Certificate"
                      className="doc-img"
                      onClick={() =>
                        setPreview(getFileUrl(selectedBiz.business_certificate_url))
                      }
                    />
                  ) : (
                    <span>No file uploaded</span>
                  )}
                </div>

                <div className="doc-box">
                  <p>Business Mayor Permit</p>
                  {selectedBiz.mayors_permit_url ? (
                    <img
                      src={getFileUrl(selectedBiz.mayors_permit_url)}
                      alt="Business Mayor Permit"
                      className="doc-img"
                      onClick={() =>
                        setPreview(getFileUrl(selectedBiz.mayors_permit_url))
                      }
                    />
                  ) : (
                    <span>No file uploaded</span>
                  )}
                </div>
              </div>

              <div className="review-actions">
                <button className="approve-btn" onClick={handleApprove}>
                  Approve
                </button>
                <button className="reject-btn" onClick={() => setShowRejectModal(true)}>
                  Reject
                </button>
                <button className="back-btn" onClick={() => setSelectedBiz(null)}>
                  Back
                </button>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Image Preview Modal */}
      {preview && (
        <div className="preview-overlay" onClick={() => setPreview(null)}>
          <div className="preview-content">
            <img src={preview} alt="Document Preview" />
          </div>
        </div>
      )}

      {/* Reject Modal */}
      {showRejectModal && (
        <div className="modal-overlay">
          <div className="modal">
            <div className="modal-header">
              <h3>Rejecting This Applicant</h3>
              <button className="close-btn" onClick={() => setShowRejectModal(false)}>
                ×
              </button>
            </div>

            <div className="modal-body">
              <h4>Reason for Rejection</h4>
              {[
                "Incomplete Documents",
                "Invalid Documents",
                "Duplicate Registration",
                "Unclear Photo of documentation",
              ].map((r) => (
                <label key={r}>
                  <input
                    type="radio"
                    name="reason"
                    value={r}
                    checked={reason === r}
                    onChange={(e) => setReason(e.target.value)}
                  />
                  {r}
                </label>
              ))}

              <h4>Specific Reason</h4>
              <textarea
                placeholder="Write your Reason why this client is rejected."
                value={specificReason}
                onChange={(e) => setSpecificReason(e.target.value)}
              />
            </div>

            <div className="modal-footer">
              <button className="reject-confirm" onClick={handleReject}>
                Reject
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Applications;
