import React, { useState, useEffect, useRef } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Applications.css";
import { FiMenu, FiSearch, FiSettings } from "react-icons/fi";
import { useNavigate } from "react-router-dom";

// ✅ Sidebar + Notifications
import Sidebar from "./Sidebar";
import Notifications from "./Notifications";

// ✅ Filter Right Section (date dropdown + transaction dropdown)
const ApplicationsFilterRight = ({
  startDate,
  endDate,
  setStartDate,
  setEndDate,
  showDateDropdown,
  setShowDateDropdown,
  handleCustomDateFilter,
  handleFilterStatus,
  selectedStatus,
}) => {
  const [showStatusDropdown, setShowStatusDropdown] = useState(false);

  return (
    <div className="applications-filter-right">
      {/* 📅 Date Button */}
      <div className="date-dropdown-wrapper">
        <button
          className="a-date-btn"
          onClick={() => setShowDateDropdown(!showDateDropdown)}
        >
          {startDate && endDate
            ? `${new Date(startDate).toLocaleDateString()} - ${new Date(
                endDate
              ).toLocaleDateString()}`
            : "Filter by Date Range"}
        </button>

        {/* ✅ Date Dropdown with calendar inputs */}
        {showDateDropdown && (
          <div className="date-dropdown">
            <label>
              Start Date:
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
              />
            </label>
            <label>
              End Date:
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
              />
            </label>
            <button
              className="apply-btn"
              onClick={() => handleCustomDateFilter()}
            >
              Apply Filter
            </button>
          </div>
        )}
      </div>

      {/* 💼 All Transactions Button with Dropdown */}
      <div className="dropdown-container">
        <button
          className="a-all-btn"
          onClick={() => setShowStatusDropdown(!showStatusDropdown)}
        >
          {selectedStatus ? selectedStatus : "All Transactions"}
        </button>

        {showStatusDropdown && (
          <div className="dropdown-menu">
            {["All Transactions", "Pending", "Approved", "Rejected"].map(
              (status) => (
                <div
                  key={status}
                  className={selectedStatus === status ? "active" : ""}
                  onClick={() => {
                    handleFilterStatus(status);
                    setShowStatusDropdown(false);
                  }}
                >
                  {status}
                </div>
              )
            )}
          </div>
        )}
      </div>
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

  // ✅ Date Filter States
  const [showDateDropdown, setShowDateDropdown] = useState(false);
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");

  // ✅ Transaction Filter
  const [selectedStatus, setSelectedStatus] = useState("All Transactions");

  const navigate = useNavigate();
  const searchRef = useRef(null);

  // ✅ Supabase public file URL helper
  const getFileUrl = (path, bucketName = "businessdocuments") => {
    if (!path) return null;
    if (path.startsWith("http")) return path;
    const cleanPath = path.replace(/^\/+|\/+$/g, "");
    const { data } = supabase.storage.from(bucketName).getPublicUrl(cleanPath);
    return data?.publicUrl || null;
  };

  const renderDocumentImage = (url, alt) => {
    const imageUrl = getFileUrl(url);
    if (!url) return <span>No file uploaded</span>;
    if (!imageUrl) return <span className="error-text">Invalid URL</span>;

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

  // ✅ Fetch all businesses
  useEffect(() => {
    fetchBusinesses();
  }, []);

  const fetchBusinesses = async () => {
    setLoading(true);
    const { data } = await supabase.from("business_profiles").select("*");
    setBusinesses(data || []);
    setLoading(false);
  };

  // ✅ Custom Date Filter
  const handleCustomDateFilter = async () => {
    if (!startDate || !endDate) {
      alert("Please select both start and end dates.");
      return;
    }

    const { data, error } = await supabase
      .from("business_profiles")
      .select("*")
      .gte("created_at", new Date(startDate).toISOString())
      .lte("created_at", new Date(endDate).toISOString());

    if (error) {
      console.error("Error filtering by date:", error.message);
    } else {
      setBusinesses(data || []);
      setShowDateDropdown(false);
    }
  };

  // ✅ Filter by Status
  const handleFilterStatus = async (status) => {
    setSelectedStatus(status);
    if (status === "All Transactions") {
      fetchBusinesses();
    } else {
      const { data, error } = await supabase
        .from("business_profiles")
        .select("*")
        .eq("status", status.toLowerCase());
      if (error) console.error(error.message);
      else setBusinesses(data || []);
    }
  };

  // ✅ Search history outside click
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (searchRef.current && !searchRef.current.contains(e.target)) {
        setShowHistory(false);
        setShowDateDropdown(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // ✅ Save search history
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

  // ✅ Approve
  const handleApprove = async () => {
    if (!selectedBiz) return;
    const { data } = await supabase
      .from("business_profiles")
      .update({ status: "approved" })
      .eq("id", selectedBiz.id)
      .select();
    if (data?.length) {
      setBusinesses((prev) =>
        prev.map((b) =>
          b.id === selectedBiz.id ? { ...b, status: "approved" } : b
        )
      );
      setSelectedBiz(null);
    }
  };

  // ✅ Reject
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
              <h2 className="applications-title">Applications</h2>
              <p className="applications-subtitle">
                Review, Approve, or Reject submitted business applications
              </p>
            </div>
          </div>
          <div className="applications-header-icons">
            <div className="notification-wrapper">
              <Notifications />
            </div>
            <FiSettings
              size={22}
              className="settings-icon"
              onClick={() => navigate("/settings")}
            />
            <img
              src="https://via.placeholder.com/32"
              alt="profile"
              className="profile-avatar"
              onClick={() => navigate("/profile")}
            />
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

              {/* Search */}
              <div className="applications-search-box" ref={searchRef}>
                <FiSearch className="search-icon" />
                <input
                  type="text"
                  placeholder="Search here..."
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

              {/* ✅ Date & Transaction Filters */}
              <ApplicationsFilterRight
                startDate={startDate}
                endDate={endDate}
                setStartDate={setStartDate}
                setEndDate={setEndDate}
                showDateDropdown={showDateDropdown}
                setShowDateDropdown={setShowDateDropdown}
                handleCustomDateFilter={handleCustomDateFilter}
                handleFilterStatus={handleFilterStatus}
                selectedStatus={selectedStatus}
              />
            </div>

            {/* Table */}
            <div className="applications-table-wrapper">
              <h3 className="applications-table-title">Applicants For Review</h3>
              <table className="applications-table">
                <thead>
                  <tr>
                    <th>Review</th>
                    <th>Store Name</th>
                    <th>Owner Name</th>
                    <th>Phone</th>
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
                            new Date(biz.created_at).toLocaleDateString("en-US")}
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
            <h3>{selectedBiz.business_name} — Review</h3>
            <p>
              <strong>Owner:</strong> {selectedBiz.owner_first_name}{" "}
              {selectedBiz.owner_last_name}
            </p>
            <p>
              <strong>Phone:</strong> {selectedBiz.business_phone_number}
            </p>
            <p>
              <strong>Address:</strong> {selectedBiz.business_address}
            </p>

            <div className="review-docs">
              <div className="doc-box">
                <p>BIR Registration</p>
                {renderDocumentImage(selectedBiz.bir_registration_url, "BIR")}
              </div>
              <div className="doc-box">
                <p>Business Certificate</p>
                {renderDocumentImage(
                  selectedBiz.business_certificate_url,
                  "Certificate"
                )}
              </div>
              <div className="doc-box">
                <p>Mayor’s Permit</p>
                {renderDocumentImage(selectedBiz.mayors_permit_url, "Permit")}
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

      {/* ✅ Image Preview */}
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
              <h3>Rejecting Applicant</h3>
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
                "Unclear Photo of Documentation",
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
