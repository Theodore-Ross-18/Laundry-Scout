import React, { useState, useEffect } from "react";
import { supabase } from "../Supabase/supabaseClient";
import {
  FiSettings,
  FiBell,
  FiMenu,
  FiHome,
  FiFileText,
  FiUsers,
  FiUser,
  FiClock,
  FiMessageSquare,
  FiLogOut,
  FiUserCheck,
  FiUserPlus,
  FiGrid,
  FiMail,
} from "react-icons/fi";
import { Link, useNavigate } from "react-router-dom";
import "../Style/Dashboard.css";

function Dashboard({ users }) {
  const [customers, setCustomers] = useState(0);
  const [owners, setOwners] = useState(0);
  const [scans, setScans] = useState(0);
  const [feedback, setFeedback] = useState(0);
  const [applicants, setApplicants] = useState([]);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // 🔧 Settings / Notifications
  const [showSettings, setShowSettings] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  const navigate = useNavigate();

  // ⭐ Ratings
  const [averageRating, setAverageRating] = useState(0);
  const [ratingCounts, setRatingCounts] = useState({
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
  });
  const [totalRatings, setTotalRatings] = useState(0);

  useEffect(() => {
    const fetchStats = async () => {
      const { count: customerCount } = await supabase
        .from("user_profiles")
        .select("*", { count: "exact", head: true });

      const { count: ownerCount } = await supabase
        .from("business_profiles")
        .select("*", { count: "exact", head: true });

      const { count: scanCount } = await supabase
        .from("qr_scans")
        .select("*", { count: "exact", head: true });

      const { count: feedbackCount } = await supabase
        .from("feedback")
        .select("*", { count: "exact", head: true });

      setCustomers(customerCount || 0);
      setOwners(ownerCount || 0);
      setScans(scanCount || 0);
      setFeedback(feedbackCount || 0);
    };

    const fetchApplicants = async () => {
      const { data, error } = await supabase
        .from("business_profiles")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(5);

      if (!error && data) {
        setApplicants(data);
      }
    };

    const fetchRatings = async () => {
      const { data, error } = await supabase.from("feedback").select("rating");

      if (!error && data) {
        const counts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
        let total = data.length;
        let sum = 0;

        data.forEach((row) => {
          if (row.rating >= 1 && row.rating <= 5) {
            counts[row.rating] += 1;
            sum += row.rating;
          }
        });

        setTotalRatings(total);
        setRatingCounts(counts);
        setAverageRating(total > 0 ? (sum / total).toFixed(1) : 0);
      }
    };

    fetchStats();
    fetchApplicants();
    fetchRatings();
  }, []);

  // 🔔 Notifications (Supabase real-time)
  useEffect(() => {
    const addNotification = (title, message) => {
      setNotifications((prev) => [
        { id: Date.now(), title, message, time: new Date().toLocaleTimeString(), read: false },
        ...prev,
      ]);
      setUnreadCount((prev) => prev + 1);
    };

    const userSub = supabase
      .channel("user-changes")
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "user_profiles" }, (payload) => {
        addNotification("New user registered", `User ${payload.new.username || payload.new.email} just signed up.`);
      })
      .subscribe();

    const appSub = supabase
      .channel("business-changes")
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "business_profiles" }, (payload) => {
        addNotification("New business application", `${payload.new.business_name} submitted a new application.`);
      })
      .subscribe();

    const feedbackSub = supabase
      .channel("feedback-changes")
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "feedback" }, (payload) => {
        addNotification("New feedback received", `A user left a rating of ${payload.new.rating}★`);
      })
      .subscribe();

    return () => {
      supabase.removeChannel(userSub);
      supabase.removeChannel(appSub);
      supabase.removeChannel(feedbackSub);
    };
  }, []);

  return (
    <div className="dashboard-root">
      {/* Sidebar */}
      <aside className={`sidebar ${sidebarOpen ? "" : "closed"}`}>
        <div className="sidebar-title">Laundry Scout</div>
        <nav>
          <ul>
            <li className="active">
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
            <li>
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

      {/* Main */}
      <main className={`dashboard-main ${sidebarOpen ? "" : "expanded"}`}>
        <header className="dashboard-header">
          <div className="header-left">
            <FiMenu
              className="toggle-sidebar"
              onClick={() => setSidebarOpen(!sidebarOpen)}
            />
            <div>
              <h2>DASHBOARD</h2>
              <div className="dashboard-date">{new Date().toDateString()}</div>
            </div>
          </div>
          <div className="dashboard-header-icons">
            {/* Notifications */}
            <div className="dropdown-wrapper">
              <FiBell
                className="icon"
                onClick={() => {
                  setShowNotifications(!showNotifications);
                  setShowSettings(false);
                  setUnreadCount(0);
                }}
              />
              {unreadCount > 0 && <span className="notification-badge">{unreadCount}</span>}

              {showNotifications && (
                <div className="dropdown-panel">
                  {notifications.length === 0 ? (
                    <div className="dropdown-item">No notifications</div>
                  ) : (
                    notifications.slice(0, 5).map((n) => (
                      <div key={n.uid} className="dropdown-item">
                        <strong>{n.title}</strong>
                        <p>{n.message}</p>
                        <span className="notif-time">{n.time}</span>
                      </div>
                    ))
                  )}
                  <div
                    className="dropdown-item"
                    onClick={() => navigate("/notifications")}
                  >
                    View All
                  </div>
                </div>
              )}
            </div>

            {/* Profile */}
            <div className="dropdown-wrapper">
              <img
                src="https://via.placeholder.com/32"
                alt="profile"
                className="profile-avatar"
                onClick={() => {
                  setShowSettings(!showSettings);
                  setShowNotifications(false);
                }}
              />
              {showSettings && (
                <div className="dropdown-panel">
                  <div className="dropdown-item" onClick={() => navigate("/profile")}>
                    My Profile
                  </div>
                  <div className="dropdown-item" onClick={() => navigate("/settings")}>
                    Settings
                  </div>
                  <div className="dropdown-item" onClick={() => alert("Logging out...")}>
                    Logout
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Stats */}
        <section className="dashboard-overview">
          <div className="overview-rating">
            <div className="overview-title">Average User Rating</div>
            <div className="stars">
              {Array.from({ length: 5 }).map((_, i) => (
                <span
                  key={i}
                  style={{
                    color: i < Math.round(averageRating) ? "#FFD600" : "#ddd",
                  }}
                >
                  ★
                </span>
              ))}
            </div>
            <div className="rating-count">
              {totalRatings} Total Ratings — Avg: {averageRating} ★
            </div>
            <div className="rating-bars">
              {[5, 4, 3, 2, 1].map((star) => {
                const percent =
                  totalRatings > 0 ? (ratingCounts[star] / totalRatings) * 100 : 0;
                return (
                  <div className="rating-bar-row" key={star}>
                    <span>{star}★</span>
                    <div className="bar">
                      <div
                        className="fill"
                        style={{ width: `${percent}%` }}
                      ></div>
                    </div>
                    <span className="percent">{percent.toFixed(1)}%</span>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="overview-stats">
            <div className="stat-box">
              <div className="stat-icon">
                <FiUserCheck />
              </div>
              <div className="stat-label">Customers</div>
              <div className="stat-value">{customers}</div>
            </div>
            <div className="stat-box">
              <div className="stat-icon">
                <FiUserPlus />
              </div>
              <div className="stat-label">Owners</div>
              <div className="stat-value">{owners}</div>
            </div>
            <div className="stat-box">
              <div className="stat-icon">
                <FiGrid />
              </div>
              <div className="stat-label">QR Scans</div>
              <div className="stat-value">{scans}</div>
            </div>
            <div className="stat-box">
              <div className="stat-icon">
                <FiMail />
              </div>
              <div className="stat-label">Private Feedback</div>
              <div className="stat-value">{feedback}</div>
            </div>
          </div>
        </section>

        {/* Applicants */}
        <section className="dashboard-applicants">
          <div className="applicants-header">
            <div className="applicants-title">Applicants</div>
            <button
              className="view-all-btn"
              onClick={() => navigate("/applications")}
            >
              View All
            </button>
          </div>
          <table>
            <thead>
              <tr>
                <th>Store Name</th>
                <th>Owner Name</th>
                <th>Date Submitted</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {applicants.map((app, idx) => (
                <tr key={idx}>
                  <td>{app.business_name}</td>
                  <td>
                    {app.owner_first_name || ""} {app.owner_last_name || ""}
                  </td>
                  <td>
                    {app.created_at
                      ? new Date(app.created_at).toLocaleDateString("en-US", {
                          year: "numeric",
                          month: "long",
                          day: "numeric",
                        })
                      : ""}
                  </td>
                  <td className={`status ${app.status || "pending"}`}>
                    {app.status || "Pending"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      </main>
    </div>
  );
}

export default Dashboard;
