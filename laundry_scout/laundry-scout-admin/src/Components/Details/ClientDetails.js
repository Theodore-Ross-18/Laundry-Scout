// src/Components/Details/ClientDetail.js
import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { supabase } from "../../Supabase/supabaseClient";
import "../../Style/Details/ClientDetails.css";
import Sidebar from "../Sidebar";
import Notifications from "../Notifications";
import { FiSettings } from "react-icons/fi";

function ClientDetail() {
  const { id } = useParams();
  const [client, setClient] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(true);

  useEffect(() => {
    const fetchClient = async () => {
      const { data, error } = await supabase
        .from("business_profiles")
        .select("*")
        .eq("id", id)
        .single();

      if (error) {
        console.error("Error fetching client:", error.message);
      } else {
        setClient(data);
      }
      setLoading(false);
    };

    fetchClient();
  }, [id]);

  return (
    <div className="client-detail-root">
      {/* Sidebar */}
      <Sidebar isOpen={sidebarOpen} />

      {/* Main Content */}
      <main className={`client-detail-main ${sidebarOpen ? "shifted" : ""}`}>
        {/* Header */}
        <div className="client-detail-header">
          <div className="client-detail-header-left">
            <div>
              <h1 className="client-detail-title">Client Details</h1>
              <p className="client-detail-subtitle">
                All Approved Laundry Businesses
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
        </div>

        {/* Scrollable Details */}
        <div className="client-detail">
          {loading ? (
            // Loading spinner
            <div className="loading-spinner">
              <div className="spinner"></div>
              <p>Fetching client data...</p>
            </div>
          ) : !client ? (
            <p className="loading-msg">No client found.</p>
          ) : (
            <>
              {/* Header Section */}
              <div className="client-header">
                <img
                  src={
                    client.cover_photo_url ||
                    "https://via.placeholder.com/600x300"
                  }
                  alt={
                    client.business_name ||
                    client.owner_last_name ||
                    "Business"
                  }
                  className="cover-photo"
                />
                <h1>
                  {client.business_name ||
                    `${client.owner_first_name || ""} ${
                      client.owner_last_name || ""
                    }`}
                </h1>
                <p className="address">
                  📍 {client.business_address || "N/A"}
                </p>
                <p className="since">
                  Member Since{" "}
                  {client?.created_at
                    ? new Date(client.created_at).toLocaleDateString()
                    : "N/A"}
                </p>
              </div>

              {/* Body Sections */}
              <div className="client-body">
                <section>
                  <h2>Business Information</h2>
                  <p>
                    <strong>Business Name: </strong>
                    {client.business_name || "N/A"}
                  </p>
                  <p>
                    <strong>Business Address: </strong>
                    {client.business_address || "N/A"}
                  </p>
                  <p>
                    <strong>Business Type: </strong>
                    {client.business_type || "N/A"}
                  </p>
                </section>

                <section>
                  <h2>Owner Information</h2>
                  <p>
                    <strong>First Name: </strong>
                    {client.owner_first_name || "N/A"}
                  </p>
                  <p>
                    <strong>Last Name: </strong>
                    {client.owner_last_name || "N/A"}
                  </p>
                  <p>
                    <strong>Email: </strong>
                    {client.owner_email || "N/A"}
                  </p>
                  <p>
                    <strong>Phone: </strong>
                    {client.owner_phone || "N/A"}
                  </p>
                </section>

                <section>
                  <h2>Additional Details</h2>
                  {Object.entries(client).map(([key, value]) => {
                    if (
                      [
                        "id",
                        "created_at",
                        "cover_photo_url",
                        "business_name",
                        "business_address",
                        "business_type",
                        "owner_first_name",
                        "owner_last_name",
                        "owner_email",
                        "owner_phone",
                      ].includes(key)
                    )
                      return null;

                    return (
                      <p key={key}>
                        <strong>{key.replace(/_/g, " ")}: </strong>
                        {value && value !== "" ? value.toString() : "N/A"}
                      </p>
                    );
                  })}
                </section>
              </div>
            </>
          )}
        </div>
      </main>
    </div>
  );
}

export default ClientDetail;
