import React, { useEffect, useState } from "react";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Clients.css";
import { FiMenu } from "react-icons/fi";
import { useNavigate } from "react-router-dom";

// ✅ Import the shared components
import Sidebar from "./Sidebar";
import Notifications from "./Notifications";

function Clients() {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [showSettings, setShowSettings] = useState(false); // ✅ settings dropdown

  const navigate = useNavigate();

  // 🔹 Fetch APPROVED clients from Supabase
  useEffect(() => {
    const fetchClients = async () => {
      setLoading(true);
      const { data, error } = await supabase
        .from("business_profiles")
        .select("*")
        .eq("status", "approved"); // ✅ only approved

      if (error) {
        console.error("Error fetching clients:", error.message);
      } else {
        setClients(data || []);
      }
      setLoading(false);
    };

    fetchClients();
  }, []);

  // 🔹 Filter clients
  const filteredClients = clients.filter((client) => {
    const name = client?.business_name || client?.name || "";
    return name.toLowerCase().includes(search.toLowerCase());
  });

  // Close settings dropdown on outside click
  useEffect(() => {
    const handleClickOutside = () => setShowSettings(false);
    document.addEventListener("click", handleClickOutside);
    return () => document.removeEventListener("click", handleClickOutside);
  }, []);

  return (
    <div className="clients-root">
      {/* ✅ Shared Sidebar */}
      <Sidebar isOpen={sidebarOpen} activePage="clients" />

      {/* Main Content */}
      <main className={`clients-main ${sidebarOpen ? "" : "expanded"}`}>
        <header className="clients-header">
          <div className="clients-header-left">
            <FiMenu
              className="clients-toggle-sidebar"
              onClick={() => setSidebarOpen(!sidebarOpen)}
            />
            <div>
              <h1 className="clients-title">CLIENTS</h1>
              <p className="clients-subtitle">All Approved Laundry Businesses</p>
            </div>
          </div>

          {/* Header icons: Notifications + Profile Dropdown */}
          <div className="clients-header-icons">
            <Notifications />

            {/* ✅ Profile Avatar */}
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

        {/* Search */}
        <div>
          <input
            type="text"
            placeholder="Search clients..."
            className="clients-search-box"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
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
