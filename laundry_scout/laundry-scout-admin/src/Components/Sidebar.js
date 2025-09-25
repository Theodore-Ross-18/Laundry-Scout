import React, { useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { FiHome, FiFileText, FiUsers, FiUser, FiClock, FiMessageSquare, FiLogOut } from "react-icons/fi";
import { handleLogout } from "./Services/Logout";
import "../Style/Sidebar.css";
import titleLogo from "../laundry-scout_title-logo.png";

function Sidebar({ isOpen = true, onLogout }) {
  const location = useLocation();
  const navigate = useNavigate();
  const [loggingOut, setLoggingOut] = useState(false);

  const isActive = (path) => location.pathname.startsWith(path);

  return (
    <aside className={`sidebar ${isOpen ? "" : "closed"}`}>
      <div className="sidebar-title"><img src={titleLogo} alt="laundry-scout" width="" height=""/></div>
      <nav>
        <ul>
          <li className={isActive("/dashboard") ? "active" : ""}>
            <Link to="/dashboard"><FiHome className="menu-icon" /><span>Dashboard</span></Link>
          </li>
          <li className={isActive("/applications") ? "active" : ""}>
            <Link to="/applications"><FiFileText className="menu-icon" /><span>Applications</span></Link>
          </li>
          <li className={isActive("/clients") ? "active" : ""}>
            <Link to="/clients"><FiUsers className="menu-icon" /><span>Clients</span></Link>
          </li>
          <li className={isActive("/users") ? "active" : ""}>
            <Link to="/users"><FiUser className="menu-icon" /><span>Users</span></Link>
          </li>
          <li className={isActive("/history") ? "active" : ""}>
            <Link to="/history"><FiClock className="menu-icon" /><span>History</span></Link>
          </li>
          <li className={isActive("/feedback") ? "active" : ""}>
            <Link to="/feedback"><FiMessageSquare className="menu-icon" /><span>Feedback</span></Link>
          </li>
        </ul>
      </nav>

      <button
        className="sidebar-logout"
        onClick={() => handleLogout(navigate, onLogout, setLoggingOut)}
        disabled={loggingOut}
      >
        <FiLogOut className="menu-icon" />
        <span>{loggingOut ? "Logging out..." : "Log Out"}</span>
      </button>
    </aside>
  );
}

export default Sidebar;
