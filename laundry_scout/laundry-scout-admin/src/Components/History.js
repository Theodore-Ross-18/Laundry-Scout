import React, { useState, useEffect, useRef } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/History.css";
import { FiMenu, FiSearch } from "react-icons/fi";
import { useNavigate } from "react-router-dom";
import Notifications from "./Notifications";
import Sidebar from "./Sidebar";

function History() {
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [search, setSearch] = useState("");
  const [searchHistory, setSearchHistory] = useState([]);
  const [showHistory, setShowHistory] = useState(false);

  const [showSettings, setShowSettings] = useState(false); // ✅ Profile dropdown
  const searchRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("business_profiles")
      .select(
        "id,business_name,owner_first_name,owner_last_name,status,rejection_reason,created_at"
      )
      .in("status", ["approved", "rejected"])
      .order("created_at", { ascending: false });

    if (error) console.error("Error fetching history:", error.message);
    else {
      const transformed = (data || []).map((row) => ({
        id: row.id,
        business_name: row.business_name,
        owner_name: `${row.owner_first_name || ""} ${row.owner_last_name || ""}`.trim(),
        action:
          row.status && row.status.toLowerCase() === "approved"
            ? "Approval"
            : row.status && row.status.toLowerCase() === "rejected"
            ? "Rejection"
            : "-",
        status: row.status,
        rejection_reason: row.rejection_reason,
        created_at: row.created_at,
      }));
      setRecords(transformed);
    }
    setLoading(false);
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter" && search.trim() !== "") {
      if (!searchHistory.includes(search)) {
        setSearchHistory([search, ...searchHistory].slice(0, 5));
      }
      setShowHistory(false);
    }
  };

  const deleteHistory = (item) => setSearchHistory(searchHistory.filter((h) => h !== item));

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (searchRef.current && !searchRef.current.contains(event.target)) {
        setShowHistory(false);
        setShowSettings(false); // ✅ close profile dropdown too
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const filteredRecords = records.filter((rec) =>
    [rec.business_name, rec.owner_name, rec.action, rec.status]
      .filter(Boolean)
      .some((field) => field.toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div className="history-root">
      {/* Sidebar */}
      <Sidebar isOpen={isSidebarOpen} activePage="history" />

      <main className={`history-main ${isSidebarOpen ? "" : "expanded"}`}>
        <header className="history-header">
          <div className="history-header-left">
            <FiMenu
              className="history-toggle-sidebar"
              onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            />
            <div>
              <h2 className="history-title">HISTORY</h2>
              <p className="history-subtitle">Track all approval and rejection records</p>
            </div>
          </div>

          {/* Header Icons: Notifications + Profile */}
          <div className="history-header-icons">
            <Notifications />
            
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
          <h3 className="History-table-title">Application History</h3>
          <table>
            <thead>
              <tr>
                <th>Business</th>
                <th>Owner</th>
                <th>Action</th>
                <th>Status</th>
                <th>Rejection Reason</th>
                <th>Date</th>
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
                      {rec.status?.toLowerCase() === "approved" ? (
                        <span style={{ color: "green", fontWeight: "bold" }}>✔ Approved</span>
                      ) : (
                        <span style={{ color: "red", fontWeight: "bold" }}>✖ Rejected</span>
                      )}
                    </td>
                    <td>{rec.status?.toLowerCase() === "rejected" ? rec.rejection_reason || "N/A" : "N/A"}</td>
                    <td className="record-time">
                      {rec.created_at ? new Date(rec.created_at).toLocaleString() : ""}
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
