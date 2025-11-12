import React, { useState, useEffect, useRef } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Applications.css";
import { FiSearch, FiSettings } from "react-icons/fi";
import { useNavigate } from "react-router-dom";
import AccessibleDropdown from "./AccessibleDropdown";
import DateRangePicker from "./DateRangePicker";
<<<<<<< HEAD
import Sidebar from "./Sidebar";
import Notifications from "./Notifications";

=======

// ✅ Sidebar + Notifications
import Sidebar from "./Sidebar";
import Notifications from "./Notifications";


>>>>>>> f5615fdd80d0ceac6fb28889d0236b852237681d
function Applications() {
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [history, setHistory] = useState([]);
  const [showHistory, setShowHistory] = useState(false);
  const [selectedBiz, setSelectedBiz] = useState(null);
  const [preview, setPreview] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const [showRejectModal, setShowRejectModal] = useState(false);
  const [reason, setReason] = useState("");
  const [specificReason, setSpecificReason] = useState("");

<<<<<<< HEAD
=======
  // ✅ Date Filter States
>>>>>>> f5615fdd80d0ceac6fb28889d0236b852237681d
  const [startDate, setStartDate] = useState("");
   const [endDate, setEndDate] = useState("");

  const [selectedStatus, setSelectedStatus] = useState("All Transactions");

  const navigate = useNavigate();
  const searchRef = useRef(null);

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

  // Fetch businesses
  useEffect(() => {
    fetchBusinesses();
  }, []);

  const fetchBusinesses = async () => {
    setLoading(true);
    const { data, error } = await supabase.from("business_profiles").select("*");
    if (error) console.error(error.message);
    setBusinesses(data || []);
    setLoading(false);
  };

  const handleCustomDateFilter = async () => {
    if (!startDate || !endDate) {
      alert("Please select both start and end dates.");
      return;
    }
    const start = new Date(startDate);
    start.setHours(0, 0, 0, 0);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const start = new Date(startDate);
    start.setHours(0, 0, 0, 0);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const { data, error } = await supabase
      .from("business_profiles")
      .select("*")
      .gte("created_at", start.toISOString())
      .lte("created_at", end.toISOString());

<<<<<<< HEAD
    if (error) console.error(error.message);
    else setBusinesses(data || []);
=======
    if (error) {
      console.error("Error filtering by date:", error.message);
    } else {
      setBusinesses(data || []);
    }
>>>>>>> f5615fdd80d0ceac6fb28889d0236b852237681d
  };

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

  // Approve applicant
  const handleApprove = async () => {
    if (!selectedBiz) return;
    try {
      const { data, error } = await supabase
        .from("business_profiles")
        .update({ status: "approved", updated_at: new Date().toISOString() })
        .eq("id", selectedBiz.id)
        .select("*");

      if (error) throw error;

      if (data && data.length > 0) {
        setBusinesses((prev) =>
          prev.map((b) =>
            b.id === selectedBiz.id ? { ...b, status: "approved" } : b
          )
        );
        setSelectedBiz(null);
        alert("Applicant approved successfully!");
      }
    } catch (err) {
      console.error("Error approving applicant:", err);
      alert("Failed to approve applicant. Please try again.");
    }
  };

  // ✅ Reject applicant
  const handleReject = async () => {
    if (!selectedBiz) return;
    if (!reason) {
      alert("Please select a reason for rejection.");
      return;
    }

    console.log("Rejecting applicant ID:", selectedBiz.id);

    try {
      const { data, error } = await supabase
        .from("business_profiles")
        .update({
          status: "rejected",
          rejection_reason: reason,
          rejection_notes: specificReason || null,
          updated_at: new Date().toISOString(),
        })
        .eq("id", selectedBiz.id)
        .select("*");

      if (error) throw error;

      if (data && data.length > 0) {
        setBusinesses((prev) =>
          prev.map((b) =>
            b.id === selectedBiz.id
              ? { ...b, status: "rejected", rejection_reason: reason, rejection_notes: specificReason }
              : b
          )
        );
        setSelectedBiz(null);
        setShowRejectModal(false);
        setReason("");
        setSpecificReason("");
        alert("Applicant rejected successfully.");
      } else {
        alert("No applicant updated. Please try again.");
      }
    } catch (err) {
      console.error("Error rejecting applicant:", err);
      alert("Failed to reject applicant. Please try again.");
    }
  };

  return (
    <div className="applications-root">
      <Sidebar isOpen={sidebarOpen} activePage="applications" />

      <main className={`applications-main ${sidebarOpen ? "" : "expanded"}`}>
        <header className="applications-header">
          <div>
            <h2 className="applications-title">Applications</h2>
            <p className="applications-subtitle">
              Review, Approve, or Reject submitted business applications
            </p>
          </div>
          <div className="applications-header-icons">
            <Notifications />
            <FiSettings size={22} className="settings-icon" onClick={() => navigate("/settings")} />
            <img
              src="https://via.placeholder.com/32"
              alt="profile"
              className="profile-avatar"
              onClick={() => navigate("/profile")}
            />
          </div>
        </header>

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

<<<<<<< HEAD
=======
              {/* ✅ Date & Transaction Filters */}
>>>>>>> f5615fdd80d0ceac6fb28889d0236b852237681d
              <div className="applications-filter-right">
                <DateRangePicker
                  startDate={startDate}
                  endDate={endDate}
                  onChangeStart={setStartDate}
                  onChangeEnd={setEndDate}
                  onApply={handleCustomDateFilter}
                  buttonClassName="a-date-btn"
                  formatLabel={(s, e) =>
                    s && e
                      ? `${new Date(s).toLocaleDateString()} - ${new Date(e).toLocaleDateString()}`
                      : "Filter by Date Range"
                  }
                  align="right"
                />
                <AccessibleDropdown
                  buttonClassName="a-all-btn"
                  selected={selectedStatus}
                  options={["All Transactions", "Pending", "Approved", "Rejected"]}
                  onSelect={handleFilterStatus}
                  placeholder="All Transactions"
                  align="right"
                />
              </div>
            </div>

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
                    <tr><td colSpan="6">Loading...</td></tr>
                  ) : filteredBusinesses.length > 0 ? (
                    filteredBusinesses.map((biz) => (
                      <tr key={biz.id}>
                        <td><button className="review-btn" onClick={() => setSelectedBiz(biz)}>Review</button></td>
                        <td>{biz.business_name}</td>
                        <td>{biz.owner_first_name} {biz.owner_last_name}</td>
                        <td>{biz.business_phone_number}</td>
                        <td>{biz.created_at && new Date(biz.created_at).toLocaleDateString()}</td>
                        <td className={`status ${biz.status || "pending"}`}>{biz.status || "Pending"}</td>
                      </tr>
                    ))
                  ) : (
                    <tr><td colSpan="6">No businesses found.</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </>
        ) : (
          <div className="applications-review-panel">
            <h3>{selectedBiz.business_name} — Review</h3>
            <p><strong>Owner:</strong> {selectedBiz.owner_first_name} {selectedBiz.owner_last_name}</p>
            <p><strong>Phone:</strong> {selectedBiz.business_phone_number}</p>
            <p><strong>Address:</strong> {selectedBiz.business_address}</p>

            <div className="review-docs">
              <div className="doc-box">
                <p>BIR Registration</p>
                {renderDocumentImage(selectedBiz.bir_registration_url, "BIR")}
              </div>
              <div className="doc-box">
                <p>Business Certificate</p>
                {renderDocumentImage(selectedBiz.business_certificate_url, "Certificate")}
              </div>
              <div className="doc-box">
                <p>Mayor’s Permit</p>
                {renderDocumentImage(selectedBiz.mayors_permit_url, "Permit")}
              </div>
            </div>

            <div className="review-actions">
              <button className="approve-btn" onClick={handleApprove}>Approve</button>
              <button className="reject-btn" onClick={() => setShowRejectModal(true)}>Reject</button>
              <button className="back-btn" onClick={() => setSelectedBiz(null)}>Back</button>
            </div>
          </div>
        )}
      </main>

      {preview && (
        <div className="preview-overlay" onClick={() => setPreview(null)}>
          <div className="preview-content">
            <img src={preview} alt="Document Preview" />
          </div>
        </div>
      )}

      {showRejectModal && (
        <div className="modal-overlay">
          <div className="modal">
            <div className="modal-header">
              <h3>Rejecting Applicant</h3>
              <button className="close-btn" onClick={() => setShowRejectModal(false)}>×</button>
            </div>
            <div className="modal-body">
              <h4>Reason for Rejection</h4>
              {["Incomplete Documents", "Invalid Documents", "Duplicate Registration", "Unclear Photo of Documentation"].map((r) => (
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
              <button className="reject-confirm" onClick={handleReject}>Reject</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Applications;
