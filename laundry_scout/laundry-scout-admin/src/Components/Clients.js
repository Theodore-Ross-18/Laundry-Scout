import React, { useEffect, useState, useRef } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Clients.css";
import { FiMenu, FiSearch, FiSettings } from "react-icons/fi";
import { useNavigate } from "react-router-dom";

// ✅ Import the shared components
import Sidebar from "./Sidebar";
import Notifications from "./Notifications";

function Clients() {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  // added to support search history
  const [searchHistory, setSearchHistory] = useState([]);
  const [showHistory, setShowHistory] = useState(false);

  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [showSettings, setShowSettings] = useState(false); // settings dropdown
  const searchRef = useRef(null);

  const navigate = useNavigate();

  // 🔹 Fetch APPROVED clients from Supabase
  useEffect(() => {
    const fetchClients = async () => {
      setLoading(true);
      const { data, error } = await supabase
        .from("business_profiles")
        .select("*")
        .eq("status", "approved"); // only approved

      if (error) {
        console.error("Error fetching clients:", error.message);
      } else {
        setClients(data || []);
      }
      setLoading(false);
    };

    fetchClients();
  }, []);

  // 🔹 Filter clients by search text
  const filteredClients = clients.filter((client) => {
    const name = client?.business_name || client?.name || "";
    return name.toLowerCase().includes(search.toLowerCase());
  });

  // 🔹 handle Enter key for search history
  const handleKeyDown = (e) => {
    if (e.key === "Enter" && search.trim() !== "") {
      if (!searchHistory.includes(search)) {
        setSearchHistory([search, ...searchHistory].slice(0, 5));
      }
      setShowHistory(false);
    }
  };

  const deleteHistory = (item) =>
    setSearchHistory(searchHistory.filter((h) => h !== item));

  // Close dropdowns on outside click
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (searchRef.current && !searchRef.current.contains(event.target)) {
        setShowHistory(false);
        setShowSettings(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <div className="clients-root">
      {/* ✅ Shared Sidebar */}
      <Sidebar isOpen={sidebarOpen} activePage="clients" />

      {/* Main Content */}
      <main className={`clients-main ${sidebarOpen ? "" : "expanded"}`}>
        <header className="clients-header">
          <div className="clients-header-left">
            <div>
              <h1 className="clients-title">CLIENTS</h1>
              <p className="clients-subtitle">All Approved Laundry Businesses</p>
            </div>
          </div>

          {/* Header icons: Notifications + Profile Dropdown */}
          <div className="clients-header-icons">
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

        {/* Search + Filter */}
        <div className="applications-filters">
          <div className="applications-filter-tab">
            <span className="app-filter-label">All Clients</span>
            <span className="count">{filteredClients.length}</span>
          </div>
          <div className="applications-search-box" ref={searchRef}>
            <FiSearch className="search-icon" />
            <input
              type="text"
              placeholder="Search Clients"
              className="applications-search-input"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={handleKeyDown}
              onFocus={() => setShowHistory(true)}
            />
            {showHistory && searchHistory.length > 0 && (
              <ul className="applications-search-history">
                {searchHistory.map((item, idx) => (
                  <li key={idx} onClick={() => setSearch(item)}>
                    <span>{item}</span>
                    <button
                      className="applications-delete-history"
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
          <div className="applications-filter-right">
            <button className="date-btn">19 Dec - 20 Dec 2024</button>
            <button className="all-btn">All Transactions</button>
          </div>
        </div>

        {/* Client Cards */}
        {loading ? (
          <p>Loading clients...</p>
        ) : filteredClients.length === 0 ? (
          <p>No approved clients found.</p>
        ) : (
          <div className="grid">
            {filteredClients.map((client) => (
              <div
                key={client.id}
                className="client-card"
                onClick={() => navigate(`/clients/${client.id}`)}
                style={{ cursor: "pointer" }}
              >
                <img
                  src={
                    client?.cover_photo_url ||
                    "https://via.placeholder.com/400x200"
                  }
                  alt={client?.business_name || client?.name || "Business"}
                />
                <div className="info">
                  <h2>
                    {client?.business_name ||
                      client?.name ||
                      "Unnamed Business"}
                  </h2>
                  <p className="address">
                    📍 {client?.business_address || "No address provided"}
                  </p>
                  <p className="since">
                    Since{" "}
                    {client?.created_at
                      ? new Date(client.created_at).toLocaleDateString()
                      : "N/A"}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}

export default Clients;
