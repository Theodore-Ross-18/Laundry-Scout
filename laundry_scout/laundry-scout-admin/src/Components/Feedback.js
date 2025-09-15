import React, { useState, useEffect } from "react";
import {
  FiSettings,
  FiBell,
  FiHome,
  FiFileText,
  FiUsers,
  FiUser,
  FiClock,
  FiMessageSquare,
  FiLogOut,
} from "react-icons/fi";
import { Link, useNavigate } from "react-router-dom";
import { supabase } from "../Supabase/supabaseClient";
import "../Style/Feedback.css";

function Feedback() {
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [userFeedbacks, setUserFeedbacks] = useState([]);
  const [businessFeedbacks, setBusinessFeedbacks] = useState([]);
  const [adminFeedbacks, setAdminFeedbacks] = useState([]);
  const [users, setUsers] = useState([]);
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('users'); // 'users', 'businesses', or 'admin'

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

        // Merge user feedback with user info
        const mergedUserFeedbacks = (userFeedbackData || []).map((fb) => {
          const user = userData?.find((u) => u.id === fb.user_id);
          return {
            ...fb,
            user_fullname: user
              ? `${user.first_name} ${user.last_name}`
              : "Unknown User",
            user_avatar:
              user?.profile_image_url || "https://via.placeholder.com/48",
            user_username: user?.username || "",
          };
        });

        // Fetch business feedback with business_profiles join
        const { data: businessFeedbackData, error: businessFeedbackError } = await supabase
          .from("feedback")
          .select(`*, business_profiles!inner(business_name, cover_photo_url)`)
          .eq("feedback_type", "business")
          .order("created_at", { ascending: false });

        if (businessFeedbackError) throw businessFeedbackError;

        // Merge business feedback with business info
        const mergedBusinessFeedbacks = (businessFeedbackData || []).map((fb) => {
          const user = userData?.find((u) => u.id === fb.user_id);
          return {
            ...fb,
            business_name: fb.business_profiles?.business_name || (user ? `${user.first_name} ${user.last_name}` : "Business Owner"),
            business_avatar: fb.business_profiles?.cover_photo_url || user?.profile_image_url || "https://via.placeholder.com/48",
            reviewer_name: user ? `${user.first_name} ${user.last_name}` : "Anonymous",
          };
        });

        // Fetch admin feedback (from message screen)
        const { data: adminFeedbackData, error: adminFeedbackError } = await supabase
          .from("feedback")
          .select("*")
          .eq("feedback_type", "admin")
          .order("created_at", { ascending: false });

        if (adminFeedbackError) throw adminFeedbackError;

        // Merge admin feedback with user info
        const mergedAdminFeedbacks = (adminFeedbackData || []).map((fb) => {
          const user = userData?.find((u) => u.id === fb.user_id);
          return {
            ...fb,
            user_fullname: user
              ? `${user.first_name} ${user.last_name}`
              : "Unknown User",
            user_avatar:
              user?.profile_image_url || "https://via.placeholder.com/48",
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
    <div className="dashboard-root">
      {/* Sidebar */}
      <aside className={`sidebar ${sidebarOpen ? "" : "closed"}`}>
        <div className="sidebar-title">Laundry Scout</div>
        <nav>
          <ul>
            <li>
              <Link to="/dashboard">
                <FiHome className="menu-icon" />
                <span>Dashboard</span>
              </Link>
            </li>
            <li>
              <Link to="/applications">
                <FiFileText className="menu-icon" />
                <span>Applications</span>
              </Link>
            </li>
            <li>
              <Link to="/clients">
                <FiUsers className="menu-icon" />
                <span>Clients</span>
              </Link>
            </li>
            <li>
              <Link to="/users">
                <FiUser className="menu-icon" />
                <span>Users</span>
              </Link>
            </li>
            <li>
              <Link to="/history">
                <FiClock className="menu-icon" />
                <span>History</span>
              </Link>
            </li>
            <li className="active">
              <Link to="/feedback">
                <FiMessageSquare className="menu-icon" />
                <span>Feedback</span>
              </Link>
            </li>
          </ul>
        </nav>
        <div className="logout" onClick={() => navigate("/logout")}>
          <FiLogOut className="menu-icon" />
          <span>Log Out</span>
        </div>
      </aside>

      {/* Main Content */}
      <main className="dashboard-main">
        <header className="page-header">
          <div>
            <h1>Feedback</h1>
            <p>Showing all feedback from users, businesses, and admin</p>
          </div>
          <div className="dashboard-header-icons">
            <FiSettings className="icon" />
            <FiBell className="icon" />
            <img
              src="https://via.placeholder.com/32"
              alt="Profile"
              className="profile-avatar"
            />
          </div>
        </header>

        {/* Tab Navigation */}
        <div className="feedback-tabs">
          <button 
            className={`tab-button ${activeTab === 'users' ? 'active' : ''}`}
            onClick={() => setActiveTab('users')}
          >
            User Feedback
          </button>
          <button 
            className={`tab-button ${activeTab === 'businesses' ? 'active' : ''}`}
            onClick={() => setActiveTab('businesses')}
          >
            Business Feedback
          </button>
          <button 
            className={`tab-button ${activeTab === 'admin' ? 'active' : ''}`}
            onClick={() => setActiveTab('admin')}
          >
            Admin Feedback
          </button>
        </div>

        {/* Feedback List */}
        <div className="feedback-list">
          {loading ? (
            <p>Loading...</p>
          ) : activeTab === 'users' ? (
            userFeedbacks.length > 0 ? (
              userFeedbacks.map((fb) => (
                <div key={fb.id} className="feedback-card">
                  <div className="feedback-top">
                    <div className="feedback-user">
                      <img
                        src={fb.user_avatar}
                        alt={fb.user_fullname}
                        className="feedback-avatar"
                      />
                      <div>
                        <h3 className="feedback-name">{fb.user_fullname}</h3>
                        <span className="feedback-username">
                          @{fb.user_username}
                        </span>
                        <br />
                        <span className="feedback-date">
                          {new Date(fb.created_at).toLocaleDateString()}
                        </span>
                      </div>
                    </div>
                    <div className="feedback-rating">
                      {"⭐".repeat(Math.min(Math.floor(fb.rating || 0), 5))}
                      <span className="rating-value">
                        {fb.rating ? fb.rating.toFixed(1) : ""}
                      </span>
                    </div>
                  </div>
                  <p className="feedback-message">{fb.comment}</p>
                </div>
              ))
            ) : (
              <p>No user feedback available.</p>
            )
          ) : activeTab === 'businesses' ? (
            businessFeedbacks.length > 0 ? (
              businessFeedbacks.map((fb) => (
                <div key={fb.id} className="feedback-card">
                  <div className="feedback-top">
                    <div className="feedback-user">
                      <img
                        src={fb.business_avatar}
                        alt={fb.business_name}
                        className="feedback-avatar"
                      />
                      <div>
                        <h3 className="feedback-name">{fb.business_name}</h3>
                        <span className="feedback-username">
                          Reviewed by: {fb.reviewer_name}
                        </span>
                        <br />
                        <span className="feedback-date">
                          {new Date(fb.created_at).toLocaleDateString()}
                        </span>
                      </div>
                    </div>
                    <div className="feedback-rating">
                      {"⭐".repeat(Math.min(Math.floor(fb.rating || 0), 5))}
                      <span className="rating-value">
                        {fb.rating ? fb.rating.toFixed(1) : ""}
                      </span>
                    </div>
                  </div>
                  <p className="feedback-message">{fb.comment}</p>
                </div>
              ))
            ) : (
              <p>No business feedback available.</p>
            )
          ) : (
            adminFeedbacks.length > 0 ? (
              adminFeedbacks.map((fb) => (
                <div key={fb.id} className="feedback-card">
                  <div className="feedback-top">
                    <div className="feedback-user">
                      <img
                        src={fb.user_avatar}
                        alt={fb.user_fullname}
                        className="feedback-avatar"
                      />
                      <div>
                        <h3 className="feedback-name">{fb.user_fullname}</h3>
                        <span className="feedback-username">
                          @{fb.user_username}
                        </span>
                        <br />
                        <span className="feedback-date">
                          {new Date(fb.created_at).toLocaleDateString()}
                        </span>
                      </div>
                    </div>
                    <div className="feedback-rating">
                      {"⭐".repeat(Math.min(Math.floor(fb.rating || 0), 5))}
                      <span className="rating-value">
                        {fb.rating ? fb.rating.toFixed(1) : ""}
                      </span>
                    </div>
                  </div>
                  <p className="feedback-message">{fb.comment}</p>
                </div>
              ))
            ) : (
              <p>No admin feedback available.</p>
            )
          )}
        </div>
      </main>
    </div>
  );
}

export default Feedback;
