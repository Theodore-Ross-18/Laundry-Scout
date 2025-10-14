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
  const [activeTab, setActiveTab] = useState("info");
  const [modalImage, setModalImage] = useState(null); // for permit lightbox

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
              {/* Summary Header (new layout) */}
              <div className="client-summary">
                <div className="summary-left">
                  <h1 className="summary-title">
                    {client.business_name ||
                      `${client.owner_first_name || ""} ${
                        client.owner_last_name || ""
                      }`}
                  </h1>
                  <p className="summary-address">
                    {client.business_address || "N/A"}
                  </p>
                  <p className="summary-since">
                    Member Since {client?.created_at
                      ? new Date(client.created_at).toLocaleDateString()
                      : "N/A"}
                  </p>
                </div>
                <div className="summary-right">
                  <img
                    src={
                      client.cover_photo_url ||
                      "https://via.placeholder.com/360x120"
                    }
                    alt={client.business_name || "Business"}
                    className="summary-cover"
                  />
                </div>
              </div>

              {/* Tabs */}
              <div className="client-tabs">
                <button
                  className={`client-tab ${activeTab === "info" ? "active" : ""}`}
                  onClick={() => setActiveTab("info")}
                >
                  Business & Owner Information
                </button>
                <button
                  className={`client-tab ${activeTab === "permits" ? "active" : ""}`}
                  onClick={() => setActiveTab("permits")}
                >
                  Permits
                </button>
                <button
                  className={`client-tab ${activeTab === "service" ? "active" : ""}`}
                  onClick={() => setActiveTab("service")}
                >
                  Service Details
                </button>
                <button
                  className={`client-tab ${activeTab === "terms" ? "active" : ""}`}
                  onClick={() => setActiveTab("terms")}
                >
                  Terms & Conditions
                </button>
              </div>

              {/* Body Sections */}
              <div className="client-body">
                {activeTab === "info" && (
                  <div className="info-card">
                    <div className="info-columns">
                      <div className="info-col">
                        <div className="info-item">
                          <div className="label">Business Name</div>
                          <div className="value bold">{client.business_name || "N/A"}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Business Address</div>
                          <div className="value">{client.business_address || "N/A"}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Business Type</div>
                          <div className="value">{client.business_type || "N/A"}</div>
                        </div>
                      </div>
                      <div className="divider" />
                      <div className="info-col">
                        <div className="info-item">
                          <div className="label">First Name</div>
                          <div className="value">{client.owner_first_name || "N/A"}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Last Name</div>
                          <div className="value">{client.owner_last_name || "N/A"}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Email</div>
                          <div className="value">{client.owner_email || "N/A"}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Contact Number</div>
                          <div className="value">{client.owner_phone || "N/A"}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Owner ID</div>
                          <div className="value">{client.id || "N/A"}</div>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {activeTab === "permits" && (
                  <div className="permits-grid">
                    <div className="permit-card">
                      <div className="permit-header">
                        <span className="permit-index">Business Permit 1</span>
                        <span className="permit-title">BIR Registration</span>
                      </div>
                      <div className="permit-image-wrap">
                        {client.bir_registration_url ? (
                          <img src={client.bir_registration_url} alt="BIR Registration" className="permit-image" onClick={() => setModalImage(client.bir_registration_url)} />
                        ) : (
                          <div className="permit-image placeholder" />
                        )}
                      </div>
                    </div>

                    <div className="permit-card">
                      <div className="permit-header">
                        <span className="permit-index">Business Permit 2</span>
                        <span className="permit-title">Business Certificate</span>
                      </div>
                      <div className="permit-image-wrap">
                        {client.business_certificate_url ? (
                          <img src={client.business_certificate_url} alt="Business Certificate" className="permit-image" onClick={() => setModalImage(client.business_certificate_url)} />
                        ) : (
                          <div className="permit-image placeholder" />
                        )}
                      </div>
                    </div>

                    <div className="permit-card">
                      <div className="permit-header">
                        <span className="permit-index">Business Permit 3</span>
                        <span className="permit-title">Mayors Permit</span>
                      </div>
                      <div className="permit-image-wrap">
                        {client.mayors_permit_url ? (
                          <img src={client.mayors_permit_url} alt="Mayor's Permit" className="permit-image" onClick={() => setModalImage(client.mayors_permit_url)} />
                        ) : (
                          <div className="permit-image placeholder" />
                        )}
                      </div>
                    </div>
                  </div>
                )}

                {activeTab === "service" && (
                  <div className="info-card">
                    <div className="info-columns">
                      <div className="info-col">
                        <div className="info-item">
                          <div className="label">Services Offered</div>
                          <div className="value">
                            {Array.isArray(client.services_offered)
                              ? client.services_offered
                                  .map((s) => (typeof s === "string" ? s.trim() : String(s)))
                                  .filter(Boolean)
                              .join(", ")
                              : (client.services_offered || "N/A")}
                          </div>
                        </div>
                        <div className="info-item">
                          <div className="label">Exact Location</div>
                          <div className="value">{client.exact_location || client.business_name + ", " + (client.business_address || "")}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Business Contact Number</div>
                          <div className="value">{client.business_phone_number || client.owner_phone || "N/A"}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Open Hours</div>
                          <div className="value">{client.open_hours || "N/A"}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Availability Status</div>
                          <div className="value">{client.availability_status || "N/A"}</div>
                        </div>
                      </div>
                      <div className="divider" />
                      <div className="info-col">
                        <div className="info-item">
                          <div className="label">About the Business</div>
                          <div className="value">{client.about_business || "N/A"}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Last Active</div>
                          <div className="value">{client.last_active || (client.updated_at ? new Date(client.updated_at).toISOString().slice(0,10) : "N/A")}</div>
                        </div>
                        <div className="info-item">
                          <div className="label">Status</div>
                          <div className={`value status ${String(client.status || "Approved").toLowerCase()}`}>{client.status || "Approved"}</div>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {activeTab === "terms" && (
                  <div className="terms-card">
                    <div className="terms-header">Terms & Conditions</div>
                    <div className="terms-content">
                      {client.terms_and_conditions || "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum id felis ullamcorper, efficitur nisi varius, mollis odio. Praesent quis interdum felis, a placerat purus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos."}
                    </div>
                  </div>
                )}
              </div>
            </>
          )}
        </div>
      {/* Clicking Image - Permits */}
      {/* Centered image modal */}
      {modalImage && (
        <div className="image-modal" onClick={() => setModalImage(null)}>
          <div className="image-modal-inner" onClick={(e) => e.stopPropagation()}>
            <img src={modalImage} alt="Permit" className="image-modal-img" />
            <button className="image-modal-close" aria-label="Close" onClick={() => setModalImage(null)}>×</button>
          </div>
        </div>
      )}
      </main>
    </div>
  );
}

export default ClientDetail;
