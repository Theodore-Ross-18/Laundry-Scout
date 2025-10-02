import React, { useState, useEffect, useRef } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Applications.css";
import { FiMenu, FiSearch, FiSettings } from "react-icons/fi";
import { useNavigate } from "react-router-dom";

// ✅ Sidebar + Notifications
import Sidebar from "./Sidebar";
import Notifications from "./Notifications";

// ✅ Filter Right Section as Function
const ApplicationsFilterRight = ({ dateRange, onDateClick, onAllClick }) => {
  return (
    <div className="applications-filter-right">
      <button className="a-date-btn" onClick={onDateClick}>
        {dateRange}
      </button>
      <button className="a-all-btn" onClick={onAllClick}>
        All Transactions
      </button>
    </div>
  );
};

function Applications() {
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [history, setHistory] = useState([]);
  const [showHistory, setShowHistory] = useState(false);

  const [selectedBiz, setSelectedBiz] = useState(null);
  const [preview, setPreview] = useState(null);

  const [sidebarOpen, setSidebarOpen] = useState(true);

  // Reject Modal
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [reason, setReason] = useState("");
  const [specificReason, setSpecificReason] = useState("");

  const navigate = useNavigate();
  const searchRef = useRef(null);

  // ✅ helper for Supabase public URLs
  const getFileUrl = (path, bucketName = "businessdocuments") => {
    if (!path) return null;
    if (path.startsWith("http")) return path;
    const cleanPath = path.replace(/^\/+|\/+$/g, "");
    const { data } = supabase.storage.from(bucketName).getPublicUrl(cleanPath);
    return data?.publicUrl || null;
  };

  const renderDocumentImage = (url, alt, key) => {
    const imageUrl = getFileUrl(url);
    if (!url) return <span>No file uploaded</span>;
    if (!imageUrl) return <span className="error-text">Invalid image URL</span>;

    return (
      <img
        src={imageUrl}
        alt={alt}
        className="doc-img"
        onClick={() => setPreview(imageUrl)}
        onError={(e) => (e.target.style.display = "none")}
      />
    );
  };

  // ✅ fetch businesses
  useEffect(() => {
    fetchBusinesses();
  }, []);

  const fetchBusinesses = async () => {
    setLoading(true);
    const { data } = await supabase.from("business_profiles").select("*");
    setBusinesses(data || []);
    setLoading(false);
  };

  // ✅ search history click outside
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (searchRef.current && !searchRef.current.contains(e.target)) {
        setShowHistory(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // ✅ search history save
  const handleKeyDown = (e) => {
    if (e.key === "Enter" && search.trim() !== "") {
      if (!history.includes(search)) {
        setHistory([search, ...history].slice(0, 5));
      }
      setShowHistory(false);
    }
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
      .some((f) => f.toLowerCase().includes(search.toLowerCase()))
  );

  // ✅ Approve business
  const handleApprove = async () => {
    if (!selectedBiz) return;
    const { data, error } = await supabase
      .from("business_profiles")
      .update({ status: "approved" })
      .eq("id", selectedBiz.id)
      .select();

    if (!error && data?.length) {
      setBusinesses((prev) =>
        prev.map((b) =>
          b.id === selectedBiz.id ? { ...b, status: "approved" } : b
        )
      );
      setSelectedBiz(null);
    }
  };

  // ✅ Reject business
  const handleReject = async () => {
    if (!selectedBiz) return;
    await supabase
      .from("business_profiles")
      .update({
        status: "rejected",
        rejection_reason: reason,
        rejection_notes: specificReason,
      })
      .eq("id", selectedBiz.id);

    setBusinesses((prev) =>
      prev.map((b) =>
        b.id === selectedBiz.id
          ? { ...b, status: "rejected", rejection_reason: reason }
          : b
      )
    );
    setSelectedBiz(null);
    setShowRejectModal(false);
    setReason("");
    setSpecificReason("");
  };

  return (
    <div className="applications-root">
      {/* ✅ Sidebar */}
      <Sidebar isOpen={sidebarOpen} activePage="applications" />

      <main className={`applications-main ${sidebarOpen ? "" : "expanded"}`}>
        {/* Header */}
        <header className="applications-header">
          <div className="applications-header-left">
            <div>
              <h2 className="applications-title">APPLICATIONS</h2>
              <p className="applications-subtitle">
                All the Applicants Businesses waiting to be reviewed and Approved
              </p>
            </div>
          </div>
          <div className="applications-header-icons">
            <div className="notification-wrapper">
              <Notifications />
            </div>
            <div className="settings-wrapper">
              <FiSettings
                size={22}
                className="settings-icon"
                onClick={() => navigate("/settings")}
              />
            </div>
            <div className="dropdown-wrapper">
              <img
                src="https://via.placeholder.com/32"
                alt="profile"
                className="profile-avatar"
                onClick={() => navigate("/profile")}
              />
            </div>
          </div>
        </header>

        {/* ✅ Table or Review panel */}
        {!selectedBiz ? (
          <>
            {/* Filters */}
            <div className="applications-filters">
              <div className="applications-filter-tab">
                <span className="app-filter-label">All Applicants</span>
                <span className="count">{filteredBusinesses.length}</span>
              </div>

              <div className="applications-search-box" ref={searchRef}>
                <FiSearch className="search-icon" />
                <input
                  type="text"
                  placeholder="Search Here"
                  className="applications-search-input"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  onKeyDown={handleKeyDown}
                  onFocus={() => setShowHistory(true)}
                />
                {showHistory && history.length > 0 && (
                  <ul className="applications-search-history">
                    {history.map((item, idx) => (
                      <li key={idx} onClick={() => setSearch(item)}>
                        <span>{item}</span>
                        <button
                          className="applications-delete-history"
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

              {/* ✅ New Functional Filter */}
              <ApplicationsFilterRight
                dateRange="19 Dec - 20 Dec 2024"
                onDateClick={() => console.log("Date filter clicked")}
                onAllClick={() => console.log("All Transactions clicked")}
              />
            </div>

            {/* Table */}
            <div className="applications-table-wrapper">
              <h3 className="applications-table-title">
                Applicants For Review
              </h3>
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
                    filteredBusinesses.map((biz) => (
                      <tr key={biz.id}>
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
                          {biz.owner_first_name} {biz.owner_last_name}
                        </td>
                        <td>{biz.business_phone_number}</td>
                        <td>
                          {biz.created_at &&
                            new Date(biz.created_at).toLocaleDateString(
                              "en-US"
                            )}
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
          <div className="applications-review-panel">
            <h3 className="applications-review-panel-title">
              {selectedBiz.business_name} For Review
            </h3>
            <p>
              <strong>First Name:</strong> {selectedBiz.owner_first_name}
            </p>
            <p>
              <strong>Last Name:</strong> {selectedBiz.owner_last_name}
            </p>
            <p>
              <strong>Phone Number:</strong> {selectedBiz.business_phone_number}
            </p>
            <p>
              <strong>Business Name:</strong> {selectedBiz.business_name}
            </p>
            <p>
              <strong>Business Address:</strong> {selectedBiz.business_address}
            </p>

            <div className="review-docs">
              <div className="doc-box">
                <p>Attach BIR Registration</p>
                {renderDocumentImage(
                  selectedBiz.bir_registration_url,
                  "BIR Registration",
                  "bir"
                )}
              </div>
              <div className="doc-box">
                <p>Business Certificate</p>
                {renderDocumentImage(
                  selectedBiz.business_certificate_url,
                  "Business Certificate",
                  "certificate"
                )}
              </div>
              <div className="doc-box">
                <p>Business Mayor Permit</p>
                {renderDocumentImage(
                  selectedBiz.mayors_permit_url,
                  "Mayor Permit",
                  "mayor"
                )}
              </div>
            </div>

            <div className="review-actions">
              <button className="approve-btn" onClick={handleApprove}>
                Approve
              </button>
              <button
                className="reject-btn"
                onClick={() => setShowRejectModal(true)}
              >
                Reject
              </button>
              <button className="back-btn" onClick={() => setSelectedBiz(null)}>
                Back
              </button>
            </div>
          </div>
        )}
      </main>

      {/* ✅ Image Preview Modal */}
      {preview && (
        <div className="preview-overlay" onClick={() => setPreview(null)}>
          <div className="preview-content">
            <img src={preview} alt="Document Preview" />
          </div>
        </div>
      )}

      {/* ✅ Reject Modal */}
      {showRejectModal && (
        <div className="modal-overlay">
          <div className="modal">
            <div className="modal-header">
              <h3>Rejecting This Applicant</h3>
              <button
                className="close-btn"
                onClick={() => setShowRejectModal(false)}
              >
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
                placeholder="Write your reason..."
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
