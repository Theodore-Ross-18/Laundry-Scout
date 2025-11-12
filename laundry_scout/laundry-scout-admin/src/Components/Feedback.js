import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Feedback.css";
import {
  FiSettings,
  FiMenu,
  FiUserCheck,
  FiUserPlus,
  FiGrid,
  FiMail,
} from "react-icons/fi";
import Notifications from "./Notifications";
import Sidebar from "./Sidebar";

function Feedback() {
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [userFeedbacks, setUserFeedbacks] = useState([]);
  const [businessFeedbacks, setBusinessFeedbacks] = useState([]);
  const [adminFeedbacks, setAdminFeedbacks] = useState([]);
  const [users, setUsers] = useState([]);
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState("admin"); // 'admin' or 'businesses'

  // ✅ Profile dropdown state
  const [showSettings, setShowSettings] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);

        // Fetch user profiles
        const { data: userData, error: userError } = await supabase
          .from("user_profiles")
          .select("id, first_name, last_name, username, profile_image_url");
        if (userError) throw userError;
        setUsers(userData || []);

        // Fetch business profiles
        const { data: businessData, error: businessError } = await supabase
          .from("business_profiles")
          .select("id, business_name, cover_photo_url");
        if (businessError) throw businessError;
        setBusinesses(businessData || []);

        // Fetch user feedback
        const { data: userFeedbackData, error: userFeedbackError } = await supabase
          .from("feedback")
          .select("*")
          .eq("feedback_type", "user")
          .order("created_at", { ascending: false });
        if (userFeedbackError) throw userFeedbackError;

        const mergedUserFeedbacks = (userFeedbackData || []).map((fb) => {
          const user = userData?.find((u) => u.id === fb.user_id);
          return {
            ...fb,
            user_fullname: user ? `${user.first_name} ${user.last_name}` : "Unknown User",
            user_avatar: user?.profile_image_url || "https://via.placeholder.com/48",
            user_username: user?.username || "",
          };
        });

        // Fetch business feedback with join
        const { data: businessFeedbackData, error: businessFeedbackError } = await supabase
          .from("feedback")
          .select(`*, business_profiles!inner(business_name, cover_photo_url)`)
          .eq("feedback_type", "business")
          .order("created_at", { ascending: false });
        if (businessFeedbackError) throw businessFeedbackError;

        const mergedBusinessFeedbacks = (businessFeedbackData || []).map((fb) => {
          const user = userData?.find((u) => u.id === fb.user_id);
          return {
            ...fb,
            business_name:
              fb.business_profiles?.business_name ||
              (user ? `${user.first_name} ${user.last_name}` : "Business Owner"),
            business_avatar:
              fb.business_profiles?.cover_photo_url ||
              user?.profile_image_url ||
              "https://via.placeholder.com/48",
            reviewer_name: user ? `${user.first_name} ${user.last_name}` : "Anonymous",
          };
        });

        // Fetch admin feedback
        const { data: adminFeedbackData, error: adminFeedbackError } = await supabase
          .from("feedback")
          .select("*")
          .eq("feedback_type", "admin")
          .order("created_at", { ascending: false });
        if (adminFeedbackError) throw adminFeedbackError;

        const mergedAdminFeedbacks = (adminFeedbackData || []).map((fb) => {
          const user = userData?.find((u) => u.id === fb.user_id);
          return {
            ...fb,
            user_fullname: user ? `${user.first_name} ${user.last_name}` : "Unknown User",
            user_avatar: user?.profile_image_url || "https://via.placeholder.com/48",
            user_username: user?.username || "",
          };
        });

        setUserFeedbacks(mergedUserFeedbacks);
        setBusinessFeedbacks(mergedBusinessFeedbacks);
        setAdminFeedbacks(mergedAdminFeedbacks);
      } catch (err) {
        console.error("Error fetching data:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  return (
    <div className="feedback-root">
      {/* Sidebar */}
      <Sidebar isOpen={sidebarOpen} activePage="feedback" />

      <main className={`feedback-main ${sidebarOpen ? "" : "expanded"}`}>
        <header className="feedback-header">
          <div>
            <h2 className="feedback-title">Feedback</h2>
            <p className="feedback-subtitle">Showing all feedback from users and businesses here.</p>
          </div>

          {/* Notifications + Profile */}
          <div className="feedback-header-icons">
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

        {/* Tab Navigation */}
        <div className="feedback-tabs">
          <button
            className={`tab-button ${activeTab === "admin" ? "active" : ""}`}
            onClick={() => setActiveTab("admin")}
          >
            User Feedback
          </button>
          <button
            className={`tab-button ${activeTab === "businesses" ? "active" : ""}`}
            onClick={() => setActiveTab("businesses")}
          >
            Business Feedback
          </button>
        </div>

        {/* Feedback List */}
        <div className="feedback-list">
          {loading ? (
            <p>Loading...</p>
          ) : activeTab === "admin" ? (
            adminFeedbacks.length > 0 ? (
              adminFeedbacks.map((fb) => (
                <div key={fb.id} className="feedback-card">
                  <div className="feedback-top">
                    <div className="feedback-user">
                      <img src={fb.user_avatar} alt={fb.user_fullname} className="feedback-avatar" />
                      <div>
                        <h3 className="feedback-name">{fb.user_fullname}</h3>
                        <span className="feedback-username">@{fb.user_username}</span>
                        <br />
                        <span className="feedback-date">{new Date(fb.created_at).toLocaleDateString()}</span>
                      </div>
                    </div>
                    <div className="feedback-rating">
                      {"⭐".repeat(Math.min(Math.floor(fb.rating || 0), 5))}
                      <span className="rating-value">{fb.rating ? fb.rating.toFixed(1) : ""}</span>
                    </div>
                  </div>
                  <p className="feedback-message">{fb.comment}</p>
                </div>
              ))
            ) : (
              <p>No user feedback available.</p>
            )
          ) : businessFeedbacks.length > 0 ? (
            businessFeedbacks.map((fb) => (
              <div key={fb.id} className="feedback-card">
                <div className="feedback-top">
                  <div className="feedback-user">
                    <img src={fb.business_avatar} alt={fb.business_name} className="feedback-avatar" />
                    <div>
                      <h3 className="feedback-name">{fb.business_name}</h3>
                      <span className="feedback-username">Reviewed by: {fb.reviewer_name}</span>
                      <br />
                      <span className="feedback-date">{new Date(fb.created_at).toLocaleDateString()}</span>
                    </div>
                  </div>
                  <div className="feedback-rating">
                    {"⭐".repeat(Math.min(Math.floor(fb.rating || 0), 5))}
                    <span className="rating-value">{fb.rating ? fb.rating.toFixed(1) : ""}</span>
                  </div>
                </div>
                <p className="feedback-message">{fb.comment}</p>
              </div>
            ))
          ) : (
            <p>No business feedback available.</p>
          )}
        </div>
      </main>
    </div>
  );
}

export default Feedback;
