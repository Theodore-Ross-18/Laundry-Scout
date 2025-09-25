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

      {/* Dynamic Body Section */}
      <div className="client-body">
        <h2>Profile Details</h2>
        {Object.entries(client).map(([key, value]) => {
          // Skip system fields if you don’t want them
          if (["id", "created_at", "cover_photo_url"].includes(key)) return null;

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
