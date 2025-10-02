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
          alt={client.business_name || client.owner_last_name || "Business"}
          className="cover-photo"
        />
        <h1>
          {client.business_name ||
            `${client.owner_first_name || ""} ${client.owner_last_name || ""}`}
        </h1>
        <p className="address">📍 {client.business_address || "N/A"}</p>
        <p className="since">
          Member Since{" "}
          {client?.created_at
            ? new Date(client.created_at).toLocaleDateString()
            : "N/A"}
        </p>
      </div>

      {/* Profile Sections */}
      <div className="client-body">
        {/* Business Info */}
        <h2>Business Information</h2>
        <p>
          <strong>Business Name:</strong> {client.business_name || "N/A"}
        </p>
        <p>
          <strong>Business Address:</strong> {client.business_address || "N/A"}
        </p>
        <p>
          <strong>Business Type:</strong> {client.business_type || "N/A"}
        </p>

        {/* Owner Info */}
        <h2>Owner Information</h2>
        <p>
          <strong>Owner First Name:</strong> {client.owner_first_name || "N/A"}
        </p>
        <p>
          <strong>Owner Last Name:</strong> {client.owner_last_name || "N/A"}
        </p>
        <p>
          <strong>Owner Email:</strong> {client.owner_email || "N/A"}
        </p>
        <p>
          <strong>Owner Phone:</strong> {client.owner_phone || "N/A"}
        </p>

        {/* Other Details */}
        <h2>Additional Details</h2>
        {Object.entries(client).map(([key, value]) => {
          // skip system + already shown fields
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
              <strong>{key.replace(/_/g, " ")}:</strong>{" "}
              {value && value !== "" ? value.toString() : "N/A"}
            </p>
          );
        })}
      </div>
    </div>
  );
}

export default ClientDetail;
