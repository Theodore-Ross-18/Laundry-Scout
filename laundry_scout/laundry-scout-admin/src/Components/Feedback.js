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
  const [feedbacks, setFeedbacks] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);

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

        // Fetch feedback
        const { data: feedbackData, error: feedbackError } = await supabase
          .from("feedback")
          .select("*")
          .order("created_at", { ascending: false });

        if (feedbackError) throw feedbackError;

        // Merge feedback with user info
        const merged = (feedbackData || []).map((fb) => {
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

        setFeedbacks(merged);
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
            <p>Showing all feedback from users</p>
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

        {/* Feedback List */}
        <div className="feedback-list">
          {loading ? (
            <p>Loading...</p>
          ) : feedbacks.length > 0 ? (
            feedbacks.map((fb) => (
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
            <p>No feedback available.</p>
          )}
        </div>
      </main>
    </div>
  );
}

export default Feedback;
