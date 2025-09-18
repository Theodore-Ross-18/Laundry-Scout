import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { supabase } from "../../Supabase/supabaseClient";
import "../../Style/Details/ClientDetails.css";

function ClientDetail() {
  const { id } = useParams();
  const [client, setClient] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

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

  if (loading) return <p>Loading details...</p>;
  if (!client) return <p>No client found.</p>;

  return (
    <div className="client-detail">
      {/* Back Button */}
      <button onClick={() => navigate(-1)} className="back-btn">
        ⬅ Back
      </button>

      {/* Header Section */}
      <div className="client-header">
        <img
          src={client.cover_photo_url || "https://via.placeholder.com/600x300"}
          alt={client.business_name || client.owner_last_name}
          className="cover-photo"
        />
        <h1>{client.business_name || (client.owner_first_name + " " + client.owner_last_name)}</h1>
        <p className="address">📍 {client.business_address || "N/A"}</p>
        <p className="since">
          Member Since{" "}
          {client?.created_at
            ? new Date(client.created_at).toLocaleDateString()
            : "N/A"}
        </p>
      </div>

      {/* Body Section */}
      <div className="client-body">
        <h2>Business Information</h2>
        <p>
          <strong>Owner:</strong> {client.owner_last_name || "N/A"}
        </p>
        <p>
          <strong>Description:</strong> {client.description || "No description"}
        </p>
        <p>
          <strong>Status:</strong> {client.status || "N/A"}
        </p>
        <p>
          <strong>Type:</strong> {client.business_type || "N/A"}
        </p>
        <p>
          <strong>Registration #:</strong> {client.registration_number || "N/A"}
        </p>
        <p>
          <strong>Tax ID:</strong> {client.tax_id || "N/A"}
        </p>

        <h2>Contact Info</h2>
        <p>📞 {client.business_phone_number || "N/A"}</p>
        <p>📧 {client.email || "N/A"}</p>
        <p>🌐 {client.website || "N/A"}</p>
        <p>📱 {client.social_media || "N/A"}</p>

        <h2>Location</h2>
        <p>
          <strong>Address:</strong> {client.business_address || "N/A"}
        </p>
        <p>
          <strong>City:</strong> {client.city || "N/A"}
        </p>
        <p>
          <strong>Province:</strong> {client.province || "N/A"}
        </p>
        <p>
          <strong>Zip Code:</strong> {client.zip_code || "N/A"}
        </p>

        <h2>Additional Info</h2>
        <p>
          <strong>Employees:</strong> {client.employees_count || "N/A"}
        </p>
        <p>
          <strong>Opening Hours:</strong> {client.opening_hours || "N/A"}
        </p>
        <p>
          <strong>Payment Methods:</strong> {client.payment_methods || "N/A"}
        </p>
      </div>
    </div>
  );
}

export default ClientDetail;
