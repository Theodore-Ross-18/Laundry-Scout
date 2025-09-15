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

  // Image handling states
  const [imageErrors, setImageErrors] = useState({});
  const [imageLoading, setImageLoading] = useState({});

  const navigate = useNavigate();
  const searchRef = useRef(null);

  // Enhanced helper to get public storage url with proper bucket handling
  const getFileUrl = (path, bucketName = 'businessdocuments') => {
    if (!path) {
      console.log('No path provided for image');
      return null;
    }
    
    // Check if the path already contains the full URL (like the ones you provided)
    if (path.startsWith('http')) {
      console.log('URL already complete:', path);
      return path;
    }
    
    // Check if the path is just a filename without the full URL structure
    if (!path.includes('supabase.co')) {
      const bucket = bucketName || 'businessdocuments';
      const cleanPath = path.replace(/^\/+|\/+$/g, '');
      
      try {
        const { data } = supabase.storage
          .from(bucket)
          .getPublicUrl(cleanPath);
        
        if (!data || !data.publicUrl) {
          console.error('No public URL returned from Supabase storage');
          return null;
        }
        
        console.log('Generated URL from path:', data.publicUrl);
        return data.publicUrl;
      } catch (error) {
        console.error('Error generating Supabase storage URL:', error);
        return null;
      }
    }
    
    // If it's already a complete URL but doesn't start with http (edge case)
    return path;
  };

  // Handle image loading states
  const handleImageLoad = (imageKey) => {
    setImageLoading(prev => ({ ...prev, [imageKey]: false }));
  };

  const handleImageLoadStart = (imageKey) => {
    setImageLoading(prev => ({ ...prev, [imageKey]: true }));
  };

  // Handle image loading errors with detailed logging
  const handleImageError = (imageKey, url) => {
    console.error(`Failed to load image: ${imageKey}, URL: ${url}`);
    setImageErrors(prev => ({ ...prev, [imageKey]: true }));
  };

  // Helper to render document images with proper loading states
  const renderDocumentImage = (url, alt, imageKey) => {
    const imageUrl = getFileUrl(url);
    const isLoading = imageLoading[imageKey];
    const hasError = imageErrors[imageKey];
    
    console.log(`Rendering image for ${imageKey}:`, {
      originalUrl: url,
      processedUrl: imageUrl,
      isLoading,
      hasError
    });
    
    if (!url) {
      return <span>No file uploaded</span>;
    }
    
    if (!imageUrl) {
      return <span className="error-text">Invalid image URL</span>;
    }
    
    if (hasError) {
      return (
        <div className="error-text">
          <span>Failed to load image</span>
          <br />
          <small style={{ fontSize: '10px', wordBreak: 'break-all' }}>
            {imageUrl}
          </small>
        </div>
      );
    }
    
    return (
      <>
        {isLoading && <div className="image-loading">Loading...</div>}
        <img
          src={imageUrl}
          alt={alt}
          className="doc-img"
          style={{ display: isLoading ? 'none' : 'block' }}
          onClick={() => setPreview(imageUrl)}
          onLoad={() => handleImageLoad(imageKey)}
          onLoadStart={() => handleImageLoadStart(imageKey)}
          onError={() => handleImageError(imageKey, imageUrl)}
        />
      </>
    );
  };

  // Add a function to verify bucket access
  const verifyBucketAccess = async () => {
    try {
      const { data, error } = await supabase.storage
        .from('businessdocuments')
        .list('', { limit: 1 });
      
      if (error) {
        console.error('Cannot access businessdocuments bucket:', error);
      } else {
        console.log('Successfully accessed businessdocuments bucket');
      }
    } catch (error) {
      console.error('Error verifying bucket access:', error);
    }
  };

  // Reset states when selecting new business
  useEffect(() => {
    if (selectedBiz) {
      setImageErrors({});
      setImageLoading({});
      console.log('Selected business documents:', {
        bir: selectedBiz.bir_registration_url,
        certificate: selectedBiz.business_certificate_url,
        mayor: selectedBiz.mayors_permit_url
      });
    }
  }, [selectedBiz]);

  // Call verify bucket access on component mount
  useEffect(() => {
    verifyBucketAccess();
  }, []);

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
      console.log("Fetched businesses data:", data);
      // Log the first business's URLs to see the format
      if (data && data.length > 0) {
        console.log("Sample business URLs:", {
          bir: data[0].bir_registration_url,
          certificate: data[0].business_certificate_url,
          mayor: data[0].mayors_permit_url
        });
      }
      setBusinesses(data);
    }
    setLoading(false);
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
    
    try {
      console.log("Attempting to approve business with ID:", selectedBiz.id);

      const { data, error } = await supabase
        .from("business_profiles")
        .update({ status: "approved" })
        .eq("id", selectedBiz.id)
        .select();

      if (error) {
        console.error("Error updating business_profiles:", error);
        alert(`Error approving business: ${error.message}`);
        return;
      }

      console.log("Supabase update response data:", data);

      if (data && data.length > 0) {
        console.log("Business approved successfully in database:", data);
        alert("Business approved successfully!");

        // Update local state
        setBusinesses(prevBusinesses =>
          prevBusinesses.map(biz =>
            biz.id === selectedBiz.id ? { ...biz, status: "approved" } : biz
          )
        );

        setSelectedBiz(null);
      } else {
        console.warn("Update operation did not return any data. This might be due to RLS policies.");
        alert("Approval might not have been saved. Please check database permissions (RLS).");
      }
    } catch (err) {
      console.error("An exception occurred during the approval process:", err);
      alert("An unexpected error occurred: " + err.message);
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
                  {renderDocumentImage(selectedBiz.bir_registration_url, "BIR Registration", "bir")}
                </div>

                <div className="doc-box">
                  <p>Business Certificate</p>
                  {renderDocumentImage(selectedBiz.business_certificate_url, "Business Certificate", "certificate")}
                </div>

                <div className="doc-box">
                  <p>Business Mayor Permit</p>
                  {renderDocumentImage(selectedBiz.mayors_permit_url, "Business Mayor Permit", "mayor")}
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
